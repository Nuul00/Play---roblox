-- Ребёрс: игрок отдаёт монеты и прокачку, получает постоянный множитель монет (Config.GetRebirthBonus),
-- удачу яиц (атрибут RebirthLuck), слоты команды питомцев (RebirthSlots), титул и ауру на вехах
-- и разовые подарки-зелья (Config.RebirthMilestones).
-- Требование: монеты И яйца, открытые с прошлого ребёрса (Save_RebirthEggs — сохраняется автоматически).
-- Выданные вехи: Save_RebirthClaimed = число ребёрсов, до которого подарки уже выданы.
-- Сохраняется: питомцы, яйца, магниты, зелья, индекс, достижения, открытые миры.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))
local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
local world = workspace:WaitForChild("CoinSpeedWorld")

local EGGS_ATTR = "Save_RebirthEggs"
local CLAIMED_ATTR = "Save_RebirthClaimed"

local remote = Instance.new("RemoteEvent")
remote.Name = "GameRebirth"
remote.Parent = ReplicatedStorage

-- Короткая запись больших чисел: 1.5K, 20M, 3.2Qa.
local function fmt(n)
	n = tonumber(n) or 0
	local units = { { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			local v = n / u[1]
			return (string.format(v >= 100 and "%.0f" or "%.1f", v):gsub("%.0$", "")) .. u[2]
		end
	end
	return tostring(math.floor(n))
end

-- ===== Визуал: аура (частицы у корня) и титул над головой =====
local AURA_COLORS = {
	ColorSequence.new(Color3.fromRGB(255, 175, 100), Color3.fromRGB(200, 110, 50)),
	ColorSequence.new(Color3.fromRGB(255, 245, 150), Color3.fromRGB(255, 185, 40)),
	ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 80)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 230, 120)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 160, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 100, 255)),
	}),
	ColorSequence.new(Color3.fromRGB(180, 120, 255), Color3.fromRGB(80, 210, 255)),
}
local TITLE_COLORS = {
	Reborn = Color3.fromRGB(255, 225, 120),
	Ascended = Color3.fromRGB(140, 230, 255),
	Mythic = Color3.fromRGB(255, 120, 200),
	Eternal = Color3.fromRGB(200, 160, 255),
}

local function applyVisuals(p)
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local r = p:GetAttribute("Rebirths") or 0
	if root then
		local old = root:FindFirstChild("RebirthAura")
		if old then
			old:Destroy()
		end
		local tier = Config.GetRebirthAura(r)
		if tier > 0 then
			local e = Instance.new("ParticleEmitter")
			e.Name = "RebirthAura"
			e.Color = AURA_COLORS[math.clamp(tier, 1, #AURA_COLORS)]
			e.LightEmission = 0.8
			e.LightInfluence = 0
			e.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(0.3, 0.45),
				NumberSequenceKeypoint.new(1, 0),
			})
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.6),
				NumberSequenceKeypoint.new(0.3, 0.1),
				NumberSequenceKeypoint.new(1, 1),
			})
			e.Lifetime = NumberRange.new(1, 1.8)
			e.Rate = 5 + 4 * tier
			e.Speed = NumberRange.new(1.5, 3)
			e.SpreadAngle = Vector2.new(25, 25)
			e.EmissionDirection = Enum.NormalId.Top
			e.Acceleration = Vector3.new(0, 1.5, 0)
			e.RotSpeed = NumberRange.new(-90, 90)
			e.Rotation = NumberRange.new(0, 360)
			e.Parent = root
		end
	end
	if head then
		local oldTag = head:FindFirstChild("RebirthTitle")
		if oldTag then
			oldTag:Destroy()
		end
		local title = Config.GetRebirthTitle(r)
		if title ~= "" then
			local b = Instance.new("BillboardGui")
			b.Name = "RebirthTitle"
			b.Size = UDim2.fromScale(6, 0.9)
			b.StudsOffset = Vector3.new(0, 2.7, 0)
			b.MaxDistance = 90
			b.LightInfluence = 0
			b.Adornee = head
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, 1)
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.Text = "🔄 " .. title .. " · " .. r
			l.TextColor3 = TITLE_COLORS[title] or Color3.new(1, 1, 1)
			l.Parent = b
			local s = Instance.new("UIStroke")
			s.Color = Color3.fromRGB(30, 30, 40)
			s.Thickness = 2
			s.Parent = l
			b.Parent = head
		end
	end
end

-- ===== Награды =====
-- Разовые подарки вех: выдаём только при загруженном профиле, иначе загрузка их перезапишет.
local function giveMilestones(p)
	if not p:GetAttribute("ProfileReady") then
		return
	end
	local r = p:GetAttribute("Rebirths") or 0
	local claimed = tonumber(p:GetAttribute(CLAIMED_ATTR)) or 0
	if r <= claimed then
		return
	end
	local names = {}
	for _, m in ipairs(Config.RebirthMilestones) do
		if m.At > claimed and m.At <= r then
			if m.Potions then
				for name, n in pairs(m.Potions) do
					local attr = "Potion" .. name
					p:SetAttribute(attr, (p:GetAttribute(attr) or 0) + n)
				end
			end
			table.insert(names, m.Icon .. " " .. m.Name)
		end
	end
	p:SetAttribute(CLAIMED_ATTR, r)
	if #names > 0 then
		feedback:FireClient(p, "🎁 Rebirth reward unlocked: " .. table.concat(names, ", ") .. "!", true)
	end
end

-- Постоянные бонусы читают другие системы: RebirthLuck (доля), RebirthSlots (целое).
local function applyRewards(p)
	local r = p:GetAttribute("Rebirths") or 0
	p:SetAttribute("RebirthLuck", Config.GetRebirthLuck(r))
	p:SetAttribute("RebirthSlots", Config.GetRebirthSlots(r))
	p:SetAttribute("RebirthTitle", Config.GetRebirthTitle(r))
	p:SetAttribute("RebirthAura", Config.GetRebirthAura(r))
	giveMilestones(p)
	applyVisuals(p)
end

local function setup(p)
	p:GetAttributeChangedSignal("Rebirths"):Connect(function()
		applyRewards(p)
	end)
	p:GetAttributeChangedSignal("ProfileReady"):Connect(function()
		if p:GetAttribute("ProfileReady") then
			applyRewards(p)
		end
	end)
	p.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Head", 10)
		if p.Character == character then
			applyVisuals(p)
		end
	end)
	applyRewards(p)
end
Players.PlayerAdded:Connect(setup)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setup, p)
end

-- ===== Счётчик яиц с прошлого ребёрса =====
task.spawn(function()
	local signals = ServerStorage:WaitForChild("ServerSignals", 60)
	local eggs = signals and signals:WaitForChild("EggsHatched", 60)
	if not eggs then
		warn("Rebirth: ServerSignals.EggsHatched not found, egg requirement will not progress")
		return
	end
	eggs.Event:Connect(function(p, _eggId, amount)
		if typeof(p) ~= "Instance" or not p:IsA("Player") or not p:GetAttribute("ProfileReady") then
			return
		end
		local n = math.floor(tonumber(amount) or 0)
		if n <= 0 then
			return
		end
		p:SetAttribute(EGGS_ATTR, math.min((tonumber(p:GetAttribute(EGGS_ATTR)) or 0) + n, 1e9))
	end)
end)

-- ===== Запрос ребёрса =====
local last, lastTry = {}, {}
Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
	lastTry[p] = nil
end)

remote.OnServerEvent:Connect(function(p)
	if not p:GetAttribute("ProfileReady") then
		return
	end
	local now = os.clock()
	if now - (last[p] or -10) < 2 or now - (lastTry[p] or -10) < 0.5 then
		return
	end
	lastTry[p] = now
	local stats = p:FindFirstChild("leaderstats")
	local character = p.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not stats or not humanoid or humanoid.Health <= 0 then
		return
	end
	local count = p:GetAttribute("Rebirths") or 0
	if count >= Config.MaxRebirths then
		feedback:FireClient(p, "You reached the maximum rebirth!", false)
		return
	end
	local cost = Config.GetRebirthCost(count)
	local needEggs = Config.GetRebirthEggs(count)
	local eggs = tonumber(p:GetAttribute(EGGS_ATTR)) or 0
	local have = stats.Coins.Value
	local missCoins = have < cost
	local missEggs = eggs < needEggs
	if missCoins and missEggs then
		feedback:FireClient(p, "Rebirth needs " .. fmt(cost - have) .. " more coins and " .. tostring(math.floor(needEggs - eggs)) .. " more eggs opened", false)
		return
	elseif missCoins then
		feedback:FireClient(p, "Rebirth needs " .. fmt(cost - have) .. " more coins", false)
		return
	elseif missEggs then
		feedback:FireClient(p, "Open " .. tostring(math.floor(needEggs - eggs)) .. " more eggs to rebirth!", false)
		return
	end
	last[p] = now
	stats.Coins.Value = 0
	stats.SpeedLevel.Value = math.max(Config.RebirthStartSpeed, 0)
	for _, name in ipairs({ "MagnetLevel", "IncomeLevel", "DoubleLevel" }) do
		p:SetAttribute(name, 0)
	end
	p:SetAttribute(EGGS_ATTR, 0)
	p:SetAttribute("Rebirths", count + 1) -- applyRewards сработает через сигнал атрибута
	PlayerSystems.ApplySpeed(p)
	-- Игрок остаётся в своём мире (открытые миры не сбрасываются): ребёрс ощущается как рывок силы —
	-- дешёвые первые уровни прокачки здесь же, богатые монеты мира и новый множитель. Раньше кидало
	-- в Meadow, и приходилось вручную лететь обратно через TELEPORT.
end)
