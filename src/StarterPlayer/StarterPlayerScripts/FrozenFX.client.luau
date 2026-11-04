-- Эффекты Frozen Peaks на клиенте: снегопад вокруг камеры, переливы северного сияния
-- и мягкое мерцание кристаллов. Работает только пока игрок в этом мире.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local frozen = world:WaitForChild("FrozenPeaks", 90)
if not frozen then
	return
end

-- Снег: невидимая плита над камерой, частицы падают вниз.
local snow = Instance.new("Part")
snow.Name = "FrozenSnowEmitter"
snow.Anchored, snow.CanCollide, snow.CanTouch, snow.CanQuery = true, false, false, false
snow.Transparency = 1
snow.Size = Vector3.new(140, 1, 140)
local flakes = Instance.new("ParticleEmitter")
flakes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
flakes.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
flakes.LightEmission = 0.15
flakes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.14) })
flakes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.15), NumberSequenceKeypoint.new(0.85, 0.3), NumberSequenceKeypoint.new(1, 1) })
flakes.Lifetime = NumberRange.new(6, 8)
flakes.Rate = 180
flakes.Speed = NumberRange.new(6, 9)
flakes.EmissionDirection = Enum.NormalId.Bottom
flakes.SpreadAngle = Vector2.new(15, 15)
flakes.Acceleration = Vector3.new(1.5, 0, 0.8)
flakes.RotSpeed = NumberRange.new(-60, 60)
flakes.Parent = snow

local bands = {}
for _, b in ipairs(frozen:WaitForChild("Aurora", 30):GetDescendants()) do
	if b:IsA("Beam") then
		table.insert(bands, { beam = b, k = b:GetAttribute("Band") or 1, layer = b:GetAttribute("Layer") or 1, c0 = b.CurveSize0, c1 = b.CurveSize1 })
	end
end
local glows = CollectionService:GetTagged("FrozenGlow")

-- Как и в Sky Isles: детали мира иногда приходят на клиент со скрытием LocalTransparencyModifier = 1
-- (причина в движке не найдена), поэтому на входе в мир снимаем его со всех деталей острова.
local frozenParts = {}
for _, d in ipairs(frozen:GetDescendants()) do
	if d:IsA("BasePart") then
		table.insert(frozenParts, d)
	end
end
frozen.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") then
		table.insert(frozenParts, d)
	end
end)
local function showParts()
	for _, p in ipairs(frozenParts) do
		if p.LocalTransparencyModifier > 0 then
			p.LocalTransparencyModifier = 0
		end
	end
end

local conn: RBXScriptConnection? = nil
local t = 0
local function step(dt: number)
	t += dt
	local cam = workspace.CurrentCamera
	if cam then
		local p = cam.CFrame.Position
		snow.CFrame = CFrame.new(p.X, p.Y + 35, p.Z)
	end
	for _, b in ipairs(bands) do
		local k = b.k
		local h = 0.36 + 0.1 * math.sin(t * 0.2 + k * 0.9)
		b.beam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(h % 1, 0.75, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromHSV((h + 0.1) % 1, 0.7, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV((h + 0.32) % 1, 0.6, 1)),
		})
		local wave = math.sin(t * 0.35 + k * 1.7)
		b.beam.CurveSize0 = b.c0 * (1 + 0.3 * wave)
		b.beam.CurveSize1 = b.c1 * (1 - 0.3 * wave)
		local tr = 0.5 + b.layer * 0.12 + 0.08 * math.sin(t * 0.5 + k)
		b.beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, tr), NumberSequenceKeypoint.new(0.8, tr), NumberSequenceKeypoint.new(1, 1) })
	end
	local pulse = 0.25 + 0.15 * math.sin(t * 1.6)
	for i, g in ipairs(glows) do
		if g.Parent then
			g.Transparency = pulse + 0.1 * math.sin(t * 2 + i)
		end
	end
end

local function onWorld()
	local inside = player:GetAttribute("CurrentWorld") == "Frozen Peaks"
	if inside and not conn then
		snow.Parent = workspace
		showParts()
		task.delay(1, showParts)
		task.delay(3, showParts)
		glows = CollectionService:GetTagged("FrozenGlow")
		conn = RunService.RenderStepped:Connect(step)
	elseif not inside and conn then
		conn:Disconnect()
		conn = nil
		snow.Parent = nil
	end
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
onWorld()
