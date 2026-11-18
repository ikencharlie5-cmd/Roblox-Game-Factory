--!strict
-- Mossback (Common, lazy): wide, low brick tortoise with the inspo frog's green / pale-belly scheme.
-- Hero feature: a ziggurat moss hump (4x4 -> 3x3 -> 2x2) dotted with flower studs. ~25 parts.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {}
local legs: { { any } } = { { "LegFL", -1.4, -1.4 }, { "LegFR", 1.4, -1.4 }, { "LegBL", -1.4, 2.2 }, { "LegBR", 1.4, 2.2 } }
for _, l in legs do
	table.insert(parts, S.Brick(l[1], V(1.2, 1.2, 1.2), V(l[2], 0.6, l[3]), "Accent", l[1]))
end
-- Body 4x2x5 (1.2 + 0.8) on a pale underside plate.
table.insert(parts, S.Brick("Underside", V(4, 0.4, 5), V(0, 0.8, 0.4), "Belly", "Body", "Top"))
S.Slab(parts, "Body", 4, 5, 0, 1.0, 0.4, { 1.2, 0.8 }, "Primary", "Body", true)
-- Moss hump ziggurat (alternate ×0.95 shade via Layer).
local hump = { { 4, 1.2, 3.6 }, { 3, 0.8, 4.6 }, { 2, 0.8, 5.4 } }
for i, h in hump do
	local spec = S.Brick(if i == 1 then "MossA" elseif i == 2 then "MossB" else "MossTop", V(h[1], h[2], h[1]), V(0, h[3], 0.8), "Feature", "Body")
	spec.Layer = i
	spec.Shadow = i == 1
	table.insert(parts, spec)
end
-- Flower studs on the hump steps.
table.insert(parts, S.Brick("FlowerA", V(0.6, 0.6, 0.6), V(-1.6, 4.5, -0.8), "Glow", "Body"))
table.insert(parts, S.Brick("FlowerB", V(0.6, 0.6, 0.6), V(1.1, 5.3, 1.9), "Glow", "Body"))
table.insert(parts, S.Brick("FlowerC", V(0.6, 0.6, 0.6), V(0.4, 6.1, 0.4), "Secondary", "Body"))
-- Head 3x2.4x3, low at the front (top = body top + 0.4).
S.Slab(parts, "Head", 3, 3, 0, 1.0, -3.0, { 1.2, 1.2 }, "Primary", "Head", true)
table.insert(parts, S.Brick("Tail", V(0.8, 0.8, 0.8), V(0, 1.6, 3.3), "Primary", "Tail"))
table.insert(parts, S.Pattern(S.Tile("SpotA", V(0.1, 0.8, 1.2), V(2.05, 2.0, 0.0), "Accent", "Body")))
table.insert(parts, S.Pattern(S.Tile("SpotB", V(0.1, 0.8, 1.2), V(-2.05, 2.0, 1.4), "Accent", "Body")))
S.BrickFace(parts, 3, 2.4, 1.0, -4.5, { Muzzle = V(1.6, 0.8, 0.6) })

local bp: S.Blueprint = {
	Species = "Mossback",
	Palette = {
		Primary = hex("#A87C55"),
		Secondary = hex("#F5CD30"),
		Belly = hex("#F2D6B3"),
		Accent = hex("#7A5A40"),
		Feature = hex("#6FC24A"),
		Glow = hex("#FF8FB8"),
	},
	AltPalette = {
		Primary = hex("#7C8898"),
		Feature = hex("#3FAF8A"),
		Glow = hex("#FFE27A"),
	},
	HeadPivot = V(0, 2.2, -1.6),
	Parts = parts,
	Shards = {
		S.Shard(V(0, 5.8, 0.8), 0, 0, 1.2),
		S.Shard(V(1.6, 4.2, -0.8), -10, -15, 0.9),
		S.Shard(V(-1.6, 4.2, 2.4), 10, 15, 0.9),
		S.Shard(V(-1.6, 4.2, -0.8), -10, 15, 0.8),
		S.Shard(V(1.6, 4.2, 2.4), 10, -15, 0.8),
	},
	EmitterPart = "MossTop",
	Native = {},
}
return bp
