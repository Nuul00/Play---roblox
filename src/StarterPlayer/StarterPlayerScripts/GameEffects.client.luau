-- Только оформление у клиента: питомцы игроков (до 3), кольцо радиуса магнита,
-- вращение монет и звук сбора. Денег и наград здесь нет.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local localPlayer = Players.LocalPlayer

local effects = Instance.new("Folder")
effects.Name = "CoinSprintClientFX"
effects.Parent = Workspace

-- ===== Питомцы =====
local records = {}
local function clearPets(record)
	for _, pet in ipairs(record.pets) do
		pet.model:Destroy()
	end
	record.pets = {}
end
-- Расстановка, удобная игроку: камера смотрит из-за спины, поэтому прямо сзади никого нет.
-- Питомцы идут парами по бокам (следующая пара чуть дальше назад), нечётный — сзади по центру.
-- Так обзор чистый, и всё симметрично.
local PET_SCALE = 1.1
local function formation(n: number): { Vector3 }
	local list = {}
	local pairsCount = math.floor(n / 2)
	for row = 1, pairsCount do
		local z = 0.6 + (row - 1) * 3.4
		local x = 4.4 + (row - 1) * 0.6
		table.insert(list, Vector3.new(-x, 0, z))
		table.insert(list, Vector3.new(x, 0, z))
	end
	if n % 2 == 1 then
		table.insert(list, Vector3.new(0, 0, 3.4 + pairsCount * 3.4)) -- сзади по центру, за последней парой
	end
	return list
end
local function rebuild(record)
	clearPets(record)
	record.levelTags = {}
	local codes = ShopConfig.ParseEquipped(record.player:GetAttribute("Equipped"))
	local spots = formation(#codes)
	for slot, code in ipairs(codes) do
		local id, tier = ShopConfig.SplitPet(code)
		local def = Config.Pets[id]
		if def then
			local model = PetVisuals.BuildCode(code, true)
			model.Name = "Pet_" .. record.player.UserId .. "_" .. slot
			pcall(function()
				model:ScaleTo(model:GetScale() * PET_SCALE)
			end)
			-- насколько опорная точка модели выше её низа: ставим питомца лапами на землю
			local bbox, ext = model:GetBoundingBox()
			local lift = model:GetPivot().Position.Y - (bbox.Position.Y - ext.Y / 2)
			model.Parent = effects
			local tag = Instance.new("BillboardGui")
			tag.Size = UDim2.fromOffset(140, 18)
			tag.StudsOffset = Vector3.new(0, 2.5, 0)
			tag.MaxDistance = 22
			tag.LightInfluence = 0
			tag.Parent = model.PrimaryPart
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Font = Enum.Font.GothamBold
			text.TextSize = 11
			text.TextColor3 = Color3.new(1, 1, 1)
			text.TextStrokeTransparency = 0.3
			local variant = ShopConfig.Variants[tier]
			local baseName = (variant and (variant.Name .. " ") or "") .. def.Name -- без множителя: имя и уровень
			text.Text = "Lv " .. ShopConfig.PetLevelOf(record.player, id) .. " · " .. baseName
			if variant then
				text.TextColor3 = variant.Color:Lerp(Color3.new(1, 1, 1), 0.3)
			end
			text.Parent = tag
			record.levelTags = record.levelTags or {}
			table.insert(record.levelTags, { id = id, label = text, name = baseName })
			local rainbow = {}
			if tier == 3 then
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("BasePart") then
						table.insert(rainbow, d)
					end
				end
			end
			table.insert(record.pets, { model = model, slot = slot, rainbow = rainbow, offset = spots[slot], lift = lift })
		end
	end
end
local function addPlayer(player)
	if records[player] then
		return
	end
	local record = { player = player, pets = {}, connections = {} }
	records[player] = record
	table.insert(record.connections, player:GetAttributeChangedSignal("Equipped"):Connect(function()
		-- пачка из 9 яиц меняет команду до 9 раз: пересобираем питомцев один раз
		if record.pending then
			return
		end
		record.pending = true
		task.defer(function()
			record.pending = false
			if records[player] == record then
				rebuild(record)
			end
		end)
	end))
	-- уровень питомца вырос (опыт вида Save_PetXP_<id>) — обновляем «Lv N» в табличке без пересборки
	table.insert(record.connections, player.AttributeChanged:Connect(function(name)
		local id = tonumber(string.match(name, "^Save_PetXP_(%d+)$"))
		if not id then
			return
		end
		local lv = ShopConfig.PetLevelOf(player, id)
		for _, t in ipairs(record.levelTags or {}) do
			if t.id == id and t.label.Parent then
				local s = "Lv " .. lv .. " · " .. t.name
				if t.label.Text ~= s then
					t.label.Text = s
				end
			end
		end
	end))
	rebuild(record)
end
local function removePlayer(player)
	local record = records[player]
	if record then
		for _, c in ipairs(record.connections) do
			c:Disconnect()
		end
		clearPets(record)
		records[player] = nil
	end
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, p in ipairs(Players:GetPlayers()) do
	addPlayer(p)
end

-- Позиции трёх мест: слева, позади, справа от хозяина.
-- Дуга позади-сбоку, чтобы питомцы не закрывали персонажа от камеры.
local slotOffsets = { Vector3.new(-4.6, 0, 1.2), Vector3.new(4.6, 0, 1.2), Vector3.new(-2.6, 0, 4.4) }
-- Слоты за ребёрсы (больше 3 питомцев): второй ряд позади игрока.
for _, offset in ipairs({ Vector3.new(2.6, 0, 4.4), Vector3.new(0, 0, 6.2), Vector3.new(-5.2, 0, 6.6), Vector3.new(5.2, 0, 6.6), Vector3.new(-2.6, 0, 8.6), Vector3.new(2.6, 0, 8.6) }) do
	table.insert(slotOffsets, offset)
end
local hidden = CFrame.new(0, -10000, 0)

-- ===== Кольцо магнита (видно, если включено в статистике) =====
local ringSegments = {}
for i = 1, 32 do
	local part = Instance.new("Part")
	part.Name = "MagnetRing"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(191, 114, 255)
	part.Transparency = 1
	part.Size = Vector3.new(0.08, 0.05, 1)
	part.Parent = effects
	ringSegments[i] = part
end
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- ===== Монеты: вращение и покачивание только у клиента =====
local coins = {}
local world = Workspace:WaitForChild("CoinSpeedWorld")
local skyWorld = world:WaitForChild("SkyIsles", 30)
-- Frozen, Volcano и Galaxy свои монеты-модели оживляет TripoCoins, здесь — Meadow, Неон и Sky.
-- Крутим только монеты мира, где сейчас игрок (остальные не видно), и только рядом с камерой.
local COIN_ZONES = { { world, "Meadow Isles" }, { world:WaitForChild("NeonCity"), "Neon District" }, { skyWorld, "Sky Isles" } }
for _, entry in ipairs(COIN_ZONES) do
	local zone, zoneWorld = entry[1], entry[2]
	for _, coin in ipairs(zone and zone:GetChildren() or {}) do
		if coin:IsA("BasePart") and coin.Name:match("^Coin_%d+$") then
			local rec = { part = coin, base = coin.CFrame, phase = #coins * 0.7, world = zoneWorld }
			table.insert(coins, rec)
			-- сервер может переставить монету (WorldPolish поднимает из земли): берём новый «дом»
			coin:GetAttributeChangedSignal("Home"):Connect(function()
				local home = coin:GetAttribute("Home")
				if typeof(home) == "Vector3" then
					rec.base = CFrame.new(home) * rec.base.Rotation
				end
			end)
			local home = coin:GetAttribute("Home")
			if typeof(home) == "Vector3" then
				rec.base = CFrame.new(home) * rec.base.Rotation
			end
			for _, d in ipairs(coin:GetDescendants()) do
				if d:IsA("BillboardGui") then
					d.Enabled = false
				end
			end
		end
	end
end

-- ===== Эффект сбора монет: монета вспыхивает, взлетает к игроку и тает, разлетаются искры цветов мира =====
-- (CoinTypes.Worlds[...].Theme). Редкие монеты дают больше искр; в Неонграде ещё расходится неоновое кольцо.
local TweenService = game:GetService("TweenService")
local CoinTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("CoinTypes"))
local burstsLive = 0
local function collectBurst(coin)
	-- у монет с 3D-моделью (TripoCoins) свой эффект сбора
	if coin:FindFirstChildWhichIsA("Model") then
		return
	end
	local worldId = coin:GetAttribute("CoinWorld") or "Sky"
	local theme = (CoinTypes.Worlds[worldId] or CoinTypes.Worlds.Sky).Theme
	local rarity = coin:GetAttribute("Rarity") or 1
	-- вспышка только у своих монет (рядом с собой) и не больше 6 сразу — иначе Vacuum и чужие
	-- сборы плодят десятки клонов и частиц
	local me = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not me or (me.Position - coin.Position).Magnitude > 45 or burstsLive >= 6 then
		return
	end
	burstsLive += 1
	task.delay(0.9, function()
		burstsLive -= 1
	end)
	local ghost = coin:Clone()
	for _, d in ipairs(ghost:GetChildren()) do
		if not d:IsA("SurfaceAppearance") then
			d:Destroy()
		end
	end
	ghost.Name = "CoinGhost"
	ghost.Transparency = 0
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanTouch = false
	ghost.CanQuery = false
	ghost.Parent = effects
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	burst.Color = ColorSequence.new(theme[1], theme[2])
	burst.LightEmission = 1
	burst.Lifetime = NumberRange.new(0.4, 0.8)
	burst.Speed = NumberRange.new(6, 12)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Drag = 4
	burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	burst.Rate = 0
	burst.Parent = ghost
	burst:Emit(10 + rarity * 6)
	-- Летит вверх и к игроку, если он рядом, уменьшаясь и растворяясь.
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = coin.Position + Vector3.new(0, 3, 0)
	if root and (root.Position - coin.Position).Magnitude < 40 then
		target = coin.Position:Lerp(root.Position + Vector3.new(0, 2, 0), 0.7)
	end
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	TweenService:Create(ghost, info, { CFrame = CFrame.new(target) * ghost.CFrame.Rotation * CFrame.Angles(0, math.pi, 0), Size = ghost.Size * 0.3, Transparency = 1 }):Play()
	if worldId == "Neon" then
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = theme[rarity % 2 + 1]
		ring.Size = Vector3.new(0.1, 1, 1)
		ring.CFrame = CFrame.new(coin.Position - Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Transparency = 0.2
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanTouch = false
		ring.CanQuery = false
		ring.CastShadow = false
		ring.Parent = effects
		local grow = TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.1, 7 + rarity * 2, 7 + rarity * 2), Transparency = 1 })
		grow.Completed:Connect(function()
			ring:Destroy()
		end)
		grow:Play()
	end
	task.delay(0.9, function()
		ghost:Destroy()
	end)
end
for _, c in ipairs(coins) do
	local coin = c.part
	coin:GetAttributeChangedSignal("Available"):Connect(function()
		if coin:GetAttribute("Available") == false then
			collectBurst(coin)
		end
	end)
end

-- ===== Звук сбора монеты: берём звук "coin2" из плейса, иначе стандартный =====
local soundId = "rbxasset://sounds/electronicpingshort.wav"
for _, d in ipairs(Workspace:GetDescendants()) do
	if d:IsA("Sound") and string.lower(d.Name):find("coin") and d.SoundId ~= "" then
		soundId = d.SoundId
		break
	end
end
local sounds = {}
for i = 1, 4 do
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = 0.45
	s.Parent = SoundService
	sounds[i] = s
end
local soundIndex, lastSound = 0, 0
-- Магнитные волны (фидбэк 2026-11): когда магнит собирает монеты, от него расходится полупрозрачная
-- волна до радиуса магнита — видно, что монеты притягивает именно он. Не чаще ~3 раз в секунду.
local lastWave = 0
local function magnetWave()
	if os.clock() - lastWave < 0.33 then
		return
	end
	local char = localPlayer.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local from = (handle and handle:IsA("BasePart") and handle) or root
	if not from then
		return
	end
	lastWave = os.clock()
	local radius = math.clamp(tonumber(localPlayer:GetAttribute("MagnetRadius")) or 6, 3, 40)
	local wave = Instance.new("Part")
	wave.Name = "MagnetWave"
	wave.Shape = Enum.PartType.Ball
	wave.Material = Enum.Material.ForceField
	wave.Color = Color3.fromRGB(120, 200, 255)
	wave.Anchored, wave.CanCollide, wave.CanQuery, wave.CanTouch, wave.CastShadow = true, false, false, false, false
	wave.Size = Vector3.new(1.5, 1.5, 1.5)
	wave.Transparency = 0.1
	wave.CFrame = from.CFrame
	wave.Parent = Workspace
	local info = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(wave, info, { Size = Vector3.new(radius * 2, radius * 2, radius * 2), Transparency = 1 }):Play()
	task.delay(0.6, function()
		wave:Destroy()
	end)
end
local lastCollected = localPlayer:GetAttribute("CoinsCollected") or 0
localPlayer:GetAttributeChangedSignal("CoinsCollected"):Connect(function()
	local now = localPlayer:GetAttribute("CoinsCollected") or 0
	if now > lastCollected and os.clock() - lastSound > 0.05 then
		lastSound = os.clock()
		soundIndex = soundIndex % #sounds + 1
		sounds[soundIndex].PlaybackSpeed = 0.95 + math.random() * 0.12
		sounds[soundIndex]:Play()
	end
	lastCollected = now
end)

local t = 0
local coinClock, coinParts, coinFrames = 0, {}, {}
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local camera = Workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position or Vector3.zero

	for player, record in pairs(records) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		for _, pet in ipairs(record.pets) do
			if root and humanoid and humanoid.Health > 0 and (root.Position - eye).Magnitude < 220 then
				local _, yaw = root.CFrame:ToOrientation()
				local offset = pet.offset or slotOffsets[pet.slot] or slotOffsets[2]
				local ground = -(humanoid.HipHeight + root.Size.Y / 2) -- уровень земли относительно центра HumanoidRootPart
				local target = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0) * CFrame.new(offset.X, ground + (pet.lift or 1.9) + 0.05, offset.Z)
				if not pet.frame or (pet.frame.Position - target.Position).Magnitude > 50 then
					pet.frame = target
				else
					pet.frame = pet.frame:Lerp(target, 1 - math.exp(-9 * dt))
				end
				-- «Живое» движение без костей: на бегу питомец скачет (частота от скорости), наклоняется
				-- вперёд и переваливается с боку на бок, при приземлении чуть кивает; стоя — плавно
				-- покачивается и иногда оглядывается. Переход между режимами плавный (pet.move 0..1).
				local v = root.AssemblyLinearVelocity
				local speed = Vector2.new(v.X, v.Z).Magnitude
				local moving = speed > 2 and 1 or 0
				pet.move = (pet.move or 0) + (moving - (pet.move or 0)) * (1 - math.exp(-6 * dt))
				pet.phase = (pet.phase or pet.slot * 1.1) + dt * math.clamp(speed * 0.55, 7, 15) * pet.move
				local m = pet.move
				local s = math.sin(pet.phase)
				local hop = math.abs(s) * 0.85 * m
				local land = (1 - math.abs(s)) ^ 4 -- 1 в момент касания земли
				local idle = 1 - m
				local bob = math.sin(t * 2.2 + pet.slot * 1.3) * 0.18 * idle
				local pitch = (-0.16 + 0.14 * land) * m + math.sin(t * 1.7 + pet.slot) * 0.04 * idle
				local roll = s * 0.16 * m -- знак меняется на каждом прыжке: вперевалку
				local look = math.sin(t * 0.45 + pet.slot * 2.1) ^ 3 * 0.55 * idle
				pet.hidden = false
				pet.model:PivotTo(pet.frame * CFrame.new(0, hop + bob, 0) * CFrame.Angles(pitch, look, roll))
			elseif pet.frame ~= nil or not pet.hidden then
				-- прячем один раз (аудит 2026-11: раньше спрятанных двигали заново каждый кадр)
				pet.frame = nil
				pet.hidden = true
				pet.model:PivotTo(hidden)
			end
		end
	end

	-- монеты: каждый кадр (при 30 Гц вращение выглядело рывками — фидбэк 2026-11), только своего мира
	-- и в 110 стадах, одним пакетом BulkMoveTo
	coinClock += dt
	if coinClock >= 0 then
		coinClock = 0
		local here = localPlayer:GetAttribute("CurrentWorld") or "Meadow Isles"
		table.clear(coinParts)
		table.clear(coinFrames)
		for _, c in ipairs(coins) do
			if c.world == here and c.part.Parent and (eye - c.base.Position).Magnitude < 110 then
				local a = t + c.phase
				table.insert(coinParts, c.part)
				table.insert(coinFrames, CFrame.new(c.base.Position + Vector3.new(0, math.sin(a * 2) * 0.35, 0)) * CFrame.Angles(0, a * 1.8, 0) * c.base.Rotation)
			end
		end
		if #coinParts > 0 then
			Workspace:BulkMoveTo(coinParts, coinFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end

	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local show = root and localPlayer:GetAttribute("ShowMagnetRange")
	if show then
		rayParams.FilterDescendantsInstances = { effects, character }
		local ground = Workspace:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -40, 0), rayParams)
		show = ground ~= nil
		if ground then
			local radius = localPlayer:GetAttribute("MagnetRadius") or Config.GetMagnetRadius(0)
			local center = Vector3.new(root.Position.X, ground.Position.Y + 0.1, root.Position.Z)
			local n = #ringSegments
			local chord = 2 * radius * math.sin(math.pi / n) + 0.02
			for i, part in ipairs(ringSegments) do
				local a = (i - 0.5) / n * math.pi * 2
				part.Size = Vector3.new(0.08, 0.05, chord)
				part.CFrame = CFrame.new(center + Vector3.new(math.cos(a), 0, math.sin(a)) * radius) * CFrame.Angles(0, -a, 0)
				part.Transparency = 0.5
			end
		end
	end
	if not show then
		for _, part in ipairs(ringSegments) do
			part.Transparency = 1
		end
	end
end)

-- Радужные питомцы переливаются цветами (10 раз в секунду, только у видимых).
do
	local acc, hue = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		hue += dt * 0.25
		if acc < 0.1 then
			return
		end
		acc = 0
		for _, record in pairs(records) do
			for _, pet in ipairs(record.pets) do
				for k, part in ipairs(pet.rainbow or {}) do
					part.Color = Color3.fromHSV((hue + k * 0.09) % 1, 0.7, 1)
				end
			end
		end
	end)
end
