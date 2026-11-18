--!strict
-- The one shared creature card (guide §4), 150x190: static viewport, mutation dots (top-right,
-- max 3 then "+N"), happiness ring, name + species/stage, rarity band. Used by Collection,
-- Breeding picker/slots and Journal (species variant with silhouettes).
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Derived = require(script.Parent:WaitForChild("Derived"))

local CreatureCard = {}

export type Opts = {
	OnClick: (() -> ())?,
	Disabled: string?, -- reason; greys the card and shows the reason instead of the species line
	Selected: boolean?,
	LayoutOrder: number?,
	Size: UDim2?,
}

local function clickable(card: Frame, opts: Opts)
	local hit = Kit.Make("TextButton", {
		Name = "Hit",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	}, card)
	local scale = Kit.Make("UIScale", { Name = "Hover" }, card)
	hit.MouseEnter:Connect(function()
		Kit.Tween(scale, 0.12, { Scale = 1.04 })
	end)
	hit.MouseLeave:Connect(function()
		Kit.Tween(scale, 0.12, { Scale = 1 })
	end)
	hit.MouseButton1Down:Connect(function()
		Kit.Tween(scale, 0.07, { Scale = 0.95 })
	end)
	hit.Activated:Connect(function()
		Kit.Tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		if opts.Disabled then
			Kit.Sound("Error")
			return
		end
		Kit.Sound("Click")
		if opts.OnClick then
			(opts.OnClick :: () -> ())()
		end
	end)
end

function CreatureCard.New(parent: Instance?, c: { [string]: any }, opts: Opts?): Frame
	local o: Opts = opts or {}
	local species = tostring(Derived.Field(c, "species", "Species") or "?")
	local rarity = Derived.Rarity(species)
	local muts = Derived.Muts(c)
	local card = Kit.Card(nil, rarity, {
		Name = "Card_" .. tostring(c.uid),
		Size = o.Size or UDim2.fromOffset(150, 190),
		LayoutOrder = o.LayoutOrder or 0,
	})
	Kit.CreatureView(card, species, {
		Genes = Derived.Field(c, "genes"),
		Mutations = muts,
		Stage = Derived.Stage(c),
		Rarity = rarity,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(1, -20, 0.55, 0),
		ZIndex = 2,
	})
	-- Mutation dots
	local dots = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(70, 22),
		ZIndex = 4,
	}, card)
	local dl = Kit.List(dots, true, 2)
	dl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	for i, m in muts do
		if i > 3 then
			Kit.Title(dots, "+" .. (#muts - 3), Style.Color.Chip, { Size = UDim2.fromOffset(22, 22), TextSize = 16 })
			break
		end
		Kit.MutationBadge(dots, m, 20, { LayoutOrder = i, ZIndex = 4 })
	end
	Kit.HappyRing(card, Derived.Happy(c), 32, {
		Position = UDim2.new(0, 6, 0.55, -30),
		ZIndex = 4,
	})
	Kit.Label(card, Derived.Name(c), {
		Position = UDim2.new(0, 6, 0.6, 0),
		Size = UDim2.new(1, -12, 0, 24),
		TextSize = 20,
		ZIndex = 3,
	})
	local sub = if o.Disabled then o.Disabled else species .. " · " .. Derived.Stage(c)
	Kit.Body(card, sub, {
		Position = UDim2.new(0, 6, 0.6, 24),
		Size = UDim2.new(1, -12, 0, 18),
		TextSize = 15,
		TextColor3 = if o.Disabled then Style.Color.Red else Style.Color.InkSoft,
		ZIndex = 3,
	})
	if o.Disabled then
		Kit.Make("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 10,
		}, card)
	end
	if o.Selected then
		local s = Kit.Stroke(card, Style.Pal.Leaf.Bottom, 5)
		s.Name = "Selected"
	end
	clickable(card, o)
	card.Parent = parent
	return card
end

-- Journal species card: unknown = silhouette "???", seen = grey band, captured+ = full card.
function CreatureCard.Species(parent: Instance?, def: { [string]: any }, step: number, opts: Opts?): Frame
	local o: Opts = opts or {}
	local rarity = Derived.Field(def, "rarity", "Rarity") or "Common"
	local known = step >= 1
	local card = Kit.Card(nil, if step >= 2 then rarity else nil, {
		Name = "Species_" .. tostring(def.name),
		Size = o.Size or UDim2.fromOffset(150, 190),
		LayoutOrder = o.LayoutOrder or 0,
	})
	Kit.CreatureView(card, tostring(def.name), {
		Silhouette = not known,
		Rarity = rarity,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(1, -20, 0.55, 0),
		ZIndex = 2,
	})
	Kit.Label(card, if known then tostring(def.name) else "???", {
		Position = UDim2.new(0, 6, 0.6, 0),
		Size = UDim2.new(1, -12, 0, 24),
		TextSize = 20,
		ZIndex = 3,
	})
	local hint = if step == 1
		then "Seen"
		elseif step >= 2 then string.format("Research %d/5", step)
		else tostring(Derived.Field(def, "hint", "Hint") or "Not found yet")
	Kit.Body(card, hint, {
		Position = UDim2.new(0, 6, 0.6, 24),
		Size = UDim2.new(1, -12, 0, if step >= 2 then 18 else 40),
		TextSize = 15,
		ZIndex = 3,
	})
	clickable(card, o)
	card.Parent = parent
	return card
end

return CreatureCard
