--!strict
-- Game Passes (cached on join) and Dev Products (ProcessReceipt, dupe-proof via saved PurchaseIds).
-- Cosmetic / convenience only: never mutation luck or capture guarantees.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local MonetizationService = {}

local owned: { [Player]: { [string]: boolean } } = {}
local pendingHatch: { [Player]: string } = {}

local function instantHatch(player: Player, data: any): boolean
	local now = os.time()
	local target: any = nil
	for _, e in data.eggs do
		if e.id == pendingHatch[player] and e.readyAt > now then
			target = e
		end
	end
	if not target then
		for _, e in data.eggs do
			if e.readyAt > now and (not target or e.readyAt > target.readyAt) then
				target = e
			end
		end
	end
	pendingHatch[player] = nil
	DataService.Update(player, function(d)
		if target then
			target.readyAt = now
		else
			d.coins += Config.InstantHatchFallbackCoins
		end
	end)
	if target then
		Guard.Toast(player, "Your " .. target.species .. " egg is ready to hatch!", "success")
		Guard.Sound(player, "EggReady")
	else
		Guard.Toast(player, "No egg was incubating - here are " .. Config.InstantHatchFallbackCoins .. " coins", "info")
	end
	return true
end

local function coins(key: string): (Player, any) -> boolean
	return function(player)
		DataService.AddCoins(player, (Config.DevProducts :: any)[key].Coins, false)
		Guard.Sound(player, "Purchase")
		return true
	end
end

local productHandlers: { [string]: (Player, any) -> boolean } = {
	InstantHatch1 = instantHatch,
	InstantHatch2 = instantHatch,
	InstantHatch3 = instantHatch,
	CoinsSmall = coins("CoinsSmall"),
	CoinsMedium = coins("CoinsMedium"),
	CoinsLarge = coins("CoinsLarge"),
	StarterPack = function(player)
		DataService.Update(player, function(d)
			d.coins += Config.DevProducts.StarterPack.Coins
			d.flags.starterPack = true
			d.flags.bow = true
		end)
		Guard.Reveal(player, "StarterPack", { coins = Config.DevProducts.StarterPack.Coins })
		Guard.Sound(player, "Purchase")
		Signals.Fire("BowUnlocked", player)
		return true
	end,
}

function MonetizationService.HasPass(player: Player, key: string): boolean
	local t = owned[player]
	return t ~= nil and t[key] == true
end

local function setPassAttrs(player: Player)
	for key in Config.GamePasses do
		player:SetAttribute("Pass_" .. key, MonetizationService.HasPass(player, key))
	end
	player:SetAttribute("VIP", MonetizationService.HasPass(player, "VIP"))
end

local function loadPasses(player: Player)
	local t = {}
	for key, pass in Config.GamePasses :: any do
		if pass.Id ~= 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			t[key] = ok and has == true
		end
	end
	owned[player] = t
	setPassAttrs(player)
end

local function prompt(player: Player, data: any, kind: any, key: any)
	if kind == "pass" and type(key) == "string" and (Config.GamePasses :: any)[key] then
		local pass = (Config.GamePasses :: any)[key]
		if MonetizationService.HasPass(player, key) then
			return Guard.Fail(player, "You already own this")
		end
		if pass.Id == 0 then
			return Guard.Fail(player, "Coming soon!")
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.Id)
		return true, key
	elseif kind == "product" and type(key) == "string" and (Config.DevProducts :: any)[key] then
		local product = (Config.DevProducts :: any)[key]
		if string.sub(key, 1, 12) == "InstantHatch" then
			return false, "Use RequestInstantHatch"
		end
		if key == "StarterPack" and data.flags.starterPack then
			return Guard.Fail(player, "You already have the Starter Pack")
		end
		if product.Id == 0 then
			return Guard.Fail(player, "Coming soon!")
		end
		MarketplaceService:PromptProductPurchase(player, product.Id)
		return true, key
	end
	return false, "Bad request"
end

local function requestInstantHatch(player: Player, data: any, eggId: any)
	if type(eggId) ~= "string" then
		return false, "Bad request"
	end
	for _, e in data.eggs do
		if e.id == eggId then
			local left = e.readyAt - os.time()
			if left <= 0 then
				return Guard.Fail(player, "It's already ready!")
			end
			local key = Formulas.InstantHatchKey(left)
			local product = (Config.DevProducts :: any)[key]
			if product.Id == 0 then
				return Guard.Fail(player, "Coming soon!")
			end
			pendingHatch[player] = eggId
			MarketplaceService:PromptProductPurchase(player, product.Id)
			return true, key
		end
	end
	return false, "Bad request"
end

function MonetizationService.Init()
	Players.PlayerAdded:Connect(loadPasses)
	for _, p in Players:GetPlayers() do
		task.spawn(loadPasses, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		owned[p] = nil
		pendingHatch[p] = nil
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased or not owned[player] then
			return
		end
		for key, pass in Config.GamePasses :: any do
			if pass.Id == passId then
				owned[player][key] = true
				Guard.Reveal(player, "PassBought", { key = key, name = pass.Name })
				Guard.Sound(player, "Purchase")
			end
		end
		setPassAttrs(player)
		Signals.Fire("CreaturesChanged", player) -- VIP income bonus
	end)
	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		local data = player and DataService.Get(player)
		if not player or not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if table.find(data.receipts, info.PurchaseId) then
			-- already granted here; only confirm once it's actually persisted (SaveNow is false on lost lock)
			if not DataService.SaveNow(player) then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		for key, product in Config.DevProducts :: any do
			local handler = productHandlers[key]
			if product.Id == info.ProductId and product.Id ~= 0 and handler then
				local ok, granted = pcall(handler, player, data)
				if not ok or not granted then
					warn("[Monetization] grant failed:", key, granted)
					return Enum.ProductPurchaseDecision.NotProcessedYet
				end
				DataService.Update(player, function(d)
					table.insert(d.receipts, info.PurchaseId)
					while #d.receipts > Config.ReceiptMemory do
						table.remove(d.receipts, 1)
					end
				end)
				if not DataService.SaveNow(player) then
					return Enum.ProductPurchaseDecision.NotProcessedYet -- receipt is cached: retry won't double-grant
				end
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Guard.Bind("PromptPurchase", prompt)
	Guard.Bind("RequestInstantHatch", requestInstantHatch)
end

return MonetizationService
