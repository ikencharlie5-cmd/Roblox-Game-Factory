--!strict
-- Boots the game: World builder first, then DataService + the 8 gameplay Services (all Init(), then
-- all Start()). Helper modules in Services/ (PlotCore, Placement, ParkRating, Capture, WildRoll, Shop,
-- Quests, CreatureAI, CreatureCare, Models, Journal, PlotGrid, DataSchema, DataSettings, Guard,
-- Signals) are driven by their Service and never booted here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local World = require(script.Parent:WaitForChild("World")) :: any
local servicesFolder = script.Parent:WaitForChild("Services")

-- Load order matters: DataService first, then the 8 gameplay Services.
local ORDER = {
	"DataService",
	"MonetizationService",
	"PlotService",
	"CreatureService",
	"GeneticsService",
	"WildService",
	"EconomyService",
	"RewardService",
	"VisitService",
}

local services = {}
for _, name in ORDER do
	table.insert(services, require(servicesFolder:WaitForChild(name)) :: any)
end

World.Init() -- builds the map (yields while the ground fills)
for _, s in services do
	if s.Init then
		s.Init()
	end
end
task.spawn(World.Start)
for _, s in services do
	if s.Start then
		task.spawn(s.Start)
	end
end
