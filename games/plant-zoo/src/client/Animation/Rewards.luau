--!strict
-- Reward juice: tip-jar coin burst on collect (coins arc to the local player if they are at the jar,
-- otherwise spray and drop) + jar hop, and the Release float-away (a client copy of the released
-- creature rises from where it stood - or from the Release Altar - spinning, shrinking and fading).
-- Coins come from a fixed pool (no per-frame Instance creation); all moved with one BulkMoveTo.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureModels = require(Shared:WaitForChild("CreatureModels")) :: any
local Theme = require(Shared:WaitForChild("Theme")) :: any
local Tuning = require(script.Parent.Tuning)
local Moments = require(script.Parent.Moments)
local Items = require(script.Parent.Items)

local Rewards = {}

type Coin = { part: BasePart, a: Vector3, b: Vector3, c: Vector3, t0: number, dur: number, spin: number }
type Hop = { model: Model, pivot: CFrame, t0: number }
type Ghost = { model: Model, root: BasePart, parts: { BasePart }, from: CFrame, t0: number }

local POOL = 40
local PARK = CFrame.new(0, -500, 0)
local rng = Random.new()
local free: { BasePart } = {}
local flying: { Coin } = {}
local hops: { Hop } = {}
local ghosts: { Ghost } = {}
local movParts: { BasePart } = {}
local movCF: { CFrame } = {}

local function makePool()
	for _ = 1, POOL do
		local p = Instance.new("Part")
		p.Name = "Coin"
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.18, 0.9, 0.9)
		p.Color = Theme.Colors.Gold
		p.Material = Enum.Material.Metal
		p.Reflectance = 0.2
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = PARK
		p.Parent = Moments.Folder()
		table.insert(free, p)
	end
end

local function hrp(): BasePart?
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function burst(jar: BasePart, amount: number)
	local cam = workspace.CurrentCamera
	if not cam or (cam.CFrame.Position - jar.Position).Magnitude > Tuning.ActiveRadius then
		return
	end
	local top = jar.Position + Vector3.new(0, 1.5, 0)
	local me = hrp()
	local toMe = me and (me.Position - jar.Position).Magnitude <= Tuning.CoinFlyRadius
	local n = math.clamp(math.ceil(amount / 25), 4, Tuning.Coins)
	local now = os.clock()
	for i = 1, n do
		local p = table.remove(free)
		if not p then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local c = if toMe and me then me.Position else top + out * rng:NextNumber(2, 4.5) - Vector3.new(0, 1.6, 0)
		local b = top:Lerp(c, 0.5) + out * 1.5 + Vector3.new(0, rng:NextNumber(3.5, 5.5), 0)
		table.insert(flying, {
			part = p,
			a = top,
			b = b,
			c = c,
			t0 = now + i * 0.03,
			dur = rng:NextNumber(0.45, 0.65),
			spin = rng:NextNumber(8, 14),
		})
	end
	Moments.Burst("Coins", top, 12)
	local vis = jar.Parent and jar.Parent:FindFirstChild("TipJarVisual")
	if vis and vis:IsA("Model") then
		for _, h in hops do
			if h.model == vis then
				return
			end
		end
		table.insert(hops, { model = vis, pivot = vis:GetPivot(), t0 = now })
	end
end

local function bindJar(jar: Instance)
	if not jar:IsA("BasePart") then
		return
	end
	local last = (jar:GetAttribute("Amount") :: number?) or 0
	jar:GetAttributeChangedSignal("Amount"):Connect(function()
		local now = (jar:GetAttribute("Amount") :: number?) or 0
		if now < last and last - now >= 1 then
			burst(jar, last - now)
		end
		last = now
	end)
end

-- Release float-away --------------------------------------------------------------------------------
local function float(species: string, color: string?, from: Vector3)
	local ok, m = pcall(CreatureModels.Build, species, "Grown", { Color = color })
	if not ok or not m then
		return
	end
	local model = m :: Model
	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		return
	end
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			table.insert(parts, d)
		end
	end
	local cf = CFrame.new(from)
	model:PivotTo(cf)
	model.Parent = Moments.Folder()
	Moments.Burst("Sparkle", from + Vector3.new(0, 2, 0), 40, Theme.Colors.Thriving)
	table.insert(ghosts, { model = model, root = root, parts = parts, from = cf, t0 = os.clock() })
end

local function altarPos(): Vector3
	local altar = CollectionService:GetTagged("ReleaseAltar")[1]
	return if altar and altar:IsA("BasePart")
		then altar.Position + Vector3.new(0, altar.Size.Y / 2, 0)
		else Vector3.zero
end

local function onNewReserve(species: string, color: string?)
	task.spawn(function()
		local r = Items.TakeRemoved(species, color, 4)
		if not r then
			task.wait(0.4)
			r = Items.TakeRemoved(species, color, 4)
		end
		float(species, color, if r then r.pos else altarPos())
	end)
end

local function bindReserve()
	local st = ReplicatedStorage:WaitForChild("GameState", 60)
	local sv = st and st:WaitForChild("WorldReserve", 60)
	if not sv or not sv:IsA("StringValue") then
		return
	end
	local counts: { [string]: number }? = nil
	local function read()
		local ok, list = pcall(HttpService.JSONDecode, HttpService, sv.Value)
		if not ok or type(list) ~= "table" then
			return
		end
		local now: { [string]: number } = {}
		for _, e in list do
			if type(e) == "table" and type(e.species) == "string" then
				local key = e.species .. "|" .. tostring(e.color or "None") .. "|" .. tostring(e.userId)
				now[key] = (now[key] or 0) + 1
				if counts and now[key] > (counts[key] or 0) then
					onNewReserve(e.species, if type(e.color) == "string" then e.color else nil)
				end
			end
		end
		counts = now
	end
	read()
	sv.Changed:Connect(read)
end

-- Per frame -----------------------------------------------------------------------------------------
function Rewards.Step(now: number)
	table.clear(movParts)
	table.clear(movCF)
	for i = #flying, 1, -1 do
		local c = flying[i]
		local p = (now - c.t0) / c.dur
		if p >= 1 then
			table.insert(movParts, c.part)
			table.insert(movCF, PARK)
			table.insert(free, c.part)
			table.remove(flying, i)
		elseif p >= 0 then
			local q = 1 - p
			local pos = c.a * (q * q) + c.b * (2 * q * p) + c.c * (p * p)
			table.insert(movParts, c.part)
			table.insert(movCF, CFrame.new(pos) * CFrame.Angles(0, now * c.spin, math.pi / 2))
		end
	end
	if #movParts > 0 then
		workspace:BulkMoveTo(movParts, movCF, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for i = #hops, 1, -1 do
		local h = hops[i]
		local p = (now - h.t0) / 0.4
		if p >= 1 or not h.model.Parent then
			if h.model.Parent then
				h.model:PivotTo(h.pivot)
			end
			table.remove(hops, i)
		else
			h.model:PivotTo(h.pivot * CFrame.new(0, 0.7 * math.sin(math.pi * p), 0))
		end
	end
	for i = #ghosts, 1, -1 do
		local g = ghosts[i]
		local p = (now - g.t0) / Tuning.ReleaseTime
		if p >= 1 then
			g.model:Destroy()
			table.remove(ghosts, i)
		else
			local ease = p * p * (3 - 2 * p)
			local wob = 0.6 * math.sin(p * 9)
			g.root.CFrame = g.from
				* CFrame.new(wob, Tuning.ReleaseRise * ease, 0)
				* CFrame.Angles(0, p * 4 * math.pi, 0.15 * math.sin(p * 7))
			local fade = math.clamp((p - 0.55) / 0.45, 0, 1)
			for _, part in g.parts do
				part.LocalTransparencyModifier = fade
			end
		end
	end
end

function Rewards.Start()
	makePool()
	for _, j in CollectionService:GetTagged("TipJar") do
		bindJar(j)
	end
	CollectionService:GetInstanceAddedSignal("TipJar"):Connect(bindJar)
	task.spawn(bindReserve)
end

return Rewards
