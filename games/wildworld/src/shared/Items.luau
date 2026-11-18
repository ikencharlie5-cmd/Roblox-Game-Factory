--!strict
-- Build catalog. W/D = footprint in 4-stud cells (at rotation 0). Layer "floor" (pads, paths)
-- and "object" (everything else) have separate occupancy: objects may sit on pads/paths.
-- Kind: pad | path | fence | tree | bush | flower | rock | log | burrow | sand | sunspot | water
--       | food | drink | shelter | toy | light | stand | decor
-- Tags = biome tags provided to a habitat. Enrich = counts as enrichment. Fine = 15-degree rotation.
-- Unlock: Level (park level), Pass (game pass key), Starter (Starter Pack), RP (cost in RP),
-- ShopRare (only from shop restock -> inventory), Max (per plot).
export type ItemDef = {
	Id: string,
	Name: string,
	Kind: string,
	W: number,
	D: number,
	Cost: number,
	Level: number,
	Layer: string,
	Tags: { string },
	Enrich: boolean?,
	Fine: boolean?,
	Pass: string?,
	Starter: boolean?,
	RP: number?,
	ShopRare: boolean?,
	Max: number?,
	PadSize: number?, -- studs, pads only
	PadCapacity: number?,
	Order: number,
}

local list: { any } = {
	-- Habitat pads (auto-fenced with gate; Graphics builds the visual)
	{ "PadSmall", "Small Habitat Pad", "pad", 6, 6, 100, 1, { PadSize = 24, PadCapacity = 4, Tags = { "grass" } } },
	{ "PadMedium", "Medium Habitat Pad", "pad", 9, 9, 600, 3, { PadSize = 36, PadCapacity = 8, Tags = { "grass" } } },
	{ "PadLarge", "Large Habitat Pad", "pad", 12, 12, 2500, 6, { PadSize = 48, PadCapacity = 12, Tags = { "grass" } } },
	-- Structure
	{ "Fence", "Wood Fence", "fence", 1, 1, 5, 1, {} },
	{ "Path", "Stone Path", "path", 1, 1, 3, 2, {} },
	{ "Bench", "Park Bench", "decor", 2, 1, 40, 2, { Fine = true } },
	{ "SnackStand", "Snack Stand", "stand", 2, 2, 750, 3, { Max = 3 } },
	{ "Lantern", "Firefly Lantern", "light", 1, 1, 60, 7, { Fine = true, Enrich = true } },
	-- Plants & terrain
	{ "TreeOak", "Round Oak", "tree", 2, 2, 25, 1, { Tags = { "tree" }, Enrich = true, Fine = true } },
	{ "TreePine", "Tall Pine", "tree", 2, 2, 40, 2, { Tags = { "tree" }, Enrich = true, Fine = true } },
	{ "TreeMagic", "Blossom Tree", "tree", 2, 2, 200, 5, { Tags = { "tree", "flower" }, Enrich = true, Fine = true } },
	{ "Bush", "Berry Bush", "bush", 1, 1, 15, 1, { Tags = { "bush" }, Fine = true } },
	{ "Flowers", "Flower Patch", "flower", 1, 1, 10, 1, { Tags = { "flower" }, Fine = true } },
	{ "Rock", "Mossy Rock", "rock", 1, 1, 20, 1, { Tags = { "rock" }, Fine = true } },
	{ "BigRock", "Boulder Den", "rock", 2, 2, 90, 3, { Tags = { "rock" }, Shelter = true } },
	{ "Log", "Hollow Log", "log", 2, 1, 20, 1, { Tags = { "log" }, Enrich = true } },
	{ "Burrow", "Cozy Burrow", "burrow", 2, 2, 30, 1, { Tags = { "burrow" }, Shelter = true } },
	{ "SandPatch", "Sand Patch", "sand", 2, 2, 20, 2, { Tags = { "sand" } } },
	{ "Sunspot", "Sun Stone", "sunspot", 2, 2, 30, 2, { Tags = { "sunspot" } } },
	{ "Pond", "Lily Pond", "water", 3, 3, 120, 3, { Tags = { "water" }, Drink = true } },
	{ "Waterfall", "Little Waterfall", "water", 2, 2, 800, 6, { Tags = { "water" }, Drink = true, Enrich = true } },
	-- Care
	{ "FoodBowl", "Food Bowl", "food", 1, 1, 15, 1, {} },
	{ "WaterTrough", "Water Trough", "drink", 1, 1, 20, 1, { Drink = true } },
	{ "ShelterHut", "Shelter Hut", "shelter", 2, 2, 150, 2, { Shelter = true } },
	{ "ToyBall", "Toy Ball", "toy", 1, 1, 40, 1, { Enrich = true } },
	-- Special sets
	{ "VipFountain", "VIP Golden Fountain", "decor", 2, 2, 0, 1, { Pass = "VIP", Enrich = true } },
	{ "CrystalCluster", "Crystal Cluster", "decor", 1, 1, 0, 1, { Pass = "CrystalGrotto", Enrich = true, Fine = true } },
	{ "GrottoArch", "Grotto Arch", "decor", 3, 1, 0, 1, { Pass = "CrystalGrotto", Enrich = true } },
	{ "GlowShroom", "Glow Shroom", "decor", 1, 1, 0, 1, { Pass = "CrystalGrotto", Enrich = true, Fine = true } },
	{ "StarterArch", "Explorer's Arch", "decor", 3, 1, 0, 1, { Starter = true, Enrich = true } },
	{ "MossStatue", "Moss Statue", "decor", 1, 1, 0, 1, { ShopRare = true, Enrich = true, Fine = true } },
	{ "RainbowFlowers", "Rainbow Flowers", "flower", 1, 1, 0, 1, { ShopRare = true, Tags = { "flower" }, Enrich = true } },
}

local Items = {}
Items.Defs = {} :: { [string]: ItemDef } -- Items.Defs[id]
local ordered: { ItemDef } = {}
for i, row in list do
	local extra = row[8] or {}
	local def: any = {
		Id = row[1],
		Name = row[2],
		Kind = row[3],
		W = row[4],
		D = row[5],
		Cost = row[6],
		Level = row[7],
		Layer = if row[3] == "pad" or row[3] == "path" then "floor" else "object",
		Tags = extra.Tags or {},
		Order = i,
	}
	for k, v in extra do
		if k ~= "Tags" then
			def[k] = v
		end
	end
	Items.Defs[def.Id] = def
	table.insert(ordered, def)
end

-- Ordered list for UI build tray.
function Items.List(): { ItemDef }
	return ordered
end

-- Footprint (cells) after rotation in degrees.
function Items.Footprint(def: ItemDef, rot: number): (number, number)
	local quarter = math.floor(((rot % 360) + 45) / 90) % 4
	if quarter % 2 == 1 then
		return def.D, def.W
	end
	return def.W, def.D
end

function Items.IsShelter(def: any): boolean
	return def.Shelter == true or def.Kind == "shelter"
end

function Items.IsDrink(def: any): boolean
	return def.Drink == true or def.Kind == "drink"
end

function Items.Get(id: any): ItemDef?
	if type(id) ~= "string" then
		return nil
	end
	return Items.Defs[id]
end

return Items
