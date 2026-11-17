--!strict
-- Renders visuals for gameplay's item models in workspace.ZooItems.Plot<n>.<itemId>.
-- Each item Model has an invisible "Hitbox" (PrimaryPart, bottom on the pad surface) + attributes
-- (Kind "plant"|"decor", Species, Stage, Color, Weather, Thriving, DecorKind, PlotIndex, PadIndex).
-- We add a child Model "Visual" and rebuild it when those attributes change.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreatureModels = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CreatureModels"))
local Decor = require(script.Parent.Decor)
local Motion = require(script.Parent.Motion)

local ItemVisuals = {}

type PadTopFn = (plotIndex: number, padIndex: number) -> CFrame?

local rainbow: { [Model]: boolean } = {}
local padTop: PadTopFn = function(_: number, _: number): CFrame?
	return nil
end
local onCounts: (plotIndex: number) -> () = function(_: number) end

local REBUILD = { Stage = true, Species = true, DecorKind = true, Kind = true }
local RELOOK = { Color = true, Weather = true, Thriving = true }

local function noQuery(m: Model)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery = false
			d.CanTouch = false
			d.CanCollide = false
		end
	end
end

local function render(item: Model, pop: boolean)
	local hb = item.PrimaryPart or item:FindFirstChild("Hitbox") :: BasePart?
	if not hb or not item.Parent then
		return
	end
	local old = item:FindFirstChild("Visual")
	if old then
		rainbow[old :: Model] = nil
		old:Destroy()
	end
	local base = hb.CFrame * CFrame.new(0, -hb.Size.Y / 2, 0)
	local visual: Model?
	local isPlant = item:GetAttribute("Kind") ~= "decor"
	if isPlant then
		local species = item:GetAttribute("Species")
		if typeof(species) ~= "string" then
			return
		end
		visual = CreatureModels.Build(species, item:GetAttribute("Stage") :: string?, {
			Color = item:GetAttribute("Color") :: string?,
			Weather = item:GetAttribute("Weather") :: string?,
			Thriving = item:GetAttribute("Thriving") == true,
		})
	else
		local kind = item:GetAttribute("DecorKind")
		if typeof(kind) == "string" then
			visual = Decor.Build(kind)
		end
	end
	if not visual then
		return
	end
	local v = visual :: Model
	v.Name = "Visual"
	v:PivotTo(base)
	noQuery(v)
	v.Parent = item
	if isPlant then
		rainbow[v] = if v:GetAttribute("Rainbow") then true else nil
		if pop then
			Motion.Pop(v)
		end
		if v:GetAttribute("Stage") == "Grown" then
			local plot = item:GetAttribute("PlotIndex") :: number? or 0
			local pad = item:GetAttribute("PadIndex") :: number? or 0
			local top = padTop(plot, pad) or base
			task.delay(if pop then 0.3 else 0, function()
				if v.Parent then
					Motion.Creature(v, top, base)
				end
			end)
		end
	end
end

local function relook(item: Model)
	local v = item:FindFirstChild("Visual") :: Model?
	if not v or v:GetAttribute("Species") == nil then
		return
	end
	CreatureModels.ApplyLook(v, {
		Color = item:GetAttribute("Color") or false,
		Weather = item:GetAttribute("Weather") or false,
		Thriving = item:GetAttribute("Thriving") == true,
	})
	noQuery(v)
	rainbow[v] = if v:GetAttribute("Rainbow") then true else nil
end

local function bindItem(item: Instance, plotIndex: number)
	if not item:IsA("Model") then
		return
	end
	local m = item :: Model
	local hb = m.PrimaryPart or m:WaitForChild("Hitbox", 5) :: BasePart?
	if not hb then
		return
	end
	local pending = false
	local function schedule(pop: boolean)
		if pending then
			return
		end
		pending = true
		task.defer(function()
			pending = false
			render(m, pop)
			onCounts(plotIndex)
		end)
	end
	m.AttributeChanged:Connect(function(name)
		if REBUILD[name] then
			schedule(true)
		elseif RELOOK[name] then
			relook(m)
			onCounts(plotIndex)
		end
	end)
	hb:GetPropertyChangedSignal("CFrame"):Connect(function()
		schedule(false)
	end)
	schedule(false)
end

local function bindFolder(folder: Instance)
	local idx = folder:GetAttribute("PlotIndex") or tonumber(string.match(folder.Name, "%d+")) or 0
	local plotIndex = idx :: number
	for _, c in folder:GetChildren() do
		task.spawn(bindItem, c, plotIndex)
	end
	folder.ChildAdded:Connect(function(c)
		bindItem(c, plotIndex)
	end)
	folder.ChildRemoved:Connect(function()
		onCounts(plotIndex)
	end)
end

-- (grown, thriving) creature counts for a plot.
function ItemVisuals.Counts(plotIndex: number): (number, number)
	local root = Workspace:FindFirstChild("ZooItems")
	local folder = root and root:FindFirstChild("Plot" .. plotIndex)
	local grown, thriving = 0, 0
	if folder then
		for _, m in folder:GetChildren() do
			if m:GetAttribute("Kind") ~= "decor" and m:GetAttribute("Stage") == "Grown" then
				grown += 1
				if m:GetAttribute("Thriving") == true then
					thriving += 1
				end
			end
		end
	end
	return grown, thriving
end

function ItemVisuals.Start(padTopFn: PadTopFn, countsChanged: (number) -> ())
	padTop = padTopFn
	onCounts = countsChanged
	task.spawn(function()
		local root = Workspace:WaitForChild("ZooItems")
		for _, f in root:GetChildren() do
			bindFolder(f)
		end
		root.ChildAdded:Connect(bindFolder)
	end)
	task.spawn(function()
		local hue = 0
		while true do
			task.wait(0.25)
			hue = (hue + 0.03) % 1
			for m in rainbow do
				if m.Parent then
					CreatureModels.StepRainbow(m, hue)
				else
					rainbow[m] = nil
				end
			end
		end
	end)
end

return ItemVisuals
