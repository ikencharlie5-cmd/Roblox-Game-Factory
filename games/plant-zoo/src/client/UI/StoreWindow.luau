--!strict
-- Robux store: game passes (with Owned state) and dev products. Server grants everything.
local Players = game:GetService("Players")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Market = require(script.Parent:WaitForChild("Market"))

local StoreWindow = {}

local list: ScrollingFrame

-- Icon = Style.Icons name (code-drawn badge until uploaded).
local PASSES = {
	{ Key = "VIP", Desc = "+25% income, 100% offline cash, VIP chat tag" },
	{ Key = "DoubleCash", Desc = "x2 cash forever" },
	{ Key = "SuperLuck", Desc = "+50% shop luck forever" },
	{ Key = "AutoGardener", Desc = "Auto-collects Tip Jars + auto-waters" },
}

local PRODUCTS = {
	{ Key = "CashBoost", Desc = "30 min of income right now" },
	{ Key = "FinishGrowing", Desc = "Finish ALL growing plants" },
	{ Key = "InstantRestock", Desc = "New Seed Shop stock now" },
	{ Key = "Hope100", Icon = "Hope", Desc = "100 Hope" },
	{ Key = "Hope500", Icon = "Hope", Desc = "500 Hope" },
	{ Key = "Hope1500", Icon = "Hope", Desc = "1,500 Hope - best value!" },
}

local function card(
	order: number,
	icon: string,
	name: string,
	desc: string,
	price: number,
	owned: boolean,
	fn: () -> ()
)
	local c = Kit.Card(list, nil, { LayoutOrder = order })
	if owned then
		(c:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = Style.Pal.Leaf.Bottom
	end
	Kit.Icon(c, icon, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(76, 76),
		Depth = true,
		ZIndex = 3,
	})
	Kit.Label(
		c,
		name,
		{ Position = UDim2.fromOffset(6, 88), Size = UDim2.new(1, -12, 0, 30), TextSize = 22, ZIndex = 3 }
	)
	Kit.Body(
		c,
		desc,
		{ Position = UDim2.fromOffset(8, 118), Size = UDim2.new(1, -16, 0, 52), TextSize = 17, ZIndex = 3 }
	)
	Kit.Button(c, if owned then "Owned" else "R$ " .. price, if owned then Style.Color.Grey else "Robux", fn, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 54),
		TextSize = 24,
		Lip = 4,
		ZIndex = 4,
	})
end

function StoreWindow.Render()
	if not Windows.IsOpen("Store") then
		return
	end
	Kit.Clear(list)
	local Config = Derived.Config
	for i, p in PASSES do
		local def = Config.GamePasses[p.Key]
		if def then
			card(i, p.Key, def.Name, p.Desc, def.Price or 0, Derived.HasPass(p.Key), function()
				Market.PromptPass(p.Key)
			end)
		end
	end
	for i, p in PRODUCTS do
		local def = Config.DevProducts[p.Key]
		if def then
			card(10 + i, p.Icon or p.Key, def.Name, p.Desc, def.Price or 0, false, function()
				Market.PromptProduct(p.Key)
			end)
		end
	end
end

function StoreWindow.Mount()
	local win = Windows.Create("Store", "Store", "Pink", "Store")
	list = Kit.Scroll(win.Body)
	Kit.Grid(list, UDim2.fromOffset(172, 240), 12)
	Kit.Padding(list, 8)
	win.OnOpen = function()
		StoreWindow.Render()
	end
	-- Refresh "Owned" when MonetizationService flips a Pass_ attribute.
	local player = Players.LocalPlayer :: Player
	player.AttributeChanged:Connect(function(attr)
		if string.sub(attr, 1, 5) == "Pass_" then
			StoreWindow.Render()
		end
	end)
end

return StoreWindow
