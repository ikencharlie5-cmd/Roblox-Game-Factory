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

-- Mutation badges: code-drawn chips (2 letters) in the mutation's colour.
local BADGES: { [string]: string } = {
	Gold = "Sun",
	Diamond = "Sky",
	Rainbow = "Pink",
	Dewy = "Teal",
	Sunkissed = "Sun",
	Frosted = "Sky",
	Electric = "Purple",
	Starlit = "Purple",
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
			local c = Kit.Card(list, s.Rarity, { LayoutOrder = i })
			Kit.CreatureView(c, s.Name, "Grown", {
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.new(1, -12, 0, 90),
				Silhouette = not isFound,
				ZIndex = 2,
			})
			Kit.Label(c, "#" .. i, {
				Position = UDim2.fromOffset(8, 4),
				Size = UDim2.fromOffset(40, 22),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Style.Color.InkSoft,
				ZIndex = 3,
			})
			Kit.BiomeChip(c, s.Biome, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.fromOffset(28, 28),
				ZIndex = 3,
			})
			Kit.Label(c, if isFound then s.Name else "???", {
				Position = UDim2.fromOffset(4, 96),
				Size = UDim2.new(1, -8, 0, 26),
				TextSize = 20,
				TextColor3 = if isFound then Style.Color.Ink else Style.Color.InkSoft,
				ZIndex = 3,
			})
			Kit.Body(c, if isFound then string.format("$%s/s · %s", Format.Number(s.Income), s.Role) else s.Biome, {
				Position = UDim2.fromOffset(4, 120),
				Size = UDim2.new(1, -8, 0, 22),
				TextSize = 16,
				ZIndex = 3,
			})
			local row = Kit.Make("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(4, 144),
				Size = UDim2.new(1, -8, 0, 24),
				ZIndex = 3,
			}, c)
			Kit.List(row, true, 3, true)
			if type(entry) == "table" then
				for mut in entry do
					if type(mut) == "string" and BADGES[mut] then
						Kit.CodeBadge(row, string.sub(mut, 1, 2), Style.Pal[BADGES[mut]], {
							Size = UDim2.fromOffset(24, 24),
							ZIndex = 3,
						})
					end
				end
			end
		end
	end
	countLabel.Text = string.format("Found %d / %d", have, total)
		.. (if roleFilter then "   (showing " .. roleFilter .. "s)" else "")
end

function IndexWindow.Mount()
	local win = Windows.Create("Index", "Index", "Purple", "Index")
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58) }, win.Body)
	countLabel = Kit.Label(top, "", {
		Size = UDim2.new(0.7, 0, 0, 44),
		Position = UDim2.fromOffset(4, 6),
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local allBtn = Kit.Button(top, "Show all", "Purple", function()
		roleFilter = nil
		IndexWindow.Render(true)
	end, { Size = UDim2.new(0.26, 0, 0, 56), Position = UDim2.new(0.74, 0, 0, 0), TextSize = 24, Lip = 4 })
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68) })
	Kit.Grid(list, UDim2.fromOffset(140, 202), 10)
	Kit.Padding(list, 8)
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
