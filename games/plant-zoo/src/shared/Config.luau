--!strict
-- Every tunable number lives here.
local Config = {}

Config.GameName = "Plant Zoo (working title)"
Config.Studio = "Chiken Studios"

Config.DataStoreName = "plant-zoo_v1"
Config.AutosaveSeconds = 120
Config.RemoteCooldown = 0.2

-- Shown in leaderstats (must be number fields in DefaultData).
Config.Leaderstats = { "Cash" }

Config.DefaultData = {
	Cash = 0,
	Rebirths = 0,
	LastDailyClaim = 0,
	DailyStreak = 0,
}

Config.Daily = {
	CooldownSeconds = 20 * 60 * 60,
	StreakResetSeconds = 48 * 60 * 60,
	BaseReward = 100,
	StreakBonus = 50,
}

-- Placeholder IDs: 0 = not set yet (Charlie TODO).
Config.GamePasses = {
	DoubleCash = { Id = 0, Name = "2x Cash" },
	VIP = { Id = 0, Name = "VIP" },
}

Config.DevProducts = {
	CashPackSmall = { Id = 0, Name = "Cash Pack", Cash = 1000 },
}

return Config
