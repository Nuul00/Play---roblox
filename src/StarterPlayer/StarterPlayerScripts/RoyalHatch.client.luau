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
local Themes = require(script.Parent:WaitForChild("RoyalHatchThemes"))
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
	-- Сколько раз яйцо эволюционирует: Common/Uncommon — нет, Rare/Epic — 1 раз, Legendary/Secret — 2.
	-- Игрок видит эволюцию и понимает: будет что-то редкое (наша фишка).
	local stages = rank >= 5 and 3 or rank >= 3 and 2 or 1
	local function makeEgg(stage: number, height: number)
		local m = RoyalEggModel.Build(stage)
		anchorAll(m)
		local _, s0 = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * height / math.max(s0.Y, 0.1))
		m.Parent = folder
		return m
	end
	local egg = makeEgg(1, 4.2)
	local _, size = egg:GetBoundingBox()
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

	-- надпись над яйцом (стадии)
	local tagGui = Instance.new("BillboardGui")
	tagGui.Size = UDim2.fromOffset(240, 50)
	tagGui.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
	tagGui.AlwaysOnTop = true
	tagGui.LightInfluence = 0
	tagGui.Adornee = dust
	tagGui.Parent = folder
	local tagText = Instance.new("TextLabel")
	tagText.BackgroundTransparency = 1
	tagText.Size = UDim2.fromScale(1, 1)
	tagText.TextScaled = true
	tagText.Font = Enum.Font.FredokaOne
	tagText.Text = ""
	tagText.Parent = tagGui
	local tagStroke = Instance.new("UIStroke")
	tagStroke.Thickness = 3
	tagStroke.Color = Color3.fromRGB(30, 10, 50)
	tagStroke.Parent = tagText
	local tagScale = Instance.new("UIScale", tagText)
	local function say(text: string, c: Color3)
		tagText.Text = text
		tagText.TextColor3 = c
		tagScale.Scale = 0.3
		TweenService:Create(tagScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	local function shake(sec: number, amp: number, freq: number)
		local s0 = os.clock()
		while os.clock() - s0 < sec do
			local e = os.clock() - s0
			put(landPos, CFrame.Angles(0, e * 2, math.sin(e * freq) * math.rad(amp)))
			RunService.RenderStepped:Wait()
		end
	end
	-- шар света вокруг яйца в момент превращения
	local function orb(c: Color3)
		local b = Instance.new("Part")
		b.Shape = Enum.PartType.Ball
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, false, false, false, false
		b.Material = Enum.Material.Neon
		b.Color = c
		b.Transparency = 0.1
		b.Size = Vector3.new(1, 1, 1)
		b.Position = landPos + Vector3.new(0, size.Y / 2, 0)
		b.Parent = folder
		TweenService:Create(b, TweenInfo.new(0.55, Enum.EasingStyle.Quad), { Size = Vector3.new(9, 9, 9), Transparency = 1 }):Play()
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Brightness = 0.25
		cc.TintColor = c:Lerp(Color3.new(1, 1, 1), 0.5)
		cc.Parent = Lighting
		TweenService:Create(cc, TweenInfo.new(0.5), { Brightness = 0, TintColor = Color3.new(1, 1, 1) }):Play()
		task.delay(0.55, function()
			cc:Destroy()
		end)
	end
	-- смена модели: старое яйцо крутится и сжимается, новое вырастает с отскоком
	local function evolve(stage: number, height: number, c: Color3)
		local s0 = os.clock()
		local scale0 = egg:GetScale()
		while os.clock() - s0 < 0.35 do
			local k = (os.clock() - s0) / 0.35
			pcall(function()
				egg:ScaleTo(math.max(scale0 * (1 - k * 0.9), 0.01))
			end)
			put(landPos, CFrame.Angles(0, k * math.pi * 3, 0))
			RunService.RenderStepped:Wait()
		end
		orb(c)
		puff:Emit(40)
		UISounds.Play("reward")
		egg:Destroy()
		egg = makeEgg(stage, height)
		local _, sz = egg:GetBoundingBox()
		size = sz
		local target = egg:GetScale()
		s0 = os.clock()
		while os.clock() - s0 < 0.45 do
			local k = (os.clock() - s0) / 0.45
			local over = 1 + math.sin(k * math.pi) * 0.25 -- перелёт и возврат
			pcall(function()
				egg:ScaleTo(math.max(target * k * over, 0.01))
			end)
			put(landPos, CFrame.Angles(0, (1 - k) * math.pi * 2, 0))
			RunService.RenderStepped:Wait()
		end
		pcall(function()
			egg:ScaleTo(target)
		end)
	end
	local skyShaft
	if stages >= 2 then
		say("✨ EVOLVING...", Color3.fromRGB(150, 230, 255))
		shake(1.1, 14, 22)
		evolve(2, 4.8, Color3.fromRGB(120, 220, 255))
		say("💎 EVOLVED!", Color3.fromRGB(120, 220, 255))
		shake(0.9, 8, 16)
	end
	if stages >= 3 then
		say("✨ EVOLVING AGAIN...", Color3.fromRGB(255, 220, 120))
		shake(1.2, 20, 28)
		-- из земли поднимается королевский пьедестал, яйцо взлетает на него
		local ped
		local f = ReplicatedStorage:FindFirstChild("TripoEggs")
		local pt = f and f:FindFirstChild("RoyalPedestal")
		if pt then
			ped = pt:Clone()
			anchorAll(ped)
			local _, ps0 = ped:GetBoundingBox()
			ped:ScaleTo(ped:GetScale() * 6 / math.max(ps0.X, ps0.Z, 0.1))
			ped.Parent = folder
			local pcf, psz = ped:GetBoundingBox()
			local off = ped:GetPivot():ToObjectSpace(pcf)
			local s0 = os.clock()
			while os.clock() - s0 < 0.6 do
				local k = (os.clock() - s0) / 0.6
				ped:PivotTo(CFrame.new(landPos + Vector3.new(0, psz.Y / 2 - psz.Y * (1 - k), 0)) * off:Inverse())
				put(landPos + Vector3.new(0, psz.Y * k, 0), CFrame.Angles(0, k * 4, 0))
				RunService.RenderStepped:Wait()
			end
			landPos = landPos + Vector3.new(0, psz.Y * 0.95, 0)
			dust.Position = landPos + Vector3.new(0, 0.3, 0)
		end
		evolve(3, 5.6, Color3.fromRGB(255, 225, 130))
		say("👑 DIVINE EGG!", Color3.fromRGB(255, 215, 90))
		-- мягкий луч света с неба на яйцо
		skyShaft = Themes.LightShaft(folder, landPos, 70, Color3.fromRGB(255, 236, 170), 0.8, { power = 0.55, bottom = size.Y * 1.1 })
		task.wait(0.5)
		shake(0.8, 6, 12)
	end

	-- 2) качание с нарастанием (чем реже питомец, тем дольше), свет усиливается
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 4
	glow.Brightness = 0
	glow.Parent = dust
	local aura = emitter(dust, color, { Rate = 0, Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }) })
	aura.Enabled = true
	local wobble = (stages > 1 and 1.2 or 1.6) + rank * 0.2
	t0 = os.clock()
	local rays = {}
	local rayHub, rayCore
	while os.clock() - t0 < wobble do
		local k = (os.clock() - t0) / wobble
		local amp = math.rad(6 + 22 * k)
		local w = math.sin((os.clock() - t0) * (10 + 14 * k)) * amp
		local hop = (k > 0.6 and math.abs(math.sin((os.clock() - t0) * 9)) * 0.6 * k) or 0
		put(landPos + Vector3.new(0, hop, 0), CFrame.Angles(0, 0, w))
		glow.Range = 4 + 18 * k
		glow.Brightness = 3 * k
		aura.Rate = 10 + 60 * k
		-- мягкие лучи света из «трещин» после половины
		if k > 0.55 and #rays < 6 then
			if not rayHub then
				rayHub = Instance.new("Part")
				rayHub.Anchored, rayHub.CanCollide, rayHub.CanQuery, rayHub.CanTouch, rayHub.Transparency = true, false, false, false, 1
				rayHub.Size = Vector3.new(0.2, 0.2, 0.2)
				rayHub.CFrame = CFrame.new(landPos + Vector3.new(0, size.Y * 0.5, 0))
				rayHub.Parent = folder
				rayCore = Instance.new("Attachment")
				rayCore.Parent = rayHub
			end
			local tip = Instance.new("Attachment")
			tip.Parent = rayHub
			local bm = Instance.new("Beam")
			bm.Attachment0, bm.Attachment1 = rayCore, tip
			bm.FaceCamera = true
			bm.LightEmission, bm.LightInfluence = 1, 0
			bm.Texture = "rbxasset://textures/particles/smoke_main.dds"
			bm.TextureMode = Enum.TextureMode.Stretch
			bm.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.6))
			bm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.6, 0.45), NumberSequenceKeypoint.new(1, 1) })
			bm.Parent = rayHub
			table.insert(rays, { part = bm, tip = tip, dir = CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, 0).LookVector })
		end
		for _, r in ipairs(rays) do
			local len = 2 + 6 * k
			r.tip.Position = r.dir * len
			r.part.Width0 = 0.5 + 0.9 * k
			r.part.Width1 = 1.6 + 2.6 * k
		end
		RunService.RenderStepped:Wait()
	end
	-- 3) финал под конкретного питомца (кристаллы, огонь, космос...) — RoyalHatchThemes
	if rayHub then
		rayHub:Destroy()
	end
	local theme = Themes.ByTier[def.RoyalTier or 1] or "royal"
	local ctx = { folder = folder, ground = landPos, center = landPos + Vector3.new(0, size.Y / 2, 0), egg = egg, color = color, rank = rank }
	Themes.Climax(theme, ctx)
	if egg.Parent then
		egg:Destroy()
	end
	tagGui:Destroy()
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
	if skyShaft then
		skyShaft.fade(0.8)
	end
	-- колонна света редкости: мягкий луч, вырастает из земли вверх
	local pillar = Themes.LightShaft(folder, landPos, 45, color, 0.4 + rank * 0.1, { rise = true, power = 0.75, bottom = 3 + rank * 0.4 })
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
	local auraUpdate = Themes.Aura(theme, ctx)
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
		pillar.update(e)
		if auraUpdate then
			pcall(auraUpdate, e, landPos + Vector3.new(0, sz.Y, 0))
		end
		RunService.RenderStepped:Wait()
	end
	-- исчезает: прыгает к игроку и тает
	pillar.fade(0.5)
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
		-- сбоку от игрока, чтобы персонаж не заслонял яйцо
		local goal = CFrame.lookAt(root.Position - look * 3 + right * 9 + Vector3.new(0, 7, 0), focus + Vector3.new(0, 2.5, 0))
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
