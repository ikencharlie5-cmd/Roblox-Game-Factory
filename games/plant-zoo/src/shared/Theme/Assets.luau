--!strict
-- Asset hooks (shared). Real 3D assets live in the Studio place under ReplicatedStorage.Assets:
--   Assets/Creatures/<SpeciesName>   Model or MeshPart (Grown stage of that species)
--   Assets/Props/<Kind><N>           Model or MeshPart, e.g. Tree1, Tree2, Bush1, Flower1, Rock1, Lamp, Bench1, Cloud1, Fence
-- Every hook falls back to primitives when the asset is missing, so the game still works from `rojo build`.
-- Optional attributes on an asset: YawOffset (degrees, rotate so the asset's front faces -Z of its pivot),
-- HeightScale (multiplies the target height). Scripts inside assets are always deleted on clone.
-- Full contract: games/plant-zoo/notes/graphics.md "Asset hooks".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = {}

local function norm(s: string): string
	return (string.lower(s):gsub("[%s_%-]", ""))
end

function Assets.Folder(category: string): Instance?
	local root = ReplicatedStorage:FindFirstChild("Assets")
	return if root then root:FindFirstChild(category) else nil
end

local function usable(i: Instance): boolean
	return i:IsA("Model") or i:IsA("BasePart")
end

-- Exact (normalized) name match, e.g. Find("Creatures", "Dandelion Lion").
function Assets.Find(category: string, name: string): Instance?
	local folder = Assets.Folder(category)
	if not folder then
		return nil
	end
	local exact = folder:FindFirstChild(name)
	if exact and usable(exact) then
		return exact
	end
	local n = norm(name)
	for _, c in folder:GetChildren() do
		if usable(c) and norm(c.Name) == n then
			return c
		end
	end
	return nil
end

-- All variants of a kind: name == kind, or kind followed by digits / "_" / " " (Tree, Tree1, Tree_Pine).
function Assets.Variants(category: string, kind: string): { Instance }
	local out = {}
	local folder = Assets.Folder(category)
	if not folder then
		return out
	end
	local k = string.lower(kind)
	for _, c in folder:GetChildren() do
		if usable(c) then
			local name = string.lower(c.Name)
			if name == k then
				table.insert(out, c)
			elseif string.sub(name, 1, #k) == k then
				local rest = string.sub(name, #k + 1, #k + 1)
				if string.match(rest, "[%d_ ]") then
					table.insert(out, c)
				end
			end
		end
	end
	return out
end

function Assets.Pick(category: string, kind: string, rng: Random?): Instance?
	local list = Assets.Variants(category, kind)
	if #list == 0 then
		return nil
	end
	local i = if rng then rng:NextInteger(1, #list) else math.random(1, #list)
	return list[i]
end

local function strip(i: Instance)
	for _, d in i:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
end

-- Bounding box (min, max) of all BaseParts in `frame` space.
local function bounds(parts: { BasePart }, frame: CFrame): (Vector3, Vector3)
	local lo = Vector3.one * math.huge
	local hi = -lo
	for _, p in parts do
		local h = p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
					local l = frame:PointToObjectSpace(w)
					lo = lo:Min(l)
					hi = hi:Max(l)
				end
			end
		end
	end
	return lo, hi
end

export type FitOpts = {
	Height: number, -- target height in studs
	MaxWidth: number?, -- clamp the larger of X/Z footprint
	Feet: CFrame, -- where the bottom-center goes (front = -Z of this CFrame)
	Anchored: boolean?, -- default true
}

-- Clones `source`, deletes scripts, wraps a lone part in a Model, scales it to opts.Height (and
-- MaxWidth), and puts the bottom-center of its bounding box at opts.Feet. Returns the Model + parts.
function Assets.Fit(source: Instance, opts: FitOpts): (Model, { BasePart })
	local clone = source:Clone()
	strip(clone)
	local model: Model
	local pivot: CFrame
	if clone:IsA("Model") then
		model = clone
		pivot = clone:GetPivot()
	else
		model = Instance.new("Model")
		model.Name = source.Name
		local part = clone :: BasePart
		pivot = part:GetPivot()
		part.Parent = model
	end
	-- With a PrimaryPart the pivot follows that part; clear it so WorldPivot (our yaw frame) is used.
	model.PrimaryPart = nil
	local yaw = source:GetAttribute("YawOffset")
	local frame = CFrame.new(pivot.Position) * pivot.Rotation
	if typeof(yaw) == "number" then
		frame *= CFrame.Angles(0, math.rad(yaw), 0)
	end
	model.WorldPivot = frame
	local parts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = if opts.Anchored == false then false else true
			table.insert(parts, d)
		end
	end
	if #parts == 0 then
		return model, parts
	end
	local lo, hi = bounds(parts, frame)
	local size = hi - lo
	local hs = source:GetAttribute("HeightScale")
	local height = opts.Height * (if typeof(hs) == "number" then hs else 1)
	local k = height / math.max(size.Y, 0.05)
	if opts.MaxWidth then
		k = math.min(k, opts.MaxWidth / math.max(size.X, size.Z, 0.05))
	end
	model:ScaleTo(model:GetScale() * k)
	-- ScaleTo scales about the pivot, so the bottom-center scales by k too.
	local bottom = Vector3.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2) * k
	model:PivotTo(opts.Feet * CFrame.new(-bottom))
	model.WorldPivot = opts.Feet
	return model, parts
end

return Assets
