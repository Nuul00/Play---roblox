-- Анимация Неонграда (только у игрока, только когда он в Neon District):
-- переливающаяся дорога, бегущая разметка, огни по бордюрам, вращающееся радужное кольцо,
-- и портал на остров. Яйца оживляет EggBillboards.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local city = workspace:WaitForChild("CoinSpeedWorld"):WaitForChild("NeonCity")
local streets = city:WaitForChild("NeonStreets")

local fxFolder = Instance.new("Folder")
fxFolder.Name = "NeonRoadFX_Local"
fxFolder.Parent = workspace

local function newPart(name, size, cf, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = fxFolder
	return p
end

-- ===== Сбор деталей =====
local dashes, ring, curbs, crosswalks, guis, hues, emitters = {}, {}, {}, {}, {}, {}, {}
for _, d in ipairs(streets:GetDescendants()) do
	if d:IsA("BasePart") then
		if d.Name == "LaneDash" then
			table.insert(dashes, { part = d, base = d.CFrame })
		elseif d.Name == "PlazaRing" then
			-- 2026-11 (фидбэк): радужное кольцо на площади убрано — дорога идёт насквозь
			d.Transparency = 1
		elseif d.Name == "CurbLine" or d.Name == "CurbGlow" then
			table.insert(curbs, d)
		elseif d.Name == "Crosswalk" then
			table.insert(crosswalks, d)
		end
	elseif d:IsA("SurfaceGui") then
		table.insert(guis, d)
		local hue = d:GetAttribute("Hue")
		local label = d:FindFirstChildOfClass("TextLabel")
		if hue and label then
			table.insert(hues, { label = label, hue = hue, stroke = label:FindFirstChildOfClass("UIStroke") })
		end
	elseif d:IsA("ParticleEmitter") then
		table.insert(emitters, d)
	end
end

-- Разметка едет вдоль дороги: каждый штрих сдвигается на шаг между штрихами и возвращается.
local dashStep = 8
if #dashes > 1 then
	local zs = {}
	for _, d in ipairs(dashes) do
		table.insert(zs, d.base.Position.Z)
	end
	table.sort(zs)
	local gaps = {}
	for i = 2, #zs do
		local g = zs[i] - zs[i - 1]
		if g > 0.5 then
			table.insert(gaps, g)
		end
	end
	table.sort(gaps)
	dashStep = gaps[math.max(1, math.floor(#gaps / 2))] or 8
end
for _, d in ipairs(dashes) do
	d.part.Color = Color3.fromRGB(255, 225, 90)
	d.part.Material = Enum.Material.Neon
end

-- Центр радужного кольца.
local ringCenter = Vector3.zero
for _, r in ipairs(ring) do
	ringCenter += r.base.Position
end
if #ring > 0 then
	ringCenter /= #ring
end
local ringRadius = 0
for _, r in ipairs(ring) do
	ringRadius += (r.base.Position - ringCenter).Magnitude / #ring
end
-- Второе, внутреннее пунктирное кольцо крутится навстречу.
local innerRing = {}
if #ring > 0 then
	for k = 0, 35 do
		if k % 2 == 0 then
			local a = k / 36 * math.pi * 2
			local p = newPart("InnerRing", Vector3.new(0.35, 0.08, 1.4), CFrame.new(), Color3.new(1, 1, 1))
			table.insert(innerRing, { part = p, angle = a })
		end
	end
end

-- Огни, бегущие по бордюрам.
local comets = {}
for i, curb in ipairs(curbs) do
	local axis = curb.Size.Z >= curb.Size.X and "Z" or "X"
	local len = axis == "Z" and curb.Size.Z or curb.Size.X
	for k = 1, 7 do
		local p = newPart("Comet", Vector3.new(0.3, 0.16, 6), curb.CFrame, Color3.new(1, 1, 1))
		table.insert(comets, { part = p, curb = curb, axis = axis, len = len, phase = k / 7, dir = i % 2 == 0 and 1 or -1 })
	end
end

-- Переливающееся покрытие дорог: полупрозрачные цветные волны по верхней грани.
local roadTiles = {}
local TILE = 24
for _, name in ipairs({ "MainPath", "ShopPath", "EggPath" }) do
	local road = city:FindFirstChild(name)
	if road and road:IsA("BasePart") then
		local long = math.max(road.Size.X, road.Size.Z)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RoadGlow"
		gui.Face = Enum.NormalId.Top
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 2
		gui.LightInfluence = 0
		gui.Brightness = 1.4
		gui.Adornee = road
		gui.Parent = fxFolder
		local clip = Instance.new("Frame")
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Size = UDim2.fromScale(1, 1)
		clip.Parent = gui
		local alongY = road.Size.Z >= road.Size.X
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromScale(1, 1)
		holder.Parent = clip
		local count = math.ceil(long / TILE) + 2
		for k = 0, count - 1 do
			local tile = Instance.new("Frame")
			tile.BorderSizePixel = 0
			tile.BackgroundColor3 = Color3.new(1, 1, 1)
			if alongY then
				tile.Size = UDim2.new(1, 0, 0, TILE * 2)
				tile.Position = UDim2.fromOffset(0, (k - 1) * TILE * 2)
			else
				tile.Size = UDim2.new(0, TILE * 2, 1, 0)
				tile.Position = UDim2.fromOffset((k - 1) * TILE * 2, 0)
			end
			tile.Parent = holder
			local grad = Instance.new("UIGradient")
			grad.Rotation = alongY and 90 or 0
			grad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.92),
				NumberSequenceKeypoint.new(0.5, 0.62),
				NumberSequenceKeypoint.new(1, 0.92),
			})
			grad.Parent = tile
			table.insert(roadTiles, { tile = tile, grad = grad, k = k, holder = holder, alongY = alongY })
		end
	end
end

-- Портал: кольцо переливается и «дышит».
local portalRing = {}
local portal = city:FindFirstChild("IslandPortal")
if portal then
	for _, p in ipairs(portal:GetChildren()) do
		if p.Name == "PortalRing" then
			table.insert(portalRing, p)
		end
	end
end
local portalDisc = city:FindFirstChild("PortalToIsland")

-- Работает, когда камера рядом с Неонградом (как бы игрок туда ни попал).
local cityCenter = city:WaitForChild("Floor").Position
local player = game:GetService("Players").LocalPlayer
local function active()
	-- только когда игрок в Неонграде (раньше — по расстоянию камеры, работало и из других миров)
	return player:GetAttribute("CurrentWorld") == "Neon District"
end
local function setVisible(visible)
	for _, g in ipairs(guis) do
		g.Enabled = visible
	end
	for _, e in ipairs(emitters) do
		e.Enabled = visible
	end
	fxFolder.Parent = visible and workspace or nil
end
local shown = nil

-- ===== Изогнутая дорога к лидербордам (LeaderboardRoad, строит WorldPolish) =====
-- Пунктир продолжает бег с улицы: та же скорость и фаза, по кривой Безье. Бордюры изгиба
-- берут цвет бордюров улицы с тем же смещением (Dx).
local mainPath = city:FindFirstChild("MainPath")
local curve = nil
local function bezAt(c, t)
	local u = 1 - t
	return c.P0 * (u * u * u) + c.P1 * (3 * u * u * t) + c.P2 * (3 * u * t * t) + c.P3 * (t * t * t)
end
local function setupCurve(road)
	local P0, P1, P2, P3 = road:GetAttribute("P0"), road:GetAttribute("P1"), road:GetAttribute("P2"), road:GetAttribute("P3")
	if typeof(P0) ~= "Vector3" or not mainPath then
		return
	end
	local c = { P0 = P0, P1 = P1, P2 = P2, P3 = P3, start = road:GetAttribute("DashStart") or 5, samples = {}, dashes = {}, strips = {} }
	-- таблица длины дуги
	local prev, s = bezAt(c, 0), 0
	table.insert(c.samples, { t = 0, s = 0 })
	for i = 1, 200 do
		local tt = i / 200
		local p = bezAt(c, tt)
		s += (p - prev).Magnitude
		prev = p
		table.insert(c.samples, { t = tt, s = s })
	end
	c.total = s
	local sample
	for _, d in ipairs(road:GetChildren()) do
		if d:IsA("BasePart") then
			if d.Name == "RoadDash" then
				sample = sample or d
				d.LocalTransparencyModifier = 1 -- статичные штрихи сервера прячем, рисуем бегущие
			elseif d.Name == "RoadStrip" then
				table.insert(c.strips, { part = d, dx = d:GetAttribute("Dx") or 0 })
			end
		end
	end
	if sample then
		c.dashY = sample.Position.Y
		for k = 1, math.floor(c.total / dashStep) + 2 do
			local p = newPart("CurveDash", sample.Size, CFrame.new(), Color3.fromRGB(255, 225, 90))
			table.insert(c.dashes, p)
		end
	end
	curve = c
end
local function tAtArc(c, s)
	local lo, hi = 1, #c.samples
	while hi - lo > 1 do
		local m = (lo + hi) // 2
		if c.samples[m].s < s then
			lo = m
		else
			hi = m
		end
	end
	local a, b = c.samples[lo], c.samples[hi]
	local f = (b.s - a.s) > 0 and (s - a.s) / (b.s - a.s) or 0
	return a.t + (b.t - a.t) * f
end
local function curveStep(shift, t)
	local c = curve
	if not c then
		local road = city:FindFirstChild("LeaderboardRoad")
		if road then
			setupCurve(road)
		end
		return
	end
	for k, p in ipairs(c.dashes) do
		local s = c.start + (k - 2) * dashStep + shift
		if s < 0.5 or s > c.total - 0.5 then
			p.Transparency = 1
		else
			local tt = tAtArc(c, s)
			local pos = bezAt(c, tt)
			local ahead = bezAt(c, math.min(tt + 0.01, 1))
			local back = bezAt(c, math.max(tt - 0.01, 0))
			local at = Vector3.new(pos.X, c.dashY, pos.Z)
			p.CFrame = CFrame.lookAt(at, at + Vector3.new(ahead.X - back.X, 0, ahead.Z - back.Z))
			p.Transparency = 0.15 * (0.5 + 0.5 * math.sin(pos.Z * 0.08 - t * 4))
		end
	end
	-- цвет бордюров изгиба = цвет бордюра улицы с тем же смещением
	local mx = mainPath.Position.X
	for _, st in ipairs(c.strips) do
		local best, bd = nil, 0.3
		for _, cb in ipairs(curbs) do
			local d = math.abs((cb.Position.X - mx) - st.dx)
			if d < bd then
				best, bd = cb, d
			end
		end
		if best then
			st.part.Color = best.Color
		end
	end
end

local t = 0
local acc, tileClock = 0, 1
RunService.RenderStepped:Connect(function(dt)
	local now = active()
	if now ~= shown then
		shown = now
		setVisible(now)
	end
	if not now then
		return
	end
	-- 20 раз в секунду хватает для плавной разметки, а сотни деталей не двигаются каждый кадр
	acc += dt
	if acc < 1 / 20 then
		return
	end
	t += acc
	tileClock += acc
	acc = 0
	local tilesNow = tileClock >= 0.2
	if tilesNow then
		tileClock = 0
	end

	-- Разметка едет к порталу и пульсирует волной.
	local shift = (t * 10) % dashStep
	for _, d in ipairs(dashes) do
		d.part.CFrame = d.base + Vector3.new(0, 0, shift)
		d.part.Transparency = 0.15 * (0.5 + 0.5 * math.sin(d.base.Position.Z * 0.08 - t * 4))
	end

	curveStep(shift, t)

	-- Покрытие дорог: цветные волны плывут и меняют оттенок.
	for _, r in ipairs(tilesNow and roadTiles or {}) do
		local off = (t * 14) % (TILE * 2)
		if r.k == 0 then
			r.holder.Position = r.alongY and UDim2.fromOffset(0, off) or UDim2.fromOffset(off, 0)
		end
		local hue = (t * 0.05 - ((r.k - 1) + off / (TILE * 2)) * 0.09) % 1
		r.tile.BackgroundColor3 = Color3.fromHSV(hue, 0.75, 1)
	end

	-- Бордюры: мягкая пульсация и бегущие огни.
	local curbHue = (t * 0.08) % 1
	for i, c in ipairs(curbs) do
		c.Color = Color3.fromHSV((curbHue + i * 0.5) % 1, 0.8, 1)
	end
	for _, c in ipairs(comets) do
		local s = ((c.phase + t * 0.06 * c.dir) % 1 - 0.5) * c.len
		local offset = c.axis == "Z" and Vector3.new(0, 0, s) or Vector3.new(s, 0, 0)
		local rot = c.axis == "Z" and CFrame.identity or CFrame.Angles(0, math.pi / 2, 0)
		c.part.CFrame = CFrame.new(c.curb.Position + offset + Vector3.new(0, 0.12, 0)) * rot
		c.part.Color = Color3.fromHSV((curbHue + 0.15) % 1, 0.4, 1)
	end
	for i, cw in ipairs(crosswalks) do
		cw.Transparency = 0.1 + 0.5 * (0.5 + 0.5 * math.sin(t * 3 - i * 0.6))
	end

	-- Радужное кольцо вращается, цвета бегут по кругу.
	local spin = t * 0.5
	local n = #ring
	for i, r in ipairs(ring) do
		local rot = CFrame.new(ringCenter) * CFrame.Angles(0, spin, 0) * CFrame.new(-ringCenter)
		r.part.CFrame = rot * r.base
		r.part.Color = Color3.fromHSV((t * 0.15 + i / n) % 1, 0.85, 1)
	end
	for i, r in ipairs(innerRing) do
		local a = r.angle - t * 0.8
		local pos = ringCenter + Vector3.new(math.cos(a), 0, math.sin(a)) * (ringRadius * 0.82)
		r.part.CFrame = CFrame.new(pos) * CFrame.Angles(0, -a, 0)
		r.part.Color = Color3.fromHSV((t * 0.15 + 0.5 + i / #innerRing) % 1, 0.6, 1)
	end

	-- Портал.
	for i, p in ipairs(portalRing) do
		p.Color = Color3.fromHSV((0.38 + 0.12 * math.sin(t * 2 + i / #portalRing * math.pi * 2)) % 1, 0.7, 1)
	end
	if portalDisc and not portalDisc:GetAttribute("Dressed") then
		portalDisc.Transparency = 0.15 + 0.15 * math.sin(t * 3)
	end

	-- Подписи с атрибутом Hue переливаются (как раньше).
	for _, h in ipairs(hues) do
		local hue = (h.hue + t * 0.05) % 1
		h.label.TextColor3 = Color3.fromHSV(hue, 0.45, 1)
		if h.stroke then
			h.stroke.Color = Color3.fromHSV((hue + 0.5) % 1, 0.9, 1)
		end
	end
end)
