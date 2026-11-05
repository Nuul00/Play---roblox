-- Живые сундуки Sky Isles (модель Tripo внутри Chest/TripoModel):
--  • издалека покачиваются и мягко светятся;
--  • чем ближе игрок, тем сильнее «радуются»: прыгают, вертятся, вокруг больше искр;
--  • при открытии: сжатие и прыжок, вспышка, фонтан монет к игроку и «+N»;
--  • после открытия сундук «спит» (тусклый, с таймером) до конца перезарядки.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local NEAR = 40
local COLORS = { Color3.fromRGB(255, 170, 215), Color3.fromRGB(140, 170, 255), Color3.fromRGB(255, 215, 110) }

local chests = {}

local function comma(n: number): string
	for _, u in ipairs({ { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" } }) do
		if n >= u[1] then
			return (string.format("%.2f", n / u[1]):gsub("%.?0+$", "")) .. u[2]
		end
	end
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function setup(base: BasePart)
	local chest = base.Parent
	if not chest then
		return
	end
	local model = chest:WaitForChild("TripoModel", 20)
	if not model then
		return
	end
	local id = base:GetAttribute("ChestId") or 1
	local color = COLORS[id] or COLORS[1]
	local anchor = Instance.new("Part")
	anchor.Name = "ChestFXAnchor"
	anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	local cf, size = model:GetBoundingBox()
	anchor.CFrame = CFrame.new(cf.Position)
	anchor.Parent = chest
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 16
	light.Brightness = 0.8
	light.Parent = anchor
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(0.8, 1.4)
	sparks.Speed = NumberRange.new(2, 5)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 2
	sparks.Parent = anchor
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 40)
	gui.StudsOffset = Vector3.new(0, size.Y / 2 + 2.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 70
	gui.Enabled = false
	local timer = Instance.new("TextLabel")
	timer.BackgroundTransparency = 1
	timer.Size = UDim2.fromScale(1, 1)
	timer.Font = Enum.Font.FredokaOne
	timer.TextScaled = true
	timer.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(70, 40, 110)
	stroke.Parent = timer
	timer.Parent = gui
	gui.Parent = anchor
	chests[id] = {
		id = id,
		model = model,
		base = model:GetPivot(),
		center = cf.Position,
		height = size.Y,
		light = light,
		sparks = sparks,
		gui = gui,
		timer = timer,
		color = color,
		phase = id * 1.9,
		sleepUntil = 0,
		popUntil = 0,
		excite = 0,
	}
end

for _, b in ipairs(CollectionService:GetTagged("SkyChest")) do
	task.spawn(setup, b)
end
CollectionService:GetInstanceAddedSignal("SkyChest"):Connect(function(b)
	task.spawn(setup, b)
end)

-- Фонтан монет: монетки вылетают из сундука и летят к игроку.
local function coinFountain(c, reward: number)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for i = 1, 18 do
		local coin = Instance.new("Part")
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.25, 1, 1)
		coin.Color = Color3.fromRGB(255, 205, 60)
		coin.Material = Enum.Material.Neon
		coin.Anchored, coin.CanCollide, coin.CanTouch, coin.CanQuery = true, false, false, false
		coin.CFrame = CFrame.new(c.center + Vector3.new(0, c.height * 0.4, 0))
		coin.Parent = workspace
		local a = math.random() * math.pi * 2
		local up = c.center + Vector3.new(math.cos(a) * 4, c.height + 4 + math.random() * 3, math.sin(a) * 4)
		task.delay(i * 0.03, function()
			local t1 = TweenService:Create(coin, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(up) * CFrame.Angles(0, a, math.pi / 2) })
			t1:Play()
			t1.Completed:Wait()
			local target = root and root.Position or c.center
			local t2 = TweenService:Create(coin, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(target), Size = Vector3.new(0.1, 0.3, 0.3) })
			t2:Play()
			t2.Completed:Wait()
			coin:Destroy()
		end)
	end
	-- «+N» над сундуком
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.AlwaysOnTop = true
	gui.StudsOffset = Vector3.new(0, c.height + 2, 0)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = "+" .. comma(reward)
	t.TextColor3 = Color3.fromRGB(255, 225, 90)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = Color3.fromRGB(120, 60, 20)
	s.Parent = t
	t.Parent = gui
	gui.Adornee = c.gui.Parent
	gui.Parent = c.gui.Parent
	TweenService:Create(gui, TweenInfo.new(1.6), { StudsOffset = Vector3.new(0, c.height + 7, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	TweenService:Create(s, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
	task.delay(1.7, function()
		gui:Destroy()
	end)
end

ReplicatedStorage:WaitForChild("SkyChestOpened").OnClientEvent:Connect(function(id, reward, refillAt)
	local c = chests[id]
	if not c then
		return
	end
	c.popUntil = os.clock() + 0.9
	c.sleepUntil = refillAt
	c.sparks:Emit(60)
	local flash = TweenService:Create(c.light, TweenInfo.new(0.15), { Brightness = 8, Range = 30 })
	flash:Play()
	task.delay(0.2, function()
		TweenService:Create(c.light, TweenInfo.new(0.8), { Brightness = 0.25, Range = 12 }):Play()
	end)
	coinFountain(c, reward)
end)

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local now = os.time()
	for _, c in pairs(chests) do
		if c.model.Parent then
			local dist = root and (root.Position - c.center).Magnitude or 999
			if dist > 150 then
				continue
			end
			local asleep = now < c.sleepUntil
			local target = asleep and 0 or math.clamp(1 - (dist - 8) / (NEAR - 8), 0, 1)
			c.excite += (target - c.excite) * math.min(1, dt * 4)
			local e = c.excite
			local offset
			if os.clock() < c.popUntil then
				-- открытие: сжатие и высокий прыжок с поворотом
				local k = 1 - (c.popUntil - os.clock()) / 0.9
				local h = math.sin(k * math.pi) * 3.5
				offset = CFrame.new(0, h, 0) * CFrame.Angles(0, k * math.pi * 2, 0)
			elseif asleep then
				offset = CFrame.new(0, math.sin(t * 0.8 + c.phase) * 0.08, 0)
			else
				-- ожидание: лёгкое покачивание; радость: прыжки и вертушка
				local bob = math.sin(t * 1.6 + c.phase) * 0.18
				local hop = math.abs(math.sin(t * (5 + e * 4))) * e * 1.4
				local wiggle = math.sin(t * 11) * e * 0.18
				local tilt = math.sin(t * 7) * e * 0.08
				offset = CFrame.new(0, bob + hop, 0) * CFrame.Angles(tilt, wiggle, -tilt)
			end
			c.model:PivotTo(c.base * offset)
			if not asleep and os.clock() > c.popUntil then
				c.light.Brightness = 0.8 + e * 2.2 + math.sin(t * 3) * 0.2
				c.light.Range = 16 + e * 8
			end
			c.sparks.Rate = asleep and 0 or 2 + e * 25
			c.gui.Enabled = asleep
			if asleep then
				local left = c.sleepUntil - now
				c.timer.Text = string.format("💤 %d:%02d", left // 60, left % 60)
			end
		end
	end
end)
