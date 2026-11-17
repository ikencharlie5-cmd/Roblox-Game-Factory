--!strict
-- World Reserve diorama: released creatures (with owner name tags) + release beam FX.
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local CreatureModels = require(Shared:WaitForChild("CreatureModels"))
local Build = require(script.Parent.Build)
local Motion = require(script.Parent.Motion)

local Reserve = {}

local RESERVE_CAP = 8
local reserveFolder: Folder
local zones: { [string]: BasePart } = {}

function Reserve.Init(folder: Folder, zoneParts: { [string]: BasePart })
	reserveFolder = folder
	zones = zoneParts
end

function Reserve.Add(species: string, color: string?, ownerName: string)
	local look = CreatureModels.GetLook(species)
	local zone = zones[look.Biome] or zones.Meadow
	local existing = {}
	for _, m in reserveFolder:GetChildren() do
		if m:GetAttribute("Biome") == look.Biome then
			table.insert(existing, m)
		end
	end
	if #existing >= RESERVE_CAP then
		existing[1]:Destroy()
	end
	local m = CreatureModels.Build(species, "Grown", { Color = color, Scale = 0.55 })
	m:SetAttribute("Biome", look.Biome)
	m:SetAttribute("Owner", ownerName)
	local top = zone.CFrame * CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(0, zone.Size.X / 2, 0)
	local a, r = math.random() * math.pi * 2, math.random() * 2.5
	local home = top * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, math.random() * 6.28, 0)
	m:PivotTo(home)
	m.Parent = reserveFolder
	local root = m.PrimaryPart :: BasePart
	local tag = Build.Billboard(root, ownerName, Color3.new(1, 1, 1), 3.5, 5)
	local bb = tag.Parent :: BillboardGui
	bb.MaxDistance = 60
	Motion.Creature(m, top, home, 4.2)
	zone:SetAttribute("Count", math.min(#existing + 1, RESERVE_CAP))
end

-- Tall green beam + puff where a creature is released (e.g. its old position).
function Reserve.Beam(position: Vector3)
	local beam = Build.Cyl(
		Workspace,
		60,
		3,
		CFrame.new(position + Vector3.new(0, 30, 0)),
		Theme.Colors.Thriving,
		Enum.Material.Neon,
		false
	)
	beam.Transparency = 0.2
	beam.CanQuery = false
	local puff = Theme.Effects.Puff(Color3.new(1, 1, 1))
	puff.Parent = beam
	puff:Emit(30)
	local info = TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(beam, info, { Transparency = 1, Size = Vector3.new(60, 0.2, 0.2) }):Play()
	task.delay(2, function()
		beam:Destroy()
	end)
end

-- Mirror gameplay's GameState.WorldReserve list ({species, color, owner}); newest entries win.
-- Plays a beam over a zone for each entry that wasn't there last time.
local seen: { [string]: number } = {}
local synced = false
function Reserve.Sync(list: { any })
	reserveFolder:ClearAllChildren()
	local counts: { [string]: number } = {}
	local fresh: { [string]: number } = {}
	for _, e in list do
		local key = string.format("%s|%s|%s", tostring(e.species), tostring(e.color), tostring(e.owner))
		fresh[key] = (fresh[key] or 0) + 1
	end
	local beams: { [string]: boolean } = {}
	for key, n in fresh do
		if synced and n > (seen[key] or 0) then
			local species = string.split(key, "|")[1]
			beams[CreatureModels.GetLook(species).Biome] = true
		end
	end
	seen = fresh
	synced = true
	for i = #list, 1, -1 do
		local e = list[i]
		if typeof(e) == "table" and typeof(e.species) == "string" then
			local biome = CreatureModels.GetLook(e.species).Biome
			counts[biome] = (counts[biome] or 0) + 1
			if counts[biome] <= RESERVE_CAP then
				local color = if typeof(e.color) == "string" and e.color ~= "None" then e.color else nil
				Reserve.Add(e.species, color, tostring(e.owner or "?"))
			end
		end
	end
	for biome in beams do
		local zone = zones[biome]
		if zone then
			Reserve.Beam(zone.Position)
		end
	end
end

return Reserve
