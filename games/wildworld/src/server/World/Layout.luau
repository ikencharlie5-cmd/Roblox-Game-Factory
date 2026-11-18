--!strict
-- Map layout constants (studs, ground top y = 0). North = -Z.
--   Hub plaza at the origin (r = 80). 8 plots (128x128) in a ring at r = 270, the north gap is the forest road.
--   Greenleaf Forest north of the ring: Meadow Edge -> Mossy Hollow -> Waterfall Glade.
local Layout = {}

Layout.PlazaRadius = 80
Layout.PlotCount = 8
Layout.PlotRing = 270
Layout.PlotSize = 128
Layout.PlotFloorTop = 0.5

-- Plot i centre angle (radians, x = cos, z = sin). North (-Z) is -90°; plots sit 22.5° either side of it.
function Layout.PlotAngle(i: number): number
	return math.rad(-90 + 22.5 + (i - 1) * 45)
end

-- Plot pivot: centre of the floor top; -Z (LookVector) points at the hub = entrance side.
function Layout.PlotCFrame(i: number): CFrame
	local a = Layout.PlotAngle(i)
	local pos = Vector3.new(math.cos(a) * Layout.PlotRing, Layout.PlotFloorTop, math.sin(a) * Layout.PlotRing)
	return CFrame.lookAt(pos, Vector3.new(0, Layout.PlotFloorTop, 0))
end

Layout.ForestGateZ = -370
Layout.RoadWidth = 14

export type ZoneDef = {
	Id: string, -- gameplay id (Config.Zones[i].Id): written to every Zone attribute gameplay reads
	Key: string, -- Theme.Zones / audio key
	Index: number,
	ZMin: number,
	ZMax: number,
	HalfWidth: number,
	RequiredLevel: number,
	Cost: number,
}

-- Zone gates default to the spec numbers; Config.Zones (gameplay, matched by Id) overrides Level/Cost.
Layout.Zones = {
	{ Id = "Meadow", Key = "MeadowEdge", Index = 1, ZMin = -640, ZMax = -370, HalfWidth = 210, RequiredLevel = 1, Cost = 0 },
	{ Id = "Hollow", Key = "MossyHollow", Index = 2, ZMin = -900, ZMax = -640, HalfWidth = 200, RequiredLevel = 4, Cost = 1000 },
	{ Id = "Glade", Key = "WaterfallGlade", Index = 3, ZMin = -1160, ZMax = -900, HalfWidth = 200, RequiredLevel = 8, Cost = 5000 },
} :: { ZoneDef }

Layout.Lake = { Center = Vector3.new(40, 0, -1040), Radius = 46 }
Layout.WaterfallTop = Vector3.new(40, 56, -1144)

-- Terrain extent.
Layout.MinX, Layout.MaxX = -640, 640
Layout.MinZ, Layout.MaxZ = -1280, 640

return Layout
