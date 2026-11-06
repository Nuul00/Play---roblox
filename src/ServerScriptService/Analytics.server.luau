-- Аналитика Roblox (AnalyticsService): воронка новичка, экономика монет, прогресс по мирам,
-- ребёрсам и квестам. Все данные видны в Creator Dashboard → Analytics.
-- Скрипт только СЛУШАЕТ (атрибуты игрока и сигналы ServerSignals), игровую логику не трогает.
-- Монеты с подбора не шлём по одной: копим и отправляем одним событием раз в минуту.
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local Worlds = require(ReplicatedStorage:WaitForChild("WorldsConfig"))

local Flow = Enum.AnalyticsEconomyFlowType
local Tx = Enum.AnalyticsEconomyTransactionType
local CURRENCY = "Coins"

local function safe(f, ...)
	local ok, err = pcall(f, AnalyticsService, ...)
	if not ok then
		warn("[Analytics]", err)
	end
end
local function balance(p: Player): number
	local stats = p:FindFirstChild("leaderstats")
	local c = stats and stats:FindFirstChild("Coins")
	return c and math.floor(math.min(c.Value, 1e300)) or 0
end
local function economy(p: Player, flow, amount: number, tx: string, sku: string)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	safe(AnalyticsService.LogEconomyEvent, p, flow, CURRENCY, amount, balance(p), tx, sku)
end

-- ===== Воронка новичка: каждый шаг один раз за всю жизнь профиля (флаги Save_ сохраняются) =====
local ONBOARD = { "Joined", "FirstCoin", "FirstUpgrade", "FirstEgg" }
local function onboard(p: Player, step: number, name: string)
	if not p:GetAttribute("Save_OnbEligible") or p:GetAttribute("Save_Onb" .. step) then
		return
	end
	p:SetAttribute("Save_Onb" .. step, true)
	safe(AnalyticsService.LogOnboardingFunnelStepEvent, p, step, name)
end

local UPGRADE_COST = {
	MagnetLevel = Config.GetMagnetUpgradeCost,
	IncomeLevel = Config.GetIncomeUpgradeCost,
	DoubleLevel = Config.GetDoubleUpgradeCost,
}
local WORLD_INDEX = {}
for i, def in ipairs(Worlds.Worlds) do
	WORLD_INDEX[def.Id] = i
end

local pickup: { [Player]: number } = {}
local lastCoins: { [Player]: number } = {}

local function flushPickups(p: Player)
	local sum = pickup[p]
	pickup[p] = nil
	if sum and sum >= 1 then
		economy(p, Flow.Source, sum, Tx.Gameplay.Name, "CoinPickup")
	end
end

local function track(p: Player)
	-- снимок значений после загрузки профиля: рост после этого = действие игрока
	local snap = {}
	local function num(name)
		return tonumber(p:GetAttribute(name)) or 0
	end
	for _, n in ipairs({ "MagnetLevel", "IncomeLevel", "DoubleLevel", "MagnetTier", "Rebirths", "EggsOpened", "CoinsCollected", "DailyDay", "Save_QuestLineStep" }) do
		snap[n] = num(n)
	end
	-- новичок: ещё ничего не заработал и не начинал квесты
	if num("LifetimeEarned") <= 0 and num("Save_QuestLineStep") <= 1 and not p:GetAttribute("Save_Onb1") then
		p:SetAttribute("Save_OnbEligible", true)
	end
	onboard(p, 1, ONBOARD[1])

	local stats = p:WaitForChild("leaderstats", 30)
	local coins = stats and stats:WaitForChild("Coins", 10)
	local speed = stats and stats:WaitForChild("SpeedLevel", 10)
	if coins then
		lastCoins[p] = coins.Value
		coins.Changed:Connect(function(v)
			lastCoins[p] = v
		end)
	end
	if speed then
		local old = speed.Value
		speed.Changed:Connect(function(v)
			if v > old and (p:GetAttribute("Rebirths") or 0) == snap.Rebirths then
				local spent = 0
				for lvl = old, v - 1 do
					spent += Config.GetUpgradeCost(lvl)
				end
				economy(p, Flow.Sink, spent, Tx.Shop.Name, "Upgrade_Speed")
				onboard(p, 3, ONBOARD[3])
			end
			old = v
		end)
	end

	p.AttributeChanged:Connect(function(name)
		local new = num(name)
		local old = snap[name]
		if old == nil then
			-- открытие мира (атрибут UnlockKey)
			for _, def in ipairs(Worlds.Worlds) do
				if name == Worlds.UnlockKey(def.Id) and p:GetAttribute(name) == true and (def.Cost or 0) > 0 then
					economy(p, Flow.Sink, def.Cost, Tx.Shop.Name, "World_" .. def.Id)
					safe(AnalyticsService.LogProgressionEvent, p, "Worlds", Enum.AnalyticsProgressionType.Complete, WORLD_INDEX[def.Id] or 0, def.Id)
					if def.Id == "Neon District" then
						onboard(p, 15, "UnlockNeon")
					end
				end
			end
			return
		end
		snap[name] = new
		if name == "Rebirths" then
			if new > old then
				-- монеты уже обнулены: сколько было перед ребёрсом — последнее известное значение
				safe(AnalyticsService.LogProgressionEvent, p, "Rebirth", Enum.AnalyticsProgressionType.Complete, new, "Rebirth" .. new)
			end
			-- уровни прокачки сброшены — новые точки отсчёта
			for _, n in ipairs({ "MagnetLevel", "IncomeLevel", "DoubleLevel" }) do
				snap[n] = num(n)
			end
			return
		end
		if new <= old then
			return
		end
		if UPGRADE_COST[name] then
			local spent = 0
			for lvl = old, new - 1 do
				spent += UPGRADE_COST[name](lvl)
			end
			economy(p, Flow.Sink, spent, Tx.Shop.Name, "Upgrade_" .. string.gsub(name, "Level", ""))
			onboard(p, 3, ONBOARD[3])
		elseif name == "MagnetTier" then
			local def = ShopConfig.Magnets[new]
			if def then
				economy(p, Flow.Sink, def.Price, Tx.Shop.Name, "Magnet" .. new)
			end
		elseif name == "CoinsCollected" and old == 0 then
			onboard(p, 2, ONBOARD[2])
		elseif name == "DailyDay" then
			safe(AnalyticsService.LogCustomEvent, p, "DailyClaim", new)
		elseif name == "Save_QuestLineStep" then
			local done = new - 1
			if done < 1 then
				return
			end
			safe(AnalyticsService.LogProgressionEvent, p, "QuestLine", Enum.AnalyticsProgressionType.Complete, done, "Quest" .. done)
			if done <= 10 then
				onboard(p, 4 + done, "Quest" .. done)
			end
		end
	end)
end

local function onPlayer(p: Player)
	if p:GetAttribute("ProfileReady") then
		track(p)
		return
	end
	local conn
	conn = p:GetAttributeChangedSignal("ProfileReady"):Connect(function()
		if p:GetAttribute("ProfileReady") then
			conn:Disconnect()
			track(p)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end
Players.PlayerRemoving:Connect(function(p)
	flushPickups(p)
	lastCoins[p] = nil
end)

-- сигналы из GameServer / Monetization
task.spawn(function()
	local signals = ServerStorage:WaitForChild("ServerSignals", 60)
	if not signals then
		return
	end
	local packs = signals:FindFirstChild("CoinPackGranted") or Instance.new("BindableEvent")
	packs.Name = "CoinPackGranted"
	packs.Parent = signals
	packs.Event:Connect(function(p, key, amount)
		economy(p, Flow.Source, amount, Tx.IAP.Name, key)
	end)
	local coin = signals:WaitForChild("CoinCollected", 60)
	if coin then
		coin.Event:Connect(function(p, earned)
			if type(earned) == "number" and earned > 0 then
				pickup[p] = (pickup[p] or 0) + earned
			end
		end)
	end
	local eggs = signals:WaitForChild("EggsHatched", 60)
	if eggs then
		eggs.Event:Connect(function(p, eggId, amount)
			local egg = Config.Eggs[eggId]
			if egg then
				economy(p, Flow.Sink, egg.Cost * (amount or 1), Tx.Shop.Name, "Egg" .. eggId)
			end
			onboard(p, 4, ONBOARD[4])
		end)
	end
end)

-- накопленные монеты с подбора — раз в минуту
task.spawn(function()
	while true do
		task.wait(60)
		for p in pairs(pickup) do
			flushPickups(p)
		end
	end
end)
