--!strict
-- Build-item visuals (ids + footprints match shared/Items.luau, which gameplay owns for prices/unlocks).
-- Props.Build(itemId, seed?) -> unparented Model, pivot = centre of the footprint at ground level
-- (y = 0 = plot floor top), facing -Z. Invisible "Root" part = PrimaryPart (footprint box).
-- Model attributes: ItemId, Category, FootX, FootZ, BiomeTags ("tree,flower"), and Role flag
-- (Food / Water / Shelter / Toy / Enrichment = true) when it has one.
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Nature = require(script.Parent.Nature)
local Structures = require(script.Parent.Structures)
local Decor = require(script.Parent.Decor)

local Props = {}

type Builder = (parent: Model, rng: Random) -> ()
export type ItemVisual = {
	Name: string,
	Category: string, -- Habitat | Nature | Feature | Decor | Path | Shop | Special
	Foot: { number }, -- {x, z} in 4-stud cells at rotation 0
	Tags: { string },
	Role: string?,
	Build: Builder,
}

local O = CFrame.new()

-- { id, name, category, footX, footZ, tags, role, builder }
local ROWS: { { any } } = {
	{ "PadSmall", "Small Habitat Pad", "Habitat", 6, 6, { "grass" }, nil, function(m, rng)
		Structures.Pad(m, O, 24, rng)
	end },
	{ "PadMedium", "Medium Habitat Pad", "Habitat", 9, 9, { "grass" }, nil, function(m, rng)
		Structures.Pad(m, O, 36, rng)
	end },
	{ "PadLarge", "Large Habitat Pad", "Habitat", 12, 12, { "grass" }, nil, function(m, rng)
		Structures.Pad(m, O, 48, rng)
	end },
	{ "Fence", "Wood Fence", "Decor", 1, 1, {}, nil, function(m)
		Structures.FenceRun(m, O, 4)
	end },
	{ "Path", "Stone Path", "Path", 1, 1, {}, nil, function(m)
		Structures.Path(m, O)
	end },
	{ "Bench", "Park Bench", "Decor", 2, 1, {}, nil, function(m)
		Structures.Bench(m, O)
	end },
	{ "SnackStand", "Snack Stand", "Shop", 2, 2, {}, nil, function(m, rng)
		Structures.SnackStand(m, O, rng)
	end },
	{ "Lantern", "Firefly Lantern", "Decor", 1, 1, {}, "Enrichment", function(m)
		Structures.Lantern(m, CFrame.new(-0.6, 0, 0))
	end },
	{ "TreeOak", "Round Oak", "Nature", 2, 2, { "tree" }, "Enrichment", function(m, rng)
		Nature.Tree(m, O, 0.85, rng)
	end },
	{ "TreePine", "Tall Pine", "Nature", 2, 2, { "tree" }, "Enrichment", function(m, rng)
		Nature.Pine(m, O, 0.9, rng)
	end },
	{ "TreeMagic", "Blossom Tree", "Nature", 2, 2, { "tree", "flower" }, "Enrichment", function(m, rng)
		Nature.MagicTree(m, O, 0.75, rng, true)
	end },
	{ "Bush", "Berry Bush", "Nature", 1, 1, { "bush" }, nil, function(m, rng)
		Nature.Bush(m, O, 0.8, rng, true)
	end },
	{ "Flowers", "Flower Patch", "Nature", 1, 1, { "flower" }, nil, function(m, rng)
		Nature.FlowerPatch(m, O, 0.9, rng)
	end },
	{ "Rock", "Mossy Rock", "Nature", 1, 1, { "rock" }, nil, function(m, rng)
		Nature.Rock(m, O, 0.7, rng, true)
	end },
	{ "BigRock", "Boulder Den", "Nature", 2, 2, { "rock" }, "Shelter", function(m, rng)
		Decor.BigRock(m, O, rng)
	end },
	{ "Log", "Hollow Log", "Nature", 2, 1, { "log" }, "Enrichment", function(m)
		Nature.Log(m, O, 1)
	end },
	{ "Burrow", "Cozy Burrow", "Nature", 1, 1, { "burrow" }, "Shelter", function(m)
		Decor.SmallBurrow(m, O)
	end },
	{ "Sand", "Sand Patch", "Nature", 2, 2, { "sand" }, nil, function(m, rng)
		Structures.SandPatch(m, O, rng)
	end },
	{ "Sunspot", "Sun Stone", "Nature", 1, 1, { "sunspot" }, nil, function(m)
		Decor.Sunspot(m, O)
	end },
	{ "Pond", "Lily Pond", "Feature", 3, 3, { "water" }, "Water", function(m, rng)
		Nature.Pond(m, O, 1, rng)
	end },
	{ "Waterfall", "Little Waterfall", "Feature", 2, 2, { "water" }, "Water", function(m, rng)
		Structures.Waterfall(m, CFrame.new(0, 0, 0.6), rng)
	end },
	{ "FoodBowl", "Food Bowl", "Feature", 1, 1, {}, "Food", function(m)
		Structures.FoodBowl(m, O)
	end },
	{ "WaterTrough", "Water Trough", "Feature", 2, 1, {}, "Water", function(m)
		Structures.WaterTrough(m, O)
	end },
	{ "ShelterHut", "Shelter Hut", "Feature", 2, 2, {}, "Shelter", function(m, rng)
		Structures.ShelterHut(m, O, rng)
	end },
	{ "ToyBall", "Toy Ball", "Feature", 1, 1, {}, "Toy", function(m, rng)
		Structures.ToyBall(m, O, rng)
	end },
	{ "VipFountain", "VIP Golden Fountain", "Special", 2, 2, {}, "Enrichment", function(m)
		Decor.VipFountain(m, O)
	end },
	{ "CrystalCluster", "Crystal Cluster", "Special", 1, 1, {}, "Enrichment", function(m, rng)
		Decor.CrystalCluster(m, O, rng)
	end },
	{ "GrottoArch", "Grotto Arch", "Special", 3, 1, {}, "Enrichment", function(m, rng)
		Decor.GrottoArch(m, O, rng)
	end },
	{ "GlowShroom", "Glow Shroom", "Special", 1, 1, {}, "Enrichment", function(m, rng)
		Decor.GlowShroom(m, O, rng)
	end },
	{ "StarterArch", "Explorer's Arch", "Special", 3, 1, {}, "Enrichment", function(m)
		Decor.StarterArch(m, O)
	end },
	{ "FieldTent", "Field Tent", "Special", 2, 2, {}, "Shelter", function(m)
		Decor.FieldTent(m, O)
	end },
	{ "JournalSign", "Journal Signpost", "Special", 1, 1, {}, "Enrichment", function(m)
		Decor.JournalSign(m, O)
	end },
	{ "MossStatue", "Moss Statue", "Special", 1, 1, {}, "Enrichment", function(m)
		Decor.MossStatue(m, O)
	end },
	{ "RainbowFlowers", "Rainbow Flowers", "Special", 1, 1, { "flower" }, "Enrichment", function(m, rng)
		Decor.RainbowFlowers(m, O, rng)
	end },
	{ "StoneTotem", "Stone Totem", "Special", 1, 1, { "rock" }, "Enrichment", function(m)
		Decor.StoneTotem(m, O)
	end },
}

Props.Items = {} :: { [string]: ItemVisual }
for _, r in ROWS do
	local id = r[1] :: string
	local build = r[8] :: Builder
	Props.Items[id] = {
		Name = r[2],
		Category = r[3],
		Foot = { r[4], r[5] },
		Tags = r[6],
		Role = r[7],
		Build = build,
	}
end

-- Build an item model (unparented). seed keeps random colours stable for the same placed item.
-- footX/footZ override the footprint (e.g. from Items.Defs W/D) for unknown or resized items.
function Props.Build(itemId: string, seed: number?, footX: number?, footZ: number?): Model?
	local def = Props.Items[itemId]
	local fx = footX or (if def then def.Foot[1] else 1)
	local fz = footZ or (if def then def.Foot[2] else 1)
	local m = Kit.Model(nil, itemId)
	if def then
		def.Build(m, Random.new(seed or 1))
	else
		-- Unknown id: a tidy flower planter so the game never shows a grey box.
		Kit.Solid(m, Vector3.new(fx * 4 - 0.6, 1, fz * 4 - 0.6), CFrame.new(0, 0.5, 0), P.Wood, Enum.Material.WoodPlanks)
		Nature.FlowerPatch(m, CFrame.new(0, 1, 0), 1, Random.new(seed or 1))
	end
	local root = Kit.Block(m, Vector3.new(fx * 4, 0.2, fz * 4), CFrame.new(0, 0.1, 0), P.Cream)
	root.Name = "Root"
	root.Transparency = 1
	root.CastShadow = false
	m.PrimaryPart = root
	m:SetAttribute("ItemId", itemId)
	m:SetAttribute("Category", if def then def.Category else "Decor")
	m:SetAttribute("FootX", fx)
	m:SetAttribute("FootZ", fz)
	m:SetAttribute("BiomeTags", if def then table.concat(def.Tags, ",") else "")
	if def and def.Role then
		m:SetAttribute(def.Role, true)
	end
	return m
end

-- Ghost copy for build-mode preview: translucent, tinted green (valid) / red (invalid), no collisions.
function Props.Ghost(itemId: string, valid: boolean): Model?
	local m = Props.Build(itemId, 1)
	if not m then
		return nil
	end
	local tint = if valid then Color3.fromHex("#7CFF9A") else Color3.fromHex("#FF6B6B")
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			d.Transparency = math.max(d.Transparency, 0.45)
			d.Color = d.Color:Lerp(tint, 0.35)
			d.CanCollide = false
			d.CanQuery = false
			d.CastShadow = false
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("SurfaceGui") then
			d:Destroy()
		end
	end
	return m
end

return Props
