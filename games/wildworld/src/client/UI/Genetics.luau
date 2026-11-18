--!strict
-- Display-only genetics helpers: parse "Cc|Pp|Ss|Gg", describe expressed traits, and compute
-- Mendelian offspring odds for the Breeding panel. The server rolls the real result.
local Derived = require(script.Parent:WaitForChild("Derived"))

local Genetics = {}

export type GeneDef = { key: string, label: string, dom: string, rec: string, mixed: string? }

-- Order matches the genes string. Config.Genes (array of {key,label,dom,rec,mixed}) wins if present.
local FALLBACK: { GeneDef } = {
	{ key = "C", label = "Colour", dom = "Natural", rec = "Alt colour" },
	{ key = "P", label = "Pattern", dom = "Plain", rec = "Spots" },
	{ key = "S", label = "Size", dom = "Full size", rec = "Small (x0.85)", mixed = "Medium (x0.95)" },
	{ key = "G", label = "Glow", dom = "No glow", rec = "Glow marks" },
}

function Genetics.Defs(): { GeneDef }
	local g = Derived.Cfg("Genes")
	if type(g) == "table" and #g > 0 and type(g[1]) == "table" and g[1].key then
		return g :: any
	end
	return FALLBACK
end

-- "Cc|Pp|Ss|Gg" -> { {"C","c"}, ... }. Unknown/hidden -> nil.
function Genetics.Parse(genes: any): { { string } }?
	if type(genes) ~= "string" or genes == "" then
		return nil
	end
	local out = {}
	for pair in string.gmatch(genes, "[^|]+") do
		table.insert(out, { string.sub(pair, 1, 1), string.sub(pair, 2, 2) })
	end
	return out
end

local function isDom(a: string): boolean
	return a ~= "" and string.upper(a) == a
end
Genetics.IsDominant = isDom

-- Expressed trait text for an allele pair.
function Genetics.Express(def: GeneDef, pair: { string }): string
	local d1, d2 = isDom(pair[1]), isDom(pair[2])
	if d1 and d2 then
		return def.dom
	elseif d1 or d2 then
		return def.mixed or def.dom
	end
	return def.rec
end

-- Are this creature's genes visible to the player? (bred once, scanned, or bred in the park)
function Genetics.Known(c: { [string]: any }): boolean
	-- Gameplay: genes are known when the creature has bred once or was scanned.
	return c.scanned == true or (tonumber(c.bred) or 0) > 0
end

-- Offspring outcome odds for one gene: { {text, pct} } sorted by pct desc.
function Genetics.Odds(def: GeneDef, a: { string }, b: { string }): { { any } }
	local tally: { [string]: number } = {}
	for _, x in a do
		for _, y in b do
			local t = Genetics.Express(def, { x, y })
			tally[t] = (tally[t] or 0) + 25
		end
	end
	local out = {}
	for t, p in tally do
		table.insert(out, { t, p })
	end
	table.sort(out, function(p, q)
		return p[2] > q[2]
	end)
	return out
end

return Genetics
