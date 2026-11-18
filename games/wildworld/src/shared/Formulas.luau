--!strict
-- Pure formulas shared by server and UI (so UI previews match the server exactly).
local Config = require(script.Parent:WaitForChild("Config"))
local Species = require(script.Parent:WaitForChild("Species"))
local Genetics = require(script.Parent:WaitForChild("Genetics"))

local Formulas = {}

-- XP needed to go from level n to n+1.
function Formulas.LevelXP(n: number): number
	return math.floor(Config.XP.Base * n ^ Config.XP.Exp)
end

function Formulas.HabitatMult(rating: number): number
	return 0.5 + 1.5 * math.clamp(rating, 0, 100) / 100
end

-- Returns tier index (1..6), tier def.
function Formulas.ParkTier(rating: number): (number, any)
	local tiers = Config.Economy.ParkTiers
	local idx = 1
	for i, t in tiers do
		if rating >= t.Min then
			idx = i
		end
	end
	return idx, tiers[idx]
end

function Formulas.HappyMult(happy: number): number
	return if happy < Config.Needs.HappyLowThreshold then 0.5 else 1
end

-- Coins/min one creature contributes before habitat/park multipliers.
function Formulas.CreatureValue(rec: any): number
	local def = Species[rec.species]
	if not def then
		return 0
	end
	local v = def.BaseValue * Genetics.MutationMult(rec.mutations) * Formulas.HappyMult(rec.happy or 100)
	if rec.stage == "Baby" then
		v *= Config.Growth.BabyIncomeMult
	end
	return v
end

function Formulas.SellValue(rec: any): number
	local def = Species[rec.species]
	if not def then
		return 0
	end
	return math.floor(def.BaseValue * Genetics.MutationMult(rec.mutations) * Config.SellValueMinutes)
end

function Formulas.ParkSlots(level: number): number
	local slots = Config.Upgrades.Capacity.Slots
	return slots[math.clamp(level + 1, 1, #slots)]
end

function Formulas.LandSize(level: number): number
	local sizes = Config.Grid.LandSizes
	return sizes[math.clamp(level + 1, 1, #sizes)]
end

function Formulas.Incubators(level: number, hasPass: boolean): number
	return Config.Breeding.BaseIncubators + level + (if hasPass then 1 else 0)
end

function Formulas.CalmNetBonus(level: number): number
	return level * Config.Capture.CalmNetBonus
end

-- Next upgrade cost or nil when maxed.
function Formulas.UpgradeCost(key: string, level: number): number?
	local def = (Config.Upgrades :: any)[key]
	if not def then
		return nil
	end
	return def.Costs[level + 1]
end

function Formulas.BreedCost(species: string): number
	local def = Species[species]
	local costs: any = Config.Breeding.Cost
	return if def then costs[def.Rarity] or 50 else 50
end

-- Dev product key for Instant Hatch by seconds left.
function Formulas.InstantHatchKey(secondsLeft: number): string
	for _, key in { "InstantHatch1", "InstantHatch2", "InstantHatch3" } do
		if secondsLeft <= (Config.DevProducts :: any)[key].MaxSecondsLeft then
			return key
		end
	end
	return "InstantHatch3"
end

-- UTC day number (daily reward, quests, likes).
function Formulas.Day(t: number?): number
	return math.floor((t or os.time()) / 86400)
end

-- Grid: cells across the full plot and the buildable square for a land level (cell range, inclusive).
function Formulas.PlotCells(): number
	return Config.Grid.PlotSize // Config.Grid.Cell
end

function Formulas.BuildRange(landLevel: number): (number, number)
	local n = Formulas.LandSize(landLevel) // Config.Grid.Cell
	local total = Formulas.PlotCells()
	local lo = (total - n) // 2
	return lo, lo + n - 1
end

-- Plot-local centre (studs, X/Z) of an item whose min corner cell is (x, z) with footprint w x d.
function Formulas.CellCentre(x: number, z: number, w: number, d: number): (number, number)
	local cell = Config.Grid.Cell
	local half = Formulas.PlotCells() / 2
	return (x + w / 2 - half) * cell, (z + d / 2 - half) * cell
end

return Formulas
