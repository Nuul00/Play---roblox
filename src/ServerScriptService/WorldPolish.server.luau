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
	-- lake/rink: на льду катка Frozen монет нет (фидбэк 2026-11)
	local PATH_WORDS = { "path", "plaza", "road", "street", "bridge", "walk", "sidewalk", "lake", "rink" }
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

-- Коньки (фидбэк 2026-11: «некрасиво сидят»): тёмно-синий ботинок по форме стопы, белая шнуровка,
-- меховая манжета на щиколотке, две серебряные стойки и тонкое лезвие с загнутым носком.
local BOOT = Color3.fromRGB(40, 70, 140)
local FUR = Color3.fromRGB(245, 248, 255)
local STEEL = Color3.fromRGB(215, 225, 240)
local function skatePart(name, size, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.CastShadow = false
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
	for _, names in ipairs({ { "LeftFoot", "Left Leg", "LeftLowerLeg" }, { "RightFoot", "Right Leg", "RightLowerLeg" } }) do
		local foot = char:FindFirstChild(names[1]) or char:FindFirstChild(names[2])
		if foot and foot:IsA("BasePart") then
			local r15 = foot.Name == names[1]
			local fx = r15 and foot.Size.X or 1
			local fz = r15 and foot.Size.Z or 1
			local bottom = -foot.Size.Y / 2
			local base = r15 and CFrame.new() or CFrame.new(0, bottom + 0.35, -0.05)
			local fy = r15 and foot.Size.Y or 0.7
			local boot = skatePart("SkateBoot", Vector3.new(fx + 0.06, fy + 0.06, fz + 0.1), BOOT, Enum.Material.SmoothPlastic)
			boot.Parent = folder
			weld(foot, boot, base)
			local lace = skatePart("SkateLace", Vector3.new(fx * 0.4, 0.04, fz * 0.55), FUR, Enum.Material.SmoothPlastic)
			lace.Parent = folder
			weld(foot, lace, base * CFrame.new(0, fy / 2 + 0.04, -fz * 0.12))
			local shin = r15 and char:FindFirstChild(names[3])
			if shin and shin:IsA("BasePart") then
				local cuff = skatePart("SkateCuff", Vector3.new(0.3, shin.Size.X + 0.18, shin.Size.Z + 0.18), FUR, Enum.Material.Fabric, Enum.PartType.Cylinder)
				cuff.Parent = folder
				weld(shin, cuff, CFrame.new(0, -shin.Size.Y / 2 + 0.25, 0) * CFrame.Angles(0, 0, math.pi / 2))
			end
			local sole = (r15 and bottom or (bottom + 0.35 - fy / 2)) - 0.03
			for _, sz in ipairs({ -fz * 0.3, fz * 0.3 }) do
				local strut = skatePart("SkateStrut", Vector3.new(0.1, 0.22, 0.12), STEEL, Enum.Material.Metal)
				strut.Parent = folder
				weld(foot, strut, CFrame.new(0, sole - 0.11, sz))
			end
			local blade = skatePart("SkateBlade", Vector3.new(0.06, 0.12, fz + 0.45), STEEL, Enum.Material.Metal)
			blade.Reflectance = 0.5
			blade.Parent = folder
			weld(foot, blade, CFrame.new(0, sole - 0.27, -0.05))
			local tip = skatePart("SkateTip", Vector3.new(0.06, 0.12, 0.28), STEEL, Enum.Material.Metal)
			tip.Reflectance = 0.5
			tip.Parent = folder
			weld(foot, tip, CFrame.new(0, sole - 0.18, -(fz / 2 + 0.3)) * CFrame.Angles(math.rad(40), 0, 0))
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

------------------------------------------------------------------ круги магазинов перед прилавком
-- Фидбэк 2026-11: круг (ShopZone) заходил под модель магазина или стоял сбоку. Ставим его по центру
-- лицевой стороны, на 1.5 студа перед ней. Лицевая сторона — ось модели, ближайшая к направлению на круг.
task.spawn(function()
	local done = {}
	for _ = 1, 12 do
		task.wait(5)
		for _, zone in ipairs(world:GetDescendants()) do
			if zone:IsA("BasePart") and zone.Name == "ShopZone" and not done[zone] then
				local shop = zone.Parent
				local tm = shop and shop:FindFirstChild("TripoModel")
				-- магазин без модели Tripo (Frozen: ларёк магнитов из деталей) — его «тело» по прилавку и стенам
				local bodyBox = nil
				if not tm and shop and shop:FindFirstChild("Counter") then
					local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
					for _, d in ipairs(shop:GetChildren()) do
						if d:IsA("BasePart") and (d.Name == "Counter" or d.Name == "CounterTop" or d.Name == "BackWall" or d.Name == "Pillar") then
							local h = d.Size / 2
							for _, sx in { -1, 1 } do
								for _, sy in { -1, 1 } do
									for _, sz in { -1, 1 } do
										local c = d.CFrame * Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)
										mn, mx = mn:Min(c), mx:Max(c)
									end
								end
							end
						end
					end
					if mx.X > mn.X then
						bodyBox = { CFrame.new((mn + mx) / 2), mx - mn }
					end
				end
				if (tm and tm:IsA("Model")) or bodyBox then
					done[zone] = true
					-- круг не шире дорожки (фидбэк 2026-11: во Frozen круг 22 вылезал за дорожку 14)
					if math.max(zone.Size.Y, zone.Size.Z) > 13 then
						zone.Size = Vector3.new(zone.Size.X, 13, 13)
					end
					-- Neon: магазин магнитов стоял в конце боковой дорожки, далеко от площади (фидбэк 2026-11) —
					-- двигаем его к западному краю площади прибытия, боковую дорожку прячем
					if shop.Name == "MagnetShop" and shop.Parent and shop.Parent.Name == "NeonCity" and shop:IsA("Model") and not shop:GetAttribute("Moved") then
						shop:SetAttribute("Moved", true)
						pcall(function()
							local plaza = shop.Parent:FindFirstChild("ArrivalPlaza")
							local cf, size = tm:GetBoundingBox()
							local r = math.max(zone.Size.Y, zone.Size.Z) / 2
							local westEdge = plaza and (plaza.Position.X - plaza.Size.X / 2) or 9954
							-- круг касается края площади: центр модели = край − r − 1.5 − половина глубины
							local targetX = westEdge - r - 1.5 - size.X / 2
							-- по Z — середина западного края площади (место, отмеченное на скрине: ~z 183)
							local targetZ = plaza and (plaza.Position.Z - 3) or 183
							shop:PivotTo(shop:GetPivot() + Vector3.new(targetX - cf.X, 0, targetZ - cf.Z))
							local path = shop.Parent:FindFirstChild("MagnetPath")
							if path and path:IsA("BasePart") then
								path.Transparency = 1
								path.CanCollide = false
								for _, d in ipairs(path:GetChildren()) do
									if d:IsA("Decal") or d:IsA("Texture") then
										d.Transparency = 1
									end
								end
							end
						end)
						tm = shop:FindFirstChild("TripoModel")
					end
					pcall(function()
						local cf, size
						if tm then
							cf, size = tm:GetBoundingBox()
						else
							cf, size = bodyBox[1], bodyBox[2]
						end
						local to = zone.Position - cf.Position
						to = Vector3.new(to.X, 0, to.Z)
						if to.Magnitude < 2 then
							-- круг в центре: перед — сторона, противоположная продавцу (VendorAnchor стоит сзади)
							local v = shop:FindFirstChild("VendorAnchor")
							if not v then
								return
							end
							to = cf.Position - v.Position
							to = Vector3.new(to.X, 0, to.Z)
						end
						-- снап к оси мира (магазины стоят под 0/90/180/270)
						local dir = math.abs(to.X) > math.abs(to.Z) and Vector3.new(math.sign(to.X), 0, 0) or Vector3.new(0, 0, math.sign(to.Z))
						local half = math.abs(dir.X) * size.X / 2 + math.abs(dir.Z) * size.Z / 2
						local r = math.max(zone.Size.Y, zone.Size.Z) / 2
						local p = cf.Position + dir * (half + r + 1.5)
						zone.Position = Vector3.new(p.X, zone.Position.Y, p.Z)
						zone:SetAttribute("Aligned", true)
					end)
				end
			end
		end
	end
end)

------------------------------------------------------------------ Neon: дорога до конца площади
-- Фидбэк 2026-11: главная улица обрывалась посреди площади прибытия, дальше — тёмный пол до
-- дороги к лидербордам. Продлеваем асфальт, неоновые бордюры и разметку до края площади.
task.spawn(function()
	local city = world:WaitForChild("NeonCity", 60)
	if not city then
		return
	end
	local main = city:WaitForChild("MainPath", 30)
	local plaza = city:FindFirstChild("ArrivalPlaza")
	if not (main and main:IsA("BasePart")) then
		return
	end
	local endZ = (plaza and (plaza.Position.Z + plaza.Size.Z / 2) or 208)
	local function extend(p: BasePart)
		local z0, z1 = p.Position.Z - p.Size.Z / 2, p.Position.Z + p.Size.Z / 2
		if z1 < endZ and p.Size.Z > 200 then
			p.Size = Vector3.new(p.Size.X, p.Size.Y, endZ - z0)
			p.Position = Vector3.new(p.Position.X, p.Position.Y, (z0 + endZ) / 2)
		end
	end
	extend(main)
	local streets = city:FindFirstChild("NeonStreets")
	local lastDash
	for _, d in ipairs(streets and streets:GetDescendants() or {}) do
		if d:IsA("BasePart") then
			if d.Name == "CurbGlow" or d.Name == "CurbLine" then
				extend(d)
			elseif d.Name == "LaneDash" and (not lastDash or d.Position.Z > lastDash.Position.Z) then
				lastDash = d
			end
		end
	end
	if lastDash then
		local z = lastDash.Position.Z + 8
		while z < endZ - 2 do
			local c = lastDash:Clone()
			c.Position = Vector3.new(lastDash.Position.X, lastDash.Position.Y, z)
			c.Parent = lastDash.Parent
			z += 8
		end
	end
end)

------------------------------------------------------------------ Neon: одна дорога от улицы до моста
-- Фидбэк 2026-11: дорога к лидербордам — продолжение главной улицы. Изогнутая (кривая Безье),
-- начинается ровно в конце улицы и повторяет её разметку: бордюры ±7.5, линии ±6.7, пунктир
-- 3.8 через 8 (тот же шаг, что у улицы). К мосту плавно сужается. Табличка — за обочиной.
task.spawn(function()
	local city = world:WaitForChild("NeonCity", 60)
	local island = city and city:WaitForChild("LeaderboardIsland_NeonCity", 90)
	local main = city and city:FindFirstChild("MainPath")
	local deck = island and island:WaitForChild("BridgeDeck", 30)
	if not (main and deck and deck:IsA("BasePart")) then
		return
	end
	task.wait(2)
	for _, d in ipairs(island:GetChildren()) do
		if d:IsA("BasePart") and (d.Name == "ApproachPath" or d.Name == "ApproachEdge" or d.Name == "ApproachDash" or d.Name == "ApproachPost" or d.Name == "ApproachLamp") then
			d.Transparency = 1
			for _, l in ipairs(d:GetChildren()) do
				if l:IsA("Light") then
					l.Enabled = false
				end
			end
		end
	end
	-- разметка улицы (продольные полосы и пунктир) — образцы
	local streets = city:FindFirstChild("NeonStreets")
	local strips, dashSample, lastDashZ = {}, nil, -math.huge
	for _, d in ipairs(streets and streets:GetDescendants() or {}) do
		if d:IsA("BasePart") then
			if (d.Name == "CurbGlow" or d.Name == "CurbLine") and math.abs(d.Position.X - main.Position.X) < 12 then
				table.insert(strips, { dx = d.Position.X - main.Position.X, y = d.Position.Y, part = d })
			elseif d.Name == "LaneDash" and math.abs(d.Position.X - main.Position.X) < 1 then
				dashSample = dashSample or d
				lastDashZ = math.max(lastDashZ, d.Position.Z)
			end
		end
	end
	local topY = main.Position.Y + main.Size.Y / 2
	local mainEnd = main.Position.Z + main.Size.Z / 2
	local a = Vector3.new(main.Position.X, topY, mainEnd)
	local back = deck.CFrame * CFrame.new(0, 0, -deck.Size.Z / 2)
	local front = deck.CFrame * CFrame.new(0, 0, deck.Size.Z / 2)
	local nearBack = (back.Position - a).Magnitude < (front.Position - a).Magnitude
	local b = nearBack and back.Position or front.Position
	local far = nearBack and front.Position or back.Position
	b = Vector3.new(b.X, topY, b.Z)
	local bridgeDir = Vector3.new(far.X - b.X, 0, far.Z - b.Z).Unit
	local k = (b - a).Magnitude * 0.45
	local P0, P1, P2, P3 = a, a + Vector3.new(0, 0, 1) * k, b - bridgeDir * k, b
	local function bez(t)
		local u = 1 - t
		return P0 * (u * u * u) + P1 * (3 * u * u * t) + P2 * (3 * u * t * t) + P3 * (t * t * t)
	end
	local W = main.Size.X
	local Wend = deck.Size.X + 1
	local folder = Instance.new("Model")
	folder.Name = "LeaderboardRoad"
	local function p(name, size, at, color, mat, transp)
		local q = Instance.new("Part")
		q.Name = name
		q.Anchored = true
		q.CanCollide = name == "Road"
		q.CanQuery = name == "Road"
		q.CanTouch = false
		q.CastShadow = false
		q.Size = size
		q.CFrame = at
		q.Color = color
		q.Material = mat
		q.Transparency = transp or 0
		q.Parent = folder
		return q
	end
	local N = 20
	local arc = 0
	local nextDash = dashSample and (lastDashZ + 8 - mainEnd) or 5 -- длина дуги до центра следующего штриха
	-- для клиента (NeonRoadFX): форма кривой и фаза пунктира — штрихи бегут по изгибу, как по улице
	folder:SetAttribute("P0", P0)
	folder:SetAttribute("P1", P1)
	folder:SetAttribute("P2", P2)
	folder:SetAttribute("P3", P3)
	folder:SetAttribute("DashStart", nextDash)
	folder:SetAttribute("WScaleEnd", Wend / W)
	for i = 1, N do
		local t0, t1 = (i - 1) / N, i / N
		local q0, q1 = bez(t0), bez(t1)
		local mid = (q0 + q1) / 2
		local segLen = (q1 - q0).Magnitude
		local sc = 1 + (Wend / W - 1) * ((t0 + t1) / 2)
		local w = W * sc
		local scf = CFrame.lookAt(mid, mid + (q1 - q0))
		p("Road", Vector3.new(w, main.Size.Y, segLen + 0.6), scf * CFrame.new(0, -main.Size.Y / 2 + 0.01, 0), main.Color, main.Material)
		for _, s in ipairs(strips) do
			-- в кадре сегмента «вправо» = −X мира, поэтому смещение берём с минусом
			p("RoadStrip", Vector3.new(s.part.Size.X, s.part.Size.Y, segLen + 0.12), scf * CFrame.new(-s.dx * sc, s.y - topY, 0), s.part.Color, s.part.Material, s.part.Transparency):SetAttribute("Dx", s.dx)
		end
		while dashSample and nextDash <= arc + segLen do
			local along = nextDash - arc - segLen / 2
			p("RoadDash", dashSample.Size, scf * CFrame.new(0, dashSample.Position.Y - topY, -along), dashSample.Color, dashSample.Material)
			nextDash += 8
		end
		arc += segLen
	end
	folder.Parent = city
	-- табличка «TOP PLAYERS» за обочиной: снаружи изгиба, на трети пути, лицом к идущим с площади
	task.wait(1)
	local sign = island:FindFirstChild("TopSignModel")
	if sign and sign:IsA("Model") then
		local tq = 0.3
		local pt = bez(tq)
		local tan = (bez(tq + 0.02) - bez(tq - 0.02)).Unit
		local left = Vector3.new(tan.Z, 0, -tan.X) -- влево по ходу (к −X)
		if left.X > 0 then
			left = -left
		end
		local w = W * (1 + (Wend / W - 1) * tq)
		local base = pt + left * (w / 2 + 7)
		local oldCf = sign:GetPivot()
		local face = CFrame.lookAt(Vector3.new(base.X, oldCf.Y, base.Z), Vector3.new(base.X, oldCf.Y, base.Z) - tan - left * 0.55) -- лицом к дороге и к идущим с площади
		local pivot0 = oldCf.Position
		local function move(inst: Instance)
			if inst:IsA("BasePart") then
				local rel = CFrame.new(pivot0):ToObjectSpace(inst.CFrame)
				inst.CFrame = face * oldCf.Rotation:Inverse() * rel
			end
		end
		for _, d in ipairs(sign:GetDescendants()) do
			move(d)
		end
		for _, d in ipairs(island:GetChildren()) do
			if d.Name == "TopBoardPost" or d.Name == "TopBoardLamp" or d.Name == "TopSign" then
				move(d)
			end
		end
		sign.WorldPivot = face
	end
end)

------------------------------------------------------------------ Frozen: оформление площадки яиц
-- Фидбэк 2026-11: ледяная площадка с тремя яйцами пустая. По краю — ёлки, ледяные кристаллы,
-- снеговики и фонари (модели Tripo), проход от дорожки оставляем свободным.
task.spawn(function()
	local fz = world:WaitForChild("FrozenPeaks", 120)
	local garden = fz and fz:WaitForChild("Paths", 30) and fz.Paths:WaitForChild("EggGarden", 30)
	local props = game:GetService("ReplicatedStorage"):FindFirstChild("TripoProps")
	if not (garden and props) then
		return
	end
	task.wait(3)
	local center = garden.Position
	local topY = garden.Position.Y + garden.Size.X / 2
	local R = math.max(garden.Size.Y, garden.Size.Z) / 2
	local entry = fz.Paths:FindFirstChild("PathEggs")
	local entryAng = entry and math.atan2(entry.Position.Z - center.Z, entry.Position.X - center.X) or math.rad(142)
	local folder = Instance.new("Model")
	folder.Name = "EggGardenDecor"
	local function place(name, height, pos, yaw)
		local t = props:FindFirstChild(name)
		if not t then
			return
		end
		local m = t:Clone()
		local _, ext = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * height / math.max(ext.Y, 0.1))
		local cf, ext2 = m:GetBoundingBox()
		local off = m:GetPivot():ToObjectSpace(cf)
		m:PivotTo(CFrame.new(pos + Vector3.new(0, ext2.Y / 2 - 0.1, 0)) * CFrame.Angles(0, yaw, 0) * off:Inverse())
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = name ~= "IceCrystals"
				d.CanQuery = false
				d.CanTouch = false
			elseif d:IsA("LuaSourceContainer") then
				d:Destroy()
			end
		end
		m.Parent = folder
	end
	local rng = Random.new(7)
	local plan = { "SnowPine", "IceCrystals", "SnowPine", "FrozenLamp", "SnowPine", "Snowman", "IceCrystals", "SnowPine", "FrozenLamp", "SnowPine", "IceCrystals", "Snowman", "SnowPine", "FrozenLamp" }
	local n = #plan
	for i, name in ipairs(plan) do
		local a = entryAng + math.rad(32) + (i - 1) / (n - 1) * (math.pi * 2 - math.rad(64))
		local r = R - (name == "FrozenLamp" and 4 or 7) + rng:NextNumber(-1.5, 1.5)
		local pos = Vector3.new(center.X + math.cos(a) * r, topY, center.Z + math.sin(a) * r)
		local h = ({ SnowPine = rng:NextNumber(14, 19), IceCrystals = rng:NextNumber(5, 7), Snowman = 6.5, FrozenLamp = 9 })[name]
		place(name, h, pos, rng:NextNumber(0, math.pi * 2))
	end
	folder.Parent = fz
end)
