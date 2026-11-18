--!strict
-- Tutorial pointers: a bouncing code-drawn gold arrow next to a UI button, and in the world a
-- curved Beam from the player's feet plus a bobbing arrow billboard over the target.
-- Everything lives under the camera / PlayerGui so only this player sees it.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local Arrows = {}

local player = Players.LocalPlayer :: Player
local gui: ScreenGui
local uiArrow: Frame
local uiTarget: GuiObject? = nil
local beam: Beam
local targetAtt: Attachment
local worldArrow: BillboardGui
local worldTarget: Instance? = nil

-- Chunky gold arrow (diamond head + shaft) pointing left; rotate the holder to aim it.
local function arrow(parent: Instance, size: Vector2): Frame
	local pal = Style.Pal.Sun
	local holder = Kit.Make("Frame", {
		Name = "Arrow",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size.X, size.Y),
		ZIndex = 40,
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
		ZIndex = 40,
	})
	piece({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.3, 0.5),
		Size = UDim2.fromScale(0.42, 0.42 * size.X / size.Y),
		Rotation = 45,
		ZIndex = 41,
	})
	return holder
end

local function posOf(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position + Vector3.new(0, inst.Size.Y / 2 + 1, 0)
	elseif inst:IsA("Model") then
		local cf, size = inst:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y / 2 + 1, 0)
	end
	return nil
end

function Arrows.Ui(target: GuiObject?)
	uiTarget = target
	uiArrow.Visible = target ~= nil
end

function Arrows.World(target: Instance?)
	worldTarget = target
	if not target then
		beam.Enabled = false
		worldArrow.Enabled = false
	end
end

function Arrows.Mount(screenGui: ScreenGui)
	gui = screenGui
	uiArrow = arrow(Kit.Root(gui), Vector2.new(72, 50))
	uiArrow.Visible = false
	local folder = Kit.Make("Folder", { Name = "WildTutorialWorld" }, workspace.CurrentCamera)
	local anchor = Kit.Make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.one,
	}, folder)
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
	}, folder)
	worldArrow = Kit.Make("BillboardGui", {
		Name = "TutorialArrow",
		Size = UDim2.fromOffset(84, 84),
		AlwaysOnTop = true,
		Enabled = false,
		ResetOnSpawn = false,
		Adornee = anchor,
	}, player:WaitForChild("PlayerGui"))
	local down = arrow(worldArrow, Vector2.new(84, 58))
	down.AnchorPoint = Vector2.new(0.5, 0.5)
	down.Position = UDim2.fromScale(0.5, 0.5)
	down.Rotation = -90

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local wt = worldTarget
		local p = if wt and wt.Parent then posOf(wt) else nil
		if p then
			targetAtt.WorldPosition = p
			worldArrow.StudsOffsetWorldSpace = Vector3.new(0, 4 + math.sin(t * 4) * 0.8, 0)
			worldArrow.Enabled = true
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local a0 = hrp and hrp:FindFirstChild("WildTutorialAtt") :: Attachment?
			if hrp and not a0 then
				a0 = Kit.Make("Attachment", { Name = "WildTutorialAtt", Position = Vector3.new(0, -2, 0) }, hrp)
			end
			beam.Attachment0 = a0
			beam.Enabled = a0 ~= nil
		elseif worldArrow.Enabled then
			worldArrow.Enabled = false
			beam.Enabled = false
		end
		local target = uiTarget
		if target and target.Parent and target.Visible then
			local pos = Kit.ToRoot(gui, target.AbsolutePosition)
			local s = target.AbsoluteSize / Kit.Scale()
			uiArrow.Position = UDim2.fromOffset(pos.X + s.X + 10 + math.sin(t * 6) * 8, pos.Y + s.Y / 2 - 25)
			uiArrow.Visible = true
		elseif uiArrow.Visible then
			uiArrow.Visible = false
		end
	end)
end

return Arrows
