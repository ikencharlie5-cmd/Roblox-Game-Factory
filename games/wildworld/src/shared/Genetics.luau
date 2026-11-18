--!strict
-- Pure genetics math (shared so the Breeding UI can show the same odds the server uses).
-- Genes string: "Cc|Pp|Ss|Gg" (dominant uppercase first). Order: Color, Pattern, Size, Glow.
local Config = require(script.Parent:WaitForChild("Config"))
local Species = require(script.Parent:WaitForChild("Species"))

local Genetics = {}

Genetics.Genes = { "C", "P", "S", "G" }
Genetics.GeneNames = { C = "Color", P = "Pattern", S = "Size", G = "Glow" }

local function norm(a: string, b: string): string
	-- uppercase first so "cC" == "Cc"
	if a == string.lower(a) and b ~= string.lower(b) then
		return b .. a
	end
	return a .. b
end

-- Returns { "Cc", "PP", ... } or nil if malformed.
function Genetics.Parse(genes: any): { string }?
	if type(genes) ~= "string" then
		return nil
	end
	local parts = string.split(genes, "|")
	if #parts ~= 4 then
		return nil
	end
	for i, g in Genetics.Genes do
		local pair = parts[i]
		if #pair ~= 2 then
			return nil
		end
		for j = 1, 2 do
			local ch = string.sub(pair, j, j)
			if ch ~= g and ch ~= string.lower(g) then
				return nil
			end
		end
	end
	return parts
end

function Genetics.Join(parts: { string }): string
	return table.concat(parts, "|")
end

function Genetics.Default(): string
	return "CC|PP|SS|GG"
end

-- Wild / starter genes: each allele recessive with `chance`.
function Genetics.Random(rng: Random, chance: number): string
	local out = {}
	for _, g in Genetics.Genes do
		local a = if rng:NextNumber() < chance then string.lower(g) else g
		local b = if rng:NextNumber() < chance then string.lower(g) else g
		table.insert(out, norm(a, b))
	end
	return Genetics.Join(out)
end

-- Mendelian: one random allele from each parent per gene.
function Genetics.Cross(rng: Random, genesA: string, genesB: string): string
	local a = Genetics.Parse(genesA) or string.split(Genetics.Default(), "|")
	local b = Genetics.Parse(genesB) or string.split(Genetics.Default(), "|")
	local out = {}
	for i = 1, 4 do
		local xi = rng:NextInteger(1, 2)
		local x = string.sub(a[i], xi, xi)
		local yi = rng:NextInteger(1, 2)
		local y = string.sub(b[i], yi, yi)
		table.insert(out, norm(x, y))
	end
	return Genetics.Join(out)
end

-- Visible traits from a gene string.
export type Traits = { altColor: boolean, spots: boolean, size: number, glow: boolean }
function Genetics.Traits(genes: string): Traits
	local p = Genetics.Parse(genes) or string.split(Genetics.Default(), "|")
	local function recessive(pair: string): boolean
		return pair == string.lower(pair)
	end
	local s = p[3]
	local size = if s == "ss" then 0.85 elseif s == "SS" then 1 else 0.95
	return { altColor = recessive(p[1]), spots = recessive(p[2]), size = size, glow = recessive(p[4]) }
end

-- Breeding odds per gene for the UI. knownA/knownB false -> that gene shows "?".
-- Returns { {gene="C", name="Color", recessivePct=25, mixedPct=50, known=true}, ... }
function Genetics.Odds(genesA: string, genesB: string, knownA: boolean, knownB: boolean): { any }
	local a = Genetics.Parse(genesA) or string.split(Genetics.Default(), "|")
	local b = Genetics.Parse(genesB) or string.split(Genetics.Default(), "|")
	local out = {}
	for i, g in Genetics.Genes do
		local rec, mixed = 0, 0
		for x = 1, 2 do
			for y = 1, 2 do
				local ax, by = string.sub(a[i], x, x), string.sub(b[i], y, y)
				local lowA, lowB = ax == string.lower(ax), by == string.lower(by)
				if lowA and lowB then
					rec += 25
				elseif lowA ~= lowB then
					mixed += 25
				end
			end
		end
		table.insert(out, {
			gene = g,
			name = Genetics.GeneNames[g],
			recessivePct = rec,
			mixedPct = mixed,
			known = knownA and knownB,
		})
	end
	return out
end

-- Chance of mutation `name` for a baby, given parent mutation lists and modifiers.
function Genetics.MutationChance(name: string, mutsA: { string }?, mutsB: { string }?, mods: any?): number
	local def = (Config.Mutations :: any)[name]
	if not def or not def.Enabled then
		return 0
	end
	local rules = Config.MutationRules
	local hasA = mutsA ~= nil and table.find(mutsA, name) ~= nil
	local hasB = mutsB ~= nil and table.find(mutsB, name) ~= nil
	local c = def.Chance
	if hasA and hasB then
		c *= rules.HeirloomBoth
	elseif hasA or hasB then
		c *= rules.HeirloomOne
	end
	if mods and mods.habitat80 then
		c *= rules.HabitatBonus
	end
	if mods and mods.rainbow then
		c *= rules.RainbowBonus
	end
	return math.min(c, rules.Cap)
end

local function exclusive(a: string, b: string): boolean
	for _, pair in Config.MutationRules.Exclusive do
		if (pair[1] == a and pair[2] == b) or (pair[1] == b and pair[2] == a) then
			return true
		end
	end
	return false
end

-- Rolls up to 2 mutations. force = name to guarantee as the first (golden first egg, daily egg).
function Genetics.RollMutations(rng: Random, mutsA: { string }?, mutsB: { string }?, mods: any?, force: string?)
	local result: { string } = {}
	if force then
		table.insert(result, force)
	else
		for _, name in Config.MutationOrder do
			if rng:NextNumber() < Genetics.MutationChance(name, mutsA, mutsB, mods) then
				table.insert(result, name)
				break
			end
		end
	end
	if #result == 1 then
		for _, name in Config.MutationOrder do
			if name ~= result[1] and not exclusive(name, result[1]) then
				local c = Genetics.MutationChance(name, mutsA, mutsB, mods) / Config.MutationRules.SecondDivisor
				if rng:NextNumber() < c then
					table.insert(result, name)
					break
				end
			end
		end
	end
	return result
end

-- Combined income multiplier (combos replace the product of their parts).
function Genetics.MutationMult(muts: { string }?): number
	if not muts or #muts == 0 then
		return 1
	end
	for _, combo in Config.MutationRules.Combos do
		if table.find(muts, combo.A) and table.find(muts, combo.B) then
			return combo.Mult
		end
	end
	local m = 1
	for _, name in muts do
		local def = (Config.Mutations :: any)[name]
		if def then
			m *= def.Mult
		end
	end
	return m
end

-- Display name of a mutation list: "Gilded Crystal", "Golden", "Golden Glowing", "".
function Genetics.MutationLabel(muts: { string }?): string
	if not muts or #muts == 0 then
		return ""
	end
	for _, combo in Config.MutationRules.Combos do
		if table.find(muts, combo.A) and table.find(muts, combo.B) then
			return combo.Name
		end
	end
	return table.concat(muts, " ")
end

local function rarityIndex(r: string): number
	return table.find(Config.RarityOrder, r) or 1
end

-- Rarity shown on cards / reveal ladder: max(species rarity, mutation rarity).
function Genetics.DisplayRarity(species: string, muts: { string }?): string
	local def = Species[species]
	local best = if def then def.Rarity else "Common"
	if muts then
		for _, name in muts do
			local m = (Config.Mutations :: any)[name]
			if m and rarityIndex(m.Rarity) > rarityIndex(best) then
				best = m.Rarity
			end
		end
		if #muts >= 2 then
			best = "Legendary"
		end
	end
	return best
end

return Genetics
