# Wildworld
by Chiken Studios

## How to play
TBD

## How to publish
1. Download `wildworld.rbxl` from the latest GitHub Actions run (Artifacts), or run
   `rojo build games/wildworld -o wildworld.rbxl`.
2. Open it in Roblox Studio → File → Publish to Roblox.
3. Game Settings → Security → turn on **Studio Access to API Services** (for saving).

## Charlie TODO
- [ ] UI icons (one pack, one style, PNG with transparent background): Collection, Breed, Build, Journal, Inventory, Park, Shop, Daily, Visit, Settings, Coins, RP, Quest, Feed, Pet, Inspect, Capture, Hatch, Rotate, Delete, Grid, Place, Exit, mutation badges (Golden, Albino, Crystal, Glowing) and build categories. Upload, then paste ids into `Style.Icons` in `src/client/UI/Style.luau` (letter badges show until then).
- [ ] Create Game Passes / Dev Products and paste their IDs into `src/shared/Config.luau`
- [ ] Audio: in Studio Toolbox > Audio, fill every `Id = 0` in `src/shared/Sounds.luau` (creature voices, egg crack, feed munch, mutation riser, night/waterfall/forest one-shots). Search terms in `notes/audio.md`. Missing ones are just silent.
- [ ] Audio: listen to and keep or swap the "verify" tracks (Music_Forest, Music_Glade, Music_Menu, LevelUp) and check `rbxasset://sounds/swoosh.wav` plays.
- [ ] (Optional) Waterfall: upload a vertical water-streak texture and note its id here; Graphics then adds a scrolling Beam to `src/server/World/Waterfall.luau` (part sheets + particles work fine without it).
