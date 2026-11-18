--!strict
-- Build mode (guide §7): ghost preview (0.5 transparency + green/red Highlight + reason
-- billboard), 4-stud grid snapping, 90 deg rotate (15 deg for decor), delete mode.
-- PC: mouse follows, click places. Touch: tap the ground to move, then press Place (never
-- place on the first tap). Gamepad: screen centre, A place, X rotate, Y delete, B exit.
-- Only fires PlaceItem / RemoveItem / RotateItem; the server decides.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local PlotInfo = require(script.Parent:WaitForChild("PlotInfo"))
local BuildTray = require(script.Parent:WaitForChild("BuildTray"))
local BuildGrid = require(script.Parent:WaitForChild("BuildGrid"))

local BuildMode = {}

local player = Players.LocalPlayer :: Player
local active = false
local item: { [string]: any }? = nil
local rot = 0
local deleting = false
local gridOn = true
local cellX, cellZ = 0, 0
local valid = false
local reason = ""
local folder: Folder
local ghost: Part
local highlight: Highlight
local reasonGui: BillboardGui
local reasonText: TextLabel
local touchPos: Vector3? = nil
local changed = Instance.new("BindableEvent")
BuildMode.Changed = changed.Event -- (active: boolean)

local function isTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- viewport = true for mouse/centre points, false for touch (GUI-inset) points.
local function raycast(screen: Vector2, viewport: boolean): Vector3?
	local cam = workspace.CurrentCamera
	local ray = if viewport
		then cam:ViewportPointToRay(screen.X, screen.Y)
		else cam:ScreenPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder, player.Character :: any }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	if hit then
		return hit.Position
	end
	local center = PlotInfo.Bounds()
	local y = if center then center.Y else 0
	if math.abs(ray.Direction.Y) < 1e-3 then
		return nil
	end
	local t = (y - ray.Origin.Y) / ray.Direction.Y
	return if t > 0 then ray.Origin + ray.Direction * t else nil
end

local function aimPoint(): Vector3?
	if UserInputService.GamepadEnabled and not UserInputService.MouseEnabled then
		local vp = workspace.CurrentCamera.ViewportSize
		return raycast(vp / 2, true)
	end
	if isTouch() then
		return touchPos
	end
	return raycast(UserInputService:GetMouseLocation(), true)
end

local function update()
	if not active then
		return
	end
	local pos = aimPoint()
	if not pos then
		ghost.Parent = nil
		return
	end
	local w, d = 1, 1
	if item and not deleting then
		w, d = PlotInfo.Footprint(item :: any, rot)
	end
	local cx, cz = PlotInfo.ToCell(pos)
	cellX, cellZ = cx - math.floor((w - 1) / 2), cz - math.floor((d - 1) / 2)
	local center = PlotInfo.Center()
	if not center then
		valid, reason = true, ""
	elseif not PlotInfo.InBounds(cellX, cellZ, w, d) then
		valid, reason = false, "Outside your plot"
	elseif deleting then
		valid = PlotInfo.ItemAt(cellX, cellZ) ~= nil
		reason = if valid then "" else "Nothing here"
	else
		local def = item :: any
		local layer = PlotInfo.Occupied()[if def.Layer == "floor" then "floor" else "object"]
		valid, reason = true, ""
		for dx = 0, w - 1 do
			for dz = 0, d - 1 do
				if layer[(cellX + dx) .. "," .. (cellZ + dz)] then
					valid, reason = false, "Overlapping"
				end
			end
		end
		local stored = tonumber(State.Tbl("decorInv")[def.Id]) or 0
		local free = (def.Pass and player:GetAttribute("Pass_" .. def.Pass) == true)
			or (def.Starter and State.Tbl("flags").starterPack == true)
		if valid and stored <= 0 and not free then
			if def.RP and State.Num("rp") < def.RP then
				valid, reason = false, "Not enough RP"
			elseif not def.RP and State.Num("coins") < (tonumber(def.Cost) or 0) then
				valid, reason = false, "Not enough Coins"
			end
		end
	end
	local size = Vector3.new(w * PlotInfo.Cell, if deleting then 0.4 else 2, d * PlotInfo.Cell)
	ghost.Size = size
	ghost.CFrame = PlotInfo.CellCFrame(cellX, cellZ, w, d, if deleting then 0 else rot) * CFrame.new(0, size.Y / 2, 0)
	local color = if deleting then Style.Color.Invalid elseif valid then Style.Color.Valid else Style.Color.Invalid
	ghost.Color = color
	highlight.FillColor = color
	highlight.OutlineColor = color
	ghost.Parent = if item or deleting then folder else nil
	reasonText.Text = reason
	reasonGui.Enabled = reason ~= ""
	BuildGrid.Draw(folder, if gridOn then center else nil)
end

function BuildMode.Place()
	if not active then
		return
	end
	update()
	if deleting then
		local uid = PlotInfo.ItemAt(cellX, cellZ)
		if valid and uid then
			Net.Do("RemoveItem", nil, uid)
		end
		return
	end
	if not item then
		Net.Toast("Pick something from the tray first", "info")
		return
	end
	if not valid then
		Kit.Sound("Build_Invalid")
		Net.Toast(if reason ~= "" then reason else "Can't place here", "error")
		return
	end
	local ok = Net.Do("PlaceItem", nil, (item :: any).Id, cellX, cellZ, rot)
	if ok then
		ghost.Size *= 1.2 -- server plays the place thud
	end
end

function BuildMode.Rotate(step: number?)
	local fine = item ~= nil and (item :: any).Fine == true
	local s = step or 90
	if s ~= 90 and s ~= -90 and not fine then
		s = if s > 0 then 90 else -90
	end
	rot = (rot + s) % 360
	if not fine then
		rot = rot - rot % 90
	end
	Kit.Sound("Rotate")
	update()
end

function BuildMode.Select(def: { [string]: any }?)
	item = def
	deleting = false
	BuildTray.SetMode(deleting, gridOn)
	update()
end

function BuildMode.ToggleDelete()
	deleting = not deleting
	BuildTray.SetMode(deleting, gridOn)
	update()
end

function BuildMode.ToggleGrid()
	gridOn = not gridOn
	BuildTray.SetMode(deleting, gridOn)
	update()
end

function BuildMode.IsActive(): boolean
	return active
end

function BuildMode.Enter()
	if active then
		return
	end
	active = true
	item, deleting, touchPos = nil, false, nil
	BuildTray.Show(true)
	changed:Fire(true)
end

function BuildMode.Exit()
	if not active then
		return
	end
	active = false
	ghost.Parent = nil
	BuildGrid.Draw(folder, nil)
	reasonGui.Enabled = false
	BuildTray.Show(false)
	changed:Fire(false)
end

function BuildMode.Mount(gui: ScreenGui)
	folder = Kit.Make("Folder", { Name = "WildBuildGhost" }, workspace.CurrentCamera)
	ghost = Kit.Make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Transparency = 0.5,
		Material = Enum.Material.SmoothPlastic,
	})
	highlight = Kit.Make("Highlight", { FillTransparency = 0.6, DepthMode = Enum.HighlightDepthMode.Occluded }, ghost)
	reasonGui = Kit.Make("BillboardGui", {
		Size = UDim2.fromOffset(220, 40),
		StudsOffset = Vector3.new(0, 4, 0),
		AlwaysOnTop = true,
		Enabled = false,
	}, ghost)
	reasonText = Kit.Title(reasonGui, "", Style.Pal.Red.Dark, { TextSize = 26, TextColor3 = Style.Pal.Red.Top })
	BuildTray.Mount(gui, {
		Select = BuildMode.Select,
		Place = BuildMode.Place,
		Rotate = BuildMode.Rotate,
		Delete = BuildMode.ToggleDelete,
		Grid = BuildMode.ToggleGrid,
		Exit = BuildMode.Exit,
	})
	RunService.RenderStepped:Connect(update)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not active or processed then
			return
		end
		local k = input.KeyCode
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			BuildMode.Place()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			touchPos = raycast(Vector2.new(input.Position.X, input.Position.Y), false)
		elseif k == Enum.KeyCode.R or k == Enum.KeyCode.ButtonX then
			BuildMode.Rotate(90)
		elseif k == Enum.KeyCode.Q then
			BuildMode.Rotate(-15)
		elseif k == Enum.KeyCode.E then
			BuildMode.Rotate(15)
		elseif k == Enum.KeyCode.X or k == Enum.KeyCode.ButtonY then
			BuildMode.ToggleDelete()
		elseif k == Enum.KeyCode.G then
			BuildMode.ToggleGrid()
		elseif k == Enum.KeyCode.ButtonA then
			BuildMode.Place()
		elseif k == Enum.KeyCode.Escape or k == Enum.KeyCode.ButtonB then
			BuildMode.Exit()
		elseif k == Enum.KeyCode.ButtonL1 or k == Enum.KeyCode.ButtonR1 then
			BuildTray.CycleCategory(if k == Enum.KeyCode.ButtonR1 then 1 else -1)
		end
	end)
end

return BuildMode
