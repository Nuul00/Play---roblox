-- Доски лидеров для Sky Isles, Frozen Peaks, Magma Volcano и Cosmic Galaxy (в Meadow и Neon они стоят в плейсе).
-- В каждом мире свой стиль рамки и своя лёгкая анимация (её делает клиент, LeaderboardFX):
--   Sky     — облачная рамка, доски покачиваются на облаках;
--   Frozen  — ледяная рамка со снежной шапкой и искрами инея;
--   Volcano — обсидиан с лавовыми прожилками (пульсируют) и угольками;
--   Galaxy  — доски парят над полом, плавают и чуть покачиваются, вокруг звёздная пыль.
-- Место ищется автоматически: свободная ровная площадка недалеко от точки появления, доски смотрят на спавн.
-- Имена совпадают с теми, что ждёт WorldProgress: BoardCoins/BoardEggs/BoardPickups и Podium_<доска> с Place1..3/Plate1..3.
local CollectionService = game:GetService("CollectionService")

local B = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local BOARD_W, BOARD_H = 17, 7.2
local GAP = 3
local ORDER = { "BoardPickups", "BoardEggs", "BoardCoins" } -- слева направо, если смотреть со спавна (как в Meadow)

local THEMES = {
	SkyIsles = {
		Board = rgb(40, 70, 120), Frame = rgb(250, 250, 255), FrameMat = M.SmoothPlastic, Trim = rgb(255, 215, 110), TrimMat = M.Neon,
		Title = rgb(255, 225, 130), Sub = rgb(200, 235, 255), Legs = true, LegColor = rgb(235, 240, 255),
		Lift = 0, Float = { Bob = 0.45, Sway = 0.8, Speed = 0.7 },
		Steps = { rgb(255, 210, 80), rgb(225, 232, 245), rgb(240, 160, 100) }, StepMat = M.SmoothPlastic,
	},
	FrozenPeaks = {
		Board = rgb(20, 55, 95), Frame = rgb(170, 225, 255), FrameMat = M.Glacier, Trim = rgb(140, 230, 255), TrimMat = M.Neon,
		Title = rgb(190, 240, 255), Sub = rgb(150, 210, 255), Legs = true, LegColor = rgb(150, 205, 240), Snow = true,
		Lift = 0, Sparkle = rgb(200, 245, 255),
		Steps = { rgb(255, 215, 110), rgb(210, 235, 255), rgb(235, 165, 120) }, StepMat = M.Ice,
	},
	MagmaVolcano = {
		Board = rgb(28, 18, 18), Frame = rgb(40, 30, 32), FrameMat = M.Basalt, Trim = rgb(255, 110, 30), TrimMat = M.Neon,
		Title = rgb(255, 170, 70), Sub = rgb(255, 210, 150), Legs = true, LegColor = rgb(45, 35, 35), Pulse = true,
		Lift = 0, Embers = rgb(255, 140, 40),
		Steps = { rgb(255, 190, 60), rgb(190, 190, 200), rgb(210, 120, 70) }, StepMat = M.Basalt,
	},
	CosmicGalaxy = {
		Board = rgb(14, 10, 40), Frame = rgb(60, 50, 110), FrameMat = M.Metal, Trim = rgb(120, 230, 255), TrimMat = M.Neon, Trim2 = rgb(255, 110, 220),
		Title = rgb(255, 150, 240), Sub = rgb(140, 230, 255), Legs = false,
		Lift = 7, Float = { Bob = 1.1, Sway = 2.5, Speed = 0.5 }, Stardust = rgb(200, 190, 255),
		Steps = { rgb(255, 215, 110), rgb(200, 210, 255), rgb(240, 150, 200) }, StepMat = M.Glass,
	},
}

local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end
local GHOST = { CanCollide = false, CanQuery = false, CanTouch = false }

local function emitter(parent, color, rate, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Rate = rate
	e.Lifetime = NumberRange.new(1.5, 3)
	e.Speed = NumberRange.new(0.3, 1)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	if props then
		for k, v in props do
			e[k] = v
		end
	end
	e.Parent = parent
	return e
end

-- ===== поиск свободной площадки =====
local function isCoin(inst)
	return string.match(inst.Name, "^Coin_%d+$") ~= nil or inst:FindFirstAncestor("CoinFX") ~= nil
end
local BAD = { "Lava", "River", "Pond", "Water", "Rink", "Pool", "Bridge" }
local function badGround(inst)
	for _, k in BAD do
		if string.find(inst.Name, k, 1, true) then return true end
	end
	return false
end
local function groundAt(pos, ignore)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ignore
	rp.RespectCanCollide = true
	local hit = workspace:Raycast(pos + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), rp)
	-- второй луч видит и несталкиваемые детали (реки лавы, вода, берега): на них не ставим
	rp.RespectCanCollide = false
	local soft = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), rp)
	if soft and badGround(soft.Instance) then
		return nil
	end
	return hit
end
-- Важные объекты (их не трогаем и к ним не подходим вплотную) и мелкий декор (ёлки, кристаллы,
-- фонари, камни): декор, попавший на площадку досок, просто убираем — его в мире расставлено случайно.
local IMPORTANT = { "Portal", "EggStand", "Shop", "Machine", "Chest", "Statue", "Podium", "Board", "Spawn", "Start",
	"Mountain", "Volcano", "Pond", "Lake", "Bridge", "Igloo", "Rink", "Observatory", "Monument", "Fountain", "Windmill",
	"Tower", "House", "Arch", "Gate", "Wall", "Lava", "River", "Planet", "Island", "Balloon", "Rainbow", "Sign", "Leaderboard" }
local function isImportant(full)
	for _, k in IMPORTANT do
		if string.find(full, k, 1, true) then
			return true
		end
	end
	return false
end
local function decorRoot(q, model)
	local r = q
	-- поднимаемся до отдельной вещи (фонарь, ёлка), но не до общего контейнера декора с десятками детей
	while r.Parent and r.Parent ~= model and r.Parent ~= workspace and not r.Parent:IsA("Folder") and #r.Parent:GetChildren() <= 12 do
		r = r.Parent
	end
	return r
end
local allParts -- все детали workspace (один раз на все миры)
local function collectObstacles(model, spawn, groundY, pad)
	if not allParts then
		allParts = {}
		for i, q in workspace:GetDescendants() do
			if i % 8000 == 0 then task.wait() end
			if q:IsA("BasePart") and not q:IsDescendantOf(workspace.Terrain) then
				table.insert(allParts, q)
			end
		end
	end
	local list = {}
	local rootBig = {}
	for i, q in allParts do
		if i % 4000 == 0 then task.wait() end
		if q.Parent and (q.Position - spawn).Magnitude < 260 and not isCoin(q) and not (q.Parent and isCoin(q.Parent)) and not q.Parent:FindFirstChildOfClass("Humanoid") then
			local h = q.Size.Y
			local top, bottom = q.Position.Y + h / 2, q.Position.Y - h / 2
			local big = math.max(q.Size.X, q.Size.Z) > 300 -- пол мира, небо, кольцо-граница
			-- низкие площадки (плаза, ступенька, дорожка) — это пол, по нему ходят
			local flat = top < groundY + 0.8 or (q.Size.Y < 6 and top < groundY + 2.6 and math.max(q.Size.X, q.Size.Z) > 6)
			local away = bottom > groundY + 30 or top < groundY - 20
			local invisible = q.Transparency >= 0.99 and not q.CanCollide
			if flat and not away and not invisible and not big and badGround(q) then flat = false end -- реки лавы, пруды, каток
			if not big and not flat and not away and not invisible then
				-- имя считаем относительно мира: «MagmaVolcano» в пути есть у всего мира, это не «вулкан»
				local full = q:GetFullName()
				local mf = model:GetFullName()
				if string.sub(full, 1, #mf) == mf then full = string.sub(full, #mf + 1) end
				-- крупное (острова, скалы, дома) тоже не трогаем, даже если оно без «важного» имени
				local important = isImportant(full) or not q:IsDescendantOf(model) or math.max(q.Size.X, q.Size.Z) > 25
				if not important then
					local root = decorRoot(q, model)
					if root:IsA("Model") then
						if rootBig[root] == nil then
							local _, ext = root:GetBoundingBox()
							rootBig[root] = math.max(ext.X, ext.Z) > 30
						end
						important = rootBig[root]
					end
				end
				local r = math.min(math.max(q.Size.X, q.Size.Z) / 2, important and 40 or 6)
				if important and (string.find(full, "Portal", 1, true) or string.find(full, "EggStand", 1, true) or string.find(full, "Shop", 1, true) or string.find(full, "Machine", 1, true)) then
					r += pad -- там толпятся игроки и к ним подходят
				end
				table.insert(list, { q.Position, r, top - groundY, important, (not important) and decorRoot(q, model) or nil, full })
			end
		end
	end
	return list
end
local function findSpot(model, spawn, groundY, ignore, relaxed, pad)
	local width = #ORDER * BOARD_W + (#ORDER - 1) * GAP + 6
	local depth = 24 -- доска + пьедестал + проход перед ним
	local obstacles = collectObstacles(model, spawn, groundY, pad)
	local best, bestScore, bestClear
	local tried, passed, gfail, ofail = 0, 0, 0, 0
	local blockers = {}
	-- точки проверки пола: сетка каждые ~6 стадов по всей площадке (дорожка 18 шириной не проскочит)
	local samples = {}
	for x = -width / 2, width / 2 + 0.01, width / 10 do
		for _, z in { -depth / 2 - 4, -4, depth / 2 - 4 } do
			table.insert(samples, Vector3.new(x, 0, z))
		end
	end
	for r = 36, 150, 8 do
		task.wait() -- не держим сервер одним длинным циклом
		for deg = 0, 350, 10 do
			tried += 1
			local a = math.rad(deg)
			local c = Vector3.new(spawn.X + math.cos(a) * r, groundY, spawn.Z + math.sin(a) * r)
			local look = Vector3.new(spawn.X - c.X, 0, spawn.Z - c.Z).Unit
			local cf = CFrame.lookAt(c, c + look)
			-- пол везде под площадкой и на одной высоте
			local ok = true
			for _, off in samples do
				local hit = groundAt(cf:PointToWorldSpace(off), ignore)
				if not hit or math.abs(hit.Position.Y - groundY) > 2.5 or (not relaxed and (string.find(hit.Instance.Name, "Path", 1, true) or string.find(hit.Instance.Name, "Plaza", 1, true))) or badGround(hit.Instance) then
					ok = false
					gfail += 1
					break
				end
			end
			local clear = {}
			if ok then
				-- пространственные запросы не видят детали с CanQuery=false (декор, арки), поэтому проверяем по списку
				for _, o in obstacles do
					local lp = cf:PointToObjectSpace(o[1]) + Vector3.new(0, 0, 4) -- центр площадки сдвинут к пьедесталам
					local inside = math.abs(lp.X) < width / 2 + o[2] and math.abs(lp.Z) < depth / 2 + o[2]
					-- перед досками (к спавну) — «коридор обзора»: высокое там закрывало бы доски
					local view = o[3] > 4 and math.abs(lp.X) < width / 2 and lp.Z < 0 and lp.Z > -(depth / 2 + 26)
					if inside or view then
						if o[4] then
							ok = false
							ofail += 1
							blockers[o[6]] = (blockers[o[6]] or 0) + 1
							break
						end
						clear[o[5]] = true
					end
				end
			end
			if ok then
				passed += 1
				local n = 0
				for _ in clear do n += 1 end
				-- ближе к спавну и меньше убирать декора — лучше; за спиной игрока (к порталу, +Z) — хуже
				local score = r + n * 4 + (math.sin(a) > 0.3 and 70 or 0)
				if not bestScore or score < bestScore then
					best, bestScore, bestClear = cf, score, clear
				end
			end
		end
	end
	local top = {}
	for k, v in blockers do table.insert(top, { k, v }) end
	table.sort(top, function(x, y) return x[2] > y[2] end)
	local names = {}
	for i = 1, math.min(6, #top) do table.insert(names, top[i][1] .. "=" .. top[i][2]) end
	model:SetAttribute("LeaderboardBlockers", table.concat(names, " ; "))
	model:SetAttribute("LeaderboardSpot", string.format("tried %d ok %d ground-fail %d obj-fail %d obstacles %d", tried, passed, gfail, ofail, #obstacles))
	if best then
		for root in bestClear do
			if root.Parent then root:Destroy() end
		end
	end
	return best
end

-- ===== сборка =====
local function buildBoard(model, theme, name, cf)
	local rig = Instance.new("Model")
	rig.Name = "Rig_" .. name
	rig.Parent = model
	local lift = theme.Lift or 0
	local center = cf * CFrame.new(0, lift + 3.2 + BOARD_H / 2, 0)
	local board = part(rig, name, Vector3.new(BOARD_W, BOARD_H, 0.6), center, theme.Board, M.SmoothPlastic, { CanCollide = true })
	board:SetAttribute("TitleColor", theme.Title)
	board:SetAttribute("SubColor", theme.Sub)
	board:SetAttribute("NoLight", true)
	board:SetAttribute("TrimColor", theme.Trim)
	local t = 1.1
	local fw, fh = BOARD_W + t * 2, BOARD_H + t * 2
	for _, b in {
		{ "FrameTop", Vector3.new(fw, t, 1.4), CFrame.new(0, BOARD_H / 2 + t / 2, 0.2) },
		{ "FrameBottom", Vector3.new(fw, t, 1.4), CFrame.new(0, -BOARD_H / 2 - t / 2, 0.2) },
		{ "FrameLeft", Vector3.new(t, fh, 1.4), CFrame.new(-BOARD_W / 2 - t / 2, 0, 0.2) },
		{ "FrameRight", Vector3.new(t, fh, 1.4), CFrame.new(BOARD_W / 2 + t / 2, 0, 0.2) },
	} do
		part(rig, b[1], b[2], center * b[3], theme.Frame, theme.FrameMat, GHOST)
	end
	-- светящийся кант по контуру доски (спереди)
	for i, b in {
		{ Vector3.new(BOARD_W + 0.2, 0.22, 0.2), CFrame.new(0, BOARD_H / 2 + 0.05, -0.45) },
		{ Vector3.new(BOARD_W + 0.2, 0.22, 0.2), CFrame.new(0, -BOARD_H / 2 - 0.05, -0.45) },
		{ Vector3.new(0.22, BOARD_H + 0.2, 0.2), CFrame.new(-BOARD_W / 2 - 0.05, 0, -0.45) },
		{ Vector3.new(0.22, BOARD_H + 0.2, 0.2), CFrame.new(BOARD_W / 2 + 0.05, 0, -0.45) },
	} do
		local color = theme.Trim2 and i % 2 == 0 and theme.Trim2 or theme.Trim
		local trim = part(rig, "Trim", b[1], center * b[2], color, theme.TrimMat, GHOST)
		if theme.Pulse then
			CollectionService:AddTag(trim, "BoardPulse")
		end
	end
	-- ножки для «наземных» миров
	if theme.Legs then
		for _, x in { -BOARD_W / 2 + 1.5, BOARD_W / 2 - 1.5 } do
			local h = lift + 3.2
			part(rig, "Leg", Vector3.new(1, h + 0.5, 1), cf * CFrame.new(x, h / 2, 0.4), theme.LegColor, theme.FrameMat)
		end
	end
	-- стиль мира
	if theme.Snow then
		part(rig, "SnowCap", Vector3.new(fw + 0.6, 0.7, 2), center * CFrame.new(0, fh / 2 + 0.2, 0.2), rgb(250, 252, 255), M.Snow, GHOST)
		for i = -3, 3 do
			local len = 0.8 + (i % 3) * 0.5
			part(rig, "Icicle", Vector3.new(0.35, len, 0.35), center * CFrame.new(i * 3.1, -fh / 2 - len / 2, -0.3), rgb(190, 235, 255), M.Ice, GHOST)
		end
	end
	if model.Name == "SkyIsles" then
		for i = -2, 2 do
			local d = 4.6 - math.abs(i) * 0.4
			local puff = part(rig, "CloudPuff", Vector3.new(d, d, d), cf * CFrame.new(i * 4.4, 1.6 + (i % 2) * 0.5, 0.3), rgb(255, 255, 255), M.SmoothPlastic, GHOST)
			puff.Shape = Enum.PartType.Ball
		end
	end
	if theme.Embers then
		local src = part(rig, "Embers", Vector3.new(BOARD_W, 0.2, 1), cf * CFrame.new(0, 0.3, -0.6), theme.Embers, M.SmoothPlastic, GHOST)
		src.Transparency = 1
		emitter(src, theme.Embers, 4, {
			Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(10, 10), EmissionDirection = Enum.NormalId.Top,
			Lifetime = NumberRange.new(1.5, 2.5), Acceleration = Vector3.new(0, 1, 0),
		})
	end
	if theme.Sparkle then
		emitter(board, theme.Sparkle, 3, { EmissionDirection = Enum.NormalId.Front })
	end
	if theme.Stardust then
		local glow = part(rig, "Thruster", Vector3.new(BOARD_W * 0.7, 0.3, 2.4), center * CFrame.new(0, -fh / 2 - 1.2, 0.2), theme.Trim, M.Neon, GHOST)
		glow.Transparency = 0.35
		emitter(glow, theme.Stardust, 5, {
			EmissionDirection = Enum.NormalId.Bottom, Speed = NumberRange.new(1, 2.5), SpreadAngle = Vector2.new(25, 25),
			Lifetime = NumberRange.new(1, 2),
		})
		emitter(board, theme.Stardust, 3, { Speed = NumberRange.new(0.2, 0.6) })
		local l = Instance.new("PointLight")
		l.Color = theme.Trim
		l.Range = 16
		l.Brightness = 1.2
		l.Parent = glow
	end
	if theme.Float then
		CollectionService:AddTag(rig, "BoardFloat")
		rig:SetAttribute("Bob", theme.Float.Bob)
		rig:SetAttribute("Sway", theme.Float.Sway)
		rig:SetAttribute("Speed", theme.Float.Speed)
		rig:SetAttribute("Phase", #model:GetChildren() * 0.9)
	end
	rig.PrimaryPart = board
	return board
end

local function buildPodium(model, theme, name, cf)
	local podium = Instance.new("Model")
	podium.Name = "Podium_" .. name
	local look = cf.LookVector
	podium:SetAttribute("Yaw", math.atan2(-look.X, -look.Z))
	podium.Parent = model
	-- если смотреть со спавна: 2 слева, 1 по центру, 3 справа (правая сторона доски = левая для зрителя)
	local H = { 2.6, 1.8, 1.2 }
	local X = { 0, 4.2, -4.2 }
	local base = cf * CFrame.new(0, 0, -6)
	part(podium, "Base", Vector3.new(14.6, 0.5, 5.2), base * CFrame.new(0, 0.25, 0), theme.Frame, theme.FrameMat)
	local rim = part(podium, "Rim", Vector3.new(14.8, 0.18, 5.4), base * CFrame.new(0, 0.55, 0), theme.Trim, M.Neon, GHOST)
	rim.Transparency = 0.2
	for place = 1, 3 do
		local h = H[place]
		local step = part(podium, "Place" .. place, Vector3.new(4, h, 4), base * CFrame.new(X[place], 0.5 + h / 2, 0), theme.Steps[place], theme.StepMat)
		local plate = part(podium, "Plate" .. place, Vector3.new(3.4, math.min(1.1, h - 0.2), 0.2), step.CFrame * CFrame.new(0, -h / 2 + 0.7, -2.08), rgb(48, 44, 86), M.SmoothPlastic, GHOST)
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.CanvasSize = Vector2.new(200, 60)
		g.LightInfluence = 0
		g.Parent = plate
		local tl = Instance.new("TextLabel")
		tl.Name = "PlayerName"
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.fromScale(1, 1)
		tl.Font = Enum.Font.FredokaOne
		tl.TextScaled = true
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.Text = "—"
		tl.Parent = g
		local num = Instance.new("SurfaceGui")
		num.Face = Enum.NormalId.Top
		num.CanvasSize = Vector2.new(100, 100)
		num.LightInfluence = 0
		num.Parent = step
	end
	return podium
end

function B.Build(world)
	local built = {}
	for key, theme in THEMES do
		local model = world:WaitForChild(key, 60)
		if not model or model:FindFirstChild("BoardCoins", true) then
			continue
		end
		local spawn = model:GetAttribute("Spawn")
		if typeof(spawn) ~= "Vector3" then
			continue
		end
		local players = {}
		for _, p in game:GetService("Players"):GetPlayers() do
			if p.Character then
				table.insert(players, p.Character)
			end
		end
		local hit = groundAt(spawn, players)
		local groundY = hit and hit.Position.Y or spawn.Y - 4
		-- сначала ищем место вне дорожек; если мир плотный (Volcano) — разрешаем стоять у дорожки
		-- сначала с большим отступом от магазинов/яиц/порталов, потом поскромнее, потом и у дорожки
		local cf = findSpot(model, spawn, groundY, players, false, 22)
			or findSpot(model, spawn, groundY, players, false, 12)
			or findSpot(model, spawn, groundY, players, true, 12)
		if not cf then
			warn("[Leaderboards] no free spot in " .. key)
			continue
		end
		local width = BOARD_W + GAP
		for i, name in ORDER do
			-- для зрителя слева направо: Pickups, Eggs, Coins (правый вектор доски = левая сторона зрителя)
			local boardCf = cf * CFrame.new((2 - i) * width, 0, 0)
			buildBoard(model, theme, name, boardCf)
			buildPodium(model, theme, name, boardCf)
		end
		-- монеты, что лежали на месте досок/пьедесталов, переносим вперёд, к спавну (иначе они внутри досок)
		local footprint = cf * CFrame.new(0, 12, -2)
		local rng = Random.new(#key)
		local size = Vector3.new(#ORDER * width + 6, 30, 24)
		for _, c in model:GetChildren() do
			if c:IsA("BasePart") and isCoin(c) then
				local lp = footprint:PointToObjectSpace(c.Position)
				if math.abs(lp.X) < size.X / 2 and math.abs(lp.Y) < size.Y / 2 and math.abs(lp.Z) < size.Z / 2 then
					-- вперёд за площадку и чуть врассыпную, чтобы монеты не слиплись кучкой
					local jitter = rng:NextNumber(-10, 10)
					c.Position = c.Position + cf.LookVector * (lp.Z + size.Z / 2 + rng:NextNumber(4, 14)) + cf.RightVector * jitter
				end
			end
		end
		table.insert(built, model)
	end
	return built
end

return B
