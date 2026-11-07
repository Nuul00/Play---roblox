-- Мини-ивент Frozen Peaks «Метель» (BLIZZARD).
-- Раз в несколько минут во Frozen поднимается метель на 60 секунд: все монеты мира дают x2
-- (PlayerSystems.CoinMultiplier), а по всему острову падают ледяные кристаллы-бонусы.
-- Подобрать кристалл = большая награда (как 40 обычных монет мира с учётом бонусов игрока).
-- Клиент (FrozenFX) по атрибутам workspace.FrozenStormEnd рисует метель, баннер и таймер.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))
local world = workspace:WaitForChild("CoinSpeedWorld")
local frozen = world:WaitForChild("FrozenPeaks", 120)
if not frozen then
	return
end
local CENTER = Vector3.new(3000, 60, 0)
local INTERVAL = 6 * 60
local FIRST = 2 * 60
local DURATION = 60
local CRYSTALS = 24
local REWARD_COINS = 40 -- в «обычных монетах» Frozen
-- ледяная монета берётся из CoinTypes (было вписано 400 при реальных 700 — кристаллы недодавали 43%)
local BASE_VALUE = 700
pcall(function()
	local kinds = require(ReplicatedStorage:WaitForChild("CoinTypes")).Worlds.Frozen.Kinds
	BASE_VALUE = kinds[1].Value
end)

local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
local folder = Instance.new("Folder")
folder.Name = "BlizzardCrystals"
folder.Parent = frozen

local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Include
local function groundAt(x: number, z: number): Vector3?
	ray.FilterDescendantsInstances = { frozen }
	local hit = workspace:Raycast(Vector3.new(x, CENTER.Y + 80, z), Vector3.new(0, -140, 0), ray)
	-- не на горах и не внутри скал (Tripo-горы твёрдые): только земля у подножия
	if not hit or hit.Instance:FindFirstAncestor("TripoModel") or hit.Position.Y > CENTER.Y + 8 then
		return nil
	end
	-- не на острове лидеров
	if hit.Instance:FindFirstAncestor("LeaderboardIsland_FrozenPeaks") then
		return nil
	end
	-- 2026-11: не у яиц и не у магазинов (раньше кристаллы появлялись прямо в зоне яиц)
	for _, d in ipairs(frozen:GetChildren()) do
		if d:IsA("Model") and (string.match(d.Name, "^EggStand%d+$") or d.Name == "UpgradeShop" or d.Name == "MagnetShop") then
			local cf, size = d:GetBoundingBox()
			local o = hit.Position - cf.Position
			if Vector2.new(o.X, o.Z).Magnitude < math.max(size.X, size.Z) / 2 + 14 then
				return nil
			end
		end
	end
	return hit.Position
end

local Worlds = require(game:GetService("ReplicatedStorage"):WaitForChild("WorldsConfig"))
local function unlocked(p, name)
	local def = Worlds.Find(name)
	return not def or (def.Cost or 0) <= 0 or p:GetAttribute(Worlds.UnlockKey(name)) == true
end
local function makeCrystal(pos: Vector3)
	local m = Instance.new("Model")
	m.Name = "FrostCrystal"
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.Material = Enum.Material.Glass
	core.Color = Color3.fromRGB(150, 225, 255)
	core.Transparency = 0.15
	core.Size = Vector3.new(1.8, 3.6, 1.8)
	core.CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, math.random() * 6, 0)
	core.Parent = m
	for k = 1, 3 do
		local shard = core:Clone()
		shard.Name = "Shard"
		shard.CanTouch = false
		shard.Size = Vector3.new(0.9, 2, 0.9)
		shard.CFrame = core.CFrame * CFrame.Angles(0, k * 2.1, 0) * CFrame.new(1, -0.8, 0) * CFrame.Angles(0, 0, 0.5)
		shard.Parent = m
	end
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(150, 220, 255)
	glow.Range = 12
	glow.Brightness = 2
	glow.Parent = core
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
	sp.LightEmission = 1
	sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sp.Lifetime = NumberRange.new(0.8, 1.4)
	sp.Speed = NumberRange.new(1, 3)
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.Rate = 8
	sp.Parent = core
	-- картинка-кристалл (ChatGPT) на билборде вместо простых стеклянных призм + кольцо и луч
	local okE, E = pcall(require, ReplicatedStorage:WaitForChild("LocalEvents"))
	if okE and E.FrostImage then
		for _, d in ipairs(m:GetChildren()) do
			if d:IsA("BasePart") then
				d.Transparency = 1
			end
		end
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(5.2, 5.2)
		bb.StudsOffset = Vector3.new(0, 0.4, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 260
		bb.Adornee = core
		bb.Parent = core
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = E.FrostImage
		img.Parent = bb
		local ring = Instance.new("Part")
		ring.Name = "Ring"
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(150, 225, 255)
		ring.Transparency = 0.45
		ring.Size = Vector3.new(0.2, 5, 5)
		ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Parent = m
		local a0 = Instance.new("Attachment")
		a0.WorldPosition = pos + Vector3.new(0, 0.3, 0)
		a0.Parent = core
		local a1 = Instance.new("Attachment")
		a1.WorldPosition = pos + Vector3.new(0, 22, 0)
		a1.Parent = core
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 2.4
		beam.Width1 = 0.4
		beam.Segments = 10
		beam.LightEmission = 1
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(Color3.fromRGB(150, 225, 255), Color3.fromRGB(220, 245, 255))
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		beam.Parent = core
	end
	m.PrimaryPart = core
	m:AddTag("FrostCrystal")
	local taken = false
	core.Touched:Connect(function(hit)
		if taken then
			return
		end
		local char = hit:FindFirstAncestorOfClass("Model")
		local p = char and Players:GetPlayerFromCharacter(char)
		local stats = p and p:FindFirstChild("leaderstats")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not (stats and root) or (root.Position - core.Position).Magnitude > 12 then
			return
		end
		if not p:GetAttribute("ProfileReady") or not unlocked(p, "Frozen Peaks") then
			return
		end
		-- не больше 8 кристаллов одному игроку за метель (иначе скрипт-телепорт собирал все 24)
		local cap = folder:GetAttribute("Cap_" .. p.UserId) or 0
		if cap >= 8 then
			return
		end
		folder:SetAttribute("Cap_" .. p.UserId, cap + 1)
		taken = true
		local earned = math.floor(BASE_VALUE * REWARD_COINS * PlayerSystems.CoinMultiplier(p))
		stats.Coins.Value += earned
		p:SetAttribute("LifetimeEarned", (p:GetAttribute("LifetimeEarned") or 0) + earned)
		p:SetAttribute("FrostCrystals", (p:GetAttribute("FrostCrystals") or 0) + 1)
		folder:SetAttribute("LastPickup", core.Position) -- клиент проигрывает вспышку
		m:Destroy()
	end)
	m.Parent = folder
end

local function storm()
	local now = workspace:GetServerTimeNow()
	workspace:SetAttribute("FrozenStormEnd", now + DURATION)
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("CurrentWorld") == "Frozen Peaks" then
			feedback:FireClient(p, "❄ BLIZZARD! x2 coins and frost crystals for 60s!", true)
		end
	end
	-- кристаллы падают не сразу, а волнами
	for wave = 1, 3 do
		for _ = 1, CRYSTALS / 3 do
			local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * 140
			local pos = groundAt(CENTER.X + math.cos(a) * r, CENTER.Z + math.sin(a) * r)
			if pos then
				makeCrystal(pos)
			end
		end
		if wave < 3 then
			task.wait(15)
		end
	end
	task.wait(math.max(0, DURATION - 30))
	folder:ClearAllChildren()
	for name in folder:GetAttributes() do
		if string.sub(name, 1, 4) == "Cap_" then folder:SetAttribute(name, nil) end
	end
end

task.wait(FIRST)
while true do
	local ok, err = pcall(storm)
	if not ok then
		warn("[FrozenEvent] " .. tostring(err))
	end
	task.wait(INTERVAL - DURATION)
end
