--!strict
-- Robux purchases go through the PromptPurchase remote; the server prompts and grants.
-- Id 0 = not created yet (Charlie TODO) -> server answers "Coming soon!".
local Derived = require(script.Parent:WaitForChild("Derived"))
local Net = require(script.Parent:WaitForChild("Net"))

local Market = {}

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

-- The server prompts (PromptPurchase) so it can check Id 0 / already owned in one place.
function Market.PromptPass(key: string)
	if Derived.HasPass(key) then
		Net.Toast("You already own " .. tostring((def("GamePasses", key) or {}).Name or key) .. "!", "success")
		return
	end
	Net.Do("PromptPurchase", nil, "pass", key)
end

function Market.PromptProduct(key: string)
	Net.Do("PromptPurchase", nil, "product", key)
end

return Market
