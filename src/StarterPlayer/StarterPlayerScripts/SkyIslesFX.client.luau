-- Атмосфера Sky Isles: пока камера в облачном мире, свет становится дневным и мягким,
-- парящие островки покачиваются, радуга дышит. Вне мира всё возвращается как было.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local world = workspace:WaitForChild("CoinSpeedWorld")
local sky = world:WaitForChild("SkyIsles", 60)
if not sky then
	return
end
local center = sky:WaitForChild("Ground"):WaitForChild("Deck").Position
-- Облачная подушка под островом плавно качается вверх-вниз.
local cushion = sky.Ground:WaitForChild("Underside", 10)
local cushionBase = cushion and cushion:GetPivot()

local islets = {}
for _, m in ipairs(sky:WaitForChild("Islets"):GetChildren()) do
	table.insert(islets, { model = m, base = m:GetPivot(), phase = math.random() * 6 })
end
-- Звёзды (модели "Star") покачиваются вверх-вниз и медленно крутятся; облака с тегом "SkyCloud" плывут.
local stars = {}
local ripples = {}
local lilies = {}
local pondWater
local function addStar(d)
	if d:IsA("Model") and d.Name == "Lily" then
		table.insert(lilies, { model = d, base = d.WorldPivot, phase = math.random() * 6 })
	elseif d:IsA("BasePart") and d.Name == "Water" and d.Parent and d.Parent.Name == "Pond" then
		pondWater = d
	elseif d:IsA("Texture") and d.Name == "Ripple" then
		table.insert(ripples, d)
	elseif d:IsA("Model") and d.Name == "Star" then
		table.insert(stars, { model = d, base = d:GetPivot(), phase = math.random() * 6, amp = 0.8 + math.random() * 1.4, spin = (math.random() - 0.5) * 1.2 })
	end
end
for _, d in ipairs(sky:GetDescendants()) do
	addStar(d)
end
sky.DescendantAdded:Connect(function(d)
	task.defer(addStar, d) -- части звезды приходят следом за моделью
end)
local clouds = {}
local CollectionService = game:GetService("CollectionService")
-- Атрибут Sway задаёт размах вручную: плотным облачным стенам (водопад) нужен маленький, чтобы не было щелей.
local function addCloud(c)
	if c:IsA("BasePart") and c:IsDescendantOf(sky) then
		table.insert(clouds, { part = c, base = c.CFrame, phase = math.random() * 6, sway = c:GetAttribute("Sway") or (1 + math.random() * 2) })
	end
end
for _, c in ipairs(CollectionService:GetTagged("SkyCloud")) do
	addCloud(c)
end
CollectionService:GetInstanceAddedSignal("SkyCloud"):Connect(addCloud)
-- Контуры (тег SkyTrim) плавно переливаются розовый → сиреневый → небесный.
local trims = CollectionService:GetTagged("SkyTrim")
CollectionService:GetInstanceAddedSignal("SkyTrim"):Connect(function(p)
	table.insert(trims, p)
end)
local bands = {}
for _, d in ipairs(sky:GetChildren()) do
	if d.Name == "RainbowBand" then
		table.insert(bands, { part = d, band = d:GetAttribute("Band") or 1, along = d:GetAttribute("Along") or 0 })
	end
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "SkyIslesAtmosphere"
atmosphere.Density = 0.22
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(215, 185, 240)
atmosphere.Decay = Color3.fromRGB(255, 150, 180)
atmosphere.Glare = 0
atmosphere.Haze = 0.5
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "SkyIslesTint"
tint.TintColor = Color3.fromRGB(255, 232, 248)
tint.Saturation = 0.08
tint.Brightness = 0

-- Детали острова собираем один раз (и дополняем по мере появления): страховке и входу в мир
-- не нужно каждый раз обходить ~5000 объектов.
local skyParts = {}
for _, d in ipairs(sky:GetDescendants()) do
	if d:IsA("BasePart") then
		table.insert(skyParts, d)
	end
end
sky.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") then
		table.insert(skyParts, d)
	end
end)
local function showSkyParts()
	for _, p in ipairs(skyParts) do
		if p.LocalTransparencyModifier > 0 then
			p.LocalTransparencyModifier = 0
		end
	end
end

local saved
local function setActive(on)
	if on then
		-- страховка: на входе гарантируем, что геометрия острова не спрятана клиентом
		showSkyParts()
		saved = { Lighting.ClockTime, Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.ExposureCompensation }
		atmosphere.Parent = Lighting
		tint.Parent = Lighting
		TweenService:Create(Lighting, TweenInfo.new(0.4), {
			ClockTime = 18.2,
			Brightness = 1.6,
			Ambient = Color3.fromRGB(125, 105, 165),
			OutdoorAmbient = Color3.fromRGB(150, 125, 190),
			ExposureCompensation = -0.1,
		}):Play()
	else
		atmosphere.Parent = nil
		tint.Parent = nil
		if saved then
			TweenService:Create(Lighting, TweenInfo.new(0.4), {
				ClockTime = saved[1],
				Brightness = saved[2],
				Ambient = saved[3],
				OutdoorAmbient = saved[4],
				ExposureCompensation = saved[5],
			}):Play()
			saved = nil
		end
	end
end

local active = false
-- Кольцо: тонкий светлый диск растёт и тает.
local nextRipple = 0
local function spawnRipple()
	local radius = pondWater.Size.Y / 2 - 3
	local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * radius
	local top = pondWater.Position + Vector3.new(math.cos(a) * r, pondWater.Size.X / 2 + 0.03, math.sin(a) * r)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.05, 1, 1)
	ring.CFrame = CFrame.new(top) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Color = Color3.fromRGB(240, 252, 255)
	ring.Material = Enum.Material.SmoothPlastic
	ring.Transparency = 0.45
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Parent = workspace
	local grow = TweenService:Create(ring, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.05, 7, 7), Transparency = 1 })
	grow.Completed:Connect(function()
		ring:Destroy()
	end)
	grow:Play()
end
-- Производительность: медленные плавные движения обновляем 30 раз в секунду, цвета — 20,
-- а облака и звёзды дальше CULL студов от камеры не трогаем (смещение там всё равно не видно).
-- Облака двигаем одним пакетом через BulkMoveTo. Так кадр в мире стал примерно вдвое легче.
local MOVE_STEP, COLOR_STEP, CULL = 1 / 30, 1 / 20, 300
local cloudParts, cloudFrames = {}, {}
local t = 0
local guard = 0
local moveAcc, colorAcc = 0, 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local near = camera ~= nil and game:GetService("Players").LocalPlayer:GetAttribute("CurrentWorld") == "Sky Isles" and (camera.CFrame.Position - center).Magnitude < 420
	if near ~= active then
		active = near
		setActive(near)
	end
	if not near then
		return
	end
	t += dt
	guard += dt
	if guard > 8 then
		guard = 0
		showSkyParts()
	end
	-- Круги на воде: время от времени в случайной точке пруда расходится светлое кольцо.
	if pondWater and pondWater.Parent then
		nextRipple -= dt
		if nextRipple <= 0 then
			nextRipple = 0.35 + math.random() * 0.5
			spawnRipple()
		end
	end
	for k, r in ipairs(ripples) do
		r.OffsetStudsU = t * (k % 2 == 0 and 0.7 or -0.5)
		r.OffsetStudsV = t * 0.4
	end

	local camPos = camera.CFrame.Position
	moveAcc += dt
	if moveAcc >= MOVE_STEP then
		moveAcc = 0
		for _, i in ipairs(islets) do
			i.model:PivotTo(i.base + Vector3.new(0, math.sin(t * 0.6 + i.phase) * 2.2, 0))
		end
		for _, s in ipairs(stars) do
			if (s.base.Position - camPos).Magnitude < CULL then
				local a = t + s.phase
				s.model:PivotTo(s.base * CFrame.new(0, math.sin(a * 0.9) * s.amp, 0) * CFrame.Angles(0, a * s.spin, math.sin(a * 0.7) * 0.15))
			end
		end
		if cushion and cushion.Parent then
			cushion:PivotTo(cushionBase + Vector3.new(0, math.sin(t * 0.5) * 2.5, 0))
		end
		-- Кувшинки покачиваются на воде и медленно поворачиваются.
		for _, l in ipairs(lilies) do
			local a = t + l.phase
			l.model:PivotTo(l.base * CFrame.new(0, math.sin(a * 1.6) * 0.08, 0) * CFrame.Angles(math.sin(a) * 0.04, a * 0.15, math.cos(a * 1.3) * 0.04))
		end
		-- Облака — после подушки, как и раньше: если деталь есть в обоих списках, побеждает облако.
		table.clear(cloudParts)
		table.clear(cloudFrames)
		for _, c in ipairs(clouds) do
			if c.part.Parent and (c.base.Position - camPos).Magnitude < CULL then
				local a = t * 0.25 + c.phase
				table.insert(cloudParts, c.part)
				table.insert(cloudFrames, c.base + Vector3.new(math.sin(a) * c.sway, math.sin(a * 1.7) * 0.6, math.cos(a * 0.8) * c.sway))
			end
		end
		if #cloudParts > 0 then
			workspace:BulkMoveTo(cloudParts, cloudFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end

	colorAcc += dt
	if colorAcc >= COLOR_STEP then
		colorAcc = 0
		local trimHue = 0.72 + 0.12 * math.sin(t * 0.4)
		for k, p in ipairs(trims) do
			p.Color = Color3.fromHSV((trimHue + 0.04 * math.sin(t + k)) % 1, 0.32, 1)
		end
		-- Радуги: цвета бегут волной вдоль дуги, полосы сохраняют порядок, яркость пульсирует.
		for _, b in ipairs(bands) do
			local hue = ((b.band - 1) / 7 * 0.8 - t * 0.18 + b.along * 0.6) % 1
			local wave = math.sin(t * 3 - b.along * 12)
			b.part.Color = Color3.fromHSV(hue, 0.65 - 0.15 * wave, 1)
			b.part.Transparency = 0.2 - 0.12 * wave
		end
	end
end)
