-- Данж «Coin Rush». Портал в Meadow: раз в день бесплатно, дальше — ключ за монеты (цена растёт
-- с игроком). Забег — личный (у каждого свой экземпляр карты): 3 комнаты по таймеру, в каждой
-- монеты (дороже от комнаты к комнате) и вращающиеся лазеры (удар — минус 15% собранного).
-- Комната 4 — Хранилище: если собрано не меньше порога, оно открывается: награда ×2 и лут
-- (зелья, 3% — эксклюзив Vault Golem). Монеты зачисляются в конце. Всё решает сервер.
-- ЭТАЖИ 1–10 (Save_RushFloor): каждая победа над боссом открывает следующий этаж — монеты дороже,
-- лазеры и лава быстрее, лут лучше. ЗВЁЗДЫ за забег: 1 — дошёл, 2 — победил босса, 3 — без ударов (≤1).
-- БОСС в хранилище: Vault Golem (3D-модель питомца, увеличенная) бьёт по полу волнами-кольцами
-- (перепрыгнуть). РЮКЗАК-ПЕРЕРАБОТЧИК: на спине у игрока рюкзак, по трубке в магнит течёт золото —
-- собранные в комнатах монеты становятся патронами (сами монеты не тратятся). У босса игрок
-- зажимает ЛКМ / кнопку FIRE — магнит стреляет золотыми пулями с автоприцелом. Патроны
-- понемногу восстанавливаются, кристаллы на арене дают +6.
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
-- Комнаты — испытания (магнит в данже НЕ работает: монету надо задеть, радиус R.PICKUP):
--  1 COIN CHASE — монеты появляются волнами и через Life секунд исчезают (мигают перед этим);
--  2 LASER HALL — вращающиеся лазеры + низкий лазер-«метла» через всю комнату: его надо перепрыгнуть;
--  3 LAVA FLOOR — плитки пола загораются оранжевым (предупреждение) и становятся лавой.
R.ROOMS = {
	{ Name = "COIN CHASE", Hint = "Coins vanish fast — grab them!", Mode = "waves", Coins = 64, Wave = 8, WaveEvery = 2.6, Life = 4.2, Value = 0.5, Lasers = 0, Time = 25, Floor = Color3.fromRGB(70, 60, 90), Glow = Color3.fromRGB(255, 200, 70) },
	{ Name = "LASER HALL", Hint = "Dodge the beams — JUMP over the low laser!", Coins = 70, Value = 0.75, Lasers = 2, Speed = 0.7, Sweep = true, Time = 25, Floor = Color3.fromRGB(45, 50, 80), Glow = Color3.fromRGB(90, 200, 255) },
	{ Name = "LAVA FLOOR", Hint = "Red tiles burn — keep moving!", Coins = 80, Value = 1, Lasers = 0, Lava = true, Time = 25, Floor = Color3.fromRGB(80, 40, 50), Glow = Color3.fromRGB(255, 90, 120) },
}
R.PICKUP = 3.8 -- радиус подбора монет в данже (вместо магнита)
R.SPEED_CAP = 26 -- скорость в данже не выше (прокачанные не пролетают комнату за секунды)
R.VAULT_TIME = 12
R.VAULT_NEED = 0.55 -- доля от всех монет забега (в «весе»), чтобы открыть хранилище
R.HIT_LOSS = 0.15
R.KEY_COINS = 80 -- ключ стоит столько «монет» лучшего мира игрока
R.COOLDOWN = 120
R.FLOORS = 10
R.BOSS_TIME = 32
function R.Floor(p): number
	return math.clamp(math.floor(tonumber(p:GetAttribute("Save_RushFloor")) or 1), 1, R.FLOORS)
end
-- поляна справа от главной дороги перед рядом яиц (видно со спавна), лицом к дороге.
-- Слева на той же высоте стоит UpgradeShop (его детали не видны запросам CanQuery=false).
-- Yaw — поворот модели Tripo, если её «лицо» смотрит не туда.
R.PORTAL = { Pos = Vector3.new(44, 0, 96), Face = Vector3.new(0, 0, 96), Yaw = 0, Size = 34 }

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
-- модель Tripo (ReplicatedStorage.TripoProps), отмасштабированная по наибольшей стороне
local function tripo(name: string, size: number, parent: Instance, cf: CFrame): Model?
	local src
	for _, folderName in ipairs({ "TripoProps", "TripoEggs" }) do
		local f = ReplicatedStorage:FindFirstChild(folderName)
		src = src or (f and f:FindFirstChild(name))
	end
	if not src then
		return nil
	end
	local m = src:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanTouch, d.CastShadow = true, false, false, true
		end
	end
	local _, ext = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * size / math.max(ext.X, ext.Y, ext.Z, 0.01))
	local bcf, bsz = m:GetBoundingBox()
	local off = m:GetPivot():ToObjectSpace(bcf)
	m:PivotTo(cf * CFrame.new(0, bsz.Y / 2, 0) * off:Inverse())
	m.Parent = parent
	return m
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
		part(room, "Floor", Vector3.new(size, 2, size), CFrame.new(c - Vector3.new(0, 1, 0)), def.Floor, Enum.Material.Marble)
		-- узор пола: светящиеся линии сетки
		for k = -2, 2 do
			part(room, "Line", Vector3.new(size, 0.1, 0.25), CFrame.new(c + Vector3.new(0, 0.05, k * size / 5)), def.Glow, Enum.Material.Neon, { CanCollide = false, Transparency = 0.82 })
			part(room, "Line", Vector3.new(0.25, 0.1, size), CFrame.new(c + Vector3.new(k * size / 5, 0.05, 0)), def.Glow, Enum.Material.Neon, { CanCollide = false, Transparency = 0.82 })
		end
		-- стены с неоновой полосой и колоннами по углам
		for _, side in ipairs({ { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
			local along = side[1] == 0
			local wsize = along and Vector3.new(size + 4, 18, 2) or Vector3.new(2, 18, size + 4)
			local pos = c + Vector3.new(side[1] * (size / 2 + 1), 9, side[2] * (size / 2 + 1))
			part(room, "Wall", wsize, CFrame.new(pos), Color3.fromRGB(70, 48, 58), Enum.Material.Brick)
			part(room, "WallGlow", along and Vector3.new(size, 0.6, 2.2) or Vector3.new(2.2, 0.6, size), CFrame.new(pos + Vector3.new(0, 3, 0)), def.Glow, Enum.Material.Neon, { CanCollide = false })
			part(room, "Cap", along and Vector3.new(size + 6, 1, 3) or Vector3.new(3, 1, size + 6), CFrame.new(pos + Vector3.new(0, 9.5, 0)), Color3.fromRGB(200, 160, 70), Enum.Material.Metal)
		end
		-- потолок: сокровищница под землёй, неба не видно
		part(room, "Ceiling", Vector3.new(size + 6, 2, size + 6), CFrame.new(c + Vector3.new(0, 31, 0)), Color3.fromRGB(40, 30, 45), Enum.Material.Slate)
		for _, side in ipairs({ { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
			local along = side[1] == 0
			part(room, "HighWall", along and Vector3.new(size + 4, 12, 2) or Vector3.new(2, 12, size + 4), CFrame.new(c + Vector3.new(side[1] * (size / 2 + 1), 24.5, side[2] * (size / 2 + 1))), Color3.fromRGB(60, 42, 52), Enum.Material.Brick)
		end
		-- красная ковровая дорожка от входа и знамёна на боковых стенах
		part(room, "Carpet", Vector3.new(9, 0.12, size - 6), CFrame.new(c + Vector3.new(0, 0.06, 0)), Color3.fromRGB(150, 25, 45), Enum.Material.Fabric, { CanCollide = false })
		for _, x in ipairs({ -5, 5 }) do
			part(room, "CarpetTrim", Vector3.new(0.7, 0.14, size - 6), CFrame.new(c + Vector3.new(x, 0.07, 0)), Color3.fromRGB(255, 200, 70), Enum.Material.Metal, { CanCollide = false })
		end
		for _, sx in ipairs({ -1, 1 }) do
			for _, z in ipairs({ -size / 4, 0, size / 4 }) do
				local bpos = c + Vector3.new(sx * (size / 2 - 0.3), 17, z)
				local banner = part(room, "Banner", Vector3.new(0.3, 12, 7), CFrame.new(bpos), def.Glow:Lerp(Color3.fromRGB(120, 20, 40), 0.6), Enum.Material.Fabric, { CanCollide = false })
				part(room, "BannerRod", Vector3.new(0.6, 0.6, 8), CFrame.new(bpos + Vector3.new(0, 6.2, 0)), Color3.fromRGB(255, 200, 70), Enum.Material.Metal, { CanCollide = false })
				-- герб: золотой ромб с камнем и бахрома снизу
				part(room, "Emblem", Vector3.new(0.4, 3.2, 3.2), CFrame.new(bpos + Vector3.new(-sx * 0.2, 1, 0)) * CFrame.Angles(math.rad(45), 0, 0), Color3.fromRGB(255, 200, 70), Enum.Material.Metal, { CanCollide = false })
				part(room, "Gem", Vector3.new(0.5, 1.2, 1.2), CFrame.new(bpos + Vector3.new(-sx * 0.35, 1, 0)), def.Glow, Enum.Material.Neon, { CanCollide = false, Shape = Enum.PartType.Ball })
				part(room, "Fringe", Vector3.new(0.4, 0.6, 7), CFrame.new(bpos + Vector3.new(-sx * 0.05, -6, 0)), Color3.fromRGB(255, 200, 70), Enum.Material.Fabric, { CanCollide = false })
			end
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
			l.Range = 30
			l.Brightness = 0.7
			l.Parent = orb
		end
		-- центральная «люстра»: золотое кольцо под потолком и сильный свет на всю комнату
		local lamp = part(room, "Lamp", Vector3.new(0.6, size * 0.35, size * 0.35), CFrame.new(c + Vector3.new(0, 26, 0)) * CFrame.Angles(0, 0, math.rad(90)), def.Glow, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false, Transparency = 0.2 })
		local big = Instance.new("PointLight")
		big.Color = def.Glow:Lerp(Color3.new(1, 1, 1), 0.5)
		big.Range = 55
		big.Brightness = 0.9
		big.Shadows = false
		big.Parent = lamp
		for _, q in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local wl = Instance.new("PointLight")
			wl.Color = def.Glow
			wl.Range = 30
			wl.Brightness = 0.5
			wl.Parent = part(room, "WallLamp", Vector3.new(1.5, 1.5, 1.5), CFrame.new(c + Vector3.new(q[1] * (size / 2 - 1), 12, q[2] * (size / 2 - 1))), def.Glow, Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
		end
		-- сокровища по углам (Tripo): кучи золота и сундуки — комната выглядит как сокровищница
		local corners = { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
		for k, q in ipairs(corners) do
			local at = c + Vector3.new(q[1] * (size / 2 - 11), 0, q[2] * (size / 2 - 11))
			local face = CFrame.lookAt(at, c)
			if def.Vault or k <= 2 or i == 3 then
				local name = (k % 2 == 0) and "RushChest" or "RushGold"
				tripo(name, def.Vault and 10 or 8, room, face)
			end
		end
		local spawn = part(room, "Spawn", Vector3.new(6, 0.2, 6), CFrame.new(c + Vector3.new(0, 0.1, -size / 2 + 8)), def.Glow, Enum.Material.Neon, { CanCollide = false, Transparency = 0.4 })
		spawn:SetAttribute("Room", i)
		if def.Vault then
			-- хранилище: огромная круглая дверь сейфа (Tripo) в дальней стене, перед ней золотой круг
			local doorAt = c + Vector3.new(0, 0, size / 2 - 3)
			local door = tripo("RushVault", 26, room, CFrame.lookAt(doorAt, doorAt - Vector3.new(0, 0, 1)))
			if door then
				door.Name = "VaultDoor"
			else
				-- запасной вариант без модели: сундук-сейф из деталей
				local vault = Instance.new("Model")
				vault.Name = "VaultDoor"
				vault.Parent = room
				local vc = c + Vector3.new(0, 0, 12)
				part(vault, "Body", Vector3.new(20, 10, 14), CFrame.new(vc + Vector3.new(0, 6, 0)), Color3.fromRGB(150, 100, 40), Enum.Material.Wood)
				part(vault, "Lid", Vector3.new(20.4, 4, 14.4), CFrame.new(vc + Vector3.new(0, 13, 0)), Color3.fromRGB(170, 115, 45), Enum.Material.Wood)
				for _, x in ipairs({ -8, 0, 8 }) do
					part(vault, "Band", Vector3.new(1.4, 14.6, 14.8), CFrame.new(vc + Vector3.new(x, 7.5, 0)), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
				end
			end
			-- сияние за дверью (видно, когда она откроется)
			-- за дверью: тёплое мягкое сияние (слои от яркого центра к прозрачному краю) и сокровища
			for k, sz in ipairs({ 18, 13, 8 }) do
				part(room, "VaultGlowLayer", Vector3.new(sz, sz, 0.2), CFrame.new(doorAt + Vector3.new(0, 11, 2.4 - k * 0.3)), Color3.fromRGB(255, 170 + k * 20, 60 + k * 30), Enum.Material.Neon, { CanCollide = false, Transparency = 0.75 - k * 0.12 })
			end
			local glow = part(room, "VaultGlow", Vector3.new(1, 1, 1), CFrame.new(doorAt + Vector3.new(0, 11, 1)), Color3.fromRGB(255, 220, 120), Enum.Material.Neon, { CanCollide = false, Transparency = 1 })
			local gl = Instance.new("PointLight")
			gl.Color = Color3.fromRGB(255, 210, 110)
			gl.Range = 50
			gl.Brightness = 0
			gl.Name = "VaultLight"
			gl.Parent = glow
			local zone = part(room, "VaultZone", Vector3.new(0.3, 20, 20), CFrame.new(c + Vector3.new(0, 0.1, 10)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 215, 90), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false, Transparency = 0.5 })
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
	params.FilterDescendantsInstances = { world, workspace.Terrain } -- поверх пола местами лежит рельеф (Terrain)
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
	-- арка из Tripo (золотой вход в сокровищницу); без модели — простая арка из деталей
	local arch = tripo("RushPortal", R.PORTAL.Size, portal, face * CFrame.Angles(0, math.rad(R.PORTAL.Yaw), 0))
	local h, w
	if arch then
		arch.Name = "Arch"
		for _, d in ipairs(arch:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanCollide = false -- в арку можно зайти
			end
		end
		local _, sz = arch:GetBoundingBox()
		h, w = sz.Y, math.max(sz.X, sz.Z)
	else
		h, w = 18, 16
		for _, x in ipairs({ -7, 7 }) do
			part(portal, "Post", Vector3.new(2.5, 16, 2.5), face * CFrame.new(x, 8.5, 0), DARK, Enum.Material.Slate)
		end
		part(portal, "Top", Vector3.new(17, 2.5, 3), face * CFrame.new(0, 17.5, 0), DARK, Enum.Material.Slate)
	end
	-- портал в проёме арки: «капсула» точно по форме проёма (измерено: ~9.8 ст шириной, прямые края
	-- до ~12 ст и полукруглый верх). Поверхность — SurfaceGui со слоями градиентов (клиент их крутит:
	-- переливы и спираль), светлое ядро, мерцающие искорки; по краю проёма — светящийся ободок;
	-- искры вылетают из портала навстречу игроку.
	-- поверхность чуть больше проёма: края уходят за раму арки, без щелей по своду
	local OW = arch and 11.4 or 10 -- ширина (проём ~9.8)
	local OR = OW / 2
	local OS = arch and 13.2 or 10 -- высота прямых краёв (дальше — полукруг до ~18.9, свод арки ~17)
	local surfH = OS + OR + OR -- снизу запас под землю, чтобы нижнее скругление спряталось
	local surfCF = face * CFrame.new(0, OS + OR - surfH / 2, 0)
	local field = part(portal, "Field", Vector3.new(OW, surfH, 0.2), surfCF, GOLD, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false, Transparency = 1, CastShadow = false })
	field:SetAttribute("PortalSurface", true)
	local PPS = 24
	for _, faceId in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Name = "PortalGui"
		sg.Face = faceId
		sg.PixelsPerStud = PPS
		sg.LightInfluence = 0
		pcall(function()
			sg.Brightness = 1.15
		end)
		sg.ClipsDescendants = true
		sg.Parent = field
		local function layer(name, scale, color, transp, rot)
			local f = Instance.new("Frame")
			f.Name = name
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.Size = UDim2.fromScale(scale, scale)
			f.BackgroundColor3 = Color3.new(1, 1, 1)
			f.BorderSizePixel = 0
			f.Parent = sg
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, math.floor(OW * PPS * scale / 2))
			c.Parent = f
			local g = Instance.new("UIGradient")
			g.Color = color
			g.Transparency = transp
			g.Rotation = rot
			g.Parent = f
			return f
		end
		-- 1) основа: тёплое золото с тёмно-оранжевой глубиной к краям
		layer("Base", 1, ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 70, 20)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 160, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 110)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 160, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 70, 20)),
		}), NumberSequence.new(0.05), 0)
		-- 2) спиральные полосы света (вращаются)
		layer("Bands", 1, ColorSequence.new(Color3.fromRGB(255, 250, 220)), NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.55), NumberSequenceKeypoint.new(0.25, 1),
			NumberSequenceKeypoint.new(0.45, 0.5), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(0.75, 0.55),
			NumberSequenceKeypoint.new(0.85, 1), NumberSequenceKeypoint.new(1, 1),
		}), 30)
		-- 3) второй слой полос навстречу — даёт «закрутку»
		layer("Bands2", 1, ColorSequence.new(Color3.fromRGB(255, 200, 90)), NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(0.4, 1),
			NumberSequenceKeypoint.new(0.6, 0.6), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1),
		}), -60)
		-- 4) светлое ядро в глубине
		layer("Core", 0.55, ColorSequence.new(Color3.fromRGB(255, 255, 240)), NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1),
		}), 90)
		-- 5) искорки
		for k = 1, 9 do
			local sp = Instance.new("ImageLabel")
			sp.Name = "Twinkle"
			sp.BackgroundTransparency = 1
			sp.Image = "rbxasset://textures/particles/sparkles_main.dds"
			sp.AnchorPoint = Vector2.new(0.5, 0.5)
			sp.Position = UDim2.fromScale(0.2 + (k * 0.37) % 0.6, 0.12 + (k * 0.23) % 0.62)
			sp.Size = UDim2.fromOffset(34, 34)
			sp.ImageColor3 = Color3.fromRGB(255, 250, 220)
			sp:SetAttribute("Phase", k * 0.7)
			sp.Parent = sg
		end
	end
	-- искры из портала навстречу и лёгкая золотая дымка у порога
	local swirl = Instance.new("ParticleEmitter")
	swirl.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	swirl.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 245, 200))
	swirl.LightEmission = 1
	swirl.Rate = 35
	swirl.Lifetime = NumberRange.new(1, 1.8)
	swirl.Speed = NumberRange.new(1.5, 4)
	swirl.SpreadAngle = Vector2.new(25, 25)
	swirl.EmissionDirection = Enum.NormalId.Front
	swirl.Acceleration = Vector3.new(0, 1.5, 0)
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	swirl.Parent = field
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(255, 215, 120))
	mist.LightEmission = 0.6
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.75), NumberSequenceKeypoint.new(1, 1) })
	mist.Rate = 6
	mist.Lifetime = NumberRange.new(2, 3)
	mist.Speed = NumberRange.new(0.5, 1.2)
	mist.Size = NumberSequence.new(3, 6)
	mist.EmissionDirection = Enum.NormalId.Front
	local glow = Instance.new("PointLight")
	glow.Color = GOLD
	glow.Range = 28
	glow.Brightness = 2
	glow.Parent = field
	mist.Parent = part(portal, "MistAnchor", Vector3.new(OW, 0.2, 0.2), face * CFrame.new(0, 0.6, -0.5), GOLD, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	-- живые факелы и сундуки модели арки (точки подобраны по виду в Play: факелы ±11.7 на высоте 14,
	-- сундуки ±11.4 сверху ~6.4; оси — как у арки). Огонь, угольки и свет — у факелов; золотые искры
	-- у сундуков, а клиент периодически «выстреливает» из них монеты (крышка — часть меша).
	if arch then
		for _, sx in ipairs({ -1, 1 }) do
			local torch = part(portal, "TorchFire", Vector3.new(0.4, 0.4, 0.4), face * CFrame.new(sx * 11.7, 14.0, 0), GOLD, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
			local fire = Instance.new("Fire")
			fire.Size = 2.6
			fire.Heat = 9
			fire.Color = Color3.fromRGB(255, 140, 30)
			fire.SecondaryColor = Color3.fromRGB(255, 220, 80)
			fire.Parent = torch
			local embers = Instance.new("ParticleEmitter")
			embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 90, 20))
			embers.LightEmission = 1
			embers.Rate = 10
			embers.Lifetime = NumberRange.new(0.8, 1.5)
			embers.Speed = NumberRange.new(2, 4)
			embers.SpreadAngle = Vector2.new(20, 20)
			embers.Acceleration = Vector3.new(0, 3, 0)
			embers.Size = NumberSequence.new(0.25, 0)
			embers.Parent = torch
			local tl = Instance.new("PointLight")
			tl.Name = "TorchLight"
			tl.Color = Color3.fromRGB(255, 150, 60)
			tl.Range = 16
			tl.Brightness = 2
			tl.Parent = torch
			torch:SetAttribute("Torch", true)
			local chest = part(portal, "ChestGlow", Vector3.new(3.5, 1, 3), face * CFrame.new(sx * 11.4, 6.4, 0.5), GOLD, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
			chest:SetAttribute("Chest", sx)
			local glit = Instance.new("ParticleEmitter")
			glit.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			glit.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 255, 230))
			glit.LightEmission = 1
			glit.Rate = 7
			glit.Lifetime = NumberRange.new(0.6, 1.1)
			glit.Speed = NumberRange.new(0.5, 2)
			glit.SpreadAngle = Vector2.new(60, 60)
			glit.RotSpeed = NumberRange.new(-120, 120)
			glit.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.5), NumberSequenceKeypoint.new(1, 0) })
			glit.Parent = chest
			local cl = Instance.new("PointLight")
			cl.Name = "ChestLight"
			cl.Color = Color3.fromRGB(255, 200, 80)
			cl.Range = 10
			cl.Brightness = 0.8
			cl.Parent = chest
		end
	end
	-- табличка над аркой: название и цена (цену пишет клиент)
	local anchor = part(portal, "SignAnchor", Vector3.new(1, 1, 1), face * CFrame.new(0, h + 3.5, 0), GOLD, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	local bb = Instance.new("BillboardGui")
	bb.Name = "RushSign"
	bb.Size = UDim2.fromOffset(300, 92)
	bb.MaxDistance = 220
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Parent = anchor
	local function lbl(text, y, hh, color)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(0, y)
		l.Size = UDim2.new(1, 0, 0, hh)
		l.Text = text
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = color
		l.Parent = bb
		local st = Instance.new("UIStroke")
		st.Thickness = 3
		st.Color = Color3.fromRGB(70, 35, 10)
		st.Parent = l
		return l
	end
	lbl("💰 COIN RUSH", 0, 48, GOLD)
	local sub = lbl("Treasure Dungeon", 48, 26, Color3.new(1, 1, 1))
	sub.Name = "Sub"
	-- красивая тропинка от главной дороги к порталу: плавная «змейка» из светлых каменных плит
	-- с золотой каймой, по краям — огоньки (мигают волной, клиент), над ней парят золотые монеты,
	-- на развилке у дороги — указатель. Ничего не мешает: детали без столкновений, только плиты твёрдые.
	local path = Instance.new("Model")
	path.Name = "RushPath"
	path.Parent = portal
	local side = R.PORTAL.Pos.X > 0 and 1 or -1
	local startP = Vector3.new(side * 8.5, 0, base.Z - 8) -- край главной дороги (в стороне от уличного фонаря у z≈95)
	startP = Vector3.new(startP.X, groundAt(startP), startP.Z)
	local endP = (face * CFrame.new(0, 0, -7)).Position -- у входа в арку
	endP = Vector3.new(endP.X, gy, endP.Z)
	local dir = (endP - startP)
	local len = dir.Magnitude
	local right = Vector3.new(-dir.Z, 0, dir.X).Unit
	local steps = math.max(6, math.floor(len / 2.6))
	local function at(t)
		return startP + dir * t + right * math.sin(t * math.pi * 2) * 3.2
	end
	local STONE, RIM = Color3.fromRGB(238, 222, 190), Color3.fromRGB(255, 196, 60)
	for k = 0, steps do
		local t = k / steps
		local pos = at(t)
		pos = Vector3.new(pos.X, groundAt(pos), pos.Z)
		local ahead = at(math.min(1, t + 0.02)) - at(math.max(0, t - 0.02))
		local cf = CFrame.lookAt(pos, pos + Vector3.new(ahead.X, 0, ahead.Z)) * CFrame.Angles(0, math.rad((k % 3 - 1) * 6), 0)
		part(path, "PathRim", Vector3.new(5.6, 0.5, 3.0), cf * CFrame.new(0, 0.25, 0), RIM, Enum.Material.Metal, { CanCollide = false, CanQuery = false })
		part(path, "PathStone", Vector3.new(5, 0.62, 2.5), cf * CFrame.new(0, 0.31, 0), STONE, Enum.Material.Slate)
		if k % 2 == 0 and k > 0 and k < steps then
			for _, x in ipairs({ -3.6, 3.6 }) do
				local l = part(path, "PathLight", Vector3.new(0.9, 0.9, 0.9), cf * CFrame.new(x, 1.5, 0), RIM, Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false, CanQuery = false })
				l:SetAttribute("Wave", t)
			end
		end
	end
	-- парящие монеты над тропинкой (модель Tripo в золоте, крутит клиент)
	local coinSrc = ReplicatedStorage:FindFirstChild("TripoProps") and ReplicatedStorage.TripoProps:FindFirstChild("RushCoin")
	for k, t in ipairs({ 0.18, 0.42 }) do -- ближе к дороге: у арки монета закрывала сундук
		local pos = at(t)
		pos = Vector3.new(pos.X, groundAt(pos) + 4.5, pos.Z)
		if coinSrc then
			local c = coinSrc:Clone()
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("SurfaceAppearance") then
					d.Parent = nil
				elseif d:IsA("BasePart") then
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
					d.Material = Enum.Material.Metal
					d.Color = Color3.fromRGB(245, 185, 40)
					d.Reflectance = 0.18
				end
			end
			local _, ext = c:GetBoundingBox()
			c:ScaleTo(c:GetScale() * 2.6 / math.max(ext.X, ext.Y, ext.Z, 0.01))
			c:PivotTo(CFrame.new(pos))
			c.Name = "FloatCoin"
			c:SetAttribute("Float", k)
			c.Parent = path
		end
		local sp = part(path, "CoinSparkle", Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), RIM, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(RIM)
		e.LightEmission = 1
		e.Rate = 6
		e.Lifetime = NumberRange.new(0.8, 1.2)
		e.Speed = NumberRange.new(0.5, 1.5)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new(0.35, 0)
		e.Parent = sp
	end
	-- парадный вход на тропинку у главной дороги: две колонны с золотыми капителями и крутящимися
	-- монетами, арка с надписью COIN RUSH, клумбы с цветами и кучки золота. Всё сквозное — не мешает.
	local NC = { CanCollide = false, CanQuery = false }
	local gateCF = CFrame.lookAt(startP, startP + Vector3.new(dir.X, 0, dir.Z)) * CFrame.new(0, 0, -2.2)
	local STONE2, GOLD2 = Color3.fromRGB(235, 220, 190), Color3.fromRGB(255, 196, 60)
	local spread = 4.6
	for _, x in ipairs({ -spread, spread }) do
		local pc = gateCF * CFrame.new(x, 0, 0)
		part(path, "GateBase", Vector3.new(2.6, 1, 2.6), pc * CFrame.new(0, 0.5, 0), GOLD2, Enum.Material.Metal, NC)
		part(path, "GatePillar", Vector3.new(1.8, 8.5, 1.8), pc * CFrame.new(0, 5.2, 0), STONE2, Enum.Material.Marble, NC)
		for _, y in ipairs({ 2.4, 5.2, 8 }) do
			part(path, "GateBand", Vector3.new(2.05, 0.35, 2.05), pc * CFrame.new(0, y, 0), GOLD2, Enum.Material.Metal, NC)
		end
		local cap = part(path, "GateCap", Vector3.new(2.7, 0.8, 2.7), pc * CFrame.new(0, 9.8, 0), GOLD2, Enum.Material.Metal, NC)
		-- монета на капители (крутит клиент, как парящие над тропинкой)
		if coinSrc then
			local c = coinSrc:Clone()
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("SurfaceAppearance") then
					d.Parent = nil
				elseif d:IsA("BasePart") then
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
					d.Material = Enum.Material.Metal
					d.Color = Color3.fromRGB(245, 185, 40)
					d.Reflectance = 0.18
				end
			end
			local _, ext = c:GetBoundingBox()
			c:ScaleTo(c:GetScale() * 2.4 / math.max(ext.X, ext.Y, ext.Z, 0.01))
			c:PivotTo(pc * CFrame.new(0, 12, 0))
			c.Name = "FloatCoin"
			c:SetAttribute("Float", x)
			c.Parent = path
		end
		local gl = Instance.new("PointLight")
		gl.Color = GOLD2
		gl.Range = 14
		gl.Brightness = 1.3
		gl.Parent = cap
		-- клумба с цветами и кучка золота у колонны (снаружи от тропинки)
		local out = x > 0 and 1 or -1
		local bed = pc * CFrame.new(out * 2.8, 0, 0.4)
		part(path, "FlowerBed", Vector3.new(2.6, 0.7, 3.6), bed * CFrame.new(0, 0.35, 0), Color3.fromRGB(120, 80, 50), Enum.Material.Wood, NC)
		local cols = { Color3.fromRGB(255, 90, 140), Color3.fromRGB(255, 210, 70), Color3.fromRGB(170, 110, 255), Color3.fromRGB(255, 255, 255) }
		for k = 0, 5 do
			local fx = ((k % 2) - 0.5) * 1.2
			local fz = (math.floor(k / 2) - 1) * 1.1
			part(path, "Bush", Vector3.new(1.3, 1.1, 1.3), bed * CFrame.new(fx, 1.1, fz), Color3.fromRGB(70, 170, 70), Enum.Material.Grass, { CanCollide = false, CanQuery = false, Shape = Enum.PartType.Ball })
			part(path, "Flower", Vector3.new(0.5, 0.5, 0.5), bed * CFrame.new(fx, 1.75, fz), cols[k % #cols + 1], Enum.Material.Neon, { CanCollide = false, CanQuery = false, Shape = Enum.PartType.Ball })
		end
		tripo("RushGold", 3, path, pc * CFrame.new(0, 0, 2.2))
	end
	-- арка между колоннами: изогнутая золотая дуга из сегментов и табличка
	local segs = 9
	for k = 0, segs do
		local t = k / segs
		local x = -spread + 2 * spread * t
		local y = 10.4 + math.sin(t * math.pi) * 2.2
		local seg = part(path, "GateArc", Vector3.new(2 * spread / segs + 0.25, 0.7, 1.1), gateCF * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, math.cos(t * math.pi) * 0.45), GOLD2, Enum.Material.Metal, NC)
		if k % 3 == 0 then
			part(path, "GateGem", Vector3.new(0.6, 0.6, 0.6), seg.CFrame * CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 80, 120), Enum.Material.Neon, { CanCollide = false, CanQuery = false, Shape = Enum.PartType.Ball })
		end
	end
	local board = part(path, "GateSign", Vector3.new(7.2, 1.9, 0.4), gateCF * CFrame.new(0, 10.3, 0), Color3.fromRGB(80, 35, 25), Enum.Material.Wood, NC)
	part(path, "GateSignTrim", Vector3.new(7.6, 2.3, 0.3), board.CFrame, GOLD2, Enum.Material.Metal, NC)
	for _, faceId in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = faceId
		sg.PixelsPerStud = 40
		sg.LightInfluence = 0
		sg.Parent = board
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Text = "COIN RUSH"
		tl.TextScaled = true
		tl.Font = Enum.Font.FredokaOne
		tl.TextColor3 = GOLD2
		tl.Parent = sg
		local st = Instance.new("UIStroke")
		st.Thickness = 2.5
		st.Color = Color3.fromRGB(60, 25, 10)
		st.Parent = tl
	end
	-- гирлянда огоньков по дуге (мигают волной вместе с огоньками тропинки)
	for k = 1, segs - 1 do
		local t = k / segs
		local l = part(path, "PathLight", Vector3.new(0.9, 0.9, 0.9), gateCF * CFrame.new(-spread + 2 * spread * t, 10.4 + math.sin(t * math.pi) * 2.2 - 0.9, 0), GOLD2, Enum.Material.Neon, { CanCollide = false, CanQuery = false, Shape = Enum.PartType.Ball })
		l:SetAttribute("Wave", -t * 0.3)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Enter Coin Rush"
	prompt.ObjectText = "Treasure Dungeon"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	-- подсказка «Enter» висит на невидимой опоре у входа на уровне груди (на вихре высоко в арке
	-- она появлялась ненадёжно)
	local promptAnchor = part(portal, "PromptAnchor", Vector3.new(4, 4, 1), face * CFrame.new(0, 3, -1.5), GOLD, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	prompt.Parent = promptAnchor
	portal.Parent = world
	R.Prompt = prompt
	R.ReturnCF = face * CFrame.new(0, 4, -12) * CFrame.Angles(0, math.pi, 0)
end

-- монеты мира не спавнятся у портала и на тропинке: переносим их на главную дорогу рядом
task.delay(12, function() -- после WorldPolish (он двигает монеты при старте)
	local center = portal:GetPivot().Position
	local stones = {}
	for _, d in ipairs(portal:GetDescendants()) do
		if d.Name == "PathStone" or d.Name == "GateBase" then
			table.insert(stones, d.Position)
		end
	end
	local rng = Random.new(7)
	local moved = 0
	for _, c in ipairs(world:GetChildren()) do
		if c:IsA("BasePart") and string.match(c.Name, "^Coin_%d+$") then
			local p = c.Position
			local near = Vector2.new(p.X - center.X, p.Z - center.Z).Magnitude < 22
			for _, sp in ipairs(stones) do
				if Vector2.new(p.X - sp.X, p.Z - sp.Z).Magnitude < 6 then
					near = true
				end
			end
			if near then
				local np = Vector3.new(rng:NextNumber(-5, 5), p.Y, p.Z + rng:NextNumber(-18, 18))
				c.Position = np
				c:SetAttribute("Home", np)
				moved += 1
			end
		end
	end
	print("[CoinRush] coins moved away from the portal:", moved)
end)

-- ===== забеги =====
local runs = {} -- [player] = run
local spawnBoss -- задаётся ниже (босс хранилища)
local openVault -- задаётся ниже
local removePack -- задаётся ниже (рюкзак)
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

local function spawnOne(run, folder, def, c: Vector3, rng, life: number?)
	local half = R.ROOM / 2 - 8
	-- часть монет — дорогие золотые слитки (×3)
	local big = rng:NextNumber() < 0.12
	local pos = c + Vector3.new(rng:NextNumber(-half, half), big and 0.6 or 1.8, rng:NextNumber(-half + 10, half))
	local coin = part(folder, big and "RushBar" or "RushCoinPart", big and Vector3.new(2.8, 1.1, 1.4) or Vector3.new(0.5, 2.6, 2.6), CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), big and Color3.fromRGB(245, 185, 40) or Color3.fromRGB(255, 215, 70), big and Enum.Material.Metal or Enum.Material.Neon, { Shape = big and Enum.PartType.Block or Enum.PartType.Cylinder, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	coin:SetAttribute("RushCoin", true)
	local e = { part = coin, value = def.Value * (big and 3 or 1) * (run.fmul or 1) }
	if life then
		e.expire = os.clock() + life
		coin:SetAttribute("ExpireAt", workspace:GetServerTimeNow() + life) -- клиент мигает перед исчезновением
	end
	table.insert(run.coins, e)
end
local function spawnCoins(run, i: number)
	local def = R.ROOMS[i]
	local c = run.offset + roomCenter(i)
	local folder = Instance.new("Folder")
	folder.Name = "Coins" .. i
	folder.Parent = run.model
	run.coins = {}
	run.folder, run.def, run.center, run.rng = folder, def, c, Random.new()
	run.wave, run.sweep, run.lava = nil, nil, nil
	if def.Mode == "waves" then
		run.wave = { left = def.Coins, nextAt = os.clock() + 1 }
	else
		for _ = 1, def.Coins do
			spawnOne(run, folder, def, c, run.rng)
		end
	end
	-- низкий лазер-«метла»: едет поперёк комнаты туда-обратно, его перепрыгивают
	if def.Sweep then
		local w = R.ROOM - 4
		local cf = CFrame.new(c + Vector3.new(0, 1.3, -R.ROOM / 2 + 14))
		local core = part(folder, "SweepLaser", Vector3.new(w, 0.45, 0.45), cf, Color3.fromRGB(255, 210, 220), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 0.8 })
		local glowS = part(folder, "SweepGlow", Vector3.new(w, 1.3, 1.3), cf, Color3.fromRGB(255, 40, 90), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 0.9 })
		for _, x in ipairs({ -w / 2, w / 2 }) do
			local emit = part(folder, "SweepEnd", Vector3.new(1.6, 1.6, 1.6), cf * CFrame.new(x, 0, 0), Color3.fromRGB(80, 20, 30), Enum.Material.Metal, { CanCollide = false, CanQuery = false })
			emit:SetAttribute("SweepEnd", x)
		end
		run.sweep = { core = core, glow = glowS, z = -R.ROOM / 2 + 14, dir = 1, speed = 13 * (1 + 0.06 * ((run.floor or 1) - 1)), c = c, armAt = os.clock() + 2.5, half = R.ROOM / 2 - 6 }
	end
	-- пол-лава: сетка 6×6 плиток-наложений, загораются циклами
	if def.Lava then
		local n, size = 6, R.ROOM / 6
		run.lava = { tiles = {}, nextAt = os.clock() + 2.5, size = size, n = n, c = c }
		for ix = 0, n - 1 do
			for iz = 0, n - 1 do
				local pos = c + Vector3.new(-R.ROOM / 2 + size * (ix + 0.5), 0.12, -R.ROOM / 2 + size * (iz + 0.5))
				local t = part(folder, "LavaTile", Vector3.new(size - 0.6, 0.12, size - 0.6), CFrame.new(pos), Color3.fromRGB(255, 140, 40), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 1 })
				-- плитка у входа никогда не горит (безопасный старт)
				table.insert(run.lava.tiles, { part = t, ix = ix, iz = iz, state = 0, safe = (iz == 0 and (ix == 2 or ix == 3)) })
			end
		end
	end
	-- лазеры: вращающиеся балки через центр комнаты
	run.lasers = {}
	for k = 1, def.Lasers do
		local beam = part(folder, "Laser", Vector3.new(R.ROOM - 10, 1.2, 1.2), CFrame.new(c + Vector3.new(0, 2.5, 0)), Color3.fromRGB(255, 40, 70), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		local hub = part(folder, "LaserHub", Vector3.new(4, 5, 4), CFrame.new(c + Vector3.new(0, 2.5, 0)), Color3.fromRGB(60, 20, 30), Enum.Material.Metal, { CanCollide = true })
		hub.Shape = Enum.PartType.Cylinder
		hub.CFrame = CFrame.new(c + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		beam.Color = Color3.fromRGB(255, 200, 210)
		beam.Size = Vector3.new(R.ROOM - 10, 0.5, 0.5)
		local glowL = part(folder, "LaserGlow", Vector3.new(R.ROOM - 10, 1.6, 1.6), beam.CFrame, Color3.fromRGB(255, 30, 70), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 0.55 })
		local hl = Instance.new("PointLight")
		hl.Color = Color3.fromRGB(255, 50, 80)
		hl.Range = 26
		hl.Brightness = 3
		hl.Parent = hub
		local sp = Instance.new("ParticleEmitter")
		sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sp.Color = ColorSequence.new(Color3.fromRGB(255, 120, 140))
		sp.LightEmission = 1
		sp.Rate = 25
		sp.Lifetime = NumberRange.new(0.3, 0.6)
		sp.Speed = NumberRange.new(4, 9)
		sp.SpreadAngle = Vector2.new(180, 180)
		sp.Size = NumberSequence.new(0.35, 0)
		sp.Parent = hub
		-- первые 2 с лазер мигает и не бьёт — предупреждение
		beam.Transparency, glowL.Transparency = 0.8, 0.9
		table.insert(run.lasers, { part = beam, glow = glowL, center = c + Vector3.new(0, 2.5, 0), angle = (k - 1) * math.pi / def.Lasers, speed = def.Speed * (1 + 0.07 * ((run.floor or 1) - 1)) * (k % 2 == 0 and -1 or 1), armAt = os.clock() + 2 })
	end
	run.totalWeight += def.Coins * def.Value * 1.24 * (run.fmul or 1) -- 12% слитков ×3 → средний вес монеты 1.24 (вся комната, и волны тоже)
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
	pcall(PlayerSystems.ApplySpeed, p)
	pcall(removePack, p)
	local reward = math.floor(run.bank * run.worth)
	local loot = {}
	local F = run.floor or 1
	-- звёзды и этажи
	local stars = (run.room or 1) > #R.ROOMS and 1 or 0
	if run.bossBeaten then
		stars = run.hits <= 1 and 3 or 2
	end
	local starKey = "Save_RushStars" .. F
	if stars > (p:GetAttribute(starKey) or 0) then
		p:SetAttribute(starKey, stars)
	end
	local newFloor = nil
	if run.bossBeaten and F >= R.Floor(p) and F < R.FLOORS then
		newFloor = F + 1
		p:SetAttribute("Save_RushFloor", newFloor)
		table.insert(loot, "🏰 Floor " .. newFloor .. " unlocked!")
	end
	if run.bossBeaten and (F == 5 or F == 10) and stars == 3 then
		p:SetAttribute("Save_RushKeys", (p:GetAttribute("Save_RushKeys") or 0) + 2)
		table.insert(loot, "🔑 +2 Rush Keys (perfect floor " .. F .. ")")
	end
	if run.vaultOpen then
		reward *= 2
		local rng = Random.new()
		if rng:NextNumber() < math.min(0.45 + 0.05 * (F - 1), 0.95) then
			local names = ShopConfig.SuperPotionOrder -- в сейфе — только СУПЕР-зелья
			local name = names[rng:NextInteger(1, #names)]
			p:SetAttribute("Potion" .. name, (p:GetAttribute("Potion" .. name) or 0) + 1)
			table.insert(loot, ShopConfig.Potions[name].Icon .. " " .. ShopConfig.Potions[name].Name)
		end
		if rng:NextNumber() < 0.03 + 0.006 * (F - 1) then
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
	send(run, "result", { Floor = F, Stars = stars, NewFloor = newFloor, Coins = reward, Vault = run.vaultOpen == true, Loot = loot, Reason = reason, Hits = run.hits })
	task.delay(0.2, function()
		if p.Parent == Players then
			tp(p, R.ReturnCF)
		end
		run.model:Destroy()
		slots[run.slot] = nil
	end)
end

-- ===== Босс хранилища =====
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local function bossModel(run, at: CFrame): Model
	local id = Config.VaultPets and Config.VaultPets[SHORT[bestWorld(run.player)] or "island"]
	local ok, m = pcall(function()
		return PetVisuals.Build(id)
	end)
	if not ok or not m then
		m = Instance.new("Model")
		part(m, "Body", Vector3.new(6, 8, 5), CFrame.new(), Color3.fromRGB(230, 180, 60), Enum.Material.Metal)
	end
	local _, ext = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * 15 / math.max(ext.Y, 0.1)) -- великан ~15 студов
	local cf, ext2 = m:GetBoundingBox()
	m:PivotTo(at * CFrame.new(0, ext2.Y / 2, 0) * m:GetPivot():ToObjectSpace(cf):Inverse())
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
		end
	end
	m.Name = "VaultBoss"
	m.Parent = run.model
	return m
end
spawnBoss = function(run, c: Vector3)
	local F = run.floor or 1
	run.center, run.folder = c, nil -- пол арены (для высоты прыжка над кольцом)
	local zone = run.model:FindFirstChild("VaultZone", true)
	if zone then
		zone.Transparency = 1
	end
	local at = CFrame.lookAt(c + Vector3.new(0, 0, 12), c + Vector3.new(0, 0, -20))
	local hp = 20 + 3 * (F - 1) -- выстрелов: 20 на 1 этаже … 47 на 10-м
	run.boss = {
		model = bossModel(run, at), base = at, c = c, hp = hp, max = hp,
		nextSlam = os.clock() + 3, slamEvery = math.max(2.2, 3.8 - 0.16 * (F - 1)), ringSpeed = 17 + F,
		rings = {}, crystals = {}, nextCrystal = os.clock() + 4, bullets = {}, nextRegen = os.clock() + 1,
	}
	-- полоса жизней над големом
	local _, ext = run.boss.model:GetBoundingBox()
	local bb = Instance.new("BillboardGui")
	bb.Name = "BossBar"
	bb.Size = UDim2.fromOffset(220, 46)
	bb.StudsOffsetWorldSpace = Vector3.new(0, ext.Y / 2 + 2.5, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = run.boss.model.PrimaryPart or run.boss.model:FindFirstChildWhichIsA("BasePart", true)
	local nameL = Instance.new("TextLabel")
	nameL.BackgroundTransparency = 1
	nameL.Size = UDim2.new(1, 0, 0, 22)
	nameL.Font = Enum.Font.FredokaOne
	nameL.TextScaled = true
	nameL.TextColor3 = Color3.fromRGB(255, 225, 120)
	nameL.TextStrokeTransparency = 0
	nameL.Text = "VAULT GOLEM · FLOOR " .. F
	nameL.Parent = bb
	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(10, 26)
	back.Size = UDim2.new(1, -20, 0, 16)
	back.BackgroundColor3 = Color3.fromRGB(30, 16, 60)
	back.Parent = bb
	Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	bb.Parent = run.boss.model
	run.boss.fill = fill
	run.boss.rel = at:ToObjectSpace(run.boss.model:GetPivot())
	-- патроны: 8 + 40% собранных монет, не больше 90
	run.ammo = math.min(8 + math.floor((run.picked or 0) * 0.4), 90) -- поворот к игроку сохраняет посадку модели
	run.boss.model:SetAttribute("Hp", hp)
	run.boss.model:SetAttribute("MaxHp", hp)
end
local function bossRing(run)
	local B = run.boss
	local ring = part(run.model, "BossRing", Vector3.new(0.4, 4, 4), CFrame.new(B.c + Vector3.new(0, 0.3, 12)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 0.25 })
	table.insert(B.rings, { part = ring, r = 2, born = os.clock() })
	send(run, "bossSlam", {})
end
local function bossCrystal(run)
	local B = run.boss
	local rng = run.rng or Random.new()
	local a = rng:NextNumber(0, math.pi * 2)
	local d = rng:NextNumber(10, 24)
	local pos = B.c + Vector3.new(math.cos(a) * d, 2.2, 6 + math.sin(a) * d * 0.8)
	local cr = part(run.model, "BossCrystal", Vector3.new(2, 3.4, 2), CFrame.new(pos) * CFrame.Angles(0, a, math.rad(20)), Color3.fromRGB(110, 230, 255), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(110, 230, 255)
	l.Range = 12
	l.Brightness = 2
	l.Parent = cr
	cr:SetAttribute("BossCrystal", true)
	table.insert(B.crystals, cr)
end

local function bossDamage(run, n: number)
	local B = run.boss
	if not B or run.vaultTried then
		return
	end
	B.hp -= n
	B.model:SetAttribute("Hp", B.hp)
	if B.fill then
		B.fill.Size = UDim2.fromScale(math.max(B.hp, 0) / B.max, 1)
	end
	-- белая вспышка попадания
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 240, 160)
	hl.FillTransparency = 0.3
	hl.OutlineTransparency = 1
	hl.Parent = B.model
	task.delay(0.08, function()
		hl:Destroy()
	end)
	send(run, "bossHit", { Hp = B.hp, Max = B.max })
	if B.hp <= 0 then
		run.bossBeaten = true
		for _, c2 in ipairs(B.crystals) do
			c2:Destroy()
		end
		for _, r2 in ipairs(B.rings) do
			r2.part:Destroy()
		end
		for _, b2 in ipairs(B.bullets) do
			b2.part:Destroy()
		end
		B.crystals, B.rings, B.bullets = {}, {}, {}
		B.model:Destroy()
		openVault(run)
	end
end
-- выстрел магнитом: клиент только просит, сервер проверяет фазу, темп и патроны
local shoot = Instance.new("RemoteEvent")
shoot.Name = "RushShoot"
shoot.Parent = ReplicatedStorage
shoot.OnServerEvent:Connect(function(p)
	local run = runs[p]
	local B = run and run.boss
	if not B or run.vaultTried or run.done then
		return
	end
	local now = os.clock()
	if now - (run.lastShot or 0) < 0.17 or (run.ammo or 0) < 1 then
		return
	end
	run.lastShot = now
	run.ammo -= 1
	local char = p.Character
	local tool = char and char:FindFirstChild("CoinMagnet")
	local muzzle = tool and tool:FindFirstChild("Handle") or (char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")))
	if not muzzle then
		return
	end
	local from = muzzle.Position + muzzle.CFrame.UpVector * 1.2
	local bullet = part(run.model, "GoldBullet", Vector3.new(0.9, 0.9, 0.9), CFrame.new(from), Color3.fromRGB(255, 205, 60), Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.35, 0)
	a0.Parent = bullet
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.35, 0)
	a1.Parent = bullet
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 0.18
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 150, 30))
	tr.Transparency = NumberSequence.new(0.1, 1)
	tr.Parent = bullet
	table.insert(B.bullets, { part = bullet })
	send(run, "shot", { Ammo = run.ammo })
end)

local function startRoom(run, i: number)
	run.room = i
	if run.model:FindFirstChild("Coins" .. (i - 1)) then
		run.model["Coins" .. (i - 1)]:Destroy()
	end
	local spawnCF = CFrame.new(run.offset + roomCenter(i) + Vector3.new(0, 4, -R.ROOM / 2 + 8))
	if i <= #R.ROOMS then
		spawnCoins(run, i)
		local dur = RunService:IsStudio() and workspace:GetAttribute("RushRoomTime") or R.ROOMS[i].Time -- в Studio можно ускорить
		run.ends = os.clock() + dur
		send(run, "room", { Floor = run.floor, Room = i, Rooms = #R.ROOMS, Worth = run.worth, Name = R.ROOMS[i].Name, Hint = R.ROOMS[i].Hint, Ends = workspace:GetServerTimeNow() + dur, Total = #run.coins + (run.wave and run.wave.left or 0) })
	else
		spawnCF = CFrame.new(run.offset + roomCenter(i) + Vector3.new(0, 4, -26))
		run.coins, run.lasers, run.sweep, run.lava, run.wave = {}, {}, nil, nil, nil
		run.need = run.totalWeight * (RunService:IsStudio() and workspace:GetAttribute("RushVaultNeed") or R.VAULT_NEED) -- в Studio порог можно задать атрибутом
		run.ends = os.clock() + R.BOSS_TIME
		spawnBoss(run, run.offset + roomCenter(i))
		send(run, "boss", { Ammo = run.ammo, Floor = run.floor, Hp = run.boss.hp, Max = run.boss.max, Ends = workspace:GetServerTimeNow() + R.BOSS_TIME, Worth = run.worth, Have = run.bank })
	end
	-- лицом в комнату (к монетам / к боссу), а не к стене входа
	tp(run.player, CFrame.lookAt(spawnCF.Position, spawnCF.Position + Vector3.new(0, 0, 1)))
end

openVault = function(run)
	if run.vaultTried then
		return
	end
	run.vaultTried = true
	if run.boss then
		run.vaultOpen = run.bossBeaten == true -- победил босса — сейф открыт
	else
		run.vaultOpen = run.bank >= run.need
	end
	local door = run.model:FindFirstChild("VaultDoor", true)
	if run.vaultOpen and door then
		-- дверь сейфа (вместе с каменной рамой — одна модель Tripo) уезжает вверх, как решётка,
		-- и открывает сияние сокровищницы
		local start = door:GetPivot()
		local _, size = door:GetBoundingBox()
		local light = run.model:FindFirstChild("VaultLight", true)
		task.spawn(function()
			task.wait(0.6) -- сначала тряска и щелчки замка (клиент)
			for k = 1, 45 do
				local e = 1 - (1 - k / 45) ^ 3
				door:PivotTo(start + Vector3.new(0, size.Y * 1.05 * e, 0))
				if light then
					light.Brightness = 3 * e
				end
				task.wait(0.03)
			end
		end)
	end
	send(run, "vaultResult", { Open = run.vaultOpen, Have = run.bank, Need = run.need })
	task.delay(run.vaultOpen and 4.2 or 2, function()
		finish(run)
	end)
end

-- ===== Рюкзак-переработчик и трубка к магниту =====
local GOLD = Color3.fromRGB(255, 200, 50)
local PACK_YAW = math.pi -- поворот модели рюкзака Tripo на спине (подбирается под модель)
local function weldTo(partA: BasePart, partB: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = partA, partB
	w.Parent = partA
end
local function buildPack(): Model
	local tpl = ReplicatedStorage:FindFirstChild("TripoProps") and ReplicatedStorage.TripoProps:FindFirstChild("RushBackpack")
	local m
	if tpl then
		m = tpl:Clone()
		local _, ext = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * 2.3 / math.max(ext.Y, 0.1))
	else
		-- запасной рюкзак из деталей: фиолетовый корпус, золотой бак с окошком
		m = Instance.new("Model")
		local body = part(m, "Body", Vector3.new(2.2, 2.4, 1.1), CFrame.new(), Color3.fromRGB(120, 70, 210), Enum.Material.SmoothPlastic)
		part(m, "Tank", Vector3.new(2.6, 1.3, 1.3), CFrame.new(0, 0, 0.35) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		part(m, "Window", Vector3.new(1.2, 1.6, 0.2), CFrame.new(0, 0, 0.95), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, { Transparency = 0.15 })
		part(m, "Cap", Vector3.new(0.5, 0.6, 0.5), CFrame.new(0.6, 1.4, 0.2), GOLD, Enum.Material.Metal)
		m.PrimaryPart = body
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, false, true
		end
	end
	m.Name = "RushPack"
	return m
end
local function equipPack(p)
	local char = p.Character
	local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
	if not torso or char:FindFirstChild("RushPack") then
		return
	end
	local pack = buildPack()
	local bcf, ext = pack:GetBoundingBox()
	local offset = pack:GetPivot():ToObjectSpace(bcf) -- центр габаритов относительно точки модели
	-- за спиной: центр рюкзака позади торса, чуть выше середины; окошко с золотом смотрит назад
	local target = torso.CFrame * CFrame.new(0, 0.55, torso.Size.Z / 2 + ext.Z / 2 - 0.1) * CFrame.Angles(0, PACK_YAW, 0)
	pack:PivotTo(target * offset:Inverse())
	local root = pack.PrimaryPart or pack:FindFirstChildWhichIsA("BasePart", true)
	for _, d in ipairs(pack:GetDescendants()) do
		if d:IsA("BasePart") then
			weldTo(d, torso)
		end
	end
	pack.Parent = char
	-- трубка: Beam от бока рюкзака к магниту (или к руке), по ней бегут золотые шевроны
	local a0 = Instance.new("Attachment")
	a0.Name = "TubeStart"
	a0.WorldPosition = root.Position + torso.CFrame.RightVector * (ext.X / 2) + Vector3.new(0, -0.3, 0)
	a0.Parent = root
	local tool = char:FindFirstChild("CoinMagnet")
	local endPart = tool and tool:FindFirstChild("Handle") or char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if endPart then
		local a1 = Instance.new("Attachment")
		a1.Name = "TubeEnd"
		a1.Parent = endPart
		local outer = Instance.new("Beam")
		outer.Name = "PackTube"
		outer.Attachment0, outer.Attachment1 = a0, a1
		outer.Width0, outer.Width1 = 0.35, 0.3
		outer.Segments = 10
		-- без стрелок-потока и с меньшим изгибом: полоса «>>>» тянулась по полю и мешала выстрелам (фидбэк 2026-11)
		outer.CurveSize0, outer.CurveSize1 = -0.8, 0.5
		outer.Color = ColorSequence.new(Color3.fromRGB(150, 100, 230))
		outer.Transparency = NumberSequence.new(0.35)
		outer.FaceCamera = true
		outer.Parent = root
	end
end
removePack = function(p)
	local char = p.Character
	local pack = char and char:FindFirstChild("RushPack")
	if pack then
		pack:Destroy()
	end
	for _, d in ipairs(char and char:GetDescendants() or {}) do
		if d.Name == "TubeEnd" then
			d:Destroy()
		end
	end
end

local function startRun(p)
	local slot = takeSlot()
	local offset = R.ORIGIN + Vector3.new((slot - 1) * R.SLOT, 0, 0)
	local m = template:Clone()
	m.Name = "CoinRush_" .. p.UserId
	m:PivotTo(m:GetPivot() + offset)
	m.Parent = workspace
	local F = RunService:IsStudio() and workspace:GetAttribute("RushFloor") or R.Floor(p) -- в Studio этаж можно задать атрибутом
	local run = { player = p, slot = slot, offset = offset, model = m, bank = 0, totalWeight = 0, hits = 0, worth = coinWorth(p), lastHit = 0, floor = F, fmul = 1 + 0.3 * (F - 1) }
	runs[p] = run
	p:SetAttribute("InRush", true)
	pcall(PlayerSystems.ApplySpeed, p) -- в данже скорость ограничена (R.SPEED_CAP)
	pcall(equipPack, p)
	startRoom(run, RunService:IsStudio() and workspace:GetAttribute("RushStartRoom") or 1) -- в Studio можно начать с любой комнаты
end

R.Prompt.Triggered:Connect(function(p)
	if runs[p] or not p:GetAttribute("ProfileReady") then
		return
	end
	if p:GetAttribute("Trading") then
		notify(p, "Finish your trade first")
		return
	end
	local now = os.clock()
	local cooldown = RunService:IsStudio() and 3 or R.COOLDOWN
	if lastRun[p] and now - lastRun[p] < cooldown then
		notify(p, "Coin Rush recharging: " .. math.ceil(cooldown - (now - lastRun[p])) .. " s")
		return
	end
	local free = (p:GetAttribute("Save_RushFreeDay") or -1) ~= today()
	local keys = p:GetAttribute("Save_RushKeys") or 0
	if free then
		p:SetAttribute("Save_RushFreeDay", today())
	elseif keys > 0 then
		-- ключ из награды (дейлики, ребёрс) — забег без оплаты
		p:SetAttribute("Save_RushKeys", keys - 1)
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
				p:SetAttribute("RushKeyCost", (free or (p:GetAttribute("Save_RushKeys") or 0) > 0) and 0 or R.KeyCost(p))
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
		local t = os.clock()
		for _, L in ipairs(run.lasers or {}) do
			if t >= L.armAt then
				L.angle += L.speed * dt
				if not L.armed then
					L.armed = true
					L.part.Transparency, L.glow.Transparency = 0, 0.55
				end
			else
				local blink = math.floor(t * 6) % 2 == 0
				L.part.Transparency = blink and 0.3 or 0.85
			end
			local cf = CFrame.new(L.center) * CFrame.Angles(0, L.angle, 0)
			L.part.CFrame = cf
			L.glow.CFrame = cf
		end
		local S = run.sweep
		if S then
			if t >= S.armAt then
				if not S.armed then
					S.armed = true
					S.core.Transparency, S.glow.Transparency = 0, 0.5
				end
				S.z += S.dir * S.speed * dt
				if S.z > S.half then
					S.z, S.dir = S.half, -1
				elseif S.z < -S.half then
					S.z, S.dir = -S.half, 1
				end
			else
				S.core.Transparency = math.floor(t * 6) % 2 == 0 and 0.3 or 0.85
			end
			local cf = CFrame.new(S.c + Vector3.new(0, 1.3, S.z))
			S.core.CFrame, S.glow.CFrame = cf, cf
			for _, e in ipairs(run.folder and run.folder:GetChildren() or {}) do
				if e.Name == "SweepEnd" then
					e.CFrame = cf * CFrame.new(e:GetAttribute("SweepEnd"), 0, 0)
				end
			end
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
			local radius = R.PICKUP -- магнит в данже не действует
			local function hit(from: Vector3)
				if now - run.lastHit <= 1.2 then
					return
				end
				run.lastHit = now
				run.hits += 1
				local lost = run.bank * R.HIT_LOSS
				run.bank -= lost
				local away = Vector3.new(pos.X - from.X, 0, pos.Z - from.Z)
				root.AssemblyLinearVelocity = (away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, -1)) * 55 + Vector3.new(0, 35, 0)
				send(run, "hit", { Lost = lost, Bank = run.bank })
			end
			-- волны монет (комната 1)
			local W = run.wave
			if W and W.left > 0 and now >= W.nextAt then
				for _ = 1, math.min(run.def.Wave, W.left) do
					spawnOne(run, run.folder, run.def, run.center, run.rng, run.def.Life)
				end
				W.left -= math.min(run.def.Wave, W.left)
				W.nextAt = now + run.def.WaveEvery
				send(run, "bank", { Bank = run.bank, Left = #run.coins + W.left, Got = 0 })
			end
			local got = 0
			for k = #run.coins, 1, -1 do
				local c = run.coins[k]
				if c.expire and now >= c.expire then
					c.part:SetAttribute("Expired", true)
					c.part:Destroy()
					table.remove(run.coins, k)
				elseif (c.part.Position - pos).Magnitude <= radius then
					run.bank += c.value
					got += 1
					run.picked = (run.picked or 0) + 1
					c.part:Destroy()
					table.remove(run.coins, k)
				end
			end
			if got > 0 then
				send(run, "bank", { Bank = run.bank, Left = #run.coins + (W and W.left or 0), Got = got })
			end
			local floorY = run.center and run.center.Y or pos.Y - 3
			-- низкий лазер: задел, если не в прыжке
			local S = run.sweep
			if S and S.armed and math.abs(pos.Z - (S.c.Z + S.z)) < 1.4 and pos.Y - floorY < 4.6 then
				hit(Vector3.new(pos.X, pos.Y, S.c.Z + S.z - S.dir * 3))
			end
			-- лава: циклы предупреждение → лава → остывание
			local Lv = run.lava
			if Lv then
				if now >= Lv.nextAt then
					Lv.nextAt = now + 3.2 / (1 + 0.05 * ((run.floor or 1) - 1))
					for _, tile in ipairs(Lv.tiles) do
						if not tile.safe and tile.state == 0 and run.rng:NextNumber() < 0.42 then
							tile.state, tile.warnAt = 1, now
						end
					end
				end
				for _, tile in ipairs(Lv.tiles) do
					if tile.state == 1 then
						tile.part.Transparency = 0.35 + 0.25 * math.sin(now * 18)
						tile.part.Color = Color3.fromRGB(255, 95, 10)
						if now - tile.warnAt >= 1.1 then
							tile.state, tile.hotAt = 2, now
							tile.part.Color = Color3.fromRGB(200, 20, 10)
							tile.part.Transparency = 0.05
						end
					elseif tile.state == 2 and now - tile.hotAt >= 1.7 then
						tile.state = 0
						tile.part.Transparency = 1
					end
				end
				local ix = math.floor((pos.X - (Lv.c.X - R.ROOM / 2)) / Lv.size)
				local iz = math.floor((pos.Z - (Lv.c.Z - R.ROOM / 2)) / Lv.size)
				local tile = Lv.tiles[ix * Lv.n + iz + 1]
				if tile and ix >= 0 and ix < Lv.n and iz >= 0 and iz < Lv.n and tile.state == 2 and pos.Y - floorY < 5 then
					hit(tile.part.Position)
				end
			end
			-- лазеры
			for _, L in ipairs(run.lasers or {}) do
				local half = L.part.CFrame.RightVector * (L.part.Size.X / 2)
				if L.armed and math.abs(pos.Y - L.center.Y) < 4 and segDist(Vector3.new(pos.X, L.center.Y, pos.Z), L.center - half, L.center + half) < 2.2 then
					hit(L.center)
				end
			end
			-- босс хранилища
			local B = run.boss
			if B and not run.vaultTried then
				-- смотрит на игрока
				local look = Vector3.new(pos.X, B.base.Position.Y, pos.Z)
				if (look - B.base.Position).Magnitude > 1 then
					B.model:PivotTo(CFrame.lookAt(B.base.Position, look) * B.rel)
				end
				-- удар по полу → кольцо-волна
				if now >= B.nextSlam then
					B.nextSlam = now + B.slamEvery
					bossRing(run)
				end
				for k = #B.rings, 1, -1 do
					local rg = B.rings[k]
					rg.r = 2 + (now - rg.born) * B.ringSpeed
					rg.part.Size = Vector3.new(0.4, rg.r * 2, rg.r * 2)
					rg.part.Transparency = math.clamp(0.2 + rg.r / 60, 0, 1)
					local center = Vector3.new(rg.part.Position.X, 0, rg.part.Position.Z)
					local dist = (Vector3.new(pos.X, 0, pos.Z) - center).Magnitude
					if not rg.hit and math.abs(dist - rg.r) < 1.6 and pos.Y - floorY < 4.4 then
						rg.hit = true
						hit(rg.part.Position)
					end
					if rg.r > 46 then
						rg.part:Destroy()
						table.remove(B.rings, k)
					end
				end
				-- кристалл-патроны: по одному, раз в ~5 с
				if #B.crystals < 1 and now >= B.nextCrystal then
					B.nextCrystal = now + 5
					bossCrystal(run)
				end
				for k = #B.crystals, 1, -1 do
					local cr = B.crystals[k]
					if (cr.Position - pos).Magnitude <= 4.2 then
						cr:Destroy()
						table.remove(B.crystals, k)
						B.nextCrystal = now + 5
						run.ammo = math.min((run.ammo or 0) + 6, 99)
						send(run, "ammo", { Ammo = run.ammo, Got = 6 })
					end
				end
				-- патроны сами понемногу восстанавливаются
				if now >= B.nextRegen then
					B.nextRegen = now + 1
					if (run.ammo or 0) < 12 then
						run.ammo = (run.ammo or 0) + 1
						send(run, "ammo", { Ammo = run.ammo })
					end
				end
				-- полёт пуль
				local target = B.model:GetBoundingBox().Position
				for k = #B.bullets, 1, -1 do
					local b = B.bullets[k]
					local to = target - b.part.Position
					local step = 140 * 0.05
					if to.Magnitude <= step + 2 then
						b.part:Destroy()
						table.remove(B.bullets, k)
						bossDamage(run, 1)
						if run.vaultTried then
							break
						end
					else
						b.part.CFrame = CFrame.new(b.part.Position + to.Unit * step)
					end
				end
			end
			-- таймер или все монеты собраны
			if not run.vaultTried and (now >= run.ends or (run.room <= #R.ROOMS and #run.coins == 0 and not (W and W.left > 0))) then
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
