-- LocalScript в StarterPlayer > StarterPlayerScripts.
-- Только оформление: питомцы и кольцо магнита. Денег и наград здесь нет.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local localPlayer = Players.LocalPlayer
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))

if type(Config.Pets) ~= "table"
	or type(Config.GetPetMultiplier) ~= "function"
	or type(Config.GetMagnetRadius) ~= "function" then
	warn("[CoinSprint] GameEffects: обновите GameConfig для питомцев и магнита.")
	return
end

-- Объекты, созданные LocalScript, видны только на этом компьютере.
-- Каждый клиент сам рисует питомцев всех игроков по их атрибутам.
local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "CoinSprintClientFX"
effectsFolder.Parent = Workspace

local records = {}
local connections = {}
local stopped = false
local offscreen = CFrame.new(0, -10000, 0)

local function getPetLevel(player)
	local value = player:GetAttribute("PetLevel")
	if type(value) ~= "number" then
		return 0
	end
	return math.clamp(math.floor(value), 0, #Config.Pets)
end

local function getMagnetLevel()
	local value = localPlayer:GetAttribute("MagnetLevel")
	return type(value) == "number" and math.max(0, math.floor(value)) or 0
end

local function setPetVisible(record, visible)
	if record.visible == visible then
		return
	end
	record.visible = visible
	for _, entry in ipairs(record.parts) do
		if entry.part.Parent then
			entry.part.Transparency = visible and entry.transparency or 1
		end
	end
	if record.billboard then
		record.billboard.Enabled = visible
	end
end

local function refreshPet(record)
	local level = getPetLevel(record.player)
	if level == record.level then
		return
	end
	if record.model then
		record.model:Destroy()
	end
	record.level = level
	record.model = nil
	record.billboard = nil
	record.parts = {}
	record.frame = nil
	record.visible = false
	if level == 0 then
		return
	end

	local definition = Config.Pets[level]
	local model, parts = PetVisuals.Build(level)
	model.Name = "Pet_" .. record.player.UserId
	model.Parent = effectsFolder
	record.model = model
	record.parts = parts
	local body = model.PrimaryPart
	for _,entry in ipairs(parts) do entry.part.Transparency = 1 end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PetName"
	billboard.Size = UDim2.fromOffset(170, 28)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.MaxDistance = 45
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	billboard.Parent = body
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 13
	text.TextColor3 = Color3.fromRGB(255, 248, 229)
	text.TextStrokeTransparency = 0.25
	text.Text = definition.Name .. "  x" .. string.format("%g", Config.GetPetMultiplier(level))
	text.Parent = billboard
	record.billboard = billboard
end

-- Кольцо лежит чуть выше поверхности, чтобы не мерцать внутри пола.
local ring = Instance.new("Model")
ring.Name = "LocalMagnetRadius"
ring.Parent = effectsFolder
local ringSegments = {}
local ringVisible = false
local ringRadius = -1
local segmentCount = 24
local segmentAngle = math.pi * 2 / segmentCount
for index = 1, segmentCount do
	local angleA = (index - 1) * segmentAngle
	local angleB = index * segmentAngle
	local a = Vector3.new(math.cos(angleA), 0, math.sin(angleA))
	local b = Vector3.new(math.cos(angleB), 0, math.sin(angleB))
	local part = Instance.new("Part")
	part.Name = "RingSegment"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(191, 114, 255)
	part.Size = Vector3.new(0.1, 0.07, 0.5)
	part.Transparency = 1
	part.CFrame = offscreen
	part.Parent = ring
	table.insert(ringSegments, {
		part = part,
		middle = (a + b) / 2,
		rotation = CFrame.lookAt(Vector3.zero, b - a),
	})
end

local function setRingVisible(visible)
	if ringVisible == visible then
		return
	end
	ringVisible = visible
	for _, segment in ipairs(ringSegments) do
		segment.part.Transparency = visible and 0.86 or 1
	end
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local function refreshRaycastFilter()
	local excluded = { effectsFolder }
	for player in pairs(records) do
		if player.Character then
			table.insert(excluded, player.Character)
		end
	end
	raycastParams.FilterDescendantsInstances = excluded
end

local function addPlayer(player)
	if records[player] then
		return
	end
	local record = { player = player, level = -1, parts = {}, connections = {}, visible = false }
	records[player] = record
	table.insert(record.connections, player:GetAttributeChangedSignal("PetLevel"):Connect(function()
		refreshPet(record)
	end))
	table.insert(record.connections, player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
		record.frame = nil -- Портал: сразу переносим питомца вместе с хозяином.
	end))
	table.insert(record.connections, player.CharacterAdded:Connect(function()
		record.frame = nil
		refreshRaycastFilter()
	end))
	table.insert(record.connections, player.CharacterRemoving:Connect(function()
		setPetVisible(record, false)
		record.frame = nil
		if player == localPlayer then
			setRingVisible(false)
		end
	end))
	refreshPet(record)
	refreshRaycastFilter()
end

local function removePlayer(player)
	local record = records[player]
	if not record then
		return
	end
	for _, connection in ipairs(record.connections) do
		connection:Disconnect()
	end
	if record.model then
		record.model:Destroy()
	end
	records[player] = nil
	refreshRaycastFilter()
end

table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
table.insert(connections, Players.PlayerRemoving:Connect(removePlayer))
for _, player in ipairs(Players:GetPlayers()) do
	addPlayer(player)
end

local elapsed = 0
local ringElapsed = 0
table.insert(connections, RunService.RenderStepped:Connect(function(deltaTime)
	if stopped then
		return
	end
	elapsed = elapsed + deltaTime
	for player, record in pairs(records) do
		if record.model then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not humanoid or humanoid.Health <= 0 or not root then
				setPetVisible(record, false)
				record.frame = nil
			else
				local _, yaw = root.CFrame:ToOrientation()
				local bob = math.sin(elapsed * 3 + player.UserId % 9) * 0.17
				local target = CFrame.new(root.Position)
					* CFrame.Angles(0, yaw, 0)
					* CFrame.new(3, -1.2 + bob, 3)
				if not record.frame or (record.frame.Position - target.Position).Magnitude > 50 then
					record.frame = target
				else
					record.frame = record.frame:Lerp(target, 1 - math.exp(-10 * deltaTime))
				end
				record.model:PivotTo(record.frame)
				setPetVisible(record, true)
			end
		end
	end

	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		setRingVisible(false)
		return
	end

	-- Питомцы следуют каждый кадр, а 48 сегментов кольца достаточно обновлять 30 раз/с.
	ringElapsed = ringElapsed + deltaTime
	if ringElapsed < 1 / 30 and ringVisible then
		return
	end
	ringElapsed = 0
	local ground = Workspace:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -40, 0), raycastParams)
	if not ground then
		setRingVisible(false)
		return
	end
	if not localPlayer:GetAttribute("ShowMagnetRange") then setRingVisible(false); return end
	local radius = Config.GetMagnetRadius(getMagnetLevel())
	local center = Vector3.new(root.Position.X, ground.Position.Y + 0.08, root.Position.Z)
	local chord = 2 * radius * math.sin(segmentAngle / 2) + 0.015
	for _, segment in ipairs(ringSegments) do
		if radius ~= ringRadius then
			segment.part.Size = Vector3.new(0.045, 0.03, chord)
		end
		segment.part.CFrame = CFrame.new(center + segment.middle * radius) * segment.rotation
	end
	ringRadius = radius
	setRingVisible(true)
end))

local function cleanup()
	if stopped then
		return
	end
	stopped = true
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	for player in pairs(records) do
		removePlayer(player)
	end
	effectsFolder:Destroy()
end

script.Destroying:Connect(cleanup)

local nearbyCoins={}
local rootWorld=Workspace:WaitForChild("CoinSpeedWorld")
for _,zone in ipairs({rootWorld,rootWorld:WaitForChild("NeonCity")}) do
 for _,coin in ipairs(zone:GetChildren()) do
  if coin:IsA("BasePart") and string.match(coin.Name,"^Coin_%d+$") then table.insert(nearbyCoins,coin) end
 end
end
-- Монеты крутятся и покачиваются только у клиента; сервер считает сбор по исходной позиции.
local coinBase={}
for i,coin in ipairs(nearbyCoins) do coinBase[coin]={cf=coin.CFrame,phase=i*0.7} end
local coinClock=0
local coinConnection=RunService.RenderStepped:Connect(function(dt)
 coinClock=coinClock+dt
 local camera=Workspace.CurrentCamera
 local eye=camera and camera.CFrame.Position
 for coin,base in pairs(coinBase) do
  if coin.Parent and eye and (eye-base.cf.Position).Magnitude<160 then
   local t=coinClock+base.phase
   coin.CFrame=CFrame.new(base.cf.Position+Vector3.new(0,math.sin(t*2)*0.35,0))*CFrame.Angles(0,t*1.8,0)*base.cf.Rotation
  end
 end
end)
script.Destroying:Connect(function() coinConnection:Disconnect() end)
