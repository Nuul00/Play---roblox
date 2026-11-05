-- Острова лидеров: в каждом из 6 миров у края площадки строится отдельный парящий островок в стиле мира,
-- к нему ведёт мост с перилами и арка «TOP PLAYERS». На острове — три доски (PICKUPS / EGGS / COINS)
-- полукругом и 3D-пьедесталы с аватарами топ-3. Направление выбирается само: край площадки, куда мост
-- проходит, не задевая порталов/магазинов/яиц/скал, а сам остров не врезается в соседние острова и горы.
-- Старые доски Meadow и Neon (стояли в плейсе) убираются в ServerStorage.OldLeaderboards, если остров построен.
-- Имена для WorldProgress: LeaderboardIsland_<мир> с BoardCoins/BoardEggs/BoardPickups (внутри Rig_*)
-- и Podium_<доска> (Place1..3 — цилиндры-ступени, Plate1..3 с PlayerName).
-- Анимации делает клиент (LeaderboardFX): BoardFloat (парение), BoardEmblem (вращение), BoardPulse (мерцание).
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local B = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local BOARD_W, BOARD_H = 17, 7.2
local R = 42 -- радиус острова
local GAP = 22 -- пролёт моста над пустотой
local BRIDGE_W = 10
local ORDER = { "BoardPickups", "BoardEggs", "BoardCoins" } -- слева направо для того, кто пришёл по мосту

local THEMES = {
	Meadow = {
		Board = rgb(30, 70, 45), Frame = rgb(120, 80, 45), FrameMat = M.Wood, Trim = rgb(255, 220, 120), TrimMat = M.Neon,
		Title = rgb(255, 225, 130), Sub = rgb(220, 245, 210), Legs = true, LegColor = rgb(110, 72, 40), Leaves = true,
		Steps = { rgb(255, 205, 60), rgb(220, 225, 235), rgb(220, 140, 80) }, StepMat = M.SmoothPlastic, StepRim = M.Neon,
		Top = rgb(110, 200, 90), TopMat = M.Grass, Under = rgb(120, 95, 70), UnderMat = M.Slate, Rim = rgb(90, 160, 70), RimMat = M.Grass,
		Deck = rgb(150, 100, 60), DeckMat = M.WoodPlanks, Rail = rgb(110, 72, 40), RailMat = M.Wood, Lamp = rgb(255, 210, 120),
		Arch = rgb(120, 80, 45), ArchMat = M.Wood, ArchInk = rgb(90, 50, 10),
	},
	NeonCity = {
		Board = rgb(12, 10, 30), Frame = rgb(30, 26, 60), FrameMat = M.Metal, Trim = rgb(255, 80, 220), TrimMat = M.Neon, Trim2 = rgb(80, 230, 255),
		Title = rgb(255, 130, 240), Sub = rgb(120, 235, 255), Legs = true, LegColor = rgb(40, 36, 80), Pulse = true,
		Steps = { rgb(255, 215, 90), rgb(200, 210, 255), rgb(255, 140, 200) }, StepMat = M.Glass, StepRim = M.Neon,
		Top = rgb(22, 18, 44), TopMat = M.Metal, Under = rgb(30, 26, 60), UnderMat = M.Metal, Rim = rgb(255, 80, 220), RimMat = M.Neon, Grid = rgb(80, 230, 255),
		Deck = rgb(26, 22, 50), DeckMat = M.Metal, Rail = rgb(80, 230, 255), RailMat = M.Neon, Lamp = rgb(255, 80, 220),
		Arch = rgb(30, 26, 60), ArchMat = M.Metal, ArchInk = rgb(120, 20, 120), ArchGlow = rgb(255, 80, 220),
	},
	SkyIsles = {
		Board = rgb(40, 70, 120), Frame = rgb(250, 250, 255), FrameMat = M.SmoothPlastic, Trim = rgb(255, 215, 110), TrimMat = M.Neon,
		Title = rgb(255, 225, 130), Sub = rgb(200, 235, 255), Legs = true, LegColor = rgb(235, 240, 255), Clouds = true,
		Float = { Bob = 0.45, Sway = 0.8, Speed = 0.7 },
		Steps = { rgb(255, 210, 80), rgb(225, 232, 245), rgb(240, 160, 100) }, StepMat = M.SmoothPlastic, StepRim = M.Neon,
		Top = rgb(245, 240, 255), TopMat = M.SmoothPlastic, Under = rgb(255, 255, 255), UnderMat = M.SmoothPlastic, Rim = rgb(255, 215, 110), RimMat = M.Neon, Puffs = true,
		Deck = rgb(255, 250, 255), DeckMat = M.SmoothPlastic, Rail = rgb(255, 215, 110), RailMat = M.Neon, Lamp = rgb(255, 230, 150),
		Arch = rgb(255, 255, 255), ArchMat = M.SmoothPlastic, ArchInk = rgb(170, 110, 30), ArchGlow = rgb(255, 215, 110),
	},
	FrozenPeaks = {
		Board = rgb(20, 55, 95), Frame = rgb(170, 225, 255), FrameMat = M.Glacier, Trim = rgb(140, 230, 255), TrimMat = M.Neon,
		Title = rgb(190, 240, 255), Sub = rgb(150, 210, 255), Legs = true, LegColor = rgb(150, 205, 240), Snow = true, Sparkle = rgb(200, 245, 255),
		Steps = { rgb(255, 215, 110), rgb(210, 235, 255), rgb(235, 165, 120) }, StepMat = M.Ice, StepRim = M.Neon,
		Top = rgb(245, 250, 255), TopMat = M.Snow, Under = rgb(150, 205, 240), UnderMat = M.Glacier, Rim = rgb(140, 230, 255), RimMat = M.Ice, Icicles = true,
		Deck = rgb(180, 225, 250), DeckMat = M.Ice, Rail = rgb(245, 250, 255), RailMat = M.Snow, Lamp = rgb(150, 230, 255),
		Arch = rgb(170, 225, 255), ArchMat = M.Glacier, ArchInk = rgb(20, 70, 130), ArchGlow = rgb(140, 230, 255),
	},
	MagmaVolcano = {
		Board = rgb(28, 18, 18), Frame = rgb(40, 30, 32), FrameMat = M.Basalt, Trim = rgb(255, 110, 30), TrimMat = M.Neon,
		Title = rgb(255, 170, 70), Sub = rgb(255, 210, 150), Legs = true, LegColor = rgb(45, 35, 35), Pulse = true, Embers = rgb(255, 140, 40),
		Steps = { rgb(255, 190, 60), rgb(190, 190, 200), rgb(210, 120, 70) }, StepMat = M.Basalt, StepRim = M.Neon,
		Top = rgb(60, 36, 30), TopMat = M.CrackedLava, Under = rgb(40, 30, 32), UnderMat = M.Basalt, Rim = rgb(255, 110, 30), RimMat = M.Neon, Cracks = rgb(255, 120, 30),
		Deck = rgb(45, 35, 35), DeckMat = M.Basalt, Rail = rgb(255, 110, 30), RailMat = M.Neon, Lamp = rgb(255, 140, 40),
		Arch = rgb(40, 30, 32), ArchMat = M.Basalt, ArchInk = rgb(120, 30, 0), ArchGlow = rgb(255, 110, 30),
	},
	CosmicGalaxy = {
		Board = rgb(14, 10, 40), Frame = rgb(60, 50, 110), FrameMat = M.Metal, Trim = rgb(120, 230, 255), TrimMat = M.Neon, Trim2 = rgb(255, 110, 220),
		Title = rgb(255, 150, 240), Sub = rgb(140, 230, 255), Legs = false, Lift = 7, Stardust = rgb(200, 190, 255),
		Float = { Bob = 1.1, Sway = 2.5, Speed = 0.5 },
		Steps = { rgb(255, 215, 110), rgb(200, 210, 255), rgb(240, 150, 200) }, StepMat = M.Glass, StepRim = M.Neon,
		Top = rgb(20, 16, 50), TopMat = M.Glass, Under = rgb(50, 40, 100), UnderMat = M.Slate, Rim = rgb(120, 230, 255), RimMat = M.Neon, Grid = rgb(255, 110, 220), Asteroids = true,
		Deck = rgb(40, 34, 90), DeckMat = M.Glass, Rail = rgb(120, 230, 255), RailMat = M.Neon, Lamp = rgb(200, 160, 255),
		Arch = rgb(60, 50, 110), ArchMat = M.Metal, ArchInk = rgb(60, 0, 90), ArchGlow = rgb(255, 110, 220),
	},
}

local GHOST = { CanCollide = false, CanQuery = false, CanTouch = false }
local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end
local function cyl(parent, name, height, diameter, cf, color, mat, props)
	-- вертикальный цилиндр (ось X повёрнута вверх)
	local p = part(parent, name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), color, mat, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(parent, name, d, pos, color, mat, props)
	local p = part(parent, name, Vector3.new(d, d, d), CFrame.new(pos), color, mat, props)
	p.Shape = Enum.PartType.Ball
	return p
end
local function emitter(parent, color, rate, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Rate = rate
	e.Lifetime = NumberRange.new(1.5, 3)
	e.Speed = NumberRange.new(0.3, 1)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	if props then
		for k, v in props do
			e[k] = v
		end
	end
	e.Parent = parent
	return e
end
local function light(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Parent = parent
	return l
end
local function text(parent, face, str, ink, font, ppStud)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = ppStud or 40
	g.LightInfluence = 0
	g.MaxDistance = 220
	g.Parent = parent
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(0.94, 0.8)
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.52)
	t.Font = font or Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = str
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = g
	local st = Instance.new("UIStroke")
	st.Thickness = 5
	st.Color = ink
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.Parent = t
	return t
end

local function isCoin(inst)
	return string.match(inst.Name, "^Coin_%d+$") ~= nil or inst:FindFirstAncestor("CoinFX") ~= nil
end

-- ===== доска (рамка, кант, ножки, стиль мира) =====
local function buildBoard(model, theme, name, cf)
	local rig = Instance.new("Model")
	rig.Name = "Rig_" .. name
	rig.Parent = model
	local lift = theme.Lift or 0
	local center = cf * CFrame.new(0, lift + 3.2 + BOARD_H / 2, 0)
	local board = part(rig, name, Vector3.new(BOARD_W, BOARD_H, 0.6), center, theme.Board, M.SmoothPlastic, { CanCollide = true })
	board:SetAttribute("TitleColor", theme.Title)
	board:SetAttribute("SubColor", theme.Sub)
	board:SetAttribute("NoLight", true)
	board:SetAttribute("TrimColor", theme.Trim)
	local t = 1.1
	local fw, fh = BOARD_W + t * 2, BOARD_H + t * 2
	for _, b in {
		{ "FrameTop", Vector3.new(fw, t, 1.4), CFrame.new(0, BOARD_H / 2 + t / 2, 0.2) },
		{ "FrameBottom", Vector3.new(fw, t, 1.4), CFrame.new(0, -BOARD_H / 2 - t / 2, 0.2) },
		{ "FrameLeft", Vector3.new(t, fh, 1.4), CFrame.new(-BOARD_W / 2 - t / 2, 0, 0.2) },
		{ "FrameRight", Vector3.new(t, fh, 1.4), CFrame.new(BOARD_W / 2 + t / 2, 0, 0.2) },
	} do
		part(rig, b[1], b[2], center * b[3], theme.Frame, theme.FrameMat, GHOST)
	end
	-- светящийся кант по контуру доски (спереди)
	for i, b in {
		{ Vector3.new(BOARD_W + 0.2, 0.22, 0.2), CFrame.new(0, BOARD_H / 2 + 0.05, -0.45) },
		{ Vector3.new(BOARD_W + 0.2, 0.22, 0.2), CFrame.new(0, -BOARD_H / 2 - 0.05, -0.45) },
		{ Vector3.new(0.22, BOARD_H + 0.2, 0.2), CFrame.new(-BOARD_W / 2 - 0.05, 0, -0.45) },
		{ Vector3.new(0.22, BOARD_H + 0.2, 0.2), CFrame.new(BOARD_W / 2 + 0.05, 0, -0.45) },
	} do
		local color = theme.Trim2 and i % 2 == 0 and theme.Trim2 or theme.Trim
		local trim = part(rig, "Trim", b[1], center * b[2], color, theme.TrimMat, GHOST)
		if theme.Pulse then
			CollectionService:AddTag(trim, "BoardPulse")
		end
	end
	-- ножки для «наземных» миров
	if theme.Legs then
		for _, x in { -BOARD_W / 2 + 1.5, BOARD_W / 2 - 1.5 } do
			local h = lift + 3.2
			part(rig, "Leg", Vector3.new(1, h + 0.5, 1), cf * CFrame.new(x, h / 2, 0.4), theme.LegColor, theme.FrameMat)
		end
	end
	-- стиль мира
	if theme.Snow then
		part(rig, "SnowCap", Vector3.new(fw + 0.6, 0.7, 2), center * CFrame.new(0, fh / 2 + 0.2, 0.2), rgb(250, 252, 255), M.Snow, GHOST)
		for i = -3, 3 do
			local len = 0.8 + (i % 3) * 0.5
			part(rig, "Icicle", Vector3.new(0.35, len, 0.35), center * CFrame.new(i * 3.1, -fh / 2 - len / 2, -0.3), rgb(190, 235, 255), M.Ice, GHOST)
		end
	end
	if theme.Clouds then
		for i = -2, 2 do
			local d = 4.6 - math.abs(i) * 0.4
			local puff = part(rig, "CloudPuff", Vector3.new(d, d, d), cf * CFrame.new(i * 4.4, 1.6 + (i % 2) * 0.5, 0.3), rgb(255, 255, 255), M.SmoothPlastic, GHOST)
			puff.Shape = Enum.PartType.Ball
		end
	end
	if theme.Embers then
		local src = part(rig, "Embers", Vector3.new(BOARD_W, 0.2, 1), cf * CFrame.new(0, 0.3, -0.6), theme.Embers, M.SmoothPlastic, GHOST)
		src.Transparency = 1
		emitter(src, theme.Embers, 4, {
			Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(10, 10), EmissionDirection = Enum.NormalId.Top,
			Lifetime = NumberRange.new(1.5, 2.5), Acceleration = Vector3.new(0, 1, 0),
		})
	end
	if theme.Sparkle then
		emitter(board, theme.Sparkle, 3, { EmissionDirection = Enum.NormalId.Front })
	end
	if theme.Stardust then
		local glow = part(rig, "Thruster", Vector3.new(BOARD_W * 0.7, 0.3, 2.4), center * CFrame.new(0, -fh / 2 - 1.2, 0.2), theme.Trim, M.Neon, GHOST)
		glow.Transparency = 0.35
		emitter(glow, theme.Stardust, 5, {
			EmissionDirection = Enum.NormalId.Bottom, Speed = NumberRange.new(1, 2.5), SpreadAngle = Vector2.new(25, 25),
			Lifetime = NumberRange.new(1, 2),
		})
		emitter(board, theme.Stardust, 3, { Speed = NumberRange.new(0.2, 0.6) })
		local l = Instance.new("PointLight")
		l.Color = theme.Trim
		l.Range = 16
		l.Brightness = 1.2
		l.Parent = glow
	end
	if theme.Float then
		CollectionService:AddTag(rig, "BoardFloat")
		rig:SetAttribute("Bob", theme.Float.Bob)
		rig:SetAttribute("Sway", theme.Float.Sway)
		rig:SetAttribute("Speed", theme.Float.Speed)
		rig:SetAttribute("Phase", #model:GetChildren() * 0.9)
	end
	rig.PrimaryPart = board
	return board
end


-- ===== 3D-пьедестал =====
local MEDAL = { rgb(255, 205, 50), rgb(215, 222, 235), rgb(215, 130, 70) }
local function buildPodium(model, theme, name, cf)
	local podium = Instance.new("Model")
	podium.Name = "Podium_" .. name
	local look = cf.LookVector
	podium:SetAttribute("Yaw", math.atan2(-look.X, -look.Z))
	podium.Parent = model
	-- для зрителя: 2 слева, 1 по центру (выше всех), 3 справа
	local H = { 3, 2.1, 1.4 }
	local X = { 0, 4.7, -4.7 }
	local base = cf * CFrame.new(0, 0, -6.5)
	-- круглый помост с кантом
	cyl(podium, "Base", 0.7, 16, base * CFrame.new(0, 0.35, 0), theme.Frame, theme.FrameMat)
	local rim = cyl(podium, "Rim", 0.25, 16.6, base * CFrame.new(0, 0.62, 0), theme.Trim, M.Neon, GHOST)
	rim.Transparency = 0.15
	for place = 1, 3 do
		local h = H[place]
		local at = base * CFrame.new(X[place], 0.7, 0)
		-- ступень-цилиндр, тёмное «основание» и светящееся кольцо по верхнему краю
		cyl(podium, "StepFoot" .. place, 0.4, 4.8, at * CFrame.new(0, 0.2, 0), theme.Steps[place]:Lerp(Color3.new(0, 0, 0), 0.35), theme.StepMat)
		cyl(podium, "Place" .. place, h, 4.3, at * CFrame.new(0, h / 2, 0), theme.Steps[place], theme.StepMat)
		local ring = cyl(podium, "StepRing" .. place, 0.3, 4.6, at * CFrame.new(0, h - 0.1, 0), MEDAL[place], theme.StepRim or M.Neon, GHOST)
		ring.Transparency = 0.05
		-- медаль с цифрой на лицевой стороне ступени
		local medal = part(podium, "Medal" .. place, Vector3.new(0.35, 1.5, 1.5), at * CFrame.new(0, math.max(h - 0.95, 0.9), -2.15) * CFrame.Angles(0, math.rad(90), 0), MEDAL[place], M.Metal, GHOST)
		medal.Shape = Enum.PartType.Cylinder
		medal.Reflectance = 0.15
		for _, f in { Enum.NormalId.Left, Enum.NormalId.Right } do
			text(medal, f, tostring(place), MEDAL[place]:Lerp(Color3.new(0, 0, 0), 0.55), Enum.Font.LuckiestGuy, 80)
		end
		-- табличка с именем у подножия
		local plate = part(podium, "Plate" .. place, Vector3.new(3.8, 0.9, 0.25), at * CFrame.new(0, 0.12 + 0.45, -2.45), rgb(48, 44, 86), M.SmoothPlastic, GHOST)
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 60
		g.LightInfluence = 0
		g.Parent = plate
		local tl = Instance.new("TextLabel")
		tl.Name = "PlayerName"
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.fromScale(0.94, 0.86)
		tl.AnchorPoint = Vector2.new(0.5, 0.5)
		tl.Position = UDim2.fromScale(0.5, 0.5)
		tl.Font = Enum.Font.FredokaOne
		tl.TextScaled = true
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.Text = "—"
		tl.Parent = g
		if place == 1 then
			emitter(ring, MEDAL[1], 4, { Speed = NumberRange.new(0.5, 1.2), EmissionDirection = Enum.NormalId.Top })
		end
	end
	return podium
end

-- ===== остров =====
local function buildIsland(island, theme, ic, groundY)
	local pos = ic.Position
	local function at(y)
		return CFrame.new(pos.X, groundY + y, pos.Z) * ic.Rotation
	end
	cyl(island, "Top", 2.4, R * 2, at(-1.2), theme.Top, theme.TopMat)
	local rim = cyl(island, "RimBand", 1.8, R * 2 + 3, at(-1.5), theme.Rim, theme.RimMat)
	if theme.RimMat == M.Neon then
		rim.Transparency = 0.1
		CollectionService:AddTag(rim, "BoardPulse")
	end
	-- «корень» острова — ступенчатый конус вниз
	local layers = { { 6, 0.9 }, { 6, 0.7 }, { 6, 0.48 }, { 5, 0.26 } }
	local y = -2.4
	for i, l in layers do
		y -= l[1] / 2
		cyl(island, "Under" .. i, l[1], R * 2 * l[2], at(y), theme.Under:Lerp(Color3.new(0, 0, 0), i * 0.08), theme.UnderMat, GHOST)
		y -= l[1] / 2
	end
	if theme.Grid then
		for k = -3, 3 do
			local off = k * R / 4
			local len = 2 * math.sqrt(math.max(0, R * R - off * off)) - 2
			local a = part(island, "Grid", Vector3.new(0.35, 0.08, len), ic * CFrame.new(off, 0, 0) + Vector3.new(0, groundY - pos.Y + 0.04, 0), theme.Grid, M.Neon, GHOST)
			local b = part(island, "Grid", Vector3.new(len, 0.08, 0.35), ic * CFrame.new(0, 0, off) + Vector3.new(0, groundY - pos.Y + 0.04, 0), theme.Grid, M.Neon, GHOST)
			a.Transparency, b.Transparency = 0.35, 0.35
		end
	end
	if theme.Cracks then
		local rng = Random.new(5)
		for i = 1, 9 do
			local a = rng:NextNumber(0, math.pi * 2)
			local r0 = rng:NextNumber(8, R - 8)
			local c = part(island, "Crack", Vector3.new(0.5, 0.08, rng:NextNumber(5, 11)), CFrame.new(pos.X + math.cos(a) * r0, groundY + 0.04, pos.Z + math.sin(a) * r0) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), theme.Cracks, M.Neon, GHOST)
			CollectionService:AddTag(c, "BoardPulse")
		end
		local src = part(island, "EmberSource", Vector3.new(R * 1.6, 0.2, R * 1.6), at(0.2), theme.Cracks, M.SmoothPlastic, GHOST)
		src.Transparency = 1
		emitter(src, theme.Embers or theme.Cracks, 6, {
			Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(15, 15), EmissionDirection = Enum.NormalId.Top,
			Lifetime = NumberRange.new(2, 3.5), Acceleration = Vector3.new(0, 1, 0),
		})
	end
	if theme.Puffs then
		for i = 0, 15 do
			local a = i / 16 * math.pi * 2
			local d = 7 + (i % 3) * 2
			ball(island, "Puff", d, Vector3.new(pos.X + math.cos(a) * (R + 1), groundY - 2 - (i % 2) * 2, pos.Z + math.sin(a) * (R + 1)), rgb(255, 255, 255), M.SmoothPlastic, GHOST)
		end
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2 + 0.3
			ball(island, "Puff", 10, Vector3.new(pos.X + math.cos(a) * R * 0.55, groundY - 12, pos.Z + math.sin(a) * R * 0.55), rgb(250, 245, 255), M.SmoothPlastic, GHOST)
		end
	end
	if theme.Icicles then
		local rng = Random.new(9)
		for i = 0, 17 do
			local a = i / 18 * math.pi * 2
			local len = rng:NextNumber(3, 7)
			part(island, "Icicle", Vector3.new(1.2, len, 1.2), CFrame.new(pos.X + math.cos(a) * (R - 1), groundY - 3 - len / 2, pos.Z + math.sin(a) * (R - 1)) * CFrame.Angles(0, a, 0), rgb(190, 235, 255), M.Ice, GHOST).Transparency = 0.15
		end
		emitter(island.Top, theme.Sparkle, 6, { EmissionDirection = Enum.NormalId.Top })
	end
	if theme.Leaves then
		local src = part(island, "LeafFX", Vector3.new(R * 1.4, 0.2, R * 1.4), at(18), theme.Top, M.SmoothPlastic, GHOST)
		src.Transparency = 1
		local e = emitter(src, rgb(150, 230, 110), 4, {
			Color = ColorSequence.new(rgb(150, 230, 110), rgb(255, 200, 90)), LightEmission = 0.3,
			Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(0.4, 1), EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0.5, -0.6, 0), RotSpeed = NumberRange.new(-90, 90), Rotation = NumberRange.new(0, 360),
		})
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.25) })
	end
	if theme.Asteroids then
		local ring = Instance.new("Model")
		ring.Name = "Asteroids"
		local hub = part(ring, "Hub", Vector3.new(0.2, 0.2, 0.2), at(4), theme.Rim, M.SmoothPlastic, GHOST)
		hub.Transparency = 1
		ring.PrimaryPart = hub
		local rng = Random.new(3)
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			local d = rng:NextNumber(1.6, 3.6)
			ball(ring, "Rock", d, Vector3.new(pos.X + math.cos(a) * (R + 9), groundY + rng:NextNumber(-6, 10), pos.Z + math.sin(a) * (R + 9)), rgb(90, 80, 130), M.Slate, GHOST)
		end
		ring.Parent = island
		ring:SetAttribute("Spin", 5)
		ring:SetAttribute("Bob", 0.6)
		CollectionService:AddTag(ring, "BoardEmblem")
	end
end


-- ===== 3D-декор острова из моделей мира (ReplicatedStorage.TripoProps) =====
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function prop(name)
	local f = ReplicatedStorage:FindFirstChild("TripoProps")
	return f and f:FindFirstChild(name)
end
-- копия модели размером size (по большей стороне), стоящая основанием на `bottom`
local function placeProp(parent, name, size, bottom)
	local t = prop(name)
	if not t then return nil end
	local m = t:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local _, ext = m:GetBoundingBox()
	pcall(function() m:ScaleTo(m:GetScale() * size / math.max(ext.X, ext.Y, ext.Z, 0.01)) end)
	local cf, ext2 = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(cf)
	m:PivotTo(bottom * CFrame.new(0, ext2.Y / 2, 0) * offset:Inverse())
	m.Name = "Decor_" .. name
	m.Parent = parent
	return m
end
-- места на острове (в осях острова: −Z — к мосту): {x, z, слот}
local SLOTS = {
	{ -27, -17, "A1" }, { 27, -17, "A2" },   -- у входа, по бокам дорожки
	{ -35, -1, "B1" }, { 35, -1, "B2" },      -- по краям, между входом и досками
	{ -26, 33, "C1" }, { 26, 33, "C2" },     -- дальние углы за боковыми досками
	{ -13, -33, "L" }, { 13, -33, "L" },     -- фонари у арки
	{ -39, -15, "L" }, { 39, -15, "L" },      -- фонари по бокам
	{ 0, 39, "L" },                          -- фонарь за центральной доской
}
local DECOR = {
	Meadow = { A1 = { "MeadowFountain", 9 }, A2 = { "MeadowBench", 5.5 }, B1 = { "MeadowMushroom", 9 }, B2 = { "MeadowMushroom", 7 }, C1 = { "MeadowWindmill", 15 }, C2 = { "MeadowMushroom", 8 }, L = { "MeadowLamp", 8 } },
	NeonCity = { A1 = { "NeonVending", 8 }, A2 = { "NeonArcade", 8 }, B1 = { "NeonPalm", 14 }, B2 = { "NeonPalm", 13 }, C1 = { "NeonHoverCar", 9, 5 }, C2 = { "NeonPalm", 12 }, L = { "NeonLamp", 9 } },
	SkyIsles = { A1 = { "SkyStatue", 9 }, A2 = { "SkyBalloon", 12, 6 }, B1 = { "SkyBalloon", 10, 10 }, B2 = { "SkyStatue", 8 }, C1 = { "SkyIsland", 14, 12 }, C2 = { "SkyBalloon", 11, 8 }, L = { "SkyLamp", 8 } },
	FrozenPeaks = { A1 = { "Snowman", 7 }, A2 = { "PenguinStatue", 7 }, B1 = { "SnowPine", 14 }, B2 = { "SnowPine", 12 }, C1 = { "Igloo", 12 }, C2 = { "IceCrystals", 9 }, L = { "FrozenLamp", 9 } },
	MagmaVolcano = { A1 = { "LavaFountain", 9 }, A2 = { "LavaPillar", 8 }, B1 = { "LavaTree1", 13 }, B2 = { "LavaTree2", 13 }, C1 = { "LavaTree2", 11 }, C2 = { "LavaTree1", 11 }, L = { "LavaPillar", 7 } },
	CosmicGalaxy = { A1 = { "AlienMonolith", 9 }, A2 = { "SpaceObservatory", 11 }, B1 = { "PlanetPillar", 12 }, B2 = { "PlanetPillar", 11 }, C1 = { "AlienMonolith", 8 }, C2 = { "SpaceObservatory", 9 }, L = { "PlanetPillar", 8 } },
}
local function decorateIsland(island, key, theme, ic, groundY)
	local list = DECOR[key]
	if not list then return end
	local pos = ic.Position
	for i, sl in SLOTS do
		local d = list[sl[3]]
		if d then
			local p = ic * CFrame.new(sl[1], 0, sl[2])
			-- смотрим в центр острова, чуть случайный поворот, чтобы не было «по линейке»
			local face = CFrame.lookAt(Vector3.new(p.X, groundY + (d[3] or 0), p.Z), Vector3.new(pos.X, groundY + (d[3] or 0), pos.Z)) * CFrame.Angles(0, math.rad((i * 37) % 30 - 15), 0)
			local m = placeProp(island, d[1], d[2], face)
			if m and sl[3] == "L" then
				local any = m:FindFirstChildWhichIsA("BasePart", true)
				if any then light(any, theme.Lamp, 18, 1.4) end
			end
			if m and d[3] then
				-- парящие вещи (шары, островок, ховеркар) тихо покачиваются
				CollectionService:AddTag(m, "BoardEmblem")
				m:SetAttribute("Spin", 0)
				m:SetAttribute("Bob", 0.8)
			end
		end
	end
	-- дорожка от арки к доскам
	local walk = part(island, "Walk", Vector3.new(8, 0.12, 30), ic * CFrame.new(0, 0, -22) + Vector3.new(0, groundY - pos.Y + 0.06, 0), theme.Deck, theme.DeckMat, GHOST)
	if theme.DeckMat == M.Glass then walk.Transparency = 0.2 end
	for _, s in { -1, 1 } do
		local e = part(island, "WalkEdge", Vector3.new(0.4, 0.16, 30), ic * CFrame.new(s * 4.1, 0, -22) + Vector3.new(0, groundY - pos.Y + 0.08, 0), theme.Rail, theme.RailMat, GHOST)
		if theme.RailMat == M.Neon then CollectionService:AddTag(e, "BoardPulse") end
	end
end

-- ===== мост и арка =====
local function buildBridge(island, theme, from, to, groundY)
	local a = Vector3.new(from.X, groundY, from.Z)
	local b = Vector3.new(to.X, groundY, to.Z)
	local L = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	local deck = part(island, "BridgeDeck", Vector3.new(BRIDGE_W, 1, L), cf * CFrame.new(0, -0.5, 0), theme.Deck, theme.DeckMat)
	if theme.DeckMat == M.Glass then deck.Transparency = 0.2 end
	for _, s in { -1, 1 } do
		local edge = part(island, "BridgeEdge", Vector3.new(0.6, 0.9, L), cf * CFrame.new(s * (BRIDGE_W / 2 - 0.3), 0.2, 0), theme.Rail, theme.RailMat, GHOST)
		if theme.RailMat == M.Neon then CollectionService:AddTag(edge, "BoardPulse") end
		-- перила: столбики и поручень (поручень твёрдый — с моста не упасть)
		for z = -L / 2 + 1, L / 2 - 1, 5 do
			part(island, "BridgePost", Vector3.new(0.5, 3.2, 0.5), cf * CFrame.new(s * (BRIDGE_W / 2 - 0.3), 1.6, z), theme.Rail, theme.RailMat == M.Neon and M.Metal or theme.RailMat, GHOST)
		end
		part(island, "BridgeRail", Vector3.new(0.4, 0.4, L), cf * CFrame.new(s * (BRIDGE_W / 2 - 0.3), 3.3, 0), theme.Rail, theme.RailMat)
		part(island, "BridgeGuard", Vector3.new(0.3, 3.4, L), cf * CFrame.new(s * (BRIDGE_W / 2 - 0.2), 1.7, 0), theme.Rail, M.SmoothPlastic, { Transparency = 1, CanQuery = false })
	end
	if theme.Puffs then
		for z = -L / 2, L / 2, 5 do
			ball(island, "BridgePuff", 6, (cf * CFrame.new(0, -2.5, z)).Position, rgb(255, 255, 255), M.SmoothPlastic, GHOST)
		end
	end
	-- арка «TOP PLAYERS» у входа на остров
	local gate = CFrame.lookAt(b, a) * CFrame.new(0, 0, 3)
	for _, s in { -1, 1 } do
		part(island, "ArchPillar", Vector3.new(2, 11, 2), gate * CFrame.new(s * (BRIDGE_W / 2 + 1.5), 5.5, 0), theme.Arch, theme.ArchMat)
		ball(island, "ArchKnob", 2.6, (gate * CFrame.new(s * (BRIDGE_W / 2 + 1.5), 11.4, 0)).Position, theme.ArchGlow or theme.Lamp, M.Neon, GHOST)
	end
	local beam = part(island, "ArchBeam", Vector3.new(BRIDGE_W + 7, 3.2, 1.6), gate * CFrame.new(0, 12.2, 0), theme.Arch, theme.ArchMat)
	local glow = part(island, "ArchGlow", Vector3.new(BRIDGE_W + 6, 0.35, 1.7), gate * CFrame.new(0, 10.5, 0), theme.ArchGlow or theme.Lamp, M.Neon, GHOST)
	light(glow, theme.ArchGlow or theme.Lamp, 16, 1.5)
	for _, f in { Enum.NormalId.Front, Enum.NormalId.Back } do
		text(beam, f, "🏆 TOP PLAYERS", theme.ArchInk, Enum.Font.LuckiestGuy, 50)
	end
end

-- ===== выбор направления =====
local IMPORTANT = { "Portal", "EggStand", "Shop", "Machine", "Chest", "Statue", "Podium", "Board", "Spawn", "Start",
	"Mountain", "Volcano", "Pond", "Lake", "Igloo", "Rink", "Observatory", "Monument", "Fountain", "Windmill",
	"Tower", "House", "Arch", "Gate", "Lava", "River", "Planet", "Balloon", "Rainbow", "Sign" }
local function relName(q, model)
	local full = q:GetFullName()
	local mf = model:GetFullName()
	if string.sub(full, 1, #mf) == mf then
		full = string.sub(full, #mf + 1)
	end
	return full
end
local function isImportant(q, model)
	if not q:IsDescendantOf(model) or math.max(q.Size.X, q.Size.Z) > 25 then
		return true
	end
	local full = relName(q, model)
	for _, k in IMPORTANT do
		if string.find(full, k, 1, true) then
			return true
		end
	end
	return false
end
local allParts
local function parts()
	if not allParts then
		allParts = {}
		for i, q in workspace:GetDescendants() do
			if i % 8000 == 0 then task.wait() end
			if q:IsA("BasePart") and not q:IsDescendantOf(workspace.Terrain) and not isCoin(q) and q.Transparency < 0.95 then
				table.insert(allParts, q)
			end
		end
	end
	return allParts
end
local function chars()
	local list = {}
	for _, p in Players:GetPlayers() do
		if p.Character then table.insert(list, p.Character) end
	end
	return list
end
-- первая видимая твёрдая поверхность под точкой (прозрачное и монеты пропускаем)
local function rayDown(origin, depth)
	local ignore = chars()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.IgnoreWater = true
	for _ = 1, 8 do
		rp.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(origin, Vector3.new(0, -depth, 0), rp)
		if not hit then return nil end
		local q = hit.Instance
		if q:IsA("BasePart") and (q.Transparency >= 0.95 or isCoin(q) or (not q.CanCollide and q.Size.Y < 0.6)) then
			table.insert(ignore, q)
		else
			return hit
		end
	end
	return nil
end
local function findDirection(model, spawn, groundY)
	local list = parts()
	local near = {}
	for _, q in list do
		if q.Parent and Vector2.new(q.Position.X - spawn.X, q.Position.Z - spawn.Z).Magnitude < 420 and q.Position.Y < groundY + 60 and q.Position.Y > groundY - 60 then
			table.insert(near, q)
		end
	end
	local best, bestScore, bestInfo, bestRemove, bestY
	local why = {}
	for deg = 0, 350, 10 do
		task.wait()
		local a = math.rad(deg)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local base = Vector3.new(spawn.X, groundY, spawn.Z)
		local edge
		local blocked
		for d = 8, 330, 4 do
			local hit = rayDown(base + dir * d + Vector3.new(0, 25, 0), 70)
			if not hit or hit.Position.Y < groundY - 4 then
				edge = d
				break
			end
		end
		if not edge then
			why[#why + 1] = deg .. ":noedge"
			continue
		end
		-- высота начала моста: там, где игрок на него заходит (в Meadow это склон холма у берега)
		local head = rayDown(base + dir * (edge - 8) + Vector3.new(0, 40, 0), 80)
		local hy = head and head.Position.Y or groundY
		if hy > groundY + 25 or hy < groundY - 6 then
			why[#why + 1] = deg .. ":steep"
			continue
		end
		local center = base + dir * (edge + GAP + R)
		local removable = {}
		-- остров и пролёт не задевают ничего; у начала моста (последние 14 стадов площадки) нет важного
		for _, q in near do
			local off = q.Position - base
			local along = off:Dot(dir)
			local side = math.abs(off:Dot(Vector3.new(-dir.Z, 0, dir.X)))
			local r = math.max(q.Size.X, q.Size.Z) / 2
			local top, bottom = q.Position.Y + q.Size.Y / 2, q.Position.Y - q.Size.Y / 2
			local inIsland = Vector2.new(q.Position.X - center.X, q.Position.Z - center.Z).Magnitude < R + 10 + math.min(r, 30) and top > hy - 30 and bottom < hy + 30
			local inSpan = along > edge and along < edge + GAP + 2 and side < BRIDGE_W / 2 + 3 + math.min(r, 20) and top > hy - 6 and bottom < hy + 14
			local atHead = along > edge - 14 and along <= edge and side < BRIDGE_W / 2 + 2 + math.min(r, 20) and top > hy + 1 and bottom < hy + 14
			local thin = q.Size.Y < 0.5 and not q.CanCollide -- светящиеся линии на полу
			if (inIsland or inSpan or atHead) and not thin then
				-- мелкий декор (облачка, камни пояса астероидов, ёлки) убираем, важное и крупное — нет
				local fluff = (string.find(q.Name, "Puff", 1, true) or string.find(q.Name, "Cloud", 1, true)) and math.max(q.Size.X, q.Size.Z) < 60
				if not fluff and (isImportant(q, model) or math.max(q.Size.X, q.Size.Y, q.Size.Z) > 20) then
					blocked = q
					break
				end
				table.insert(removable, q)
			end
		end
		if blocked then
			why[#why + 1] = deg .. ":" .. blocked.Name
			continue
		end
		-- Terrain (холмы, скалы Meadow) запросы по деталям не видят: щупаем лучами.
		-- Вдоль моста ничего не торчит выше настила, под островом нет суши выше его «корня».
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local bump
		for d = edge - 6, edge + GAP, 3 do
			for _, s in { -BRIDGE_W / 2, 0, BRIDGE_W / 2 } do
				local hit = rayDown(base + dir * d + side * s + Vector3.new(0, 50, 0), 90)
				if hit and hit.Position.Y > hy + 1.5 and not hit.Instance:IsDescendantOf(model) or (hit and hit.Instance:IsA("Terrain") and hit.Position.Y > hy + 1.5) then
					bump = true
					break
				end
			end
			if bump then break end
		end
		if not bump then
			for k = 0, 12 do
				local a2 = k / 12 * math.pi * 2
				local rr = k == 0 and 0 or R * 0.85
				local hit = rayDown(center + Vector3.new(math.cos(a2) * rr, 40, math.sin(a2) * rr), 90)
				if hit and hit.Position.Y > hy - 12 then
					bump = true
					break
				end
			end
		end
		if bump then
			why[#why + 1] = deg .. ":terrain"
			continue
		end
		local score = edge + #removable * 2
		if not bestScore or score < bestScore then
			best, bestScore, bestInfo, bestRemove, bestY = dir, score, edge, removable, hy
		end
	end
	model:SetAttribute("LeaderboardIslandWhy", table.concat(why, " "))
	return best, bestInfo, near, bestRemove, bestY
end

-- пьедестал из плейса (как в Meadow / Neon): копия, уменьшенная под доску острова, в цветах мира
local podiumTpl = {}
local function placePodium(island, theme, name, cf, tpl)
	local m = tpl.model:Clone()
	for _, c in m:GetChildren() do
		if string.match(c.Name, "^Winner") or c.Name:match("^PodiumSpot") then c:Destroy() end
	end
	pcall(function() m:ScaleTo(m:GetScale() * 0.72) end)
	local bcf, size = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(bcf)
	local target = CFrame.new((cf * CFrame.new(0, size.Y / 2, -7)).Position) * cf.Rotation * tpl.rot
	m:PivotTo(target * offset:Inverse())
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d.Name == "Plinth" or d.Name == "Foot" then
				d.Color = theme.Frame
				d.Material = theme.FrameMat
			end
		end
	end
	m.Name = "Podium_" .. name
	local look = cf.LookVector
	m:SetAttribute("Yaw", math.atan2(-look.X, -look.Z))
	m.Parent = island
	return m
end
local function grabTemplate(zone)
	local board = zone and zone:FindFirstChild("BoardEggs")
	local pod = zone and zone:FindFirstChild("Podium_BoardEggs")
	if not (board and pod) then return nil end
	local copy = pod:Clone()
	for _, c in copy:GetChildren() do
		if string.match(c.Name, "^Winner") or c.Name:match("^PodiumSpot") then c:Destroy() end
	end
	-- поворот пьедестала относительно своей доски (доски на острове повёрнуты иначе)
	local rot = board.CFrame.Rotation:Inverse() * pod:GetPivot().Rotation
	return { model = copy, rot = rot }
end

function B.Build(world)
	local built = {}
	podiumTpl.Meadow = grabTemplate(world)
	podiumTpl.Neon = grabTemplate(world:FindFirstChild("NeonCity"))
	local neon = world:FindFirstChild("NeonCity")
	local worlds = {
		{ "Meadow", world, Vector3.new(0, 3 + (world:GetAttribute("GroundY") or 0), 180) },
		{ "NeonCity", neon, neon and neon:FindFirstChild("Floor") and Vector3.new(neon.Floor.Position.X, 3, 180) },
	}
	for _, key in { "SkyIsles", "FrozenPeaks", "MagmaVolcano", "CosmicGalaxy" } do
		local m = world:WaitForChild(key, 60)
		table.insert(worlds, { key, m, m and m:GetAttribute("Spawn") })
	end
	for _, w in worlds do
		local key, model, spawn = w[1], w[2], w[3]
		local theme = THEMES[key]
		if not model or typeof(spawn) ~= "Vector3" or model:FindFirstChild("LeaderboardIsland_" .. key) then
			continue
		end
		local g = rayDown(spawn + Vector3.new(0, 5, 0), 30)
		local groundY = g and g.Position.Y or spawn.Y - 3
		local dir, edge, near, remove, hy = findDirection(model, spawn, groundY)
		if not dir then
			warn("[Leaderboards] no island direction in " .. key)
			continue
		end
		local base = Vector3.new(spawn.X, hy, spawn.Z)
		local center = base + dir * (edge + GAP + R)
		local ic = CFrame.lookAt(center, center - dir) -- остров «смотрит» на мост
		local island = Instance.new("Model")
		island.Name = "LeaderboardIsland_" .. key
		island:SetAttribute("WorldKey", key)
		buildIsland(island, theme, ic, hy)
		decorateIsland(island, key, theme, ic, hy)
		buildBridge(island, theme, base + dir * (edge - 8), center - dir * (R - 1), hy)
		-- мелкий декор на месте острова, моста и у начала моста убираем
		for _, q in remove do
			if q.Parent then
				local root = q
				while root.Parent and root.Parent ~= model and not root.Parent:IsA("Folder") and #root.Parent:GetChildren() <= 12 do
					root = root.Parent
				end
				root:Destroy()
			end
		end
		-- невидимые стенки-границы мира на месте моста пропускают игрока
		for _, q in near do
			if q.Parent then
				local off = q.Position - base
				local along = off:Dot(dir)
				local side = math.abs(off:Dot(Vector3.new(-dir.Z, 0, dir.X)))
				if along > edge - 14 and along < edge + GAP + 2 and side < BRIDGE_W / 2 + 2 + math.min(math.max(q.Size.X, q.Size.Z) / 2, 6) and q.Position.Y + q.Size.Y / 2 > hy + 1 and q.Position.Y - q.Size.Y / 2 < hy + 14 and not isImportant(q, model) then
					local root = q
					while root.Parent and root.Parent ~= model and not root.Parent:IsA("Folder") and #root.Parent:GetChildren() <= 12 do
						root = root.Parent
					end
					root:Destroy()
				end
			end
		end
		for _, q in model:GetDescendants() do
			if q:IsA("BasePart") and q.Transparency >= 0.95 and q.CanCollide then
				local off = q.Position - base
				local along = off:Dot(dir)
				local side = math.abs(off:Dot(Vector3.new(-dir.Z, 0, dir.X)))
				if along > edge - 20 and along < edge + GAP + 4 and side < BRIDGE_W / 2 + q.Size.Magnitude / 2 then
					q.CanCollide = false
				end
			end
		end
		-- доски полукругом, лицом к мосту
		local focus = ic * CFrame.new(0, 0, -8)
		for i, name in ORDER do
			-- дуга радиуса 34: центры досок в ~21 стаде друг от друга — рамки и пьедесталы не наезжают
			local ang = math.rad(({ 38, 0, -38 })[i])
			local cf = focus * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, 34)
			buildBoard(island, theme, name, cf)
			local tpl = (key == "NeonCity" or key == "CosmicGalaxy") and podiumTpl.Neon or podiumTpl.Meadow
			if not (tpl and placePodium(island, theme, name, cf, tpl)) then
				buildPodium(island, theme, name, cf)
			end
		end
		island.Parent = model
		-- старые доски Meadow/Neon (из плейса) — в хранилище
		if key == "Meadow" or key == "NeonCity" then
			local store = ServerStorage:FindFirstChild("OldLeaderboards") or Instance.new("Folder")
			store.Name = "OldLeaderboards"
			store.Parent = ServerStorage
			for _, c in model:GetChildren() do
				if (string.match(c.Name, "^Board") or string.match(c.Name, "^Podium_") or c.Name == "LeafFX") and c ~= island then
					c.Parent = store
				end
			end
		end
		island:SetAttribute("Edge", edge)
		table.insert(built, island)
	end
	return built
end

return B
