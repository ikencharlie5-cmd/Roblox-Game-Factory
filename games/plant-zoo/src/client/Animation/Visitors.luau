--!strict
-- Client-side blocky visitors walking each plot's paths (moved here from server World/Motion).
-- Server sets attributes on each plot's "Visitors" folder: Count (number) and Origin (CFrame = plot pivot,
-- -Z toward the hub). Each client spawns its own visitors (anchored parts, no physics, no network) and
-- moves every visible visitor part with one workspace:BulkMoveTo per frame. Frozen when far away.
local CollectionService = game:GetService("CollectionService")
local Tuning = require(script.Parent.Tuning)
local Moments = require(script.Parent.Moments)

local Visitors = {}

local V = Vector3.new
local C = CFrame.new
local hex = Color3.fromHex

local NODES = { -37, -12, 12, 37 }
local SHIRTS = { "#FF6F61", "#3BA7FF", "#FFD54F", "#7BD148", "#B57CFF", "#FF8FB8", "#FFFFFF" }
local SKINS = { "#FFD7B5", "#E8B48A", "#C68A5E", "#8D5A3B", "#F5E0C8" }
local BUBBLES = { "Wow!", "So cute!", "🌱", "❤", "Ooh!", "$$$" }

type Piece = { part: BasePart, off: CFrame, limb: number } -- limb: 0 body, 1/-1 leg, 2/-2 arm
type Visitor = {
	model: Model,
	pieces: { Piece },
	label: TextLabel,
	ix: number,
	iz: number,
	pos: Vector3,
	target: Vector3,
	dir: Vector3,
	idleUntil: number,
	phase: number,
}
type Plot = { model: Instance, folder: Folder, origin: CFrame, list: { Visitor } }

local rng = Random.new()
local plots: { Plot } = {}
local parts: { BasePart } = {}
local cframes: { CFrame } = {}

local function build(parent: Instance): (Model, { Piece }, TextLabel)
	local m = Instance.new("Model")
	m.Name = "Visitor"
	local pieces: { Piece } = {}
	local function piece(size: Vector3, off: CFrame, color: Color3, limb: number, ball: boolean?)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if ball then
			p.Shape = Enum.PartType.Ball
		end
		p.Parent = m
		table.insert(pieces, { part = p, off = off, limb = limb })
		return p
	end
	local shirt = hex(SHIRTS[rng:NextInteger(1, #SHIRTS)])
	local skin = hex(SKINS[rng:NextInteger(1, #SKINS)])
	local pants = hex("#3B4A6B"):Lerp(shirt, 0.2)
	piece(V(0.9, 1.6, 0.9), C(-0.5, -0.8, 0), pants, -1)
	piece(V(0.9, 1.6, 0.9), C(0.5, -0.8, 0), pants, 1)
	piece(V(2, 1.8, 1), C(0, 2.5, 0), shirt, 0)
	piece(V(0.6, 1.6, 0.6), C(-1.3, -0.7, 0), skin, -2)
	piece(V(0.6, 1.6, 0.6), C(1.3, -0.7, 0), skin, 2)
	local head = piece(V(1.5, 1.5, 1.5), C(0, 4.15, 0), skin, 0)
	piece(V(0.25, 0.25, 0.1), C(-0.3, 4.3, -0.76), hex("#1B1B2A"), 0)
	piece(V(0.25, 0.25, 0.1), C(0.3, 4.3, -0.76), hex("#1B1B2A"), 0)
	if rng:NextNumber() < 0.5 then
		piece(V(1.7, 0.5, 1.7), C(0, 5.1, 0), hex(SHIRTS[rng:NextInteger(1, #SHIRTS)]), 0)
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(4, 1.4)
	bb.StudsOffset = V(0, 2.2, 0)
	bb.MaxDistance = 70
	bb.Enabled = false
	bb.Adornee = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 0.1
	label.TextColor3 = Color3.fromRGB(60, 40, 30)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.4, 0)
	corner.Parent = label
	bb.Parent = head
	m.Parent = parent
	return m, pieces, label
end

local function node(plot: Plot, ix: number, iz: number): Vector3
	return (plot.origin * C(NODES[ix], 0.15, NODES[iz])).Position
end

local function sync(plot: Plot)
	local n = plot.folder:GetAttribute("Count")
	local origin = plot.folder:GetAttribute("Origin")
	if typeof(origin) == "CFrame" then
		plot.origin = origin
	end
	local want = if type(n) == "number" then math.clamp(math.floor(n), 0, 12) else 0
	for i = #plot.list, want + 1, -1 do
		plot.list[i].model:Destroy()
		table.remove(plot.list, i)
	end
	for _ = #plot.list + 1, want do
		local m, pieces, label = build(Moments.Folder())
		local ix = rng:NextInteger(1, 4)
		local p = node(plot, ix, 1)
		for _, pc in pieces do
			pc.part.CFrame = CFrame.new(p) * pc.off
		end
		table.insert(plot.list, {
			model = m,
			pieces = pieces,
			label = label,
			ix = ix,
			iz = 1,
			pos = p,
			target = p,
			dir = (plot.origin.LookVector * -1),
			idleUntil = 0,
			phase = rng:NextNumber(0, 6),
		})
	end
end

local function bindPlot(model: Instance)
	local folder = model:WaitForChild("Visitors", 30)
	if not folder or not folder:IsA("Folder") then
		return
	end
	local origin = if model:IsA("Model") then model:GetPivot() else (model :: BasePart).CFrame
	local plot: Plot = { model = model, folder = folder, origin = origin, list = {} }
	table.insert(plots, plot)
	folder.AttributeChanged:Connect(function()
		sync(plot)
	end)
	sync(plot)
end

local function stepVisitor(plot: Plot, v: Visitor, now: number, dt: number)
	local walking = false
	if now >= v.idleUntil then
		local d = v.target - v.pos
		local dist = d.Magnitude
		if dist < 0.2 then
			-- arrived: maybe pause with a bubble, then pick the next node along the path grid
			if rng:NextNumber() < 0.35 then
				local thriving = (plot.model:GetAttribute("ThrivingCount") :: number?) or 0
				v.label.Text = if thriving > 0 and rng:NextNumber() < 0.4
					then "Thriving!"
					else BUBBLES[rng:NextInteger(1, #BUBBLES)]
				local bb = v.label.Parent :: BillboardGui
				bb.Enabled = true
				v.idleUntil = now + rng:NextNumber(1.5, 3)
				task.delay(v.idleUntil - now, function()
					bb.Enabled = false
				end)
			end
			if rng:NextNumber() < 0.5 then
				v.ix = math.clamp(v.ix + (if rng:NextNumber() < 0.5 then -1 else 1), 1, 4)
			else
				v.iz = math.clamp(v.iz + (if rng:NextNumber() < 0.5 then -1 else 1), 1, 4)
			end
			v.target = node(plot, v.ix, v.iz)
		else
			walking = true
			v.dir = d.Unit
			v.pos += v.dir * math.min(dist, Tuning.VisitorSpeed * dt)
		end
	end
	local t = now * 9 + v.phase
	local swing = if walking then math.sin(t) * 0.6 else 0
	local lift = if walking then math.abs(math.sin(t)) * 0.12 else 0.04 * math.sin(now * 2 + v.phase)
	local flat = V(v.dir.X, 0, v.dir.Z)
	local root = CFrame.lookAt(v.pos, v.pos + (if flat.Magnitude > 0.01 then flat else V(0, 0, -1))) * C(0, lift, 0)
	for _, pc in v.pieces do
		local cf: CFrame
		if pc.limb == 0 then
			cf = root * pc.off
		elseif pc.limb == 1 or pc.limb == -1 then
			cf = root * C(pc.off.X, 1.6, 0) * CFrame.Angles(swing * pc.limb, 0, 0) * C(0, pc.off.Y, 0)
		else
			cf = root * C(pc.off.X, 3.3, 0) * CFrame.Angles(-swing * pc.limb * 0.5, 0, 0) * C(0, pc.off.Y, 0)
		end
		table.insert(parts, pc.part)
		table.insert(cframes, cf)
	end
end

function Visitors.Step(now: number, dt: number, camPos: Vector3)
	table.clear(parts)
	table.clear(cframes)
	for _, plot in plots do
		if #plot.list > 0 and (plot.origin.Position - camPos).Magnitude <= Tuning.VisitorRadius then
			for _, v in plot.list do
				stepVisitor(plot, v, now, dt)
			end
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function Visitors.Start()
	for _, m in CollectionService:GetTagged("Plot") do
		task.spawn(bindPlot, m)
	end
	CollectionService:GetInstanceAddedSignal("Plot"):Connect(function(m)
		task.spawn(bindPlot, m)
	end)
end

return Visitors
