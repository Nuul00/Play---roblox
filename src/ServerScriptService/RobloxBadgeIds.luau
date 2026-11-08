-- Ачивки игры -> настоящие бейджи Roblox (попадают в инвентарь и профиль игрока на сайте Roblox).
-- Бейдж создаётся вручную: create.roblox.com -> Coin Sprint -> Associated Items -> Badges -> Create a Badge.
-- После создания впиши его номер (Badge ID из адреса страницы бейджа) напротив нужной ачивки.
-- 0 — бейдж ещё не создан, такая ачивка остаётся только внутри игры. Выдаёт RobloxBadges.server.luau.
return {
	-- Coin Collector
	Pickup100 = 0, -- I   · Pick up 100 coins
	Pickup1000 = 0, -- II  · Pick up 1K coins
	CoinsCollected10000 = 0, -- III · Pick up 10K coins
	CoinsCollected50000 = 0, -- IV  · Pick up 50K coins
	CoinsCollected250000 = 0, -- V   · Pick up 250K coins
	CoinsCollected1000000 = 0, -- VI  · Pick up 1M coins
	CoinsCollected5000000 = 0, -- VII · Pick up 5M coins
	-- Egg Master
	Eggs10 = 0, -- I   · Open 10 eggs
	Eggs100 = 0, -- II  · Open 100 eggs
	EggsOpened500 = 0, -- III · Open 500 eggs
	EggsOpened2500 = 0, -- IV  · Open 2.5K eggs
	EggsOpened10000 = 0, -- V   · Open 10K eggs
	EggsOpened50000 = 0, -- VI  · Open 50K eggs
	-- Rich
	Rich = 0, -- I   · Earn 100K coins
	LifetimeEarned100000000 = 0, -- II  · 100M
	LifetimeEarned10000000000 = 0, -- III · 10B
	LifetimeEarned1000000000000 = 0, -- IV  · 1T
	LifetimeEarned100000000000000 = 0, -- V   · 100T
	LifetimeEarned10000000000000000 = 0, -- VI  · 10Qa
	LifetimeEarned1000000000000000000 = 0, -- VII · 1Qi
	-- Explorer
	Index12 = 0, -- I   · Discover 12 pets
	PetsDiscovered25 = 0, -- II
	PetsDiscovered40 = 0, -- III
	PetsDiscovered60 = 0, -- IV
	PetsDiscovered80 = 0, -- V
	PetsDiscovered100 = 0, -- VI
	-- Reborn
	Rebirths1 = 0, -- I    · 1 rebirth
	Rebirths3 = 0, -- II
	Rebirths5 = 0, -- III
	Rebirths10 = 0, -- IV
	Rebirths15 = 0, -- V
	Rebirths25 = 0, -- VI
	Rebirths35 = 0, -- VII
	Rebirths50 = 0, -- VIII
	-- Magnet Fan
	MagnetTier5 = 0, -- I   · Own magnet #5
	MagnetTier10 = 0, -- II
	MagnetTier20 = 0, -- III
	MagnetTier30 = 0, -- IV
	MagnetTier40 = 0, -- V
	MagnetTier50 = 0, -- VI
	MagnetTier60 = 0, -- VII
	-- Vault Raider (Coin Rush)
	Rush1 = 0, -- I   · Finish 1 run
	Rush5 = 0, -- II
	Rush25 = 0, -- III
	Rush100 = 0, -- IV
	-- Combo King
	Combo15 = 0, -- I   · 15-coin combo
	Combo40 = 0, -- II
	Combo80 = 0, -- III
	Combo150 = 0, -- IV
}
