-- Донат-магазин: геймпассы (покупаются один раз навсегда) и продукты (можно покупать снова).
-- Id создаются в Roblox (Creator Dashboard или Open Cloud); 0 — ещё не создан, в магазине не показывается.
local StoreConfig = {}

StoreConfig.Passes = {
	{ Key = "Coins2x", Id = 2067944455, Name = "2x Coins", Desc = "Double coins from everything, forever", Color = Color3.fromRGB(255, 200, 60) },
	{ Key = "Luck2x", Id = 2067302561, Name = "2x Luck", Desc = "Every egg rolls twice — rare pets twice as often", Random = true, Color = Color3.fromRGB(90, 220, 110) },
	{ Key = "PetSlots", Id = 2066816547, Name = "+3 Pet Slots", Desc = "Equip 3 more pets at once", Color = Color3.fromRGB(255, 150, 40) },
	{ Key = "VIP", Id = 2069984395, Name = "VIP", Desc = "+25% coins, golden [VIP] chat tag", Color = Color3.fromRGB(255, 215, 80) },
	{ Key = "FastHatch", Id = 2068076497, Name = "Fast Hatch", Desc = "Eggs hatch 3x faster", Color = Color3.fromRGB(120, 200, 255) },
	{ Key = "SuperMagnet", Id = 2070158347, Name = "Super Magnet", Desc = "2x magnet radius (up to 80 studs)", Color = Color3.fromRGB(110, 140, 255) },
	{ Key = "SuperLuck", Id = 2067554513, Name = "Super Luck", Desc = "+2 egg rolls · 2x Super Secret chance", Random = true, Color = Color3.fromRGB(90, 170, 255) },
	{ Key = "MythicLuck", Id = 2067596576, Name = "Mythic Luck", Desc = "+1 egg roll · 2x Super Secret chance (3x with Super Luck)", Random = true, Color = Color3.fromRGB(240, 90, 220) },
}

-- Random = true: влияет на случайные награды (яйца) — в странах, где платные случайные предметы
-- запрещены (PolicyService.ArePaidRandomItemsRestricted), такие товары не показываются.
-- Монеты в паках считаются от прогресса игрока: доля от всех заработанных монет (не меньше Min),
-- чтобы пак был полезен и новичку, и тому, кто уже далеко.
StoreConfig.Products = {
	{ Key = "CoinsSmall", Id = 3728499048, Name = "Coin Pack", Desc = "Coins = 5% of all you've earned", Kind = "coins", Share = 0.05, Random = true, Min = 2500, Color = Color3.fromRGB(255, 200, 60) },
	{ Key = "CoinsMedium", Id = 3728499058, Name = "Big Coin Pack", Desc = "Coins = 15% of all you've earned", Kind = "coins", Share = 0.15, Random = true, Min = 10000, Color = Color3.fromRGB(255, 170, 40) },
	{ Key = "CoinsHuge", Id = 3728499068, Name = "Huge Coin Pack", Desc = "Coins = 35% of all you've earned", Kind = "coins", Share = 0.35, Random = true, Min = 50000, Color = Color3.fromRGB(255, 130, 30) },
	{ Key = "Potions", Id = 3728499075, Name = "Potion Pack", Desc = "3 Coin, 3 Speed and 3 Luck potions", Kind = "potions", Count = 3, Random = true, Color = Color3.fromRGB(180, 120, 255) },
	{ Key = "LuckBoost", Id = 3728499085, Name = "Luck Boost", Desc = "x2 egg luck for 15 minutes", Kind = "luck", Seconds = 900, Random = true, Color = Color3.fromRGB(90, 220, 110) },
}

function StoreConfig.PassByKey(key: string)
	for _, p in ipairs(StoreConfig.Passes) do
		if p.Key == key then
			return p
		end
	end
	return nil
end

return StoreConfig
