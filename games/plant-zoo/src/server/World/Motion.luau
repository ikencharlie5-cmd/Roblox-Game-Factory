--!strict
-- Creature idle motion (bob + slow wander inside the pad) and blocky visitor NPCs.
-- Everything is moved with TweenService on an anchored Root; welded parts follow. No physics.
local TweenService = game:GetService("TweenService")
local Build = require(script.Parent.Build)

local V = Vector3.new
local C = CFrame.new
local hex = Color3.fromHex

local Motion = {}

local rng = Random.new()
local PAD_HALF = 10
local MARGIN = 1.8

-- Starts bob + wander for a Grown creature. padTop = pad top-center CFrame, home = its cell CFrame.
function Motion.Creature(model: Model, padTop: CFrame, home: CFrame, half: number?)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local bob = root:FindFirstChild("Bob") :: Weld?
	if bob then
		local hover = if model:GetAttribute("Kind") == "fish" or model:GetAttribute("Kind") == "bird" then 0.5 else 0.25
		local tw = TweenService:Create(
			bob,
			TweenInfo.new(rng:NextNumber(0.7, 1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{
				C0 = C(0, hover, 0),
			}
		)
		tw:Play()
	end
	local homeLocal = padTop:ToObjectSpace(home)
	task.spawn(function()
		task.wait(rng:NextNumber(0, 3))
		while model.Parent do
			task.wait(rng:NextNumber(3, 7))
			if not model.Parent then
				break
			end
			local lim = (half or PAD_HALF) - MARGIN
			local x = math.clamp(homeLocal.X + rng:NextNumber(-2.5, 2.5), -lim, lim)
			local z = math.clamp(homeLocal.Z + rng:NextNumber(-2.5, 2.5), -lim, lim)
			local target = (padTop * C(x, 0, z)).Position
			local from = root.Position
			local flat = V(target.X - from.X, 0, target.Z - from.Z)
			if flat.Magnitude > 0.3 then
				local goal = CFrame.lookAt(target, target + flat.Unit)
				TweenService:Create(root, TweenInfo.new(flat.Magnitude / 2.5, Enum.EasingStyle.Sine), { CFrame = goal })
					:Play()
			end
		end
	end)
end

-- Growth "pop": quick scale overshoot. Runs a few ScaleTo steps (rare event, fine on server).
function Motion.Pop(model: Model)
	task.spawn(function()
		local seq = { 0.6, 0.85, 1.12, 1.05, 1 }
		for _, s in seq do
			if not model.Parent then
				return
			end
			model:ScaleTo(s)
			task.wait(0.04)
		end
	end)
end

-- Visitors ---------------------------------------------------------------------------------------
local NODES = { -37, -12, 12, 37 }
local SHIRTS = { "#FF6F61", "#3BA7FF", "#FFD54F", "#7BD148", "#B57CFF", "#FF8FB8", "#FFFFFF" }
local SKINS = { "#FFD7B5", "#E8B48A", "#C68A5E", "#8D5A3B", "#F5E0C8" }
local BUBBLES = { "Wow!", "So cute!", "🌱", "❤", "Ooh!", "$$$" }

local function visitorModel(parent: Instance): (Model, BasePart, TextLabel)
	local m = Instance.new("Model")
	m.Name = "Visitor"
	local root = Build.Deco(m, { Size = V(2, 0.2, 1), CFrame = C(), Transparency = 1, Name = "Root" })
	m.PrimaryPart = root
	local function piece(size: Vector3, off: CFrame, color: Color3, ball: boolean?)
		local p = Build.Deco(
			m,
			{ Size = size, CFrame = off, Color = color, Shape = if ball then Enum.PartType.Ball else nil }
		)
		p.Anchored = false
		p.Massless = true
		p.CanQuery = false
		p.CastShadow = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
	end
	local shirt = hex(SHIRTS[rng:NextInteger(1, #SHIRTS)])
	local skin = hex(SKINS[rng:NextInteger(1, #SKINS)])
	local pants = hex("#3B4A6B"):Lerp(shirt, 0.2)
	piece(V(0.9, 1.6, 0.9), C(-0.5, 0.8, 0), pants)
	piece(V(0.9, 1.6, 0.9), C(0.5, 0.8, 0), pants)
	piece(V(2, 1.8, 1), C(0, 2.5, 0), shirt)
	piece(V(0.6, 1.6, 0.6), C(-1.3, 2.5, 0), skin)
	piece(V(0.6, 1.6, 0.6), C(1.3, 2.5, 0), skin)
	piece(V(1.5, 1.5, 1.5), C(0, 4.15, 0), skin)
	piece(V(0.25, 0.25, 0.1), C(-0.3, 4.3, -0.76), hex("#1B1B2A"))
	piece(V(0.25, 0.25, 0.1), C(0.3, 4.3, -0.76), hex("#1B1B2A"))
	if rng:NextNumber() < 0.5 then
		piece(V(1.7, 0.5, 1.7), C(0, 5.1, 0), hex(SHIRTS[rng:NextInteger(1, #SHIRTS)]))
	end
	local label = Build.Billboard(root, "", Color3.fromRGB(60, 40, 30), 6.6, 4)
	local bb = label.Parent :: BillboardGui
	bb.MaxDistance = 70
	bb.Enabled = false
	label.BackgroundTransparency = 0.1
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.4, 0)
	corner.Parent = label
	m.Parent = parent
	return m, root, label
end

local function nodePos(plotCf: CFrame, ix: number, iz: number): CFrame
	return plotCf * C(NODES[ix], 0.15, NODES[iz])
end

local function walk(plotModel: Model, plotCf: CFrame, m: Model, root: BasePart, label: TextLabel)
	local ix, iz = rng:NextInteger(1, 4), 1
	root.CFrame = nodePos(plotCf, ix, iz)
	while m.Parent do
		local nx, nz = ix, iz
		if rng:NextNumber() < 0.5 then
			nx = math.clamp(ix + (if rng:NextNumber() < 0.5 then -1 else 1), 1, 4)
		else
			nz = math.clamp(iz + (if rng:NextNumber() < 0.5 then -1 else 1), 1, 4)
		end
		local target = nodePos(plotCf, nx, nz).Position
		local dist = (target - root.Position).Magnitude
		if dist > 0.5 then
			local goal = CFrame.lookAt(target, target + (target - root.Position).Unit)
			root.CFrame = CFrame.lookAt(root.Position, root.Position + (target - root.Position).Unit)
			local tw = TweenService:Create(root, TweenInfo.new(dist / 6, Enum.EasingStyle.Linear), { CFrame = goal })
			tw:Play()
			tw.Completed:Wait()
		end
		ix, iz = nx, nz
		if rng:NextNumber() < 0.35 and m.Parent then
			local thriving = (plotModel:GetAttribute("ThrivingCount") :: number?) or 0
			label.Text = if thriving > 0 and rng:NextNumber() < 0.4
				then "Thriving!"
				else BUBBLES[rng:NextInteger(1, #BUBBLES)]
			local bb = label.Parent :: BillboardGui
			bb.Enabled = true
			task.wait(rng:NextNumber(1.5, 3))
			bb.Enabled = false
		end
	end
end

-- Keep exactly n visitors walking in this plot's Visitors folder.
function Motion.SetVisitors(folder: Folder, plotModel: Model, plotCf: CFrame, n: number)
	local list = folder:GetChildren()
	for i = #list, n + 1, -1 do
		list[i]:Destroy()
	end
	for _ = #list + 1, n do
		local m, root, label = visitorModel(folder)
		task.spawn(walk, plotModel, plotCf, m, root, label)
	end
end

return Motion
