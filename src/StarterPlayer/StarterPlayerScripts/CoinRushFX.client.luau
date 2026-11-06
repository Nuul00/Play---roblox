-- Красота данжа Coin Rush (только клиент, на логику не влияет):
--  • монеты забега — 3D-монеты Tripo (ReplicatedStorage.TripoProps.RushCoin), крутятся и покачиваются;
--    серверный диск прячется (LocalTransparencyModifier);
--  • сбор — золотая вспышка, кольцо и звон с тоном, растущим при быстрой серии;
--  • свет сокровищницы: тёплая цветокоррекция и bloom, пока идёт забег;
--  • смена комнаты — затемнение экрана; удар лазера — тряска камеры;
--  • хранилище открылось — кинематограф: камера на дверь, тряска, фонтан монет и вспышка.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("CoinRushEvent")
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local GOLD = Color3.fromRGB(255, 210, 70)

local props
-- геометрия монеты Tripo (герб, рант) + блестящее золото: текстура Tripo в свете сокровищницы
-- выглядела плоским жёлтым пятном, а металл даёт объём и блики
local function goldify(m: Instance)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("SurfaceAppearance") then
			d.Parent = nil
		elseif d:IsA("BasePart") then
			d.Material = Enum.Material.Metal
			d.Color = Color3.fromRGB(245, 185, 40)
			d.Reflectance = 0.18
		end
	end
end
local function coinTemplate(): Model?
	props = props or ReplicatedStorage:FindFirstChild("TripoProps") or ReplicatedStorage:WaitForChild("TripoProps", 5)
	local t = props and props:FindFirstChild("RushCoin")
	return t and t:IsA("Model") and t or nil
end

-- ===== свет =====
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "CoinRushTint"
cc.Brightness = 0
cc.Contrast = 0.15
cc.Saturation = 0.12
cc.TintColor = Color3.fromRGB(255, 244, 225)
local bloom = Instance.new("BloomEffect")
bloom.Name = "CoinRushBloom"
bloom.Intensity = 0.35
bloom.Size = 24
bloom.Threshold = 0.96
local function setMood(on: boolean)
	cc.Parent = on and Lighting or nil
	bloom.Parent = on and Lighting or nil
end

-- ===== экран =====
local gui = Instance.new("ScreenGui")
gui.Name = "CoinRushFX"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 29
gui.Parent = player:WaitForChild("PlayerGui")
local fade = Instance.new("Frame")
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.Parent = gui
local flash = fade:Clone()
flash.BackgroundColor3 = Color3.fromRGB(255, 235, 170)
flash.Parent = gui

local shakeUntil, shakeAmp = 0, 0
local function shake(sec, amp)
	shakeUntil = math.max(shakeUntil, os.clock() + sec)
	shakeAmp = math.max(amp, os.clock() < shakeUntil and shakeAmp or 0)
end
RunService:BindToRenderStep("CoinRushShake", Enum.RenderPriority.Camera.Value + 1, function()
	local now = os.clock()
	if now < shakeUntil then
		local cam = workspace.CurrentCamera
		local k = (shakeUntil - now)
		local a = shakeAmp * math.min(1, k * 2)
		cam.CFrame = cam.CFrame * CFrame.Angles(math.rad((math.random() - 0.5) * a), math.rad((math.random() - 0.5) * a), 0)
	end
end)

-- ===== звук сбора =====
local ding = Instance.new("Sound")
ding.SoundId = "rbxasset://sounds/electronicpingshort.wav"
ding.Volume = 0.22
ding.Parent = SoundService
local chain, lastDing = 0, 0
local function playDing()
	local now = os.clock()
	if now - lastDing > 0.9 then
		chain = 0
	end
	if now - lastDing < 0.045 then
		return
	end
	chain += 1
	lastDing = now
	ding.PlaybackSpeed = 1 + math.min(chain, 24) * 0.035
	SoundService:PlayLocalSound(ding)
end

-- ===== монеты =====
local fxFolder = Instance.new("Folder")
fxFolder.Name = "CoinRushClientFX"
fxFolder.Parent = workspace
local visuals = {} -- [server part] = { model, base, phase, big }
local function burst(pos: Vector3, big: boolean)
	local a = Instance.new("Part")
	a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
	a.Size = Vector3.new(0.2, 0.2, 0.2)
	a.Position = pos
	a.Parent = fxFolder
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 250, 210))
	e.LightEmission = 1
	e.Rate = 0
	e.Speed = NumberRange.new(6, 14)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.Size = NumberSequence.new(big and 0.9 or 0.6, 0)
	e.Drag = 4
	e.Parent = a
	e:Emit(big and 26 or 12)
	local ring = Instance.new("Part")
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = GOLD
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.1, 1, 1)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = fxFolder
	TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = Vector3.new(0.1, big and 9 or 6, big and 9 or 6), Transparency = 1 }):Play()
	task.delay(0.8, function()
		a:Destroy()
		ring:Destroy()
	end)
end
local function dress(part: BasePart)
	if visuals[part] then
		return
	end
	local big = part.Name == "RushBar"
	local info = { base = part.CFrame, phase = math.random() * 6, big = big, expireAt = part:GetAttribute("ExpireAt") }
	local t = coinTemplate()
	if t and not big then
		local m = t:Clone()
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
			end
		end
		local _, ext = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * 2.8 / math.max(ext.X, ext.Y, ext.Z, 0.01))
		goldify(m)
		m.Parent = fxFolder
		info.model = m
		part.Transparency = 1 -- только у себя (сервер это свойство больше не меняет)
	end
	visuals[part] = info
	part.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			local v = visuals[part]
			visuals[part] = nil
			if v then
				if v.model then
					v.model:Destroy()
				end
				local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if part:GetAttribute("Expired") then
					-- не успел: монета тает серым дымком
					local a = Instance.new("Part")
					a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
					a.Size = Vector3.new(0.2, 0.2, 0.2)
					a.Position = v.base.Position
					a.Parent = fxFolder
					local e = Instance.new("ParticleEmitter")
					e.Texture = "rbxasset://textures/particles/smoke_main.dds"
					e.Color = ColorSequence.new(Color3.fromRGB(200, 190, 170))
					e.Transparency = NumberSequence.new(0.4, 1)
					e.Rate = 0
					e.Speed = NumberRange.new(1, 3)
					e.SpreadAngle = Vector2.new(180, 180)
					e.Lifetime = NumberRange.new(0.4, 0.7)
					e.Size = NumberSequence.new(1.2, 2.4)
					e.Parent = a
					e:Emit(6)
					task.delay(1, function()
						a:Destroy()
					end)
				elseif me and (me.Position - v.base.Position).Magnitude < 40 then
					burst(v.base.Position, v.big)
					playDing()
				end
			end
		end
	end)
end
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local st = workspace:GetServerTimeNow()
	for part, v in pairs(visuals) do
		if v.model then
			local cf = CFrame.new(v.base.Position + Vector3.new(0, 0.9 + math.sin(t * 2.5 + v.phase) * 0.35, 0)) * CFrame.Angles(0, t * 2.2 + v.phase, 0)
			v.model:PivotTo(cf)
			-- скоро исчезнет: мигает всё чаще
			if v.expireAt then
				local left = v.expireAt - st
				local hide = left < 1.4 and math.floor(t * (left < 0.6 and 14 or 7)) % 2 == 0
				if hide ~= v.hidden then
					v.hidden = hide
					for _, d in ipairs(v.model:GetDescendants()) do
						if d:IsA("BasePart") then
							d.LocalTransparencyModifier = hide and 0.85 or 0
						end
					end
				end
			end
		end
	end
end)

local myRun
local function watchRun(m: Instance)
	myRun = m
	setMood(true)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("RushCoin") then
			dress(d)
		end
	end
	m.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			task.defer(function()
				if d:GetAttribute("RushCoin") then
					dress(d)
				end
			end)
		end
	end)
	m.AncestryChanged:Connect(function(_, parent)
		if parent == nil and myRun == m then
			myRun = nil
			setMood(false)
			for part, v in pairs(visuals) do
				if v.model then
					v.model:Destroy()
				end
				visuals[part] = nil
			end
		end
	end)
end
local runName = "CoinRush_" .. player.UserId
workspace.ChildAdded:Connect(function(c)
	if c.Name == runName then
		watchRun(c)
	end
end)
if workspace:FindFirstChild(runName) then
	watchRun(workspace[runName])
end

-- ===== события забега =====
local function blackFade()
	fade.BackgroundTransparency = 0
	TweenService:Create(fade, TweenInfo.new(0.55, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
end
local function vaultCinematic()
	local door = myRun and myRun:FindFirstChild("VaultDoor", true)
	if not door then
		return
	end
	local cam = workspace.CurrentCamera
	local cf, size = door:GetBoundingBox()
	local front = cf.Position - cf.LookVector * 0 -- центр двери
	local roomCenter = myRun:FindFirstChild("VaultZone", true)
	local from = roomCenter and roomCenter.Position + Vector3.new(0, 9, -14) or front + Vector3.new(0, 6, -30)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(from, front)
	TweenService:Create(cam, TweenInfo.new(3.6, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(from + (front - from).Unit * 8 + Vector3.new(0, -2, 0), front) }):Play()
	shake(0.6, 1.2)
	task.delay(0.6, function()
		shake(1.4, 2.2)
		flash.BackgroundTransparency = 0.35
		TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		-- фонтан монет из сокровищницы
		local a = Instance.new("Part")
		a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
		a.Size = Vector3.new(10, 10, 1)
		a.CFrame = CFrame.lookAt(front, from)
		a.Parent = fxFolder
		local e = Instance.new("ParticleEmitter")
		e.Texture = SPARK
		e.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 245, 200))
		e.LightEmission = 1
		e.Rate = 160
		e.Speed = NumberRange.new(18, 34)
		e.SpreadAngle = Vector2.new(35, 35)
		e.Acceleration = Vector3.new(0, -40, 0)
		e.Lifetime = NumberRange.new(1, 1.8)
		e.Size = NumberSequence.new(1.1, 0.2)
		e.EmissionDirection = Enum.NormalId.Front
		e.Parent = a
		local coin = coinTemplate()
		if coin then
			for k = 1, 18 do
				local m = coin:Clone()
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("BasePart") then
						d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
					end
				end
				local _, ext = m:GetBoundingBox()
				m:ScaleTo(m:GetScale() * 2.4 / math.max(ext.X, ext.Y, ext.Z, 0.01))
				goldify(m)
				m.Parent = fxFolder
				local vel = (from - front).Unit * (16 + math.random() * 14) + Vector3.new((math.random() - 0.5) * 20, 18 + math.random() * 14, (math.random() - 0.5) * 6)
				local pos = front
				local spin = math.random() * 10
				task.spawn(function()
					local t0 = os.clock()
					while os.clock() - t0 < 2 and m.Parent do
						local dt = RunService.RenderStepped:Wait()
						vel += Vector3.new(0, -50, 0) * dt
						pos += vel * dt
						spin += dt * 9
						m:PivotTo(CFrame.new(pos) * CFrame.Angles(spin, spin * 0.7, 0))
					end
					m:Destroy()
				end)
				task.wait(0.05)
			end
		end
		task.delay(1.6, function()
			e.Enabled = false
		end)
		task.delay(3.5, function()
			a:Destroy()
		end)
	end)
	task.delay(3.9, function()
		cam.CameraType = Enum.CameraType.Custom
	end)
end
remote.OnClientEvent:Connect(function(kind, d)
	if kind == "room" or kind == "vault" then
		blackFade()
	elseif kind == "hit" then
		shake(0.35, 3)
	elseif kind == "vaultResult" and d.Open then
		vaultCinematic()
	elseif kind == "result" then
		blackFade()
	end
end)
