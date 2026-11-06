-- Открытие Royal Egg прямо в мире: яйцо выпрыгивает с пьедестала (или падает с неба, если игрок
-- далеко), по дуге летит к игроку и приземляется на землю перед ним, качается всё сильнее,
-- светится и трескается лучами света, взрывается искрами — и на земле появляется питомец
-- с колонной света его редкости и табличкой. При ×3 — три яйца веером.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local RoyalEggModel = require(ReplicatedStorage:WaitForChild("RoyalEggModel"))
local UISounds = require(ReplicatedStorage:WaitForChild("UISounds"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer

local RARITY = {
	Common = Color3.fromRGB(220, 225, 235),
	Uncommon = Color3.fromRGB(110, 230, 120),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 190, 50),
	Secret = Color3.fromRGB(255, 90, 170),
}
local RANK = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Secret = 6 }
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local function anchorAll(m: Instance)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
		elseif d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
end
local function ground(pos: Vector3, ignore): Vector3
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -120, 0), rp)
	return hit and hit.Position or pos
end
local function emitter(parent, color, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Enabled = false
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local busy = false
local function playOne(result, startPos: Vector3, landPos: Vector3, delayStart: number, folder: Folder)
	local def = Config.Pets[result.Pet]
	if not def then
		return
	end
	local color = RARITY[def.Rarity] or RARITY.Common
	local rank = RANK[def.Rarity] or 1
	task.wait(delayStart)
	local egg = RoyalEggModel.Build()
	anchorAll(egg)
	local _, s = egg:GetBoundingBox()
	egg:ScaleTo(egg:GetScale() * 4.2 / math.max(s.Y, 0.1))
	local _, size = egg:GetBoundingBox()
	egg.Parent = folder
	local function put(pos: Vector3, rot: CFrame)
		local cf, sz = egg:GetBoundingBox()
		local off = egg:GetPivot():ToObjectSpace(cf) -- центр габарита относительно опоры
		local target = CFrame.new(pos + Vector3.new(0, sz.Y / 2, 0)) * rot
		egg:PivotTo(target * off:Inverse())
	end
	-- 1) прыжок по дуге (0.9 с) с кувырком
	local t0 = os.clock()
	local flight = 0.9
	while true do
		local k = math.min((os.clock() - t0) / flight, 1)
		local p = startPos:Lerp(landPos, k) + Vector3.new(0, math.sin(k * math.pi) * 14, 0)
		put(p, CFrame.Angles(k * math.pi * 2, k * math.pi, 0))
		if k >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
	-- приземление: пыль и «сплющивание»
	local dust = Instance.new("Part")
	dust.Anchored, dust.CanCollide, dust.CanQuery, dust.CanTouch, dust.Transparency = true, false, false, false, 1
	dust.Size = Vector3.new(1, 1, 1)
	dust.Position = landPos + Vector3.new(0, 0.3, 0)
	dust.Parent = folder
	local puff = emitter(dust, Color3.fromRGB(255, 240, 210), { Rate = 0, Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(6, 10), SpreadAngle = Vector2.new(80, 10), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }), Acceleration = Vector3.new(0, -8, 0) })
	puff:Emit(30)
	UISounds.Play("crack")
	-- кольцо-волна по земле
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 215, 110)
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(landPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(0.6), { Size = Vector3.new(0.2, 16, 16), Transparency = 1 }):Play()

	-- 2) качание с нарастанием (чем реже питомец, тем дольше), свет усиливается
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 4
	glow.Brightness = 0
	glow.Parent = dust
	local aura = emitter(dust, color, { Rate = 0, Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }) })
	aura.Enabled = true
	local wobble = 1.6 + rank * 0.25
	t0 = os.clock()
	local rays = {}
	while os.clock() - t0 < wobble do
		local k = (os.clock() - t0) / wobble
		local amp = math.rad(6 + 22 * k)
		local w = math.sin((os.clock() - t0) * (10 + 14 * k)) * amp
		local hop = (k > 0.6 and math.abs(math.sin((os.clock() - t0) * 9)) * 0.6 * k) or 0
		put(landPos + Vector3.new(0, hop, 0), CFrame.Angles(0, 0, w))
		glow.Range = 4 + 18 * k
		glow.Brightness = 3 * k
		aura.Rate = 10 + 60 * k
		-- лучи из «трещин» после половины
		if k > 0.55 and #rays < 5 then
			local r = Instance.new("Part")
			r.Anchored, r.CanCollide, r.CanQuery, r.CanTouch, r.CastShadow = true, false, false, false, false
			r.Material = Enum.Material.Neon
			r.Color = color:Lerp(Color3.new(1, 1, 1), 0.25)
			r.Transparency = 0.35
			r.Size = Vector3.new(0.15, 0.15, 1)
			r.Parent = folder
			table.insert(rays, { part = r, dir = CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, 0).LookVector })
		end
		for _, r in ipairs(rays) do
			local len = 1.5 + 4.5 * k
			local c = landPos + Vector3.new(0, size.Y * 0.5, 0)
			r.part.Size = Vector3.new(0.18, 0.18, len)
			r.part.CFrame = CFrame.lookAt(c + r.dir * len / 2, c + r.dir * len)
		end
		RunService.RenderStepped:Wait()
	end
	-- 3) взрыв: вспышка, яйцо исчезает, искры, конфетти
	local burst = emitter(dust, color, { Rate = 0, Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(14, 26), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -14, 0), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
	burst:Emit(80 + rank * 25)
	local conf = Instance.new("ParticleEmitter")
	conf.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	conf.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 90)), ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 200, 255)) })
	conf.Rate = 0
	conf.Lifetime = NumberRange.new(1.5, 2.5)
	conf.Speed = NumberRange.new(10, 18)
	conf.SpreadAngle = Vector2.new(40, 40)
	conf.Acceleration = Vector3.new(0, -12, 0)
	conf.RotSpeed = NumberRange.new(-300, 300)
	conf.Size = NumberSequence.new(0.5)
	conf.EmissionDirection = Enum.NormalId.Top
	conf.Parent = dust
	conf:Emit(60)
	for _, r in ipairs(rays) do
		TweenService:Create(r.part, TweenInfo.new(0.3), { Transparency = 1 }):Play()
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.35
	cc.TintColor = color:Lerp(Color3.new(1, 1, 1), 0.6)
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(0.6), { Brightness = 0, TintColor = Color3.new(1, 1, 1) }):Play()
	task.delay(0.7, function()
		cc:Destroy()
	end)
	egg:Destroy()
	aura.Enabled = false
	UISounds.Play(rank >= 5 and "rare" or "hatch")

	-- 4) питомец на земле: вырастает с прокрутом, колонна света редкости, табличка
	local ok, pet = pcall(PetVisuals.Build, result.Pet)
	if not ok or not pet then
		return
	end
	anchorAll(pet)
	local _, ps = pet:GetBoundingBox()
	local scale0 = pet:GetScale()
	local want = scale0 * (3.2 + rank * 0.35) / math.max(ps.Y, ps.X, 0.1)
	pet.Parent = folder
	local beam = Instance.new("Part")
	beam.Shape = Enum.PartType.Cylinder
	beam.Anchored, beam.CanCollide, beam.CanQuery, beam.CanTouch, beam.CastShadow = true, false, false, false, false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.8
	beam.Size = Vector3.new(40, 0.3, 0.3)
	beam.CFrame = CFrame.new(landPos + Vector3.new(0, 20, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Parent = folder
	TweenService:Create(beam, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Size = Vector3.new(40, 1.5 + rank * 0.5, 1.5 + rank * 0.5) }):Play()
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 90)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 6 + rank * 0.4, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = dust
	bb.Parent = folder
	local function txt(text, y, h, c)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(0, y)
		l.Size = UDim2.new(1, 0, 0, h)
		l.Text = text
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = c
		l.Parent = bb
		local s = Instance.new("UIStroke")
		s.Thickness = 2.5
		s.Color = Color3.fromRGB(30, 15, 45)
		s.Parent = l
	end
	txt("👑 ROYAL " .. def.Rarity:upper(), 0, 30, color)
	txt(def.Name, 30, 34, Color3.new(1, 1, 1))
	txt("×" .. NumberFormat.Short(def.Multiplier) .. " coins", 64, 24, Color3.fromRGB(255, 225, 140))
	t0 = os.clock()
	local show = 4.2 + rank * 0.4
	while os.clock() - t0 < show do
		local e = os.clock() - t0
		local grow = math.min(e / 0.5, 1)
		local k = 1 - (1 - grow) ^ 3
		pcall(function()
			pet:ScaleTo(math.max(want * k, scale0 * 0.05))
		end)
		local cf, sz = pet:GetBoundingBox()
		local off = pet:GetPivot():ToObjectSpace(cf)
		local look = CFrame.Angles(0, (1 - k) * math.pi * 4 + e * 0.8, 0)
		pet:PivotTo(CFrame.new(landPos + Vector3.new(0, sz.Y / 2 + math.abs(math.sin(e * 3)) * 0.4, 0)) * look * off:Inverse())
		beam.Transparency = 0.78 + 0.12 * math.sin(e * 6)
		RunService.RenderStepped:Wait()
	end
	-- исчезает: прыгает к игроку и тает
	TweenService:Create(beam, TweenInfo.new(0.4), { Transparency = 1, Size = Vector3.new(40, 0.2, 0.2) }):Play()
	bb:Destroy()
	for _, d in ipairs(pet:GetDescendants()) do
		if d:IsA("BasePart") then
			TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		end
	end
	task.wait(0.45)
end

ReplicatedStorage:WaitForChild("GameHatched").OnClientEvent:Connect(function(batch, sourceEgg)
	if sourceEgg ~= "royal" or type(batch) ~= "table" or busy then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	busy = true
	player:SetAttribute("UIScreen", "")
	local folder = Instance.new("Folder")
	folder.Name = "RoyalHatchFX"
	folder.Parent = workspace
	-- откуда прыгает яйцо: с пьедестала, если он рядом, иначе — с неба над игроком
	local info = player.PlayerGui:FindFirstChild("RoyalEggStandInfo")
	local standPos, dist
	if info then
		standPos, dist = info:Invoke("info")
	end
	local fromStand = standPos and dist and dist < 90
	if fromStand then
		info:Invoke("hide")
	end
	local cam = workspace.CurrentCamera
	local look = (cam and cam.CFrame.LookVector or root.CFrame.LookVector) * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, -1)
	local right = look:Cross(Vector3.new(0, 1, 0))
	-- камера плавно смотрит на место приземления (сбоку-сверху), в конце возвращается
	local focus = root.Position + look * 9
	local prevType = cam and cam.CameraType
	if cam then
		cam.CameraType = Enum.CameraType.Scriptable
		local goal = CFrame.lookAt(root.Position - look * 7 + right * 3 + Vector3.new(0, 8, 0), focus + Vector3.new(0, 2, 0))
		TweenService:Create(cam, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { CFrame = goal }):Play()
	end
	local done = 0
	for i, r in ipairs(batch) do
		local spread = (#batch > 1) and (i - (#batch + 1) / 2) * 6 or 0
		local land = ground(root.Position + look * 9 + right * spread, { char, folder })
		local start = fromStand and standPos or (land + Vector3.new(0, 40, 0))
		task.spawn(function()
			local ok, err = pcall(playOne, r, start, land, (i - 1) * 0.35, folder)
			if not ok then
				warn("[RoyalHatch] " .. tostring(err))
			end
			done += 1
		end)
	end
	local t0 = os.clock()
	while done < #batch and os.clock() - t0 < 20 do
		task.wait(0.2)
	end
	folder:Destroy()
	if cam then
		cam.CameraType = prevType or Enum.CameraType.Custom
	end
	if fromStand and info then
		info:Invoke("show")
	end
	busy = false
end)
