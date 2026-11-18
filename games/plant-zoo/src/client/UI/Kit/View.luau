--!strict
-- Creature pictures: a ViewportFrame with the real model from Shared/CreatureModels.
-- Each species+stage is built once and cached; viewports get a cheap Clone. Silhouette = black
-- tint for undiscovered Index entries.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(Kit: any, _Style: any)
	local CreatureModels: any = nil
	local templates: { [string]: { model: Model, cf: CFrame } } = {}

	local function template(species: string, stage: string?): { model: Model, cf: CFrame }?
		local key = species .. "|" .. (stage or "Grown")
		if templates[key] then
			return templates[key]
		end
		if CreatureModels == nil then
			local ok, mod = pcall(function()
				return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CreatureModels")) :: any
			end)
			CreatureModels = if ok then mod else false
		end
		if not CreatureModels then
			return nil
		end
		local ok, model = pcall(CreatureModels.Build, species, stage or "Grown")
		if not ok or typeof(model) ~= "Instance" then
			warn("[UI] creature view failed:", species, model)
			return nil
		end
		local m = model :: Model
		-- Viewports don't render particles/lights/sounds: strip them so clones stay light.
		for _, d in m:GetDescendants() do
			if d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Sound") or d:IsA("Script") then
				d:Destroy()
			end
		end
		m:PivotTo(CFrame.new())
		local box, size = m:GetBoundingBox()
		local radius = math.max(size.X, size.Y, size.Z) * 0.62
		local dist = radius / math.tan(math.rad(15)) * 1.05
		local center = box.Position
		-- 3/4 view from the front (front = -Z), slightly above.
		local dir = Vector3.new(-0.55, 0.42, -1).Unit
		local cf = CFrame.lookAt(center + dir * dist, center)
		local t = { model = m, cf = cf }
		templates[key] = t
		return t
	end

	local SKIP = { Silhouette = true }

	function Kit.CreatureView(
		parent: Instance?,
		species: string,
		stage: string?,
		props: { [string]: any }?
	): ViewportFrame
		local p = props or {}
		local vp = Kit.Make("ViewportFrame", {
			Name = "CreatureView",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Ambient = Color3.new(1, 1, 1),
			LightColor = Color3.new(1, 1, 1),
			LightDirection = Vector3.new(-1, -1, -1),
		})
		if p.Silhouette then
			vp.ImageColor3 = Color3.fromHex("#2B1D14")
			vp.ImageTransparency = 0.25
		end
		Kit.Apply(vp, p, SKIP)
		local t = template(species, stage)
		if t then
			local cam = Kit.Make("Camera", { FieldOfView = 30, CFrame = t.cf }, vp)
			vp.CurrentCamera = cam
			t.model:Clone().Parent = vp
		end
		vp.Parent = parent
		return vp
	end
end
