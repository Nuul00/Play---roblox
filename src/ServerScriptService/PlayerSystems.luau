-- Серверные системы игрока: команда из 3 питомцев, зелья, достижения, магниты в руке.
-- Все решения принимает сервер; клиент только просит через RemoteEvent GameAction.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local MagnetVisuals = require(ReplicatedStorage:WaitForChild("MagnetVisuals"))

local PlayerSystems = {}
local notifyFn = function(_p, _text, _ok) end

function PlayerSystems.SetNotifier(fn)
	notifyFn = fn
end

-- ===== Команда питомцев =====
local function owned(p, id)
	return p:GetAttribute("PetOwned" .. id) or 0
end
function PlayerSystems.GetEquipped(p): { number }
	return ShopConfig.ParseEquipped(p:GetAttribute("Equipped"))
end
function PlayerSystems.SetEquipped(p, list: { number })
	local counts, clean = {}, {}
	for _, id in ipairs(list) do
		if Config.Pets[id] and #clean < ShopConfig.MaxEquipped then
			counts[id] = (counts[id] or 0) + 1
			if counts[id] <= owned(p, id) then
				table.insert(clean, id)
			end
		end
	end
	table.sort(clean, function(a, b)
		return Config.GetPetMultiplier(a) > Config.GetPetMultiplier(b)
	end)
	local mults, text = {}, {}
	for _, id in ipairs(clean) do
		table.insert(mults, Config.GetPetMultiplier(id))
		table.insert(text, tostring(id))
	end
	p:SetAttribute("Equipped", table.concat(text, ","))
	p:SetAttribute("PetBonus", ShopConfig.TeamBonus(mults))
	p:SetAttribute("PetLevel", clean[1] or 0) -- самый сильный, для статистики
end
function PlayerSystems.EquipBest(p)
	local all = {}
	for id = 1, #Config.Pets do
		for _ = 1, math.min(owned(p, id), ShopConfig.MaxEquipped) do
			table.insert(all, id)
		end
	end
	table.sort(all, function(a, b)
		return Config.GetPetMultiplier(a) > Config.GetPetMultiplier(b)
	end)
	PlayerSystems.SetEquipped(p, { all[1], all[2], all[3] })
end
-- Новый питомец: занимает свободное место или заменяет самого слабого, если сильнее.
function PlayerSystems.OnHatched(p, id)
	local list = PlayerSystems.GetEquipped(p)
	if #list < ShopConfig.MaxEquipped then
		table.insert(list, id)
	else
		local weakest = list[#list]
		if Config.GetPetMultiplier(id) > Config.GetPetMultiplier(weakest) then
			list[#list] = id
		end
	end
	PlayerSystems.SetEquipped(p, list)
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
		if owned(p, id) > 0 then
			discovered += 1
		end
	end
	p:SetAttribute("PetsDiscovered", discovered)
	local unlocked = 0
	for _, badge in ipairs(ShopConfig.Badges) do
		local key = "Badge" .. badge.Id
		if not p:GetAttribute(key) and (p:GetAttribute(badge.Stat) or 0) >= badge.Goal then
			p:SetAttribute(key, true)
			notifyFn(p, "🏅 Achievement: " .. badge.Name .. " · x1.05 coins forever!", true)
		end
		if p:GetAttribute(key) then
			unlocked += 1
		end
	end
	p:SetAttribute("BadgeBonus", ShopConfig.BadgeBonus ^ unlocked)
end

-- ===== Доход =====
function PlayerSystems.CoinMultiplier(p): number
	local m = (p:GetAttribute("PetBonus") or 1) * Config.GetIncomeMultiplier(p:GetAttribute("IncomeLevel") or 0) * (p:GetAttribute("BadgeBonus") or 1)
	if PlayerSystems.PotionActive(p, "Coins") then
		m *= 2
	end
	return m
end

-- ===== Скорость =====
function PlayerSystems.ApplySpeed(p)
	local stats = p:FindFirstChild("leaderstats")
	local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not stats or not h then
		return
	end
	local speed = Config.GetWalkSpeed(stats.SpeedLevel.Value)
	if PlayerSystems.PotionActive(p, "Speed") then
		speed *= 1.5
	end
	if h.WalkSpeed ~= speed then
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
	return r
end
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
	PlayerSystems.GiveMagnet(p)
	notifyFn(p, ShopConfig.Magnets[tier].Name .. " equipped", true)
end

-- ===== Начальные значения =====
function PlayerSystems.Setup(p)
	p:SetAttribute("Equipped", "")
	p:SetAttribute("PetBonus", 1)
	p:SetAttribute("BadgeBonus", 1)
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

return PlayerSystems
