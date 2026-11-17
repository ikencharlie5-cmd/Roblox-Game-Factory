--!strict
-- Game Passes (cached on join) and Dev Products (ProcessReceipt). IDs live in Config.
-- Other services register product handlers with RegisterProduct (avoids require cycles).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local MonetizationService = {}

local owned: { [Player]: { [string]: boolean } } = {}
local productHandlers: { [string]: (Player) -> boolean } = {}
local passCbs: { (Player) -> () } = {}
-- Receipts granted this session (guards against double-grant if ProcessReceipt retries).
local granted: { [string]: boolean } = {}

-- handler(player) -> true once granted (data already updated).
function MonetizationService.RegisterProduct(key: string, handler: (Player) -> boolean)
	productHandlers[key] = handler
end

-- Called (player) whenever a player's pass ownership changes (load or purchase).
function MonetizationService.OnPassesChanged(fn: (Player) -> ())
	table.insert(passCbs, fn)
end

function MonetizationService.HasPass(player: Player, key: string): boolean
	local t = owned[player]
	return t ~= nil and t[key] == true
end

local function firePass(player: Player)
	for _, fn in passCbs do
		task.spawn(fn, player)
	end
end

local function loadPasses(player: Player)
	local t = {}
	for key, pass in Config.GamePasses :: any do
		local has = false
		if pass.Id ~= 0 then
			local ok, res = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			has = ok and res == true
		end
		t[key] = has
		player:SetAttribute("Pass_" .. key, has)
	end
	owned[player] = t
	firePass(player)
end

function MonetizationService.Init()
	Players.PlayerAdded:Connect(loadPasses)
	for _, p in Players:GetPlayers() do
		task.spawn(loadPasses, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		owned[p] = nil
	end)
	DataService.OnLoaded(function(player)
		firePass(player) -- data may load after passes; let income recompute
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Config.GamePasses :: any do
			if pass.Id == passId and owned[player] then
				owned[player][key] = true
				player:SetAttribute("Pass_" .. key, true)
				Guard.Notify(player, "Thanks! " .. pass.Name .. " unlocked", "success")
				Guard.Sound(player, "Purchase")
				firePass(player)
			end
		end
	end)

	-- Hope packs are handled here; others register from their own services.
	for key, product in Config.DevProducts :: any do
		if product.Hope then
			productHandlers[key] = function(player)
				DataService.Update(player, function(d)
					d.hope += product.Hope
				end)
				return true
			end
		end
	end

	MarketplaceService.ProcessReceipt = function(info)
		if granted[info.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player or not DataService.Get(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		for key, product in Config.DevProducts :: any do
			if product.Id == info.ProductId and product.Id ~= 0 then
				local handler = productHandlers[key]
				local ok, res = pcall(function()
					return handler and handler(player)
				end)
				if ok and res then
					granted[info.PurchaseId] = true
					Guard.Notify(player, "Thanks! " .. product.Name, "success")
					Guard.Sound(player, "Purchase")
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
				warn("[MonetizationService] product handler failed:", key, res)
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return MonetizationService
