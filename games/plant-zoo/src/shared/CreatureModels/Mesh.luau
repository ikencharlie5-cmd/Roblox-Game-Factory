--!strict
-- Mesh creature hook: the Grown stage clones ReplicatedStorage.Assets.Creatures.<Species> when present.
-- The clone is fitted to Mesh.Height * scale tall (max footprint Mesh.Width * scale), bottom-center at the
-- feet, front = -Z, and every part is welded to Body so the Root/Bob contract and Motion keep working.
-- Parts without a texture get the Skin attributes (tinted by ApplyLook like primitives). Textured
-- MeshParts / parts with a SurfaceAppearance ignore Color, so they get attribute Textured = true and
-- ApplyLook draws a tinted translucent "shell" copy over them instead (see Effects.luau).
local Assets = require(script.Parent.Parent.Theme.Assets)

local Mesh = {}

-- Grown height (studs) at rarity scale 1. Common = 3 studs ... Secret (x1.65) ≈ 5 studs.
Mesh.Height = 3
Mesh.Width = 4

function Mesh.Source(species: string): Instance?
	return Assets.Find("Creatures", species)
end

local function isTextured(p: BasePart): boolean
	if p:FindFirstChildOfClass("SurfaceAppearance") then
		return true
	end
	return p:IsA("MeshPart") and (p :: MeshPart).TextureID ~= ""
end

-- Adds the species mesh to `model`, welded to `body` (at the feet). Returns false if there is no asset.
function Mesh.Attach(model: Model, body: BasePart, species: string, scale: number): boolean
	local src = Mesh.Source(species)
	if not src then
		return false
	end
	local fitted, parts = Assets.Fit(src, {
		Height = Mesh.Height * scale,
		MaxWidth = Mesh.Width * scale,
		Feet = body.CFrame,
		Anchored = true,
	})
	if #parts == 0 then
		fitted:Destroy()
		return false
	end
	for _, d in fitted:GetDescendants() do
		if d:IsA("Humanoid") or d:IsA("AnimationController") then
			d:Destroy()
		end
	end
	for _, p in parts do
		p.CanCollide = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = true
		if isTextured(p) then
			p:SetAttribute("Textured", true)
		elseif p.Transparency < 1 then
			p:SetAttribute("Skin", true)
			p:SetAttribute("BaseColor", p.Color)
			p:SetAttribute("BaseMat", p.Material.Name)
		end
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = p
		w.Parent = p
		p.Anchored = false
	end
	fitted.Name = "Mesh"
	fitted.Parent = model
	model:SetAttribute("Mesh", true)
	return true
end

return Mesh
