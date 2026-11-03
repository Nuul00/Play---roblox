-- Готовые 3D-модели порталов (ReplicatedStorage/CustomPortals/<имя>, например из Tripo3D) вместо арок из деталей.
-- Модель масштабируется до нужной высоты, ставится низом на землю проёмом к игроку, получает
-- светящийся проём с частицами и мягкий свет. Пульсацию света делает GlowFX.client (тег "PortalGlow").
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local PortalDecor = {}

function PortalDecor.Template(name: string): Instance?
	local folder = ReplicatedStorage:FindFirstChild("CustomPortals")
	local template = folder and folder:FindFirstChild(name)
	if template and template:FindFirstChildWhichIsA("BasePart", true) then
		return template
	end
	return nil
end

local function sparkles(parent: Instance, color: Color3, rate: number, size: number)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Sparkles"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Rate = rate
	e.Lifetime = NumberRange.new(1.4, 2.6)
	e.Speed = NumberRange.new(0.6, 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 1.2, 0)
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Parent = parent
	return e
end

-- Портал: bottom — точка на земле под центром проёма, facing — направление, куда смотрит проём,
-- height — высота модели, glow — цвет света и частиц, yaw — доворот модели вокруг вертикали (радианы).
function PortalDecor.Dress(parent: Instance, templateName: string, opts: { [string]: any }): Model?
	local template = PortalDecor.Template(templateName)
	if not template then
		return nil
	end
	local source = template:Clone()
	local model = Instance.new("Model")
	model.Name = opts.Name or (templateName .. "Model")
	if source:IsA("Model") then
		for _, child in ipairs(source:GetChildren()) do
			child.Parent = model
		end
		source:Destroy()
	else
		source.Parent = model
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
	local _, size = model:GetBoundingBox()
	model:ScaleTo(opts.Height / math.max(size.Y, 0.01))
	local facing = Vector3.new(opts.Facing.X, 0, opts.Facing.Z).Unit
	local cf
	cf, size = model:GetBoundingBox()
	local placed = CFrame.lookAt(opts.Bottom, opts.Bottom + facing) * CFrame.Angles(0, opts.Yaw or 0, 0)
	-- Центр рамки модели над точкой bottom, низ — на земле.
	local offset = model:GetPivot():ToObjectSpace(cf)
	model:PivotTo(placed * CFrame.new(0, size.Y / 2, 0) * offset:Inverse())

	-- Светящийся проём: невидимая плита в центре арки, из неё летят искры, в ней горит свет.
	local glow = opts.Glow or Color3.fromRGB(190, 140, 255)
	local aperture = Instance.new("Part")
	aperture.Name = "Aperture"
	aperture.Size = Vector3.new(size.X * (opts.ApertureWidth or 0.45), size.Y * (opts.ApertureHeight or 0.55), 0.4)
	aperture.CFrame = CFrame.lookAt(opts.Bottom, opts.Bottom + facing) * CFrame.new(0, size.Y * (opts.ApertureY or 0.42), 0)
	aperture.Transparency = 1
	aperture.Anchored = true
	aperture.CanCollide = false
	aperture.CanTouch = false
	aperture.CanQuery = false
	aperture.Parent = model
	sparkles(aperture, glow, opts.Rate or 18, 0.35)
	-- Вихрь: крупные полупрозрачные вращающиеся блики заполняют проём мягким сиянием.
	local swirl = Instance.new("ParticleEmitter")
	swirl.Name = "Swirl"
	swirl.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	swirl.Rate = opts.SwirlRate or 8
	swirl.Lifetime = NumberRange.new(1.6, 2.4)
	swirl.Speed = NumberRange.new(0)
	swirl.LockedToPart = true
	swirl.Rotation = NumberRange.new(0, 360)
	swirl.RotSpeed = NumberRange.new(-90, 90)
	swirl.Color = ColorSequence.new(glow)
	swirl.LightEmission = 0.8
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, aperture.Size.X * 0.3), NumberSequenceKeypoint.new(1, aperture.Size.X * 0.6) })
	swirl.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.7), NumberSequenceKeypoint.new(1, 1) })
	swirl.Parent = aperture
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = math.clamp(size.Y * 1.2, 14, 32)
	light.Brightness = opts.LightBrightness or 1.4
	light.Shadows = false
	light.Parent = aperture
	aperture:SetAttribute("BaseBrightness", light.Brightness)
	CollectionService:AddTag(aperture, "PortalGlow")

	-- Нарядный портал (opts.Fancy): столб искр от земли и кольцо из неоновых бусин в проёме,
	-- которое вращает GlowFX (тег PortalSwirl). Сам источник искр на земле невидим.
	if opts.Fancy then
		local floorGlow = Instance.new("Part")
		floorGlow.Name = "FloorGlow"
		floorGlow.Shape = Enum.PartType.Cylinder
		floorGlow.Size = Vector3.new(0.2, size.X * 0.55, size.X * 0.55)
		floorGlow.CFrame = CFrame.new(opts.Bottom + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		floorGlow.Color = glow
		floorGlow.Material = Enum.Material.Neon
		floorGlow.Transparency = 1
		floorGlow.Anchored = true
		floorGlow.CanCollide = false
		floorGlow.CanTouch = false
		floorGlow.CanQuery = false
		floorGlow.Parent = model
		local column = sparkles(floorGlow, glow, 20, 0.45)
		column.Name = "Column"
		column.EmissionDirection = Enum.NormalId.Right -- ось диска смотрит вверх
		column.SpreadAngle = Vector2.new(8, 8)
		column.Speed = NumberRange.new(3, 6)
		column.Acceleration = Vector3.zero
		local swirl = Instance.new("Model")
		swirl.Name = "Swirl"
		local center = aperture.CFrame
		local radius = math.min(aperture.Size.X, aperture.Size.Y) * 0.45
		for i = 1, 20 do
			local a = i / 20 * math.pi * 2
			local bead = Instance.new("Part")
			bead.Shape = Enum.PartType.Ball
			bead.Size = Vector3.new(0.7, 0.7, 0.7) * (0.6 + (i % 4) * 0.2)
			bead.CFrame = center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)
			bead.Color = glow:Lerp(Color3.new(1, 1, 1), (i % 3) * 0.25)
			bead.Material = Enum.Material.Neon
			bead.Anchored = true
			bead.CanCollide = false
			bead.CanTouch = false
			bead.CanQuery = false
			bead.CastShadow = false
			bead.Parent = swirl
		end
		swirl.WorldPivot = center
		swirl.Parent = model
		CollectionService:AddTag(swirl, "PortalSwirl")
	end

	model.Parent = parent
	return model
end

-- Старое оформление портала: прячем детали (свет, частицы, подписи тоже), оставляя только keep.
function PortalDecor.HideOld(root: Instance, keep: { [string]: boolean }?)
	keep = keep or {}
	local function kept(d: Instance)
		local node = d
		while node and node ~= root do
			if keep[node.Name] then
				return true
			end
			node = node.Parent
		end
		return false
	end
	for _, d in ipairs(root:GetDescendants()) do
		if not kept(d) then
			if d:IsA("BasePart") then
				d.Transparency = 1
				d.CastShadow = false
			elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
				d.Enabled = false
			elseif d:IsA("Decal") or d:IsA("Texture") then
				d.Transparency = 1
			end
		end
	end
end

return PortalDecor
