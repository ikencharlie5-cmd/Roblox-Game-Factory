--!strict
-- Helper for WildService (not a service): what a wild spawn is. Species by rarity weight
-- (Config.Capture.SpawnWeights) with the new-player breeding-match bias, and wild mutations
-- (Starfruit bait nearby boosts the chance).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Species = require(Shared:WaitForChild("Species"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local WildRoll = {}

local rng = Random.new()

local function nearestStarfruit(pos: Vector3): boolean
	for _, p in Players:GetPlayers() do
		local d = DataService.Get(p)
		local root = Guard.RootPos(p)
		if d and root and d.boosts.starfruit > os.time() and (root - pos).Magnitude < 200 then
			return true
		end
	end
	return false
end

-- Species that a player who hasn't bred their first (Golden) egg owns exactly one of.
function WildRoll.WantedSpecies(zone: any): { string }
	local out = {}
	for _, p in Players:GetPlayers() do
		local d = DataService.Get(p)
		if d and not d.flags.goldenGiven then
			local count: { [string]: number } = {}
			for _, c in d.creatures do
				count[c.species] = (count[c.species] or 0) + 1
			end
			for sp, n in count do
				if n == 1 and table.find(zone.Species, sp) and not table.find(out, sp) then
					table.insert(out, sp)
				end
			end
		end
	end
	return out
end

function WildRoll.PickSpecies(zone: any): string
	local want = WildRoll.WantedSpecies(zone)
	if #want > 0 and rng:NextNumber() < Config.Capture.StarterSpeciesBias then
		return want[rng:NextInteger(1, #want)]
	end
	local weights: any = Config.Capture.SpawnWeights
	local total, list = 0, {}
	for _, sp in zone.Species do
		local w = weights[Species[sp].Rarity] or 1
		total += w
		table.insert(list, { sp = sp, w = w })
	end
	local roll = rng:NextNumber(0, total)
	for _, e in list do
		roll -= e.w
		if roll <= 0 then
			return e.sp
		end
	end
	return list[1].sp
end

function WildRoll.Mutations(zone: any, pos: Vector3): { string }
	local mult = if nearestStarfruit(pos) then Config.Capture.StarfruitEpicMult else 1
	if zone.Legendary and rng:NextNumber() < Config.Capture.WildLegendaryChance * mult then
		return { "Crystal" }
	end
	if rng:NextNumber() < Config.Capture.WildEpicChance * mult then
		return { if rng:NextNumber() < 0.5 then "Golden" else "Albino" }
	end
	return {}
end

return WildRoll
