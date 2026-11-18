--!strict
-- Build tray UI (guide §7): bottom tray with category tabs + item cards (price chip and
-- "+Habitat" tags), the right-side action column (84 px, stacked above the jump button, key
-- hints on PC) and the live habitat-rating strip at the top-centre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local PlotInfo = require(script.Parent:WaitForChild("PlotInfo"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local BuildTray = {}

type Actions = {
	Select: (any) -> (),
	Place: () -> (),
	Rotate: (number?) -> (),
	Delete: () -> (),
	Grid: () -> (),
	Exit: () -> (),
}

local actions: Actions
local tray: Frame
local tabsRow: ScrollingFrame
local itemsRow: ScrollingFrame
local column: Frame
local strip: Frame
local setStars: (number) -> ()
local ratingText: TextLabel
local needText: TextLabel
local deleteBtn: TextButton
local gridBtn: TextButton
local categories: { string } = {}
local catIdx = 1
local selectedId: string? = nil
local highlightId: string? = nil
local lastRating = -1

local function renderItems()
	Kit.Clear(itemsRow)
	local cat = categories[catIdx]
	local lvl = Derived.Level()
	local i = 0
	for _, def in PlotInfo.Items() do
		if tostring(Derived.Field(def, "category", "Category") or "Decor") == cat then
			i += 1
			local need = tonumber(Derived.Field(def, "level", "Level", "unlockLevel")) or 0
			local locked = need > lvl
			local price = tonumber(Derived.Field(def, "price", "Price", "cost")) or 0
			local sel = selectedId == def.id
			local pal = if locked then "Stone" elseif sel then "Leaf" else "Card"
			local b = Kit.Button(itemsRow, "", pal, function()
				if locked then
					Kit.Sound("Error")
					return
				end
				selectedId = def.id
				actions.Select(def)
				renderItems()
			end, { Size = UDim2.fromOffset(120, 136), LayoutOrder = i, Name = tostring(def.id) })
			local face = Kit.ButtonFace(b)
			Kit.Icon(face, tostring(def.id), {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 8),
				Size = UDim2.fromOffset(52, 52),
				ZIndex = 4,
			})
			Kit.Label(face, tostring(def.name or def.id), {
				Position = UDim2.fromOffset(4, 62),
				Size = UDim2.new(1, -8, 0, 22),
				TextSize = 18,
				ZIndex = 4,
			})
			local tags = Derived.Field(def, "tags", "Tags")
			if type(tags) == "table" and #tags > 0 then
				Kit.Body(face, "+" .. table.concat(tags, " +"), {
					Position = UDim2.fromOffset(4, 84),
					Size = UDim2.new(1, -8, 0, 16),
					TextSize = 13,
					TextColor3 = Style.Pal.Leaf.Dark,
					ZIndex = 4,
				})
			end
			Kit.Chip(face, if locked then "Lv " .. need else Format.Number(price), {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -4),
				Size = UDim2.new(1, -16, 0, 24),
				ZIndex = 5,
			})
			if highlightId == def.id then
				Kit.Pulse(b, 1.1)
				Kit.Badge(b).Visible = true
			end
		end
	end
end

local function renderTabs()
	Kit.Clear(tabsRow)
	categories = PlotInfo.Categories()
	catIdx = math.clamp(catIdx, 1, math.max(1, #categories))
	for i, c in categories do
		Kit.Button(tabsRow, c, if i == catIdx then "Wood" else "Card", function()
			catIdx = i
			renderTabs()
			renderItems()
		end, { Size = UDim2.fromOffset(150, 52), LayoutOrder = i, TextSize = 20, Radius = 99, Lip = 4 })
	end
end

local function actionButton(name: string, label: string, color: string, key: string?, fn: () -> (), order: number): TextButton
	local b = Kit.IconButton(column, name, label, color, fn, { LayoutOrder = order, Size = UDim2.fromOffset(84, 84) })
	if key then
		Kit.KeyHint(Kit.ButtonHolder(b), key)
	end
	return b
end

function BuildTray.Mount(gui: ScreenGui, a: Actions)
	actions = a
	local root = Kit.Root(gui)
	local phone = Kit.IsTouch()
	tray = Kit.Make("Frame", {
		Name = "BuildTray",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 260),
		Size = if phone then UDim2.new(0.6, 0, 0, 180) else UDim2.new(1, -440, 0, 210),
		Visible = false,
	}, root)
	local face = Kit.Slab(tray, Style.Pal.Body, 22, 6, 4)
	tabsRow = Kit.Scroll(face, {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 62),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,
		ZIndex = 4,
	})
	Kit.List(tabsRow, true, 8).VerticalAlignment = Enum.VerticalAlignment.Center
	itemsRow = Kit.Scroll(face, {
		Position = UDim2.fromOffset(12, 70),
		Size = UDim2.new(1, -24, 1, -76),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,
		ZIndex = 4,
	})
	Kit.List(itemsRow, true, 10).VerticalAlignment = Enum.VerticalAlignment.Center

	-- Action column: right side, above the jump button / tray.
	column = Kit.Make("Frame", {
		Name = "BuildActions",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, if phone then -170 else -240),
		Size = UDim2.fromOffset(84, 5 * 84 + 4 * 30),
		Visible = false,
	}, root)
	local list = Kit.List(column, false, 30)
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	actionButton("Exit", "Done", "Red", "Esc", a.Exit, 1)
	gridBtn = actionButton("Grid", "Grid", "Teal", "G", a.Grid, 2)
	deleteBtn = actionButton("Delete", "Delete", "Red", "X", a.Delete, 3)
	actionButton("Rotate", "Rotate", "Sky", "R", function()
		a.Rotate(90)
	end, 4)
	actionButton("Place", "Place", "Leaf", nil, a.Place, 5)

	-- Habitat rating strip (top-centre, under the biome chip).
	strip = Kit.Make("Frame", {
		Name = "RatingStrip",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 68),
		Size = UDim2.fromOffset(460, 50),
		Visible = false,
	}, root)
	local sface = Kit.Slab(strip, Style.Pal.Body, 99, 4, 3)
	local _, setter = Kit.Stars(sface, { Position = UDim2.fromOffset(16, 10), ZIndex = 4 })
	setStars = setter
	ratingText = Kit.Label(sface, "0", { Position = UDim2.fromOffset(186, 4), Size = UDim2.fromOffset(60, 36), TextSize = 26, ZIndex = 4 })
	needText = Kit.Body(sface, "", { Position = UDim2.fromOffset(250, 4), Size = UDim2.new(1, -262, 0, 36), TextSize = 18, ZIndex = 4 })
	State.OnChange(function(what)
		if what == "data" and tray.Visible then
			BuildTray.RefreshRating()
		end
	end)
end

-- Rating = best habitat (data.habitats[*].rating) or the park rating; hint = first missing need.
function BuildTray.RefreshRating()
	local best, hint = State.Num("parkRating"), nil
	for _, h in State.Tbl("habitats") do
		if type(h) == "table" then
			local r = tonumber(h.rating) or 0
			if r >= best then
				best = r
			end
			local hints = h.hints or h.missing
			if not hint and type(hints) == "table" and hints[1] then
				hint = tostring(if type(hints[1]) == "table" then hints[1].text or hints[1].need else hints[1])
			end
		end
	end
	setStars(best)
	if lastRating >= 0 and best > lastRating then
		Kit.Sound("RatingUp")
		Kit.PopIn(strip, 1.15, 0.35)
	end
	lastRating = best
	ratingText.Text = tostring(math.floor(best))
	needText.Text = if hint then "Needs: " .. hint else "Add plants, rocks and food to raise it"
end

function BuildTray.Show(on: boolean)
	if on then
		renderTabs()
		renderItems()
		tray.Visible, column.Visible, strip.Visible = true, true, true
		Kit.Tween(tray, 0.25, { Position = UDim2.new(0.5, 0, 1, -12) }, Enum.EasingStyle.Back)
		BuildTray.RefreshRating()
	else
		Kit.Tween(tray, 0.2, { Position = UDim2.new(0.5, 0, 1, 260) })
		column.Visible, strip.Visible = false, false
		selectedId = nil
		task.delay(0.2, function()
			if column.Visible == false then
				tray.Visible = false
			end
		end)
	end
end

function BuildTray.SetMode(deleting: boolean, gridOn: boolean)
	Kit.SetButtonColor(deleteBtn, if deleting then "Coral" else "Red")
	Kit.SetButtonColor(gridBtn, if gridOn then "Teal" else "Stone")
	if deleting then
		selectedId = nil
		renderItems()
	end
end

function BuildTray.CycleCategory(dir: number)
	if #categories == 0 then
		return
	end
	catIdx = (catIdx - 1 + dir) % #categories + 1
	renderTabs()
	renderItems()
end

-- Tutorial: pulse + "!" on one item, and jump to its category.
function BuildTray.HighlightItem(id: string?)
	highlightId = id
	if id then
		local def = PlotInfo.Item(id)
		local cat = tostring(Derived.Field(def, "category", "Category") or "")
		local idx = table.find(PlotInfo.Categories(), cat)
		if idx then
			catIdx = idx
		end
	end
	if tray and tray.Visible then
		renderTabs()
		renderItems()
	end
end

return BuildTray
