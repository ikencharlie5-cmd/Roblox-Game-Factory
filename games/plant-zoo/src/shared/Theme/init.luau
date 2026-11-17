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
-- (pad local -Z, toward the hub), column 1 = pad local -X. Same math as gameplay's PlotService.CellCFrame.
Theme.Grid = { CellSize = 4, Cells = 5, PadSize = 20, PadSpacing = 24 }

-- Offset from the pad's TOP-CENTER CFrame to a cell (padTop * Theme.CellOffset(cell, rot)).
-- rot: degrees (0/90/180/270, gameplay's format) or quarter turns 0..3.
function Theme.CellOffset(cell: number, rot: number?): CFrame
	local n = Theme.Grid.Cells
	local c = math.clamp(math.floor(cell), 1, n * n)
	local row = (c - 1) // n + 1
	local col = (c - 1) % n + 1
	local s = Theme.Grid.CellSize
	local mid = (n + 1) / 2
	local r = rot or 0
	local deg = if r > 3 then r else r * 90
	return CFrame.new((col - mid) * s, 0, (row - mid) * s) * CFrame.Angles(0, math.rad(deg), 0)
end

Theme.Effects = require(script.Effects)

return Theme
