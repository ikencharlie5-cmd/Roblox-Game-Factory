--!strict
-- UI palette (Top/Bottom/Dark per colour), fonts and icons. Follows research/UI_STYLE_GUIDE.md.
-- World colours live in Shared/Theme. No emoji anywhere: icons are images or code-drawn badges.
local Style = {}

local function hex(h: string): Color3
	return Color3.fromHex(h)
end

export type Palette = { Top: Color3, Bottom: Color3, Dark: Color3, Text: Color3? }

local function pal(top: string, bottom: string, dark: string): Palette
	return { Top = hex(top), Bottom = hex(bottom), Dark = hex(dark) }
end

Style.Font = Enum.Font.FredokaOne
Style.FontBody = Enum.Font.BuilderSansExtraBold

-- Button / header palettes (guide section 6). Dark = stroke + lip + text stroke.
Style.Pal = {
	Leaf = pal("#8BE36A", "#3FAE2A", "#1F5E14"),
	Sun = pal("#FFE36B", "#FFAE1A", "#8A4F00"),
	Sky = pal("#7FDBFF", "#2A8CF0", "#0F427F"),
	Pink = pal("#FFA3D4", "#F2479A", "#7A1048"),
	Purple = pal("#CFA0FF", "#8A47F0", "#3E1B7A"),
	Teal = pal("#7DF0DE", "#1FB5A5", "#0B5A52"),
	Red = pal("#FF8A80", "#E8383A", "#7A1416"),
	Stone = pal("#E3E7EE", "#A7B0C0", "#4A5263"),
	Disabled = pal("#C9C9C9", "#9A9A9A", "#5A5A5A"),
	Robux = pal("#7CF0B0", "#14B86A", "#055233"),
	Wood = pal("#E0A36A", "#A8673A", "#5A3418"),
	Body = pal("#FFF6DC", "#FFE6B0", "#6B4A2E"),
	Card = pal("#FFFFFF", "#F4EEDC", "#6B4A2E"),
}

-- Kept for older call sites: flat colours. Kit maps these to a palette above.
Style.Color = {
	Cream = hex("#FFF6DC"),
	Panel = hex("#FFFDF5"),
	Card = hex("#F4EEDC"),
	Ink = hex("#4A3426"),
	InkSoft = hex("#7A5C45"),
	Leaf = hex("#3FAE2A"),
	LeafDark = hex("#1F5E14"),
	Sky = hex("#2A8CF0"),
	Sun = hex("#FFAE1A"),
	Cash = hex("#6BEA4A"),
	Hope = hex("#FFD54F"),
	Luck = hex("#7CE38B"),
	Pink = hex("#F2479A"),
	Purple = hex("#8A47F0"),
	Teal = hex("#1FB5A5"),
	Red = hex("#E8383A"),
	Grey = hex("#A7B0C0"),
	White = Color3.new(1, 1, 1),
	Dark = hex("#2B1D14"),
	Chip = hex("#2B1D14"),
	Robux = hex("#14B86A"),
	Wood = hex("#A8673A"),
	WoodDark = hex("#6B4A2E"),
}

-- Flat colour -> palette name (lets Kit.Button(parent, text, Style.Color.X) keep working).
local COLOR_TO_PAL: { [string]: string } = {}
for name, key in
	{
		Leaf = "Leaf",
		LeafDark = "Leaf",
		Cash = "Leaf",
		Luck = "Leaf",
		Sky = "Sky",
		Sun = "Sun",
		Hope = "Sun",
		Pink = "Pink",
		Purple = "Purple",
		Teal = "Teal",
		Red = "Red",
		Grey = "Disabled",
		Robux = "Robux",
		Wood = "Wood",
		WoodDark = "Wood",
		Cream = "Body",
		Panel = "Card",
		Card = "Card",
	}
do
	COLOR_TO_PAL[Style.Color[name]:ToHex()] = key
end

local function derive(c: Color3): Palette
	local h, s, v = c:ToHSV()
	return {
		Top = Color3.fromHSV(h, s * 0.6, math.min(1, v * 1.15 + 0.1)),
		Bottom = c,
		Dark = Color3.fromHSV(h, math.min(1, s * 1.1), v * 0.38),
	}
end

-- Accepts a palette table, a palette name ("Leaf") or any Color3.
function Style.PaletteFor(c: any): Palette
	if type(c) == "table" and c.Top then
		return c
	elseif type(c) == "string" and Style.Pal[c] then
		return Style.Pal[c]
	elseif typeof(c) == "Color3" then
		local key = COLOR_TO_PAL[c:ToHex()]
		if key then
			return Style.Pal[key]
		end
		for _, p in Style.Pal do
			if p.Bottom:ToHex() == c:ToHex() then
				return p
			end
		end
		return derive(c)
	end
	return Style.Pal.Leaf
end

Style.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret" }

Style.Rarity = {
	Common = hex("#B8C0C8"),
	Uncommon = hex("#5BD35B"),
	Rare = hex("#3BA7FF"),
	Epic = hex("#A55BFF"),
	Legendary = hex("#FFB300"),
	Mythical = hex("#FF3D7F"),
	Secret = hex("#1A1A1A"),
}

Style.RarityDark = {
	Common = hex("#59616B"),
	Uncommon = hex("#1F6B1F"),
	Rare = hex("#0F4F8F"),
	Epic = hex("#4A1A8F"),
	Legendary = hex("#8A5200"),
	Mythical = hex("#7A0F35"),
	Secret = hex("#000000"),
}

local SHORT = { C = "Common", U = "Uncommon", R = "Rare", E = "Epic", L = "Legendary", M = "Mythical", S = "Secret" }

-- Accepts "C", "Common", "common" or a 1-7 index; returns the full rarity name.
function Style.NormRarity(r: any): string
	if type(r) == "number" then
		return Style.RarityOrder[math.clamp(math.floor(r), 1, 7)]
	end
	if type(r) ~= "string" or r == "" then
		return "Common"
	end
	if SHORT[r] then
		return SHORT[r]
	end
	local cap = string.upper(string.sub(r, 1, 1)) .. string.lower(string.sub(r, 2))
	if cap == "Mythic" then
		return "Mythical"
	end
	return if Style.Rarity[cap] then cap else "Common"
end

function Style.RarityIndex(r: any): number
	return table.find(Style.RarityOrder, Style.NormRarity(r)) or 1
end

function Style.RarityColor(r: any): Color3
	return Style.Rarity[Style.NormRarity(r)]
end

function Style.RarityDarkColor(r: any): Color3
	return Style.RarityDark[Style.NormRarity(r)]
end

function Style.RarityPalette(r: any): Palette
	local name = Style.NormRarity(r)
	local c = Style.Rarity[name]
	if name == "Secret" then
		return pal("#4A4A55", "#1A1A1A", "#000000")
	end
	local h, s, v = c:ToHSV()
	return { Top = Color3.fromHSV(h, s * 0.55, math.min(1, v + 0.15)), Bottom = c, Dark = Style.RarityDark[name] }
end

-- Biomes: colour + 2-letter code for the code-drawn chip (until biome icons are uploaded).
Style.Biome = {
	Meadow = { Color = hex("#7BD148"), Code = "Me" },
	Pond = { Color = hex("#2EA6D9"), Code = "Po" },
	Desert = { Color = hex("#F2C27B"), Code = "De" },
	Canopy = { Color = hex("#2F8F4E"), Code = "Ca" },
	Fungus = { Color = hex("#B57CFF"), Code = "Fu" },
	Frost = { Color = hex("#9FD8FF"), Code = "Fr" },
}

function Style.BiomeInfo(name: any): { Color: Color3, Code: string }
	if type(name) == "string" then
		for key, info in Style.Biome do
			if string.find(string.lower(name), string.lower(key), 1, true) then
				return info
			end
		end
	end
	return { Color = Style.Color.Grey, Code = "?" }
end

Style.Weather = {
	Rain = { Code = "Ra", Color = hex("#4FA3E0"), Text = "Growth x1.5 · Dewy x2" },
	Heatwave = { Code = "He", Color = hex("#FF9E3D"), Text = "Sunkissed x2" },
	SnowFlurry = { Code = "Sn", Color = hex("#9FD8FF"), Text = "Frosted x3" },
	BloomSeason = { Code = "Bl", Color = hex("#FF8FC8"), Text = "Growth x2 · Colour mutations x2" },
	Thunderstorm = { Code = "Th", Color = hex("#7A6CFF"), Text = "Electric x8" },
	Starfall = { Code = "St", Color = hex("#3A3F8F"), Text = "Starlit x5" },
}

function Style.WeatherInfo(name: string): { Code: string, Color: Color3, Text: string }
	local key = string.gsub(name, "%s", "")
	return Style.Weather[key] or { Code = "Wx", Color = hex("#2A8CF0"), Text = "" }
end

-- Charlie's uploaded icons (image asset ids). Add an id here to replace a code-drawn badge.
Style.Icons = {
	Store = "rbxassetid://118340248374796",
	Settings = "rbxassetid://77037572950989",
	Daily = "rbxassetid://88974008115545",
	Release = "rbxassetid://114309448468135",
	Cash = "rbxassetid://75451473231283",
	DoubleCash = "rbxassetid://129143175711617",
	VIP = "rbxassetid://124845073094946",
	AutoGardener = "rbxassetid://133153479023421",
	CashBoost = "rbxassetid://101692449472461",
} :: { [string]: string }

-- Code-drawn placeholder badges for icons not uploaded yet (see notes/ui.md "Charlie TODO: icons").
Style.IconFallback = {
	Shop = { Glyph = "S", Pal = "Sun" },
	Inventory = { Glyph = "B", Pal = "Wood" },
	Build = { Glyph = "+", Pal = "Sun" },
	Index = { Glyph = "#", Pal = "Purple" },
	Upgrades = { Glyph = "UP", Pal = "Leaf" },
	Quests = { Glyph = "!", Pal = "Teal" },
	Visit = { Glyph = "V", Pal = "Sky" },
	Hope = { Glyph = "H", Pal = "Sun" },
	Luck = { Glyph = "L", Pal = "Leaf" },
	SuperLuck = { Glyph = "L", Pal = "Leaf" },
	FinishGrowing = { Glyph = ">>", Pal = "Teal" },
	InstantRestock = { Glyph = "R", Pal = "Sun" },
	HopeCrate = { Glyph = "?", Pal = "Purple" },
	LuckPotion = { Glyph = "L", Pal = "Purple" },
	GrowTonic = { Glyph = "T", Pal = "Sky" },
	Locked = { Glyph = "?", Pal = "Stone" },
	Decor = { Glyph = "D", Pal = "Wood" },
} :: { [string]: { Glyph: string, Pal: string } }

return Style
