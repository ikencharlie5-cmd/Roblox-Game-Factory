--!strict
-- Upgrades (kept through Release): level pips, effect, next cost, Buy.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local UpgradesWindow = {}

local list: ScrollingFrame
local lastSig = ""

local INFO: { [string]: { Glyph: string, Pal: string, Text: string } } = {
	WateringCan = { Glyph = "W", Pal = "Sky", Text = "Water skips more grow time" },
	Fertilizer = { Glyph = "F", Pal = "Leaf", Text = "+10% grow speed per level" },
	ShopLuck = { Glyph = "L", Pal = "Leaf", Text = "+10% shop luck per level" },
	BiggerRestock = { Glyph = "R", Pal = "Sun", Text = "+1 Seed Shop slot per level" },
	VisitorAppeal = { Glyph = "V", Pal = "Pink", Text = "+10% income per level" },
	ComfyBenches = { Glyph = "C", Pal = "Wood", Text = "+2 h offline earnings cap" },
}

function UpgradesWindow.Render(force: boolean?)
	if not Windows.IsOpen("Upgrades") then
		return
	end
	local ups = State.Tbl("upgrades")
	local sig = Kit.Sig(ups)
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	Kit.Clear(list)
	local Config = Derived.Config
	for i, key in Config.UpgradeOrder do
		local def = Config.Upgrades[key]
		local level = ups[key] or 0
		local max = #def.Costs
		local cost = def.Costs[level + 1]
		local info = INFO[key] or { Glyph = "U", Pal = "Leaf", Text = "" }
		local row = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = i, Size = UDim2.new(1, -12, 0, 84) })
		Kit.Stagger(row)
		Kit.CodeBadge(row, info.Glyph, Style.Pal[info.Pal], {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(60, 60),
		})
		Kit.Label(row, def.Name, {
			Size = UDim2.new(0.45, -84, 0, 34),
			Position = UDim2.fromOffset(84, 8),
			TextSize = 28,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		Kit.Body(row, info.Text, {
			Size = UDim2.new(0.45, -84, 0, 28),
			Position = UDim2.fromOffset(84, 46),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local pips = Kit.Make("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0.25, 0, 0, 22),
			Position = UDim2.new(0.47, 0, 0.5, 0),
		}, row)
		Kit.List(pips, true, 5, true)
		for p = 1, max do
			local on = p <= level
			local pal = if on then Style.Pal.Leaf else Style.Pal.Disabled
			local pip = Kit.Make("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Size = UDim2.new(1 / max, -5, 1, 0),
				LayoutOrder = p,
			}, pips)
			Kit.Corner(pip, 99)
			Kit.Gradient(pip, pal)
			Kit.Stroke(pip, pal.Dark, 2.5)
		end
		if cost then
			Kit.Button(row, "$" .. Format.Number(cost), "Leaf", function()
				Net.Do("BuyUpgrade", def.Name .. " upgraded!", key)
			end, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0.24, 0, 0, 60),
				Icon = "Cash",
				IconSize = 32,
				TextSize = 24,
			})
		else
			Kit.Title(row, "MAX", Style.Pal.Sun.Dark, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0.24, 0, 0, 44),
				TextSize = 34,
				TextColor3 = Style.Pal.Sun.Top,
			})
		end
	end
end

function UpgradesWindow.Mount()
	local win = Windows.Create("Upgrades", "Upgrades", "Leaf", "Upgrades")
	Kit.Body(win.Body, "Upgrades are kept forever - even after Release!", {
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = 22,
	})
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 1, -38) })
	Kit.List(list, false, 10, true)
	Kit.Padding(list, 6)
	win.OnOpen = function()
		UpgradesWindow.Render(true)
	end
	State.OnChange(function(what)
		if what == "data" then
			UpgradesWindow.Render()
		end
	end)
end

return UpgradesWindow
