--!strict
-- Species blueprints for the code-built creatures (Graphics).
--   CreatureBlueprints.Species[species] -> Blueprint (see Shapes.luau for the format)
--   CreatureBlueprints.Build(species, look) -> Model   (gameplay hook used by server/Services/Models.luau;
--     look = { genes, mutations, stage, hue, scale, bow } -> forwarded to CreatureBuilder.FromLook)
local Shapes = require(script.Shapes)

local Species: { [string]: Shapes.Blueprint } = {
	Lumibun = require(script.Lumibun),
	Mossback = require(script.Mossback),
	Emberfox = require(script.Emberfox),
	Pebblehorn = require(script.Pebblehorn),
	Thornstag = require(script.Thornstag),
}

local CreatureBlueprints = {}
CreatureBlueprints.Species = Species

function CreatureBlueprints.Get(species: string): Shapes.Blueprint?
	return Species[species]
end

function CreatureBlueprints.Build(species: string, look: any?): Model?
	-- Required lazily: CreatureBuilder requires this module.
	local Builder = require(script.Parent:WaitForChild("CreatureBuilder")) :: any
	return Builder.FromLook(species, look)
end

return CreatureBlueprints
