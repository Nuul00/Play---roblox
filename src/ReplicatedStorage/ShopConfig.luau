-- Настройки магазинов и систем: магниты, зелья, достижения, команда питомцев.
-- Общий модуль для сервера и клиента (только данные и чистые функции).
local ShopConfig = {}

ShopConfig.MaxEquipped = 3

-- Магниты: носятся в руке, добавляют радиус к прокачке магнита из киоска.
ShopConfig.Magnets = {
	{ Id = 1, Name = "Starter Magnet", Price = 0, Bonus = 0, Body = Color3.fromRGB(215, 55, 55), Tip = Color3.fromRGB(215, 220, 230), Glow = false },
	{ Id = 2, Name = "Iron Magnet", Price = 300, Bonus = 1.5, Body = Color3.fromRGB(95, 100, 115), Tip = Color3.fromRGB(90, 170, 255), Glow = false },
	{ Id = 3, Name = "Golden Magnet", Price = 2500, Bonus = 3.5, Body = Color3.fromRGB(255, 190, 40), Tip = Color3.fromRGB(255, 245, 200), Glow = false },
	{ Id = 4, Name = "Diamond Magnet", Price = 15000, Bonus = 6, Body = Color3.fromRGB(110, 220, 255), Tip = Color3.fromRGB(240, 255, 255), Glow = true },
	{ Id = 5, Name = "Neon Magnet", Price = 60000, Bonus = 10, Body = Color3.fromRGB(255, 70, 210), Tip = Color3.fromRGB(80, 240, 255), Glow = true },
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

return ShopConfig
