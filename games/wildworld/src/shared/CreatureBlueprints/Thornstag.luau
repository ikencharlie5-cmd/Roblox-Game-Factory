--!strict
-- Thornstag (Rare, curious): tall and proud. Hero feature: branch antlers with leaf buds.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {
	S.Shadow(S.Blob("Body", V(1.7, 1.8, 3.2), V(0, 2.8, 0.3), "Primary", "Body")),
	S.Blob("Belly", V(1.3, 1.0, 2.2), V(0, 2.4, 0.2), "Belly", "Body"),
	S.Stick("Neck", V(0, 3.2, -0.8), V(0, 4.5, -1.5), 0.8, "Primary", "Head"),
	S.Shadow(S.Ball("Head", 1.55, V(0, 4.8, -1.6), "Primary", "Head")),
	S.Blob("Snout", V(0.8, 0.7, 0.95), V(0, 4.55, -2.3), "Secondary", "Head"),
	S.Blob("EarL", V(0.75, 0.35, 0.3), CFrame.new(-0.85, 5.0, -1.4) * CFrame.Angles(0, 0, math.rad(-15)), "Primary", "EarL"),
	S.Blob("EarR", V(0.75, 0.35, 0.3), CFrame.new(0.85, 5.0, -1.4) * CFrame.Angles(0, 0, math.rad(15)), "Primary", "EarR"),
	S.Leg("LegFL", 2.2, 0.42, V(-0.5, 1.1, -0.8), "Primary", "LegFL"),
	S.Leg("LegFR", 2.2, 0.42, V(0.5, 1.1, -0.8), "Primary", "LegFR"),
	S.Leg("LegBL", 2.2, 0.42, V(-0.5, 1.1, 1.4), "Primary", "LegBL"),
	S.Leg("LegBR", 2.2, 0.42, V(0.5, 1.1, 1.4), "Primary", "LegBR"),
	S.Blob("Tail", V(0.5, 0.6, 0.5), V(0, 3.1, 1.95), "Secondary", "Tail"),
	-- Antlers (2 sticks + 2 leaf buds per side)
	S.Stick("AntlerL", V(-0.3, 5.4, -1.6), V(-1.0, 6.9, -1.4), 0.22, "Feature", "Head"),
	S.Stick("AntlerR", V(0.3, 5.4, -1.6), V(1.0, 6.9, -1.4), 0.22, "Feature", "Head"),
	S.Stick("ForkL", V(-0.65, 6.15, -1.5), V(-0.2, 7.0, -1.75), 0.18, "Feature", "Head"),
	S.Stick("ForkR", V(0.65, 6.15, -1.5), V(0.2, 7.0, -1.75), 0.18, "Feature", "Head"),
	S.Ball("LeafL1", 0.6, V(-1.05, 7.0, -1.4), "Accent", "Head"),
	S.Ball("LeafR1", 0.6, V(1.05, 7.0, -1.4), "Accent", "Head"),
	S.Ball("LeafL2", 0.5, V(-0.18, 7.1, -1.78), "Glow", "Head"),
	S.Ball("LeafR2", 0.5, V(0.18, 7.1, -1.78), "Glow", "Head"),
	S.Pattern(S.Blob("Dapples", V(1.75, 0.5, 2.2), V(0, 3.45, 0.5), "Secondary", "Body")),
}
S.Face(parts, 0.38, 4.9, -2.2, 0.42, false)

local bp: S.Blueprint = {
	Species = "Thornstag",
	Palette = {
		Primary = hex("#B5835A"),
		Secondary = hex("#F5E3C8"),
		Belly = hex("#F5E3C8"),
		Accent = hex("#4FA63A"),
		Feature = hex("#7A4A2A"),
		Glow = hex("#A8E36A"),
	},
	AltPalette = {
		Primary = hex("#8C8FA8"),
		Secondary = hex("#E8EAF5"),
		Accent = hex("#FF9EC8"),
		Glow = hex("#FFB3D9"),
	},
	HeadPivot = V(0, 3.4, -0.9),
	Parts = parts,
	Shards = {
		S.Shard(V(0, 3.75, -0.2), -20, 0, 1.0),
		S.Shard(V(0, 3.8, 0.6), -20, 0, 1.1),
		S.Shard(V(0, 3.7, 1.3), -20, 0, 0.9),
		S.Shard(V(-1.0, 7.4, -1.4), 0, 15, 0.9, "Head"),
		S.Shard(V(1.0, 7.4, -1.4), 0, -15, 0.9, "Head"),
	},
	EmitterPart = "Head",
	Native = {},
}
return bp
