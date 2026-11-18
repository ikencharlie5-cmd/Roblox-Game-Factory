--!strict
-- Release to the Wild (prestige): requirement + reward, pick an eligible creature, confirm
-- "They won't come back!", then a short camera cutscene to the World Reserve.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Plots = require(script.Parent:WaitForChild("Plots"))

local ReleaseWindow = {}

local reqLabel: TextLabel
local rewardLabel: TextLabel
local list: ScrollingFrame
local releaseBtn: TextButton
local selected: any = nil
local lastSig = ""
local splash: ((string, Color3?, number?) -> ())? = nil

function ReleaseWindow.SetSplash(fn: (string, Color3?, number?) -> ())
	splash = fn
end

local function eligible(item: any, placed: boolean, minRarity: string): boolean
	local s = Derived.Species(item.species)
	if not s or Style.RarityIndex(s.Rarity) < Style.RarityIndex(minRarity) then
		return false
	end
	if placed then
		local _, progress = Derived.Stage(item)
		return progress >= 1
	end
	return true
end

local function cutscene()
	local cam = workspace.CurrentCamera
	local altar = Plots.TaggedPart("ReleaseAltar")
	if splash then
		(splash :: (string, Color3?, number?) -> ())("Released to the Wild!", Style.Color.Teal, 2.5)
	end
	if not altar then
		return
	end
	local oldType = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable
	local target = altar.Position
	cam.CFrame = CFrame.lookAt(target + Vector3.new(0, 40, 60), target)
	Kit.Tween(cam, 3, { CFrame = CFrame.lookAt(target + Vector3.new(0, 18, 28), target) }, Enum.EasingStyle.Sine)
	task.wait(3.2)
	cam.CameraType = oldType
end

local function creatureCard(item: any, rarity: string, order: number)
	local isSel = selected == item.id
	local c = Kit.Card(list, rarity, { LayoutOrder = order })
	Kit.CreatureView(c, tostring(item.species), "Grown", {
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, 84),
		ZIndex = 2,
	})
	Kit.Label(c, Derived.DisplayName(item), {
		Position = UDim2.fromOffset(4, 92),
		Size = UDim2.new(1, -8, 0, 40),
		TextSize = 20,
		ZIndex = 3,
	})
	if isSel then
		local st = c:FindFirstChildOfClass("UIStroke") :: UIStroke
		st.Thickness = 5
		Kit.CodeBadge(c, "OK", Style.Pal.Teal, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.fromOffset(34, 34),
			ZIndex = 5,
		})
	end
	local hit = Kit.Make("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
	}, c)
	hit.Activated:Connect(function()
		Kit.Sound("Click")
		selected = item.id
		ReleaseWindow.Render(true)
	end)
end

function ReleaseWindow.Render(force: boolean?)
	if not Windows.IsOpen("Release") then
		return
	end
	local n, cash, minRarity = Derived.ReleaseInfo()
	local have = State.Num("cash")
	local cashOk = have >= cash
	local sig = Kit.Sig({ n, cashOk, #State.Tbl("placed"), State.Tbl("inventory").creatures, selected })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	reqLabel.Text = string.format(
		'Release #%d needs: <font color="#%s">$%s</font> + 1 grown %s+ creature',
		n,
		if cashOk then Style.Pal.Leaf.Bottom:ToHex() else Style.Pal.Red.Bottom:ToHex(),
		Format.Number(cash),
		minRarity
	)
	local slotBonus = if n % 2 == 0 then " · +1 shop slot" else ""
	rewardLabel.Text = string.format(
		"You get: +50%% income forever · +10%% luck · %d Hope%s\nKeeps creatures, upgrades, biomes, Hope, Index. Cash -> $100, pads -> 1.",
		Derived.Config.Release.HopePer * n,
		slotBonus
	)
	Kit.Clear(list)
	local count = 0
	for _, entry in Derived.AllCreatures() do
		local item = entry.item
		if eligible(item, entry.placed, minRarity) then
			count += 1
			local s = Derived.Species(item.species)
			creatureCard(item, s.Rarity, count)
		end
	end
	if count == 0 then
		Kit.Body(list, "No grown " .. minRarity .. "+ creature yet. Keep growing!", {
			LayoutOrder = 1,
			TextSize = 22,
		})
		selected = nil
	end
	local ready = cashOk and selected ~= nil
	Kit.SetButtonColor(releaseBtn, if ready then "Teal" else Style.Color.Grey)
end

function ReleaseWindow.Mount()
	local win = Windows.Create("Release", "Release to the Wild", "Teal", "Release")
	reqLabel = Kit.Label(win.Body, "", { Size = UDim2.new(1, 0, 0, 36), TextSize = 28 })
	rewardLabel = Kit.Body(win.Body, "", {
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 0, 52),
		TextSize = 20,
	})
	Kit.Label(win.Body, "Pick who goes to the World Reserve:", {
		Position = UDim2.fromOffset(0, 94),
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	list = Kit.Scroll(win.Body, { Position = UDim2.fromOffset(0, 128), Size = UDim2.new(1, 0, 1, -212) })
	Kit.Grid(list, UDim2.fromOffset(140, 170), 10)
	Kit.Padding(list, 8)
	releaseBtn = Kit.Button(win.Body, "Release to the Wild", Style.Color.Grey, function()
		local id = selected
		local item = nil
		for _, e in Derived.AllCreatures() do
			if e.item.id == id then
				item = e.item
			end
		end
		if not item then
			Kit.Sound("Error")
			return
		end
		Windows.Confirm(
			"Release " .. Derived.DisplayName(item) .. "?",
			"They won't come back! Your cash resets to $100 and pads to 1.",
			"Release!",
			function()
				if Net.Do("Release", nil, id) then
					selected = nil
					Windows.Close()
					cutscene()
				end
			end
		)
	end, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(380, 72),
		Icon = "Release",
		TextSize = 28,
	})
	win.OnOpen = function()
		ReleaseWindow.Render(true)
	end
	State.OnChange(function(what)
		if what == "data" then
			ReleaseWindow.Render()
		end
	end)
end

return ReleaseWindow
