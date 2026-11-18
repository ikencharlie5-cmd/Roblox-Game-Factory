--!strict
-- Pooled client-only effects (all created once in Init, never per frame):
--   Burst(kind, pos, n, color?)        particle burst: "Sparkle" | "Dust"
--   Float(text, pos, color?, size?)    rising text billboard: hearts, "z", "+25"
--   Coins(pos, n, target?)             coin fountain; homes in on target if given
--   Shell(pos, color, size)            two egg-shell halves fly out
--   Bubble(pos, r0, r1, life)          capture bubble (ForceField ball) that pops at the end
--   Ring(pos, color, radius)           flat shockwave ring
--   Flash(pos, color, brightness, life) short point-light flash
local Batch = require(script.Parent.Batch)
local FxPools = require(script.Parent.FxPools)
local Tuning = require(script.Parent.Tuning)

local Fx = {}

type Item = FxPools.Item

local items: { [string]: { Item } } = {}
local emitters: { [string]: ParticleEmitter } = {}
local HIDE = FxPools.HIDE
local rng = Random.new()
local inited = false

local function take(kind: string): Item?
	local list = items[kind]
	if not list then
		return nil
	end
	local oldest: Item? = nil
	for _, it in list do
		if not it.active then
			return it
		end
		if not oldest or it.t0 < oldest.t0 then
			oldest = it
		end
	end
	return oldest -- recycle the oldest when the pool is full
end

function Fx.Init()
	if inited then
		return
	end
	inited = true
	local folder = Instance.new("Folder")
	folder.Name = "ClientAnimFx"
	folder.Parent = workspace
	items, emitters = FxPools.Build(folder)
end

function Fx.Burst(kind: string, pos: Vector3, n: number?, color: Color3?)
	local e = emitters[kind]
	if not e then
		return
	end
	local part = e.Parent :: BasePart
	part.CFrame = CFrame.new(pos)
	e.Color = ColorSequence.new(color or (if kind == "Dust" then Color3.fromRGB(226, 208, 170) else Color3.fromRGB(255, 226, 122)))
	e:Emit(n or 12)
end

local function start(it: Item, pos: Vector3, life: number)
	it.active = true
	it.t0 = os.clock()
	it.life = life
	it.pos = pos
	it.target = nil
end

function Fx.Float(text: string, pos: Vector3, color: Color3?, size: number?)
	local it = take("Float")
	if not it or not it.gui then
		return
	end
	start(it, pos + Vector3.new(rng:NextNumber(-0.6, 0.6), 0, rng:NextNumber(-0.6, 0.6)), 1.2)
	it.vel = Vector3.new(0, 2.2, 0)
	local gui = it.gui :: TextLabel
	gui.Text = text
	gui.TextColor3 = color or Color3.fromRGB(255, 110, 150)
	local bb = gui.Parent :: BillboardGui
	bb.Size = UDim2.fromScale(size or 1.6, size or 1.6)
end

function Fx.Coins(pos: Vector3, n: number, target: Vector3?)
	for _ = 1, math.min(n, 12) do
		local it = take("Coin")
		if not it then
			return
		end
		start(it, pos, 1.6)
		local a = rng:NextNumber(0, 2 * math.pi)
		local s = rng:NextNumber(3, 7)
		it.vel = Vector3.new(math.cos(a) * s, rng:NextNumber(14, 20), math.sin(a) * s)
		it.spin = rng:NextNumber(6, 12)
		it.ground = pos.Y
		it.target = target
		it.part.Transparency = 0
	end
	Fx.Burst("Sparkle", pos + Vector3.new(0, 1, 0), 10)
end

function Fx.Shell(pos: Vector3, color: Color3, size: number)
	for side = -1, 1, 2 do
		local it = take("Shell")
		if not it then
			return
		end
		start(it, pos + Vector3.new(side * size * 0.15, size * 0.3, 0), 0.9)
		it.vel = Vector3.new(side * rng:NextNumber(5, 8), rng:NextNumber(10, 14), rng:NextNumber(-3, 3))
		it.spin = side * rng:NextNumber(5, 9)
		it.ground = pos.Y - size * 0.4
		it.part.Size = Vector3.new(size, size * 0.6, size)
		it.part.Color = color
		it.part.Transparency = 0
	end
end

function Fx.Bubble(pos: Vector3, r0: number, r1: number, life: number)
	local it = take("Bubble")
	if not it then
		return
	end
	start(it, pos, life)
	it.r0, it.r1 = r0, r1
	it.part.Transparency = 0.2
end

function Fx.Ring(pos: Vector3, color: Color3, radius: number)
	local it = take("Ring")
	if not it then
		return
	end
	start(it, pos + Vector3.new(0, 0.1, 0), 0.5)
	it.r0, it.r1 = 0.5, radius * 2
	it.part.Color = color
	it.part.Transparency = 0.3
end

function Fx.Flash(pos: Vector3, color: Color3, brightness: number, life: number)
	local it = take("Flash")
	if not it or not it.light then
		return
	end
	local light = it.light :: PointLight
	start(it, pos, life)
	it.r0 = brightness
	light.Color = color
end

local function stop(it: Item)
	it.active = false
	it.part.Transparency = 1
	Batch.Add(it.part, HIDE)
end

function Fx.Step(now: number, dt: number, playerPos: Vector3?)
	for kind, list in items do
		for _, it in list do
			if not it.active then
				continue
			end
			local p = (now - it.t0) / it.life
			if p >= 1 then
				if kind == "Bubble" then
					Fx.Burst("Sparkle", it.pos, 24, Color3.fromRGB(200, 240, 255))
				elseif kind == "Flash" and it.light then
					(it.light :: PointLight).Brightness = 0
				elseif kind == "Float" and it.gui then
					(it.gui :: TextLabel).TextTransparency = 1
				end
				stop(it)
				continue
			end
			if kind == "Float" then
				it.pos += it.vel * dt
				local gui = it.gui :: TextLabel
				gui.TextTransparency = math.max(0, (p - 0.6) / 0.4)
				gui.TextStrokeTransparency = 0.4 + 0.6 * gui.TextTransparency
				Batch.Add(it.part, CFrame.new(it.pos))
			elseif kind == "Coin" or kind == "Shell" then
				local tgt = it.target or (if kind == "Coin" then playerPos else nil)
				if kind == "Coin" and tgt and p > 0.3 and (tgt - it.pos).Magnitude < Tuning.CoinFlyRadius then
					local d = tgt + Vector3.new(0, 1.5, 0) - it.pos
					if d.Magnitude < 1 then
						stop(it)
						continue
					end
					it.vel = it.vel:Lerp(d.Unit * 45, math.min(1, dt * 8))
				else
					it.vel += Vector3.new(0, -50 * dt, 0)
				end
				it.pos += it.vel * dt
				if it.pos.Y < it.ground then
					it.pos = Vector3.new(it.pos.X, it.ground, it.pos.Z)
					it.vel = Vector3.new(it.vel.X * 0.5, math.abs(it.vel.Y) * 0.3, it.vel.Z * 0.5)
				end
				if p > 0.7 then
					it.part.Transparency = (p - 0.7) / 0.3
				end
				local a = (now - it.t0) * it.spin
				Batch.Add(it.part, CFrame.new(it.pos) * CFrame.Angles(a * 0.5, a, 0))
			elseif kind == "Bubble" then
				local r = it.r0 + (it.r1 - it.r0) * p * p
				it.part.Size = Vector3.one * (r * 2 * (1 + 0.04 * math.sin(now * 20)))
				Batch.Add(it.part, CFrame.new(it.pos))
			elseif kind == "Ring" then
				local d = it.r0 + (it.r1 - it.r0) * (1 - (1 - p) ^ 3)
				it.part.Size = Vector3.new(0.15, d, d)
				it.part.Transparency = 0.3 + 0.7 * p
				Batch.Add(it.part, CFrame.new(it.pos) * CFrame.Angles(0, 0, math.pi / 2))
			elseif kind == "Flash" and it.light then
				(it.light :: PointLight).Brightness = it.r0 * (1 - p) * (1 - p)
				Batch.Add(it.part, CFrame.new(it.pos))
			end
		end
	end
end

return Fx
