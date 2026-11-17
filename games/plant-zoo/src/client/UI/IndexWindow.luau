--!strict
-- Collection Index: all 28 species, silhouettes until found, rarity colors, mutation badges.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local IndexWindow = {}

local list: ScrollingFrame
local countLabel: TextLabel
local roleFilter: string? = nil
local lastSig = ""

local BADGES: { [string]: string } = {
	Gold = "🟡",
	Diamond = "💎",
	Rainbow = "🌈",
	Dewy = "💧",
	Sunkissed = "☀️",
	Frosted = "🧊",
	Electric = "⚡",
	Starlit = "⭐",
}

function IndexWindow.Render(force: boolean?)
	if not Windows.IsOpen("Index") then
		return
	end
	local found = State.Tbl("indexFound")
	local sig = Kit.Sig({ found, roleFilter })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	Kit.Clear(list)
	local total, have = 0, 0
	for i, s in Derived.Config.Species.List do
		total += 1
		local entry = found[s.Name]
		local isFound = entry ~= nil and entry ~= false
		if isFound then
			have += 1
		end
		if roleFilter == nil or s.Role == roleFilter then
			local color = Style.RarityColor(s.Rarity)
			local c = Kit.Panel(list, if isFound then Style.Color.Panel else Style.Color.Dark, { LayoutOrder = i })
			local stroke = c:FindFirstChildOfClass("UIStroke") :: UIStroke
			stroke.Color = color
			stroke.Thickness = 3
			local band = Kit.Make("Frame", { BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0.18) }, c)
			Kit.Corner(band, 10)
			Kit.Label(band, string.format("#%d %s", i, s.Rarity), { TextColor3 = Style.Color.White })
			Kit.Label(c, if isFound then s.Name else "???", {
				Size = UDim2.new(1, -8, 0.22, 0),
				Position = UDim2.new(0, 4, 0.2, 0),
				TextColor3 = if isFound then Style.Color.Ink else Style.Color.Grey,
			})
			local biome = Style.BiomeInfo(s.Biome).Icon .. " " .. s.Biome
			Kit.Label(c, if isFound then string.format("%s\n$%s/s · %s", biome, Format.Number(s.Income), s.Role) else biome, {
				Size = UDim2.new(1, -8, 0.3, 0),
				Position = UDim2.new(0, 4, 0.43, 0),
				Font = Style.FontBody,
				TextColor3 = if isFound then Style.Color.InkSoft else Style.Color.Grey,
			})
			local badges = ""
			if type(entry) == "table" then
				for mut in entry do
					badges ..= BADGES[mut] or ""
				end
			end
			Kit.Label(c, badges, { Size = UDim2.new(1, -8, 0.2, 0), Position = UDim2.new(0, 4, 0.76, 0) })
			if s.Rarity == "Secret" then
				task.spawn(function()
					while stroke.Parent do
						stroke.Color = Color3.fromHSV((os.clock() / 4) % 1, 0.8, 1)
						task.wait(0.05)
					end
				end)
			end
		end
	end
	countLabel.Text = string.format("📖 Found %d / %d", have, total)
		.. (if roleFilter then "   (showing " .. roleFilter .. "s)" else "")
end

function IndexWindow.Mount()
	local win = Windows.Create("Index", "📖 Index", Style.Color.Sky)
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) }, win.Body)
	countLabel = Kit.Label(top, "", { Size = UDim2.new(0.7, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
	local allBtn = Kit.Button(top, "Show all", Style.Color.Sky, function()
		roleFilter = nil
		IndexWindow.Render(true)
	end, { Size = UDim2.new(0.26, 0, 1, 0), Position = UDim2.new(0.74, 0, 0, 0) })
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52) })
	Kit.Grid(list, UDim2.new(0.19, -6, 0.5, -6), 8)
	Kit.Padding(list, 4)
	win.OnOpen = function(arg: any)
		roleFilter = if type(arg) == "table" then arg.role else nil
		allBtn.Visible = roleFilter ~= nil
		IndexWindow.Render(true)
	end
	State.OnChange(function(what)
		if what == "data" then
			IndexWindow.Render()
		end
	end)
end

return IndexWindow
