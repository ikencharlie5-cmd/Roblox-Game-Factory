--!strict
-- Visual recipe per species: body archetype (Kind), colors, head feature (Top).
-- Keys match Species.Name. Rarity duplicated here so the builder works standalone.
export type Look = {
	Kind: string,
	Body: string,
	Accent: string,
	Top: string,
	Rarity: string,
	Biome: string,
}

local function L(kind: string, body: string, accent: string, top: string, rarity: string, biome: string): Look
	return { Kind = kind, Body = body, Accent = accent, Top = top, Rarity = rarity, Biome = biome }
end

local Looks: { [string]: Look } = {
	["Sproutling"] = L("blob", "#7BD148", "#FFD54F", "sprout", "Common", "Meadow"),
	["Pebble Pea"] = L("blob", "#A6D86A", "#8C8C7A", "pebbles", "Common", "Meadow"),
	["Lily Guppy"] = L("fish", "#FF9EC4", "#5FBF6A", "lily", "Common", "Pond"),
	["Prickle Pup"] = L("quad", "#6DB55A", "#FFE9A8", "spikes", "Common", "Desert"),
	["Mossmouse"] = L("quad", "#7E9B66", "#B57CFF", "shroom", "Common", "Fungus Cave"),
	["Snowdrop Bunny"] = L("quad", "#F4F8FF", "#BDE7FF", "bunnyears", "Common", "Frost Garden"),
	["Dandelion Lion"] = L("quad", "#FFD54F", "#FFB300", "mane", "Uncommon", "Meadow"),
	["Kelp Eel"] = L("serpent", "#2F8F6E", "#9BE36A", "fins", "Uncommon", "Pond"),
	["Vine Monkey"] = L("biped", "#7B9E3A", "#C9E59A", "leafears", "Uncommon", "Canopy"),
	["Tumbleweed Hog"] = L("blob", "#C9A26B", "#8B6A3E", "twigs", "Uncommon", "Desert"),
	["Puffball Frog"] = L("frog", "#E9D8FF", "#B57CFF", "puffs", "Uncommon", "Fungus Cave"),
	["Sunflower Owl"] = L("bird", "#8B5A2B", "#FFC83D", "sunpetals", "Rare", "Canopy"),
	["Bubble Lotus Turtle"] = L("turtle", "#5BB89A", "#FF9EC4", "lotus", "Rare", "Pond"),
	["Cactus Camel"] = L("quad", "#5E9E4A", "#FF7FA0", "humps", "Rare", "Desert"),
	["Frostfern Fox"] = L("quad", "#9FD8FF", "#2E6B5A", "fern", "Rare", "Frost Garden"),
	["Glowcap Snail"] = L("snail", "#D8C29A", "#B57CFF", "glowcap", "Rare", "Fungus Cave"),
	["Orchid Parrot"] = L("bird", "#FF6FB5", "#7CF7FF", "orchid", "Epic", "Canopy"),
	["Venus Croc"] = L("croc", "#3E8E3E", "#FF5E7A", "traps", "Epic", "Pond"),
	["Crystal Moth"] = L("bird", "#BFA8FF", "#E6F7FF", "mothwings", "Epic", "Fungus Cave"),
	["Pinecone Bear"] = L("biped", "#8B5A2B", "#5E3B1E", "pinecone", "Epic", "Frost Garden"),
	["Blossom Stag"] = L("quad", "#F7C6D9", "#8B5A2B", "antlers", "Legendary", "Meadow"),
	["Bonsai Dragon"] = L("serpent", "#4E9D4A", "#FFB300", "bonsai", "Legendary", "Canopy"),
	["Sandstorm Scorpion"] = L("scorpion", "#D9A55B", "#8B4A2B", "stinger", "Legendary", "Desert"),
	["Glacier Yeti"] = L("biped", "#EAF6FF", "#7FD3FF", "icecrown", "Legendary", "Frost Garden"),
	["Phoenix Fern"] = L("bird", "#FF6A2B", "#FFD54F", "flame", "Mythical", "Desert"),
	["Moonpetal Unicorn"] = L("quad", "#F3EFFF", "#C8A8FF", "horn", "Mythical", "Meadow"),
	["World Tree Tortoise"] = L("turtle", "#7A8F5A", "#4CAF50", "worldtree", "Secret", "Canopy"),
	["Abyss Bloom Kraken"] = L("kraken", "#2B2F6B", "#FF3DCB", "abyssbloom", "Secret", "Pond"),
}

return Looks
