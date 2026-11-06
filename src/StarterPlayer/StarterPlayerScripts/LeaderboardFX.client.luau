-- Лёгкие анимации досок лидеров. Всё считается только вблизи камеры.
--   BoardFloat (Model): доска парит — покачивание вверх-вниз (Bob), наклон (Sway, °), скорость (Speed). Sky, Galaxy.
--   BoardEmblem (Part): эмблема над доской крутится (Spin °/с) и покачивается (Bob). Если она внутри
--                       парящей доски — движется вместе с ней.
--   BoardPulse (Part):  неоновый кант мягко «дышит» (Neon-рамки, лава в Volcano).
--   IslandPond (Part):  по глади пруда расходятся круги (как на облачном острове). Атрибуты Radius, Rate.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local RANGE = 180
local rigs, emblems, pulses = {}, {}, {}

local function rigOf(p)
	local m = p:FindFirstAncestorOfClass("Model")
	while m do
		if CollectionService:HasTag(m, "BoardFloat") then return m end
		m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end
local function addRig(m)
	if m:IsA("Model") then
		-- base берём позже, когда доска (PrimaryPart) уже пришла с сервера: модель реплицируется раньше деталей
		rigs[m] = { base = nil, bob = m:GetAttribute("Bob") or 0.6, sway = math.rad(m:GetAttribute("Sway") or 1), speed = m:GetAttribute("Speed") or 0.6, phase = m:GetAttribute("Phase") or 0 }
	end
end
local function getCF(p) return p:IsA("Model") and p:GetPivot() or p.CFrame end
local function setCF(p, cf) if p:IsA("Model") then p:PivotTo(cf) else p.CFrame = cf end end
local function addEmblem(p)
	if not (p:IsA("BasePart") or p:IsA("Model")) then return end
	if p:IsA("Model") and not p:FindFirstChildWhichIsA("BasePart", true) then
		-- модель пришла раньше деталей: ждём их
		task.delay(0.5, addEmblem, p)
		return
	end
	local rig = rigOf(p)
	if rig and not rigs[rig] then addRig(rig) end
	-- для эмблем на парящих досках смещение относительно доски считаем в первом кадре (rel)
	emblems[p] = { spin = p:GetAttribute("Spin") or 0, bob = p:GetAttribute("Bob") or 0.35, rig = rig, base = (not rig) and getCF(p) or nil, phase = p:IsA("Model") and p.Name ~= "Crown" and math.random() * 6 or 0 }
end
local function addPulse(p)
	if p:IsA("BasePart") then pulses[p] = { t0 = p.Transparency, phase = math.random() * 6 } end
end

for _, m in CollectionService:GetTagged("BoardFloat") do addRig(m) end
for _, p in CollectionService:GetTagged("BoardEmblem") do addEmblem(p) end
for _, p in CollectionService:GetTagged("BoardPulse") do addPulse(p) end
CollectionService:GetInstanceAddedSignal("BoardFloat"):Connect(addRig)
CollectionService:GetInstanceAddedSignal("BoardEmblem"):Connect(function(p) task.defer(addEmblem, p) end)
CollectionService:GetInstanceAddedSignal("BoardPulse"):Connect(addPulse)
CollectionService:GetInstanceRemovedSignal("BoardFloat"):Connect(function(m) rigs[m] = nil end)
CollectionService:GetInstanceRemovedSignal("BoardEmblem"):Connect(function(p) emblems[p] = nil end)
CollectionService:GetInstanceRemovedSignal("BoardPulse"):Connect(function(p) pulses[p] = nil end)

local t = 0
local current = {} -- текущая поза парящих досок в этом кадре
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if not cam then return end
	local cp = cam.CFrame.Position
	for m, d in rigs do
		if not m.Parent then rigs[m] = nil continue end
		if not d.base then
			if not m.PrimaryPart then continue end
			d.base = m:GetPivot()
		end
		if (d.base.Position - cp).Magnitude < RANGE then
			local w = t * d.speed + d.phase
			local cf = d.base * CFrame.new(0, math.sin(w * 2) * d.bob, 0) * CFrame.Angles(math.sin(w * 1.3) * d.sway * 0.5, 0, math.sin(w) * d.sway)
			m:PivotTo(cf)
			current[m] = cf
		else
			current[m] = nil
		end
	end
	for p, d in emblems do
		if not p.Parent then emblems[p] = nil continue end
		local anchor
		if d.rig then
			local r = rigs[d.rig]
			local rc = current[d.rig] or (r and r.base)
			if not rc then continue end
			if not d.rel then d.rel = rc:ToObjectSpace(getCF(p)) end
			anchor = rc * d.rel
		else
			anchor = d.base
		end
		if anchor and (anchor.Position - cp).Magnitude < RANGE then
			local y = math.sin(t * 2 + d.phase) * d.bob
			setCF(p, CFrame.new(anchor.Position + Vector3.new(0, y, 0)) * CFrame.Angles(0, math.rad(d.spin * t), 0) * anchor.Rotation)
		end
	end
	for p, d in pulses do
		if not p.Parent then pulses[p] = nil continue end
		if (p.Position - cp).Magnitude < RANGE then
			p.Transparency = math.clamp(d.t0 + 0.18 + math.sin(t * 2.2 + d.phase) * 0.18, 0, 0.9)
		end
	end
end)

-- Круги на воде прудов островов: тонкий светлый диск растёт и тает.
local TweenService = game:GetService("TweenService")
local ponds = {}
local function addPond(p)
	if p:IsA("BasePart") then ponds[p] = { next = math.random() } end
end
for _, p in CollectionService:GetTagged("IslandPond") do addPond(p) end
CollectionService:GetInstanceAddedSignal("IslandPond"):Connect(addPond)
CollectionService:GetInstanceRemovedSignal("IslandPond"):Connect(function(p) ponds[p] = nil end)
local function ripple(p)
	local radius = p:GetAttribute("Radius") or 4
	local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * radius
	local topY = p.Position.Y + p.Size.X / 2 + 0.03 -- цилиндр лежит осью X вверх
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.04, 0.6, 0.6)
	ring.CFrame = CFrame.new(p.Position.X + math.cos(a) * r, topY, p.Position.Z + math.sin(a) * r) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Color = Color3.fromRGB(235, 250, 255)
	ring.Material = Enum.Material.SmoothPlastic
	ring.Transparency = 0.5
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Parent = workspace
	local size = p:GetAttribute("Rate") and 3.2 or 4.5
	local tw = TweenService:Create(ring, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.04, size, size), Transparency = 1 })
	tw.Completed:Connect(function() ring:Destroy() end)
	tw:Play()
end
RunService.Heartbeat:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local cp = cam.CFrame.Position
	for p, d in ponds do
		if not p.Parent then ponds[p] = nil continue end
		if (p.Position - cp).Magnitude < 120 then
			d.next -= dt
			if d.next <= 0 then
				local rate = p:GetAttribute("Rate") or 0.7
				d.next = rate * (0.6 + math.random() * 0.8)
				ripple(p)
			end
		end
	end
end)
