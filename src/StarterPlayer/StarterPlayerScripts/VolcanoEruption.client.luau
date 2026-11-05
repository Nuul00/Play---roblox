-- Живой вулкан Magma Volcano (только на клиенте, только пока игрок в вулкане):
-- * в кратере светится озеро лавы, над ним жар и дым;
-- * из кратера по склонам стекают лавовые потоки — светящиеся ленты лежат прямо на поверхности
--   горы и «текут» (бегущая текстура), у подножия растекаются;
-- * каждые 9–16 с извержение: выброс лавовых бомб и искр, клуб дыма, вспышка света.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local volcanoWorld = world:WaitForChild("MagmaVolcano", 120)
if not volcanoWorld then
	return
end
local mountain = volcanoWorld:WaitForChild("Volcano", 60)
if not mountain then
	return
end
local model = mountain:WaitForChild("TripoModel", 30) or mountain
-- части модели приходят на клиент не сразу: ждём, пока появится сама гора
local function partCount()
	local n = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end
for _ = 1, 60 do
	if partCount() > 0 then
		break
	end
	task.wait(1)
end
if partCount() == 0 then
	return
end

local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local LAVA = Color3.fromRGB(255, 110, 25)
local HOT = Color3.fromRGB(255, 200, 70)

local folder = Instance.new("Folder")
folder.Name = "VolcanoEruption"

-- Поверхность горы ищем лучами по самой модели: на клиенте временно разрешаем по ней запросы.
local meshes = {}
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then
		table.insert(meshes, d)
	end
end
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = meshes
local ground = volcanoWorld:FindFirstChild("Ground")
local rpGround = RaycastParams.new()
rpGround.FilterType = Enum.RaycastFilterType.Include
rpGround.FilterDescendantsInstances = { ground or volcanoWorld }

local cf, ext = model:GetBoundingBox()
local center = cf.Position
local topY = center.Y + ext.Y / 2
local baseY = center.Y - ext.Y / 2
local R = math.max(ext.X, ext.Z) / 2
if R < 5 or ext.Y < 5 then
	return -- модель не та или ещё пустая: без вулкана эффектов не строим
end

local function anchorPart(pos: Vector3, name: string)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Parent = folder
	return p
end

local function build()
	local saved = {}
	for _, m in ipairs(meshes) do
		saved[m] = m.CanQuery
		m.CanQuery = true
	end
	-- кратер: верхняя точка у центра горы
	local craterHit = workspace:Raycast(Vector3.new(center.X, topY + 40, center.Z), Vector3.new(0, -ext.Y - 80, 0), rp)
	local crater = craterHit and craterHit.Position or Vector3.new(center.X, topY - 4, center.Z)
	-- радиус кратера: идём от центра, пока поверхность не начнёт уходить вниз
	local rimR = R * 0.12
	for i = 1, 18 do
		local r = R * (0.03 + i * 0.02)
		local h = workspace:Raycast(Vector3.new(center.X + r, topY + 40, center.Z), Vector3.new(0, -ext.Y - 80, 0), rp)
		if h and h.Position.Y < crater.Y - 6 then
			rimR = r
			break
		end
	end

	-- озеро лавы и жар в кратере
	local lake = Instance.new("Part")
	lake.Name = "CraterLake"
	lake.Shape = Enum.PartType.Cylinder
	lake.Anchored, lake.CanCollide, lake.CanQuery, lake.CanTouch, lake.CastShadow = true, false, false, false, false
	lake.Material = Enum.Material.Neon
	lake.Color = LAVA
	lake.Size = Vector3.new(0.6, rimR * 1.7, rimR * 1.7)
	lake.CFrame = CFrame.new(crater + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	lake.Parent = folder
	local vent = anchorPart(crater + Vector3.new(0, 2, 0), "Vent")
	local light = Instance.new("PointLight")
	light.Color = LAVA
	light.Range = 60
	light.Brightness = 3
	light.Parent = vent
	local glow = Instance.new("ParticleEmitter")
	glow.Name = "Heat"
	glow.Texture = FIRE
	glow.Color = ColorSequence.new(HOT, LAVA)
	glow.LightEmission = 1
	glow.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, rimR * 0.5), NumberSequenceKeypoint.new(1, rimR * 0.9) })
	glow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	glow.Lifetime = NumberRange.new(1, 1.8)
	glow.Speed = NumberRange.new(3, 6)
	glow.Rate = 10
	glow.EmissionDirection = Enum.NormalId.Top
	glow.Parent = vent
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = SMOKE
	smoke.Color = ColorSequence.new(Color3.fromRGB(80, 70, 70), Color3.fromRGB(30, 28, 30))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 40) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(7, 11)
	smoke.Speed = NumberRange.new(7, 12)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Acceleration = Vector3.new(2, 1, 0)
	smoke.RotSpeed = NumberRange.new(-15, 15)
	smoke.Rate = 6
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = vent
	local bombs = Instance.new("ParticleEmitter")
	bombs.Name = "LavaBombs"
	bombs.Texture = FIRE
	bombs.Color = ColorSequence.new(HOT, Color3.fromRGB(200, 50, 15))
	bombs.LightEmission = 1
	bombs.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.6), NumberSequenceKeypoint.new(1, 1.2) })
	bombs.Lifetime = NumberRange.new(3, 4.5)
	bombs.Speed = NumberRange.new(35, 55)
	bombs.SpreadAngle = Vector2.new(28, 28)
	bombs.Acceleration = Vector3.new(0, -30, 0)
	bombs.Rate = 0
	bombs.EmissionDirection = Enum.NormalId.Top
	bombs.Parent = vent
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Texture = SPARK
	sparks.Color = ColorSequence.new(HOT, LAVA)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(2, 3.5)
	sparks.Speed = NumberRange.new(20, 40)
	sparks.SpreadAngle = Vector2.new(35, 35)
	sparks.Acceleration = Vector3.new(0, -16, 0)
	sparks.Rate = 8
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Parent = vent

	-- лавовые потоки: 6 направлений, точки по поверхности горы от края кратера до подножия
	local rng = Random.new(5)
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local pts = {}
		local steps = 22
		for i = 0, steps do
			local r = rimR * 0.9 + (R * 1.05 - rimR * 0.9) * i / steps
			local wob = math.sin(i * 0.7 + k) * 0.06
			local dir = Vector3.new(math.cos(a + wob), 0, math.sin(a + wob))
			local x = center + dir * r
			local h = workspace:Raycast(Vector3.new(x.X, topY + 40, x.Z), Vector3.new(0, -ext.Y - 120, 0), rp)
			local g = workspace:Raycast(Vector3.new(x.X, topY + 40, x.Z), Vector3.new(0, -ext.Y - 120, 0), rpGround)
			local best = h
			if g and (not best or g.Position.Y > best.Position.Y) then
				best = g
			end
			if best then
				table.insert(pts, { pos = best.Position + best.Normal * 0.35, normal = best.Normal })
			end
			if best and best.Position.Y < baseY + 1.5 and i > 3 then
				break -- дошли до подножия
			end
		end
		local atts = {}
		for i, pt in ipairs(pts) do
			local nextPt = pts[i + 1] or pts[i - 1]
			local along = nextPt and (nextPt.pos - pt.pos) or Vector3.new(1, 0, 0)
			if i == #pts and pts[i - 1] then
				along = pt.pos - pts[i - 1].pos
			end
			local n = pt.normal
			local x = (along - n * along:Dot(n))
			x = x.Magnitude > 0.01 and x.Unit or Vector3.new(1, 0, 0)
			local holder = anchorPart(pt.pos, "FlowPoint")
			local att = Instance.new("Attachment")
			att.Parent = holder
			att.WorldCFrame = CFrame.fromMatrix(pt.pos, x, n)
			atts[i] = att
		end
		for i = 1, #atts - 1 do
			local t = (i - 1) / math.max(#atts - 2, 1)
			for layer = 1, 2 do
				local b = Instance.new("Beam")
				b.Name = "LavaFlow"
				b.Attachment0, b.Attachment1 = atts[i], atts[i + 1]
				local w = (5 + t * 7) * (layer == 1 and 1 or 0.55)
				b.Width0, b.Width1 = w, w + 0.4
				b.FaceCamera = false
				b.Segments = 4
				if layer == 2 then
					-- верхний слой с бегущей текстурой: лава течёт вниз, от кратера
					b.Texture = FIRE
					b.TextureMode = Enum.TextureMode.Stretch
					b.TextureLength = 1
					b.TextureSpeed = -0.5
				end
				b.LightEmission = 1
				b.LightInfluence = 0
				b.Brightness = layer == 1 and 2 or 4
				b.Color = layer == 1 and ColorSequence.new(LAVA, Color3.fromRGB(220, 60, 15)) or ColorSequence.new(HOT)
				b.Transparency = NumberSequence.new(layer == 1 and 0 or 0.2)
				b.ZOffset = layer
				b.Parent = atts[i].Parent
			end
			if i % 5 == 0 then
				local l = Instance.new("PointLight")
				l.Color = LAVA
				l.Range = 14
				l.Brightness = 1.6
				l.Parent = atts[i].Parent
			end
		end
		-- у подножия поток растекается: лужица лавы с дымком
		local last = pts[#pts]
		if last then
			local pool = Instance.new("Part")
			pool.Name = "LavaPool"
			pool.Shape = Enum.PartType.Cylinder
			pool.Anchored, pool.CanCollide, pool.CanQuery, pool.CanTouch, pool.CastShadow = true, false, false, false, false
			pool.Material = Enum.Material.Neon
			pool.Color = Color3.fromRGB(230, 75, 20)
			pool.Size = Vector3.new(0.3, 11, 9)
			pool.CFrame = CFrame.new(last.pos + Vector3.new(0, -0.15, 0)) * CFrame.Angles(0, a, math.pi / 2)
			pool.Parent = folder
		end
	end
	for m, v in pairs(saved) do
		m.CanQuery = v
	end
	return vent, light, bombs, sparks, smoke
end

local ok, vent, light, bombs, sparks, smoke = pcall(build)
if not ok then
	warn("[VolcanoEruption]", vent)
	return
end

local inside = false
local gen = 0
local function onWorld()
	local now = player:GetAttribute("CurrentWorld") == "Magma Volcano"
	if now == inside then
		return
	end
	inside = now
	folder.Parent = inside and workspace or nil
	gen += 1
	local my = gen
	if inside then
		task.spawn(function()
			while inside and gen == my do -- быстрый выход/вход не запускает второй цикл
				task.wait(math.random(9, 16))
				if not inside or gen ~= my then
					break
				end
				-- извержение
				bombs:Emit(26)
				sparks:Emit(80)
				smoke:Emit(8)
				TweenService:Create(light, TweenInfo.new(0.2), { Brightness = 9, Range = 110 }):Play()
				task.wait(0.4)
				TweenService:Create(light, TweenInfo.new(2.5), { Brightness = 3, Range = 60 }):Play()
			end
		end)
	end
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
onWorld()
