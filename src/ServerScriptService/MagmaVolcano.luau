-- Пятый мир Magma Volcano: базальтовое плато вокруг огромного вулкана, лавовые реки и озёра,
-- обсидиановые кристаллы, факелы, мёртвые деревья и вулканический магазин. Строится кодом (как Frozen Peaks).
-- Монеты Coin_N с атрибутами из CoinTypes собирает GameServer; магазины UpgradeShop/MagnetShop (ShopZone) — тоже он.
-- Порталы: PortalToFrozen (назад в Frozen Peaks) и PortalToGalaxy (вперёд в Cosmic Galaxy).
-- BuildFrozenPortal ставит арку PortalToVolcano в мире Frozen Peaks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoinTypes = require(ReplicatedStorage:WaitForChild("CoinTypes"))

local Volcano = {}
Volcano.Center = Vector3.new(6000, 60, 0)
local C = Volcano.Center
local M = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local BASALT = rgb(52, 46, 48)
local BASALT_LIGHT = rgb(88, 78, 76)
local OBSIDIAN = rgb(28, 20, 34)
local ASH = rgb(70, 64, 62)
local LAVA = rgb(255, 120, 30)
local LAVA_HOT = rgb(255, 190, 70)
local LAVA_DARK = rgb(200, 50, 20)
local IRON = rgb(60, 50, 46)
local WHITE = rgb(255, 255, 255)
local rand = Random.new(6060)

local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
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
-- Пирамида из четырёх угловых клиньев: скалы и пики.
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
	s.Color = rgb(70, 20, 10)
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
-- Пламя: огненные частицы вверх.
local function flames(parent: Instance, size: number)
	return emitter(parent, "Fire", {
		Texture = FIRE_TEX,
		Rate = 18,
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(12, 12),
		EmissionDirection = Enum.NormalId.Top,
		LightEmission = 1,
		Color = ColorSequence.new(LAVA_HOT, LAVA_DARK),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.2) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		RotSpeed = NumberRange.new(-60, 60),
		Rotation = NumberRange.new(0, 360),
	})
end
-- Искры-угольки, медленно поднимающиеся над площадью детали.
local function embers(parent: Instance, rate: number)
	return emitter(parent, "Embers", {
		Texture = SPARK_TEX,
		Rate = rate,
		Lifetime = NumberRange.new(3, 6),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, 1, 0),
		LightEmission = 1,
		Color = ColorSequence.new(LAVA_HOT, LAVA_DARK),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
	})
end

-- ===== Декор =====
local function torch(parent, at: Vector3, h: number)
	local m = Instance.new("Model")
	m.Name = "Torch"
	part(m, "Pole", Vector3.new(1.2, h, 1.2), at + Vector3.new(0, h / 2, 0), OBSIDIAN, M.Basalt)
	disc(m, "Bowl", 3.2, 1, at + Vector3.new(0, h + 0.5, 0), IRON, M.CorrodedMetal)
	local flame = ball(m, "Flame", 1.8, at + Vector3.new(0, h + 1.5, 0), LAVA, M.Neon, { CanCollide = false })
	flames(flame, 1.6)
	light(flame, rgb(255, 140, 60), 20, 2)
	m.Parent = parent
	return m
end
local function rock(parent, at: Vector3, s: number, color: Color3?)
	local m = Instance.new("Model")
	m.Name = "Rock"
	for k = 1, 3 do
		local w = s * rand:NextNumber(0.6, 1.1)
		local cf = CFrame.new(at + Vector3.new(rand:NextNumber(-s, s) * 0.5, w * 0.3, rand:NextNumber(-s, s) * 0.5)) * CFrame.Angles(rand:NextNumber(0, 1), rand:NextNumber(0, 6.3), rand:NextNumber(0, 1))
		part(m, "Stone", Vector3.new(w, w * rand:NextNumber(0.5, 0.9), w * rand:NextNumber(0.7, 1.2)), cf, (color or BASALT):Lerp(OBSIDIAN, rand:NextNumber(0, 0.5)), k == 1 and M.Basalt or M.Slate)
	end
	m.Parent = parent
	return m
end
-- Обсидиановые кристаллы с раскалёнными кончиками.
local function obsidian(parent, at: Vector3, scale: number, glow: Color3)
	local m = Instance.new("Model")
	m.Name = "ObsidianCluster"
	for k = 1, 4 do
		local h = scale * rand:NextNumber(5, 10) * (k == 1 and 1.4 or 1)
		local w = scale * rand:NextNumber(1.3, 2.1)
		local tilt = k == 1 and 0 or rand:NextNumber(0.25, 0.6)
		local dir = rand:NextNumber(0, math.pi * 2)
		local cf = CFrame.new(at) * CFrame.Angles(0, dir, 0) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, h / 2, 0)
		part(m, "Shard", Vector3.new(w, h, w), cf * CFrame.Angles(0, math.pi / 4, 0), OBSIDIAN, M.Glass, { Reflectance = 0.15, CanCollide = k == 1 })
		part(m, "ShardTip", Vector3.new(w * 0.7, w * 0.9, w * 0.7), cf * CFrame.new(0, h / 2 + w * 0.3, 0) * CFrame.Angles(0, math.pi / 4, math.pi / 4), glow, M.Neon, { CanCollide = false })
	end
	local core = ball(m, "Glow", scale * 2, at + Vector3.new(0, scale * 1.5, 0), glow, M.Neon, { Transparency = 0.6, CanCollide = false })
	light(core, glow, 12 * scale, 1.5)
	m.Parent = parent
	return m
end
local function deadTree(parent, at: Vector3, h: number)
	local m = Instance.new("Model")
	m.Name = "DeadTree"
	local base = CFrame.new(at) * CFrame.Angles(0, rand:NextNumber(0, 6.3), rand:NextNumber(-0.12, 0.12))
	local wood = rgb(45, 34, 30)
	part(m, "Trunk", Vector3.new(1.6, h, 1.6), base * CFrame.new(0, h / 2, 0), wood, M.Wood)
	for k = 1, 4 do
		local len = h * rand:NextNumber(0.3, 0.45)
		local cf = base * CFrame.new(0, h * (0.45 + k * 0.12), 0) * CFrame.Angles(0, k * 2.2, 0) * CFrame.Angles(0, 0, -rand:NextNumber(0.6, 1.1)) * CFrame.new(0, len / 2, 0)
		part(m, "Branch", Vector3.new(0.7, len, 0.7), cf, wood, M.Wood, { CanCollide = false })
		-- Тлеющий кончик ветки.
		if k % 2 == 0 then
			ball(m, "Ember", 0.6, (cf * CFrame.new(0, len / 2, 0)).Position, LAVA, M.Neon, { CanCollide = false })
		end
	end
	m.Parent = parent
	return m
end
-- Лавовая река: ломаная из светящихся сегментов с тёмным берегом. Не опасна, просто декор.
local function lavaRiver(parent, points: { Vector3 }, width: number, spots)
	local m = Instance.new("Model")
	m.Name = "LavaRiver"
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local len = (b - a).Magnitude + width * 0.6
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(L(mid.X, 0, mid.Z), L(b.X, 0, b.Z))
		part(m, "Bank", Vector3.new(width + 5, 0.16, len + 3), cf * CFrame.new(0, 0.08, 0), rgb(60, 32, 26), M.CrackedLava, { CanCollide = false })
		part(m, "Lava", Vector3.new(width, 0.25, len), cf * CFrame.new(0, 0.14, 0), i % 2 == 0 and LAVA or LAVA:Lerp(LAVA_HOT, 0.3), M.Neon, { CanCollide = false })
		table.insert(spots, { a.X, a.Z, width / 2 + 4 })
	end
	local last = points[#points]
	table.insert(spots, { last.X, last.Z, width / 2 + 4 })
	-- Свет и угольки над серединой реки.
	local mid = points[math.ceil(#points / 2)]
	local glow = part(m, "RiverGlow", Vector3.new(30, 0.2, 30), L(mid.X, 0.3, mid.Z), LAVA, M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	light(glow, LAVA, 40, 2)
	embers(glow, 6)
	m.Parent = parent
	return m
end
local function lavaPool(parent, x: number, z: number, d: number, spots)
	local m = Instance.new("Model")
	m.Name = "LavaPool"
	disc(m, "Shore", d + 8, 0.2, L(x, 0.1, z), rgb(60, 32, 26), M.CrackedLava, { CanCollide = false })
	local lava = disc(m, "Lava", d, 0.3, L(x, 0.18, z), LAVA, M.Neon, { CanCollide = false })
	disc(m, "HotCore", d * 0.45, 0.32, L(x, 0.22, z), LAVA_HOT, M.Neon, { CanCollide = false })
	light(lava, LAVA, d * 1.4, 2.5)
	embers(lava, 5)
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2 + rand:NextNumber(-0.3, 0.3)
		rock(m, L(x + math.cos(a) * (d / 2 + 4), 0, z + math.sin(a) * (d / 2 + 4)), rand:NextNumber(2, 4))
	end
	table.insert(spots, { x, z, d / 2 + 6 })
	m.Parent = parent
	return m
end

-- ===== Вулкан в центре: ярусы-цилиндры, обшитые клиньями — получается конус =====
local VX, VZ = 0, -110
local TIERS = { 75, 64, 54, 45, 37, 30, 25 }
local TIER_H = 11
local function volcano(parent)
	local m = Instance.new("Model")
	m.Name = "Volcano"
	local function slope(rInner: number, rOuter: number, y0: number, n: number, color: Color3)
		local run = rOuter - rInner
		local w = 2 * math.pi * rOuter / n * 1.08
		for k = 1, n do
			local a = (k + 0.5 * (y0 / TIER_H % 2)) / n * math.pi * 2
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local pos = L(VX, y0 + TIER_H / 2, VZ) + dir * (rInner + run / 2)
			part(m, "Slope", Vector3.new(w, TIER_H, run), CFrame.lookAt(pos, pos + dir), color, M.Basalt, { Class = "WedgePart" })
		end
	end
	for i, r in ipairs(TIERS) do
		local y0 = (i - 1) * TIER_H
		disc(m, "Tier", r * 2, TIER_H, L(VX, y0 + TIER_H / 2, VZ), BASALT:Lerp(OBSIDIAN, i / #TIERS * 0.6), M.Basalt)
		local outer = i == 1 and r + 14 or TIERS[i - 1]
		slope(r, outer, y0, 22, BASALT:Lerp(OBSIDIAN, i / #TIERS * 0.5))
	end
	-- Лавовые потоки по склонам: от кратера вниз по каждому ярусу.
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + 0.2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		for i = #TIERS, 1, -1 do
			local rTop = TIERS[i]
			local rBot = i == 1 and rTop + 14 or TIERS[i - 1]
			local yTop = i * TIER_H
			local yBot = (i - 1) * TIER_H
			local pTop = L(VX, yTop, VZ) + dir * rTop
			local pBot = L(VX, yBot, VZ) + dir * rBot
			local cf = CFrame.lookAt((pTop + pBot) / 2, pTop)
			local width = 2.2 + (k % 3) * 0.8 + (#TIERS - i) * 0.15
			part(m, "LavaStreak", Vector3.new(width, 0.4, (pTop - pBot).Magnitude + 1), cf * CFrame.new(0, 0.35, 0), k % 2 == 0 and LAVA or LAVA_DARK, M.Neon, { CanCollide = false })
		end
	end
	-- Кратер: кольцо камней и озеро лавы на вершине, дым и свет.
	local topY = #TIERS * TIER_H
	local rTop = TIERS[#TIERS]
	for k = 1, 14 do
		local a = k / 14 * math.pi * 2
		local pos = L(VX + math.cos(a) * (rTop - 2.5), topY + 2, VZ + math.sin(a) * (rTop - 2.5))
		part(m, "CraterRim", Vector3.new(7, 5 + (k % 3), 6), CFrame.lookAt(pos, L(VX, topY + 2, VZ)) * CFrame.Angles(0.15, 0, 0), OBSIDIAN, M.Basalt)
	end
	disc(m, "CraterLava", rTop * 2 - 8, 0.6, L(VX, topY + 0.4, VZ), LAVA, M.Neon, { CanCollide = false })
	disc(m, "CraterCore", rTop, 0.7, L(VX, topY + 0.5, VZ), LAVA_HOT, M.Neon, { CanCollide = false })
	local vent = part(m, "CraterVent", Vector3.new(30, 1, 30), L(VX, topY + 1, VZ), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	emitter(vent, "Smoke", {
		Texture = SMOKE_TEX,
		Rate = 14,
		Lifetime = NumberRange.new(6, 10),
		Speed = NumberRange.new(6, 10),
		SpreadAngle = Vector2.new(18, 18),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(2, 1.5, 0),
		Color = ColorSequence.new(rgb(90, 80, 80), rgb(40, 36, 38)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 30) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-20, 20),
	})
	emitter(vent, "Sparks", {
		Texture = SPARK_TEX,
		Rate = 25,
		Lifetime = NumberRange.new(2, 3.5),
		Speed = NumberRange.new(18, 30),
		SpreadAngle = Vector2.new(30, 30),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -14, 0),
		LightEmission = 1,
		Color = ColorSequence.new(LAVA_HOT, LAVA_DARK),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.1) }),
	})
	flames(vent, 6).Rate = 30
	light(vent, LAVA, 60, 4)
	m.Parent = parent
	return m
end

-- ===== Вулканический магазин (структура как у Frozen: Counter, ShopZone, VendorAnchor, Sign) =====
local function shop(parent, at: Vector3, name: string?, title: string?)
	local m = Instance.new("Model")
	m.Name = name or "UpgradeShop"
	disc(m, "Plinth", 22, 0.6, at + Vector3.new(0, 0.3, 2), BASALT_LIGHT, M.Basalt)
	disc(m, "PlinthGlow", 22.8, 0.3, at + Vector3.new(0, 0.2, 2), LAVA, M.Neon, { CanCollide = false })
	part(m, "Counter", Vector3.new(14, 4, 3), at + Vector3.new(0, 2.6, -2), OBSIDIAN, M.Basalt)
	part(m, "CounterTop", Vector3.new(15, 0.8, 4), at + Vector3.new(0, 5, -2), IRON, M.CorrodedMetal)
	part(m, "CounterGlow", Vector3.new(14.2, 0.4, 0.4), at + Vector3.new(0, 3.2, -0.45), LAVA, M.Neon, { CanCollide = false })
	part(m, "BackWall", Vector3.new(16, 11, 1), at + Vector3.new(0, 6, -6), rgb(70, 34, 26), M.CrackedLava)
	for _, sx in ipairs({ -1, 1 }) do
		part(m, "Pillar", Vector3.new(1.8, 14, 1.8), at + Vector3.new(sx * 8, 7.5, 1.5), OBSIDIAN, M.Basalt)
		disc(m, "PillarBowl", 3, 0.8, at + Vector3.new(sx * 8, 14.8, 1.5), IRON, M.CorrodedMetal)
		local flame = ball(m, "PillarFlame", 1.6, at + Vector3.new(sx * 8, 15.8, 1.5), LAVA, M.Neon, { CanCollide = false })
		flames(flame, 1.4)
		light(flame, rgb(255, 140, 60), 16, 1.8)
	end
	for i = 1, 9 do
		local c = i % 2 == 0 and rgb(200, 60, 30) or rgb(45, 34, 34)
		part(m, "Awning", Vector3.new(1.9, 0.6, 11), CFrame.new(at + Vector3.new(-8 + (i - 1) * 2, 14.3, -2)) * CFrame.Angles(math.rad(10), 0, 0), c, M.Fabric, { CanCollide = false })
		-- Капли лавы по краю навеса.
		local len = 1.2 + (i % 3) * 0.7
		part(m, "LavaDrip", Vector3.new(0.5, len, 0.5), at + Vector3.new(-8 + (i - 1) * 2, 13.6 - len / 2, 3.6), LAVA, M.Neon, { CanCollide = false })
	end
	sign(m, title or "VOLCANO SHOP", Vector3.new(15, 3.6, 0.5), CFrame.new(at + Vector3.new(0, 18.5, -2.6)) * CFrame.Angles(0, math.pi, 0), WHITE, rgb(170, 50, 20))
	local zone = disc(m, "ShopZone", 24, 0.3, at + Vector3.new(0, 0.7, 10), rgb(255, 150, 70), M.SmoothPlastic, { Transparency = 0.55, CanCollide = false })
	zone.Size = Vector3.new(0.3, 24, 24)
	part(m, "VendorAnchor", Vector3.new(1, 1, 1), at + Vector3.new(0, 0.6, -5.5), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	m.Parent = parent
	return m
end

-- ===== Базальтовая арка-портал =====
local function portalArch(parent, name: string, at: Vector3, yaw: number, targetName: string, fieldColor: Color3)
	local m = Instance.new("Model")
	m.Name = name .. "Arch"
	local rot = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	for i = 0, 16 do
		local a = math.pi * i / 16
		local p = rot * CFrame.new(math.cos(a) * 11, math.sin(a) * 13 + 1, 0)
		part(m, "ArchBlock", Vector3.new(3.4, 3.4, 3.4), p * CFrame.Angles(0, 0, a), i % 2 == 0 and OBSIDIAN or BASALT_LIGHT, i % 2 == 0 and M.Basalt or M.Slate)
		if i % 4 == 2 then
			part(m, "ArchGlow", Vector3.new(3.6, 0.5, 3.6), p * CFrame.Angles(0, 0, a), LAVA, M.Neon, { CanCollide = false })
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		torch(m, (rot * CFrame.new(s * 15, 0, 0)).Position, 7)
		obsidian(m, (rot * CFrame.new(s * 18, 0, 2)).Position, 0.5, LAVA)
	end
	-- Круглое поле портала (цилиндр, ось — поперёк арки), нижняя часть уходит под землю.
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
	disc(ped, "Base", 15, 0.5, at + Vector3.new(0, 0.25, 0), BASALT_LIGHT, M.Basalt)
	disc(ped, "Rim", 15.6, 0.3, at + Vector3.new(0, 0.4, 0), LAVA, M.Neon, { CanCollide = false })
	local glow = disc(ped, "Glow", 10, 0.2, at + Vector3.new(0, 0.55, 0), color, M.Neon, { CanCollide = false })
	emitter(glow, "Rise", {
		Texture = SPARK_TEX,
		Rate = 10,
		Lifetime = NumberRange.new(1.5, 2.5),
		Speed = NumberRange.new(2, 4),
		EmissionDirection = Enum.NormalId.Right, -- ось диска смотрит вверх
		SpreadAngle = Vector2.new(10, 10),
		Color = ColorSequence.new(color, LAVA_HOT),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
	})
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local pos = at + Vector3.new(math.cos(a) * 8.4, 0, math.sin(a) * 8.4)
		local h = 2 + (i % 2) * 1.5
		part(ped, "Spike", Vector3.new(1.2, h, 1.2), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, a, 0.15), OBSIDIAN, M.Glass, { Reflectance = 0.15, CanCollide = false })
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
		ball(egg, "Spot", 1.1, at + Vector3.new(math.cos(a) * r, y, math.sin(a) * r), color:Lerp(LAVA_HOT, 0.5), M.Neon, noHit)
	end
	egg.PrimaryPart = body
	local bbox = egg:GetBoundingBox()
	egg.WorldPivot = CFrame.new(bbox.Position)
	egg.Parent = stand
	part(stand, "SignAnchor", Vector3.new(1, 1, 1), at + Vector3.new(0, 13, 0), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	stand:SetAttribute("EggReady", true)
	return stand
end

-- Невидимые стены по кругу: с плато не упасть.
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
-- Раскладка (относительно Center, Y = 0 — верх земли):
--   вход/спавн у портала в Frozen на юге (z = +182), главная дорога на север к площади (0, 10)
--   и вулкану (0, -110); магазины слева (x = -90), яйца справа (z = 70), портал в Galaxy на востоке.
function Volcano.Build(world: Instance): Model
	local model = Instance.new("Model")
	model.Name = "MagmaVolcano"

	-- Плато: базальтовая плита, кромка из треснувшей лавы, светящийся край и лавовое море внизу.
	local ground = Instance.new("Model")
	ground.Name = "Ground"
	ground.Parent = model
	disc(ground, "Deck", 440, 8, L(0, -4, 0), BASALT, M.Basalt)
	disc(ground, "Rim", 452, 6, L(0, -6, 0), rgb(70, 34, 26), M.CrackedLava)
	disc(ground, "RimGlow", 458, 1, L(0, -9, 0), LAVA, M.Neon, { CanCollide = false })
	disc(ground, "LavaSea", 1100, 2, L(0, -60, 0), LAVA_DARK, M.Neon, { CanCollide = false, CanQuery = false, CanTouch = false })
	-- Снизу плато — перевёрнутые базальтовые пики.
	for k = 1, 18 do
		local a = k / 18 * math.pi * 2 + rand:NextNumber(-0.1, 0.1)
		local r = rand:NextNumber(60, 180)
		local w = rand:NextNumber(40, 70)
		local h = w * rand:NextNumber(0.8, 1.4)
		local spike = pyramid(ground, "Underside", w, h, L(math.cos(a) * r, -8 - h, math.sin(a) * r), BASALT:Lerp(OBSIDIAN, rand:NextNumber(0.2, 0.7)), M.Basalt, rand:NextNumber(0, 3))
		local center = spike:GetBoundingBox()
		spike:PivotTo(center * CFrame.Angles(math.pi, 0, 0))
		for _, d in ipairs(spike:GetChildren()) do
			(d :: BasePart).CanCollide = false
		end
	end
	-- Зубцы скал по краю и стекающая лава.
	for k = 1, 30 do
		local a = k / 30 * math.pi * 2 + rand:NextNumber(-0.05, 0.05)
		local r = rand:NextNumber(219, 225)
		local w = rand:NextNumber(10, 18)
		pyramid(ground, "EdgeCrag", w, w * rand:NextNumber(0.8, 1.6), L(math.cos(a) * r, -1, math.sin(a) * r), BASALT:Lerp(OBSIDIAN, rand:NextNumber(0, 0.6)), M.Basalt, rand:NextNumber(0, 3))
		if k % 2 == 0 then
			local len = rand:NextNumber(10, 30)
			part(ground, "LavaFall", Vector3.new(2, len, 1.2), L(math.cos(a + 0.1) * 226.5, -8 - len / 2, math.sin(a + 0.1) * 226.5), LAVA, M.Neon, { CanCollide = false, CanQuery = false })
		end
	end
	boundary(model, 214, 48)

	-- Дорожки из светлого базальта.
	local paths = Instance.new("Model")
	paths.Name = "Paths"
	paths.Parent = model
	part(paths, "PathMain", Vector3.new(18, 0.3, 200), L(0, 0.15, 80), BASALT_LIGHT, M.Slate)
	part(paths, "PathShop", Vector3.new(76, 0.3, 14), L(-46, 0.16, 40), BASALT_LIGHT, M.Slate)
	part(paths, "PathMagnets", Vector3.new(76, 0.3, 14), L(-46, 0.16, 100), BASALT_LIGHT, M.Slate)
	part(paths, "PathEggs", Vector3.new(156, 0.3, 14), L(82, 0.16, 70), BASALT_LIGHT, M.Slate)
	part(paths, "PathGalaxy", Vector3.new(142, 0.3, 14), L(95, 0.16, 10), BASALT_LIGHT, M.Slate)
	disc(paths, "Plaza", 54, 0.32, L(0, 0.16, 10), BASALT_LIGHT:Lerp(ASH, 0.3), M.Slate)
	disc(paths, "PlazaRing", 56, 0.2, L(0, 0.1, 10), LAVA, M.Neon, { CanCollide = false })
	-- Светящиеся трещины по краям главной дороги.
	for _, sx in ipairs({ -1, 1 }) do
		part(paths, "PathGlow", Vector3.new(0.5, 0.32, 160), L(sx * 9.2, 0.15, 100), LAVA_DARK, M.Neon, { CanCollide = false })
	end

	volcano(model)

	-- Занятые места {x, z, радиус}: вулкан, площадь, магазины, подиумы, порталы, спавн.
	local placedSpots = {
		{ VX, VZ, 92 }, { 0, 10, 28 }, { -90, 40, 16 }, { -90, 100, 16 }, { -90, 52, 13 }, { -90, 112, 13 },
		{ 40, 70, 11 }, { 92, 70, 11 }, { 144, 70, 11 }, { 0, 182, 20 }, { 172, 10, 20 }, { 0, 158, 10 },
	}
	local function onPath(x, z)
		if math.abs(x) < 12 and z > -25 and z < 185 then
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
		if math.abs(z - 10) < 10 and x > 0 and x < 170 then
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

	-- Магазины слева от дороги.
	shop(model, L(-90, 0.3, 40), "UpgradeShop", "VOLCANO SHOP")
	shop(model, L(-90, 0.3, 100), "MagnetShop", "VOLCANO MAGNETS")

	-- Подиумы с яйцами справа от дороги.
	eggStand(model, 10, L(40, 0, 70), rgb(255, 120, 40))
	eggStand(model, 11, L(92, 0, 70), rgb(230, 60, 30))
	eggStand(model, 12, L(144, 0, 70), rgb(130, 60, 190))

	-- Порталы: назад в Frozen Peaks (у спавна) и дальше в Cosmic Galaxy (восток).
	portalArch(model, "PortalToFrozen", L(0, 0, 182), 0, "FROZEN PEAKS", rgb(170, 210, 255))
	portalArch(model, "PortalToGalaxy", L(172, 0, 10), math.pi / 2, "COSMIC GALAXY", rgb(170, 120, 255))

	-- Лава: две реки от подножия вулкана к краю и несколько озёр.
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model
	local function river(x0, z0, x1, z1, wiggle, n)
		local pts = {}
		for i = 0, n do
			local t = i / n
			local x = x0 + (x1 - x0) * t
			local z = z0 + (z1 - z0) * t + math.sin(t * math.pi * 3) * wiggle
			table.insert(pts, Vector3.new(x, 0, z))
		end
		return pts
	end
	lavaRiver(decor, river(-80, -95, -205, -50, 10, 8), 7, placedSpots)
	lavaRiver(decor, river(78, -130, 200, -75, 9, 8), 7, placedSpots)
	lavaRiver(decor, river(-50, -170, -110, -175, 6, 4), 5, placedSpots)
	lavaPool(decor, -150, -10, 30, placedSpots)
	lavaPool(decor, 130, -95, 26, placedSpots)
	lavaPool(decor, 70, 140, 22, placedSpots)
	lavaPool(decor, -130, 140, 24, placedSpots)

	-- Факелы вдоль главной дороги, у площади и к подиумам.
	for z = 30, 150, 30 do
		for _, sx in ipairs({ -1, 1 }) do
			torch(decor, L(sx * 13, 0, z), 7)
		end
	end
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		torch(decor, L(math.cos(a) * 30, 0, 10 + math.sin(a) * 30), 8)
	end
	for _, x in ipairs({ 66, 118 }) do
		torch(decor, L(x, 0, 79), 6)
		torch(decor, L(x, 0, 19), 6)
	end
	for _, z in ipairs({ 49, 109 }) do
		torch(decor, L(-60, 0, z), 6)
	end

	-- Обсидиановые кристаллы, мёртвые деревья, валуны.
	local glows = { LAVA, rgb(255, 70, 40), rgb(170, 80, 255) }
	local count = 0
	for _ = 1, 400 do
		if count >= 16 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(40, 195)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 6) then
			count += 1
			obsidian(decor, L(x, 0, z), rand:NextNumber(0.7, 1.3), glows[count % #glows + 1])
			table.insert(placedSpots, { x, z, 6 })
		end
	end
	count = 0
	for _ = 1, 400 do
		if count >= 18 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(40, 195)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 6) then
			count += 1
			deadTree(decor, L(x, 0, z), rand:NextNumber(12, 20))
			table.insert(placedSpots, { x, z, 6 })
		end
	end
	count = 0
	for _ = 1, 500 do
		if count >= 30 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(30, 198)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 4) then
			count += 1
			rock(decor, L(x, 0, z), rand:NextNumber(2.5, 6))
			table.insert(placedSpots, { x, z, 4 })
		end
	end
	-- Угольки в воздухе по всему плато.
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		local e = part(decor, "EmberField", Vector3.new(160, 1, 160), L(math.cos(a) * 90, 1, math.sin(a) * 90), WHITE, M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		embers(e, 12)
	end

	-- Монеты: угли 2800 / магма 5600 / обсидиан 11200 (CoinTypes.Worlds.Volcano). Как у Frozen: Coin_N в модели мира.
	local placed = 0
	for _ = 1, 4000 do
		if placed >= 70 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), math.sqrt(rand:NextNumber()) * 195
		local x, z = math.cos(a) * r, math.sin(a) * r
		if clear(x, z, 3) then
			placed += 1
			local kind, rarity = CoinTypes.Pick("Volcano", placed)
			local size = CoinTypes.BaseSize.Volcano * kind.Scale
			local coin = part(model, "Coin_" .. placed, Vector3.new(0.5, size, size), L(x, 2.6, z), kind.Color, M.Foil, { Shape = Enum.PartType.Cylinder, CanCollide = false })
			CoinTypes.Mark(coin, "Volcano", kind, rarity)
			CoinTypes.AddGlow(coin, kind.Color, rarity)
			for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
				local gui = Instance.new("SurfaceGui")
				gui.Face = face
				gui.CanvasSize = Vector2.new(100, 100)
				gui.LightInfluence = 0
				local glyph = Instance.new("TextLabel")
				glyph.BackgroundTransparency = 1
				glyph.Size = UDim2.fromScale(1, 1)
				glyph.Text = rarity >= 3 and "✦" or "✹"
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
			character:PivotTo(CFrame.new(spawn))
		end
	end)

	model.Parent = world
	return model
end

-- Портал в Magma Volcano в мире Frozen Peaks: на свободном месте справа от входа,
-- арка смотрит на центр острова. Ёлки/кристаллы, случайно попавшие на это место, убираем.
function Volcano.BuildFrozenPortal(frozenModel: Model)
	local center = Vector3.new(3000, 60, 0)
	local ground = frozenModel:FindFirstChild("Ground")
	local deck = ground and ground:FindFirstChild("Deck")
	if deck and deck:IsA("BasePart") then
		center = Vector3.new(deck.Position.X, deck.Position.Y + deck.Size.X / 2, deck.Position.Z)
	end
	local at = center + Vector3.new(100, 0, 110)
	local decor = frozenModel:FindFirstChild("Decor")
	if decor then
		for _, d in ipairs(decor:GetChildren()) do
			if d:IsA("Model") then
				local cf = d:GetBoundingBox()
				local flat = Vector2.new(cf.Position.X - at.X, cf.Position.Z - at.Z)
				if flat.Magnitude < 22 then
					d:Destroy()
				end
			end
		end
	end
	local dx, dz = at.X - center.X, at.Z - center.Z
	local yaw = math.atan2(dx, dz) -- ось прохода (локальная Z) направлена на центр
	local _, field = portalArch(frozenModel, "PortalToVolcano", at, yaw, "MAGMA VOLCANO", rgb(255, 140, 60))
	return field
end

return Volcano
