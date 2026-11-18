--!strict
-- PlotService: plot claim + park building + habitat/park rating and income per minute.
-- One service over three helpers (none of them are services):
--   PlotCore   - assigns 1 of 8 plots, spawns, plot <-> world transforms, OnAssigned/OnFreed
--   Placement  - PlaceItem / RotateItem / MoveItem / RemoveItem, occupancy grid (PlotGrid)
--   ParkRating - habitat ratings, park rating + tier, income, GetHabitat
-- Every helper function is re-exported here, so other services only require PlotService.
local PlotCore = require(script.Parent:WaitForChild("PlotCore"))
local Placement = require(script.Parent:WaitForChild("Placement"))
local ParkRating = require(script.Parent:WaitForChild("ParkRating"))

local PlotService: any = {}

for _, helper in { PlotCore, Placement, ParkRating } :: { any } do
	for k, v in helper do
		if type(v) == "function" and k ~= "Bind" and k ~= "Loop" then
			assert(PlotService[k] == nil, "PlotService export clash: " .. k)
			PlotService[k] = v
		end
	end
end

function PlotService.Init()
	PlotCore.Bind()
	Placement.Bind()
	ParkRating.Bind()
end

function PlotService.Start()
	ParkRating.Loop()
end

return PlotService
