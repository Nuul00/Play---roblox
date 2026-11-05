-- Табло над каждым яйцом (оба мира): название, цена и питомцы, которых можно выбить, с шансами.
-- Плюс оживление яиц: парят, крутятся, вокруг летают огоньки, голо-кольцо вращается.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
-- Модели питомцев из Tripo (ReplicatedStorage.TripoPets) приходят на клиент не сразу: ждём их,
-- иначе на табло яиц остаются старые процедурные питомцы.
do
	local tripo = ReplicatedStorage:WaitForChild("TripoPets", 10)
	local t0 = os.clock()
	while tripo and #tripo:GetChildren() < 150 and os.clock() - t0 < 20 do
		task.wait(0.25)
	end
end
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity")

local rarityColors = {
	Common = Color3.fromRGB(182, 203, 190),
	Uncommon = Color3.fromRGB(128, 218, 147),
	Rare = Color3.fromRGB(110, 179, 255),
	Epic = Color3.fromRGB(198, 135, 255),
	Legendary = Color3.fromRGB(255, 206, 101),
	Mythic = Color3.fromRGB(255, 126, 191),
	Secret = Color3.fromRGB(255, 255, 255),
}

local function fmt(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function stroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or Color3.fromRGB(20, 20, 30)
	s.ApplyStrokeMode = parent:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end
local function label(parent, text, pos, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextScaled = true
	l.Font = font or Enum.Font.FredokaOne
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Parent = parent
	stroke(l, 2)
	return l
end

local boards = {}
local function buildBoard(id, stand)
	local egg = Config.Eggs[id]
	local neon=egg.World=="neon"
	-- Яйца Sky Isles — облачный пастельный стиль: светлая панель с градиентом, белая обводка.
	local sky = egg.World == "sky"
	local anchor = stand:FindFirstChild("SignAnchor")
	if not anchor then
		local cf, size = stand.EggDisplay:GetBoundingBox()
		anchor = Instance.new("Attachment")
		anchor.Name = "SignAnchorLocal"
		anchor.Parent = stand:FindFirstChild("Interact") or stand.EggDisplay.PrimaryPart
		anchor.WorldPosition = cf.Position + Vector3.new(0, size.Y / 2 + 4.6, 0)
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EggBoard"
	gui:SetAttribute("EggId", id) -- по нему PityHUD ставит плашку гарантии над этим табло
	-- Табло меньше прежнего и видно только рядом с яйцом (см. цикл внизу), зато поверх всего и чётко.
	gui.Size = UDim2.fromScale(neon and 11 or 10.5, neon and 12 or (#egg.Pool > 6 and 11 or 6))
	gui.MaxDistance = 150
	gui.AlwaysOnTop = true
	gui.Enabled = false
	-- Высокое табло (9 питомцев) поднимаем, чтобы яйцо его не закрывало.
	gui.StudsOffsetWorldSpace = Vector3.new(0, neon and 3 or (#egg.Pool > 6 and 2 or 0), 0)
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Adornee = anchor
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	local pop = Instance.new("UIScale")
	pop.Scale = 0.6
	pop.Parent = panel
	panel.BackgroundColor3 = sky and Color3.new(1, 1, 1) or Color3.fromRGB(22, 24, 40)
	panel.BackgroundTransparency = sky and 0.05 or 0.15
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0.08, 0)
	if sky then
		local bg = Instance.new("UIGradient")
		bg.Color = ColorSequence.new(Color3.fromRGB(255, 226, 244), Color3.fromRGB(205, 230, 255))
		bg.Rotation = 90
		bg.Parent = panel
		stroke(panel, 4, Color3.new(1, 1, 1))
	else
		stroke(panel, 3, egg.Color)
	end

	-- Шапка: название и цена.
	local head = Instance.new("Frame")
	head.Size = UDim2.fromScale(1, #egg.Pool > 6 and 0.15 or 0.24)
	head.BackgroundColor3 = egg.Color
	head.Parent = panel
	Instance.new("UICorner", head).CornerRadius = UDim.new(0.3, 0)
	local grad = Instance.new("UIGradient")
	grad.Color = sky and ColorSequence.new(egg.Color:Lerp(Color3.new(1, 1, 1), 0.55), egg.Color:Lerp(Color3.new(1, 1, 1), 0.15)) or ColorSequence.new(egg.Color:Lerp(Color3.new(1, 1, 1), 0.25), egg.Color:Lerp(Color3.new(0, 0, 0), 0.25))
	grad.Rotation = 90
	grad.Parent = head
	if sky then
		stroke(head, 3, Color3.new(1, 1, 1))
	end
	label(head, string.upper(egg.Name), neon and UDim2.fromScale(0.04,0.02) or UDim2.fromScale(0.04,0.08), neon and UDim2.fromScale(0.92,0.43) or UDim2.fromScale(0.56,0.84))
	local price = label(head, "💰 " .. fmt(egg.Cost), neon and UDim2.fromScale(0.15,0.5) or UDim2.fromScale(0.6,0.12), neon and UDim2.fromScale(0.7,0.44) or UDim2.fromScale(0.37,0.76), Color3.fromRGB(255, 230, 90))
	price.TextXAlignment = neon and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right

	-- Питомцы: 6 ячеек в ряд, под каждой шанс выпадения.
	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	local many = #egg.Pool > 6
	grid.Position = UDim2.fromScale(0.025, many and 0.18 or 0.29)
	grid.Size = UDim2.fromScale(0.95, many and 0.75 or 0.62)
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = #egg.Pool>9 and UDim2.fromScale(0.188, 0.48) or many and UDim2.fromScale(0.32, 0.317) or UDim2.fromScale(0.155, 1)
	layout.CellPadding = UDim2.fromScale(0.014, 0.02)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	for i, entry in ipairs(egg.Pool) do
		local def = Config.Pets[entry.Pet]
		local color = rarityColors[def.Rarity] or Color3.new(1, 1, 1)
		local cell = Instance.new("Frame")
		cell.LayoutOrder = i
		cell.BackgroundColor3 = sky and Color3.fromRGB(252, 248, 255) or Color3.fromRGB(40, 44, 66)
		cell.Parent = grid
		Instance.new("UICorner", cell).CornerRadius = UDim.new(0.14, 0)
		stroke(cell, 2, color)
		local view = Instance.new("ViewportFrame")
		view.BackgroundTransparency = 1
		view.Size = UDim2.fromScale(1, many and 0.62 or 0.66)
		view.Ambient = Color3.fromRGB(200, 200, 215)
		view.LightColor = Color3.fromRGB(255, 248, 230)
		view.LightDirection = Vector3.new(-1, -1, -2)
		view.Parent = cell
		local cam = Instance.new("Camera")
		cam.FieldOfView = 38
		cam.CFrame = CFrame.lookAt(Vector3.new(4, 2.8, -6), Vector3.new(0, 0.2, 0))
		cam.Parent = view
		view.CurrentCamera = cam
		local scene = Instance.new("WorldModel")
		scene.Parent = view
		local ok, model = pcall(PetVisuals.Build, entry.Pet)
		if ok and model then
			model.Parent = scene
		end
		-- 3D-модель питомца могла ещё не дойти до клиента: дождёмся её и перерисуем ячейку.
		local tripoPets = ReplicatedStorage:FindFirstChild("TripoPets")
		if tripoPets and not tripoPets:FindFirstChild("Pet" .. entry.Pet) then
			task.spawn(function()
				if tripoPets:WaitForChild("Pet" .. entry.Pet, 120) and scene.Parent then
					task.wait(0.5)
					scene:ClearAllChildren()
					local ok2, m2 = pcall(PetVisuals.Build, entry.Pet)
					if ok2 and m2 then
						m2.Parent = scene
					end
				end
			end)
		end
		if many then
			-- 9 питомцев: шанс, имя и редкость под моделькой.
			local grad = Instance.new("UIGradient")
			grad.Color = sky and ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.55), Color3.fromRGB(240, 236, 255)) or ColorSequence.new(color:Lerp(Color3.fromRGB(40, 44, 66), 0.6), Color3.fromRGB(30, 32, 50))
			grad.Rotation = 90
			grad.Parent = cell
			label(cell, string.format("%g%%", entry.Chance), UDim2.fromScale(0.04, 0.6), UDim2.fromScale(0.92, 0.23), color)
			label(cell, def.Rarity:upper(), UDim2.fromScale(0.04, 0.83), UDim2.fromScale(0.92, 0.15), color, Enum.Font.GothamBlack)
		else
			label(cell, string.format("%g%%", entry.Chance), UDim2.fromScale(0.04, 0.64), UDim2.fromScale(0.92, 0.2), color)
			label(cell, def.Rarity, UDim2.fromScale(0.04, 0.83), UDim2.fromScale(0.92, 0.14), color, Enum.Font.GothamBold)
		end
	end
	label(panel, "Touch the egg · OPEN ×1 / ×3 / AUTO", UDim2.fromScale(0.1, many and 0.94 or 0.915), UDim2.fromScale(0.8, many and 0.05 or 0.07), sky and Color3.fromRGB(150, 110, 220) or Color3.fromRGB(200, 205, 225), sky and Enum.Font.FredokaOne or Enum.Font.GothamMedium)
	table.insert(boards, { gui = gui, anchor = anchor, pop = pop, shown = false })
end

-- Оживление яиц: парят и крутятся, «дышат» (лёгкое сжатие-растяжение), время от времени
-- вздрагивают, будто вот-вот вылупятся, а когда игрок рядом — радостно подпрыгивают.
-- Вокруг — огоньки с хвостами, мягкий свет и искры цвета яйца; у дорогого яйца мира
-- (3-е в каждом мире) ещё и фонтан золотых искр. При открытии яйцо подпрыгивает с вспышкой.
local eggs = {}
local fxFolder = Instance.new("Folder")
fxFolder.Name = "EggFX"
fxFolder.Parent = workspace

local function measure(entry, model: Model)
	entry.model = model
	entry.base = model:GetPivot()
	local _, size = model:GetBoundingBox()
	entry.height = size.Y
	entry.radius = math.max(size.X, size.Z) / 2
	entry.scale = model:GetScale()
	entry.applied = 1
end

local function setupEgg(id, stand)
	local display = stand:FindFirstChild("EggDisplay")
	if not display then
		return
	end
	local egg = Config.Eggs[id]
	local tier = (id - 1) % 3 + 1 -- 1..3 внутри мира
	local entry = {
		id = id,
		phase = id * 1.3,
		neon = egg.World == "neon",
		spin = id,
		holo = {},
		orbs = {},
		tier = tier,
		excite = 0,
		nextWobble = 2 + id * 0.7,
		wobbleAt = -10,
		popAt = -10,
	}
	measure(entry, display)
	-- Сервер (TripoDressing) меняет модель яйца на модель из Tripo: оживляем уже её.
	stand.ChildAdded:Connect(function(c)
		if c.Name == "EggDisplay" and c:IsA("Model") then
			task.defer(measure, entry, c)
		end
	end)
	local ped = stand:FindFirstChild("Pedestal")
	if ped then
		local center = ped:FindFirstChild("Base") and ped.Base.Position or entry.base.Position
		for _, p in ipairs(ped:GetChildren()) do
			if p.Name == "HoloRing" then
				table.insert(entry.holo, { part = p, base = p.CFrame, center = center })
			end
		end
	end
	local color = egg.Color
	-- в тёмном Неонграде свет белее, чтобы был виден рисунок яйца
	local light = color:Lerp(Color3.new(1, 1, 1), egg.World == "neon" and 0.75 or 0.35)

	-- Невидимый якорь в центре яйца: свет и искры.
	local anchor = Instance.new("Part")
	anchor.Name = "EggAura" .. id
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch, anchor.CastShadow = true, false, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(entry.base.Position)
	anchor.Parent = fxFolder
	local glow = Instance.new("PointLight")
	glow.Color = light
	glow.Range = 16
	glow.Brightness = 1.6
	glow.Shadows = false
	glow.Parent = anchor
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(color, light)
	sparks.LightEmission = 0.35
	sparks.LightInfluence = 0
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new(0.1, 1)
	sparks.Lifetime = NumberRange.new(1, 1.8)
	sparks.Speed = NumberRange.new(1.5, 3.5)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, 2, 0)
	sparks.Rate = 3
	sparks.Parent = anchor
	entry.anchor, entry.glow, entry.sparks = anchor, glow, sparks

	-- Издалека яйцо видно сразу: мягкий столб света в цвет яйца и надпись с названием и ценой
	-- (вблизи её сменяет большое табло с питомцами).
	-- Луч света сверху, как солнце сквозь листву: невидимая деталь-ось, на ней мягкий
	-- размытый Beam (к земле чуть плотнее, вверху растворяется) и редкие пылинки, плывущие в луче.
	local H = 44
	local baseY = entry.base.Position.Y + entry.height / 2
	local pillar = Instance.new("Part")
	pillar.Name = "EggPillar"
	pillar.Transparency = 1
	pillar.Anchored, pillar.CanCollide, pillar.CanQuery, pillar.CanTouch, pillar.CastShadow = true, false, false, false, false
	pillar.Size = Vector3.new(6, H, 6)
	pillar.CFrame = CFrame.new(entry.base.Position.X, baseY + H / 2, entry.base.Position.Z)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, -H / 2, 0)
	a0.Parent = pillar
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, H / 2, 0)
	a1.Parent = pillar
	local ray = Instance.new("Beam")
	ray.Attachment0, ray.Attachment1 = a0, a1
	ray.FaceCamera = true
	ray.Width0, ray.Width1 = 7, 13 -- луч расширяется кверху
	ray.Texture = "rbxasset://textures/particles/smoke_main.dds"
	ray.TextureMode = Enum.TextureMode.Stretch
	ray.TextureLength = 1
	ray.TextureSpeed = 0.04
	ray.LightEmission = 1
	ray.LightInfluence = 0
	ray.Brightness = 1.5
	ray.Color = ColorSequence.new(light:Lerp(Color3.fromRGB(255, 245, 210), 0.5), light)
	ray.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.62),
		NumberSequenceKeypoint.new(0.5, 0.76),
		NumberSequenceKeypoint.new(1, 1),
	})
	ray.Parent = pillar
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(255, 250, 225))
	dust.LightEmission = 1
	dust.LightInfluence = 0
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.22), NumberSequenceKeypoint.new(1, 0) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(4, 7)
	dust.Speed = NumberRange.new(0.2, 0.7)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Acceleration = Vector3.new(0, 0.15, 0)
	dust.Drag = 1
	dust.RotSpeed = NumberRange.new(-30, 30)
	dust.Rate = 5
	dust.Shape = Enum.ParticleEmitterShape.Box
	dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	dust.Parent = pillar
	pillar.Parent = fxFolder
	entry.dustFX, entry.rayFX = dust, ray
	local tag = Instance.new("BillboardGui")
	tag.Name = "EggTag"
	tag.Size = UDim2.fromOffset(200, 54)
	tag.StudsOffsetWorldSpace = Vector3.new(0, entry.height / 2 + 4, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.MaxDistance = 260
	tag.Adornee = anchor
	local tName = Instance.new("TextLabel")
	tName.BackgroundTransparency = 1
	tName.Size = UDim2.new(1, 0, 0.6, 0)
	tName.Font = Enum.Font.FredokaOne
	tName.TextScaled = true
	tName.Text = "🥚 " .. string.upper(egg.Name)
	tName.TextColor3 = Color3.new(1, 1, 1)
	local s1 = Instance.new("UIStroke")
	s1.Thickness = 2.5
	s1.Color = color:Lerp(Color3.new(0, 0, 0), 0.55)
	s1.Parent = tName
	tName.Parent = tag
	local tPrice = tName:Clone()
	tPrice.Position = UDim2.fromScale(0, 0.6)
	tPrice.Size = UDim2.new(1, 0, 0.4, 0)
	tPrice.Text = "💰 " .. fmt(egg.Cost)
	tPrice.TextColor3 = Color3.fromRGB(255, 225, 90)
	tPrice.Parent = tag
	tag.Parent = anchor
	entry.tag = tag

	-- Огоньки по орбите: чем дороже яйцо, тем их больше; у каждого светящийся хвост.
	for k = 1, 2 + tier do
		local orb = Instance.new("Part")
		orb.Name = "EggOrb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(0.5, 0.5, 0.5)
		orb.Material = Enum.Material.Neon
		orb.Color = light
		orb.Anchored, orb.CanCollide, orb.CanQuery, orb.CanTouch, orb.CastShadow = true, false, false, false, false
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.22, 0)
		a0.Parent = orb
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.22, 0)
		a1.Parent = orb
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = ColorSequence.new(light, color)
		trail.LightEmission = 1
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Lifetime = 0.45
		trail.FaceCamera = true
		trail.Parent = orb
		orb.Parent = fxFolder
		table.insert(entry.orbs, orb)
	end

	-- У самого дорогого яйца мира вверх бьёт фонтан золотых искр.
	if tier == 3 then
		local pillar = Instance.new("ParticleEmitter")
		pillar.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pillar.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), color)
		pillar.LightEmission = 0.4
		pillar.LightInfluence = 0
		pillar.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.2) })
		pillar.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) })
		pillar.Lifetime = NumberRange.new(1.6, 2.4)
		pillar.Speed = NumberRange.new(7, 10)
		pillar.EmissionDirection = Enum.NormalId.Top
		pillar.SpreadAngle = Vector2.new(6, 6)
		pillar.Rate = 10
		pillar.Parent = anchor
		entry.pillar = pillar
	end
	eggs[id] = entry
end

for id in ipairs(Config.Eggs) do
	local w = Config.Eggs[id].World
	local zone = w == "neon" and city or w == "sky" and world:WaitForChild("SkyIsles", 60) or w == "volcano" and world:WaitForChild("MagmaVolcano", 60) or w == "galaxy" and world:WaitForChild("CosmicGalaxy", 60) or w == "frozen" and world:WaitForChild("FrozenPeaks", 60) or world
	if not zone then
		continue
	end
	local stand = zone:WaitForChild("EggStand" .. id, 10)
	-- Яйца острова 1–3 сервер пересобирает при запуске: ждём готовую модель.
	while stand and not stand:GetAttribute("EggReady") do
		stand.AttributeChanged:Wait()
	end
	if stand then
		local ok, err = pcall(buildBoard, id, stand)
		if not ok then
			warn("[EggBillboards] " .. tostring(err))
		end
		setupEgg(id, stand)
	end
end

-- При открытии яйца: прыжок с переворотом, вспышка и фонтан искр.
ReplicatedStorage:WaitForChild("GameHatched").OnClientEvent:Connect(function(_, sourceEgg)
	local e = eggs[sourceEgg]
	if e then
		e.popAt = os.clock()
		e.sparks:Emit(40)
	end
end)

-- Табло появляется (с «пружинкой»), когда игрок подходит к яйцу ближе 24 студов.
local BOARD_NEAR = 24
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	do
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for _, b in ipairs(boards) do
			local a = b.anchor
			local pos = a and a.Parent and (a:IsA("Attachment") and a.WorldPosition or a.Position)
			local near = r ~= nil and pos ~= nil and (r.Position - pos).Magnitude < BOARD_NEAR
			if near ~= b.shown then
				b.shown = near
				if near then
					b.gui.Enabled = true
					b.pop.Scale = 0.6
					TweenService:Create(b.pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				else
					b.gui.Enabled = false
				end
			end
		end
	end
	local now = os.clock()
	local camera = workspace.CurrentCamera
	local camPos = camera and camera.CFrame.Position or Vector3.zero
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, e in pairs(eggs) do
		local center = e.base.Position
		local camDist = (center - camPos).Magnitude
		-- яйца других миров и далёкие: всё выключено (свет, луч, пыль, искры)
		local active = camDist < 120
		if e.wasActive ~= active then
			e.wasActive = active
			e.sparks.Enabled = active
			e.glow.Enabled = active
			if e.dustFX then
				e.dustFX.Enabled = active
			end
			if e.rayFX then
				e.rayFX.Enabled = active
			end
			if e.pillar and not active then
				e.pillar.Enabled = false
			end
		end
		if active and e.model.Parent then
			local dist = root and (root.Position - center).Magnitude or 999
			local target = math.clamp(1 - (dist - 10) / 22, 0, 1)
			e.tag.Enabled = dist > 24
			e.excite += (target - e.excite) * math.min(1, dt * 3)
			local x = e.excite
			local h = e.height

			-- вздрагивание раз в несколько секунд (рядом с игроком — чаще)
			if t > e.nextWobble then
				e.wobbleAt = t
				e.nextWobble = t + (x > 0.3 and 2.2 or 5) + math.random() * 3
				e.sparks:Emit(8 + e.tier * 4)
			end
			local w = t - e.wobbleAt
			local rock = 0
			if w < 0.9 then
				rock = math.sin(w * 38) * 0.2 * (1 - w / 0.9)
			end

			local bob = math.sin(t * (e.neon and 1.05 or 1.6) + e.phase) * (e.neon and 0.22 or 0.35) * (1 - x * 0.5)
			local hop = math.abs(math.sin(t * 5.5 + e.phase)) * x * 1.1
			e.spin += dt * ((e.neon and 0.4 or 0.55) + x * 1.4)
			local lean = math.sin(t * 0.8 + e.phase) * 0.04

			-- прыжок при открытии
			local pop = now - e.popAt
			local popH, popSpin = 0, 0
			if pop < 0.8 then
				local k = pop / 0.8
				popH = math.sin(k * math.pi) * (h * 0.6 + 2)
				popSpin = k * math.pi * 2
			end

			local pivot = e.base
				* CFrame.new(0, 0.35 + bob + hop + popH, 0)
				* CFrame.Angles(0, e.spin + popSpin, 0)
				* CFrame.new(0, -h / 2, 0)
				* CFrame.Angles(lean + rock * 0.6, 0, rock)
				* CFrame.new(0, h / 2, 0)
			e.model:PivotTo(pivot)

			-- «дыхание» через ScaleTo убрано: пересчитывать всю модель каждый кадр слишком дорого

			local flash = pop < 0.5 and (1 - pop / 0.5) * 6 or 0
			local shake = w < 0.9 and (1 - w / 0.9) * 1.5 or 0
			e.anchor.CFrame = CFrame.new(center + Vector3.new(0, 0.35 + bob + hop + popH, 0))
			e.glow.Brightness = (e.neon and 1.6 or 0.8) + 0.35 * math.sin(t * 2 + e.phase) + x * 1.6 + shake + flash
			-- Range не меняем каждый кадр (дорого для освещения): только яркость
			e.sparks.Rate = 2 + e.tier + x * 18

			local r = math.max(3.4, e.radius + 1.6)
			for k, orb in ipairs(e.orbs) do
				local n = #e.orbs
				local a = t * (1.2 + x * 1.6) + k / n * math.pi * 2 + e.phase
				local y = math.sin(t * 2 + k * 1.7) * h * 0.3
				orb.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * r, 0.35 + y + popH * 0.5, math.sin(a) * r))
			end
			if e.pillar then
				e.pillar.Enabled = true
				e.pillar.Rate = 10 + x * 20
			end
			for _, hr in ipairs(e.holo) do
				local rot = CFrame.new(hr.center) * CFrame.Angles(0, t * 0.7, 0) * CFrame.new(-hr.center)
				hr.part.CFrame = rot * hr.base
			end
		end
	end
end)
