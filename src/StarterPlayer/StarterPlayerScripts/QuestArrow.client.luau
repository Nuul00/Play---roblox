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
-- «FIND AN EGG» из пустого инвентаря: на 25 с стрелка ведёт к ближайшему яйцу своего мира
local standList = nil -- все подставки яиц (ищем один раз)
local function nearestEgg(): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	if not standList then
		standList = {}
		for _, d in ipairs(world:GetDescendants()) do
			if d:IsA("Model") and d.Name:match("^EggStand%d+$") then
				table.insert(standList, d)
			end
		end
	end
	local best, bd = nil, math.huge
	for _, d in ipairs(standList) do
		if d.Parent then
			local pos = posOf(d:FindFirstChild("Interact") or d)
			local dist = pos and (pos - root.Position).Magnitude or math.huge
			if dist < bd and dist < FAR then
				best, bd = pos, dist
			end
		end
	end
	return best
end
local function target(): Vector3?
	if (player:GetAttribute("GuideEggUntil") or 0) > os.clock() then
		local e = nearestEgg()
		if e then
			return e
		end
	end
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
-- бегущие шевроны: видно и направление, и что подсказка «живая»
beam.Texture = "rbxassetid://119363361632569"
beam.TextureMode = Enum.TextureMode.Static
beam.TextureLength = 2
beam.TextureSpeed = 1.6
beam.Width0, beam.Width1 = 1.6, 1.6
beam.LightEmission = 0.8
beam.Brightness = 2
beam.Color = ColorSequence.new(Color3.fromRGB(255, 225, 80), Color3.fromRGB(255, 160, 60))
beam.Segments = 12
beam.CurveSize0, beam.CurveSize1 = 0, 0
beam.Parent = holder
-- кольцо на земле у цели
local ring = Instance.new("Part")
ring.Name = "QuestRing"
ring.Shape = Enum.PartType.Cylinder
ring.Anchored = true
ring.CanCollide = false
ring.CanQuery = false
ring.CanTouch = false
ring.Material = Enum.Material.Neon
ring.Color = Color3.fromRGB(255, 215, 70)
ring.Size = Vector3.new(0.2, 8, 8)
ring.Parent = holder
local tag = Instance.new("BillboardGui")
tag.Size = UDim2.fromOffset(96, 118)
tag.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
tag.AlwaysOnTop = true
tag.LightInfluence = 0
tag.Adornee = holder
-- значок: золотой круг с «!» и стрелкой, под ним расстояние
local badge = Instance.new("Frame")
badge.AnchorPoint = Vector2.new(0.5, 0)
badge.Position = UDim2.new(0.5, 0, 0, 0)
badge.Size = UDim2.fromOffset(62, 62)
badge.BackgroundColor3 = Color3.new(1, 1, 1)
badge.Parent = tag
Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
local bg = Instance.new("UIGradient")
bg.Rotation = 90
bg.Color = ColorSequence.new(Color3.fromRGB(255, 235, 120), Color3.fromRGB(245, 150, 40))
bg.Parent = badge
local bs = Instance.new("UIStroke")
bs.Thickness = 4
bs.Color = Color3.fromRGB(30, 16, 60)
bs.Parent = badge
local function txt(parent, s2, pos, size)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = s2
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Parent = parent
	local st = Instance.new("UIStroke")
	st.Thickness = 2.5
	st.Color = Color3.fromRGB(30, 16, 60)
	st.Parent = l
	return l
end
txt(badge, "!", UDim2.fromOffset(6, 4), UDim2.new(1, -12, 1, -8))
local arrow = txt(tag, "▼", UDim2.new(0.5, -16, 0, 60), UDim2.fromOffset(32, 26))
arrow.TextColor3 = Color3.fromRGB(255, 215, 70)
local distLabel = txt(tag, "", UDim2.new(0, 0, 0, 88), UDim2.new(1, 0, 0, 26))
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
	-- Settings → Quest arrow: OFF — подсказку не показываем (Save_QuestArrow, сохраняется)
	if not current or d < NEAR or d > FAR or (player:GetAttribute("UIScreen") or "") ~= "" or player:GetAttribute("Save_QuestArrow") == "off" then
		holder.Parent = nil
		return
	end
	holder.Position = current + Vector3.new(0, 0.5, 0)
	local t = os.clock()
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0.15), NumberSequenceKeypoint.new(0.9, 0.15), NumberSequenceKeypoint.new(1, 0.6) })
	tag.StudsOffsetWorldSpace = Vector3.new(0, 8 + math.abs(math.sin(t * 3)) * 1.4, 0)
	distLabel.Text = math.floor(d) .. "m"
	-- кольцо расходится волной от цели
	local k = (t * 0.8) % 1
	local r = 5 + k * 9
	local ground = current
	ring.Size = Vector3.new(0.15, r, r)
	ring.CFrame = CFrame.new(ground.X, ground.Y - 0.2, ground.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.35 + k * 0.65
	if holder.Parent ~= workspace then
		holder.Parent = workspace
	end
end)
