--!strict
-- Pure game math shared by server and client (UI can use these for previews/timers).
local Config = require(script.Parent:WaitForChild("Config"))

local Formulas = {}

function Formulas.RarityIndex(rarity: string): number
	local r = (Config.Rarities :: any)[rarity]
	return if r then r.Index else 0
end

-- passes: { SuperLuck: boolean? }
function Formulas.Luck(data: any, hasSuperLuck: boolean, now: number): number
	local l = 1
		+ Config.Luck.PerShopLuck * (data.upgrades.ShopLuck or 0)
		+ Config.Luck.PerRelease * data.releases
		+ (if hasSuperLuck then Config.Luck.SuperLuck else 0)
	if (data.potions.luckUntil or 0) > now then
		l *= Config.Luck.PotionMult
	end
	return l
end

function Formulas.GrowTime(speciesName: string, fertLevel: number): number
	local s = Config.Species.ByName[speciesName]
	return s.Grow / (1 + Config.FertilizerPerLevel * fertLevel)
end

-- 0..1 progress of a placed plant. growTotal 0 = already grown.
function Formulas.Progress(item: any, now: number): number
	if (item.growTotal or 0) <= 0 then
		return 1
	end
	return math.clamp((now - item.plantedAt) / item.growTotal, 0, 1)
end

function Formulas.ReadyAt(item: any): number
	return (item.plantedAt or 0) + (item.growTotal or 0)
end

function Formulas.Stage(progress: number): string
	if progress >= 1 then
		return "Grown"
	end
	local name = "Seed"
	for _, st in Config.Stages do
		if progress >= st.From then
			name = st.Name
		end
	end
	return name
end

-- base $/s x color x weather (before needs and player multipliers)
function Formulas.CreatureBase(item: any): number
	local s = Config.Species.ByName[item.species]
	if not s then
		return 0
	end
	local c = (Config.ColorMults :: any)[item.color or ""] or 1
	local w = (Config.WeatherMults :: any)[item.weather or ""] or 1
	return s.Income * c * w
end

function Formulas.PlayerMult(data: any, vip: boolean, double: boolean): number
	local m = (1 + Config.Income.PerRelease * data.releases)
		* (1 + Config.Income.PerAppeal * (data.upgrades.VisitorAppeal or 0))
	if vip then
		m *= Config.Income.VIP
	end
	if double then
		m *= Config.Income.DoubleCash
	end
	return m
end

function Formulas.SellValue(item: any): number
	local s = Config.Species.ByName[item.species]
	if not s then
		return 0
	end
	local c = (Config.ColorMults :: any)[item.color or ""] or 1
	local w = (Config.WeatherMults :: any)[item.weather or ""] or 1
	return math.floor(s.Cost * 0.5 * c * w)
end

function Formulas.SlotCount(data: any): number
	local n = Config.Shop.BaseSlots + (data.upgrades.BiggerRestock or 0) + data.releases // Config.Shop.SlotsPerReleases
	return math.min(n, Config.Shop.MaxSlots)
end

function Formulas.OfflineCapSeconds(data: any): number
	return (
		Config.Income.OfflineBaseCapHours
		+ Config.Income.OfflineCapHoursPerBench * (data.upgrades.ComfyBenches or 0)
	) * 3600
end

-- n = the release number being attempted (releases + 1)
function Formulas.ReleaseCash(n: number): number
	local list = Config.Release.CashReq
	if n <= #list then
		return list[n]
	end
	return list[#list] * 10 ^ (n - #list)
end

function Formulas.UpgradeCost(key: string, currentLevel: number): number?
	local u = (Config.Upgrades :: any)[key]
	if not u then
		return nil
	end
	return u.Costs[currentLevel + 1]
end

-- Map a uniform draw u in [0,1) to a rarity, with non-Common weights x luck.
function Formulas.RollRarity(u: number, luck: number, minRarity: string?): string
	local minIdx = if minRarity then Formulas.RarityIndex(minRarity) else 1
	local total = 0
	for _, name in Config.RarityOrder do
		local r = (Config.Rarities :: any)[name]
		if r.Index >= minIdx then
			total += if name == "Common" then r.Weight else r.Weight * luck
		end
	end
	local pick = u * total
	local last = Config.RarityOrder[#Config.RarityOrder]
	for _, name in Config.RarityOrder do
		local r = (Config.Rarities :: any)[name]
		if r.Index >= minIdx then
			local w = if name == "Common" then r.Weight else r.Weight * luck
			if pick < w then
				return name
			end
			pick -= w
		end
	end
	return last
end

function Formulas.Day(now: number): number
	return now // 86400
end

return Formulas
