-- Оформление досок лидеров: объёмная табличка-«пилюля» с названием и 3D-эмблема над ней.
--   COINS   — монета мира (Tripo-модель монеты, где она есть; иначе собранная золотая монета с ободком);
--   EGGS    — Tripo-модель яйца этого мира;
--   PICKUPS — три маленькие монеты мира, кружащие хороводом.
-- Эмблемы помечены тегом BoardEmblem (Spin °/с, Bob studs) — вращает их клиент (LeaderboardFX).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local D = {}

local rgb = Color3.fromRGB
D.TITLE_FONT = Enum.Font.LuckiestGuy
D.BODY_FONT = Enum.Font.FredokaOne

-- Стиль каждого мира: цвета таблички, кант, монеты и яйцо для эмблем.
local WORLD = {
	Meadow = { Rim = rgb(255, 255, 255), Coin = rgb(255, 196, 40), Egg = 2 },
	Neon = { Rim = rgb(255, 90, 220), Coin = rgb(255, 210, 60), Egg = 5, Neon = true },
	SkyIsles = { Rim = rgb(255, 230, 140), Coin = rgb(255, 205, 70), Egg = 8 },
	FrozenPeaks = { Rim = rgb(150, 230, 255), Coin = rgb(170, 225, 255), Egg = 17, Coins = { "CoinAurora", "CoinIce", "CoinCrystal" } },
	MagmaVolcano = { Rim = rgb(255, 120, 40), Coin = rgb(255, 150, 50), Egg = 11, Coins = { "CoinMagma", "CoinEmber", "CoinObsidian" } },
	CosmicGalaxy = { Rim = rgb(130, 230, 255), Coin = rgb(200, 160, 255), Egg = 14, Coins = { "CoinCosmic", "CoinNebula", "CoinStardust" } },
}
local BOARD = {
	BoardCoins = { Text = "COINS", Plate = rgb(255, 190, 40), Plate2 = rgb(255, 225, 110), Ink = rgb(130, 70, 0) },
	BoardEggs = { Text = "EGGS", Plate = rgb(90, 200, 255), Plate2 = rgb(170, 235, 255), Ink = rgb(15, 60, 130) },
	BoardPickups = { Text = "PICKUPS", Plate = rgb(185, 110, 255), Plate2 = rgb(225, 180, 255), Ink = rgb(70, 20, 120) },
	-- одна большая доска с вкладками
	BoardMain = { Text = "LEADERBOARD", Plate = rgb(255, 185, 40), Plate2 = rgb(255, 225, 120), Ink = rgb(120, 60, 0) },
}

local function ghost(p)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end
local function part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	ghost(p)
	p.Parent = parent
	return p
end

-- Копия Tripo-модели размером `size` (по большей стороне) с центром в `center`.
local function fitModel(template, size, center, parent, name)
	local m = template:Clone()
	m.Name = name or template.Name
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			ghost(d)
		end
	end
	local _, ext = m:GetBoundingBox()
	pcall(function()
		m:ScaleTo(m:GetScale() * size / math.max(ext.X, ext.Y, ext.Z, 0.01))
	end)
	local cf = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(cf)
	m:PivotTo(center * offset:Inverse())
	-- точка вращения — центр модели (иначе при вращении она «гуляет» по кругу)
	m.PrimaryPart = nil
	m.WorldPivot = center
	m.Parent = parent
	return m
end
local function prop(name)
	local f = ReplicatedStorage:FindFirstChild("TripoProps")
	return f and f:FindFirstChild(name)
end
local function eggTemplate(id)
	local f = ReplicatedStorage:FindFirstChild("TripoEggs")
	return f and f:FindFirstChild("Egg" .. id)
end

-- Собранная монета: тёмный ободок, светлое лицо с выпуклым знаком с двух сторон.
-- `cf` смотрит лицом вдоль LookVector.
local function builtCoin(parent, d, cf, color, sign)
	local m = Instance.new("Model")
	m.Name = "Coin"
	local face = cf * CFrame.Angles(0, math.rad(90), 0) -- ось цилиндра (X) — вдоль взгляда
	part(m, "Rim", Vector3.new(d * 0.16, d, d), face, color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Metal, Enum.PartType.Cylinder).Reflectance = 0.1
	local inner = part(m, "Face", Vector3.new(d * 0.2, d * 0.8, d * 0.8), face, color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	inner.Reflectance = 0.18
	part(m, "Ring", Vector3.new(d * 0.22, d * 0.66, d * 0.66), face, color:Lerp(Color3.new(0, 0, 0), 0.12), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	part(m, "Center", Vector3.new(d * 0.24, d * 0.58, d * 0.58), face, color:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	for _, side in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local g = Instance.new("SurfaceGui")
		g.Face = side
		g.CanvasSize = Vector2.new(200, 200)
		g.LightInfluence = 0.3
		g.Parent = m.Center
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(0.5, 0.54)
		t.Size = UDim2.fromScale(0.62, 0.62)
		t.Font = D.TITLE_FONT
		t.TextScaled = true
		t.Text = sign or "$"
		t.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.55)
		t.Parent = g
		local st = Instance.new("UIStroke")
		st.Thickness = 5
		st.Color = color:Lerp(Color3.new(0, 0, 0), 0.45)
		st.Parent = t
	end
	m.PrimaryPart = m.Rim
	m.Parent = parent
	return m
end

local function coinModel(parent, w, size, cf, index)
	local name = w.Coins and w.Coins[index or 1]
	local t = name and prop(name)
	if t then
		return fitModel(t, size, cf, parent, "Coin")
	end
	return builtCoin(parent, size, cf, w.Coin)
end

local function glow(model, color, bright)
	local p = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not p then
		return
	end
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = 12
	l.Brightness = bright or 1.4
	l.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Rate = 5
	e.Lifetime = NumberRange.new(0.8, 1.6)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Parent = p
end

-- Табличка-«пилюля»: корпус + полукруглые торцы, светящийся кант сзади, текст спереди и сзади
-- (холст по пропорциям корпуса — буквы не растягиваются).
local function plate(parent, b, w, center, k)
	local H, T = 3.4 * k, 1.3 * k
	local len = (1.4 + #b.Text * 1.85) * k
	local body = part(parent, "TitlePlate", Vector3.new(len, H, T), center, b.Plate)
	-- верхняя светлая половина — «глянец»
	part(parent, "TitleGloss", Vector3.new(len, H * 0.42, T + 0.04), center * CFrame.new(0, H * 0.27, 0), b.Plate2)
	for _, x in { -len / 2, len / 2 } do
		part(parent, "TitleCap", Vector3.new(T, H, H), center * CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad(90), 0), b.Plate, nil, Enum.PartType.Cylinder)
	end
	local rimC = w.Rim
	local rim = part(parent, "TitleRim", Vector3.new(len, H + 0.6 * k, 0.5), center * CFrame.new(0, 0, T / 2 - 0.1), rimC, Enum.Material.Neon)
	for _, x in { -len / 2, len / 2 } do
		part(parent, "TitleRimCap", Vector3.new(0.5, H + 0.6 * k, H + 0.6 * k), center * CFrame.new(x, 0, T / 2 - 0.1) * CFrame.Angles(0, math.rad(90), 0), rimC, Enum.Material.Neon, Enum.PartType.Cylinder)
	end
	rim.Transparency = 0.1
	local px = 60 / k
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = px
		g.LightInfluence = 0
		g.Brightness = 1.3
		g.MaxDistance = 180
		g.Parent = body
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(0.5, 0.52)
		t.Size = UDim2.new(1, -0.2 * px, 0.84, 0)
		t.Font = D.TITLE_FONT
		t.TextScaled = true
		t.Text = b.Text
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Parent = g
		local st = Instance.new("UIStroke")
		st.Thickness = 6
		st.Color = b.Ink
		st.LineJoinMode = Enum.LineJoinMode.Round
		st.Parent = t
	end
	return body, H
end

-- worldKey: Meadow | Neon | SkyIsles | FrozenPeaks | MagmaVolcano | CosmicGalaxy
function D.Decorate(board, worldKey, topY)
	local b = BOARD[board.Name]
	local w = WORLD[worldKey] or WORLD.Meadow
	if not b or board.Parent:FindFirstChild(board.Name .. "_3D") then
		return
	end
	local m = Instance.new("Model")
	m.Name = board.Name .. "_3D"
	m.Parent = board.Parent
	local cf = board.CFrame
	local base = cf * CFrame.new(0, topY - board.Position.Y, 0)
	-- крупные доски (Meadow, Neon) получают пропорционально крупные табличку и эмблему
	local k = board.Name == "BoardMain" and 1.5 or math.clamp(board.Size.X / 17, 1, 2.2)
	local plateCf = base * CFrame.new(0, 2.3 * k, 0)
	local _, H = plate(m, b, w, plateCf, k)
	local center = plateCf * CFrame.new(0, H / 2 + 3.6 * k, 0)
	local function make(kind, at, scale)
		local emblem
		if kind == "BoardCoins" then
			emblem = coinModel(m, w, 5.2 * scale, at, 1)
			emblem:SetAttribute("Spin", 80)
			emblem:SetAttribute("Bob", 0.35)
		elseif kind == "BoardEggs" then
			local t = eggTemplate(w.Egg)
			if t then
				emblem = fitModel(t, 5.4 * scale, at, m, "Egg")
			else
				emblem = Instance.new("Model")
				emblem.Name = "Egg"
				local e = part(emblem, "Shell", Vector3.new(4, 5, 4) * scale, at, rgb(170, 230, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = e
				emblem.PrimaryPart = e
				emblem.Parent = m
			end
			emblem:SetAttribute("Spin", 35)
			emblem:SetAttribute("Bob", 0.5)
		else
			-- хоровод из трёх монет вокруг центра
			emblem = Instance.new("Model")
			emblem.Name = "Pickups"
			local hub = part(emblem, "Hub", Vector3.new(0.2, 0.2, 0.2), at, w.Coin)
			hub.Transparency = 1
			emblem.PrimaryPart = hub
			for i = 1, 3 do
				local a = (i - 1) * math.pi * 2 / 3
				local pos = at * CFrame.Angles(0, a, 0) * CFrame.new(0, ((i == 2) and 0.6 or -0.3) * scale, -2.1 * scale)
				coinModel(emblem, w, 2.6 * scale, pos * CFrame.Angles(0, math.rad(90), 0), i)
			end
			emblem.Parent = m
			emblem:SetAttribute("Spin", 70)
			emblem:SetAttribute("Bob", 0.3)
		end
		glow(emblem, kind == "BoardEggs" and (BOARD.BoardEggs.Plate2) or w.Coin, w.Neon and 4 or nil) -- в тёмном Неоне подсвечиваем сильнее
		CollectionService:AddTag(emblem, "BoardEmblem")
		return emblem
	end
	if board.Name == "BoardMain" then
		-- над большой доской: монета слева, яйцо по центру, хоровод монет справа — как вкладки
		local half = board.Size.X / 2
		make("BoardCoins", center * CFrame.new(-half + 6 * k, -1.5 * k, 0), k)
		make("BoardEggs", center, k)
		make("BoardPickups", center * CFrame.new(half - 6 * k, -1.5 * k, 0), k)
	else
		make(board.Name, center, k)
	end
	return m
end

return D
