--!strict
-- Lumibun (Common, shy): tiny round bun. Hero feature: long ears with glowing tips.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {
	S.Shadow(S.Ball("Body", 1.7, V(0, 0.95, 0.25), "Primary", "Body")),
	S.Blob("Belly", V(1.15, 1.1, 0.45), V(0, 0.85, -0.45), "Belly", "Body"),
	S.Shadow(S.Ball("Head", 1.95, V(0, 2.25, -0.3), "Primary", "Head")),
	S.Blob("FootL", V(0.6, 0.4, 0.9), V(-0.45, 0.2, -0.35), "Secondary", "LegFL"),
	S.Blob("FootR", V(0.6, 0.4, 0.9), V(0.45, 0.2, -0.35), "Secondary", "LegFR"),
	S.Ball("Tail", 0.75, V(0, 1.0, 1.1), "Secondary", "Tail"),
	S.Blob("EarL", V(0.5, 2.4, 0.28), CFrame.new(-0.42, 3.75, -0.15) * CFrame.Angles(0, 0, math.rad(12)), "Primary", "EarL"),
	S.Blob("EarR", V(0.5, 2.4, 0.28), CFrame.new(0.42, 3.75, -0.15) * CFrame.Angles(0, 0, math.rad(-12)), "Primary", "EarR"),
	S.Blob("EarInL", V(0.3, 1.7, 0.1), CFrame.new(-0.42, 3.6, -0.3) * CFrame.Angles(0, 0, math.rad(12)), "Secondary", "EarL"),
	S.Blob("EarInR", V(0.3, 1.7, 0.1), CFrame.new(0.42, 3.6, -0.3) * CFrame.Angles(0, 0, math.rad(-12)), "Secondary", "EarR"),
	S.Blob("EarTipL", V(0.46, 0.62, 0.3), CFrame.new(-0.67, 4.8, -0.15) * CFrame.Angles(0, 0, math.rad(12)), "Glow", "EarL"),
	S.Blob("EarTipR", V(0.46, 0.62, 0.3), CFrame.new(0.67, 4.8, -0.15) * CFrame.Angles(0, 0, math.rad(-12)), "Glow", "EarR"),
	S.Ball("Nose", 0.2, V(0, 2.0, -1.25), "Cheek", "Head"),
	S.Pattern(S.Blob("SpotA", V(0.6, 0.5, 0.2), CFrame.new(0.45, 1.25, 0.95) * CFrame.Angles(0, math.rad(-30), 0), "Accent", "Body")),
	S.Pattern(S.Blob("SpotB", V(0.45, 0.4, 0.2), CFrame.new(-0.5, 1.45, 0.85) * CFrame.Angles(0, math.rad(30), 0), "Accent", "Body")),
}
S.Face(parts, 0.42, 2.05, -1.12, 0.5, true)

local bp: S.Blueprint = {
	Species = "Lumibun",
	Palette = {
		Primary = hex("#F7F1FF"),
		Secondary = hex("#FFC8E0"),
		Belly = hex("#FFFFFF"),
		Accent = hex("#D9C6F5"),
		Feature = hex("#F7F1FF"),
		Glow = hex("#9FE8FF"),
	},
	AltPalette = {
		Primary = hex("#D9B48C"),
		Secondary = hex("#FFE3C2"),
		Accent = hex("#A87C55"),
		Glow = hex("#FFE27A"),
	},
	HeadPivot = V(0, 1.55, -0.2),
	Parts = parts,
	Shards = {
		S.Shard(V(-0.5, 1.6, 0.6), -20, 15, 0.9),
		S.Shard(V(0.5, 1.6, 0.7), -20, -15, 0.8),
		S.Shard(V(0, 1.75, 0.8), -30, 0, 1.1),
		S.Shard(V(-0.35, 3.4, 0.0), 0, 0, 0.7, "Head"),
	},
	EmitterPart = "EarTipR",
	Native = { NightLight = 5 },
}
return bp
