--!strict
-- Gameplay hook (Models.luau looks for World.ItemModels.Build): build-item visuals from Theme.Props.
-- Build(itemId, def?) -> Model, pivot = footprint centre at ground level. def = Items.Defs entry (W/D used
-- as the footprint so visuals always match gameplay's grid).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

local ItemModels = {}
local counter = 0

function ItemModels.Build(itemId: string, def: any?): Model?
	counter += 1
	local w = if type(def) == "table" and type(def.W) == "number" then def.W else nil
	local d = if type(def) == "table" and type(def.D) == "number" then def.D else nil
	return Theme.Props.Build(itemId, counter, w, d)
end

return ItemModels
