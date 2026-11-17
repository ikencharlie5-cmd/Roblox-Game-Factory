--!strict
-- Needs check for every creature in a pad (pure; server caches the result, UI may preview it).
local Config = require(script.Parent:WaitForChild("Config"))
local Formulas = require(script.Parent:WaitForChild("Formulas"))

export type NeedResult = {
	biome: boolean,
	decor: boolean,
	buddy: boolean?, -- nil = this species has no buddy need (Commons)
	thriving: boolean,
	herd: boolean,
	sign: boolean,
	met: number,
	total: number,
}

local Needs = {}

-- Returns { [itemId] = NeedResult } for every plant/creature placed on `pad`.
function Needs.ForPad(data: any, pad: number, now: number): { [number]: NeedResult }
	local biome = data.padBiome[pad]
	local decorKinds: { [string]: boolean } = {}
	for _, d in data.decor do
		if d.pad == pad then
			decorKinds[d.kind] = true
		end
	end
	local roles: { [string]: boolean } = {}
	local counts: { [string]: number } = {}
	for _, p in data.placed do
		if p.pad == pad then
			local s = Config.Species.ByName[p.species]
			if s then
				roles[s.Role] = true
				counts[p.species] = (counts[p.species] or 0) + 1
			end
		end
	end
	local out: { [number]: NeedResult } = {}
	for _, p in data.placed do
		if p.pad == pad then
			local s = Config.Species.ByName[p.species]
			if s then
				local bOk = s.Biome == biome
				local dOk = decorKinds[s.Decor] == true
				local buddyOk: boolean? = nil
				local total, met = 2, (if bOk then 1 else 0) + (if dOk then 1 else 0)
				if s.Buddy then
					-- A creature can't be its own buddy: need ANOTHER creature with that role.
					local ok = false
					for _, q in data.placed do
						if q.pad == pad and q.id ~= p.id then
							local qs = Config.Species.ByName[q.species]
							if qs and qs.Role == s.Buddy then
								ok = true
								break
							end
						end
					end
					buddyOk = ok
					total += 1
					met += if ok then 1 else 0
				end
				out[p.id] = {
					biome = bOk,
					decor = dOk,
					buddy = buddyOk,
					thriving = met == total and Formulas.Progress(p, now) >= 1,
					herd = (counts[p.species] or 0) >= Config.Income.HerdSize,
					sign = decorKinds["Info Sign"] == true,
					met = met,
					total = total,
				}
			end
		end
	end
	return out
end

-- $/s for one creature before player multipliers (0 while growing).
function Needs.CreatureIncome(item: any, r: NeedResult?, now: number): number
	if Formulas.Progress(item, now) < 1 then
		return 0
	end
	local v = Formulas.CreatureBase(item)
	if r then
		if r.thriving then
			v *= Config.Income.Thriving
		end
		if r.herd then
			v *= Config.Income.Herd
		end
		if r.sign then
			v *= Config.Income.InfoSign
		end
	end
	return v
end

return Needs
