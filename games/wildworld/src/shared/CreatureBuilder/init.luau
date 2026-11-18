--!strict
-- Builds code-built creature models from shared/CreatureBlueprints + genes + mutations (Graphics).
--
--   CreatureBuilder.Build(species, opts?) -> Model?
--     opts = { genes = "Cc|Pp|Ss|Gg", mutations = {"Golden", ...}, stage = "Baby"|"Juvenile"|"Adult",
--              seed = number (stable hue/size jitter, e.g. hash of uid) }
--   CreatureBuilder.FromLook(species, look) -> Model?  gameplay look table { genes, mutations, stage, hue, scale, bow }
--     (scale = final scale incl. size gene + baby scale; hue = hue shift; bow = Starter Pack bow)
--   CreatureBuilder.BuildEgg(species, opts?) -> Model?   opts = { mutations?, seed? }
--   CreatureBuilder.ScaleFor(genes, stage, seed) -> number
--
-- Model: PrimaryPart = invisible "Hitbox" (CanQuery, the click/prompt target); model pivot = ground point
-- under the creature, facing -Z. Every part is anchored, non-colliding, massless.
-- Part attributes: Role, Anim, Rest (CFrame relative to Hitbox, for the client animator).
-- Model attributes: Species, Genes, Mutations ("Golden,Crystal"), Stage, Scale, HeadPivot (Vector3, rel. Hitbox),
--   Pulse (bool, Glowing: client pulses the PointLight 0.6..1.2 over 2 s).
-- Lights tagged "NightLight" should only be enabled at night (Lighting attribute IsNight).
local Lighting = game:GetService("Lighting")
local Blueprints = require(script.Parent.CreatureBlueprints).Species
local Shapes = require(script.Parent.CreatureBlueprints.Shapes)
local Mutations = require(script.Mutations)

local CreatureBuilder = {}
CreatureBuilder.Species = Blueprints

export type BuildOpts = {
	genes: string?,
	mutations: { string }?,
	stage: string?,
	seed: number?,
	scale: number?, -- absolute scale override (gameplay already folded in size gene / baby scale)
	hue: number?, -- hue shift override (-0.06..0.06) instead of the seeded jitter
	bow: boolean?, -- Starter Pack creature bow
}

local STAGE_SCALE: { [string]: number } = { Baby = 0.5, Juvenile = 0.75, Adult = 1 }
local HEAD_GROUP: { [string]: boolean } = { Head = true, EarL = true, EarR = true }
local HUE_JITTER = 0.06
local SIZE_JITTER = 0.03
local CACHE_MAX = 64

local cache: { [string]: Model } = {}
local cacheCount = 0

-- "Cc|Pp|Ss|Gg" -> { Color = "Cc", Pattern = "Pp", Size = "Ss", Glow = "Gg" }
local function parseGenes(genes: string?): { [string]: string }
	local out = { Color = "CC", Pattern = "PP", Size = "SS", Glow = "GG" }
	if genes then
		local keys = { "Color", "Pattern", "Size", "Glow" }
		local i = 1
		for pair in string.gmatch(genes, "[^|]+") do
			if keys[i] then
				out[keys[i]] = pair
			end
			i += 1
		end
	end
	return out
end

local function recessive(pair: string): boolean
	return pair == string.lower(pair)
end

function CreatureBuilder.ScaleFor(genes: string?, stage: string?, seed: number?): number
	local g = parseGenes(genes)
	local sizeMult = if recessive(g.Size) then 0.85 elseif g.Size ~= string.upper(g.Size) then 0.95 else 1
	local rng = Random.new(seed or 0)
	rng:NextNumber() -- keep in step with colour jitter order
	local jitter = 1 + rng:NextNumber(-SIZE_JITTER, SIZE_JITTER)
	return (STAGE_SCALE[stage or "Adult"] or 1) * sizeMult * jitter
end

local function shiftHue(c: Color3, dh: number): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV((h + dh) % 1, s, v)
end

local function makePart(spec: Shapes.PartSpec): BasePart
	local part: BasePart
	if spec.Shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		if spec.Shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		elseif spec.Shape == "Cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
		part = p
		if spec.Shape == "Blob" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
	end
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = spec.Shadow == true
	part.Transparency = spec.Transparency or 0
	part.Name = spec.Name
	part:SetAttribute("Role", spec.Role)
	part:SetAttribute("Anim", spec.Anim)
	return part
end

local function build(species: string, opts: BuildOpts): Model?
	local bp = Blueprints[species]
	if not bp then
		warn("[CreatureBuilder] unknown species", species)
		return nil
	end
	local g = parseGenes(opts.genes)
	local stage = opts.stage or "Adult"
	local scale = opts.scale or CreatureBuilder.ScaleFor(opts.genes, stage, opts.seed)
	local rng = Random.new(opts.seed or 0)
	local jitter = rng:NextNumber(-HUE_JITTER, HUE_JITTER) * 0.5
	local hue = if opts.hue then math.clamp(opts.hue, -HUE_JITTER, HUE_JITTER) else jitter

	-- Palette: base, Color gene cc swaps to the alt palette, hue jitter on body colours.
	local palette: { [string]: Color3 } = table.clone(bp.Palette)
	if recessive(g.Color) then
		for k, v in bp.AltPalette do
			palette[k] = v
		end
	end
	palette.Primary = shiftHue(palette.Primary, hue)
	palette.Secondary = shiftHue(palette.Secondary, hue)
	palette.Eye = Color3.fromHex("#1E1B2E")
	palette.EyeShine = Color3.new(1, 1, 1)
	palette.Cheek = Color3.fromHex("#FF9EB5")
	local showPattern = recessive(g.Pattern)
	local neonMarks = recessive(g.Glow)
	local baby = stage == "Baby"
	local pivot = bp.HeadPivot

	local model = Instance.new("Model")
	model.Name = species
	local minV, maxV = Vector3.one * math.huge, -Vector3.one * math.huge
	local parts: { BasePart } = {}
	for _, spec in bp.Parts do
		if spec.Pattern and not showPattern then
			continue
		end
		local part = makePart(spec)
		local cf, size = spec.CF, spec.Size
		if baby and HEAD_GROUP[spec.Anim] then
			cf = CFrame.new(pivot + (cf.Position - pivot) * 1.25) * cf.Rotation
			size *= 1.25
		end
		part.Size = size * scale
		part.CFrame = CFrame.new(cf.Position * scale) * cf.Rotation
		part.Color = palette[spec.Role] or palette.Primary
		if neonMarks and spec.Role == "Glow" then
			part.Material = Enum.Material.Neon
		end
		part.Parent = model
		table.insert(parts, part)
		local half = part.Size / 2
		minV = minV:Min(part.Position - half)
		maxV = maxV:Max(part.Position + half)
	end

	-- Hitbox = PrimaryPart, centred on the bounds; pivot = ground point below.
	local hb = Instance.new("Part")
	hb.Name = "Hitbox"
	hb.Anchored = true
	hb.CanCollide = false
	hb.CanTouch = false
	hb.CanQuery = true
	hb.Massless = true
	hb.Transparency = 1
	hb.CastShadow = false
	local center = (minV + maxV) / 2
	local box = (maxV - minV) * 1.05
	hb.Size = box
	hb.CFrame = CFrame.new(center)
	hb.PivotOffset = CFrame.new(0, -center.Y, 0)
	hb.Parent = model
	model.PrimaryPart = hb

	-- Native VFX (one emitter + one light max; mutations may replace them).
	local host = model:FindFirstChild(bp.EmitterPart) :: BasePart?
	if host and bp.Native.NightLight then
		local light = Instance.new("PointLight")
		light.Range = bp.Native.NightLight * scale
		light.Brightness = 0.8
		light.Color = palette.Glow
		light.Shadows = false
		light.Parent = host
		host:AddTag("NightLight")
	end
	if host and bp.Native.Emitter == "Embers" then
		local e = Mutations.Effects.Embers()
		e.Parent = host
	end

	local muts = opts.mutations or {}
	Mutations.Apply(model, bp, muts, palette, scale)
	if opts.bow then
		Mutations.Bow(model, scale)
	end

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= hb then
			d:SetAttribute("Rest", hb.CFrame:ToObjectSpace(d.CFrame))
		end
	end
	model:SetAttribute("Species", species)
	model:SetAttribute("Genes", opts.genes or "CC|PP|SS|GG")
	model:SetAttribute("Mutations", table.concat(muts, ","))
	model:SetAttribute("Stage", stage)
	model:SetAttribute("Scale", scale)
	model:SetAttribute("HeadPivot", pivot * scale - hb.Position)
	model:PivotTo(CFrame.new())
	return model
end

-- Night-only lights (Lumibun ears) start in the current day/night state.
local function syncNight(m: Model): Model
	local night = Lighting:GetAttribute("IsNight") == true
	for _, d in m:GetDescendants() do
		if d:IsA("Light") and d.Parent and d.Parent:HasTag("NightLight") then
			d.Enabled = night
		end
	end
	return m
end

-- Build (or clone from cache) a creature model. Unparented; PivotTo it where it should stand.
function CreatureBuilder.Build(species: string, opts: BuildOpts?): Model?
	local o: BuildOpts = opts or {}
	local muts = table.clone(o.mutations or {})
	table.sort(muts)
	local key = table.concat({
		species,
		o.genes or "",
		table.concat(muts, ","),
		o.stage or "Adult",
		tostring(o.seed or 0),
		string.format("%.3f|%.3f", o.scale or 0, o.hue or 0),
		if o.bow then "bow" else "",
	}, "|")
	local hit = cache[key]
	if hit then
		return syncNight(hit:Clone())
	end
	local m = build(species, o)
	if not m then
		return nil
	end
	if cacheCount >= CACHE_MAX then
		for k, v in cache do
			v:Destroy()
			cache[k] = nil
		end
		cacheCount = 0
	end
	cache[key] = m
	cacheCount += 1
	return syncNight(m:Clone())
end

-- Adapter for gameplay's look table (server/Services/Models.luau).
function CreatureBuilder.FromLook(species: string, look: any?): Model?
	local l = if type(look) == "table" then look else {}
	local genes = if type(l.genes) == "string" then l.genes else nil
	if not genes and type(l.traits) == "table" then
		local t = l.traits
		genes = table.concat({
			if t.altColor then "cc" else "CC",
			if t.spots then "pp" else "PP",
			"SS",
			if t.glow then "gg" else "GG",
		}, "|")
	end
	return CreatureBuilder.Build(species, {
		genes = genes,
		mutations = if type(l.mutations) == "table" then l.mutations else nil,
		stage = if type(l.stage) == "string" then l.stage else nil,
		scale = if type(l.scale) == "number" then l.scale else nil,
		hue = if type(l.hue) == "number" then l.hue else nil,
		bow = l.bow == true,
	})
end

-- Egg: ellipsoid shell in the species Primary with Secondary spots (Golden mutation = gold Metal + sparkle).
function CreatureBuilder.BuildEgg(species: string, opts: BuildOpts?): Model?
	local bp = Blueprints[species]
	if not bp then
		return nil
	end
	local o: BuildOpts = opts or {}
	return Mutations.Egg(bp, o.mutations or {}, o.seed or 0)
end

return CreatureBuilder
