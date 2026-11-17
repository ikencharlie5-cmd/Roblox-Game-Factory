--!strict
-- Colors, fonts and icons shared by every UI module (cozy garden palette).
local Theme = {}

local function hex(h: string): Color3
	return Color3.fromHex(h)
end

Theme.Font = Enum.Font.FredokaOne
Theme.FontBody = Enum.Font.GothamBold

Theme.Color = {
	Cream = hex("#FFF8E7"),
	Panel = hex("#FFFDF5"),
	Card = hex("#F3EAD3"),
	Ink = hex("#3B2F2F"),
	InkSoft = hex("#7A6A5A"),
	Leaf = hex("#5BBF4A"),
	LeafDark = hex("#3E8E32"),
	Sky = hex("#4FB3FF"),
	Sun = hex("#FFB300"),
	Cash = hex("#3DDC84"),
	Hope = hex("#FFD54F"),
	Luck = hex("#7CE38B"),
	Pink = hex("#FF6FA8"),
	Purple = hex("#A55BFF"),
	Red = hex("#FF5A5A"),
	Grey = hex("#B8B0A0"),
	White = Color3.new(1, 1, 1),
	Dark = hex("#2B2B3A"),
	Robux = hex("#00B06F"),
	Wood = hex("#A8673A"),
}

Theme.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret" }

Theme.Rarity = {
	Common = hex("#B0B0B0"),
	Uncommon = hex("#5BD35B"),
	Rare = hex("#3BA7FF"),
	Epic = hex("#A55BFF"),
	Legendary = hex("#FFB300"),
	Mythical = hex("#FF3D7F"),
	Secret = hex("#1A1A1A"),
}

local SHORT = { C = "Common", U = "Uncommon", R = "Rare", E = "Epic", L = "Legendary", M = "Mythical", S = "Secret" }

-- Accepts "C", "Common", "common" or a 1-7 index; returns the full rarity name.
function Theme.NormRarity(r: any): string
	if type(r) == "number" then
		return Theme.RarityOrder[math.clamp(math.floor(r), 1, 7)]
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
	return if Theme.Rarity[cap] then cap else "Common"
end

function Theme.RarityIndex(r: any): number
	local name = Theme.NormRarity(r)
	return table.find(Theme.RarityOrder, name) or 1
end

function Theme.RarityColor(r: any): Color3
	return Theme.Rarity[Theme.NormRarity(r)]
end

Theme.Biome = {
	Meadow = { Color = hex("#7BD148"), Icon = "🌼" },
	Pond = { Color = hex("#2EA6D9"), Icon = "💧" },
	Desert = { Color = hex("#F2C27B"), Icon = "🌵" },
	Canopy = { Color = hex("#2F8F4E"), Icon = "🌴" },
	Fungus = { Color = hex("#B57CFF"), Icon = "🍄" },
	Frost = { Color = hex("#9FD8FF"), Icon = "❄️" },
}

function Theme.BiomeInfo(name: any): { Color: Color3, Icon: string }
	if type(name) == "string" then
		for key, info in Theme.Biome do
			if string.find(string.lower(name), string.lower(key), 1, true) then
				return info
			end
		end
	end
	return { Color = Theme.Color.Grey, Icon = "⬜" }
end

Theme.Weather = {
	Rain = { Icon = "🌧️", Color = hex("#4FA3E0"), Text = "Growth x1.5 · Dewy x2" },
	Heatwave = { Icon = "☀️", Color = hex("#FF9E3D"), Text = "Sunkissed x2" },
	SnowFlurry = { Icon = "❄️", Color = hex("#9FD8FF"), Text = "Frosted x3" },
	BloomSeason = { Icon = "🌸", Color = hex("#FF8FC8"), Text = "Growth x2 · Color mutations x2" },
	Thunderstorm = { Icon = "⚡", Color = hex("#7A6CFF"), Text = "Electric x8" },
	Starfall = { Icon = "🌠", Color = hex("#3A3F8F"), Text = "Starlit x5" },
}

function Theme.WeatherInfo(name: string): { Icon: string, Color: Color3, Text: string }
	local key = string.gsub(name, "%s", "")
	return Theme.Weather[key] or { Icon = "🌤️", Color = Theme.Color.Sky, Text = "" }
end

return Theme
