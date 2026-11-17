# Open questions

- [audio] Weather: please set `workspace:SetAttribute("Weather", "<Rain|Heatwave|SnowFlurry|BloomSeason|Thunderstorm|Starfall>")` ("" when clear) — MusicDirector also listens to a `WeatherChanged` RE (string or table with Name). (built: both supported)
- [audio] Pads: please set Attribute `Biome` on each `ExhibitPad` tagged part (Meadow/Pond/Desert/Canopy/Fungus/Frost) so biome ambience works. (built: defaults to Meadow)
- [audio] Settings toggle: UI sets LocalPlayer Attributes `MusicOn`/`SFXOn` (bool); should gameplay save them in data? (built: client-only, default on)
- [gameplay] Spec says restock is "same stock every server" but also "rarity weights x luck" (luck is per player). (built: shared seeded draws per slot; each player's luck maps the same draw to a rarity, so lucky players see better seeds in the same slots)
- [gameplay] Starfall is "night only" but weather is a global cross-server schedule while day/night is per server. (built: weather type picked from a global seed; if it's Starfall and this server's Lighting.ClockTime is day, it re-rolls)
- [gameplay] Removing a still-growing plant from the grid: keep progress or not? (built: returns the seed to inventory, growth lost; grown creatures keep everything)
