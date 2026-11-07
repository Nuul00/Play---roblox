-- Меню прокачки в киоске (скорость, магнит, доход) и магазин магнитов (магниты, прокачка, зелья).
-- Открывает сервер, когда игрок заходит в зелёный круг; закрывается, когда игрок выходит из круга.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local MagnetVisuals = require(ReplicatedStorage:WaitForChild("MagnetVisuals"))
local buy = ReplicatedStorage:WaitForChild("GameShopBuy")
local stats = player:WaitForChild("leaderstats")
local coins = stats:WaitForChild("Coins")
local speed = stats:WaitForChild("SpeedLevel")
local dark = Color3.fromRGB(30, 30, 42)

local gui = Instance.new("ScreenGui")
gui.Name = "ShopPanels"
gui.ResetOnSpawn = false
gui.DisplayOrder = 22
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(p, r)
	Instance.new("UICorner", p).CornerRadius = UDim.new(0, r)
end
local function stroke(p, t, c)
	local s = Instance.new("UIStroke")
	s.Thickness = t
	s.Color = c or dark
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end
local function label(parent, text, pos, size, textSize, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextSize = textSize
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = font or Enum.Font.FredokaOne
	l.TextWrapped = true
	l.Parent = parent
	return l
end
local function button(parent, text, pos, size, color)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.Text = text
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 18
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color
	b.Parent = parent
	corner(b, 12)
	stroke(b, 2.5)
	return b
end
-- Сочная заливка: сверху светлее, снизу темнее.
local function gradient(p, color, light, darkness)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), light or 0.35), color:Lerp(Color3.new(0, 0, 0), darkness or 0.25))
	g.Rotation = 90
	g.Parent = p
	p.BackgroundColor3 = Color3.new(1, 1, 1) -- UIGradient умножается на цвет фона
	return g
end
-- Глянцевый блик в верхней половине круга или кнопки.
local function gloss(p, r)
	local g = Instance.new("Frame")
	g.Name = "Gloss"
	g.BackgroundColor3 = Color3.new(1, 1, 1)
	g.BackgroundTransparency = 0.6
	g.AnchorPoint = Vector2.new(0.5, 0)
	g.Position = UDim2.new(0.5, 0, 0.07, 0)
	g.Size = UDim2.fromScale(0.78, 0.4)
	g.ZIndex = p.ZIndex + 1
	g.Parent = p
	corner(g, r)
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new(0.1, 1)
	fade.Parent = g
end
-- Иконка-конфета: свечение позади, кольцо с градиентом, белая обводка, глянец, тень под эмодзи
-- и лёгкое покачивание. ring — цвет кольца (ступень прокачки), color — цвет самой иконки.
local function juicyIcon(parent, icon, color, ringColor, size, pos)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = pos
	holder.Size = UDim2.fromOffset(size, size)
	holder.Parent = parent
	-- Ореол: полупрозрачный круг цвета иконки с мягкой широкой обводкой.
	local glow = Instance.new("Frame")
	glow.BackgroundColor3 = color
	glow.BackgroundTransparency = 0.55
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(1.3, 1.3)
	glow.Parent = holder
	corner(glow, size * 2)
	local halo = stroke(glow, 8, color)
	halo.Transparency = 0.7
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundColor3 = ringColor
	ring.Parent = holder
	corner(ring, size)
	gradient(ring, ringColor, 0.45, 0.2)
	stroke(ring, 3.5, Color3.new(1, 1, 1))
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(0.8, 0.8)
	inner.BackgroundColor3 = color
	inner.Parent = ring
	corner(inner, size)
	gradient(inner, color, 0.4, 0.35)
	stroke(inner, 2, color:Lerp(Color3.new(0, 0, 0), 0.45))
	gloss(inner, size)
	local shadow = label(inner, icon, UDim2.new(0, 3, 0, 4), UDim2.fromScale(1, 1), math.floor(size * 0.62), Color3.new(0, 0, 0))
	shadow.TextTransparency = 0.6
	shadow.ZIndex = inner.ZIndex + 2
	local text = label(inner, icon, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), math.floor(size * 0.62))
	text.ZIndex = inner.ZIndex + 3
	-- Покачивание и «дыхание» свечения; останавливаются вместе с окном (Destroy при перерисовке).
	ring.Rotation = -6
	TweenService:Create(ring, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 6 }):Play()
	TweenService:Create(glow, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.8, Size = UDim2.fromScale(1.5, 1.5) }):Play()
	return holder, ring
end

-- Цены, показанные в окне: окно перерисовываем, только когда монеты пересекают одну из них.
local shownPrices = {}
local recording = false
local NumberFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberFormat"))
local function fmt(n)
	if recording then
		table.insert(shownPrices, n)
	end
	return NumberFormat.Short(n)
end

-- Два окна в стиле UIKit (как DAILY / инвентарь): широкое для киоска прокачки и узкое для магазина магнитов.
local K = require(ReplicatedStorage:WaitForChild("UIKit"))
local rgb = Color3.fromRGB
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local COIN_IMG = ShopConfig.RewardImages.CoinPile
local panels = {}
local function makePanel(key, w, pillW, titleColors)
	local p, cl, sc, tl = K.window(gui, "Shop_" .. key, w, 452, "UPGRADE KIOSK", titleColors, pillW)
	p.AnchorPoint = Vector2.new(1, 0.5)
	p.Position = UDim2.new(1, -20, 0.5, 16)
	panels[key] = { panel = p, close = cl, scale = sc, title = tl }
	return panels[key]
end
makePanel("upgrades", 860, 380, K.ORANGE)
do
	local pill = panels.upgrades.panel:FindFirstChild("TitlePill")
	local em = Instance.new("ImageLabel")
	em.BackgroundTransparency = 1
	em.Image = ShopConfig.UpgradeImages.kiosk
	em.Position = UDim2.fromOffset(-34, -18)
	em.Size = UDim2.fromOffset(88, 88)
	em.Rotation = -10
	em.ZIndex = 3
	em.Parent = pill
	panels.upgrades.title.Position = UDim2.fromOffset(46, 6)
	panels.upgrades.title.Size = UDim2.new(1, -56, 1, -10)
end
makePanel("magnets", 640, 320, K.RED)
local window, title, scale, close = panels.upgrades.panel, panels.upgrades.title, panels.upgrades.scale, panels.upgrades.close
-- кошелёк: плашка с монетами слева от заголовка
local walletChip = K.frame(window, UDim2.fromOffset(22, 18), UDim2.fromOffset(170, 40), WHITE, 20)
K.grad(walletChip, rgb(70, 46, 140), rgb(36, 22, 80))
K.stroke(walletChip, K.GOLD, 2.5)
local walletIcon = Instance.new("ImageLabel")
walletIcon.BackgroundTransparency = 1
walletIcon.Position = UDim2.fromOffset(5, 3) -- внутри плашки, не вылезает за край
walletIcon.Size = UDim2.fromOffset(34, 34)
walletIcon.Image = COIN_IMG
walletIcon.Parent = walletChip
local wallet = K.text(walletChip, "", UDim2.fromOffset(44, 4), UDim2.new(1, -52, 1, -8), 24, K.GOLD, 2)
wallet.TextXAlignment = Enum.TextXAlignment.Left
local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(14, 72)
body.Size = UDim2.fromOffset(832, 366)
body.Parent = window
local function usePanel(key)
	local P = panels[key]
	for k, o in pairs(panels) do
		if k ~= key then
			o.panel.Visible = false
		end
	end
	window, title, scale, close = P.panel, P.title, P.scale, P.close
	body.Parent = window
	walletChip.Parent = window
end

local mode, zoneId
local zonePart
local spinning = {}

-- Карточка прокачки: иконка в круге цвета ступени, уровень «N / предел мира», значения до/после, кнопка.
-- Предел зависит от магазина: Meadow 10, Neon 25, Sky 50 (Config.ZoneMax); цены растут с уровнем.
local upgradeDefs = {
	speed = { Title = "SPEED", Image = ShopConfig.UpgradeImages.speed, Icon = "⚡", Accent = Color3.fromRGB(80, 170, 255), Global = Config.MaxSpeedLevel,
		Level = function() return speed.Value end, Cost = Config.GetUpgradeCost,
		Value = function(l) return tostring(Config.GetWalkSpeed(l)) end, Unit = "walk speed · +1% coins / lv" },
	magnet = { Title = "MAGNET", Image = ShopConfig.UpgradeImages.magnet, Icon = "🧲", Accent = Color3.fromRGB(230, 80, 90), Global = Config.MaxMagnetLevel,
		Level = function() return player:GetAttribute("MagnetLevel") or 0 end, Cost = Config.GetMagnetUpgradeCost,
		Value = function(l) return string.format("%.1f", Config.GetMagnetRadius(l)) end, Unit = "studs radius" },
	income = { Title = "COINS", Image = ShopConfig.UpgradeImages.income, Icon = "💰", Accent = Color3.fromRGB(255, 190, 40), Global = Config.MaxIncomeLevel,
		Level = function() return player:GetAttribute("IncomeLevel") or 0 end, Cost = Config.GetIncomeUpgradeCost,
		Value = function(l) return "x" .. string.format("%g", Config.GetIncomeMultiplier(l)) end, Unit = "coin income" },
	double = { Title = "DOUBLE", Image = ShopConfig.UpgradeImages.double, Icon = "✨", Accent = Color3.fromRGB(190, 110, 255), Global = Config.MaxDoubleLevel,
		Level = function() return player:GetAttribute("DoubleLevel") or 0 end, Cost = Config.GetDoubleUpgradeCost,
		Value = function(l) return string.format("%g%%", math.floor(Config.GetDoubleChance(l) * 1000 + 0.5) / 10) end, Unit = "double coin chance" },
}
local function orbIcon(card, d, size, y)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, y)
	holder.Size = UDim2.fromOffset(size, size)
	holder.Parent = card
	local glow = K.frame(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1.22, 1.22), d.Accent, UDim.new(1, 0))
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 0.7
	TweenService:Create(glow, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.88, Size = UDim2.fromScale(1.38, 1.38) }):Play()
	local orb = K.frame(holder, UDim2.new(), UDim2.fromScale(1, 1), WHITE, UDim.new(1, 0))
	K.grad(orb, d.Accent:Lerp(WHITE, 0.55), d.Accent:Lerp(BLACK, 0.35))
	K.stroke(orb, WHITE, 3.5)
	local shine = K.frame(orb, UDim2.fromScale(0.18, 0.08), UDim2.fromScale(0.64, 0.34), WHITE, UDim.new(1, 0))
	shine.BackgroundTransparency = 0.72
	local icon
	if d.Image then
		icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Image = d.Image
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Size = UDim2.fromOffset(size - 10, size - 10)
		icon.Parent = orb
	else
		icon = K.text(orb, d.Icon, UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.8, 0.8), math.floor(size * 0.6), nil, 0)
	end
	icon.Rotation = -6
	TweenService:Create(icon, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 6 }):Play()
	local pop = Instance.new("UIScale")
	pop.Parent = holder
	return holder, pop
end

local function upgradeCard(parent, kind, pos, size)
	local d = upgradeDefs[kind]
	local level = d.Level()
	local cap = math.min(d.Global, Config.ZoneMax[zoneId] or Config.BaseMaxLevel)
	local atCap = level >= cap
	local card = K.frame(parent, pos, size, WHITE, 20)
	K.grad(card, K.CARD:Lerp(d.Accent, 0.16), K.CARD2)
	K.stroke(card, d.Accent, 3)
	-- цветная шапка
	local band = K.frame(card, UDim2.new(), UDim2.new(1, 0, 0, 42), WHITE, 20)
	K.grad(band, d.Accent:Lerp(WHITE, 0.3), d.Accent:Lerp(BLACK, 0.15))
	local bandFill = K.frame(band, UDim2.new(0, 0, 1, -14), UDim2.new(1, 0, 0, 14), WHITE)
	K.grad(bandFill, d.Accent:Lerp(BLACK, 0.08), d.Accent:Lerp(BLACK, 0.15))
	K.text(band, d.Title, UDim2.fromOffset(8, 5), UDim2.new(1, -16, 1, -10), 24, nil, 2.5)
	-- иконка в светящемся шаре
	local _, pop = orbIcon(card, d, 100, 54)
	-- уровень: плашка и полоска прогресса до предела мира
	local lv = K.frame(card, UDim2.new(0.5, -58, 0, 160), UDim2.fromOffset(116, 26), WHITE, 13)
	K.grad(lv, rgb(80, 56, 150), rgb(44, 28, 96))
	K.stroke(lv, d.Accent, 2)
	K.text(lv, atCap and level >= d.Global and "MAX LEVEL" or string.format("LV %d / %d", level, cap), UDim2.fromOffset(6, 2), UDim2.new(1, -12, 1, -4), 18, nil, 1.5)
	local bar = K.frame(card, UDim2.new(0, 16, 0, 194), UDim2.new(1, -32, 0, 12), rgb(20, 12, 46), 6)
	K.stroke(bar, K.INK, 2)
	local fill = K.frame(bar, UDim2.new(), UDim2.fromScale(math.clamp(level / math.max(cap, 1), 0, 1), 1), WHITE, 6)
	K.grad(fill, d.Accent:Lerp(WHITE, 0.45), d.Accent, 0)
	if cap <= 12 then
		for k = 1, cap - 1 do
			local tick = K.frame(bar, UDim2.new(k / cap, -1, 0, 2), UDim2.new(0, 2, 1, -4), K.INK)
			tick.BackgroundTransparency = 0.4
		end
	end
	-- было → станет
	local nowText = d.Value(level)
	local nextText = level < d.Global and d.Value(level + 1) or nowText
	local val = K.text(card, "", UDim2.fromOffset(8, 214), UDim2.new(1, -16, 0, 32), 26, nil, 2)
	val.RichText = true
	val.Text = atCap and (nowText .. ' <font color="#FFD24A">MAX</font>') or (nowText .. ' <font color="#9CFF7A">→ ' .. nextText .. "</font>")
	K.text(card, string.upper(d.Unit), UDim2.fromOffset(8, 246), UDim2.new(1, -16, 0, 18), 14, rgb(190, 180, 235), 0)
	if atCap and level < d.Global then
		K.text(card, "more levels in the next world!", UDim2.fromOffset(8, 266), UDim2.new(1, -16, 0, 18), 14, K.GOLD, 1.5)
	end
	-- кнопки
	local price = atCap and 0 or d.Cost(level)
	local affordable = coins.Value >= price
	local b, lbl = K.button(card, level >= d.Global and "MAXED" or atCap and "MAX HERE" or fmt(price),
		UDim2.new(0, 10, 1, -58), UDim2.new(1, atCap and -20 or -86, 0, 48), atCap and K.GRAY or (affordable and K.GREEN or K.RED), 24)
	if not atCap then
		local ci = Instance.new("ImageLabel")
		ci.BackgroundTransparency = 1
		ci.Image = COIN_IMG
		ci.Position = UDim2.fromOffset(7, 7)
		ci.Size = UDim2.fromOffset(34, 34)
		ci.Parent = b
		lbl.Position = UDim2.fromOffset(42, 2)
		lbl.Size = UDim2.new(1, -48, 1, -4)
		local mx = K.button(card, "MAX", UDim2.new(1, -72, 1, -58), UDim2.fromOffset(62, 48), affordable and K.ORANGE or K.GRAY, 20)
		mx.Activated:Connect(function()
			buy:FireServer(kind, zoneId, "max")
			pop.Scale = 1.2
			TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end)
	end
	b.Activated:Connect(function()
		if not atCap then
			buy:FireServer(kind, zoneId)
			pop.Scale = 1.15
			TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end)
end

local function magnetViewport(parent, tier, pos, size)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = pos
	view.Size = size
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.Parent = parent
	local model = MagnetVisuals.Build(tier)
	model.Parent = view
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.6, -6.2), Vector3.new(0, 1.3, 0))
	cam.Parent = view
	view.CurrentCamera = cam
	table.insert(spinning, model)
end

local function renderUpgrades()
	title.Text = "UPGRADE KIOSK"
	for i, kind in ipairs({ "speed", "magnet", "income", "double" }) do
		upgradeCard(body, kind, UDim2.fromOffset((i - 1) * 208 + 2, 0), UDim2.fromOffset(198, 362))
	end
end

local magnetTab = "magnets"
local magnetZone = nil
local MAGNET_TITLES = { island = "🧲 MAGNET SHOP", neon = "🌃 NEON MAGNETS", sky = "☁️ SKY MAGNETS", frozen = "❄️ FROZEN MAGNETS", volcano = "🌋 VOLCANO MAGNETS", galaxy = "🌌 GALAXY MAGNETS" }
-- Магазин магнитов строится ОДИН раз (карточки и 3D-превью кэшируются), дальше только обновляются
-- надписи и цвета. Раньше всё окно со всеми превью пересобиралось при каждом изменении монет —
-- а монеты, пока стоишь в магазине, меняются постоянно, отсюда и были лаги.
local magnetPanel, magnetArea, potionArea, tabButtons, magnetCards = nil, nil, nil, {}, {}
local buildQueue = {}
local function buildMagnetPanel()
	magnetPanel = Instance.new("Frame")
	magnetPanel.Name = "MagnetPanel"
	magnetPanel.BackgroundTransparency = 1
	magnetPanel.Size = UDim2.fromOffset(612, 360)
	magnetPanel.Parent = body
	local tabs = { { "magnets", "MAGNETS" }, { "potions", "POTIONS" } }
	for i, t in ipairs(tabs) do
		local b, _, setC = K.button(magnetPanel, t[2], UDim2.fromOffset((i - 1) * 144 + 4, 0), UDim2.fromOffset(134, 36), K.GRAY, 18)
		b:SetAttribute("Tab", t[1])
		tabButtons[t[1] .. "_set"] = setC
		b.Activated:Connect(function()
			magnetTab = t[1]
			gui:SetAttribute("Dirty", true)
		end)
	end
	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(0, 44)
	scroll.Size = UDim2.fromOffset(612, 316)
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = Color3.fromRGB(240, 160, 50)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = magnetPanel
	magnetArea = scroll
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(140, 196)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll
	for i, def in ipairs(ShopConfig.Magnets) do
		local card = K.frame(scroll, UDim2.new(), UDim2.new(), WHITE, 16)
		card.LayoutOrder = i
		local cg = K.grad(card, K.CARD:Lerp(def.Body, 0.18), K.CARD2)
		K.stroke(card, def.Body, 3)
		label(card, "#" .. i, UDim2.fromOffset(6, 2), UDim2.fromOffset(30, 16), 12, Color3.fromRGB(200, 205, 220))
		label(card, def.Name, UDim2.fromOffset(4, 110), UDim2.fromOffset(132, 26), 15)
		local sub = def.Bonus > 0 and ("+" .. def.Bonus .. " radius") or "basic pull"
		if def.World and def.World ~= "Meadow Isles" then
			sub = sub .. " · " .. string.split(def.World, " ")[1]
		end
		label(card, sub, UDim2.fromOffset(4, 136), UDim2.fromOffset(132, 16), 12, def.Body:Lerp(Color3.new(1, 1, 1), 0.55))
		local b, blbl, bset = K.button(card, "", UDim2.fromOffset(8, 156), UDim2.fromOffset(124, 34), K.GRAY, 16)
		b.Activated:Connect(function()
			if i <= (player:GetAttribute("MagnetTier") or 1) + 1 then
				buy:FireServer("magnettool", "magnets", i)
			end
		end)
		local lockImg = Instance.new("ImageLabel")
		lockImg.BackgroundTransparency = 1
		lockImg.Image = ShopConfig.UpgradeImages.lock
		lockImg.AnchorPoint = Vector2.new(0.5, 0.5)
		lockImg.Position = UDim2.fromOffset(112, 30)
		lockImg.Size = UDim2.fromOffset(44, 44)
		lockImg.ZIndex = 5
		lockImg.Visible = false
		lockImg.Parent = card
		magnetCards[i] = { lock = lockImg, card = card, button = b, label = blbl, set = bset, grad = cg, body = def.Body }
		table.insert(buildQueue, { card = card, tier = i })
	end
	potionArea = Instance.new("Frame")
	potionArea.BackgroundTransparency = 1
	potionArea.Position = UDim2.fromOffset(0, 44)
	potionArea.Size = UDim2.fromOffset(612, 316)
	potionArea.Parent = magnetPanel
end

-- 3D-превью строим понемногу (по 3 за кадр), чтобы открытие магазина не подвисало.
RunService.Heartbeat:Connect(function()
	if #buildQueue == 0 or not window.Visible then
		return
	end
	for _ = 1, 3 do
		local job = table.remove(buildQueue, 1)
		if not job then
			break
		end
		local view = Instance.new("ViewportFrame")
		view.BackgroundTransparency = 1
		view.Position = UDim2.fromOffset(6, 8)
		view.Size = UDim2.fromOffset(128, 100)
		view.Ambient = Color3.fromRGB(200, 200, 210)
		view.LightColor = Color3.fromRGB(255, 250, 240)
		local ok, model = pcall(MagnetVisuals.Build, job.tier)
		if ok and model then
			model:PivotTo(CFrame.Angles(0, 0.6, 0))
			model.Parent = view
			magnetCards[job.tier].model = model
		end
		local cam = Instance.new("Camera")
		cam.FieldOfView = 40
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.6, -6.2), Vector3.new(0, 1.3, 0))
		cam.Parent = view
		view.CurrentCamera = cam
		view.Parent = job.card
	end
end)

local function renderPotions()
	potionArea:ClearAllChildren()
	for i, name in ipairs(ShopConfig.PotionOrder) do
		local def = ShopConfig.Potions[name]
		local card = K.frame(potionArea, UDim2.fromOffset((i - 1) * 204 + 4, 0), UDim2.fromOffset(196, 312), WHITE, 18)
		K.grad(card, K.CARD:Lerp(def.Color, 0.18), K.CARD2)
		K.stroke(card, def.Color, 3)
		if def.Image then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.AnchorPoint = Vector2.new(0.5, 0)
			img.Position = UDim2.new(0.5, 0, 0, 4)
			img.Size = UDim2.fromOffset(112, 112)
			img.Image = def.Image
			img.Parent = card
		else
			juicyIcon(card, def.Icon, def.Color, def.Color:Lerp(Color3.new(1, 1, 1), 0.3), 92, UDim2.new(0.5, 0, 0, 14))
		end
		label(card, def.Name, UDim2.fromOffset(0, 116), UDim2.new(1, 0, 0, 28), 20)
		label(card, def.Effect .. " · 5 min", UDim2.fromOffset(0, 146), UDim2.new(1, 0, 0, 22), 15, def.Color)
		label(card, "You have: " .. (player:GetAttribute("Potion" .. name) or 0), UDim2.fromOffset(0, 176), UDim2.new(1, 0, 0, 22), 16, Color3.fromRGB(220, 225, 235), Enum.Font.GothamBold)
		local price = ShopConfig.PotionCost(name, player:GetAttribute("LifetimeEarned"))
		local b = K.button(card, "BUY  💰 " .. fmt(price), UDim2.new(0, 12, 1, -58), UDim2.new(1, -24, 0, 46), coins.Value >= price and K.GREEN or K.RED, 20)
		b.Activated:Connect(function()
			buy:FireServer("potion", "magnets", name)
		end)
	end
end

local lastTier = nil
local ZONE_WORLD = { island = "Meadow Isles", neon = "Neon District", sky = "Sky Isles", frozen = "Frozen Peaks", volcano = "Magma Volcano", galaxy = "Cosmic Galaxy" }
local lastShopWorld = nil
local function renderMagnets()
	title.Text = MAGNET_TITLES[magnetZone or ""] or "🧲 MAGNET SHOP"
	if not magnetPanel then
		buildMagnetPanel()
	end
	magnetPanel.Visible = true
	for _, key in ipairs({ "magnets", "potions" }) do
		tabButtons[key .. "_set"](key == magnetTab and K.ORANGE or K.GRAY)
	end
	magnetArea.Visible = magnetTab == "magnets"
	potionArea.Visible = magnetTab == "potions"
	if magnetTab == "potions" then
		renderPotions()
		return
	end
	local ownedTier = player:GetAttribute("MagnetTier") or 1
	local equipped = player:GetAttribute("MagnetOff") and 0 or (player:GetAttribute("MagnetEquipped") or 1)
	table.clear(spinning)
	-- Каждый магазин показывает только магниты своего мира (+ надетый, чтобы его можно было снять).
	local shopWorld = ZONE_WORLD[magnetZone or "island"] or "Meadow Isles"
	local jump = lastShopWorld ~= shopWorld
	lastShopWorld = shopWorld
	local visibleIndex, targetIndex = 0, nil
	for i, def in ipairs(ShopConfig.Magnets) do
		local c = magnetCards[i]
		c.card.Visible = (def.World or "Meadow Isles") == shopWorld or i == equipped
		if c.card.Visible then
			visibleIndex += 1
			if i == ownedTier + 1 or (not targetIndex and i == ownedTier) then
				targetIndex = visibleIndex
			end
		end
		c.grad.Color = ColorSequence.new(i == equipped and rgb(50, 130, 80) or K.CARD:Lerp(c.body, 0.18), K.CARD2)
		local text, color
		if i == equipped then
			text, color = "TAKE OFF", K.ORANGE
		elseif i <= ownedTier then
			text, color = "EQUIP", K.BLUE
		elseif i == ownedTier + 1 then
			text, color = "💰 " .. fmt(def.Price), coins.Value >= def.Price and K.GREEN or K.RED
		else
			text, color = "LOCKED", K.GRAY
		end
		c.lock.Visible = text == "LOCKED"
		if c.label.Text ~= text then
			c.label.Text = text
		end
		c.set(color)
		-- крутятся только надетый и следующий для покупки
		if c.model and (i == equipped or i == ownedTier + 1) then
			table.insert(spinning, c.model)
		end
	end
	-- Прокручиваем к следующему магниту только при входе в магазин (другого мира). После покупки
	-- окно остаётся там, где игрок его оставил: раньше оно отлистывалось к самому началу, потому что
	-- ряд считался по номеру магнита среди ВСЕХ миров, а карточки чужих миров скрыты.
	lastTier = ownedTier
	if jump and targetIndex then
		local row = math.floor((targetIndex - 1) / 4)
		magnetArea.CanvasPosition = Vector2.new(0, math.max(row - 1, 0) * 204)
	end
end

local renderInner
local function render()
	table.clear(shownPrices)
	recording = true
	local ok, err = pcall(renderInner)
	recording = false
	if not ok then
		warn("[ShopPanels] " .. tostring(err))
	end
end
function renderInner()
	-- Панель магнитов не удаляем (кэш), всё остальное пересобираем.
	for _, c in ipairs(body:GetChildren()) do
		if c ~= magnetPanel then
			c:Destroy()
		end
	end
	if magnetPanel then
		magnetPanel.Visible = false
	end
	if mode ~= "magnets" then
		spinning = {}
	end
	wallet.Text = fmt(coins.Value)
	local wide = mode == "upgrades"
	body.Size = UDim2.fromOffset(wide and 832 or 612, 366)
	if mode == "upgrades" then
		renderUpgrades()
	elseif mode == "magnets" then
		renderMagnets()
	end
end

local function hide()
	window.Visible = false
	mode = nil
	local s = player:GetAttribute("UIScreen")
	if s == "upgrades" or s == "magnets" then
		player:SetAttribute("UIScreen", "")
	end
end
for _, P in pairs(panels) do
	P.close.Activated:Connect(hide)
end

ReplicatedStorage:WaitForChild("GameShopOpen").OnClientEvent:Connect(function(newMode, newZone)
	if newMode ~= "upgrades" and newMode ~= "magnets" then
		return
	end
	mode, zoneId = newMode, newMode == "magnets" and "magnets" or newZone
	if newMode == "magnets" then
		magnetZone = newZone
	end
	local world = workspace:WaitForChild("CoinSpeedWorld")
	if newMode == "magnets" then
		local shopHolder = newZone == "neon" and world:FindFirstChild("NeonCity") or newZone == "sky" and world:FindFirstChild("SkyIsles") or newZone == "frozen" and world:FindFirstChild("FrozenPeaks") or newZone == "volcano" and world:FindFirstChild("MagmaVolcano") or newZone == "galaxy" and world:FindFirstChild("CosmicGalaxy") or world
		zonePart = shopHolder:FindFirstChild("MagnetShop") and shopHolder.MagnetShop:FindFirstChild("ShopZone")
	else
		local zone = newZone == "neon" and world:FindFirstChild("NeonCity") or newZone == "sky" and world:FindFirstChild("SkyIsles") or newZone == "frozen" and world:FindFirstChild("FrozenPeaks") or newZone == "volcano" and world:FindFirstChild("MagmaVolcano") or newZone == "galaxy" and world:FindFirstChild("CosmicGalaxy") or world
		zonePart = zone.UpgradeShop:FindFirstChild("ShopZone") or zone.UpgradeShop:FindFirstChild("Counter")
	end
	player:SetAttribute("UIScreen", newMode)
	usePanel(newMode)
	if not window.Visible then
		window.Visible = true
		scale.Scale = 0.6
	end
	render()
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	local s = player:GetAttribute("UIScreen")
	if window.Visible and s ~= mode then
		window.Visible = false
		mode = nil
	end
end)
local function dirty()
	if window.Visible then
		gui:SetAttribute("Dirty", true)
	end
end
local lastCoins = coins.Value
coins.Changed:Connect(function(v)
	local lo, hi = math.min(lastCoins, v), math.max(lastCoins, v)
	lastCoins = v
	for _, price in ipairs(shownPrices) do
		if price > lo and price <= hi then
			dirty()
			return
		end
	end
end)
speed.Changed:Connect(dirty)
player.AttributeChanged:Connect(function(name)
	if name == "MagnetLevel" or name == "IncomeLevel" or name == "DoubleLevel" or name == "MagnetTier" or name == "MagnetEquipped" or name == "MagnetOff" or name:sub(1, 6) == "Potion" or name == "MagnetRadius" then
		dirty()
	end
end)

local spin, check, lastRender = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		local target = math.clamp(math.min(camera.ViewportSize.X / (window.Size.X.Offset + 60), camera.ViewportSize.Y / 530), 0.35, 1)
		scale.Scale += (target - scale.Scale) * math.min(dt * 14, 1) -- мягкое появление
	end
	if not window.Visible then
		return
	end
	-- Обновляем окно не чаще 4 раз в секунду (монеты меняются постоянно); кошелёк — сразу.
	wallet.Text = fmt(coins.Value)
	if gui:GetAttribute("Dirty") and os.clock() - lastRender > 0.25 then
		lastRender = os.clock()
		gui:SetAttribute("Dirty", false)
		render()
	end
	spin += dt
	for _, m in ipairs(spinning) do
		if m.Parent then
			m:PivotTo(CFrame.Angles(0, spin, 0))
		end
	end
	check += dt
	if check > 0.2 then
		check = 0
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if zonePart and root then
			local o = root.Position - zonePart.Position
			local radius = math.max(zonePart.Size.Y, zonePart.Size.Z) / 2
			if Vector2.new(o.X, o.Z).Magnitude > radius + 1.5 then -- вышел из круга — окно закрылось
				hide()
			end
		elseif not root then
			hide()
		end
	end
end)
