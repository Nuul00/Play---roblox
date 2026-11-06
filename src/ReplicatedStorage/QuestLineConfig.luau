-- Квестовая линия (сюжетная цепочка): шаги идут строго по порядку, по главе на мир.
-- Отдельно от ежедневных заданий (DailyConfig) — их не трогаем.
-- Общий модуль для сервера и клиента: только данные и чистые функции.
--
-- Типы целей (Goal.Type):
--   collect    — подобрать N монет (считается с начала шага)
--   earn       — заработать N монет (LifetimeEarned, с начала шага)
--   eggs       — открыть N яиц (Egg = id яйца из GameConfig.Eggs или nil — любые), с начала шага
--   speed / magnet / income / double — достичь уровня прокачки N (абсолютное значение)
--   magnetTier — купить магнит №N (атрибут MagnetTier)
--   discover   — открыть N разных питомцев (атрибут PetsDiscovered)
--   variant    — создать N питомцев ступени Key (Gold / Diamond / Rainbow), с начала шага
--   world      — побывать в мире World (CurrentWorld)
--   rebirth    — сделать N ребёрсов (с начала шага)
-- Награда (Reward): Coins, Potion ("Coins"/"Speed"/"Luck"), Hatch (id яйца — бесплатное открытие
-- с двойной удачей), Bonus (постоянная прибавка к множителю монет, атрибут Save_QuestLineBonus).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local Q = {}
local rgb = Color3.fromRGB

-- Атрибуты игрока (Save_ сохраняются автоматически через WorldProgress).
Q.Attr = {
	Step = "Save_QuestLineStep", -- номер текущего шага (1..#Steps, больше — линия пройдена)
	Base = "Save_QuestLineBase", -- значение статистики в момент начала шага (строка: числа бывают огромными)
	Count = "Save_QuestLineCount", -- счётчик для яиц / улучшенных питомцев
	Ready = "Save_QuestLineReady", -- цель выполнена, ждёт CLAIM (не сбрасывается, даже если уровень упал)
	Bonus = "Save_QuestLineBonus", -- постоянный множитель монет от глав (1 = без бонуса)
	Progress = "QuestLineProgress", -- для клиента: текущее значение
	Goal = "QuestLineGoal", -- для клиента: цель
}
Q.RemoteName = "QuestLineRemote"

Q.Chapters = {
	{ Name = "Meadow Isles", Title = "Meadow Beginnings", Icon = "🌴", Top = rgb(130, 235, 120), Bottom = rgb(40, 150, 70), Accent = rgb(200, 255, 150) },
	{ Name = "Neon District", Title = "Neon Nights", Icon = "🌃", Top = rgb(230, 120, 255), Bottom = rgb(95, 40, 200), Accent = rgb(255, 170, 255) },
	{ Name = "Sky Isles", Title = "Above the Clouds", Icon = "☁️", Top = rgb(150, 215, 255), Bottom = rgb(110, 120, 240), Accent = rgb(220, 240, 255) },
	{ Name = "Frozen Peaks", Title = "Frozen Frontier", Icon = "❄️", Top = rgb(170, 235, 255), Bottom = rgb(60, 140, 220), Accent = rgb(210, 250, 255) },
	{ Name = "Magma Volcano", Title = "Trial by Fire", Icon = "🌋", Top = rgb(255, 150, 60), Bottom = rgb(170, 40, 20), Accent = rgb(255, 210, 120) },
	{ Name = "Cosmic Galaxy", Title = "Cosmic Legend", Icon = "🌌", Top = rgb(150, 140, 255), Bottom = rgb(60, 30, 140), Accent = rgb(220, 190, 255) },
}

local function step(chapter, title, hint, goal, reward)
	return { Chapter = chapter, Title = title, Hint = hint, Goal = goal, Reward = reward }
end

Q.Steps = {
	-- ===== Глава 1: Meadow Isles (яйца 1, 2, 3; прокачка до 10) =====
	step(1, "First Steps", "Run over coins to pick them up!", { Type = "collect", N = 10 }, { Coins = 50 }),
	step(1, "Speedy Start", "Buy Speed at the upgrade kiosk.", { Type = "speed", N = 3 }, { Coins = 100 }),
	step(1, "Your First Egg", "Egg stands are near the spawn!", { Type = "eggs", N = 1, Egg = 1 }, { Coins = 100, Potion = "Luck" }),
	step(1, "Coin Hunter", "Keep running and collecting!", { Type = "collect", N = 60 }, { Coins = 200 }),
	step(1, "Magnet Power", "A bigger magnet pulls coins from afar.", { Type = "magnet", N = 3 }, { Coins = 250 }),
	step(1, "Egg Collector", "More eggs, more pets!", { Type = "eggs", N = 5, Egg = 1 }, { Coins = 300, Potion = "Coins" }),
	step(1, "Sakura Season", "Sakura pets are twice as strong.", { Type = "eggs", N = 3, Egg = 2 }, { Coins = 600 }),
	step(1, "Pet Explorer", "Every new pet fills your Pet Index.", { Type = "discover", N = 6 }, { Coins = 800 }),
	step(1, "Income Boost", "Income multiplies every coin.", { Type = "income", N = 5 }, { Coins = 1000 }),
	step(1, "Golden Touch", "Fuse 5 same pets in the golden machine.", { Type = "variant", N = 1, Key = "Gold" }, { Coins = 1500, Potion = "Luck" }),
	step(1, "Starlight Wish", "The rarest egg of the meadow!", { Type = "eggs", N = 3, Egg = 3 }, { Coins = 2000 }),
	step(1, "Meadow Master", "Finish the chapter for a big prize!", { Type = "earn", N = 10000 }, { Coins = 3000, Hatch = 3, Bonus = 0.05 }),

	-- ===== Глава 2: Neon District (яйца 4, 5, 6; прокачка до 25) =====
	step(2, "Into the Neon", "Unlock it in the TELEPORT menu (1K coins).", { Type = "world", World = "Neon District" }, { Coins = 1100 }),
	step(2, "Neon Runner", "Neon kiosks sell higher levels.", { Type = "speed", N = 15 }, { Coins = 2900 }),
	step(2, "Disco Fever", "Neon pets are way stronger!", { Type = "eggs", N = 5, Egg = 4 }, { Coins = 8000, Potion = "Luck" }),
	step(2, "Double Trouble", "A chance for every coin to count twice.", { Type = "double", N = 5 }, { Coins = 21000 }),
	step(2, "Tech Upgrade", "Cyber pets await inside.", { Type = "eggs", N = 5, Egg = 5 }, { Coins = 60000, Potion = "Coins" }),
	step(2, "Magnet Shopper", "Buy new magnets at the magnet shop.", { Type = "magnetTier", N = 5 }, { Coins = 150000 }),
	step(2, "Pet Hunter", "Open different eggs to find new pets.", { Type = "discover", N = 20 }, { Coins = 400000 }),
	step(2, "Diamond Shine", "Fuse 5 golden pets in the Neon machine.", { Type = "variant", N = 1, Key = "Diamond" }, { Coins = 1.1e6, Potion = "Luck" }),
	step(2, "City Lights", "The best egg of the district!", { Type = "eggs", N = 5, Egg = 6 }, { Coins = 2.8e6 }),
	step(2, "Neon Tycoon", "Finish the chapter for a big prize!", { Type = "earn", N = 2e7 }, { Coins = 8e6, Hatch = 6, Bonus = 0.05 }),

	-- ===== Глава 3: Sky Isles (яйца 7, 8, 9; прокачка до 50; первый ребёрс) =====
	step(3, "Above the Clouds", "Unlock Sky Isles in TELEPORT (25M coins).", { Type = "world", World = "Sky Isles" }, { Coins = 6e6 }),
	step(3, "Cloud Walker", "Sky kiosks go up to level 50.", { Type = "speed", N = 30 }, { Coins = 3e7 }),
	step(3, "Cloud Egg", "Fluffy pets from the clouds!", { Type = "eggs", N = 5, Egg = 7 }, { Coins = 5e7, Potion = "Luck" }),
	step(3, "Sky Magnet", "Pull in coins across the islands.", { Type = "magnet", N = 35 }, { Coins = 8e7 }),
	step(3, "Celestial Call", "Celestial pets shine bright.", { Type = "eggs", N = 5, Egg = 8 }, { Coins = 1.2e8, Potion = "Coins" }),
	step(3, "Magnet Collector", "Buy Bubblegum Pop in the Sky magnet shop.", { Type = "magnetTier", N = 22 }, { Coins = 2e8 }),
	step(3, "Fresh Start", "Rebirth for a permanent coin bonus!", { Type = "rebirth", N = 1 }, { Coins = 3.5e8, Potion = "Speed" }),
	step(3, "Egg Frenzy", "Open any eggs you like!", { Type = "eggs", N = 50 }, { Coins = 5.5e8 }),
	step(3, "Rainbow Dream", "Fuse 5 diamond pets in the Sky machine.", { Type = "variant", N = 1, Key = "Rainbow" }, { Coins = 9e8, Potion = "Luck" }),
	step(3, "Crystal Clear", "The most precious egg in the sky.", { Type = "eggs", N = 5, Egg = 9 }, { Coins = 1.4e9 }),
	step(3, "Sky Baron", "Finish the chapter for a big prize!", { Type = "earn", N = 3e10 }, { Coins = 2.5e9, Hatch = 9, Bonus = 0.05 }),

	-- ===== Глава 4: Frozen Peaks (яйца 16, 17, 18; прокачка до 75) =====
	step(4, "Frozen Frontier", "Unlock Frozen Peaks in TELEPORT (10B coins).", { Type = "world", World = "Frozen Peaks" }, { Coins = 2.5e9 }),
	step(4, "Snowflake Hunt", "Snowy pets love the cold.", { Type = "eggs", N = 10, Egg = 16 }, { Coins = 5.7e9, Potion = "Luck" }),
	step(4, "Ice Skater", "Frozen kiosks go up to level 75.", { Type = "speed", N = 55 }, { Coins = 9e9 }),
	step(4, "Aurora Lights", "Pets glowing like the northern sky.", { Type = "eggs", N = 10, Egg = 17 }, { Coins = 1.5e10, Potion = "Coins" }),
	step(4, "Prism Power", "Buy Aurora Wave in the Frozen magnet shop.", { Type = "magnetTier", N = 35 }, { Coins = 2.7e10 }),
	step(4, "Double Chill", "Double coins, double fun.", { Type = "double", N = 60 }, { Coins = 4.8e10 }),
	step(4, "Pet Professor", "Your Pet Index keeps growing!", { Type = "discover", N = 60 }, { Coins = 7.8e10 }),
	step(4, "Glacier Giant", "The mightiest egg of the peaks.", { Type = "eggs", N = 10, Egg = 18 }, { Coins = 1.2e11, Potion = "Luck" }),
	step(4, "Frozen Fortune", "Finish the chapter for a big prize!", { Type = "earn", N = 1.5e12 }, { Coins = 2.4e11, Hatch = 18, Bonus = 0.05 }),

	-- ===== Глава 5: Magma Volcano (яйца 10, 11, 12; прокачка до 100) =====
	step(5, "Heat Wave", "Unlock Magma Volcano in TELEPORT (1.2T coins).", { Type = "world", World = "Magma Volcano" }, { Coins = 3e11 }),
	step(5, "Ember Awakening", "Fire pets burn with power.", { Type = "eggs", N = 10, Egg = 10 }, { Coins = 7.8e11, Potion = "Luck" }),
	step(5, "Lava Sprinter", "Volcano kiosks go up to level 100.", { Type = "speed", N = 80 }, { Coins = 1.2e12 }),
	step(5, "Molten Magnet", "Buy Magma Core in the Volcano magnet shop.", { Type = "magnetTier", N = 45 }, { Coins = 2.1e12 }),
	step(5, "Magma Core", "Hatch pets forged in lava.", { Type = "eggs", N = 10, Egg = 11 }, { Coins = 3.6e12, Potion = "Coins" }),
	step(5, "Reborn in Fire", "Rebirth twice to grow even stronger.", { Type = "rebirth", N = 2 }, { Coins = 6e12, Potion = "Speed" }),
	step(5, "Income Inferno", "Push your income to level 90.", { Type = "income", N = 90 }, { Coins = 9e12 }),
	step(5, "Lava Hunter", "Collect coins among the lava rivers.", { Type = "collect", N = 3000 }, { Coins = 1.8e13 }),
	step(5, "Obsidian Secret", "The darkest egg hides a dragon.", { Type = "eggs", N = 10, Egg = 12 }, { Coins = 3e13, Potion = "Luck" }),
	step(5, "Volcano Lord", "Finish the chapter for a big prize!", { Type = "earn", N = 4e14 }, { Coins = 4.8e13, Hatch = 12, Bonus = 0.05 }),

	-- ===== Глава 6: Cosmic Galaxy (яйца 13, 14, 15; прокачка до 125) =====
	step(6, "Lift Off", "Unlock Cosmic Galaxy in TELEPORT (300T coins)!", { Type = "world", World = "Cosmic Galaxy" }, { Coins = 7.5e13 }),
	step(6, "Rocket Science", "Space pets from another world.", { Type = "eggs", N = 10, Egg = 13 }, { Coins = 1.8e14, Potion = "Luck" }),
	step(6, "Star Speed", "Galaxy kiosks go up to level 125.", { Type = "speed", N = 110 }, { Coins = 3.6e14 }),
	step(6, "Nebula Drift", "Pets born in the stars.", { Type = "eggs", N = 10, Egg = 14 }, { Coins = 6.3e14, Potion = "Coins" }),
	step(6, "Cosmic Magnet", "Buy Nebula Swirl in the Galaxy magnet shop.", { Type = "magnetTier", N = 55 }, { Coins = 1.2e15 }),
	step(6, "Egg Legend", "Open any eggs you like!", { Type = "eggs", N = 500 }, { Coins = 2.1e15, Potion = "Luck" }),
	step(6, "Supernova", "The ultimate egg of the universe!", { Type = "eggs", N = 10, Egg = 15 }, { Coins = 3.6e15, Potion = "Luck" }),
	step(6, "Master of the Universe", "The final quest. Become a legend!", { Type = "earn", N = 1e17 }, { Coins = 6.6e15, Hatch = 15, Bonus = 0.10 }),
}

-- Шаг внутри главы: «3/12».
function Q.ChapterInfo(index: number): (number, number, number)
	local s = Q.Steps[index]
	if not s then
		return #Q.Chapters, 0, 0
	end
	local pos, total = 0, 0
	for i, other in ipairs(Q.Steps) do
		if other.Chapter == s.Chapter then
			total += 1
			if i <= index then
				pos += 1
			end
		end
	end
	return s.Chapter, pos, total
end

-- Большие числа: 1.5K, 20M, 3.2B, 5T, 1Qa.
function Q.Format(n: number): string
	n = n or 0
	local units = { { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			local v = n / u[1]
			return (string.format(v >= 100 and "%.0f" or "%.1f", v):gsub("%.0$", "")) .. u[2]
		end
	end
	return tostring(math.floor(n))
end

local function variantByKey(key)
	for i, v in ipairs(ShopConfig.Variants) do
		if v.Key == key then
			return v, i
		end
	end
	return nil, nil
end
Q.VariantByKey = variantByKey

-- Текст цели для трекера.
function Q.GoalText(goal): string
	local t = goal.Type
	local n = goal.N or 1
	if t == "collect" then
		return "Collect " .. Q.Format(n) .. " coins"
	elseif t == "earn" then
		return "Earn " .. Q.Format(n) .. " coins"
	elseif t == "eggs" then
		local egg = goal.Egg and Config.Eggs[goal.Egg]
		if egg then
			return "Open " .. Q.Format(n) .. " " .. egg.Name .. (n > 1 and "s" or "")
		end
		return "Open " .. Q.Format(n) .. " eggs"
	elseif t == "speed" then
		return "Reach Speed level " .. n
	elseif t == "magnet" then
		return "Upgrade Magnet to level " .. n
	elseif t == "income" then
		return "Upgrade Income to level " .. n
	elseif t == "double" then
		return "Upgrade Double Coins to level " .. n
	elseif t == "magnetTier" then
		local m = ShopConfig.Magnets[n]
		return "Unlock the " .. (m and m.Name or ("#" .. n)) .. " magnet"
	elseif t == "discover" then
		return "Discover " .. n .. " different pets"
	elseif t == "variant" then
		local v = variantByKey(goal.Key)
		local name = v and v.Name or tostring(goal.Key)
		return (n > 1 and ("Create " .. n .. " ") or "Create a ") .. name .. " pet"
	elseif t == "world" then
		return "Travel to " .. tostring(goal.World)
	elseif t == "rebirth" then
		return "Rebirth " .. n .. (n > 1 and " times" or " time")
	end
	return "???"
end

-- Значение цели (для world — 1).
function Q.GoalAmount(goal): number
	if goal.Type == "world" then
		return 1
	end
	return goal.N or 1
end

-- Короткие строчки награды для превью: { "💰 500", "🍀 Luck Potion", ... }.
function Q.RewardParts(reward): { string }
	local parts = {}
	if reward.Coins then
		table.insert(parts, "💰 " .. Q.Format(reward.Coins))
	end
	if reward.Potion then
		local def = ShopConfig.Potions[reward.Potion]
		if def then
			table.insert(parts, def.Icon .. " " .. def.Name)
		end
	end
	if reward.Hatch and Config.Eggs[reward.Hatch] then
		table.insert(parts, "🥚 Free " .. Config.Eggs[reward.Hatch].Name)
	end
	if reward.Bonus then
		table.insert(parts, "⭐ +" .. math.floor(reward.Bonus * 100 + 0.5) .. "% coins forever")
	end
	return parts
end

return Q
