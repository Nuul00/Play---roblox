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

-- Монеты Frozen, Вулкана и Галактики — модели Tripo по виду монеты (атрибут Kind).
local KIND = {
	Ice = "CoinIce", Crystal = "CoinCrystal", Aurora = "CoinAurora",
	Ember = "CoinEmber", Magma = "CoinMagma", Obsidian = "CoinObsidian",
	Stardust = "CoinStardust", Nebula = "CoinNebula", Cosmic = "CoinCosmic",
}
-- цвета вспышки при подборе
local FX = {
	["Frozen Peaks"] = { Color3.fromRGB(200, 240, 255), Color3.fromRGB(150, 220, 255), Color3.fromRGB(30, 80, 160) },
	["Magma Volcano"] = { Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 110, 40), Color3.fromRGB(120, 30, 10) },
	["Cosmic Galaxy"] = { Color3.fromRGB(220, 200, 255), Color3.fromRGB(170, 120, 255), Color3.fromRGB(40, 20, 110) },
}
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
local fxLive = 0
collectFX = function(e)
	local from = e.model:GetPivot()
	-- только свои сборы рядом с собой и не больше 6 одновременно (Vacuum собирает десятки)
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not me or (me.Position - from.Position).Magnitude > 45 or fxLive >= 6 then
		return
	end
	fxLive += 1
	task.delay(0.8, function()
		fxLive -= 1
	end)
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
	local fxc = FX[e.world] or FX["Frozen Peaks"]
	flakes.Color = ColorSequence.new(fxc[1], Color3.fromRGB(255, 255, 255))
	flakes.LightEmission = 0.8
	flakes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	flakes.Lifetime = NumberRange.new(0.6, 1.1)
	flakes.Speed = NumberRange.new(8, 14)
	flakes.SpreadAngle = Vector2.new(180, 180)
	flakes.Drag = 3
	flakes.RotSpeed = NumberRange.new(-200, 200)
	flakes.Rate = 0
	flakes.Parent = anchor
	flakes:Emit(18)
	-- ледяное кольцо по земле
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = fxc[2]
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
		t.TextColor3 = fxc[1]
		local st = Instance.new("UIStroke")
		st.Thickness = 2.5
		st.Color = fxc[3]
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
		-- уменьшаем только на подлёте и не каждый кадр: ScaleTo пересчитывает всю модель
		if k > 0.45 and math.floor(k * 20) % 2 == 0 then
			ghost:ScaleTo(scale * math.max(0.05, 1 - (k - 0.45) * 1.6))
		end
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

local function attach(part: BasePart, worldName: string)
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
	-- значки старой плоской монеты (SurfaceGui) — прячем вместе с ней
	local guis = {}
	for _, d in ipairs(part:GetChildren()) do
		if d:IsA("LayerCollector") then
			table.insert(guis, d)
		end
	end
	local entry = { part = part, model = m, parts = parts, guis = guis, phase = math.random() * 6, world = worldName }
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
	for holder, worldName in pairs({ FrozenPeaks = "Frozen Peaks", MagmaVolcano = "Magma Volcano", CosmicGalaxy = "Cosmic Galaxy" }) do
		local zone = world:WaitForChild(holder, 30)
		if zone then
			for _, c in ipairs(zone:GetChildren()) do
				if c:IsA("BasePart") and string.match(c.Name, "^Coin_%d+$") then
					attach(c, worldName)
				end
			end
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
	if acc < 0.05 then
		return
	end
	acc = 0
	local current = player:GetAttribute("CurrentWorld")
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position
	for _, e in ipairs(coins) do
		if e.world == current then
			-- Скрипты миров при входе «проявляют» все детали (LocalTransparencyModifier = 0), а сервер
			-- включает значки монеты при её появлении — поэтому старую плоскую монету прячем постоянно.
			if e.part.LocalTransparencyModifier ~= 1 then
				e.part.LocalTransparencyModifier = 1
			end
			for _, g in ipairs(e.guis) do
				if g.Enabled then
					g.Enabled = false
				end
			end
		end
		if e.world == current and e.part.Transparency < 1 and camPos and (e.part.Position - camPos).Magnitude < 110 then
			local p = e.part.Position
			e.model:PivotTo(CFrame.new(p + Vector3.new(0, math.sin(t * 2 + e.phase) * 0.3, 0)) * CFrame.Angles(0, t * 1.8 + e.phase, 0))
		end
	end
end)
