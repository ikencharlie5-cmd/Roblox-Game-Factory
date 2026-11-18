--!strict
-- Mutation visual layers (ART_STYLE_GUIDE §5.4), applied in a fixed order: recolour -> material ->
-- attachments -> VFX. MVP: Golden, Albino, Crystal, Glowing (+ Golden+Crystal = "Gilded Crystal").
-- Golden and Albino both recolour, so if both are present the rarer one (Albino) wins.
-- Budget: at most 1 ParticleEmitter + 1 PointLight per creature; mutation VFX replace native ones.
local Shapes = require(script.Parent.Parent.CreatureBlueprints.Shapes)
local Effects = require(script.Parent.Parent.Theme.Effects)

local Mutations = {}
Mutations.Effects = Effects

local hex = Color3.fromHex
local GOLD = hex("#F5C542")
local GOLD_BELLY = hex("#FFE59A")
local CRYSTAL = hex("#9FE8FF")
local GILDED = hex("#FFE9A8")
local ALBINO_P = hex("#F6F2EE")
local ALBINO_S = hex("#FFE6EC")
local ALBINO_EYE = hex("#E8505B")

local BODY_ROLES: { [string]: boolean } = { Primary = true, Secondary = true, Accent = true, Feature = true }

local function has(list: { string }, name: string): boolean
	return table.find(list, name) ~= nil
end

local function forParts(model: Model, fn: (BasePart, string) -> ())
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "Hitbox" then
			fn(d, (d:GetAttribute("Role") :: string?) or "")
		end
	end
end

local function clearVfx(model: Model, emitters: boolean, lights: boolean)
	for _, d in model:GetDescendants() do
		if (emitters and d:IsA("ParticleEmitter")) or (lights and d:IsA("Light")) then
			if d.Parent then
				d.Parent:RemoveTag("NightLight")
			end
			d:Destroy()
		end
	end
end

local function pale(c: Color3): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s * 0.25, math.max(v, 0.9))
end

function Mutations.Apply(model: Model, bp: Shapes.Blueprint, list: { string }, palette: { [string]: Color3 }, scale: number)
	if #list == 0 then
		return
	end
	local golden = has(list, "Golden")
	local albino = has(list, "Albino")
	local crystal = has(list, "Crystal")
	local glowing = has(list, "Glowing")
	if golden and albino then
		golden = false -- exclusive recolours: rarer wins
	end
	local host = (model:FindFirstChild(bp.EmitterPart) :: BasePart?) or model.PrimaryPart

	-- 1) Recolour + material
	forParts(model, function(p, role)
		if albino then
			if role == "Primary" or role == "Feature" then
				p.Color = ALBINO_P
			elseif role == "Secondary" or role == "Belly" then
				p.Color = ALBINO_S
			elseif role == "Accent" or role == "Glow" then
				p.Color = pale(p.Color)
			elseif role == "Eye" then
				p.Color = ALBINO_EYE
			end
		elseif golden then
			if BODY_ROLES[role] or role == "Glow" then
				p.Color = GOLD
				p.Material = Enum.Material.Metal
			elseif role == "Belly" then
				p.Color = GOLD_BELLY
				p.Material = Enum.Material.Metal
			end
		end
		if crystal and not golden and role == "Primary" then
			p.Color = p.Color:Lerp(CRYSTAL, 0.3)
		end
		if glowing and (role == "Glow" or role == "Accent") and p.Size.Magnitude < 3.2 then
			p.Material = Enum.Material.Neon
		end
	end)

	-- 2) Attachments: Crystal shards (Glass, 0.25 transparency) along the back / hero feature.
	if crystal then
		local shardColor = if golden then GILDED else CRYSTAL
		local hb = model.PrimaryPart
		for i, s in bp.Shards do
			local shard = Instance.new("Part")
			shard.Name = "Shard" .. i
			shard.Anchored = true
			shard.CanCollide = false
			shard.CanTouch = false
			shard.CanQuery = false
			shard.Massless = true
			shard.CastShadow = false
			shard.Material = Enum.Material.Glass
			shard.Transparency = 0.25
			shard.Color = shardColor
			shard.Size = Vector3.new(0.45, s.Len, 0.45) * scale
			shard.CFrame = CFrame.new(s.CF.Position * scale) * s.CF.Rotation
			shard:SetAttribute("Role", "Crystal")
			shard:SetAttribute("Anim", s.Anim)
			shard.Parent = model
		end
		if hb then
			hb.Size = hb.Size + Vector3.new(0, 0.6 * scale, 0)
		end
	end

	-- 3) VFX: one emitter, one light (merged colours).
	if golden and host then
		clearVfx(model, true, false)
		local e = Effects.Sparkle(hex("#FFE27A"), 3)
		e.Parent = host
	end
	if (crystal or glowing) and host then
		clearVfx(model, false, true)
		local light = Instance.new("PointLight")
		light.Shadows = false
		if glowing then
			light.Range = 8 * math.max(scale, 0.6)
			light.Brightness = 1
			light.Color = if crystal then (palette.Glow or CRYSTAL):Lerp(CRYSTAL, 0.5) else (palette.Glow or CRYSTAL)
			model:SetAttribute("Pulse", true)
		else
			light.Range = 6 * math.max(scale, 0.6)
			light.Brightness = 0.6
			light.Color = if golden then GILDED else CRYSTAL
		end
		light.Parent = host
	end
end

-- Starter Pack bow: two coral loops + a knot on top of the head (Role "Accessory", Anim "Head").
function Mutations.Bow(model: Model, scale: number)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local top = head.Position + Vector3.new(head.Size.X * 0.28, head.Size.Y * 0.44, 0)
	local coral = hex("#FF6F91")
	local function piece(name: string, size: Vector3, cf: CFrame)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = coral
		p.Size = size * scale
		p.CFrame = cf
		p:SetAttribute("Role", "Accessory")
		p:SetAttribute("Anim", "Head")
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		p.Parent = model
	end
	piece("BowL", Vector3.new(0.7, 0.45, 0.3), CFrame.new(top + Vector3.new(-0.3 * scale, 0, 0)) * CFrame.Angles(0, 0, math.rad(15)))
	piece("BowR", Vector3.new(0.7, 0.45, 0.3), CFrame.new(top + Vector3.new(0.3 * scale, 0, 0)) * CFrame.Angles(0, 0, math.rad(-15)))
	piece("BowKnot", Vector3.new(0.28, 0.28, 0.32), CFrame.new(top))
end

-- Egg model: 2.4-stud tall ellipsoid shell + 3 spots, Hitbox PrimaryPart, pivot at the egg's base.
function Mutations.Egg(bp: Shapes.Blueprint, list: { string }, seed: number): Model
	local rng = Random.new(seed)
	local golden = has(list, "Golden")
	local model = Instance.new("Model")
	model.Name = bp.Species .. "Egg"
	local function blob(name: string, size: Vector3, cf: CFrame, color: Color3, role: string): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.Material = if golden then Enum.Material.Metal else Enum.Material.SmoothPlastic
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.CastShadow = name == "Shell"
		p:SetAttribute("Role", role)
		p:SetAttribute("Anim", "Body")
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		p.Parent = model
		return p
	end
	local shellColor = if golden then GOLD else bp.Palette.Primary
	local spotColor = if golden then GOLD_BELLY else bp.Palette.Secondary
	local shell = blob("Shell", Vector3.new(2, 2.5, 2), CFrame.new(0, 1.25, 0), shellColor, "Primary")
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local y = rng:NextNumber(0.8, 1.9)
		local pos = Vector3.new(math.cos(a) * 0.9, y, math.sin(a) * 0.9)
		blob("Spot" .. i, Vector3.new(0.7, 0.6, 0.25), CFrame.lookAt(pos, Vector3.new(0, y, 0)), spotColor, "Secondary")
	end
	local hb = Instance.new("Part")
	hb.Name = "Hitbox"
	hb.Anchored = true
	hb.CanCollide = false
	hb.CanTouch = false
	hb.CanQuery = true
	hb.Transparency = 1
	hb.Size = Vector3.new(2.4, 2.8, 2.4)
	hb.CFrame = CFrame.new(0, 1.4, 0)
	hb.PivotOffset = CFrame.new(0, -1.4, 0)
	hb.Parent = model
	model.PrimaryPart = hb
	if golden then
		Effects.Sparkle(hex("#FFE27A"), 3).Parent = shell
	end
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d ~= hb then
			d:SetAttribute("Rest", hb.CFrame:ToObjectSpace(d.CFrame))
		end
	end
	model:SetAttribute("Species", bp.Species)
	model:SetAttribute("Mutations", table.concat(list, ","))
	model:SetAttribute("IsEgg", true)
	return model
end

return Mutations
