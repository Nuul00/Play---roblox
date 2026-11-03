-- Третий мир: Sky Isles. Всё строится кодом при старте сервера (модель workspace.CoinSpeedWorld.SkyIsles):
-- облачная площадка, магазины прокачек и магнитов, два яйца, монеты, радуги, парящие островки.
-- Механики (монеты, магазины, яйца, телепорт) подключает GameServer по именам деталей, как у остальных миров.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoinTypes = require(ReplicatedStorage:WaitForChild("CoinTypes"))

local Sky = {}
Sky.Center = Vector3.new(1100, 300, 0)
local C = Sky.Center
local M = Enum.Material

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local function L(x, y, z)
	return C + Vector3.new(x, y, z)
end

local function part(parent, name, size, at, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = material or M.SmoothPlastic
	p.Color = color
	p.CFrame = typeof(at) == "CFrame" and at or CFrame.new(at)
	if props then
		for k, v in pairs(props) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end
local function ball(parent, name, diameter, at, color, collide)
	return part(parent, name, Vector3.new(diameter, diameter, diameter), at, color, M.SmoothPlastic, { Shape = Enum.PartType.Ball, CanCollide = collide == true })
end

-- Свои 3D-модели из ReplicatedStorage: CustomClouds/* — облака (случайно), CustomCoins/* — монеты (по кругу),
-- CustomShops/UpgradeShop и CustomShops/MagnetShop — магазины.
local function meshFrom(template)
	return template and (template:IsA("MeshPart") and template or template:FindFirstChildWhichIsA("MeshPart", true))
end
local function meshList(folderName)
	local list = {}
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	if folder then
		local children = folder:GetChildren()
		table.sort(children, function(a, b)
			return a.Name < b.Name
		end)
		for _, t in ipairs(children) do
			local mesh = meshFrom(t)
			if mesh then
				table.insert(list, mesh)
			end
		end
	end
	return list
end
local cloudMeshes = meshList("CustomClouds")
local coinMeshes = meshList("CustomCoins")
local function decorate(p)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

-- Облако: 3D-модель со своей текстурой, если она есть, иначе шар. Где облако держит игроков (бортик),
-- остаётся невидимый шар. drift = true — облако плавно плывёт (SkyIslesFX, тег "SkyCloud");
-- облака внутри парящих островков не помечаем: их двигает весь островок целиком.
local cloudRng = Random.new(11)
local function cloud(parent, name, diameter, at, color, collide, hidden, drift)
	if #cloudMeshes == 0 then
		return ball(parent, name, diameter, at, color, collide)
	end
	if collide then
		ball(parent, name .. "Collider", diameter, at, color, true).Transparency = 1
	end
	if hidden then
		return nil
	end
	local template = cloudMeshes[cloudRng:NextInteger(1, #cloudMeshes)]
	local c = decorate(template:Clone())
	c.Name = name
	c.Size *= diameter * 1.25 / math.max(c.Size.X, c.Size.Z)
	c.CFrame = CFrame.new(at) * CFrame.Angles(0, cloudRng:NextNumber(0, math.pi * 2), 0) * template.CFrame.Rotation
	c.Parent = parent
	if drift then
		c:AddTag("SkyCloud")
	end
	return c
end

-- Плоский диск (ось цилиндра вертикальна).
local function disc(parent, name, diameter, thickness, at, color, material, props)
	local p = part(parent, name, Vector3.new(thickness, diameter, diameter), CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function sign(parent, text, sub, size, cf, bg, fg, face)
	local board = part(parent, "Sign", size, cf, bg, M.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(size.X * 40, size.Y * 40)
	gui.LightInfluence = 0.2
	gui.Parent = board
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, sub and 0.65 or 1)
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = fg
	t.Parent = gui
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = rgb(70, 90, 160)
	s.Parent = t
	if sub then
		local u = Instance.new("TextLabel")
		u.BackgroundTransparency = 1
		u.Position = UDim2.fromScale(0, 0.62)
		u.Size = UDim2.fromScale(1, 0.3)
		u.Text = sub
		u.TextScaled = true
		u.Font = Enum.Font.GothamBold
		u.TextColor3 = rgb(110, 130, 200)
		u.Parent = gui
	end
	return board
end

local PASTEL = { rgb(255, 165, 208), rgb(165, 200, 255), rgb(190, 165, 255), rgb(255, 200, 165), rgb(190, 255, 228) }
local GOLD = rgb(255, 176, 64)
local GLOW = rgb(255, 222, 150)
-- Контуры площадки, дорожек и витрины яиц: мягкая пастельная неоновая кромка вместо жёлтой.
-- Цвет плавно переливается розовый → сиреневый → небесный (SkyIslesFX, тег SkyTrim).
local TRIM = rgb(255, 190, 235)
local function trim(p)
	p.Transparency = 0.25
	p:AddTag("SkyTrim")
	return p
end

-- Надпись SKY ISLES: парит в воздухе и всегда повёрнута к игроку. Облачный пастельный стиль:
-- крупный Fredoka One с градиентом розовый → небесный, толстая белая обводка, подпись ниже.
local function skyTitle(parent, at)
	local anchor = part(parent, "TitleAnchor", Vector3.new(0.2, 0.2, 0.2), at, rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false })
	local board = Instance.new("BillboardGui")
	board.Name = "SkyTitle"
	board.Size = UDim2.fromScale(34, 11)
	board.LightInfluence = 0
	board.MaxDistance = 320
	board.Parent = anchor
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.72)
	title.Text = "SKY ISLES"
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = rgb(255, 255, 255)
	title.Parent = board
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 170, 220)), ColorSequenceKeypoint.new(0.5, rgb(255, 235, 250)), ColorSequenceKeypoint.new(1, rgb(150, 205, 255)) })
	g.Rotation = 90
	g.Parent = title
	local s = Instance.new("UIStroke")
	s.Thickness = 5
	s.Color = rgb(150, 110, 220)
	s.Parent = title
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0, 0.7)
	sub.Size = UDim2.fromScale(1, 0.28)
	sub.Text = "above the clouds"
	sub.TextScaled = true
	sub.Font = Enum.Font.FredokaOne
	sub.TextColor3 = rgb(255, 255, 255)
	sub.Parent = board
	local s2 = Instance.new("UIStroke")
	s2.Thickness = 3
	s2.Color = rgb(120, 150, 230)
	s2.Parent = sub
	return anchor
end

local function glowPart(parent, name, size, at, color, extra)
	local p = part(parent, name, size, at, color, M.Neon, { CanCollide = false, CastShadow = false })
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	return p
end

-- Искорка-звезда (видна с любой стороны).
-- Звезда — отдельная модель "Star": SkyIslesFX покачивает её вверх-вниз и медленно вращает.
local function star(parent, at, s, color)
	color = color or GLOW
	local m = Instance.new("Model")
	m.Name = "Star"
	glowPart(m, "StarCore", Vector3.new(s * 0.35, s * 0.35, s * 0.35), at, color)
	glowPart(m, "StarA", Vector3.new(s, s * 0.14, s * 0.14), at, color)
	glowPart(m, "StarB", Vector3.new(s * 0.14, s, s * 0.14), at, color)
	glowPart(m, "StarC", Vector3.new(s * 0.14, s * 0.14, s), at, color)
	glowPart(m, "StarD", Vector3.new(s * 0.6, s * 0.1, s * 0.1), CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 4), color)
	glowPart(m, "StarE", Vector3.new(s * 0.1, s * 0.1, s * 0.6), CFrame.new(at) * CFrame.Angles(math.pi / 4, 0, 0), color)
	m.WorldPivot = CFrame.new(at)
	m.Parent = parent
	return m
end

-- ===== Магазин: прилавок, полосатый навес, облачная вывеска с иконкой =====
-- Своя 3D-модель (модель или деталь) высотой height: низ на земле в точке at, лицевая сторона (+Z модели)
-- повёрнута на yaw вокруг вертикали (0 — к +Z мира).
local function placeTemplate(template, parent, name, height, at, yaw)
	local source = template:Clone()
	local m = Instance.new("Model")
	m.Name = name
	if source:IsA("Model") then
		for _, child in ipairs(source:GetChildren()) do
			child.Parent = m
		end
		source:Destroy()
	else
		source.Parent = m
	end
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			decorate(p)
		end
	end
	local _, size = m:GetBoundingBox()
	m:ScaleTo(height / math.max(size.Y, 0.01))
	local cf
	cf, size = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(cf)
	m:PivotTo(CFrame.new(at + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, yaw or 0, 0) * offset.Rotation:Inverse() * CFrame.new(-offset.Position))
	m.Parent = parent
	return m, size
end

local function shop(parent, name, at, title, accent, icon)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local folder = ReplicatedStorage:FindFirstChild("CustomShops")
	local template = folder and folder:FindFirstChild(name)
	if template and template:FindFirstChildWhichIsA("BasePart", true) then
		-- Своя модель магазина вместо прилавка из деталей. Вход смотрит на центральную дорожку (x = 0),
		-- перед входом невидимый круг ShopZone: пробежал через него — открылось меню. VendorAnchor
		-- для продавца (атрибут Yaw — куда он смотрит), вывеска с названием над крышей.
		local dir = Vector3.new(C.X - at.X, 0, 0).Unit
		local yaw = math.atan2(dir.X, dir.Z)
		-- Лицевая сторона моделей магазинов — их -Z, поэтому доворачиваем ещё на 180°.
		local _, size = placeTemplate(template, m, "ShopModel", 22, at - dir * 3, yaw + math.pi)
		sign(m, title, nil, Vector3.new(15, 3.6, 0.5), CFrame.new(at + dir * 4 + Vector3.new(0, size.Y + 3, 0)) * CFrame.Angles(0, yaw, 0), rgb(255, 250, 255), accent:Lerp(rgb(60, 70, 150), 0.45), Enum.NormalId.Back)
		local zone = disc(m, "ShopZone", 24, 0.3, at + dir * 15 + Vector3.new(0, 0.7, 0), rgb(255, 190, 110), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
		zone.Size = Vector3.new(0.3, 24, 24)
		local anchor = part(m, "VendorAnchor", Vector3.new(1, 1, 1), at + dir * 4 + Vector3.new(0, 0.6, 0), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
		anchor:SetAttribute("Yaw", math.atan2(-dir.X, -dir.Z))
		m:SetAttribute("NoVendor", true) -- у своих моделей пустой прилавок, продавца GameServer не ставит
		return m
	end
	local floor = disc(m, "Plinth", 24, 0.6, at + Vector3.new(0, 0.3, 4), rgb(250, 246, 255), M.SmoothPlastic)
	floor.CanCollide = true
	disc(m, "PlinthGlow", 24.8, 0.3, at + Vector3.new(0, 0.2, 4), GOLD, M.Neon, { CanCollide = false })
	part(m, "Counter", Vector3.new(14, 4, 3), at + Vector3.new(0, 2.6, -2), rgb(250, 246, 255))
	part(m, "CounterTop", Vector3.new(15, 0.6, 4), at + Vector3.new(0, 4.9, -2), accent)
	part(m, "BackWall", Vector3.new(16, 11, 1), at + Vector3.new(0, 6, -6), accent:Lerp(rgb(255, 255, 255), 0.55))
	for _, sx in ipairs({ -1, 1 }) do
		part(m, "Pillar", Vector3.new(1.4, 14, 1.4), at + Vector3.new(sx * 8, 7.5, 1.5), rgb(250, 246, 255))
		ball(m, "PillarCap", 2.6, at + Vector3.new(sx * 8, 14.8, 1.5), GOLD)
	end
	-- Полосатый навес со скалопами по краю.
	for i = 1, 9 do
		local c = i % 2 == 0 and accent or rgb(255, 255, 255)
		part(m, "Awning", Vector3.new(1.9, 0.6, 11), CFrame.new(at + Vector3.new(-8 + (i - 1) * 2, 14.3, -2)) * CFrame.Angles(math.rad(10), 0, 0), c, M.SmoothPlastic, { CanCollide = false })
		ball(m, "Scallop", 2, at + Vector3.new(-8 + (i - 1) * 2, 13.1, 3.4), c)
	end
	-- Облачная вывеска.
	local cy = 20
	for k, d in ipairs({ 7, 10, 12, 10, 7 }) do
		cloud(m, "SignCloud", d, at + Vector3.new(-10 + (k - 1) * 5, cy + (k == 3 and 1.5 or 0), -5.8), rgb(255, 255, 255))
	end
	sign(m, title, nil, Vector3.new(15, 3.6, 0.5), CFrame.new(at + Vector3.new(0, cy + 0.5, -2.6)), rgb(255, 250, 255), accent:Lerp(rgb(60, 70, 150), 0.45), Enum.NormalId.Back)
	-- Иконка на вывеске.
	local ip = at + Vector3.new(0, cy + 6.2, -2.4)
	if icon == "basket" then
		ball(m, "IconBasket", 5, ip, accent)
		part(m, "IconHandle", Vector3.new(4.4, 0.6, 0.6), ip + Vector3.new(0, 2.8, 0), accent:Lerp(rgb(255, 255, 255), 0.4))
		for k = -1, 1 do
			ball(m, "IconDot", 0.9, ip + Vector3.new(k * 1.3, 0.3, 2.3), rgb(255, 255, 255))
		end
	else
		ball(m, "IconPaw", 3.6, ip + Vector3.new(0, -0.8, 0), accent)
		for k = 0, 3 do
			ball(m, "IconToe", 1.5, ip + Vector3.new(-2.4 + k * 1.6, 1.9 + ((k == 1 or k == 2) and 0.7 or 0), 0), accent)
		end
	end
	-- Зона: заходишь в круг — открывается меню.
	local zone = disc(m, "ShopZone", 24, 0.3, at + Vector3.new(0, 0.7, 10), rgb(255, 190, 110), M.SmoothPlastic, { Transparency = 0.55, CanCollide = false })
	zone.Size = Vector3.new(0.3, 24, 24)
	part(m, "VendorAnchor", Vector3.new(1, 1, 1), at + Vector3.new(0, 0.6, -5.5), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	-- Фонарики по краю навеса.
	for i = 0, 8 do
		glowPart(m, "Lantern", Vector3.new(0.9, 0.9, 0.9), at + Vector3.new(-8 + i * 2, 12.2, 3.6), PASTEL[i % #PASTEL + 1], { Shape = Enum.PartType.Ball })
	end
	return m
end

-- ===== Подиум с яйцом (центральный выше, как на арте) =====
local function eggStand(parent, id, at, theme)
	local stand = Instance.new("Model")
	stand.Name = "EggStand" .. id
	stand.Parent = parent
	local ped = Instance.new("Model")
	ped.Name = "Pedestal"
	ped.Parent = stand
	-- Низкий подиум (0,5 студа): на него заходят, ни во что не упираясь. Красота — в эффектах:
	-- пушистые облачка по краю, светящееся кольцо (его крутит SkyIslesFX, тег PedestalRing), искры вверх.
	disc(ped, "Base", 15, 0.5, at + Vector3.new(0, 0.25, 0), rgb(250, 246, 255))
	trim(disc(ped, "GoldRim", 15.6, 0.3, at + Vector3.new(0, 0.4, 0), TRIM, M.Neon, { CanCollide = false }))
	local glow = trim(disc(ped, "Glow", 10, 0.2, at + Vector3.new(0, 0.55, 0), TRIM, M.Neon, { CanCollide = false }))
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Rise"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 10
	sparks.Lifetime = NumberRange.new(1.5, 2.5)
	sparks.Speed = NumberRange.new(2, 4)
	sparks.EmissionDirection = Enum.NormalId.Right -- ось диска смотрит вверх
	sparks.SpreadAngle = Vector2.new(10, 10)
	sparks.Color = ColorSequence.new(GLOW, rgb(255, 255, 255))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparks.Parent = glow
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		cloud(ped, "Puff", 4.5, at + Vector3.new(math.cos(a) * 8.6, 0.6, math.sin(a) * 8.6), rgb(255, 255, 255))
	end
	local ring = Instance.new("Model")
	ring.Name = "PedestalRing"
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		glowPart(ring, "RingBead", Vector3.new(0.6, 0.6, 0.6), at + Vector3.new(math.cos(a) * 6.2, 1.4, math.sin(a) * 6.2), PASTEL[i % #PASTEL + 1], { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	ring.WorldPivot = CFrame.new(at + Vector3.new(0, 1.4, 0))
	ring.Parent = ped
	ring:AddTag("PedestalRing")
	part(stand, "Interact", Vector3.new(14, 7, 14), at + Vector3.new(0, 4, 0), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	-- Своя 3D-модель яйца (ReplicatedStorage/CustomEggs/Egg<id>) важнее яйца из деталей.
	-- Имя EggDisplay нужно табло и анимации вылупления; покачивает его EggBillboards.
	local folder = ReplicatedStorage:FindFirstChild("CustomEggs")
	local custom = folder and folder:FindFirstChild("Egg" .. id)
	if custom and custom:FindFirstChildWhichIsA("BasePart", true) then
		local egg = placeTemplate(custom, stand, "EggDisplay", 9, at + Vector3.new(0, 1.6, 0))
		egg.WorldPivot = CFrame.new((egg:GetBoundingBox()).Position)
	else
		local egg = require(ReplicatedStorage:WaitForChild("ThemedVisuals")).BuildEgg(theme)
		egg:PivotTo(CFrame.new(at + Vector3.new(0, 5.6, 0)))
		egg.Parent = stand
	end
	stand:SetAttribute("EggReady", true)
	return stand
end

-- Радуга: семь неоновых полос плавной дугой из коротких сегментов, концы прячутся в облаках.
-- Бегущие цвета (атрибуты Band и Along у сегментов "RainbowBand") анимирует SkyIslesFX.
local function rainbow(parent, at, radius)
	local cols = { rgb(255, 90, 110), rgb(255, 160, 80), rgb(255, 230, 100), rgb(120, 230, 140), rgb(100, 200, 255), rgb(110, 130, 255), rgb(185, 120, 255) }
	local width = 2.4
	local segments = 44
	for band, col in ipairs(cols) do
		local r = radius - (band - 1) * width
		local step = (math.pi + 0.2) / segments
		for k = 0, segments - 1 do
			local a = -0.1 + (k + 0.5) * step
			local pos = at + Vector3.new(math.cos(a) * r, math.sin(a) * r, 0)
			local chord = 2 * r * math.sin(step / 2) + 0.15
			local seg = part(parent, "RainbowBand", Vector3.new(chord, width + 0.05, 1.2), CFrame.new(pos) * CFrame.Angles(0, 0, a + math.pi / 2), col, M.Neon, { Transparency = 0.25, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false })
			seg:SetAttribute("Band", band)
			seg:SetAttribute("Along", k / (segments - 1))
		end
	end
	-- Облака на концах закрывают места, где дуга уходит в пол.
	local inner = radius - #cols * width
	for _, side in ipairs({ -1, 1 }) do
		local foot = at + Vector3.new(side * (radius + inner) / 2, 0, 0)
		cloud(parent, "RainbowCloud", 20, foot + Vector3.new(0, 1.5, 0), rgb(250, 246, 255), false, false, true)
		cloud(parent, "RainbowCloud", 13, foot + Vector3.new(side * 7, 0.5, 3), rgb(250, 246, 255), false, false, true)
	end
end

-- ===== Фонарный столб, забор, цветы =====
local function lamp(parent, at)
	part(parent, "LampPole", Vector3.new(0.7, 10, 0.7), at + Vector3.new(0, 5, 0), rgb(250, 246, 255))
	ball(parent, "LampBase", 2, at + Vector3.new(0, 0.6, 0), GOLD)
	part(parent, "LampArm", Vector3.new(0.5, 0.5, 2.4), at + Vector3.new(0, 10, 0), GOLD)
	local bulb = glowPart(parent, "LampBulb", Vector3.new(2.2, 2.2, 2.2), at + Vector3.new(0, 10.4, 1.2), GLOW, { Shape = Enum.PartType.Ball })
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 205, 150)
	l.Range = 24
	l.Brightness = 1.3
	l.Shadows = false
	l.Parent = bulb
end
local function fence(parent, x, z1, z2)
	part(parent, "FenceRail", Vector3.new(0.5, 0.5, math.abs(z2 - z1)), Vector3.new(x, C.Y + 1.7, C.Z + (z1 + z2) / 2) + Vector3.new(C.X, 0, 0), rgb(250, 246, 255), M.SmoothPlastic)
	part(parent, "FenceRail", Vector3.new(0.5, 0.5, math.abs(z2 - z1)), Vector3.new(x, C.Y + 0.8, C.Z + (z1 + z2) / 2) + Vector3.new(C.X, 0, 0), rgb(250, 246, 255), M.SmoothPlastic)
	for z = z1, z2, 5 do
		part(parent, "FencePost", Vector3.new(0.9, 2.6, 0.9), Vector3.new(C.X + x, C.Y + 1.3, C.Z + z), rgb(250, 246, 255), M.SmoothPlastic)
		ball(parent, "FenceCap", 1.1, Vector3.new(C.X + x, C.Y + 2.8, C.Z + z), GOLD)
	end
end
local function flowers(parent, at, i)
	local n = 3 + i % 3
	for k = 1, n do
		local off = Vector3.new(math.cos(k * 2.3 + i) * 2, 0, math.sin(k * 2.3 + i) * 2)
		part(parent, "Stem", Vector3.new(0.2, 1.4, 0.2), at + off + Vector3.new(0, 0.9, 0), rgb(120, 200, 140), M.SmoothPlastic, { CanCollide = false })
		ball(parent, "Bloom", 1.3, at + off + Vector3.new(0, 1.8, 0), PASTEL[(i + k) % #PASTEL + 1])
		ball(parent, "Heart", 0.5, at + off + Vector3.new(0, 2.1, 0), rgb(255, 236, 140))
	end
end

-- ===== Леденцовое дерево =====
local function candyTree(parent, at, i)
	local trunk = part(parent, "Trunk", Vector3.new(7, 1.4, 1.4), CFrame.new(at + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), rgb(250, 240, 245), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	trunk.Size = Vector3.new(7, 1.4, 1.4)
	local col = PASTEL[i % #PASTEL + 1]
	ball(parent, "Crown", 7.5, at + Vector3.new(0, 9, 0), col)
	ball(parent, "Crown2", 5, at + Vector3.new(2.4, 11.2, 0.4), col:Lerp(rgb(255, 255, 255), 0.3))
	ball(parent, "Crown3", 4.2, at + Vector3.new(-2.2, 10.6, -0.6), col:Lerp(rgb(255, 255, 255), 0.5))
end

-- ===== Парящий островок с кристаллами =====
local function islet(parent, at, seed)
	local m = Instance.new("Model")
	m.Name = "Islet"
	m.Parent = parent
	local rng = Random.new(seed)
	local size = rng:NextInteger(26, 44)
	if #cloudMeshes > 0 then
		-- Со своими облаками островок — просто пушистая группа облаков, без диска и кристаллов.
		cloud(m, "Puff", size, at, rgb(255, 255, 255))
		for k = 1, 3 do
			local a = k / 3 * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
			local r = size * rng:NextNumber(0.35, 0.5)
			cloud(m, "Puff", size * rng:NextNumber(0.45, 0.65), at + Vector3.new(math.cos(a) * r, rng:NextNumber(-3, 2), math.sin(a) * r), rgb(255, 255, 255))
		end
		m:SetAttribute("BaseY", at.Y)
		return m
	end
	local top = disc(m, "Top", size, 3, at, rgb(228, 222, 250))
	top.CanCollide = false
	disc(m, "TopGlow", size + 1.4, 0.4, at + Vector3.new(0, -1.3, 0), GOLD, M.Neon, { CanCollide = false })
	for k = 1, 5 do
		cloud(m, "Under", size * rng:NextNumber(0.3, 0.5), at + Vector3.new(rng:NextNumber(-size / 4, size / 4), -rng:NextNumber(3, 9), rng:NextNumber(-size / 4, size / 4)), rgb(240, 236, 255))
	end
	local col = PASTEL[seed % #PASTEL + 1]
	for k = 1, 3 do
		local h = rng:NextNumber(6, 13)
		local sp = part(m, "Crystal", Vector3.new(2.2, h, 2.2), CFrame.new(at + Vector3.new(rng:NextNumber(-size / 4, size / 4), h / 2 + 1.5, rng:NextNumber(-size / 4, size / 4))) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 3), rng:NextNumber(-0.15, 0.15)), col, M.Neon, { CanCollide = false, Transparency = 0.3 })
		if k == 1 then
			local l = Instance.new("PointLight")
			l.Color = col
			l.Range = 18
			l.Brightness = 0.9
			l.Parent = sp
		end
	end
	m:SetAttribute("BaseY", at.Y)
	return m
end
-- ===== Пруд: настоящая вода Terrain (волны, отражения) в приподнятой чаше с облачным бортиком,
-- кувшинки с цветами, водопад со скального уступа под облаками. Кувшинки и круги на воде анимирует SkyIslesFX.
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = parent
	return e
end
local function lily(parent, p, rng)
	local m = Instance.new("Model")
	m.Name = "Lily"
	local size = rng:NextNumber(3.4, 4.6)
	disc(m, "Pad", size, 0.2, p, rgb(95, 205, 130), M.SmoothPlastic, { CanCollide = false, CastShadow = false })
	disc(m, "PadRim", size + 0.3, 0.12, p - Vector3.new(0, 0.05, 0), rgb(55, 150, 95), M.SmoothPlastic, { CanCollide = false, CastShadow = false })
	local petal = PASTEL[rng:NextInteger(1, #PASTEL)]
	local center = p + Vector3.new(size * 0.12, 0.35, 0)
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2
		part(m, "Petal", Vector3.new(0.55, 0.25, 1.3), CFrame.new(center) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.6) * CFrame.Angles(math.rad(-25), 0, 0), petal:Lerp(rgb(255, 255, 255), 0.25), M.SmoothPlastic, { CanCollide = false, CastShadow = false })
	end
	ball(m, "Heart", 0.6, center + Vector3.new(0, 0.15, 0), rgb(255, 225, 110))
	m.WorldPivot = CFrame.new(p)
	m.Parent = parent
	return m
end
local function pond(parent, at)
	local m = Instance.new("Model")
	m.Name = "Pond"
	m.Parent = parent
	local R = 20
	-- Вода Terrain рисуется клетками по 4 студа: заполняем ровно одну клетку над площадкой (y 300..304),
	-- поэтому чаша приподнята, а края закрывает облачный бортик.
	local deckTop = math.floor(at.Y / 4 + 0.5) * 4
	local surface = deckTop + 4
	workspace.Terrain:FillCylinder(CFrame.new(at.X, deckTop + 2, at.Z), 4, R, Enum.Material.Water)
	disc(m, "PondBed", R * 2, 0.3, Vector3.new(at.X, deckTop + 0.2, at.Z), rgb(120, 195, 215), M.Sand, { CanCollide = false })
	-- Невидимая метка поверхности: по ней SkyIslesFX пускает круги на воде.
	disc(m, "Water", R * 2 - 4, 0.1, Vector3.new(at.X, surface, at.Z), rgb(255, 255, 255), M.SmoothPlastic, { CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1 })
	local rng = Random.new(3)
	local back = Vector3.new(at.X - C.X, 0, at.Z - C.Z).Unit
	local side = Vector3.new(-back.Z, 0, back.X)
	for k = 1, 26 do
		local a = k / 26 * math.pi * 2
		-- За водопадом бортика нет: там скала, а струя должна падать в воду, а не в облака.
		if Vector3.new(math.cos(a), 0, math.sin(a)):Dot(back) < 0.88 then
			cloud(m, "RimCloud", rng:NextNumber(8, 10), Vector3.new(at.X + math.cos(a) * (R + 1.5), surface - 1.2, at.Z + math.sin(a) * (R + 1.5)), rgb(255, 255, 255))
		end
	end
	for k = 1, 6 do
		local a = k * 1.05 + rng:NextNumber(-0.2, 0.2)
		local r = rng:NextNumber(5, 12)
		-- Чуть выше уровня: волны Terrain не захлёстывают кувшинки.
		lily(m, Vector3.new(at.X + math.cos(a) * r, surface + 0.35, at.Z + math.sin(a) * r), rng)
	end

	-- Водопад с дальней от центра острова стороны: скальный уступ в облаках, вода падает отвесно в пруд.
	local cliff = Vector3.new(at.X, surface, at.Z) + back * (R + 3)
	local stone = { rgb(215, 210, 230), rgb(230, 226, 242), rgb(198, 194, 218) }
	local function rock(pos, size)
		part(m, "Cliff", size, CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, 6.28), rng:NextNumber(-0.12, 0.12)), stone[rng:NextInteger(1, 3)], M.Slate, { CanCollide = true })
	end
	for _, k in ipairs({ -1, 1 }) do
		rock(cliff + side * (k * 6.5) + Vector3.new(0, 4.5, 0), Vector3.new(7, 11, 7))
		rock(cliff + side * (k * 5) + back * 2 + Vector3.new(0, 10.5, 0), Vector3.new(6, 5, 6))
		rock(cliff + side * (k * 10) + Vector3.new(0, 2, 0), Vector3.new(6, 5, 6))
	end
	rock(cliff + back * 2.5 + Vector3.new(0, 5, 0), Vector3.new(7, 12, 6))
	local lipY = surface + 11
	-- Уступ выдаётся над прудом, чтобы струя падала в воду, а не в бортик.
	local lip = Vector3.new(cliff.X, lipY, cliff.Z) - back * 5
	part(m, "Lip", Vector3.new(6, 0.8, 7), CFrame.lookAt(lip, lip - back), stone[2], M.Slate, { CanCollide = true })
	-- Облака лежат на скале и вдавлены в неё: сверху шапка, по бокам и у краёв уступа — подушки,
	-- так что камень проглядывает только местами. Середину перед струёй не закрываем.
	cloud(m, "FallCloud", 20, cliff + back * 3 + Vector3.new(0, 12.5, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 14, cliff + back * 1 + side * 8.5 + Vector3.new(0, 9.5, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 14, cliff + back * 1 - side * 8.5 + Vector3.new(0, 10, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 12, cliff - back * 1 + side * 8 + Vector3.new(0, 4, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 12, cliff - back * 1 - side * 8 + Vector3.new(0, 4.5, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 11, cliff + side * 12 + Vector3.new(0, 1, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 11, cliff - side * 12 + Vector3.new(0, 1.5, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 7, lip + side * 4.8 + Vector3.new(0, 0.6, 0), rgb(255, 255, 255))
	cloud(m, "FallCloud", 7, lip - side * 4.8 + Vector3.new(0, 0.6, 0), rgb(255, 255, 255))
	-- Пелена воды: прозрачное стекло от края уступа до поверхности, по нему бегут струи капель.
	local top = lip - back * 3.6 + Vector3.new(0, 0.5, 0)
	local bottom = Vector3.new(top.X, surface, top.Z) - back * 0.6
	local height = top.Y - bottom.Y
	local mid = (top + bottom) / 2
	local sheet = part(m, "FallSheet", Vector3.new(5, height, 0.4), CFrame.lookAt(mid, mid - back), rgb(185, 230, 255), M.Glass, { CanCollide = false, CanQuery = false, CanTouch = false })
	sheet.Transparency = 0.25
	sheet.Reflectance = 0.25
	local core = part(m, "FallCore", Vector3.new(3.4, height, 0.2), CFrame.lookAt(mid, mid - back) * CFrame.new(0, 0, -0.15), rgb(245, 252, 255), M.SmoothPlastic, { CanCollide = false, CanQuery = false, CanTouch = false })
	core.Transparency = 0.4
	local source = part(m, "DropSource", Vector3.new(4.6, 0.2, 0.6), CFrame.lookAt(top, top - back), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	emitter(source, {
		Name = "Streaks",
		Color = ColorSequence.new(rgb(250, 254, 255)),
		LightEmission = 0.3,
		Rate = 160,
		Lifetime = NumberRange.new(height / 24),
		Speed = NumberRange.new(22, 26),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(2, 2),
		Squash = NumberSequence.new(-1.5),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1.4) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.45) }),
		Shape = Enum.ParticleEmitterShape.Box,
	})
	emitter(source, {
		Name = "LipMist",
		Color = ColorSequence.new(rgb(245, 252, 255)),
		Rate = 5,
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(0.5, 1.5),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) }),
	})
	-- Пена, брызги и туман у подножия.
	local foam = disc(m, "Foam", 8, 0.15, bottom + Vector3.new(0, 0.05, 0) - back * 0.6, rgb(250, 254, 255), M.SmoothPlastic, { CanCollide = false, Transparency = 0.3 })
	emitter(foam, {
		Name = "Splash",
		Color = ColorSequence.new(rgb(245, 252, 255)),
		Rate = 35,
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(4, 8),
		SpreadAngle = Vector2.new(50, 50),
		Acceleration = Vector3.new(0, -18, 0),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.4) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		EmissionDirection = Enum.NormalId.Right, -- ось диска смотрит вверх
	})
	emitter(foam, {
		Name = "Mist",
		Color = ColorSequence.new(rgb(240, 250, 255)),
		Rate = 10,
		Lifetime = NumberRange.new(1.5, 2.5),
		Speed = NumberRange.new(1, 2.5),
		SpreadAngle = Vector2.new(80, 80),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 7) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) }),
		EmissionDirection = Enum.NormalId.Right,
	})
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CastShadow = p.Name == "Cliff"
		end
	end
end

-- ===== Низ острова: облачная подушка =====
-- Под площадкой (её низ — y = -10 от центра мира) пышная масса облаков в форме перевёрнутого конуса:
-- кольца облаков плотно перекрываются, внутри светлая сердцевина, чтобы не было просветов.
-- Из облаков торчат пастельные кристаллы, снизу светящаяся друза. Вся подушка (модель "Underside")
-- плавно качается вверх-вниз (SkyIslesFX), а кольцо облаков под краем площадки стоит на месте и прячет стык.
local function underside(parent)
	local m = Instance.new("Model")
	m.Name = "Underside"
	m.Parent = parent
	local rng = Random.new(19)
	local top, depth, layers, R = -14, 120, 9, 150
	local function radiusAt(k)
		return R * (1 - k / layers) ^ 1.3 + 6
	end
	local white = rgb(246, 242, 255)
	for k = 0, layers - 1 do
		local y = top - (k + 0.5) * depth / layers
		local r = radiusAt(k + 0.5)
		disc(m, "CloudCore", r * 2 - 8, depth / layers + 6, L(0, y, 0), white, M.SmoothPlastic, { CanCollide = false })
		local size = math.clamp(r * 0.45, 18, 44)
		local count = math.max(5, math.floor(2 * math.pi * r / (size * 0.55)))
		for i = 1, count do
			local a = i / count * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
			cloud(m, "UnderPuff", size * rng:NextNumber(0.9, 1.15), L(math.cos(a) * (r - size * 0.15), y + rng:NextNumber(-3, 3), math.sin(a) * (r - size * 0.15)), white)
		end
	end
	cloud(m, "UnderPuff", 30, L(0, top - depth + 4, 0), white)
	-- Кристаллы торчат из облаков.
	for i = 1, 26 do
		local k = rng:NextNumber(1, layers - 1.5)
		local a = rng:NextNumber(0, math.pi * 2)
		local r = radiusAt(k) + 4
		local y = top - k * depth / layers
		local col = PASTEL[rng:NextInteger(1, #PASTEL)]
		local len = rng:NextNumber(10, 18)
		local base = L(math.cos(a) * r, y, math.sin(a) * r)
		local out = Vector3.new(math.cos(a), rng:NextNumber(-0.6, -0.1), math.sin(a)).Unit
		local c = part(m, "Crystal", Vector3.new(3, len, 3), CFrame.lookAt(base + out * len / 2, base + out * len) * CFrame.Angles(math.pi / 2, 0, 0), col, M.Neon, { CanCollide = false, Transparency = 0.25 })
		if i % 4 == 0 then
			local l = Instance.new("PointLight")
			l.Color = col
			l.Range = 16
			l.Brightness = 0.8
			l.Shadows = false
			l.Parent = c
		end
	end
	-- Светящаяся друза снизу.
	local tip = L(0, top - depth - 6, 0)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local dir = i == 7 and Vector3.new(0, -1, 0) or Vector3.new(math.cos(a) * 0.45, -1, math.sin(a) * 0.45).Unit
		local len = i == 7 and 16 or rng:NextNumber(8, 12)
		part(m, "TipCrystal", Vector3.new(3, len, 3), CFrame.lookAt(tip + dir * len / 2, tip + dir * len) * CFrame.Angles(math.pi / 2, 0, 0), PASTEL[i % #PASTEL + 1], M.Neon, { CanCollide = false, Transparency = 0.15 })
	end
	local glow = Instance.new("PointLight")
	glow.Color = rgb(200, 170, 255)
	glow.Range = 40
	glow.Brightness = 1.5
	glow.Parent = m:FindFirstChild("TipCrystal")
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
		end
	end
	m.WorldPivot = CFrame.new(L(0, top, 0))
	-- Неподвижное кольцо облаков под краем площадки: закрывает стык, когда подушка опускается.
	for i = 1, 40 do
		local a = i / 40 * math.pi * 2
		cloud(parent, "SeamPuff", rng:NextNumber(26, 34), L(math.cos(a) * 150, -12 + rng:NextNumber(-2, 1), math.sin(a) * 150), white)
	end
	disc(parent, "SeamCore", 300, 8, L(0, -14, 0), white, M.SmoothPlastic, { CanCollide = false, CanTouch = false, CanQuery = false })
end

-- ===== Обкантовка витрины яиц =====
-- Низкий светлый бордюр по контуру площадки-«пилюли» (прямые бока и полукруглые концы),
-- сверху пастельная неоновая полоса, через равные промежутки светящиеся фонарики-кристаллы.
-- Где проходит главная дорога (|x| < 11), бордюра нет — там проход.
local function eggBorder(parent, center, halfLen, radius)
	local m = Instance.new("Model")
	m.Name = "EggBorder"
	m.Parent = parent
	local points = {}
	local step = 3
	for x = -halfLen, halfLen, step do
		table.insert(points, { Vector3.new(x, 0, radius), Vector3.new(1, 0, 0) })
		table.insert(points, { Vector3.new(x, 0, -radius), Vector3.new(1, 0, 0) })
	end
	for _, sx in ipairs({ -1, 1 }) do
		local n = math.floor(math.pi * radius / step)
		for k = 1, n - 1 do
			local a = -math.pi / 2 + k / n * math.pi
			local off = Vector3.new(math.cos(a) * radius * sx, 0, math.sin(a) * radius)
			table.insert(points, { Vector3.new(halfLen * sx, 0, 0) + off, Vector3.new(-math.sin(a) * sx, 0, math.cos(a)) })
		end
	end
	local i = 0
	for _, pt in ipairs(points) do
		local pos, dir = pt[1], pt[2]
		if math.abs(pos.X) > 11 then
			i += 1
			local cf = CFrame.lookAt(center + pos + Vector3.new(0, 0.45, 0), center + pos + Vector3.new(0, 0.45, 0) + dir)
			part(m, "Curb", Vector3.new(1.2, 0.9, step + 0.3), cf, rgb(250, 246, 255), M.SmoothPlastic, { CanCollide = false })
			part(m, "CurbTrim", Vector3.new(0.5, 0.15, step + 0.3), cf * CFrame.new(0, 0.5, 0), PASTEL[math.floor(i / 3) % #PASTEL + 1], M.Neon, { CanCollide = false })
			if i % 6 == 0 then
				local post = cf * CFrame.new(0, 1.6, 0)
				part(m, "LanternPost", Vector3.new(0.5, 2.2, 0.5), post, rgb(250, 246, 255), M.SmoothPlastic, { CanCollide = false })
				local col = PASTEL[(i / 6) % #PASTEL + 1]
				local gem = part(m, "LanternGem", Vector3.new(1, 1.6, 1), post * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, math.pi / 4, 0), col, M.Neon, { CanCollide = false, Transparency = 0.15 })
				if i % 12 == 0 then
					local l = Instance.new("PointLight")
					l.Color = col
					l.Range = 10
					l.Brightness = 0.8
					l.Shadows = false
					l.Parent = gem
				end
			end
		end
	end
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
		end
	end
end

function Sky.Build(world)
	local model = Instance.new("Model")
	model.Name = "SkyIsles"
	local ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = model

	-- Основная площадка с золотой подсветкой по краю и пушистым бортиком.
	disc(ground, "Deck", 320, 10, L(0, -5, 0), rgb(212, 204, 238))
	trim(disc(ground, "GoldOutline", 306, 0.3, L(0, 0.12, 0), TRIM, M.Neon, { CanCollide = false }))
	disc(ground, "Plaza", 300, 0.4, L(0, 0.2, 0), rgb(232, 226, 250), M.SmoothPlastic, { CanCollide = false })
	disc(ground, "InnerRing", 250, 0.3, L(0, 0.3, 0), rgb(222, 214, 246), M.SmoothPlastic, { CanCollide = false })
	for i = 1, 56 do
		local a = i / 56 * math.pi * 2
		-- Бортик сплошной (портал стоит на острове). Облака опущены, чтобы кромка площадки пряталась под ними.
		cloud(ground, "RimPuff", 28 + (i % 3) * 3, L(math.cos(a) * 162, 1.5, math.sin(a) * 162), rgb(246, 240, 255), true, false, true)
	end
	local rng = Random.new(7)
	-- Снизу площадка — облачная подушка с кристаллами, она качается вверх-вниз.
	underside(ground)
	-- Дорожки с золотыми кромками.
	part(ground, "MainPath", Vector3.new(18, 0.5, 270), L(0, 0.4, 5), rgb(255, 214, 236), M.SmoothPlastic, { CanCollide = false })
	part(ground, "ShopPath", Vector3.new(190, 0.5, 14), L(0, 0.41, 45), rgb(200, 214, 255), M.SmoothPlastic, { CanCollide = false })
	for _, sx in ipairs({ -1, 1 }) do
		trim(glowPart(ground, "PathEdge", Vector3.new(0.4, 0.2, 270), L(sx * 9.2, 0.6, 5), TRIM))
	end
	for z = -120, 120, 12 do
		part(ground, "PathDash", Vector3.new(1, 0.55, 5), L(0, 0.45, z), rgb(255, 255, 255), M.SmoothPlastic, { CanCollide = false })
	end

	-- Магазины.
	local upgrade = shop(model, "UpgradeShop", L(-85, 0.4, 45), "SKY SHOP", rgb(255, 130, 190), "basket")
	shop(model, "MagnetShop", L(85, 0.4, 45), "SKY MAGNETS", rgb(110, 170, 255), "paw")
	upgrade:SetAttribute("Sky", true)

	-- Витрина яиц: низкая пилюля-ярус (на неё просто заходят), три подиума в ряд, золотая арка со звездой.
	local tierY = 0.4
	local tier = part(model, "EggTier", Vector3.new(120, 0.4, 28), L(0, tierY + 0.2, 112), rgb(250, 246, 255))
	for _, sx in ipairs({ -1, 1 }) do
		disc(model, "EggTierEnd", 28, 0.4, L(sx * 60, tierY + 0.2, 112), rgb(250, 246, 255))
		trim(disc(model, "EggTierGlow", 29, 0.3, L(sx * 60, tierY + 0.2, 112), TRIM, M.Neon, { CanCollide = false }))
	end
	trim(glowPart(model, "EggTierGlow", Vector3.new(120, 0.3, 29), L(0, tierY + 0.2, 112), TRIM))
	local topY = tierY + 0.4
	eggStand(model, 7, L(-40, topY, 112), "Cloud")
	eggStand(model, 8, L(0, topY, 112), "Celestial")
	eggStand(model, 9, L(40, topY, 112), "Crystal")
	eggBorder(model, L(0, tierY, 112), 60, 15)
	for _, sx in ipairs({ -1, 1 }) do
		star(model, L(sx * 60, topY + 14, 112), 3.5)
	end

	-- Арка входа и обратный портал в Неонград.
	local archY = 0.4
	-- Портал в Неонград стоит на острове, в конце главной дороги; над ним парит надпись SKY ISLES.
	local portalZ = 146
	skyTitle(model, L(0, archY + 31, portalZ))
	local portal = part(model, "PortalToNeon", Vector3.new(18, 22, 1), L(0, archY + 11, portalZ), rgb(170, 190, 255), M.ForceField, { CanCollide = false, Transparency = 0.2 })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterWorld"
	prompt.ActionText = "Return to Neon District"
	prompt.ObjectText = "Portal"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = portal

	-- Радуги, деревья, фонари, заборы, цветы, пруд.
	rainbow(model, L(0, 0.5, -95), 80)
	rainbow(model, L(-100, 0.5, 120), 38)
	for i = 0, 9 do
		candyTree(model, L(-24 - (i % 2) * 3, 0.4, 85 - i * 22), i)
		candyTree(model, L(24 + (i % 2) * 3, 0.4, 85 - i * 22), i + 2)
	end
	local deco = Instance.new("Folder")
	deco.Name = "Decor"
	deco.Parent = model
	for z = -100, 90, 38 do
		lamp(deco, L(-14, 0.4, z))
		lamp(deco, L(14, 0.4, z))
	end
	for _, sx in ipairs({ -1, 1 }) do
		fence(deco, sx * 11.5, -105, 30)
		fence(deco, sx * 11.5, 60, 92)
		lamp(deco, L(sx * 120, 0.4, 112))
		lamp(deco, L(sx * 60, 0.4, 70))
	end
	-- Пруд с водопадом.
	pond(deco, L(-70, 0.3, -35))
	-- Цветы.
	local fr = Random.new(21)
	for i = 1, 46 do
		local a = fr:NextNumber(0, math.pi * 2)
		local r = fr:NextNumber(30, 140)
		local fx, fz = math.cos(a) * r, math.sin(a) * r
		if math.abs(fx) > 14 and (fx + 70) ^ 2 + (fz + 35) ^ 2 > 34 ^ 2 and not (fz > 95 and fz < 130) and not (math.abs(fz - 45) < 14) then
			flowers(deco, L(fx, 0.4, fz), i)
		end
	end
	-- Искорки-звёзды.
	local sparks = Instance.new("Folder")
	sparks.Name = "Sparkles"
	sparks.Parent = model
	local sr = Random.new(5)
	for i = 1, 70 do
		local a = sr:NextNumber(0, math.pi * 2)
		local r = sr:NextNumber(10, 175)
		star(sparks, L(math.cos(a) * r, sr:NextNumber(6, 40), math.sin(a) * r), sr:NextNumber(1.2, 3))
	end
	local islets = Instance.new("Folder")
	islets.Name = "Islets"
	islets.Parent = model
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		islet(islets, L(math.cos(a) * (215 + (i % 3) * 25), 5 + (i % 4) * 14, math.sin(a) * (215 + (i % 3) * 25)), i * 13)
	end

	-- Монеты: стоячие золотые диски, значение 150, нужен уровень скорости мира.
	local placed = 0
	local avoid = { L(-85, 0, 55), L(85, 0, 55), L(-40, 0, 112), L(0, 0, 112), L(40, 0, 112), L(0, 0, 150), L(-70, 0, -35), L(-60, 0, 112), L(60, 0, 112) }
	local tries = 0
	while placed < 110 and tries < 1200 do -- было 130, на 15% меньше
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber(0, 1)) * 138
		local pos = L(math.cos(a) * r, 3.4, math.sin(a) * r)
		local ok = true
		for _, v in ipairs(avoid) do
			local lim = (v.Z - C.Z == -35) and 34 or 24
			if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(v.X, 0, v.Z)).Magnitude < lim then
				ok = false
				break
			end
		end
		if pos.Z - C.Z > 98 and pos.Z - C.Z < 126 then
			ok = false
		end
		if ok then
			placed += 1
			-- Вид монеты (облачная 150 / звёздная 300 / крылатая 600) и её модель — из CoinTypes;
			-- имя Coin_N и атрибут Value нужны GameServer.
			local kind, rarity = CoinTypes.Pick("Sky", placed)
			local size = CoinTypes.BaseSize.Sky * kind.Scale
			local folder = ReplicatedStorage:FindFirstChild("CustomCoins")
			local template = meshFrom(folder and folder:FindFirstChild(kind.Model)) or coinMeshes[1]
			local coin
			if template then
				coin = decorate(template:Clone())
				coin.Name = "Coin_" .. placed
				coin.Size *= size / math.max(coin.Size.X, coin.Size.Y, coin.Size.Z)
				coin.CFrame = CFrame.new(pos) * template.CFrame.Rotation
				coin.Parent = model
			else
				coin = part(model, "Coin_" .. placed, Vector3.new(0.5, size, size), pos, kind.Color, M.Foil, { Shape = Enum.PartType.Cylinder, CanCollide = false })
			end
			CoinTypes.Mark(coin, "Sky", kind, rarity)
			CoinTypes.AddGlow(coin, kind.Color, rarity)
		end
	end

	-- Страховка: упавшего возвращаем на вход.
	local net = part(model, "SafetyNet", Vector3.new(900, 2, 900), L(0, -110, 0), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	local spawn = L(0, 4, 124) -- перед порталом, лицом к острову
	model:SetAttribute("Spawn", spawn)
	net.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and character.PrimaryPart then
			character:PivotTo(CFrame.new(spawn))
		end
	end)

	model.Parent = world
	return model
end

return Sky
