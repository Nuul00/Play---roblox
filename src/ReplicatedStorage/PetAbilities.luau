-- Способности питомцев. У каждого питомца есть простая способность (монеты, магнит, скорость,
-- удача яиц, шанс двойной монеты), у Legendary и Secret — ещё уникальная супер-способность.
-- Общий модуль для сервера и клиента: только данные и чистые функции.
-- Сумму команды сервер пишет в атрибуты игрока (AbilCoins, AbilMagnet, AbilSpeed, AbilLuck,
-- AbilDouble) и строку PetSupers ("CoinRain=2;Vacuum=1": ключ супер-способности = уровень).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local PetAbilities = {}

-- ===== Простые способности =====
-- Values — по рангу редкости (ShopConfig.RarityRank: 1 Common … 5 Mythic, 6 Legendary, 7 Secret).
-- Проценты хранятся долей (0.12 = +12%), магнит — в стадах.
PetAbilities.Order = { "Coins", "Magnet", "Speed", "Luck", "Double" }
PetAbilities.Kinds = {
	Coins = { Icon = "💰", Attr = "AbilCoins", Label = "coins", Percent = true, Values = { 0.02, 0.03, 0.05, 0.08, 0.11, 0.15, 0.30 } },
	Magnet = { Icon = "🧲", Attr = "AbilMagnet", Label = "magnet", Percent = false, Values = { 0.5, 0.8, 1.2, 1.8, 2.5, 3.5, 6 } },
	Speed = { Icon = "⚡", Attr = "AbilSpeed", Label = "speed", Percent = true, Values = { 0.02, 0.03, 0.04, 0.06, 0.08, 0.10, 0.20 } },
	Luck = { Icon = "🍀", Attr = "AbilLuck", Label = "egg luck", Percent = true, Values = { 0.02, 0.03, 0.05, 0.08, 0.11, 0.15, 0.30 } },
	Double = { Icon = "✨", Attr = "AbilDouble", Label = "double coins", Percent = true, Values = { 0.005, 0.008, 0.012, 0.02, 0.03, 0.04, 0.06 } },
}
-- Множитель способности по ступени: обычный, Golden, Diamond, Rainbow.
PetAbilities.TierScale = { [0] = 1, [1] = 1.35, [2] = 1.7, [3] = 2.2 }
-- Потолок суммы всей команды (чтобы ребёрс-слоты не ломали баланс).
PetAbilities.Caps = { Coins = 3, Magnet = 40, Speed = 0.6, Luck = 2, Double = 0.3 }

-- ===== Супер-способности (только Legendary и Secret) =====
-- Уровень 1 — Legendary, уровень 2 — Secret (сильнее).
-- Vacuum: радиус = магнит × Range, но не больше магнита + MaxExtra стадов.
PetAbilities.SuperOrder = { "CoinRain", "Vacuum", "LuckyAura" }
PetAbilities.Supers = {
	CoinRain = {
		Icon = "🌧️",
		Color = Color3.fromRGB(255, 200, 50),
		Levels = {
			{ Name = "Coin Rain", Interval = 30, Pickups = 15 },
			{ Name = "Coin Storm", Interval = 20, Pickups = 30 },
		},
	},
	Vacuum = {
		Icon = "🌀",
		Color = Color3.fromRGB(120, 200, 255),
		Levels = {
			{ Name = "Coin Vacuum", Interval = 4, Range = 2.5, MaxExtra = 25 },
			{ Name = "Black Hole", Interval = 2.5, Range = 3.5, MaxExtra = 40 },
		},
	},
	LuckyAura = {
		Icon = "🌟",
		Color = Color3.fromRGB(110, 235, 130),
		Levels = {
			{ Name = "Lucky Aura", Luck = 0.10 },
			{ Name = "Fortune Aura", Luck = 0.25 },
		},
	},
}

-- Номер питомца в пуле его яйца: виды способностей чередуются внутри яйца.
local poolPlace = {}
for eggId, egg in pairs(Config.Eggs) do
	for i, entry in ipairs(egg.Pool) do
		if not poolPlace[entry.Pet] then
			poolPlace[entry.Pet] = { Egg = eggId, Index = i }
		end
	end
end

local function rank(id: number): number
	local def = Config.Pets[id]
	return def and ShopConfig.RarityRank[def.Rarity] or 1
end

local function pct(v: number): string
	return string.format("%g", math.floor(v * 1000 + 0.5) / 10) .. "%"
end

function PetAbilities.Format(kind: string, value: number): string
	local k = PetAbilities.Kinds[kind]
	if not k then
		return ""
	end
	local amount = k.Percent and pct(value) or string.format("%g", math.floor(value * 10 + 0.5) / 10)
	return k.Icon .. " +" .. amount .. " " .. k.Label
end

-- Простая способность питомца id на ступени tier: { Kind, Value, Icon, Text, Attr }.
function PetAbilities.Get(id: number, tier: number?)
	local place = poolPlace[id]
	local n = place and (place.Index - 1 + place.Egg) or id
	local kind = PetAbilities.Order[n % #PetAbilities.Order + 1]
	local k = PetAbilities.Kinds[kind]
	local values = k.Values
	local base = values[math.clamp(rank(id), 1, #values)]
	local value = base * (PetAbilities.TierScale[tier or 0] or 1)
	return { Kind = kind, Value = value, Icon = k.Icon, Attr = k.Attr, Text = PetAbilities.Format(kind, value) }
end
function PetAbilities.GetCode(code: number)
	local id, tier = ShopConfig.SplitPet(code)
	return PetAbilities.Get(id, tier)
end

-- Параметры супер-способности key на уровне level (Name, Interval, Pickups, Range, Luck…).
function PetAbilities.SuperParams(key: string, level: number)
	local s = PetAbilities.Supers[key]
	return s and s.Levels[math.clamp(level, 1, #s.Levels)]
end

local function superText(key: string, p): string
	if key == "CoinRain" then
		return string.format("Every %ds: coins rain down, worth %d pickups", p.Interval, p.Pickups)
	elseif key == "Vacuum" then
		return string.format("Every %gs: grabs coins in %gx magnet range", p.Interval, p.Range)
	elseif key == "LuckyAura" then
		return string.format("Eggs: best of 2 rolls, +%s luck", pct(p.Luck))
	end
	return ""
end

-- Супер-способность питомца или nil: { Key, Name, Icon, Text, Level, Color, Params }.
function PetAbilities.Super(id: number)
	local def = Config.Pets[id]
	if not def then
		return nil
	end
	local level = def.Rarity == "Secret" and 2 or def.Rarity == "Legendary" and 1 or nil
	if not level then
		return nil
	end
	local place = poolPlace[id]
	local n = place and (place.Egg + place.Index) or id
	local key = PetAbilities.SuperOrder[n % #PetAbilities.SuperOrder + 1]
	local s = PetAbilities.Supers[key]
	local params = s.Levels[level]
	return { Key = key, Name = params.Name, Icon = s.Icon, Color = s.Color, Level = level, Params = params, Text = superText(key, params) }
end

-- Сумма способностей команды (коды питомцев id + ступень*1000).
-- Одинаковые супер-способности не складываются: берётся самый высокий уровень.
function PetAbilities.Team(codes: { number })
	local total = { Coins = 0, Magnet = 0, Speed = 0, Luck = 0, Double = 0, Supers = {} }
	for _, code in ipairs(codes) do
		local id, tier = ShopConfig.SplitPet(code)
		if Config.Pets[id] then
			local a = PetAbilities.Get(id, tier)
			total[a.Kind] += a.Value
			local s = PetAbilities.Super(id)
			if s and (total.Supers[s.Key] or 0) < s.Level then
				total.Supers[s.Key] = s.Level
			end
		end
	end
	for kind, cap in pairs(PetAbilities.Caps) do
		total[kind] = math.min(total[kind], cap)
	end
	local parts = {}
	for _, key in ipairs(PetAbilities.SuperOrder) do
		if total.Supers[key] then
			table.insert(parts, key .. "=" .. total.Supers[key])
		end
	end
	total.SuperText = table.concat(parts, ";")
	return total
end

-- Строка PetSupers → { CoinRain = 2, … }. Результат кэшируется (не менять таблицу!).
local parseCache = {}
function PetAbilities.ParseSupers(text: string?)
	text = text or ""
	local cached = parseCache[text]
	if cached then
		return cached
	end
	local out = {}
	for key, level in string.gmatch(text :: string, "(%a+)=(%d+)") do
		if PetAbilities.Supers[key] then
			out[key] = tonumber(level)
		end
	end
	parseCache[text] = out
	return out
end

-- Короткая строка итогов команды для интерфейса: "💰 +12% coins  ⚡ +4% speed".
function PetAbilities.TeamText(player): string
	local parts = {}
	for _, kind in ipairs(PetAbilities.Order) do
		local v = player:GetAttribute(PetAbilities.Kinds[kind].Attr) or 0
		if v > 0 then
			table.insert(parts, PetAbilities.Format(kind, v))
		end
	end
	for key, level in pairs(PetAbilities.ParseSupers(player:GetAttribute("PetSupers"))) do
		local s = PetAbilities.Supers[key]
		table.insert(parts, s.Icon .. " " .. s.Levels[level].Name)
	end
	return table.concat(parts, "   ")
end

return PetAbilities
