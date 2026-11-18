--!strict
-- Incubator nest row (guide §6): one tile per incubator slot with an egg, a fill-up timer bar and
-- the time left. READY eggs pulse and hatch on tap (HatchEgg); waiting eggs offer Instant Hatch
-- (Robux). Locked slots point at the Park upgrades. Also drives the HUD Breed badge.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Formulas: any = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Formulas"))

local Nests = {}

local row: Frame? = nil
local lastSig = ""

-- Incubator slots: data.incubators if sent, else 2 + upgrade level (+1 with the pass).
function Nests.Capacity(): number
	local lvl = tonumber(State.Tbl("upgrades").Incubators) or 0
	local ok, v = pcall(Formulas.Incubators, lvl, Derived.HasPass("ExtraIncubator"))
	return if ok and type(v) == "number" then v else 2 + lvl
end

function Nests.FreeSlots(): number
	return Nests.Capacity() - #Derived.Eggs()
end

function Nests.ReadyCount(): number
	local n = 0
	for _, e in Derived.Eggs() do
		if Derived.EggLeft(e) <= 0 then
			n += 1
		end
	end
	return n
end

local function tile(parent: Frame, i: number, egg: { [string]: any }?, locked: boolean)
	local f = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(120, 150), LayoutOrder = i }, parent)
	local pal = if locked then Style.Pal.Stone elseif egg then Style.Pal.Sun else Style.Pal.Card
	local face = Kit.Slab(f, pal, 16, 5)
	if locked then
		Kit.Title(face, "Locked\n+ Park upgrade", pal.Dark, { TextSize = 18, ZIndex = 4 })
		return
	end
	if not egg then
		Kit.Label(face, "Empty nest", { TextSize = 18, ZIndex = 4, TextColor3 = Style.Color.InkSoft })
		return
	end
	local e = egg :: { [string]: any }
	local left = Derived.EggLeft(e)
	local species = tostring(Derived.Field(e, "species") or "Egg")
	local oval = Kit.Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(52, 64),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 4,
	}, face)
	Kit.Corner(oval, 99)
	Kit.Gradient(oval, Style.RarityPalette(Derived.Rarity(species)))
	Kit.Stroke(oval, Style.Color.Frame, 3)
	local total = math.max(1, (tonumber(e.readyAt) or 0) - (tonumber(e.laidAt) or 0))
	local _, set = Kit.Progress(face, "Leaf", { Position = UDim2.new(0, 10, 0, 82), Size = UDim2.new(1, -20, 0, 12), ZIndex = 4 })
	set(1 - left / math.max(1, total))
	local ready = left <= 0
	Kit.Button(f, if ready then "HATCH" else Format.Time(left), if ready then "Leaf" else "Sky", function()
		if ready then
			Net.Do("HatchEgg", nil, e.id)
		else
			Net.Do("RequestInstantHatch", nil, e.id)
		end
	end, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(1, -12, 0, 46),
		TextSize = 20,
		Pulse = ready,
		ZIndex = 6,
	})
end

function Nests.Mount(parent: Instance, pos: UDim2, size: UDim2)
	local holder = Kit.Make("Frame", { BackgroundTransparency = 1, Position = pos, Size = size }, parent)
	Kit.Label(holder, "Nests", { Size = UDim2.new(1, 0, 0, 30), TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left })
	local scroll = Kit.Scroll(holder, {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 1, -34),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
	})
	Kit.List(scroll, true, 12)
	row = scroll :: any
end

function Nests.Refresh()
	local r = row
	if not r then
		return
	end
	local eggs = Derived.Eggs()
	local cap = Nests.Capacity()
	local sig = Kit.Sig({ eggs, cap, math.floor(State.Now()) })
	if sig == lastSig then
		return
	end
	lastSig = sig
	Kit.Clear(r)
	for i = 1, math.max(cap, #eggs) do
		tile(r, i, eggs[i], false)
	end
	tile(r, 99, nil, true)
end

-- Egg flies from the Breed button into the nest row (0.45 s Quad In).
function Nests.FlyEgg(from: GuiObject)
	local r = row
	if not r then
		return
	end
	local gui = from:FindFirstAncestorOfClass("ScreenGui")
	if not gui then
		return
	end
	local root = Kit.Root(gui)
	local start = Kit.ToRoot(gui, from.AbsolutePosition + from.AbsoluteSize / 2)
	local target = Kit.ToRoot(gui, r.AbsolutePosition + Vector2.new(60, 60))
	local egg = Kit.Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(start.X, start.Y),
		Size = UDim2.fromOffset(44, 56),
		BackgroundColor3 = Style.Pal.Sun.Bottom,
		ZIndex = 60,
	}, root)
	Kit.Corner(egg, 99)
	Kit.Stroke(egg, Style.Pal.Sun.Dark, 3)
	Kit.Tween(egg, 0.45, { Position = UDim2.fromOffset(target.X, target.Y) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.5, function()
		egg:Destroy()
	end)
end

return Nests
