--!strict
-- Mutation tints, weather marks, rarity auras and Thriving FX for creature models.
local Theme = require(script.Parent.Parent.Theme)

local function skinParts(model: Model): { BasePart }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Skin") then
			table.insert(out, d)
		end
	end
	return out
end

local function fxPart(folder: Folder, anchorTo: BasePart, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = "FXCore"
	p.Size = size
	p.CFrame = cf
	p.Transparency = 1
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchorTo
	w.Part1 = p
	w.Parent = p
	p.Parent = folder
	return p
end

local function light(parent: Instance, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
end

-- Flat disc under the feet (SmoothPlastic, not Neon: big Neon surfaces blow out with bloom).
local function ring(folder: Folder, root: BasePart, d: number, color: Color3, transparency: number): Part
	local p = Instance.new("Part")
	p.Name = "RarityRing"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.12, d, d)
	p.CFrame = root.CFrame * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = transparency
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
	p.Parent = folder
	return p
end

-- Tinted translucent copy of a textured mesh part (mutation colour for meshes). Skin=true so
-- StepRainbow cycles it too.
local function shell(folder: Folder, src: BasePart, color: Color3, mat: Enum.Material, alpha: number, refl: number)
	local c = src:Clone()
	c:ClearAllChildren()
	if c:IsA("MeshPart") then
		c.TextureID = ""
	end
	c.Size = src.Size * 1.04
	c.CFrame = src.CFrame
	c.Color = color
	c.Material = mat
	c.Transparency = alpha
	c.Reflectance = refl
	c.Anchored = false
	c.CanCollide = false
	c.CanTouch = false
	c.CanQuery = false
	c.Massless = true
	c.CastShadow = false
	c:SetAttribute("Textured", nil)
	c:SetAttribute("Skin", true)
	c.Name = "MutationShell"
	local w = Instance.new("WeldConstraint")
	w.Part0 = src
	w.Part1 = c
	w.Parent = c
	c.Parent = folder
end

local Effects = {}

-- opts: { Color = "Gold"|"Diamond"|"Rainbow"|nil, Weather = "Dewy"|"Sunkissed"|"Frosted"|"Electric"|"Starlit"|nil,
--         Thriving = boolean }. Missing keys keep the model's current value; use false to clear.
function Effects.ApplyLook(model: Model, opts: { [string]: any }?)
	local o = opts or {}
	local function pick(key: string): any
		local v = o[key]
		if v == nil then
			v = model:GetAttribute(key)
		end
		if v == false or v == "" or v == "None" then
			return nil
		end
		return v
	end
	local color: string? = pick("Color")
	local weather: string? = pick("Weather")
	local thriving = pick("Thriving") == true
	model:SetAttribute("Color", color or "")
	model:SetAttribute("Weather", weather or "")
	model:SetAttribute("Thriving", thriving)
	model:SetAttribute("Rainbow", color == "Rainbow")

	local old = model:FindFirstChild("FX")
	if old then
		old:Destroy()
	end
	local root = model.PrimaryPart
	local body = model:FindFirstChild("Body") :: BasePart?
	if not root or not body then
		return
	end
	local s = (model:GetAttribute("Scale") :: number?) or 1
	local grown = model:GetAttribute("Stage") == "Grown"

	-- Reset skin, then tint.
	local mut = if color then Theme.ColorMutations[color] else nil
	local mark = if weather then Theme.WeatherMarks[weather] else nil
	for _, p in skinParts(model) do
		local base = (p:GetAttribute("BaseColor") :: Color3?) or p.Color
		local mat = (Enum.Material :: any)[p:GetAttribute("BaseMat") or "SmoothPlastic"]
		if mut then
			base = base:Lerp(mut.Color, mut.Mix)
			mat = mut.Material
		end
		if mark and mark.Tint then
			base = base:Lerp(mark.Tint, 0.3)
		end
		p.Color = base
		p.Material = mat
		p.Reflectance = if color == "Diamond" then 0.2 else 0
	end

	local folder = Instance.new("Folder")
	folder.Name = "FX"
	folder.Parent = model
	-- Textured mesh parts ignore Color: draw a tinted translucent shell over them instead.
	if mut or (mark and mark.Tint) then
		local tint = if mut then mut.Color else (mark :: any).Tint :: Color3
		local mat = if mut then mut.Material else Enum.Material.SmoothPlastic
		local alpha = if color == "Diamond" then 0.45 elseif mut then 0.35 else 0.7
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Textured") then
				shell(folder, d, tint, mat, alpha, if color == "Diamond" then 0.25 else 0)
			end
		end
	end
	local h = if grown then 2.5 * s else 1.5
	local core = fxPart(folder, body, Vector3.new(2.5, 2.5, 2.5) * s, body.CFrame * CFrame.new(0, h, 0))

	if grown then
		-- Rarity VFX ladder (ART_STYLE_GUIDE §8): sparkles -> ring -> light -> aura -> rainbow.
		local rarity = model:GetAttribute("Rarity") :: string?
		local rc = Theme.Rarity[rarity or "Common"] or Color3.new(1, 1, 1)
		local rank = table.find(Theme.RarityOrder, rarity or "Common") or 1
		if rarity == "Secret" then
			Theme.Effects.RainbowAura().Parent = core
			light(core, Color3.fromHex("#C77DFF"), 1.5, 12)
			ring(folder, root, 3.8 * s, Color3.fromHex("#2B1B3A"), 0.35)
		elseif rank >= 3 then
			Theme.Effects.Sparkle(rc, ({ 2, 4, 6, 6 })[rank - 2]).Parent = core
			if rank >= 4 then
				ring(folder, root, 3.8 * s, rc, 0.6)
			end
			if rank >= 5 then
				Theme.Effects.Aura(rc).Parent = core
				light(core, rc, 1, 8)
			end
		end
	end
	if color == "Gold" or color == "Diamond" then
		Theme.Effects.Sparkle(if color == "Gold" then Theme.Colors.Gold else Color3.fromHex("#BFF3FF"), 3).Parent = core
	elseif color == "Rainbow" then
		Theme.Effects.RainbowAura().Parent = core
	end
	if mark then
		local e = Theme.Effects.Sparkle(mark.Color, if weather == "Electric" then 12 else 4)
		if weather == "Dewy" then
			e.Acceleration = Vector3.new(0, -8, 0)
		end
		e.Parent = core
		if mark.Light then
			light(core, mark.Light, 1, 8)
		end
	end
	if thriving then
		local r = ring(folder, root, 4.6 * math.max(s, 1), Theme.Colors.Thriving, 0.45)
		r.Name = "ThrivingRing"
		Theme.Effects.Sparkle(Theme.Colors.Thriving, 5).Parent = core
		Theme.Effects.Leaves().Parent = core
	end
end

-- Rainbow color cycle. Call every ~0.2 s with a hue in [0,1).
function Effects.StepRainbow(model: Model, hue: number)
	for i, p in skinParts(model) do
		p.Color = Color3.fromHSV((hue + i * 0.04) % 1, 0.65, 1)
	end
end
return Effects
