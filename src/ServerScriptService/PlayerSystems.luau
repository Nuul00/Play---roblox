-- Серверные системы игрока: команда из 3 питомцев, зелья, достижения, магниты в руке.
-- Все решения принимает сервер; клиент только просит через RemoteEvent GameAction.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local MagnetVisuals = require(ReplicatedStorage:WaitForChild("MagnetVisuals"))
local PetAbilities = require(ReplicatedStorage:WaitForChild("PetAbilities"))

local PlayerSystems = {}
local notifyFn = function(_p, _text, _ok) end

function PlayerSystems.SetNotifier(fn)
	notifyFn = fn
end

-- ===== Команда питомцев =====
-- В списке надетых лежат «коды»: id + ступень * 1000 (см. ShopConfig.Variants).
local function owned(p, code)
	local id, tier = ShopConfig.SplitPet(code)
	if id ~= math.floor(id) or tier < 0 or not Config.Pets[id] or (tier > 0 and not ShopConfig.Variants[tier]) then
		return 0
	end
	return p:GetAttribute(ShopConfig.OwnedAttr(id, tier)) or 0
end
local function mult(code)
	local id, tier = ShopConfig.SplitPet(code)
	return Config.GetPetMultiplier(id) * ShopConfig.VariantMult(tier)
end
PlayerSystems.Owned = owned
PlayerSystems.CodeMultiplier = mult
function PlayerSystems.GetEquipped(p): { number }
	return ShopConfig.ParseEquipped(p:GetAttribute("Equipped"))
end
-- Размер команды: базовые 3 + слоты за ребёрсы (атрибут RebirthSlots ставит система ребёрсов).
function PlayerSystems.MaxEquipped(p): number
	local extra = math.clamp(math.floor(tonumber(p:GetAttribute("RebirthSlots")) or 0), 0, 20)
	if p:GetAttribute("Pass_PetSlots") then
		extra += 3 -- геймпасс «+3 Pet Slots»
	end
	return ShopConfig.MaxEquipped + extra
end
-- Последний запрошенный список команды: если слоты за ребёрсы придут позже сохранённой
-- команды, лишние питомцы не потеряются — список применится заново.
local wantedTeam = {}
Players.PlayerRemoving:Connect(function(p)
	wantedTeam[p] = nil
end)
function PlayerSystems.SetEquipped(p, list: { number })
	wantedTeam[p] = table.clone(list)
	local maxEquipped = PlayerSystems.MaxEquipped(p)
	if p:GetAttribute("MaxEquipped") ~= maxEquipped then
		p:SetAttribute("MaxEquipped", maxEquipped)
	end
	local counts, clean = {}, {}
	for _, code in ipairs(list) do
		if owned(p, code) > 0 and #clean < maxEquipped then
			counts[code] = (counts[code] or 0) + 1
			if counts[code] <= owned(p, code) then
				table.insert(clean, code)
			end
		end
	end
	table.sort(clean, function(a, b)
		return mult(a) > mult(b)
	end)
	local mults, text = {}, {}
	for _, code in ipairs(clean) do
		table.insert(mults, mult(code))
		table.insert(text, tostring(code))
	end
	p:SetAttribute("Equipped", table.concat(text, ","))
	p:SetAttribute("PetBonus", ShopConfig.TeamBonus(mults))
	p:SetAttribute("PetLevel", clean[1] and (ShopConfig.SplitPet(clean[1])) or 0) -- самый сильный, для статистики
	-- Способности команды: сумма простых и список супер-способностей.
	local team = PetAbilities.Team(clean)
	for _, kind in ipairs(PetAbilities.Order) do
		p:SetAttribute(PetAbilities.Kinds[kind].Attr, team[kind])
	end
	p:SetAttribute("PetSupers", team.SuperText)
	PlayerSystems.ApplySpeed(p)
end
function PlayerSystems.EquipBest(p)
	local maxEquipped = PlayerSystems.MaxEquipped(p)
	local all = {}
	for id = 1, #Config.Pets do
		for tier = 0, #ShopConfig.Variants do
			local code = ShopConfig.PetCode(id, tier)
			for _ = 1, math.min(owned(p, code), maxEquipped) do
				table.insert(all, code)
			end
		end
	end
	table.sort(all, function(a, b)
		return mult(a) > mult(b)
	end)
	local best = {}
	for i = 1, math.min(#all, maxEquipped) do
		best[i] = all[i]
	end
	PlayerSystems.SetEquipped(p, best)
end
-- Новый питомец: занимает свободное место или заменяет самого слабого, если сильнее.
function PlayerSystems.OnHatched(p, code)
	local list = PlayerSystems.GetEquipped(p)
	if #list < PlayerSystems.MaxEquipped(p) then
		table.insert(list, code)
	else
		local weakest = list[#list]
		if mult(code) > mult(weakest) then
			list[#list] = code
		end
	end
	PlayerSystems.SetEquipped(p, list)
end

-- ===== Машины улучшения =====
-- Need питомцев ступени tier-1 одного вида превращаются в одного питомца ступени tier.
function PlayerSystems.Fuse(p, tier: number, id: number): boolean
	local v = ShopConfig.Variants[tier]
	if not v or not Config.Pets[id] then
		return false
	end
	if Config.Pets[id].Super then
		notifyFn(p, "Super Secret pets are already one of a kind!")
		return false
	end
	local fromAttr = ShopConfig.OwnedAttr(id, tier - 1)
	local have = p:GetAttribute(fromAttr) or 0
	if have < v.Need then
		notifyFn(p, "Need " .. v.Need .. " of this pet (you have " .. have .. ")")
		return false
	end
	p:SetAttribute(fromAttr, have - v.Need)
	local toAttr = ShopConfig.OwnedAttr(id, tier)
	p:SetAttribute(toAttr, (p:GetAttribute(toAttr) or 0) + 1)
	PlayerSystems.SetEquipped(p, PlayerSystems.GetEquipped(p)) -- снимет потраченных питомцев
	PlayerSystems.OnHatched(p, ShopConfig.PetCode(id, tier))
	-- потраченные копии могли освободить места в команде — заполняем лучшими
	if #PlayerSystems.GetEquipped(p) < PlayerSystems.MaxEquipped(p) then
		PlayerSystems.EquipBest(p)
	end
	notifyFn(p, v.Icon .. " " .. v.Name .. " " .. Config.Pets[id].Name .. " created! x" .. string.format("%g", mult(ShopConfig.PetCode(id, tier))), true)
	return true
end

-- ===== Зелья =====
function PlayerSystems.PotionActive(p, name): boolean
	return (p:GetAttribute("PotionEnd" .. name) or 0) > os.time()
end
function PlayerSystems.UsePotion(p, name)
	local def = ShopConfig.Potions[name]
	if not def then
		return
	end
	local count = p:GetAttribute("Potion" .. name) or 0
	if count <= 0 then
		notifyFn(p, "You have no " .. def.Name .. "s")
		return
	end
	p:SetAttribute("Potion" .. name, count - 1)
	local start = math.max(os.time(), p:GetAttribute("PotionEnd" .. name) or 0)
	p:SetAttribute("PotionEnd" .. name, start + def.Duration)
	notifyFn(p, def.Name .. " active: " .. def.Effect, true)
	PlayerSystems.ApplySpeed(p)
end

-- ===== Достижения =====
function PlayerSystems.CheckBadges(p)
	local discovered = 0
	for id = 1, #Config.Pets do
		if not Config.Pets[id].Super and ShopConfig.Discovered(p, id) then
			discovered += 1
		end
	end
	p:SetAttribute("PetsDiscovered", discovered)
	local unlocked = 0
	for _, badge in ipairs(ShopConfig.Badges) do
		local key = "Badge" .. badge.Id
		if not p:GetAttribute(key) and (p:GetAttribute(badge.Stat) or 0) >= badge.Goal then
			p:SetAttribute(key, true)
			notifyFn(p, "🏅 Achievement: " .. badge.Name .. " · x" .. ShopConfig.BadgeBonus .. " coins forever!", true)
		end
		if p:GetAttribute(key) then
			unlocked += 1
		end
	end
	p:SetAttribute("BadgeBonus", ShopConfig.BadgeBonus ^ unlocked)
end

-- ===== Доход =====
function PlayerSystems.CoinMultiplier(p): number
	local m = (p:GetAttribute("PetBonus") or 1) * Config.GetIncomeMultiplier(p:GetAttribute("IncomeLevel") or 0) * (p:GetAttribute("BadgeBonus") or 1) * Config.GetRebirthBonus(p:GetAttribute("Rebirths") or 0)
	m *= (p:GetAttribute("IndexBonus") or 1) * (p:GetAttribute("FriendBonus") or 1)
	m *= p:GetAttribute("Save_QuestLineBonus") or 1 -- постоянный бонус за главы квестовой линии
	local stats = p:FindFirstChild("leaderstats")
	m *= Config.GetSpeedCoinBonus(stats and stats.SpeedLevel.Value or 0) -- +1% монет за уровень скорости
	if PlayerSystems.EventActive("Golden") then
		m *= 2
	end
	-- Мини-ивент Frozen Peaks «Метель»: x2 монет тем, кто в этот момент во Frozen.
	if (workspace:GetAttribute("FrozenStormEnd") or 0) > workspace:GetServerTimeNow() and p:GetAttribute("CurrentWorld") == "Frozen Peaks" then
		m *= 2
	end
	if PlayerSystems.PotionActive(p, "Coins") then
		m *= 2
	end
	-- Способность питомцев «+% монет» (MainHUD считает так же).
	m *= 1 + (p:GetAttribute("AbilCoins") or 0)
	-- геймпассы
	if p:GetAttribute("Pass_Coins2x") then
		m *= 2
	end
	if p:GetAttribute("Pass_VIP") then
		m *= 1.25
	end
	-- подписка Roblox Premium: +10% монет (Roblox платит авторам за время Premium-игроков)
	if p.MembershipType == Enum.MembershipType.Premium then
		m *= 1.1
	end
	return m
end

-- ===== Скорость =====
PlayerSystems.MaxWalkSpeed = 85
PlayerSystems.MaxMagnetBase = 55 -- уровень + магнит + питомцы
PlayerSystems.MaxMagnetTotal = 80 -- с геймпассом Super Magnet
function PlayerSystems.ApplySpeed(p)
	local stats = p:FindFirstChild("leaderstats")
	local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not stats or not h then
		return
	end
	local speed = Config.GetWalkSpeed(stats.SpeedLevel.Value)
	if PlayerSystems.PotionActive(p, "Speed") then
		speed *= 1.25
	end
	speed *= 1 + (p:GetAttribute("AbilSpeed") or 0) -- способность питомцев
	speed = math.min(math.floor(speed * 10 + 0.5) / 10, PlayerSystems.MaxWalkSpeed) -- выше — уже неуправляемо
	if math.abs(h.WalkSpeed - speed) > 0.01 then
		h.WalkSpeed = speed
	end
end

-- ===== Магниты =====
local function holdingMagnet(p)
	local c = p.Character
	return c ~= nil and c:FindFirstChild("CoinMagnet") ~= nil
end
function PlayerSystems.MagnetRadius(p): number
	local r = Config.GetMagnetRadius(p:GetAttribute("MagnetLevel") or 0)
	if holdingMagnet(p) then
		local def = ShopConfig.Magnets[p:GetAttribute("MagnetEquipped") or 1]
		r += def and def.Bonus or 0
	end
	r += p:GetAttribute("AbilMagnet") or 0 -- способность питомцев
	r = math.min(r, PlayerSystems.MaxMagnetBase)
	if p:GetAttribute("Pass_SuperMagnet") then
		r *= 2 -- геймпасс «Super Magnet»
	end
	return math.min(r, PlayerSystems.MaxMagnetTotal) -- больше не нужно: иначе можно стоять на месте и собирать весь мир

end
-- Магнит всегда в руках (панели инструментов Roblox нет): снять или надеть его можно только
-- в магазине магнитов. Атрибут MagnetOff = true — игрок снял магнит, бонус радиуса не действует.
function PlayerSystems.GiveMagnet(p)
	local tier = p:GetAttribute("MagnetEquipped") or 1
	for _, container in ipairs({ p:FindFirstChild("Backpack"), p.Character }) do
		if container then
			local old = container:FindFirstChild("CoinMagnet")
			if old then
				old:Destroy()
			end
		end
	end
	if p:GetAttribute("MagnetOff") then
		return
	end
	local character = p.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "CoinMagnet"
	tool.ToolTip = ShopConfig.Magnets[tier].Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	local model = MagnetVisuals.Build(tier)
	for _, part in ipairs(model:GetChildren()) do
		part.Parent = tool
	end
	model:Destroy()
	-- Рукоять в кулаке, подкова смотрит вперёд-вверх.
	tool.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(-20), 0, 0)
	tool.Parent = p:FindFirstChild("Backpack")
	humanoid:EquipTool(tool)
end
function PlayerSystems.EquipMagnet(p, tier)
	if type(tier) ~= "number" or not ShopConfig.Magnets[tier] then
		return
	end
	if tier > (p:GetAttribute("MagnetTier") or 1) then
		return
	end
	p:SetAttribute("MagnetEquipped", tier)
	p:SetAttribute("MagnetOff", false)
	PlayerSystems.GiveMagnet(p)
	notifyFn(p, ShopConfig.Magnets[tier].Name .. " equipped", true)
end
function PlayerSystems.UnequipMagnet(p)
	p:SetAttribute("MagnetOff", true)
	PlayerSystems.GiveMagnet(p) -- уберёт инструмент и не выдаст новый
	notifyFn(p, "Magnet taken off", true)
end

-- ===== Начальные значения =====
function PlayerSystems.Setup(p)
	p:SetAttribute("Equipped", "")
	p:SetAttribute("PetBonus", 1)
	p:SetAttribute("BadgeBonus", 1)
	p:SetAttribute("IndexBonus", 1)
	p:SetAttribute("FriendBonus", 1)
	for _, kind in ipairs(PetAbilities.Order) do
		p:SetAttribute(PetAbilities.Kinds[kind].Attr, 0)
	end
	p:SetAttribute("PetSupers", "")
	p:SetAttribute("MaxEquipped", PlayerSystems.MaxEquipped(p))
	-- Ребёрс дал (или снял) слот команды — применяем последний запрошенный список заново.
	p:GetAttributeChangedSignal("RebirthSlots"):Connect(function()
		PlayerSystems.SetEquipped(p, wantedTeam[p] or PlayerSystems.GetEquipped(p))
	end)
	-- геймпасс «+3 Pet Slots» мог подтвердиться после загрузки команды — возвращаем всю команду
	p:GetAttributeChangedSignal("Pass_PetSlots"):Connect(function()
		PlayerSystems.SetEquipped(p, wantedTeam[p] or PlayerSystems.GetEquipped(p))
	end)
	for _, tier in ipairs(ShopConfig.Pity) do
		p:SetAttribute("Pity" .. tier.Rarity, 0)
	end
	p:SetAttribute("PetsDiscovered", 0)
	p:SetAttribute("MagnetTier", 1)
	p:SetAttribute("MagnetEquipped", 1)
	for name in pairs(ShopConfig.Potions) do
		p:SetAttribute("Potion" .. name, 1) -- одно бесплатное зелье каждого вида
		p:SetAttribute("PotionEnd" .. name, 0)
	end
	for _, badge in ipairs(ShopConfig.Badges) do
		p:SetAttribute("Badge" .. badge.Id, false)
	end
	p:SetAttribute("MagnetRadius", Config.GetMagnetRadius(0))
	p.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		task.wait(0.3)
		if p.Character == character then
			PlayerSystems.GiveMagnet(p)
		end
	end)
	if p.Character then
		task.spawn(PlayerSystems.GiveMagnet, p)
	end
end

-- Раз в полсекунды: скорость с учётом зелья, радиус магнита для HUD, достижения.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("ProfileReady") then
				PlayerSystems.ApplySpeed(p)
				local r = PlayerSystems.MagnetRadius(p)
				if math.abs((p:GetAttribute("MagnetRadius") or 0) - r) > 0.001 then
					p:SetAttribute("MagnetRadius", r)
				end
				PlayerSystems.CheckBadges(p)
			end
		end
	end
end)

-- ===== Мировые события =====
function PlayerSystems.EventActive(id: string): boolean
	return workspace:GetAttribute("EventId") == id and (workspace:GetAttribute("EventEnd") or 0) > workspace:GetServerTimeNow()
end

-- ===== Бонус индекса =====
-- Каждая забранная страница индекса (все питомцы одного яйца) — постоянно +5% к монетам.
function PlayerSystems.RefreshIndexBonus(p)
	local pages = 0
	for i = 1, #Config.Eggs do
		if p:GetAttribute("IndexClaimed" .. i) then
			pages += 1
		end
	end
	p:SetAttribute("IndexBonus", 1 + pages * ShopConfig.IndexBonusPerPage)
end

-- ===== Гарантия (pity) =====
local pityRandom = Random.new()
local function rank(petId: number): number
	local def = Config.Pets[petId]
	return def and ShopConfig.RarityRank[def.Rarity] or 1
end
PlayerSystems.RarityRank = rank
-- Вызывается для каждого открытого питомца уже после обычного броска (и зелья удачи).
-- Возвращает итогового питомца и true, если сработала гарантия.
function PlayerSystems.ApplyPity(p, eggId: number, result: number): (number, boolean)
	local egg = Config.Eggs[eggId]
	for _, tier in ipairs(ShopConfig.Pity) do
		local key = "Pity" .. tier.Rarity
		p:SetAttribute(key, (p:GetAttribute(key) or 0) + 1)
	end
	local forced = false
	for _, tier in ipairs(ShopConfig.Pity) do
		local need = ShopConfig.RarityRank[tier.Rarity]
		if (p:GetAttribute("Pity" .. tier.Rarity) or 0) >= tier.Threshold and rank(result) < need and egg then
			local total = 0
			local pool = {}
			for _, entry in ipairs(egg.Pool) do
				if rank(entry.Pet) == need then
					table.insert(pool, entry)
					total += entry.Weight
				end
			end
			if total > 0 then
				local roll = pityRandom:NextInteger(1, total)
				for _, entry in ipairs(pool) do
					roll -= entry.Weight
					if roll <= 0 then
						result = entry.Pet
						break
					end
				end
				forced = true
				break
			end
		end
	end
	for _, tier in ipairs(ShopConfig.Pity) do
		if rank(result) >= ShopConfig.RarityRank[tier.Rarity] then
			p:SetAttribute("Pity" .. tier.Rarity, 0)
		end
	end
	return result, forced
end

return PlayerSystems
