--!strict
-- Static brick-model pictures (guide §4 performance rules): one ViewportFrame per icon, no WorldModel,
-- no per-frame updates. Templates are built once per name and cloned (cache), camera framed once.
--   Kit.ModelView(parent, nameOrModel, props) -> ViewportFrame
--   Kit.HasIconModel(name) -> boolean   (Theme.IconModels.Has, false if Theme is missing)
-- Icon models come from Shared/Theme/IconModels (Graphics owns them; notes/graphics.md).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Template = { model: Model, cf: CFrame }

return function(Kit: any, _Style: any)
	local iconModels: any = nil
	local templates: { [string]: Template | false } = {}

	local function lib(): any
		if iconModels ~= nil then
			return iconModels
		end
		iconModels = false
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local theme = shared and shared:FindFirstChild("Theme")
		local mod = theme and theme:FindFirstChild("IconModels")
		if mod and mod:IsA("ModuleScript") then
			local ok, res = pcall(require, mod)
			if ok and type(res) == "table" and type(res.Build) == "function" then
				iconModels = res
			else
				warn("[UI] IconModels failed to load:", res)
			end
		end
		return iconModels
	end

	-- Strip anything a viewport can't use, anchor, and frame a 3/4 front camera (front = -Z).
	local function prepare(m: Model): Template
		for _, d in m:GetDescendants() do
			if
				d:IsA("ParticleEmitter")
				or d:IsA("Light")
				or d:IsA("Sound")
				or d:IsA("LuaSourceContainer")
				or d:IsA("Beam")
				or d:IsA("Trail")
			then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		local box, size = m:GetBoundingBox()
		local radius = size.Magnitude * 0.5
		local dist = radius / math.tan(math.rad(15)) * 1.02
		local center = box.Position
		local yaw = math.rad(22)
		local dir = Vector3.new(-math.sin(yaw), 0.35, -math.cos(yaw)).Unit
		return { model = m, cf = CFrame.lookAt(center + dir * dist, center) }
	end

	local function template(name: string): Template | false
		local cached = templates[name]
		if cached ~= nil then
			return cached
		end
		local L = lib()
		local t: Template | false = false
		if L then
			local ok, m = pcall(L.Build, name)
			if ok and typeof(m) == "Instance" and (m :: Instance):IsA("Model") then
				t = prepare(m :: Model)
			elseif not ok then
				warn("[UI] icon model failed:", name, m)
			end
		end
		templates[name] = t
		return t
	end

	function Kit.HasIconModel(name: string): boolean
		local L = lib()
		if not L or type(L.Has) ~= "function" then
			return false
		end
		local ok, has = pcall(L.Has, name)
		return ok and has == true
	end

	-- source: IconModels name, or a Model (framed once, not cached). Returns nil if nothing to show.
	function Kit.ModelView(parent: Instance?, source: string | Model, props: { [string]: any }?): ViewportFrame?
		local t: Template | false
		if typeof(source) == "Instance" then
			t = prepare((source :: Model):Clone())
		else
			t = template(source :: string)
		end
		if not t then
			return nil
		end
		local vp = Kit.Make("ViewportFrame", {
			Name = "ModelView",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Ambient = Color3.fromRGB(200, 200, 205),
			LightColor = Color3.new(1, 1, 1),
			LightDirection = Vector3.new(-0.6, -1, -0.8),
		})
		Kit.Apply(vp, props)
		local cam = Kit.Make("Camera", { FieldOfView = 30, CFrame = t.cf }, vp)
		vp.CurrentCamera = cam
		t.model:Clone().Parent = vp
		vp.Parent = parent
		return vp
	end
end
