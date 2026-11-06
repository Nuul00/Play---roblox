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

local BOARD_W, BOARD_H = 32, 14.5 -- одна доска с вкладками (на 30% меньше прежней 46x21)
local R = 58 -- радиус острова
local GAP = 22 -- пролёт моста над пустотой
local BRIDGE_W = 10
local ORDER = { "BoardPickups", "BoardEggs", "BoardCoins" } -- слева направо для того, кто пришёл по мосту

local THEMES = {
	Meadow = {
		Board = rgb(30, 70, 45), Frame = rgb(120, 80, 45), FrameMat = M.Wood, Trim = rgb(255, 220, 120), TrimMat = M.Neon,
		Title = rgb(255, 225, 130), Sub = rgb(220, 245, 210), Legs = true, LegColor = rgb(110, 72, 40), Leaves = true, Lift = 11,
		Steps = { rgb(255, 205, 60), rgb(220, 225, 235), rgb(220, 140, 80) }, StepMat = M.SmoothPlastic, StepRim = M.Neon,
		Top = rgb(110, 200, 90), TopMat = M.Grass, Under = rgb(120, 95, 70), UnderMat = M.Slate, Rim = rgb(90, 160, 70), RimMat = M.Grass,
		Deck = rgb(150, 100, 60), DeckMat = M.WoodPlanks, Rail = rgb(110, 72, 40), RailMat = M.Wood, Lamp = rgb(255, 210, 120),
		Arch = rgb(120, 80, 45), ArchMat = M.Wood, ArchInk = rgb(90, 50, 10),
	},
	NeonCity = {
		Board = rgb(12, 10, 30), Frame = rgb(30, 26, 60), FrameMat = M.Metal, Trim = rgb(255, 80, 220), TrimMat = M.Neon, Trim2 = rgb(80, 230, 255),
		Title = rgb(255, 130, 240), Sub = rgb(120, 235, 255), Legs = true, LegColor = rgb(40, 36, 80), Pulse = true, Lift = 11,
		Steps = { rgb(255, 215, 90), rgb(200, 210, 255), rgb(255, 140, 200) }, StepMat = M.Glass, StepRim = M.Neon,
		Top = rgb(22, 18, 44), TopMat = M.Metal, Under = rgb(30, 26, 60), UnderMat = M.Metal, Rim = rgb(255, 80, 220), RimMat = M.Neon, Grid = rgb(80, 230, 255),
		Deck = rgb(26, 22, 50), DeckMat = M.Metal, Rail = rgb(80, 230, 255), RailMat = M.Neon, Lamp = rgb(255, 80, 220),
		Arch = rgb(30, 26, 60), ArchMat = M.Metal, ArchInk = rgb(120, 20, 120), ArchGlow = rgb(255, 80, 220),
	},
	SkyIsles = {
		Board = rgb(40, 70, 120), Frame = rgb(250, 250, 255), FrameMat = M.SmoothPlastic, Trim = rgb(255, 215, 110), TrimMat = M.Neon,
		Title = rgb(255, 225, 130), Sub = rgb(200, 235, 255), Legs = true, LegColor = rgb(235, 240, 255), Clouds = true, Lift = 11,
		Float = { Bob = 0.45, Sway = 0.8, Speed = 0.7 },
		Steps = { rgb(255, 210, 80), rgb(225, 232, 245), rgb(240, 160, 100) }, StepMat = M.SmoothPlastic, StepRim = M.Neon,
		Top = rgb(245, 240, 255), TopMat = M.SmoothPlastic, Under = rgb(255, 255, 255), UnderMat = M.SmoothPlastic, Rim = rgb(255, 215, 110), RimMat = M.Neon, Puffs = true,
		Deck = rgb(255, 250, 255), DeckMat = M.SmoothPlastic, Rail = rgb(255, 215, 110), RailMat = M.Neon, Lamp = rgb(255, 230, 150),
		Arch = rgb(255, 255, 255), ArchMat = M.SmoothPlastic, ArchInk = rgb(170, 110, 30), ArchGlow = rgb(255, 215, 110),
	},
	FrozenPeaks = {
		Board = rgb(20, 55, 95), Frame = rgb(170, 225, 255), FrameMat = M.Glacier, Trim = rgb(140, 230, 255), TrimMat = M.Neon,
		Title = rgb(190, 240, 255), Sub = rgb(150, 210, 255), Legs = true, LegColor = rgb(150, 205, 240), Snow = true, Sparkle = rgb(200, 245, 255), Lift = 11,
		Steps = { rgb(255, 215, 110), rgb(210, 235, 255), rgb(235, 165, 120) }, StepMat = M.Ice, StepRim = M.Neon,
		Top = rgb(245, 250, 255), TopMat = M.Snow, Under = rgb(150, 205, 240), UnderMat = M.Glacier, Rim = rgb(140, 230, 255), RimMat = M.Ice, Icicles = true,
		Deck = rgb(180, 225, 250), DeckMat = M.Ice, Rail = rgb(245, 250, 255), RailMat = M.Snow, Lamp = rgb(150, 230, 255),
		Arch = rgb(170, 225, 255), ArchMat = M.Glacier, ArchInk = rgb(20, 70, 130), ArchGlow = rgb(140, 230, 255),
	},
	MagmaVolcano = {
		Board = rgb(28, 18, 18), Frame = rgb(40, 30, 32), FrameMat = M.Basalt, Trim = rgb(255, 110, 30), TrimMat = M.Neon,
		Title = rgb(255, 170, 70), Sub = rgb(255, 210, 150), Legs = true, LegColor = rgb(45, 35, 35), Pulse = true, Embers = rgb(255, 140, 40), Lift = 11,
		Steps = { rgb(255, 190, 60), rgb(190, 190, 200), rgb(210, 120, 70) }, StepMat = M.Basalt, StepRim = M.Neon,
		Top = rgb(60, 36, 30), TopMat = M.CrackedLava, Under = rgb(40, 30, 32), UnderMat = M.Basalt, Rim = rgb(255, 110, 30), RimMat = M.Neon, Cracks = rgb(255, 120, 30),
		Deck = rgb(45, 35, 35), DeckMat = M.Basalt, Rail = rgb(255, 110, 30), RailMat = M.Neon, Lamp = rgb(255, 140, 40),
		Arch = rgb(40, 30, 32), ArchMat = M.Basalt, ArchInk = rgb(120, 30, 0), ArchGlow = rgb(255, 110, 30),
	},
	CosmicGalaxy = {
		Board = rgb(14, 10, 40), Frame = rgb(60, 50, 110), FrameMat = M.Metal, Trim = rgb(120, 230, 255), TrimMat = M.Neon, Trim2 = rgb(255, 110, 220),
		Title = rgb(255, 150, 240), Sub = rgb(140, 230, 255), Legs = false, Lift = 14, Stardust = rgb(200, 190, 255),
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
	{ -37, -28, "A1" }, { 37, -28, "A2" },   -- у входа, по бокам дорожки
	{ -48, -4, "B1" }, { 48, -4, "B2" },     -- по краям, между входом и досками
	-- всё держим внутри радиуса ~52 (R = 58, по краю заборчик/бортик) — ничего не висит над пустотой
	{ -26, 44, "C1" }, { 26, 44, "C2" },     -- позади, между досками
	{ -16, -49, "L" }, { 16, -49, "L" },     -- фонари у арки
	{ -46, -24, "L" }, { 46, -24, "L" },     -- фонари по бокам
	{ 0, 50, "L" },                          -- фонарь за центральной доской
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
	local walk = part(island, "Walk", Vector3.new(8, 0.12, 40), ic * CFrame.new(0, 0, -34) + Vector3.new(0, groundY - pos.Y + 0.06, 0), theme.Deck, theme.DeckMat, GHOST)
	if theme.DeckMat == M.Glass then walk.Transparency = 0.2 end
	for _, s in { -1, 1 } do
		local e = part(island, "WalkEdge", Vector3.new(0.4, 0.16, 40), ic * CFrame.new(s * 4.1, 0, -34) + Vector3.new(0, groundY - pos.Y + 0.08, 0), theme.Rail, theme.RailMat, GHOST)
		if theme.RailMat == M.Neon then CollectionService:AddTag(e, "BoardPulse") end
	end
end


-- ===== сад для острова Meadow (чтобы не казался пустым): деревья, клумбы, кусты, прудик, пикник, заборчик, бабочки =====
local PETALS = { rgb(255, 120, 160), rgb(255, 215, 80), rgb(170, 130, 255), rgb(255, 255, 255), rgb(255, 150, 70), rgb(120, 190, 255) }
local BLOSSOM = { rgb(255, 180, 210), rgb(255, 205, 225), rgb(250, 150, 190) }
local function meadowGarden(island, ic, groundY)
	local pos = ic.Position
	local function at(x, z, y)
		return ic * CFrame.new(x, 0, z) + Vector3.new(0, groundY - pos.Y + (y or 0), 0)
	end
	-- занятые места: доска с пьедесталом, дорожка/мост, слоты декора
	local busy = { { 0, 24, 24 }, { 0, -40, 9 }, { 0, -22, 7 } }
	for _, sl in SLOTS do
		table.insert(busy, { sl[1], sl[2], sl[3] == "L" and 4 or 9 })
	end
	local function free(x, z, r)
		if x * x + z * z > (R - 5) ^ 2 then return false end
		if math.abs(x) < 7 + r and z < -12 then return false end -- дорожка к мосту
		for _, b in busy do
			if (x - b[1]) ^ 2 + (z - b[2]) ^ 2 < (b[3] + r) ^ 2 then return false end
		end
		return true
	end
	local function take(x, z, r)
		table.insert(busy, { x, z, r })
	end
	local rng = Random.new(11)

	-- цветущие деревья
	local function tree(x, z, h)
		local m = Instance.new("Model")
		m.Name = "GardenTree"
		local base = at(x, z)
		cyl(m, "Trunk", h, 2.4, base * CFrame.new(0, h / 2, 0), rgb(120, 80, 50), M.Wood, GHOST)
		for k, c in { { 0, 0, 0, 7.5 }, { 2.6, -1, 1, 5.5 }, { -2.4, -0.6, -1.2, 5.8 }, { 0.6, 1.6, -2.2, 5 }, { -0.8, -1.2, 2.6, 5 } } do
			ball(m, "Crown", c[4] * 1.35, (base * CFrame.new(c[1] * 1.35, h + c[2] * 1.35, c[3] * 1.35)).Position, BLOSSOM[(k % #BLOSSOM) + 1], M.SmoothPlastic, GHOST)
		end
		local e = emitter(m:FindFirstChild("Crown"), rgb(255, 190, 215), 3, {
			Color = ColorSequence.new(rgb(255, 190, 215), rgb(255, 240, 245)), LightEmission = 0.2,
			Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(0.3, 0.8), Acceleration = Vector3.new(0.4, -0.7, 0),
			RotSpeed = NumberRange.new(-90, 90), Rotation = NumberRange.new(0, 360),
		})
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.2) })
		m.Parent = island
		take(x, z, 9)
	end
	tree(-44, 28, 12)
	tree(44, 28, 13)
	tree(-14, 48, 11)
	tree(14, 48, 11.5)
	tree(-28, -44, 9)
	tree(28, -44, 9.5)

	-- живой пруд (по мотивам облачного острова). Вода — из деталей, а не Terrain: Terrain рисует воду
	-- клетками по 4 студа, на мелком пруду сквозь неё просвечивала трава и край был «восьмиугольником».
	-- Здесь круглая чаша: тёмное дно с камешками → толща воды (стекло) → по глади расходятся круги
	-- (клиент LeaderboardFX, тег IslandPond). Бортик и горка — из угловатых сланцевых глыб, как у пруда
	-- в самом Meadow. Водопад сидит в расщелине горки и падает прямо в воду.
	do
		local px, pz, PR = -33, 4, 8.5
		local WATER_H = 1.1 -- гладь над травой
		local stone = { rgb(128, 128, 122), rgb(150, 146, 136), rgb(112, 116, 112) }
		local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
		local function slab(x, z, y, sx, sy, sz, tilt)
			local c = at(x, z, y) * CFrame.Angles(rng:NextNumber(-tilt, tilt), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-tilt, tilt))
			return part(island, "PondStone", Vector3.new(sx, sy, sz), c, stone[rng:NextInteger(1, 3)], M.Slate, GHOST)
		end
		-- дно: песчаная кайма → тёмная середина, на дне редкие камешки
		cyl(island, "PondShore", 0.12, PR * 2 + 2, at(px, pz, 0.06), rgb(205, 185, 140), M.Sand, GHOST)
		cyl(island, "PondBed", 0.12, PR * 2, at(px, pz, 0.12), rgb(45, 110, 120), M.Sand, GHOST)
		cyl(island, "PondDeep", 0.12, PR * 1.25, at(px, pz, 0.16), rgb(28, 78, 98), M.Sand, GHOST)
		for _ = 1, 9 do
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(1, PR - 1.5)
			local s = rng:NextNumber(0.4, 0.8)
			part(island, "BedPebble", Vector3.new(s * 1.3, s * 0.5, s), at(px + math.cos(a) * r, pz + math.sin(a) * r, 0.3) * CFrame.Angles(0, a, 0), stone[rng:NextInteger(1, 3)], M.Slate, GHOST)
		end
		-- толща воды и гладь
		local water = cyl(island, "PondWater", WATER_H - 0.15, PR * 2, at(px, pz, 0.15 + (WATER_H - 0.15) / 2), rgb(70, 165, 210), M.Glass, GHOST)
		water.Transparency = 0.45
		water.Reflectance = 0.12
		water:SetAttribute("Radius", PR - 1.2)
		CollectionService:AddTag(water, "IslandPond")
		local shine = cyl(island, "PondShine", 0.04, PR * 2 - 0.3, at(px, pz, WATER_H + 0.01), rgb(200, 240, 255), M.SmoothPlastic, GHOST)
		shine.Transparency = 0.82
		shine.Reflectance = 0.3
		-- бортик: угловатые глыбы плотно по кругу (под водопадом проход), сверху местами мох
		local n = 34
		for i = 0, n - 1 do
			local a = i / n * math.pi * 2 + rng:NextNumber(-0.04, 0.04)
			if math.sin(a) > 0.93 then continue end
			local r = PR + 0.5
			local sx, sy, sz = rng:NextNumber(1.8, 2.5), rng:NextNumber(1.3, 1.9), rng:NextNumber(1.4, 1.9)
			local s = slab(px + math.cos(a) * r, pz + math.sin(a) * r, sy / 2 - 0.1, sx, sy, sz, 0.18)
			if i % 4 == 0 then
				part(island, "Moss", Vector3.new(sx * 0.7, 0.18, sz * 0.6), s.CFrame * CFrame.new(0, sy / 2, 0), rgb(95, 165, 75), M.Grass, GHOST)
			end
			if i % 2 == 0 then
				-- второй, внешний ряд мельче — бортик выглядит естественно, не «бусами»
				slab(px + math.cos(a + 0.09) * (r + 1.3), pz + math.sin(a + 0.09) * (r + 1.3), 0.35, sx * 0.7, 0.9, sz * 0.7, 0.25)
			end
		end
		-- горка с водопадом: слои глыб, чем выше — тем уже; спереди расщелина под струю
		local cz = pz + PR + 2.2
		local layers = { { y = 0.9, w = 8, d = 4.4, h = 2.2, n = 5 }, { y = 2.9, w = 6.6, d = 3.8, h = 2.2, n = 4 }, { y = 4.9, w = 5.2, d = 3.2, h = 2.1, n = 3 }, { y = 6.8, w = 3.8, d = 2.8, h = 1.9, n = 2 } }
		for _, L in layers do
			for k = 0, L.n - 1 do
				local x = -L.w / 2 + (k + 0.5) * L.w / L.n
				if math.abs(x) > 1.2 or L == layers[#layers] then -- по центру нижних слоёв расщелина
					slab(px + x + rng:NextNumber(-0.25, 0.25), cz + rng:NextNumber(-0.2, 0.3), L.y, L.w / L.n + 0.9, L.h, L.d, 0.12)
				end
			end
			-- задняя стенка расщелины
			slab(px, cz + 1.2, L.y, 2.4, L.h, 1.6, 0.05)
		end
		-- козырёк, с которого срывается вода, и мох с цветами на макушке
		local lipY = 6.4
		part(island, "Lip", Vector3.new(3, 0.7, 2.6), at(px, cz - 0.7, lipY), stone[2], M.Slate, GHOST)
		for _, g in { { -1.2, 0.2, 8.1, 2.2, 1.6 }, { 1.1, 0.5, 8, 1.8, 1.4 }, { 0, -0.4, 8.3, 1.6, 1.2 } } do
			part(island, "Moss", Vector3.new(g[4], 0.35, g[5]), at(px + g[1], cz + g[2], g[3]) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), rgb(95, 165, 75), M.Grass, GHOST)
		end
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			ball(island, "Petal", 0.5, at(px + 0.9 + math.cos(a) * 0.35, cz + 0.3 + math.sin(a) * 0.35, 8.45).Position, rgb(255, 150, 200), M.SmoothPlastic, GHOST)
		end
		ball(island, "PetalCore", 0.35, at(px + 0.9, cz + 0.3, 8.55).Position, rgb(255, 220, 90), M.SmoothPlastic, GHOST)
		-- струя: светлая полупрозрачная пелена в расщелине + бегущие вниз вытянутые струи
		local back = (at(px, cz + 1).Position - at(px, cz).Position).Unit
		local top = at(px, cz - 1.7, lipY + 0.2).Position
		local bot = at(px, cz - 2.6, WATER_H - 0.3).Position
		local mid = (top + bot) / 2
		local height = (top - bot).Magnitude
		local tilt = math.atan2(((top - bot) * Vector3.new(1, 0, 1)).Magnitude, top.Y - bot.Y)
		local sheet = part(island, "FallSheet", Vector3.new(2.4, height, 0.4), CFrame.lookAt(mid, mid - back) * CFrame.Angles(tilt, 0, 0), rgb(205, 238, 255), M.SmoothPlastic, GHOST)
		sheet.Transparency = 0.45
		local src = part(island, "DropSource", Vector3.new(2.1, 0.2, 0.3), CFrame.lookAt(top - back * 0.35, top - back * 2), rgb(255, 255, 255), M.SmoothPlastic, GHOST)
		src.Transparency = 1
		emitter(src, rgb(250, 254, 255), 90, {
			Name = "Streaks", Texture = SMOKE, Color = ColorSequence.new(rgb(250, 254, 255)), LightEmission = 0.5,
			EmissionDirection = Enum.NormalId.Bottom, Shape = Enum.ParticleEmitterShape.Box,
			Lifetime = NumberRange.new(height / 17), Speed = NumberRange.new(15, 17), SpreadAngle = Vector2.new(2, 2),
			Squash = NumberSequence.new(-1.5), RotSpeed = NumberRange.new(0), Rotation = NumberRange.new(0),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.45) }),
		})
		-- пена, брызги, лёгкий туман там, где струя входит в воду
		local foamAt = at(px, cz - 2.9, WATER_H + 0.03)
		local foam = cyl(island, "Foam", 0.05, 2.8, foamAt, rgb(250, 254, 255), M.SmoothPlastic, GHOST)
		foam.Transparency = 0.4
		foam:SetAttribute("Radius", 0.6)
		foam:SetAttribute("Rate", 0.25)
		CollectionService:AddTag(foam, "IslandPond")
		emitter(foam, rgb(245, 252, 255), 26, {
			Name = "Splash", Texture = SMOKE, Color = ColorSequence.new(rgb(245, 252, 255)), LightEmission = 0,
			EmissionDirection = Enum.NormalId.Right, -- ось цилиндра смотрит вверх
			Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(2.5, 5), SpreadAngle = Vector2.new(45, 45), Acceleration = Vector3.new(0, -16, 0),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.8) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		})
		emitter(foam, rgb(240, 250, 255), 6, {
			Name = "Mist", Texture = SMOKE, Color = ColorSequence.new(rgb(240, 250, 255)), LightEmission = 0,
			EmissionDirection = Enum.NormalId.Right, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(0.6, 1.4), SpreadAngle = Vector2.new(70, 70),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 3.2) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) }),
		})
		-- кувшинки: тонкий лист вровень с водой (с тёмным ободком), на части — цветок
		local PASTEL = { rgb(255, 170, 210), rgb(255, 235, 245), rgb(255, 205, 140), rgb(215, 180, 255) }
		local placed = { { px + 2.5, pz - 2.5, 1.6 }, { px, cz - 2.9, 3 } } -- уточка и место, где падает вода
		local function lily(x, z, size, flower)
			local m = Instance.new("Model")
			m.Name = "Lily"
			local p0 = at(x, z, WATER_H + 0.05) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			local pad = cyl(m, "LilyPad", 0.08, size, p0, rgb(90, 190, 105), M.SmoothPlastic, GHOST)
			cyl(m, "PadRim", 0.06, size + 0.2, p0 * CFrame.new(0, -0.02, 0), rgb(50, 135, 80), M.SmoothPlastic, GHOST)
			m.PrimaryPart = pad
			if flower then
				local col = PASTEL[rng:NextInteger(1, #PASTEL)]
				local center = p0 * CFrame.new(size * 0.1, 0.22, size * 0.06)
				for k = 1, 7 do
					local a = k / 7 * math.pi * 2
					part(m, "Petal", Vector3.new(0.32, 0.14, 0.75), center * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.32) * CFrame.Angles(math.rad(-28), 0, 0), col:Lerp(rgb(255, 255, 255), 0.25), M.SmoothPlastic, GHOST)
				end
				ball(m, "Heart", 0.32, (center * CFrame.new(0, 0.1, 0)).Position, rgb(255, 225, 110), M.SmoothPlastic, GHOST)
			end
			m.Parent = island
			m:SetAttribute("Spin", rng:NextNumber(-4, 4))
			m:SetAttribute("Bob", 0.025)
			CollectionService:AddTag(m, "BoardEmblem")
		end
		local made = 0
		for _ = 1, 80 do
			if made >= 6 then break end
			local size = rng:NextNumber(1.6, 2.3)
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(1.5, PR - 1.6 - size / 2)
			local x, z = px + math.cos(a) * r, pz + math.sin(a) * r
			local ok = true
			for _, q in placed do
				if (x - q[1]) ^ 2 + (z - q[2]) ^ 2 < (size / 2 + q[3] / 2 + 0.6) ^ 2 then ok = false break end
			end
			if ok then
				table.insert(placed, { x, z, size })
				made += 1
				lily(x, z, size, made % 2 == 1)
			end
		end
		-- уточка: сидит на воде (низ тела чуть в воде)
		do
			local m = Instance.new("Model")
			m.Name = "Duck"
			local d0 = at(px + 2.5, pz - 2.5, WATER_H + 0.45) * CFrame.Angles(0, math.rad(200), 0)
			local body = part(m, "Body", Vector3.new(1.2, 0.9, 1.6), d0, rgb(255, 215, 55), M.SmoothPlastic, GHOST)
			body.Shape = Enum.PartType.Ball
			body.Size = Vector3.new(1.4, 1.4, 1.4)
			ball(m, "Back", 1.1, (d0 * CFrame.new(0, 0.2, 0.35)).Position, rgb(255, 210, 50), M.SmoothPlastic, GHOST)
			ball(m, "Tail", 0.55, (d0 * CFrame.new(0, 0.55, 0.8)).Position, rgb(255, 205, 45), M.SmoothPlastic, GHOST)
			ball(m, "Head", 0.9, (d0 * CFrame.new(0, 0.95, -0.45)).Position, rgb(255, 225, 70), M.SmoothPlastic, GHOST)
			part(m, "Beak", Vector3.new(0.42, 0.16, 0.42), d0 * CFrame.new(0, 0.88, -0.98), rgb(255, 140, 40), M.SmoothPlastic, GHOST)
			for _, s in { -1, 1 } do
				ball(m, "Eye", 0.15, (d0 * CFrame.new(s * 0.28, 1.08, -0.82)).Position, rgb(30, 30, 40), M.SmoothPlastic, GHOST)
			end
			m.PrimaryPart = body
			m.Parent = island
			m:SetAttribute("Spin", 8)
			m:SetAttribute("Bob", 0.06)
			CollectionService:AddTag(m, "BoardEmblem")
		end
		-- рогоз пучками у берега (не на камнях)
		for _, g in { { math.pi * 0.8, 5 }, { math.pi * 1.05, 4 }, { math.pi * 1.5, 4 } } do
			for k = 1, g[2] do
				local a = g[1] + (k - g[2] / 2) * 0.05
				local h = rng:NextNumber(2.2, 3.4)
				local x, z = px + math.cos(a) * (PR + 3), pz + math.sin(a) * (PR + 3)
				local stem = at(x, z, h / 2) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12))
				part(island, "Reed", Vector3.new(0.14, h, 0.14), stem, rgb(100, 155, 60), M.Grass, GHOST)
				if k % 2 == 1 then
					cyl(island, "ReedTop", 0.8, 0.32, stem * CFrame.new(0, h / 2 - 0.3, 0), rgb(120, 78, 45), M.SmoothPlastic, GHOST)
				end
			end
		end
		-- светлячки над водой
		local fl = part(island, "Fireflies", Vector3.new(PR * 1.8, 0.2, PR * 1.8), at(px, pz, 2.5), rgb(255, 255, 255), M.SmoothPlastic, GHOST)
		fl.Transparency = 1
		emitter(fl, rgb(220, 255, 120), 2, {
			Color = ColorSequence.new(rgb(230, 255, 130), rgb(255, 220, 90)), LightEmission = 1, EmissionDirection = Enum.NormalId.Top,
			Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(0.3, 0.8), SpreadAngle = Vector2.new(80, 80),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.28), NumberSequenceKeypoint.new(1, 0) }),
		})
		take(px, pz, PR + 3.5)
		take(px, cz + 1, 6.5)
	end

	-- пикник (справа): плед, корзинка, яблоки
	do
		local px, pz = 32, 6
		local cf = at(px, pz, 0.05) * CFrame.Angles(0, math.rad(20), 0)
		for i = 0, 3 do
			for j = 0, 3 do
				part(island, "Blanket", Vector3.new(2, 0.1, 2), cf * CFrame.new(-3 + i * 2, 0, -3 + j * 2), (i + j) % 2 == 0 and rgb(220, 60, 60) or rgb(250, 245, 235), M.Fabric, GHOST)
			end
		end
		part(island, "Basket", Vector3.new(2.2, 1.4, 1.6), cf * CFrame.new(1.4, 0.75, 1), rgb(170, 120, 60), M.WoodPlanks, GHOST)
		part(island, "BasketHandle", Vector3.new(0.2, 1.2, 0.2), cf * CFrame.new(0.6, 2, 1), rgb(140, 95, 45), M.Wood, GHOST)
		part(island, "BasketHandle", Vector3.new(0.2, 1.2, 0.2), cf * CFrame.new(2.2, 2, 1), rgb(140, 95, 45), M.Wood, GHOST)
		part(island, "BasketHandle", Vector3.new(1.8, 0.2, 0.2), cf * CFrame.new(1.4, 2.6, 1), rgb(140, 95, 45), M.Wood, GHOST)
		for k, o in { { -1.2, -1 }, { -0.4, -1.6 }, { -1.6, -0.2 } } do
			ball(island, "Apple", 0.7, (cf * CFrame.new(o[1], 0.4, o[2])).Position, k == 2 and rgb(140, 210, 60) or rgb(220, 40, 40), M.SmoothPlastic, GHOST)
		end
		take(px, pz, 6)
	end

	-- кусты
	for _ = 1, 40 do
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(24, R - 7)
		local x, z = math.cos(a) * d, math.sin(a) * d
		if free(x, z, 2.5) then
			for b = 1, 3 do
				ball(island, "Bush", rng:NextNumber(2, 3), at(x + math.cos(b * 2.1) * 1.1, z + math.sin(b * 2.1) * 1.1, 0.9).Position,
					rgb(80, 165, 80):Lerp(rgb(140, 215, 110), rng:NextNumber(0, 0.5)), M.Grass, GHOST)
			end
			take(x, z, 2.5)
		end
	end

	-- клумбы-кучки цветов
	local function flower(x, z, col)
		local h = rng:NextNumber(1.3, 2.2)
		cyl(island, "FlowerStem", h, 0.14, at(x, z, h / 2), rgb(90, 160, 60), M.SmoothPlastic, GHOST)
		local head = at(x, z, h)
		for p = 0, 4 do
			local a = p / 5 * math.pi * 2
			ball(island, "Petal", 0.62, (head * CFrame.new(math.cos(a) * 0.42, 0, math.sin(a) * 0.42)).Position, col, M.SmoothPlastic, GHOST)
		end
		ball(island, "FlowerCore", 0.45, head.Position + Vector3.new(0, 0.08, 0), rgb(255, 200, 40), M.SmoothPlastic, GHOST)
	end
	local beds = 0
	for _ = 1, 80 do
		if beds >= 22 then break end
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(14, R - 6)
		local x, z = math.cos(a) * d, math.sin(a) * d
		if free(x, z, 2.2) then
			local col = PETALS[rng:NextInteger(1, #PETALS)]
			for _ = 1, 5 do
				flower(x + rng:NextNumber(-1.8, 1.8), z + rng:NextNumber(-1.8, 1.8), col)
			end
			take(x, z, 2.2)
			beds += 1
		end
	end

	-- заборчик по краю (кроме входа с моста)
	local fr = R - 2.5
	local step = 4.5
	local n = math.floor(2 * math.pi * fr / step)
	local prev
	for i = 0, n do
		local a = i / n * math.pi * 2
		local x, z = math.sin(a) * fr, -math.cos(a) * fr -- a=0 — в сторону моста (−Z)
		local gap = math.abs(math.atan2(x, -z)) < math.rad(14)
		if not gap then
			local post = at(x, z, 1.4)
			part(island, "FencePost", Vector3.new(0.5, 2.8, 0.5), post, rgb(250, 245, 235), M.Wood, GHOST)
			part(island, "FenceCap", Vector3.new(0.7, 0.3, 0.7), post * CFrame.new(0, 1.5, 0), rgb(250, 245, 235), M.Wood, GHOST)
			if prev then
				local mid = (prev + post.Position) / 2
				local len = (post.Position - prev).Magnitude
				for _, hy in { -0.4, 0.6 } do
					part(island, "FenceRail", Vector3.new(0.25, 0.35, len), CFrame.lookAt(mid, post.Position) + Vector3.new(0, hy, 0), rgb(240, 230, 215), M.Wood, GHOST)
				end
			end
			prev = post.Position
		else
			prev = nil
		end
	end

	-- бабочки
	local fly = part(island, "Butterflies", Vector3.new(R * 1.3, 0.2, R * 1.3), at(0, 0, 4), rgb(255, 255, 255), M.SmoothPlastic, GHOST)
	fly.Transparency = 1
	local e = emitter(fly, rgb(255, 160, 220), 3, {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 150, 210)), ColorSequenceKeypoint.new(0.5, rgb(255, 220, 90)), ColorSequenceKeypoint.new(1, rgb(150, 200, 255)) }),
		LightEmission = 0.4, Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(0.8, 1.6),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, -0.05, 0),
		RotSpeed = NumberRange.new(-200, 200), Rotation = NumberRange.new(0, 360),
	})
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) })
end

-- ===== пьедестал из каталога Roblox (ReplicatedStorage.LeaderboardPodium, «Rank Board») =====
-- Лицевая сторона модели — −Z её точки опоры. Высоты ступеней меряем лучами один раз; на верх каждой
-- ступени ставим невидимую Place1..3 (на неё WorldProgress ставит аватар), спереди — таблички Plate1..3.
local function localExtents(m)
	local piv = m:GetPivot()
	local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local c = piv:ToObjectSpace(p.CFrame)
			local h = p.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local v = c * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
						mn, mx = mn:Min(v), mx:Max(v)
					end
				end
			end
		end
	end
	return mn, mx
end
local catalog
local function measureCatalog(name)
	local t = ReplicatedStorage:FindFirstChild(name or "LeaderboardPodium")
	if not t then return nil end
	local c = t:Clone()
	for _, d in c:GetDescendants() do
		if d:IsA("BaseScript") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true end
	end
	c:PivotTo(CFrame.new(0, 4000, 0))
	c.Parent = workspace
	local mn, mx = localExtents(c)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { c }
	local steps = {}
	for _, fx in { 1 / 6, 0.5, 5 / 6 } do
		local x = mn.X + (mx.X - mn.X) * fx
		local origin = c:GetPivot() * Vector3.new(x, mx.Y + 5, (mn.Z + mx.Z) / 2)
		local hit = workspace:Raycast(origin, Vector3.new(0, -(mx.Y - mn.Y) - 10, 0), rp)
		if hit then
			table.insert(steps, { x = x, top = c:GetPivot():PointToObjectSpace(hit.Position).Y })
		end
	end
	c:Destroy()
	if #steps < 3 then return nil end
	-- выше всех — 1-е место, из боковых выше — 2-е
	local order = { 1, 2, 3 }
	table.sort(order, function(a, b) return steps[a].top > steps[b].top end)
	for place, i in order do steps[i].place = place end
	return { tpl = t, mn = mn, mx = mx, steps = steps }
end
local function placeCatalogPodium(island, theme, name, cf, cat)
	local m = cat.tpl:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true end
	end
	local mn, mx = cat.mn, cat.mx
	local k = (cat.width or 12) / (mx.X - mn.X) -- пьедестал перед большой доской; головы победителей у её нижнего края
	m:PivotTo(CFrame.new())
	pcall(function() m:ScaleTo(m:GetScale() * k) end)
	local cx, cz = (mn.X + mx.X) / 2 * k, (mn.Z + mx.Z) / 2 * k
	local ground = (cf * CFrame.new(0, 0, -9)).Position
	local piv = CFrame.new(ground) * cf.Rotation * CFrame.new(-cx, -mn.Y * k, -cz)
	m:PivotTo(piv)
	m.Name = "Podium_" .. name
	local look = cf.LookVector
	m:SetAttribute("Yaw", math.atan2(-look.X, -look.Z))
	local _, _, v = theme.Top:ToHSV()
	if cat.crown and v < 0.3 then
		-- в тёмных мирах (неон, лава, космос) белый пластик под bloom «выгорает» — приглушаем
		for _, d in m:GetDescendants() do
			if d:IsA("SurfaceAppearance") then pcall(function() d.Color = rgb(185, 185, 200) end) end
		end
	end
	for _, st in cat.steps do
		local top = piv * Vector3.new(st.x * k, st.top * k, cz)
		local place = part(m, "Place" .. st.place, Vector3.new(3, 0.2, 3), CFrame.new(top - Vector3.new(0, 0.1, 0)) * cf.Rotation, MEDAL[st.place], M.SmoothPlastic, GHOST)
		place.Transparency = 1
		local plate = part(m, "Plate" .. st.place, Vector3.new(cat.crown and 2.8 or 3.4, cat.crown and 0.7 or 0.9, 0.2), CFrame.new(piv * Vector3.new(st.x * k, mn.Y * k + (cat.crown and 0.55 or 0.9), mn.Z * k - 0.15)) * cf.Rotation, rgb(48, 44, 86), M.SmoothPlastic, GHOST)
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 60
		g.LightInfluence = 0
		g.Parent = plate
		local tl = Instance.new("TextLabel")
		tl.Name = "PlayerName"
		tl.BackgroundTransparency = 1
		tl.AnchorPoint = Vector2.new(0.5, 0.5)
		tl.Position = UDim2.fromScale(0.5, 0.5)
		tl.Size = UDim2.fromScale(0.94, 0.86)
		tl.Font = Enum.Font.FredokaOne
		tl.TextScaled = true
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.Text = "—"
		tl.Parent = g
		if cat.crown and st.place == 1 then
			-- корона парит над головой победителя
			local crown = Instance.new("Model")
			crown.Name = "Crown"
			local at = CFrame.new(top + Vector3.new(0, 5.2, 0))
			local band = cyl(crown, "Band", 0.7, 2.2, at, MEDAL[1], M.Metal, GHOST)
			band.Reflectance = 0.25
			crown.PrimaryPart = band
			for i = 0, 4 do
				local a = i / 5 * math.pi * 2
				part(crown, "Spike", Vector3.new(0.35, 0.9, 0.35), at * CFrame.new(math.cos(a) * 0.95, 0.75, math.sin(a) * 0.95), MEDAL[1], M.Metal, GHOST)
				ball(crown, "Gem", 0.35, (at * CFrame.new(math.cos(a) * 0.95, 1.25, math.sin(a) * 0.95)).Position, rgb(255, 80, 120), M.Neon, GHOST)
			end
			emitter(band, MEDAL[1], 5, { Speed = NumberRange.new(0.3, 1) })
			light(band, MEDAL[1], 7, 0.8)
			crown:SetAttribute("Spin", 60)
			crown:SetAttribute("Bob", 0.3)
			CollectionService:AddTag(crown, "BoardEmblem")
			crown.Parent = m
		end
	end
	m.Parent = island
	return m
end


-- ===== арка входа =====
-- Две колонны с базами и капителями, полукруглый свод из камней с замковым камнем, гирлянда огоньков
-- по своду, висящая табличка-«пилюля» TOP PLAYERS и золотой кубок на вершине (во Frozen — снежинка).
local function trophy(parent, cf, size)
	local m = Instance.new("Model")
	m.Name = "Trophy"
	local gold = rgb(255, 200, 50)
	local base = cyl(m, "Base", size * 0.18, size * 0.55, cf, rgb(90, 55, 20), M.Wood, GHOST)
	cyl(m, "Stem", size * 0.3, size * 0.14, cf * CFrame.new(0, size * 0.24, 0), gold, M.Metal, GHOST).Reflectance = 0.2
	cyl(m, "Knob", size * 0.1, size * 0.3, cf * CFrame.new(0, size * 0.42, 0), gold, M.Metal, GHOST)
	local cup = cyl(m, "Cup", size * 0.45, size * 0.62, cf * CFrame.new(0, size * 0.7, 0), gold, M.Metal, GHOST)
	cup.Reflectance = 0.25
	cyl(m, "Rim", size * 0.06, size * 0.7, cf * CFrame.new(0, size * 0.93, 0), rgb(255, 235, 140), M.Neon, GHOST)
	for _, s in { -1, 1 } do
		local h = part(m, "Handle", Vector3.new(size * 0.08, size * 0.32, size * 0.08), cf * CFrame.new(s * size * 0.4, size * 0.72, 0) * CFrame.Angles(0, 0, math.rad(s * 25)), gold, M.Metal, GHOST)
		h.Reflectance = 0.2
	end
	m.PrimaryPart = base
	emitter(cup, rgb(255, 230, 120), 6, { Speed = NumberRange.new(0.5, 1.5) })
	light(cup, rgb(255, 220, 120), 16, 1.6)
	m.Parent = parent
	m:SetAttribute("Spin", 40)
	m:SetAttribute("Bob", 0.3)
	CollectionService:AddTag(m, "BoardEmblem")
	return m
end
local function buildArch(island, theme, gate)
	local half = BRIDGE_W / 2 + 2.2 -- ось колонны
	local H = 12 -- высота колонн
	local glow = theme.ArchGlow or theme.Lamp
	for _, s in { -1, 1 } do
		local c = gate * CFrame.new(s * half, 0, 0)
		part(island, "ArchBase", Vector3.new(3.8, 1.4, 3.8), c * CFrame.new(0, 0.7, 0), theme.Arch:Lerp(Color3.new(0, 0, 0), 0.2), theme.ArchMat)
		cyl(island, "ArchColumn", H - 2.4, 2.6, c * CFrame.new(0, 1.4 + (H - 2.4) / 2, 0), theme.Arch, theme.ArchMat)
		part(island, "ArchCapital", Vector3.new(3.6, 1, 3.6), c * CFrame.new(0, H - 0.5, 0), theme.Arch:Lerp(Color3.new(0, 0, 0), 0.2), theme.ArchMat)
		local ring = cyl(island, "ArchRing", 0.4, 3, c * CFrame.new(0, H - 1.3, 0), glow, M.Neon, GHOST)
		CollectionService:AddTag(ring, "BoardPulse")
		local l = ball(island, "ArchLantern", 1.2, (c * CFrame.new(0, 3, -1.6)).Position, glow, M.Neon, GHOST)
		light(l, glow, 12, 1.2)
	end
	-- свод: полукруг из 11 камней поверх колонн
	local r = half
	local center = gate * CFrame.new(0, H, 0)
	local n = 11
	for i = 0, n - 1 do
		local th = math.pi * (i + 0.5) / n
		local p = center * CFrame.new(math.cos(th) * r, math.sin(th) * r, 0)
		local seg = 2 * r * math.sin(math.pi / n / 2) + 0.35
		local key = i == math.floor(n / 2)
		local stone = part(island, key and "ArchKeystone" or "ArchStone", Vector3.new(seg, key and 3.2 or 2.4, key and 2.8 or 2.2), p * CFrame.Angles(0, 0, th - math.pi / 2), key and glow or theme.Arch, key and M.Neon or theme.ArchMat)
		if key then CollectionService:AddTag(stone, "BoardPulse") end
		-- огоньки гирлянды по внешнему краю свода
		local bulb = ball(island, "ArchBulb", 0.7, (center * CFrame.new(math.cos(th) * (r + 1.6), math.sin(th) * (r + 1.6), -0.6)).Position, i % 2 == 0 and glow or theme.Lamp, M.Neon, GHOST)
		if i % 3 == 0 then light(bulb, bulb.Color, 8, 0.8) end
	end
	-- табличка-«пилюля» под сводом на двух цепочках
	local signCf = gate * CFrame.new(0, H - 0.8, 0)
	local len, sh = BRIDGE_W - 1, 2.8
	local body = part(island, "ArchSign", Vector3.new(len, sh, 0.9), signCf, theme.Arch, theme.ArchMat)
	for _, x in { -len / 2, len / 2 } do
		part(island, "ArchSignCap", Vector3.new(0.9, sh, sh), signCf * CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad(90), 0), theme.Arch, theme.ArchMat, { Shape = Enum.PartType.Cylinder })
	end
	local edge = part(island, "ArchSignEdge", Vector3.new(len, sh + 0.5, 0.4), signCf * CFrame.new(0, 0, 0.35), glow, M.Neon, GHOST)
	CollectionService:AddTag(edge, "BoardPulse")
	for _, x in { -len / 3, len / 3 } do
		part(island, "ArchChain", Vector3.new(0.18, r * 0.9, 0.18), signCf * CFrame.new(x, sh / 2 + r * 0.45, 0), rgb(200, 190, 160), M.Metal, GHOST)
	end
	for _, f in { Enum.NormalId.Front, Enum.NormalId.Back } do
		text(body, f, "TOP PLAYERS", theme.ArchInk, Enum.Font.LuckiestGuy, 60)
	end
	if not theme.Snow then
		trophy(island, center * CFrame.new(0, r + 1.6, 0), 4.2)
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
	buildArch(island, theme, CFrame.lookAt(b, a) * CFrame.new(0, 0, 4))
end


-- ===== снежный шар (Frozen Peaks) =====
-- Остров под стеклянным куполом на деревянной подставке с золотым ободком, внутри свой снегопад.
-- Вход: стеклянный тоннель с мерцающими кольцами над концом моста, на арке — крутящаяся снежинка,
-- в проёме купола — переливающаяся «плёнка», сквозь которую проходишь. Экранный ветер/иней внутри шара
-- делает клиент (GlobeFX) по тегу SnowGlobe.
local function snowflake(parent, size, cf, color)
	local m = Instance.new("Model")
	m.Name = "Snowflake"
	local hub = ball(m, "Hub", size * 0.22, cf.Position, color, M.Neon, GHOST)
	m.PrimaryPart = hub
	for i = 0, 2 do
		local arm = cf * CFrame.Angles(0, 0, math.rad(i * 60))
		part(m, "Arm", Vector3.new(size, size * 0.09, size * 0.09), arm, color, M.Neon, GHOST)
		for _, s in { -1, 1 } do
			for _, f in { 0.28, 0.4 } do
				local at = arm * CFrame.new(s * size * f, 0, 0)
				part(m, "Twig", Vector3.new(size * 0.22, size * 0.06, size * 0.06), at * CFrame.Angles(0, 0, math.rad(s * 45)), color, M.Neon, GHOST)
				part(m, "Twig", Vector3.new(size * 0.22, size * 0.06, size * 0.06), at * CFrame.Angles(0, 0, math.rad(-s * 45)), color, M.Neon, GHOST)
			end
		end
	end
	m.Parent = parent
	return m
end
local function buildGlobe(island, theme, ic, groundY, from, to)
	local pos = Vector3.new(ic.Position.X, groundY, ic.Position.Z)
	local Dm = R * 2 + 14
	-- купол: шар чуть ниже уровня острова, видна верхняя «шапка»
	local dome = part(island, "GlobeGlass", Vector3.new(Dm, Dm, Dm), CFrame.new(pos + Vector3.new(0, -8, 0)), rgb(210, 240, 255), M.Glass, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	dome.Shape = Enum.PartType.Ball
	dome.Transparency = 0.82
	dome.Reflectance = 0.25
	dome:SetAttribute("Radius", Dm / 2)
	CollectionService:AddTag(dome, "SnowGlobe")
	-- подставка: дерево с золотыми кольцами
	cyl(island, "GlobeBase", 5, R * 2 + 10, CFrame.new(pos + Vector3.new(0, -3.6, 0)), rgb(120, 40, 40), M.Wood)
	cyl(island, "GlobeBaseLow", 4, R * 2 + 16, CFrame.new(pos + Vector3.new(0, -7.5, 0)), rgb(95, 30, 30), M.Wood, GHOST)
	for _, y in { -1.2, -6 } do
		local ring = cyl(island, "GlobeRing", 0.8, R * 2 + (y < -3 and 16.6 or 10.6), CFrame.new(pos + Vector3.new(0, y, 0)), rgb(255, 205, 80), M.Neon, GHOST)
		CollectionService:AddTag(ring, "BoardPulse")
	end
	-- свой снегопад внутри шара (виден и снаружи — как будто шар потрясли)
	local sky = part(island, "GlobeSnow", Vector3.new(R * 1.6, 0.2, R * 1.6), CFrame.new(pos + Vector3.new(0, 30, 0)), rgb(255, 255, 255), M.SmoothPlastic, GHOST)
	sky.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.4
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.3) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.1), NumberSequenceKeypoint.new(0.85, 0.25), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(7, 9)
	e.Rate = 40
	e.Speed = NumberRange.new(2, 4)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(30, 30)
	e.Acceleration = Vector3.new(1.5, -0.5, 0.8)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Rotation = NumberRange.new(0, 360)
	e.Parent = sky
	-- вход: стеклянный тоннель с кольцами над последними 16 стадами моста
	local a = Vector3.new(from.X, groundY, from.Z)
	local b = Vector3.new(to.X, groundY, to.Z)
	local dir = (b - a).Unit
	local tc = CFrame.lookAt(b - dir * 8 + Vector3.new(0, 5.5, 0), b + Vector3.new(0, 5.5, 0))
	local tube = part(island, "GlobeTunnel", Vector3.new(16, 14, 14), tc * CFrame.Angles(0, math.rad(90), 0), rgb(200, 240, 255), M.Glass, GHOST)
	tube.Shape = Enum.PartType.Cylinder
	tube.Transparency = 0.8
	for z = -7, 7, 4.6 do
		local ring = part(island, "TunnelRing", Vector3.new(0.6, 14.6, 14.6), tc * CFrame.new(0, 0, z) * CFrame.Angles(0, math.rad(90), 0), rgb(140, 230, 255), M.Neon, GHOST)
		ring.Shape = Enum.PartType.Cylinder
		ring.Transparency = 0.15
		CollectionService:AddTag(ring, "BoardPulse")
	end
	-- «плёнка» в проёме шара: переливается, сквозь неё проходят
	local film = part(island, "GlobeDoor", Vector3.new(0.2, 12.6, 12.6), CFrame.lookAt(b + Vector3.new(0, 5.5, 0), b + dir + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, math.rad(90), 0), rgb(170, 230, 255), M.ForceField, GHOST)
	film.Shape = Enum.PartType.Cylinder
	film.Transparency = 0.2
	emitter(film, rgb(200, 245, 255), 12, { Speed = NumberRange.new(0.5, 2), EmissionDirection = Enum.NormalId.Right })
	light(film, rgb(150, 230, 255), 18, 2)
	-- крутящаяся снежинка над аркой
	local flake = snowflake(island, 7, CFrame.lookAt(b + dir * 4 + Vector3.new(0, 25.5, 0), b + dir * 4 + Vector3.new(0, 25.5, 0) - dir), rgb(170, 235, 255))
	flake:SetAttribute("Spin", 45)
	flake:SetAttribute("Bob", 0.4)
	CollectionService:AddTag(flake, "BoardEmblem")
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
-- Ворота в стене мира: стену-брусок режем на два куска с проёмом под мост, по краям — светящиеся столбы.
local function cutGate(wall, base, dir, hy, theme, island)
	local cf, size, wpos = wall.CFrame, wall.Size, wall.Position
	local longX = size.X >= size.Z
	local axis = longX and cf.RightVector or cf.LookVector
	local normal = longX and cf.LookVector or cf.RightVector
	local denom = dir:Dot(normal)
	local hit
	if math.abs(denom) > 0.05 then
		local t = (wpos - base):Dot(normal) / denom
		hit = base + dir * t
	else
		hit = wpos
	end
	local L = longX and size.X or size.Z
	local c = (hit - wpos):Dot(axis)
	local g = (BRIDGE_W + 6) / 2 / math.max(0.35, math.abs(dir:Dot(normal)))
	local function piece(a, b)
		if b - a < 0.5 then return end
		local p = wall:Clone()
		p.Size = longX and Vector3.new(b - a, size.Y, size.Z) or Vector3.new(size.X, size.Y, b - a)
		p.CFrame = cf + axis * ((a + b) / 2)
		p.Parent = wall.Parent
	end
	local gateTop = hy + 14
	local wb, wt = wpos.Y - size.Y / 2, wpos.Y + size.Y / 2
	if wb >= gateTop then return end -- полоса/стена целиком выше проёма — не трогаем
	piece(-L / 2, c - g)
	piece(c + g, L / 2)
	if wt > gateTop + 0.5 then
		-- перемычка над воротами: стена остаётся сплошной выше проёма
		local p = wall:Clone()
		local h = wt - gateTop
		p.Size = longX and Vector3.new(2 * g, h, size.Z) or Vector3.new(size.X, h, 2 * g)
		p.CFrame = cf + axis * c + Vector3.new(0, (gateTop + h / 2) - wpos.Y, 0)
		p.Parent = wall.Parent
	end
	wall:Destroy()
	if size.Y < 3 then return end -- для тонких неоновых полос столбы не нужны
	-- столбы ворот
	for _, sgn in { -1, 1 } do
		local at = wpos + axis * (c + sgn * (g + 0.8))
		local h = gateTop - hy
		local post = part(island, "GatePost", Vector3.new(1.6, h, 1.6), CFrame.new(at.X, hy + h / 2, at.Z), theme.Rail, theme.RailMat)
		if theme.RailMat == M.Neon then CollectionService:AddTag(post, "BoardPulse") end
		light(ball(island, "GateLamp", 1.8, Vector3.new(at.X, gateTop + 1, at.Z), theme.Lamp, M.Neon, GHOST), theme.Lamp, 22, 2)
	end
end

local function findDirection(model, spawn, groundY, avoid)
	local list = parts()
	local near = {}
	for _, q in list do
		if q.Parent and Vector2.new(q.Position.X - spawn.X, q.Position.Z - spawn.Z).Magnitude < 420 and q.Position.Y - q.Size.Y / 2 < groundY + 60 and q.Position.Y + q.Size.Y / 2 > groundY - 60 then
			table.insert(near, q)
		end
	end
	local best, bestScore, bestInfo, bestRemove, bestY, bestWalls
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
		local walls = {}
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
			local isWall = string.find(q.Name, "Wall", 1, true) and q:IsA("Part") and q.Shape == Enum.PartType.Block
			if isWall then
				-- стена вокруг мира (Neon): длинная, по центру детали не судим. Если её пересекает
				-- коридор моста — прорежем ворота; иначе стена мосту не мешает.
				local crosses = false
				local half = q.Size / 2
				for d = edge - 14, edge + GAP + 4, 2 do
					for _, sd in { -BRIDGE_W / 2, 0, BRIDGE_W / 2 } do
						local lp = q.CFrame:PointToObjectSpace(base + dir * d + Vector3.new(-dir.Z, 0, dir.X) * sd + Vector3.new(0, hy + 3 - base.Y, 0))
						if math.abs(lp.X) <= half.X and math.abs(lp.Z) <= half.Z and math.abs(lp.Y) <= half.Y + 8 then crosses = true break end
					end
					if crosses then break end
				end
				if crosses then table.insert(walls, q) end
			elseif (inIsland or inSpan or atHead) and not thin then
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
		-- не за порталом возврата: иначе, чтобы дойти до топов, игрок пятится и улетает в прошлый мир
		for _, av in avoid or {} do
			local to = (av - base) * Vector3.new(1, 0, 1)
			if to.Magnitude > 4 then
				if dir:Dot(to.Unit) > 0.35 then score += 1000 end
			elseif dir.Z > 0.35 then
				-- портал прямо на точке появления (Neon): игрок выходит лицом к −Z, позади — портал
				score += 1000
			end
		end
		score += #walls * 15
		if not bestScore or score < bestScore then
			best, bestScore, bestInfo, bestRemove, bestY, bestWalls = dir, score, edge, removable, hy, walls
		end
	end
	model:SetAttribute("LeaderboardIslandWhy", table.concat(why, " "))
	return best, bestInfo, near, bestRemove, bestY, bestWalls
end

-- пьедестал из плейса (как в Meadow / Neon): копия, уменьшенная под доску острова, в цветах мира
local podiumTpl = {}
local function placePodium(island, theme, name, cf, tpl)
	local m = tpl.model:Clone()
	for _, c in m:GetChildren() do
		if string.match(c.Name, "^Winner") or c.Name:match("^PodiumSpot") then c:Destroy() end
	end
	pcall(function() m:ScaleTo(m:GetScale() * 0.62) end)
	local bcf, size = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(bcf)
	local target = CFrame.new((cf * CFrame.new(0, size.Y / 2, -6)).Position) * cf.Rotation * tpl.rot
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
	-- украшения: светящееся кольцо по верху ступени, медаль с цифрой спереди, корона над первым местом
	local up = Vector3.yAxis
	local function halfAlong(p, v)
		local c = p.CFrame
		return math.abs(c.RightVector:Dot(v)) * p.Size.X / 2 + math.abs(c.UpVector:Dot(v)) * p.Size.Y / 2 + math.abs(c.LookVector:Dot(v)) * p.Size.Z / 2
	end
	for place = 1, 3 do
		local st = m:FindFirstChild("Place" .. place)
		if st and st:IsA("BasePart") then
			local top = st.Position.Y + halfAlong(st, up)
			local r = halfAlong(st, cf.RightVector)
			local ring = cyl(m, "GlowRing" .. place, 0.3, r * 2 + 0.4, CFrame.new(st.Position.X, top - 0.1, st.Position.Z), MEDAL[place], M.Neon, GHOST)
			ring.Transparency = 0.1
			CollectionService:AddTag(ring, "BoardPulse")
			local depth = halfAlong(st, look)
			-- медаль стоит ребром на переднем крае ступени, у ног победителя — табличку с именем не закрывает
			local mc = CFrame.lookAt(Vector3.new(st.Position.X, top + 0.75, st.Position.Z) + look * (depth - 0.3), Vector3.new(st.Position.X, top + 0.75, st.Position.Z) + look * 50)
			local medal = part(m, "Medal" .. place, Vector3.new(0.3, 1.5, 1.5), mc * CFrame.Angles(0, math.rad(90), 0), MEDAL[place], M.Metal, GHOST)
			medal.Shape = Enum.PartType.Cylinder
			medal.Reflectance = 0.2
			for _, f in { Enum.NormalId.Left, Enum.NormalId.Right } do
				text(medal, f, tostring(place), MEDAL[place]:Lerp(Color3.new(0, 0, 0), 0.55), Enum.Font.LuckiestGuy, 80)
			end
			if place == 1 then
				-- корона парит над головой победителя
				local crown = Instance.new("Model")
				crown.Name = "Crown"
				local at = CFrame.new(st.Position.X, top + 5, st.Position.Z)
				local band = cyl(crown, "Band", 0.7, 2.2, at, MEDAL[1], M.Metal, GHOST)
				band.Reflectance = 0.25
				crown.PrimaryPart = band
				for i = 0, 4 do
					local a = i / 5 * math.pi * 2
					part(crown, "Spike", Vector3.new(0.35, 0.9, 0.35), at * CFrame.new(math.cos(a) * 0.95, 0.75, math.sin(a) * 0.95), MEDAL[1], M.Metal, GHOST)
					ball(crown, "Gem", 0.35, (at * CFrame.new(math.cos(a) * 0.95, 1.25, math.sin(a) * 0.95)).Position, rgb(255, 80, 120), M.Neon, GHOST)
				end
				emitter(band, MEDAL[1], 5, { Speed = NumberRange.new(0.3, 1) })
				light(band, MEDAL[1], 12, 1.4)
				crown:SetAttribute("Spin", 60)
				crown:SetAttribute("Bob", 0.3)
				CollectionService:AddTag(crown, "BoardEmblem")
				crown.Parent = m
			end
		end
	end
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
	catalog = measureCatalog()
	-- единый пьедестал из Tripo (ReplicatedStorage.TripoPodium) — один вид во всех мирах
	local tripo = measureCatalog("TripoPodium")
	if tripo then tripo.width = 10; tripo.crown = true end
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
		local avoid = {}
		for _, d in model:GetDescendants() do
			if string.sub(d.Name, 1, 8) == "PortalTo" and (d:IsA("BasePart") or d:IsA("Model")) then
				local pp = d:IsA("Model") and d:GetPivot().Position or d.Position
				if ((pp - spawn) * Vector3.new(1, 0, 1)).Magnitude < 90 then table.insert(avoid, pp) end
			end
		end
		local dir, edge, near, remove, hy, walls = findDirection(model, spawn, groundY, avoid)
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
		if key == "Meadow" then meadowGarden(island, ic, hy) end
		buildBridge(island, theme, base + dir * (edge - 8), center - dir * (R - 1), hy)
		-- проход к мосту: скалы/холмы Terrain, которые встают между площадкой и началом моста
		-- выше настила, срезаем ровной просекой (в Meadow мост упирался в скалу у берега)
		for _, wl in walls or {} do pcall(cutGate, wl, base, dir, hy, theme, island) end
		-- подход к мосту: дорожка и фонари, чтобы вход к топам было видно издалека, а не «шагнул в темноту»
		do
			local side = Vector3.new(-dir.Z, 0, dir.X)
			local L0, L1 = edge - 44, edge - 7
			for d = L0, L1, 4 do
				local c = base + dir * (d + 2)
				local g = rayDown(Vector3.new(c.X, hy + 12, c.Z), 30)
				if g and math.abs(g.Position.Y - hy) < 4 then
					local tile = part(island, "ApproachPath", Vector3.new(BRIDGE_W - 2, 0.15, 4.1), CFrame.lookAt(g.Position + Vector3.new(0, 0.08, 0), g.Position + Vector3.new(0, 0.08, 0) + dir), theme.Deck, theme.DeckMat, GHOST)
					if theme.DeckMat == M.Glass then tile.Transparency = 0.25 end
					for _, sg in { -1, 1 } do
						local e = part(island, "ApproachEdge", Vector3.new(0.35, 0.2, 4.1), tile.CFrame * CFrame.new(sg * (BRIDGE_W / 2 - 0.9), 0.05, 0), theme.Rail, theme.RailMat, GHOST)
						if theme.RailMat == M.Neon then e.Transparency = 0.1 end
					end
				end
			end
			for d = L0 + 4, L1, 12 do
				for _, sg in { -1, 1 } do
					local c = base + dir * d + side * sg * (BRIDGE_W / 2 + 1)
					local g = rayDown(Vector3.new(c.X, hy + 12, c.Z), 30)
					local y = g and g.Position.Y or hy
					cyl(island, "ApproachPost", 3.4, 0.35, CFrame.new(c.X, y + 1.7, c.Z), theme.Rail:Lerp(Color3.new(0, 0, 0), 0.3), M.Metal, GHOST)
					local bulb = ball(island, "ApproachLamp", 0.9, Vector3.new(c.X, y + 3.7, c.Z), theme.Lamp, M.Neon, GHOST)
					light(bulb, theme.Lamp, 14, 1.2)
				end
			end
		end
		for d = edge - 40, edge + 2, 3 do
			local c = base + dir * d
			local mid = Vector3.new(c.X, hy + 0.9 + 20, c.Z)
			workspace.Terrain:FillBlock(CFrame.lookAt(mid, mid + dir), Vector3.new(BRIDGE_W + 8, 40, 3.6), Enum.Material.Air)
		end
		if key == "FrozenPeaks" then
			buildGlobe(island, theme, ic, hy, base + dir * (edge - 8), center - dir * (R - 1))
		end
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
		-- одна большая доска с вкладками COINS / EGGS / PICKUPS у дальнего края острова, лицом к арке;
		-- перед ней один пьедестал (топ-3 по монетам)
		local cf = ic * CFrame.new(0, 0, 24)
		buildBoard(island, theme, "BoardMain", cf)
		local tpl = (key == "NeonCity" or key == "CosmicGalaxy") and podiumTpl.Neon or podiumTpl.Meadow
		-- пьедестал как в первом/втором мире (из плейса), с медалями и короной; каталожный — только запасной
		if not ((tripo and placeCatalogPodium(island, theme, "BoardCoins", cf, tripo)) or (tpl and placePodium(island, theme, "BoardCoins", cf, tpl)) or (catalog and placeCatalogPodium(island, theme, "BoardCoins", cf, catalog))) then
			buildPodium(island, theme, "BoardCoins", cf)
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
