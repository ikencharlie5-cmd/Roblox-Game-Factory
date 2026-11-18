--!strict
-- Map layout constants (studs, ground top y = 0). North = -Z.
--   Hub plaza at the origin (r = 80). 8 plots (128x128) in a ring at r = 270, the north gap is the forest road.
--   Greenleaf Meadow north of the ring (the only v1 wild zone): road -> hills/flowers -> lake + waterfall
--   at the back edge (brick cliff). Mossy Hollow / Waterfall Glade are cut until update 2.
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

-- v1: one wild zone. Config.Zones (gameplay, matched by Id) overrides Level/Cost on the ForestGate anchor.
Layout.Zones = {
	{ Id = "Meadow", Key = "MeadowEdge", Index = 1, ZMin = -800, ZMax = -370, HalfWidth = 210, RequiredLevel = 1, Cost = 0 },
} :: { ZoneDef }

-- Lake + waterfall at the meadow's back edge; the road ends facing them (the zone's focal point).
Layout.Lake = { Center = Vector3.new(40, 0, -680), Radius = 46 }
Layout.WaterfallTop = Vector3.new(40, 56, -784)
Layout.RoadEndZ = -612

-- Terrain extent (ground plates cover MinZ..MaxZ+127).
Layout.MinX, Layout.MaxX = -640, 640
Layout.MinZ, Layout.MaxZ = -1024, 640

return Layout
