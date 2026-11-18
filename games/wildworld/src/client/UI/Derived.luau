--!strict
-- Read-only helpers over Shared/Config + the server data mirror (State). Display only.
-- Reads Config first (Gameplay owns it); the FALLBACK tables mirror SPEC.md so the UI still
-- renders if a Config key is missing or renamed. Never used to decide outcomes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(script.Parent:WaitForChild("State"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config: any = require(Shared:WaitForChild("Config"))

local Derived = {}
Derived.Config = Config

local function sharedModule(name: string): any
	local m = Shared:FindFirstChild(name)
	if m and m:IsA("ModuleScript") then
		local ok, mod = pcall(require, m)
		if ok then
			return mod
		end
	end
	return nil
end

-- First non-nil Config.<k> (or a shared module named k).
local function cfg(...: string): any
	for _, k in { ... } do
		if Config[k] ~= nil then
			return Config[k]
		end
	end
	for _, k in { ... } do
		local m = sharedModule(k)
		if m ~= nil then
			return m
		end
	end
	return nil
end
Derived.Cfg = cfg

local FALLBACK_SPECIES = {
	{ name = "Lumibun", rarity = "Common", baseValue = 4, eggTime = 120, tags = { "grass", "flower", "burrow" } },
	{ name = "Mossback", rarity = "Common", baseValue = 5, eggTime = 120, tags = { "grass", "tree", "rock" } },
	{ name = "Emberfox", rarity = "Common", baseValue = 6, eggTime = 120, tags = { "tree", "log", "sunspot" } },
	{ name = "Pebblehorn", rarity = "Uncommon", baseValue = 12, eggTime = 300, tags = { "rock", "water", "sand" } },
	{ name = "Thornstag", rarity = "Rare", baseValue = 25, eggTime = 600, tags = { "tree", "water", "bush" } },
}

local FALLBACK_TIERS = {
	{ name = "Poor", min = 0, bonus = 0 },
	{ name = "Developing", min = 20, bonus = 0.05 },
	{ name = "Good", min = 40, bonus = 0.10 },
	{ name = "Excellent", min = 60, bonus = 0.20 },
	{ name = "World-class", min = 75, bonus = 0.35 },
	{ name = "Legendary", min = 90, bonus = 0.50 },
}

local function field(t: any, ...: string): any
	if type(t) ~= "table" then
		return nil
	end
	for _, k in { ... } do
		if t[k] ~= nil then
			return t[k]
		end
	end
	return nil
end
Derived.Field = field

-- Normalises a keyed-or-array table of defs into an array of {name=..., raw...}.
local function list(t: any): { { [string]: any } }
	local out = {}
	if type(t) ~= "table" then
		return out
	end
	for k, v in t do
		if type(v) == "table" then
			local e = table.clone(v)
			e.name = field(v, "name", "Name", "id", "Id") or (if type(k) == "string" then k else tostring(k))
			table.insert(out, e)
		end
	end
	table.sort(out, function(a, b)
		local oa = field(a, "order", "Order", "LayoutOrder") or 0
		local ob = field(b, "order", "Order", "LayoutOrder") or 0
		if oa ~= ob then
			return oa < ob
		end
		return tostring(a.name) < tostring(b.name)
	end)
	return out
end
Derived.List = list

function Derived.SpeciesList(): { { [string]: any } }
	local s = list(cfg("Species", "SpeciesData"))
	if #s == 0 then
		return FALLBACK_SPECIES
	end
	return s
end

function Derived.Species(name: string): { [string]: any }
	for _, s in Derived.SpeciesList() do
		if s.name == name then
			return s
		end
	end
	return { name = name, rarity = "Common", baseValue = 0 }
end

function Derived.Rarity(species: string): string
	return field(Derived.Species(species), "rarity", "Rarity") or "Common"
end

function Derived.Mutations(): { { [string]: any } }
	local m = list(cfg("Mutations"))
	local out = {}
	for _, e in m do
		if field(e, "enabled", "Enabled") ~= false then
			table.insert(out, e)
		end
	end
	if #out == 0 then
		return {
			{ name = "Golden", mult = 3 },
			{ name = "Albino", mult = 2.5 },
			{ name = "Crystal", mult = 5 },
			{ name = "Glowing", mult = 2 },
		}
	end
	return out
end

-- Creatures as an array with uid filled in (data.creatures is a uid -> creature map).
function Derived.Creatures(): { { [string]: any } }
	local out = {}
	for k, c in State.Tbl("creatures") do
		if type(c) == "table" then
			local e = table.clone(c)
			e.uid = field(c, "uid", "id", "Uid") or k
			table.insert(out, e)
		end
	end
	return out
end

function Derived.Creature(uid: any): { [string]: any }?
	for _, c in Derived.Creatures() do
		if tostring(c.uid) == tostring(uid) then
			return c
		end
	end
	return nil
end

function Derived.Muts(c: { [string]: any }): { string }
	local m = field(c, "mutations", "Mutations")
	local out = {}
	if type(m) == "table" then
		for k, v in m do
			if type(v) == "string" then
				table.insert(out, v)
			elseif v == true and type(k) == "string" then
				table.insert(out, k)
			end
		end
	elseif type(m) == "string" and m ~= "" then
		table.insert(out, m)
	end
	return out
end

function Derived.Happy(c: { [string]: any }): number
	local v = field(c, "happy", "happiness", "Happy")
	return if type(v) == "number" then v else 100
end

function Derived.Stage(c: { [string]: any }): string
	return tostring(field(c, "stage", "Stage") or "Adult")
end

function Derived.Name(c: { [string]: any }): string
	local n = field(c, "nickname", "name")
	return if type(n) == "string" and n ~= "" then n else tostring(field(c, "species") or "Creature")
end

function Derived.Eggs(): { { [string]: any } }
	local out = {}
	for k, e in State.Tbl("eggs") do
		if type(e) == "table" then
			local x = table.clone(e)
			x.id = field(e, "id", "eggId", "Id") or k
			table.insert(out, x)
		end
	end
	table.sort(out, function(a, b)
		return (tonumber(field(a, "readyAt")) or 0) < (tonumber(field(b, "readyAt")) or 0)
	end)
	return out
end

function Derived.EggLeft(e: { [string]: any }): number
	local ready = tonumber(field(e, "readyAt", "hatchAt"))
	if not ready then
		return 0
	end
	return math.max(0, ready - State.Now())
end

function Derived.XpFor(level: number): number
	local f = cfg("XpForLevel")
	if type(f) == "function" then
		local ok, v = pcall(f, level)
		if ok and type(v) == "number" then
			return v
		end
	end
	return math.floor(100 * level ^ 1.4)
end

function Derived.Level(): (number, number)
	local lvl = math.max(1, State.Num("level"))
	local need = Derived.XpFor(lvl)
	return lvl, math.clamp(State.Num("xp") / math.max(1, need), 0, 1)
end

function Derived.ParkTiers(): { { [string]: any } }
	local t = list(cfg("ParkTiers"))
	return if #t > 0 then t else FALLBACK_TIERS
end

function Derived.ParkTier(rating: number): ({ [string]: any }, { [string]: any }?)
	local tiers = Derived.ParkTiers()
	local cur, nxt = tiers[1], nil
	for i, t in tiers do
		if rating >= (tonumber(field(t, "min", "Min")) or 0) then
			cur, nxt = t, tiers[i + 1]
		end
	end
	return cur, nxt
end

function Derived.HasPass(key: string): boolean
	local passes = State.Tbl("passes")
	return passes[key] == true or table.find(passes, key) ~= nil
end

function Derived.Flag(key: string): any
	return State.Tbl("flags")[key]
end

function Derived.JournalStep(species: string): number
	local v = State.Tbl("journal")[species]
	if type(v) == "table" then
		v = field(v, "step", "Step")
	end
	return if type(v) == "number" then v else 0
end

-- Breeding cost by rarity (spec: 50 / 150 / 400).
function Derived.BreedCost(species: string): number
	local b = cfg("Breeding") or {}
	local costs = field(b, "Cost", "cost", "Costs") or { Common = 50, Uncommon = 150, Rare = 400 }
	return tonumber(costs[Derived.Rarity(species)]) or 50
end

function Derived.BreedMinHappy(): number
	return tonumber(field(cfg("Breeding") or {}, "MinHappiness", "minHappy")) or 50
end

return Derived
