--!strict
-- Discovery Journal (guide §8): Greenleaf Forest completion bar, species grid (silhouette "???"
-- until seen), and a species page with the 5-step research track (Seen -> Captured -> Bred ->
-- Mutation found -> Mastered) and a mutation gallery (found in colour, unfound as "?").
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local CreatureCard = require(script.Parent:WaitForChild("CreatureCard"))

local JournalWindow = {}

local STEPS = { "Seen", "Captured", "Bred", "Mutation found", "Mastered" }

local win: any
local header: TextLabel
local setBar: (number) -> ()
local body: Frame
local page: string? = nil
local lastSig = ""
local seenSteps: { [string]: number } = {}
local badgeFn: ((number) -> ())? = nil

function JournalWindow.SetBadge(fn: (number) -> ())
	badgeFn = fn
end

local function foundMutations(species: string): { [string]: boolean }
	local out: { [string]: boolean } = {}
	local j = State.Tbl("journal")[species]
	local list = if type(j) == "table" then (j.mutations or j.found) else nil
	if type(list) == "table" then
		for k, v in list do
			if type(v) == "string" then
				out[v] = true
			elseif v == true then
				out[tostring(k)] = true
			end
		end
	end
	for _, c in Derived.Creatures() do
		if c.species == species then
			for _, m in Derived.Muts(c) do
				out[m] = true
			end
		end
	end
	return out
end

local function grid()
	local scroll = Kit.Scroll(body)
	Kit.Grid(scroll, UDim2.fromOffset(150, 190), 12)
	Kit.Padding(scroll, 8)
	for i, def in Derived.SpeciesList() do
		CreatureCard.Species(scroll, def, Derived.JournalStep(def.name), {
			LayoutOrder = i,
			OnClick = function()
				if Derived.JournalStep(def.name) >= 1 then
					page = def.name
					lastSig = ""
					JournalWindow.Render()
				else
					Kit.Sound("Error")
				end
			end,
		})
	end
end

local function speciesPage(name: string)
	local def = Derived.Species(name)
	local step = Derived.JournalStep(name)
	Kit.Button(body, "< Back", "Stone", function()
		page = nil
		lastSig = ""
		JournalWindow.Render()
	end, { Size = UDim2.fromOffset(130, 50), TextSize = 22 })
	local pane = Kit.Panel(body, nil, { Position = UDim2.fromOffset(0, 60), Size = UDim2.new(0.38, 0, 1, -60) })
	Kit.CreatureView(pane, name, { Rarity = def.rarity, Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), ZIndex = 3 })
	local right = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.38, 16, 0, 0),
		Size = UDim2.new(0.62, -16, 1, 0),
	}, body)
	Kit.Label(right, name, { Size = UDim2.new(1, 0, 0, 44), TextSize = 40, TextXAlignment = Enum.TextXAlignment.Left })
	local tags = Derived.Field(def, "tags", "Tags")
	local about = string.format(
		"%s · %s\nLikes: %s",
		Style.NormRarity(def.rarity),
		tostring(Derived.Field(def, "personality", "Personality") or "Greenleaf Forest"),
		if type(tags) == "table" then table.concat(tags, ", ") else "?"
	)
	Kit.Body(right, tostring(Derived.Field(def, "description", "Description") or about), {
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 56),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- Research track: 5 connected 40 px nodes, filled = purple.
	local track = Kit.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 116), Size = UDim2.new(1, 0, 0, 90) }, right)
	Kit.Make("Frame", {
		BackgroundColor3 = Style.Color.Frame,
		BorderSizePixel = 0,
		Position = UDim2.new(0.1, 0, 0, 19),
		Size = UDim2.new(0.8, 0, 0, 4),
	}, track)
	for i, label in STEPS do
		local on = step >= i
		local x = (i - 0.5) / #STEPS
		Kit.CodeBadge(track, tostring(i), if on then Style.Pal.Purple else Style.Pal.Stone, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(x, 0),
			Size = UDim2.fromOffset(40, 40),
			ZIndex = 3,
		})
		Kit.Body(track, label, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(x, 0, 0, 46),
			Size = UDim2.new(1 / #STEPS, 0, 0, 36),
			TextSize = 14,
			TextColor3 = if on then Style.Pal.Purple.Dark else Style.Color.InkSoft,
		})
	end
	Kit.Label(right, "Mutation gallery", { Position = UDim2.fromOffset(0, 214), Size = UDim2.new(1, 0, 0, 32), TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left })
	local gallery = Kit.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, 0, 0, 100) }, right)
	Kit.Grid(gallery, UDim2.fromOffset(96, 84), 10).HorizontalAlignment = Enum.HorizontalAlignment.Left
	local found = foundMutations(name)
	for i, m in Derived.Mutations() do
		local cell = Kit.Panel(gallery, nil, { LayoutOrder = i })
		local got = found[m.name] == true
		if got then
			Kit.MutationBadge(cell, m.name, 40, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), ZIndex = 3 })
		else
			Kit.CodeBadge(cell, "?", Style.Pal.Stone, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(40, 40), ZIndex = 3 })
		end
		Kit.Body(cell, if got then m.name else "???", { Position = UDim2.fromOffset(4, 50), Size = UDim2.new(1, -8, 0, 26), TextSize = 16, ZIndex = 3 })
	end
end

function JournalWindow.Render()
	if not Windows.IsOpen("Journal") then
		return
	end
	local list = Derived.SpeciesList()
	local total, known = #list * 5, 0
	local found = 0
	for _, def in list do
		local s = Derived.JournalStep(def.name)
		known += math.min(5, s)
		if s >= 2 then
			found += 1
		end
		seenSteps[def.name] = s
	end
	header.Text = string.format("Greenleaf Forest  %d/%d species  (%d%%)", found, #list, math.floor(known / math.max(1, total) * 100))
	setBar(known / math.max(1, total))
	if badgeFn then
		(badgeFn :: (number) -> ())(0)
	end
	local sig = Kit.Sig({ page, State.Get("journal") })
	if sig == lastSig then
		return
	end
	lastSig = sig
	Kit.Clear(body)
	if page then
		speciesPage(page :: string)
	else
		grid()
	end
end

-- Badge = species whose research step went up since the Journal was last opened.
function JournalWindow.NewCount(): number
	local n = 0
	for _, def in Derived.SpeciesList() do
		if Derived.JournalStep(def.name) > (seenSteps[def.name] or 0) then
			n += 1
		end
	end
	return n
end

function JournalWindow.Mount()
	win = Windows.Create("Journal", "Discovery Journal", "Purple", "Journal", Vector2.new(900, 640))
	header = Kit.Label(win.Body, "", { Size = UDim2.new(1, 0, 0, 32), TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left })
	local _, set = Kit.Progress(win.Body, "Purple", { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 16) })
	setBar = set
	body = Kit.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 1, -64) }, win.Body)
	win.OnOpen = function()
		page = nil
		lastSig = ""
		JournalWindow.Render()
	end
	State.OnChange(function(what)
		if what == "data" then
			JournalWindow.Render()
			if badgeFn and not Windows.IsOpen("Journal") then
				(badgeFn :: (number) -> ())(JournalWindow.NewCount())
			end
		end
	end)
end

-- Seed "already seen" steps on first data so returning players don't get a badge for old entries.
function JournalWindow.Seed()
	for _, def in Derived.SpeciesList() do
		seenSteps[def.name] = Derived.JournalStep(def.name)
	end
end

return JournalWindow
