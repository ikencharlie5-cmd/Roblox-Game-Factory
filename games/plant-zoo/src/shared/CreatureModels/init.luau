--!strict
-- Builds cute plant-creature models from primitives (works on server or client, e.g. ViewportFrames).
--   CreatureModels.Build(species, stage, opts?) -> Model  (PrimaryPart = "Root" at the feet, front = -Z)
--   CreatureModels.ApplyLook(model, {Color=?, Weather=?, Thriving=?})  -- mutations / Thriving FX
--   CreatureModels.StepRainbow(model, hue)                               -- call repeatedly for Rainbow
-- Structure: Root (Anchored, invisible) --Weld "Bob"--> Body (invisible) <-WeldConstraint- visible parts.
-- Move the creature by setting Root.CFrame (or PivotTo); bob by tweening the "Bob" weld's C0.
local Theme = require(script.Parent.Theme)
local Looks = require(script.Looks)
local Kinds = require(script.Kinds)
local Tops = require(script.Tops)
local Effects = require(script.Effects)

local CreatureModels = {}
CreatureModels.Stages = { "Seed", "Sprout", "Bud", "Grown" }
CreatureModels.ApplyLook = Effects.ApplyLook
CreatureModels.StepRainbow = Effects.StepRainbow

export type Opts = { Color: string?, Weather: string?, Thriving: boolean?, Scale: number? }

local byNorm: { [string]: Looks.Look } = {}
for name, look in Looks do
	byNorm[Theme.Normalize(name)] = look
end

local DEFAULT: Looks.Look =
	{ Kind = "blob", Body = "#7BD148", Accent = "#FFD54F", Top = "sprout", Rarity = "Common", Biome = "Meadow" }

function CreatureModels.GetLook(species: string): Looks.Look
	return Looks[species] or byNorm[Theme.Normalize(species)] or DEFAULT
end

function CreatureModels.StageName(stage: (string | number)?): string
	if typeof(stage) == "number" then
		return CreatureModels.Stages[math.clamp(math.floor(stage), 1, 4)]
	end
	if typeof(stage) == "string" then
		for _, s in CreatureModels.Stages do
			if string.lower(s) == string.lower(stage) then
				return s
			end
		end
	end
	return "Grown"
end

local function basePart(name: string, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Transparency = 1
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function makeAdd(model: Model, body: BasePart, s: number): Kinds.Add
	return function(shape: string, size: Vector3, offset: CFrame, color: Color3, o: Kinds.AddOpts?): BasePart
		local opts: Kinds.AddOpts = o or {}
		local cf = body.CFrame * CFrame.new(offset.Position * s) * offset.Rotation
		local part: BasePart
		if shape == "wedge" then
			part = Instance.new("WedgePart")
			part.Size = size * s
		else
			local p = Instance.new("Part")
			if shape == "ball" then
				p.Shape = Enum.PartType.Ball
			elseif shape == "cyl" then
				p.Shape = Enum.PartType.Cylinder
				size = Vector3.new(size.Y, size.X, size.Z)
				cf = cf * CFrame.Angles(0, 0, math.rad(90))
			elseif shape == "blob" then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = p
			end
			p.Size = size * s
			part = p
		end
		part.CFrame = cf
		part.Color = color
		part.Material = opts.mat or Enum.Material.SmoothPlastic
		part.Transparency = opts.transparency or 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		local skin = if opts.skin == nil then part.Material ~= Enum.Material.Neon else opts.skin
		if skin then
			part:SetAttribute("Skin", true)
			part:SetAttribute("BaseColor", color)
			part:SetAttribute("BaseMat", part.Material.Name)
		end
		weld(body, part)
		part.Parent = model
		return part
	end
end

local function face(add: Kinds.Add, head: CFrame, r: number)
	local black = Color3.fromHex("#1B1B2A")
	for _, x in { -1, 1 } do
		add(
			"ball",
			Vector3.one * 0.5 * r,
			head * CFrame.new(x * 0.42 * r, 0.15 * r, -0.83 * r),
			Color3.new(1, 1, 1),
			{ skin = false }
		)
		add("ball", Vector3.one * 0.3 * r, head * CFrame.new(x * 0.42 * r, 0.17 * r, -1.0 * r), black, { skin = false })
		add(
			"blob",
			Vector3.new(0.4 * r, 0.2 * r, 0.1 * r),
			head * CFrame.new(x * 0.66 * r, -0.25 * r, -0.74 * r) * CFrame.Angles(0, math.rad(-x * 35), 0),
			Color3.fromHex("#FF9EB5"),
			{ skin = false }
		)
	end
end

local function buildStage(add: Kinds.Add, stage: string, look: Looks.Look)
	local b, a = Color3.fromHex(look.Body), Color3.fromHex(look.Accent)
	local dirt = Color3.fromHex("#7A4E2D")
	add("blob", Vector3.new(2.6, 0.9, 2.6), CFrame.new(0, 0.15, 0), dirt, { skin = false, mat = Enum.Material.Ground })
	if stage == "Seed" then
		add("ball", Vector3.one * 0.6, CFrame.new(0, 0.6, 0), a, { skin = false })
		return
	end
	local leaf = Color3.fromHex("#8BD65A")
	local h = if stage == "Sprout" then 0.9 else 1.6
	add("cyl", Vector3.new(0.3, h, 0.3), CFrame.new(0, 0.4 + h / 2, 0), Color3.fromHex("#4CAF50"), { skin = false })
	local ly = if stage == "Sprout" then 0.4 + h else 0.9
	for _, x in { -1, 1 } do
		add(
			"blob",
			Vector3.new(1.4, 0.15, 0.7),
			CFrame.new(x * 0.6, ly, 0) * CFrame.Angles(0, 0, math.rad(-x * 25)),
			leaf,
			{ skin = false }
		)
	end
	if stage == "Bud" then
		add("blob", Vector3.new(1.5, 2.1, 1.5), CFrame.new(0, 2.6, 0), b)
		for i = 0, 2 do
			local cf = CFrame.new(0, 3.2, 0) * CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(0, 0, -0.45)
			add("blob", Vector3.new(0.5, 1, 0.3), cf * CFrame.Angles(math.rad(-15), 0, 0), a)
		end
	end
end

function CreatureModels.Build(species: string, stage: (string | number)?, opts: Opts?): Model
	local o: Opts = opts or {}
	local look = CreatureModels.GetLook(species)
	local stageName = CreatureModels.StageName(stage)
	local s = if stageName == "Grown" then (Theme.RarityScale[look.Rarity] or 1) * (o.Scale or 1) else 1

	local model = Instance.new("Model")
	model.Name = species
	local root = basePart("Root", Vector3.new(2, 0.2, 2) * s, CFrame.new())
	root.Anchored = true
	root.Parent = model
	local body = basePart("Body", Vector3.one * 0.2, CFrame.new())
	body.Parent = model
	local bob = Instance.new("Weld")
	bob.Name = "Bob"
	bob.Part0 = root
	bob.Part1 = body
	bob.Parent = root
	model.PrimaryPart = root

	local add = makeAdd(model, body, s)
	if stageName == "Grown" then
		local b, a = Color3.fromHex(look.Body), Color3.fromHex(look.Accent)
		local kindFn = (Kinds :: any)[look.Kind] or Kinds.blob
		local head, r = kindFn(add, b, a)
		face(add, head, r)
		local top = Tops[look.Top]
		if top then
			top(add, head, r, b, a)
		end
	else
		buildStage(add, stageName, look)
	end

	model:SetAttribute("Species", species)
	model:SetAttribute("Stage", stageName)
	model:SetAttribute("Rarity", look.Rarity)
	model:SetAttribute("Kind", look.Kind)
	model:SetAttribute("Scale", s)
	CreatureModels.ApplyLook(model, o :: any)
	return model
end

return CreatureModels
