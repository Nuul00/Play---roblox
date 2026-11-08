--!nocheck
-- Симулятор экономики Coin Sprint (2026-11). Запуск: вставить в execute_luau (Edit) в Studio —
-- берёт НАСТОЯЩИЕ формулы и таблицы из ReplicatedStorage.GameConfig (цены, яйца, питомцы, ребёрс).
-- Модель: игрок без доната и ивентов; каждые 5 с собирает монеты (скорость сбора ~ радиус × скорость
-- бега, потолок по респавну), жадно открывает следующий мир, яйца лучшего мира, самую дешёвую
-- прокачку и делает ребёрс. Неизвестная — K (монет/мин на «радиус × скорость»), калибруется аналитикой.
-- Параметры: PET_POWER (множитель питомца m считается как m^PET_POWER), K, HOURS.
return function(opts)
	opts = opts or {}
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))
	local PET_POWER = opts.petPower or 1
	local K = opts.k or 0.55
	local HOURS = opts.hours or 40
	local rng = Random.new(opts.seed or 1)
	local ORDER = { island = 0, neon = 1, sky = 2, frozen = 3, volcano = 4, galaxy = 5 }
	local NAMES = { "Neon", "Sky", "Frozen", "Volcano", "Galaxy" }
	local WORLD_COST = opts.worldCost or { 6e4, 25e6, 10e9, 1.2e12, 3e14 }
	local GATES = { [2] = { 0, 25 }, [3] = { 2, 42 }, [4] = { 4, 58 }, [5] = { 6, 72 } }
	local AVG = opts.avgCoin or { [0] = 4.5, 24.5, 192, 1008, 4480, 40768 }
	local TOOL = { [0] = 3, 7, 11, 15, 19, 24 }
	local eggs = {}
	for _, e in pairs(Config.Eggs) do
		table.insert(eggs, e)
	end
	local lv = { speed = 0, magnet = 0, income = 0, double = 0 }
	local costFn = { speed = Config.GetUpgradeCost, magnet = Config.GetMagnetUpgradeCost, income = Config.GetIncomeUpgradeCost, double = Config.GetDoubleUpgradeCost }
	local coins, world, reb, rebEggs, slots = 0, 0, 0, 0, 3
	local owned, index, nIndex = {}, {}, 0
	local log = {}
	local function teamMult()
		table.sort(owned, function(a, b)
			return a > b
		end)
		local b = 1
		for i = 1, math.min(slots, #owned) do
			b += owned[i] ^ PET_POWER - 1
		end
		return b
	end
	local team = 1
	local t = 0
	while t < HOURS * 3600 do
		t += 5
		local r = math.min(55, Config.GetMagnetRadius(lv.magnet) + TOOL[world])
		local v = Config.GetWalkSpeed(lv.speed)
		local cpm = math.min(K * r * v, 140 * 60 / 8)
		local mult = team * Config.GetIncomeMultiplier(lv.income) * Config.GetRebirthBonus(reb) * Config.GetSpeedCoinBonus(lv.speed) * (1 + Config.GetDoubleChance(lv.double)) * 1.25 ^ world
		coins += cpm / 12 * AVG[world] * mult
		local acted = false
		if world < 5 and coins >= WORLD_COST[world + 1] then
			local g = GATES[world + 1] or { 0, 0 }
			if reb >= g[1] and nIndex >= g[2] then
				coins -= WORLD_COST[world + 1]
				world += 1
				table.insert(log, string.format("%5.2f h %s (team x%.0f, rebirths %d)", t / 3600, NAMES[world], team, reb))
				if world == 5 then
					return t / 3600, log
				end
				acted = true
			end
		end
		if not acted and reb < Config.MaxRebirths and coins >= Config.GetRebirthCost(reb) and rebEggs >= Config.GetRebirthEggs(reb) then
			coins = 0
			for key in pairs(lv) do
				lv[key] = math.floor(lv[key] * 0.25)
			end
			reb += 1
			rebEggs = 0
			slots = 3 + Config.GetRebirthSlots(reb)
			acted = true
		end
		if not acted then
			local best
			for _, e in ipairs(eggs) do
				if (ORDER[e.World] or 9) <= world and e.Cost <= coins * 0.4 and (not best or e.Cost > best.Cost) then
					best = e
				end
			end
			if best then
				local total = 0
				for _, s in ipairs(best.Pool) do
					total += s.Chance
				end
				for _ = 1, 4 do
					if coins < best.Cost then
						break
					end
					coins -= best.Cost
					local x = rng:NextNumber(0, total)
					local pid = best.Pool[1].Pet
					for _, s in ipairs(best.Pool) do
						x -= s.Chance
						if x <= 0 then
							pid = s.Pet
							break
						end
					end
					table.insert(owned, Config.GetPetMultiplier(pid))
					if not index[pid] then
						index[pid] = true
						nIndex += 1
					end
					if best.Cost >= Config.GetRebirthEggMinCost(reb) then
						rebEggs += 1
					end
				end
				if #owned > 300 then
					table.sort(owned, function(a, b)
						return a > b
					end)
					for i = #owned, 40, -1 do
						owned[i] = nil
					end
				end
				team = teamMult()
			end
			for _ = 1, 3 do
				local key, c = nil, math.huge
				for q, f in pairs(costFn) do
					if lv[q] < 125 then
						local cc = f(lv[q] + 1)
						if cc < c then
							key, c = q, cc
						end
					end
				end
				if key and c <= coins * 0.5 then
					coins -= c
					lv[key] += 1
				else
					break
				end
			end
		end
	end
	return nil, log
end
