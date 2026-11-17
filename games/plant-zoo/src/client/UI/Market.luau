--!strict
-- Robux prompts. The server (MonetizationService) grants everything; the client only prompts.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Derived = require(script.Parent:WaitForChild("Derived"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local Market = {}

local player = Players.LocalPlayer :: Player
local notify: ((string, string?) -> ())? = nil

function Market.SetNotifier(fn: (string, string?) -> ())
	notify = fn
end

local function soon()
	Kit.Sound("Error")
	if notify then
		(notify :: (string, string?) -> ())("Coming soon!", "info")
	end
end

function Market.PromptPass(key: string)
	local def = Derived.Config.GamePasses[key]
	if not def or (def.Id or 0) == 0 then
		soon()
		return
	end
	if Derived.HasPass(key) then
		if notify then
			(notify :: (string, string?) -> ())("You already own " .. def.Name .. "!", "success")
		end
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, def.Id)
end

function Market.PromptProduct(key: string)
	local def = Derived.Config.DevProducts[key]
	if not def or (def.Id or 0) == 0 then
		soon()
		return
	end
	MarketplaceService:PromptProductPurchase(player, def.Id)
end

return Market
