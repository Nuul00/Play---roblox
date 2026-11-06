-- Studio-only: «новичок-бот» играет за локального игрока N секунд и пишет лог (префикс "HAS BOT").
-- Ведёт себя как обычный игрок: бегает за ближайшими монетами, покупает новые яйца и прокачку,
-- надевает лучших питомцев, забирает награды квестов, открывает следующий мир, когда хватает монет.
-- Запуск (Play → Client command bar): require(game.ReplicatedStorage.DevBot)(900)
return function(duration, mode)
	mode = mode or "player"
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	duration = duration or 900
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local P = Players.LocalPlayer
	local Config = require(RS.GameConfig)
	local Worlds = require(RS.WorldsConfig)
	local buy, act = RS.GameShopBuy, RS.GameAction
	local quest = RS:FindFirstChild("QuestLineRemote")
	local tele = RS:FindFirstChild("WorldTeleport")
	local feedback = RS:FindFirstChild("GameFeedback")
	local hatched = RS:FindFirstChild("GameHatched")
	local w = workspace.CoinSpeedWorld
	local t0 = os.clock()
	local logs = {}
	_G.botLog = logs
	local function log(s)
		local m = string.format("[%4ds] %s", math.floor(os.clock() - t0), s)
		table.insert(logs, m)
		print("HAS BOT " .. m)
	end
	local function short(n)
		n = tonumber(n) or 0
		local u = { "", "K", "M", "B", "T", "Qa" }
		local i = 1
		while n >= 1000 and i < #u do n /= 1000 i += 1 end
		return string.format(i == 1 and "%d%s" or "%.1f%s", n, u[i])
	end
	local seenMsg = {}
	if feedback then
		feedback.OnClientEvent:Connect(function(msg)
			msg = tostring(msg)
			seenMsg[msg] = (seenMsg[msg] or 0) + 1
			if seenMsg[msg] <= 2 then log("MSG: " .. msg) end
		end)
	end
	local hatchedCount, rareLog = 0, {}
	if hatched then
		hatched.OnClientEvent:Connect(function(results, eggId)
			for _, r in results do
				hatchedCount += 1
				local pet = Config.Pets[r.Pet]
				local name = pet and pet.Name or tostring(r.Pet)
				local mult = Config.GetPetMultiplier and Config.GetPetMultiplier(r.Pet) or 0
				if hatchedCount <= 3 or (pet and pet.Rarity and pet.Rarity ~= "Common") then
					log(("HATCH egg%d → %s x%s %s"):format(eggId, name, tostring(mult), pet and pet.Rarity or ""))
				end
			end
		end)
	end

	local ZONE = { ["Meadow Isles"] = "island", ["Neon District"] = "neon", ["Sky Isles"] = "sky", ["Frozen Peaks"] = "frozen", ["Magma Volcano"] = "volcano", ["Cosmic Galaxy"] = "galaxy" }
	local HOLDER = { island = w, neon = w:FindFirstChild("NeonCity"), sky = w:FindFirstChild("SkyIsles"), frozen = w:FindFirstChild("FrozenPeaks"), volcano = w:FindFirstChild("MagmaVolcano"), galaxy = w:FindFirstChild("CosmicGalaxy") }
	local function stats() return P:FindFirstChild("leaderstats") end
	local function coins() local s = stats() return s and s:FindFirstChild("Coins") and s.Coins.Value or 0 end
	local function zoneId() return ZONE[P:GetAttribute("CurrentWorld") or "Meadow Isles"] or "island" end
	local function hum()
		local c = P.Character
		return c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
	end
	local function walkTo(pos, near, timeout)
		local h, root = hum()
		if not h then return false end
		local t = os.clock()
		while os.clock() - t < (timeout or 8) do
			if ((root.Position - pos) * Vector3.new(1, 0, 1)).Magnitude <= (near or 3) then return true end
			if h.Sit then -- сел на лавку — встаём
				local seat = h.SeatPart
				local weld = seat and seat:FindFirstChild("SeatWeld")
				if weld then weld:Destroy() end
				h.Sit = false
				h.Jump = true
			end
			h:MoveTo(pos)
			task.wait(0.25)
			if h.FloorMaterial == Enum.Material.Air and math.random() < 0.15 then h.Jump = true end
		end
		return false
	end

	-- монеты текущего мира
	local coinList, coinZone = {}, nil
	local skip = {}
	local function refreshCoins()
		local holder = HOLDER[zoneId()] or w
		coinList = {}
		coinZone = zoneId()
		for _, d in holder:GetDescendants() do
			if d:IsA("BasePart") and string.match(d.Name, "^Coin_%d+$") then
				if zoneId() == "island" then
					-- в Meadow монеты лежат прямо в мире; не берём монеты из других миров
					local inOther = false
					for k, hld in HOLDER do
						if k ~= "island" and hld and d:IsDescendantOf(hld) then inOther = true break end
					end
					if not inOther then table.insert(coinList, d) end
				else
					table.insert(coinList, d)
				end
			end
		end
	end
	local function nearestCoin()
		local _, root = hum()
		if not root then return nil end
		local best, bd = nil, 1e9
		for _, c in coinList do
			if c.Parent and c:GetAttribute("Available") ~= false and c.Transparency < 0.9 and (skip[c] or 0) < os.clock() then
				local d = (c.Position - root.Position).Magnitude
				if d < bd and math.abs(c.Position.Y - root.Position.Y) < 12 then best, bd = c, d end
			end
		end
		return best
	end

	local UP = {
		{ "speed", function() return stats().SpeedLevel.Value end, Config.GetUpgradeCost },
		{ "income", function() return P:GetAttribute("IncomeLevel") or 0 end, Config.GetIncomeUpgradeCost },
		{ "magnet", function() return P:GetAttribute("MagnetLevel") or 0 end, Config.GetMagnetUpgradeCost },
		{ "double", function() return P:GetAttribute("DoubleLevel") or 0 end, Config.GetDoubleUpgradeCost },
	}
	-- выбор прокачки. "cheap": самая дешёвая. "player": как обычный игрок — держит уровни ровно с упором
	-- на монеты и скорость, и тратит на один уровень не больше 25% кошелька, остальное копит на цель.
	local WEIGHT = { income = 1, speed = 0.85, double = 0.7, magnet = 0.6 }
	local maxedAt = {}
	local function pickUpgrade()
		local best, bc, bs
		for _, u in UP do
			local lvl = u[2]()
			local cost = u[3](lvl)
			if maxedAt[u[1]] ~= lvl then
				local score = mode == "cheap" and cost or (lvl + 1) / WEIGHT[u[1]]
				if not bs or score < bs then best, bc, bs = u[1], cost, score end
			end
		end
		if mode ~= "cheap" and best and bc > coins() * 0.25 then return nil end
		return best, bc
	end
	local opened = {}
	local function eggsHere()
		local list = {}
		for id, e in Config.Eggs do
			if e.World == zoneId() then table.insert(list, e) end
		end
		table.sort(list, function(a, b) return a.Cost < b.Cost end)
		return list
	end
	local function doBuyUpgrade(kind, cost)
		local holder = HOLDER[zoneId()]
		local shop = holder and holder:FindFirstChild("UpgradeShop")
		local zp = shop and shop:FindFirstChild("ShopZone")
		if not zp then return false end
		if not walkTo(zp.Position, (Config.ShopDistance or 12) - 3, 25) then log("could not reach upgrade shop") return false end
		-- как живой игрок: у прилавка покупает подряд всё, на что хватает (самое дешёвое первым)
		local n, spent = 0, 0
		for _ = 1, 40 do
			local best, bc = pickUpgrade()
			if not best or coins() < bc then break end
			local before = coins()
			local lvlBefore
			for _, u in UP do if u[1] == best then lvlBefore = u[2]() end end
			buy:FireServer(best, zoneId())
			task.wait(0.5)
			if coins() >= before then maxedAt[best] = lvlBefore break end
			n += 1
			spent += before - coins()
		end
		if n > 0 then
			log(("UPGRADES x%d (-%s) → coins %s | spd=%d inc=%d mag=%d dbl=%d"):format(n, short(spent), short(coins()), stats().SpeedLevel.Value, P:GetAttribute("IncomeLevel") or 0, P:GetAttribute("MagnetLevel") or 0, P:GetAttribute("DoubleLevel") or 0))
			return true
		end
		return false
	end
	local function doBuyEgg(e)
		local holder = HOLDER[zoneId()]
		local stand = holder and holder:FindFirstChild("EggStand" .. e.Id, true)
		local ip = stand and stand:FindFirstChild("Interact")
		if not ip then return false end
		if not walkTo(ip.Position, (Config.ShopDistance or 12) - 3, 25) then log("could not reach egg " .. e.Name) return false end
		local before = coins()
		buy:FireServer("egg", zoneId(), e.Id, 1)
		task.wait(4)
		if coins() < before then
			opened[e.Id] = (opened[e.Id] or 0) + 1
			act:FireServer("best")
			task.wait(0.3)
			if opened[e.Id] == 1 then log(("FIRST EGG %s (%s) → coins %s"):format(e.Name, short(e.Cost), short(coins()))) end
			return true
		end
		return false
	end

	local lastStatus, lastDecide, lastWorldTry = -1e9, -1e9, -1e9
	local function status()
		local s = stats()
		local eq = P:GetAttribute("EquippedPets") or P:GetAttribute("Equipped") or ""
		log(("STATUS coins=%s earned=%s spd=%d inc=%d mag=%d dbl=%d eggs=%d hatched=%d world=%s eq=%s q=%s rebirths=%s"):format(
			short(coins()), short(P:GetAttribute("LifetimeEarned") or 0), s.SpeedLevel.Value, P:GetAttribute("IncomeLevel") or 0,
			P:GetAttribute("MagnetLevel") or 0, P:GetAttribute("DoubleLevel") or 0, P:GetAttribute("EggsOpened") or 0, hatchedCount,
			tostring(P:GetAttribute("CurrentWorld")), tostring(eq), tostring(P:GetAttribute("QuestStep") or P:GetAttribute("QuestLineStep") or "?"),
			tostring(s:FindFirstChild("Rebirths") and s.Rebirths.Value or P:GetAttribute("Rebirths") or 0)))
	end
	log("bot start, mode " .. mode .. ", duration " .. duration .. "s")
	refreshCoins()
	local earnedAt = {}
	while os.clock() - t0 < duration do
		local now = os.clock() - t0
		if now - lastStatus >= 60 then lastStatus = now status() table.clear(maxedAt) end
		if quest then quest:FireServer("claim") end
		if coinZone ~= zoneId() then refreshCoins() end
		if now - lastDecide >= 6 then
			lastDecide = now
			local c = coins()
			-- 1) следующий мир
			local nextW
			for _, d in Worlds.Worlds do
				if (d.Cost or 0) > 0 and not P:GetAttribute(Worlds.UnlockKey(d.Id)) then nextW = d break end
			end
			local r = (stats():FindFirstChild("Rebirths") and stats().Rebirths.Value) or P:GetAttribute("Rebirths") or 0
			local rcost = Config.GetRebirthCost(r)
			local reb = RS:FindFirstChild("GameRebirth")
			if reb and c >= rcost and (P:GetAttribute("EggsOpened") or 0) >= Config.GetRebirthEggs(r) and now - (_G.botLastReb or -1e9) > 30 then
				_G.botLastReb = now
				reb:FireServer()
				task.wait(2)
				table.clear(maxedAt)
				log(("REBIRTH try (cost %s) → coins %s"):format(short(rcost), short(coins())))
			end
			-- как игрок: после ребёрса (он кидает в Meadow) летим в самый дальний открытый мир
			local bestOpen = "Meadow Isles"
			for _, d in Worlds.Worlds do
				if (d.Cost or 0) == 0 or P:GetAttribute(Worlds.UnlockKey(d.Id)) then bestOpen = d.Id end
			end
			if tele and P:GetAttribute("CurrentWorld") ~= bestOpen and now - (_G.botLastHop or -1e9) > 20 then
				_G.botLastHop = now
				pcall(tele.InvokeServer, tele, bestOpen)
				task.wait(3)
				table.clear(maxedAt)
				refreshCoins()
				log("HOP to " .. bestOpen)
			end
			if nextW and c >= nextW.Cost and tele and now - lastWorldTry > 30 then
				lastWorldTry = now
				local ok, res = pcall(tele.InvokeServer, tele, nextW.Id, true)
				log(("WORLD unlock try %s (%s): %s"):format(nextW.Id, short(nextW.Cost), ok and type(res) == "table" and tostring(res.Message) or tostring(res)))
				task.wait(3)
				refreshCoins()
			else
				-- 2) новое яйцо (ещё не открывали) → 3) дешёвая прокачка → 4) яйцо, если монет с запасом
				local eggs = eggsHere()
				local bought = false
				for i = #eggs, 1, -1 do
					local e = eggs[i]
					if not opened[e.Id] and c >= e.Cost then bought = doBuyEgg(e) break end
				end
				if not bought then
					local best, bc = pickUpgrade()
					if best and c >= bc then
						bought = doBuyUpgrade(best, bc)
					end
				end
				if not bought and mode ~= "cheap" then
					-- копим на ближайшую цель (новое яйцо / мир), а лишние деньги крутим в лучшем яйце
					local goal
					for _, e in eggs do if not opened[e.Id] then goal = e.Cost break end end
					if nextW then goal = goal and math.min(goal, nextW.Cost) or nextW.Cost end
					local bestEgg
					for i = #eggs, 1, -1 do if opened[eggs[i].Id] then bestEgg = eggs[i] break end end
					if bestEgg and c >= bestEgg.Cost * 2 and (not goal or c - bestEgg.Cost >= goal or c < goal * 0.25) and (opened[bestEgg.Id] or 0) < 40 then
						doBuyEgg(bestEgg)
					end
				elseif not bought then
					for i = #eggs, 1, -1 do
						local e = eggs[i]
						if c >= e.Cost * 3 and (opened[e.Id] or 0) < 12 then doBuyEgg(e) break end
					end
				end
			end
		end
		local coin = nearestCoin()
		if coin then
			walkTo(coin.Position, 2, 2.5)
			task.wait(0.15)
			-- монета не подобралась (стоим рядом, а она на месте) — временно пропускаем её
			local _, root = hum()
			if root and coin:GetAttribute("Available") ~= false and (coin.Position - root.Position).Magnitude < 4 then
				skip[coin] = os.clock() + 8
			end
		else
			task.wait(1)
			refreshCoins()
		end
	end
	status()
	log("bot done")
	return logs
end
