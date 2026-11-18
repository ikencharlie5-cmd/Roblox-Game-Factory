# 🦊 Wildworld [🥚 BREEDING!]
by Chiken Studios

**Game description (for the Roblox page):**
Hatch, catch and breed cute original creatures! 🥚 Explore Greenleaf Forest, befriend wild Lumibuns, Mossbacks, Emberfoxes, Pebblehorns and Thornstags, then breed them for rare Golden, Albino, Crystal and Glowing mutations. ✨ Build beautiful habitats, earn coins from visitors, and show off your park to friends. Can you breed a Gilded Crystal?

**Icon / thumbnail ideas:**
- Icon: a big-eyed Emberfox popping out of a cracked golden egg, sparkles, bright teal background.
- Thumb 1: player's park with waterfall + 5 creatures, "BREED RARE MUTATIONS!" text.
- Thumb 2: Golden vs Crystal vs Albino Lumibun side by side with rarity labels.
- Thumb 3: catching a wild Thornstag in Waterfall Glade with the net ring.

## How to play
1. **Hatch** your starter egg on your plot and **feed** your creature (stand close, tap Feed).
2. Open **Build**, place items in your habitat — a better habitat rating = more visitor coins (up to 2×).
3. Walk to **Greenleaf Forest**, throw bait at a wild creature, then hold and release the net in the ring to **catch** it.
4. Open **Breed** with two of the same species → wait for the egg → hatch. Your first bred egg is always **Golden**.
5. Unlock **Mossy Hollow** and **Waterfall Glade** from the Park window or at the forest gates for new species and rarer finds.
6. Claim your **Daily** reward, finish quests, **Visit** and **Like** other players' parks.

PC: WASD move, R/Q/E rotate, X delete, G grid, Esc exit build. Mobile/console: on-screen buttons.

## Monetization (create these on the Roblox Creator Dashboard)
| Type | Name | Price (R$) | What it does |
|---|---|---|---|
| Game Pass | VIP | 399 | Gold VIP name tag + chat tag, VIP decor set, +1 daily quest reroll, +10% coins |
| Game Pass | Extra Incubator | 199 | +1 egg slot |
| Game Pass | Auto-Feeder | 149 | Food stations refill automatically |
| Game Pass | Crystal Grotto Decor Pack | 249 | Crystal-themed habitat decor |
| Dev Product | Instant Hatch (≤2 min) | 15 | Hatch an egg now |
| Dev Product | Instant Hatch (≤5 min) | 25 | Hatch an egg now |
| Dev Product | Instant Hatch (any) | 49 | Hatch an egg now |
| Dev Product | 2,500 Coins | 49 | Coins |
| Dev Product | 10,000 Coins | 149 | Coins |
| Dev Product | 40,000 Coins | 449 | Coins |
| Dev Product | Starter Pack | 99 | Theme decor + creature bow + 2,000 coins (one-time) |

Nothing for sale changes mutation or capture odds.

## How to publish
1. Download `wildworld.rbxl` from the latest GitHub Actions run (Artifacts), or run
   `rojo build games/wildworld -o wildworld.rbxl`.
2. Open it in Roblox Studio → File → Publish to Roblox.
3. Game Settings → Security → turn on **Studio Access to API Services** (for saving).

## Charlie TODO
- [ ] UI icons (one pack, one style, PNG with transparent background): Collection, Breed, Build, Journal, Inventory, Park, Shop, Daily, Visit, Settings, Coins, RP, Quest, Feed, Pet, Inspect, Capture, Hatch, Rotate, Delete, Grid, Place, Exit, mutation badges (Golden, Albino, Crystal, Glowing) and build categories. Upload, then paste ids into `Style.Icons` in `src/client/UI/Style.luau` (letter badges show until then).
- [ ] Create the 4 Game Passes + 7 Dev Products from the table above, then paste each ID into `Config.GamePasses` / `Config.DevProducts` in `src/shared/Config.luau` (Id 0 = shop button disabled)
- [x] Studio playtest by Claude: hatch → feed → place tree → catch → breed all work, no script errors (saving untested until published)
- [ ] Try a 2-player Team Test (visit + Like) and the phone emulator
- [ ] Audio: in Studio Toolbox > Audio, fill every `Id = 0` in `src/shared/Sounds.luau` (creature voices, egg crack, feed munch, mutation riser, night/waterfall/forest one-shots). Search terms in `notes/audio.md`. Missing ones are just silent.
- [ ] Audio: listen to and keep or swap the "verify" tracks (Music_Forest, Music_Glade, Music_Menu, LevelUp).
- [ ] (Optional) Waterfall: upload a vertical water-streak texture and note its id here; Graphics then adds a scrolling Beam to `src/server/World/Waterfall.luau` (part sheets + particles work fine without it).
