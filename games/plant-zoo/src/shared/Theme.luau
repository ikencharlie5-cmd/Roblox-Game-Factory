--!strict
-- Sprout Zoo visual theme: palette, biome kits, rarity/mutation looks, grid math, particle presets.
-- Shared so client UI (viewports, build ghost) can use the same colors and grid math.
local Theme = {}

local function hex(h: string): Color3
	return Color3.fromHex(h)
end
Theme.hex = hex

Theme.Colors = {
	Grass = hex("#7BD148"),
	GrassDark = hex("#5FB23A"),
	Path = hex("#E8D3A3"),
	PathEdge = hex("#CDB27E"),
	Wood = hex("#A8673A"),
	WoodDark = hex("#6B4A2E"),
	Leaf = hex("#4CAF50"),
	LeafLight = hex("#8BD65A"),
	Hedge = hex("#3E8E3E"),
	Dirt = hex("#8A5A3B"),
	Stone = hex("#B9B4A8"),
	Water = hex("#2EA6D9"),
	White = hex("#FFFFFF"),
	Cream = hex("#FFF6E0"),
	Gold = hex("#FFC83D"),
	Pink = hex("#FF8FB8"),
	Sky = hex("#9EDCFF"),
	Sunset = hex("#FF9E5E"),
	Night = hex("#1E2A4A"),
	Firefly = hex("#FFF27A"),
	Thriving = hex("#6BFF7A"),
	Text = hex("#3B2A1A"),
}

-- Biome kits. Keys match Species.Biome (gameplay names). Use Theme.BiomeKey() to normalize.
export type BiomeKit = {
	Ground: Color3,
	GroundMaterial: Enum.Material,
	Fence: Color3,
	FenceMaterial: Enum.Material,
	Accent: Color3,
	Accent2: Color3,
	Fence3: Color3,
}
Theme.Biomes = {
	Meadow = {
		Ground = hex("#7BD148"),
		GroundMaterial = Enum.Material.Grass,
		Fence = hex("#FFFFFF"),
		FenceMaterial = Enum.Material.WoodPlanks,
		Accent = hex("#FFD54F"),
		Accent2 = hex("#FF8FB8"),
		Fence3 = hex("#A8673A"),
	},
	Pond = {
		Ground = hex("#E8D3A3"),
		GroundMaterial = Enum.Material.Sand,
		Fence = hex("#A7E8F5"),
		FenceMaterial = Enum.Material.Glass,
		Accent = hex("#2EA6D9"),
		Accent2 = hex("#7FE0C8"),
		Fence3 = hex("#5C8FA8"),
	},
	Desert = {
		Ground = hex("#F2C27B"),
		GroundMaterial = Enum.Material.Sand,
		Fence = hex("#C8643B"),
		FenceMaterial = Enum.Material.Brick,
		Accent = hex("#5E9E4A"),
		Accent2 = hex("#FF7FA0"),
		Fence3 = hex("#E0A060"),
	},
	Canopy = {
		Ground = hex("#2F8F4E"),
		GroundMaterial = Enum.Material.LeafyGrass,
		Fence = hex("#6B4A2E"),
		FenceMaterial = Enum.Material.Wood,
		Accent = hex("#D9D9D9"),
		Accent2 = hex("#FF6FB5"),
		Fence3 = hex("#4E7D3A"),
	},
	["Fungus Cave"] = {
		Ground = hex("#3B5E3A"),
		GroundMaterial = Enum.Material.Ground,
		Fence = hex("#4A4A5A"),
		FenceMaterial = Enum.Material.Slate,
		Accent = hex("#B57CFF"),
		Accent2 = hex("#7CF7FF"),
		Fence3 = hex("#2E2E3A"),
	},
	["Frost Garden"] = {
		Ground = hex("#EAF6FF"),
		GroundMaterial = Enum.Material.Snow,
		Fence = hex("#9FD8FF"),
		FenceMaterial = Enum.Material.Ice,
		Accent = hex("#2E6B5A"),
		Accent2 = hex("#FFFFFF"),
		Fence3 = hex("#CFEFFF"),
	},
} :: { [string]: BiomeKit }

Theme.BiomeOrder = { "Meadow", "Pond", "Desert", "Canopy", "Fungus Cave", "Frost Garden" }

local function norm(s: string): string
	return (string.lower(s):gsub("[%s_%-]", ""))
end
Theme.Normalize = norm

local BIOME_ALIASES: { [string]: string } = {
	meadow = "Meadow",
	pond = "Pond",
	pondtank = "Pond",
	desert = "Desert",
	desertdome = "Desert",
	canopy = "Canopy",
	canopyaviary = "Canopy",
	fungus = "Fungus Cave",
	funguscave = "Fungus Cave",
	frost = "Frost Garden",
	frostgarden = "Frost Garden",
}
-- Accepts "Fungus", "fungus_cave", "Fungus Cave" ... returns the canonical key or nil.
function Theme.BiomeKey(name: string?): string?
	if not name then
		return nil
	end
	return BIOME_ALIASES[norm(name)]
end

Theme.Rarity = {
	Common = hex("#B0B0B0"),
	Uncommon = hex("#5BD35B"),
	Rare = hex("#3BA7FF"),
	Epic = hex("#A55BFF"),
	Legendary = hex("#FFB300"),
	Mythical = hex("#FF3D7F"),
	Secret = hex("#1A1A1A"),
} :: { [string]: Color3 }
Theme.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret" }
-- Model scale per rarity ("scale up a bit per rarity").
Theme.RarityScale = {
	Common = 1,
	Uncommon = 1.08,
	Rare = 1.16,
	Epic = 1.25,
	Legendary = 1.38,
	Mythical = 1.5,
	Secret = 1.65,
} :: { [string]: number }

-- Color mutations (Material + tint). Rainbow is animated by WorldService (hue cycle).
Theme.ColorMutations = {
	Gold = { Color = hex("#FFC83D"), Material = Enum.Material.Metal, Mix = 0.75 },
	Diamond = { Color = hex("#BFF3FF"), Material = Enum.Material.Glass, Mix = 0.75 },
	Rainbow = { Color = hex("#FF5E5E"), Material = Enum.Material.SmoothPlastic, Mix = 0.6 },
} :: { [string]: { Color: Color3, Material: Enum.Material, Mix: number } }

-- Weather mutation marks (emitter color + optional light/tint).
Theme.WeatherMarks = {
	Dewy = { Color = hex("#9FE6FF"), Tint = nil, Light = nil },
	Sunkissed = { Color = hex("#FFB25E"), Tint = hex("#FF9E5E"), Light = hex("#FFA040") },
	Frosted = { Color = hex("#E6FAFF"), Tint = hex("#CFF0FF"), Light = nil },
	Electric = { Color = hex("#FFF27A"), Tint = nil, Light = hex("#FFF27A") },
	Starlit = { Color = hex("#FFFFFF"), Tint = nil, Light = hex("#B8C8FF") },
} :: { [string]: { Color: Color3, Tint: Color3?, Light: Color3? } }

-- Grid: each ExhibitPad is 5x5 cells of 4 studs. Cell 1..25 row-major: row 1 = entrance side
-- (pad local -Z), column 1 = pad local -X. Rot 0..3 = 90 degree steps; rot 0 faces the entrance.
Theme.Grid = { CellSize = 4, Cells = 5, PadSize = 20, PadSpacing = 24 }

-- Offset from the pad's TOP-CENTER CFrame to a cell (multiply: padTop * Theme.CellOffset(cell, rot)).
function Theme.CellOffset(cell: number, rot: number?): CFrame
	local n = Theme.Grid.Cells
	local c = math.clamp(math.floor(cell), 1, n * n)
	local row = (c - 1) // n + 1
	local col = (c - 1) % n + 1
	local s = Theme.Grid.CellSize
	local mid = (n + 1) / 2
	return CFrame.new((col - mid) * s, 0, (row - mid) * s) * CFrame.Angles(0, math.rad(90 * ((rot or 0) % 4)), 0)
end

-- Particle presets. Each returns a ParticleEmitter (not parented). Built-in textures only.
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new(a, b)
end

local function emitter(props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE
	e.LightEmission = 0.6
	e.LockedToPart = false
	for k, v in props do
		(e :: any)[k] = v
	end
	return e
end

Theme.Effects = {}

function Theme.Effects.Sparkle(color: Color3, rate: number?): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(color),
		Rate = rate or 6,
		Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(0.5, 0),
		Transparency = seq(0.1, 1),
	})
end

function Theme.Effects.Aura(color: Color3): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(color),
		Rate = 10,
		Lifetime = NumberRange.new(1, 1.8),
		Speed = NumberRange.new(1, 2),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(25, 25),
		Size = seq(0.7, 0.1),
		Transparency = seq(0.2, 1),
		LightEmission = 1,
	})
end

function Theme.Effects.RainbowAura(): ParticleEmitter
	local e = Theme.Effects.Aura(Color3.new(1, 1, 1))
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.8, 1)))
	end
	e.Color = ColorSequence.new(keys)
	return e
end

function Theme.Effects.Leaves(): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(hex("#6BFF7A"), hex("#2F8F4E")),
		Rate = 3,
		Lifetime = NumberRange.new(1.5, 2.5),
		Speed = NumberRange.new(1, 2),
		Acceleration = Vector3.new(0, -1.5, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-90, 90),
		SpreadAngle = Vector2.new(60, 60),
		Size = seq(0.35, 0.2),
		Transparency = seq(0, 1),
		LightEmission = 0.2,
	})
end

-- Burst emitter: call :Emit(n) yourself (Rate = 0).
function Theme.Effects.CoinBurst(): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(hex("#FFE066"), hex("#FFB300")),
		Rate = 0,
		Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(10, 16),
		Acceleration = Vector3.new(0, -35, 0),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(40, 40),
		Size = seq(0.8, 0.4),
		Transparency = seq(0, 0.6),
		LightEmission = 0.8,
	})
end

function Theme.Effects.Puff(color: Color3): ParticleEmitter
	return emitter({
		Texture = SMOKE,
		Color = ColorSequence.new(color),
		Rate = 0,
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(4, 7),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(1.2, 2.5),
		Transparency = seq(0.3, 1),
		LightEmission = 0,
	})
end

function Theme.Effects.Fireflies(): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(hex("#FFF27A")),
		Rate = 4,
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 0.2, 0),
		Size = seq(0.35, 0.35),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0),
			NumberSequenceKeypoint.new(0.7, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		LightEmission = 1,
	})
end

-- Weather sheets: emitted from a flat part high above an area, falling down.
function Theme.Effects.Weather(kind: string): ParticleEmitter?
	local base = {
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(5, 5),
		Rate = 60,
	}
	if kind == "Rain" or kind == "Thunderstorm" then
		base.Color = ColorSequence.new(hex("#CFE8FF"))
		base.Speed = NumberRange.new(60, 70)
		base.Lifetime = NumberRange.new(0.6, 0.8)
		base.Size = seq(0.12, 0.12)
		base.Squash = seq(4, 4)
		base.Transparency = seq(0.3, 0.3)
		base.LightEmission = 0.2
		base.Rate = if kind == "Thunderstorm" then 150 else 110
	elseif kind == "Snow Flurry" or kind == "Snow" then
		base.Color = ColorSequence.new(Color3.new(1, 1, 1))
		base.Speed = NumberRange.new(6, 9)
		base.Lifetime = NumberRange.new(5, 7)
		base.Size = seq(0.35, 0.3)
		base.SpreadAngle = Vector2.new(25, 25)
		base.Transparency = seq(0.1, 0.4)
	elseif kind == "Bloom Season" or kind == "Bloom" then
		base.Color = ColorSequence.new(hex("#FFB7D5"), hex("#FFF0F6"))
		base.Speed = NumberRange.new(5, 8)
		base.Lifetime = NumberRange.new(5, 7)
		base.Size = seq(0.45, 0.35)
		base.Rotation = NumberRange.new(0, 360)
		base.RotSpeed = NumberRange.new(-120, 120)
		base.SpreadAngle = Vector2.new(30, 30)
		base.Rate = 30
	elseif kind == "Starfall" then
		base.Color = ColorSequence.new(hex("#FFFFFF"), hex("#B8C8FF"))
		base.Speed = NumberRange.new(40, 60)
		base.Lifetime = NumberRange.new(1, 1.5)
		base.Size = seq(1, 0)
		base.SpreadAngle = Vector2.new(35, 35)
		base.LightEmission = 1
		base.Rate = 4
	elseif kind == "Heatwave" then
		base.Texture = SMOKE
		base.Color = ColorSequence.new(hex("#FFD9A0"))
		base.EmissionDirection = Enum.NormalId.Top
		base.Speed = NumberRange.new(1, 2)
		base.Lifetime = NumberRange.new(2, 3)
		base.Size = seq(6, 10)
		base.Transparency = seq(0.92, 1)
		base.Rate = 6
	else
		return nil
	end
	return emitter(base)
end

return Theme
