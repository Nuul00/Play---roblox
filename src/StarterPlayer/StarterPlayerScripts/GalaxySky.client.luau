-- Живое небо Cosmic Galaxy (фидбэк 2026-11: «космос живёт своей жизнью»). Только на клиенте и
-- только пока игрок в Галактике:
-- * кольца планет вращаются, по ним бегут пульсирующие волны свечения;
-- * звёзды мерцают, на небе созвездия с тонкими светящимися линиями, далёкие туманности;
-- * ракеты летают между планетами: взлёт, перелёт по дуге, посадка, стоянка, снова взлёт;
-- * спутники кружат по орбитам с мигающими огнями, летающая тарелка бродит с лучом;
-- * астероиды с огненным хвостом врезаются в планеты — вспышка, взрыв, ударная волна;
-- * падающие звёзды чертят небо.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local galaxy = world:WaitForChild("CosmicGalaxy", 120)
if not galaxy then
	return
end
local space = galaxy:WaitForChild("Space", 60)
if not space then
	return
end
task.wait(2)

local CENTER = Vector3.new(7500, 60, 0)
local rgb = Color3.fromRGB
local CYAN, PINK, GOLD, VIOLET, WHITE = rgb(100, 220, 255), rgb(230, 110, 230), rgb(255, 215, 110), rgb(150, 100, 255), rgb(255, 255, 255)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local rng = Random.new()

local folder = Instance.new("Folder")
folder.Name = "GalaxySky"

local function mk(name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.Neon
	if shape then
		p.Shape = shape
	end
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- ===== Планеты: центр, радиус и кольца =====
local planets = {}
local rings = {} -- { parts, base, center, axis, speed }
for _, m in ipairs(space:GetChildren()) do
	local body = m:IsA("Model") and m:FindFirstChild("Body")
	if body and body:IsA("BasePart") then
		local pl = { name = m.Name, center = body.Position, r = body.Size.X / 2 }
		table.insert(planets, pl)
		local parts, base = {}, {}
		local axis
		for _, d in ipairs(m:GetChildren()) do
			if d.Name == "Ring" and d:IsA("BasePart") then
				table.insert(parts, d)
				table.insert(base, d.CFrame)
				axis = axis or d.CFrame.UpVector
			end
		end
		if #parts > 0 then
			local baseT = {}
			for i, p in ipairs(parts) do
				baseT[i] = p.Transparency
			end
			table.insert(rings, { parts = parts, base = base, baseT = baseT, baseC = parts[1].Color, center = pl.center, axis = axis, speed = (0.06 + rng:NextNumber(0, 0.06)) * (rng:NextNumber() < 0.5 and -1 or 1), frames = table.create(#parts) })
		end
	elseif m:IsA("BasePart") and m.Name == "Moon" then
		table.insert(planets, { name = "Moon", center = m.Position, r = m.Size.X / 2 })
	end
end
if #planets < 2 then
	return
end

-- ===== Звёзды и созвездия =====
local stars = {}
local SKY_R = 800
local function skyPoint(dir: Vector3)
	return CENTER + dir.Unit * SKY_R
end
for _ = 1, 260 do
	local d = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.05, 1), rng:NextNumber(-1, 1))
	local s = rng:NextNumber(2, 5.5)
	local col = ({ WHITE, WHITE, WHITE, rgb(190, 220, 255), rgb(255, 220, 230), rgb(255, 240, 200) })[rng:NextInteger(1, 6)]
	local p = mk("Star", Vector3.new(s, s, s), CFrame.new(skyPoint(d)), col, Enum.Material.Neon, Enum.PartType.Ball)
	p.Parent = folder
	table.insert(stars, { part = p, ph = rng:NextNumber(0, 6.28), f = rng:NextNumber(0.6, 2.4), tw = rng:NextNumber() < 0.45 })
end
-- созвездия: узор в плоскости неба (u, v) + линии-лучи между звёздами
local CONSTELLATIONS = {
	{ dir = Vector3.new(0.3, 0.7, -0.6), pts = { { 0, 0 }, { 1, 0.15 }, { 2, 0.1 }, { 3, 0.4 }, { 3.6, 1.3 }, { 4.8, 1.2 }, { 4.9, 0.25 } }, lines = { { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 7 }, { 7, 4 } } }, -- ковш
	{ dir = Vector3.new(-0.6, 0.6, -0.4), pts = { { 0, 0 }, { 1, 1 }, { 2, 0.2 }, { 3, 1.1 }, { 4, 0 } }, lines = { { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 } } }, -- «W»
	{ dir = Vector3.new(0.7, 0.55, 0.3), pts = { { 0, 0 }, { 0, 2 }, { 0.9, 3 }, { -0.9, 3 }, { 0, 4.2 }, { 1.4, 1 }, { -1.4, 1 } }, lines = { { 1, 2 }, { 2, 3 }, { 2, 4 }, { 3, 5 }, { 4, 5 }, { 1, 6 }, { 1, 7 } } }, -- «ракета»
	{ dir = Vector3.new(-0.4, 0.8, 0.5), pts = { { 0, 0 }, { 1.2, 0.6 }, { 2.4, 0 }, { 1.2, -1.4 }, { 1.2, 2.2 } }, lines = { { 1, 2 }, { 2, 3 }, { 2, 4 }, { 2, 5 } } }, -- «крест»
	{ dir = Vector3.new(0.05, 0.9, 0.45), pts = { { 0, 0 }, { 0.8, 0.8 }, { 1.8, 0.9 }, { 2.6, 0.2 }, { 1.8, -0.6 }, { 0.8, -0.5 } }, lines = { { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 1 } } }, -- кольцо
}
local beams = {}
for ci, c in ipairs(CONSTELLATIONS) do
	local n = c.dir.Unit
	local u = n:Cross(Vector3.yAxis)
	if u.Magnitude < 0.1 then
		u = Vector3.xAxis
	end
	u = u.Unit
	local v = u:Cross(n).Unit
	local scale = 55
	local atts = {}
	local col = ({ CYAN, PINK, GOLD, VIOLET, CYAN })[ci]
	for i, p in ipairs(c.pts) do
		local pos = CENTER + n * SKY_R + (u * p[1] + v * p[2]) * scale
		local star = mk("ConstStar", Vector3.new(8, 8, 8), CFrame.new(pos), WHITE:Lerp(col, 0.25), Enum.Material.Neon, Enum.PartType.Ball)
		star.Parent = folder
		table.insert(stars, { part = star, ph = rng:NextNumber(0, 6.28), f = 0.8, tw = true, big = true })
		local a = Instance.new("Attachment")
		a.Parent = star
		atts[i] = a
	end
	for _, l in ipairs(c.lines) do
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = atts[l[1]], atts[l[2]]
		b.Width0, b.Width1 = 1.6, 1.6
		b.FaceCamera = true
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Color = ColorSequence.new(col)
		b.Transparency = NumberSequence.new(0.5)
		b.Segments = 1
		b.Parent = atts[l[1]].Parent
		table.insert(beams, { beam = b, ph = ci * 1.3 })
	end
end
-- туманности: огромные мягкие цветные облака далеко в небе
local nebulae = {}
for k, d in ipairs({ Vector3.new(-0.8, 0.35, -0.5), Vector3.new(0.6, 0.4, -0.7), Vector3.new(0.9, 0.25, 0.4), Vector3.new(-0.5, 0.45, 0.8), Vector3.new(0.1, 0.95, -0.2) }) do
	local p = mk("Nebula", Vector3.new(1, 1, 1), CFrame.new(CENTER + d.Unit * (SKY_R * 0.95)), WHITE)
	p.Transparency = 1
	p.Parent = folder
	local cols = { { PINK, VIOLET }, { CYAN, VIOLET }, { GOLD, PINK }, { VIOLET, CYAN }, { PINK, CYAN } }
	local e = emitter(p, {
		Texture = SMOKE,
		Color = ColorSequence.new(cols[k][1], cols[k][2]),
		LightEmission = 0.8,
		LightInfluence = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 220), NumberSequenceKeypoint.new(1, 320) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.72), NumberSequenceKeypoint.new(0.7, 0.75), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(30, 40),
		Speed = NumberRange.new(0, 0.5),
		RotSpeed = NumberRange.new(-2, 2),
		Rotation = NumberRange.new(0, 360),
		Rate = 0.25,
		LockedToPart = true,
	})
	table.insert(nebulae, e)
end

-- ===== Модели: ракета, спутник, тарелка (детали + смещения от «центра» модели) =====
local function model(spec)
	local parts, offs = {}, {}
	for _, s in ipairs(spec) do
		local p = mk(s[1], s[2], CFrame.new(), s[3], s[4] or Enum.Material.SmoothPlastic, s[6])
		p.Parent = folder
		table.insert(parts, p)
		table.insert(offs, s[5])
	end
	return { parts = parts, offs = offs, frames = table.create(#parts) }
end
local function place(m, cf: CFrame)
	for i, o in ipairs(m.offs) do
		m.frames[i] = cf * o
	end
	workspace:BulkMoveTo(m.parts, m.frames, Enum.BulkMoveMode.FireCFrameChanged)
end
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local function rocketModel(trim: Color3)
	-- ось ракеты — +Y (нос вверх); у цилиндров ось X, поэтому повёрнуты на 90° вокруг Z
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local spec = {
		{ "RocketBody", Vector3.new(9, 3.2, 3.2), WHITE, Enum.Material.SmoothPlastic, CFrame.new(0, 0, 0) * up, CYL },
		{ "RocketBand", Vector3.new(1, 3.35, 3.35), trim, Enum.Material.Neon, CFrame.new(0, 2.6, 0) * up, CYL },
		{ "RocketNose", Vector3.new(3.2, 3.2, 3.2), trim, Enum.Material.SmoothPlastic, CFrame.new(0, 4.4, 0), BALL },
		{ "RocketTip", Vector3.new(1.6, 1.6, 1.6), trim, Enum.Material.SmoothPlastic, CFrame.new(0, 5.9, 0), BALL },
		{ "RocketWindow", Vector3.new(0.4, 1.4, 1.4), CYAN, Enum.Material.Neon, CFrame.new(0, 1.2, -1.5) * CFrame.Angles(0, math.pi / 2, 0), CYL },
		{ "RocketNozzle", Vector3.new(1.4, 2.4, 2.4), rgb(70, 70, 90), Enum.Material.Metal, CFrame.new(0, -5, 0) * up, CYL },
	}
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		table.insert(spec, { "RocketFin", Vector3.new(0.3, 3.4, 2.2), trim, Enum.Material.SmoothPlastic, CFrame.Angles(0, a, 0) * CFrame.new(0, -3.4, 2) * CFrame.Angles(-0.35, 0, 0) })
	end
	local m = model(spec)
	-- пламя и шлейф из сопла
	local nozzle = m.parts[6]
	local fire = emitter(nozzle, {
		Texture = FIRE,
		Color = ColorSequence.new(rgb(255, 230, 140), rgb(255, 90, 30)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 0.4) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.25, 0.45),
		Speed = NumberRange.new(14, 20),
		EmissionDirection = Enum.NormalId.Left, -- ось цилиндра X; «вниз» ракеты — −X
		Rate = 60,
	})
	local smoke = emitter(nozzle, {
		Texture = SMOKE,
		Color = ColorSequence.new(rgb(230, 220, 255), rgb(140, 120, 200)),
		LightEmission = 0.3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(1.2, 2),
		Speed = NumberRange.new(4, 8),
		EmissionDirection = Enum.NormalId.Left,
		Rate = 18,
	})
	local glow = Instance.new("PointLight")
	glow.Color = rgb(255, 160, 80)
	glow.Range = 25
	glow.Brightness = 3
	glow.Parent = nozzle
	m.fire, m.smoke, m.glow = fire, smoke, glow
	return m
end
local function satelliteModel(col: Color3)
	local m = model({
		{ "SatBody", Vector3.new(2.6, 2.6, 3.4), rgb(210, 210, 225), Enum.Material.Metal, CFrame.new() },
		{ "SatPanelL", Vector3.new(7, 0.2, 2.6), rgb(40, 70, 170), Enum.Material.Glass, CFrame.new(-5, 0, 0) },
		{ "SatPanelR", Vector3.new(7, 0.2, 2.6), rgb(40, 70, 170), Enum.Material.Glass, CFrame.new(5, 0, 0) },
		{ "SatDish", Vector3.new(0.3, 2.6, 2.6), WHITE, Enum.Material.SmoothPlastic, CFrame.new(0, 0, -2.2) * CFrame.Angles(0, math.pi / 2, 0), CYL },
		{ "SatBlink", Vector3.new(0.8, 0.8, 0.8), col, Enum.Material.Neon, CFrame.new(0, 1.7, 0), BALL },
	})
	return m
end
local function ufoModel()
	local m = model({
		{ "UfoDisc", Vector3.new(1.4, 16, 16), rgb(170, 175, 200), Enum.Material.Metal, CFrame.Angles(0, 0, math.pi / 2), CYL },
		{ "UfoRim", Vector3.new(0.5, 17, 17), CYAN, Enum.Material.Neon, CFrame.Angles(0, 0, math.pi / 2), CYL },
		{ "UfoDome", Vector3.new(7, 7, 7), rgb(120, 230, 200), Enum.Material.Glass, CFrame.new(0, 1.4, 0), BALL },
		{ "UfoBelly", Vector3.new(0.6, 6, 6), PINK, Enum.Material.Neon, CFrame.new(0, -0.9, 0) * CFrame.Angles(0, 0, math.pi / 2), CYL },
	})
	m.parts[3].Transparency = 0.35
	-- луч вниз
	local a0 = Instance.new("Attachment")
	a0.Parent = m.parts[4]
	local tgt = mk("UfoBeamEnd", Vector3.new(0.2, 0.2, 0.2), CFrame.new(), WHITE)
	tgt.Transparency = 1
	tgt.Parent = folder
	local a1 = Instance.new("Attachment")
	a1.Parent = tgt
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Width0, b.Width1 = 3, 14
	b.FaceCamera = true
	b.LightEmission = 1
	b.Color = ColorSequence.new(rgb(140, 255, 220), rgb(100, 220, 255))
	b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	b.Parent = m.parts[4]
	m.beam, m.beamEnd = b, tgt
	return m
end

-- ===== Ракеты: взлёт → перелёт по дуге → посадка → стоянка =====
local function surfacePoint(pl, n: Vector3)
	return pl.center + n.Unit * (pl.r + 0.2)
end
local function randomUp()
	return Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.3, 1), rng:NextNumber(-1, 1)).Unit
end
local function bez(p0, p1, p2, p3, t)
	local u = 1 - t
	return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t
end
local rockets = {}
for k, trim in ipairs({ rgb(230, 60, 60), CYAN, GOLD }) do
	local r = rocketModel(trim)
	local pl = planets[(k % #planets) + 1]
	r.planet = pl
	r.n = randomUp()
	r.state = "rest"
	r.timer = rng:NextNumber(1, 5)
	table.insert(rockets, r)
end
local function rocketCF(pos: Vector3, fwd: Vector3)
	return CFrame.lookAt(pos, pos + fwd) * CFrame.Angles(-math.pi / 2, 0, 0)
end
local function stepRocket(r, dt)
	if r.state == "rest" then
		r.timer -= dt
		local pos = surfacePoint(r.planet, r.n) + r.n * 5.6
		place(r, rocketCF(pos, r.n))
		r.fire.Enabled, r.smoke.Enabled, r.glow.Enabled = false, false, false
		if r.timer <= 0 then
			-- куда летим: другая планета
			local to
			repeat
				to = planets[rng:NextInteger(1, #planets)]
			until to ~= r.planet
			local nTo = (CENTER + Vector3.new(0, 80, 0) - to.center).Unit:Lerp(randomUp(), 0.6).Unit
			local p0 = surfacePoint(r.planet, r.n) + r.n * 5.6
			local p3 = surfacePoint(to, nTo) + nTo * 5.6
			local lift = math.clamp((p3 - p0).Magnitude * 0.35, 60, 220)
			r.path = { p0, p0 + r.n * lift, p3 + nTo * lift, p3 }
			r.len = (p3 - p0).Magnitude + lift
			r.t = 0
			r.dest, r.nDest = to, nTo
			r.state = "fly"
			r.fire.Enabled, r.smoke.Enabled, r.glow.Enabled = true, true, true
		end
	else
		r.t += dt * 55 / r.len
		local t = math.clamp(r.t, 0, 1)
		local e = t * t * (3 - 2 * t) -- плавный разгон и торможение
		local p = r.path
		local pos = bez(p[1], p[2], p[3], p[4], e)
		local ahead = bez(p[1], p[2], p[3], p[4], math.min(e + 0.01, 1))
		local fwd = (ahead - pos)
		if fwd.Magnitude < 0.01 then
			fwd = r.nDest
		end
		local cf = rocketCF(pos, fwd.Unit)
		if t > 0.7 then
			-- посадка: плавно разворачивается соплом к планете и садится носом вверх
			cf = cf:Lerp(rocketCF(pos, r.nDest), math.clamp((t - 0.7) / 0.25, 0, 1))
		end
		place(r, cf)
		if t >= 1 then
			r.planet, r.n = r.dest, r.nDest
			r.state = "rest"
			r.timer = rng:NextNumber(4, 9)
		end
	end
end

-- ===== Спутники на орбитах и летающая тарелка =====
local sats = {}
for k = 1, 5 do
	local pl = planets[(k % #planets) + 1]
	local s = satelliteModel(k % 2 == 0 and rgb(255, 80, 80) or rgb(120, 255, 140))
	s.planet = pl
	s.radius = pl.r + rng:NextNumber(10, 26)
	s.tilt = CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 6.28), rng:NextNumber(-0.6, 0.6))
	s.speed = rng:NextNumber(0.15, 0.35) * (rng:NextNumber() < 0.5 and -1 or 1)
	s.a = rng:NextNumber(0, 6.28)
	table.insert(sats, s)
end
local ufo = ufoModel()
ufo.from = CENTER + Vector3.new(-150, 120, -120)
ufo.to = CENTER + Vector3.new(120, 100, 60)
ufo.t = 0

-- ===== Астероиды врезаются в планеты =====
local impacts = {}
local function spawnImpact()
	local pl = planets[rng:NextInteger(1, #planets)]
	if pl.r < 10 then
		return
	end
	-- удар в сторону, видную с платформы
	local n = ((CENTER + Vector3.new(0, 60, 0)) - pl.center).Unit:Lerp(randomUp(), 0.5).Unit
	local hit = pl.center + n * pl.r
	local from = hit + (n + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.2, 1), rng:NextNumber(-1, 1))).Unit * rng:NextNumber(260, 380)
	local s = rng:NextNumber(4, 8)
	local rock = mk("ImpactRock", Vector3.new(s, s, s), CFrame.new(from), rgb(110, 90, 120), Enum.Material.Slate, BALL)
	rock.Parent = folder
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, s * 0.45, 0)
	a0.Parent = rock
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -s * 0.45, 0)
	a1.Parent = rock
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 0.9
	tr.FaceCamera = true
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(rgb(255, 230, 150), rgb(255, 80, 40))
	tr.Transparency = NumberSequence.new(0.1, 1)
	tr.WidthScale = NumberSequence.new(1.6, 0)
	tr.Parent = rock
	emitter(rock, {
		Texture = FIRE,
		Color = ColorSequence.new(rgb(255, 220, 120), rgb(255, 70, 30)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s * 0.9), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		Rate = 40,
	})
	table.insert(impacts, { rock = rock, from = from, hit = hit, n = n, t = 0, dur = rng:NextNumber(3.5, 5.5), pl = pl, size = s })
end
local function explode(hit: Vector3, n: Vector3, scale: number)
	local holder = mk("Boom", Vector3.new(1, 1, 1), CFrame.new(hit), WHITE)
	holder.Transparency = 1
	holder.Parent = folder
	local fire = emitter(holder, {
		Texture = FIRE,
		Color = ColorSequence.new(rgb(255, 240, 180), rgb(255, 80, 30)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, scale * 2), NumberSequenceKeypoint.new(1, scale * 5) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(10, 30),
		SpreadAngle = Vector2.new(180, 180),
		Rate = 0,
	})
	fire:Emit(30)
	local sp = emitter(holder, {
		Texture = SPARK,
		Color = ColorSequence.new(rgb(255, 230, 120), rgb(255, 120, 60)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, scale * 0.6), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.8, 1.6),
		Speed = NumberRange.new(30, 60),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 2,
		Rate = 0,
	})
	sp:Emit(60)
	local dust = emitter(holder, {
		Texture = SMOKE,
		Color = ColorSequence.new(rgb(180, 150, 200), rgb(80, 60, 100)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, scale * 3), NumberSequenceKeypoint.new(1, scale * 8) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(2, 3.5),
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(180, 180),
		Rate = 0,
	})
	dust:Emit(12)
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 170, 90)
	l.Range = 60
	l.Brightness = 8
	l.Parent = holder
	TweenService:Create(l, TweenInfo.new(1.2), { Brightness = 0 }):Play()
	-- ударная волна по поверхности планеты
	local wave = mk("Shockwave", Vector3.new(0.3, 2, 2), CFrame.lookAt(hit, hit + n) * CFrame.Angles(0, math.pi / 2, 0), rgb(255, 200, 120), Enum.Material.Neon, CYL)
	wave.Transparency = 0.1
	wave.Parent = folder
	TweenService:Create(wave, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, scale * 9, scale * 9), Transparency = 1 }):Play()
	task.delay(4, function()
		holder:Destroy()
		wave:Destroy()
	end)
end

-- ===== Падающие звёзды =====
local function shootingStar()
	local a = randomUp()
	local start = CENTER + a * 700
	local dir = (Vector3.new(rng:NextNumber(-1, 1), -rng:NextNumber(0.2, 0.5), rng:NextNumber(-1, 1))).Unit
	local p = mk("ShootingStar", Vector3.new(2.5, 2.5, 2.5), CFrame.new(start), WHITE, Enum.Material.Neon, BALL)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = p
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 0.5
	tr.FaceCamera = true
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(WHITE, rgb(150, 200, 255))
	tr.Transparency = NumberSequence.new(0, 1)
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.Parent = p
	p.Parent = folder
	TweenService:Create(p, TweenInfo.new(1.3, Enum.EasingStyle.Linear), { Position = start + dir * 420 }):Play()
	task.delay(1.9, function()
		p:Destroy()
	end)
end

-- ===== Чёрная дыра с вращающимся аккреционным диском =====
local BH = CENTER + Vector3.new(-430, 280, -470)
local bhUp = ((CENTER - BH).Unit * 0.45 + Vector3.yAxis).Unit -- диск наклонён к платформе (видно эллипсом)
local bhRight = bhUp:Cross(Vector3.zAxis).Unit
local bhTilt = CFrame.fromMatrix(BH, bhRight, bhUp)
local bh = { disks = {} }
do
	local core = mk("BlackHole", Vector3.new(80, 80, 80), CFrame.new(BH), rgb(0, 0, 0), Enum.Material.SmoothPlastic, BALL)
	core.Parent = folder
	local halo = mk("BlackHoleHalo", Vector3.new(90, 90, 90), CFrame.new(BH), rgb(255, 150, 70), Enum.Material.Neon, BALL)
	halo.Transparency = 0.9
	halo.Parent = folder
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 150, 80)
	l.Range = 120
	l.Brightness = 3
	l.Parent = core
	for band = 1, 4 do
		local r = 55 + band * 22
		local n = 36
		local parts, base = {}, {}
		local chord = 2 * r * math.sin(math.pi / n) * 1.25
		for k = 1, n do
			local a = k / n * math.pi * 2
			local cf = bhTilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -r)
			local col = rgb(255, 245, 210):Lerp(rgb(255, 120, 40), (band - 1) / 3):Lerp(rgb(170, 60, 200), math.max(0, band - 3) * 0.6)
			local p = mk("Accretion", Vector3.new(chord, 0.8, 20), cf, col, Enum.Material.Neon)
			p.Transparency = 0.05 + band * 0.12
			p.Parent = folder
			table.insert(parts, p)
			table.insert(base, cf)
		end
		table.insert(bh.disks, { parts = parts, base = base, speed = 1.4 / band, frames = table.create(n) })
	end
	-- затягиваемая материя: искры по спирали к центру
	local swirl = mk("BlackHoleSwirl", Vector3.new(200, 1, 200), bhTilt, WHITE)
	swirl.Transparency = 1
	swirl.Parent = folder
	emitter(swirl, {
		Texture = SPARK,
		Color = ColorSequence.new(rgb(255, 220, 160), rgb(200, 90, 255)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(2, 3),
		Speed = NumberRange.new(0, 0),
		Rate = 30,
		Shape = Enum.ParticleEmitterShape.Box,
		LockedToPart = true,
	})
end

-- ===== Спиральная галактика далеко в небе (медленно вращается) =====
local spiral = { parts = {}, base = {}, frames = {} }
do
	local n = Vector3.new(0.55, 0.55, 0.62).Unit
	local c = CENTER + n * (SKY_R * 0.92)
	local u = n:Cross(Vector3.yAxis).Unit
	local v = u:Cross(n).Unit
	local tilt = CFrame.fromMatrix(c, u, n:Lerp(v, 0.35).Unit) -- диском к зрителю, чуть наклонена
	spiral.center = c
	spiral.axis = tilt.UpVector
	local core = mk("GalaxyCore", Vector3.new(44, 44, 44), CFrame.new(c), rgb(255, 235, 200), Enum.Material.Neon, BALL)
	core.Parent = folder
	emitter(core, {
		Texture = SMOKE,
		Color = ColorSequence.new(rgb(255, 220, 180), rgb(200, 140, 255)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 60), NumberSequenceKeypoint.new(1, 90) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(6, 8),
		Speed = NumberRange.new(0, 0),
		Rate = 1.2,
		LockedToPart = true,
	})
	for arm = 0, 2 do
		for i = 1, 70 do
			local tt = i / 70
			local ang = arm * math.pi * 2 / 3 + tt * 4.2
			local rad = 14 + tt * 230
			local jitter = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * (6 + tt * 18)
			local pos = tilt * (Vector3.new(math.cos(ang) * rad, 0, math.sin(ang) * rad) + jitter)
			local s = rng:NextNumber(3, 7) * (1.2 - tt * 0.5)
			local col = rgb(255, 240, 220):Lerp(({ CYAN, PINK, VIOLET })[arm + 1], tt)
			local p = mk("GalaxyStar", Vector3.new(s, s, s), CFrame.new(pos), col, Enum.Material.Neon, BALL)
			p.Parent = folder
			table.insert(spiral.parts, p)
			table.insert(spiral.base, CFrame.new(pos))
		end
	end
	spiral.frames = table.create(#spiral.parts)
end

-- ===== Космическая станция на орбите гигантской планеты =====
local giant = planets[1]
for _, pl in ipairs(planets) do
	if pl.r > giant.r then
		giant = pl
	end
end
local station = model({
	{ "StHub", Vector3.new(14, 7, 7), rgb(210, 215, 235), Enum.Material.Metal, CFrame.Angles(0, 0, math.pi / 2), CYL },
	{ "StHubGlow", Vector3.new(2, 7.4, 7.4), CYAN, Enum.Material.Neon, CFrame.Angles(0, 0, math.pi / 2), CYL },
	{ "StPanelA", Vector3.new(26, 0.4, 6), rgb(40, 70, 170), Enum.Material.Glass, CFrame.new(0, 0, 0) },
	{ "StPanelB", Vector3.new(6, 0.4, 26), rgb(40, 70, 170), Enum.Material.Glass, CFrame.new(0, -4, 0) },
	{ "StBeacon", Vector3.new(1.4, 1.4, 1.4), rgb(255, 80, 80), Enum.Material.Neon, CFrame.new(0, 8, 0), BALL },
})
do
	-- вращающееся жилое кольцо
	local n = 24
	for k = 1, n do
		local a = k / n * math.pi * 2
		local p = mk("StRing", Vector3.new(4.8, 2, 2.2), CFrame.new(), k % 4 == 0 and CYAN or rgb(190, 195, 215), k % 4 == 0 and Enum.Material.Neon or Enum.Material.Metal)
		p.Parent = folder
		table.insert(station.parts, p)
		table.insert(station.offs, CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -18))
	end
	station.ringFrom = #station.parts - n + 1
	station.frames = table.create(#station.parts)
end

-- ===== Комета с длинным хвостом =====
local comet = mk("Comet", Vector3.new(7, 7, 7), CFrame.new(CENTER + Vector3.new(0, 600, 0)), rgb(200, 240, 255), Enum.Material.Neon, BALL)
do
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 3, 0)
	a0.Parent = comet
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -3, 0)
	a1.Parent = comet
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 6
	tr.FaceCamera = true
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(rgb(220, 250, 255), rgb(120, 140, 255))
	tr.Transparency = NumberSequence.new(0.1, 1)
	tr.WidthScale = NumberSequence.new(3, 0.2)
	tr.Parent = comet
	emitter(comet, {
		Texture = SMOKE,
		Color = ColorSequence.new(rgb(200, 240, 255), rgb(140, 120, 255)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 22) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(2, 3),
		Speed = NumberRange.new(0, 1),
		Rate = 10,
	})
	comet.Parent = folder
end
local cometT, cometFrom, cometTo = 1, Vector3.zero, Vector3.zero
local function newComet()
	local a = rng:NextNumber(0, math.pi * 2)
	cometFrom = CENTER + Vector3.new(math.cos(a) * 650, rng:NextNumber(250, 450), math.sin(a) * 650)
	cometTo = CENTER + Vector3.new(-math.cos(a + 0.6) * 650, rng:NextNumber(200, 400), -math.sin(a + 0.6) * 650)
	cometT = 0
end
newComet()

-- ещё ракеты (всего 5)
for _, trim in ipairs({ PINK, rgb(120, 255, 160) }) do
	local r = rocketModel(trim)
	r.planet = planets[rng:NextInteger(1, #planets)]
	r.n = randomUp()
	r.state = "rest"
	r.timer = rng:NextNumber(2, 8)
	table.insert(rockets, r)
end

-- цвет колец: мягкий переливающийся градиент вокруг кольца (вместо сплошного белого)
for _, ring in ipairs(rings) do
	local h, s = ring.baseC:ToHSV()
	ring.hue = h
	ring.sat = math.max(s, 0.45)
end
local nextShower = 12

-- ===== Главный цикл =====
local inside = false
local conn: RBXScriptConnection? = nil
local t = 0
local slow = 0
local nextImpact, nextStar = 3, 1.5
local function step(dt)
	t += dt
	-- кольца: вращение каждый кадр
	for _, ring in ipairs(rings) do
		local rot = CFrame.new(ring.center) * CFrame.fromAxisAngle(ring.axis, t * ring.speed) * CFrame.new(-ring.center)
		for i, b in ipairs(ring.base) do
			ring.frames[i] = rot * b
		end
		workspace:BulkMoveTo(ring.parts, ring.frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for _, r in ipairs(rockets) do
		stepRocket(r, dt)
	end
	for _, s in ipairs(sats) do
		s.a += dt * s.speed
		local c = s.planet.center
		local pos = (CFrame.new(c) * s.tilt * CFrame.Angles(0, s.a, 0) * CFrame.new(0, 0, s.radius)).Position
		place(s, CFrame.lookAt(pos, c) * CFrame.Angles(0, 0, t * 0.3))
	end
	-- тарелка: плавно бродит, покачивается, луч до платформы
	ufo.t += dt * 0.05
	local k = 0.5 - 0.5 * math.cos(ufo.t * math.pi)
	local up = ufo.from:Lerp(ufo.to, k) + Vector3.new(math.sin(t * 0.7) * 12, math.sin(t * 1.3) * 4, math.cos(t * 0.5) * 12)
	place(ufo, CFrame.new(up) * CFrame.Angles(math.sin(t * 0.9) * 0.08, t * 0.8, math.cos(t * 1.1) * 0.08))
	ufo.beamEnd.CFrame = CFrame.new(Vector3.new(up.X, CENTER.Y, up.Z))
	if ufo.t >= 2 then
		ufo.t = 0
		ufo.from = ufo.to
		ufo.to = CENTER + Vector3.new(rng:NextNumber(-170, 170), rng:NextNumber(90, 140), rng:NextNumber(-170, 170))
	end
	-- астероиды
	for i = #impacts, 1, -1 do
		local im = impacts[i]
		im.t += dt / im.dur
		local e = im.t * im.t -- разгоняется к удару
		im.rock.CFrame = CFrame.new(im.from:Lerp(im.hit, math.min(e, 1))) * CFrame.Angles(t * 2, t * 1.4, 0)
		if im.t >= 1 then
			explode(im.hit, im.n, math.clamp(im.size * 1.2, 5, 10))
			im.rock:Destroy()
			table.remove(impacts, i)
		end
	end
	nextImpact -= dt
	if nextImpact <= 0 and #impacts < 3 then
		nextImpact = rng:NextNumber(3, 7)
		spawnImpact()
	end
	nextStar -= dt
	if nextStar <= 0 then
		nextStar = rng:NextNumber(1.2, 3.5)
		shootingStar()
	end
	-- метеорный дождь: раз в ~20–30 с пачка падающих звёзд
	nextShower -= dt
	if nextShower <= 0 then
		nextShower = rng:NextNumber(20, 30)
		for k = 0, 9 do
			task.delay(k * 0.18, shootingStar)
		end
	end
	-- чёрная дыра: диски крутятся (внутренние быстрее)
	for _, d in ipairs(bh.disks) do
		local rot = CFrame.new(BH) * CFrame.fromAxisAngle(bhTilt.UpVector, t * d.speed) * CFrame.new(-BH)
		for i, b in ipairs(d.base) do
			d.frames[i] = rot * b
		end
		workspace:BulkMoveTo(d.parts, d.frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	-- спиральная галактика медленно вращается
	do
		local rot = CFrame.new(spiral.center) * CFrame.fromAxisAngle(spiral.axis, t * 0.04) * CFrame.new(-spiral.center)
		for i, b in ipairs(spiral.base) do
			spiral.frames[i] = rot * b
		end
		workspace:BulkMoveTo(spiral.parts, spiral.frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	-- станция: по орбите гиганта, жилое кольцо вращается
	do
		local c = giant.center
		local pos = (CFrame.new(c) * CFrame.Angles(0.35, t * 0.05, 0.15) * CFrame.new(0, 0, giant.r + 45)).Position
		local base = CFrame.lookAt(pos, c)
		for i, o in ipairs(station.offs) do
			if i >= station.ringFrom then
				station.frames[i] = base * CFrame.Angles(0, t * 0.6, 0) * o
			else
				station.frames[i] = base * o
			end
		end
		workspace:BulkMoveTo(station.parts, station.frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	-- комета пересекает небо за ~30 с, потом новая
	cometT += dt / 30
	if cometT >= 1 then
		newComet()
	end
	do
		local mid = (cometFrom + cometTo) / 2 + Vector3.new(0, 140, 0)
		local u = 1 - cometT
		comet.CFrame = CFrame.new(cometFrom * u * u + mid * 2 * u * cometT + cometTo * cometT * cometT)
	end
	-- 20 раз в секунду: мерцание звёзд, пульс колец и созвездий, мигание спутников
	slow += dt
	if slow >= 0.05 then
		slow = 0
		for _, s in ipairs(stars) do
			if s.tw then
				local v = 0.5 + 0.5 * math.sin(t * s.f + s.ph)
				s.part.Transparency = s.big and (0.05 + 0.3 * v) or (0.1 + 0.75 * v ^ 3)
			end
		end
		for _, b in ipairs(beams) do
			b.beam.Transparency = NumberSequence.new(0.45 + 0.3 * (0.5 + 0.5 * math.sin(t * 1.4 + b.ph)))
		end
		for _, ring in ipairs(rings) do
			-- по кольцу бежит светлая волна; всё кольцо медленно «дышит»
			local n = #ring.parts
			local breath = 0.5 + 0.5 * math.sin(t * 1.2)
			for i, p in ipairs(ring.parts) do
				local wave = math.max(0, math.cos((i / n) * math.pi * 4 - t * 2.4)) ^ 6
				p.Transparency = math.clamp(ring.baseT[i] - 0.15 * breath - 0.25 * wave, 0, 1)
				local hue = (ring.hue + (i / n) * 0.18 + math.sin(t * 0.15) * 0.05) % 1
				p.Color = Color3.fromHSV(hue, ring.sat, 1):Lerp(WHITE, 0.3 * wave)
			end
		end
		station.parts[5].Transparency = (math.floor(t * 1.5) % 2 == 0) and 0 or 0.9
		for i, s in ipairs(sats) do
			s.parts[5].Transparency = (math.floor(t * 2 + i) % 2 == 0) and 0 or 0.85
		end
	end
end

local function onWorld()
	local now = player:GetAttribute("CurrentWorld") == "Cosmic Galaxy"
	if now == inside then
		return
	end
	inside = now
	if inside then
		folder.Parent = workspace
		for _, e in ipairs(nebulae) do
			e:Clear()
			e:Emit(5)
		end
		conn = RunService.RenderStepped:Connect(step)
	else
		if conn then
			conn:Disconnect()
			conn = nil
		end
		folder.Parent = nil
	end
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
onWorld()
