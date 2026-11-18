--!strict
-- Context bar (guide §3): appears bottom-centre only when you're within ~12 studs of a creature
-- or your egg. Own creature: Feed / Pet / Inspect. Wild: Capture. Own egg: Hatch (or timer).
-- Hidden while building, while a window is open, or while capturing.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local WorldQuery = require(script.Parent:WaitForChild("WorldQuery"))
local CaptureUI = require(script.Parent:WaitForChild("CaptureUI"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local ContextBar = {}

local RANGE = 12
local bar: Frame
local current: Instance? = nil
local currentKind = ""
local suppressed = false
local inspectFn: ((any) -> ())? = nil
local hatchBtn: TextButton? = nil
local actionSignal = Instance.new("BindableEvent")
ContextBar.Action = actionSignal.Event -- (action: string) for the tutorial

function ContextBar.SetInspect(fn: (any) -> ())
	inspectFn = fn
end

local function button(text: string, icon: string, color: string, order: number, fn: () -> ()): TextButton
	return Kit.Button(bar, text, color, function()
		fn()
		actionSignal:Fire(text)
	end, { Size = UDim2.fromOffset(200, 64), Icon = icon, LayoutOrder = order, TextSize = 26 })
end

local function build(inst: Instance, kind: string)
	Kit.Clear(bar)
	hatchBtn = nil
	if kind == "own" then
		local uid = inst:GetAttribute("Uid")
		button("Feed", "Feed", "Leaf", 1, function()
			Kit.Sound("Feed")
			Net.Do("FeedCreature", nil, uid)
		end)
		button("Pet", "Pet", "Coral", 2, function()
			Kit.Sound("Pet")
			Net.Do("PetCreature", nil, uid)
		end)
		button("Inspect", "Inspect", "Sky", 3, function()
			if inspectFn then
				(inspectFn :: (any) -> ())(uid)
			end
		end)
	elseif kind == "wild" then
		button("Capture", "Capture", "Teal", 1, function()
			CaptureUI.Open(inst)
		end)
	elseif kind == "egg" then
		hatchBtn = button("Hatch!", "Hatch", "Sun", 1, function()
			local ready = tonumber(inst:GetAttribute("ReadyAt")) or 0
			if ready > State.Now() then
				Net.Toast("Hatching in " .. Format.Time(ready - State.Now()), "info")
				return
			end
			Net.Do("HatchEgg", nil, inst:GetAttribute("EggId"))
		end)
	end
	Kit.PopIn(bar, 0.7, 0.25)
end

local function pick(): (Instance?, string)
	local egg = WorldQuery.Nearest(WorldQuery.Eggs(), RANGE, WorldQuery.IsMine)
	if egg then
		return egg, "egg"
	end
	local c = WorldQuery.Nearest(WorldQuery.Creatures(), RANGE, function(i)
		return WorldQuery.IsMine(i) or i:GetAttribute("WildId") ~= nil
	end)
	if c then
		return c, if WorldQuery.IsMine(c) then "own" else "wild"
	end
	return nil, ""
end

function ContextBar.Mount(gui: ScreenGui)
	local root = Kit.Root(gui)
	bar = Kit.Make("Frame", {
		Name = "ContextBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.fromOffset(640, 72),
		Visible = false,
	}, root)
	Kit.List(bar, true, 14, true)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local hide = suppressed or CaptureUI.IsOpen() or Windows.AnyOpen()
			local inst, kind = pick()
			if hide or not inst then
				bar.Visible = false
				current = nil
			else
				if inst ~= current or kind ~= currentKind then
					current, currentKind = inst, kind
					build(inst :: Instance, kind)
				end
				bar.Visible = true
				local hb = hatchBtn
				if hb and inst then
					local left = (tonumber((inst :: Instance):GetAttribute("ReadyAt")) or 0) - State.Now()
					hb.Text = if left > 0 then Format.Time(left) else "Hatch!"
				end
			end
		end
	end)
end

-- Build mode / tutorial overlays hide the bar.
function ContextBar.Suppress(on: boolean)
	suppressed = on
end

return ContextBar
