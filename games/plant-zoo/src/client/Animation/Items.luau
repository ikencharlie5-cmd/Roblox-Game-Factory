--!strict
-- Watches workspace.ZooItems (gameplay item Models; Graphics adds a child Model "Visual") and the
-- World Reserve, registers creatures with Creatures, and turns item changes into moments:
--   new item -> Seed: Pop + dust | grown creature: Thud + dust | decor: drop-in thud + dust
--   Stage change -> Bounce + leaves (to Grown: Celebrate + rarity sparkles)
--   Color / Weather mutation -> Celebrate + sparkles     Thriving on -> HappyHops + leaves
--   item attribute "Moment" = "<name>" -> plays that moment (server/other branches hook)
--   moved (same stage) -> Thud
-- Removed grown items are remembered for a few seconds so Rewards can float them away on Release.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme")) :: any
local Creatures = require(script.Parent.Creatures)
local Moments = require(script.Parent.Moments)
local Tuning = require(script.Parent.Tuning)

local Items = {}

type Rec = { stage: string?, species: string?, color: string?, pos: Vector3?, plot: number }
export type Removed = { species: string, color: string?, pos: Vector3, plot: number, t: number }

local recs: { [Model]: Rec } = {}
local removed: { Removed } = {}
local armed = false
local thuds: { { model: Model, pivot: CFrame, t0: number } } = {}

local function rarityColor(model: Instance): Color3
	local c = Theme.Rarity and Theme.Rarity[model:GetAttribute("Rarity")]
	return if typeof(c) == "Color3" then c else Theme.Colors.Gold
end

local function visualOf(item: Model): Model?
	local v = item:FindFirstChild("Visual")
	return if v and v:IsA("Model") then v else nil
end

local function play(item: Model, name: string)
	local v = visualOf(item)
	local c = v and Creatures.Get(v)
	if c then
		Creatures.Play(c, name)
	end
end

local function feet(v: Model): Vector3
	return v:GetPivot().Position + Vector3.new(0, 0.4, 0)
end

local function onVisual(item: Model, v: Model)
	local rec = recs[item]
	if not rec then
		return
	end
	local isDecor = item:GetAttribute("Kind") == "decor"
	local stage = if isDecor then "Decor" else v:GetAttribute("Stage") :: string?
	local prev = rec.stage
	rec.stage = stage
	rec.species = item:GetAttribute("Species") :: string?
	rec.color = item:GetAttribute("Color") :: string?
	rec.pos = v:GetPivot().Position
	local c = if isDecor then nil else Creatures.Add(v, false)
	if c then
		Creatures.SetThriving(c, item:GetAttribute("Thriving") == true)
	end
	if not armed then
		return
	end
	local pos = feet(v)
	if isDecor then
		table.insert(thuds, { model = v, pivot = v:GetPivot(), t0 = os.clock() })
		Moments.Burst("Dust", pos, 14)
	elseif not c then
		return
	elseif prev == nil then
		Creatures.Play(c, if stage == "Seed" then "Pop" else "Thud")
		Moments.Burst("Dust", pos, if stage == "Seed" then 8 else 14)
	elseif prev ~= stage then
		if stage == "Grown" then
			Creatures.Play(c, "Celebrate")
			Moments.Burst("Sparkle", pos + Vector3.new(0, 2, 0), 30, rarityColor(v))
		else
			Creatures.Play(c, "Bounce")
			Moments.Burst("Leaves", pos + Vector3.new(0, 1, 0), 10)
		end
	else
		Creatures.Play(c, "Thud")
		Moments.Burst("Dust", pos, 10)
	end
end

local function bindItem(item: Instance, plot: number)
	if not item:IsA("Model") or recs[item] then
		return
	end
	local m = item :: Model
	recs[m] = { plot = plot }
	m.ChildAdded:Connect(function(ch)
		if ch.Name == "Visual" and ch:IsA("Model") then
			task.defer(onVisual, m, ch)
		end
	end)
	local v = visualOf(m)
	if v then
		task.defer(onVisual, m, v)
	end
	m.AttributeChanged:Connect(function(name)
		local val = m:GetAttribute(name)
		local rec = recs[m]
		if name == "Thriving" then
			local vis = visualOf(m)
			local c = vis and Creatures.Get(vis)
			if c then
				Creatures.SetThriving(c, val == true)
				if val == true and armed then
					Creatures.Play(c, "HappyHops")
					Moments.Burst("Leaves", feet(vis :: Model) + Vector3.new(0, 1.5, 0), 14)
				end
			end
		elseif (name == "Color" or name == "Weather") and armed and val ~= nil and val ~= "None" then
			if rec and name == "Color" then
				rec.color = val :: string
			end
			local vis = visualOf(m)
			if vis and vis:GetAttribute("Stage") == "Grown" then
				play(m, "Celebrate")
				Moments.Burst("Sparkle", feet(vis) + Vector3.new(0, 2, 0), 40, rarityColor(vis))
			end
		elseif name == "Moment" and type(val) == "string" then
			play(m, val)
		end
	end)
end

local function bindFolder(folder: Instance)
	local plot = tonumber(string.match(folder.Name, "%d+")) or 0
	for _, c in folder:GetChildren() do
		bindItem(c, plot)
	end
	folder.ChildAdded:Connect(function(c)
		bindItem(c, plot)
	end)
	folder.ChildRemoved:Connect(function(c)
		local rec = recs[c :: Model]
		recs[c :: Model] = nil
		if rec and rec.stage == "Grown" and rec.species and rec.pos then
			table.insert(
				removed,
				{ species = rec.species, color = rec.color, pos = rec.pos, plot = rec.plot, t = os.clock() }
			)
			if #removed > 30 then
				table.remove(removed, 1)
			end
		end
	end)
end

-- Most recent removed grown creature matching species/color within `window` seconds (consumed).
function Items.TakeRemoved(species: string, color: string?, window: number): Removed?
	local now = os.clock()
	for i = #removed, 1, -1 do
		local r = removed[i]
		if now - r.t <= window and r.species == species and (color == nil or (r.color or "None") == color) then
			table.remove(removed, i)
			return r
		end
	end
	return nil
end

function Items.Step(now: number)
	for i = #thuds, 1, -1 do
		local th = thuds[i]
		local p = (now - th.t0) / Tuning.ThudTime
		if p >= 1 or not th.model.Parent then
			if th.model.Parent then
				th.model:PivotTo(th.pivot)
			end
			table.remove(thuds, i)
		else
			local fall = math.min(p / 0.45, 1)
			local dy = Tuning.ThudDrop * (1 - fall * fall)
			if p > 0.45 then
				dy = 0.25 * math.sin(math.pi * (p - 0.45) / 0.55) * (1 - p)
			end
			th.model:PivotTo(th.pivot * CFrame.new(0, dy, 0))
		end
	end
end

function Items.Start()
	task.spawn(function()
		local root = workspace:WaitForChild("ZooItems")
		for _, f in root:GetChildren() do
			bindFolder(f)
		end
		root.ChildAdded:Connect(bindFolder)
		-- Existing items on join don't get moments; arm once the initial load has settled.
		task.wait(3)
		armed = true
	end)
	task.spawn(function()
		if not workspace:GetAttribute("WorldReady") then
			workspace:GetAttributeChangedSignal("WorldReady"):Wait()
		end
		local folder = workspace:FindFirstChild("ReserveCreatures", true)
		if not folder then
			return
		end
		local function add(m: Instance)
			if m:IsA("Model") then
				task.defer(Creatures.Add, m, true)
			end
		end
		for _, m in folder:GetChildren() do
			add(m)
		end
		folder.ChildAdded:Connect(add)
	end)
end

return Items
