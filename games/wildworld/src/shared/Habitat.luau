--!strict
-- Habitat rating 0..100 (pure; shared so Build mode can preview the live checklist).
-- Space 25 · Biome tags 20 · Food+water 15 · Shelter 10 · Enrichment 15 (5+4+3+2+1) · Social 15
local Config = require(script.Parent:WaitForChild("Config"))
local Species = require(script.Parent:WaitForChild("Species"))
local Items = require(script.Parent:WaitForChild("Items"))

local Habitat = {}

local ENRICH_STEPS = { 5, 4, 3, 2, 1 }

export type CheckRow = { key: string, label: string, score: number, max: number, hint: string? }
export type Result = {
	rating: number,
	checklist: { CheckRow },
	social: number, -- 0..100 (per pad average, for happiness)
	enrichment: number, -- 0..100
	hasFood: boolean,
	hasWater: boolean,
}

local function round1(n: number): number
	return math.floor(n * 10 + 0.5) / 10
end

-- pad: Items def of the pad. items: Items defs inside the pad. creatures: list of species names.
function Habitat.Rate(pad: any, items: { any }, creatures: { string }): Result
	local rows: { CheckRow } = {}
	local cells = (pad.W or 6) * (pad.D or 6)

	-- Space
	local need = 0
	local counts: { [string]: number } = {}
	for _, sp in creatures do
		local def = Species[sp]
		need += if def then def.Space else 9
		counts[sp] = (counts[sp] or 0) + 1
	end
	local space = if need == 0 then 25 else 25 * math.min(1, cells / need)
	table.insert(rows, {
		key = "Space",
		label = "Space",
		score = round1(space),
		max = 25,
		hint = if space < 25 then "+" .. math.ceil(25 - space) .. " with a bigger pad or fewer creatures" else nil,
	})

	-- Tags present
	local tags: { [string]: boolean } = {}
	for _, t in pad.Tags or {} do
		tags[t] = true
	end
	local hasFood, hasWater, hasShelter = false, false, false
	local enrichCount = 0
	for _, it in items do
		for _, t in it.Tags or {} do
			tags[t] = true
		end
		if it.Kind == "food" then
			hasFood = true
		end
		if Items.IsDrink(it) then
			hasWater = true
		end
		if Items.IsShelter(it) then
			hasShelter = true
		end
		if it.Enrich or it.Kind == "toy" then
			enrichCount += 1
		end
	end

	-- Biome tags (avg over species present; empty pad: any 3 tags)
	local biome, missing = 0, nil :: string?
	local nSpecies = 0
	for sp in counts do
		local def = Species[sp]
		if def then
			nSpecies += 1
			local have = 0
			for _, t in def.Tags do
				if tags[t] then
					have += 1
				elseif not missing then
					missing = t
				end
			end
			biome += have / #def.Tags
		end
	end
	if nSpecies > 0 then
		biome = 20 * biome / nSpecies
	else
		local n = 0
		for _ in tags do
			n += 1
		end
		biome = 20 * math.min(1, n / 3)
	end
	local perTag = if nSpecies > 0 then 20 / (3 * nSpecies) else 20 / 3
	table.insert(rows, {
		key = "Biome",
		label = "Biome match",
		score = round1(biome),
		max = 20,
		hint = if missing then "+" .. math.ceil(perTag) .. " if you add " .. missing else nil,
	})

	-- Food + water
	local fw = (if hasFood then 7.5 else 0) + (if hasWater then 7.5 else 0)
	table.insert(rows, {
		key = "FoodWater",
		label = "Food & water",
		score = fw,
		max = 15,
		hint = if not hasFood then "+7.5 if you add a food bowl"
			elseif not hasWater then "+7.5 if you add a water trough or pond"
			else nil,
	})

	-- Shelter
	table.insert(rows, {
		key = "Shelter",
		label = "Shelter",
		score = if hasShelter then 10 else 0,
		max = 10,
		hint = if hasShelter then nil else "+10 if you add a burrow or shelter hut",
	})

	-- Enrichment (diminishing)
	local enrich = 0
	for i = 1, math.min(enrichCount, #ENRICH_STEPS) do
		enrich += ENRICH_STEPS[i]
	end
	local nextStep = ENRICH_STEPS[enrichCount + 1]
	table.insert(rows, {
		key = "Enrichment",
		label = "Enrichment",
		score = enrich,
		max = 15,
		hint = if nextStep then "+" .. nextStep .. " if you add a toy, tree or decor" else nil,
	})

	-- Social (group size within the species' preferred range)
	local social, socialHint = 0, nil :: string?
	if nSpecies > 0 then
		for sp, n in counts do
			local def = Species[sp]
			local range = def and (Config.AI.GroupRange :: any)[def.Personality] or { 1, 4 }
			local s = 1
			if n < range[1] then
				s = n / range[1]
				socialHint = socialHint or ("+" .. math.ceil(15 * (1 - s) / nSpecies) .. " if you add another " .. sp)
			elseif n > range[2] then
				s = range[2] / n
				socialHint = socialHint or ("Too crowded: " .. sp .. " likes up to " .. range[2])
			end
			social += s
		end
		social = 15 * social / nSpecies
	end
	table.insert(rows, {
		key = "Social",
		label = "Social",
		score = round1(social),
		max = 15,
		hint = if nSpecies == 0 then "Assign creatures to this habitat" else socialHint,
	})

	local total = 0
	for _, r in rows do
		total += r.score
	end
	return {
		rating = math.clamp(math.floor(total + 0.5), 0, 100),
		checklist = rows,
		social = if nSpecies > 0 then social / 15 * 100 else 0,
		enrichment = enrich / 15 * 100,
		hasFood = hasFood,
		hasWater = hasWater,
	}
end

-- 0..100 rating -> stars (0..5 in halves) for UI.
function Habitat.Stars(rating: number): number
	return math.floor(rating / 10 + 0.5) / 2
end

return Habitat
