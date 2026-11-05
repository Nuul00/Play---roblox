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

local function sign(model: Model, cf: CFrame, title: string, sub: string, color: Color3)
	local board = part(model, "Sign", Vector3.new(9, 2.6, 0.3), cf, Color3.fromRGB(30, 20, 50))
	board.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(450, 130)
	gui.LightInfluence = 0
	gui.Parent = board
	local function text(t: string, y: number, h: number, c: Color3)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(10, y)
		l.Size = UDim2.fromOffset(430, h)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.Text = t
		l.TextColor3 = c
		l.Parent = gui
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
	-- Каменная площадка под машиной и мостик до дорожки (тем же камнем, что дорожка): машина
	-- не тонет в траве и к ней видно, как подойти.
	if path and path:IsA("BasePart") then
		local top = path.Position.Y + path.Size.Y / 2
		local edge = path.Position.Z + path.Size.Z / 2
		local pad = path:Clone()
		pad.Name = "MachinePad"
		pad:ClearAllChildren()
		pad.Size = Vector3.new(17, path.Size.Y, 17)
		pad.CFrame = CFrame.new(pos.X, path.Position.Y, pos.Z)
		pad.Parent = model
		local link = path:Clone()
		link.Name = "MachinePath"
		link:ClearAllChildren()
		local from, to = edge - 0.2, pos.Z - 8.3
		link.Size = Vector3.new(7, path.Size.Y, math.max(to - from, 0.5))
		link.CFrame = CFrame.new(pos.X, path.Position.Y, (from + to) / 2)
		link.Parent = model
		y = top
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
for tier in ipairs(ShopConfig.Variants) do
	task.spawn(function()
		local ok, result = pcall(build, tier)
		if ok then
			machines[tier] = result
		else
			warn("[PetMachines] " .. tostring(result))
		end
	end)
end

local cooldown = {}
fuse.OnServerEvent:Connect(function(p, tier, id)
	if type(tier) ~= "number" or type(id) ~= "number" or tier ~= math.floor(tier) or id ~= math.floor(id) then
		return
	end
	if not p:GetAttribute("ProfileReady") then
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
