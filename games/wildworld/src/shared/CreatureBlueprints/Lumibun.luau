--!strict
-- Lumibun (Common, shy) -> the inspo white brick bunny. 3x3 BrickHeadz head on a 3x3 body, stubby feet.
-- Hero feature: tall brick ears with glowing tips (night light). ~23 parts.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {}
-- Body 3x2.4x3 (2 slabs), head 3x3.2x3 (1.2/1.2/0.8) with a 0.4 overlap, top at y 5.6.
S.Slab(parts, "Body", 3, 3, 0, 0.4, 0.3, { 1.2, 1.2 }, "Primary", "Body", true)
S.Slab(parts, "Head", 3, 3, 0, 2.4, 0, { 1.2, 1.2, 0.8 }, "Primary", "Head", true)
table.insert(parts, S.Tile("Belly", V(2, 1.6, 0.1), V(0, 1.6, -1.25), "Belly", "Body"))
-- Feet poke 0.6 forward of the body.
table.insert(parts, S.Brick("FootL", V(1, 0.8, 1.6), V(-0.9, 0.4, -1.0), "Secondary", "LegFL"))
table.insert(parts, S.Brick("FootR", V(1, 0.8, 1.6), V(0.9, 0.4, -1.0), "Secondary", "LegFR"))
-- Ears 1x3.2x0.6 tilted ±8°, pink inner tile, glow tip brick.
for _, side in { -1, 1 } do
	local tag = if side < 0 then "L" else "R"
	local base = CFrame.new(side * 0.8, 5.4, 0.2) * CFrame.Angles(0, 0, math.rad(-side * 8))
	table.insert(parts, S.Brick("Ear" .. tag, V(1, 3.2, 0.6), base * CFrame.new(0, 1.6, 0), "Primary", "Ear" .. tag))
	table.insert(parts, S.Tile("EarIn" .. tag, V(0.6, 2.4, 0.1), base * CFrame.new(0, 1.5, -0.35), "Secondary", "Ear" .. tag))
	table.insert(parts, S.Brick("EarTip" .. tag, V(1, 0.8, 0.6), base * CFrame.new(0, 3.6, 0), "Glow", "Ear" .. tag))
end
table.insert(parts, S.Brick("Tail", V(1, 1, 1), V(0, 1.4, 2.3), "Secondary", "Tail"))
table.insert(parts, S.Pattern(S.Tile("SpotA", V(0.1, 1, 1.2), V(1.55, 1.8, 0.8), "Accent", "Body")))
table.insert(parts, S.Pattern(S.Tile("SpotB", V(0.1, 0.8, 0.8), V(-1.55, 1.2, 0.4), "Accent", "Body")))
S.BrickFace(parts, 3, 3.2, 2.4, -1.5, { NoseRole = "Cheek" })

local bp: S.Blueprint = {
	Species = "Lumibun",
	Palette = {
		Primary = hex("#F4F5F7"),
		Secondary = hex("#FFB7CE"),
		Belly = hex("#FFFFFF"),
		Accent = hex("#D9C6F5"),
		Feature = hex("#F4F5F7"),
		Glow = hex("#9FE8FF"),
	},
	AltPalette = {
		Primary = hex("#D9B48C"),
		Secondary = hex("#FFE3C2"),
		Accent = hex("#A87C55"),
		Glow = hex("#FFE27A"),
	},
	HeadPivot = V(0, 2.6, 0),
	Parts = parts,
	Shards = {
		S.Shard(V(-1.1, 2.8, 1.5), -10, 10, 0.7),
		S.Shard(V(1.1, 2.8, 1.5), -10, -10, 0.7),
		S.Shard(V(0, 1.9, 2.3), 0, 0, 0.6, "Tail"),
		S.Shard(V(0, 5.6, 0.8), 0, 0, 0.7, "Head"),
	},
	EmitterPart = "EarTipR",
	Native = { NightLight = 6 },
}
return bp
