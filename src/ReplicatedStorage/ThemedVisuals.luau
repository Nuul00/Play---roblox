-- Питомцы и яйца серий Sakura и Starlight, собранные из деталей Roblox по артам владельца.
-- Стиль: «кубик» с круглыми гранями, большие светящиеся глаза, детали серии (цветы, звёзды, крылья).
-- Лицо смотрит в -Z. Каждая модель центрируется и приводится к размеру 2.8 стада, как Sunset-питомцы.
local T = {}

local M = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local HALF = math.pi / 2

local PALETTES = {
	Sakura = {
		main = rgb(255, 190, 222),
		light = rgb(255, 232, 244),
		white = rgb(255, 248, 252),
		accent = rgb(255, 110, 175),
		deep = rgb(214, 70, 140),
		gold = rgb(255, 205, 95),
		eye = rgb(255, 120, 200),
		dark = rgb(70, 45, 70),
		branch = rgb(110, 62, 58),
	},
	Starlight = {
		main = rgb(78, 52, 160),
		light = rgb(190, 160, 255),
		white = rgb(245, 238, 255),
		accent = rgb(150, 100, 255),
		deep = rgb(38, 24, 92),
		gold = rgb(255, 210, 90),
		eye = rgb(255, 225, 120),
		dark = rgb(25, 18, 55),
		branch = rgb(120, 90, 200),
	},
	Sky = {
		main = rgb(150, 200, 255),
		light = rgb(225, 240, 255),
		white = rgb(255, 255, 255),
		accent = rgb(255, 214, 120),
		deep = rgb(90, 140, 230),
		gold = rgb(255, 215, 100),
		eye = rgb(70, 110, 220),
		dark = rgb(40, 60, 110),
		branch = rgb(180, 200, 240),
	},
	Cloud = {
		main = rgb(160, 205, 255),
		light = rgb(228, 242, 255),
		white = rgb(255, 255, 255),
		accent = rgb(255, 214, 120),
		deep = rgb(100, 150, 235),
		gold = rgb(255, 215, 100),
		eye = rgb(70, 130, 235),
		dark = rgb(45, 65, 120),
		branch = rgb(190, 210, 245),
	},
	Celestial = {
		main = rgb(105, 75, 195),
		light = rgb(200, 175, 255),
		white = rgb(250, 244, 255),
		accent = rgb(255, 214, 120),
		deep = rgb(52, 32, 125),
		gold = rgb(255, 215, 100),
		eye = rgb(255, 225, 130),
		dark = rgb(25, 18, 60),
		branch = rgb(150, 120, 220),
	},
	Crystal = {
		main = rgb(125, 205, 245),
		light = rgb(208, 240, 255),
		white = rgb(242, 252, 255),
		accent = rgb(85, 225, 255),
		deep = rgb(65, 135, 205),
		gold = rgb(255, 225, 120),
		eye = rgb(80, 215, 255),
		dark = rgb(30, 55, 100),
		branch = rgb(170, 220, 250),
	},
	Aurora = {
		main = rgb(255, 170, 220),
		light = rgb(255, 225, 245),
		white = rgb(255, 255, 255),
		accent = rgb(120, 230, 255),
		deep = rgb(170, 90, 220),
		gold = rgb(255, 235, 130),
		eye = rgb(130, 70, 210),
		dark = rgb(70, 40, 100),
		branch = rgb(200, 150, 230),
	},
}

local function builder(name)
	local m = Instance.new("Model")
	m.Name = name
	local parts = {}
	local pivot = Instance.new("Part")
	pivot.Name = "Pivot"
	pivot.Size = Vector3.new(0.05, 0.05, 0.05)
	pivot.Transparency = 1
	pivot.Anchored = true
	pivot.CanCollide = false
	pivot.CanTouch = false
	pivot.CanQuery = false
	pivot.Parent = m
	m.PrimaryPart = pivot
	local function P(n, size, cf, color, shape, material)
		local p = Instance.new(shape == "wedge" and "WedgePart" or shape == "corner" and "CornerWedgePart" or "Part")
		p.Name = n
		p.Size = size
		p.Color = color
		p.Material = material or M.SmoothPlastic
		if shape == "ball" then
			p.Shape = Enum.PartType.Ball
		elseif shape == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
		p.Parent = m
		table.insert(parts, { part = p, transparency = 0 })
		return p
	end
	return m, parts, P
end

-- Готовая модель: центр в нуле, наибольший размер 2.8.
local function finish(m, parts)
	local cf, size = m:GetBoundingBox()
	local shift = cf.Position
	for _, v in ipairs(parts) do
		v.part.CFrame = v.part.CFrame - shift
	end
	m.PrimaryPart.CFrame = CFrame.identity
	m:PivotTo(CFrame.identity)
	m:ScaleTo(2.8 / math.max(size.X, size.Y, size.Z))
	return m, parts
end

-- ===== Общие детали =====
local function kit(P, pal)
	local K = {}
	function K.ball(n, pos, d, color, material)
		return P(n, Vector3.new(d, d, d), pos, color, "ball", material)
	end
	-- Плоский диск, «смотрящий» в направлении normal.
	function K.disc(n, pos, normal, d, thick, color, material)
		return P(n, Vector3.new(thick, d, d), CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, HALF, 0), color, "cyl", material)
	end
	-- Кубик со скруглёнными углами.
	function K.cube(n, center, size, color, r, material)
		r = r or 0.22
		local c = CFrame.new(center)
		P(n, size - Vector3.new(2 * r, 0, 0), c, color, nil, material)
		P(n, size - Vector3.new(0, 2 * r, 0), c, color, nil, material)
		P(n, size - Vector3.new(0, 0, 2 * r), c, color, nil, material)
		local h = size / 2 - Vector3.new(r, r, r)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					K.ball(n .. "Corner", center + Vector3.new(h.X * sx, h.Y * sy, h.Z * sz), 2 * r, color, material)
				end
			end
		end
	end
	-- Цветок сакуры из пяти лепестков.
	function K.blossom(pos, normal, scale, color)
		local base = CFrame.lookAt(pos, pos + normal)
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			P("Petal", Vector3.new(0.05 * scale, 0.32 * scale, 0.32 * scale), base * CFrame.new(math.cos(a) * 0.15 * scale, math.sin(a) * 0.15 * scale, 0) * CFrame.Angles(0, HALF, 0), color or pal.accent, "cyl")
		end
		K.ball("FlowerCore", (base * CFrame.new(0, 0, -0.03 * scale)).Position, 0.13 * scale, pal.gold)
	end
	-- Четырёхлучевая звезда (светится).
	function K.star(pos, normal, scale, color)
		local base = CFrame.lookAt(pos, pos + normal)
		for k = 0, 1 do
			P("Star", Vector3.new(0.14 * scale, 0.7 * scale, 0.05 * scale), base * CFrame.Angles(0, 0, k * HALF), color or pal.gold, nil, M.Neon)
			P("Star", Vector3.new(0.1 * scale, 0.36 * scale, 0.05 * scale), base * CFrame.Angles(0, 0, math.pi / 4 + k * HALF), color or pal.gold, nil, M.Neon)
		end
	end
	-- Ухо-треугольник из двух клиньев, основание в pos, наклон наружу.
	function K.ear(pos, side, w, h, thick, color, inner, tilt)
		local e = CFrame.new(pos) * CFrame.Angles(0, 0, -side * (tilt or 0.25))
		P("Ear", Vector3.new(thick, h, w / 2), e * CFrame.new(-w / 4, h / 2, 0) * CFrame.Angles(0, HALF, 0), color, "wedge")
		P("Ear", Vector3.new(thick, h, w / 2), e * CFrame.new(w / 4, h / 2, 0) * CFrame.Angles(0, -HALF, 0), color, "wedge")
		if inner then
			P("EarInner", Vector3.new(0.05, h * 0.6, w / 4), e * CFrame.new(-w / 8, h * 0.35, -thick / 2 - 0.01) * CFrame.Angles(0, HALF, 0), inner, "wedge")
			P("EarInner", Vector3.new(0.05, h * 0.6, w / 4), e * CFrame.new(w / 8, h * 0.35, -thick / 2 - 0.01) * CFrame.Angles(0, -HALF, 0), inner, "wedge")
		end
	end
	-- Глаза: светящиеся круглые или «счастливые» дуги ^ ^.
	function K.eyes(y, z, spread, d, style, color)
		for _, side in ipairs({ -1, 1 }) do
			local pos = Vector3.new(side * spread, y, z)
			if style == "happy" then
				for k = -1, 1, 2 do
					P("Eye", Vector3.new(0.2, 0.06, 0.05), CFrame.new(pos + Vector3.new(k * 0.07, 0, 0)) * CFrame.Angles(0, 0, k * 0.6), pal.dark)
				end
			else
				K.disc("Eye", pos, Vector3.new(0, 0, -1), d, 0.06, color or pal.eye, M.Neon)
				K.ball("EyeShine", pos + Vector3.new(-0.06, 0.07, -0.04), d * 0.28, Color3.new(1, 1, 1), M.Neon)
			end
		end
	end
	function K.cheeks(y, z, spread, color)
		for _, side in ipairs({ -1, 1 }) do
			K.disc("Cheek", Vector3.new(side * spread, y, z), Vector3.new(0, 0, -1), 0.22, 0.04, color or pal.accent)
		end
	end
	function K.feet(y, spreadX, z1, z2, color)
		for _, sx in ipairs({ -1, 1 }) do
			for _, z in ipairs({ z1, z2 }) do
				P("Foot", Vector3.new(0.32, 0.36, 0.36), CFrame.new(sx * spreadX, y, z) * CFrame.Angles(0, 0, HALF), color, "cyl")
			end
		end
	end
	-- Веер перьев (крыло) от точки root, направление side (-1 лево, 1 право).
	function K.wing(root, side, len, color, tip, count)
		count = count or 5
		for k = 1, count do
			local a = math.rad(20 + k * 14)
			local l = len * (1 - k * 0.11)
			local cf = CFrame.new(root) * CFrame.Angles(0, side * 0.35, 0) * CFrame.Angles(0, 0, -side * a) * CFrame.new(side * l / 2, 0, 0.05 * k)
			P("Feather", Vector3.new(l, 0.32, 0.1), cf, k == 1 and (tip or color) or color)
			K.ball("FeatherTip", (cf * CFrame.new(side * l / 2, 0, 0)).Position, 0.32, tip or color)
		end
	end
	-- Перепончатое крыло дракона из клиньев.
	function K.dragonWing(root, side, size, color, edge)
		local base = CFrame.new(root) * CFrame.Angles(0, side * 0.5, 0) * CFrame.Angles(0, 0, -side * 0.5)
		for k = 0, 2 do
			local cf = base * CFrame.Angles(0, 0, side * k * 0.35) * CFrame.new(side * size * 0.5, size * 0.25, 0)
			P("WingWeb", Vector3.new(0.06, size * 0.7, size * 0.9), cf * CFrame.Angles(0, side * HALF, 0), color, "wedge")
			P("WingBone", Vector3.new(size, 0.09, 0.09), base * CFrame.Angles(0, 0, side * k * 0.35) * CFrame.new(side * size * 0.5, size * 0.6, 0) * CFrame.Angles(0, 0, side * 0.6), edge)
		end
	end
	return K
end

-- ===== Sakura =====
local SAKURA = {}
function SAKURA.Bunny(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.light)
	K.eyes(0.12, -0.81, 0.38, 0.34, "happy")
	K.cheeks(-0.12, -0.81, 0.55)
	K.ball("Nose", Vector3.new(0, -0.02, -0.82), 0.12, pal.accent)
	for _, side in ipairs({ -1, 1 }) do
		local base = Vector3.new(side * 0.42, 0.7, 0.1)
		local ear = CFrame.new(base) * CFrame.Angles(0, 0, -side * 0.18) * CFrame.new(0, 0.62, 0)
		P("Ear", Vector3.new(0.42, 1.3, 0.3), ear, pal.light, "cyl" == nil and nil or nil)
		K.ball("EarTip", (ear * CFrame.new(0, 0.62, 0)).Position, 0.42, pal.light)
		P("EarInner", Vector3.new(0.2, 1.0, 0.05), ear * CFrame.new(0, 0.05, -0.16), pal.main)
	end
	for k = -2, 2 do
		K.blossom(Vector3.new(k * 0.32, 0.8, -0.55 + math.abs(k) * 0.05), Vector3.new(0, 0.6, -1), 1.1, k % 2 == 0 and pal.accent or pal.main)
	end
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.white)
	K.ball("Tail", Vector3.new(0, -0.25, 0.9), 0.5, pal.white)
end
function SAKURA.Fox(P, K, pal)
	K.cube("Body", Vector3.new(0, 0, 0), Vector3.new(1.6, 1.4, 1.5), pal.accent)
	P("Muzzle", Vector3.new(1.0, 0.6, 0.5), CFrame.new(0, -0.25, -0.85), pal.white)
	K.ball("Nose", Vector3.new(0, -0.12, -1.12), 0.16, pal.dark)
	K.eyes(0.18, -0.77, 0.38, 0.32, nil, pal.gold)
	for _, side in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(side * 0.5, 0.68, 0), side, 0.6, 0.75, 0.2, pal.accent, pal.light, 0.2)
	end
	-- Пушистые хвосты-лепестки веером.
	for k = -2, 2 do
		local cf = CFrame.new(0, 0, 0.75) * CFrame.Angles(0, 0, k * 0.4) * CFrame.Angles(-0.7, 0, 0) * CFrame.new(0, 0.75, 0)
		P("Tail", Vector3.new(0.5, 1.4, 0.4), cf, k % 2 == 0 and pal.main or pal.accent)
		K.ball("TailTip", (cf * CFrame.new(0, 0.7, 0)).Position, 0.45, pal.white)
	end
	P("Chest", Vector3.new(0.9, 0.6, 0.1), CFrame.new(0, -0.45, -0.76), pal.white)
	K.blossom(Vector3.new(0.45, 0.72, -0.4), Vector3.new(0.3, 0.6, -1), 1.2, pal.light)
	K.feet(-0.75, 0.48, -0.4, 0.4, pal.deep)
end
function SAKURA.Cat(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.white)
	K.eyes(0.1, -0.81, 0.4, 0.38, nil, pal.eye)
	K.cheeks(-0.15, -0.81, 0.6)
	P("Mouth", Vector3.new(0.18, 0.05, 0.04), CFrame.new(0, -0.15, -0.82), pal.dark)
	for _, side in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(side * 0.5, 0.72, 0.1), side, 0.55, 0.6, 0.2, pal.white, pal.main, 0.15)
	end
	-- Большой цветок и бутоны на голове.
	K.blossom(Vector3.new(0, 0.78, -0.2), Vector3.new(0, 1, -0.4), 2.2, pal.main)
	K.blossom(Vector3.new(-0.5, 0.78, -0.3), Vector3.new(-0.3, 1, -0.4), 1.2, pal.accent)
	K.blossom(Vector3.new(0.5, 0.78, -0.3), Vector3.new(0.3, 1, -0.4), 1.2, pal.accent)
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.main)
	local tail = CFrame.new(0, -0.2, 0.85) * CFrame.Angles(-0.6, 0, 0) * CFrame.new(0, 0.5, 0)
	P("Tail", Vector3.new(0.25, 1.1, 0.25), tail, pal.white)
end
function SAKURA.Deer(P, K, pal)
	K.cube("Body", Vector3.new(0, -0.1, 0), Vector3.new(1.5, 1.3, 1.5), pal.main)
	P("Snout", Vector3.new(0.8, 0.5, 0.3), CFrame.new(0, -0.35, -0.8), pal.light)
	K.ball("Nose", Vector3.new(0, -0.25, -0.98), 0.14, pal.deep)
	K.eyes(0.1, -0.76, 0.36, 0.3, nil, pal.eye)
	for i = 1, 6 do
		K.ball("Spot", Vector3.new(((i * 37) % 10 - 5) * 0.12, -0.3 + (i % 3) * 0.25, 0.76 - (i % 2) * 1.52 * 0), 0.18, pal.white)
	end
	for _, side in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(side * 0.72, 0.3, 0), side, 0.35, 0.45, 0.15, pal.main, pal.light, 1.1)
		-- Рога-веточки с цветами.
		local root = Vector3.new(side * 0.35, 0.55, 0.1)
		local a = CFrame.new(root) * CFrame.Angles(0, 0, -side * 0.35) * CFrame.new(0, 0.5, 0)
		P("Antler", Vector3.new(0.12, 1.0, 0.12), a, pal.gold)
		for j = 1, 2 do
			local b = a * CFrame.new(0, -0.1 + j * 0.25, 0) * CFrame.Angles(0, 0, -side * 0.9) * CFrame.new(0, 0.22, 0)
			P("AntlerBranch", Vector3.new(0.09, 0.45, 0.09), b, pal.gold)
			K.blossom((b * CFrame.new(0, 0.25, 0)).Position, Vector3.new(0, 0.3, -1), 0.9, j == 1 and pal.accent or pal.light)
		end
		K.blossom((a * CFrame.new(0, 0.55, 0)).Position, Vector3.new(0, 0.3, -1), 1, pal.accent)
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -0.45, 0.45 }) do
			P("Leg", Vector3.new(0.26, 0.6, 0.26), CFrame.new(sx * 0.45, -0.95, z), pal.main)
			P("Hoof", Vector3.new(0.28, 0.14, 0.28), CFrame.new(sx * 0.45, -1.25, z), pal.deep)
		end
	end
end
function SAKURA.Sheep(P, K, pal)
	-- Пушистая шерсть из шариков, мордочка спереди.
	for i = 1, 22 do
		local a = i * 2.4
		local y = ((i * 7) % 11) / 11 * 1.3 - 0.55
		local r = 0.85 - math.abs(y) * 0.25
		K.ball("Wool", Vector3.new(math.cos(a) * r, y, math.sin(a) * r * 0.9 + 0.1), 0.75, i % 3 == 0 and pal.main or pal.light)
	end
	K.cube("Face", Vector3.new(0, -0.05, -0.75), Vector3.new(0.95, 0.85, 0.4), pal.white, 0.15)
	K.eyes(0.02, -0.97, 0.22, 0.24, "happy")
	K.cheeks(-0.18, -0.97, 0.33)
	for _, side in ipairs({ -1, 1 }) do
		P("Ear", Vector3.new(0.5, 0.2, 0.25), CFrame.new(side * 0.6, 0.15, -0.65) * CFrame.Angles(0, 0, side * 0.5), pal.white)
		K.ball("Curl", Vector3.new(side * 0.55, 0.55, -0.5), 0.45, pal.main)
	end
	K.blossom(Vector3.new(0.3, 0.75, -0.55), Vector3.new(0.2, 0.7, -1), 1.3, pal.accent)
	K.blossom(Vector3.new(-0.25, 0.85, -0.4), Vector3.new(-0.2, 0.8, -1), 1.1, pal.white)
	K.feet(-0.85, 0.45, -0.35, 0.4, pal.dark)
end
function SAKURA.Panda(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.white)
	for _, side in ipairs({ -1, 1 }) do
		K.disc("EyePatch", Vector3.new(side * 0.4, 0.05, -0.81), Vector3.new(0, 0, -1), 0.55, 0.04, pal.dark)
		K.disc("Eye", Vector3.new(side * 0.4, 0.08, -0.84), Vector3.new(0, 0, -1), 0.26, 0.04, pal.eye, M.Neon)
		K.ball("EyeShine", Vector3.new(side * 0.4 - 0.05, 0.14, -0.87), 0.08, Color3.new(1, 1, 1), M.Neon)
		K.ball("Ear", Vector3.new(side * 0.62, 0.75, 0.1), 0.55, pal.dark)
		P("Arm", Vector3.new(0.35, 0.6, 0.4), CFrame.new(side * 0.9, -0.35, -0.2), pal.dark)
	end
	K.ball("Nose", Vector3.new(0, -0.18, -0.83), 0.16, pal.dark)
	K.cheeks(-0.25, -0.82, 0.62)
	-- Венок из роз.
	for k = 0, 6 do
		local a = math.pi + k / 6 * math.pi
		K.blossom(Vector3.new(math.cos(a) * 0.7, 0.8, math.sin(a) * -0.6 * -1 - 0.1), Vector3.new(math.cos(a) * 0.4, 1, -0.5), 1.1, k % 2 == 0 and pal.accent or pal.main)
	end
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.dark)
end
function SAKURA.Butterfly(P, K, pal)
	P("Body", Vector3.new(0.4, 1.3, 0.4), CFrame.new(0, -0.1, 0), pal.deep)
	K.ball("Head", Vector3.new(0, 0.7, -0.05), 0.7, pal.main)
	K.eyes(0.75, -0.38, 0.15, 0.2, nil, pal.white)
	for _, side in ipairs({ -1, 1 }) do
		-- Верхнее и нижнее крыло: большие диски с узором.
		local up = Vector3.new(side * 0.95, 0.35, 0.15)
		local low = Vector3.new(side * 0.75, -0.55, 0.15)
		K.disc("WingUpper", up, Vector3.new(0, 0, -1), 1.5, 0.06, pal.main)
		K.disc("WingUpperEdge", up + Vector3.new(0, 0, 0.03), Vector3.new(0, 0, -1), 1.68, 0.05, pal.accent, M.Neon)
		K.disc("WingLower", low, Vector3.new(0, 0, -1), 1.05, 0.06, pal.light)
		K.disc("WingLowerEdge", low + Vector3.new(0, 0, 0.03), Vector3.new(0, 0, -1), 1.2, 0.05, pal.accent, M.Neon)
		K.disc("WingSpot", up + Vector3.new(side * 0.15, 0.1, -0.05), Vector3.new(0, 0, -1), 0.45, 0.04, pal.gold, M.Neon)
		K.blossom(low + Vector3.new(0, 0, -0.06), Vector3.new(0, 0, -1), 1.1, pal.white)
		local ant = CFrame.new(side * 0.12, 1.0, -0.1) * CFrame.Angles(0, 0, -side * 0.35) * CFrame.new(0, 0.3, 0)
		P("Antenna", Vector3.new(0.05, 0.6, 0.05), ant, pal.deep)
		K.ball("AntennaTip", (ant * CFrame.new(0, 0.3, 0)).Position, 0.15, pal.gold, M.Neon)
	end
end
function SAKURA.Dragon(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.6, 1.4, 1.6), pal.main)
	P("Snout", Vector3.new(0.9, 0.5, 0.5), CFrame.new(0, -0.3, -0.95), pal.main)
	P("Belly", Vector3.new(1.0, 0.7, 0.1), CFrame.new(0, -0.35, -0.81), pal.light)
	K.ball("Nostril", Vector3.new(-0.18, -0.15, -1.21), 0.08, pal.deep)
	K.ball("Nostril", Vector3.new(0.18, -0.15, -1.21), 0.08, pal.deep)
	K.eyes(0.22, -0.81, 0.4, 0.3, nil, pal.gold)
	for _, side in ipairs({ -1, 1 }) do
		local horn = CFrame.new(side * 0.45, 0.75, 0.2) * CFrame.Angles(-0.5, 0, -side * 0.3)
		P("Horn", Vector3.new(0.18, 0.8, 0.18), horn * CFrame.new(0, 0.35, 0), pal.gold, nil, M.Neon)
		K.dragonWing(Vector3.new(side * 0.75, 0.4, 0.4), side, 1.3, pal.accent, pal.gold)
	end
	for k = 0, 3 do
		P("Spike", Vector3.new(0.12, 0.35, 0.3), CFrame.new(0, 0.75, -0.3 + k * 0.4) * CFrame.Angles(0, HALF, 0), pal.accent, "wedge")
	end
	for k = 1, 5 do
		K.ball("Tail", Vector3.new(0, -0.3 + k * 0.06, 0.75 + k * 0.28), 0.55 - k * 0.06, k % 2 == 0 and pal.main or pal.accent)
	end
	K.blossom(Vector3.new(0, -0.05, 2.25), Vector3.new(0, 0, 1), 1.4, pal.light)
	K.blossom(Vector3.new(0.4, 0.75, -0.55), Vector3.new(0.2, 1, -0.6), 1.2, pal.white)
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.deep)
end
function SAKURA.Spirit(P, K, pal)
	-- Тёмное облачко-дух с сияющими глазами и венцом из цветов.
	for i = 1, 16 do
		local a = i * 2.4
		local y = ((i * 5) % 9) / 9 * 1.2 - 0.5
		local r = 0.75 - math.abs(y) * 0.2
		K.ball("Cloud", Vector3.new(math.cos(a) * r, y, math.sin(a) * r), 0.85, i % 2 == 0 and rgb(120, 60, 130) or rgb(160, 80, 160))
	end
	K.ball("Core", Vector3.new(0, 0.05, 0), 1.5, rgb(90, 40, 100))
	for _, side in ipairs({ -1, 1 }) do
		K.disc("Eye", Vector3.new(side * 0.3, 0.12, -0.78), Vector3.new(0, 0, -1), 0.38, 0.06, Color3.new(1, 1, 1), M.Neon)
	end
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		K.blossom(Vector3.new(math.cos(a) * 0.95, 1.2, math.sin(a) * 0.95), Vector3.new(math.cos(a), 0.6, math.sin(a)), 1.1, k % 2 == 0 and pal.accent or pal.light)
	end
	for k = 0, 19 do
		local a = k / 20 * math.pi * 2
		P("Halo", Vector3.new(0.32, 0.07, 0.1), CFrame.new(math.cos(a) * 0.8, 1.55, math.sin(a) * 0.8) * CFrame.Angles(0, -a, 0), pal.gold, nil, M.Neon)
	end
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2
		P("FloatingPetal", Vector3.new(0.04, 0.25, 0.25), CFrame.new(math.cos(a) * 1.3, (k % 3) * 0.4 - 0.3, math.sin(a) * 1.3) * CFrame.Angles(a, a, 0) * CFrame.Angles(0, HALF, 0), pal.main, "cyl", M.Neon)
	end
end

-- ===== Starlight =====
local STAR = {}
function STAR.Cat(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.main)
	K.eyes(0.08, -0.81, 0.4, 0.36, nil, pal.eye)
	for _, side in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(side * 0.5, 0.72, 0.1), side, 0.55, 0.62, 0.2, pal.main, pal.accent, 0.15)
		for k = -1, 1 do
			P("Whisker", Vector3.new(0.45, 0.03, 0.03), CFrame.new(side * 0.95, -0.15 + k * 0.08, -0.78) * CFrame.Angles(0, 0, side * k * 0.15), pal.gold, nil, M.Neon)
		end
	end
	-- Полумесяц на лбу.
	K.disc("Moon", Vector3.new(0, 0.5, -0.82), Vector3.new(0, 0, -1), 0.4, 0.04, pal.gold, M.Neon)
	K.disc("MoonCut", Vector3.new(0.09, 0.55, -0.84), Vector3.new(0, 0, -1), 0.34, 0.04, pal.main)
	K.star(Vector3.new(-0.9, 0.55, -0.3), Vector3.new(0, 0, -1), 0.9)
	for i = 1, 6 do
		K.ball("Sparkle", Vector3.new(((i * 53) % 14 - 7) * 0.1, ((i * 31) % 10 - 5) * 0.12, 0.81), 0.08, pal.white, M.Neon)
	end
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.gold)
	local tail = CFrame.new(0, -0.2, 0.85) * CFrame.Angles(-0.6, 0, 0) * CFrame.new(0, 0.5, 0)
	P("Tail", Vector3.new(0.25, 1.1, 0.25), tail, pal.main)
	K.star((tail * CFrame.new(0, 0.6, 0)).Position, Vector3.new(0, 0, -1), 0.7)
end
function STAR.Wolf(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.6, 1.4, 1.6), pal.deep)
	P("Muzzle", Vector3.new(0.9, 0.5, 0.55), CFrame.new(0, -0.28, -0.9), pal.main)
	K.ball("Nose", Vector3.new(0, -0.12, -1.18), 0.16, pal.dark)
	K.eyes(0.18, -0.81, 0.38, 0.3, nil, Color3.fromRGB(140, 230, 255))
	for _, side in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(side * 0.48, 0.68, 0.05), side, 0.5, 0.75, 0.2, pal.deep, pal.accent, 0.1)
		K.wing(Vector3.new(side * 0.7, 0.4, 0.3), side, 1.5, pal.white, pal.light, 5)
	end
	K.disc("Moon", Vector3.new(0, 0.45, -0.82), Vector3.new(0, 0, -1), 0.38, 0.04, pal.gold, M.Neon)
	K.disc("MoonCut", Vector3.new(0.08, 0.5, -0.84), Vector3.new(0, 0, -1), 0.32, 0.04, pal.deep)
	K.star(Vector3.new(0.55, 0.95, 0.4), Vector3.new(0, 0, -1), 0.6, pal.white)
	K.feet(-0.75, 0.48, -0.4, 0.4, pal.main)
	for k = 1, 3 do
		K.ball("Tail", Vector3.new(0, -0.1 + k * 0.15, 0.75 + k * 0.25), 0.5 - k * 0.05, k == 3 and pal.white or pal.deep)
	end
end
function STAR.Owl(P, K, pal)
	K.ball("Body", Vector3.new(0, -0.1, 0), 1.7, pal.main)
	K.ball("Belly", Vector3.new(0, -0.35, -0.35), 1.15, pal.light)
	for _, side in ipairs({ -1, 1 }) do
		K.disc("EyeRing", Vector3.new(side * 0.33, 0.25, -0.76), Vector3.new(0, 0, -1), 0.6, 0.05, pal.gold, M.Neon)
		K.disc("Eye", Vector3.new(side * 0.33, 0.25, -0.79), Vector3.new(0, 0, -1), 0.36, 0.05, pal.dark)
		K.ball("EyeShine", Vector3.new(side * 0.33 - 0.06, 0.32, -0.83), 0.1, Color3.new(1, 1, 1), M.Neon)
		P("Tuft", Vector3.new(0.18, 0.5, 0.3), CFrame.new(side * 0.5, 0.8, -0.1) * CFrame.Angles(0, 0, -side * 0.5), pal.accent, "wedge")
		K.wing(Vector3.new(side * 0.7, 0.1, 0.1), side, 1.2, pal.accent, pal.gold, 4)
	end
	P("Beak", Vector3.new(0.18, 0.22, 0.25), CFrame.new(0, 0.02, -0.86) * CFrame.Angles(math.pi, 0, 0), pal.gold, "wedge")
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		P("Halo", Vector3.new(0.3, 0.07, 0.1), CFrame.new(math.cos(a) * 0.65, 1.15, math.sin(a) * 0.65) * CFrame.Angles(0, -a, 0), pal.gold, nil, M.Neon)
	end
	for i = 1, 5 do
		K.star(Vector3.new(((i * 37) % 10 - 5) * 0.15, -0.3 + (i % 3) * 0.3, 0.8), Vector3.new(0, 0, 1), 0.4, pal.white)
	end
	K.feet(-0.95, 0.3, -0.2, -0.2, pal.gold)
end
function STAR.Unicorn(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.light)
	K.eyes(0.08, -0.81, 0.4, 0.36, nil, rgb(255, 150, 230))
	K.cheeks(-0.18, -0.81, 0.6, rgb(255, 160, 220))
	for _, side in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(side * 0.5, 0.72, 0.1), side, 0.45, 0.55, 0.2, pal.light, rgb(255, 180, 230), 0.15)
	end
	-- Золотой рог: витой из сегментов.
	for k = 0, 4 do
		P("Horn", Vector3.new(0.34 - k * 0.06, 0.22, 0.34 - k * 0.06), CFrame.new(0, 0.85 + k * 0.2, -0.35) * CFrame.Angles(0, k * 0.6, 0), pal.gold, nil, M.Neon)
	end
	-- Пастельная грива.
	local mane = { rgb(255, 170, 230), rgb(170, 200, 255), rgb(200, 160, 255), rgb(255, 220, 170) }
	for k = 0, 7 do
		K.ball("Mane", Vector3.new(0.25 + (k % 2) * 0.15, 0.7 - k * 0.2, 0.2 + k * 0.08), 0.55, mane[k % 4 + 1])
	end
	for k = 0, 3 do
		K.ball("Tail", Vector3.new(0, -0.2 - k * 0.1, 0.85 + k * 0.2), 0.45, mane[k + 1])
	end
	K.star(Vector3.new(-0.55, 0.45, -0.82), Vector3.new(0, 0, -1), 0.5)
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.gold)
end
function STAR.Whale(P, K, pal)
	K.ball("Body", Vector3.new(0, 0, 0), 1.9, pal.main)
	P("BodyLong", Vector3.new(1.5, 1.4, 1.8), CFrame.new(0, 0, 0.5), pal.main)
	K.ball("BodyBack", Vector3.new(0, 0, 1.3), 1.4, pal.main)
	P("Belly", Vector3.new(1.3, 0.5, 2.4), CFrame.new(0, -0.6, 0.3), pal.white)
	K.eyes(0.1, -0.88, 0.45, 0.28, nil, pal.white)
	for _, side in ipairs({ -1, 1 }) do
		P("Fin", Vector3.new(0.7, 0.12, 0.5), CFrame.new(side * 1.0, -0.4, -0.1) * CFrame.Angles(0, side * 0.3, side * 0.5), pal.accent)
		P("Fluke", Vector3.new(0.8, 0.12, 0.55), CFrame.new(side * 0.4, 0.3, 2.2) * CFrame.Angles(0.3, side * 0.5, 0), pal.accent)
	end
	-- Кольцо как у планеты.
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		P("Ring", Vector3.new(0.45, 0.08, 0.14), CFrame.Angles(0.35, 0, 0.2) * CFrame.new(math.cos(a) * 1.45, 0, math.sin(a) * 1.45 + 0.4) * CFrame.Angles(0, -a, 0), pal.gold, nil, M.Neon)
	end
	for i = 1, 8 do
		K.ball("Star", Vector3.new(((i * 41) % 12 - 6) * 0.12, 0.45 + (i % 3) * 0.12, ((i * 29) % 20) * 0.1 - 0.5), 0.09, pal.white, M.Neon)
	end
end
function STAR.Lion(P, K, pal)
	-- Пламенная золотая грива веером вокруг тёмной мордочки.
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local cf = CFrame.new(0, 0.1, 0.1) * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.0, 0)
		P("Mane", Vector3.new(0.55, 0.9, 0.35), cf, k % 2 == 0 and pal.gold or rgb(255, 170, 60), nil, M.Neon)
		K.ball("ManeTip", (cf * CFrame.new(0, 0.42, 0)).Position, 0.4, k % 2 == 0 and rgb(255, 230, 140) or pal.gold, M.Neon)
	end
	K.cube("Body", Vector3.zero, Vector3.new(1.5, 1.4, 1.5), pal.deep)
	K.eyes(0.15, -0.76, 0.33, 0.32, nil, pal.gold)
	P("Muzzle", Vector3.new(0.7, 0.35, 0.2), CFrame.new(0, -0.3, -0.8), pal.main)
	K.ball("Nose", Vector3.new(0, -0.18, -0.9), 0.14, pal.gold)
	for _, side in ipairs({ -1, 1 }) do
		K.ball("Ear", Vector3.new(side * 0.55, 0.72, 0), 0.4, pal.deep)
	end
	K.feet(-0.75, 0.45, -0.4, 0.4, pal.gold)
end
function STAR.Dragon(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.6, 1.4, 1.6), pal.main)
	P("Snout", Vector3.new(0.9, 0.5, 0.55), CFrame.new(0, -0.3, -0.95), pal.main)
	K.ball("Nostril", Vector3.new(-0.18, -0.15, -1.23), 0.08, pal.accent, M.Neon)
	K.ball("Nostril", Vector3.new(0.18, -0.15, -1.23), 0.08, pal.accent, M.Neon)
	K.eyes(0.22, -0.81, 0.4, 0.3, nil, rgb(220, 150, 255))
	for _, side in ipairs({ -1, 1 }) do
		local horn = CFrame.new(side * 0.45, 0.75, 0.2) * CFrame.Angles(-0.5, 0, -side * 0.3)
		P("Horn", Vector3.new(0.2, 0.9, 0.2), horn * CFrame.new(0, 0.4, 0), pal.light, nil, M.Neon)
		K.dragonWing(Vector3.new(side * 0.75, 0.4, 0.4), side, 1.4, pal.deep, pal.accent)
	end
	-- Кристаллические шипы по спине.
	for k = 0, 4 do
		P("Crystal", Vector3.new(0.25, 0.55, 0.25), CFrame.new(0, 0.85, -0.5 + k * 0.38) * CFrame.Angles(-0.3, math.rad(45), 0), k % 2 == 0 and pal.accent or pal.light, nil, M.Neon)
	end
	for k = 1, 5 do
		K.ball("Tail", Vector3.new(0, -0.3 + k * 0.06, 0.75 + k * 0.28), 0.55 - k * 0.06, k % 2 == 0 and pal.main or pal.deep)
	end
	P("TailCrystal", Vector3.new(0.3, 0.6, 0.3), CFrame.new(0, 0.1, 2.3) * CFrame.Angles(0.8, math.rad(45), 0), pal.accent, nil, M.Neon)
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.deep)
end
function STAR.Cloud(P, K, pal)
	for i = 1, 18 do
		local a = i * 2.4
		local y = ((i * 7) % 11) / 11 * 1.1 - 0.45
		local r = 0.8 - math.abs(y) * 0.25
		K.ball("Cloud", Vector3.new(math.cos(a) * r, y, math.sin(a) * r * 0.85), 0.85, i % 3 == 0 and pal.accent or pal.light)
	end
	K.ball("Core", Vector3.zero, 1.55, pal.light)
	K.eyes(0.05, -0.79, 0.3, 0.34, nil, pal.deep)
	K.cheeks(-0.18, -0.78, 0.5, rgb(255, 170, 230))
	K.star(Vector3.new(0, 0.55, -0.72), Vector3.new(0, 0.3, -1), 1.1)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		K.star(Vector3.new(math.cos(a) * 1.25, 0.2 + (i % 2) * 0.4, math.sin(a) * 1.25), Vector3.new(math.cos(a), 0, math.sin(a)), 0.45, pal.white)
	end
end
function STAR.Spirit(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.white)
	K.eyes(0.08, -0.81, 0.4, 0.36, nil, rgb(150, 120, 255))
	for _, side in ipairs({ -1, 1 }) do
		K.wing(Vector3.new(side * 0.75, 0.35, 0.3), side, 1.7, pal.white, pal.gold, 6)
	end
	-- Корона со звездой.
	P("CrownBand", Vector3.new(1.0, 0.25, 0.9), CFrame.new(0, 0.85, 0), pal.gold, nil, M.Foil)
	for k = -1, 1 do
		P("CrownSpike", Vector3.new(0.16, 0.45, 0.16), CFrame.new(k * 0.35, 1.15, -0.3) * CFrame.Angles(0, 0, math.rad(45)), pal.gold, nil, M.Foil)
	end
	K.star(Vector3.new(0, 1.35, -0.35), Vector3.new(0, 0, -1), 1.2)
	K.disc("Gem", Vector3.new(0, 0.85, -0.47), Vector3.new(0, 0, -1), 0.2, 0.05, pal.accent, M.Neon)
	-- Сияние вокруг.
	for k = 0, 19 do
		local a = k / 20 * math.pi * 2
		P("Aura", Vector3.new(0.35, 0.06, 0.1), CFrame.new(math.cos(a) * 1.15, 0, math.sin(a) * 1.15) * CFrame.Angles(0, -a, 0), pal.light, nil, M.Neon)
	end
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.gold)
end

-- ===== Cloud / Celestial / Crystal: питомцы третьего мира (Sky Isles) =====
local function halo(P, y, r, color)
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		P("Halo", Vector3.new(0.3, 0.07, 0.1), CFrame.new(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(0, -a, 0), color, nil, M.Neon)
	end
end
local function sparkles(K, pal, n, radius)
	for i = 1, n do
		local a = i * 2.4
		K.ball("Sparkle", Vector3.new(math.cos(a) * radius, ((i * 37) % 13 - 6) * 0.14, math.sin(a) * radius), 0.09, pal.white, M.Neon)
	end
end
local SKYP = {}
function SKYP.Bear(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.white)
	for _, s in ipairs({ -1, 1 }) do
		K.ball("Ear", Vector3.new(s * 0.62, 0.78, 0), 0.5, pal.white)
		K.ball("EarIn", Vector3.new(s * 0.62, 0.78, -0.14), 0.26, pal.accent)
		K.disc("GogRing", Vector3.new(s * 0.38, 0.3, -0.83), Vector3.new(0, 0, -1), 0.6, 0.08, pal.gold, M.Metal)
		K.disc("GogLens", Vector3.new(s * 0.38, 0.3, -0.87), Vector3.new(0, 0, -1), 0.44, 0.05, rgb(150, 225, 255), M.Neon)
	end
	P("GogBand", Vector3.new(1.76, 0.14, 1.66), CFrame.new(0, 0.3, 0), pal.deep)
	K.ball("Muzzle", Vector3.new(0, -0.3, -0.82), 0.7, pal.light)
	K.ball("Nose", Vector3.new(0, -0.22, -1.14), 0.2, pal.dark)
	P("Scarf", Vector3.new(1.8, 0.3, 1.7), CFrame.new(0, -0.62, 0), pal.accent)
	P("ScarfTail", Vector3.new(0.35, 0.8, 0.15), CFrame.new(0.5, -1.0, -0.8) * CFrame.Angles(0, 0, 0.15), pal.accent)
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.white)
end
function SKYP.Balloon(P, K, pal)
	K.ball("Balloon", Vector3.new(0, 1.0, 0), 2.0, pal.white)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		K.ball("Puff", Vector3.new(math.cos(a) * 0.85, 0.8 + (i % 2) * 0.3, math.sin(a) * 0.85), 0.9, pal.light)
	end
	for _, s in ipairs({ -1, 1 }) do
		P("Rope", Vector3.new(0.05, 0.9, 0.05), CFrame.new(s * 0.45, -0.15, 0) * CFrame.Angles(0, 0, -s * 0.35), pal.gold)
	end
	P("Basket", Vector3.new(1.1, 0.6, 1.1), CFrame.new(0, -0.9, 0), rgb(190, 140, 90), nil, M.Wood)
	K.ball("Hamster", Vector3.new(0, -0.5, 0), 0.95, pal.light)
	K.eyes(-0.45, -0.46, 0.2, 0.2, "happy")
	K.cheeks(-0.6, -0.44, 0.3, pal.accent)
	for _, s in ipairs({ -1, 1 }) do
		K.ball("Ear", Vector3.new(s * 0.34, -0.05, 0), 0.26, pal.light)
	end
end
function SKYP.Tornado(P, K, pal)
	for i = 0, 9 do
		local t = i / 9
		local r = 0.25 + t * 0.8
		local a = i * 0.9
		P("Swirl", Vector3.new(0.3, r * 2, r * 2), CFrame.new(math.sin(a) * 0.1, (t - 0.5) * 2.0, math.cos(a) * 0.1) * CFrame.Angles(0, 0, HALF), i % 2 == 0 and pal.light or pal.main, "cyl", i % 3 == 0 and M.Neon or nil)
	end
	K.eyes(0.35, -0.83, 0.28, 0.3, nil, pal.deep)
	for i = 1, 5 do
		local a = i * 1.3
		K.ball("Leaf", Vector3.new(math.cos(a) * 1.2, (i - 3) * 0.35, math.sin(a) * 1.2), 0.2, rgb(120, 210, 110))
	end
end
function SKYP.RainbowCat(P, K, pal)
	local cols = { rgb(255, 90, 90), rgb(255, 170, 80), rgb(255, 235, 100), rgb(110, 220, 130), rgb(100, 180, 255), rgb(170, 130, 255) }
	for i, c in ipairs(cols) do
		P("Rainbow", Vector3.new(1.7, 0.2, 1.6), CFrame.new(0, 0.55 - i * 0.22, 1.5), c, nil, M.Neon)
	end
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.white)
	K.eyes(0.1, -0.81, 0.4, 0.34, "happy")
	K.cheeks(-0.2, -0.81, 0.6, rgb(255, 150, 190))
	for _, s in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(s * 0.5, 0.72, 0.1), s, 0.55, 0.6, 0.2, pal.white, rgb(255, 170, 200), 0.15)
	end
	for i = -1, 1 do
		K.ball("CloudBase", Vector3.new(i * 0.6, -0.9, 0), 0.8, pal.light)
	end
end
function SKYP.Griffin(P, K, pal)
	K.cube("Body", Vector3.new(0, -0.15, 0.2), Vector3.new(1.6, 1.3, 1.8), pal.gold:Lerp(pal.white, 0.3))
	K.ball("Head", Vector3.new(0, 0.4, -0.55), 1.15, pal.white)
	P("Beak", Vector3.new(0.3, 0.3, 0.5), CFrame.new(0, 0.28, -1.2), pal.accent, "ball")
	K.eyes(0.52, -1.0, 0.28, 0.24, nil, pal.eye)
	for _, s in ipairs({ -1, 1 }) do
		K.wing(Vector3.new(s * 0.7, 0.35, 0.3), s, 1.9, pal.white, pal.gold, 6)
	end
	K.ball("TailTuft", Vector3.new(0, 0, 1.3), 0.55, pal.gold)
	K.feet(-0.85, 0.45, -0.3, 0.6, pal.gold)
end
function SKYP.AngelCat(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.white)
	K.eyes(0.08, -0.81, 0.4, 0.34, nil, pal.gold)
	for _, s in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(s * 0.5, 0.72, 0.1), s, 0.55, 0.62, 0.2, pal.white, pal.accent, 0.15)
		K.wing(Vector3.new(s * 0.75, 0.3, 0.3), s, 1.6, pal.white, pal.gold, 5)
	end
	halo(P, 1.3, 0.65, pal.gold)
	K.cheeks(-0.2, -0.81, 0.6, rgb(255, 190, 200))
	K.star(Vector3.new(0, 0.55, -0.82), Vector3.new(0, 0, -1), 0.6)
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.gold)
end
function SKYP.Storm(P, K, pal)
	local dark, mid = rgb(70, 55, 120), rgb(105, 85, 165)
	for i = 1, 18 do
		local a = i * 2.4
		local y = ((i * 7) % 11) / 11 * 1.1 - 0.45
		local r = 0.8 - math.abs(y) * 0.25
		K.ball("Cloud", Vector3.new(math.cos(a) * r, y, math.sin(a) * r * 0.85), 0.85, i % 3 == 0 and mid or dark)
	end
	K.ball("Core", Vector3.zero, 1.55, mid)
	K.eyes(0.05, -0.79, 0.3, 0.34, nil, pal.gold)
	for i = -1, 1 do
		P("Bolt", Vector3.new(0.14, 0.7, 0.14), CFrame.new(i * 0.55, -0.95, -0.2) * CFrame.Angles(0, 0, i * 0.4), pal.gold, nil, M.Neon)
	end
end
function SKYP.Blossom(P, K, pal)
	local pink, light = rgb(255, 170, 215), rgb(255, 220, 238)
	for i = 1, 16 do
		local a = i * 2.4
		local r = 0.55 + (i % 3) * 0.15
		K.ball("Bloom", Vector3.new(math.cos(a) * r, 0.6 + ((i * 5) % 7) / 7 * 0.7, math.sin(a) * r), 0.75 + (i % 2) * 0.2, i % 2 == 0 and pink or light)
	end
	K.cube("Body", Vector3.new(0, -0.15, 0), Vector3.new(1.4, 1.3, 1.4), rgb(255, 160, 205))
	K.eyes(-0.1, -0.71, 0.33, 0.32, nil, rgb(255, 110, 190))
	K.cheeks(-0.3, -0.71, 0.5, rgb(255, 120, 170))
	for i = 1, 5 do
		K.ball("Petal", Vector3.new(((i * 41) % 11 - 5) * 0.28, -0.9 - (i % 3) * 0.15, ((i * 17) % 9 - 4) * 0.25), 0.16, light)
	end
	K.feet(-0.85, 0.4, -0.3, 0.3, rgb(120, 70, 60))
end
local function islandBase(P, K, pal)
	K.cube("Rock", Vector3.new(0, -0.55, 0), Vector3.new(1.8, 1.0, 1.8), rgb(80, 68, 120), 0.3)
	P("Grass", Vector3.new(2.0, 0.28, 2.0), CFrame.new(0, 0.05, 0), rgb(120, 200, 110))
	K.eyes(-0.5, -0.92, 0.4, 0.3, nil, rgb(120, 230, 255))
	P("Water", Vector3.new(0.28, 0.9, 0.1), CFrame.new(0.72, -0.6, -0.93), rgb(150, 220, 255), nil, M.Neon)
end
function SKYP.Castle(P, K, pal)
	islandBase(P, K, pal)
	P("Keep", Vector3.new(0.9, 0.8, 0.9), CFrame.new(0, 0.55, 0), pal.white)
	for _, s in ipairs({ -1, 1 }) do
		P("Tower", Vector3.new(0.4, 1.1, 0.4), CFrame.new(s * 0.62, 0.7, 0), pal.light)
		K.ball("Roof", Vector3.new(s * 0.62, 1.4, 0), 0.5, pal.accent)
	end
	P("Spire", Vector3.new(0.45, 1.3, 0.45), CFrame.new(0, 1.3, 0), pal.light)
	K.ball("SpireRoof", Vector3.new(0, 2.0, 0), 0.6, pal.gold)
	K.star(Vector3.new(0, 2.5, 0), Vector3.new(0, 0, -1), 0.7)
end
function SKYP.Ruins(P, K, pal)
	islandBase(P, K, pal)
	for _, s in ipairs({ -1, 1 }) do
		P("Pillar", Vector3.new(0.35, s < 0 and 1.2 or 0.8, 0.35), CFrame.new(s * 0.6, s < 0 and 0.7 or 0.5, 0), pal.light, nil, M.Marble)
	end
	P("ArchBeam", Vector3.new(1.0, 0.25, 0.35), CFrame.new(-0.35, 1.4, 0) * CFrame.Angles(0, 0, 0.12), pal.white, nil, M.Marble)
	for i = 1, 6 do
		K.ball("Ivy", Vector3.new(((i * 29) % 11 - 5) * 0.15, 0.2 + (i % 3) * 0.3, ((i * 13) % 7 - 3) * 0.2), 0.22, rgb(90, 190, 90))
	end
	K.star(Vector3.new(0.6, 1.4, 0), Vector3.new(0, 0, -1), 0.5)
end
function SKYP.Pegasus(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.white)
	K.eyes(0.08, -0.81, 0.4, 0.36, nil, pal.eye)
	K.cheeks(-0.18, -0.81, 0.6, rgb(255, 190, 220))
	for _, s in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(s * 0.5, 0.72, 0.1), s, 0.45, 0.55, 0.2, pal.white, pal.accent, 0.15)
		K.wing(Vector3.new(s * 0.75, 0.35, 0.3), s, 1.8, pal.white, pal.light, 6)
	end
	local mane = { pal.accent, pal.light, pal.main, pal.white }
	for k = 0, 6 do
		K.ball("Mane", Vector3.new(0, 0.7 - k * 0.2, 0.2 + k * 0.08), 0.55, mane[k % 4 + 1])
	end
	for k = 0, 3 do
		K.ball("Tail", Vector3.new(0, -0.2 - k * 0.1, 0.85 + k * 0.2), 0.45, mane[k + 1])
	end
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.gold)
end
function SKYP.Stag(P, K, pal)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), pal.main)
	P("Muzzle", Vector3.new(0.8, 0.5, 0.4), CFrame.new(0, -0.3, -0.86), pal.light)
	K.ball("Nose", Vector3.new(0, -0.2, -1.08), 0.16, pal.dark)
	K.eyes(0.15, -0.81, 0.4, 0.3, nil, pal.eye)
	for _, s in ipairs({ -1, 1 }) do
		K.ear(Vector3.new(s * 0.62, 0.55, 0), s, 0.4, 0.5, 0.15, pal.main, pal.light, 0.9)
		P("Antler", Vector3.new(0.14, 1.1, 0.14), CFrame.new(s * 0.45, 1.2, 0.05) * CFrame.Angles(0, 0, -s * 0.25), pal.gold, nil, M.Foil)
		for b = 1, 3 do
			P("Branch", Vector3.new(0.5, 0.11, 0.11), CFrame.new(s * (0.55 + b * 0.1), 0.95 + b * 0.25, 0.05) * CFrame.Angles(0, 0, s * 0.5), pal.gold, nil, M.Foil)
		end
		K.wing(Vector3.new(s * 0.8, 0.0, 0.3), s, 0.9, pal.white, pal.light, 3)
	end
	K.star(Vector3.new(0, 0.55, -0.82), Vector3.new(0, 0, -1), 0.5)
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.deep)
end
function SKYP.Clock(P, K, pal)
	K.cube("Chest", Vector3.zero, Vector3.new(1.7, 1.4, 1.6), rgb(150, 105, 75), 0.2, M.Wood)
	P("Lid", Vector3.new(1.76, 0.4, 1.66), CFrame.new(0, 0.85, 0), rgb(120, 80, 55), nil, M.Wood)
	K.disc("FaceRim", Vector3.new(0, 0.05, -0.83), Vector3.new(0, 0, -1), 1.0, 0.06, pal.gold, M.Metal)
	K.disc("Face", Vector3.new(0, 0.05, -0.87), Vector3.new(0, 0, -1), 0.84, 0.05, rgb(255, 250, 235))
	P("HandH", Vector3.new(0.07, 0.3, 0.04), CFrame.new(0, 0.2, -0.9), rgb(40, 35, 50))
	P("HandM", Vector3.new(0.3, 0.06, 0.04), CFrame.new(0.13, 0.05, -0.9), rgb(40, 35, 50))
	K.eyes(0.82, -0.84, 0.4, 0.24, nil, rgb(200, 255, 255))
	K.ball("Lock", Vector3.new(0, 0.5, -0.86), 0.2, pal.gold, M.Metal)
	for _, s in ipairs({ -1, 1 }) do
		K.wing(Vector3.new(s * 0.85, 0.1, 0.3), s, 1.6, pal.white, pal.gold, 5)
	end
	K.feet(-0.75, 0.55, -0.45, 0.45, pal.gold)
end
function SKYP.Golem(P, K, pal)
	local glass = rgb(110, 195, 235)
	K.cube("Body", Vector3.zero, Vector3.new(1.7, 1.5, 1.6), glass, 0.2, M.Glass)
	K.eyes(0.15, -0.81, 0.38, 0.34, nil, pal.accent)
	P("Mouth", Vector3.new(0.5, 0.08, 0.05), CFrame.new(0, -0.25, -0.82), pal.accent, nil, M.Neon)
	for k = 1, 8 do
		local a = k * 0.8
		P("Crystal", Vector3.new(0.3, 0.55 + (k % 3) * 0.3, 0.3), CFrame.new(math.cos(a) * 0.55, 0.95, math.sin(a) * 0.5) * CFrame.Angles(0.25 * math.cos(a), math.rad(45), 0.25 * math.sin(a)), k % 2 == 0 and pal.accent or pal.light, nil, M.Neon)
	end
	for _, s in ipairs({ -1, 1 }) do
		K.cube("Arm", Vector3.new(s * 1.05, -0.2, 0), Vector3.new(0.45, 0.8, 0.45), glass, 0.12, M.Glass)
		P("ArmCrystal", Vector3.new(0.2, 0.5, 0.2), CFrame.new(s * 1.1, 0.35, 0) * CFrame.Angles(0, math.rad(45), s * 0.3), pal.accent, nil, M.Neon)
	end
	K.feet(-0.8, 0.5, -0.45, 0.45, pal.deep)
end
function SKYP.Phoenix(P, K, pal)
	local fire, gold = rgb(255, 140, 55), rgb(255, 215, 90)
	K.ball("Body", Vector3.zero, 1.6, fire)
	K.ball("Belly", Vector3.new(0, -0.2, -0.4), 1.0, gold)
	K.ball("Head", Vector3.new(0, 0.6, -0.4), 1.0, gold)
	K.eyes(0.68, -0.88, 0.25, 0.22, nil, rgb(120, 40, 20))
	P("Beak", Vector3.new(0.28, 0.24, 0.42), CFrame.new(0, 0.52, -1.0), rgb(255, 120, 60), "ball")
	for i = -1, 1 do
		P("Crest", Vector3.new(0.18, 0.55, 0.18), CFrame.new(i * 0.2, 1.25, -0.35) * CFrame.Angles(0, 0, -i * 0.3), fire, "ball", M.Neon)
	end
	for _, s in ipairs({ -1, 1 }) do
		K.wing(Vector3.new(s * 0.7, 0.25, 0.2), s, 1.8, fire, gold, 6)
	end
	for i = 1, 5 do
		P("TailFeather", Vector3.new(0.3, 0.45, 1.5), CFrame.new((i - 3) * 0.24, -0.25, 1.15) * CFrame.Angles(0, (i - 3) * 0.2, 0), fire:Lerp(gold, i / 7), "ball", M.Neon)
	end
end

local SKY_BUILDERS = {
	Cloud = { Cloud = STAR.Cloud, Bear = SKYP.Bear, Balloon = SKYP.Balloon, Tornado = SKYP.Tornado, RainbowCat = SKYP.RainbowCat, Unicorn = STAR.Unicorn, Griffin = SKYP.Griffin, AngelCat = SKYP.AngelCat },
	Celestial = { MoonCat = STAR.Cat, Storm = SKYP.Storm, Blossom = SKYP.Blossom, Castle = SKYP.Castle, Ruins = SKYP.Ruins, Wolf = STAR.Wolf, Dragon = STAR.Dragon, Whale = STAR.Whale },
	Crystal = { Pegasus = SKYP.Pegasus, Whale = STAR.Whale, Lion = STAR.Lion, Stag = SKYP.Stag, Clock = SKYP.Clock, Golem = SKYP.Golem, Phoenix = SKYP.Phoenix, Queen = STAR.Spirit },
}

local BUILDERS = { Sakura = SAKURA, Starlight = STAR, Sky = STAR, Aurora = STAR, Cloud = SKY_BUILDERS.Cloud, Celestial = SKY_BUILDERS.Celestial, Crystal = SKY_BUILDERS.Crystal }

function T.BuildPet(theme, kind, name)
	local pal = PALETTES[theme]
	local m, parts, P = builder(name)
	local K = kit(P, pal)
	local fn = BUILDERS[theme] and BUILDERS[theme][kind]
	if fn then
		fn(P, K, pal)
	else
		K.cube("Body", Vector3.zero, Vector3.new(1.6, 1.4, 1.5), pal.main)
		K.eyes(0.1, -0.76, 0.38, 0.32)
	end
	return finish(m, parts)
end

-- ===== Яйца =====
function T.BuildEgg(theme)
	local pal = PALETTES[theme]
	local m, _, P = builder("EggDisplay")
	local K = kit(P, pal)
	local steps = 56
	local H = 7.5
	local function radiusAt(t)
		return 3.05 * math.sqrt(math.max(0, 1 - (t * 2 - 1) ^ 2)) * (1 - 0.26 * t)
	end
	for i = 1, steps do
		local t = (i - 0.5) / steps
		local radius = radiusAt(t)
		local c
		if theme == "Sakura" then
			c = t < 0.5 and pal.accent:Lerp(pal.main, t * 2) or pal.main:Lerp(pal.light, (t - 0.5) * 2)
		else
			c = t < 0.5 and pal.deep:Lerp(pal.main, t * 2) or pal.main:Lerp(pal.accent, (t - 0.5) * 2)
		end
		P("Shell", Vector3.new(H / steps + 0.015, radius * 2, radius * 2), CFrame.new(0, (t - 0.5) * H, 0) * CFrame.Angles(0, 0, HALF), c, "cyl")
	end
	-- Точка на поверхности скорлупы: высота t (0..1) и угол a.
	local function surface(t, a, out)
		local r = radiusAt(t) + (out or 0)
		local pos = Vector3.new(math.cos(a) * r, (t - 0.5) * H, math.sin(a) * r)
		return pos, Vector3.new(math.cos(a), 0.15, math.sin(a))
	end
	if theme == "Sakura" then
		-- Ветка обвивает яйцо, на ней цветы.
		local prev
		for k = 0, 26 do
			local t = 0.12 + k / 26 * 0.75
			local a = k * 0.42
			local pos = surface(t, a, 0.05)
			if prev then
				local mid = (prev + pos) / 2
				P("Branch", Vector3.new(0.22, 0.22, (pos - prev).Magnitude + 0.1), CFrame.lookAt(mid, pos), pal.branch, nil, M.Wood)
			end
			prev = pos
			if k % 2 == 0 then
				local fp, n = surface(t + 0.03, a + 0.2, 0.1)
				K.blossom(fp, n, 2.4, k % 4 == 0 and pal.white or pal.light)
			end
		end
		for k = 1, 14 do
			local fp, n = surface(0.15 + (k * 0.37) % 0.75, k * 1.7, 0.08)
			K.blossom(fp, n, 1.6, pal.accent)
		end
	else
		-- Звёзды и искры на галактической скорлупе.
		for k = 1, 7 do
			local fp, n = surface(0.2 + (k * 0.29) % 0.65, k * 0.9, 0.08)
			K.star(fp, n, k == 1 and 3.2 or 1.8)
		end
		for k = 1, 40 do
			local fp = surface(0.08 + (k * 0.173) % 0.85, k * 2.39, 0.04)
			K.ball("Sparkle", fp, 0.12 + (k % 3) * 0.05, k % 4 == 0 and pal.gold or pal.white, M.Neon)
		end
	end
	-- Особенности яиц Sky Isles.
	if theme == "Cloud" then
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			K.ball("CloudBase", Vector3.new(math.cos(a) * 3.0, -3.6, math.sin(a) * 3.0), 1.9 + (k % 3) * 0.35, pal.white)
		end
		for _, s in ipairs({ -1, 1 }) do
			K.wing(Vector3.new(s * 2.5, 0.4, 0), s, 3.4, pal.white, pal.gold, 6)
		end
		for k = 0, 23 do
			local a = k / 24 * math.pi * 2
			P("Halo", Vector3.new(0.5, 0.1, 0.14), CFrame.new(math.cos(a) * 1.5, 4.5, math.sin(a) * 1.5) * CFrame.Angles(0, -a, 0), pal.gold, nil, M.Neon)
		end
	elseif theme == "Celestial" then
		for k = 0, 35 do
			local a = k / 36 * math.pi * 2
			P("OrbitRing", Vector3.new(0.7, 0.1, 0.18), CFrame.Angles(0.45, 0, 0.25) * CFrame.new(math.cos(a) * 4.6, 0, math.sin(a) * 4.6) * CFrame.Angles(0, -a, 0), pal.gold, nil, M.Neon)
		end
		local mp, mn = surface(0.62, -HALF, 0.1)
		K.disc("Moon", mp, mn, 2.0, 0.08, pal.gold, M.Neon)
		K.disc("MoonCut", mp + Vector3.new(0.5, 0.25, -0.12), mn, 1.7, 0.08, pal.main)
	elseif theme == "Crystal" then
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local h = 1.8 + (k % 3) * 0.7
			P("Shard", Vector3.new(0.7, h, 0.7), CFrame.new(math.cos(a) * 3.4, -3.3 + h / 2 - 0.4, math.sin(a) * 3.4) * CFrame.Angles(math.sin(a) * 0.3, a, -math.cos(a) * 0.3) * CFrame.Angles(0, math.rad(45), 0), k % 2 == 0 and pal.accent or pal.light, nil, M.Glass)
		end
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			P("Shard", Vector3.new(0.5, 1.6, 0.5), CFrame.new(math.cos(a) * 0.9, 3.9, math.sin(a) * 0.9) * CFrame.Angles(math.sin(a) * 0.5, a, -math.cos(a) * 0.5) * CFrame.Angles(0, math.rad(45), 0), pal.accent, nil, M.Glass)
		end
	end
	for i = 1, 40 do
		local a = i / 40 * math.pi * 2
		P("GlowRing", Vector3.new(0.48, 0.08, 0.1), CFrame.new(math.cos(a) * 3.1, -3.85, math.sin(a) * 3.1) * CFrame.Angles(0, -a, 0), pal.accent, nil, M.Neon)
	end
	local light = Instance.new("PointLight")
	light.Color = pal.accent
	light.Range = 15
	light.Brightness = 1.2
	light.Parent = m.PrimaryPart
	m:PivotTo(CFrame.identity)
	return m
end

return T
