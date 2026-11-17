--!strict
-- All 28 species (Config.Species). Grow is seconds. Buddy = role needed in the same pad (Uncommon+).
export type SpeciesDef = {
	Name: string,
	Rarity: string,
	Biome: string,
	Income: number,
	Cost: number,
	Grow: number,
	Decor: string,
	Buddy: string?,
	Role: string,
}

local M = 60
local H = 3600

local list: { SpeciesDef } = {
	{ Name = "Sproutling", Rarity = "Common", Biome = "Meadow", Income = 1, Cost = 10, Grow = 10, Decor = "Flower Bed", Role = "Pollinator" },
	{ Name = "Pebble Pea", Rarity = "Common", Biome = "Meadow", Income = 2, Cost = 25, Grow = 25, Decor = "Log", Role = "Grazer" },
	{ Name = "Lily Guppy", Rarity = "Common", Biome = "Pond", Income = 3, Cost = 50, Grow = 30, Decor = "Lily Pad", Role = "Grazer" },
	{ Name = "Prickle Pup", Rarity = "Common", Biome = "Desert", Income = 3, Cost = 60, Grow = 35, Decor = "Sandstone Rock", Role = "Guardian" },
	{ Name = "Mossmouse", Rarity = "Common", Biome = "Fungus Cave", Income = 4, Cost = 80, Grow = 45, Decor = "Glow Shroom", Role = "Grazer" },
	{ Name = "Snowdrop Bunny", Rarity = "Common", Biome = "Frost Garden", Income = 5, Cost = 100, Grow = 60, Decor = "Pine Tree", Role = "Pollinator" },
	{ Name = "Dandelion Lion", Rarity = "Uncommon", Biome = "Meadow", Income = 12, Cost = 300, Grow = 90, Decor = "Beehive", Buddy = "Grazer", Role = "Guardian" },
	{ Name = "Kelp Eel", Rarity = "Uncommon", Biome = "Pond", Income = 15, Cost = 450, Grow = 2 * M, Decor = "Reed Clump", Buddy = "Grazer", Role = "Glower" },
	{ Name = "Vine Monkey", Rarity = "Uncommon", Biome = "Canopy", Income = 18, Cost = 600, Grow = 2 * M, Decor = "Vine Swing", Buddy = "Pollinator", Role = "Grazer" },
	{ Name = "Tumbleweed Hog", Rarity = "Uncommon", Biome = "Desert", Income = 22, Cost = 850, Grow = 150, Decor = "Clay Pot", Buddy = "Guardian", Role = "Grazer" },
	{ Name = "Puffball Frog", Rarity = "Uncommon", Biome = "Fungus Cave", Income = 30, Cost = 1200, Grow = 3 * M, Decor = "Stalagmite", Buddy = "Glower", Role = "Pollinator" },
	{ Name = "Sunflower Owl", Rarity = "Rare", Biome = "Canopy", Income = 60, Cost = 3000, Grow = 4 * M, Decor = "Nest", Buddy = "Grazer", Role = "Guardian" },
	{ Name = "Bubble Lotus Turtle", Rarity = "Rare", Biome = "Pond", Income = 90, Cost = 5000, Grow = 5 * M, Decor = "Pond Rock", Buddy = "Glower", Role = "Grazer" },
	{ Name = "Cactus Camel", Rarity = "Rare", Biome = "Desert", Income = 120, Cost = 7000, Grow = 6 * M, Decor = "Palm Shade", Buddy = "Guardian", Role = "Grazer" },
	{ Name = "Frostfern Fox", Rarity = "Rare", Biome = "Frost Garden", Income = 160, Cost = 10000, Grow = 7 * M, Decor = "Ice Crystal", Buddy = "Pollinator", Role = "Guardian" },
	{ Name = "Glowcap Snail", Rarity = "Rare", Biome = "Fungus Cave", Income = 200, Cost = 12000, Grow = 8 * M, Decor = "Crystal", Buddy = "Grazer", Role = "Glower" },
	{ Name = "Orchid Parrot", Rarity = "Epic", Biome = "Canopy", Income = 500, Cost = 45000, Grow = 10 * M, Decor = "Hollow Log", Buddy = "Glower", Role = "Pollinator" },
	{ Name = "Venus Croc", Rarity = "Epic", Biome = "Pond", Income = 750, Cost = 75000, Grow = 12 * M, Decor = "Reed Clump", Buddy = "Grazer", Role = "Guardian" },
	{ Name = "Crystal Moth", Rarity = "Epic", Biome = "Fungus Cave", Income = 1000, Cost = 110000, Grow = 15 * M, Decor = "Crystal", Buddy = "Pollinator", Role = "Glower" },
	{ Name = "Pinecone Bear", Rarity = "Epic", Biome = "Frost Garden", Income = 1400, Cost = 150000, Grow = 18 * M, Decor = "Snowman", Buddy = "Grazer", Role = "Guardian" },
	{ Name = "Blossom Stag", Rarity = "Legendary", Biome = "Meadow", Income = 5000, Cost = 700000, Grow = 30 * M, Decor = "Beehive", Buddy = "Pollinator", Role = "Grazer" },
	{ Name = "Bonsai Dragon", Rarity = "Legendary", Biome = "Canopy", Income = 8000, Cost = 1200000, Grow = 35 * M, Decor = "Vine Swing", Buddy = "Guardian", Role = "Glower" },
	{ Name = "Sandstorm Scorpion", Rarity = "Legendary", Biome = "Desert", Income = 11000, Cost = 1700000, Grow = 40 * M, Decor = "Palm Shade", Buddy = "Grazer", Role = "Guardian" },
	{ Name = "Glacier Yeti", Rarity = "Legendary", Biome = "Frost Garden", Income = 15000, Cost = 2200000, Grow = 45 * M, Decor = "Ice Crystal", Buddy = "Glower", Role = "Guardian" },
	{ Name = "Phoenix Fern", Rarity = "Mythical", Biome = "Desert", Income = 60000, Cost = 15000000, Grow = 90 * M, Decor = "Clay Pot", Buddy = "Guardian", Role = "Glower" },
	{ Name = "Moonpetal Unicorn", Rarity = "Mythical", Biome = "Meadow", Income = 100000, Cost = 30000000, Grow = 2 * H, Decor = "Flower Bed", Buddy = "Glower", Role = "Pollinator" },
	{ Name = "World Tree Tortoise", Rarity = "Secret", Biome = "Canopy", Income = 500000, Cost = 200000000, Grow = 3 * H, Decor = "Nest", Buddy = "Pollinator", Role = "Guardian" },
	{ Name = "Abyss Bloom Kraken", Rarity = "Secret", Biome = "Pond", Income = 1000000, Cost = 500000000, Grow = 4 * H, Decor = "Pond Rock", Buddy = "Guardian", Role = "Glower" },
}

local Species = {
	List = list,
	ByName = {} :: { [string]: SpeciesDef },
	ByRarity = {} :: { [string]: { SpeciesDef } },
}
for _, s in list do
	Species.ByName[s.Name] = s
	local bucket = Species.ByRarity[s.Rarity]
	if not bucket then
		bucket = {}
		Species.ByRarity[s.Rarity] = bucket
	end
	table.insert(bucket, s)
end

return Species
