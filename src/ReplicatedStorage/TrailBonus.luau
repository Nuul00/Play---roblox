-- Бонусы трейлов (магазин трейлов партнёра, жетоны ⚡ за квестовую линию).
-- Надетый трейл сервер QuestService пишет в атрибут EquippedTrail (Id трейла).
-- Coins — доля к монетам (умножается на остальные бонусы), Speed — доля к скорости бега.
local T = {}
T.Attr = "EquippedTrail"
T.List = {
	Spark = { Coins = 0, Speed = 0.05 },
	NeonStreak = { Coins = 0.05, Speed = 0.05 },
	SunsetRibbon = { Coins = 0.10, Speed = 0.05 },
	CloudWake = { Coins = 0.10, Speed = 0.10 },
	Comet = { Coins = 0.15, Speed = 0.10 },
	RainbowRush = { Coins = 0.30, Speed = 0.15 },
}
-- Прокачка трейлов за жетоны ⚡: уровни 1–5, каждый уровень +25% к бонусу трейла.
-- Цена перехода lv → lv+1 = ceil(цена трейла / 2 * lv). Цены трейлов — из магазина партнёра.
T.MaxLevel = 5
T.Price = { Spark = 3, NeonStreak = 5, SunsetRibbon = 7, CloudWake = 10, Comet = 14, RainbowRush = 21 }
function T.LevelAttr(id)
	return "Save_TrailLv_" .. id
end
function T.Level(p, id)
	return math.clamp(math.floor(tonumber(p:GetAttribute(T.LevelAttr(id))) or 1), 1, T.MaxLevel)
end
function T.UpgradeCost(id, lv)
	return math.ceil((T.Price[id] or 10) / 2 * lv)
end
function T.Scaled(id, lv)
	local b = T.List[id]
	if not b then
		return nil
	end
	local k = 1 + 0.25 * ((lv or 1) - 1)
	return { Coins = b.Coins * k, Speed = b.Speed * k }
end
function T.Get(p)
	local id = p:GetAttribute(T.Attr)
	return id and T.Scaled(id, T.Level(p, id)) or nil
end

-- Обмен жетонов (когда трейлы уже прокачаны): ключи Coin Rush и супер-зелья.
T.Exchange = {
	{ Key = "RushKey", Name = "Rush Key", Cost = 3, Image = "rbxassetid://106655154523737" },
	{ Key = "SuperSpeed", Name = "Super Speed", Cost = 4, Image = "rbxassetid://126064573164393" },
	{ Key = "SuperCoins", Name = "Super Coins", Cost = 5, Image = "rbxassetid://96705395595679" },
	{ Key = "SuperLuck", Name = "Super Luck", Cost = 6, Image = "rbxassetid://126031374933776" },
}
-- Откуда ещё жетоны (кроме квестов): забег Coin Rush, ребёрс, ежедневная награда.
T.Sources = { Rush = 1, Rebirth = 3, Daily = 2 }

function T.Text(id, lv)
	local b = T.Scaled(id, lv or 1)
	if not b then
		return ""
	end
	local parts = {}
	if b.Coins > 0 then
		table.insert(parts, "+" .. math.floor(b.Coins * 100 + 0.5) .. "% coins")
	end
	if b.Speed > 0 then
		table.insert(parts, "+" .. math.floor(b.Speed * 100 + 0.5) .. "% speed")
	end
	return table.concat(parts, " · ")
end
return T
