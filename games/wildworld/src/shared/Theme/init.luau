--!strict
-- Wildworld visual theme (owned by Graphics), classic studs look (research/STUDS_STYLE_GUIDE.md). Shared so server world, UI viewports and the build ghost
-- all use the same palette, item visuals, grid math and effects.
--   Theme.Colors        palette (Theme/Palette)
--   Theme.Rarity        rarity colours; Theme.Mutation mutation colours
--   Theme.Effects       particle presets (Sparkle, Embers, Hearts, CoinBurst, Confetti, Puff, Discovery,
--                       Fireflies, Mist, Splash, WaterMist, Fall)
--   Theme.Moments       in-world VFX: Hatch, CaptureBubble, DiscoveryBeam, RatingUp, Coins, Hearts
--   Theme.IconModels    UI icon brick models: IconModels.Build(name) (Coin, RP, bait, passes, packs, eggs)
--   Theme.Props         build-item visuals: Items catalog, Build(itemId, seed), Ghost(itemId, valid)
--   Theme.Nature / Theme.Structures / Theme.Decor / Theme.Kit   lower-level builders (Kit.Brick = studded part)
--   Theme.Lighting      day/night values; Theme.Zones biome atmosphere per zone (client tweens on entry)
--   Theme.Grid          plot grid math (4-stud cells, 128-stud plot)
local Palette = require(script.Palette)

local Theme = {}

Theme.Kit = require(script.Kit)
Theme.Colors = Palette
Theme.Rarity = Palette.Rarity
Theme.Mutation = Palette.Mutation
Theme.Effects = require(script.Effects)
Theme.Nature = require(script.Nature)
Theme.Structures = require(script.Structures)
Theme.Decor = require(script.Decor)
Theme.Props = require(script.Props)
Theme.Moments = require(script.Moments)
Theme.IconModels = require(script.IconModels)

local hex = Color3.fromHex

-- STUDS_STYLE_GUIDE §7: flatter, brighter light for the brick look (ShadowMap set in default.project.json).
Theme.Lighting = {
	DayLengthSeconds = 14 * 60,
	ClockTime = 14.5,
	Env = { DiffuseScale = 0.5, SpecularScale = 0.2, ShadowSoftness = 0.2, Latitude = 30 },
	Day = {
		Brightness = 3,
		Ambient = Color3.new(0.55, 0.55, 0.58),
		OutdoorAmbient = Color3.new(0.6, 0.6, 0.62),
	},
	Night = {
		Brightness = 1.0,
		Ambient = hex("#5A6A9A"),
		OutdoorAmbient = hex("#4A5A8C"),
	},
	Atmosphere = {
		Density = 0.18,
		Offset = 0.1,
		Color = hex("#BFE3FF"),
		Decay = hex("#9CCBFF"),
		Glare = 0,
		Haze = 0.5,
	},
	ColorCorrection = { Saturation = 0.12, Contrast = 0.12, Brightness = 0.03, TintColor = hex("#FFFFFF") },
	Bloom = { Intensity = 0.2, Size = 18, Threshold = 2.2 },
	SunRays = { Intensity = 0.03, Spread = 0.5 },
}

-- Zone looks. Every zone volume in the world (tag "WorldZone") has attribute ZoneKey = one of these keys.
-- The client tweens Atmosphere to these values over 2 s on entry (UI/Animation owns the client side).
-- Biome tints from ART_STYLE_GUIDE §1 kept; densities ×0.7 for the brick look.
export type ZoneLook = {
	DisplayName: string,
	Biome: string,
	Density: number,
	Color: Color3,
	Decay: Color3,
	Haze: number,
	Glare: number,
	Music: string,
}
Theme.Zones = {
	Park = {
		DisplayName = "Your Park",
		Biome = "Park",
		Density = 0.18,
		Color = hex("#BFE3FF"),
		Decay = hex("#9CCBFF"),
		Haze = 0.5,
		Glare = 0,
		Music = "Park",
	},
	Hub = {
		DisplayName = "Wildworld Plaza",
		Biome = "Park",
		Density = 0.18,
		Color = hex("#BFE3FF"),
		Decay = hex("#9CCBFF"),
		Haze = 0.5,
		Glare = 0,
		Music = "Park",
	},
	MeadowEdge = {
		DisplayName = "Greenleaf Meadow",
		Biome = "Greenleaf",
		Density = 0.175,
		Color = hex("#D6F0FF"),
		Decay = hex("#FFE6C4"),
		Haze = 0.8,
		Glare = 0.1,
		Music = "Forest",
	},
} :: { [string]: ZoneLook }

-- Plot grid: 128x128 studs, 4-stud cells, cells 1..32 on each axis. Local space: origin = plot floor
-- centre (top surface), -Z = entrance (faces the hub).
local Grid = {
	Cell = 4,
	PlotSize = 128,
	Cells = 32,
}

-- Local position of a footprint's centre (cellX/cellZ = lowest cell, footX/footZ in cells, rot in 90° steps).
function Grid.CellToLocal(cellX: number, cellZ: number, footX: number, footZ: number, rot: number?): CFrame
	local r = (rot or 0) % 4
	local fx, fz = footX, footZ
	if r == 1 or r == 3 then
		fx, fz = footZ, footX
	end
	local half = Grid.PlotSize / 2
	local x = -half + (cellX - 1 + fx / 2) * Grid.Cell
	local z = -half + (cellZ - 1 + fz / 2) * Grid.Cell
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(90 * r), 0)
end

-- Is a cell inside the unlocked (centred) square of side `landStuds` (64..128)?
function Grid.IsUnlocked(cellX: number, cellZ: number, landStuds: number): boolean
	local n = math.floor(landStuds / Grid.Cell)
	local lo = (Grid.Cells - n) / 2 + 1
	local hi = lo + n - 1
	return cellX >= lo and cellX <= hi and cellZ >= lo and cellZ <= hi
end

Theme.Grid = Grid

return Theme
