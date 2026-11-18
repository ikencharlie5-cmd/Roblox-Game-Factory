--!strict
-- Wildworld colour palette, classic studs look (research/STUDS_STYLE_GUIDE.md §3). Plastic darkens colours a
-- little, so these are one step brighter than SmoothPlastic picks. Old token names are kept (other code and
-- builders use them) and re-pointed at the brick palette. Rarity / Mutation tables are unchanged.
local function hex(h: string): Color3
	return Color3.fromHex(h)
end

local Palette = {
	-- Ground
	GrassTop = hex("#5CB83C"),
	GrassAlt = hex("#52AA36"),
	GrassSide = hex("#3F8F2E"),
	Dirt = hex("#A0703F"),
	Grass = hex("#5CB83C"),
	GrassHill = hex("#52AA36"),
	ForestFloor = hex("#4C9E33"),
	ForestAlt = hex("#46952F"),
	PlotFloor = hex("#5CB83C"),
	PlotLocked = hex("#9DB98A"),
	PlotFree = hex("#9DB98A"),
	TerrainPath = hex("#E3CFA0"),
	Path = hex("#E3CFA0"),
	PathEdge = hex("#B89C6B"),
	Plaza = hex("#E5E4DF"),
	PlazaStone = hex("#C9C7BF"),
	Sand = hex("#F2D98A"),
	-- Stone / wood
	Stone = hex("#A3A2A5"),
	StoneDark = hex("#635F62"),
	Rock = hex("#A3A2A5"),
	RockWarm = hex("#B5A99A"),
	Wood = hex("#B07A45"),
	WoodDark = hex("#694028"),
	Trunk = hex("#694028"),
	-- Foliage (canopy layers bottom -> top)
	Leaf1 = hex("#3E9B45"),
	Leaf2 = hex("#5CC04A"),
	Leaf3 = hex("#A4CF4A"),
	PineLeaf = hex("#3E9B45"),
	Moss = hex("#6FC24A"),
	MagicPink = hex("#FFB3D9"),
	MagicPurple = hex("#B9A4FF"),
	-- Water
	Water = hex("#3FA9F5"),
	WaterDeep = hex("#2F7FE0"),
	-- Toy brick primaries
	White = hex("#F4F5F7"),
	Red = hex("#E0453A"),
	Blue = hex("#2F7FE0"),
	Yellow = hex("#F5CD30"),
	Pink = hex("#FF9EB5"),
	Eye = hex("#1B1B1F"),
	-- Misc
	Discovery = hex("#FFF3A0"),
	Cloud = hex("#FFFFFF"),
	Cream = hex("#FFF6E6"),
	Text = hex("#1F2A36"),
	Teal = hex("#1FA59A"),
	Coral = hex("#FF7B6B"),
	Parchment = hex("#F4F5F7"), -- sign boards are white plastic now
	Lantern = hex("#FFD27A"),
	Food = hex("#F5CD30"),
	Flowers = { hex("#E0453A"), hex("#F5CD30"), hex("#FFFFFF"), hex("#FF98DC"), hex("#6E99CA") },
	Awnings = { hex("#E0453A"), hex("#F5CD30"), hex("#2F7FE0"), hex("#FF98DC") },
	Roofs = { hex("#E0453A"), hex("#2F7FE0") },
	Toys = { hex("#E0453A"), hex("#2F7FE0"), hex("#F5CD30") },
	Sky = hex("#BFE3FF"),
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
