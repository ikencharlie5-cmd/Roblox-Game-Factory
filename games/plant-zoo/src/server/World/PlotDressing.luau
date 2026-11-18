--!strict
-- Plot readability (ART_STYLE_GUIDE §7): raised wood border, flower strips, corner bushes/trees,
-- an arch gate over the entrance with the big owner sign, and a floor that's lighter once owned.
-- Plot local space: origin = floor top center, -Z = entrance (toward the hub). Floor is 80x80.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)

local V = Vector3.new
local C = CFrame.new
local hex = Color3.fromHex

local PlotDressing = {}

local HALF = 40
local GAP = 9 -- entrance gap half-width (18 studs, same as before)
local CURB_H = 1.5 -- from 0.5 below the floor top to 1 stud above it

-- White FredokaOne text with a dark stroke (readable from far away).
local function bigText(part: BasePart, face: Enum.NormalId, text: string): TextLabel
	local label = Build.Label(part, face, text, hex("#FFFFFF"))
	local stroke = Instance.new("UIStroke")
	stroke.Color = hex("#3B2A1A")
	stroke.Thickness = 3
	stroke.Parent = label
	return label
end
PlotDressing.BigText = bigText

-- Wood curb segment from local (x1,z1) to (x2,z2) (axis-aligned).
local function curb(f: Instance, cf: CFrame, x1: number, z1: number, x2: number, z2: number)
	local alongX = z1 == z2
	local len = if alongX then math.abs(x2 - x1) else math.abs(z2 - z1)
	local mid = cf * C((x1 + x2) / 2, CURB_H / 2 - 0.5, (z1 + z2) / 2)
	local size = if alongX then V(len, CURB_H, 1.4) else V(1.4, CURB_H, len)
	Build.Part(
		f,
		{ Size = size, CFrame = mid, Color = Theme.Colors.Wood, Material = Enum.Material.WoodPlanks, Name = "Curb" }
	)
	local cap = if alongX then V(len + 0.2, 0.25, 1.7) else V(1.7, 0.25, len + 0.2)
	Build.Deco(f, { Size = cap, CFrame = mid * C(0, CURB_H / 2, 0), Color = Theme.Colors.WoodDark, Name = "CurbCap" })
end

function PlotDressing.Border(f: Instance, cf: CFrame, rng: Random)
	local e = HALF + 0.7
	curb(f, cf, -e - 0.7, e, e + 0.7, e)
	curb(f, cf, -e, -e, -e, e)
	curb(f, cf, e, -e, e, e)
	curb(f, cf, -e - 0.7, -e, -GAP, -e)
	curb(f, cf, GAP, -e, e + 0.7, -e)
	-- Optional fence asset on top of the curb.
	local top = CURB_H - 0.5
	local function fence(x1: number, z1: number, x2: number, z2: number)
		Props.FenceRun(f, (cf * C(x1, top, z1)).Position, (cf * C(x2, top, z2)).Position, 2.5, rng)
	end
	fence(-e, e, e, e)
	fence(-e, -e, -e, e)
	fence(e, -e, e, e)
	fence(-e, -e, -GAP - 1, -e)
	fence(GAP + 1, -e, e, -e)
	-- Flower strips outside the front curb, a bush hedge row outside the other three sides.
	local o = e + 2.2
	Props.FlowerStrip(f, (cf * C(-o + 3, -0.5, -o)).Position, (cf * C(-GAP - 4, -0.5, -o)).Position, 3, rng)
	Props.FlowerStrip(f, (cf * C(GAP + 4, -0.5, -o)).Position, (cf * C(o - 3, -0.5, -o)).Position, 3, rng)
	for k = -3, 3 do
		local t = k * 11.5
		Props.Bush(f, (cf * C(t, -0.5, o + 1)).Position, rng:NextNumber(0.9, 1.2), rng)
		Props.Bush(f, (cf * C(-o - 1, -0.5, t)).Position, rng:NextNumber(0.9, 1.2), rng)
		Props.Bush(f, (cf * C(o + 1, -0.5, t)).Position, rng:NextNumber(0.9, 1.2), rng)
	end
	-- Front corners: big bushes. Back corners: trees.
	for _, x in { -1, 1 } do
		Props.Bush(f, (cf * C(x * (o + 1), -0.5, -o - 1)).Position, 1.5, rng)
		Props.Tree(f, (cf * C(x * (o + 3), -0.5, o + 3)).Position, 1.3, rng, x > 0)
	end
end

-- Arch gate over the entrance with the PlotSign board. Returns nothing; wires the sign text itself.
function PlotDressing.Gate(model: Model, plotIndex: number, cf: CFrame)
	local f = Build.Model(model, "Sign")
	local g = cf * C(0, 0, -(HALF + 1))
	local wood, dark = Theme.Colors.Wood, Theme.Colors.WoodDark
	for _, x in { -1, 1 } do
		Build.Part(f, { Size = V(1.8, 13, 1.8), CFrame = g * C(x * 9.5, 6, 0), Color = wood, Name = "Post" })
		Build.Deco(f, { Size = V(2.4, 0.8, 2.4), CFrame = g * C(x * 9.5, 0, 0), Color = dark, Name = "PostBase" })
		Build.Ball(f, 2.6, g * C(x * 9.5, 13, 0), Theme.LeafColors[2])
		Props.Lamp(f, (g * C(x * 11, -0.5, -2)).Position, Random.new(plotIndex))
	end
	-- Curved top: 7 short beams on an arc.
	for k = -3, 3 do
		local a = math.rad(k * 18)
		local pos = g * C(math.sin(a) * 11, 10.5 + math.cos(a) * 3.2, 0)
		local tilt = math.atan(-(3.2 * math.sin(a)) / (11 * math.cos(a)))
		Build.Deco(
			f,
			{ Size = V(3.8, 1.2, 1.4), CFrame = pos * CFrame.Angles(0, 0, tilt), Color = dark, Name = "Arch" }
		)
		Build.Ball(f, 1.1, pos * C(0, 0.8, -0.5), Theme.FlowerColors[(k + 3) % 5 + 1]).CastShadow = false
	end
	local board = Build.Part(f, {
		Size = V(17, 4.2, 0.6),
		CFrame = g * C(0, 9.4, -0.6),
		Color = Theme.Colors.Wood,
		Material = Enum.Material.WoodPlanks,
		Name = "Board",
	})
	board.CanCollide = false
	for _, t in { { 0, 2.35, 17.8, 0.5 }, { 0, -2.35, 17.8, 0.5 }, { -8.75, 0, 0.5, 4.2 }, { 8.75, 0, 0.5, 4.2 } } do
		Build.Deco(
			f,
			{ Size = V(t[3], t[4], 0.8), CFrame = board.CFrame * C(t[1], t[2], 0), Color = dark, Name = "Trim" }
		)
	end
	Build.Tag(board, "PlotSign", { PlotIndex = plotIndex })
	local front = bigText(board, Enum.NormalId.Front, "Free Plot")
	local back = bigText(board, Enum.NormalId.Back, "Free Plot")
	local function refresh()
		local name = model:GetAttribute("OwnerName")
		local likes = model:GetAttribute("Likes") or 0
		local text = if typeof(name) == "string" and name ~= ""
			then string.format("%s's Zoo  ❤ %d", name, likes)
			else "Free Plot"
		front.Text = text
		back.Text = text
	end
	model:GetAttributeChangedSignal("OwnerName"):Connect(refresh)
	model:GetAttributeChangedSignal("Likes"):Connect(refresh)
end

-- Floor: grey-green while unclaimed, bright plot green once owned.
function PlotDressing.BindFloor(model: Model, floor: BasePart)
	local function refresh()
		local owned = (model:GetAttribute("OwnerUserId") or 0) ~= 0
		floor.Color = if owned then Theme.Colors.PlotFloor else Theme.Colors.PlotFloorFree
	end
	model:GetAttributeChangedSignal("OwnerUserId"):Connect(refresh)
	refresh()
end

return PlotDressing
