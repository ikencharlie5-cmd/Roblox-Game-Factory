--!strict
-- Left column: 8 square icon buttons (2 columns, more columns on short screens so the bottom-left
-- joystick zone stays clear on touch). Red "!" badges = something to claim. During the tutorial
-- only the buttons the player has reached are shown; new ones pop in (staggered 0.06 s).
local Kit = require(script.Parent:WaitForChild("Kit"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local SideBar = {}

-- Upgrades lives in the Build window (max 8 left buttons); Store + Settings are top-right.
local BUTTONS = {
	{ Name = "Shop", Label = "Shop", Pal = "Leaf" },
	{ Name = "Inventory", Label = "Bag", Pal = "Sky" },
	{ Name = "Build", Label = "Build", Pal = "Wood" },
	{ Name = "Index", Label = "Index", Pal = "Purple" },
	{ Name = "Release", Label = "Release", Pal = "Teal" },
	{ Name = "Quests", Label = "Quests", Pal = "Pink" },
	{ Name = "Daily", Label = "Daily", Pal = "Sun" },
	{ Name = "Visit", Label = "Visit", Pal = "Sky" },
}

local CELL, GAP_X, GAP_Y, TOP = 84, 12, 18, 236

local gui: ScreenGui
local bar: Frame
local grid: UIGridLayout
local barScale: UIScale
local buttons: { [string]: TextButton } = {}
local badges: { [string]: Frame } = {}
local shown: { [string]: boolean } = {}

local function fit()
	local count = 0
	for _, b in buttons do
		if b.Visible then
			count += 1
		end
	end
	count = math.max(count, 1)
	local v = Kit.Virtual(gui)
	local bottom = if Kit.IsTouch() then 190 else 24
	local avail = math.max(120, v.Y - TOP - bottom)
	local cols, h = 2, 0
	for c = 2, 4 do
		cols = c
		local rows = math.ceil(count / c)
		h = rows * CELL + (rows - 1) * GAP_Y + 12
		if h <= avail then
			break
		end
	end
	local s = math.min(1, avail / h)
	barScale.Scale = s
	grid.FillDirectionMaxCells = cols
	local w = cols * CELL + (cols - 1) * GAP_X
	bar.Size = UDim2.fromOffset(w, h)
	-- Vertically centred in the free space under the currency chips (anchored at its centre so
	-- the UIScale shrink keeps the left edge at 16 px).
	bar.Position = UDim2.fromOffset(16 + w * s / 2, TOP + math.max(0, (avail - h * s) / 2) + h * s / 2)
end

function SideBar.Mount(screenGui: ScreenGui)
	gui = screenGui
	bar = Kit.Make("Frame", {
		Name = "SideBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(16, TOP),
		Size = UDim2.fromOffset(180, 400),
		ZIndex = 2,
	}, Kit.Root(gui))
	barScale = Kit.Make("UIScale", { Scale = 1 }, bar)
	grid = Kit.Grid(bar, UDim2.fromOffset(CELL, CELL), GAP_X)
	grid.CellPadding = UDim2.fromOffset(GAP_X, GAP_Y)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left

	for i, def in BUTTONS do
		local b = Kit.IconButton(bar, def.Name, def.Label, def.Pal, function()
			Windows.Toggle(def.Name)
		end, { LayoutOrder = i })
		b.Name = def.Name
		buttons[def.Name] = b
		badges[def.Name] = Kit.Badge(b)
		shown[def.Name] = true
	end
	Kit.Resized:Connect(fit)
	fit()
end

function SideBar.Badge(name: string, on: boolean)
	local dot = badges[name]
	if dot then
		dot.Visible = on
	end
end

function SideBar.Button(name: string): TextButton?
	return buttons[name]
end

-- Show only these buttons (nil = all). Newly shown buttons pop in, staggered.
function SideBar.SetVisible(names: { string }?)
	local want: { [string]: boolean } = {}
	for _, def in BUTTONS do
		want[def.Name] = names == nil or table.find(names :: { string }, def.Name) ~= nil
	end
	local delay = 0
	local changed = false
	for _, def in BUTTONS do
		local b = buttons[def.Name]
		if want[def.Name] ~= shown[def.Name] then
			changed = true
			shown[def.Name] = want[def.Name]
			b.Visible = want[def.Name]
			if want[def.Name] then
				local press = Kit.ButtonPress(b)
				press.Scale = 0
				task.delay(delay, function()
					Kit.Tween(press, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
				end)
				delay += 0.06
			end
		end
	end
	if changed then
		fit()
	end
end

return SideBar
