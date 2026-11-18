--!strict
-- Boots every Service: all Init() first, then all Start().
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local servicesFolder = script.Parent:WaitForChild("Services")

-- Load order matters: DataService first.
local ORDER = { "DataService", "MonetizationService", "DailyRewardService" }

local services = {}
local loaded: { [string]: boolean } = {}
for _, name in ORDER do
	table.insert(services, require(servicesFolder:WaitForChild(name)) :: any)
	loaded[name] = true
end
for _, child in servicesFolder:GetChildren() do
	if child:IsA("ModuleScript") and not loaded[child.Name] then
		table.insert(services, require(child) :: any)
	end
end

for _, s in services do
	if s.Init then
		s.Init()
	end
end
for _, s in services do
	if s.Start then
		task.spawn(s.Start)
	end
end
