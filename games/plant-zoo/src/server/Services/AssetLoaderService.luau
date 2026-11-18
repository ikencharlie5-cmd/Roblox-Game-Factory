--!strict
-- Makes the repo self-contained: if ReplicatedStorage.Assets.Creatures is missing any species,
-- load it from Charlie's published asset ids (InsertService works for assets the place owner owns).
-- Runs FIRST in Main (blocks Init up to Timeout seconds) so the world never builds with fallbacks.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ids = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CreatureAssetIds"))

local AssetLoaderService = {}
local TIMEOUT = 20

local function folder(parent: Instance, name: string): Instance
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function strip(inst: Instance)
	for _, d in inst:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("PackageLink") then
			d:Destroy()
		end
	end
end

function AssetLoaderService.Init()
	local creatures = folder(folder(ReplicatedStorage, "Assets"), "Creatures")
	local pending = 0
	for species, id in Ids :: { [string]: number } do
		if not creatures:FindFirstChild(species) then
			pending += 1
			task.spawn(function()
				local ok, res = pcall(InsertService.LoadAsset, InsertService, id)
				if ok and res then
					local model = (res :: Instance):GetChildren()[1]
					if model then
						strip(model)
						model.Name = species
						model.Parent = creatures
					end
					(res :: Instance):Destroy()
				else
					warn("[AssetLoader] couldn't load", species, id, res)
				end
				pending -= 1
			end)
		end
	end
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < TIMEOUT do
		task.wait(0.1)
	end
	if pending > 0 then
		warn("[AssetLoader]", pending, "creature models still loading; those use primitive fallbacks")
	end
end

return AssetLoaderService
