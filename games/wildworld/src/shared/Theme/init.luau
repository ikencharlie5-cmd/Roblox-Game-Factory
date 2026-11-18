--!strict
-- Wildworld visual theme (owned by Graphics). Shared so server world, UI viewports and the build ghost
-- all use the same palette, item visuals, grid math and effects.
--   Theme.Colors        palette (Theme/Palette)
--   Theme.Rarity        rarity colours; Theme.Mutation mutation colours
--   Theme.Effects       particle presets (Sparkle, Embers, Hearts, CoinBurst, Confetti, Puff, Discovery,
--                       Fireflies, Mist, Splash, WaterMist, Fall, Weather(kind))
--   Theme.Moments       in-world VFX: Hatch, CaptureBubble, DiscoveryBeam, RatingUp, Coins, Hearts
--   Theme.Props         build-item visuals: Items catalog, Build(itemId, seed), Ghost(itemId, valid)
--   Theme.Nature / Theme.Structures / Theme.Decor / Theme.Kit   lower-level builders
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

local hex = Color3.fromHex

-- ART_STYLE_GUIDE §1 (ShadowMap set in default.project.json).
Theme.Lighting = {
	DayLengthSeconds = 14 * 60,
	Day = {
		Brightness = 2.8,
		Ambient = Color3.new(0.53, 0.53, 0.55),
		OutdoorAmbient = Color3.new(0.5, 0.5, 0.53),
	},
	Night = {
		Brightness = 1.0,
		Ambient = hex("#5A6A9A"),
		OutdoorAmbient = hex("#4A5A8C"),
	},
	Atmosphere = {
		Density = 0.25,
		Offset = 0.25,
		Color = hex("#CDEBFF"),
		Decay = hex("#FFE0BF"),
		Glare = 0.3,
		Haze = 1.3,
	},
	ColorCorrection = { Saturation = 0.22, Contrast = 0.08, Brightness = 0.02, TintColor = hex("#FFF8EE") },
	Bloom = { Intensity = 0.35, Size = 24, Threshold = 1.7 },
	SunRays = { Intensity = 0.05, Spread = 0.6 },
}

-- Zone looks. Every zone volume in the world (tag "WorldZone") has attribute Zone = one of these keys.
-- The client tweens Atmosphere to these values over 2 s on entry (UI/Animation owns the client side).
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
		Density = 0.25,
		Color = hex("#CDEBFF"),
		Decay = hex("#FFE0BF"),
		Haze = 1.3,
		Glare = 0.3,
		Music = "Park",
	},
	Hub = {
		DisplayName = "Wildworld Plaza",
		Biome = "Park",
		Density = 0.25,
		Color = hex("#CDEBFF"),
		Decay = hex("#FFE0BF"),
		Haze = 1.3,
		Glare = 0.3,
		Music = "Park",
	},
	MeadowEdge = {
		DisplayName = "Meadow Edge",
		Biome = "Greenleaf",
		Density = 0.25,
		Color = hex("#D6F0FF"),
		Decay = hex("#FFE6C4"),
		Haze = 1.2,
		Glare = 0.3,
		Music = "Forest",
	},
	MossyHollow = {
		DisplayName = "Mossy Hollow",
		Biome = "Greenleaf",
		Density = 0.36,
		Color = hex("#D4EBDC"),
		Decay = hex("#A9C9A0"),
		Haze = 2,
		Glare = 0.1,
		Music = "Forest",
	},
	WaterfallGlade = {
		DisplayName = "Waterfall Glade",
		Biome = "Greenleaf",
		Density = 0.28,
		Color = hex("#E6DDFF"),
		Decay = hex("#FFC8E6"),
		Haze = 1.4,
		Glare = 0.5,
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
