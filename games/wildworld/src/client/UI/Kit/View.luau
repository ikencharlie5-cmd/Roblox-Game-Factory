--!strict
-- Creature pictures: a static ViewportFrame (guide §4 performance rules: no WorldModel, no
-- per-frame spin in grids, anchored display clone with scripts/emitters stripped).
-- Builder lookup (Graphics owns it): Shared/CreatureBuilder | CreatureBlueprints | CreatureModels,
-- function Build | BuildCreature | Create | Make (species, {genes, mutations, stage}) -> Model.
-- If no builder exists yet, a code-drawn letter badge is shown instead.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(Kit: any, Style: any)
	local builder: any = nil
	local templates: { [string]: { model: Model, cf: CFrame, center: Vector3, dist: number } | false } = {}

	local function findBuilder(): any
		if builder ~= nil then
			return builder
		end
		builder = false
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		if not shared then
			return builder
		end
		for _, name in { "CreatureBuilder", "CreatureBlueprints", "CreatureModels" } do
			local m = shared:FindFirstChild(name)
			if m and m:IsA("ModuleScript") then
				local ok, mod = pcall(require, m)
				if ok and type(mod) == "table" then
					for _, fn in { "Build", "BuildCreature", "Create", "Make" } do
						if type(mod[fn]) == "function" then
							builder = mod[fn]
							return builder
						end
					end
				end
			end
		end
		return builder
	end

	local function key(species: string, o: { [string]: any }): string
		local muts = if type(o.mutations) == "table" then table.concat(o.mutations, ",") else ""
		return species .. "|" .. tostring(o.stage or "") .. "|" .. tostring(o.genes or "") .. "|" .. muts
	end

	local function template(species: string, o: { [string]: any })
		local k = key(species, o)
		local cached = templates[k]
		if cached ~= nil then
			return cached
		end
		local fn = findBuilder()
		if not fn then
			return false
		end
		local ok, model = pcall(fn, species, { genes = o.genes, mutations = o.mutations, stage = o.stage })
		if not ok or typeof(model) ~= "Instance" or not (model :: Instance):IsA("Model") then
			warn("[UI] creature view failed:", species, model)
			templates[k] = false
			return false
		end
		local m = model :: Model
		for _, d in m:GetDescendants() do
			if
				d:IsA("ParticleEmitter")
				or d:IsA("Light")
				or d:IsA("Sound")
				or d:IsA("LuaSourceContainer")
				or d:IsA("Constraint")
				or d:IsA("Beam")
				or d:IsA("Trail")
			then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		m:PivotTo(CFrame.new())
		local box, size = m:GetBoundingBox()
		local radius = math.max(size.X, size.Y, size.Z) * 0.62
		local dist = radius / math.tan(math.rad(15)) * 1.05
		local center = box.Position
		-- Brick 3/4 front view (STUDS_STYLE_GUIDE §4.4): FOV 30, yaw 25 deg, shows head top + front studs.
		local yaw = math.rad(25)
		local dir = Vector3.new(-math.sin(yaw), 0.42, -math.cos(yaw)).Unit -- front = -Z
		local t = { model = m, cf = CFrame.lookAt(center + dir * dist, center), center = center, dist = dist }
		templates[k] = t
		return t
	end

	local SKIP = { Silhouette = true, Genes = true, Mutations = true, Stage = true, Rarity = true, Burst = true }

	-- Blue sunburst backdrop (#3D8FE0 -> #7EC4FF, STUDS_STYLE_GUIDE "For UI"): linear gradient + soft
	-- centre glow + 4 crossed rays (8 spokes). Rays stay inside the inscribed circle, so no clipping needed.
	local BURST_EDGE = Color3.fromHex("#3D8FE0")
	local BURST_MID = Color3.fromHex("#7EC4FF")
	function Kit.Sunburst(parent: Instance?, props: { [string]: any }?): Frame
		local f = Kit.Make("Frame", { Name = "Sunburst", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 })
		Kit.Corner(f, 12)
		Kit.Make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, BURST_EDGE),
				ColorSequenceKeypoint.new(0.5, BURST_MID),
				ColorSequenceKeypoint.new(1, BURST_EDGE),
			}),
		}, f)
		local fade = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		for i = 0, 3 do
			local ray = Kit.Make("Frame", {
				Name = "Ray",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.16, 0.98),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Rotation = i * 45,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
			}, f)
			Kit.Make("UIGradient", { Rotation = 90, Transparency = fade }, ray)
		end
		Kit.Apply(f, props)
		for _, d in f:GetChildren() do
			if d:IsA("GuiObject") then
				d.ZIndex = f.ZIndex
			end
		end
		f.Parent = parent
		return f
	end

	-- Puts a sunburst behind `view` in the same parent, matching its placement.
	local function burstBehind(view: GuiObject, parent: Instance?)
		Kit.Sunburst(parent, {
			AnchorPoint = view.AnchorPoint,
			Position = view.Position,
			Size = view.Size,
			ZIndex = math.max(1, view.ZIndex - 1),
			LayoutOrder = view.LayoutOrder,
		})
	end

	-- props extras: Silhouette (black tint), Genes, Mutations, Stage, Rarity (fallback badge colour),
	-- Burst (blue sunburst backdrop placed behind the view in the same parent).
	function Kit.CreatureView(parent: Instance?, species: string, props: { [string]: any }?): GuiObject
		local p = props or {}
		local t = template(species, { genes = p.Genes, mutations = p.Mutations, stage = p.Stage })
		if not t then
			local holder = Kit.Make("Frame", { Name = "CreatureView", BackgroundTransparency = 1 })
			Kit.Apply(holder, p, SKIP)
			local pal = if p.Silhouette then Style.Pal.Stone else Style.RarityPalette(p.Rarity or "Common")
			Kit.CodeBadge(holder, if p.Silhouette then "?" else string.sub(species, 1, 2), pal, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.7, 0.7),
			})
			if p.Burst and not p.Silhouette then
				burstBehind(holder, parent)
			end
			holder.Parent = parent
			return holder
		end
		local vp = Kit.Make("ViewportFrame", {
			Name = "CreatureView",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Ambient = Color3.new(1, 1, 1),
			LightColor = Color3.new(1, 1, 1),
			LightDirection = Vector3.new(-1, -1, -1),
		})
		if p.Silhouette then
			vp.ImageColor3 = Color3.fromHex("#1A1A2E")
		end
		Kit.Apply(vp, p, SKIP)
		local cam = Kit.Make("Camera", { FieldOfView = 30, CFrame = t.cf }, vp)
		vp.CurrentCamera = cam
		t.model:Clone().Parent = vp
		vp:SetAttribute("Dist", t.dist)
		vp:SetAttribute("Center", t.center)
		if p.Burst and not p.Silhouette then
			burstBehind(vp, parent)
		end
		vp.Parent = parent
		return vp
	end

	-- Orbit the camera of a CreatureView (Inspect preview only - never in grids).
	function Kit.OrbitView(vp: Instance, angleDeg: number)
		if not vp:IsA("ViewportFrame") then
			return
		end
		local cam = vp.CurrentCamera
		local dist = vp:GetAttribute("Dist")
		local center = vp:GetAttribute("Center")
		if not cam or type(dist) ~= "number" or typeof(center) ~= "Vector3" then
			return
		end
		local a = math.rad(angleDeg)
		local dir = Vector3.new(math.sin(a) * 1.15, 0.42, -math.cos(a) * 1.15).Unit
		cam.CFrame = CFrame.lookAt(center + dir * dist, center)
	end
end
