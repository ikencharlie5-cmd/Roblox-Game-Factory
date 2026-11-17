# Gameplay notes (Sprout Zoo) — WORK IN PROGRESS, contract first

(Full remote list is being written; this section is the world contract and will not change.)

## What Gameplay EXPECTS from Graphics (WorldService)
CollectionService tags + Attributes (all optional; gameplay falls back to computed positions and warns):
- `Plot` — one Part/Model per plot, Attribute `PlotIndex` (1..6). Its pivot = plot centre on ground, LookVector pointing to the hub.
- `ExhibitPad` — the 20x20 ground part of each pad, Attributes `PlotIndex`, `PadIndex` (1..9, row-major from the entrance-left). Top surface = planting surface.
- `TipJar` — one part per pad, Attributes `PlotIndex`, `PadIndex`. Server listens to `.Touched` (needs CanTouch=true).
- `PlotSpawn` — optional part per plot, Attribute `PlotIndex` (where the owner spawns/visitors land).
- `ShopStand` (Seed Shop), `HopeShop`, `UpgradeStand`, `ReleaseAltar` (World Reserve), `DailyStand` (optional) — hub parts; server adds a ProximityPrompt that opens the screen on the client.
Fallback if missing: plot i at angle (i-1)*60 deg, radius 170; pad (row,col) at plot pivot + ((col-2)*24, 0, (row-2)*24).
