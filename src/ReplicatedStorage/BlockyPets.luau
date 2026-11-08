-- Блочные питомцы из деталей (стиль «кубический пет»): большая голова, неоновые глаза, крылья из перьев.
-- Модель строится в своих единицах (рост ~9), потом ScaleTo подгоняет её под размер редкости.
-- Перед — по -Z, как у процедурных питомцев в PetVisuals.
local BlockyPets = {}

local PALETTES = {
	Shadow = {
		main = Color3.fromRGB(26, 26, 32), dark = Color3.fromRGB(48, 48, 60), light = Color3.fromRGB(140, 140, 158),
		trim = Color3.fromRGB(240, 240, 248), eye = Color3.fromRGB(120, 255, 90), nose = Color3.fromRGB(8, 8, 10),
	},
	Frost = {
		main = Color3.fromRGB(225, 238, 255), dark = Color3.fromRGB(170, 200, 235), light = Color3.fromRGB(120, 160, 210),
		trim = Color3.fromRGB(110, 215, 255), eye = Color3.fromRGB(70, 200, 255), nose = Color3.fromRGB(40, 60, 95),
	},
}

local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local r = math.rad

local function wingWolf(model: Model, parts, pal)
	local function p(size, cf, color, mat)
		local b = Instance.new("Part")
		b.Size = size
		b.CFrame = cf
		b.Color = color
		b.Material = mat or Enum.Material.SmoothPlastic
		b.Anchored = true
		b.CanCollide = false
		b.CanTouch = false
		b.CanQuery = false
		b.CastShadow = false
		b.TopSurface = Enum.SurfaceType.Smooth
		b.BottomSurface = Enum.SurfaceType.Smooth
		b.Parent = model
		table.insert(parts, { part = b, transparency = 0 })
		return b
	end
	local body = p(V(2.8, 2.4, 3.8), C(0, 2.9, 0.2), pal.main)
	body.Name = "Body"
	model.PrimaryPart = body
	p(V(3.2, 2.6, 1.4), C(0, 3.2, -1.4), pal.dark) -- грива на груди
	p(V(2.0, 0.8, 1.0), C(0, 1.9, -1.7), pal.light)
	local H = C(0, 5.3, -2.6)
	p(V(3.4, 3.0, 3.0), H, pal.main) -- голова
	p(V(3.8, 1.0, 1.6), H * C(0, -0.9, 0.6), pal.dark) -- щёки
	p(V(1.7, 1.2, 1.3), H * C(0, -0.7, -2.0), pal.main) -- морда
	p(V(1.4, 0.35, 1.2), H * C(0, -1.35, -1.9), pal.light)
	p(V(0.8, 0.5, 0.35), H * C(0, -0.25, -2.65), pal.nose)
	for _, s in { -1, 1 } do
		local eye = p(V(0.85, 0.55, 0.12), H * C(0.78 * s, 0.25, -1.52), pal.eye, Enum.Material.Neon)
		eye.Name = "Eye"
		if s == 1 then
			local l = Instance.new("PointLight")
			l.Color = pal.eye
			l.Range = 5
			l.Brightness = 1.5
			l.Parent = eye
		end
		p(V(0.25, 0.25, 0.13), H * C(0.62 * s, 0.33, -1.55), Color3.new(1, 1, 1), Enum.Material.Neon)
		p(V(1.0, 0.16, 0.16), H * C(0.78 * s, 0.65, -1.53) * A(0, 0, r(-14 * s)), pal.nose)
		p(V(0.9, 1.2, 0.45), H * C(1.1 * s, 1.9, 0.3) * A(0, 0, r(-14 * s)), pal.main) -- уши
		p(V(0.45, 0.75, 0.1), H * C(1.1 * s, 1.85, 0.04) * A(0, 0, r(-14 * s)), pal.light)
		-- рога: дуга вверх, назад и наружу
		local base = V(0.55 * s, 1.5, -0.7)
		local pts = { V(0, 0, 0), V(0.15 * s, 0.6, 0.2), V(0.35 * s, 1.1, 0.6), V(0.55 * s, 1.4, 1.15), V(0.7 * s, 1.45, 1.75) }
		for i = 1, #pts - 1 do
			local a, b = base + pts[i], base + pts[i + 1]
			local sz = 0.62 - i * 0.1
			p(V(sz, sz, (b - a).Magnitude + 0.25), H * CFrame.lookAt((a + b) / 2, b), i == #pts - 1 and pal.light or pal.trim)
		end
		for _, z in { -1.2, 1.5 } do -- лапы с повязками
			p(V(0.95, 1.8, 0.95), C(1.0 * s, 1.05, z), pal.main)
			p(V(1.1, 0.45, 1.1), C(1.0 * s, 0.3, z), pal.trim)
		end
		-- крыло: две кости и 7 перьев
		local root = C(1.4 * s, 4.0, 0.2) * A(0, r(-20 * s), r(30 * s))
		p(V(2.4, 0.45, 0.6), root * C(1.2 * s, 0, 0), pal.dark)
		local tip = root * C(2.4 * s, 0, 0) * A(0, 0, r(25 * s))
		p(V(2.4, 0.4, 0.5), tip * C(1.2 * s, 0, 0), pal.dark)
		for i = 1, 7 do
			local along = i * 0.64
			local seg = (along <= 2.4) and root * C(along * s, 0, 0) or tip * C((along - 2.4) * s, 0, 0)
			local len = 1.8 + i * 0.26
			local fc = seg * C(0, -0.05, 0.2) * A(r(-62 + i * 4), 0, 0)
			p(V(0.62, 0.18, len), fc * C(0, 0, len / 2), i % 2 == 0 and pal.main or pal.dark)
			p(V(0.62, 0.2, 0.55), fc * C(0, 0, len + 0.22), i > 4 and pal.trim or pal.light)
		end
	end
	for i = 0, 3 do
		p(V(0.32, 0.55, 0.45), C(0, 4.25, -0.6 + i * 0.65) * A(r(-30), 0, 0), pal.dark) -- шипы на спине
	end
	local tpts = { V(0, 3.4, 2.0), V(0, 3.9, 2.6), V(0, 4.6, 3.0), V(0, 5.3, 3.1), V(0, 5.9, 2.9) }
	for i = 1, #tpts - 1 do
		local a, b = tpts[i], tpts[i + 1]
		local w = 0.85 - i * 0.1
		p(V(w, w, (b - a).Magnitude + 0.25), CFrame.lookAt((a + b) / 2, b), i == #tpts - 1 and pal.trim or pal.main)
	end
end

local KINDS = { WingWolf = wingWolf }

-- key: "<Kind>_<Palette>", например "WingWolf_Shadow". targetSize — наибольший размер модели в студах.
function BlockyPets.Build(key: string, name: string, targetSize: number)
	local kind, palName = string.match(key, "^(%a+)_(%a+)$")
	local builder = KINDS[kind or ""]
	local pal = PALETTES[palName or ""]
	if not builder or not pal then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = name
	local parts = {}
	builder(model, parts, pal)
	-- Опора в центре рамки, затем масштаб под редкость.
	local bb, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(bb.Position)
	model:ScaleTo(targetSize / math.max(size.X, size.Y, size.Z, 0.1))
	model:PivotTo(CFrame.identity)
	return model, parts
end

return BlockyPets
