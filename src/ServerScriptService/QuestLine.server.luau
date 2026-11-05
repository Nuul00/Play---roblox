-- Квестовая линия: сервер ведёт прогресс шагов и выдаёт награды. Клиент только просит CLAIM.
-- Состояние — в атрибутах Save_QuestLine* (их сохраняет WorldProgress), список шагов — QuestLineConfig.
-- Постоянный бонус глав лежит в Save_QuestLineBonus (множитель монет, по умолчанию 1).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local Q = require(ReplicatedStorage:WaitForChild("QuestLineConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))
local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
local A = Q.Attr

local remote = ReplicatedStorage:FindFirstChild(Q.RemoteName) or Instance.new("RemoteEvent")
remote.Name = Q.RemoteName
remote.Parent = ReplicatedStorage

local random = Random.new()
local CLAIM_COOLDOWN = 0.6

-- Цели «с начала шага»: от какой статистики считаем разницу.
local RELATIVE = { collect = "CoinsCollected", earn = "LifetimeEarned", rebirth = "Rebirths" }
-- Цели по абсолютному значению атрибута.
local ABSOLUTE = { magnet = "MagnetLevel", income = "IncomeLevel", double = "DoubleLevel", magnetTier = "MagnetTier", discover = "PetsDiscovered" }

-- [player] = { cache = {атрибут улучшенного питомца -> количество}, conn, lastClaim }
local state = {}

local function num(p, name): number
	local v = p:GetAttribute(name)
	return type(v) == "number" and v or 0
end

local function speedLevel(p): number
	local stats = p:FindFirstChild("leaderstats")
	local lv = stats and stats:FindFirstChild("SpeedLevel")
	return lv and lv.Value or 0
end

local function currentStep(p)
	local i = p:GetAttribute(A.Step)
	if type(i) ~= "number" then
		return nil, nil
	end
	return i, Q.Steps[i]
end

local function setIfChanged(p, name, value)
	if p:GetAttribute(name) ~= value then
		p:SetAttribute(name, value)
	end
end

-- Сырой прогресс текущей цели (без учёта «готово»).
local function progressOf(p, goal): number
	local t = goal.Type
	if t == "rebirth" and num(p, "Rebirths") >= Config.MaxRebirths then
		return Q.GoalAmount(goal) -- больше ребёрсов сделать нельзя: не запираем линию
	end
	if RELATIVE[t] then
		local base = tonumber(p:GetAttribute(A.Base) or "0") or 0
		return math.max(0, num(p, RELATIVE[t]) - base)
	elseif ABSOLUTE[t] then
		return num(p, ABSOLUTE[t])
	elseif t == "speed" then
		return speedLevel(p)
	elseif t == "eggs" or t == "variant" then
		return num(p, A.Count)
	elseif t == "world" then
		return p:GetAttribute("CurrentWorld") == goal.World and 1 or 0
	end
	return 0
end

-- Пересчитать прогресс и выставить атрибуты для клиента.
local function refresh(p)
	local _, s = currentStep(p)
	if not s then
		setIfChanged(p, A.Progress, 0)
		setIfChanged(p, A.Goal, 0)
		return
	end
	local goalN = Q.GoalAmount(s.Goal)
	local ready = p:GetAttribute(A.Ready) == true
	local prog = ready and goalN or math.min(progressOf(p, s.Goal), goalN)
	if not ready and prog >= goalN then
		p:SetAttribute(A.Ready, true)
		feedback:FireClient(p, "📜 Quest complete: " .. s.Title .. "! Claim your reward.", true)
	end
	setIfChanged(p, A.Goal, goalN)
	setIfChanged(p, A.Progress, prog)
end

-- Начать шаг: запомнить точку отсчёта, сбросить счётчик.
local function startStep(p, index: number)
	local s = Q.Steps[index]
	local base = 0
	if s and RELATIVE[s.Goal.Type] then
		base = num(p, RELATIVE[s.Goal.Type])
	end
	p:SetAttribute(A.Base, string.format("%.17g", base))
	p:SetAttribute(A.Count, 0)
	p:SetAttribute(A.Ready, false)
	p:SetAttribute(A.Step, index)
	refresh(p)
end

-- Бесплатное открытие яйца (награда главы): два броска, остаётся сильнейший питомец.
local function freeHatch(p, eggId: number): number?
	if not Config.Eggs[eggId] then
		return nil
	end
	local pet = Config.RollEgg(eggId, random:NextInteger(1, 100000))
	local second = Config.RollEgg(eggId, random:NextInteger(1, 100000))
	if Config.GetPetMultiplier(second) > Config.GetPetMultiplier(pet) then
		pet = second
	end
	local attr = "PetOwned" .. pet
	local count = num(p, attr) + 1
	p:SetAttribute(attr, count)
	PlayerSystems.OnHatched(p, pet)
	local def = Config.Pets[pet]
	feedback:FireClient(p, "🥚 Free " .. Config.Eggs[eggId].Name .. ": " .. def.Name .. " (" .. def.Rarity .. ")!", true)
	-- Показываем обычную анимацию открытия яйца (ShopUI), когда отыграет анимация награды.
	task.delay(1.6, function()
		local hatched = ReplicatedStorage:FindFirstChild("GameHatched")
		if hatched and p.Parent == Players then
			hatched:FireClient(p, { { Pet = pet, Count = count, Deleted = false, Forced = false } }, eggId)
		end
	end)
	return pet
end

local function grant(p, s, index: number)
	local r = s.Reward
	local stats = p:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if r.Coins and coins then
		coins.Value += r.Coins -- LifetimeEarned не трогаем: он только для настоящих монет
	end
	if r.Potion and ShopConfig.Potions[r.Potion] then
		local key = "Potion" .. r.Potion
		p:SetAttribute(key, num(p, key) + 1)
	end
	if r.Bonus then
		local bonus = p:GetAttribute(A.Bonus)
		p:SetAttribute(A.Bonus, (type(bonus) == "number" and bonus or 1) + r.Bonus)
	end
	-- ⚡ жетоны для магазина трейлов (раньше давались ежедневными заданиями, теперь — квестовой
	-- линией): 1 за шаг, +3 за конец главы. Хранятся в QuestService (места, сделано партнёром).
	pcall(function()
		local qs = script.Parent:FindFirstChild("QuestService")
		local st = qs and require(qs).GetState(p)
		if st then
			st.tokens = (st.tokens or 0) + 1 + (r.Bonus and 3 or 0)
			require(qs).Commit(p)
		end
	end)
	local pet = r.Hatch and freeHatch(p, r.Hatch) or nil
	remote:FireClient(p, "claimed", index, pet)
	local nextStep = Q.Steps[index + 1]
	if not nextStep then
		feedback:FireClient(p, "🏆 You finished the whole quest line! Legend!", true)
	elseif nextStep.Chapter ~= s.Chapter then
		feedback:FireClient(p, "⭐ Chapter complete! Next: " .. Q.Chapters[nextStep.Chapter].Name, true)
	end
end

-- Улучшенные питомцы: считаем только прирост атрибутов Pet<Key><id> (слияние в машине).
local function onAttributeChanged(p, st, name: string)
	local key = string.match(name, "^Pet(%a+)%d+$")
	if not key or key == "Owned" or not Q.VariantByKey(key) then
		return
	end
	local new = num(p, name)
	local old = st.cache[name] or 0
	st.cache[name] = new
	if new <= old then
		return
	end
	local _, s = currentStep(p)
	if s and s.Goal.Type == "variant" and s.Goal.Key == key and p:GetAttribute(A.Ready) ~= true then
		p:SetAttribute(A.Count, num(p, A.Count) + (new - old))
		refresh(p)
	end
end

local function init(p)
	-- Ждём загрузки сохранения: до этого Save_-атрибутов ещё нет.
	while p.Parent == Players and not p:GetAttribute("ProfileReady") do
		task.wait(0.25)
	end
	if p.Parent ~= Players or state[p] then
		return
	end
	local st = { cache = {}, lastClaim = -10 }
	if type(p:GetAttribute(A.Bonus)) ~= "number" then
		p:SetAttribute(A.Bonus, 1)
	end
	-- Текущие количества улучшенных питомцев — точка отсчёта для прироста.
	for id = 1, #Config.Pets do
		for tier = 1, #ShopConfig.Variants do
			local attr = ShopConfig.OwnedAttr(id, tier)
			st.cache[attr] = num(p, attr)
		end
	end
	state[p] = st
	st.conn = p.AttributeChanged:Connect(function(name)
		onAttributeChanged(p, st, name)
	end)
	local i = p:GetAttribute(A.Step)
	if type(i) ~= "number" or i < 1 then
		startStep(p, 1)
	else
		i = math.floor(i)
		if i > #Q.Steps then
			i = #Q.Steps + 1
		end
		setIfChanged(p, A.Step, i)
		if type(p:GetAttribute(A.Base)) ~= "string" then
			startStep(p, i)
		else
			refresh(p)
		end
	end
end

Players.PlayerAdded:Connect(function(p)
	task.spawn(init, p)
end)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(init, p)
end
Players.PlayerRemoving:Connect(function(p)
	local st = state[p]
	if st and st.conn then
		st.conn:Disconnect()
	end
	state[p] = nil
end)

-- Сигналы других систем.
task.spawn(function()
	local signals = ServerStorage:WaitForChild("ServerSignals", 60)
	if not signals then
		warn("[QuestLine] ServerSignals not found")
		return
	end
	local eggs = signals:WaitForChild("EggsHatched", 60)
	if eggs then
		eggs.Event:Connect(function(p, eggId, amount)
			if typeof(p) ~= "Instance" or not state[p] then
				return
			end
			local _, s = currentStep(p)
			if not s or s.Goal.Type ~= "eggs" or p:GetAttribute(A.Ready) == true then
				return
			end
			if s.Goal.Egg and s.Goal.Egg ~= eggId then
				return
			end
			p:SetAttribute(A.Count, num(p, A.Count) + (tonumber(amount) or 1))
			refresh(p)
		end)
	end
	local coin = signals:WaitForChild("CoinCollected", 60)
	if coin then
		coin.Event:Connect(function(p)
			if typeof(p) ~= "Instance" or not state[p] then
				return
			end
			local _, s = currentStep(p)
			if s and (s.Goal.Type == "collect" or s.Goal.Type == "earn") then
				refresh(p)
			end
		end)
	end
end)

-- Остальные цели (уровни, мир, питомцы) проверяем по таймеру.
task.spawn(function()
	while true do
		task.wait(0.5)
		for p in pairs(state) do
			if p.Parent == Players then
				refresh(p)
			end
		end
	end
end)

remote.OnServerEvent:Connect(function(p, action)
	if action ~= "claim" then
		return
	end
	local st = state[p]
	if not st or not p:GetAttribute("ProfileReady") then
		return
	end
	local now = os.clock()
	if now - st.lastClaim < CLAIM_COOLDOWN then
		return
	end
	st.lastClaim = now
	refresh(p)
	local i, s = currentStep(p)
	if not s or p:GetAttribute(A.Ready) ~= true then
		return
	end
	-- Сначала переходим к следующему шагу, потом выдаём награду: повторный запрос ничего не даст.
	startStep(p, i + 1)
	grant(p, s, i)
end)
