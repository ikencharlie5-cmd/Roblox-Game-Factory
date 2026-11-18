--!strict
-- MVP species (Greenleaf Forest). Palettes are gene hints: Main = C allele, Alt = c allele.
-- Graphics' CreatureBlueprints may override colours; numbers here drive gameplay.
export type SpeciesDef = {
	Name: string,
	Rarity: string,
	BaseValue: number, -- coins/min
	Space: number, -- cells needed per creature
	Personality: string,
	Tags: { string }, -- biome tags the habitat needs
	EggSeconds: number,
	Speed: number, -- studs/s walking
	Order: number, -- journal order
	Blurb: string,
	Main: Color3,
	Alt: Color3,
}

local Species: { [string]: SpeciesDef } = {
	Lumibun = {
		Name = "Lumibun",
		Rarity = "Common",
		BaseValue = 4,
		Space = 6,
		Personality = "Shy",
		Tags = { "grass", "flower", "burrow" },
		EggSeconds = 120,
		Speed = 7,
		Order = 1,
		Blurb = "A shy bunny whose long ears glow softly at dusk.",
		Main = Color3.fromRGB(245, 236, 214),
		Alt = Color3.fromRGB(196, 170, 230),
	},
	Mossback = {
		Name = "Mossback",
		Rarity = "Common",
		BaseValue = 5,
		Space = 12,
		Personality = "Lazy",
		Tags = { "grass", "tree", "rock" },
		EggSeconds = 120,
		Speed = 4,
		Order = 2,
		Blurb = "A sleepy tortoise-pup with a garden growing on its back.",
		Main = Color3.fromRGB(122, 160, 92),
		Alt = Color3.fromRGB(176, 140, 96),
	},
	Emberfox = {
		Name = "Emberfox",
		Rarity = "Common",
		BaseValue = 6,
		Space = 9,
		Personality = "Playful",
		Tags = { "tree", "log", "sunspot" },
		EggSeconds = 120,
		Speed = 9,
		Order = 3,
		Blurb = "A playful fox whose tail flickers like a warm campfire.",
		Main = Color3.fromRGB(240, 130, 60),
		Alt = Color3.fromRGB(200, 70, 90),
	},
	Pebblehorn = {
		Name = "Pebblehorn",
		Rarity = "Uncommon",
		BaseValue = 12,
		Space = 12,
		Personality = "Social",
		Tags = { "rock", "water", "sand" },
		EggSeconds = 300,
		Speed = 6,
		Order = 4,
		Blurb = "A friendly little rhino that polishes pebbles with its nose horn.",
		Main = Color3.fromRGB(150, 160, 175),
		Alt = Color3.fromRGB(110, 140, 190),
	},
	Thornstag = {
		Name = "Thornstag",
		Rarity = "Rare",
		BaseValue = 25,
		Space = 16,
		Personality = "Curious",
		Tags = { "tree", "water", "bush" },
		EggSeconds = 600,
		Speed = 10,
		Order = 5,
		Blurb = "A curious fawn crowned with living branch antlers.",
		Main = Color3.fromRGB(150, 105, 70),
		Alt = Color3.fromRGB(90, 120, 80),
	},
}

return Species
