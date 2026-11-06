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
local function fmt(n)
	if recording then
		table.insert(shownPrices, n)
	end
	for _, u in ipairs({ { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then
			return (string.format("%.1f", n / u[1]):gsub("%.0$", "")) .. u[2]
		end
	end
	return string.format("%g", math.floor(n))
end

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(1, 0.5)
window.Position = UDim2.new(1, -20, 0.5, 0)
window.Size = UDim2.fromOffset(640, 430)
window.BackgroundColor3 = Color3.fromRGB(36, 44, 66)
window.Visible = false
window.Parent = gui
corner(window, 20)
stroke(window, 4)
local scale = Instance.new("UIScale", window)
local title = label(window, "", UDim2.fromOffset(20, 8), UDim2.fromOffset(420, 44), 28, Color3.fromRGB(255, 230, 150))
title.TextXAlignment = Enum.TextXAlignment.Left
local wallet = label(window, "", UDim2.fromOffset(330, 12), UDim2.fromOffset(240, 36), 20, Color3.fromRGB(255, 215, 80))
wallet.TextXAlignment = Enum.TextXAlignment.Right
local close = button(window, "×", UDim2.new(1, -52, 0, 10), UDim2.fromOffset(40, 40), Color3.fromRGB(220, 70, 70))
close.TextSize = 28
close.Modal = true
local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(14, 60)
body.Size = UDim2.fromOffset(612, 360)
body.Parent = window

local mode, zoneId
local zonePart
local spinning = {}

-- Карточка прокачки: иконка в круге цвета ступени, уровень «N / предел мира», значения до/после, кнопка.
-- Предел зависит от магазина: Meadow 10, Neon 25, Sky 50 (Config.ZoneMax); цены растут с уровнем.
local upgradeDefs = {
	speed = { Title = "SPEED", Icon = "⚡", Accent = Color3.fromRGB(80, 170, 255), Global = Config.MaxSpeedLevel,
		Level = function() return speed.Value end, Cost = Config.GetUpgradeCost,
		Value = function(l) return tostring(Config.GetWalkSpeed(l)) .. " (+" .. l .. "% coins)" end, Unit = "walk speed" },
	magnet = { Title = "MAGNET", Icon = "🧲", Accent = Color3.fromRGB(230, 80, 90), Global = Config.MaxMagnetLevel,
		Level = function() return player:GetAttribute("MagnetLevel") or 0 end, Cost = Config.GetMagnetUpgradeCost,
		Value = function(l) return string.format("%.1f", Config.GetMagnetRadius(l)) end, Unit = "studs radius" },
	income = { Title = "COINS", Icon = "💰", Accent = Color3.fromRGB(255, 190, 40), Global = Config.MaxIncomeLevel,
		Level = function() return player:GetAttribute("IncomeLevel") or 0 end, Cost = Config.GetIncomeUpgradeCost,
		Value = function(l) return "x" .. string.format("%g", Config.GetIncomeMultiplier(l)) end, Unit = "coin income" },
	double = { Title = "DOUBLE", Icon = "✨", Accent = Color3.fromRGB(190, 110, 255), Global = Config.MaxDoubleLevel,
		Level = function() return player:GetAttribute("DoubleLevel") or 0 end, Cost = Config.GetDoubleUpgradeCost,
		Value = function(l) return string.format("%g%%", math.floor(Config.GetDoubleChance(l) * 1000 + 0.5) / 10) end, Unit = "double coin chance" },
}
local function upgradeCard(parent, kind, pos, size)
	local d = upgradeDefs[kind]
	local level = d.Level()
	local cap = math.min(d.Global, Config.ZoneMax[zoneId] or Config.BaseMaxLevel)
	local tier = ShopConfig.TierColor(level, d.Global)
	local card = Instance.new("Frame")
	card.Position = pos
	card.Size = size
	card.BackgroundColor3 = Color3.fromRGB(54, 62, 90)
	card.Parent = parent
	corner(card, 16)
	stroke(card, 3, tier)
	gradient(card, Color3.fromRGB(62, 72, 108), 0.1, 0.3)
	local head = Instance.new("Frame")
	head.Size = UDim2.new(1, 0, 0, 38)
	head.BackgroundColor3 = d.Accent
	head.Parent = card
	corner(head, 16)
	gradient(head, d.Accent, 0.3, 0.2)
	local headText = label(head, d.Title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 22)
	headText.TextStrokeTransparency = 0.3
	-- Иконка растёт и меняет цвет кольца по мере прокачки.
	local iconSize = 78 + math.floor(level / math.max(d.Global, 1) * 14)
	local ring = juicyIcon(card, d.Icon, d.Accent, tier, iconSize, UDim2.new(0.5, 0, 0, 48))
	label(card, string.format("LEVEL %d / %d", level, cap), UDim2.fromOffset(0, 144), UDim2.new(1, 0, 0, 26), 20, tier)
	local nowText = d.Value(level)
	local nextText = level < d.Global and d.Value(level + 1) or nowText
	label(card, level < cap and (nowText .. "  →  " .. nextText) or (nowText .. "  MAX"), UDim2.fromOffset(0, 174), UDim2.new(1, 0, 0, 30), 24)
	label(card, d.Unit, UDim2.fromOffset(0, 202), UDim2.new(1, 0, 0, 20), 14, Color3.fromRGB(200, 205, 220), Enum.Font.GothamMedium)
	local atCap = level >= cap
	local price = atCap and 0 or d.Cost(level)
	local affordable = coins.Value >= price
	local text = level >= d.Global and "MAXED" or atCap and "MAX HERE" or ("BUY  💰 " .. fmt(price))
	local b = button(card, text, UDim2.new(0, 12, 1, -58), UDim2.new(1, atCap and -24 or -92, 0, 46),
		atCap and Color3.fromRGB(120, 120, 130) or (affordable and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(150, 80, 80)))
	if not atCap then
		-- MAX: сразу все уровни, на которые хватает монет
		local mx = button(card, "MAX", UDim2.new(1, -76, 1, -58), UDim2.fromOffset(64, 46), affordable and Color3.fromRGB(255, 170, 40) or Color3.fromRGB(150, 110, 80))
		mx.TextSize = 20
		mx.Activated:Connect(function()
			buy:FireServer(kind, zoneId, "max")
			TweenService:Create(ring, TweenInfo.new(0.12), { Size = UDim2.fromOffset(iconSize + 16, iconSize + 16) }):Play()
		end)
	end
	if atCap and level < d.Global then
		label(card, "more levels in the next world", UDim2.fromOffset(0, 226), UDim2.new(1, 0, 0, 18), 13, Color3.fromRGB(255, 215, 120), Enum.Font.GothamMedium)
	end
	b.Activated:Connect(function()
		if not atCap then
			buy:FireServer(kind, zoneId)
			TweenService:Create(ring, TweenInfo.new(0.12), { Size = UDim2.fromOffset(iconSize + 10, iconSize + 10) }):Play()
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
	title.Text = "⬆ UPGRADE KIOSK"
	for i, kind in ipairs({ "speed", "magnet", "income", "double" }) do
		upgradeCard(body, kind, UDim2.fromOffset((i - 1) * 208, 0), UDim2.fromOffset(200, 340))
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
		local b = button(magnetPanel, t[2], UDim2.fromOffset((i - 1) * 140, 0), UDim2.fromOffset(132, 34), Color3.fromRGB(70, 80, 110))
		b.TextSize = 16
		b.Activated:Connect(function()
			magnetTab = t[1]
			window:SetAttribute("Dirty", true)
		end)
		tabButtons[t[1]] = b
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
		local card = Instance.new("Frame")
		card.LayoutOrder = i
		card.BackgroundColor3 = Color3.fromRGB(54, 62, 90)
		card.Parent = scroll
		corner(card, 14)
		stroke(card, 3, def.Body)
		label(card, "#" .. i, UDim2.fromOffset(6, 2), UDim2.fromOffset(30, 16), 12, Color3.fromRGB(200, 205, 220))
		label(card, def.Name, UDim2.fromOffset(4, 110), UDim2.fromOffset(132, 26), 15)
		local sub = def.Bonus > 0 and ("+" .. def.Bonus .. " radius") or "basic pull"
		if def.World and def.World ~= "Meadow Isles" then
			sub = sub .. " · " .. string.split(def.World, " ")[1]
		end
		label(card, sub, UDim2.fromOffset(4, 136), UDim2.fromOffset(132, 16), 12, def.Body:Lerp(Color3.new(1, 1, 1), 0.55))
		local b = button(card, "", UDim2.fromOffset(8, 158), UDim2.fromOffset(124, 30), Color3.fromRGB(80, 80, 90))
		b.TextSize = 13
		b.Activated:Connect(function()
			if i <= (player:GetAttribute("MagnetTier") or 1) + 1 then
				buy:FireServer("magnettool", "magnets", i)
			end
		end)
		magnetCards[i] = { card = card, button = b }
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
		local card = Instance.new("Frame")
		card.Position = UDim2.fromOffset((i - 1) * 206, 0)
		card.Size = UDim2.fromOffset(196, 312)
		card.BackgroundColor3 = Color3.fromRGB(54, 62, 90)
		card.Parent = potionArea
		corner(card, 16)
		stroke(card, 3, def.Color)
		gradient(card, Color3.fromRGB(62, 72, 108), 0.1, 0.3)
		juicyIcon(card, def.Icon, def.Color, def.Color:Lerp(Color3.new(1, 1, 1), 0.3), 92, UDim2.new(0.5, 0, 0, 14))
		label(card, def.Name, UDim2.fromOffset(0, 116), UDim2.new(1, 0, 0, 28), 20)
		label(card, def.Effect .. " · 5 min", UDim2.fromOffset(0, 146), UDim2.new(1, 0, 0, 22), 15, def.Color)
		label(card, "You have: " .. (player:GetAttribute("Potion" .. name) or 0), UDim2.fromOffset(0, 176), UDim2.new(1, 0, 0, 22), 16, Color3.fromRGB(220, 225, 235), Enum.Font.GothamBold)
		local price = ShopConfig.PotionCost(name, player:GetAttribute("LifetimeEarned"))
		local b = button(card, "BUY  💰 " .. fmt(price), UDim2.new(0, 12, 1, -58), UDim2.new(1, -24, 0, 46), coins.Value >= price and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(150, 80, 80))
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
	for key, b in pairs(tabButtons) do
		b.BackgroundColor3 = key == magnetTab and Color3.fromRGB(240, 160, 50) or Color3.fromRGB(70, 80, 110)
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
	if lastShopWorld ~= shopWorld then
		lastShopWorld = shopWorld
		magnetArea.CanvasPosition = Vector2.zero
	end
	for i, def in ipairs(ShopConfig.Magnets) do
		local c = magnetCards[i]
		c.card.Visible = (def.World or "Meadow Isles") == shopWorld or i == equipped
		c.card.BackgroundColor3 = i == equipped and Color3.fromRGB(60, 110, 70) or Color3.fromRGB(54, 62, 90)
		local text, color
		if i == equipped then
			text, color = "TAKE OFF", Color3.fromRGB(215, 120, 60)
		elseif i <= ownedTier then
			text, color = "EQUIP", Color3.fromRGB(70, 140, 220)
		elseif i == ownedTier + 1 then
			text, color = "💰 " .. fmt(def.Price), coins.Value >= def.Price and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(150, 80, 80)
		else
			text, color = "🔒 LOCKED", Color3.fromRGB(80, 80, 90)
		end
		if c.button.Text ~= text then
			c.button.Text = text
		end
		c.button.BackgroundColor3 = color
		-- крутятся только надетый и следующий для покупки
		if c.model and (i == equipped or i == ownedTier + 1) then
			table.insert(spinning, c.model)
		end
	end
	if lastTier ~= ownedTier then
		lastTier = ownedTier
		local row = math.floor(math.min(ownedTier, #ShopConfig.Magnets - 1) / 4)
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
	wallet.Text = "💰 " .. fmt(coins.Value)
	local wide = mode == "upgrades"
	window.Size = UDim2.fromOffset(wide and 860 or 640, 430)
	body.Size = UDim2.fromOffset(wide and 832 or 612, 360)
	wallet.Position = UDim2.fromOffset(wide and 550 or 330, 12)
	close.Position = UDim2.new(1, -52, 0, 10)
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
close.Activated:Connect(hide)

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
	window.Visible = true
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
		window:SetAttribute("Dirty", true)
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
		scale.Scale = math.clamp(math.min(camera.ViewportSize.X / (window.Size.X.Offset + 60), camera.ViewportSize.Y / 500), 0.35, 1)
	end
	if not window.Visible then
		return
	end
	-- Обновляем окно не чаще 4 раз в секунду (монеты меняются постоянно); кошелёк — сразу.
	wallet.Text = "💰 " .. fmt(coins.Value)
	if window:GetAttribute("Dirty") and os.clock() - lastRender > 0.25 then
		lastRender = os.clock()
		window:SetAttribute("Dirty", false)
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
			if Vector2.new(o.X, o.Z).Magnitude > radius + 3 then
				hide()
			end
		elseif not root then
			hide()
		end
	end
end)
