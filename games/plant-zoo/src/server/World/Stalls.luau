--!strict
-- Landmark shop stalls (ART_STYLE_GUIDE §6): striped awning with a scalloped edge, big stroked sign,
-- and a 3D icon prop on the roof (asset hook Assets.Props.<Icon> e.g. "SeedIcon", else primitives).
-- cf = stall floor CFrame facing the hub center (-Z = customers). The tagged Counter is unchanged.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)
local PlotDressing = require(script.Parent.PlotDressing)

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rad = math.rad
local hex = Color3.fromHex
local M = Enum.Material

local Stalls = {}

local ICONS: { [string]: (Instance, CFrame, Color3) -> () } = {
	SeedIcon = function(m, cf, c)
		Build.Blob(m, V(3.4, 4.2, 2.2), cf * C(0, 2.1, 0), hex("#E9C98F"))
		Build.Deco(m, { Size = V(2.6, 0.7, 1.8), CFrame = cf * C(0, 4.3, 0), Color = hex("#C9A06A") })
		Build.Blob(m, V(1.8, 1.8, 0.4), cf * C(0, 2.1, -1.05), c)
		Build.Ball(m, 0.9, cf * C(0, 2.1, -1.2), hex("#FFE38A"))
	end,
	HopeIcon = function(m, cf, c)
		for _, x in { -1, 1 } do
			Build.Ball(m, 2.4, cf * C(x * 0.85, 2.9, 0), c)
		end
		Build.Deco(m, { Size = V(2.4, 2.4, 1.6), CFrame = cf * C(0, 1.9, 0) * A(0, 0, rad(45)), Color = c })
	end,
	UpgradeIcon = function(m, cf, c)
		Build.Deco(m, { Size = V(1.4, 2.6, 1), CFrame = cf * C(0, 1.3, 0), Color = c })
		Build.Wedge(m, V(1, 1.6, 1.8), cf * C(-0.9, 3.4, 0) * A(0, rad(-90), 0), c)
		Build.Wedge(m, V(1, 1.6, 1.8), cf * C(0.9, 3.4, 0) * A(0, rad(90), 0), c)
	end,
	DailyIcon = function(m, cf, c)
		Build.Deco(m, { Size = V(3, 2.6, 3), CFrame = cf * C(0, 1.3, 0), Color = c })
		Build.Deco(m, { Size = V(3.3, 0.6, 3.3), CFrame = cf * C(0, 2.8, 0), Color = c:Lerp(hex("#000000"), 0.1) })
		Build.Deco(m, { Size = V(0.7, 3.4, 3.4), CFrame = cf * C(0, 1.5, 0), Color = hex("#FFD45C") })
		Build.Deco(m, { Size = V(3.4, 3.4, 0.7), CFrame = cf * C(0, 1.5, 0), Color = hex("#FFD45C") })
		Build.Ball(m, 1.2, cf * C(-0.5, 3.4, 0), hex("#FFD45C"))
		Build.Ball(m, 1.2, cf * C(0.5, 3.4, 0), hex("#FFD45C"))
	end,
}

export type StallRefs = { counter: Part, sign: Part, model: Model }

function Stalls.Build(
	f: Instance,
	cf: CFrame,
	title: string,
	roof: Color3,
	icon: string,
	tag: string,
	attrs: { [string]: any }
): StallRefs
	local m = Build.Model(f, title)
	local wood, dark = Theme.Colors.Wood, Theme.Colors.WoodDark
	local counter = Build.Part(
		m,
		{ Size = V(12, 3.4, 3), CFrame = cf * C(0, 1.7, 0), Color = wood, Material = M.WoodPlanks, Name = "Counter" }
	)
	Build.Tag(counter, tag, attrs)
	Build.Deco(m, { Size = V(12.6, 0.4, 3.6), CFrame = cf * C(0, 3.6, 0), Color = Theme.Colors.Cream })
	Build.Deco(m, { Size = V(12.2, 0.5, 3.1), CFrame = cf * C(0, 0.25, -0.1), Color = dark })
	Build.Part(m, {
		Size = V(13, 9, 0.6),
		CFrame = cf * C(0, 4.5, 4),
		Color = roof:Lerp(Color3.new(1, 1, 1), 0.7),
		Name = "Back",
	})
	for _, x in { -6.2, 6.2 } do
		for _, z in { -1.6, 3.8 } do
			Build.Part(m, { Size = V(0.8, 9.6, 0.8), CFrame = cf * C(x, 4.8, z), Color = dark, Name = "Post" })
		end
	end
	-- Striped awning (alternating roof colour / cream), sloping toward the customers.
	for i = 0, 5 do
		local stripe = Build.Wedge(
			m,
			V(2.3, 2, 7.4),
			cf * C(-5.75 + i * 2.3, 10.6, 0.9),
			if i % 2 == 0 then roof else Theme.RoofStripe,
			M.Fabric
		)
		stripe.CanCollide = false
	end
	-- Scalloped front edge.
	for i = 0, 6 do
		local b = Build.Blob(
			m,
			V(2, 1.1, 0.5),
			cf * C(-6 + i * 2, 9.55, -2.85),
			if i % 2 == 0 then roof else Theme.RoofStripe,
			M.Fabric
		)
		b.CastShadow = false
	end
	-- Big sign above the roof's back edge.
	local sign = Build.Deco(m, {
		Size = V(13, 3.6, 0.6),
		CFrame = cf * C(0, 13.8, 4),
		Color = roof:Lerp(hex("#3B2A1A"), 0.15),
		Material = M.WoodPlanks,
		Name = "Sign",
	})
	PlotDressing.BigText(sign, Enum.NormalId.Front, title)
	PlotDressing.BigText(sign, Enum.NormalId.Back, title)
	for _, t in { { 0, 2.05, 13.8, 0.5 }, { 0, -2.05, 13.8, 0.5 }, { -6.65, 0, 0.5, 3.6 }, { 6.65, 0, 0.5, 3.6 } } do
		Build.Deco(
			m,
			{ Size = V(t[3], t[4], 0.8), CFrame = sign.CFrame * C(t[1], t[2], 0), Color = Theme.Colors.Cream }
		)
	end
	-- Icon prop on top (asset first).
	local iconCf = cf * C(0, 15.9, 4)
	if not Props.Asset(m, icon, iconCf, 4.5, Random.new(#title)) then
		local maker = ICONS[icon]
		if maker then
			maker(m, iconCf, roof)
		end
	end
	local glint = Build.Deco(m, { Size = V(5, 4, 3), CFrame = iconCf * C(0, 2.2, 0), Transparency = 1, Name = "Glint" })
	glint.CanQuery = false
	Theme.Effects.Sparkle(hex("#FFF6C8"), 3).Parent = glint
	return { counter = counter, sign = sign, model = m }
end

return Stalls
