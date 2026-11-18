--!strict
-- Wild capture panel (spec "Capture"): trust meter (creature attribute Trust 0-100), Throw Bait,
-- then HOLD the Calm Net button: a ring shrinks; release while it's inside the green zone.
-- The server opens the window on CaptureStart and validates the release time on
-- CaptureRelease (+-150 ms). The client only shows the ring and sends the intents.
local RunService = game:GetService("RunService")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local WorldQuery = require(script.Parent:WaitForChild("WorldQuery"))

local CaptureUI = {}

local panel: Frame
local ringHolder: Frame
local ring: Frame
local zone: Frame
local trustSet: (number) -> ()
local title: TextLabel
local baitBtn: TextButton
local target: Instance? = nil
local holding = false
local holdStart = 0
local duration = 1.6
local zoneFrom, zoneTo = 0.55, 0.8 -- progress window (0 = ring big, 1 = ring gone)

local function baitCount(): number
	local inv = State.Tbl("inventory")
	local bait = inv.bait or State.Tbl("bait")
	local n = 0
	if type(bait) == "table" then
		for _, v in bait do
			n += tonumber(v) or 0
		end
	end
	return n
end

function CaptureUI.Mount(gui: ScreenGui)
	local root = Kit.Root(gui)
	panel = Kit.Make("Frame", {
		Name = "Capture",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(520, 200),
		Visible = false,
	}, root)
	local face = Kit.Slab(panel, Style.Pal.Body, 22, 6, 4)
	title = Kit.Label(face, "Wild creature", { Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -90, 0, 34), TextSize = 28, ZIndex = 4, TextXAlignment = Enum.TextXAlignment.Left })
	Kit.Body(face, "Trust", { Position = UDim2.fromOffset(16, 48), Size = UDim2.fromOffset(70, 24), TextSize = 18, ZIndex = 4 })
	local _, setter = Kit.Progress(face, "Coral", { Position = UDim2.fromOffset(90, 52), Size = UDim2.new(1, -110, 0, 18), ZIndex = 4 })
	trustSet = setter
	baitBtn = Kit.Button(face, "Throw Bait", "Sun", function()
		local t = target
		if not t then
			return
		end
		Kit.Sound("Bait_Throw")
		Net.Do("ThrowBait", nil, WorldQuery.Pos(t))
	end, { Position = UDim2.fromOffset(16, 92), Size = UDim2.fromOffset(200, 80), ZIndex = 5 })
	local net = Kit.Button(face, "HOLD NET", "Teal", nil, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 92),
		Size = UDim2.fromOffset(260, 80),
		TextSize = 30,
		ZIndex = 5,
	})
	Kit.Button(face, "X", "Red", CaptureUI.Close, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(48, 48),
		ZIndex = 6,
	})

	-- Ring over the creature area: big circle shrinking; green band = timing zone.
	ringHolder = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(320, 320),
		Visible = false,
	}, root)
	zone = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	}, ringHolder)
	Kit.Corner(zone, 99)
	Kit.Stroke(zone, Style.Pal.Leaf.Top, 14).Transparency = 0.2
	ring = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, ringHolder)
	Kit.Corner(ring, 99)
	Kit.Stroke(ring, Color3.new(1, 1, 1), 6)

	net.MouseButton1Down:Connect(function()
		CaptureUI.Hold()
	end)
	net.MouseButton1Up:Connect(function()
		CaptureUI.Release()
	end)
	net.MouseLeave:Connect(function()
		if holding then
			CaptureUI.Release()
		end
	end)
	RunService.RenderStepped:Connect(function()
		local t = target
		if not panel.Visible or not t then
			return
		end
		if not t.Parent then
			CaptureUI.Close()
			return
		end
		trustSet((tonumber(t:GetAttribute("Trust")) or 0) / 100)
		if holding then
			local p = math.clamp((os.clock() - holdStart) / duration, 0, 1)
			ring.Size = UDim2.fromScale(1 - p, 1 - p)
			if p >= 1 then
				CaptureUI.Release()
			end
		end
	end)
end

function CaptureUI.Open(wild: Instance)
	target = wild
	local species = tostring(wild:GetAttribute("Species") or "Wild creature")
	title.Text = "Wild " .. species .. "  ·  " .. Derived.Rarity(species)
	baitBtn.Text = "Throw Bait (" .. baitCount() .. ")"
	panel.Visible = true
	Kit.PopIn(panel, 0.7, 0.3)
end

function CaptureUI.IsOpen(): boolean
	return panel.Visible
end

function CaptureUI.Close()
	panel.Visible = false
	ringHolder.Visible = false
	holding = false
	target = nil
end

function CaptureUI.Hold()
	local t = target
	if holding or not t then
		return
	end
	local wildId = t:GetAttribute("WildId")
	local ok, res = Net.Call("CaptureStart", wildId)
	if not ok then
		return
	end
	if type(res) == "table" then
		duration = tonumber(res.duration) or duration
		zoneFrom = tonumber(res.zoneStart) or zoneFrom
		zoneTo = tonumber(res.zoneEnd) or zoneTo
	end
	-- Border stroke grows outward: inner edge = ring size at zoneTo, thickness = band radius.
	local inner = 1 - zoneTo
	zone.Size = UDim2.fromScale(inner, inner)
	local s = zone:FindFirstChildOfClass("UIStroke")
	if s then
		s.Thickness = math.max(4, (zoneTo - zoneFrom) * 160)
	end
	ring.Size = UDim2.fromScale(1, 1)
	ringHolder.Visible = true
	holding = true
	holdStart = os.clock()
	Kit.Sound("Capture_Wobble")
end

function CaptureUI.Release()
	local t = target
	if not holding or not t then
		return
	end
	holding = false
	Kit.Tween(ring, 0.15, { Size = UDim2.fromScale(0, 0) })
	task.delay(0.25, function()
		ringHolder.Visible = false
	end)
	Kit.Sound("Capture_Throw")
	Net.Call("CaptureRelease", t:GetAttribute("WildId"))
end

return CaptureUI
