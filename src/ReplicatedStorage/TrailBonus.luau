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
function T.Get(p)
	local id = p:GetAttribute(T.Attr)
	return id and T.List[id] or nil
end
function T.Text(id)
	local b = T.List[id]
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
