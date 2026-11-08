-- Место Royal Egg в мире (Meadow, рядом со спавном): королевский пьедестал (модель Tripo
-- ReplicatedStorage.TripoEggs.RoyalPedestal или из деталей), над ним парит яйцо, рядом большая
-- 3D-витрина (содержимое рисует клиент RoyalEggStandFX: питомцы, шансы, лучи), золотые колонны
-- света и круг входа — встал на круг, открылось окно Royal Egg.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
-- пока товар Royal Egg не создан в Roblox (Id = 0), в живой игре место не ставим — иначе
-- игрок встанет на круг, а купить нельзя. В Studio ставим всегда (для проверки).
do
	local live = false
	for _, list in pairs(StoreConfig) do
		if type(list) == "table" then
			for _, def in pairs(list) do
				if type(def) == "table" and def.Key == "RoyalEgg1" and (def.Id or 0) > 0 then
					live = true
				end
			end
		end
	end
	if not live and not RunService:IsStudio() then
		return
	end
end
local world = workspace:WaitForChild("CoinSpeedWorld")
local RoyalEggModel = require(ReplicatedStorage:WaitForChild("RoyalEggModel"))

-- место: справа от спавна Meadow (свободная поляна), Y берём лучом по земле
local SPOTS = {
	{ Name = "Meadow", Pos = Vector3.new(62, 0, 190), Face = Vector3.new(0, 0, 190) }, -- справа от спавна, лицом к нему
}

local GOLD = Color3.fromRGB(255, 200, 70)
local PURPLE = Color3.fromRGB(120, 50, 180)

local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end
local function cyl(parent, name, h, d, cf, color, mat, props)
	local p = part(parent, name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, mat, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- ставит модель так, чтобы низ её габарита был в точке bottom (повернув как face)
local function placeBottom(model: Model, bottom: CFrame)
	model:PivotTo(bottom.Rotation * (model:GetPivot() - model:GetPivot().Position) + model:GetPivot().Position)
	local cf, size = model:GetBoundingBox()
	local lowCenter = cf.Position - Vector3.new(0, size.Y / 2, 0)
	model:PivotTo(model:GetPivot() + (bottom.Position - lowCenter))
	return size
end

local function groundY(pos: Vector3): number
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { world, workspace.Terrain }
	local hit = workspace:Raycast(pos + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), rp)
	return hit and hit.Position.Y or pos.Y
end

local function build(spot)
	local y = groundY(spot.Pos)
	local base = CFrame.lookAt(Vector3.new(spot.Pos.X, y, spot.Pos.Z), Vector3.new(spot.Face.X, y, spot.Face.Z))
	local m = Instance.new("Model")
	m.Name = "RoyalEggStand"
	m:SetAttribute("Spot", spot.Name)

	-- пьедестал
	local folder = ReplicatedStorage:FindFirstChild("TripoEggs")
	local tp = folder and folder:FindFirstChild("RoyalPedestal")
	local topY
	if tp then
		local ped = tp:Clone()
		ped.Name = "Pedestal"
		local _, size = ped:GetBoundingBox()
		ped:ScaleTo(ped:GetScale() * 14 / math.max(size.X, size.Z))
		local s2 = placeBottom(ped, base)
		for _, d in ipairs(ped:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = true
			end
		end
		ped.Parent = m
		topY = s2.Y * 0.92
	else
		cyl(m, "Step1", 1, 14, base * CFrame.new(0, 0.5, 0), Color3.fromRGB(245, 240, 250), Enum.Material.Marble)
		cyl(m, "Trim1", 0.3, 14.4, base * CFrame.new(0, 1.05, 0), GOLD, Enum.Material.Foil)
		cyl(m, "Step2", 1.2, 10.5, base * CFrame.new(0, 1.7, 0), Color3.fromRGB(245, 240, 250), Enum.Material.Marble)
		cyl(m, "Trim2", 0.3, 10.9, base * CFrame.new(0, 2.35, 0), GOLD, Enum.Material.Foil)
		cyl(m, "Cushion", 0.8, 7, base * CFrame.new(0, 2.9, 0), Color3.fromRGB(180, 30, 60), Enum.Material.Fabric)
		for i = 1, 4 do
			local a = i / 4 * math.pi * 2 + math.pi / 4
			local at = base * CFrame.new(math.cos(a) * 6, 0, math.sin(a) * 6)
			cyl(m, "Pillar", 7, 0.9, at * CFrame.new(0, 3.5, 0), GOLD, Enum.Material.Foil)
			part(m, "PillarGem", Vector3.new(1, 1, 1), at * CFrame.new(0, 7.4, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color3.fromRGB(190, 110, 255), Enum.Material.Neon, { CanCollide = false })
		end
		topY = 3.3
	end

	-- парящее яйцо (клиент качает и вращает его; сервер только ставит)
	local egg = RoyalEggModel.Build()
	egg.Name = "DisplayEgg"
	local _, es = egg:GetBoundingBox()
	egg:ScaleTo(egg:GetScale() * 9 / math.max(es.Y, 0.1))
	placeBottom(egg, base * CFrame.new(0, topY + 0.8, 0))
	for _, d in ipairs(egg:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide = true, false
		end
	end
	egg.Parent = m
	local anchor = part(m, "EggAnchor", Vector3.new(1, 1, 1), CFrame.new(egg:GetBoundingBox().Position), GOLD, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 22
	light.Brightness = 2
	light.Parent = anchor

	-- витрина: щит за пьедесталом (SurfaceGui рисует клиент)
	local board = part(m, "Board", Vector3.new(22, 11, 0.6), base * CFrame.new(0, topY + 9.5, 9), Color3.fromRGB(60, 25, 95), Enum.Material.SmoothPlastic, { CanCollide = false })
	part(m, "BoardFrame", Vector3.new(23.2, 12.2, 0.4), board.CFrame * CFrame.new(0, 0, 0.35), GOLD, Enum.Material.Foil, { CanCollide = false })
	for _, sx in ipairs({ -1, 1 }) do
		cyl(m, "BoardPost", topY + 15, 1, base * CFrame.new(sx * 11.8, (topY + 15) / 2, 9.2), GOLD, Enum.Material.Foil)
	end
	-- подсветка витрины (фидбэк 8): тёплый свет на доску и неоновые кромки
	local boardLight = Instance.new("SurfaceLight")
	boardLight.Face = Enum.NormalId.Front
	boardLight.Range = 14
	boardLight.Brightness = 1.6
	boardLight.Color = Color3.fromRGB(255, 220, 160)
	boardLight.Parent = board
	for _, sy in ipairs({ -1, 1 }) do
		part(m, "BoardGlow", Vector3.new(23.4, 0.35, 0.5), board.CFrame * CFrame.new(0, sy * 6.25, -0.1), Color3.fromRGB(255, 210, 90), Enum.Material.Neon, { CanCollide = false, CanQuery = false })
	end
	local crownTop = part(m, "BoardCrown", Vector3.new(3, 2, 0.6), board.CFrame * CFrame.new(0, 7, 0), GOLD, Enum.Material.Foil, { CanCollide = false })
	crownTop.Name = "BoardCrown"

	-- круг входа перед пьедесталом
	local zone = cyl(m, "RoyalZone", 0.3, 9, base * CFrame.new(0, 0.45, -11), GOLD, Enum.Material.Neon, { CanCollide = false, CanQuery = false, Transparency = 0.45 })
	zone:SetAttribute("RoyalZone", true)
	cyl(m, "ZoneRim", 0.25, 10, base * CFrame.new(0, 0.38, -11), Color3.fromRGB(255, 240, 180), Enum.Material.Neon, { CanCollide = false, CanQuery = false, Transparency = 0.2 })
	-- Трава Terrain прорастала сквозь круг и прятала надпись (фидбэк 9): под кругом — земля без травы.
	pcall(function()
		local c = zone.Position
		local r = Region3.new(c - Vector3.new(6, 6, 6), c + Vector3.new(6, 2, 6)):ExpandToGrid(4)
		workspace.Terrain:ReplaceMaterial(r, 4, Enum.Material.Grass, Enum.Material.Ground)
		workspace.Terrain:ReplaceMaterial(r, 4, Enum.Material.LeafyGrass, Enum.Material.Ground)
	end)

	m.PrimaryPart = anchor
	m.Parent = world
	CollectionService:AddTag(m, "RoyalEggStand")
end

task.spawn(function()
	-- ждём, пока построятся мир и модели Tripo (как другие декорации)
	local t0 = os.clock()
	while not workspace:GetAttribute("TripoDressed") and os.clock() - t0 < 25 do
		task.wait(0.5)
	end
	for _, s in ipairs(SPOTS) do
		local ok, err = pcall(build, s)
		if not ok then
			warn("[RoyalEggStand] " .. tostring(err))
		end
	end
end)
