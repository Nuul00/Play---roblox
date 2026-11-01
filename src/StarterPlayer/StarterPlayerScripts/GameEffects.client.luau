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
local function rebuild(record)
	clearPets(record)
	for slot, id in ipairs(ShopConfig.ParseEquipped(record.player:GetAttribute("Equipped"))) do
		local def = Config.Pets[id]
		if def then
			local model = PetVisuals.Build(id)
			model.Name = "Pet_" .. record.player.UserId .. "_" .. slot
			model.Parent = effects
			local tag = Instance.new("BillboardGui")
			tag.Size = UDim2.fromOffset(160, 24)
			tag.StudsOffset = Vector3.new(0, 2.4, 0)
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
			text.Text = def.Name .. "  x" .. string.format("%g", def.Multiplier)
			text.Parent = tag
			table.insert(record.pets, { model = model, slot = slot })
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
for _, zone in ipairs({ world, world:WaitForChild("NeonCity") }) do
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
				local offset = slotOffsets[pet.slot] or slotOffsets[2]
				local bob = math.sin(t * 3 + pet.slot * 1.3) * 0.2
				local target = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0) * CFrame.new(offset.X, -1.1 + bob, offset.Z)
				if not pet.frame or (pet.frame.Position - target.Position).Magnitude > 50 then
					pet.frame = target
				else
					pet.frame = pet.frame:Lerp(target, 1 - math.exp(-9 * dt))
				end
				pet.model:PivotTo(pet.frame)
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
