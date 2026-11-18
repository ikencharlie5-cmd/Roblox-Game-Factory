--!strict
-- Mossback (Common, lazy): wide, low, slow. Hero feature: mossy hump with little flowers.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {
	S.Shadow(S.Blob("Body", V(3.6, 2.4, 4.4), V(0, 1.6, 0.4), "Primary", "Body")),
	S.Blob("Belly", V(3.0, 1.2, 3.6), V(0, 1.0, 0.2), "Belly", "Body"),
	S.Shadow(S.Ball("Head", 2.6, V(0, 2.4, -2.0), "Primary", "Head")),
	S.Blob("Snout", V(1.6, 1.0, 1.1), V(0, 1.95, -3.1), "Secondary", "Head"),
	S.Leg("LegFL", 1.2, 1.0, V(-1.3, 0.6, -0.8), "Primary", "LegFL"),
	S.Leg("LegFR", 1.2, 1.0, V(1.3, 0.6, -0.8), "Primary", "LegFR"),
	S.Leg("LegBL", 1.2, 1.0, V(-1.3, 0.6, 1.6), "Primary", "LegBL"),
	S.Leg("LegBR", 1.2, 1.0, V(1.3, 0.6, 1.6), "Primary", "LegBR"),
	S.Ball("Tail", 0.7, V(0, 1.4, 2.7), "Primary", "Tail"),
	S.Ball("MossA", 2.4, V(0, 2.9, 0.4), "Feature", "Body"),
	S.Ball("MossB", 1.8, V(0.9, 2.7, 1.2), "Feature", "Body"),
	S.Ball("MossC", 1.8, V(-0.9, 2.75, -0.2), "Feature", "Body"),
	S.Ball("MossD", 1.5, V(0.85, 2.6, -0.5), "Feature", "Body"),
	S.Ball("MossE", 1.6, V(-0.8, 2.6, 1.4), "Feature", "Body"),
	S.Ball("FlowerA", 0.55, V(0.5, 4.05, 0.2), "Glow", "Body"),
	S.Ball("FlowerB", 0.5, V(-0.65, 3.6, 1.1), "Glow", "Body"),
	S.Pattern(S.Blob("SpotA", V(0.9, 0.7, 0.2), CFrame.new(1.75, 1.6, 0.9) * CFrame.Angles(0, math.rad(90), 0), "Accent", "Body")),
	S.Pattern(S.Blob("SpotB", V(0.9, 0.7, 0.2), CFrame.new(-1.75, 1.6, 0.9) * CFrame.Angles(0, math.rad(90), 0), "Accent", "Body")),
}
S.Face(parts, 0.65, 2.6, -3.05, 0.55, true)

local bp: S.Blueprint = {
	Species = "Mossback",
	Palette = {
		Primary = hex("#8C6A4F"),
		Secondary = hex("#F2D6B3"),
		Belly = hex("#F2D6B3"),
		Accent = hex("#6E5240"),
		Feature = hex("#6CC644"),
		Glow = hex("#FF8FB8"),
	},
	AltPalette = {
		Primary = hex("#6F7C8C"),
		Secondary = hex("#DDE4EC"),
		Feature = hex("#3FAF8A"),
		Glow = hex("#FFE27A"),
	},
	HeadPivot = V(0, 2.0, -1.0),
	Parts = parts,
	Shards = {
		S.Shard(V(0, 3.8, 0.4), 0, 0, 1.8),
		S.Shard(V(0.9, 3.4, 1.2), -15, -20, 1.3),
		S.Shard(V(-0.9, 3.4, -0.2), 15, 20, 1.3),
		S.Shard(V(-0.8, 3.2, 1.4), -10, 25, 1.1),
		S.Shard(V(0.85, 3.2, -0.5), 10, -25, 1.0),
	},
	EmitterPart = "MossA",
	Native = {},
}
return bp
