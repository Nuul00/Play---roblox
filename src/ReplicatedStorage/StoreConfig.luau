-- Донат-магазин: геймпассы (покупаются один раз навсегда) и продукты (можно покупать снова).
-- Id создаются в Roblox (Creator Dashboard или Open Cloud); 0 — ещё не создан, в магазине не показывается.
local StoreConfig = {}

StoreConfig.Passes = {
	{ Key = "Coins2x", Id = 2067944455, Name = "2x Coins", Desc = "Double coins from everything, forever", Color = Color3.fromRGB(255, 200, 60) },
	{ Key = "Luck2x", Id = 2067302561, Name = "2x Luck", Desc = "Every egg rolls twice — rare pets twice as often", Random = true, Color = Color3.fromRGB(90, 220, 110) },
	{ Key = "PetSlots", Id = 2066816547, Name = "+3 Pet Slots", Desc = "Equip 3 more pets at once", Color = Color3.fromRGB(255, 150, 40) },
	{ Key = "VIP", Id = 2069984395, Name = "VIP", Desc = "+50% coins, golden [VIP] tag above your head and in chat, VIP aura", Color = Color3.fromRGB(255, 215, 80) },
	{ Key = "FastHatch", Id = 2068076497, Name = "Fast Hatch", Desc = "Eggs hatch 3x faster", Color = Color3.fromRGB(120, 200, 255) },
	{ Key = "SuperMagnet", Id = 2070158347, Name = "Super Magnet", Desc = "2x magnet radius (up to 80 studs)", Color = Color3.fromRGB(110, 140, 255) },
	{ Key = "SuperLuck", Id = 2067554513, Name = "Super Luck", Desc = "+2 egg rolls · 2x Super Secret chance", Random = true, Color = Color3.fromRGB(90, 170, 255) },
	-- Открытие ×9 и автооткрытие яиц. Id = 0, пока пасс не создан в Creator Dashboard — тогда
	-- функции бесплатны для всех. Кто играл до введения пассов, получает их бесплатно навсегда.
	{ Key = "Hatch9", Id = 2075900816, Name = "×9 Hatch", Desc = "Open 9 eggs at once", Color = Color3.fromRGB(190, 120, 255) },
	{ Key = "AutoHatch", Id = 2075384801, Name = "Auto Hatch", Desc = "Eggs open automatically while you stand by them", Color = Color3.fromRGB(255, 120, 170) },
	{ Key = "GoldenHatch", Id = 2074754833, Name = "Golden Hatch", Desc = "5% chance a hatched pet comes out Golden", Random = true, Color = Color3.fromRGB(255, 205, 60) },
	{ Key = "QuickTravel", Id = 2075480804, Name = "Quick Travel", Desc = "Teleport to any egg or shop in your world", Color = Color3.fromRGB(110, 210, 255) },
	{ Key = "RoyalAura", Id = 2074766782, Name = "Royal Aura", Desc = "Sparkling golden aura and crown (cosmetic)", Color = Color3.fromRGB(255, 225, 120) },
	{ Key = "MythicLuck", Id = 2067596576, Name = "Mythic Luck", Desc = "+3 egg rolls · 3x Super Secret chance (best luck pass)", Random = true, Color = Color3.fromRGB(240, 90, 220) },
}

-- Random = true: влияет на случайные награды (яйца) — в странах, где платные случайные предметы
-- запрещены (PolicyService.ArePaidRandomItemsRestricted), такие товары не показываются.
-- Монеты в паках считаются от прогресса игрока: доля от всех заработанных монет (не меньше Min),
-- чтобы пак был полезен и новичку, и тому, кто уже далеко.
StoreConfig.Products = {
	{ Key = "CoinsSmall", Id = 3728499048, Name = "Coin Pack", Desc = "Coins = 5% of all you've earned", Kind = "coins", Share = 0.05, Random = true, Min = 2500, Color = Color3.fromRGB(255, 200, 60) },
	{ Key = "CoinsMedium", Id = 3728499058, Name = "Big Coin Pack", Desc = "Coins = 15% of all you've earned", Kind = "coins", Share = 0.15, Random = true, Min = 10000, Color = Color3.fromRGB(255, 170, 40) },
	{ Key = "CoinsHuge", Id = 3728499068, Name = "Huge Coin Pack", Desc = "Coins = 35% of all you've earned", Kind = "coins", Share = 0.35, Random = true, Min = 50000, Color = Color3.fromRGB(255, 130, 30) },
	{ Key = "Potions", Id = 3728499075, Name = "Super Potion Pack", Desc = "3 SUPER Coin (x3), 3 SUPER Speed and 3 SUPER Luck potions, 10 min each", Kind = "potions", Count = 3, Random = true, Color = Color3.fromRGB(180, 120, 255) },
	-- Royal Egg за Robux: ×1 и ×3 открытия (случайно — шансы в окне яйца; Random = true).
	{ Key = "RoyalEgg1", Id = 0, Name = "Royal Egg ×1", Desc = "Open 1 Royal Egg", Kind = "royalegg", Count = 1, Random = true, Hidden = true, Color = Color3.fromRGB(255, 200, 70) },
	{ Key = "RoyalEgg3", Id = 0, Name = "Royal Egg ×3", Desc = "Open 3 Royal Eggs", Kind = "royalegg", Count = 3, Random = true, Hidden = true, Color = Color3.fromRGB(255, 170, 50) },
	-- Эксклюзивный питомец (не случайный): питомец «Royal …» лучшего открытого мира игрока.
	{ Key = "ExclusivePet", Id = 0, Name = "Royal Pet", Desc = "Exclusive Royal pet of your best world (x1.5 its top Secret)", Kind = "pet", Color = Color3.fromRGB(255, 210, 90) },
	-- Разовый набор новичка (R$49–99). Id = 0, пока продукт не создан в Creator Dashboard.
	{ Key = "StarterPack", Id = 0, Name = "Starter Pack", Desc = "One time: 3 SUPER Luck + 3 SUPER Coin potions, 3 Coin Rush keys and coins = 20% of all you've earned", Kind = "starter", Share = 0.2, Min = 5000, Count = 3, Random = true, Color = Color3.fromRGB(255, 120, 170) },
	{ Key = "LuckBoost", Id = 3728499085, Name = "Luck Boost", Desc = "x2 egg luck for 15 minutes", Kind = "luck", Seconds = 900, Random = true, Color = Color3.fromRGB(90, 220, 110) },
}

-- Есть ли у игрока функция пасса: куплен, выдан старому игроку бесплатно, или пасс ещё не создан.
function StoreConfig.HasPassFeature(p: Player, key: string): boolean
	local def = StoreConfig.PassByKey(key)
	if not def or (def.Id or 0) <= 0 then
		return true
	end
	return p:GetAttribute("Pass_" .. key) == true or p:GetAttribute("Save_Free" .. key) == true
end

function StoreConfig.PassByKey(key: string)
	for _, p in ipairs(StoreConfig.Passes) do
		if p.Key == key then
			return p
		end
	end
	return nil
end

return StoreConfig
