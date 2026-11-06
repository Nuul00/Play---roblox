-- Окно REBIRTH: значок с числом ребёрсов, два прогресса (монеты и яйца с прошлого ребёрса),
-- сравнение «сейчас → после», дорога наград-вех, что теряется / что остаётся, большая кнопка
-- и праздничный экран после ребёрса. Сервер всё проверяет (Rebirth.server).
-- Открывается как раньше: атрибут игрока UIScreen = "rebirth" (кнопка в GameHUD).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local Config = require(RS:WaitForChild("GameConfig"))
local remote = RS:WaitForChild("GameRebirth")
local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local rgb = Color3.fromRGB
local ink = rgb(30, 30, 40)
local EGGS_ATTR = "Save_RebirthEggs"
local W, H = 860, 556
local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right

local gui = Instance.new("ScreenGui")
gui.Name = "RebirthUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 41
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- ===== Помощники =====
local function round(f, r)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, r)
end
local function stroke(f, c, w)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = w
	s.Parent = f
	return s
end
local function frame(parent, x, y, w, h, c, r)
	local f = Instance.new("Frame")
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = c
	f.BorderSizePixel = 0
	f.Parent = parent
	if r then
		round(f, r)
	end
	return f
end
local function text(parent, s, x, y, w, h, size, c, xAlign)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.Text = s
	l.TextWrapped = true
	l.TextSize = size
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = c or Color3.new(1, 1, 1)
	l.TextXAlignment = xAlign or Enum.TextXAlignment.Center
	l.Parent = parent
	local st = stroke(l, ink, 2)
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	return l
end
local function grad(f, a, b, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rot or 90
	g.Parent = f
	return g
end
local function tseq(points)
	local k = {}
	for _, p in ipairs(points) do
		table.insert(k, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(k)
end
local NumberFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberFormat"))
local function fmt(n)
	return NumberFormat.Short(n)
end
local function mult(v)
	return "x" .. string.format("%g", math.floor(v * 100 + 0.5) / 100)
end
local function pct(v)
	return "+" .. tostring(math.floor(v * 100 + 0.5)) .. "%"
end
local function pop(obj, from)
	obj.Scale = from or 0.8
	Tween:Create(obj, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- ===== Окно =====
local panel = frame(gui, 0, 0, W, H, rgb(80, 50, 170), 28)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.53)
panel.Visible = false
panel:SetAttribute("NoTheme", true) -- свой фиолетовый стиль, как у DAILY
stroke(panel, ink, 5)
grad(panel, rgb(125, 85, 230), rgb(45, 22, 110))
local scale = Instance.new("UIScale", panel)

local head = frame(panel, W / 2 - 200, -34, 400, 70, rgb(255, 190, 70), 20)
stroke(head, ink, 4)
grad(head, rgb(255, 232, 125), rgb(245, 140, 40))
text(head, "🔄 REBIRTH", 0, 6, 400, 58, 38)

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(W - 58, 12)
close.Size = UDim2.fromOffset(44, 44)
close.Text = "×"
close.Font = Enum.Font.FredokaOne
close.TextSize = 32
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = rgb(235, 70, 80)
close.Modal = true
close.Parent = panel
round(close, 12)
stroke(close, ink, 3)
close.Activated:Connect(function()
	player:SetAttribute("UIScreen", "")
end)

-- ----- Левая карточка: значок и сравнение бонусов -----
local left = frame(panel, 20, 50, 260, 300, rgb(60, 35, 140), 22)
stroke(left, ink, 3)
grad(left, rgb(90, 58, 190), rgb(42, 22, 105))
left.ClipsDescendants = true -- лучи значка не вылезают за карточку

local badgeRays = {}
for i = 1, 6 do
	local ray = Instance.new("Frame")
	ray.AnchorPoint = Vector2.new(0.5, 0.5)
	ray.Position = UDim2.fromOffset(130, 98)
	ray.Size = UDim2.fromOffset(236, 22)
	ray.BackgroundColor3 = i % 2 == 0 and rgb(255, 230, 130) or rgb(255, 170, 220)
	ray.BorderSizePixel = 0
	ray.Rotation = i * 30
	ray.Parent = left
	local g = Instance.new("UIGradient")
	g.Transparency = tseq({ { 0, 1 }, { 0.5, 0.72 }, { 1, 1 } })
	g.Parent = ray
	table.insert(badgeRays, ray)
end
local badge = frame(left, 60, 28, 140, 140, rgb(255, 200, 70), 70)
stroke(badge, ink, 5)
grad(badge, rgb(255, 242, 155), rgb(250, 150, 40))
local badgeScale = Instance.new("UIScale", badge)
local inner = frame(badge, 12, 12, 116, 116, rgb(120, 60, 200), 58)
grad(inner, rgb(155, 100, 245), rgb(75, 32, 160))
stroke(inner, rgb(255, 250, 220), 2)
local countLabel = text(inner, "0", 0, 14, 116, 62, 58, rgb(255, 240, 160))
text(inner, "/ " .. Config.MaxRebirths, 0, 74, 116, 24, 18, rgb(225, 210, 255))
local titleLabel = text(left, "REBIRTHS", 0, 174, 260, 26, 19, rgb(255, 220, 120))

local function compareRow(y, icon, name)
	local row = frame(left, 12, y, 236, 28, rgb(32, 18, 80), 10)
	stroke(row, ink, 2)
	text(row, icon .. " " .. name, 8, 0, 100, 28, 15, rgb(215, 200, 255), LEFT)
	local val = text(row, "", 86, 0, 142, 28, 16, rgb(140, 255, 150), RIGHT)
	val.RichText = true
	return val
end
local coinRow = compareRow(202, "💰", "COINS")
local luckRow = compareRow(234, "🍀", "LUCK")
local slotRow = compareRow(266, "🐾", "SLOTS")

-- ----- Требования: монеты и яйца -----
local req = frame(panel, 296, 50, 544, 128, rgb(60, 35, 140), 20)
stroke(req, ink, 3)
grad(req, rgb(90, 58, 190), rgb(42, 22, 105))
text(req, "REQUIREMENTS", 16, 6, 300, 24, 18, rgb(255, 225, 140), LEFT)
text(req, "eggs count since last rebirth", 240, 8, 290, 20, 13, rgb(200, 185, 245), RIGHT)

local function bar(y, a, b)
	local back = frame(req, 14, y, 516, 40, rgb(25, 15, 60), 20)
	stroke(back, ink, 3)
	local fill = frame(back, 0, 0, 40, 40, a, 20)
	local g = grad(fill, a, b)
	local gloss = frame(fill, 10, 5, 0, 9, Color3.new(1, 1, 1), 5)
	gloss.Size = UDim2.new(1, -20, 0, 9)
	gloss.BackgroundTransparency = 0.65
	local label = text(back, "", 0, 4, 516, 32, 19)
	local check = text(back, "", 474, 4, 36, 32, 22)
	return { fill = fill, grad = g, label = label, check = check, a = a, b = b, frac = -1 }
end
local coinBar = bar(32, rgb(230, 195, 80), rgb(200, 120, 30))
local eggBar = bar(78, rgb(215, 130, 205), rgb(140, 70, 210))

local function setBar(bb, frac, s, done)
	frac = math.clamp(frac, 0, 1)
	bb.label.Text = s
	bb.check.Text = done and "✅" or ""
	if done then
		bb.grad.Color = ColorSequence.new(rgb(120, 205, 110), rgb(40, 135, 70))
	else
		bb.grad.Color = ColorSequence.new(bb.a, bb.b)
	end
	bb.fill.Visible = frac > 0.005
	if math.abs(frac - bb.frac) > 0.0005 then
		local first = bb.frac < 0
		bb.frac = frac
		local size = UDim2.fromOffset(math.max(40, 516 * frac), 40)
		if first or not panel.Visible then
			bb.fill.Size = size
		else
			Tween:Create(bb.fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = size }):Play()
		end
	end
end

-- ----- Дорога наград -----
local roadBox = frame(panel, 296, 188, 544, 168, rgb(60, 35, 140), 20)
stroke(roadBox, ink, 3)
grad(roadBox, rgb(90, 58, 190), rgb(42, 22, 105))
text(roadBox, "🎁 REWARD ROAD", 16, 6, 300, 24, 18, rgb(255, 225, 140), LEFT)
local roadHint = text(roadBox, "", 240, 8, 290, 20, 13, rgb(200, 185, 245), RIGHT)

local road = Instance.new("ScrollingFrame")
road.Position = UDim2.fromOffset(8, 30)
road.Size = UDim2.fromOffset(528, 134)
road.BackgroundTransparency = 1
road.BorderSizePixel = 0
road.ScrollingDirection = Enum.ScrollingDirection.X
road.ScrollBarThickness = 6
road.ScrollBarImageColor3 = rgb(255, 220, 120)
road.VerticalScrollBarInset = Enum.ScrollBarInset.None
road.Parent = roadBox

local STEP, NODE = 104, 92
local miles = Config.RebirthMilestones
local canvasW = 14 + #miles * STEP
road.CanvasSize = UDim2.fromOffset(canvasW, 0)
local function nodeCenter(i)
	return 14 + (i - 1) * STEP + NODE / 2
end
local track = frame(road, nodeCenter(1), 36, nodeCenter(#miles) - nodeCenter(1), 10, rgb(25, 15, 60), 5)
stroke(track, ink, 2)
local trackFill = frame(track, 0, 0, 0, 10, rgb(255, 210, 80), 5)
grad(trackFill, rgb(255, 240, 140), rgb(250, 160, 40), 0)

local nodes = {}
for i, m in ipairs(miles) do
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(14 + (i - 1) * STEP, 0)
	holder.Size = UDim2.fromOffset(NODE, 130)
	holder.Parent = road
	local glow = frame(holder, 6, 1, 80, 80, rgb(255, 225, 110), 40)
	glow.BackgroundTransparency = 1
	local circle = frame(holder, 14, 9, 64, 64, rgb(90, 90, 110), 32)
	local cStroke = stroke(circle, ink, 3)
	local cGrad = grad(circle, rgb(120, 120, 140), rgb(70, 70, 90))
	local cScale = Instance.new("UIScale", circle)
	local icon = text(circle, m.Icon, 0, 0, 64, 64, 32)
	local corner = text(holder, "", 56, 48, 28, 28, 18)
	local at = text(holder, "R" .. m.At, 0, 76, NODE, 20, 17, rgb(255, 235, 160))
	local name = text(holder, m.Name, 0, 96, NODE, 32, 12, rgb(225, 215, 255))
	name.TextYAlignment = Enum.TextYAlignment.Top
	-- Подсказка-описание при наведении/тапе.
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Size = UDim2.fromScale(1, 1)
	hit.Parent = holder
	hit.MouseEnter:Connect(function()
		roadHint.Text = "R" .. m.At .. ": " .. m.Desc
	end)
	hit.Activated:Connect(function()
		roadHint.Text = "R" .. m.At .. ": " .. m.Desc
		pop(cScale, 0.85)
	end)
	nodes[i] = { m = m, glow = glow, circle = circle, stroke = cStroke, grad = cGrad, scale = cScale, icon = icon, corner = corner, at = at, name = name }
end
local nextNode -- узел следующей вехи (светится)

local function updateRoad(r)
	nextNode = nil
	local prevAt, prevI = 0, 0
	for i, n in ipairs(nodes) do
		local done = r >= n.m.At
		local isNext = not done and nextNode == nil
		if done then
			n.grad.Color = ColorSequence.new(rgb(120, 205, 110), rgb(35, 125, 70))
			n.stroke.Color = rgb(255, 225, 110)
			n.icon.TextTransparency = 0
			n.corner.Text = "✅"
			n.at.TextColor3 = rgb(160, 255, 160)
			n.glow.BackgroundTransparency = 1
			prevAt, prevI = n.m.At, i
		elseif isNext then
			nextNode = n
			n.grad.Color = ColorSequence.new(rgb(255, 240, 140), rgb(245, 140, 40))
			n.stroke.Color = ink
			n.icon.TextTransparency = 0
			n.corner.Text = "⭐"
			n.at.TextColor3 = rgb(255, 235, 120)
		else
			n.grad.Color = ColorSequence.new(rgb(110, 105, 140), rgb(60, 55, 85))
			n.stroke.Color = ink
			n.icon.TextTransparency = 0.5
			n.corner.Text = "🔒"
			n.at.TextColor3 = rgb(175, 165, 205)
			n.glow.BackgroundTransparency = 1
		end
	end
	-- Заливка дорожки: до последней взятой вехи плюс доля пути к следующей.
	local x = 0
	if prevI > 0 then
		x = nodeCenter(prevI) - nodeCenter(1)
	end
	if nextNode and prevI > 0 then
		local nextI = prevI + 1
		x += (nodeCenter(nextI) - nodeCenter(prevI)) * math.clamp((r - prevAt) / (nextNode.m.At - prevAt), 0, 1)
	end
	trackFill.Size = UDim2.fromOffset(x, 10)
	trackFill.Visible = x > 1
	if nextNode then
		roadHint.Text = "Next at R" .. nextNode.m.At .. ": " .. nextNode.m.Desc
	else
		roadHint.Text = "All rewards unlocked!"
	end
end
local function scrollRoadToNext()
	local target = nextNode and nodeCenter(table.find(nodes, nextNode) or 1) or canvasW
	road.CanvasPosition = Vector2.new(math.clamp(target - 264, 0, math.max(0, canvasW - 528)), 0)
end

-- ----- Что теряется / что остаётся -----
local function column(x, title, a, b, lines)
	local f = frame(panel, x, 366, 404, 100, a, 18)
	stroke(f, ink, 3)
	grad(f, a, b)
	text(f, title, 0, 4, 404, 24, 19)
	for i, line in ipairs(lines) do
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		text(f, line, 12 + col * 196, 30 + row * 22, 190, 22, 14, Color3.new(1, 1, 1), LEFT)
	end
end
column(20, "YOU LOSE", rgb(200, 75, 110), rgb(130, 40, 75), {
	"💰 All coins",
	"⚡ Speed (back to lvl " .. Config.RebirthStartSpeed .. ")",
	"🧲 Magnet radius level",
	"💵 Coin income level",
	"✨ Double coin level",
	"🥚 Egg counter resets",
})
column(436, "YOU KEEP", rgb(60, 170, 110), rgb(30, 110, 70), {
	"🐾 Pets & pet index",
	"🧲 Magnets you bought",
	"🧪 Potions",
	"🏆 Achievements",
	"🌍 World access",
	"⭐ All rebirth bonuses",
})

-- ----- Кнопка -----
local button = Instance.new("TextButton")
button.Position = UDim2.fromOffset((W - 380) / 2, 478)
button.Size = UDim2.fromOffset(380, 62)
button.Text = ""
button.AutoButtonColor = false
button.BackgroundColor3 = Color3.new(1, 1, 1)
button.Parent = panel
round(button, 18)
stroke(button, ink, 4)
local btnGrad = grad(button, rgb(150, 150, 160), rgb(100, 100, 115))
local btnScale = Instance.new("UIScale", button)
local shine = frame(button, 0, 0, 380, 62, Color3.new(1, 1, 1), 18)
local shineGrad = Instance.new("UIGradient")
shineGrad.Transparency = tseq({ { 0, 1 }, { 0.4, 1 }, { 0.5, 0.55 }, { 0.6, 1 }, { 1, 1 } })
shineGrad.Rotation = 20
shineGrad.Parent = shine
shine.Visible = false
local btnLabel = text(button, "", 0, 4, 380, 54, 28)

local GRAY = ColorSequence.new(rgb(150, 150, 165), rgb(95, 95, 115))
local GREEN = ColorSequence.new(rgb(130, 215, 110), rgb(40, 140, 70))
local RED = ColorSequence.new(rgb(255, 160, 120), rgb(225, 65, 60))
local GOLD = ColorSequence.new(rgb(255, 235, 130), rgb(240, 150, 40))

-- ===== Состояние =====
local confirmUntil = 0
local function state()
	local r = player:GetAttribute("Rebirths") or 0
	local maxed = r >= Config.MaxRebirths
	local cost = maxed and 0 or Config.GetRebirthCost(r)
	local needEggs = maxed and 0 or Config.GetRebirthEggs(r)
	local eggs = tonumber(player:GetAttribute(EGGS_ATTR)) or 0
	local coinsOk = coins.Value >= cost
	local eggsOk = eggs >= needEggs
	return r, maxed, cost, needEggs, eggs, coinsOk, eggsOk, (not maxed) and coinsOk and eggsOk
end

local function compare(now, after)
	return '<font color="#d2c8ff">' .. now .. "</font>  →  " .. after
end

local lastShownR = -1
local function refresh()
	local r, maxed, cost, needEggs, eggs, coinsOk, eggsOk, ready = state()
	countLabel.Text = tostring(r)
	if r ~= lastShownR then
		if lastShownR >= 0 then
			pop(badgeScale, 0.7)
		end
		lastShownR = r
		updateRoad(r)
	end
	local title = Config.GetRebirthTitle(r)
	titleLabel.Text = title ~= "" and ("🏷️ " .. string.upper(title)) or "REBIRTHS"
	if maxed then
		coinRow.Text = mult(Config.GetRebirthBonus(r)) .. "  MAX"
		luckRow.Text = pct(Config.GetRebirthLuck(r)) .. "  MAX"
		slotRow.Text = "+" .. Config.GetRebirthSlots(r) .. "  MAX"
		setBar(coinBar, 1, "ALL REBIRTHS DONE", true)
		setBar(eggBar, 1, "YOU ARE ETERNAL", true)
	else
		coinRow.Text = compare(mult(Config.GetRebirthBonus(r)), mult(Config.GetRebirthBonus(r + 1)))
		luckRow.Text = compare(pct(Config.GetRebirthLuck(r)), pct(Config.GetRebirthLuck(r + 1)))
		local s0, s1 = Config.GetRebirthSlots(r), Config.GetRebirthSlots(r + 1)
		slotRow.Text = s1 > s0 and compare("+" .. s0, "+" .. s1) or ("+" .. s0)
		setBar(coinBar, coins.Value / cost, "💰 " .. fmt(math.min(coins.Value, cost)) .. " / " .. fmt(cost) .. " coins", coinsOk)
		setBar(eggBar, eggs / needEggs, "🥚 " .. math.floor(math.min(eggs, needEggs)) .. " / " .. needEggs .. " eggs opened", eggsOk)
	end
	if maxed then
		btnLabel.Text = "👑 MAX REBIRTH"
		btnGrad.Color = GOLD
	elseif not ready then
		local parts = {}
		if not coinsOk then
			table.insert(parts, fmt(cost - coins.Value) .. " COINS")
		end
		if not eggsOk then
			table.insert(parts, math.floor(needEggs - eggs) .. " EGGS")
		end
		btnLabel.Text = "NEED " .. table.concat(parts, " + ")
		btnGrad.Color = GRAY
	elseif os.clock() < confirmUntil then
		btnLabel.Text = "TAP AGAIN TO CONFIRM"
		btnGrad.Color = RED
	else
		btnLabel.Text = "🔄 REBIRTH!"
		btnGrad.Color = GREEN
	end
	btnLabel.TextSize = #btnLabel.Text > 20 and 22 or 28
	btnLabel.TextColor3 = (ready or maxed) and Color3.new(1, 1, 1) or rgb(230, 230, 235)
	shine.Visible = ready
end

button.Activated:Connect(function()
	local _, maxed, _, _, _, _, _, ready = state()
	if maxed then
		return
	end
	if not ready then
		-- Сервер всё равно ответит причиной через GameFeedback.
		remote:FireServer()
		pop(btnScale, 0.92)
		return
	end
	pop(btnScale, 0.9)
	if os.clock() < confirmUntil then
		confirmUntil = 0
		remote:FireServer()
	else
		confirmUntil = os.clock() + 2.5
	end
	refresh()
end)

-- ===== Праздничный экран =====
local fx = Instance.new("ScreenGui")
fx.Name = "RebirthFX"
fx.ResetOnSpawn = false
fx.IgnoreGuiInset = true
fx.DisplayOrder = 60
fx.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
fx.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("CanvasGroup")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = rgb(25, 10, 55)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel = 0
overlay.GroupTransparency = 1
overlay.Visible = false
overlay.Parent = fx

local rays = {}
for i = 1, 10 do
	local ray = Instance.new("Frame")
	ray.AnchorPoint = Vector2.new(0.5, 0.5)
	ray.Position = UDim2.fromScale(0.5, 0.4)
	ray.Size = UDim2.fromOffset(2600, 90)
	ray.BackgroundColor3 = i % 2 == 0 and rgb(255, 225, 110) or rgb(255, 140, 220)
	ray.BorderSizePixel = 0
	ray.Rotation = i * 18
	ray.Parent = overlay
	local g = Instance.new("UIGradient")
	g.Transparency = tseq({ { 0, 1 }, { 0.38, 0.75 }, { 0.5, 0.3 }, { 0.62, 0.75 }, { 1, 1 } })
	g.Parent = ray
	table.insert(rays, ray)
end

local stage = Instance.new("Frame")
stage.AnchorPoint = Vector2.new(0.5, 0.5)
stage.Position = UDim2.fromScale(0.5, 0.5)
stage.Size = UDim2.fromOffset(800, 520)
stage.BackgroundTransparency = 1
stage.Parent = overlay
local stageScale = Instance.new("UIScale", stage)

local bigBadge = frame(stage, 400 - 95, 20, 190, 190, rgb(255, 200, 70), 95)
stroke(bigBadge, ink, 6)
grad(bigBadge, rgb(255, 245, 160), rgb(250, 145, 35))
local bigInner = frame(bigBadge, 16, 16, 158, 158, rgb(120, 60, 200), 79)
grad(bigInner, rgb(160, 105, 250), rgb(75, 30, 160))
stroke(bigInner, rgb(255, 250, 225), 3)
local bigCount = text(bigInner, "1", 0, 18, 158, 100, 92, rgb(255, 240, 160))
text(bigInner, "REBIRTH", 0, 108, 158, 30, 22, rgb(230, 215, 255))
local bigBadgeScale = Instance.new("UIScale", bigBadge)

local bigTitle = text(stage, "REBIRTH!", 0, 222, 800, 80, 70, rgb(255, 230, 110))
local bigTitleScale = Instance.new("UIScale", bigTitle)
local lineCoins = text(stage, "", 0, 304, 800, 46, 38, rgb(150, 255, 150))
local lineLuck = text(stage, "", 0, 350, 800, 40, 30, rgb(140, 230, 255))
local lineGift = text(stage, "", 0, 394, 800, 70, 28, rgb(255, 215, 120))
local tapHint = text(stage, "Tap to continue", 0, 474, 800, 28, 20, rgb(220, 210, 255))

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 20
flash.Parent = overlay

local tap = Instance.new("TextButton")
tap.Size = UDim2.fromScale(1, 1)
tap.BackgroundTransparency = 1
tap.Text = ""
tap.ZIndex = 30
tap.Parent = overlay

local CONFETTI_COLORS = { rgb(255, 90, 110), rgb(255, 200, 60), rgb(90, 220, 120), rgb(80, 170, 255), rgb(200, 110, 255), rgb(255, 150, 220) }
local confetti = {}
for i = 1, 80 do
	local c = Instance.new("Frame")
	c.Size = UDim2.fromOffset(math.random(8, 14), math.random(14, 22))
	c.AnchorPoint = Vector2.new(0.5, 0.5)
	c.BackgroundColor3 = CONFETTI_COLORS[(i - 1) % #CONFETTI_COLORS + 1]
	c.BorderSizePixel = 0
	c.ZIndex = 10
	c.Visible = false
	c.Parent = overlay
	confetti[i] = { f = c, x = 0, y = 0, vx = 0, vy = 0, rot = 0, vr = 0, phase = 0 }
end

local celebrating = false
local celebT = 0
local celebFrom, celebTo = { coins = 1, luck = 0 }, { coins = 1, luck = 0 }

local function hideCelebration()
	if not celebrating then
		return
	end
	celebrating = false
	local t = Tween:Create(overlay, TweenInfo.new(0.45), { GroupTransparency = 1 })
	t:Play()
	t.Completed:Connect(function()
		if not celebrating then
			overlay.Visible = false
			for _, c in ipairs(confetti) do
				c.f.Visible = false
			end
		end
	end)
end
tap.Activated:Connect(function()
	if celebT > 1 then
		hideCelebration()
	end
end)

local function celebrate(r)
	celebrating = true
	celebT = 0
	celebFrom.coins, celebTo.coins = Config.GetRebirthBonus(r - 1), Config.GetRebirthBonus(r)
	celebFrom.luck, celebTo.luck = Config.GetRebirthLuck(r - 1), Config.GetRebirthLuck(r)
	bigCount.Text = tostring(r)
	bigTitle.Text = r >= Config.MaxRebirths and "👑 MAX REBIRTH!" or ("REBIRTH " .. r .. "!")
	local gifts = {}
	for _, m in ipairs(Config.RebirthMilestones) do
		if m.At == r then
			table.insert(gifts, m.Icon .. " " .. m.Name .. ": " .. m.Desc)
		end
	end
	lineGift.Text = #gifts > 0 and ("🎁 REWARD UNLOCKED!\n" .. table.concat(gifts, "\n")) or ""
	tapHint.TextTransparency = 1
	overlay.Visible = true
	overlay.GroupTransparency = 1
	Tween:Create(overlay, TweenInfo.new(0.25), { GroupTransparency = 0 }):Play()
	flash.BackgroundTransparency = 0
	Tween:Create(flash, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	bigBadgeScale.Scale = 0.2
	Tween:Create(bigBadgeScale, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { Scale = 1 }):Play()
	bigTitleScale.Scale = 0.3
	task.delay(0.15, function()
		Tween:Create(bigTitleScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
	-- Конфетти вылетает из центра веером вверх и падает.
	local size = overlay.AbsoluteSize
	for _, c in ipairs(confetti) do
		c.x = size.X * 0.5 + math.random(-40, 40)
		c.y = size.Y * 0.42
		local a = math.rad(math.random(200, 340))
		local speed = math.random(450, 1100) * math.max(0.6, size.Y / 900)
		c.vx = math.cos(a) * speed
		c.vy = math.sin(a) * speed
		c.rot = math.random(0, 360)
		c.vr = math.random(-400, 400)
		c.phase = math.random() * 6
		c.f.Visible = true
		c.f.Position = UDim2.fromOffset(c.x, c.y)
	end
	task.delay(5.5, function()
		if celebrating and celebT >= 5 then
			hideCelebration()
		end
	end)
end

local lastRebirths = player:GetAttribute("Rebirths") or 0
player:GetAttributeChangedSignal("Rebirths"):Connect(function()
	local r = player:GetAttribute("Rebirths") or 0
	if r > lastRebirths and player:GetAttribute("ProfileReady") then
		player:SetAttribute("UIScreen", "")
		celebrate(r)
	end
	lastRebirths = r
	refresh()
end)
player:GetAttributeChangedSignal(EGGS_ATTR):Connect(refresh)
coins.Changed:Connect(function()
	if panel.Visible then
		refresh()
	end
end)

local function update()
	local open = player:GetAttribute("UIScreen") == "rebirth"
	local was = panel.Visible
	panel.Visible = open
	if open then
		confirmUntil = 0
		refresh()
		if not was then
			scrollRoadToNext()
			pop(badgeScale, 0.6)
		end
	end
end
player:GetAttributeChangedSignal("UIScreen"):Connect(update)
update()

-- ===== Кадр: масштаб, лучи, свечение, кнопка, праздник =====
local t = 0
Run.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
	if panel.Visible then
		scale.Scale = math.min(1, (view.X - 24) / W, (view.Y - 90) / (H + 40))
		t += dt
		for i, ray in ipairs(badgeRays) do
			ray.Rotation = i * 30 + t * 25
		end
		if nextNode then
			local s = 0.5 + 0.5 * math.sin(t * 4)
			nextNode.glow.BackgroundTransparency = 0.35 + 0.4 * s
			nextNode.scale.Scale = 1 + 0.06 * s
		end
		local _, _, _, _, _, _, _, ready = state()
		btnScale.Scale = ready and (1 + 0.035 * math.sin(t * 5)) or btnScale.Scale
		if ready then
			-- Блик пробегает по кнопке раз в ~1.6 с.
			local k = (t % 1.6) / 1.6
			shineGrad.Offset = Vector2.new(-1 + 2.4 * k, 0)
		end
		if confirmUntil > 0 and os.clock() > confirmUntil then
			confirmUntil = 0
			refresh()
		end
	end
	if overlay.Visible then
		celebT += dt
		stageScale.Scale = math.min(1, view.X / 820, view.Y / 560)
		for i, ray in ipairs(rays) do
			ray.Rotation = i * 18 + celebT * 22
		end
		-- Счётчик бонусов растёт от старого значения к новому.
		local k = math.clamp((celebT - 0.4) / 1.2, 0, 1)
		k = 1 - (1 - k) ^ 3
		local cv = celebFrom.coins + (celebTo.coins - celebFrom.coins) * k
		local lv = celebFrom.luck + (celebTo.luck - celebFrom.luck) * k
		lineCoins.Text = "💰 COINS " .. mult(cv)
		lineLuck.Text = "🍀 EGG LUCK " .. pct(lv)
		if celebT > 1.2 then
			tapHint.TextTransparency = 0.3 + 0.3 * math.sin(celebT * 4)
		end
		bigBadgeScale.Scale = celebT > 0.8 and (1 + 0.04 * math.sin(celebT * 3)) or bigBadgeScale.Scale
		local size = overlay.AbsoluteSize
		for _, c in ipairs(confetti) do
			if c.f.Visible then
				c.vy += 900 * dt
				c.vx *= (1 - 1.2 * dt)
				c.vy = math.min(c.vy, 420)
				c.x += (c.vx + math.sin(celebT * 3 + c.phase) * 40) * dt
				c.y += c.vy * dt
				c.rot += c.vr * dt
				c.f.Position = UDim2.fromOffset(c.x, c.y)
				c.f.Rotation = c.rot
				if c.y > size.Y + 40 then
					c.f.Visible = false
				end
			end
		end
	end
end)
refresh()
