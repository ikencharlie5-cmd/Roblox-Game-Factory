--!strict
-- Read-only helpers that turn the synced data into display values (uses Shared Formulas/Needs).
-- Never decides outcomes: the server re-checks everything.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Formulas = require(Shared:WaitForChild("Formulas")) :: any
local Needs = require(Shared:WaitForChild("Needs")) :: any
local State = require(script.Parent:WaitForChild("State"))

local Derived = {}
Derived.Config = Config
Derived.Formulas = Formulas

local player = Players.LocalPlayer :: Player

function Derived.Species(name: any): any
	if type(name) ~= "string" then
		return nil
	end
	return Config.Species.ByName[name]
end

-- Game pass ownership as reported by the server (data.passes or player Attributes).
function Derived.HasPass(key: string): boolean
	local passes = State.Tbl("passes")
	if passes[key] then
		return true
	end
	return player:GetAttribute(key) == true or player:GetAttribute("Pass_" .. key) == true
end

-- Returns stage name, 0..1 progress, seconds left.
function Derived.Stage(item: any): (string, number, number)
	local now = State.Now()
	local p = Formulas.Progress(item, now)
	local left = math.max(0, Formulas.ReadyAt(item) - now)
	return Formulas.Stage(p), p, if p >= 1 then 0 else left
end

local function safeData(): any
	local d = State.data
	if type(d.placed) ~= "table" or type(d.decor) ~= "table" or type(d.padBiome) ~= "table" then
		return nil
	end
	return d
end

function Derived.NeedsFor(item: any): any
	if type(item.needs) == "table" then
		return item.needs
	end
	local d = safeData()
	if not d then
		return nil
	end
	local ok, res = pcall(Needs.ForPad, d, item.pad, State.Now())
	return if ok and res then res[item.id] else nil
end

function Derived.PlayerMult(): number
	local d = State.data
	local ok, m = pcall(Formulas.PlayerMult, d, Derived.HasPass("VIP"), Derived.HasPass("DoubleCash"))
	return if ok then m else 1
end

-- $/s. Prefers a server-sent value; otherwise previews it from Shared Needs.
function Derived.Income(): number
	local attr = player:GetAttribute("IncomePerSec")
	if type(attr) == "number" then
		return attr
	end
	local d = safeData()
	if not d then
		return 0
	end
	local now = State.Now()
	local total = 0
	local pads: { [number]: any } = {}
	for _, item in d.placed do
		local pad = item.pad
		if not pads[pad] then
			local ok, res = pcall(Needs.ForPad, d, pad, now)
			pads[pad] = if ok then res else {}
		end
		local ok, v = pcall(Needs.CreatureIncome, item, pads[pad][item.id], now)
		if ok then
			total += v
		end
	end
	return total * Derived.PlayerMult()
end

function Derived.CreatureIncome(item: any): number
	local ok, v = pcall(Needs.CreatureIncome, item, Derived.NeedsFor(item), State.Now())
	return if ok then v * Derived.PlayerMult() else 0
end

function Derived.Luck(): number
	local v = player:GetAttribute("Luck")
	if type(v) == "number" then
		return v
	end
	local ok, l = pcall(Formulas.Luck, State.data, Derived.HasPass("SuperLuck"), State.Now())
	return if ok then l else 1
end

function Derived.LuckPotionLeft(): number
	return math.max(0, (State.Tbl("potions").luckUntil or 0) - State.Now())
end

-- Release #n requirement: (n, cash, minRarity)
function Derived.ReleaseInfo(): (number, number, string)
	local n = State.Num("releases") + 1
	return n, Formulas.ReleaseCash(n), Config.ReleaseMinRarity(n)
end

-- Next pad to buy: (index, price) or nil when all 9 are owned.
function Derived.NextPad(): (number?, number?)
	local owned = math.max(1, State.Num("padsOwned"))
	local nextIdx = owned + 1
	local price = Config.PadCosts[nextIdx]
	if not price then
		return nil, nil
	end
	return nextIdx, price
end

function Derived.ItemAt(pad: number, cell: number): (any, string?)
	for _, item in State.Tbl("placed") do
		if item.pad == pad and item.cell == cell then
			return item, "creature"
		end
	end
	for _, item in State.Tbl("decor") do
		if item.pad == pad and item.cell == cell then
			return item, "decor"
		end
	end
	return nil, nil
end

function Derived.FindPlaced(id: any): any
	for _, item in State.Tbl("placed") do
		if item.id == id or tostring(item.id) == tostring(id) then
			return item
		end
	end
	return nil
end

-- Every creature the player owns: { item, placed: boolean }
function Derived.AllCreatures(): { { item: any, placed: boolean } }
	local out = {}
	for _, item in State.Tbl("placed") do
		table.insert(out, { item = item, placed = true })
	end
	for _, item in State.Tbl("creatures", State.Tbl("inventory")) do
		table.insert(out, { item = item, placed = false })
	end
	return out
end

function Derived.Mutations(item: any): string
	local parts = {}
	if type(item.color) == "string" and item.color ~= "" then
		table.insert(parts, item.color)
	end
	if type(item.weather) == "string" and item.weather ~= "" then
		table.insert(parts, item.weather)
	end
	return table.concat(parts, " ")
end

function Derived.DisplayName(item: any): string
	local m = Derived.Mutations(item)
	return if m ~= "" then m .. " " .. tostring(item.species) else tostring(item.species)
end

function Derived.SellValue(item: any): number
	local ok, v = pcall(Formulas.SellValue, item)
	return if ok then v else 0
end

function Derived.Day(): number
	return Formulas.Day(math.floor(State.Now()))
end

return Derived
