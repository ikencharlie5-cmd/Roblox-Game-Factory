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

local PASSES = {
	{ Key = "VIP", Icon = "👑", Desc = "+25% income, 100% offline cash, VIP chat tag" },
	{ Key = "DoubleCash", Icon = "💰", Desc = "x2 cash forever" },
	{ Key = "SuperLuck", Icon = "🍀", Desc = "+50% shop luck forever" },
	{ Key = "AutoGardener", Icon = "🤖", Desc = "Auto-collects Tip Jars + auto-waters" },
}

local PRODUCTS = {
	{ Key = "CashBoost", Icon = "💸", Desc = "30 min of income right now" },
	{ Key = "FinishGrowing", Icon = "⏩", Desc = "Finish ALL growing plants" },
	{ Key = "InstantRestock", Icon = "⚡", Desc = "New Seed Shop stock now" },
	{ Key = "Hope100", Icon = "🌟", Desc = "100 Hope" },
	{ Key = "Hope500", Icon = "🌟", Desc = "500 Hope" },
	{ Key = "Hope1500", Icon = "🌟", Desc = "1,500 Hope - best value!" },
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
	local c = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = order })
	if owned then
		(c:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = Style.Color.Leaf
	end
	Kit.Label(c, icon .. " " .. name, { Size = UDim2.new(1, -8, 0.24, 0), Position = UDim2.new(0, 4, 0.04, 0) })
	Kit.Label(c, desc, {
		Size = UDim2.new(1, -8, 0.32, 0),
		Position = UDim2.new(0, 4, 0.29, 0),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	Kit.Button(
		c,
		if owned then "✅ Owned" else "R$ " .. price,
		if owned then Style.Color.Grey else Style.Color.Robux,
		fn,
		{
			Size = UDim2.new(1, -12, 0.3, 0),
			Position = UDim2.new(0, 6, 0.65, 0),
		}
	)
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
			card(i, p.Icon, def.Name, p.Desc, def.Price or 0, Derived.HasPass(p.Key), function()
				Market.PromptPass(p.Key)
			end)
		end
	end
	for i, p in PRODUCTS do
		local def = Config.DevProducts[p.Key]
		if def then
			card(10 + i, p.Icon, def.Name, p.Desc, def.Price or 0, false, function()
				Market.PromptProduct(p.Key)
			end)
		end
	end
end

function StoreWindow.Mount()
	local win = Windows.Create("Store", "💎 Store", Style.Color.Robux)
	list = Kit.Scroll(win.Body)
	Kit.Grid(list, UDim2.new(0.24, -6, 0.5, -6), 8)
	Kit.Padding(list, 4)
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
