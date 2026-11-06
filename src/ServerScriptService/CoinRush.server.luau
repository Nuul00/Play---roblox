-- Данж «Coin Rush». Портал в Meadow: раз в день бесплатно, дальше — ключ за монеты (цена растёт
-- с игроком). Забег — личный (у каждого свой экземпляр карты): 3 комнаты по таймеру, в каждой
-- монеты (дороже от комнаты к комнате) и вращающиеся лазеры (удар — минус 15% собранного).
-- Комната 4 — Хранилище: если собрано не меньше порога, оно открывается: награда ×2 и лут
-- (зелья, 3% — эксклюзив Vault Golem). Монеты зачисляются в конце. Всё решает сервер.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local Worlds = require(ReplicatedStorage:WaitForChild("WorldsConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))

local R = {}
R.ORIGIN = Vector3.new(-6000, 60, 0)
R.SLOT = 600 -- шаг между экземплярами забегов по X
R.ROOM = 96 -- размер комнаты
R.ROOMS = {
	{ Name = "THE MINT", Coins = 60, Value = 0.5, Lasers = 0, Time = 25, Floor = Color3.fromRGB(70, 60, 90), Glow = Color3.fromRGB(255, 200, 70) },
	{ Name = "LASER HALL", Coins = 80, Value = 0.75, Lasers = 2, Speed = 0.6, Time = 25, Floor = Color3.fromRGB(45, 50, 80), Glow = Color3.fromRGB(90, 200, 255) },
	{ Name = "GOLD STORM", Coins = 100, Value = 1, Lasers = 3, Speed = 0.9, Time = 25, Floor = Color3.fromRGB(80, 40, 50), Glow = Color3.fromRGB(255, 90, 120) },
}
R.VAULT_TIME = 12
R.VAULT_NEED = 0.55 -- доля от всех монет забега (в «весе»), чтобы открыть хранилище
R.HIT_LOSS = 0.15
R.KEY_COINS = 80 -- ключ стоит столько «монет» лучшего мира игрока
R.COOLDOWN = 120
R.PORTAL = { Pos = Vector3.new(-38, 0, 186), Face = Vector3.new(0, 0, 186) } -- свободная поляна слева от спавна

local remote = Instance.new("RemoteEvent")
remote.Name = "CoinRushEvent"
remote.Parent = ReplicatedStorage

local SHORT = { ["Meadow Isles"] = "island", ["Neon District"] = "neon", ["Sky Isles"] = "sky", ["Frozen Peaks"] = "frozen", ["Magma Volcano"] = "volcano", ["Cosmic Galaxy"] = "galaxy" }
local function bestWorld(p): string
	local best = "Meadow Isles"
	for _, w in ipairs(Worlds.Worlds) do
		if w.Open and SHORT[w.Id] and ((w.Cost or 0) <= 0 or p:GetAttribute(Worlds.UnlockKey(w.Id))) then
			best = w.Id
		end
	end
	return best
end
local function coinWorth(p): number
	local sig = ServerStorage:FindFirstChild("ServerSignals")
	local f = sig and sig:FindFirstChild("CoinWorth")
	if f then
		local ok, v = pcall(function()
			return f:Invoke(p, bestWorld(p))
		end)
		if ok and type(v) == "number" and v == v and v > 0 then
			return v
		end
	end
	return 1
end
local function today(): number
	return math.floor(os.time() / 86400)
end
function R.KeyCost(p): number
	return math.max(500, math.floor(coinWorth(p) * R.KEY_COINS))
end
local function notify(p, text, ok)
	local fb = ReplicatedStorage:FindFirstChild("GameFeedback")
	if fb then
		fb:FireClient(p, text, ok or false)
	end
end

-- ===== строим карту (один шаблон, клон на каждый забег) =====
local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end
local function roomCenter(i: number): Vector3
	return Vector3.new(0, 0, (i - 1) * (R.ROOM + 40))
end
local function buildTemplate(): Model
	local m = Instance.new("Model")
	m.Name = "CoinRushTemplate"
	local S = R.ROOM
	local rooms = table.clone(R.ROOMS)
	table.insert(rooms, { Name = "THE VAULT", Floor = Color3.fromRGB(60, 45, 25), Glow = Color3.fromRGB(255, 215, 90), Vault = true })
	for i, def in ipairs(rooms) do
		local c = roomCenter(i)
		local room = Instance.new("Model")
		room.Name = "Room" .. i
		room.Parent = m
		local size = def.Vault and 64 or S
		part(room, "Floor", Vector3.new(size, 2, size), CFrame.new(c - Vector3.new(0, 1, 0)), def.Floor, Enum.Material.Slate)
		-- узор пола: светящиеся линии сетки
		for k = -2, 2 do
			part(room, "Line", Vector3.new(size, 0.1, 0.25), CFrame.new(c + Vector3.new(0, 0.05, k * size / 5)), def.Glow, Enum.Material.Neon, { CanCollide = false, Transparency = 0.7 })
			part(room, "Line", Vector3.new(0.25, 0.1, size), CFrame.new(c + Vector3.new(k * size / 5, 0.05, 0)), def.Glow, Enum.Material.Neon, { CanCollide = false, Transparency = 0.7 })
		end
		-- стены с неоновой полосой и колоннами по углам
		for _, side in ipairs({ { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
			local along = side[1] == 0
			local wsize = along and Vector3.new(size + 4, 18, 2) or Vector3.new(2, 18, size + 4)
			local pos = c + Vector3.new(side[1] * (size / 2 + 1), 9, side[2] * (size / 2 + 1))
			part(room, "Wall", wsize, CFrame.new(pos), Color3.fromRGB(35, 30, 50), Enum.Material.Slate)
			part(room, "WallGlow", along and Vector3.new(size, 0.6, 2.2) or Vector3.new(2.2, 0.6, size), CFrame.new(pos + Vector3.new(0, 3, 0)), def.Glow, Enum.Material.Neon, { CanCollide = false })
			part(room, "Cap", along and Vector3.new(size + 6, 1, 3) or Vector3.new(3, 1, size + 6), CFrame.new(pos + Vector3.new(0, 9.5, 0)), Color3.fromRGB(200, 160, 70), Enum.Material.Metal)
		end
		-- невидимый потолок-стена, чтобы не перепрыгнуть
		for _, side in ipairs({ { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
			local along = side[1] == 0
			part(room, "Barrier", along and Vector3.new(size + 4, 60, 2) or Vector3.new(2, 60, size + 4), CFrame.new(c + Vector3.new(side[1] * (size / 2 + 1), 48, side[2] * (size / 2 + 1))), Color3.new(1, 1, 1), nil, { Transparency = 1, CastShadow = false, CanQuery = false })
		end
		for _, q in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
			local pc = c + Vector3.new(q[1] * (size / 2 - 3), 10, q[2] * (size / 2 - 3))
			part(room, "Pillar", Vector3.new(5, 20, 5), CFrame.new(pc), Color3.fromRGB(55, 45, 75), Enum.Material.Marble)
			local orb = part(room, "Orb", Vector3.new(3, 3, 3), CFrame.new(pc + Vector3.new(0, 11.5, 0)), def.Glow, Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
			local l = Instance.new("PointLight")
			l.Color = def.Glow
			l.Range = 40
			l.Brightness = 1.6
			l.Parent = orb
		end
		-- центральная «люстра»: золотое кольцо под потолком и сильный свет на всю комнату
		local lamp = part(room, "Lamp", Vector3.new(0.6, size * 0.35, size * 0.35), CFrame.new(c + Vector3.new(0, 26, 0)) * CFrame.Angles(0, 0, math.rad(90)), def.Glow, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false, Transparency = 0.2 })
		local big = Instance.new("PointLight")
		big.Color = def.Glow:Lerp(Color3.new(1, 1, 1), 0.5)
		big.Range = 60
		big.Brightness = 2.2
		big.Shadows = false
		big.Parent = lamp
		for _, q in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local wl = Instance.new("PointLight")
			wl.Color = def.Glow
			wl.Range = 40
			wl.Brightness = 1.2
			wl.Parent = part(room, "WallLamp", Vector3.new(1.5, 1.5, 1.5), CFrame.new(c + Vector3.new(q[1] * (size / 2 - 1), 12, q[2] * (size / 2 - 1))), def.Glow, Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
		end
		local spawn = part(room, "Spawn", Vector3.new(6, 0.2, 6), CFrame.new(c + Vector3.new(0, 0.1, -size / 2 + 8)), def.Glow, Enum.Material.Neon, { CanCollide = false, Transparency = 0.4 })
		spawn:SetAttribute("Room", i)
		if def.Vault then
			-- хранилище: большой сундук-сейф с замком
			local vault = Instance.new("Model")
			vault.Name = "Vault"
			vault.Parent = room
			local vc = c + Vector3.new(0, 0, 12)
			part(vault, "Base", Vector3.new(22, 2, 16), CFrame.new(vc + Vector3.new(0, 1, 0)), Color3.fromRGB(120, 80, 30), Enum.Material.Wood)
			part(vault, "Body", Vector3.new(20, 10, 14), CFrame.new(vc + Vector3.new(0, 7, 0)), Color3.fromRGB(150, 100, 40), Enum.Material.Wood)
			local lid = part(vault, "Lid", Vector3.new(20.4, 4, 14.4), CFrame.new(vc + Vector3.new(0, 14, 0)), Color3.fromRGB(170, 115, 45), Enum.Material.Wood)
			lid:SetAttribute("Hinge", true)
			for _, x in ipairs({ -8, 0, 8 }) do
				part(vault, "Band", Vector3.new(1.4, 14.6, 14.8), CFrame.new(vc + Vector3.new(x, 8.5, 0)), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
			end
			part(vault, "Lock", Vector3.new(4, 5, 1.5), CFrame.new(vc + Vector3.new(0, 10, -7.6)), Color3.fromRGB(255, 220, 90), Enum.Material.Metal)
			local zone = part(room, "VaultZone", Vector3.new(0.3, 22, 22), CFrame.new(c + Vector3.new(0, 0.1, -6)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 215, 90), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false, Transparency = 0.5 })
			zone:SetAttribute("VaultZone", true)
		end
	end
	return m
end
local template = buildTemplate()
template.Parent = ServerStorage

-- ===== портал в Meadow =====
local world = workspace:WaitForChild("CoinSpeedWorld")
local function groundAt(pos: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	local hit = workspace:Raycast(pos + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), params)
	return hit and hit.Position.Y or 0
end
local portal = Instance.new("Model")
portal.Name = "CoinRushPortal"
do
	local gy = groundAt(R.PORTAL.Pos)
	local base = Vector3.new(R.PORTAL.Pos.X, gy, R.PORTAL.Pos.Z)
	local face = CFrame.lookAt(base, Vector3.new(R.PORTAL.Face.X, gy, R.PORTAL.Face.Z))
	local GOLD, DARK = Color3.fromRGB(255, 200, 60), Color3.fromRGB(45, 35, 70)
	part(portal, "Step", Vector3.new(18, 1, 8), face * CFrame.new(0, 0.5, 0), DARK, Enum.Material.Slate)
	for _, x in ipairs({ -7, 7 }) do
		part(portal, "Post", Vector3.new(2.5, 16, 2.5), face * CFrame.new(x, 8.5, 0), DARK, Enum.Material.Slate)
		part(portal, "PostGlow", Vector3.new(2.7, 0.5, 2.7), face * CFrame.new(x, 14, 0), GOLD, Enum.Material.Neon)
	end
	part(portal, "Top", Vector3.new(17, 2.5, 3), face * CFrame.new(0, 17.5, 0), DARK, Enum.Material.Slate)
	local field = part(portal, "Field", Vector3.new(11.5, 15, 0.4), face * CFrame.new(0, 8.5, 0), GOLD, Enum.Material.ForceField, { CanCollide = false, Transparency = 0.15 })
	-- воронка: искры затягиваются в портал, золотой свет, кольцо по контуру
	local swirl = Instance.new("ParticleEmitter")
	swirl.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	swirl.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 240, 180))
	swirl.LightEmission = 1
	swirl.Rate = 40
	swirl.Lifetime = NumberRange.new(1, 1.6)
	swirl.Speed = NumberRange.new(1, 3)
	swirl.SpreadAngle = Vector2.new(180, 180)
	swirl.RotSpeed = NumberRange.new(-180, 180)
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	swirl.Parent = field
	local glow = Instance.new("PointLight")
	glow.Color = GOLD
	glow.Range = 24
	glow.Brightness = 2.5
	glow.Parent = field
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		part(portal, "Rim", Vector3.new(0.9, 0.9, 0.9), face * CFrame.new(math.cos(a) * 6.2, 8.5 + math.sin(a) * 7.4, 0), GOLD, Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
	end
	for _, x in ipairs({ -10.5, 10.5 }) do
		part(portal, "CoinPile", Vector3.new(1.2, 3, 3), face * CFrame.new(x, 1.6, 1) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		part(portal, "CoinPile", Vector3.new(2.4, 0.5, 2.4), face * CFrame.new(x, 2.4, 1), Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
	end
	local sign = part(portal, "Sign", Vector3.new(18, 5, 0.6), face * CFrame.new(0, 21.5, 0), DARK, Enum.Material.SmoothPlastic)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.LightInfluence = 0
	sg.PixelsPerStud = 30
	sg.Parent = sign
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "💰 COIN RUSH"
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = GOLD
	t.Parent = sg
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Parent = t
	local sg2 = sg:Clone()
	sg2.Face = Enum.NormalId.Front
	sg2.Parent = sign
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Enter Coin Rush"
	prompt.ObjectText = "Dungeon"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = field
	portal:SetAttribute("Spawn", face * CFrame.new(0, 4, -8))
	portal.Parent = world
	R.Prompt = prompt
	R.ReturnCF = face * CFrame.new(0, 4, -10) * CFrame.Angles(0, math.pi, 0)
end

-- ===== забеги =====
local runs = {} -- [player] = run
local slots = {} -- [index] = true (занят)
local lastRun = {}
local function takeSlot(): number
	local i = 1
	while slots[i] do
		i += 1
	end
	slots[i] = true
	return i
end

local function tp(p, cf: CFrame)
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	p:SetAttribute("ServerTP", os.clock())
	root.AssemblyLinearVelocity = Vector3.zero
	pcall(function()
		p:RequestStreamAroundAsync(cf.Position, 2)
	end)
	char:PivotTo(cf)
end

local function spawnCoins(run, i: number)
	local def = R.ROOMS[i]
	local c = run.offset + roomCenter(i)
	local folder = Instance.new("Folder")
	folder.Name = "Coins" .. i
	folder.Parent = run.model
	run.coins = {}
	local rng = Random.new()
	local half = R.ROOM / 2 - 8
	for n = 1, def.Coins do
		-- часть монет — дорогие золотые слитки (×3)
		local big = rng:NextNumber() < 0.12
		local pos = c + Vector3.new(rng:NextNumber(-half, half), big and 2.2 or 1.8, rng:NextNumber(-half + 10, half))
		local coin = part(folder, big and "Bar" or "Coin", big and Vector3.new(1.4, 3, 3) or Vector3.new(0.5, 2.6, 2.6), CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), big and Color3.fromRGB(255, 170, 40) or Color3.fromRGB(255, 215, 70), Enum.Material.Neon, { Shape = big and Enum.PartType.Block or Enum.PartType.Cylinder, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		coin:SetAttribute("RushCoin", true)
		table.insert(run.coins, { part = coin, value = def.Value * (big and 3 or 1) })
	end
	-- лазеры: вращающиеся балки через центр комнаты
	run.lasers = {}
	for k = 1, def.Lasers do
		local beam = part(folder, "Laser", Vector3.new(R.ROOM - 10, 1.2, 1.2), CFrame.new(c + Vector3.new(0, 2.5, 0)), Color3.fromRGB(255, 40, 70), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		local hub = part(folder, "LaserHub", Vector3.new(4, 5, 4), CFrame.new(c + Vector3.new(0, 2.5, 0)), Color3.fromRGB(60, 20, 30), Enum.Material.Metal, { CanCollide = true })
		hub.Shape = Enum.PartType.Cylinder
		hub.CFrame = CFrame.new(c + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		table.insert(run.lasers, { part = beam, center = c + Vector3.new(0, 2.5, 0), angle = (k - 1) * math.pi / def.Lasers, speed = def.Speed * (k % 2 == 0 and -1 or 1) })
	end
	run.totalWeight += def.Coins * def.Value * 1.24 -- 12% слитков ×3 → средний вес монеты 1.24
end

local function send(run, kind, data)
	if run.player.Parent == Players then
		remote:FireClient(run.player, kind, data)
	end
end

local function finish(run, reason: string?)
	if run.done then
		return
	end
	run.done = true
	local p = run.player
	runs[p] = nil
	p:SetAttribute("InRush", nil)
	local reward = math.floor(run.bank * run.worth)
	local loot = {}
	if run.vaultOpen then
		reward *= 2
		local rng = Random.new()
		if rng:NextNumber() < 0.45 then
			local names = ShopConfig.PotionOrder
			local name = names[rng:NextInteger(1, #names)]
			p:SetAttribute("Potion" .. name, (p:GetAttribute("Potion" .. name) or 0) + 1)
			table.insert(loot, ShopConfig.Potions[name].Icon .. " " .. ShopConfig.Potions[name].Name)
		end
		if rng:NextNumber() < 0.03 then
			local id = Config.VaultPets and Config.VaultPets[SHORT[bestWorld(p)] or "island"]
			if id then
				local count = (p:GetAttribute("PetOwned" .. id) or 0) + 1
				p:SetAttribute("PetOwned" .. id, count)
				pcall(PlayerSystems.OnHatched, p, id)
				table.insert(loot, "🗿 " .. Config.Pets[id].Name .. " (EXCLUSIVE)")
				local hatched = ReplicatedStorage:FindFirstChild("GameHatched")
				task.delay(2.5, function()
					if hatched and p.Parent == Players then
						hatched:FireClient(p, { { Pet = id, Count = count, Deleted = false, Forced = false } }, Config.Pets[id].EggId)
					end
				end)
			end
		end
	end
	local stats = p:FindFirstChild("leaderstats")
	if stats and reward > 0 then
		stats.Coins.Value += reward
		p:SetAttribute("LifetimeEarned", (p:GetAttribute("LifetimeEarned") or 0) + reward)
	end
	p:SetAttribute("Save_RushRuns", (p:GetAttribute("Save_RushRuns") or 0) + 1)
	if reward > (p:GetAttribute("Save_RushBest") or 0) then
		p:SetAttribute("Save_RushBest", reward)
	end
	send(run, "result", { Coins = reward, Vault = run.vaultOpen == true, Loot = loot, Reason = reason, Hits = run.hits })
	task.delay(0.2, function()
		if p.Parent == Players then
			tp(p, R.ReturnCF)
		end
		run.model:Destroy()
		slots[run.slot] = nil
	end)
end

local function startRoom(run, i: number)
	run.room = i
	if run.model:FindFirstChild("Coins" .. (i - 1)) then
		run.model["Coins" .. (i - 1)]:Destroy()
	end
	local spawnCF = CFrame.new(run.offset + roomCenter(i) + Vector3.new(0, 4, -R.ROOM / 2 + 8))
	if i <= #R.ROOMS then
		spawnCoins(run, i)
		run.ends = os.clock() + R.ROOMS[i].Time
		send(run, "room", { Room = i, Rooms = #R.ROOMS, Worth = run.worth, Name = R.ROOMS[i].Name, Ends = workspace:GetServerTimeNow() + R.ROOMS[i].Time, Total = #run.coins })
	else
		spawnCF = CFrame.new(run.offset + roomCenter(i) + Vector3.new(0, 4, -26))
		run.coins, run.lasers = {}, {}
		run.need = run.totalWeight * (RunService:IsStudio() and workspace:GetAttribute("RushVaultNeed") or R.VAULT_NEED) -- в Studio порог можно задать атрибутом
		run.ends = os.clock() + R.VAULT_TIME
		send(run, "vault", { Need = run.need, Have = run.bank, Ends = workspace:GetServerTimeNow() + R.VAULT_TIME, Worth = run.worth })
	end
	tp(run.player, spawnCF)
end

local function openVault(run)
	if run.vaultTried then
		return
	end
	run.vaultTried = true
	run.vaultOpen = run.bank >= run.need
	local lid = run.model:FindFirstChild("Lid", true)
	if run.vaultOpen and lid then
		-- крышка откидывается назад
		local hinge = lid.CFrame * CFrame.new(0, -2, 7.2)
		task.spawn(function()
			for k = 1, 20 do
				lid.CFrame = hinge * CFrame.Angles(math.rad(-5.5 * k), 0, 0) * CFrame.new(0, 2, -7.2)
				task.wait(0.02)
			end
		end)
	end
	send(run, "vaultResult", { Open = run.vaultOpen, Have = run.bank, Need = run.need })
	task.delay(run.vaultOpen and 3 or 2, function()
		finish(run)
	end)
end

local function startRun(p)
	local slot = takeSlot()
	local offset = R.ORIGIN + Vector3.new((slot - 1) * R.SLOT, 0, 0)
	local m = template:Clone()
	m.Name = "CoinRush_" .. p.UserId
	m:PivotTo(m:GetPivot() + offset)
	m.Parent = workspace
	local run = { player = p, slot = slot, offset = offset, model = m, bank = 0, totalWeight = 0, hits = 0, worth = coinWorth(p), lastHit = 0 }
	runs[p] = run
	p:SetAttribute("InRush", true)
	startRoom(run, 1)
end

R.Prompt.Triggered:Connect(function(p)
	if runs[p] or not p:GetAttribute("ProfileReady") then
		return
	end
	local now = os.clock()
	if lastRun[p] and now - lastRun[p] < R.COOLDOWN then
		notify(p, "Coin Rush recharging: " .. math.ceil(R.COOLDOWN - (now - lastRun[p])) .. " s")
		return
	end
	local free = (p:GetAttribute("Save_RushFreeDay") or -1) ~= today()
	if free then
		p:SetAttribute("Save_RushFreeDay", today())
	else
		local cost = R.KeyCost(p)
		local stats = p:FindFirstChild("leaderstats")
		if not stats or stats.Coins.Value < cost then
			notify(p, "Not enough coins for a Coin Rush key")
			return
		end
		stats.Coins.Value -= cost
	end
	lastRun[p] = now
	startRun(p)
end)

-- цена ключа для подсказки портала (обновляется раз в пару секунд)
task.spawn(function()
	while true do
		task.wait(2)
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("ProfileReady") then
				local free = (p:GetAttribute("Save_RushFreeDay") or -1) ~= today()
				p:SetAttribute("RushKeyCost", free and 0 or R.KeyCost(p))
			end
		end
	end
end)

-- главный цикл: сбор монет магнитом, лазеры, таймеры
local function segDist(pt: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local t = math.clamp((pt - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (pt - (a + ab * t)).Magnitude
end
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	for p, run in pairs(runs) do
		-- лазеры крутим каждый кадр (плавно), проверки — 20 раз в секунду
		for _, L in ipairs(run.lasers or {}) do
			L.angle += L.speed * dt
			L.part.CFrame = CFrame.new(L.center) * CFrame.Angles(0, L.angle, 0)
		end
	end
	if acc < 0.05 then
		return
	end
	acc = 0
	local now = os.clock()
	for p, run in pairs(runs) do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if p.Parent ~= Players or not root or not hum or hum.Health <= 0 then
			finish(run, "left")
		elseif not run.done then
			local pos = root.Position
			-- монеты
			local radius = (p:GetAttribute("MagnetRadius") or 6) + (p:GetAttribute("AbilMagnet") or 0) + 2
			local got = 0
			for k = #run.coins, 1, -1 do
				local c = run.coins[k]
				if (c.part.Position - pos).Magnitude <= radius then
					run.bank += c.value
					got += 1
					c.part:Destroy()
					table.remove(run.coins, k)
				end
			end
			if got > 0 then
				send(run, "bank", { Bank = run.bank, Left = #run.coins, Got = got })
			end
			-- лазеры
			for _, L in ipairs(run.lasers or {}) do
				local half = L.part.CFrame.RightVector * (L.part.Size.X / 2)
				if now - run.lastHit > 1.2 and math.abs(pos.Y - L.center.Y) < 4 and segDist(Vector3.new(pos.X, L.center.Y, pos.Z), L.center - half, L.center + half) < 2.2 then
					run.lastHit = now
					run.hits += 1
					local lost = run.bank * R.HIT_LOSS
					run.bank -= lost
					root.AssemblyLinearVelocity = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(L.center.X, 0, L.center.Z)).Unit * 60 + Vector3.new(0, 35, 0)
					send(run, "hit", { Lost = lost, Bank = run.bank })
				end
			end
			-- хранилище: встал в круг — проверка
			if run.room > #R.ROOMS and not run.vaultTried then
				local zone = run.model:FindFirstChild("VaultZone", true)
				if zone and (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(zone.Position.X, 0, zone.Position.Z)).Magnitude < 11 then
					openVault(run)
				end
			end
			-- таймер или все монеты собраны
			if not run.vaultTried and (now >= run.ends or (run.room <= #R.ROOMS and #run.coins == 0)) then
				if run.room < #R.ROOMS + 1 then
					startRoom(run, run.room + 1)
				else
					openVault(run)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	local run = runs[p]
	if run then
		finish(run, "left")
	end
	lastRun[p] = nil
end)
