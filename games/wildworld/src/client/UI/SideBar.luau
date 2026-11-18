--!strict
-- Left column (guide §3): 6 MVP buttons in a 2x3 grid of 84 px icon buttons, vertically centred,
-- x = 16. Each button stays hidden until unlocked (spec: one new HUD button per goal reached),
-- then pops in. Red count/"!" badges bob on the ones that need attention.
local Kit = require(script.Parent:WaitForChild("Kit"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local SideBar = {}

local BUTTONS = {
	{ "Collection", "Teal" },
	{ "Breed", "Coral" },
	{ "Build", "Wood" },
	{ "Journal", "Purple" },
	{ "Inventory", "Sky" },
	{ "Park", "Leaf" },
}

local column: Frame
local buttons: { [string]: TextButton } = {}
local unlocked: { [string]: boolean } = {}
local handlers: { [string]: () -> () } = {}

function SideBar.Mount(gui: ScreenGui)
	local root = Kit.Root(gui)
	column = Kit.Make("Frame", {
		Name = "SideBar",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 196),
	}, root)
	local grid = Kit.Grid(column, UDim2.fromOffset(84, 84), 14)
	grid.CellPadding = UDim2.fromOffset(14, 26)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	-- Below the currency chips. Short screens (phones) use 3x2 so the joystick zone
	-- (bottom-left 35% x 40%) stays clear; tall screens use 2x3.
	local function layout()
		local short = Kit.Virtual(gui).Y < 820
		local cols = if short then 3 else 2
		local rows = math.ceil(#BUTTONS / cols)
		column.Size = UDim2.fromOffset(cols * 84 + (cols - 1) * 14, rows * 84 + (rows - 1) * 26)
	end
	layout()
	Kit.Resized:Connect(layout)
	for i, def in BUTTONS do
		local name = def[1]
		local b = Kit.IconButton(column, name, name, def[2], function()
			local h = handlers[name]
			if h then
				h()
			else
				Windows.Toggle(name)
			end
		end, { LayoutOrder = i, Visible = false, Name = name })
		Kit.Badge(b)
		buttons[name] = b
	end
end

-- Override what a button does (e.g. Build enters build mode instead of a window).
function SideBar.SetHandler(name: string, fn: () -> ())
	handlers[name] = fn
end

function SideBar.Unlock(name: string, quiet: boolean?)
	local b = buttons[name]
	if not b or unlocked[name] then
		return
	end
	unlocked[name] = true
	b.Visible = true
	if not quiet then
		Kit.PopIn(b, 0, 0.45)
		Kit.Sound("ButtonUnlock")
	end
end

function SideBar.IsUnlocked(name: string): boolean
	return unlocked[name] == true
end

function SideBar.Button(name: string): TextButton?
	return buttons[name]
end

-- on = true shows "!", a number shows the count, false/0 hides.
function SideBar.Badge(name: string, on: any)
	local b = buttons[name]
	local badge = b and b:FindFirstChild("NotifyBadge")
	if not badge or not badge:IsA("GuiObject") then
		return
	end
	local visible = on == true or (type(on) == "number" and on > 0)
	badge.Visible = visible
	local label = badge:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = if type(on) == "number" then tostring(math.min(on, 99)) else "!"
	end
end

-- Slide the column out while building (guide §7).
function SideBar.SetHidden(hidden: boolean)
	Kit.Tween(column, 0.2, {
		Position = if hidden then UDim2.fromOffset(-320, 196) else UDim2.fromOffset(16, 196),
	})
end

return SideBar
