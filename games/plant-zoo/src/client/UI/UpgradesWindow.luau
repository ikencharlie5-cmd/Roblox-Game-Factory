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

local INFO: { [string]: { Icon: string, Text: string } } = {
	WateringCan = { Icon = "🚿", Text = "Water skips more grow time" },
	Fertilizer = { Icon = "🧪", Text = "+10% grow speed per level" },
	ShopLuck = { Icon = "🍀", Text = "+10% shop luck per level" },
	BiggerRestock = { Icon = "🛒", Text = "+1 Seed Shop slot per level" },
	VisitorAppeal = { Icon = "🎟️", Text = "+10% income per level" },
	ComfyBenches = { Icon = "🪑", Text = "+2 h offline earnings cap" },
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
		local info = INFO[key] or { Icon = "⬆️", Text = "" }
		local row = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 64) })
		Kit.Label(row, info.Icon, { Size = UDim2.new(0, 50, 1, -8), Position = UDim2.new(0, 4, 0, 4) })
		Kit.Label(row, def.Name, {
			Size = UDim2.new(0.45, -60, 0.5, -2),
			Position = UDim2.new(0, 58, 0, 4),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		Kit.Label(row, info.Text, {
			Size = UDim2.new(0.45, -60, 0.4, 0),
			Position = UDim2.new(0, 58, 0.55, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Style.FontBody,
			TextColor3 = Style.Color.InkSoft,
		})
		local pips = Kit.Make("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.25, 0, 0.4, 0),
			Position = UDim2.new(0.47, 0, 0.3, 0),
		}, row)
		Kit.List(pips, true, 4, true)
		for p = 1, max do
			local pip = Kit.Make("Frame", {
				BackgroundColor3 = if p <= level then Style.Color.Leaf else Style.Color.Grey,
				Size = UDim2.new(1 / max, -4, 1, 0),
				LayoutOrder = p,
			}, pips)
			Kit.Corner(pip, 6)
		end
		if cost then
			Kit.Button(row, "$" .. Format.Number(cost), Style.Color.Leaf, function()
				if Net.Do("BuyUpgrade", "⬆️ " .. def.Name .. " upgraded!", key) then
					Kit.Sound("Purchase")
				end
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.24, 0, 0, 48) })
		else
			Kit.Label(row, "MAX ⭐", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.new(0.24, 0, 0.6, 0),
				TextColor3 = Style.Color.Sun,
			})
		end
	end
end

function UpgradesWindow.Mount()
	local win = Windows.Create("Upgrades", "⬆️ Upgrades", Style.Color.LeafDark)
	Kit.Label(win.Body, "Upgrades are kept forever - even after Release!", {
		Size = UDim2.new(1, 0, 0, 26),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 32), Size = UDim2.new(1, 0, 1, -32) })
	Kit.List(list, false, 6)
	Kit.Padding(list, 4)
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
