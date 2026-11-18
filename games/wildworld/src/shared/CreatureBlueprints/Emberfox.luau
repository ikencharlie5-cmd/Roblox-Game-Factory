--!strict
-- Emberfox (Common, playful) -> the inspo orange brick fox: white chest + muzzle, dark socks and ear tips.
-- Hero feature: a tail of bricks stepping up and back, white tip + glowing ember cube (embers emitter). ~30 parts.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {}
-- Legs 0.8x1.2x0.8 on dark 0.4 socks.
local legs: { { any } } = { { "LegFL", -0.6, -1.2 }, { "LegFR", 0.6, -1.2 }, { "LegBL", -0.6, 1.6 }, { "LegBR", 0.6, 1.6 } }
for _, l in legs do
	table.insert(parts, S.Brick(l[1], V(0.8, 1.2, 0.8), V(l[2], 1.0, l[3]), "Primary", l[1]))
	table.insert(parts, S.Brick(l[1] .. "Sock", V(0.8, 0.4, 0.8), V(l[2], 0.2, l[3]), "Accent", l[1]))
end
-- Body 2x2.4x4 (2 slabs) + white chest block; head 3x2.8x3 overlapping the body front by 0.4.
S.Slab(parts, "Body", 2, 4, 0, 1.4, 0.3, { 1.2, 1.2 }, "Primary", "Body", true)
table.insert(parts, S.Brick("Chest", V(2, 1.6, 0.6), V(0, 2.6, -1.9), "Belly", "Body"))
S.Slab(parts, "Head", 3, 3, 0, 3.4, -1.6, { 1.2, 1.2, 0.4 }, "Primary", "Head", true)
-- Ears: brick base + dark slope tip (triangle silhouette).
for _, side in { -1, 1 } do
	local tag = if side < 0 then "L" else "R"
	local x = side * 1.0
	table.insert(parts, S.Brick("Ear" .. tag, V(1, 1.2, 0.6), V(x, 6.6, -1.2), "Primary", "Ear" .. tag))
	local tip = CFrame.new(x, 7.6, -1.2) * CFrame.Angles(0, math.rad(side * 90), 0)
	table.insert(parts, S.Wedge("EarTip" .. tag, V(0.6, 0.8, 1), tip, "Accent", "Ear" .. tag))
end
-- Tail: 3 bricks stepping up and back, white tip, glow cube on top.
table.insert(parts, S.Brick("Tail", V(1, 1.2, 1.6), V(0, 3.2, 3.0), "Primary", "Tail"))
table.insert(parts, S.Brick("Tail2", V(1.4, 1.2, 1.6), V(0, 4.2, 4.4), "Primary", "Tail"))
table.insert(parts, S.Brick("TailTip", V(1.2, 1.2, 1.2), V(0, 5.2, 5.6), "Belly", "Tail"))
table.insert(parts, S.Brick("TailGlow", V(0.8, 0.8, 0.8), V(0, 6.2, 5.6), "Glow", "Tail"))
-- Pattern (pp): dark back stripes.
table.insert(parts, S.Pattern(S.Brick("StripeA", V(2, 0.4, 0.6), V(0, 4.0, 0.6), "Accent", "Body", "Top")))
table.insert(parts, S.Pattern(S.Brick("StripeB", V(2, 0.4, 0.6), V(0, 4.0, 1.6), "Accent", "Body", "Top")))
S.BrickFace(parts, 3, 2.8, 3.4, -3.1, { Muzzle = V(1.6, 1.2, 1) })

local bp: S.Blueprint = {
	Species = "Emberfox",
	Palette = {
		Primary = hex("#F5862A"),
		Secondary = hex("#FFF4E6"),
		Belly = hex("#FFF4E6"),
		Accent = hex("#4A2E22"),
		Feature = hex("#F5862A"),
		Glow = hex("#FFC84A"),
	},
	AltPalette = {
		Primary = hex("#E8D9C8"),
		Accent = hex("#6B5A70"),
		Glow = hex("#9FE8FF"),
	},
	HeadPivot = V(0, 3.6, -1.4),
	Parts = parts,
	Shards = {
		S.Shard(V(0, 3.8, 0.2), -10, 0, 0.8),
		S.Shard(V(0, 3.8, 1.4), -10, 0, 0.7),
		S.Shard(V(0, 4.8, 4.4), 10, 0, 0.6, "Tail"),
	},
	EmitterPart = "TailGlow",
	Native = { Emitter = "Embers" },
}
return bp
