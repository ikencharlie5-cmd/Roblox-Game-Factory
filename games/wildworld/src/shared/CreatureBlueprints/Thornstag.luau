--!strict
-- Thornstag (Rare, curious): tall, proud brick deer on long 3.2 legs with dark hooves.
-- Hero feature: brick antlers (upright + branch + small upright) with leaf-bud cubes. ~31 parts.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {}
local legs: { { any } } = { { "LegFL", -0.9, -1.2 }, { "LegFR", 0.9, -1.2 }, { "LegBL", -0.9, 1.8 }, { "LegBR", 0.9, 1.8 } }
for _, l in legs do
	table.insert(parts, S.Brick(l[1], V(0.8, 3.2, 0.8), V(l[2], 2.0, l[3]), "Primary", l[1]))
	table.insert(parts, S.Brick(l[1] .. "Hoof", V(0.8, 0.4, 0.8), V(l[2], 0.2, l[3]), "Feature", l[1]))
end
-- Body 3x2.8x4.4 (2 slabs) + chest; neck 1.6x2x1.6; head 3x2.8x3 (2 slabs) with a 1.6x1.2x1.2 muzzle.
S.Slab(parts, "Body", 3, 4.4, 0, 3.4, 0.3, { 1.2, 1.6 }, "Primary", "Body", true)
table.insert(parts, S.Brick("Chest", V(2, 2, 0.6), V(0, 4.6, -2.1), "Belly", "Body"))
table.insert(parts, S.Brick("Neck", V(1.6, 2, 1.6), V(0, 6.8, -1.4), "Primary", "Head"))
S.Slab(parts, "Head", 3, 3, 0, 7.4, -2.0, { 1.2, 1.6 }, "Primary", "Head", true)
-- Antlers, per side: upright, outward branch, small upright, leaf bud cubes.
for _, side in { -1, 1 } do
	local tag = if side < 0 then "L" else "R"
	table.insert(parts, S.Brick("Antler" .. tag, V(0.6, 2.4, 0.6), V(side * 1.0, 11.2, -1.6), "Feature", "Head"))
	table.insert(parts, S.Brick("Branch" .. tag, V(1.6, 0.6, 0.6), V(side * 1.5, 11.9, -1.6), "Feature", "Head"))
	table.insert(parts, S.Brick("Fork" .. tag, V(0.6, 1.2, 0.6), V(side * 2.0, 12.8, -1.6), "Feature", "Head"))
	table.insert(parts, S.Brick("Leaf" .. tag .. "1", V(0.6, 0.6, 0.6), V(side * 1.0, 12.7, -1.6), "Accent", "Head"))
	table.insert(parts, S.Brick("Leaf" .. tag .. "2", V(0.6, 0.6, 0.6), V(side * 2.0, 13.7, -1.6), "Glow", "Head"))
end
table.insert(parts, S.Brick("Tail", V(1, 1.2, 0.6), V(0, 5.6, 2.8), "Belly", "Tail"))
table.insert(parts, S.Pattern(S.Brick("Dapples", V(2, 0.4, 2), V(0, 6.4, 0.6), "Secondary", "Body", "Top")))
S.BrickFace(parts, 3, 2.8, 7.4, -3.5, { Muzzle = V(1.6, 1.2, 1.2) })

local bp: S.Blueprint = {
	Species = "Thornstag",
	Palette = {
		Primary = hex("#C89263"),
		Secondary = hex("#F5E3C8"),
		Belly = hex("#F5E3C8"),
		Accent = hex("#5CC04A"),
		Feature = hex("#7A4A2A"),
		Glow = hex("#A8E36A"),
	},
	AltPalette = {
		Primary = hex("#8C8FA8"),
		Secondary = hex("#E8EAF5"),
		Accent = hex("#FF9EC8"),
		Glow = hex("#FFB3D9"),
	},
	HeadPivot = V(0, 6.0, -1.0),
	Parts = parts,
	Shards = {
		S.Shard(V(0, 6.2, -0.4), -10, 0, 0.9),
		S.Shard(V(0, 6.2, 0.8), -10, 0, 1.0),
		S.Shard(V(0, 6.2, 2.0), -10, 0, 0.8),
		S.Shard(V(-1.0, 13.0, -1.6), 0, 15, 0.7, "Head"),
		S.Shard(V(1.0, 13.0, -1.6), 0, -15, 0.7, "Head"),
	},
	EmitterPart = "Head",
	Native = {},
}
return bp
