--!strict
-- Creature Inspect (guide §5): left 40% = big live viewport (auto-rotates 8 deg/s, drag to
-- rotate, pauses on touch) + name field; right 60% = 4 pill tabs (Overview / Genetics /
-- Family / Care) rendered by InspectTabs. One window, no submenus.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local InspectTabs = require(script.Parent:WaitForChild("InspectTabs"))

local InspectWindow = {}

local win: any
local left: Frame
local viewHolder: Frame
local nameBox: TextBox
local content: Frame
local choose: (string) -> ()
local currentUid: any = nil
local currentTab = "Overview"
local angle = 0
local dragging = false
local lastSig = ""
local lastViewSig = ""
local view: GuiObject? = nil

local function creature(): { [string]: any }?
	return if currentUid ~= nil then Derived.Creature(currentUid) else nil
end

local function renderView(c: { [string]: any })
	Kit.Clear(viewHolder)
	view = Kit.CreatureView(viewHolder, tostring(c.species), {
		Genes = c.genes,
		Mutations = Derived.Muts(c),
		Stage = Derived.Stage(c),
		Rarity = Derived.Rarity(tostring(c.species)),
		ZIndex = 5,
		Burst = true,
	})
end

local function render(force: boolean?)
	if not Windows.IsOpen("Inspect") then
		return
	end
	local c = creature()
	if not c then
		Windows.Close()
		return
	end
	local sig = Kit.Sig({ c, currentTab })
	if sig == lastSig and not force then
		return
	end
	local viewSig = Kit.Sig({ c.species, c.genes, c.mutations, c.stage, c.uid })
	if force or viewSig ~= lastViewSig then
		renderView(c)
	end
	lastSig = sig
	lastViewSig = viewSig
	if not nameBox:IsFocused() then
		nameBox.Text = Derived.Name(c)
	end
	Kit.Clear(content)
	InspectTabs.Render(currentTab, content, c)
end

function InspectWindow.Mount()
	win = Windows.Create("Inspect", "Creature", "Teal", "Inspect", Vector2.new(860, 600))
	left = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.4, -10, 1, 0) }, win.Body)
	local pane = Kit.Panel(left, nil, { Size = UDim2.new(1, 0, 1, -64) })
	viewHolder = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		ZIndex = 5,
	}, pane)
	local drag = Kit.Make("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
	}, pane)
	drag.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			angle += input.Delta.X * 0.6
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if view and view.Parent and Windows.IsOpen("Inspect") then
			if not dragging then
				angle += 8 * dt
			end
			Kit.OrbitView(view, angle)
		end
	end)

	-- Name field (server filters text; rename only if Gameplay built the remote).
	local namePanel = Kit.Panel(left, nil, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 54),
	})
	nameBox = Kit.Make("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Font = Style.Font,
		TextSize = 26,
		TextColor3 = Style.Color.Ink,
		ClearTextOnFocus = false,
		Text = "",
		PlaceholderText = "Name",
		ZIndex = 5,
	}, namePanel)
	nameBox.FocusLost:Connect(function()
		local c = creature()
		if not c or nameBox.Text == Derived.Name(c) then
			return
		end
		local text = string.sub(nameBox.Text, 1, 20)
		if Net.Has("RenameCreature") then
			Net.Do("RenameCreature", "Renamed!", c.uid, text)
		else
			nameBox.Text = Derived.Name(c)
		end
	end)

	local right = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.6, -10, 1, 0),
	}, win.Body)
	local tabs = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52) }, right)
	content = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -64),
	}, right)
	choose = Kit.Tabs(tabs, { "Overview", "Genetics", "Family", "Care" }, function(name)
		currentTab = name
		render(false)
	end, "Teal")

	win.OnOpen = function(uid: any)
		if uid ~= nil then
			currentUid = uid
		end
		lastSig = ""
		angle = 0
		choose("Overview")
		render(true)
	end
	InspectTabs.SetOpener(function(uid: any)
		currentUid = uid
		lastSig = ""
		choose("Overview")
	end)
	State.OnChange(function(what)
		if what == "data" then
			render()
		end
	end)
end

-- Open on a specific tab (e.g. Care from the context bar).
function InspectWindow.Open(uid: any, tab: string?)
	Windows.Open("Inspect", uid)
	if tab then
		choose(tab)
	end
end

return InspectWindow
