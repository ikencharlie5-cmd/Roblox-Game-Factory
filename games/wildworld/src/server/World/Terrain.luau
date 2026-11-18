--!strict
-- Brick ground (STUDS_STYLE_GUIDE §6). Studs can't render on Terrain, so the playable area is studded
-- Plastic plates: 256x4x256 ground tiles (top y = 0) in a GrassTop/GrassAlt checker, path plates, terraced
-- brick hills, a sunken lake basin and the Glade brick cliff. Everything walkable lives in
-- Workspace.World.Ground (Scatter raycasts against it). Smooth Terrain is cleared.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Layout = require(script.Parent.Layout)

local Kit, P = Theme.Kit, Theme.Colors
local V = Vector3.new
local Terrain = {}

local TILE = 256
local DEPTH = 12
local ground: Folder? = nil

-- Folder with every walkable ground part (plates, hills, cliff, basin).
function Terrain.Folder(): Folder
	if not ground then
		ground = Kit.Folder(Kit.Folder(Workspace, "World"), "Ground")
	end
	return ground :: Folder
end

local function plate(size: Vector3, cf: CFrame, color: Color3, name: string?): Part
	local p = Kit.Brick(Terrain.Folder(), size, cf, color, "Top", true)
	p.Name = name or "Ground"
	p.CastShadow = false
	return p
end

function Terrain.Setup()
	pcall(function()
		Workspace.Terrain:Clear()
	end)
	local base = Workspace:FindFirstChild("Baseplate")
	if base then
		base:Destroy()
	end
	local floor = Instance.new("Part")
	floor.Name = "SafetyFloor"
	floor.Anchored = true
	floor.Size = V(2048, 2, 2048)
	floor.CFrame = CFrame.new(0, -DEPTH - 3, -320)
	floor.Transparency = 1
	floor.CanQuery = false
	floor.CastShadow = false
	floor.Parent = Workspace
end

type Rect = { x0: number, x1: number, z0: number, z1: number }

-- Rect minus holes -> list of rects (recursive split around the first overlapping hole).
local function subtract(r: Rect, holes: { Rect }, out: { Rect })
	for _, h in holes do
		if h.x0 < r.x1 and h.x1 > r.x0 and h.z0 < r.z1 and h.z1 > r.z0 then
			local ix0, ix1 = math.max(r.x0, h.x0), math.min(r.x1, h.x1)
			local pieces = {
				{ x0 = r.x0, x1 = ix0, z0 = r.z0, z1 = r.z1 },
				{ x0 = ix1, x1 = r.x1, z0 = r.z0, z1 = r.z1 },
				{ x0 = ix0, x1 = ix1, z0 = r.z0, z1 = math.max(r.z0, h.z0) },
				{ x0 = ix0, x1 = ix1, z0 = math.min(r.z1, h.z1), z1 = r.z1 },
			}
			for _, pc in pieces do
				if pc.x1 - pc.x0 > 0.5 and pc.z1 - pc.z0 > 0.5 then
					subtract(pc, holes, out)
				end
			end
			return
		end
	end
	table.insert(out, r)
end

local function lakeRect(): Rect
	local c, r = Layout.Lake.Center, Layout.Lake.Radius + 2
	return { x0 = c.X - r, x1 = c.X + r, z0 = c.Z - r, z1 = c.Z + r }
end

-- Checkerboard of 256-stud studded plates, top at y = 0, with a hole for the lake basin.
-- Deep forest tiles use the darker forest greens.
function Terrain.Ground()
	local holes = { lakeRect() }
	local n = 0
	local ix = 0
	for x = Layout.MinX - 128, Layout.MaxX + 127, TILE do
		local iz = 0
		for z = Layout.MinZ, Layout.MaxZ + 127, TILE do
			local cz = z + TILE / 2
			local forest = cz < -660 and math.abs(x + TILE / 2) < 300
			local even = (ix + iz) % 2 == 0
			local col = if forest then (if even then P.ForestFloor else P.ForestAlt) else (if even then P.GrassTop else P.GrassAlt)
			local rects = {}
			subtract({ x0 = x, x1 = x + TILE, z0 = z, z1 = z + TILE }, holes, rects)
			for _, r in rects do
				local w, d = r.x1 - r.x0, r.z1 - r.z0
				plate(V(w, 4, d), CFrame.new((r.x0 + r.x1) / 2, -2, (r.z0 + r.z1) / 2), col)
			end
			n += 1
			if n % 8 == 0 then
				task.wait()
			end
			iz += 1
		end
		ix += 1
	end
end

-- Straight path plate (0.4 thick, top y = 0.4) between two ground points, with 1-stud PathEdge borders.
function Terrain.Road(parent: Instance, a: Vector3, b: Vector3, width: number)
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(V(mid.X, 0.2, mid.Z), V(b.X, 0.2, b.Z))
	local len = math.floor((b - a).Magnitude + width * 0.5 + 0.5)
	local w = math.floor(width + 0.5)
	local road = Kit.Brick(parent, V(w - 2, 0.4, len), cf, P.Path, "Top", true)
	road.Name = "Road"
	road.CastShadow = false
	road.CanQuery = true
	for _, side in { -1, 1 } do
		local e = Kit.Brick(parent, V(1, 0.4, len), cf * CFrame.new(side * (w / 2 - 0.5), 0, 0), P.PathEdge, "Top", true)
		e.Name = "RoadEdge"
		e.CastShadow = false
	end
end

-- Terraced brick hill (ziggurat) on the ground at (x, z). Levels step in `step` studs per side.
-- opts: Levels (<= 6), Height per level, Step, Rocky (Stone base + Dirt band). Returns the top centre.
function Terrain.Hill(x: number, z: number, w: number, d: number, rng: Random, opts: { Levels: number?, Height: number?, Step: number?, Rocky: boolean? }?): Vector3
	local o = opts or {}
	local levels = math.min(o.Levels or 4, 6)
	local step = o.Step or 6
	local y = 0
	local cx, cz = x, z
	for i = 1, levels do
		local h = o.Height or (rng:NextInteger(3, 6) * 0.4)
		local ww, dd = math.floor(w - (i - 1) * step * 2), math.floor(d - (i - 1) * step * 2)
		if ww < 4 or dd < 4 then
			break
		end
		local col = if i % 2 == 0 then P.GrassAlt else P.GrassTop
		if o.Rocky and i == 1 then
			col = P.Stone
		elseif o.Rocky and i == 2 then
			col = P.Dirt
		end
		plate(V(ww, h, dd), CFrame.new(cx, y + h / 2, cz), col, "Hill")
		y += h
		-- Small random offset per level so terraces aren't perfectly concentric.
		cx += rng:NextInteger(-1, 1) * math.floor(step / 3)
		cz += rng:NextInteger(-1, 1) * math.floor(step / 3)
	end
	return V(cx, y, cz)
end

-- Sunken lake basin (the ground has a hole here): blue floor 2.4 below ground, stone rim walls,
-- translucent water surface 0.4 below ground, sand plates around the rim.
function Terrain.Lake()
	local r = lakeRect()
	local w, d = r.x1 - r.x0 - 2, r.z1 - r.z0 - 2
	local cx, cz = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
	plate(V(w, 2, d), CFrame.new(cx, -3.4, cz), P.WaterDeep, "LakeFloor")
	for _, side in { -1, 1 } do
		plate(V(w + 2, 4, 1), CFrame.new(cx, -2, cz + side * (d / 2 + 0.5)), P.Stone, "LakeRim")
		plate(V(1, 4, d), CFrame.new(cx + side * (w / 2 + 0.5), -2, cz), P.Stone, "LakeRim")
		plate(V(w + 12, 0.4, 4), CFrame.new(cx, 0.2, cz + side * (d / 2 + 3)), P.Sand, "Sand")
		plate(V(4, 0.4, d + 4), CFrame.new(cx + side * (w / 2 + 3), 0.2, cz), P.Sand, "Sand")
	end
	local water = Kit.Tile(Kit.Folder(Kit.Folder(Workspace, "World"), "Water"), V(w, 0.4, d), CFrame.new(cx, -0.6, cz), P.Water)
	water.Name = "Water"
	water.Transparency = 0.35
	water.Reflectance = 0.1
	water.CastShadow = false
end

-- Backdrop: terraced brick ridges ringing the park and flanking the forest so there's never a void.
-- Returns hilltop points (trees go on some of them).
function Terrain.Backdrop(rng: Random): { Vector3 }
	local tops = {}
	local function ridge(x0: number, x1: number, z0: number, z1: number, seg: number)
		local alongX = (x1 - x0) >= (z1 - z0)
		local len = if alongX then x1 - x0 else z1 - z0
		local n = math.max(1, math.floor(len / seg))
		for k = 0, n - 1 do
			local t0, t1 = k / n, (k + 1) / n
			local x = if alongX then x0 + (x1 - x0) * (t0 + t1) / 2 else (x0 + x1) / 2
			local z = if alongX then (z0 + z1) / 2 else z0 + (z1 - z0) * (t0 + t1) / 2
			local sw = if alongX then len / n + 24 else x1 - x0
			local sd = if alongX then z1 - z0 else len / n + 24
			local top = Terrain.Hill(x, z, sw, sd, rng, { Levels = rng:NextInteger(4, 6), Height = rng:NextInteger(12, 24) * 0.4, Step = 9, Rocky = k % 2 == 0 })
			table.insert(tops, top)
		end
		task.wait()
	end
	ridge(-640, 640, 470, 600, 160) -- south
	ridge(470, 600, -460, 470, 160) -- east
	ridge(-600, -470, -460, 470, 160) -- west
	ridge(260, 600, -600, -470, 120) -- north-east shoulder
	ridge(-600, -260, -600, -470, 120) -- north-west shoulder
	ridge(250, 380, -1260, -600, 150) -- forest east flank
	ridge(-380, -250, -1260, -600, 150) -- forest west flank
	return tops
end

-- Invisible boundary walls: park box (x/z ±420) + forest corridor (x ±225, down to z -1240).
-- Keeps players off the backdrop ridges / out of the SafetyFloor pit. Clear of plots (r <= 360) and zones (x ±210).
function Terrain.Bounds(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Bounds"
	folder.Parent = parent
	local H, PB, F, S = 400, 420, 225, -1240
	local function wall(name: string, a: Vector2, b: Vector2)
		local w = Instance.new("Part")
		w.Name = name
		w.Anchored = true
		w.CanCollide = true
		w.CanTouch = false
		w.CanQuery = false
		w.CastShadow = false
		w.Transparency = 1
		local mid = (a + b) / 2
		w.Size = V(math.abs(b.X - a.X) + 4, H, math.abs(b.Y - a.Y) + 4)
		w.CFrame = CFrame.new(mid.X, H / 2 - 20, mid.Y)
		w.Parent = folder
	end
	wall("South", Vector2.new(-PB, PB), Vector2.new(PB, PB))
	wall("East", Vector2.new(PB, -PB), Vector2.new(PB, PB))
	wall("West", Vector2.new(-PB, -PB), Vector2.new(-PB, PB))
	wall("NorthEast", Vector2.new(F, -PB), Vector2.new(PB, -PB))
	wall("NorthWest", Vector2.new(-PB, -PB), Vector2.new(-F, -PB))
	wall("ForestEast", Vector2.new(F, S), Vector2.new(F, -PB))
	wall("ForestWest", Vector2.new(-F, S), Vector2.new(-F, -PB))
	wall("ForestEnd", Vector2.new(-F, S), Vector2.new(F, S))
end

-- Glade back wall: stepped brick cliff (Stone base, Dirt band, studded grass cap) the waterfall pours over,
-- plus a raised stream channel from the cliff foot into the lake.
function Terrain.Cliff()
	local top = Layout.WaterfallTop
	for x = -200, 200, 40 do
		local h = math.floor((top.Y + math.abs(x - top.X) * 0.12) / 2.4 + 0.5) * 2.4
		local zf = -1190
		plate(V(40, h * 0.5, 90), CFrame.new(x, h * 0.25, zf), P.Stone, "Cliff")
		plate(V(40, h * 0.5 - 2.4, 90), CFrame.new(x, h * 0.75 - 1.2, zf), P.Dirt, "Cliff")
		plate(V(40, 2.4, 90), CFrame.new(x, h - 1.2, zf - 1), if (x / 40) % 2 == 0 then P.GrassTop else P.GrassAlt, "CliffTop")
	end
	-- Boulder stacks flanking the falls.
	for _, s in { { -30, 30, 26 }, { 32, 26, 24 } } do
		local bx = top.X + s[1]
		plate(V(s[3], s[2], 20), CFrame.new(bx, s[2] / 2, -1142), P.StoneDark, "Boulder")
		plate(V(s[3] - 8, 4.8, 14), CFrame.new(bx, s[2] + 2.4, -1142), P.Stone, "Boulder")
	end
	-- Stream channel: stone rims + water strip on top of the ground from the falls to the lake edge.
	local z0, z1 = -1140, Layout.Lake.Center.Z - Layout.Lake.Radius - 2
	local len, zc = z0 - z1, (z0 + z1) / 2
	for _, side in { -1, 1 } do
		plate(V(2, 1.2, math.abs(len)), CFrame.new(top.X + side * 10, 0.6, zc), P.Stone, "StreamRim")
	end
	local water = Kit.Tile(Kit.Folder(Kit.Folder(Workspace, "World"), "Water"), V(18, 0.4, math.abs(len)), CFrame.new(top.X, 0.6, zc), P.Water)
	water.Name = "Water"
	water.Transparency = 0.35
	water.Reflectance = 0.1
	water.CastShadow = false
	plate(V(18, 0.4, math.abs(len)), CFrame.new(top.X, 0.2, zc), P.WaterDeep, "StreamBed")
end

return Terrain
