# Plant Zoo (working title) — decisions made without asking

| Decision | Why |
|---|---|
| Name: 🌱 Sprout Zoo (Charlie approved) | Charlie OK'd spec |
| Sell Super Luck pass (399 R$) | Charlie OK'd spec |
| Weather: keep gameplay's workspace `Weather` attr + WeatherChanged RE as built | Audio already supports both; no change |
| Weather names: Config keeps "Snow Flurry"/"Bloom Season"; no audio change | MusicDirector strips spaces, so names already match |
| Biome ambience: [audio] map "Fungus Cave"/"Frost Garden" in Sounds.BiomeAmbience | Smallest fix; pads already carry full gameplay names |
| Pad `Biome` attr: already set by PlotService/WorldService | Audio's request is done |
| Music/SFX toggles: client-only, default on, not saved | Simple; save is v2 |
| Restock: shared seeded draws, per-player luck maps to rarity | Same shop for all, Super Luck pass still visibly pays |
| Starfall re-rolls on day servers | Keeps "night only" true with a global schedule |
| Removing a growing plant returns the seed, growth lost | Simple, no exploit; grown creatures keep everything |
| Rotation: Theme.CellOffset accepts degrees or quarter turns (Graphics fix) | Resolves UI/server mismatch with no other changes |
| Hope Shop = tab in Shop window + hub prompt | Keeps left bar uncluttered |
| Creature sell: single sell with confirm, no bulk sell in v1 | Prevents accidental loss of rare creatures |
| Pad order: keep formula (col 1 = local -X); [gameplay] fix notes wording only | Tags and fallback already agree |
| One Tip Jar per pad | Matches spec; more coin moments |
| Pond tunnel deferred to v2; glass tank for v1 | Simple, reads well |
| Weather particles + creature bob server-side for v1 | Works from rojo build; move to client only if lag shows |
