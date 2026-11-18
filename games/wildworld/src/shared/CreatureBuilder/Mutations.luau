--!strict
-- Mutation visual layers, brick style (STUDS_STYLE_GUIDE §5), applied in a fixed order: recolour ->
-- material -> attachments -> VFX. MVP: Golden, Albino, Crystal, Glowing (+ Golden+Crystal = "Gilded Crystal").
-- Golden and Albino both recolour, so if both are present the rarer one (Albino) wins.
-- Body parts never leave Plastic (that would remove the studs); only Glowing turns Accent/Glow parts Neon.
-- Budget: at most 1 ParticleEmitter + 1 PointLight per creature; mutation VFX replace native ones.
local Shapes = require(script.Parent.Parent.CreatureBlueprints.Shapes)
local Effects = require(script.Parent.Parent.Theme.Effects)

local Mutations = {}
Mutations.Effects = Effects

local hex = Color3.fromHex
local GOLD: { [string]: Color3 } = {
	Primary = hex("#F5C542"),
	Secondary = hex("#E0A11B"),
	Belly = hex("#FFE38A"),
	Accent = hex("#C98A12"),
	Feature = hex("#C98A12"),
	Glow = hex("#FFE38A"),
}
local ALBINO: { [string]: Color3 } = {
	Primary = hex("#F6F2EE"),
	Feature = hex("#F6F2EE"),
	Secondary = hex("#FFE6EC"),
	Belly = hex("#FFFFFF"),
	Accent = hex("#FFD6DE"),
	Eye = hex("#E8505B"),
	Cheek = hex("#FF7FA0"),
}
local CRYSTAL = hex("#9FE8FF")
local GILDED = hex("#FFE9A8")
local GLOW = hex("#7CFFB2")
local SPARKLE = hex("#FFF3A0")

local BODY_ROLES: { [string]: boolean } = { Primary = true, Secondary = true, Belly = true, Accent = true, Feature = true }

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

local function brick(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, role: string, anim: string): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	for _, f in { "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" } do
		(p :: any)[f] = Enum.SurfaceType.Studs
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p:SetAttribute("Role", role)
	p:SetAttribute("Anim", anim)
	p.Parent = model
	return p
end

-- Top of the head (highest Head-anim Primary part) for the crown plate / bow.
local function headTop(model: Model): (Vector3?, number)
	local best: BasePart? = nil
	local top = -math.huge
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d:GetAttribute("Anim") == "Head" and d:GetAttribute("Role") == "Primary" then
			local y = d.Position.Y + d.Size.Y / 2
			if y > top then
				best, top = d, y
			end
		end
	end
	if not best then
		return nil, 0
	end
	return Vector3.new(best.Position.X, top, best.Position.Z), best.Size.X
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
	local _, _, gv = (palette.Glow or GLOW):ToHSV()
	local glowColor = if gv < 0.6 then GLOW else (palette.Glow or GLOW)

	-- 1) Recolour (+ Reflectance for gold; material stays Plastic so the studs stay)
	forParts(model, function(p, role)
		if albino then
			local c = ALBINO[role]
			if c then
				p.Color = c
			elseif role == "Glow" then
				p.Color = pale(p.Color)
			end
		elseif golden then
			local c = GOLD[role]
			if c then
				p.Color = c
				p.Reflectance = 0.2
			end
		end
		if crystal and not golden and BODY_ROLES[role] then
			p.Color = p.Color:Lerp(CRYSTAL, 0.35)
		end
		if glowing and (role == "Glow" or role == "Accent") then
			p.Material = Enum.Material.Neon
			if gv < 0.6 and role == "Glow" then
				p.Color = GLOW
			end
		end
	end)

	-- 2) Attachments: golden crown plate; crystal "trans-clear" brick stacks at the blueprint mounts.
	if golden then
		local top, w = headTop(model)
		if top then
			local plate = brick(model, "Crown", Vector3.new(1, 0.4, 1) * scale, CFrame.new(top + Vector3.new(-w * 0.25, 0.2 * scale, 0)), GOLD.Feature, "Feature", "Head")
			plate.Reflectance = 0.2
		end
	end
	if crystal then
		local color = if golden then GILDED else CRYSTAL
		for i, s in bp.Shards do
			local k = s.Len * scale
			local a = Vector3.new(0.8, 1.2, 0.8) * k
			local b = Vector3.new(0.6, 0.8, 0.6) * k
			local base = CFrame.new(s.CF.Position * scale) * s.CF.Rotation
			for j, sz in { a, b } do
				local y = if j == 1 then a.Y / 2 else a.Y + b.Y / 2
				local p = brick(model, "Shard" .. i .. (if j == 1 then "" else "Top"), sz, base * CFrame.new(0, y, 0), color, "Crystal", s.Anim)
				p.Transparency = 0.3
				p.Reflectance = 0.15
			end
		end
		local hb = model.PrimaryPart
		if hb then
			hb.Size = hb.Size + Vector3.new(0, 0.6 * scale, 0)
		end
	end

	-- 3) VFX: one emitter, one light.
	if golden and host then
		clearVfx(model, true, false)
		local e = Effects.Sparkle(SPARKLE, 4)
		e.Size = NumberSequence.new(0.5 * math.max(scale, 0.6), 0.3)
		e.LightEmission = 1
		e.Parent = host
	end
	if (crystal or glowing) and host then
		clearVfx(model, false, true)
		local light = Instance.new("PointLight")
		light.Shadows = false
		if glowing then
			light.Range = 10 * math.max(scale, 0.6)
			light.Brightness = 1
			light.Color = if crystal then glowColor:Lerp(CRYSTAL, 0.5) else glowColor
			model:SetAttribute("Pulse", true)
		else
			light.Range = 8 * math.max(scale, 0.6)
			light.Brightness = 0.6
			light.Color = if golden then GILDED else CRYSTAL
		end
		light.Parent = host
	end
end

-- Starter Pack bow: two coral bricks + a knot cube on top of the head (Role "Accessory", Anim "Head").
function Mutations.Bow(model: Model, scale: number)
	local top, w = headTop(model)
	if not top then
		return
	end
	local coral = hex("#FF6F91")
	local c = top + Vector3.new(w * 0.25, 0.3 * scale, 0)
	brick(model, "BowL", Vector3.new(0.8, 0.6, 0.4) * scale, CFrame.new(c + Vector3.new(-0.6 * scale, 0, 0)), coral, "Accessory", "Head")
	brick(model, "BowR", Vector3.new(0.8, 0.6, 0.4) * scale, CFrame.new(c + Vector3.new(0.6 * scale, 0, 0)), coral, "Accessory", "Head")
	brick(model, "BowKnot", Vector3.new(0.4, 0.4, 0.5) * scale, CFrame.new(c), hex("#E04F75"), "Accessory", "Head")
end

-- Egg model: stacked studded brick egg (3.2 tall, widest 2.4) + 3 spot tiles, Hitbox PrimaryPart, pivot at
-- the egg's base. Golden = gold bricks (Reflectance 0.2) + sparkle.
function Mutations.Egg(bp: Shapes.Blueprint, list: { string }, seed: number): Model
	local rng = Random.new(seed)
	local golden = has(list, "Golden")
	local model = Instance.new("Model")
	model.Name = bp.Species .. "Egg"
	local shellColor = if golden then GOLD.Primary else bp.Palette.Primary
	local spotColor = if golden then GOLD.Belly else bp.Palette.Secondary
	-- { width, height } bottom -> top; the biggest layer is named "Shell".
	local layers = { { 1.6, 0.4 }, { 2.4, 0.8 }, { 2.4, 0.8 }, { 2, 0.8 }, { 1.2, 0.4 } }
	local y = 0
	local shell: BasePart? = nil
	for i, l in layers do
		local h, s, v = shellColor:ToHSV()
		local col = if i % 2 == 0 then Color3.fromHSV(h, s, v * 0.95) else shellColor
		local p = brick(model, if i == 2 then "Shell" else "Shell" .. i, Vector3.new(l[1], l[2], l[1]), CFrame.new(0, y + l[2] / 2, 0), col, "Primary", "Body")
		p.CastShadow = i == 2
		if golden then
			p.Reflectance = 0.2
		end
		if i == 2 then
			shell = p
		end
		y += l[2]
	end
	for i = 1, 3 do
		local face = rng:NextInteger(0, 3)
		local sy = 0.8 + i * 0.6
		local w = if sy < 2 then 2.4 else 2
		local a = face * math.pi / 2
		local pos = Vector3.new(math.sin(a) * (w / 2 + 0.05), sy, math.cos(a) * (w / 2 + 0.05))
		local spot = brick(model, "Spot" .. i, Vector3.new(0.8, 0.6, 0.1), CFrame.lookAt(pos, Vector3.new(0, sy, 0)), spotColor, "Secondary", "Body")
		spot.Material = Enum.Material.SmoothPlastic
	end
	local hb = Instance.new("Part")
	hb.Name = "Hitbox"
	hb.Anchored = true
	hb.CanCollide = false
	hb.CanTouch = false
	hb.CanQuery = true
	hb.Transparency = 1
	hb.Size = Vector3.new(2.6, 3.4, 2.6)
	hb.CFrame = CFrame.new(0, 1.7, 0)
	hb.PivotOffset = CFrame.new(0, -1.7, 0)
	hb.Parent = model
	model.PrimaryPart = hb
	if golden and shell then
		Effects.Sparkle(SPARKLE, 3).Parent = shell
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
