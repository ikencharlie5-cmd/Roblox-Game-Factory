# Open questions

- [audio] Weather: please set `workspace:SetAttribute("Weather", "<Rain|Heatwave|SnowFlurry|BloomSeason|Thunderstorm|Starfall>")` ("" when clear) — MusicDirector also listens to a `WeatherChanged` RE (string or table with Name). (built: both supported)
- [audio] Pads: please set Attribute `Biome` on each `ExhibitPad` tagged part (Meadow/Pond/Desert/Canopy/Fungus/Frost) so biome ambience works. (built: defaults to Meadow)
- [audio] Settings toggle: UI sets LocalPlayer Attributes `MusicOn`/`SFXOn` (bool); should gameplay save them in data? (built: client-only, default on)
