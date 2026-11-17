--!strict
-- Placement mode: grid ghost (green = free, red = blocked), Rotate 90°, Place, Cancel, and an
-- edit mode (tap an item -> Move / Remove). Mouse: hover + click. Touch: tap a cell, then Place.
-- Only previews locally; the server validates every placement.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local BuildGhost = require(script.Parent:WaitForChild("BuildGhost"))

local BuildMode = {}

export type Opts = { mode: string, ref: any?, label: string? }
-- mode: "seed" (ref species) | "creature" (ref id) | "decor" (ref kind, from bag)
--       "buydecor" (ref kind) | "move" (ref id) | "edit"

local player = Players.LocalPlayer :: Player
local bar: Frame
local titleLabel: TextLabel
local placeBtn: TextButton
local rotateBtn: TextButton
local moveBtn: TextButton
local removeBtn: TextButton

local active: Opts? = nil
local rot = 0 -- quarter turns 0..3 locally; the server wants degrees (rot * 90)
local selPad: number? = nil
local selCell: number? = nil
local selectedItem: number? = nil
local hoverConn: RBXScriptConnection? = nil
local oldZoom = 0
local changedSignal = Instance.new("BindableEvent")
BuildMode.Changed = changedSignal.Event -- (active: boolean)

local function cellFree(pad: number, cell: number): boolean
	if pad > math.max(1, State.Num("padsOwned")) then
		return false
	end
	local exceptId = if active and active.mode == "move" then active.ref else nil
	for _, list in { State.Tbl("placed"), State.Tbl("decor") } do
		for _, item in list do
			if item.pad == pad and item.cell == cell and item.id ~= exceptId then
				return false
			end
		end
	end
	return true
end

local function drawGhost()
	local opts = active
	if not opts or opts.mode == "edit" or not selPad or not selCell then
		BuildGhost.Hide()
		return
	end
	local part = Plots.Pads()[selPad]
	if not part then
		BuildGhost.Hide()
		return
	end
	local pad = selPad
	local free = BuildGhost.Draw(part, selCell, rot, function(c)
		return cellFree(pad, c)
	end)
	Kit.SetButtonColor(placeBtn, if free then Style.Color.Leaf else Style.Color.Grey)
end

local function pick(screen: Vector2, viewport: boolean): (number?, number?, RaycastResult?)
	local res = Plots.Raycast(screen, viewport, { BuildGhost.Folder() })
	if not res then
		return nil, nil, nil
	end
	local pad, cell = Plots.CellAt(res.Position)
	return pad, cell, res
end

local function setButtons()
	local opts = active
	local editing = opts ~= nil and opts.mode == "edit"
	placeBtn.Visible = not editing
	rotateBtn.Visible = not editing
	moveBtn.Visible = editing and selectedItem ~= nil
	removeBtn.Visible = editing and selectedItem ~= nil
end

function BuildMode.Stop()
	if not active then
		return
	end
	active = nil
	selectedItem = nil
	BuildGhost.Hide()
	bar.Visible = false
	if hoverConn then
		hoverConn:Disconnect()
		hoverConn = nil
	end
	player.CameraMaxZoomDistance = oldZoom
	changedSignal:Fire(false)
end

local function confirm()
	local opts = active
	if not opts or not selPad or not selCell then
		Kit.Sound("Error")
		return
	end
	if not cellFree(selPad, selCell) then
		Kit.Sound("Error")
		return
	end
	local ok
	if opts.mode == "seed" or opts.mode == "creature" or opts.mode == "decor" then
		ok = Net.Do("PlaceItem", nil, opts.mode, opts.ref, selPad, selCell, rot * 90)
	elseif opts.mode == "buydecor" then
		ok = Net.Do("BuyDecor", nil, opts.ref, selPad, selCell, rot * 90)
	elseif opts.mode == "move" then
		ok = Net.Do("MoveItem", nil, opts.ref, selPad, selCell, rot * 90)
	end
	if ok then
		BuildGhost.Pop()
		-- Decor bought from the shop stays in build mode so you can place several.
		if opts.mode ~= "buydecor" then
			BuildMode.Stop()
		else
			drawGhost()
		end
	end
end

function BuildMode.Start(opts: Opts)
	BuildMode.Stop()
	Windows.Close()
	if not Plots.MyPlot() then
		Kit.Sound("Error")
		return
	end
	active = opts
	selectedItem = nil
	rot = 0
	selPad, selCell = nil, nil
	titleLabel.Text = opts.label
		or (if opts.mode == "edit" then "✋ Tap an item to move or remove it" else "Tap a cell to place")
	bar.Visible = true
	setButtons()
	oldZoom = player.CameraMaxZoomDistance
	player.CameraMaxZoomDistance = math.max(oldZoom, 90)
	-- Default selection: first free cell on pad 1 so the ghost shows right away.
	for c = 13, 25 do
		if cellFree(1, c) then
			selPad, selCell = 1, c
			break
		end
	end
	drawGhost()
	if UserInputService.MouseEnabled then
		hoverConn = RunService.RenderStepped:Connect(function()
			if active and active.mode ~= "edit" then
				local pad, cell = pick(UserInputService:GetMouseLocation(), true)
				if pad and cell and (pad ~= selPad or cell ~= selCell) then
					selPad, selCell = pad, cell
					drawGhost()
				end
			end
		end)
	end
	changedSignal:Fire(true)
end

function BuildMode.IsActive(): boolean
	return active ~= nil
end

local function rotate()
	rot = (rot + 1) % 4
	Kit.Sound("Rotate")
	drawGhost()
end

local function onTap(screen: Vector2, isMouse: boolean)
	local opts = active
	if not opts then
		return
	end
	local pad, cell, res = pick(screen, false)
	if opts.mode == "edit" then
		local model, id = Plots.ItemFromHit(if res then res.Instance else nil)
		if model and id and Plots.IsMine(model) then
			selectedItem = id
			titleLabel.Text = "Selected: "
				.. tostring(model:GetAttribute("Species") or model:GetAttribute("DecorKind") or "item")
			Kit.Sound("Click")
		else
			selectedItem = nil
			titleLabel.Text = "✋ Tap an item to move or remove it"
		end
		setButtons()
		return
	end
	if pad and cell then
		if isMouse and pad == selPad and cell == selCell then
			confirm()
			return
		end
		selPad, selCell = pad, cell
		Kit.Sound("Click")
		drawGhost()
	end
end

function BuildMode.Mount(gui: ScreenGui)
	BuildGhost.Init()
	bar = Kit.Panel(gui, Style.Color.Cream, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.45, 0, 1, -8),
		Size = UDim2.fromScale(0.56, 0.17),
		Visible = false,
	})
	Kit.Make("UISizeConstraint", { MinSize = Vector2.new(320, 96), MaxSize = Vector2.new(720, 130) }, bar)
	titleLabel = Kit.Label(bar, "", { Size = UDim2.new(1, -16, 0.36, 0), Position = UDim2.new(0, 8, 0, 4) })
	local row = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0.44, 0),
		Size = UDim2.new(1, -16, 0.52, 0),
	}, bar)
	Kit.List(row, true, 8, true)
	local function btn(text: string, color: Color3, fn: () -> (), order: number): TextButton
		return Kit.Button(row, text, color, fn, { Size = UDim2.fromScale(0.23, 1), LayoutOrder = order })
	end
	rotateBtn = btn("🔄 Rotate", Style.Color.Sky, rotate, 1)
	placeBtn = btn("✅ Place", Style.Color.Leaf, confirm, 2)
	moveBtn = btn("✋ Move", Style.Color.Sky, function()
		if selectedItem then
			BuildMode.Start({ mode = "move", ref = selectedItem, label = "Pick a new cell" })
		end
	end, 3)
	removeBtn = btn("🗑️ Remove", Style.Color.Red, function()
		local id = selectedItem
		if id then
			Windows.Confirm("Remove item?", "Creatures and decor go back to your Bag.", "Remove", function()
				if Net.Do("RemoveItem", nil, id) then
					Kit.Sound("Remove")
					selectedItem = nil
					setButtons()
				end
			end)
		end
	end, 4)
	btn("❌ Done", Style.Color.Grey, BuildMode.Stop, 5)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not active or processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			rotate()
		elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Q then
			BuildMode.Stop()
		elseif input.KeyCode == Enum.KeyCode.Return then
			confirm()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			onTap(Vector2.new(input.Position.X, input.Position.Y), true)
		end
	end)
	-- TouchTap ignores camera drags, so swiping to look around never moves the ghost.
	UserInputService.TouchTap:Connect(function(positions, processed)
		if active and not processed and positions[1] then
			onTap(Vector2.new(positions[1].X, positions[1].Y), false)
		end
	end)
	State.OnChange(function(what)
		if what == "data" and active then
			drawGhost()
		end
	end)
end

return BuildMode
