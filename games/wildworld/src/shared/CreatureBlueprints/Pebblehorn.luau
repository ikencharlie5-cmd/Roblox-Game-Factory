--!strict
-- Pebblehorn (Uncommon, social): chunky and sturdy. Hero feature: stacked rock horn on the nose + back plates.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {
	S.Shadow(S.Blob("Body", V(3.2, 2.8, 3.6), V(0, 1.9, 0.3), "Primary", "Body")),
	S.Blob("Belly", V(2.4, 1.8, 2.4), V(0, 1.5, -0.45), "Belly", "Body"),
	S.Shadow(S.Blob("Head", V(2.8, 1.9, 2.3), V(0, 2.4, -1.9), "Primary", "Head")),
	S.Ball("HornA", 1.05, V(0, 2.65, -3.0), "Feature", "Head"),
	S.Ball("HornB", 0.78, V(0, 3.2, -3.15), "Feature", "Head"),
	S.Ball("HornC", 0.52, V(0, 3.65, -3.22), "Feature", "Head"),
	S.Wedge("PlateA", V(0.45, 1.0, 1.2), CFrame.new(0, 3.45, -0.5), "Accent", "Body"),
	S.Wedge("PlateB", V(0.45, 1.15, 1.25), CFrame.new(0, 3.55, 0.45), "Accent", "Body"),
	S.Wedge("PlateC", V(0.45, 0.9, 1.1), CFrame.new(0, 3.3, 1.35), "Accent", "Body"),
	S.Leg("LegFL", 1.0, 1.1, V(-1.0, 0.5, -0.7), "Primary", "LegFL"),
	S.Leg("LegFR", 1.0, 1.1, V(1.0, 0.5, -0.7), "Primary", "LegFR"),
	S.Leg("LegBL", 1.0, 1.1, V(-1.0, 0.5, 1.2), "Primary", "LegBL"),
	S.Leg("LegBR", 1.0, 1.1, V(1.0, 0.5, 1.2), "Primary", "LegBR"),
	S.Ball("Tail", 0.6, V(0, 1.8, 2.1), "Primary", "Tail"),
	S.Ball("GemL", 0.5, V(-1.55, 2.2, 0.3), "Glow", "Body"),
	S.Ball("GemR", 0.5, V(1.55, 2.2, 0.3), "Glow", "Body"),
	S.Pattern(S.Blob("SpotA", V(0.8, 0.6, 0.2), CFrame.new(1.45, 1.4, 1.2) * CFrame.Angles(0, math.rad(80), 0), "Secondary", "Body")),
	S.Pattern(S.Blob("SpotB", V(0.8, 0.6, 0.2), CFrame.new(-1.45, 1.4, 1.2) * CFrame.Angles(0, math.rad(80), 0), "Secondary", "Body")),
}
S.Face(parts, 0.75, 2.5, -2.85, 0.48, true)

local bp: S.Blueprint = {
	Species = "Pebblehorn",
	Palette = {
		Primary = hex("#7E8799"),
		Secondary = hex("#C9CFDB"),
		Belly = hex("#C9CFDB"),
		Accent = hex("#5FD3C4"),
		Feature = hex("#B8BFCC"),
		Glow = hex("#5FD3C4"),
	},
	AltPalette = {
		Primary = hex("#A0785A"),
		Secondary = hex("#E6CBA8"),
		Accent = hex("#FF9E6B"),
		Feature = hex("#D8B48A"),
		Glow = hex("#FF9E6B"),
	},
	HeadPivot = V(0, 2.3, -1.0),
	Parts = parts,
	Shards = {
		S.Shard(V(-0.8, 3.4, 0.2), 0, 25, 1.2),
		S.Shard(V(0.8, 3.4, 0.6), 0, -25, 1.2),
		S.Shard(V(0, 3.9, 0.0), -10, 0, 1.5),
		S.Shard(V(0, 4.0, -3.25), 0, 0, 0.8, "Head"),
	},
	EmitterPart = "Body",
	Native = {},
}
return bp
