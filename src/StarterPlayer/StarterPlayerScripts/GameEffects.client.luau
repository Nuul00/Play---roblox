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
-- Питомцы крупнее прежнего и стоят симметрично дугой позади игрока (центр дуги — за спиной).
-- До 5 питомцев — одна дуга, больше — две (ближняя и дальняя), каждая симметрична.
local PET_SCALE = 1.35
local function arc(n: number, radius: number, spread: number): { Vector3 }
	local out = {}
	for i = 1, n do
		local a = n == 1 and 0 or math.rad(-spread + (i - 1) * (2 * spread / (n - 1)))
		table.insert(out, Vector3.new(math.sin(a) * radius, 0, math.cos(a) * radius))
	end
	return out
end
local function formation(n: number): { Vector3 }
	if n <= 0 then
		return {}
	elseif n == 1 then
		return { Vector3.new(0, 0, 5) }
	elseif n <= 5 then
		return arc(n, 5.4, n == 2 and 38 or 62)
	end
	local inner = math.ceil(n / 2)
	local list = arc(inner, 5.2, 62)
	for _, v in ipairs(arc(n - inner, 9, inner == n - inner and 50 or 36)) do
		table.insert(list, v)
	end
	return list
end
local function rebuild(record)
	clearPets(record)
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
			tag.Size = UDim2.fromOffset(160, 24)
			tag.StudsOffset = Vector3.new(0, 3.1, 0) -- питомцы крупнее: подпись выше
			tag.MaxDistance = 40
			tag.LightInfluence = 0
			tag.Parent = model.PrimaryPart
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Font = Enum.Font.GothamBold
			text.TextSize = 13
			text.TextColor3 = Color3.new(1, 1, 1)
			text.TextStrokeTransparency = 0.3
			local variant = ShopConfig.Variants[tier]
			text.Text = (variant and (variant.Name .. " ") or "") .. def.Name .. "  x" .. string.format("%g", def.Multiplier * ShopConfig.VariantMult(tier))
			if variant then
				text.TextColor3 = variant.Color:Lerp(Color3.new(1, 1, 1), 0.3)
			end
			text.Parent = tag
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
		rebuild(record)
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
-- Frozen Peaks свои монеты-модели оживляет сам (TripoCoins), здесь — Volcano и Galaxy.
for _, zone in ipairs({ world, world:WaitForChild("NeonCity"), skyWorld, world:WaitForChild("MagmaVolcano", 30), world:WaitForChild("CosmicGalaxy", 30) }) do
	for _, coin in ipairs(zone:GetChildren()) do
		if coin:IsA("BasePart") and coin.Name:match("^Coin_%d+$") then
			table.insert(coins, { part = coin, base = coin.CFrame, phase = #coins * 0.7 })
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
local function collectBurst(coin)
	-- у монет с 3D-моделью (TripoCoins) свой эффект сбора
	if coin:FindFirstChildWhichIsA("Model") then
		return
	end
	local worldId = coin:GetAttribute("CoinWorld") or "Sky"
	local theme = (CoinTypes.Worlds[worldId] or CoinTypes.Worlds.Sky).Theme
	local rarity = coin:GetAttribute("Rarity") or 1
	local camera = Workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - coin.Position).Magnitude > 140 then
		return
	end
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
	burst:Emit(16 + rarity * 10)
	local light = Instance.new("PointLight")
	light.Color = theme[1]
	light.Range = 10
	light.Brightness = 3
	light.Parent = ghost
	-- Летит вверх и к игроку, если он рядом, уменьшаясь и растворяясь.
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = coin.Position + Vector3.new(0, 3, 0)
	if root and (root.Position - coin.Position).Magnitude < 40 then
		target = coin.Position:Lerp(root.Position + Vector3.new(0, 2, 0), 0.7)
	end
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	TweenService:Create(ghost, info, { CFrame = CFrame.new(target) * ghost.CFrame.Rotation * CFrame.Angles(0, math.pi, 0), Size = ghost.Size * 0.3, Transparency = 1 }):Play()
	TweenService:Create(light, TweenInfo.new(0.4), { Brightness = 0 }):Play()
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
				pet.model:PivotTo(pet.frame * CFrame.new(0, hop + bob, 0) * CFrame.Angles(pitch, look, roll))
			else
				pet.frame = nil
				pet.model:PivotTo(hidden)
			end
		end
	end

	for _, c in ipairs(coins) do
		if c.part.Parent and (eye - c.base.Position).Magnitude < 170 then
			local a = t + c.phase
			c.part.CFrame = CFrame.new(c.base.Position + Vector3.new(0, math.sin(a * 2) * 0.35, 0)) * CFrame.Angles(0, a * 1.8, 0) * c.base.Rotation
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
