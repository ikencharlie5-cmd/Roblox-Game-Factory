--!strict
-- Helper (not a service): builds item / creature / egg models. Uses Graphics' builders when present:
--   Shared.Theme.Props.Build(itemId, seed) -> Model?            (pivot = footprint centre, ground)
--   Shared.CreatureBuilder.Build(species, {genes, mutations, stage, seed}) -> Model? (pivot = ground point)
--   Shared.CreatureBuilder.BuildEgg(species, {mutations, seed}) -> Model?
-- Otherwise simple coloured fallbacks so the game always works.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Species = require(Shared:WaitForChild("Species"))
local Genetics = require(Shared:WaitForChild("Genetics"))

local Models = {}

local function tryRequire(parent: Instance?, name: string): any
	local m = parent and parent:FindFirstChild(name)
	if m and m:IsA("ModuleScript") then
		local ok, res = pcall(require, m)
		if ok then
			return res
		end
		warn("[Models] failed to require", name, res)
	end
	return nil
end

local itemBuilder: any = nil
local creatureBuilder: any = nil
local looked = false
local function builders()
	if looked then
		return
	end
	looked = true
	local theme = tryRequire(Shared, "Theme")
	itemBuilder = theme and theme.Props
	creatureBuilder = tryRequire(Shared, "CreatureBuilder")
end

local KIND_COLOR: { [string]: Color3 } = {
	pad = Color3.fromRGB(108, 198, 68),
	path = Color3.fromRGB(200, 190, 170),
	fence = Color3.fromRGB(138, 90, 59),
	tree = Color3.fromRGB(79, 191, 74),
	bush = Color3.fromRGB(122, 214, 90),
	flower = Color3.fromRGB(255, 179, 217),
	rock = Color3.fromRGB(150, 150, 140),
	log = Color3.fromRGB(138, 90, 59),
	burrow = Color3.fromRGB(110, 80, 60),
	sand = Color3.fromRGB(235, 215, 160),
	sunspot = Color3.fromRGB(250, 200, 120),
	water = Color3.fromRGB(60, 195, 232),
	food = Color3.fromRGB(230, 120, 80),
	drink = Color3.fromRGB(60, 195, 232),
	shelter = Color3.fromRGB(170, 120, 80),
	toy = Color3.fromRGB(255, 90, 90),
	light = Color3.fromRGB(255, 243, 160),
	stand = Color3.fromRGB(255, 160, 80),
	decor = Color3.fromRGB(185, 164, 255),
}

local function fallbackItem(def: any): Model
	local m = Instance.new("Model")
	local cell = Config.Grid.Cell
	local h = if def.Layer == "floor" then 0.4 elseif def.Kind == "tree" then 10 else 2
	local p = Instance.new("Part")
	p.Name = "Body"
	p.Anchored = true
	p.Size = Vector3.new(def.W * cell - 0.2, h, def.D * cell - 0.2)
	p.CFrame = CFrame.new(0, h / 2, 0)
	p.Color = KIND_COLOR[def.Kind] or Color3.new(1, 1, 1)
	p.Material = if def.Kind == "water" then Enum.Material.Glass else Enum.Material.SmoothPlastic
	p.Parent = m
	m.PrimaryPart = p
	m.WorldPivot = CFrame.new()
	return m
end

-- Model with pivot at footprint centre / ground level. seed = item uid (stable colours).
function Models.Item(def: any, seed: number?): Model
	builders()
	if itemBuilder and itemBuilder.Build and itemBuilder.Items and itemBuilder.Items[def.Id] then
		local ok, m = pcall(itemBuilder.Build, def.Id, seed)
		if ok and typeof(m) == "Instance" and m:IsA("Model") then
			return m
		end
		warn("[Models] Theme.Props.Build failed for", def.Id, m)
	end
	return fallbackItem(def)
end

-- Stable number from a uid string (creature look seed).
function Models.Seed(s: string): number
	local h = 7
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % 2147483647
	end
	return h
end

local function fallbackCreature(species: string, look: any): Model
	local def = Species[species]
	local m = Instance.new("Model")
	local scale = look.scale or 1
	local color = if look.traits.altColor then def.Alt else def.Main
	if table.find(look.mutations, "Golden") then
		color = Color3.fromRGB(255, 205, 60)
	elseif table.find(look.mutations, "Albino") then
		color = Color3.fromRGB(250, 250, 250)
	end
	local hit = Instance.new("Part")
	hit.Name = "Hitbox"
	hit.Anchored = true
	hit.CanCollide = false
	hit.Transparency = 1
	hit.Size = Vector3.new(3, 3, 3) * scale
	hit.CFrame = CFrame.new(0, 1.5 * scale, 0)
	hit.Parent = m
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Anchored = true
	body.CanCollide = false
	body.Size = Vector3.new(2.6, 2.6, 2.6) * scale
	body.CFrame = hit.CFrame
	body.Color = color
	body.Material = if table.find(look.mutations, "Crystal") then Enum.Material.Glass else Enum.Material.SmoothPlastic
	body:SetAttribute("Role", "Body")
	body.Parent = m
	local head = body:Clone()
	head.Name = "Head"
	head.Size = Vector3.new(1.6, 1.6, 1.6) * scale
	head.CFrame = hit.CFrame * CFrame.new(0, 1.1 * scale, -1 * scale)
	head:SetAttribute("Role", "Head")
	head.Parent = m
	m.PrimaryPart = hit
	m.WorldPivot = CFrame.new()
	return m
end

-- rec: creature record (species, genes, mutations, stage, hue, sz). Returns a Model with PrimaryPart.
function Models.Creature(rec: any, bow: boolean?): Model
	builders()
	local traits = Genetics.Traits(rec.genes)
	local scale = traits.size * (1 + (rec.sz or 0))
	if rec.stage == "Baby" then
		scale *= Config.Growth.BabyScale
	end
	local look = {
		genes = rec.genes,
		traits = traits,
		mutations = rec.mutations or {},
		stage = rec.stage,
		hue = rec.hue or 0,
		scale = scale,
		bow = bow == true,
	}
	local m: Model? = nil
	if creatureBuilder and creatureBuilder.Build then
		local opts = { genes = rec.genes, mutations = rec.mutations or {}, stage = rec.stage, seed = rec.seed or (if rec.uid then Models.Seed(rec.uid) else 1) }
		local ok, res = pcall(creatureBuilder.Build, rec.species, opts)
		if ok and typeof(res) == "Instance" and res:IsA("Model") then
			m = res
		else
			warn("[Models] CreatureBuilder.Build failed for", rec.species, res)
		end
	end
	local model = m or fallbackCreature(rec.species, look)
	model:SetAttribute("Bow", bow == true)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
		end
	end
	return model
end

-- Offset from the model pivot down to its lowest point (so feet sit on the ground).
function Models.FootOffset(model: Model): number
	local cf, size = model:GetBoundingBox()
	return model:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
end

-- World egg (starter egg) with a "Hatch!" ProximityPrompt on its PrimaryPart.
function Models.Egg(species: string, mutations: { string }, seed: number?): Model
	builders()
	local m: Model? = nil
	if creatureBuilder and creatureBuilder.BuildEgg then
		local ok, res = pcall(creatureBuilder.BuildEgg, species, { mutations = mutations, seed = seed })
		if ok and typeof(res) == "Instance" and res:IsA("Model") then
			m = res
		end
	end
	if not m then
		local nm = Instance.new("Model")
		local p = Instance.new("Part")
		p.Name = "Shell"
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.Size = Vector3.new(2.6, 2.6, 2.6)
		p.Color = if Species[species] then Species[species].Main else Color3.new(1, 1, 1)
		p.CFrame = CFrame.new(0, 1.3, 0)
		p.Parent = nm
		nm.PrimaryPart = p
		nm.WorldPivot = CFrame.new()
		m = nm
	end
	local model = m :: Model
	model.Name = "Egg"
	local target = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if target then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Hatch!"
		prompt.ObjectText = species .. " Egg"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.Parent = target
	end
	return model
end

return Models
