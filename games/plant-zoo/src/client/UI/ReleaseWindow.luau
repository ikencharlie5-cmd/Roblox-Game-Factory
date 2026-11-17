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
	Kit.Sound("Release")
	if splash then
		(splash :: (string, Color3?, number?) -> ())("🕊️ Released to the Wild!", Style.Color.Purple, 2.5)
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
		"Release #%d needs:  %s $%s   +   1 %s+ creature",
		n,
		if cashOk then "✅" else "❌",
		Format.Number(cash),
		minRarity
	)
	local slotBonus = if n % 2 == 0 then " · +1 shop slot" else ""
	rewardLabel.Text = string.format(
		"You get: +50%% income forever · +10%% luck · 🌟 %d Hope%s\nKeeps creatures, upgrades, biomes, Hope, Index. Cash -> $100, pads -> 1.",
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
			local isSel = selected == item.id
			local b = Kit.Button(list, Derived.DisplayName(item), if isSel then Style.Color.Purple else Style.RarityColor(s.Rarity), function()
				selected = item.id
				ReleaseWindow.Render(true)
			end, { LayoutOrder = count })
			if isSel then
				local st = b:FindFirstChildOfClass("UIStroke") :: UIStroke
				st.Thickness = 4
				st.Color = Style.Color.Sun
			end
		end
	end
	if count == 0 then
		Kit.Label(list, "No grown " .. minRarity .. "+ creature yet. Keep growing! 🌱", {
			LayoutOrder = 1,
			Font = Style.FontBody,
			TextColor3 = Style.Color.InkSoft,
		})
		selected = nil
	end
	local ready = cashOk and selected ~= nil
	Kit.SetButtonColor(releaseBtn, if ready then Style.Color.Purple else Style.Color.Grey)
end

function ReleaseWindow.Mount()
	local win = Windows.Create("Release", "🕊️ Release to the Wild", Style.Color.Purple)
	reqLabel = Kit.Label(win.Body, "", { Size = UDim2.fromScale(1, 0.1) })
	rewardLabel = Kit.Label(win.Body, "", {
		Size = UDim2.fromScale(1, 0.16),
		Position = UDim2.fromScale(0, 0.11),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	Kit.Label(win.Body, "Pick who goes to the World Reserve:", {
		Size = UDim2.fromScale(1, 0.07),
		Position = UDim2.fromScale(0, 0.28),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	list = Kit.Scroll(win.Body, { Position = UDim2.fromScale(0, 0.36), Size = UDim2.fromScale(1, 0.44) })
	Kit.Grid(list, UDim2.new(0.32, -6, 0, 48), 6)
	Kit.Padding(list, 4)
	releaseBtn = Kit.Button(win.Body, "🕊️ Release to the Wild", Style.Color.Grey, function()
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
	end, { Size = UDim2.fromScale(0.6, 0.16), Position = UDim2.fromScale(0.2, 0.83) })
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
