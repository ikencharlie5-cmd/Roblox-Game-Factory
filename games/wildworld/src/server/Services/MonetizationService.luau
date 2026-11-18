--!strict
-- Game Passes (cached on join) and Dev Products (ProcessReceipt). IDs live in Config.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local MonetizationService = {}

local owned: { [Player]: { [string]: boolean } } = {}

-- Handlers per Dev Product key. Return true once granted.
local productHandlers: { [string]: (Player) -> boolean } = {
	CashPackSmall = function(player)
		DataService.AddCash(player, Config.DevProducts.CashPackSmall.Cash)
		return true
	end,
}

function MonetizationService.HasPass(player: Player, key: string): boolean
	local t = owned[player]
	return t ~= nil and t[key] == true
end

-- Multiplier helper for income code.
function MonetizationService.CashMultiplier(player: Player): number
	return if MonetizationService.HasPass(player, "DoubleCash") then 2 else 1
end

function MonetizationService.PromptPass(player: Player, key: string)
	local pass = (Config.GamePasses :: any)[key]
	if pass and pass.Id ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, pass.Id)
	end
end

function MonetizationService.PromptProduct(player: Player, key: string)
	local product = (Config.DevProducts :: any)[key]
	if product and product.Id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, product.Id)
	end
end

local function loadPasses(player: Player)
	local t = {}
	for key, pass in Config.GamePasses :: any do
		if pass.Id ~= 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			t[key] = ok and has
		end
	end
	owned[player] = t
	for key, has in t do
		player:SetAttribute("Pass_" .. key, has)
	end
end

function MonetizationService.Init()
	Players.PlayerAdded:Connect(loadPasses)
	for _, p in Players:GetPlayers() do
		task.spawn(loadPasses, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		owned[p] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Config.GamePasses :: any do
			if pass.Id == passId and owned[player] then
				owned[player][key] = true
				player:SetAttribute("Pass_" .. key, true)
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player or not DataService.Get(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		for key, product in Config.DevProducts :: any do
			if product.Id == info.ProductId then
				local handler = productHandlers[key]
				if handler and handler(player) then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return MonetizationService
