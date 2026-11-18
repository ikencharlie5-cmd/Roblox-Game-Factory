--!strict
-- Emberfox (Common, playful): slim, quick. Hero feature: bead-chain flame tail with a glowing tip.
local S = require(script.Parent.Shapes)
local V = Vector3.new
local hex = Color3.fromHex

local parts: { S.PartSpec } = {
	S.Shadow(S.Blob("Body", V(1.4, 1.4, 2.6), V(0, 1.5, 0.3), "Primary", "Body")),
	S.Blob("Chest", V(1.0, 1.1, 1.3), V(0, 1.35, -0.55), "Belly", "Body"),
	S.Shadow(S.Ball("Head", 1.9, V(0, 2.5, -1.3), "Primary", "Head")),
	S.Blob("Snout", V(0.75, 0.6, 1.1), V(0, 2.2, -2.2), "Belly", "Head"),
	S.Ball("Nose", 0.3, V(0, 2.33, -2.75), "Eye", "Head"),
	S.Blob("EarL", V(0.65, 1.15, 0.28), CFrame.new(-0.55, 3.45, -1.15) * CFrame.Angles(0, 0, math.rad(18)), "Primary", "EarL"),
	S.Blob("EarR", V(0.65, 1.15, 0.28), CFrame.new(0.55, 3.45, -1.15) * CFrame.Angles(0, 0, math.rad(-18)), "Primary", "EarR"),
	S.Blob("EarTipL", V(0.36, 0.45, 0.3), CFrame.new(-0.72, 3.9, -1.15) * CFrame.Angles(0, 0, math.rad(18)), "Accent", "EarL"),
	S.Blob("EarTipR", V(0.36, 0.45, 0.3), CFrame.new(0.72, 3.9, -1.15) * CFrame.Angles(0, 0, math.rad(-18)), "Accent", "EarR"),
	S.Leg("LegFL", 1.0, 0.38, V(-0.4, 0.5, -0.5), "Accent", "LegFL"),
	S.Leg("LegFR", 1.0, 0.38, V(0.4, 0.5, -0.5), "Accent", "LegFR"),
	S.Leg("LegBL", 1.0, 0.38, V(-0.4, 0.5, 1.1), "Accent", "LegBL"),
	S.Leg("LegBR", 1.0, 0.38, V(0.4, 0.5, 1.1), "Accent", "LegBR"),
	S.Ball("TailA", 0.75, V(0, 1.8, 1.65), "Primary", "Tail"),
	S.Ball("TailB", 1.0, V(0, 2.25, 2.25), "Primary", "Tail"),
	S.Ball("TailTip", 1.35, V(0, 2.85, 2.85), "Glow", "Tail"),
	S.Pattern(S.Blob("StripeA", V(1.2, 0.3, 0.5), V(0, 2.12, 0.1), "Accent", "Body")),
	S.Pattern(S.Blob("StripeB", V(1.1, 0.3, 0.45), V(0, 2.08, 0.75), "Accent", "Body")),
}
S.Face(parts, 0.42, 2.5, -2.05, 0.48, true)

local bp: S.Blueprint = {
	Species = "Emberfox",
	Palette = {
		Primary = hex("#FF8A3D"),
		Secondary = hex("#FFF1E0"),
		Belly = hex("#FFF1E0"),
		Accent = hex("#C9402F"),
		Feature = hex("#FF8A3D"),
		Glow = hex("#FFC84A"),
	},
	AltPalette = {
		Primary = hex("#E8D9C8"),
		Secondary = hex("#FFFFFF"),
		Accent = hex("#6B5A70"),
		Glow = hex("#9FE8FF"),
	},
	HeadPivot = V(0, 2.0, -0.8),
	Parts = parts,
	Shards = {
		S.Shard(V(0, 2.3, 0.0), -25, 0, 0.9),
		S.Shard(V(0, 2.3, 0.7), -25, 0, 0.8),
		S.Shard(V(0, 3.55, 2.95), 20, 0, 0.9, "Tail"),
	},
	EmitterPart = "TailTip",
	Native = { Emitter = "Embers" },
}
return bp
