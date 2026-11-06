-- Донаты: геймпассы и продукты (StoreConfig). Владение геймпассом — атрибут Pass_<Key> у игрока
-- (его читают PlayerSystems, GameServer, ShopUI, StoreUI). Продукты выдаются в ProcessReceipt;
-- каждая покупка записывается в DataStore, чтобы при повторе Roblox её не выдало дважды.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))

local receipts = nil
pcall(function()
	receipts = DataStoreService:GetDataStore("CoinSprintReceipts_v1")
end)

local function applyPass(p: Player, def)
	if p:GetAttribute("Pass_" .. def.Key) then
		return
	end
	p:SetAttribute("Pass_" .. def.Key, true)
	if def.Key == "PetSlots" then
		p:SetAttribute("MaxEquipped", PlayerSystems.MaxEquipped(p))
	end
end

local function checkPasses(p: Player)
	for _, def in ipairs(StoreConfig.Passes) do
		if def.Id and def.Id > 0 then
			-- до 3 попыток: при сбое Roblox игрок не должен остаться без купленного
			for attempt = 1, 3 do
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, p.UserId, def.Id)
				if ok then
					if owns then
						applyPass(p, def)
					end
					break
				end
				task.wait(attempt * 2)
				if attempt == 3 and p.Parent == Players then
					-- Roblox не ответил: проверим этот геймпасс ещё раз через минуту
					task.delay(60, function()
						if p.Parent == Players and not p:GetAttribute("Pass_" .. def.Key) then
							local ok2, owns2 = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, p.UserId, def.Id)
							if ok2 and owns2 then
								applyPass(p, def)
							end
						end
					end)
				end
			end
		end
	end
end
-- Буст удачи тратится только в игре: раз в секунду списываем секунду из Save_LuckBoostLeft,
-- а GameServer смотрит на атрибут LuckBoostActive.
task.spawn(function()
	while true do
		task.wait(1)
		for _, p in ipairs(Players:GetPlayers()) do
			local left = p:GetAttribute("Save_LuckBoostLeft") or 0
			if left > 0 and p:GetAttribute("ProfileReady") then
				p:SetAttribute("Save_LuckBoostLeft", left - 1)
				p:SetAttribute("LuckBoostActive", true)
			elseif p:GetAttribute("LuckBoostActive") then
				p:SetAttribute("LuckBoostActive", nil)
			end
		end
	end
end)
-- Страны, где запрещены платные случайные предметы: прячем товары с Random = true (StoreUI)
-- и не предлагаем их сами. Пока ответа нет — считаем, что запрещено (безопаснее).
local PolicyService = game:GetService("PolicyService")
local function checkPolicy(p: Player)
	p:SetAttribute("NoPaidRandom", true)
	for attempt = 1, 3 do
		local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, p)
		if ok and info then
			p:SetAttribute("NoPaidRandom", info.ArePaidRandomItemsRestricted == true)
			return
		end
		task.wait(attempt * 2)
	end
end
local function onJoin(p: Player)
	task.spawn(checkPolicy, p)
	checkPasses(p)
end
Players.PlayerAdded:Connect(onJoin)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onJoin, p)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, passId, purchased)
	if not purchased then
		return
	end
	for _, def in ipairs(StoreConfig.Passes) do
		if def.Id == passId then
			applyPass(p, def)
		end
	end
end)

-- ===== продукты =====
local byId = {}
for _, def in ipairs(StoreConfig.Products) do
	if def.Id and def.Id > 0 then
		byId[def.Id] = def
	end
end

local function grant(p: Player, def): boolean
	if not p:GetAttribute("ProfileReady") then
		return false
	end
	if def.Kind == "coins" then
		local stats = p:FindFirstChild("leaderstats")
		if not stats then
			return false
		end
		local earned = p:GetAttribute("LifetimeEarned") or 0
		local amount = math.floor(math.max(def.Min, earned * def.Share))
		stats.Coins.Value += amount
		local sig = game:GetService("ServerStorage"):FindFirstChild("ServerSignals")
		sig = sig and sig:FindFirstChild("CoinPackGranted") -- для аналитики (Analytics.server.luau)
		if sig then
			sig:Fire(p, def.Key, amount, stats.Coins.Value)
		end
		return true
	elseif def.Kind == "potions" then
		for _, name in ipairs({ "Coins", "Speed", "Luck" }) do
			p:SetAttribute("Potion" .. name, (p:GetAttribute("Potion" .. name) or 0) + def.Count)
		end
		return true
	elseif def.Kind == "starter" then
		-- разовый набор: если уже покупали (повтор чека) — всё равно выдаём, Roblox деньги взял
		local stats = p:FindFirstChild("leaderstats")
		if not stats then
			return false
		end
		stats.Coins.Value += math.floor(math.max(def.Min, (p:GetAttribute("LifetimeEarned") or 0) * def.Share))
		for _, name in ipairs({ "Coins", "Luck" }) do
			p:SetAttribute("Potion" .. name, (p:GetAttribute("Potion" .. name) or 0) + def.Count)
		end
		p:SetAttribute("Save_StarterBought", true)
		return true
	elseif def.Kind == "luck" then
		-- копим оставшиеся секунды (как у зелий): вне игры буст не тратится
		p:SetAttribute("Save_LuckBoostLeft", (p:GetAttribute("Save_LuckBoostLeft") or 0) + def.Seconds)
		return true
	end
	return false
end

MarketplaceService.ProcessReceipt = function(info)
	local def = byId[info.ProductId]
	local p = Players:GetPlayerByUserId(info.PlayerId)
	if not def or not p then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- уже выдавали эту покупку? (сначала смотрим в профиле игрока — он сохраняется вместе с выданным)
	local function seen()
		return string.find("," .. (p:GetAttribute("Save_Receipts") or "") .. ",", "," .. info.PurchaseId .. ",", 1, true) ~= nil
	end
	local saveNow = game:GetService("ServerStorage"):FindFirstChild("SaveProfileNow")
	local function saved()
		if not saveNow then
			return false -- нечем сохранить — не подтверждаем, Roblox повторит позже
		end
		local ok, res = pcall(saveNow.Invoke, saveNow, p)
		return ok and res == true
	end
	if seen() then
		-- уже выдано в этой сессии: «готово» только когда это реально сохранено
		return saved() and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if receipts then
		local ok, done = pcall(receipts.GetAsync, receipts, info.PurchaseId)
		-- в Studio без доступа к API хранилище недоступно: тестовую покупку выдаём сразу
		if not ok and not game:GetService("RunService"):IsStudio() then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if ok and done then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	-- пока ждали хранилище, эту же покупку могла выдать параллельная обработка
	if seen() then
		return saved() and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not grant(p, def) then
		warn("[Store] grant failed", def.Key)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- запоминаем покупку в профиле (последние 30) и сразу сохраняем профиль
	local list = string.split(p:GetAttribute("Save_Receipts") or "", ",") -- свежий список: без потери параллельных покупок
	table.insert(list, info.PurchaseId)
	while #list > 30 do
		table.remove(list, 1)
	end
	p:SetAttribute("Save_Receipts", table.concat(list, ","))
	if not saved() then
		-- выдано в памяти и отмечено в профиле: при повторе Roblox второй раз не выдадим
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if receipts then
		pcall(receipts.SetAsync, receipts, info.PurchaseId, true)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
