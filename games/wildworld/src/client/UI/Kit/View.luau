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
		local dir = Vector3.new(-0.55, 0.42, -1).Unit -- 3/4 front view (front = -Z)
		local t = { model = m, cf = CFrame.lookAt(center + dir * dist, center), center = center, dist = dist }
		templates[k] = t
		return t
	end

	local SKIP = { Silhouette = true, Genes = true, Mutations = true, Stage = true, Rarity = true }

	-- props extras: Silhouette (black tint), Genes, Mutations, Stage, Rarity (fallback badge colour).
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
