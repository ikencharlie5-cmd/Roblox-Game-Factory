--!strict
-- Every sound in the game (owned by the Audio department). Id 0 = not chosen yet.
export type SoundDef = { Id: number, Volume: number, Kind: "sfx" | "music", Looped: boolean? }

local Sounds: { [string]: SoundDef } = {
	Click = { Id = 0, Volume = 0.5, Kind = "sfx" },
	Cash = { Id = 0, Volume = 0.6, Kind = "sfx" },
	Error = { Id = 0, Volume = 0.5, Kind = "sfx" },
	MainTheme = { Id = 0, Volume = 0.3, Kind = "music", Looped = true },
}

return Sounds
