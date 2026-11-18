--!strict
-- Animation tuning (visual-only numbers; gameplay numbers live in Shared/Config).
local Tuning = {
	-- Culling / budget
	ActiveRadius = 120, -- creatures/visitors farther than this from the camera are frozen
	NearRadius = 55, -- inside this: full rate + squash & stretch (mesh creatures)
	MaxActive = 60, -- most creatures animated at once (nearest first)
	MaxSquash = 24, -- most mesh creatures resized for squash & stretch at once
	CullInterval = 0.5, -- seconds between re-sorting the active set

	-- Idle
	BobHeight = 0.22, -- studs (fish/bird hover x2)
	BobSpeed = 2.1, -- rad/s base (random x0.8..1.2 per creature)
	Breathe = 0.035, -- squash & stretch amount while idle
	Wander = 1.0, -- max studs from home (server Hitbox stays put; keep < 1.2)
	WanderSpeed = 1.4, -- studs/s
	WanderEvery = { 4, 9 }, -- seconds between wander targets
	ActionEvery = { 5, 12 }, -- seconds between idle actions (hop/spin/wiggle/look)
	FaceRadius = 14, -- turn to face the local player inside this
	TurnSpeed = 5, -- yaw lerp rate

	-- Moods
	ThrivingSpeed = 1.35, -- bob speed multiplier
	ThrivingActionMul = 0.45, -- action interval multiplier (more hops)
	NightSpeed = 0.55,
	NightActionMul = 2.2,
	NightDroop = 0.06, -- forward tilt (rad) when sleepy

	-- Moments (seconds)
	PopTime = 0.45,
	BounceTime = 0.55,
	CelebrateTime = 1.1,
	HopTime = 0.45,
	ThudTime = 0.5,
	ThudDrop = 2.5, -- studs a placed item falls from

	-- Scenery
	SwayRadius = 90,
	SwayRate = 1 / 15, -- seconds between sway updates
	SwayMaxParts = 600,
	TreeSway = 0.022, -- rad
	FlowerSway = 0.09, -- rad
	FlickerRadius = 90,

	-- Visitors
	VisitorSpeed = 6,
	VisitorRadius = 150,

	-- Rewards
	Coins = 10, -- coins per tip-jar collect
	CoinFlyRadius = 14, -- coins fly to the local player if this close to the jar
	ReleaseRise = 16,
	ReleaseTime = 2.4,
}

return Tuning
