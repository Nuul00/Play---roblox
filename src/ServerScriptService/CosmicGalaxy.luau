-- Шестой мир Cosmic Galaxy: платформа в открытом космосе с неоновой сеткой, планетами с кольцами,
-- звёздными кристаллами, светильниками, летающими астероидами и огромной окольцованной планетой на фоне.
-- Строится кодом (как Frozen Peaks / Magma Volcano). Монеты Coin_N с атрибутами из CoinTypes собирает GameServer;
-- магазины UpgradeShop/MagnetShop (ShopZone) — тоже он. Портал PortalToVolcano ведёт назад в Magma Volcano.
-- Портал сюда (PortalToGalaxy) Magma Volcano строит сам; BuildVolcanoPortal просто находит его.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoinTypes = require(ReplicatedStorage:WaitForChild("CoinTypes"))

local Galaxy = {}
Galaxy.Center = Vector3.new(7500, 60, 0)
local C = Galaxy.Center
local M = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local SPACE = rgb(24, 18, 48)
local DEEP = rgb(44, 32, 92)
local METAL = rgb(72, 70, 110)
local PATH = rgb(52, 40, 100)
local CYAN = rgb(100, 220, 255)
local PINK = rgb(230, 110, 230)
local GOLD = rgb(255, 215, 110)
local VIOLET = rgb(150, 100, 255)
local WHITE = rgb(255, 255, 255)
local rand = Random.new(7575)

local SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"

local function L(x: number, y: number, z: number): Vector3
	return C + Vector3.new(x, y, z)
end
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame | Vector3, color: Color3, material: Enum.Material?, props: { [string]: any }?): BasePart
	local cls = props and props.Class or "Part"
	local p = Instance.new(cls)
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
	p.Color = color
	p.Material = material or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- мелкий декор без теней (производительность); крупные формы и земля тень оставляют
	if math.max(size.X, size.Y, size.Z) < 12 then p.CastShadow = false end
	if props then
		for k, v in pairs(props) do
			if k ~= "Class" then
				(p :: any)[k] = v
			end
		end
	end
	p.Parent = parent
	return p
end
local function ball(parent, name, d, pos, color, material, props)
	local p = part(parent, name, Vector3.new(d, d, d), pos, color, material, props and props or nil)
	p.Shape = Enum.PartType.Ball
	return p :: any
end
local function disc(parent, name, d, h, pos, color, material, props)
	local p = part(parent, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function pyramid(parent, name, w, h, base: Vector3, color, material, yaw)
	local m = Instance.new("Model")
	m.Name = name
	local half = w / 2
	local rot = CFrame.Angles(0, yaw or 0, 0)
	for k = 0, 3 do
		local a = k * math.pi / 2
		part(m, name .. "Side", Vector3.new(half, h, half), CFrame.new(base) * rot * CFrame.Angles(0, a, 0) * CFrame.new(half / 2, h / 2, half / 2), color, material, { Class = "CornerWedgePart" })
	end
	m.Parent = parent
	return m
end
local function sign(parent, text, size: Vector3, cf: CFrame, fg: Color3, bg: Color3)
	local board = part(parent, "Sign", size, cf, bg, M.SmoothPlastic, { CanCollide = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(size.X * 40, size.Y * 40)
	gui.LightInfluence = 0
	gui.Parent = board
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = fg
	l.Parent = gui
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Color = rgb(30, 15, 70)
	s.Parent = l
	return board
end
local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
	return l
end
local function emitter(parent: Instance, name: string, props: { [string]: any })
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end
local function twinkle(parent: Instance, rate: number, color: Color3, dir: Enum.NormalId?)
	return emitter(parent, "Stars", {
		Texture = SPARK_TEX,
		Rate = rate,
		Lifetime = NumberRange.new(2, 4),
		Speed = NumberRange.new(0.5, 2),
		SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = dir or Enum.NormalId.Top,
		LightEmission = 1,
		Color = ColorSequence.new(color, WHITE),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.6), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
	})
end
-- Свойства для летающего декора: не мешает ни игрокам, ни камере.
local function ghost(extra: { [string]: any }?)
	local t = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }
	if extra then
		for k, v in pairs(extra) do
			t[k] = v
		end
	end
	return t
end

-- ===== Декор =====
-- 2026-11 (фидбэк «столбики-лампы странные»): был «гриб» — диск + шар + силовое поле. Теперь — тонкий
-- тёмный маяк: конусная опора, ствол с двумя светящимися кольцами-полосками и парящий над ним
-- кристалл-ромб (его медленно крутит клиент по тегу BoardEmblem), мягкий свет.
local function lamp(parent, at: Vector3, h: number, color: Color3)
	local m = Instance.new("Model")
	m.Name = "StarLamp"
	local dark = rgb(34, 28, 60)
	disc(m, "Foot", 2.4, 0.5, at + Vector3.new(0, 0.25, 0), dark, M.Metal)
	disc(m, "FootGlow", 2.6, 0.12, at + Vector3.new(0, 0.06, 0), color, M.Neon, { CanCollide = false })
	part(m, "Pole", Vector3.new(0.55, h, 0.55), at + Vector3.new(0, h / 2, 0), dark, M.Metal)
	for _, y in ipairs({ h * 0.35, h * 0.7 }) do
		disc(m, "PoleBand", 0.75, 0.18, at + Vector3.new(0, y, 0), color, M.Neon, { CanCollide = false })
	end
	disc(m, "Cradle", 1.4, 0.3, at + Vector3.new(0, h + 0.15, 0), dark, M.Metal, { CanCollide = false })
	local gem = part(m, "Gem", Vector3.new(1.1, 1.1, 1.1), CFrame.new(at + Vector3.new(0, h + 1.5, 0)) * CFrame.Angles(math.pi / 4, 0, math.pi / 4), color, M.Neon, ghost())
	gem:SetAttribute("Spin", 50)
	gem:SetAttribute("Bob", 0.25)
	gem:AddTag("BoardEmblem")
	light(gem, color, 18, 1.4)
	m.Parent = parent
	return m
end
local function starCrystal(parent, at: Vector3, scale: number, color: Color3)
	local m = Instance.new("Model")
	m.Name = "StarCrystal"
	-- каменное основание, из которого растут кристаллы (раньше они стояли «в воздухе» на плите)
	disc(m, "CrystalBase", scale * 7, scale * 0.8, at + Vector3.new(0, scale * 0.3, 0), rgb(40, 34, 64), M.Slate)
	for k = 1, 5 do
		local h = scale * rand:NextNumber(5, 11) * (k == 1 and 1.4 or 1)
		local w = scale * rand:NextNumber(1.2, 2)
		local tilt = k == 1 and 0 or rand:NextNumber(0.25, 0.6)
		local dir = rand:NextNumber(0, math.pi * 2)
		local cf = CFrame.new(at) * CFrame.Angles(0, dir, 0) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, h / 2, 0)
		part(m, "Crystal", Vector3.new(w, h, w), cf * CFrame.Angles(0, math.pi / 4, 0), color, M.Glass, { Transparency = 0.2, Reflectance = 0.25, CanCollide = k == 1, CastShadow = false })
		-- остриё — сужение того же цвета (белые кубики-«кончики» выглядели как мусор), внутри светится жила
		part(m, "CrystalTip", Vector3.new(w * 0.55, w * 0.55, w * 0.55), cf * CFrame.new(0, h / 2 + w * 0.12, 0) * CFrame.Angles(0, math.pi / 4, 0) * CFrame.Angles(math.pi / 4, 0, 0), color, M.Glass, { Transparency = 0.2, Reflectance = 0.25, CanCollide = false })
		part(m, "CrystalCore", Vector3.new(w * 0.25, h * 0.8, w * 0.25), cf, color:Lerp(WHITE, 0.25), M.Neon, { CanCollide = false })
	end
	local core = ball(m, "Glow", scale * 2, at + Vector3.new(0, scale * 2, 0), color, M.Neon, { Transparency = 0.6, CanCollide = false })
	light(core, color, 14 * scale, 1.6)
	m.Parent = parent
	return m
end
local function spaceRock(parent, at: Vector3, s: number, floating: boolean)
	local m = Instance.new("Model")
	m.Name = floating and "Asteroid" or "SpaceRock"
	local props = floating and ghost() or nil
	for k = 1, floating and 3 or 2 do
		local d = s * rand:NextNumber(0.6, 1.1)
		local off = k == 1 and Vector3.zero or Vector3.new(rand:NextNumber(-1, 1), rand:NextNumber(-0.5, 0.5), rand:NextNumber(-1, 1)) * s * 0.5
		ball(m, "Stone", d, at + off + Vector3.new(0, floating and 0 or d * 0.25, 0), DEEP:Lerp(rgb(90, 80, 110), rand:NextNumber(0, 0.6)), M.Slate, props)
	end
	if floating then
		ball(m, "Crater", s * 0.35, at + Vector3.new(s * 0.32, s * 0.2, 0), rgb(30, 24, 50), M.Slate, ghost())
	end
	m.Parent = parent
	return m
end
-- Планета: шар, светящаяся атмосфера и (по желанию) кольцо из сегментов.
local function planet(parent, name: string, at: Vector3, d: number, color: Color3, material: Enum.Material, ringColor: Color3?, tilt: number)
	local m = Instance.new("Model")
	m.Name = name
	ball(m, "Body", d, at, color, material, ghost())
	ball(m, "Atmosphere", d * 1.08, at, color:Lerp(WHITE, 0.3), M.ForceField, ghost({ Transparency = 0.3 }))
	-- Полоса-экватор, как у газового гиганта.
	disc(m, "Band", d * 1.005, d * 0.12, at, color:Lerp(rgb(0, 0, 0), 0.25), material, ghost()).CFrame = CFrame.new(at) * CFrame.Angles(tilt, 0, tilt * 0.5) * CFrame.Angles(0, 0, math.pi / 2)
	if ringColor then
		local n = math.clamp(math.floor(d / 6), 18, 48)
		local cf0 = CFrame.new(at) * CFrame.Angles(tilt, 0, tilt * 0.5)
		for band = 0, 1 do
			local r = d * (0.82 + band * 0.2)
			local chord = 2 * r * math.sin(math.pi / n) + 0.3
			for k = 1, n do
				local a = k / n * math.pi * 2
				local cf = cf0 * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -r)
				part(m, "Ring", Vector3.new(chord, 0.2 + d * 0.01, d * 0.17), cf, band == 0 and ringColor or ringColor:Lerp(WHITE, 0.35), M.Neon, ghost({ Transparency = 0.3 + band * 0.2 }))
			end
		end
	end
	m.Parent = parent
	return m
end

-- ===== Центр: звёздный монумент с парящей звездой и орбитами =====
local SX, SZ = 0, -100
local function monument(parent)
	local m = Instance.new("Model")
	m.Name = "StarMonument"
	disc(m, "Base", 70, 2, L(SX, 1, SZ), METAL, M.DiamondPlate)
	disc(m, "BaseGlow", 72, 1, L(SX, 0.5, SZ), CYAN, M.Neon, { CanCollide = false })
	disc(m, "Inner", 52, 1, L(SX, 2.5, SZ), DEEP, M.Glass, { Reflectance = 0.3 })
	disc(m, "InnerRing", 53, 0.6, L(SX, 2.4, SZ), PINK, M.Neon, { CanCollide = false })
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2
		local pos = L(SX + math.cos(a) * 28, 0, SZ + math.sin(a) * 28)
		local col = k % 2 == 0 and CYAN or PINK
		part(m, "Pillar", Vector3.new(3, 18, 3), pos + Vector3.new(0, 11, 0), METAL, M.Metal)
		part(m, "PillarStripe", Vector3.new(3.2, 14, 0.6), pos + Vector3.new(0, 11, 0), col, M.Neon, { CanCollide = false })
		local cap = ball(m, "PillarOrb", 3.4, pos + Vector3.new(0, 21.5, 0), col, M.Neon, { CanCollide = false })
		light(cap, col, 22, 1.8)
	end
	-- Парящая звезда: ядро, ореол и восемь лучей.
	local starAt = L(SX, 34, SZ)
	local core = ball(m, "StarCore", 12, starAt, GOLD, M.Neon, ghost())
	ball(m, "StarHalo", 19, starAt, GOLD:Lerp(WHITE, 0.3), M.ForceField, ghost({ Transparency = 0.3 }))
	for k = 0, 3 do
		local cf = CFrame.new(starAt) * CFrame.Angles(0, 0, k * math.pi / 4)
		part(m, "StarRay", Vector3.new(2.6, 26, 2.6), cf * CFrame.Angles(0, math.pi / 4, 0), GOLD, M.Neon, ghost())
	end
	light(core, GOLD, 70, 3)
	twinkle(core, 20, GOLD)
	-- Две наклонные орбиты с бусинами-спутниками.
	for orbit = 1, 2 do
		local cf0 = CFrame.new(starAt) * CFrame.Angles(orbit == 1 and 0.5 or -0.5, orbit * 0.9, 0)
		local r = 15 + orbit * 3
		local n = 28
		local chord = 2 * r * math.sin(math.pi / n) + 0.2
		for k = 1, n do
			local a = k / n * math.pi * 2
			part(m, "Orbit", Vector3.new(chord, 0.4, 0.8), cf0 * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -r), orbit == 1 and CYAN or PINK, M.Neon, ghost({ Transparency = 0.2 }))
		end
		ball(m, "Satellite", 2.4, (cf0 * CFrame.new(r, 0, 0)).Position, orbit == 1 and CYAN or PINK, M.Neon, ghost())
	end
	m.Parent = parent
	return m
end

-- ===== Космический магазин (структура как у Frozen: Counter, ShopZone, VendorAnchor, Sign) =====
local function shop(parent, at: Vector3, name: string?, title: string?)
	local m = Instance.new("Model")
	m.Name = name or "UpgradeShop"
	disc(m, "Plinth", 22, 0.6, at + Vector3.new(0, 0.3, 2), METAL, M.DiamondPlate)
	disc(m, "PlinthGlow", 22.8, 0.3, at + Vector3.new(0, 0.2, 2), CYAN, M.Neon, { CanCollide = false })
	part(m, "Counter", Vector3.new(14, 4, 3), at + Vector3.new(0, 2.6, -2), DEEP, M.Metal)
	part(m, "CounterTop", Vector3.new(15, 0.8, 4), at + Vector3.new(0, 5, -2), VIOLET, M.Glass, { Transparency = 0.2, Reflectance = 0.2 })
	part(m, "CounterGlow", Vector3.new(14.2, 0.4, 0.4), at + Vector3.new(0, 3.2, -0.45), PINK, M.Neon, { CanCollide = false })
	part(m, "BackWall", Vector3.new(16, 11, 1), at + Vector3.new(0, 6, -6), SPACE, M.Metal)
	for k = 1, 7 do
		ball(m, "WallStar", 0.6 + (k % 3) * 0.3, at + Vector3.new(-6.5 + k * 1.7, 4 + ((k * 37) % 6), -5.4), k % 2 == 0 and CYAN or GOLD, M.Neon, { CanCollide = false })
	end
	for _, sx in ipairs({ -1, 1 }) do
		part(m, "Pillar", Vector3.new(1.6, 14, 1.6), at + Vector3.new(sx * 8, 7.5, 1.5), METAL, M.Metal)
		part(m, "PillarStripe", Vector3.new(1.8, 12, 0.4), at + Vector3.new(sx * 8, 7.5, 2.2), sx < 0 and CYAN or PINK, M.Neon, { CanCollide = false })
		starCrystal(m, at + Vector3.new(sx * 8, 14.5, 1.5), 0.35, sx < 0 and CYAN or PINK)
	end
	for i = 1, 9 do
		local c = i % 2 == 0 and VIOLET or DEEP
		part(m, "Awning", Vector3.new(1.9, 0.6, 11), CFrame.new(at + Vector3.new(-8 + (i - 1) * 2, 14.3, -2)) * CFrame.Angles(math.rad(10), 0, 0), c, M.SmoothPlastic, { CanCollide = false })
		ball(m, "AwningLight", 0.7, at + Vector3.new(-8 + (i - 1) * 2, 13.3, 3.6), i % 2 == 0 and CYAN or PINK, M.Neon, { CanCollide = false })
	end
	sign(m, title or "GALAXY SHOP", Vector3.new(15, 3.6, 0.5), CFrame.new(at + Vector3.new(0, 18.5, -2.6)) * CFrame.Angles(0, math.pi, 0), WHITE, rgb(80, 50, 170))
	local zone = disc(m, "ShopZone", 24, 0.3, at + Vector3.new(0, 0.7, 10), CYAN, M.SmoothPlastic, { Transparency = 0.55, CanCollide = false })
	zone.Size = Vector3.new(0.3, 24, 24)
	part(m, "VendorAnchor", Vector3.new(1, 1, 1), at + Vector3.new(0, 0.6, -5.5), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	m.Parent = parent
	return m
end

-- ===== Неоновая арка-портал =====
local function portalArch(parent, name: string, at: Vector3, yaw: number, targetName: string, fieldColor: Color3)
	local m = Instance.new("Model")
	m.Name = name .. "Arch"
	local rot = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	for i = 0, 16 do
		local a = math.pi * i / 16
		local p = rot * CFrame.new(math.cos(a) * 11, math.sin(a) * 13 + 1, 0)
		part(m, "ArchBlock", Vector3.new(3.4, 3.4, 3.4), p * CFrame.Angles(0, 0, a), i % 2 == 0 and METAL or DEEP, i % 2 == 0 and M.Metal or M.Glass)
		if i % 2 == 1 then
			part(m, "ArchGlow", Vector3.new(3.6, 0.5, 3.6), p * CFrame.Angles(0, 0, a), i % 4 == 1 and CYAN or PINK, M.Neon, { CanCollide = false })
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		lamp(m, (rot * CFrame.new(s * 15, 0, 0)).Position, 8, s < 0 and CYAN or PINK)
		starCrystal(m, (rot * CFrame.new(s * 18, 0, 2)).Position, 0.5, VIOLET)
	end
	local field = part(m, name, Vector3.new(1.5, 19, 19), rot * CFrame.new(0, 6.5, 0) * CFrame.Angles(0, math.pi / 2, 0), fieldColor, M.ForceField, { CanCollide = false, Transparency = 0.15, Shape = Enum.PartType.Cylinder })
	field.CanTouch = true
	local board = sign(m, targetName, Vector3.new(14, 3, 0.5), rot * CFrame.new(0, 17.5, 0) * CFrame.Angles(0, math.pi, 0), WHITE, rgb(150, 45, 20))
	local back = board:FindFirstChildOfClass("SurfaceGui"):Clone() -- надпись видна с обеих сторон
	back.Face = Enum.NormalId.Back
	back.Parent = board
	m.Parent = parent
	return m, field
end

-- ===== Подиум с яйцом =====
local function eggStand(parent, id: number, at: Vector3, color: Color3)
	local stand = Instance.new("Model")
	stand.Name = "EggStand" .. id
	stand.Parent = parent
	local ped = Instance.new("Model")
	ped.Name = "Pedestal"
	ped.Parent = stand
	disc(ped, "Base", 15, 0.5, at + Vector3.new(0, 0.25, 0), METAL, M.DiamondPlate)
	disc(ped, "Rim", 15.6, 0.3, at + Vector3.new(0, 0.4, 0), CYAN, M.Neon, { CanCollide = false })
	local glow = disc(ped, "Glow", 10, 0.2, at + Vector3.new(0, 0.55, 0), color, M.Neon, { CanCollide = false })
	emitter(glow, "Rise", {
		Texture = SPARK_TEX,
		Rate = 10,
		Lifetime = NumberRange.new(1.5, 2.5),
		Speed = NumberRange.new(2, 4),
		EmissionDirection = Enum.NormalId.Right, -- ось диска смотрит вверх
		SpreadAngle = Vector2.new(10, 10),
		Color = ColorSequence.new(color, WHITE),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
	})
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local pos = at + Vector3.new(math.cos(a) * 8.4, 0, math.sin(a) * 8.4)
		local h = 2 + (i % 2) * 1.5
		part(ped, "Shard", Vector3.new(1, h, 1), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, a + math.pi / 4, 0.15), i % 2 == 0 and CYAN or PINK, M.Neon, { CanCollide = false })
	end
	light(glow, color, 16, 1.5)
	part(stand, "Interact", Vector3.new(14, 7, 14), at + Vector3.new(0, 4, 0), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	-- Яйцо из шаров (имя EggDisplay нужно табло и анимациям вылупления).
	local egg = Instance.new("Model")
	egg.Name = "EggDisplay"
	local noHit = { CanCollide = false }
	ball(egg, "Bottom", 5, at + Vector3.new(0, 3.2, 0), color, M.SmoothPlastic, noHit)
	local body = ball(egg, "Body", 4.6, at + Vector3.new(0, 3.9, 0), color, M.SmoothPlastic, noHit)
	ball(egg, "Top", 3.8, at + Vector3.new(0, 5.3, 0), color, M.SmoothPlastic, noHit)
	ball(egg, "Tip", 2.6, at + Vector3.new(0, 6.4, 0), color, M.SmoothPlastic, noHit)
	for k = 1, 5 do
		local a = k / 5 * math.pi * 2
		local y = k % 2 == 0 and 3.6 or 4.8
		local r = k % 2 == 0 and 2.35 or 2.0
		ball(egg, "Spot", 1.1, at + Vector3.new(math.cos(a) * r, y, math.sin(a) * r), color:Lerp(WHITE, 0.55), M.Neon, noHit)
	end
	egg.PrimaryPart = body
	local bbox = egg:GetBoundingBox()
	egg.WorldPivot = CFrame.new(bbox.Position)
	egg.Parent = stand
	part(stand, "SignAnchor", Vector3.new(1, 1, 1), at + Vector3.new(0, 13, 0), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	stand:SetAttribute("EggReady", true)
	return stand
end

-- Невидимые стены по кругу: с платформы не упасть.
local function boundary(parent, radius: number, count: number)
	local m = Instance.new("Model")
	m.Name = "Boundary"
	local w = 2 * math.pi * radius / count + 2
	for k = 1, count do
		local a = k / count * math.pi * 2
		local at = L(math.cos(a) * radius, 150, math.sin(a) * radius)
		part(m, "Wall", Vector3.new(w, 300, 2), CFrame.lookAt(at, L(0, 150, 0)), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = true, CanQuery = false, CanTouch = false, CastShadow = false })
	end
	m.Parent = parent
	return m
end

-- ===== Постройка мира =====
-- Раскладка (относительно Center, Y = 0 — верх платформы), та же, что у Magma Volcano:
--   вход/спавн у портала в Volcano на юге (z = +182), главная дорога на север к площади (0, 10)
--   и звёздному монументу (0, -100); магазины слева (x = -90), яйца справа (z = 70).
function Galaxy.Build(world: Instance): Model
	local model = Instance.new("Model")
	model.Name = "CosmicGalaxy"

	-- Платформа: тёмная плита, металлическая кромка, неоновые кольца, сетка.
	local ground = Instance.new("Model")
	ground.Name = "Ground"
	ground.Parent = model
	-- 2026-11 (фидбэк «переделать общий вид»): вместо чёрной плиты с неоновой сеткой — поверхность
	-- астероида: лиловый лунный грунт, кратеры с каменным валом, светящиеся кристаллические жилы,
	-- россыпь камешков и стелющийся над землёй туман туманности (ниже, после дорожек).
	disc(ground, "Deck", 440, 8, L(0, -4, 0), rgb(84, 72, 124), M.Slate)
	disc(ground, "Rim", 452, 6, L(0, -6, 0), DEEP, M.Rock)
	disc(ground, "RimGlow", 458, 1, L(0, -9, 0), PINK, M.Neon, { CanCollide = false })
	disc(ground, "EdgeGlow", 444, 0.4, L(0, -0.5, 0), CYAN, M.Neon, { CanCollide = false })
	-- Снизу — перевёрнутые скалы-астероиды с кристаллами.
	for k = 1, 18 do
		local a = k / 18 * math.pi * 2 + rand:NextNumber(-0.1, 0.1)
		local r = rand:NextNumber(60, 180)
		local w = rand:NextNumber(40, 70)
		local h = w * rand:NextNumber(0.8, 1.5)
		local spike = pyramid(ground, "Underside", w, h, L(math.cos(a) * r, -8 - h, math.sin(a) * r), DEEP:Lerp(SPACE, rand:NextNumber(0.2, 0.8)), M.Rock, rand:NextNumber(0, 3))
		local center = spike:GetBoundingBox()
		spike:PivotTo(center * CFrame.Angles(math.pi, 0, 0))
		for _, d in ipairs(spike:GetChildren()) do
			(d :: BasePart).CanCollide = false
		end
		if k % 3 == 0 then
			ball(ground, "UnderGlow", rand:NextNumber(6, 10), L(math.cos(a) * r, -10 - h * 0.6, math.sin(a) * r), k % 2 == 0 and CYAN or PINK, M.Neon, ghost({ Transparency = 0.2 }))
		end
	end
	-- Кристаллы по кромке (за невидимой стеной).
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2 + 0.13
		starCrystal(ground, L(math.cos(a) * 222, 0, math.sin(a) * 222), rand:NextNumber(0.7, 1.1), k % 3 == 0 and GOLD or (k % 2 == 0 and CYAN or PINK))
	end
	boundary(model, 214, 48)

	-- Светящиеся дорожки.
	local paths = Instance.new("Model")
	paths.Name = "Paths"
	paths.Parent = model
	-- Мягкий свет вдоль дорожки (не как в Неонграде — тускло, просто чтобы путь «светился»).
	local function softLights(size: Vector3, pos: Vector3, edge: Color3)
		local long = math.max(size.X, size.Z)
		local n = math.max(1, math.floor(long / 26))
		for i = 1, n do
			local t = (i - 0.5) / n - 0.5
			local at = size.Z > size.X and pos + Vector3.new(0, 0.6, t * size.Z) or pos + Vector3.new(t * size.X, 0.6, 0)
			local lamp = part(paths, "PathGlow", Vector3.new(1, 1, 1), at, edge, M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
			local pl = Instance.new("PointLight")
			pl.Color = edge
			pl.Range = 13
			pl.Brightness = 0.55
			pl.Shadows = false
			pl.Parent = lamp
		end
	end
	local function path(name, size: Vector3, pos: Vector3, edge: Color3)
		part(paths, name, size, pos, PATH, M.Glass, { Reflectance = 0.15 })
		softLights(size, pos, edge)
		if size.Z > size.X then
			for _, s in ipairs({ -1, 1 }) do
				part(paths, name .. "Edge", Vector3.new(0.5, size.Y + 0.04, size.Z), pos + Vector3.new(s * (size.X / 2 - 0.25), 0, 0), edge, M.Neon, { CanCollide = false })
			end
		else
			for _, s in ipairs({ -1, 1 }) do
				part(paths, name .. "Edge", Vector3.new(size.X, size.Y + 0.04, 0.5), pos + Vector3.new(0, 0, s * (size.Z / 2 - 0.25)), edge, M.Neon, { CanCollide = false })
			end
		end
	end
	path("PathMain", Vector3.new(18, 0.3, 200), L(0, 0.15, 80), CYAN)
	path("PathShop", Vector3.new(76, 0.3, 14), L(-46, 0.16, 40), PINK)
	path("PathMagnets", Vector3.new(76, 0.3, 14), L(-46, 0.16, 100), PINK)
	path("PathEggs", Vector3.new(156, 0.3, 14), L(82, 0.16, 70), GOLD)
	path("PathMonument", Vector3.new(18, 0.3, 52), L(0, 0.15, -40), CYAN)
	-- Перекрёстки боковых дорожек с главной: неяркие светящиеся круги.
	for _, j in ipairs({ { -9, 40, PINK }, { -9, 100, PINK }, { 9, 70, GOLD }, { 0, -14, CYAN } }) do
		disc(paths, "JunctionGlow", 12, 0.34, L(j[1], 0.17, j[2]), j[3], M.Neon, { CanCollide = false, Transparency = 0.9 })
		local lamp = part(paths, "JunctionLight", Vector3.new(1, 1, 1), L(j[1], 1.5, j[2]), j[3], M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		local pl = Instance.new("PointLight")
		pl.Color = j[3]
		pl.Range = 18
		pl.Brightness = 0.8
		pl.Shadows = false
		pl.Parent = lamp
	end
	disc(paths, "Plaza", 54, 0.32, L(0, 0.16, 10), PATH, M.Glass, { Reflectance = 0.2 })
	disc(paths, "PlazaRing", 56, 0.2, L(0, 0.1, 10), PINK, M.Neon, { CanCollide = false })
	disc(paths, "PlazaStar", 18, 0.34, L(0, 0.17, 10), GOLD, M.Neon, { CanCollide = false, Transparency = 0.3 })

	monument(model)

	-- Занятые места {x, z, радиус}.
	local placedSpots = {
		{ SX, SZ, 40 }, { 0, 10, 28 }, { -90, 40, 16 }, { -90, 100, 16 }, { -90, 52, 13 }, { -90, 112, 13 },
		{ 40, 70, 11 }, { 92, 70, 11 }, { 144, 70, 11 }, { 0, 182, 20 }, { 0, 158, 10 },
	}
	local function onPath(x, z)
		if math.abs(x) < 12 and z > -66 and z < 185 then
			return true
		end
		if math.abs(z - 40) < 10 and x > -88 and x < 0 then
			return true
		end
		if math.abs(z - 100) < 10 and x > -88 and x < 0 then
			return true
		end
		if math.abs(z - 70) < 10 and x > 0 and x < 162 then
			return true
		end
		return false
	end
	local function clear(x, z, r)
		if Vector2.new(x, z).Magnitude > 200 - r then
			return false
		end
		for _, s in ipairs(placedSpots) do
			if Vector2.new(x - s[1], z - s[2]).Magnitude < s[3] + r then
				return false
			end
		end
		return true
	end
	local function free(x, z, r)
		return clear(x, z, r) and not onPath(x, z)
	end

	shop(model, L(-90, 0.3, 40), "UpgradeShop", "GALAXY SHOP")
	shop(model, L(-90, 0.3, 100), "MagnetShop", "GALAXY MAGNETS")

	eggStand(model, 13, L(40, 0, 70), rgb(120, 170, 255))
	eggStand(model, 14, L(92, 0, 70), rgb(220, 110, 230))
	eggStand(model, 15, L(144, 0, 70), rgb(255, 215, 110))

	portalArch(model, "PortalToVolcano", L(0, 0, 182), 0, "MAGMA VOLCANO", rgb(255, 140, 60))

	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model

	-- Светильники вдоль дорог.
	for z = 30, 150, 30 do
		for _, sx in ipairs({ -1, 1 }) do
			lamp(decor, L(sx * 13, 0, z), 8, (z / 30 + (sx > 0 and 1 or 0)) % 2 == 0 and CYAN or PINK)
		end
	end
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		lamp(decor, L(math.cos(a) * 30, 0, 10 + math.sin(a) * 30), 9, k % 2 == 0 and CYAN or PINK)
	end
	for _, x in ipairs({ 66, 118 }) do
		lamp(decor, L(x, 0, 79), 7, GOLD)
	end
	for _, z in ipairs({ 49, 109 }) do
		lamp(decor, L(-60, 0, z), 7, PINK)
	end

	-- Звёздные кристаллы и камни на платформе.
	local palette = { CYAN, PINK, GOLD, VIOLET }
	local count = 0
	for _ = 1, 400 do
		if count >= 18 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(40, 195)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 6) then
			count += 1
			starCrystal(decor, L(x, 0, z), rand:NextNumber(0.6, 1.2), palette[count % #palette + 1])
			table.insert(placedSpots, { x, z, 6 })
		end
	end
	count = 0
	for _ = 1, 400 do
		if count >= 20 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(30, 198)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 4) then
			count += 1
			spaceRock(decor, L(x, 0, z), rand:NextNumber(2.5, 5), false)
			table.insert(placedSpots, { x, z, 4 })
		end
	end

	-- Поверхность астероида: кратеры, жилы, камешки, туман.
	local surface = Instance.new("Model")
	surface.Name = "Surface"
	surface.Parent = model
	count = 0
	for _ = 1, 600 do
		if count >= 14 then
			break
		end
		local d = rand:NextNumber(10, 26)
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(30, 200 - d / 2)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, d / 2 + 2) then
			count += 1
			-- вал кратера: кольцо из глыб, внутри — тёмная чаша с еле светящимся дном
			disc(surface, "CraterFloor", d, 0.2, L(x, 0.02, z), rgb(44, 36, 72), M.Slate, { CanCollide = false })
			disc(surface, "CraterGlow", d * 0.35, 0.22, L(x, 0.03, z), count % 2 == 0 and CYAN or VIOLET, M.Neon, { CanCollide = false, Transparency = 0.45 })
			local n = math.floor(d * 0.9)
			for k = 1, n do
				local ka = k / n * math.pi * 2 + rand:NextNumber(-0.1, 0.1)
				local s = rand:NextNumber(1.6, 3) * d / 18
				part(surface, "CraterRim", Vector3.new(s * 1.6, s * rand:NextNumber(0.5, 0.9), s), CFrame.new(L(x + math.cos(ka) * d / 2, s * 0.15, z + math.sin(ka) * d / 2)) * CFrame.Angles(0, -ka, rand:NextNumber(-0.25, 0.25)), rgb(130, 118, 175):Lerp(rgb(96, 86, 140), rand:NextNumber()), M.Slate, { CanCollide = false })
			end
			table.insert(placedSpots, { x, z, d / 2 + 2 })
		end
	end
	-- светящиеся кристаллические жилы: ломаные трещины в грунте
	for k = 1, 30 do
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(30, 195)
		local p = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local heading = rand:NextNumber(0, math.pi * 2)
		local col = k % 3 == 0 and PINK or (k % 3 == 1 and CYAN or VIOLET)
		for _ = 1, rand:NextInteger(3, 6) do
			heading += rand:NextNumber(-0.6, 0.6)
			local len = rand:NextNumber(3, 7)
			local q = p + Vector3.new(math.cos(heading) * len, 0, math.sin(heading) * len)
			if q.Magnitude > 200 or onPath(q.X, q.Z) or onPath(p.X, p.Z) then
				break
			end
			local mid = (p + q) / 2
			part(surface, "Vein", Vector3.new(0.5, 0.08, len + 0.3), CFrame.lookAt(L(mid.X, 0.04, mid.Z), L(q.X, 0.04, q.Z)), col, M.Neon, ghost({ Transparency = 0 }))
			p = q
		end
	end
	-- россыпь камешков
	for _ = 1, 140 do
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(20, 205)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if not onPath(x, z) then
			local s = rand:NextNumber(0.4, 1.3)
			part(surface, "Pebble", Vector3.new(s * 1.3, s * 0.6, s), CFrame.new(L(x, s * 0.2, z)) * CFrame.Angles(0, rand:NextNumber(0, 6.3), rand:NextNumber(-0.3, 0.3)), rgb(120, 110, 165):Lerp(rgb(80, 70, 120), rand:NextNumber()), M.Slate, ghost())
		end
	end
	-- стелющийся туман туманности
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local fog = part(surface, "NebulaMist", Vector3.new(120, 1, 120), L(math.cos(a) * 110, 1.5, math.sin(a) * 110), WHITE, M.SmoothPlastic, ghost({ Transparency = 1 }))
		emitter(fog, "Mist", {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(k % 2 == 0 and rgb(140, 90, 230) or rgb(90, 140, 240), rgb(200, 110, 220)),
			LightEmission = 0.35,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 16) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(8, 12),
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(80, 80),
			Acceleration = Vector3.new(0.4, 0.05, 0.2),
			RotSpeed = NumberRange.new(-8, 8),
			Rotation = NumberRange.new(0, 360),
			Rate = 4,
		})
	end

	-- Летающие астероиды над платформой (не мешают, сквозь них можно пройти) и пояс астероидов вокруг.
	local sky = Instance.new("Model")
	sky.Name = "Space"
	sky.Parent = model
	for _ = 1, 14 do
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(40, 190)
		spaceRock(sky, L(math.cos(a) * r, rand:NextNumber(28, 70), math.sin(a) * r), rand:NextNumber(3, 7), true)
	end
	for k = 1, 40 do
		local a = k / 40 * math.pi * 2 + rand:NextNumber(-0.05, 0.05)
		local r = rand:NextNumber(255, 300)
		ball(sky, "BeltRock", rand:NextNumber(3, 9), L(math.cos(a) * r, rand:NextNumber(-25, 15), math.sin(a) * r), DEEP:Lerp(rgb(110, 100, 130), rand:NextNumber(0, 0.7)), M.Slate, ghost())
	end

	-- Планеты: огромная окольцованная на фоне и несколько поменьше вокруг.
	planet(sky, "GiantPlanet", L(0, 150, -580), 300, rgb(210, 140, 90), M.Sand, rgb(255, 210, 150), 0.35)
	planet(sky, "PinkPlanet", L(-320, 110, -170), 80, rgb(200, 90, 200), M.SmoothPlastic, PINK, -0.4)
	planet(sky, "BluePlanet", L(330, 170, 60), 60, rgb(70, 130, 240), M.SmoothPlastic, nil, 0.2)
	ball(sky, "Moon", 16, L(285, 205, 20), rgb(200, 200, 215), M.Slate, ghost())
	planet(sky, "IcePlanet", L(-250, 230, 290), 46, rgb(150, 230, 255), M.Glacier, CYAN, 0.6)
	planet(sky, "RedPlanet", L(190, 120, -320), 40, rgb(220, 90, 70), M.Sand, nil, -0.2)
	planet(sky, "TinyPlanet", L(-70, 170, -30), 26, rgb(255, 200, 110), M.SmoothPlastic, GOLD, 0.5)
	planet(sky, "MintPlanet", L(130, 140, 170), 18, rgb(120, 240, 190), M.SmoothPlastic, nil, 0)

	-- Звёздная пыль: мерцание сверху и над платформой.
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		local high = part(sky, "StarField", Vector3.new(260, 1, 260), L(math.cos(a) * 150, 110, math.sin(a) * 150), WHITE, M.SmoothPlastic, ghost({ Transparency = 1 }))
		twinkle(high, 20, k % 2 == 0 and CYAN or PINK, Enum.NormalId.Bottom)
		local low = part(sky, "StarDust", Vector3.new(160, 1, 160), L(math.cos(a) * 90, 1, math.sin(a) * 90), WHITE, M.SmoothPlastic, ghost({ Transparency = 1 }))
		twinkle(low, 8, k % 2 == 0 and GOLD or VIOLET)
	end

	-- Монеты: звезда 19600 / туманность 39200 / космос 78400 (CoinTypes.Worlds.Galaxy). Как у Frozen: Coin_N в модели мира.
	local placed = 0
	for _ = 1, 9000 do
		if placed >= 195 then -- плотность монет как в Sky/Frozen (~1.4 на 1000 кв. стадов)
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), math.sqrt(rand:NextNumber()) * 195
		local x, z = math.cos(a) * r, math.sin(a) * r
		if clear(x, z, 3) then
			placed += 1
			local kind, rarity = CoinTypes.Pick("Galaxy", placed)
			local size = CoinTypes.BaseSize.Galaxy * kind.Scale
			local coin = part(model, "Coin_" .. placed, Vector3.new(0.5, size, size), L(x, 2.6, z), kind.Color, M.Foil, { Shape = Enum.PartType.Cylinder, CanCollide = false })
			CoinTypes.Mark(coin, "Galaxy", kind, rarity)
			CoinTypes.AddGlow(coin, kind.Color, rarity)
			for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
				local gui = Instance.new("SurfaceGui")
				gui.Face = face
				gui.CanvasSize = Vector2.new(100, 100)
				gui.LightInfluence = 0
				local glyph = Instance.new("TextLabel")
				glyph.BackgroundTransparency = 1
				glyph.Size = UDim2.fromScale(1, 1)
				glyph.Text = rarity >= 3 and "✦" or "★"
				glyph.TextScaled = true
				glyph.Font = Enum.Font.GothamBold
				glyph.TextColor3 = Color3.new(1, 1, 1)
				glyph.Parent = gui
				gui.Parent = coin
			end
			table.insert(placedSpots, { x, z, 5 })
		end
	end

	-- Страховка: упавшего возвращаем на вход.
	local net = part(model, "SafetyNet", Vector3.new(900, 2, 900), L(0, -140, 0), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	local spawn = L(0, 4, 158)
	model:SetAttribute("Spawn", spawn)
	net.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and character.PrimaryPart then
			player:SetAttribute("ServerTP", os.clock()) -- серверный телепорт: проверка скачков в GameServer его не наказывает
			character:PivotTo(CFrame.new(spawn))
		end
	end)

	model.Parent = world
	return model
end

-- Портал сюда уже стоит в Magma Volcano (арка PortalToGalaxyArch строится в MagmaVolcano.Build).
function Galaxy.BuildVolcanoPortal(volcanoModel: Model)
	return volcanoModel:FindFirstChild("PortalToGalaxy", true)
end

return Galaxy
