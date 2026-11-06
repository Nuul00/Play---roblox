-- Подсказка к цели квеста: светящаяся полоса от игрока к месту, где выполняется текущий шаг
-- (яйцо, киоск прокачки, магазин магнитов, машина слияния), и стрелка ▼ над целью.
-- Только если цель в этом же мире; у «соберите/заработайте» места нет — подсказки тоже нет.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Q = require(ReplicatedStorage:WaitForChild("QuestLineConfig"))
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

local WORLD_MODEL = { ["Neon District"] = "NeonCity", ["Sky Isles"] = "SkyIsles", ["Frozen Peaks"] = "FrozenPeaks", ["Magma Volcano"] = "MagmaVolcano", ["Cosmic Galaxy"] = "CosmicGalaxy" }
local VARIANT_TIER = { Gold = 1, Diamond = 2, Rainbow = 3 }
local NEAR = 14 -- ближе — подсказка не нужна
local FAR = 600 -- дальше — цель в другом мире

local function worldRoot(): Instance
	local name = WORLD_MODEL[player:GetAttribute("CurrentWorld") or ""]
	return name and world:FindFirstChild(name) or world
end

local function posOf(x: Instance?): Vector3?
	if not x then
		return nil
	end
	if x:IsA("BasePart") then
		return x.Position
	elseif x:IsA("Model") then
		return x:GetPivot().Position
	end
	return nil
end

local eggCache = {}
local function target(): Vector3?
	if player:GetAttribute(Q.Attr.Ready) == true then
		return nil
	end
	local s = Q.Steps[player:GetAttribute(Q.Attr.Step) or 1]
	local goal = s and s.Goal
	if not goal then
		return nil
	end
	local t = goal.Type
	if t == "eggs" and goal.Egg then
		local stand = eggCache[goal.Egg]
		if not (stand and stand.Parent) then
			stand = world:FindFirstChild("EggStand" .. goal.Egg, true)
			eggCache[goal.Egg] = stand
		end
		return posOf(stand and (stand:FindFirstChild("Interact") or stand))
	elseif t == "speed" or t == "income" or t == "double" or t == "magnet" then
		local shop = worldRoot():FindFirstChild("UpgradeShop")
		return posOf(shop and (shop:FindFirstChild("ShopZone") or shop))
	elseif t == "magnetTier" then
		local shop = worldRoot():FindFirstChild("MagnetShop")
		return posOf(shop and (shop:FindFirstChild("ShopZone") or shop))
	elseif t == "variant" then
		local machines = workspace:FindFirstChild("PetMachines")
		local m = machines and machines:FindFirstChild("PetMachine" .. (VARIANT_TIER[goal.Key] or 1))
		return posOf(m)
	end
	return nil
end

-- полоса: Beam между вложением в персонаже и вложением в точке цели
local holder = Instance.new("Part")
holder.Name = "QuestArrowTarget"
holder.Anchored = true
holder.CanCollide = false
holder.CanQuery = false
holder.CanTouch = false
holder.Transparency = 1
holder.Size = Vector3.new(0.2, 0.2, 0.2)
local endAtt = Instance.new("Attachment")
endAtt.Parent = holder
local beam = Instance.new("Beam")
beam.Attachment1 = endAtt
beam.FaceCamera = true
beam.Width0, beam.Width1 = 0.5, 0.9
beam.LightEmission = 1
beam.Color = ColorSequence.new(Color3.fromRGB(255, 230, 90), Color3.fromRGB(120, 255, 140))
beam.Segments = 12
beam.CurveSize0, beam.CurveSize1 = 0, 0
beam.Parent = holder
local tag = Instance.new("BillboardGui")
tag.Size = UDim2.fromOffset(60, 60)
tag.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
tag.AlwaysOnTop = true
tag.LightInfluence = 0
tag.Adornee = holder
local arrow = Instance.new("TextLabel")
arrow.BackgroundTransparency = 1
arrow.Size = UDim2.fromScale(1, 1)
arrow.Text = "▼"
arrow.TextScaled = true
arrow.Font = Enum.Font.FredokaOne
arrow.TextColor3 = Color3.fromRGB(255, 230, 90)
arrow.TextStrokeTransparency = 0.2
arrow.Parent = tag
tag.Parent = holder

local startAtt: Attachment? = nil
local current: Vector3? = nil
local clock = 0
RunService.Heartbeat:Connect(function(dt)
	clock += dt
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		holder.Parent = nil
		return
	end
	if not (startAtt and startAtt.Parent == root) then
		startAtt = Instance.new("Attachment")
		startAtt.Name = "QuestArrowStart"
		startAtt.Position = Vector3.new(0, -1.5, 0)
		startAtt.Parent = root
		beam.Attachment0 = startAtt
	end
	-- цель пересчитываем 4 раза в секунду
	if clock >= 0.25 then
		clock = 0
		current = target()
	end
	local d = current and (current - root.Position).Magnitude
	if not current or d < NEAR or d > FAR or (player:GetAttribute("UIScreen") or "") ~= "" then
		holder.Parent = nil
		return
	end
	holder.Position = current + Vector3.new(0, 0.5, 0)
	local pulse = 0.35 + 0.25 * math.sin(os.clock() * 4)
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.15, pulse), NumberSequenceKeypoint.new(1, pulse) })
	tag.StudsOffsetWorldSpace = Vector3.new(0, 7 + math.sin(os.clock() * 3) * 0.6, 0)
	if holder.Parent ~= workspace then
		holder.Parent = workspace
	end
end)
