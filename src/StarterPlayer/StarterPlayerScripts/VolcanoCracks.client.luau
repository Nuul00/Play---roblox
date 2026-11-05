-- «Живой» пол Magma Volcano (только на клиенте и только пока игрок в вулкане).
-- Вокруг игрока по земле всё время рождаются трещины: ломаная линия с тёмными каменными краями
-- растёт за ~1 с, внутри разгорается лава, из щели идёт жар (марево) и летят искры, иногда
-- «выдох» — выброс дыма и углей. Потом трещина остывает (оранжевый → тёмно-красный) и исчезает,
-- а рядом появляются новые. Сама земля медленно «дышит» — свечение пола пульсирует.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local volcano = world:WaitForChild("MagmaVolcano", 120)
if not volcano then
	return
end
local deck = volcano:WaitForChild("Ground", 30) and volcano.Ground:FindFirstChild("Deck")

local MAX_CRACKS = 12 -- одновременно живущих трещин
local NEAR, FAR = 14, 70 -- где рождаются (кольцо вокруг игрока)
local HOT = Color3.fromRGB(225, 75, 15)
local WARM = Color3.fromRGB(255, 80, 20)
local COLD = Color3.fromRGB(90, 22, 14)
local ROCK = Color3.fromRGB(38, 22, 20)

local folder = Instance.new("Folder")
folder.Name = "VolcanoCracks"

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = deck and { deck } or { volcano }

local rng = Random.new()
local active = 0
local inside = false

local function part(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, parent: Instance)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function tween(obj, t, props, style)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- Жар над щелью: полупрозрачные клубы, медленно поднимаются и тают (эффект марева).
local function heat(parent: BasePart, rate: number)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Heat"
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 140, 70), Color3.fromRGB(120, 60, 50))
	e.LightEmission = 0.6
	e.LightInfluence = 0
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 4.5) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.82), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(1.8, 3)
	e.Speed = NumberRange.new(2, 4)
	e.SpreadAngle = Vector2.new(12, 12)
	e.EmissionDirection = Enum.NormalId.Top
	e.RotSpeed = NumberRange.new(-20, 20)
	e.Rate = rate
	e.Parent = parent
	return e
end

-- Искры: мелкие угольки вылетают из щели и гаснут.
local function sparks(parent: BasePart, rate: number)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Sparks"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 90, 20))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.6, 1.4)
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(25, 25)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -6, 0)
	e.Rate = rate
	e.Parent = parent
	return e
end

-- Одна трещина: ломаная из 3–6 отрезков, иногда с ответвлением.
local function crack(origin: Vector3, outward: number?)
	active += 1
	local model = Instance.new("Model")
	model.Name = "Crack"
	model.Parent = folder
	local glows, rims, halos = {}, {}, {}
	-- трещины бегут от вулкана наружу: направление — от кратера, с небольшим разбросом
	local heading = outward and (outward + rng:NextNumber(-0.35, 0.35)) or rng:NextNumber(0, math.pi * 2)
	local pts = { origin }
	local nSeg = rng:NextInteger(3, 6)
	for _ = 1, nSeg do
		heading += rng:NextNumber(-0.45, 0.45)
		local len = rng:NextNumber(4, 8.5)
		local last = pts[#pts]
		table.insert(pts, last + Vector3.new(math.cos(heading) * len, 0, math.sin(heading) * len))
	end
	-- ответвление от середины
	local branch
	if rng:NextNumber() < 0.55 then
		local from = pts[math.max(2, math.floor(#pts / 2))]
		local h = heading + (rng:NextNumber() < 0.5 and 1 or -1) * rng:NextNumber(0.8, 1.4)
		branch = { from, from + Vector3.new(math.cos(h) * 6, 0, math.sin(h) * 6) }
	end
	local function segment(a: Vector3, b: Vector3, width: number, delay: number)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt(mid, b)
		-- каменные края приподняты: щель выглядит объёмной
		for _, side in ipairs({ -1, 1 }) do
			-- рваный край: 2–3 вздыбленных куска камня вдоль каждой стороны
			local pieces = math.max(1, math.floor(len / 3))
			for k = 1, pieces do
				local z = (k - 0.5) / pieces * len - len / 2
				local w = rng:NextNumber(0.7, 1.1)
				local h = rng:NextNumber(0.35, 0.7)
				local rim = part(Vector3.new(w, h, 0.1), cf * CFrame.new(side * (width / 2 + w / 2 - 0.1), h / 2 - 0.05, z) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(-0.2, 0.2), side * rng:NextNumber(0.25, 0.5)), ROCK:Lerp(Color3.fromRGB(70, 40, 34), rng:NextNumber()), Enum.Material.Basalt, model)
				table.insert(rims, rim)
				task.delay(delay + k * 0.05, function()
					tween(rim, 0.3, { Size = Vector3.new(w, h, len / pieces + 0.5) }, Enum.EasingStyle.Back)
				end)
			end
		end
		local g = part(Vector3.new(width, 0.14, 0.1), cf * CFrame.new(0, 0.05, 0), HOT, Enum.Material.Neon, model)
		g.Transparency = 0.05
		table.insert(glows, g)
		task.delay(delay, function()
			tween(g, 0.35, { Size = Vector3.new(width, 0.14, len + 0.9) }) -- внахлёст: без щелей на стыках
		end)
		return g
	end
	local first
	for i = 1, #pts - 1 do
		local w = 0.45 + 0.85 * math.sin(i / #pts * math.pi) -- к концам сужается в ниточку
		local g = segment(pts[i], pts[i + 1], w, (i - 1) * 0.2)
		first = first or g
	end
	if branch then
		segment(branch[1], branch[2], 0.6, #pts * 0.2)
	end
	-- свет и жар из центра трещины
	local center = pts[math.floor(#pts / 2) + 1]
	local core = part(Vector3.new(1, 0.2, 1), CFrame.new(center + Vector3.new(0, 0.2, 0)), HOT, Enum.Material.SmoothPlastic, model)
	core.Transparency = 1
	local light = Instance.new("PointLight")
	light.Color = WARM
	light.Range = 0
	light.Brightness = 1.8
	light.Parent = core
	tween(light, 1.2, { Range = 16 })
	local haze = heat(core, 3)
	local spk = sparks(core, 6)
	-- «выдох»: иногда щель плюётся углями и дымом
	if rng:NextNumber() < 0.45 then
		task.delay(rng:NextNumber(1.2, 3), function()
			if core.Parent then
				spk:Emit(25)
				haze:Emit(6)
				tween(light, 0.15, { Brightness = 6 })
				task.wait(0.25)
				tween(light, 0.8, { Brightness = 2.5 })
			end
		end)
	end
	-- живёт 5–9 с, мерцая, затем остывает и затягивается
	local life = rng:NextNumber(5, 9)
	local t0 = os.clock()
	while os.clock() - t0 < life and inside do
		local k = 0.5 + 0.5 * math.sin((os.clock() - t0) * 6 + center.X)
		for _, g in ipairs(glows) do
			g.Color = HOT:Lerp(Color3.fromRGB(255, 130, 30), k * 0.6)
		end
		task.wait(0.12)
	end
	haze.Rate, spk.Rate = 0, 0
	tween(light, 2.5, { Brightness = 0, Range = 2 })
	for _, g in ipairs(glows) do
		tween(g, 2.5, { Color = COLD, Transparency = 0.6 })
	end
	task.wait(2.5)
	for _, p in ipairs(glows) do
		tween(p, 1.2, { Transparency = 1 })
	end
	for _, p in ipairs(halos) do
		tween(p, 1.2, { Transparency = 1 })
	end
	for _, p in ipairs(rims) do
		tween(p, 1.2, { Transparency = 1 })
	end
	task.wait(1.3)
	model:Destroy()
	active -= 1
end

-- Вулкан: центр и радиус подножия (по модели Tripo, если она есть).
local mountain = volcano:WaitForChild("Volcano", 30)
local VCENTER, VBASE, VTOP = Vector3.new(6000, 60, -110), 90, 140
local function measureVolcano()
	local m = mountain and (mountain:FindFirstChild("TripoModel") or mountain)
	if m and m:IsA("Model") then
		local cf, ext = m:GetBoundingBox()
		VCENTER = Vector3.new(cf.Position.X, cf.Position.Y - ext.Y / 2, cf.Position.Z)
		VBASE = math.max(ext.X, ext.Z) / 2
		VTOP = cf.Position.Y + ext.Y / 2
	end
end
measureVolcano()

-- Ищем точку на голой земле вулкана (не на дорожках, площадях и лаве) на лучах от подножия
-- вулкана в ту сторону, где игрок: трещины расходятся от вулкана.
local function spot(): (Vector3?, number?)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local rel = root.Position - VCENTER
	local pa = math.atan2(rel.Z, rel.X)
	local pr = Vector2.new(rel.X, rel.Z).Magnitude
	for _ = 1, 6 do
		local a, r
		if rng:NextNumber() < 0.65 then
			a = pa + rng:NextNumber(-0.45, 0.45)
			r = rng:NextNumber(VBASE * 0.8, math.max(VBASE + 25, pr + 35))
		else
			a = rng:NextNumber(0, math.pi * 2)
			r = VBASE * rng:NextNumber(0.8, 1.2)
		end
		local p = VCENTER + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local from = Vector3.new(p.X, root.Position.Y + 40, p.Z)
		local hit = workspace:Raycast(from, Vector3.new(0, -120, 0), rayParams)
		if hit then
			-- над щелью ничего не должно стоять (дорожка, площадь, постройка)
			local check = workspace:Raycast(from, Vector3.new(0, -120, 0))
			if check and check.Instance == hit.Instance and (hit.Position - root.Position).Magnitude < FAR * 1.5 then
				return hit.Position, a
			end
		end
	end
	return nil
end

-- Земля «дышит»: свечение пола медленно пульсирует.
local baseColor = deck and deck.Color
local breathConn: RBXScriptConnection? = nil

local function onWorld()
	local now = player:GetAttribute("CurrentWorld") == "Magma Volcano"
	if now == inside then
		return
	end
	inside = now
	folder.Parent = inside and workspace or nil
	if inside then
		if deck and baseColor then
			breathConn = RunService.Heartbeat:Connect(function()
				local k = 0.5 + 0.5 * math.sin(os.clock() * 0.8)
				deck.Color = baseColor:Lerp(Color3.fromRGB(150, 40, 26), k * 0.55)
			end)
		end
		task.spawn(function()
			while inside do
				if active < MAX_CRACKS then
					local p, a = spot()
					if p then
						task.spawn(crack, p, a)
					end
				end
				task.wait(rng:NextNumber(0.15, 0.45))
			end
		end)
	else
		if breathConn then
			breathConn:Disconnect()
			breathConn = nil
		end
		if deck and baseColor then
			deck.Color = baseColor
		end
	end
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
onWorld()
