--!strict
-- Build-mode grid overlay: thin teal Neon lines every cell across the buildable area.
-- Built once and only moved when the plot centre/size changes. Client-only (under the camera).
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local PlotInfo = require(script.Parent:WaitForChild("PlotInfo"))

local BuildGrid = {}

local gridLines: { Part } = {}
local gridShown = false
local gridKey = ""

-- Thin teal lines every cell across the buildable area (built once, moved when needed).
function BuildGrid.Draw(folder: Instance, center: Vector3?)
	if not center then
		if gridShown then
			for _, l in gridLines do
				l.Parent = nil
			end
			gridShown = false
			gridKey = ""
		end
		return
	end
	local _, size = PlotInfo.Bounds()
	local pcf = PlotInfo.CFrame() or CFrame.new(center :: Vector3)
	local key = tostring(pcf) .. size
	if key == gridKey then
		return
	end
	gridKey = key
	local n = math.floor(size / PlotInfo.Cell)
	for i = 0, n do
		for axis = 1, 2 do
			local idx = i * 2 + axis
			local l = gridLines[idx]
			if not l then
				l = Kit.Make("Part", {
					Anchored = true,
					CanCollide = false,
					CanQuery = false,
					CanTouch = false,
					CastShadow = false,
					Material = Enum.Material.Neon,
					Color = Style.Pal.Teal.Top,
					Transparency = 0.6,
				})
				gridLines[idx] = l
			end
			local off = -size / 2 + i * PlotInfo.Cell
			if axis == 1 then
				l.Size = Vector3.new(0.12, 0.05, size)
				l.CFrame = pcf * CFrame.new(off, 0.06, 0)
			else
				l.Size = Vector3.new(size, 0.05, 0.12)
				l.CFrame = pcf * CFrame.new(0, 0.06, off)
			end
			l.Parent = folder
		end
	end
	for idx = (n + 1) * 2 + 1, #gridLines do
		gridLines[idx].Parent = nil
	end
	gridShown = true
end

return BuildGrid
