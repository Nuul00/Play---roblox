-- Небо Неонграда: прожекторы на крышах башен шарят по небу (как в «Бэтмене») и оставляют
-- светящиеся следы, маячки мигают, голограммы вращаются. Работает, когда камера рядом с городом.
local RunService = game:GetService("RunService")

local city = workspace:WaitForChild("CoinSpeedWorld"):WaitForChild("NeonCity")
local skyline = city:WaitForChild("NeonSkyline")
local cityCenter = city:WaitForChild("Floor").Position

local fx = Instance.new("Folder")
fx.Name = "NeonSkyFX_Local"

local function invisiblePart(name, pos)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = CFrame.new(pos)
	p.Parent = fx
	return p
end

local beacons, holos, signs, lights = {}, {}, {}, {}
local origins = {}
for _, d in ipairs(skyline:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == "Beacon" then
		table.insert(beacons, { part = d, phase = d:GetAttribute("Phase") or math.random() * 1.6 })
	elseif d:IsA("BasePart") and (d.Name == "HoloRing" or d.Name == "HoloCore") then
		table.insert(holos, { part = d, base = d.CFrame, speed = d:GetAttribute("Spin") or 0.5 })
	elseif d:IsA("SurfaceGui") then
		table.insert(signs, d)
	elseif d:IsA("Beam") and d.Attachment0 and d.Attachment1 then
		-- Старые лучи прячем: вместо них ставим новые прожекторы из тех же точек.
		table.insert(origins, d.Attachment0.WorldPosition)
		d.Enabled = false
	end
end
-- Прожектор на каждой башне: точки старых лучей + маячки на крышах, без дублей рядом.
for _, b in ipairs(beacons) do
	local pos = b.part.Position
	local near = false
	for _, o in ipairs(origins) do
		if (o - pos).Magnitude < 10 then
			near = true
			break
		end
	end
	if not near then
		table.insert(origins, pos)
	end
end
table.sort(origins, function(a, b)
	return a.Y > b.Y
end)

local palette = {
	Color3.fromRGB(120, 230, 255),
	Color3.fromRGB(255, 120, 230),
	Color3.fromRGB(190, 140, 255),
	Color3.fromRGB(255, 240, 170),
}
local function makeBeam(a0, a1, color, transparencyStart, width)
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Width0 = width * 0.12
	beam.Width1 = width
	beam.Color = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, transparencyStart),
		NumberSequenceKeypoint.new(0.7, math.min(1, transparencyStart + 0.35)),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Parent = a0.Parent
	return beam
end

for i = 1, math.min(#origins, 18) do
	local origin = origins[i]
	local color = palette[(i - 1) % #palette + 1]
	-- Корпус прожектора на крыше.
	local head = Instance.new("Part")
	head.Name = "SearchlightHead"
	head.Shape = Enum.PartType.Cylinder
	head.Size = Vector3.new(1.6, 1.8, 1.8)
	head.Material = Enum.Material.Metal
	head.Color = Color3.fromRGB(40, 42, 60)
	head.Anchored = true
	head.CanCollide = false
	head.CanQuery = false
	head.CanTouch = false
	head.CFrame = CFrame.new(origin)
	head.Parent = fx
	local lens = Instance.new("Part")
	lens.Name = "Lens"
	lens.Shape = Enum.PartType.Cylinder
	lens.Size = Vector3.new(0.2, 1.6, 1.6)
	lens.Material = Enum.Material.Neon
	lens.Color = color
	lens.Anchored = true
	lens.CanCollide = false
	lens.CanQuery = false
	lens.CanTouch = false
	lens.Parent = fx
	local a0 = Instance.new("Attachment")
	a0.Parent = lens
	-- Главный луч и два «отстающих» луча-следа.
	local targets, beams = {}, {}
	for k = 0, 2 do
		local target = invisiblePart("SkyTarget", origin + Vector3.new(0, 200, 0))
		local a1 = Instance.new("Attachment")
		a1.Parent = target
		table.insert(targets, target)
		table.insert(beams, makeBeam(a0, a1, color, 0.25 + k * 0.25, 18 - k * 3))
	end
	-- След в небе от пятна прожектора.
	local spot = targets[1]
	local t0 = Instance.new("Attachment")
	t0.Position = Vector3.new(0, 0, -7)
	t0.Parent = spot
	local t1 = Instance.new("Attachment")
	t1.Position = Vector3.new(0, 0, 7)
	t1.Parent = spot
	local trail = Instance.new("Trail")
	trail.Attachment0 = t0
	trail.Attachment1 = t1
	trail.Lifetime = 1.6
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new(0.55, 1)
	trail.Parent = spot
	table.insert(lights, {
		origin = origin,
		head = head,
		lens = lens,
		targets = targets,
		beams = beams,
		phase = i * 1.7,
		speed = 0.25 + (i % 3) * 0.07,
		radius = 70 + (i % 4) * 18,
	})
end

local shown = nil
local function setVisible(visible)
	fx.Parent = visible and workspace or nil
	for _, s in ipairs(signs) do
		s.Enabled = visible
	end
end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local now = camera ~= nil and game:GetService("Players").LocalPlayer:GetAttribute("CurrentWorld") == "Neon District"
	if now ~= shown then
		shown = now
		setVisible(now)
	end
	if not now then
		return
	end
	t += dt
	for _, b in ipairs(beacons) do
		b.part.Transparency = ((t + b.phase) % 1.6 < 0.3) and 0 or 0.8
	end
	for _, h in ipairs(holos) do
		local rotation = h.base - h.base.Position
		h.part.CFrame = CFrame.new(h.base.Position) * CFrame.Angles(0, t * h.speed, 0) * rotation
	end
	for _, l in ipairs(lights) do
		for k, target in ipairs(l.targets) do
			local a = l.phase + (t - k * 0.18) * l.speed
			-- Пятно описывает «восьмёрку», луч качается из стороны в сторону.
			local offset = Vector3.new(math.cos(a) * l.radius, 210 + math.sin(a * 2) * 25, math.sin(a * 1.3) * l.radius * 0.8)
			target.CFrame = CFrame.lookAt(l.origin + offset, l.origin + offset + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
		local aim = CFrame.lookAt(l.origin, l.targets[1].Position)
		l.head.CFrame = aim * CFrame.new(0, 0, -0.4) * CFrame.Angles(0, math.rad(90), 0)
		l.lens.CFrame = aim * CFrame.new(0, 0, -1.25) * CFrame.Angles(0, math.rad(90), 0)
	end
end)
