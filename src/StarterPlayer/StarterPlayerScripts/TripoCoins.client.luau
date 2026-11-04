-- 3D-монеты Frozen Peaks из Tripo (ReplicatedStorage.TripoProps/CoinIce, CoinCrystal, CoinAurora).
-- Серверная монета остаётся (сбор, видимость), а на клиенте поверх неё крутится модель Tripo;
-- сам диск прячем через LocalTransparencyModifier. Модель видна, только пока монета доступна.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local props = ReplicatedStorage:WaitForChild("TripoProps", 30)
local world = workspace:WaitForChild("CoinSpeedWorld")
local frozen = world:WaitForChild("FrozenPeaks", 60)
if not (props and frozen) then
	return
end

local KIND = { Ice = "CoinIce", Crystal = "CoinCrystal", Aurora = "CoinAurora" }
local coins = {}

local collectFX

-- ===== Анимация сбора ледяной монеты =====
-- Копия модели подпрыгивает с быстрым вращением, летит к игроку и тает; вокруг — вспышка снежинок,
-- ледяное кольцо по земле и всплывающее «+N» (сколько монет реально прибавилось).
local TweenService = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local coinsValue = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local lastCoins = coinsValue.Value
local fxFolder = Instance.new("Folder")
fxFolder.Name = "FrozenCoinFX"
fxFolder.Parent = workspace
local function short(n)
	for _, u in ipairs({ { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then
			return string.format("%.1f%s", n / u[1], u[2])
		end
	end
	return tostring(math.floor(n))
end
collectFX = function(e)
	local cam = workspace.CurrentCamera
	local from = e.model:GetPivot()
	if not cam or (cam.CFrame.Position - from.Position).Magnitude > 140 then
		return
	end
	local ghost = e.model:Clone()
	for _, p in ipairs(ghost:GetDescendants()) do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = 0
		end
	end
	ghost.Parent = fxFolder
	-- вспышка снежинок
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = from.Position
	anchor.Parent = fxFolder
	local flakes = Instance.new("ParticleEmitter")
	flakes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	flakes.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255), Color3.fromRGB(255, 255, 255))
	flakes.LightEmission = 0.8
	flakes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	flakes.Lifetime = NumberRange.new(0.6, 1.1)
	flakes.Speed = NumberRange.new(8, 14)
	flakes.SpreadAngle = Vector2.new(180, 180)
	flakes.Drag = 3
	flakes.RotSpeed = NumberRange.new(-200, 200)
	flakes.Rate = 0
	flakes.Parent = anchor
	flakes:Emit(28)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 225, 255)
	light.Range = 12
	light.Brightness = 4
	light.Parent = anchor
	TweenService:Create(light, TweenInfo.new(0.6), { Brightness = 0 }):Play()
	-- ледяное кольцо по земле
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(150, 220, 255)
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
	ring.Size = Vector3.new(0.1, 1, 1)
	ring.Transparency = 0.2
	ring.CFrame = CFrame.new(from.Position - Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = fxFolder
	TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.1, 9, 9), Transparency = 1 }):Play()
	-- «+N»
	task.delay(0.12, function()
		local delta = coinsValue.Value - lastCoins
		lastCoins = coinsValue.Value
		if delta <= 0 then
			return
		end
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(140, 40)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.Adornee = anchor
		gui.StudsOffset = Vector3.new(0, 1.5, 0)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = "+" .. short(delta)
		t.TextColor3 = Color3.fromRGB(220, 245, 255)
		local st = Instance.new("UIStroke")
		st.Thickness = 2.5
		st.Color = Color3.fromRGB(30, 80, 160)
		st.Parent = t
		t.Parent = gui
		gui.Parent = anchor
		TweenService:Create(gui, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 5, 0) }):Play()
		TweenService:Create(t, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
		TweenService:Create(st, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
	end)
	-- прыжок с вращением и полёт к игроку
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local scale = ghost:GetScale()
	local t0 = os.clock()
	local up = from.Position + Vector3.new(0, 3.5, 0)
	while true do
		local k = (os.clock() - t0) / 0.55
		if k >= 1 then
			break
		end
		local pos
		if k < 0.45 then
			pos = from.Position:Lerp(up, math.sin(k / 0.45 * math.pi / 2))
		else
			local target = root and root.Position + Vector3.new(0, 1.5, 0) or up
			pos = up:Lerp(target, ((k - 0.45) / 0.55) ^ 2)
		end
		ghost:PivotTo(CFrame.new(pos) * CFrame.Angles(0, k * math.pi * 6, 0))
		ghost:ScaleTo(scale * math.max(0.05, 1 - math.max(0, k - 0.45) * 1.6))
		task.wait()
	end
	ghost:Destroy()
	task.delay(1, function()
		anchor:Destroy()
		ring:Destroy()
	end)
end
coinsValue.Changed:Connect(function(v)
	-- держим «последнее» значение свежим, если монеты пришли не от ледяных монет
	task.delay(0.5, function()
		lastCoins = coinsValue.Value
	end)
end)

local function attach(part: BasePart)
	local template = props:FindFirstChild(KIND[part:GetAttribute("Kind") or ""] or "")
	if not template then
		return
	end
	local m = template:Clone()
	local _, ext = m:GetBoundingBox()
	local d = math.max(part.Size.Y, part.Size.Z) * 1.15
	m:ScaleTo(m:GetScale() * d / math.max(ext.X, ext.Y, ext.Z, 0.01))
	local bb = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bb.Position)
	local parts = {}
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
			table.insert(parts, p)
		end
	end
	m.Parent = part
	part.LocalTransparencyModifier = 1
	local entry = { part = part, model = m, parts = parts, phase = math.random() * 6 }
	local function sync()
		local visible = part.Transparency < 1
		for _, p in ipairs(parts) do
			p.LocalTransparencyModifier = visible and 0 or 1
		end
	end
	part:GetPropertyChangedSignal("Transparency"):Connect(sync)
	part:GetAttributeChangedSignal("Available"):Connect(function()
		if part:GetAttribute("Available") == false then
			task.spawn(collectFX, entry)
		end
	end)
	sync()
	table.insert(coins, entry)
end

task.defer(function()
	task.wait(2)
	for _, c in ipairs(frozen:GetChildren()) do
		if c:IsA("BasePart") and string.match(c.Name, "^Coin_%d+$") then
			attach(c)
		end
	end
end)

local t = 0

-- Вращение и лёгкое парение — только в Frozen Peaks и 20 раз в секунду.
local acc = 0
local player = game:GetService("Players").LocalPlayer
RunService.Heartbeat:Connect(function(dt)
	t += dt
	acc += dt
	if acc < 0.05 or player:GetAttribute("CurrentWorld") ~= "Frozen Peaks" then
		return
	end
	acc = 0
	for _, e in ipairs(coins) do
		if e.part.Transparency < 1 then
			local p = e.part.Position
			e.model:PivotTo(CFrame.new(p + Vector3.new(0, math.sin(t * 2 + e.phase) * 0.3, 0)) * CFrame.Angles(0, t * 1.8 + e.phase, 0))
		end
	end
end)
