-- Пруд и ручей первого мира: рельеф (вода, песчаный берег, илистое дно) и украшения
-- (камни, камыши, кувшинки, мостик, причал, родник у гор). Строится при запуске сервера.
local Pond = {}

local T = workspace.Terrain
local M = Enum.Material

-- Пруд из нескольких перекрывающихся кругов — получается неровный «живой» берег.
local PONDS = {
	{ -101, -33, 16 },
	{ -88, -25, 12 },
	{ -112, -22, 8 },
	{ -95, -45, 8 },
	{ -80, -36, 6 },
	{ -138, -95, 6 }, -- чаша под водопадом у подножия холма
}
-- Русло ручья от родника у гор к пруду.
local STREAM = {
	Vector3.new(-135, 0, -90),
	Vector3.new(-128, 0, -74),
	Vector3.new(-121, 0, -60),
	Vector3.new(-113, 0, -49),
	Vector3.new(-106, 0, -40),
}
local WATER_TOP = -1

local function streamPoints(step)
	local pts = {}
	for i = 1, #STREAM - 1 do
		local a, b = STREAM[i], STREAM[i + 1]
		local n = math.ceil((b - a).Magnitude / step)
		for k = 0, n - 1 do
			table.insert(pts, a:Lerp(b, k / n))
		end
	end
	table.insert(pts, STREAM[#STREAM])
	return pts
end

function Pond.Terrain()
	-- Под газоном лежит плоская деталь Floor с материалом травы. Над прудом она закрывала воду
	-- (выглядело как зелёная лужайка, по которой можно ходить). Рельеф и так держит игроков,
	-- поэтому деталь делаем невидимой и проходимой.
	local floor = workspace:FindFirstChild("CoinSpeedWorld") and workspace.CoinSpeedWorld:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		floor.Transparency = 1
		floor.CanCollide = false
	end
	local bed = streamPoints(1.5)
	-- Ландшафт хранится вокселями 4×4×4: в одном вокселе один материал, а вода не заливает
	-- клетку, где остался хоть кусочек грунта. Поэтому всё выровнено по сетке: верхняя клетка
	-- газона — от -4 до 0, чашу вычищаем целыми клетками и только потом наливаем воду.
	-- 1. Песчаный берег: верхняя клетка вокруг воды — песок вровень с газоном.
	for _, c in ipairs(PONDS) do
		T:FillCylinder(CFrame.new(c[1], -2, c[2]), 4, c[3] + 4, M.Sand)
	end
	for _, p in ipairs(bed) do
		T:FillCylinder(CFrame.new(p.X, -2, p.Z), 4, 6.5, M.Sand)
	end
	-- 2. Чаша: вычищаем от -8 до +8 (целые клетки), дно — ил.
	for _, c in ipairs(PONDS) do
		T:FillCylinder(CFrame.new(c[1], 0, c[2]), 16, c[3], M.Air)
	end
	for _, p in ipairs(bed) do
		T:FillCylinder(CFrame.new(p.X, 0, p.Z), 16, 3.8, M.Air)
	end
	for _, c in ipairs(PONDS) do
		T:FillCylinder(CFrame.new(c[1], -10, c[2]), 4, c[3], M.Mud)
	end
	for _, p in ipairs(bed) do
		T:FillCylinder(CFrame.new(p.X, -10, p.Z), 4, 3.8, M.Mud)
	end
	-- 3. Вода: верхняя клетка заполнена на 3/4, поверхность чуть ниже берега.
	for _, c in ipairs(PONDS) do
		T:FillCylinder(CFrame.new(c[1], (WATER_TOP - 8) / 2, c[2]), 8 + WATER_TOP, c[3], M.Water)
	end
	for _, p in ipairs(bed) do
		T:FillCylinder(CFrame.new(p.X, (WATER_TOP - 8) / 2, p.Z), 8 + WATER_TOP, 3.8, M.Water)
	end
	-- 4. Доводка: клетки внутри воды, где остался кусочек грунта («островки»), делаем водой.
	local function inside(x, z)
		for _, c in ipairs(PONDS) do
			if (Vector2.new(x - c[1], z - c[2])).Magnitude < c[3] - 1.5 then
				return true
			end
		end
		local q = Vector3.new(x, 0, z)
		for i = 1, #STREAM - 1 do
			local a, b = STREAM[i], STREAM[i + 1]
			local ab = b - a
			local t = math.clamp((q - a):Dot(ab) / ab:Dot(ab), 0, 1)
			if (q - (a + ab * t)).Magnitude < 2.4 then
				return true
			end
		end
		return false
	end
	-- Клетки сетки 4×4: центр клетки x = 4k + 2.
	for x = -174, -54, 4 do
		for z = -142, -6, 4 do
			if inside(x, z) then
				T:FillBlock(CFrame.new(x, 2, z), Vector3.new(4, 12, 4), M.Air)
				T:FillBlock(CFrame.new(x, -10, z), Vector3.new(4, 4, 4), M.Sand)
				T:FillBlock(CFrame.new(x, (WATER_TOP - 8) / 2, z), Vector3.new(4, 8 + WATER_TOP, 4), M.Water)
			end
		end
	end
	T.WaterColor = Color3.fromRGB(40, 140, 175)
	T.WaterTransparency = 0.2
	T.WaterReflectance = 0.5
	T.WaterWaveSize = 0.12
	T.WaterWaveSpeed = 8
	T:SetMaterialColor(M.Sand, Color3.fromRGB(226, 205, 150))
end

-- ===== Украшения =====
local function surfaceY(x, z, withWater)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { T }
	params.IgnoreWater = not withWater
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), params)
	return hit and hit.Position.Y or 0, hit and hit.Material
end

local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or M.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local CYL = Enum.PartType.Cylinder
local UP = CFrame.Angles(0, 0, math.rad(90))

local function rock(parent, rng, pos, scale)
	local cluster = Instance.new("Model")
	cluster.Name = "Rock"
	cluster.Parent = parent
	local grey = { Color3.fromRGB(128, 128, 122), Color3.fromRGB(150, 146, 136), Color3.fromRGB(108, 112, 110) }
	for k = 1, rng:NextInteger(2, 3) do
		local s = scale * rng:NextNumber(0.6, 1)
		local offset = Vector3.new(rng:NextNumber(-0.7, 0.7), 0, rng:NextNumber(-0.7, 0.7)) * scale
		local p = part(cluster, "Stone", Vector3.new(s * 1.4, s, s * 1.1), CFrame.new(pos + offset + Vector3.new(0, s * 0.2, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4)), grey[rng:NextInteger(1, 3)], M.Slate)
		p.CanCollide = s > 1.5
	end
	-- Мох сверху.
	part(cluster, "Moss", Vector3.new(scale * 0.9, 0.15, scale * 0.7), CFrame.new(pos + Vector3.new(0, scale * 0.68, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0.1), Color3.fromRGB(90, 150, 70), M.Grass)
end

local function reeds(parent, rng, pos)
	local m = Instance.new("Model")
	m.Name = "Reeds"
	m.Parent = parent
	for k = 1, rng:NextInteger(5, 8) do
		local h = rng:NextNumber(2.2, 4)
		local base = pos + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		local tilt = CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15))
		local stem = CFrame.new(base) * tilt * CFrame.new(0, h / 2, 0)
		part(m, "Stem", Vector3.new(0.14, h, 0.14), stem, Color3.fromRGB(95, 150, 60), M.Grass)
		if k % 2 == 0 then
			part(m, "Cattail", Vector3.new(0.85, 0.32, 0.32), stem * CFrame.new(0, h / 2 - 0.4, 0) * UP, Color3.fromRGB(120, 78, 45), M.Fabric, CYL)
		else
			part(m, "Leaf", Vector3.new(0.35, h * 0.8, 0.06), CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, 6.28), rng:NextNumber(0.2, 0.45)) * CFrame.new(0, h * 0.4, 0), Color3.fromRGB(110, 170, 70), M.Grass)
		end
	end
end

local function lily(parent, rng, pos, flower)
	local m = Instance.new("Model")
	m.Name = "LilyPad"
	m.Parent = parent
	local d = rng:NextNumber(1.8, 3)
	part(m, "Pad", Vector3.new(0.1, d, d), CFrame.new(pos) * UP * CFrame.Angles(rng:NextNumber(0, 6.28), 0, 0), Color3.fromRGB(70, 160, 70), M.SmoothPlastic, CYL)
	if flower then
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			part(m, "Petal", Vector3.new(0.5, 0.18, 0.28), CFrame.new(pos + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0.25, 0, 0) * CFrame.Angles(0, 0, 0.5), Color3.fromRGB(255, 160, 200), M.SmoothPlastic)
		end
		part(m, "Core", Vector3.new(0.22, 0.22, 0.22), CFrame.new(pos + Vector3.new(0, 0.3, 0)), Color3.fromRGB(255, 220, 90), M.SmoothPlastic, Enum.PartType.Ball)
	end
end

local WOOD = Color3.fromRGB(150, 105, 65)
local WOOD_DARK = Color3.fromRGB(110, 75, 45)

-- Деревянный мостик поперёк ручья (слегка выгнутый).
local function bridge(parent, center, along, span)
	local m = Instance.new("Model")
	m.Name = "Bridge"
	m.Parent = parent
	local across = Vector3.new(-along.Z, 0, along.X)
	local planks = math.floor(span / 0.9)
	for k = 0, planks do
		local t = k / planks - 0.5
		local arch = 1.1 * (1 - (t * 2) ^ 2)
		local pos = center + across * (t * span) + Vector3.new(0, arch, 0)
		local p = part(m, "Plank", Vector3.new(0.8, 0.25, 4.4), CFrame.lookAt(pos, pos + along) * CFrame.Angles(0, math.pi / 2, 0), k % 2 == 0 and WOOD or WOOD:Lerp(WOOD_DARK, 0.3), M.WoodPlanks)
		p.CanCollide = true
		p.CFrame = CFrame.lookAt(pos, pos + across) * CFrame.Angles(0, 0, 0)
		p.Size = Vector3.new(4.4, 0.25, 0.8)
	end
	for _, side in ipairs({ -1, 1 }) do
		local prev
		for k = 0, 4 do
			local t = k / 4 - 0.5
			local arch = 1.1 * (1 - (t * 2) ^ 2)
			local pos = center + across * (t * span) + along * (side * 2.05) + Vector3.new(0, arch, 0)
			part(m, "Post", Vector3.new(0.35, 2.4, 0.35), CFrame.new(pos + Vector3.new(0, 1, 0)), WOOD_DARK, M.Wood)
			local top = pos + Vector3.new(0, 2.15, 0)
			if prev then
				local mid = (prev + top) / 2
				part(m, "Rail", Vector3.new(0.25, 0.25, (top - prev).Magnitude + 0.3), CFrame.lookAt(mid, top), WOOD, M.Wood)
			end
			prev = top
		end
	end
	return m
end

-- Причал в пруд.
local function pier(parent, from, to, waterY)
	local m = Instance.new("Model")
	m.Name = "Pier"
	m.Parent = parent
	local dir = (to - from) * Vector3.new(1, 0, 1)
	local len = dir.Magnitude
	dir = dir.Unit
	local across = Vector3.new(-dir.Z, 0, dir.X)
	local deckY = waterY + 0.9
	local n = math.floor(len / 0.9)
	for k = 0, n do
		local pos = Vector3.new(from.X, deckY, from.Z) + dir * (k * 0.9)
		local p = part(m, "Plank", Vector3.new(4, 0.25, 0.8), CFrame.lookAt(pos, pos + dir), k % 2 == 0 and WOOD or WOOD:Lerp(WOOD_DARK, 0.3), M.WoodPlanks)
		p.CanCollide = true
	end
	for k = 1, 3 do
		for _, side in ipairs({ -1, 1 }) do
			local pos = Vector3.new(from.X, deckY, from.Z) + dir * (len * k / 3) + across * (side * 1.9)
			part(m, "Pile", Vector3.new(2.6, 0.45, 0.45), CFrame.new(pos - Vector3.new(0, 1, 0)) * UP, WOOD_DARK, M.Wood, CYL)
		end
	end
	-- Фонарик в конце причала.
	local tip = Vector3.new(to.X, deckY, to.Z) + across * 1.6
	part(m, "LampPost", Vector3.new(0.3, 3, 0.3), CFrame.new(tip + Vector3.new(0, 1.5, 0)), WOOD_DARK, M.Wood)
	local bulb = part(m, "Lamp", Vector3.new(0.7, 0.7, 0.7), CFrame.new(tip + Vector3.new(0, 3.2, 0)), Color3.fromRGB(255, 220, 150), M.Neon, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 140)
	light.Range = 14
	light.Brightness = 1.2
	light.Parent = bulb
end

-- Водопад в начале ручья: скала из камней, водяная пелена с падающими струями,
-- брызги и пена в чаше внизу. Вода падает с уступа скалы прямо в чашу (не в землю).
local function waterfall(parent, rng, pool, back, waterY)
	local m = Instance.new("Model")
	m.Name = "Waterfall"
	m.Parent = parent
	local side = Vector3.new(-back.Z, 0, back.X)
	local groundY = surfaceY(pool.X + side.X * 11, pool.Z + side.Z * 11, false)
	local lipY = groundY + 11
	local cliff = Vector3.new(pool.X, groundY, pool.Z) + back * 9
	local grey = { Color3.fromRGB(118, 118, 112), Color3.fromRGB(138, 134, 124), Color3.fromRGB(100, 104, 102) }
	local function stone(pos, size)
		local p = part(m, "Cliff", size, CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 6.28), rng:NextNumber(-0.15, 0.15)), grey[rng:NextInteger(1, 3)], M.Slate)
		p.CanCollide = true
		return p
	end
	-- Скала: по бокам от струи высокие глыбы, по центру уступ, с которого падает вода.
	for _, k in ipairs({ -1, 1 }) do
		stone(cliff + side * (k * 6) + Vector3.new(0, 4, 0), Vector3.new(8, 10, 8))
		stone(cliff + side * (k * 5) + back * 2 + Vector3.new(0, 10, 0), Vector3.new(7, 6, 7))
		stone(cliff + side * (k * 9) + Vector3.new(0, 2, 0), Vector3.new(6, 5, 6))
	end
	stone(cliff + back * 2.5 + Vector3.new(0, 4.5, 0), Vector3.new(6, 11, 6))
	stone(cliff + back * 3 + Vector3.new(0, 12, 0), Vector3.new(7, 4, 7))
	-- Уступ (желобок), откуда течёт вода.
	local lip = Vector3.new(pool.X, lipY, pool.Z) + back * 5.6
	part(m, "Lip", Vector3.new(4.6, 0.6, 3), CFrame.lookAt(lip, lip - back), Color3.fromRGB(105, 105, 100), M.Slate).CanCollide = true
	part(m, "LipWater", Vector3.new(3.8, 0.2, 3), CFrame.lookAt(lip + Vector3.new(0, 0.35, 0), lip + Vector3.new(0, 0.35, 0) - back), Color3.fromRGB(150, 210, 240), M.Glass).Transparency = 0.3
	-- Пелена воды от уступа до поверхности чаши.
	local top = lip - back * 1.6 + Vector3.new(0, 0.3, 0)
	local bottom = Vector3.new(top.X, waterY + 0.1, top.Z) - back * 0.6
	local height = top.Y - bottom.Y
	local mid = (top + bottom) / 2
	local sheet = part(m, "FallSheet", Vector3.new(3.6, height, 0.5), CFrame.lookAt(mid, mid - back), Color3.fromRGB(170, 225, 250), M.Glass)
	sheet.Transparency = 0.35
	local inner = part(m, "FallCore", Vector3.new(2.6, height, 0.3), CFrame.lookAt(mid, mid - back), Color3.fromRGB(225, 245, 255), M.SmoothPlastic)
	inner.Transparency = 0.45
	-- Падающие струи и капли.
	local drops = Instance.new("ParticleEmitter")
	drops.Name = "Streaks"
	drops.Texture = "rbxasset://textures/particles/smoke_main.dds"
	drops.Color = ColorSequence.new(Color3.fromRGB(235, 250, 255))
	drops.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.7) })
	drops.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.9) })
	drops.Lifetime = NumberRange.new(height / 26)
	drops.Rate = 70
	drops.Speed = NumberRange.new(24, 28)
	drops.EmissionDirection = Enum.NormalId.Bottom
	drops.Shape = Enum.ParticleEmitterShape.Box
	drops.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	drops.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	drops.SpreadAngle = Vector2.new(3, 3)
	drops.Parent = part(m, "DropSource", Vector3.new(3.4, 0.2, 0.4), CFrame.lookAt(top, top - back), Color3.new(1, 1, 1), M.SmoothPlastic)
	drops.Parent.Transparency = 1
	-- Брызги и пена внизу.
	local splashPos = bottom - back * 0.4
	local foam = part(m, "Foam", Vector3.new(0.15, 6.5, 6.5), CFrame.new(splashPos + Vector3.new(0, 0.05, 0)) * UP, Color3.fromRGB(240, 250, 255), M.SmoothPlastic, CYL)
	foam.Transparency = 0.45
	local splash = Instance.new("ParticleEmitter")
	splash.Name = "Splash"
	splash.Texture = "rbxasset://textures/particles/smoke_main.dds"
	splash.Color = ColorSequence.new(Color3.fromRGB(245, 252, 255))
	splash.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	splash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3.2) })
	splash.Lifetime = NumberRange.new(0.8, 1.4)
	splash.Rate = 22
	splash.Speed = NumberRange.new(3, 6)
	splash.SpreadAngle = Vector2.new(60, 60)
	splash.Acceleration = Vector3.new(0, -4, 0)
	splash.EmissionDirection = Enum.NormalId.Right -- ось цилиндра смотрит вверх
	splash.Parent = foam
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CastShadow = p.Name == "Cliff"
		end
	end
end

function Pond.Decorate(world)
	local old = world:FindFirstChild("PondDecor")
	if old then
		old:Destroy()
	end
	local decor = Instance.new("Folder")
	decor.Name = "PondDecor"
	decor.Parent = world
	local rng = Random.new(20261102)
	local waterY = surfaceY(PONDS[1][1], PONDS[1][2], true)

	-- Камни и камыши по краю пруда (только там, где берег, а не вода).
	for i, c in ipairs(PONDS) do
		local count = math.floor(c[3] * 0.9)
		for k = 1, count do
			local a = k / count * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
			local r = c[3] + rng:NextNumber(0.5, 2.5)
			local x, z = c[1] + math.cos(a) * r, c[2] + math.sin(a) * r
			local y, mat = surfaceY(x, z, true)
			if mat ~= M.Water then
				if k % 3 == 0 then
					rock(decor, rng, Vector3.new(x, y - 0.3, z), rng:NextNumber(1.2, 2.6))
				elseif k % 3 == 1 then
					reeds(decor, rng, Vector3.new(x, y - 0.4, z))
				end
			end
		end
	end
	-- Кувшинки на воде.
	for k = 1, 16 do
		local c = PONDS[rng:NextInteger(1, 3)]
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(2, c[3] - 2.5)
		local x, z = c[1] + math.cos(a) * r, c[2] + math.sin(a) * r
		local y, mat = surfaceY(x, z, true)
		if mat == M.Water then
			lily(decor, rng, Vector3.new(x, y + 0.04, z), k % 3 == 0)
		end
	end
	-- Камни и камыши вдоль ручья.
	local pts = streamPoints(6)
	for i, p in ipairs(pts) do
		local nextP = pts[math.min(i + 1, #pts)]
		local dir = (nextP - p).Magnitude > 0.1 and (nextP - p).Unit or Vector3.new(0, 0, 1)
		local side = Vector3.new(-dir.Z, 0, dir.X) * (i % 2 == 0 and 1 or -1)
		local pos = p + side * rng:NextNumber(4.6, 5.8)
		local y = surfaceY(pos.X, pos.Z, false)
		if i % 3 == 0 then
			reeds(decor, rng, Vector3.new(pos.X, y - 0.3, pos.Z))
		else
			rock(decor, rng, Vector3.new(pos.X, y - 0.3, pos.Z), rng:NextNumber(0.9, 1.8))
		end
	end
	-- Мостик через середину ручья.
	local a, b = STREAM[2], STREAM[3]
	local mid = (a + b) / 2
	local bankY = surfaceY(mid.X + (b - a).Unit.Z * 7, mid.Z - (b - a).Unit.X * 7, false)
	bridge(decor, Vector3.new(mid.X, bankY + 0.1, mid.Z), (b - a).Unit, 13)
	-- Причал с восточного берега к середине пруда.
	local shore = Vector3.new(-70, 0, -30)
	pier(decor, shore, Vector3.new(-84, 0, -28), waterY)
	-- Водопад над чашей в начале ручья.
	local poolC = PONDS[#PONDS]
	local pool = Vector3.new(poolC[1], 0, poolC[2])
	local back = ((STREAM[1] - STREAM[2]) * Vector3.new(1, 0, 1)).Unit
	waterfall(decor, rng, pool, back, surfaceY(pool.X, pool.Z, true))
	-- Светлячки над водой вечером.
	local fireflies = part(decor, "Fireflies", Vector3.new(30, 1, 30), CFrame.new(PONDS[1][1] + 6, waterY + 2.5, PONDS[1][2] + 4), Color3.new(1, 1, 1), M.SmoothPlastic)
	fireflies.Transparency = 1
	local ff = Instance.new("ParticleEmitter")
	ff.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	ff.Color = ColorSequence.new(Color3.fromRGB(255, 240, 140))
	ff.LightEmission = 1
	ff.Size = NumberSequence.new(0.25)
	ff.Lifetime = NumberRange.new(3, 5)
	ff.Rate = 4
	ff.Speed = NumberRange.new(0.3, 0.8)
	ff.SpreadAngle = Vector2.new(180, 180)
	ff.Parent = fireflies
	return decor
end

return Pond
