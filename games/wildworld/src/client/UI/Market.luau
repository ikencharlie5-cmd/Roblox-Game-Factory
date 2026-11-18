--!strict
-- Robux prompts. The server (MonetizationService) grants everything; the client only prompts.
-- Id 0 / missing = not created yet (Charlie TODO) -> "Coming soon!" toast.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Derived = require(script.Parent:WaitForChild("Derived"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))

local Market = {}

local player = Players.LocalPlayer :: Player

local function soon()
	Kit.Sound("Error")
	Net.Toast("Coming soon!", "info")
end

local function def(group: string, key: string): { [string]: any }?
	local t = Derived.Config[group]
	local d = if type(t) == "table" then t[key] else nil
	return if type(d) == "table" then d else nil
end

function Market.PassDef(key: string): { [string]: any }?
	return def("GamePasses", key)
end

function Market.ProductDef(key: string): { [string]: any }?
	return def("DevProducts", key)
end

function Market.PromptPass(key: string)
	local d = def("GamePasses", key)
	if not d or (tonumber(d.Id) or 0) == 0 then
		soon()
		return
	end
	if Derived.HasPass(key) then
		Net.Toast("You already own " .. tostring(d.Name or key) .. "!", "success")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, d.Id)
end

function Market.PromptProduct(key: string)
	local d = def("DevProducts", key)
	if not d or (tonumber(d.Id) or 0) == 0 then
		soon()
		return
	end
	MarketplaceService:PromptProductPurchase(player, d.Id)
end

return Market
