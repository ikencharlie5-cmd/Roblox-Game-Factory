--!strict
-- Builds the pooled parts/emitters used by Fx (called once from Fx.Init; nothing is created per frame).
local Tuning = require(script.Parent.Tuning)

local FxPools = {}

export type Item = {
	part: BasePart,
	kind: string,
	t0: number,
	life: number,
	pos: Vector3,
	vel: Vector3,
	spin: number,
	r0: number,
	r1: number,
	target: Vector3?,
	ground: number,
	gui: TextLabel?,
	light: PointLight?,
	active: boolean,
}

local HIDE = CFrame.new(0, -1e4, 0)
FxPools.HIDE = HIDE

local folder: Folder
local items: { [string]: { Item } } = {}
local emitters: { [string]: ParticleEmitter } = {}

local function basePart(name: string): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Transparency = 1
	p.CFrame = HIDE
	p.Parent = folder
	return p
end

local function pool(kind: string, n: number, make: () -> Item)
	local list = {}
	for i = 1, n do
		list[i] = make()
	end
	items[kind] = list
end

local function newItem(part: BasePart, kind: string): Item
	return {
		part = part,
		kind = kind,
		t0 = 0,
		life = 1,
		pos = Vector3.zero,
		vel = Vector3.zero,
		spin = 0,
		r0 = 0,
		r1 = 0,
		target = nil,
		ground = 0,
		gui = nil,
		light = nil,
		active = false,
	}
end

local function emitter(name: string, texture: string, color: Color3, size: number, speed: number, life: number)
	local p = basePart(name)
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.Texture = texture
	e.Color = ColorSequence.new(color)
	e.LightEmission = if name == "Dust" then 0 else 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(life * 0.6, life)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = if name == "Dust" then Vector3.new(0, 2, 0) else Vector3.new(0, -6, 0)
	e.Drag = 2
	e.Parent = p
	emitters[name] = e
end

function FxPools.Build(parent: Folder): ({ [string]: { Item } }, { [string]: ParticleEmitter })
	folder = parent
	emitter("Sparkle", "rbxasset://textures/particles/sparkles_main.dds", Color3.fromRGB(255, 226, 122), 0.6, 12, 1.2)
	emitter("Dust", "rbxasset://textures/particles/smoke_main.dds", Color3.fromRGB(226, 208, 170), 1.4, 5, 0.8)

	pool("Float", 16, function()
		local p = basePart("Float")
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(1.6, 1.6)
		bb.LightInfluence = 0
		bb.MaxDistance = 120
		bb.Adornee = p
		bb.Parent = p
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextStrokeTransparency = 0.4
		t.TextTransparency = 1
		t.Parent = bb
		local it = newItem(p, "Float")
		it.gui = t
		return it
	end)
	pool("Coin", Tuning.CoinPool, function()
		local p = basePart("Coin")
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.18, 0.9, 0.9)
		p.Color = Color3.fromRGB(255, 205, 60)
		p.Material = Enum.Material.Metal
		return newItem(p, "Coin")
	end)
	pool("Shell", 4, function()
		local p = basePart("Shell")
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
		return newItem(p, "Shell")
	end)
	pool("Bubble", 2, function()
		local p = basePart("Bubble")
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.ForceField
		p.Color = Color3.fromRGB(150, 220, 255)
		return newItem(p, "Bubble")
	end)
	pool("Ring", 3, function()
		local p = basePart("Ring")
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		return newItem(p, "Ring")
	end)
	pool("Flash", 2, function()
		local p = basePart("Flash")
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Brightness = 0
		l.Shadows = false
		l.Parent = p
		local it = newItem(p, "Flash")
		it.light = l
		return it
	end)
	return items, emitters
end

return FxPools
