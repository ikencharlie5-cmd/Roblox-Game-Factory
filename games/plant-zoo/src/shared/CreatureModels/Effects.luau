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
	local h = if grown then 2.5 * s else 1.5
	local core = fxPart(folder, body, Vector3.new(2.5, 2.5, 2.5) * s, body.CFrame * CFrame.new(0, h, 0))

	if grown then
		local rarity = model:GetAttribute("Rarity")
		local rc = Theme.Rarity[rarity :: string]
		if rarity == "Secret" then
			Theme.Effects.RainbowAura().Parent = core
			light(core, Color3.fromHex("#C77DFF"), 1.5, 12)
		elseif rarity == "Mythical" or rarity == "Legendary" then
			Theme.Effects.Aura(rc).Parent = core
			if rarity == "Mythical" then
				light(core, rc, 1.2, 10)
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
		local d = 4.6 * math.max(s, 1)
		local ring = Instance.new("Part")
		ring.Name = "ThrivingRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.12, d, d)
		ring.CFrame = root.CFrame * CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = Theme.Colors.Thriving
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.55
		ring.CanCollide = false
		ring.CanTouch = false
		ring.CanQuery = false
		ring.Massless = true
		ring.CastShadow = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = ring
		w.Parent = ring
		ring.Parent = folder
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
