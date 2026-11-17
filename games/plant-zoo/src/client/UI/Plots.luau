--!strict
-- Finds my plot's ExhibitPads and item models, and converts world points <-> grid cells.
-- Contract (notes/gameplay.md): ExhibitPad tag + PlotIndex/PadIndex attrs; player attr PlotIndex;
-- items live in workspace.ZooItems.Plot<n> as Models with ItemId/Kind attrs.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme")) :: any

local Plots = {}

local player = Players.LocalPlayer :: Player
local HALF = 10.5 -- pad half size (+ a little slack)

function Plots.MyPlot(): number?
	local v = player:GetAttribute("PlotIndex")
	return if type(v) == "number" then v else nil
end

local function padPart(inst: Instance): BasePart?
	if inst:IsA("BasePart") then
		return inst
	end
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

-- { [padIndex] = BasePart } for a plot (default: mine)
function Plots.Pads(plot: number?): { [number]: BasePart }
	local want = plot or Plots.MyPlot()
	local out: { [number]: BasePart } = {}
	if not want then
		return out
	end
	for _, inst in CollectionService:GetTagged("ExhibitPad") do
		if inst:GetAttribute("PlotIndex") == want then
			local idx = inst:GetAttribute("PadIndex")
			local part = padPart(inst)
			if type(idx) == "number" and part then
				out[idx] = part
			end
		end
	end
	return out
end

function Plots.PadTop(part: BasePart): CFrame
	return part.CFrame * CFrame.new(0, part.Size.Y / 2, 0)
end

-- World CFrame of a cell centre on a pad (rot in 90 degree steps).
function Plots.CellCFrame(part: BasePart, cell: number, rot: number?): CFrame
	return Plots.PadTop(part) * SharedTheme.CellOffset(cell, rot or 0)
end

-- Which of my pads + cell is under a world point? Returns (pad, cell, part) or nil.
function Plots.CellAt(point: Vector3): (number?, number?, BasePart?)
	local n = SharedTheme.Grid.Cells
	local size = SharedTheme.Grid.CellSize
	for idx, part in Plots.Pads() do
		local l = Plots.PadTop(part):PointToObjectSpace(point)
		if math.abs(l.X) <= HALF and math.abs(l.Z) <= HALF and math.abs(l.Y) < 12 then
			local col = math.clamp(math.floor(l.X / size + n / 2) + 1, 1, n)
			local row = math.clamp(math.floor(l.Z / size + n / 2) + 1, 1, n)
			return idx, (row - 1) * n + col, part
		end
	end
	return nil, nil, nil
end

-- Item model hit by a raycast (walks up to the Model that has an ItemId attribute).
function Plots.ItemFromHit(hit: Instance?): (Model?, number?)
	local cur = hit
	while cur and cur ~= workspace do
		if cur:IsA("Model") and cur:GetAttribute("ItemId") ~= nil then
			local id = cur:GetAttribute("ItemId")
			return cur, if type(id) == "number" then id else tonumber(id)
		end
		cur = cur.Parent
	end
	return nil, nil
end

function Plots.IsMine(model: Model): boolean
	local owner = model:GetAttribute("OwnerUserId")
	if owner ~= nil then
		return owner == player.UserId
	end
	return model:GetAttribute("PlotIndex") == Plots.MyPlot()
end

-- First tagged instance's position (for tutorial arrows): e.g. "ShopStand", "TipJar".
function Plots.TaggedPart(tag: string, plot: number?, pad: number?): BasePart?
	for _, inst in CollectionService:GetTagged(tag) do
		local okPlot = plot == nil or inst:GetAttribute("PlotIndex") == plot
		local okPad = pad == nil or inst:GetAttribute("PadIndex") == pad
		if okPlot and okPad then
			local p = padPart(inst)
			if p then
				return p
			end
		end
	end
	return nil
end

function Plots.Raycast(screenPos: Vector2, viewport: boolean, exclude: { Instance }): RaycastResult?
	local cam = workspace.CurrentCamera
	local ray = if viewport
		then cam:ViewportPointToRay(screenPos.X, screenPos.Y)
		else cam:ScreenPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = table.clone(exclude)
	if player.Character then
		table.insert(list, player.Character)
	end
	params.FilterDescendantsInstances = list
	return workspace:Raycast(ray.Origin, ray.Direction * 600, params)
end

return Plots
