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
-- Второй слой: мягкие круглые хлопья покрупнее, кружатся, как в потрясённом снежном шаре.
local soft = Instance.new("ParticleEmitter")
soft.Name = "GlobeFlakes"
soft.Texture = "rbxasset://textures/particles/smoke_main.dds"
soft.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
soft.LightEmission = 0.5
soft.LightInfluence = 0.2
soft.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.35) })
soft.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.05), NumberSequenceKeypoint.new(0.85, 0.2), NumberSequenceKeypoint.new(1, 1) })
soft.Lifetime = NumberRange.new(7, 10)
soft.Rate = 260
soft.Speed = NumberRange.new(3, 6)
soft.EmissionDirection = Enum.NormalId.Bottom
soft.SpreadAngle = Vector2.new(25, 25)
soft.RotSpeed = NumberRange.new(-90, 90)
soft.Rotation = NumberRange.new(0, 360)
soft.Parent = snow
snow.Size = Vector3.new(180, 1, 180)

local bands = {}
for _, b in ipairs(frozen:WaitForChild("Aurora", 30):GetDescendants()) do
	if b:IsA("Beam") then
		table.insert(bands, { beam = b, k = b:GetAttribute("Band") or 1, layer = b:GetAttribute("Layer") or 1, c0 = b.CurveSize0, c1 = b.CurveSize1 })
	end
end
local glows = CollectionService:GetTagged("FrozenGlow")
local AURORA = {
	Color3.fromRGB(70, 255, 150), -- зелёный
	Color3.fromRGB(60, 240, 210), -- бирюзовый
	Color3.fromRGB(90, 170, 255), -- голубой
	Color3.fromRGB(170, 100, 255), -- фиолетовый
	Color3.fromRGB(255, 110, 200), -- розовый
}
local auroraAcc = 0
-- прозрачность слоёв снизу вверх: мягкий низ, яркое зелёное ядро, тающая к верху кайма
local LAYER_ALPHA = { 0.5, 0.22, 0.26, 0.38, 0.5, 0.64 }

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
		snow.CFrame = CFrame.new(p.X, p.Y + 38, p.Z)
		-- ветер внутри шара медленно меняет направление — снег кружится
		local wx, wz = math.sin(t * 0.21) * 3.5, math.cos(t * 0.17) * 3.5
		flakes.Acceleration = Vector3.new(wx, 0, wz)
		soft.Acceleration = Vector3.new(wx * 1.3, math.sin(t * 0.5) * 0.6, wz * 1.3)
	end
	-- Сияние как настоящее: вдоль занавеси цвета перетекают (зелёный → бирюзовый → фиолетовый →
	-- розовый), по ней бегут вертикальные «лучи» (полосы прозрачности), а сама занавесь колышется.
	-- Нижний слой — зелёное ядро, верхние — фиолетово-розовая кайма. Обновляем 15 раз в секунду.
	auroraAcc += dt
	if auroraAcc >= 0.066 then
		auroraAcc = 0
		for _, b in ipairs(bands) do
			local k, layer = b.k, b.layer
			local cols = {}
			for i = 0, 9 do
				local x = i / 9
				local flow = 0.5 + 0.5 * math.sin(x * 5.5 - t * 0.45 + k * 1.3)
				local fringe = (layer - 1) / 5 -- 0 у нижнего края (зелёный), 1 у верхнего (розовый)
				local mix = math.clamp(fringe * 0.72 + flow * 0.3 - 0.04, 0, 1)
				local col = AURORA[1]
				for c = 1, #AURORA - 1 do
					local a0, a1 = (c - 1) / (#AURORA - 1), c / (#AURORA - 1)
					if mix >= a0 and mix <= a1 then
						col = AURORA[c]:Lerp(AURORA[c + 1], (mix - a0) / (a1 - a0))
						break
					end
				end
				cols[i + 1] = ColorSequenceKeypoint.new(x, col)
			end
			b.beam.Color = ColorSequence.new(cols)
			local base = LAYER_ALPHA[layer] or 0.7
			local tr = {}
			for i = 0, 15 do
				local x = i / 15
				local edge = math.min(x, 1 - x) * 5 -- затухание к концам
				local rays = 0.22 * math.sin(x * 38 + t * 1.3 + k * 2) + 0.12 * math.sin(x * 91 - t * 2.1 + layer)
				local shimmer = 0.1 * math.sin(t * 0.8 + k + x * 4)
				tr[i + 1] = NumberSequenceKeypoint.new(x, math.clamp(base + rays + shimmer + (1 - math.min(edge, 1)), 0, 1))
			end
			b.beam.Transparency = NumberSequence.new(tr)
			local wave = math.sin(t * 0.35 + k * 1.7)
			b.beam.CurveSize0 = b.c0 * (1 + 0.35 * wave)
			b.beam.CurveSize1 = b.c1 * (1 - 0.35 * wave)
		end
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
