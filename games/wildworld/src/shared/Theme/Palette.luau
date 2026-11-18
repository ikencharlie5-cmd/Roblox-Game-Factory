--!strict
-- Wildworld colour palette (ART_STYLE_GUIDE §3). Ground calm, props brighter, creatures brightest.
local function hex(h: string): Color3
	return Color3.fromHex(h)
end

local Palette = {
	Grass = hex("#6CC644"),
	GrassHill = hex("#5DB43C"),
	ForestFloor = hex("#4FA63A"),
	PlotFloor = hex("#8BD65E"),
	PlotLocked = hex("#9DB98A"),
	PlotFree = hex("#A9C79A"),
	TerrainPath = hex("#D4B386"),
	Path = hex("#EBD5A6"),
	PathEdge = hex("#C9A979"),
	Plaza = hex("#E9DCC2"),
	PlazaStone = hex("#D8C8A8"),
	Leaf1 = hex("#4FBF4A"),
	Leaf2 = hex("#7AD65A"),
	Leaf3 = hex("#A8E36A"),
	PineLeaf = hex("#3E9E58"),
	MagicPink = hex("#FFB3D9"),
	MagicPurple = hex("#B9A4FF"),
	Trunk = hex("#8A5A3B"),
	Wood = hex("#B8784A"),
	WoodDark = hex("#7A4A2A"),
	Rock = hex("#9AA3B5"),
	RockWarm = hex("#B3A99A"),
	Moss = hex("#7BBF4E"),
	Water = hex("#3CC3E8"),
	Sand = hex("#F2DFA7"),
	Discovery = hex("#FFF3A0"),
	Cloud = hex("#FFFFFF"),
	Cream = hex("#FFF6E6"),
	Text = hex("#3B2A1A"),
	Teal = hex("#1F6F78"),
	Coral = hex("#FF7B6B"),
	Parchment = hex("#F6E7C8"),
	Lantern = hex("#FFD27A"),
	Food = hex("#FFD45C"),
	Flowers = { hex("#FF6FA8"), hex("#FFD54F"), hex("#FFFFFF"), hex("#8F7CFF"), hex("#FF8A3D") },
	Awnings = { hex("#FF7B7B"), hex("#FFD45C"), hex("#7FD0FF"), hex("#C79BFF") },
	Roofs = { hex("#E8505B"), hex("#2FA59A") },
	Toys = { hex("#FF4E4E"), hex("#3D8BFF"), hex("#FFD23F") },
	Sky = hex("#CDEBFF"),
	Sunset = hex("#FFB27A"),
	Night = hex("#5A6A9A"),
	NightOutdoor = hex("#4A5A8C"),
}

-- 5 rarity tiers (RESEARCH conflict #1).
Palette.Rarity = {
	Common = hex("#B8C4CC"),
	Uncommon = hex("#6BD66B"),
	Rare = hex("#4DA6FF"),
	Epic = hex("#B266FF"),
	Legendary = hex("#FFB400"),
}

-- Mutation signature colours (flash, labels, VFX).
Palette.Mutation = {
	Golden = hex("#F5C542"),
	Albino = hex("#FFE6EC"),
	Crystal = hex("#9FE8FF"),
	Glowing = hex("#7CFFB2"),
	GildedCrystal = hex("#FFE9A8"),
}

return Palette
