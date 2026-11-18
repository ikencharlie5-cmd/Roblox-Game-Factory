--!strict
-- First 60 seconds: bottom tracker card + bouncing code-drawn arrow on the right UI button + world
-- beam/arrow, driven by data.tutorialStep (Config.Tutorial). Left buttons are revealed as the
-- tutorial reaches them. After the tutorial the tracker shows the next daily quest.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local BuildMode = require(script.Parent:WaitForChild("BuildMode"))
local SideBar = require(script.Parent:WaitForChild("SideBar"))
local QuestsWindow = require(script.Parent:WaitForChild("QuestsWindow"))

local Tutorial = {}
local _skip: any = nil -- sink for unused multiple-return values

local player = Players.LocalPlayer :: Player
local gui: ScreenGui
local tracker: TextButton
local trackerLabel: TextLabel
local setTracker: (number) -> ()
local uiArrow: Frame
local uiTarget: GuiObject? = nil
local worldFolder: Folder
local beam: Beam
local targetAtt: Attachment
local worldArrow: BillboardGui
local goalCard: GuiObject? = nil

-- Left buttons visible per tutorial step (nil step = tutorial done = all).
local REVEAL: { { string } } = {
	{ "Shop", "Inventory" },
	{ "Shop", "Inventory", "Build" },
	{ "Shop", "Inventory", "Build", "Index" },
	{ "Shop", "Inventory", "Build", "Index", "Quests" },
	{ "Shop", "Inventory", "Build", "Index", "Quests", "Daily" },
	{ "Shop", "Inventory", "Build", "Index", "Quests", "Daily", "Release", "Visit" },
}

function Tutorial.SetGoalCard(card: GuiObject)
	goalCard = card
end

-- Chunky gold arrow (diamond head + shaft) pointing left; rotate the holder to aim it.
local function arrow(parent: Instance, size: Vector2): Frame
	local pal = Style.Pal.Sun
	local holder = Kit.Make("Frame", {
		Name = "Arrow",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size.X, size.Y),
		ZIndex = 20,
	}, parent)
	local function piece(props: { [string]: any })
		local f = Kit.Make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, holder)
		Kit.Apply(f, props)
		Kit.Corner(f, 6)
		Kit.Gradient(f, pal)
		Kit.Stroke(f, pal.Dark, 3.5)
	end
	piece({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.58, 0.36),
		ZIndex = 1,
	})
	piece({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.3, 0.5),
		Size = UDim2.fromScale(0.42, 0.42 * size.X / size.Y),
		Rotation = 45,
		ZIndex = 2,
	})
	return holder
end

local function pointUi(target: GuiObject?)
	uiTarget = target
	uiArrow.Visible = target ~= nil
end

local function pointWorld(part: BasePart?)
	if not part then
		beam.Enabled = false
		worldArrow.Enabled = false
		return
	end
	targetAtt.WorldPosition = part.Position + Vector3.new(0, part.Size.Y / 2 + 1, 0)
	worldArrow.Adornee = part
	worldArrow.Enabled = true
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local a0 = root and root:FindFirstChild("TutorialAtt") :: Attachment?
	if root and not a0 then
		a0 = Kit.Make("Attachment", { Name = "TutorialAtt", Position = Vector3.new(0, -2, 0) }, root)
	end
	beam.Attachment0 = a0
	beam.Enabled = a0 ~= nil
end

local function myPad1(): BasePart?
	return Plots.Pads()[1]
end

local function sproutGrowing(): any
	for _, item in State.Tbl("placed") do
		local _, progress = Derived.Stage(item)
		if progress < 1 then
			return item
		end
	end
	return nil
end

-- Decide hint text, UI arrow target and world target for the current step.
local function update()
	local def, step = QuestsWindow.TutorialStep()
	local building = BuildMode.IsActive()
	if State.loaded then
		SideBar.SetVisible(if def then REVEAL[math.clamp(step, 1, #REVEAL)] else nil)
	end
	tracker.Visible = not building and State.loaded
	if not def then
		pointUi(nil)
		pointWorld(nil)
		local nextQ = nil
		for _, q in QuestsWindow.DailyList() do
			if not q.claimed then
				nextQ = q
				break
			end
		end
		if nextQ then
			local done = (nextQ.progress or 0) >= (nextQ.goal or 1)
			trackerLabel.Text = (if done then "Claim: " else "Quest: ") .. Kit.StripEmoji(tostring(nextQ.text or nextQ.kind))
			setTracker((nextQ.progress or 0) / math.max(1, nextQ.goal or 1))
		else
			trackerLabel.Text = "All quests done - try a Release!"
			setTracker(1)
		end
		return
	end
	setTracker(State.Num("tutorialProgress") / math.max(1, def.Goal))
	local text = string.format("%d/%d  %s", step, #Derived.Config.Tutorial, Kit.StripEmoji(tostring(def.Text)))
	local ui: GuiObject? = nil
	local world: BasePart? = nil
	local kind = def.Kind
	if kind == "PlantSeed" then
		if building then
			text = "Tap your glowing pad, then Place"
		elseif Windows.IsOpen("Inventory") then
			text = "Tap Plant on your Sproutling"
		else
			ui = SideBar.Button("Inventory")
			text ..= " - open your Bag"
		end
		world = myPad1()
	elseif kind == "PlaceDecor" then
		local growing = sproutGrowing()
		if growing then
			local _, _, left = Derived.Stage(growing)
			text ..= string.format("  (grows in %ds)", math.ceil(left))
		end
		if building then
			text = "Tap a cell next to your Sproutling, then Place"
		elseif not Windows.IsOpen("Build") then
			ui = SideBar.Button("Build")
		end
	elseif kind == "Thriving" then
		local growing = sproutGrowing()
		if growing then
			local _, _, left = Derived.Stage(growing)
			text = string.format("Almost grown... %ds - then it's Thriving!", math.ceil(left))
		else
			text ..= " - tap your creature to see its needs"
		end
		world = myPad1()
	elseif kind == "CollectJar" then
		world = Plots.TaggedPart("TipJar", Plots.MyPlot(), 1)
		text ..= " - collect your tips!"
	elseif kind == "BuySeed" then
		world = Plots.TaggedPart("ShopStand")
		if not Windows.IsOpen("Shop") then
			ui = SideBar.Button("Shop")
		end
	elseif kind == "BuyPad" then
		ui = goalCard
	end
	trackerLabel.Text = text
	pointUi(if Windows.IsOpen("Creature") then nil else ui)
	pointWorld(world)
end

function Tutorial.Mount(screenGui: ScreenGui)
	gui = screenGui
	local root = Kit.Root(gui)
	tracker = Kit.Button(root, "", Style.Pal.Body, function()
		Windows.Toggle("Quests")
	end, {
		Name = "Tracker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, if Kit.IsTouch() then -150 else -16),
		Size = UDim2.fromOffset(620, 88),
		Radius = 18,
		Visible = false,
		ZIndex = 2,
	})
	local face = Kit.ButtonFace(tracker)
	trackerLabel = Kit.Label(face, "", {
		Size = UDim2.new(1, -28, 0, 40),
		Position = UDim2.fromOffset(14, 6),
		TextSize = 26,
		ZIndex = 5,
	})
	_skip, setTracker = Kit.Progress(face, "Leaf", {
		Size = UDim2.new(1, -28, 0, 20),
		Position = UDim2.fromOffset(14, 50),
		ZIndex = 5,
	})

	uiArrow = arrow(root, Vector2.new(72, 50))
	uiArrow.Visible = false

	worldFolder = Kit.Make("Folder", { Name = "TutorialWorld" }, workspace.CurrentCamera)
	local anchor = Kit.Make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.one,
	}, worldFolder)
	targetAtt = Kit.Make("Attachment", {}, anchor)
	beam = Kit.Make("Beam", {
		Attachment1 = targetAtt,
		Color = ColorSequence.new(Style.Pal.Sun.Bottom),
		Width0 = 0.8,
		Width1 = 0.8,
		FaceCamera = true,
		LightEmission = 0.6,
		Transparency = NumberSequence.new(0.2),
		Segments = 20,
		CurveSize0 = 4,
		Enabled = false,
	}, worldFolder)
	worldArrow = Kit.Make("BillboardGui", {
		Name = "TutorialArrow",
		Size = UDim2.fromOffset(84, 84),
		StudsOffset = Vector3.new(0, 6, 0),
		AlwaysOnTop = true,
		Enabled = false,
		ResetOnSpawn = false,
	}, player:WaitForChild("PlayerGui"))
	local down = arrow(worldArrow, Vector2.new(84, 58))
	down.AnchorPoint = Vector2.new(0.5, 0.5)
	down.Position = UDim2.fromScale(0.5, 0.5)
	down.Rotation = -90

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		worldArrow.StudsOffset = Vector3.new(0, 6 + math.sin(t * 4) * 0.8, 0)
		local target = uiTarget
		if target and target.Parent and target.Visible then
			local p = Kit.ToRoot(gui, target.AbsolutePosition)
			local s = target.AbsoluteSize / Kit.Scale()
			uiArrow.Position = UDim2.fromOffset(p.X + s.X + 10 + math.sin(t * 6) * 8, p.Y + s.Y / 2 - 25)
		elseif uiArrow.Visible then
			uiArrow.Visible = false
		end
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(update)
			if not ok then
				warn("[UI] tutorial:", err)
			end
			task.wait(0.3)
		end
	end)
end

return Tutorial
