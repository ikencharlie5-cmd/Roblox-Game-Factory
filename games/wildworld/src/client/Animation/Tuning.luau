--!strict
-- Animation tuning (visual only; gameplay numbers live in Shared/Config).
local Tuning = {
	-- Distance tiers (studs from the camera) and budget
	FullRadius = 60, -- full animation every frame
	MidRadius = 140, -- 10 Hz, position + body bob only
	MidRate = 1 / 10,
	FarRate = 1 / 2, -- beyond MidRadius: position only, 2 Hz
	MaxFull = 60, -- most creatures animated at full rate (nearest first)
	MaxParts = 1500, -- most creature parts moved per frame (full tier)
	CullInterval = 0.25, -- seconds between re-sorting creatures by distance
	ScreenMargin = 0.15, -- viewport margin counted as "on screen"
	AlwaysOnScreen = 20, -- creatures this close always animate (behind the camera too)

	-- Movement (visual root follows the server Hitbox / Goal)
	DefaultSpeed = 5, -- studs/s when the Speed attribute is missing
	SnapDistance = 40, -- teleport the visual if it is this far from its target
	TurnRate = 6, -- yaw lerp rate
	MoveBlendRate = 8,

	-- Idle
	BobAmp = 0.06, -- +- studs (0.12 total, as in the art guide)
	BobPeriod = 1.4, -- seconds
	BreathAmp = 0.04, -- body squash amount while idle
	BlinkEvery = { 3, 6 },
	BlinkTime = 0.12,
	EarFlickEvery = { 3, 6 },
	EarFlickTime = 0.22,
	EarFlickAngle = 0.5,
	LookEvery = { 2, 5 },
	LookRadius = 15, -- face the nearest player within this
	HeadYawMax = 0.8,
	ActionEvery = { 4, 9 }, -- seconds between idle actions (personality scales it)

	-- Walk
	WalkHz = 3, -- leg cycles per second at WalkRefSpeed
	WalkRefSpeed = 5,
	LegSwing = math.rad(25),
	WalkBob = 0.12,
	HopHeight = 1, -- Lumibun hop arc
	HopSquash = 0.15,

	-- Tail / wings
	TailAmp = math.rad(15),
	TailHz = 2,
	HappyTailAmp = math.rad(30),
	HappyTailHz = 4,
	WingFlap = math.rad(20),

	-- Moods (attributes on the creature Model)
	HungryBelow = 30, -- Hunger < this -> head droop
	HungryDroop = math.rad(10),
	HappyAbove = 70, -- Happiness >= this -> fast tail, extra hops
	SleepDroop = math.rad(20),
	SleepLower = 0.15,
	ZEvery = 1.3, -- seconds between floating "z" over a sleeper

	-- Moments
	RevealDelay = 0.5, -- mutation VFX turns on this long after a hatch pop
	HatchLink = 20, -- a creature appearing this close to a just-hatched egg plays Hatch
	HatchLinkTime = 6,
	BornRecent = 8, -- seconds; a creature with a Born time this recent plays Hatch
	ArmDelay = 3, -- ignore "new" things for this long after join (no pop spam)
	ThudDrop = 2.5,
	CapturedHide = 2.5, -- keep a captured creature hidden this long while the server removes it

	-- Eggs
	EggRadius = 90,
	EggBurstEvery = { 4, 0.6 }, -- seconds between wobble bursts (fresh -> ready)
	EggAmp = { math.rad(4), math.rad(14) },
	EggHz = { 7, 14 },
	EggShellBurst = true, -- set false if Graphics does its own shell halves

	-- Visitors
	VisitorRadius = 150,
	VisitorSpeed = 5,
	MaxVisitorsPerPlot = 6,
	DefaultVisitors = 3,
	VisitorEmotes = { "Wow!", "So cute!", "\u{2665}", "Aww!", "\u{2605}" },

	-- Scenery
	SwayRadius = 90,
	SwayRate = 1 / 15,
	SwayMaxParts = 600,
	TreeSway = 0.02,
	FlowerSway = 0.07,
	FlickerRadius = 90,

	-- Coins
	CoinPool = 24,
	CoinFlyRadius = 30, -- coins home in on the local player inside this

	-- Mutation colours for reveal bursts (merge with Theme when Graphics adds one)
	MutationColors = {
		Golden = Color3.fromRGB(255, 216, 74),
		Albino = Color3.fromRGB(255, 240, 245),
		Crystal = Color3.fromRGB(159, 232, 255),
		Glowing = Color3.fromRGB(182, 255, 122),
	} :: { [string]: Color3 },
	BigMutations = { Golden = true, Crystal = true } :: { [string]: boolean },

	-- Per-species feel (unknown species use Default)
	Species = {
		Default = { hop = false, speed = 1, personality = "Curious" },
		Lumibun = { hop = true, speed = 1.2, personality = "Shy" },
		Mossback = { hop = false, speed = 0.7, personality = "Lazy" },
		Emberfox = { hop = false, speed = 1.3, personality = "Playful" },
		Pebblehorn = { hop = false, speed = 0.8, personality = "Social" },
		Thornstag = { hop = false, speed = 0.9, personality = "Curious" },
	} :: { [string]: { hop: boolean, speed: number, personality: string } },

	-- Personality -> idle action interval multiplier + favourite actions
	Personality = {
		Shy = { every = 1.0, actions = { "Look", "Look", "Hop", "Sniff" } },
		Lazy = { every = 1.6, actions = { "Stretch", "Sniff", "Look" } },
		Playful = { every = 0.6, actions = { "Hop", "Spin", "Hop", "Wiggle" } },
		Social = { every = 0.9, actions = { "Hop", "Look", "Wiggle" } },
		Curious = { every = 0.9, actions = { "Sniff", "Look", "Hop" } },
		Proud = { every = 1.2, actions = { "Look", "Stretch" } },
	} :: { [string]: { every: number, actions: { string } } },
}

return Tuning
