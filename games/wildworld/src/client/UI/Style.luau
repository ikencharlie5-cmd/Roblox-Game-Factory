--!strict
-- Wildworld "toy brick" palette (research/STUDS_STYLE_GUIDE.md "For UI"; layout rules still from
-- research/UI_STYLE_GUIDE.md): white plastic bodies, navy frame, stud highlights. Fonts, icons.
-- No emoji anywhere: icons are images (Style.Icons) or code-drawn letter badges (Style.IconFallback).
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

-- Guide §2 (Top / Bottom / Dark). Category colour = menu.
Style.Pal = {
	Leaf = pal("#8EE66B", "#38A83A", "#1B5A1E"), -- Jungle green: confirm, place, feed
	Teal = pal("#6FF0D8", "#14A99A", "#0A5049"), -- Lagoon: collection, visit
	Sky = pal("#82D8FF", "#2E86EE", "#103F7A"), -- Inventory, info
	Coral = pal("#FFB08A", "#FF6A3D", "#7A2A10"), -- Breeding, "New!"
	Sun = pal("#FFE36B", "#FFAA1C", "#874C00"), -- Buy, coins, rewards
	Purple = pal("#D2A6FF", "#8C4BEF", "#3D1B78"), -- Journal, RP
	Wood = pal("#E2B07A", "#A86B3A", "#4D2E14"), -- Build
	Red = pal("#FF8A80", "#E8383A", "#7A1416"), -- Close, release, danger
	Stone = pal("#E3E7EE", "#A7B0C0", "#4A5263"), -- Settings, disabled
	Disabled = pal("#C9C9C9", "#9A9A9A", "#5A5A5A"),
	Robux = pal("#7CF0B0", "#14B86A", "#055233"),
	Body = pal("#FFFFFF", "#E9EEF3", "#1F3B57"), -- white plastic body, navy frame
	Card = pal("#FFFFFF", "#F2F5F8", "#1F3B57"),
}
Style.Pal.Pink = Style.Pal.Coral -- old call sites

Style.Color = {
	Cream = hex("#F7F9FB"), -- legacy name: now the white-plastic body tint
	Panel = hex("#FDFEFF"),
	Card = hex("#F2F5F8"),
	Ink = hex("#1F2A36"),
	InkSoft = hex("#5A6B7D"),
	Stud = hex("#FFFFFF"), -- stud highlight dot (use with Style.StudTransparency)
	Frame = hex("#1F3B57"),
	Accent = hex("#FF8A5B"),
	Leaf = hex("#38A83A"),
	Sky = hex("#2E86EE"),
	Sun = hex("#FFAA1C"),
	Cash = hex("#FFD84A"),
	Coins = hex("#FFD84A"),
	RP = hex("#C99BFF"),
	Coral = hex("#FF6A3D"),
	Purple = hex("#8C4BEF"),
	Teal = hex("#14A99A"),
	Red = hex("#E8383A"),
	Grey = hex("#A7B0C0"),
	White = Color3.new(1, 1, 1),
	Dark = hex("#1F2A36"),
	Chip = hex("#1F2A36"),
	Robux = hex("#14B86A"),
	Wood = hex("#A86B3A"),
	Valid = hex("#5BFF7A"),
	Invalid = hex("#FF4D4D"),
}

-- Toy-brick studs (Kit.Stud): highlight transparency, window header row, big buttons, rare cards.
Style.StudTransparency = 0.35
Style.StudLighten = 0.15
Style.Studs = {
	Header = { Size = 18, Gap = 10, Max = 10 },
	Button = { Size = 14, MinWidth = 160 },
	Card = { Size = 14, Count = 3, MinRarity = 4 }, -- Epic and above
}

local COLOR_TO_PAL: { [string]: string } = {}
for name, key in
	{
		Leaf = "Leaf",
		Sky = "Sky",
		Sun = "Sun",
		Cash = "Sun",
		Coins = "Sun",
		Coral = "Coral",
		Accent = "Coral",
		Purple = "Purple",
		RP = "Purple",
		Teal = "Teal",
		Red = "Red",
		Grey = "Disabled",
		Robux = "Robux",
		Wood = "Wood",
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
		return derive(c)
	end
	return Style.Pal.Leaf
end

-- MVP uses Common..Legendary; Mythical is reserved (RESEARCH conflict #1).
Style.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

Style.Rarity = {
	Common = hex("#B8C0C8"),
	Uncommon = hex("#5BD35B"),
	Rare = hex("#3BA7FF"),
	Epic = hex("#A55BFF"),
	Legendary = hex("#FFB300"),
	Mythical = hex("#FF3D7F"),
}

Style.RarityDark = {
	Common = hex("#59616B"),
	Uncommon = hex("#1F6B1F"),
	Rare = hex("#0F4F8F"),
	Epic = hex("#4A1A8F"),
	Legendary = hex("#8A5200"),
	Mythical = hex("#7A0F35"),
}

local SHORT = { C = "Common", U = "Uncommon", R = "Rare", E = "Epic", L = "Legendary", M = "Mythical" }

function Style.NormRarity(r: any): string
	if type(r) == "number" then
		return Style.RarityOrder[math.clamp(math.floor(r), 1, #Style.RarityOrder)]
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

function Style.RarityPalette(r: any): Palette
	local name = Style.NormRarity(r)
	local c = Style.Rarity[name]
	local h, s, v = c:ToHSV()
	return { Top = Color3.fromHSV(h, s * 0.55, math.min(1, v + 0.15)), Bottom = c, Dark = Style.RarityDark[name] }
end

-- Mutation badges (guide §2): colour + 2-letter code. Only the 4 MVP ones are live.
Style.Mutation = {
	Golden = { Color = hex("#FFC83D"), Dark = hex("#874C00"), Code = "GD", Shine = true },
	Albino = { Color = hex("#F4F4F4"), Dark = hex("#FF9EC4"), Code = "AL" },
	Crystal = { Color = hex("#9EF2FF"), Dark = hex("#1B6F80"), Code = "CR", Shine = true },
	Glowing = { Color = hex("#7CFFB0"), Dark = hex("#1B6B3E"), Code = "GL", Pulse = true },
	GildedCrystal = { Color = hex("#FFE9A0"), Dark = hex("#8A5200"), Code = "GC", Shine = true },
}

function Style.MutationInfo(id: any): { Color: Color3, Dark: Color3, Code: string, Shine: boolean?, Pulse: boolean? }
	local key = if type(id) == "string" then string.gsub(id, "%s", "") else "?"
	return Style.Mutation[key]
		or { Color = hex("#E3E7EE"), Dark = hex("#4A5263"), Code = string.upper(string.sub(key, 1, 2)) }
end

-- Biome / forest-area colours for the biome chip.
Style.Biome = {
	Park = hex("#6CC644"),
	Hub = hex("#E2B07A"),
	Meadow = hex("#8EE66B"),
	Mossy = hex("#3F8F5A"),
	Waterfall = hex("#3CC3E8"),
	Greenleaf = hex("#4FBF4A"),
}

function Style.BiomeColor(name: any): Color3
	if type(name) == "string" then
		for key, c in Style.Biome do
			if string.find(string.lower(name), string.lower(key), 1, true) then
				return c
			end
		end
	end
	return Style.Pal.Teal.Bottom
end

-- Uploaded icon image ids (Charlie TODO: one consistent pack). Empty = code-drawn fallback.
Style.Icons = {} :: { [string]: string }

-- Code-drawn placeholder badges for icons not uploaded yet.
Style.IconFallback = {
	Collection = { Glyph = "C", Pal = "Teal" },
	Breed = { Glyph = "B", Pal = "Coral" },
	Build = { Glyph = "+", Pal = "Wood" },
	Journal = { Glyph = "J", Pal = "Purple" },
	Inventory = { Glyph = "I", Pal = "Sky" },
	Park = { Glyph = "P", Pal = "Leaf" },
	Shop = { Glyph = "$", Pal = "Sun" },
	Daily = { Glyph = "D", Pal = "Sun" },
	Visit = { Glyph = "V", Pal = "Teal" },
	Settings = { Glyph = "S", Pal = "Stone" },
	Coins = { Glyph = "C", Pal = "Sun" },
	RP = { Glyph = "RP", Pal = "Purple" },
	Quest = { Glyph = "!", Pal = "Coral" },
	Feed = { Glyph = "F", Pal = "Leaf" },
	Pet = { Glyph = "<3", Pal = "Coral" },
	Inspect = { Glyph = "i", Pal = "Sky" },
	Capture = { Glyph = "N", Pal = "Teal" },
	Hatch = { Glyph = "E", Pal = "Sun" },
	Egg = { Glyph = "E", Pal = "Sun" },
	Rotate = { Glyph = "R", Pal = "Sky" },
	Delete = { Glyph = "X", Pal = "Red" },
	Grid = { Glyph = "#", Pal = "Teal" },
	Place = { Glyph = "OK", Pal = "Leaf" },
	Move = { Glyph = "M", Pal = "Sky" },
	Exit = { Glyph = "X", Pal = "Red" },
	Locked = { Glyph = "?", Pal = "Stone" },
	Robux = { Glyph = "R$", Pal = "Robux" },
} :: { [string]: { Glyph: string, Pal: string } }

return Style
