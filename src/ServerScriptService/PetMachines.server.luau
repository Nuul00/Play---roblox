-- Машины улучшения питомцев: Golden (Meadow), Diamond (Neon District), Rainbow (Sky Isles).
-- Сервер строит машины и проверяет запрос «сплавить»: игрок рядом с машиной, питомцев хватает.
-- Само превращение — PlayerSystems.Fuse; окно машины — PetMachineUI.client.luau.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))

local world = workspace:WaitForChild("CoinSpeedWorld")
local folder = Instance.new("Folder")
folder.Name = "PetMachines"
folder.Parent = workspace

local fuse = Instance.new("RemoteEvent")
fuse.Name = "GamePetFuse"
fuse.Parent = ReplicatedStorage

local MAX_DISTANCE = 22

-- Где стоят машины и куда смотрят. Каждая стоит у дорожки лицом к ней: в Meadow и Неонграде —
-- напротив яиц через дорожку EggPath (z = 150) на своей каменной площадке, в Sky — у дорожки
-- к магазинам (z = 45). Третье значение — дорожка, от которой ведём к машине площадку.
local SPOTS = {
	[1] = function()
		return Vector3.new(85, 0, 167), Vector3.new(85, 0, 150), world:FindFirstChild("EggPath")
	end,
	[2] = function()
		local city = world:WaitForChild("NeonCity")
		local x = city:WaitForChild("Floor").Position.X
		return Vector3.new(x + 85, 0, 167), Vector3.new(x + 85, 0, 150), city:FindFirstChild("EggPath")
	end,
	[3] = function()
		local sky = world:WaitForChild("SkyIsles", 120)
		local deck = sky and sky:WaitForChild("Ground"):WaitForChild("Deck")
		local c = deck and deck.Position or Vector3.new(1100, 0, 0)
		return Vector3.new(c.X + 45, 0, c.Z + 62), Vector3.new(c.X + 45, 0, c.Z + 45), nil
	end,
}

local STYLE = {
	[1] = { body = Color3.fromRGB(255, 244, 214), trim = Color3.fromRGB(255, 190, 40), glow = Color3.fromRGB(255, 214, 90), base = Color3.fromRGB(120, 86, 40) },
	[2] = { body = Color3.fromRGB(34, 30, 70), trim = Color3.fromRGB(80, 220, 255), glow = Color3.fromRGB(130, 240, 255), base = Color3.fromRGB(20, 18, 40) },
	[3] = { body = Color3.fromRGB(250, 240, 255), trim = Color3.fromRGB(255, 140, 220), glow = Color3.fromRGB(255, 255, 255), base = Color3.fromRGB(190, 160, 230) },
}

local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

-- Табличка — билборд: всегда повёрнута к игроку (фидбэк 7). Ниже — прыгающая стрелка ▼,
-- видна издалека и показывает, где машина (фидбэк 7/21/35).
local TweenService = game:GetService("TweenService")
local function sign(model: Model, cf: CFrame, title: string, sub: string, color: Color3)
	local board = part(model, "Sign", Vector3.new(1, 1, 1), cf, color)
	board.CanCollide = false
	board.CanQuery = false
	board.CanTouch = false
	board.Transparency = 1
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(11, 3.2)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	gui.Parent = board
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(26, 22, 40)
	bg.BackgroundTransparency = 0.15
	bg.Parent = gui
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0.25, 0)
	local edge = Instance.new("UIStroke")
	edge.Color = color
	edge.Thickness = 3
	edge.Parent = bg
	local arrowGui = Instance.new("BillboardGui")
	arrowGui.Size = UDim2.fromScale(3, 3)
	arrowGui.StudsOffset = Vector3.new(0, 3.4, 0)
	arrowGui.MaxDistance = 220
	arrowGui.LightInfluence = 0
	arrowGui.Parent = board
	local arrowText = Instance.new("TextLabel")
	arrowText.BackgroundTransparency = 1
	arrowText.Size = UDim2.fromScale(1, 1)
	arrowText.Font = Enum.Font.FredokaOne
	arrowText.TextScaled = true
	arrowText.Text = "▼"
	arrowText.TextColor3 = color
	arrowText.Parent = arrowGui
	local arrowStroke = Instance.new("UIStroke")
	arrowStroke.Thickness = 3
	arrowStroke.Color = Color3.fromRGB(20, 10, 30)
	arrowStroke.Parent = arrowText
	TweenService:Create(arrowGui, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { StudsOffset = Vector3.new(0, 4.4, 0) }):Play()
	local function text(t: string, y: number, h: number, c: Color3)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.04, y / 130)
		l.Size = UDim2.fromScale(0.92, h / 130)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.Text = t
		l.TextColor3 = c
		l.Parent = bg
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Color = Color3.fromRGB(20, 10, 30)
		s.Parent = l
	end
	text(title, 6, 70, color)
	text(sub, 78, 44, Color3.new(1, 1, 1))
end

local function build(tier: number)
	local def = ShopConfig.Variants[tier]
	local style = STYLE[tier]
	local pos, face, path = SPOTS[tier]()
	-- Высоту берём из земли под точкой.
	local hit = workspace:Raycast(pos + Vector3.new(0, 500, 0), Vector3.new(0, -1000, 0))
	local y = hit and hit.Position.Y or 0

	local model = Instance.new("Model")
	model.Name = "PetMachine" .. tier
	model:SetAttribute("Tier", tier)
	-- Каменная площадка под машиной и мостик до дорожки. Дорожки в Meadow и Неонграде нарисованы
	-- брусчаткой Terrain (поверх травы), поэтому и площадку красим так же: машина стоит на камне,
	-- а не тонет в траве, и к ней видно, как подойти.
	if path and path:IsA("BasePart") then
		local terrain = workspace.Terrain
		local tp = RaycastParams.new()
		tp.FilterType = Enum.RaycastFilterType.Include
		tp.FilterDescendantsInstances = { terrain }
		-- Terrain на сервере догружается в первые секунды: ждём, пока луч найдёт землю
		local surf
		for _ = 1, 24 do
			surf = workspace:Raycast(Vector3.new(pos.X, 60, pos.Z), Vector3.new(0, -120, 0), tp)
			if surf then
				break
			end
			task.wait(0.5)
		end
		-- нет Terrain (Неонград стоит на детали-полу) — там ничего не красим, машина просто на полу
		if not surf then
			path = nil
		end
		local sy = surf and surf.Position.Y or y
		local mat = Enum.Material.Cobblestone
		local onPath = path and workspace:Raycast(Vector3.new(path.Position.X, 60, path.Position.Z), Vector3.new(0, -120, 0), tp)
		if onPath and onPath.Material ~= Enum.Material.Grass then
			mat = onPath.Material
		end
		local edge = path and (path.Position.Z + path.Size.Z / 2) or pos.Z
		pcall(function()
			if not path then
				return
			end
			terrain:FillBlock(CFrame.new(pos.X, sy - 1.5, pos.Z), Vector3.new(16, 3, 16), mat)
			local from, to = edge - 1, pos.Z - 7
			terrain:FillBlock(CFrame.new(pos.X, sy - 1.5, (from + to) / 2), Vector3.new(7, 3, math.max(to - from, 1)), mat)
		end)
		-- Terrain округляет площадку до сетки 4 студа: поверхность может подняться выше sy. Ждём,
		-- пока заливка применится, и ставим машину на фактическую поверхность (раньше утопала на 2 студа).
		local after
		for _ = 1, 6 do
			task.wait(0.25)
			after = workspace:Raycast(Vector3.new(pos.X, 60, pos.Z), Vector3.new(0, -120, 0), tp)
		end
		y = math.max(after and after.Position.Y or sy, sy)
	end
	local origin = CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(face.X, y, face.Z))

	local base = part(model, "Base", Vector3.new(1, 15, 15), origin * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), style.base, nil, Enum.PartType.Cylinder)
	part(model, "Rim", Vector3.new(0.5, 15.8, 15.8), origin * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), style.trim, Enum.Material.Neon, Enum.PartType.Cylinder).CanCollide = false
	local body = part(model, "Body", Vector3.new(8, 6, 6), origin * CFrame.new(0, 4, 0.5), style.body)
	part(model, "Top", Vector3.new(8.6, 0.8, 6.6), origin * CFrame.new(0, 7.3, 0.5), style.trim, Enum.Material.SmoothPlastic)
	part(model, "Bottom", Vector3.new(8.6, 0.8, 6.6), origin * CFrame.new(0, 1.3, 0.5), style.trim, Enum.Material.SmoothPlastic)
	-- Лицевая панель с пятью «слотами» под питомцев.
	part(model, "Panel", Vector3.new(6.6, 3.6, 0.2), origin * CFrame.new(0, 4.2, -2.6), style.base)
	for i = 1, ShopConfig.Variants[tier].Need do
		local slot = part(model, "Slot", Vector3.new(0.9, 0.9, 0.9), origin * CFrame.new((i - 3) * 1.2, 4.9, -2.75), style.glow, Enum.Material.Neon, Enum.PartType.Ball)
		slot.CanCollide = false
	end
	local arrow = part(model, "Arrow", Vector3.new(1.2, 0.3, 0.2), origin * CFrame.new(0, 3.5, -2.75), style.trim, Enum.Material.Neon)
	arrow.CanCollide = false
	-- Купол с ядром сверху.
	local dome = part(model, "Dome", Vector3.new(5.8, 5.8, 5.8), origin * CFrame.new(0, 10.3, 0.5), Color3.fromRGB(230, 245, 255), Enum.Material.Glass, Enum.PartType.Ball)
	dome.Transparency = 0.55
	dome.CanCollide = false
	local core = part(model, "Core", Vector3.new(2.4, 2.4, 2.4), origin * CFrame.new(0, 10.3, 0.5), style.glow, Enum.Material.Neon, Enum.PartType.Ball)
	core.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = style.glow
	light.Range = 16
	light.Brightness = 2
	light.Parent = core
	-- искры вокруг купола: машину видно и «живой» (фидбэк 7)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(style.glow, Color3.new(1, 1, 1))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new(0.1, 1)
	sparks.Lifetime = NumberRange.new(1, 1.6)
	sparks.Rate = 8
	sparks.Speed = NumberRange.new(1.5, 3)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Parent = core
	for k = 1, 3 do
		local ring = part(model, tier == 3 and "RainbowRing" or "Ring", Vector3.new(0.35, 7 + k * 0.6, 7 + k * 0.6), origin * CFrame.new(0, 10.3, 0.5) * CFrame.Angles(k * 0.6, k * 0.9, math.pi / 2), style.trim, Enum.Material.Neon, Enum.PartType.Cylinder)
		ring.Transparency = 0.35
		ring.CanCollide = false
		ring.Name = (tier == 3 and "RainbowRing" or "Ring") .. k
	end
	-- Трубы по бокам.
	for _, side in ipairs({ -1, 1 }) do
		part(model, "Pipe", Vector3.new(6.5, 1.1, 1.1), origin * CFrame.new(side * 4.6, 4.3, 0.5) * CFrame.Angles(0, 0, math.pi / 2), style.trim, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		part(model, "PipeCap", Vector3.new(1.6, 1.6, 1.6), origin * CFrame.new(side * 4.6, 7.6, 0.5), style.glow, Enum.Material.Neon, Enum.PartType.Ball).CanCollide = false
	end
	sign(model, origin * CFrame.new(0, 14.6, 0.5), string.upper(def.Name) .. " MACHINE", def.Need .. " same pets = 1 " .. def.Name .. " · x" .. string.format("%g", def.Mult), def.Color)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PetMachinePrompt"
	prompt.ActionText = "Upgrade pets"
	prompt.ObjectText = def.Name .. " Machine"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false -- кнопки E нет: окно открывается, когда игрок встаёт перед машиной (PetMachineUI)
	prompt:SetAttribute("Tier", tier)
	prompt.Parent = body

	model.PrimaryPart = base
	model.Parent = folder
	return model
end

local machines = {}
for tier, variant in ipairs(ShopConfig.Variants) do
	-- Shiny (HatchOnly) — только из яиц, машины для неё нет
	if variant.HatchOnly or not variant.World then
		continue
	end
	task.spawn(function()
		local ok, result = pcall(build, tier)
		if ok then
			machines[tier] = result
		else
			warn("[PetMachines] " .. tostring(result))
		end
	end)
end

local Worlds = require(game:GetService("ReplicatedStorage"):WaitForChild("WorldsConfig"))
local function unlocked(p, name)
	local def = Worlds.Find(name)
	return not def or (def.Cost or 0) <= 0 or p:GetAttribute(Worlds.UnlockKey(name)) == true
end
local cooldown = {}
fuse.OnServerEvent:Connect(function(p, tier, id)
	if type(tier) ~= "number" or type(id) ~= "number" or tier ~= math.floor(tier) or id ~= math.floor(id) then
		return
	end
	if not p:GetAttribute("ProfileReady") then
		return
	end
	local variant = ShopConfig.Variants[tier]
	if not variant or variant.HatchOnly or not unlocked(p, variant.World) then
		return
	end
	local machine = machines[tier]
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not machine or not root or (root.Position - machine:GetPivot().Position).Magnitude > MAX_DISTANCE then
		return
	end
	if os.clock() - (cooldown[p] or 0) < 0.3 then
		return
	end
	cooldown[p] = os.clock()
	if PlayerSystems.Fuse(p, tier, id) then
		fuse:FireClient(p, tier, id)
	end
end)
Players.PlayerRemoving:Connect(function(p)
	cooldown[p] = nil
end)
