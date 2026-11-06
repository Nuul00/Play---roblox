-- Свой «финал» открытия для каждого питомца Royal Egg (RoyalHatch):
--   1 Crown Pup      — королевский: золотой фонтан монет, сверху опускается корона
--   2 Velvet Fox     — бархат: фиолетовые ленты закручиваются вихрем, лепестки роз
--   3 Sapphire Owl   — кристаллы: из земли вырастают кристаллы, яйцо покрывается льдом и раскалывается
--   4 Emerald Griffin— ветер: торнадо из перьев и листьев, кольца ветра
--   5 Golden Phoenix — огонь: огненный смерч, яйцо сгорает, феникс восстаёт из пепла
--   6 Imperial Dragon— космос: небо темнеет, вокруг кружат планеты, галактика сворачивается
--                      в чёрную дыру и взрывается сверхновой
-- Модели-реквизит из Tripo (ReplicatedStorage.TripoEggs: FX_Crystal, FX_PlanetRing, FX_Planet,
-- FX_Feather); если их нет — простые детали.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local T = {}
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
T.ByTier = { "royal", "velvet", "crystal", "wind", "fire", "cosmic" }

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local function frame()
	return RunService.RenderStepped:Wait()
end
local function basePart(folder, size, cf, color, mat, transp, shape)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = transp or 0
	if shape then
		p.Shape = shape
	end
	p.Parent = folder
	return p
end
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Rate = 0
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end
local function prop(name: string, size: number, folder)
	local f = ReplicatedStorage:FindFirstChild("TripoEggs")
	local t = f and f:FindFirstChild(name)
	if not t then
		return nil
	end
	local m = t:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
		end
	end
	local _, s = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * size / math.max(s.X, s.Y, s.Z, 0.01))
	m.Parent = folder
	return m
end
local function placeCenter(m: Model, cf: CFrame)
	local bcf = m:GetBoundingBox()
	local off = m:GetPivot():ToObjectSpace(bcf)
	m:PivotTo(cf * off:Inverse())
end
local function fadeModel(m: Instance, t: number)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			TweenService:Create(d, TweenInfo.new(t), { Transparency = 1 }):Play()
		end
	end
end
local function flash(color: Color3, bright: number, t: number)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = bright
	cc.TintColor = color
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(t), { Brightness = 0, TintColor = Color3.new(1, 1, 1) }):Play()
	task.delay(t + 0.05, function()
		cc:Destroy()
	end)
end
local function anchorAt(folder, pos)
	local a = basePart(folder, Vector3.new(1, 1, 1), CFrame.new(pos), Color3.new(1, 1, 1), nil, 1)
	return a
end
-- общий шаг: яйцо исчезает с выбросом искр нужного цвета
local function pop(ctx, colorA: Color3, colorB: Color3, n: number)
	local a = anchorAt(ctx.folder, ctx.center)
	local e = emitter(a, {
		Color = ColorSequence.new(colorA, colorB),
		LightEmission = 1,
		Lifetime = NumberRange.new(0.8, 1.6),
		Speed = NumberRange.new(14, 26),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -12, 0),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
	})
	e:Emit(n)
	if ctx.egg and ctx.egg.Parent then
		ctx.egg:Destroy()
	end
end

-- ================= ФИНАЛЫ =================
local Climax = {}

Climax.royal = function(ctx)
	-- монетный фонтан + золотая вспышка
	local a = anchorAt(ctx.folder, ctx.ground + Vector3.new(0, 0.5, 0))
	local coins = emitter(a, {
		Texture = SPARK, Color = ColorSequence.new(rgb(255, 215, 80), rgb(255, 245, 180)), LightEmission = 0.6,
		Lifetime = NumberRange.new(1.2, 1.8), Speed = NumberRange.new(16, 24), SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -30, 0),
		Size = NumberSequence.new(0.7), RotSpeed = NumberRange.new(-200, 200),
	})
	coins:Emit(70)
	flash(rgb(255, 240, 180), 0.3, 0.5)
	pop(ctx, rgb(255, 210, 70), rgb(255, 255, 255), 70)
end

Climax.velvet = function(ctx)
	-- ленты: 3 спирали из фиолетовых сегментов сжимаются к яйцу
	local ribbons = {}
	for r = 1, 3 do
		for k = 1, 14 do
			ribbons[#ribbons + 1] = { part = basePart(ctx.folder, Vector3.new(0.6, 0.1, 1.4), CFrame.new(ctx.center), r == 2 and rgb(255, 120, 190) or rgb(140, 50, 200), Enum.Material.Fabric, 0.05), r = r, k = k }
		end
	end
	local t0 = os.clock()
	while os.clock() - t0 < 1.3 do
		local e = os.clock() - t0
		local k = e / 1.3
		for _, s in ipairs(ribbons) do
			local a = s.k * 0.45 + e * 6 + s.r * 2.1
			local rad = 6 * (1 - k) + 0.8
			local p = ctx.center + Vector3.new(math.cos(a) * rad, (s.k - 7) * 0.45 * (1 - k * 0.7), math.sin(a) * rad)
			s.part.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0.3, math.cos(a)))
		end
		frame()
	end
	for _, s in ipairs(ribbons) do
		TweenService:Create(s.part, TweenInfo.new(0.4), { Transparency = 1, Size = Vector3.new(0.1, 0.05, 0.3) }):Play()
	end
	local a = anchorAt(ctx.folder, ctx.center)
	emitter(a, {
		Texture = SPARK, Color = ColorSequence.new(rgb(255, 120, 190), rgb(200, 120, 255)), LightEmission = 0.4,
		Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -3, 0), RotSpeed = NumberRange.new(-180, 180), Size = NumberSequence.new(0.6),
	}):Emit(60)
	flash(rgb(230, 190, 255), 0.25, 0.5)
	pop(ctx, rgb(200, 90, 255), rgb(255, 160, 220), 60)
end

Climax.crystal = function(ctx)
	-- кольцо кристаллов вырастает из земли, яйцо обрастает льдом, всё раскалывается
	local crystals = {}
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local pos = ctx.ground + Vector3.new(math.cos(a) * 4.2, 0, math.sin(a) * 4.2)
		local m = prop("FX_Crystal", 2.6, ctx.folder)
		if not m then
			m = Instance.new("Model")
			basePart(m, Vector3.new(0.8, 3, 0.8), CFrame.new(), i % 2 == 0 and rgb(120, 200, 255) or rgb(180, 120, 255), Enum.Material.Glass, 0.15)
			m.Parent = ctx.folder
		end
		crystals[i] = { m = m, pos = pos, s0 = m:GetScale(), tilt = CFrame.Angles(math.rad(-20), a, 0) }
	end
	local ice = basePart(ctx.folder, Vector3.new(0.1, 0.1, 0.1), CFrame.new(ctx.center), rgb(170, 230, 255), Enum.Material.Glass, 0.35, Enum.PartType.Ball)
	local t0 = os.clock()
	while os.clock() - t0 < 1.2 do
		local k = math.min((os.clock() - t0) / 0.8, 1)
		local kk = 1 - (1 - k) ^ 3
		for _, c in ipairs(crystals) do
			pcall(function()
				c.m:ScaleTo(math.max(c.s0 * kk, 0.01))
			end)
			placeCenter(c.m, CFrame.new(c.pos + Vector3.new(0, 1.2 * kk, 0)) * c.tilt)
		end
		local ik = math.clamp((os.clock() - t0 - 0.5) / 0.6, 0, 1)
		ice.Size = Vector3.new(1, 1.2, 1) * (5.5 * ik + 0.1)
		frame()
	end
	-- треск и раскол
	local a = anchorAt(ctx.folder, ctx.center)
	emitter(a, {
		Texture = SPARK, Color = ColorSequence.new(rgb(170, 230, 255), rgb(255, 255, 255)), LightEmission = 1,
		Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(18, 30), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -25, 0), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) }),
	}):Emit(110)
	for i = 1, 14 do
		local shard = basePart(ctx.folder, Vector3.new(0.5, 0.9, 0.2), CFrame.new(ctx.center) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), rgb(170, 230, 255), Enum.Material.Glass, 0.2)
		local dir = CFrame.Angles(math.random() * 6, math.random() * 6, 0).LookVector
		TweenService:Create(shard, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { CFrame = CFrame.new(ctx.center + dir * 7) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), Transparency = 1 }):Play()
	end
	ice:Destroy()
	for _, c in ipairs(crystals) do
		fadeModel(c.m, 1.5)
	end
	flash(rgb(190, 235, 255), 0.4, 0.6)
	pop(ctx, rgb(120, 200, 255), rgb(200, 150, 255), 40)
	ctx.keep = crystals
end

Climax.wind = function(ctx)
	-- торнадо из перьев
	local feathers = {}
	for i = 1, 16 do
		local m = prop("FX_Feather", 1.6, ctx.folder)
		if not m then
			m = Instance.new("Model")
			basePart(m, Vector3.new(0.2, 1.4, 0.5), CFrame.new(), i % 2 == 0 and rgb(80, 220, 120) or rgb(255, 210, 80), Enum.Material.SmoothPlastic, 0)
			m.Parent = ctx.folder
		end
		feathers[i] = { m = m, a = i / 16 * math.pi * 2, h = (i % 8) / 8 }
	end
	local rings = {}
	for i = 1, 3 do
		rings[i] = basePart(ctx.folder, Vector3.new(0.15, 2, 2), CFrame.new(ctx.ground), rgb(210, 255, 220), Enum.Material.Neon, 0.5, Enum.PartType.Cylinder)
	end
	local t0 = os.clock()
	while os.clock() - t0 < 1.5 do
		local e = os.clock() - t0
		local k = e / 1.5
		for _, f in ipairs(feathers) do
			local a = f.a + e * (5 + k * 6)
			local h = (f.h + e * 0.6) % 1
			local rad = 1.5 + h * 4 * (1 - k * 0.5)
			local p = ctx.ground + Vector3.new(math.cos(a) * rad, h * 8, math.sin(a) * rad)
			placeCenter(f.m, CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0.5, math.cos(a))))
		end
		for i, r in ipairs(rings) do
			local rk = (k * 2 + i / 3) % 1
			r.Size = Vector3.new(0.15, 2 + rk * 10, 2 + rk * 10)
			r.CFrame = CFrame.new(ctx.ground + Vector3.new(0, 0.5 + rk * 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
			r.Transparency = 0.4 + rk * 0.6
		end
		frame()
	end
	-- перья разлетаются
	for _, f in ipairs(feathers) do
		local dir = (f.m:GetPivot().Position - ctx.center).Unit
		local goal = f.m:GetPivot() + dir * 10 + Vector3.new(0, 3, 0)
		local m = f.m
		task.spawn(function()
			local s0 = os.clock()
			local from = m:GetPivot()
			while os.clock() - s0 < 0.8 and m.Parent do
				m:PivotTo(from:Lerp(goal, (os.clock() - s0) / 0.8))
				frame()
			end
		end)
		fadeModel(m, 0.9)
	end
	for _, r in ipairs(rings) do
		TweenService:Create(r, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end
	flash(rgb(210, 255, 220), 0.3, 0.5)
	pop(ctx, rgb(80, 230, 120), rgb(255, 220, 100), 70)
end

Climax.fire = function(ctx)
	-- огненный смерч и пламя, яйцо сгорает
	local a = anchorAt(ctx.folder, ctx.ground + Vector3.new(0, 0.5, 0))
	local fireE = emitter(a, {
		Texture = FIRE, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 240, 150)), ColorSequenceKeypoint.new(0.5, rgb(255, 130, 30)), ColorSequenceKeypoint.new(1, rgb(150, 30, 10)) }),
		LightEmission = 1, Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(15, 15),
		EmissionDirection = Enum.NormalId.Top, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0.5) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		RotSpeed = NumberRange.new(-90, 90), Rate = 120, Shape = Enum.ParticleEmitterShape.Cylinder, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
	})
	local embers = emitter(a, {
		Texture = SPARK, Color = ColorSequence.new(rgb(255, 200, 80), rgb(255, 90, 30)), LightEmission = 1,
		Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(4, 9), SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = Enum.NormalId.Top, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }), Rate = 60,
	})
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 140, 40)
	light.Range = 26
	light.Brightness = 4
	light.Parent = a
	local t0 = os.clock()
	while os.clock() - t0 < 1.6 do
		local k = (os.clock() - t0) / 1.6
		a.Size = Vector3.new(1, 1, 1) * (1 + k * 5)
		a.CFrame = CFrame.new(ctx.ground + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, os.clock() * 8, 0)
		if ctx.egg and ctx.egg.Parent then
			for _, d in ipairs(ctx.egg:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Color = d.Color:Lerp(rgb(40, 20, 10), 0.03)
				end
			end
		end
		frame()
	end
	fireE.Enabled = false
	embers.Enabled = false
	emitter(a, {
		Texture = SMOKE, Color = ColorSequence.new(rgb(60, 50, 45), rgb(20, 20, 20)), Lifetime = NumberRange.new(1.5, 2.5),
		Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }),
	}):Emit(25)
	TweenService:Create(light, TweenInfo.new(1.5), { Brightness = 0 }):Play()
	flash(rgb(255, 200, 120), 0.45, 0.6)
	pop(ctx, rgb(255, 170, 40), rgb(255, 240, 150), 120)
end

Climax.cosmic = function(ctx)
	-- небо темнеет, планеты на орбитах, звёздная спираль, чёрная дыра и сверхновая
	local dark = Instance.new("ColorCorrectionEffect")
	dark.Brightness = 0
	dark.Saturation = 0
	dark.TintColor = Color3.new(1, 1, 1)
	dark.Parent = Lighting
	TweenService:Create(dark, TweenInfo.new(0.6), { Brightness = -0.35, TintColor = rgb(150, 130, 230), Saturation = 0.2 }):Play()
	local planets = {}
	for i, spec in ipairs({ { "FX_PlanetRing", 3.2, rgb(200, 120, 255) }, { "FX_Planet", 2.2, rgb(90, 170, 255) }, { "FX_Planet", 1.5, rgb(255, 150, 90) } }) do
		local m = prop(spec[1], spec[2], ctx.folder)
		if not m then
			m = Instance.new("Model")
			basePart(m, Vector3.new(1, 1, 1) * spec[2], CFrame.new(), spec[3], Enum.Material.SmoothPlastic, 0, Enum.PartType.Ball)
			m.Parent = ctx.folder
		end
		planets[i] = { m = m, r = 4 + i * 1.6, sp = 1.6 - i * 0.3, ph = i * 2.1, tilt = math.rad(10 + i * 8) }
	end
	local a = anchorAt(ctx.folder, ctx.center)
	local stars = emitter(a, {
		Texture = SPARK, Color = ColorSequence.new(rgb(200, 180, 255), rgb(120, 220, 255)), LightEmission = 1,
		Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(-8, -5), SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }), Rate = 90,
		Shape = Enum.ParticleEmitterShape.Sphere, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, RotSpeed = NumberRange.new(200, 400),
	})
	a.Size = Vector3.new(14, 14, 14)
	local hole = basePart(ctx.folder, Vector3.new(0.1, 0.1, 0.1), CFrame.new(ctx.center), rgb(10, 0, 25), Enum.Material.SmoothPlastic, 0, Enum.PartType.Ball)
	local rim = basePart(ctx.folder, Vector3.new(0.1, 0.1, 0.1), CFrame.new(ctx.center), rgb(190, 120, 255), Enum.Material.Neon, 0.4, Enum.PartType.Ball)
	local t0 = os.clock()
	while os.clock() - t0 < 2.2 do
		local e = os.clock() - t0
		local k = e / 2.2
		for _, p in ipairs(planets) do
			local ang = p.ph + e * p.sp * (1 + k * 2)
			local rad = p.r * (1 - k * 0.85)
			local pos = ctx.center + CFrame.Angles(p.tilt, 0, 0):VectorToWorldSpace(Vector3.new(math.cos(ang) * rad, 0, math.sin(ang) * rad))
			placeCenter(p.m, CFrame.new(pos) * CFrame.Angles(0, e * 2, 0))
			if k > 0.75 then
				pcall(function()
					p.m:ScaleTo(math.max(p.m:GetScale() * 0.93, 0.01))
				end)
			end
		end
		local hk = math.clamp((k - 0.35) / 0.5, 0, 1)
		hole.Size = Vector3.new(1, 1, 1) * (0.1 + 3.2 * hk)
		rim.Size = hole.Size * 1.18
		rim.Transparency = 0.4 + 0.2 * math.sin(e * 20)
		if ctx.egg and ctx.egg.Parent and hk > 0.6 then
			pcall(function()
				ctx.egg:ScaleTo(math.max(ctx.egg:GetScale() * 0.9, 0.01))
			end)
		end
		frame()
	end
	stars.Enabled = false
	for _, p in ipairs(planets) do
		p.m:Destroy()
	end
	-- сверхновая
	hole:Destroy()
	TweenService:Create(rim, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = Vector3.new(26, 26, 26), Transparency = 1, Color = rgb(255, 255, 255) }):Play()
	TweenService:Create(dark, TweenInfo.new(0.8), { Brightness = 0, TintColor = Color3.new(1, 1, 1), Saturation = 0 }):Play()
	task.delay(0.9, function()
		dark:Destroy()
	end)
	flash(rgb(255, 255, 255), 0.7, 0.8)
	pop(ctx, rgb(180, 120, 255), rgb(120, 230, 255), 160)
end

function T.Climax(theme: string, ctx)
	local f = Climax[theme] or Climax.royal
	local ok, err = pcall(f, ctx)
	if not ok then
		warn("[RoyalHatchThemes] " .. tostring(err))
		if ctx.egg and ctx.egg.Parent then
			ctx.egg:Destroy()
		end
	end
end

-- ================= «АУРА» вокруг питомца, пока он стоит на земле =================
function T.Aura(theme: string, ctx)
	local a = anchorAt(ctx.folder, ctx.ground + Vector3.new(0, 2, 0))
	local parts = {}
	local update
	if theme == "royal" then
		local crown = prop("RoyalCrownFX", 1.6, ctx.folder)
		emitter(a, { Texture = SPARK, Color = ColorSequence.new(rgb(255, 215, 80), rgb(255, 255, 220)), LightEmission = 1, Rate = 14, Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new(0.4) })
		update = function(e, top)
			if crown then
				placeCenter(crown, CFrame.new(top + Vector3.new(0, 1 + math.max(0, 3 - e * 4), 0)) * CFrame.Angles(0, e, 0))
			end
		end
	elseif theme == "velvet" then
		emitter(a, { Texture = SPARK, Color = ColorSequence.new(rgb(255, 130, 200), rgb(200, 120, 255)), LightEmission = 0.5, Rate = 12, Lifetime = NumberRange.new(2.5, 3.5), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -1, 0), RotSpeed = NumberRange.new(-120, 120), Size = NumberSequence.new(0.5) })
	elseif theme == "crystal" then
		for i = 1, 3 do
			parts[i] = basePart(ctx.folder, Vector3.new(0.5, 0.9, 0.5), CFrame.new(ctx.ground), i == 2 and rgb(190, 130, 255) or rgb(130, 210, 255), Enum.Material.Glass, 0.15)
		end
		update = function(e, top)
			for i, p in ipairs(parts) do
				local ang = e * 1.5 + i * 2.1
				p.CFrame = CFrame.new(top + Vector3.new(math.cos(ang) * 2.4, -1 + math.sin(e * 2 + i) * 0.5, math.sin(ang) * 2.4)) * CFrame.Angles(e * 2, e, 0)
			end
		end
	elseif theme == "wind" then
		emitter(a, { Texture = SPARK, Color = ColorSequence.new(rgb(120, 240, 150), rgb(255, 230, 120)), LightEmission = 0.6, Rate = 10, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new(0.4) })
	elseif theme == "fire" then
		local f = Instance.new("Fire")
		f.Heat = 9
		f.Size = 6
		f.Color = rgb(255, 150, 40)
		f.SecondaryColor = rgb(255, 230, 120)
		f.Parent = a
		emitter(a, { Texture = SPARK, Color = ColorSequence.new(rgb(255, 200, 80), rgb(255, 90, 30)), LightEmission = 1, Rate = 25, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Top, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }) })
	elseif theme == "cosmic" then
		local p1 = prop("FX_PlanetRing", 1.4, ctx.folder)
		local p2 = prop("FX_Planet", 0.9, ctx.folder)
		emitter(a, { Texture = SPARK, Color = ColorSequence.new(rgb(200, 180, 255), rgb(120, 220, 255)), LightEmission = 1, Rate = 20, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }) })
		update = function(e, top)
			if p1 then
				placeCenter(p1, CFrame.new(top + Vector3.new(math.cos(e * 1.2) * 3.2, -1, math.sin(e * 1.2) * 3.2)) * CFrame.Angles(0.4, e, 0))
			end
			if p2 then
				placeCenter(p2, CFrame.new(top + Vector3.new(math.cos(-e * 1.8 + 2) * 2.4, 0, math.sin(-e * 1.8 + 2) * 2.4)) * CFrame.Angles(0, e * 2, 0))
			end
		end
	end
	return update
end

-- Мягкий «божественный» луч света вместо неоновой палки: три слоя Beam (FaceCamera, мягкие края
-- через текстуру дыма, затухание на концах), бегущие по лучу световые волны, пылинки в свете,
-- вспышка и свечение на земле. opts.rise = луч растёт от земли вверх (иначе спускается с неба).
-- Возвращает { update(e), fade(sec) }.
local function softSeq(base, top, bottom)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(top, base),
		NumberSequenceKeypoint.new(bottom, base),
		NumberSequenceKeypoint.new(1, 1),
	})
end
function T.LightShaft(folder, ground: Vector3, height: number, color: Color3, s: number, opts)
	opts = opts or {}
	local power = opts.power or 1 -- <1 = прозрачнее (чтобы не засвечивать яйцо/питомца)
	local low = opts.bottom or 0 -- нижний конец луча выше земли (луч не перекрывает питомца)
	local white = color:Lerp(Color3.new(1, 1, 1), 0.75)
	local holder = basePart(folder, Vector3.new(0.2, 0.2, 0.2), CFrame.new(ground), color, nil, 1)
	local aTop = Instance.new("Attachment")
	local aBot = Instance.new("Attachment")
	aTop.Parent, aBot.Parent = holder, holder
	aTop.Position, aBot.Position = Vector3.new(0, height, 0), Vector3.new(0, height, 0)
	if opts.rise then
		aTop.Position, aBot.Position = Vector3.new(0, low + 0.1, 0), Vector3.new(0, low, 0)
	end
	local layers = {
		-- ширина, прозрачность, цвет; слои от широкого прозрачного ореола к яркому ядру = мягкий край.
		-- tex = бегущие по лучу «волны» света (дымка)
		{ w = 16, t = 0.975, c = color },
		{ w = 13, t = 0.965, c = color },
		{ w = 10, t = 0.95, c = color },
		{ w = 7.5, t = 0.92, c = color:Lerp(white, 0.15) },
		{ w = 5.5, t = 0.86, c = color:Lerp(white, 0.3) },
		{ w = 3.8, t = 0.74, c = color:Lerp(white, 0.5) },
		{ w = 2.4, t = 0.5, c = color:Lerp(white, 0.7) },
		{ w = 1.1, t = 0.15, c = white },
		{ w = 7, t = 0.5, c = color:Lerp(white, 0.4), tex = true, len = 10, speed = opts.rise and 1.3 or -1.3 },
		{ w = 3.5, t = 0.35, c = white, tex = true, len = 5, speed = opts.rise and 2.6 or -2.6 },
	}
	local beams = {}
	for _, L in ipairs(layers) do
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = aTop, aBot
		b.FaceCamera = true
		b.LightEmission = 1
		b.LightInfluence = 0
		if L.tex then
			b.Texture = SMOKE
			b.TextureMode = Enum.TextureMode.Wrap
			b.TextureLength = L.len
			b.TextureSpeed = L.speed
		end
		b.Color = ColorSequence.new(L.c)
		b.Width0, b.Width1 = 0, 0
		b.Segments = 10 -- при 1 Beam не рисуется
		L.t = 1 - (1 - L.t) * power
		b.Transparency = softSeq(L.t, 0.12, 0.9)
		pcall(function()
			b.Brightness = 2
		end)
		b.Parent = holder
		table.insert(beams, { beam = b, L = L })
	end
	-- пылинки, медленно поднимающиеся в свете
	local motesPart = basePart(folder, Vector3.new(2.2 * s, height * 0.9, 2.2 * s), CFrame.new(ground + Vector3.new(0, height * 0.45, 0)), color, nil, 1)
	local motes = emitter(motesPart, {
		Color = ColorSequence.new(white),
		LightEmission = 1,
		LightInfluence = 0,
		Lifetime = NumberRange.new(2, 3.5),
		Speed = NumberRange.new(0.3, 1.2),
		Acceleration = Vector3.new(0, 1.5, 0),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.22 * s), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1), NumberSequenceKeypoint.new(1, 1) }),
		SpreadAngle = Vector2.new(180, 180),
	})
	pcall(function()
		motes.Shape = Enum.ParticleEmitterShape.Cylinder
		motes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end)
	-- свет на земле
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 0
	light.Brightness = 3
	light.Shadows = false
	light.Parent = holder
	local glow = basePart(folder, Vector3.new(0.05, 1, 1), CFrame.new(ground + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Neon, 0.82, Enum.PartType.Cylinder)
	local intensity = 0
	local alive = true
	local function apply(k, pulse)
		for _, B in ipairs(beams) do
			local w = B.L.w * s * k * pulse
			B.beam.Width0 = w * (opts.rise and 0.75 or 1)
			B.beam.Width1 = w
		end
		light.Range = 18 * s * k
		glow.Size = Vector3.new(0.05, 7 * s * k, 7 * s * k)
	end
	-- появление: луч опускается с неба (или вырастает из земли) и раскрывается
	task.spawn(function()
		local t0 = os.clock()
		local dur = opts.rise and 0.35 or 0.5
		while alive and os.clock() - t0 < dur do
			local k = (os.clock() - t0) / dur
			local e = 1 - (1 - k) ^ 3
			if opts.rise then
				aTop.Position = Vector3.new(0, low + (height - low) * e, 0)
			else
				aBot.Position = Vector3.new(0, low + (height - low) * (1 - e), 0)
			end
			intensity = 0.35 + 0.65 * e
			apply(intensity, 1)
			frame()
		end
		if not alive then
			return
		end
		aTop.Position, aBot.Position = Vector3.new(0, height, 0), Vector3.new(0, low, 0)
		intensity = 1
		motes.Rate = 14 * s
		-- вспышка-кольцо в точке удара
		local ring = basePart(folder, Vector3.new(0.05, 2, 2), CFrame.new(ground + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)), white, Enum.Material.Neon, 0.3, Enum.PartType.Cylinder)
		TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { Size = Vector3.new(0.05, 16 * s, 16 * s), Transparency = 1 }):Play()
		task.delay(0.75, function()
			ring:Destroy()
		end)
		light.Brightness = 8
		TweenService:Create(light, TweenInfo.new(0.6), { Brightness = 3 }):Play()
	end)
	local shaft = {}
	function shaft.update(e)
		if alive and intensity >= 1 then
			apply(1, 1 + 0.06 * math.sin(e * 2.3) + 0.03 * math.sin(e * 5.1))
		end
	end
	function shaft.fade(sec)
		if not alive then
			return
		end
		alive = false
		motes.Rate = 0
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < sec do
				local k = 1 - (os.clock() - t0) / sec
				for _, B in ipairs(beams) do
					B.beam.Transparency = softSeq(1 - (1 - B.L.t) * k, 0.12, 0.9)
					B.beam.Width0 = B.L.w * s * (0.6 + 0.4 * k)
					B.beam.Width1 = B.beam.Width0
				end
				light.Brightness = 3 * k
				glow.Transparency = 1 - 0.18 * k
				frame()
			end
			holder:Destroy()
			motesPart:Destroy()
			glow:Destroy()
		end)
	end
	return shaft
end

return T
