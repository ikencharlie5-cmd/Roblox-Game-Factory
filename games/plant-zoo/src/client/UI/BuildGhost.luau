--!strict
-- Client-only build preview: 5x5 cell tiles (green free / red taken) + a ghost block with a
-- nose showing which way the item will face. Lives under the camera so nobody else sees it.
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Plots = require(script.Parent:WaitForChild("Plots"))

local BuildGhost = {}

local folder: Folder
local ghost: Part
local tiles: { Part } = {}
local GHOST_SIZE = Vector3.new(3.4, 2.4, 3.4)

local function part(props: { [string]: any }): Part
	local p = Kit.Make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
	})
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

function BuildGhost.Init()
	folder = Kit.Make("Folder", { Name = "BuildGhost" }, workspace.CurrentCamera)
	ghost = part({ Size = GHOST_SIZE, Transparency = 0.45 })
	local nose = Kit.Make("WedgePart", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Size = Vector3.new(1.4, 0.8, 1.2),
		Color = Style.Color.White,
		Transparency = 0.2,
	})
	nose.Parent = ghost
	ghost:GetPropertyChangedSignal("CFrame"):Connect(function()
		nose.CFrame = ghost.CFrame * CFrame.new(0, 1.6, -1)
	end)
	for c = 1, 25 do
		tiles[c] = part({ Size = Vector3.new(3.7, 0.1, 3.7), Transparency = 0.65 })
	end
end

function BuildGhost.Folder(): Folder
	return folder
end

function BuildGhost.Hide()
	ghost.Parent = nil
	for _, t in tiles do
		t.Parent = nil
	end
end

-- Draws the grid on `pad` and the ghost at `cell`. Returns whether that cell is free.
function BuildGhost.Draw(pad: BasePart, cell: number, rot: number, isFree: (number) -> boolean): boolean
	for c = 1, 25 do
		local t = tiles[c]
		t.CFrame = Plots.CellCFrame(pad, c, 0) * CFrame.new(0, 0.1, 0)
		t.Color = if isFree(c) then Style.Color.Leaf else Style.Color.Red
		t.Parent = folder
	end
	local free = isFree(cell)
	ghost.Color = if free then Style.Color.Cash else Style.Color.Red
	ghost.CFrame = Plots.CellCFrame(pad, cell, rot) * CFrame.new(0, 1.2, 0)
	ghost.Parent = folder
	return free
end

-- Little bounce after a successful placement.
function BuildGhost.Pop()
	ghost.Size = GHOST_SIZE * 1.4
	Kit.Tween(ghost, 0.2, { Size = GHOST_SIZE })
end

return BuildGhost
