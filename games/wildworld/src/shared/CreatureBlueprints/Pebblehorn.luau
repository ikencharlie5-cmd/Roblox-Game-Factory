--!strict
-- Pebblehorn (Uncommon, social) -> the inspo grey-blue brick elephant: 4x4-class head, flat ear flaps
-- with pink inner tiles. Hero feature: a stacked horn on the nose (1.2 -> 0.8 -> 0.6) + teal back plates. ~29 parts.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {}
local legs: { { any } } = { { "LegFL", -1.2, -1.2 }, { "LegFR", 1.2, -1.2 }, { "LegBL", -1.2, 2.2 }, { "LegBR", 1.2, 2.2 } }
for _, l in legs do
	table.insert(parts, S.Brick(l[1], V(1.6, 2, 1.6), V(l[2], 1.0, l[3]), "Primary", l[1]))
end
-- Body 4x3.2x5 (3 slabs), head 4x3.6x4 (3 slabs) on the body front.
S.Slab(parts, "Body", 4, 5, 0, 1.8, 0.5, { 1.2, 1.2, 0.8 }, "Primary", "Body", true)
S.Slab(parts, "Head", 4, 4, 0, 3.0, -3.6, { 1.2, 1.2, 1.2 }, "Primary", "Head", true)
-- Ear flaps beside the head, facing forward, pink inner tile.
for _, side in { -1, 1 } do
	local tag = if side < 0 then "L" else "R"
	local cf = CFrame.new(side * 3.2, 5.0, -3.0) * CFrame.Angles(0, math.rad(side * -10), 0)
	table.insert(parts, S.Brick("Ear" .. tag, V(2.4, 2.4, 0.4), cf, "Primary", "Ear" .. tag))
	table.insert(parts, S.Tile("EarIn" .. tag, V(1.6, 1.6, 0.1), cf * CFrame.new(0, 0, -0.25), "Secondary", "Ear" .. tag))
end
-- Horn stack: up and forward from the muzzle.
table.insert(parts, S.Brick("Horn1", V(1.2, 1.2, 1.2), V(0, 4.8, -5.8), "Feature", "Head"))
table.insert(parts, S.Brick("Horn2", V(0.8, 0.8, 0.8), V(0, 5.8, -6.2), "Feature", "Head"))
table.insert(parts, S.Brick("Horn3", V(0.6, 0.6, 0.6), V(0, 6.5, -6.5), "Glow", "Head"))
-- Back plates along the spine, rotated 45°.
for i, z in { 0.2, 1.4, 2.6 } do
	local cf = CFrame.new(0, 5.6, z) * CFrame.Angles(0, math.rad(45), 0)
	table.insert(parts, S.Brick("Plate" .. i, V(1.2, 1.2, 1.2), cf, "Accent", "Body"))
end
table.insert(parts, S.Brick("Tail", V(0.6, 1.6, 0.6), V(0, 3.6, 3.3), "Primary", "Tail"))
table.insert(parts, S.Pattern(S.Tile("SpotA", V(0.1, 1.2, 1.2), V(2.05, 3.4, 0.4), "Accent", "Body")))
table.insert(parts, S.Pattern(S.Tile("SpotB", V(0.1, 1.2, 1.2), V(-2.05, 3.0, 1.8), "Accent", "Body")))
S.BrickFace(parts, 4, 3.6, 3.0, -5.6)

local bp: S.Blueprint = {
	Species = "Pebblehorn",
	Palette = {
		Primary = hex("#9FAED0"),
		Secondary = hex("#FFB7CE"),
		Belly = hex("#DDE4F0"),
		Accent = hex("#5FD3C4"),
		Feature = hex("#E8ECF4"),
		Glow = hex("#5FD3C4"),
	},
	AltPalette = {
		Primary = hex("#A0785A"),
		Belly = hex("#E6CBA8"),
		Accent = hex("#FF9E6B"),
		Feature = hex("#D8B48A"),
		Glow = hex("#FF9E6B"),
	},
	HeadPivot = V(0, 4.4, -1.8),
	Parts = parts,
	Shards = {
		S.Shard(V(-1.4, 5.0, 1.0), 0, 15, 1.1),
		S.Shard(V(1.4, 5.0, 2.0), 0, -15, 1.1),
		S.Shard(V(1.4, 5.0, -0.8), 0, -15, 0.9),
		S.Shard(V(-1.2, 6.6, -3.0), 0, 10, 0.8, "Head"),
	},
	EmitterPart = "Horn1",
	Native = {},
}
return bp
