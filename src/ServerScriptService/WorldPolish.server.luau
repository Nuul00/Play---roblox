-- Финальная «уборка» миров после того, как их построили и одели в модели Tripo:
-- 1) Круги-зоны под магазинами и перед машинами невидимы (зоны работают как раньше: встал — открылось).
-- 2) Монеты не прячутся в земле, траве, скалах и деревьях: поднимаем над землёй, а застрявшие
--    внутри предметов переносим на свободное место рядом.
-- 3) Каток на замёрзшем озере Frozen Peaks: встал на лёд — на ногах коньки, атрибут OnIce
--    (скольжение делает IceSkate.client).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local world = workspace:WaitForChild("CoinSpeedWorld")

------------------------------------------------------------------ 1. невидимые круги
local CIRCLES = { ShopZone = true, ShopZoneRing = true, MachineMarker = true, MachineMarkerInner = true, PlinthGlow = true }
local SHOPS = { UpgradeShop = true, MagnetShop = true }

local function hideCircle(p: BasePart)
	p.Transparency = 1
	p.CastShadow = false
	for _, d in ipairs(p:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") then
			(d :: any).Enabled = false
		end
	end
end

local function check(d: Instance)
	if not d:IsA("BasePart") then
		return
	end
	if CIRCLES[d.Name] then
		hideCircle(d)
	elseif d.Name == "Plinth" and d.Parent and SHOPS[d.Parent.Name] then
		-- круглая подставка под магазином (Frozen, Volcano, Galaxy): тоже «кружок»
		hideCircle(d)
		d.CanCollide = false
	end
end

for _, d in ipairs(world:GetDescendants()) do
	check(d)
end
world.DescendantAdded:Connect(function(d)
	task.defer(check, d)
end)
local machines = workspace:WaitForChild("PetMachines", 30)
if machines then
	for _, d in ipairs(machines:GetDescendants()) do
		check(d)
	end
	machines.DescendantAdded:Connect(function(d)
		task.defer(check, d)
	end)
end

------------------------------------------------------------------ 1б. проплешины в траве
-- Старые магазины Meadow и Неонграда спрятаны (их заменили модели Tripo), но их невидимые полы
-- и детали остались у земли — трава над ними не растёт, получается «вскопанный» участок.
-- Такие детали опускаем под землю (зоны, якоря и стойка, нужные логике, остаются на месте).
local KEEP = { ShopZone = true, ShopZoneRing = true, VendorAnchor = true, VendorSeatPoint = true, Interact = true, Counter = true, Plinth = true, PlinthGlow = true, ZoneLabel = true, Glow = true, Sign = true }
local function clearPatches(holder: Instance?)
	if not holder then
		return
	end
	for _, shopName in ipairs({ "UpgradeShop", "MagnetShop" }) do
		local shop = holder:FindFirstChild(shopName)
		if shop then
			for _, d in ipairs(shop:GetDescendants()) do
				if d:IsA("BasePart") and d.Transparency >= 1 and not KEEP[d.Name] and not d:IsDescendantOf(shop:FindFirstChild("TripoModel") or d) then
					local bottom = d.Position.Y - d.Size.Magnitude / 2
					if bottom < 4 then
						d.CanCollide = false
						d.CFrame = d.CFrame - Vector3.new(0, 60, 0)
					end
				end
			end
		end
	end
end
task.delay(8, function()
	pcall(clearPatches, world)
	pcall(clearPatches, world:FindFirstChild("NeonCity"))
end)

------------------------------------------------------------------ 2. монеты над землёй
local LIFT = 2.6
local function isCoin(p: Instance)
	return p:IsA("BasePart") and string.match(p.Name, "^Coin_%d+$") ~= nil
end

local function groundParams(coins: { Instance })
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = coins
	rp.RespectCanCollide = true
	return rp
end

local function isGround(hit: RaycastResult): boolean
	if hit.Normal.Y < 0.75 then
		return false
	end
	local inst = hit.Instance
	if inst:IsA("Terrain") then
		return true
	end
	return inst:IsA("BasePart") and math.max(inst.Size.X, inst.Size.Y, inst.Size.Z) > 30
end

local function fixCoins()
	local coins = {}
	for _, d in ipairs(world:GetDescendants()) do
		if isCoin(d) then
			table.insert(coins, d)
		end
	end
	local rp = groundParams(coins)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = coins
	overlap.RespectCanCollide = true
	local rng = Random.new(31)
	local raised, moved = 0, 0
	local function blocked(c: BasePart): boolean
		for _, p in ipairs(workspace:GetPartsInPart(c, overlap)) do
			if not p:IsDescendantOf(world) or math.max(p.Size.X, p.Size.Y, p.Size.Z) < 400 then
				return true
			end
		end
		return false
	end
	for i, c in ipairs(coins) do
		local y0 = c.Position
		-- земля под монетой
		local hit = workspace:Raycast(y0 + Vector3.new(0, 6, 0), Vector3.new(0, -50, 0), rp)
		if hit and isGround(hit) and y0.Y - hit.Position.Y < LIFT - 0.4 then
			c.Position = Vector3.new(y0.X, hit.Position.Y + LIFT, y0.Z)
			c:SetAttribute("Home", c.Position) -- клиент крутит монету вокруг этой точки
			raised += 1
		end
		-- внутри скалы, дерева, постройки — ищем рядом открытую землю
		if blocked(c) then
			local home = c.Position
			for _ = 1, 40 do
				local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(6, 34)
				local at = home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local g = workspace:Raycast(at + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), rp)
				if g and isGround(g) and math.abs(g.Position.Y - (home.Y - LIFT)) < 10 then
					c.Position = g.Position + Vector3.new(0, LIFT, 0)
					if not blocked(c) then
						c:SetAttribute("Home", c.Position)
						moved += 1
						break
					end
				end
				c.Position = home
			end
		end
		if i % 60 == 0 then
			task.wait()
		end
	end
	print(string.format("[WorldPolish] coins %d: raised %d, moved out of objects %d", #coins, raised, moved))

	-- 2026-11: монеты не лежат на дорожках/площадях/мостах, не у яиц, магазинов и машин
	-- и не друг в друге (раньше встречались по две монеты в одной точке).
	local PATH_WORDS = { "path", "plaza", "road", "street", "bridge", "walk", "sidewalk" }
	local function onPath(hit: RaycastResult?): boolean
		if not hit then
			return false
		end
		local inst = hit.Instance
		if inst:IsA("Terrain") then
			return hit.Material == Enum.Material.Cobblestone -- под дорожками Meadow — брусчатка Terrain
		end
		local n = string.lower(inst.Name)
		for _, w in ipairs(PATH_WORDS) do
			if string.find(n, w, 1, true) then
				return true
			end
		end
		return false
	end
	-- «запретные круги»: яйца, метки магазинов, машины (центр и радиус в плоскости XZ)
	local keepOut = {}
	for _, d in ipairs(world:GetDescendants()) do
		if d:IsA("Model") and string.match(d.Name, "^EggStand%d+$") then
			local cf, size = d:GetBoundingBox()
			table.insert(keepOut, { at = cf.Position, r = math.max(size.X, size.Z) / 2 + 8 })
		elseif d:IsA("BasePart") and (d.Name == "ShopZone" or d.Name == "MachineMarker" or d.Name == "Plinth") then
			table.insert(keepOut, { at = d.Position, r = math.max(d.Size.Y, d.Size.Z) / 2 + 6 })
		end
	end
	-- дорожки Sky Isles и Magma — декоративные детали без коллизии: луч для «твёрдой земли» их
	-- пролетает, поэтому дорожку ищем отдельным лучом, который видит и некасаемые детали
	local pathRay = RaycastParams.new()
	pathRay.FilterType = Enum.RaycastFilterType.Exclude
	pathRay.FilterDescendantsInstances = coins
	local function pathBelow(pos: Vector3): boolean
		return onPath(workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -50, 0), pathRay))
	end
	local MIN_GAP = 5
	local placed = {}
	local function badSpot(pos: Vector3, self: BasePart?): boolean
		for _, k in ipairs(keepOut) do
			local o = pos - k.at
			if Vector2.new(o.X, o.Z).Magnitude < k.r and math.abs(o.Y) < 25 then
				return true
			end
		end
		for _, q in ipairs(placed) do
			if q.coin ~= self and (q.at - pos).Magnitude < MIN_GAP then
				return true
			end
		end
		return pathBelow(pos)
	end
	local relocated = 0
	for i, c in ipairs(coins) do
		if badSpot(c.Position, c) then
			local home = c.Position
			local done = false
			for _ = 1, 60 do
				local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(6, 60)
				local at = home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local g = workspace:Raycast(at + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), rp)
				if g and isGround(g) and math.abs(g.Position.Y - (home.Y - LIFT)) < 10 then
					local pos = g.Position + Vector3.new(0, LIFT, 0)
					if not badSpot(pos, c) then
						c.Position = pos
						if not blocked(c) then
							c:SetAttribute("Home", c.Position)
							relocated += 1
							done = true
							break
						end
						c.Position = home
					end
				end
			end
			if not done then
				c.Position = home
			end
		end
		table.insert(placed, { coin = c, at = c.Position })
		if i % 40 == 0 then
			task.wait()
		end
	end
	print(string.format("[WorldPolish] coins moved off paths / eggs / shops / each other: %d", relocated))
end

-- миры и модели Tripo строятся в первые секунды; GameServer досыпает монеты — ждём
task.delay(12, function()
	local ok, err = pcall(fixCoins)
	if not ok then
		warn("[WorldPolish] coins", err)
	end
end)

------------------------------------------------------------------ 3. каток и коньки
local frozen = world:WaitForChild("FrozenPeaks", 120)
local lake = frozen and frozen:WaitForChild("FrozenLake", 30)
if not lake then
	return
end
local lakeR = math.max(lake.Size.Y, lake.Size.Z) / 2
local lakeTop = lake.Position.Y + lake.Size.X / 2
-- лёд скользкий и для физики
lake.CustomPhysicalProperties = PhysicalProperties.new(0.9, 0, 0, 100, 1)

local BLADE = Color3.fromRGB(220, 235, 250)
local BOOT = Color3.fromRGB(245, 245, 255)
local function skatePart(name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end
local function weld(a: BasePart, b: BasePart, c0: CFrame)
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = a, b, c0
	w.Parent = b
end
local function addSkates(char: Model)
	if char:FindFirstChild("IceSkates") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "IceSkates"
	for _, names in ipairs({ { "LeftFoot", "Left Leg" }, { "RightFoot", "Right Leg" } }) do
		local foot = char:FindFirstChild(names[1]) or char:FindFirstChild(names[2])
		if foot and foot:IsA("BasePart") then
			local r15 = foot.Name == names[1]
			local bottom = -foot.Size.Y / 2
			local boot = skatePart("SkateBoot", Vector3.new(foot.Size.X + 0.12, r15 and foot.Size.Y + 0.1 or 0.7, (r15 and foot.Size.Z or 1) + 0.15), BOOT, Enum.Material.SmoothPlastic)
			boot.Parent = folder
			weld(foot, boot, CFrame.new(0, r15 and 0.05 or bottom + 0.35, r15 and 0 or -0.05))
			local blade = skatePart("SkateBlade", Vector3.new(0.12, 0.35, (r15 and foot.Size.Z or 1) + 0.5), BLADE, Enum.Material.Metal)
			blade.Reflectance = 0.4
			blade.Parent = folder
			weld(foot, blade, CFrame.new(0, bottom - 0.2, -0.05))
			local tip = skatePart("SkateTip", Vector3.new(0.12, 0.3, 0.3), BLADE, Enum.Material.Metal)
			tip.Parent = folder
			weld(foot, tip, CFrame.new(0, bottom - 0.05, -((r15 and foot.Size.Z or 1) / 2 + 0.3)) * CFrame.Angles(math.rad(-35), 0, 0))
		end
	end
	folder.Parent = char
end
local function removeSkates(char: Model)
	local f = char:FindFirstChild("IceSkates")
	if f then
		f:Destroy()
	end
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.15 then
		return
	end
	acc = 0
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local o = root.Position - lake.Position
			local on = Vector2.new(o.X, o.Z).Magnitude < lakeR - 0.5 and root.Position.Y - lakeTop < 7 and root.Position.Y > lakeTop - 2
			if on ~= (p:GetAttribute("OnIce") == true) then
				p:SetAttribute("OnIce", on)
				if on then
					addSkates(char)
				else
					removeSkates(char)
				end
			end
		end
	end
end)

------------------------------------------------------------------ трава в кругах магазинов
-- Трава Terrain прорастала сквозь круги магазинов (фидбэк 7, как было у Royal Egg): под каждой
-- зоной магазина на Terrain трава меняется на брусчатку (как дорожки рядом).
task.spawn(function()
	task.wait(8)
	local terrain = workspace.Terrain
	for _, d in ipairs(world:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "ShopZone" then
			pcall(function()
				local r = math.min(math.max(d.Size.X, d.Size.Y, d.Size.Z) / 2 + 2, 14)
				local c = d.Position
				local reg = Region3.new(c - Vector3.new(r, 6, r), c + Vector3.new(r, 3, r)):ExpandToGrid(4)
				terrain:ReplaceMaterial(reg, 4, Enum.Material.Grass, Enum.Material.Cobblestone)
				terrain:ReplaceMaterial(reg, 4, Enum.Material.LeafyGrass, Enum.Material.Cobblestone)
			end)
		end
	end
end)
