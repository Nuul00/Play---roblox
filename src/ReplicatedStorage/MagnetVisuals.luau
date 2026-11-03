-- 20 видов подковообразных магнитов из деталей Roblox (для руки и витрины).
-- Корень — "Handle" (рукоять внизу). Подкова над ней, открыта вверх; лицевая сторона — -Z,
-- украшения дублируются на +Z, чтобы магнит выглядел одинаково спереди и сзади.
local ShopConfig = require(script.Parent:WaitForChild("ShopConfig"))

local MagnetVisuals = {}

local M = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local R = 0.9 -- радиус дуги
local W = 0.6 -- толщина подковы
local CY = 1.6 -- центр дуги над рукоятью
local ARM = 1.0 -- длина прямых плеч
local TIP_Y = CY + ARM + 0.25

local CUSTOM_HEIGHT = 3.4 -- высота процедурного магнита от низа рукояти до наконечников

-- Своя модель (CustomMagnets/Magnet<tier>, например из 3D-генератора) важнее процедурной.
-- Масштабируем до высоты обычного магнита, ставим низом на рукоять и привариваем к невидимой Handle,
-- чтобы Tool, хват и витрина магазина работали так же, как с магнитом из деталей.
local function fromTemplate(template: Instance, name: string): Model?
	if not template:FindFirstChildWhichIsA("BasePart", true) then
		return nil
	end
	local source = template:Clone()
	local model = Instance.new("Model")
	model.Name = name
	if source:IsA("Model") then
		for _, child in ipairs(source:GetChildren()) do
			child.Parent = model
		end
		source:Destroy()
	else
		source.Parent = model
	end
	local cf, size = model:GetBoundingBox()
	model:ScaleTo(CUSTOM_HEIGHT / math.max(size.Y, 0.1))
	cf, size = model:GetBoundingBox()
	-- Низ модели совпадает с низом рукояти (y = -0.5), центр — над рукоятью.
	model:TranslateBy(Vector3.new(-cf.Position.X, -0.5 + size.Y / 2 - cf.Position.Y, -cf.Position.Z))
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 1.0, 0.45)
	handle.Transparency = 1
	handle.CFrame = CFrame.identity
	handle.Parent = model
	local parts = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.Massless = true
			p.CastShadow = false
			if p ~= handle then
				table.insert(parts, p)
			end
		elseif p:IsA("JointInstance") or p:IsA("WeldConstraint") then
			p:Destroy()
		end
	end
	-- Самая крупная деталь — «сердце» магнита: остальные приварены к ней, а она к рукояти через Weld,
	-- чей C0 клиент (GlowFX) покачивает, чтобы магнит парил над рукоятью.
	table.sort(parts, function(a, b)
		return a.Size.Magnitude > b.Size.Magnitude
	end)
	local core = parts[1]
	if core then
		for i = 2, #parts do
			local w = Instance.new("WeldConstraint")
			w.Part0 = core
			w.Part1 = parts[i]
			w.Parent = parts[i]
		end
		local float = Instance.new("Weld")
		float.Name = "FloatWeld"
		float.Part0 = handle
		float.Part1 = core
		float.C0 = core.CFrame -- рукоять стоит в начале координат
		float.Parent = core
		core.Name = "Core"
	end
	model.PrimaryPart = handle
	return model
end

-- Сияние: свет, искры и мягкий ореол вокруг магнита. Чем дороже магнит, тем гуще искры.
local function addGlow(model: Model, def)
	local core = model:FindFirstChild("Core") or model:FindFirstChild("Handle")
	if not core then
		return
	end
	local look = def.Look or {}
	local color: Color3 = look.Light or look.Tip or Color3.fromRGB(255, 220, 120)
	local tier = def.Id
	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = color
	light.Range = 7 + tier * 0.15
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = core
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparkles"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 3 + tier * 0.4
	sparks.Lifetime = NumberRange.new(0.6, 1.2)
	sparks.Speed = NumberRange.new(0.3, 1)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, 0.8, 0)
	sparks.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	sparks.Parent = core
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "Aura"
	aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	aura.Rate = 2
	aura.Lifetime = NumberRange.new(1, 1.4)
	aura.Speed = NumberRange.new(0)
	aura.LockedToPart = true
	aura.Rotation = NumberRange.new(0, 360)
	aura.RotSpeed = NumberRange.new(-40, 40)
	aura.Color = ColorSequence.new(color)
	aura.LightEmission = 1
	aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(0.5, 2.2), NumberSequenceKeypoint.new(1, 1.4) })
	aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.75), NumberSequenceKeypoint.new(1, 1) })
	aura.Parent = core
	core:SetAttribute("BaseBrightness", light.Brightness)
	core:AddTag("MagnetGlow")
end

function MagnetVisuals.Build(tier: number): Model
	local def = ShopConfig.Magnets[tier] or ShopConfig.Magnets[1]
	local customFolder = script.Parent:FindFirstChild("CustomMagnets")
	local custom = customFolder and customFolder:FindFirstChild("Magnet" .. def.Id)
	if custom then
		local model = fromTemplate(custom, def.Name)
		if model then
			addGlow(model, def)
			return model
		end
	end
	local look = def.Look or {}
	local model = Instance.new("Model")
	model.Name = def.Name

	local function piece(name, size, cf, color, material, shape, transparency)
		local p = Instance.new(shape == "wedge" and "WedgePart" or "Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or M.SmoothPlastic
		if shape == "ball" then
			p.Shape = Enum.PartType.Ball
		elseif shape == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
		p.Transparency = transparency or 0
		p.CFrame = cf
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local function both(fn)
		fn(-1)
		fn(1)
	end

	-- Рукоять.
	local handle = piece("Handle", Vector3.new(0.45, 1.0, 0.45), CFrame.identity, rgb(40, 36, 36), M.SmoothPlastic)
	piece("Grip", Vector3.new(0.5, 0.15, 0.5), CFrame.new(0, 0.55, 0), look.Trim or rgb(70, 70, 75), M.Metal)

	-- Дуга и плечи. Цвет сегмента может зависеть от номера (радуга и т.п.).
	local bodyColor = look.Body or def.Body
	local bodyMat = look.Material or M.SmoothPlastic
	local n = 9
	local segments = {}
	for i = 0, n - 1 do
		local a = math.pi + (i + 0.5) / n * math.pi
		local pos = Vector3.new(math.cos(a) * R, CY + math.sin(a) * R, 0)
		local color = look.SegmentColor and look.SegmentColor(i / (n - 1)) or bodyColor
		local seg = piece("Arc", Vector3.new(W, R * math.pi / n * 1.25, W), CFrame.new(pos) * CFrame.Angles(0, 0, a), color, bodyMat)
		segments[i + 1] = { part = seg, angle = a, pos = pos }
	end
	for _, side in ipairs({ -1, 1 }) do
		local color = look.SegmentColor and look.SegmentColor(side < 0 and 0 or 1) or bodyColor
		piece("Arm", Vector3.new(W, ARM, W), CFrame.new(side * R, CY + ARM / 2, 0), color, bodyMat)
		-- Наконечник: блок пошире и «скошенная» крышка.
		local tipColor = look.Tip or def.Tip
		piece("Tip", Vector3.new(W + 0.12, 0.42, W + 0.12), CFrame.new(side * R, CY + ARM + 0.2, 0), tipColor, look.TipMaterial or M.Glass)
		piece("TipCap", Vector3.new(W - 0.08, 0.14, W - 0.08), CFrame.new(side * R, CY + ARM + 0.47, 0), tipColor:Lerp(Color3.new(1, 1, 1), 0.35), look.TipMaterial or M.Glass)
	end

	-- ===== Украшения =====
	local function onArc(t, outward, z)
		local a = math.pi + t * math.pi
		return Vector3.new(math.cos(a) * (R + outward), CY + math.sin(a) * (R + outward), z or 0), a
	end
	local front = W / 2 + 0.02

	-- Полоса-вставка по лицевой стороне (вдоль плеч и дуги).
	if look.Stripe then
		both(function(z)
			for i, s in ipairs(segments) do
				piece("Stripe", Vector3.new(W * 0.35, R * math.pi / n * 1.2, 0.06), CFrame.new(s.pos + Vector3.new(0, 0, z * front)) * CFrame.Angles(0, 0, s.angle), look.Stripe, look.StripeMaterial or M.Neon)
			end
			for _, side in ipairs({ -1, 1 }) do
				piece("Stripe", Vector3.new(W * 0.35, ARM, 0.06), CFrame.new(side * R, CY + ARM / 2, z * front), look.Stripe, look.StripeMaterial or M.Neon)
			end
		end)
	end
	-- Металлические ремни и заклёпки.
	if look.Straps then
		for _, t in ipairs({ 0.18, 0.5, 0.82 }) do
			local pos, a = onArc(t, 0)
			piece("Strap", Vector3.new(W + 0.1, 0.16, W + 0.1), CFrame.new(pos) * CFrame.Angles(0, 0, a), look.Straps, M.Metal)
		end
		for _, side in ipairs({ -1, 1 }) do
			piece("Strap", Vector3.new(W + 0.1, 0.16, W + 0.1), CFrame.new(side * R, CY + ARM * 0.6, 0), look.Straps, M.Metal)
			both(function(z)
				piece("Rivet", Vector3.new(0.12, 0.12, 0.12), CFrame.new(side * R, CY + ARM * 0.3, z * front), look.Straps, M.Metal, "ball")
			end)
		end
	end
	-- Камень в центре дуги (ромб).
	if look.Gem then
		both(function(z)
			local pos = onArc(0.5, 0, z * (front + 0.05))
			piece("Gem", Vector3.new(0.42, 0.42, 0.14), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(45)), look.Gem, look.GemMaterial or M.Glass)
		end)
	end
	-- Кристаллы, растущие из дуги.
	if look.Crystals then
		local count = look.CrystalCount or 7
		for k = 1, count do
			local t = 0.1 + (k - 1) / math.max(count - 1, 1) * 0.8
			local pos, a = onArc(t, W / 2 - 0.12)
			local len = 0.5 + (k % 3) * 0.18
			-- Ось Y детали после поворота смотрит наружу от дуги, кристалл «растёт» из корпуса.
			piece("Crystal", Vector3.new(0.24, len, 0.24), CFrame.new(pos) * CFrame.Angles(0, 0, a - math.pi / 2 + (k % 2 == 0 and 0.3 or -0.3)) * CFrame.new(0, len / 2, 0) * CFrame.Angles(0, math.rad(45), 0), look.Crystals, M.Glass, nil, 0.05)
		end
	end
	-- Трещины лавы: светящиеся вставки по сегментам.
	if look.Lava then
		both(function(z)
			for i, s in ipairs(segments) do
				if i % 2 == 1 then
					piece("Lava", Vector3.new(0.08, 0.35, 0.05), CFrame.new(s.pos + Vector3.new(0, 0, z * front)) * CFrame.Angles(0, 0, s.angle + 0.7), look.Lava, M.Neon)
				end
			end
			for _, side in ipairs({ -1, 1 }) do
				piece("Lava", Vector3.new(0.08, 0.5, 0.05), CFrame.new(side * R + 0.1, CY + 0.5, z * front) * CFrame.Angles(0, 0, 0.5), look.Lava, M.Neon)
			end
		end)
	end
	-- Крылья из перьев по бокам дуги.
	if look.Wings then
		for _, side in ipairs({ -1, 1 }) do
			for k = 1, 4 do
				local base = Vector3.new(side * (R + 0.2), CY - 0.2 - k * 0.08, 0)
				piece("Feather", Vector3.new(0.12, 0.25, 0.45 + k * 0.15), CFrame.new(base + Vector3.new(side * k * 0.18, -k * 0.12, 0)) * CFrame.Angles(0, side * math.pi / 2, math.rad(side * (20 + k * 12))), look.Wings, M.SmoothPlastic, "wedge")
			end
		end
	end
	-- Корона внизу дуги.
	if look.Crown then
		local bottom = Vector3.new(0, CY - R - 0.05, 0)
		piece("CrownBand", Vector3.new(0.8, 0.2, W + 0.15), CFrame.new(bottom), look.Crown, M.Foil)
		for k = -1, 1 do
			piece("CrownSpike", Vector3.new(0.14, 0.32, 0.14), CFrame.new(bottom + Vector3.new(k * 0.28, -0.24, 0)) * CFrame.Angles(0, 0, math.rad(45)), look.Crown, M.Foil)
		end
		both(function(z)
			piece("CrownGem", Vector3.new(0.14, 0.14, 0.06), CFrame.new(bottom + Vector3.new(0, 0, z * (W / 2 + 0.1))) * CFrame.Angles(0, 0, math.rad(45)), look.CrownGem or rgb(230, 40, 60), M.Glass)
		end)
	end
	-- Звезда-эмблема.
	if look.Star then
		both(function(z)
			local pos = onArc(0.5, 0, z * (front + 0.06))
			for k = 0, 1 do
				piece("Star", Vector3.new(0.14, 0.62, 0.06), CFrame.new(pos) * CFrame.Angles(0, 0, k * math.pi / 2), look.Star, M.Foil)
				piece("Star", Vector3.new(0.1, 0.4, 0.06), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 4 + k * math.pi / 2), look.Star, M.Foil)
			end
		end)
	end
	-- Россыпь звёздочек по корпусу.
	if look.Sparkles then
		both(function(z)
			for i, s in ipairs(segments) do
				if i % 2 == 0 then
					piece("Sparkle", Vector3.new(0.1, 0.1, 0.05), CFrame.new(s.pos + Vector3.new(0.05, 0.05, z * front)) * CFrame.Angles(0, 0, math.rad(45)), look.Sparkles, M.Neon)
				end
			end
			for _, side in ipairs({ -1, 1 }) do
				piece("Sparkle", Vector3.new(0.1, 0.1, 0.05), CFrame.new(side * R, CY + 0.7, z * front) * CFrame.Angles(0, 0, math.rad(45)), look.Sparkles, M.Neon)
			end
		end)
	end
	-- Полумесяц.
	if look.Moon then
		both(function(z)
			local pos = onArc(0.62, 0, z * (front + 0.05))
			piece("Moon", Vector3.new(0.06, 0.4, 0.4), CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0), look.Moon, M.Foil, "cyl")
			piece("MoonCut", Vector3.new(0.07, 0.34, 0.34), CFrame.new(pos + Vector3.new(0.12, 0.08, z * 0.01)) * CFrame.Angles(0, math.pi / 2, 0), bodyColor, bodyMat, "cyl")
		end)
	end
	-- Светящийся шар в центре дуги.
	if look.Orb then
		local pos = onArc(0.5, 0)
		piece("Orb", Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), look.Orb, M.Neon, "ball")
		piece("OrbRing", Vector3.new(0.08, 0.66, 0.66), CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0), look.Trim or rgb(200, 200, 210), M.Metal, "cyl")
	end
	-- Молнии.
	if look.Lightning then
		for _, side in ipairs({ -1, 1 }) do
			local p = Vector3.new(side * (R + 0.45), CY + ARM, 0)
			for k = 1, 4 do
				local q = p + Vector3.new(side * (k % 2 == 0 and 0.18 or -0.18), -0.35, (k % 2 == 0) and 0.1 or -0.1)
				piece("Bolt", Vector3.new(0.07, (q - p).Magnitude, 0.07), CFrame.lookAt((p + q) / 2, q) * CFrame.Angles(math.pi / 2, 0, 0), look.Lightning, M.Neon)
				p = q
			end
		end
		both(function(z)
			local pos = onArc(0.5, 0, z * (front + 0.05))
			piece("BoltIcon", Vector3.new(0.12, 0.45, 0.06), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(25)), rgb(255, 230, 80), M.Neon)
		end)
	end
	-- Кольцо планеты вокруг дуги.
	if look.Ring then
		local center = Vector3.new(0, CY - R * 0.55, 0)
		for k = 0, 17 do
			local a = k / 18 * math.pi * 2
			local p = center + Vector3.new(math.cos(a) * 1.45, math.sin(a) * 0.3, math.sin(a) * 0.7)
			piece("RingBit", Vector3.new(0.5, 0.1, 0.14), CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))) * CFrame.Angles(0, math.pi / 2, 0), look.Ring, M.Neon)
		end
	end
	-- Цветы.
	if look.Flowers then
		for k, t in ipairs(look.FlowerSpots or { 0.15, 0.4, 0.6, 0.85 }) do
			both(function(z)
				local pos = onArc(t, 0.05, z * (front + 0.04))
				for petal = 0, 4 do
					local a = petal / 5 * math.pi * 2
					piece("Petal", Vector3.new(0.06, 0.17, 0.17), CFrame.new(pos + Vector3.new(math.cos(a) * 0.12, math.sin(a) * 0.12, 0)) * CFrame.Angles(0, math.pi / 2, 0), look.Flowers, M.SmoothPlastic, "cyl")
				end
				piece("FlowerCore", Vector3.new(0.07, 0.1, 0.1), CFrame.new(pos + Vector3.new(0, 0, z * 0.02)) * CFrame.Angles(0, math.pi / 2, 0), rgb(255, 220, 90), M.SmoothPlastic, "cyl")
			end)
		end
	end
	-- Лианы с листьями.
	if look.Vines then
		both(function(z)
			for i, s in ipairs(segments) do
				piece("Vine", Vector3.new(0.07, 0.42, 0.05), CFrame.new(s.pos + Vector3.new(0, 0, z * front)) * CFrame.Angles(0, 0, s.angle + (i % 2 == 0 and 0.6 or -0.6)), look.Vines, M.SmoothPlastic)
				if i % 2 == 1 then
					piece("Leaf", Vector3.new(0.2, 0.12, 0.05), CFrame.new(s.pos + Vector3.new(0.12, 0.1, z * (front + 0.02))) * CFrame.Angles(0, 0, s.angle + 0.8), rgb(90, 190, 80), M.SmoothPlastic)
				end
			end
		end)
	end
	-- Солнце-эмблема.
	if look.Sun then
		both(function(z)
			local pos = onArc(0.5, 0, z * (front + 0.06))
			piece("Sun", Vector3.new(0.06, 0.34, 0.34), CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0), look.Sun, M.Foil, "cyl")
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				piece("SunRay", Vector3.new(0.07, 0.18, 0.05), CFrame.new(pos + Vector3.new(math.cos(a) * 0.27, math.sin(a) * 0.27, 0)) * CFrame.Angles(0, 0, a - math.pi / 2), look.Sun, M.Foil)
			end
		end)
	end
	-- Спираль-воронка.
	if look.Swirl then
		both(function(z)
			local c = onArc(0.5, 0, z * (front + 0.04))
			for k = 0, 13 do
				local a = k * 0.75
				local r = 0.05 + k * 0.022
				piece("Swirl", Vector3.new(0.11, 0.11, 0.11), CFrame.new(c + Vector3.new(math.cos(a) * r, math.sin(a) * r, 0)), look.Swirl, M.Neon, "ball")
			end
		end)
	end
	-- ===== Облачные украшения (Sky Isles) =====
	-- Пушистые облачка вдоль дуги.
	if look.Puffs then
		for k = 0, 8 do
			local t = 0.06 + k / 8 * 0.88
			local pos = onArc(t, W / 2 - 0.05)
			local sz = 0.42 + (k % 3) * 0.1
			piece("Puff", Vector3.new(sz, sz, sz), CFrame.new(pos), k % 2 == 0 and look.Puffs or look.Puffs:Lerp(Color3.new(1, 1, 1), 0.55), M.SmoothPlastic, "ball")
		end
		for _, side in ipairs({ -1, 1 }) do
			for k = 1, 2 do
				piece("Puff", Vector3.new(0.4, 0.4, 0.4), CFrame.new(side * R, CY + 0.2 + k * 0.38, 0), look.Puffs:Lerp(Color3.new(1, 1, 1), k * 0.25), M.SmoothPlastic, "ball")
			end
		end
	end
	-- Бантик у рукояти.
	if look.Bow then
		piece("BowL", Vector3.new(0.34, 0.26, 0.2), CFrame.new(-0.22, 0.62, -0.1) * CFrame.Angles(0, 0, math.rad(20)), look.Bow, M.SmoothPlastic, "ball")
		piece("BowR", Vector3.new(0.34, 0.26, 0.2), CFrame.new(0.22, 0.62, -0.1) * CFrame.Angles(0, 0, math.rad(-20)), look.Bow, M.SmoothPlastic, "ball")
		piece("BowKnot", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.62, -0.12), look.Bow:Lerp(Color3.new(1, 1, 1), 0.3), M.SmoothPlastic, "ball")
	end
	-- Мыльные пузыри.
	if look.Bubbles then
		local spots = { { -0.95, 2.9, 0.1, 0.34 }, { 0.9, 3.1, -0.1, 0.28 }, { -1.25, 2.3, 0.2, 0.22 }, { 1.2, 2.2, 0.1, 0.3 }, { 0.2, 3.35, 0.2, 0.2 }, { -0.4, 0.35, 0.3, 0.2 } }
		for _, b in ipairs(spots) do
			piece("Bubble", Vector3.new(b[4], b[4], b[4]), CFrame.new(b[1], b[2], b[3]), look.Bubbles, M.Glass, "ball", 0.35)
		end
	end
	-- Нимб над подковой.
	if look.Halo then
		local center = Vector3.new(0, CY + ARM + 0.95, 0)
		for k = 0, 15 do
			local a = k / 16 * math.pi * 2
			local p = center + Vector3.new(math.cos(a) * 0.6, math.sin(a) * 0.14, math.sin(a) * 0.35)
			piece("HaloBit", Vector3.new(0.26, 0.09, 0.1), CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a) * 0.5)) * CFrame.Angles(0, math.pi / 2, 0), look.Halo, M.Neon)
		end
	end
	-- Сердечко в центре дуги.
	if look.Heart then
		both(function(z)
			local c = onArc(0.5, 0, z * (front + 0.06))
			piece("HeartL", Vector3.new(0.24, 0.24, 0.1), CFrame.new(c + Vector3.new(-0.09, 0.07, 0)), look.Heart, M.Neon, "ball")
			piece("HeartR", Vector3.new(0.24, 0.24, 0.1), CFrame.new(c + Vector3.new(0.09, 0.07, 0)), look.Heart, M.Neon, "ball")
			piece("HeartB", Vector3.new(0.22, 0.22, 0.1), CFrame.new(c + Vector3.new(0, -0.05, 0)) * CFrame.Angles(0, 0, math.rad(45)), look.Heart, M.Neon)
		end)
	end
	-- Вишенка на конце.
	if look.Cherry then
		piece("Cherry", Vector3.new(0.34, 0.34, 0.34), CFrame.new(-R, TIP_Y + 0.4, 0), look.Cherry, M.SmoothPlastic, "ball")
		piece("CherryStem", Vector3.new(0.05, 0.3, 0.05), CFrame.new(-R + 0.05, TIP_Y + 0.7, 0) * CFrame.Angles(0, 0, math.rad(-20)), rgb(70, 140, 60), M.SmoothPlastic)
	end
	-- Леденцы на концах плеч.
	if look.Lollipops then
		for i, side in ipairs({ -1, 1 }) do
			piece("PopStick", Vector3.new(0.07, 0.5, 0.07), CFrame.new(side * R, TIP_Y + 0.3, 0), rgb(255, 250, 245), M.SmoothPlastic)
			piece("PopHead", Vector3.new(0.5, 0.5, 0.5), CFrame.new(side * R, TIP_Y + 0.72, 0), i == 1 and look.Lollipops or look.Lollipops:Lerp(Color3.new(1, 1, 1), 0.5), M.SmoothPlastic, "ball")
			both(function(z)
				piece("PopSwirl", Vector3.new(0.34, 0.07, 0.07), CFrame.new(side * R, TIP_Y + 0.72, z * 0.22) * CFrame.Angles(0, 0, math.rad(side * 30)), Color3.new(1, 1, 1), M.SmoothPlastic)
			end)
		end
	end
	-- Свечение для редких.
	if look.Light then
		local light = Instance.new("PointLight")
		light.Color = look.Light
		light.Range = 8
		light.Brightness = 1.4
		light.Parent = handle
	end

	for _, p in ipairs(model:GetChildren()) do
		if p ~= handle and p:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
		end
	end
	model.PrimaryPart = handle
	addGlow(model, def)
	return model
end

return MagnetVisuals
