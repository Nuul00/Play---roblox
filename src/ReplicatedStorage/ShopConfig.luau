-- Настройки магазинов и систем: магниты, зелья, достижения, команда питомцев.
-- Общий модуль для сервера и клиента (только данные и чистые функции).
local ShopConfig = {}

ShopConfig.MaxEquipped = 3

-- Магниты: носятся в руке, добавляют радиус к прокачке магнита из киоска.
-- Look описывает внешний вид (см. MagnetVisuals): цвет/материал корпуса, наконечники и украшения.
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local M = Enum.Material
local function magnet(id, name, price, bonus, look)
	return { Id = id, Name = name, Price = price, Bonus = bonus, Body = look.Body, Tip = look.Tip, Glow = look.Light ~= nil, Look = look, SkyOnly = look.SkyOnly }
end
ShopConfig.Magnets = {
	magnet(1, "Classic Magnet", 0, 0, { Body = rgb(150, 155, 165), Material = M.Metal, Tip = rgb(225, 230, 235), TipMaterial = M.Metal, Stripe = rgb(255, 200, 40), StripeMaterial = M.SmoothPlastic }),
	magnet(2, "Leather Magnet", 150, 0.5, { Body = rgb(120, 70, 40), Material = M.Leather, Tip = rgb(190, 195, 200), TipMaterial = M.Metal, Straps = rgb(170, 170, 175) }),
	magnet(3, "Emerald Circuit", 400, 1, { Body = rgb(20, 90, 60), Material = M.Metal, Tip = rgb(200, 255, 220), Stripe = rgb(60, 255, 140), Gem = rgb(40, 230, 120), Trim = rgb(30, 60, 45) }),
	magnet(4, "Frost Crystal", 900, 1.5, { Body = rgb(150, 210, 255), Material = M.Ice, Tip = rgb(235, 250, 255), Crystals = rgb(190, 235, 255), CrystalCount = 7 }),
	magnet(5, "Lava Magnet", 1800, 2, { Body = rgb(45, 30, 28), Material = M.CrackedLava, Tip = rgb(255, 150, 40), TipMaterial = M.Neon, Lava = rgb(255, 110, 20), Light = rgb(255, 120, 40) }),
	magnet(6, "Royal Wings", 3500, 2.7, { Body = rgb(255, 195, 50), Material = M.Foil, Tip = rgb(255, 245, 210), Wings = rgb(255, 250, 240), Crown = rgb(255, 210, 60), CrownGem = rgb(220, 40, 60), Trim = rgb(200, 150, 30) }),
	magnet(7, "Holy Star", 6000, 3.4, { Body = rgb(245, 245, 250), Material = M.Marble, Tip = rgb(255, 220, 110), TipMaterial = M.Foil, Stripe = rgb(255, 200, 60), StripeMaterial = M.Foil, Star = rgb(255, 215, 70), Light = rgb(255, 240, 190) }),
	magnet(8, "Starry Night", 10000, 4.2, { Body = rgb(70, 40, 140), Material = M.SmoothPlastic, Tip = rgb(220, 200, 255), Sparkles = rgb(255, 240, 160), Moon = rgb(255, 220, 110) }),
	magnet(9, "Cyber Void", 16000, 5, { Body = rgb(25, 20, 40), Material = M.Metal, Tip = rgb(200, 90, 255), TipMaterial = M.Neon, Stripe = rgb(180, 70, 255), Orb = rgb(200, 100, 255), Trim = rgb(90, 90, 110), Light = rgb(180, 80, 255) }),
	magnet(10, "Thunder Strike", 25000, 6, { Body = rgb(30, 120, 140), Material = M.Metal, Tip = rgb(150, 245, 255), TipMaterial = M.Neon, Lightning = rgb(120, 230, 255), Light = rgb(120, 220, 255) }),
	magnet(11, "Galaxy Ring", 40000, 7, { Body = rgb(40, 30, 90), Material = M.Glass, Tip = rgb(255, 150, 230), TipMaterial = M.Neon, Sparkles = rgb(255, 255, 255), Ring = rgb(150, 200, 255), Orb = rgb(255, 140, 220), Trim = rgb(120, 110, 200), Light = rgb(160, 140, 255) }),
	magnet(12, "Sakura Bloom", 60000, 8.2, { Body = rgb(255, 180, 210), Material = M.SmoothPlastic, Tip = rgb(255, 245, 250), Flowers = rgb(255, 120, 170) }),
	magnet(13, "Magma Shard", 90000, 9.5, { Body = rgb(60, 25, 20), Material = M.Basalt, Tip = rgb(255, 90, 20), TipMaterial = M.Neon, Crystals = rgb(255, 80, 30), CrystalCount = 6, Lava = rgb(255, 140, 30), Light = rgb(255, 90, 30) }),
	magnet(14, "Ruby King", 130000, 11, { Body = rgb(180, 20, 40), Material = M.Glass, Tip = rgb(255, 210, 70), TipMaterial = M.Foil, Stripe = rgb(255, 205, 60), StripeMaterial = M.Foil, Crown = rgb(255, 205, 60), CrownGem = rgb(255, 60, 90), Gem = rgb(255, 40, 70) }),
	magnet(15, "Frost Dragon", 200000, 12.5, { Body = rgb(200, 210, 225), Material = M.Metal, Tip = rgb(150, 230, 255), TipMaterial = M.Neon, Wings = rgb(170, 220, 255), Gem = rgb(90, 200, 255), Crystals = rgb(200, 240, 255), CrystalCount = 4, Light = rgb(140, 210, 255) }),
	magnet(16, "Amethyst Geode", 300000, 14, { Body = rgb(110, 50, 160), Material = M.Slate, Tip = rgb(230, 190, 255), Crystals = rgb(190, 110, 255), CrystalCount = 9, Gem = rgb(210, 140, 255), Light = rgb(190, 110, 255) }),
	magnet(17, "Vine Garden", 450000, 16, { Body = rgb(110, 75, 45), Material = M.Wood, Tip = rgb(150, 230, 120), Vines = rgb(60, 150, 60), Flowers = rgb(255, 255, 255), FlowerSpots = { 0.25, 0.5, 0.75 } }),
	magnet(18, "Sun & Moon", 650000, 18, { Body = rgb(30, 70, 170), Material = M.SmoothPlastic, Tip = rgb(255, 215, 90), TipMaterial = M.Foil, Sun = rgb(255, 200, 50), Moon = rgb(240, 240, 255), Sparkles = rgb(255, 245, 200), Light = rgb(255, 220, 140) }),
	magnet(19, "Void Vortex", 900000, 20, { Body = rgb(15, 10, 25), Material = M.Glass, Tip = rgb(120, 60, 255), TipMaterial = M.Neon, Swirl = rgb(150, 80, 255), Stripe = rgb(90, 40, 200), Light = rgb(120, 60, 255) }),
	magnet(20, "Prism Diamond", 1500000, 23, {
		Body = rgb(255, 255, 255),
		Material = M.Glass,
		SegmentColor = function(t)
			return Color3.fromHSV(t * 0.85, 0.75, 1)
		end,
		Tip = rgb(240, 255, 255),
		TipMaterial = M.Neon,
		Gem = rgb(220, 250, 255),
		GemMaterial = M.Glass,
		Sparkles = rgb(255, 255, 255),
		Light = rgb(255, 255, 255),
	}),
	-- Магниты Sky Isles (21-30): продаются только в облачном мире (SkyOnly), по арту пользователя.
	magnet(21, "Cotton Candy", 2500000, 26, { SkyOnly = true, Body = rgb(255, 185, 215), Material = M.SmoothPlastic, Tip = rgb(255, 245, 250), Puffs = rgb(255, 170, 210), Bow = rgb(255, 120, 175), Light = rgb(255, 190, 225) }),
	magnet(22, "Bubblegum Pop", 4000000, 30, { SkyOnly = true, Body = rgb(255, 140, 200), Material = M.Glass, Tip = rgb(255, 230, 245), Bubbles = rgb(255, 200, 235), Bow = rgb(120, 190, 255), Sparkles = rgb(255, 255, 255) }),
	magnet(23, "Rainbow Star", 6500000, 34, {
		SkyOnly = true,
		Body = rgb(255, 255, 255),
		Material = M.SmoothPlastic,
		SegmentColor = function(t)
			return Color3.fromHSV((1 - t) * 0.82, 0.65, 1)
		end,
		Tip = rgb(255, 255, 255),
		Star = rgb(255, 225, 110),
		Puffs = rgb(255, 255, 255),
		Light = rgb(255, 240, 220),
	}),
	magnet(24, "Angel Wings", 10000000, 39, { SkyOnly = true, Body = rgb(255, 252, 240), Material = M.Marble, Tip = rgb(255, 215, 100), TipMaterial = M.Foil, Wings = rgb(255, 255, 255), Halo = rgb(255, 225, 120), Star = rgb(255, 235, 150), Light = rgb(255, 240, 190) }),
	magnet(25, "Crystal Frost", 15000000, 45, { SkyOnly = true, Body = rgb(165, 215, 255), Material = M.Glass, Tip = rgb(235, 250, 255), Crystals = rgb(190, 235, 255), CrystalCount = 10, Gem = rgb(210, 245, 255), Puffs = rgb(235, 245, 255), Light = rgb(170, 225, 255) }),
	magnet(26, "Sundae Swirl", 23000000, 52, { SkyOnly = true, Body = rgb(255, 235, 215), Material = M.SmoothPlastic, Tip = rgb(255, 150, 190), Puffs = rgb(255, 205, 225), Cherry = rgb(220, 30, 60), Bow = rgb(150, 100, 70) }),
	magnet(27, "Heart Nebula", 35000000, 60, {
		SkyOnly = true,
		Body = rgb(150, 180, 255),
		Material = M.Glass,
		SegmentColor = function(t)
			return Color3.fromHSV(0.55 + t * 0.35, 0.6, 1)
		end,
		Tip = rgb(255, 180, 240),
		TipMaterial = M.Neon,
		Heart = rgb(255, 150, 220),
		Sparkles = rgb(255, 255, 255),
		Light = rgb(200, 170, 255),
	}),
	magnet(28, "Midnight Wish", 55000000, 70, { SkyOnly = true, Body = rgb(60, 40, 130), Material = M.SmoothPlastic, Tip = rgb(255, 225, 130), TipMaterial = M.Foil, Moon = rgb(255, 225, 130), Sparkles = rgb(255, 245, 190), Star = rgb(255, 225, 130), Light = rgb(180, 160, 255) }),
	magnet(29, "Comet Tail", 85000000, 82, { SkyOnly = true, Body = rgb(70, 50, 150), Material = M.Glass, Tip = rgb(150, 235, 255), TipMaterial = M.Neon, Swirl = rgb(190, 150, 255), Ring = rgb(255, 215, 120), Sparkles = rgb(255, 255, 255), Orb = rgb(160, 235, 255), Light = rgb(170, 220, 255) }),
	magnet(30, "Lollipop Crown", 150000000, 100, { SkyOnly = true, Body = rgb(255, 160, 205), Material = M.SmoothPlastic, Tip = rgb(255, 220, 120), TipMaterial = M.Foil, Crown = rgb(255, 205, 80), CrownGem = rgb(255, 90, 160), Lollipops = rgb(255, 120, 180), Bow = rgb(255, 255, 255), Sparkles = rgb(255, 245, 200), Light = rgb(255, 200, 235) }),
}


-- Зелья действуют 5 минут, повторное использование продлевает время.
ShopConfig.PotionOrder = { "Coins", "Speed", "Luck" }
ShopConfig.Potions = {
	Coins = { Name = "Coin Potion", Icon = "💰", Effect = "x2 coins", Price = 400, Duration = 300, Color = Color3.fromRGB(255, 200, 50) },
	Speed = { Name = "Speed Potion", Icon = "⚡", Effect = "x1.5 walk speed", Price = 300, Duration = 300, Color = Color3.fromRGB(80, 180, 255) },
	Luck = { Name = "Luck Potion", Icon = "🍀", Effect = "x2 egg luck", Price = 600, Duration = 300, Color = Color3.fromRGB(90, 220, 110) },
}

-- Достижения: каждое навсегда даёт x1.05 к монетам (умножается на остальные бонусы).
ShopConfig.BadgeBonus = 1.05
ShopConfig.Badges = {
	{ Id = "Pickup100", Name = "First Steps", Desc = "Pick up 100 coins", Stat = "CoinsCollected", Goal = 100, Icon = "👣" },
	{ Id = "Pickup1000", Name = "Coin Collector", Desc = "Pick up 1,000 coins", Stat = "CoinsCollected", Goal = 1000, Icon = "🪙" },
	{ Id = "Eggs10", Name = "Egg Opener", Desc = "Open 10 eggs", Stat = "EggsOpened", Goal = 10, Icon = "🥚" },
	{ Id = "Eggs100", Name = "Egg Master", Desc = "Open 100 eggs", Stat = "EggsOpened", Goal = 100, Icon = "🐣" },
	{ Id = "Rich", Name = "Rich", Desc = "Earn 100,000 coins", Stat = "LifetimeEarned", Goal = 100000, Icon = "💎" },
	{ Id = "Index12", Name = "Explorer", Desc = "Discover 12 pets", Stat = "PetsDiscovered", Goal = 12, Icon = "📖" },
}

-- Уровни прокачки красятся по ступеням: бронза, серебро, золото, алмаз.
ShopConfig.TierColors = {
	Color3.fromRGB(205, 127, 50),
	Color3.fromRGB(200, 205, 215),
	Color3.fromRGB(255, 200, 50),
	Color3.fromRGB(110, 230, 255),
}
function ShopConfig.TierColor(level: number, max: number): Color3
	local tier = math.clamp(math.floor(level / math.max(max, 1) * 4) + 1, 1, 4)
	return ShopConfig.TierColors[tier]
end

-- Бонус команды: 1 + сумма (x - 1) надетых питомцев. Три питомца x2 дают x4.
function ShopConfig.TeamBonus(multipliers: { number }): number
	local bonus = 1
	for _, m in ipairs(multipliers) do
		bonus += m - 1
	end
	return bonus
end

function ShopConfig.ParseEquipped(text: string?): { number }
	local list = {}
	for id in string.gmatch(text or "", "%d+") do
		table.insert(list, tonumber(id) :: number)
	end
	return list
end

-- ===== Гарантия (pity) =====
-- Счётчик растёт на каждого открытого питомца (x3 = три шага). Выпала редкость не ниже
-- указанной — счётчик сбрасывается. Дошёл до порога — следующий питомец этой редкости
-- гарантирован (берётся из пула того яйца, которое открывают). Проверка идёт сверху вниз.
ShopConfig.Pity = {
	{ Rarity = "Secret", Threshold = 2000 },
	{ Rarity = "Legendary", Threshold = 100 },
}
ShopConfig.RarityRank = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Mythic = 5, Legendary = 6, Secret = 7 }
-- Объявление на весь сервер начиная с этой редкости.
ShopConfig.AnnounceRank = 6

-- ===== Постоянные бонусы =====
-- За каждую полностью собранную и забранную страницу индекса (все питомцы одного яйца).
ShopConfig.IndexBonusPerPage = 0.05
-- За каждого друга на сервере, с потолком.
ShopConfig.FriendBonusEach = 0.1
ShopConfig.FriendBonusMax = 0.5
-- ===== Мировые события =====
-- Раз в Interval секунд на весь сервер включается следующее событие из списка на Duration секунд.
-- Сервер пишет в workspace атрибуты EventId и EventEnd (серверное время), клиенты рисуют таймер.
ShopConfig.EventInterval = 15 * 60
ShopConfig.EventFirstDelay = 5 * 60
ShopConfig.Events = {
	{ Id = "Golden", Name = "GOLDEN HOUR", Desc = "x2 coins for everyone!", Duration = 180, Icon = "💰", Color = Color3.fromRGB(255, 200, 60) },
	{ Id = "Lucky", Name = "LUCKY HOUR", Desc = "Luck boost on every egg!", Duration = 180, Icon = "🍀", Color = Color3.fromRGB(90, 220, 120) },
}

return ShopConfig
