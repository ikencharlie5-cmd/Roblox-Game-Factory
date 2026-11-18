--!strict
-- Helper (not a service): Journal mastery, 5 steps per species:
-- 1 Discover · 2 Raise an adult · 3 Breed once · 4 Own 3 at once · 5 Get a mutation.
-- First discovery = full-screen Reveal("Discovery") + RP + coins.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Species = require(Shared:WaitForChild("Species"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local Journal = {}

Journal.Steps = { "Discover", "Raise an adult", "Breed once", "Own 3 at once", "Get a mutation" }

local function check(data: any, species: string, step: number): boolean
	local owned, adult, mutated = 0, false, false
	for _, c in data.creatures do
		if c.species == species then
			owned += 1
			adult = adult or c.stage == "Adult"
			mutated = mutated or #c.mutations > 0
		end
	end
	local js = data.journalStats and data.journalStats[species] or {}
	if step == 1 then
		return owned > 0
	elseif step == 2 then
		return adult
	elseif step == 3 then
		return (js.bred or 0) > 0
	elseif step == 4 then
		return owned >= 3
	elseif step == 5 then
		return mutated or (js.mutated or 0) > 0
	end
	return false
end

-- Re-check a species after any change. note: "bred" | "mutated" | nil bumps a stat first.
function Journal.Update(player: Player, species: string, note: string?)
	local data = DataService.Get(player)
	if not data or not Species[species] then
		return
	end
	local discovered = false
	local stepsGained = 0
	DataService.Update(player, function(d)
		d.journalStats = d.journalStats or {}
		local js = d.journalStats[species] or {}
		d.journalStats[species] = js
		if note then
			js[note] = (js[note] or 0) + 1
		end
		local step = d.journal[species] or 0
		while step < #Journal.Steps and check(d, species, step + 1) do
			step += 1
			stepsGained += 1
			if step == 1 then
				discovered = true
				d.rp += Config.RP.Discovery
				d.coins += Config.RP.DiscoveryCoins
			else
				d.rp += Config.RP.JournalStep * step
			end
		end
		d.journal[species] = step
	end)
	if discovered then
		local def = Species[species]
		Guard.Reveal(player, "Discovery", {
			species = species,
			rarity = def.Rarity,
			blurb = def.Blurb,
			rp = Config.RP.Discovery,
			coins = Config.RP.DiscoveryCoins,
		})
		Guard.Sound(player, "Discovery")
	elseif stepsGained > 0 then
		Guard.Toast(player, "Journal: " .. species .. " step " .. data.journal[species] .. "/5", "reward")
		Guard.Sound(player, "JournalStep")
	end
end

return Journal
