-- Трекер квестовой линии (слева сверху, над плитками MainHUD): глава, шаг, прогресс, награда, CLAIM.
-- Только отображение: прогресс и шаг приходят атрибутами от сервера (QuestLine.server).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Q = require(ReplicatedStorage:WaitForChild("QuestLineConfig"))
local Skins = require(ReplicatedStorage:WaitForChild("HudSkins"))
local remote = ReplicatedStorage:WaitForChild(Q.RemoteName)
local A = Q.Attr
local rgb = Color3.fromRGB
local INK = rgb(30, 30, 40)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local W, H = 270, 156 -- размер карточки
local BAR_W = W - 24

local gui = Instance.new("ScreenGui")
gui.Name = "QuestLineUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 11
gui.Parent = player:WaitForChild("PlayerGui")

-- ===== Помощники в стиле остального HUD =====
local function round(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = f
	return c
end
local function stroke(f, color, w)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = w
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end
local function grad(f, a, b)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = 90
	g.Parent = f
	return g
end
local function frame(parent, x, y, w, h, color, r)
	local f = Instance.new("Frame")
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = color or WHITE
	f.BorderSizePixel = 0
	f.Parent = parent
	if r then
		round(f, r)
	end
	return f
end
local function label(parent, x, y, w, h, maxSize, color, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color or WHITE
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.Text = ""
	l.Parent = parent
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = maxSize
	c.Parent = l
	local s = Instance.new("UIStroke")
	s.Color = INK
	s.Thickness = 2
	s.Parent = l
	return l
end

-- ===== Карточка =====
local root = Instance.new("Frame")
root.Name = "QuestTracker"
root.BackgroundTransparency = 1
root.Position = UDim2.fromOffset(14, 14)
root.Size = UDim2.fromOffset(W, H)
root.Visible = false
root.Parent = gui
local ResponsiveHUD = require(game:GetService("ReplicatedStorage"):WaitForChild("Responsive"))
local rootScale = Instance.new("UIScale")
rootScale.Parent = root

local card = frame(root, 0, 0, W, H, WHITE, 16)
card.Name = "Card"
local cardGrad = grad(card, rgb(40, 110, 60), rgb(20, 60, 35))
local cardStroke = stroke(card, INK, 3)
local cardScale = Instance.new("UIScale")
cardScale.Parent = card

local header = frame(card, 0, 0, W, 34, WHITE, 16)
local headerGrad = grad(header, rgb(130, 235, 120), rgb(40, 150, 70))
local headerStroke = stroke(header, INK, 3)
local chapterText = label(header, 10, 4, 150, 26, 17)
local stepChip = frame(header, W - 106, 6, 62, 22, rgb(30, 30, 40), 11)
stepChip.BackgroundTransparency = 0.45
local stepText = label(stepChip, 0, 1, 62, 20, 15, WHITE, Enum.TextXAlignment.Center)

local collapseBtn = Instance.new("TextButton")
collapseBtn.Position = UDim2.fromOffset(W - 38, 4)
collapseBtn.Size = UDim2.fromOffset(28, 26)
collapseBtn:SetAttribute("TouchMin", true) -- TouchTargets увеличит на телефоне
collapseBtn.BackgroundColor3 = rgb(255, 255, 255)
collapseBtn.BackgroundTransparency = 0.75
collapseBtn.Text = "–"
collapseBtn.Font = Enum.Font.FredokaOne
collapseBtn.TextSize = 22
collapseBtn.TextColor3 = WHITE
collapseBtn.AutoButtonColor = true
collapseBtn.Parent = header
round(collapseBtn, 8)
local collapseStroke = Instance.new("UIStroke")
collapseStroke.Color = INK
collapseStroke.Thickness = 2
collapseStroke.Parent = collapseBtn

local titleText = label(card, 12, 39, W - 24, 23, 20, rgb(200, 255, 150))
local goalText = label(card, 12, 62, W - 24, 19, 16)
local hintText = label(card, 12, 81, W - 24, 16, 13, rgb(225, 225, 240))
hintText:FindFirstChildOfClass("UIStroke").Thickness = 1.5

local barBack = frame(card, 12, 101, BAR_W, 24, rgb(25, 20, 40), 12)
stroke(barBack, INK, 2.5)
local barFill = frame(barBack, 0, 0, 0, 24, WHITE, 12)
grad(barFill, rgb(170, 255, 150), rgb(70, 190, 90))
local barText = label(barBack, 0, 2, BAR_W, 20, 16, WHITE, Enum.TextXAlignment.Center)
barText.ZIndex = 3

local rewardText = label(card, 12, 130, W - 24, 20, 14, rgb(255, 230, 120))

-- Кнопка CLAIM: пульсирует и светится, когда цель выполнена (занимает место полоски).
local claimBtn = Instance.new("TextButton")
-- на месте полоски прогресса, но выше: на телефоне по ней должно быть легко попасть пальцем
local TOUCH = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
claimBtn.Position = UDim2.fromOffset(12, TOUCH and 97 or 101)
claimBtn.Size = UDim2.fromOffset(BAR_W, TOUCH and 36 or 24)
claimBtn.BackgroundColor3 = WHITE
claimBtn.Text = ""
claimBtn.AutoButtonColor = false
claimBtn.Visible = false
claimBtn.ZIndex = 4
claimBtn.Parent = card
round(claimBtn, 12)
grad(claimBtn, rgb(255, 235, 110), rgb(255, 150, 30))
local claimStroke = stroke(claimBtn, WHITE, 2.5)
local claimScale = Instance.new("UIScale")
claimScale.Parent = claimBtn
local shine = frame(claimBtn, 0, 0, BAR_W, TOUCH and 36 or 24, WHITE, 12)
shine.ZIndex = 5
local shineGrad = Instance.new("UIGradient")
shineGrad.Rotation = 20
shineGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.42, 1),
	NumberSequenceKeypoint.new(0.5, 0.35),
	NumberSequenceKeypoint.new(0.58, 1),
	NumberSequenceKeypoint.new(1, 1),
})
shineGrad.Parent = shine
local claimLabel = label(claimBtn, 0, TOUCH and 5 or 2, BAR_W, TOUCH and 26 or 20, TOUCH and 20 or 16, WHITE, Enum.TextXAlignment.Center)
claimLabel.Text = "🎁 CLAIM!"
claimLabel.ZIndex = 6
claimLabel:FindFirstChildOfClass("UIStroke").Color = rgb(120, 60, 10)
claimLabel:FindFirstChildOfClass("UIStroke").Thickness = 2

-- Свечение вокруг карточки, пока награда ждёт.
-- Прозрачная подложка чуть больше карточки: видна только её рамка. Внутри card — едет вместе с ней.
local glowFrame = frame(card, -4, -4, W + 8, H + 8, rgb(255, 230, 110), 20)
glowFrame.BackgroundTransparency = 1
glowFrame.ZIndex = 0
local glowStroke = stroke(glowFrame, rgb(255, 230, 110), 4)
glowStroke.Transparency = 1

-- ===== Свёрнутый вид: маленькая «таблетка» =====
local pill = Instance.new("TextButton")
pill.Position = UDim2.fromOffset(0, 0)
pill.Size = UDim2.fromOffset(176, 40)
pill.BackgroundColor3 = WHITE
pill.Text = ""
pill.AutoButtonColor = false
pill.Visible = false
pill.Parent = root
local pillCorner = round(pill, 20)
pillCorner.CornerRadius = UDim.new(1, 0)
local pillGrad = grad(pill, rgb(130, 235, 120), rgb(40, 150, 70))
local pillStroke = stroke(pill, INK, 3)
local pillScale = Instance.new("UIScale")
pillScale.Parent = pill
local pillText = label(pill, 12, 7, 152, 26, 18, WHITE, Enum.TextXAlignment.Center)
local pillDot = Instance.new("TextLabel")
pillDot.Position = UDim2.fromOffset(160, -6)
pillDot.Size = UDim2.fromOffset(22, 22)
pillDot.BackgroundColor3 = rgb(235, 60, 70)
pillDot.Text = "!"
pillDot.Font = Enum.Font.FredokaOne
pillDot.TextSize = 16
pillDot.TextColor3 = WHITE
pillDot.Visible = false
pillDot.Parent = pill
round(pillDot, 11).CornerRadius = UDim.new(1, 0)
stroke(pillDot, INK, 2)

-- ===== Слой эффектов (конфетти, монеты) поверх всего =====
local fx = Instance.new("Frame")
fx.Name = "FX"
fx.BackgroundTransparency = 1
fx.Size = UDim2.fromScale(1, 1)
fx.ZIndex = 20
fx.Parent = gui

-- ===== Состояние =====
local collapsed = false
local animating = false -- во время анимации награды не перерисовываем карточку
local pending = false
local lastReadyStep = nil
local shownStep = nil
local readyNow = false

local function stepIndex(): number?
	local i = player:GetAttribute(A.Step)
	return type(i) == "number" and i or nil
end

-- Цвета карточки берём из HUD-скина мира, где сейчас игрок (как у плиток и меню), а не из главы:
-- так трекер везде в одном стиле с остальным интерфейсом. Глава видна по названию и иконке.
local lastChapter = 1
local function applyTheme(chapter)
	lastChapter = chapter or lastChapter
	local c = Q.Chapters[lastChapter] or Q.Chapters[1]
	local skin = Skins[player:GetAttribute("CurrentWorld") or ""]
	local top = skin and skin.MenuTop or c.Top
	local bottom = skin and skin.MenuBottom or c.Bottom
	local rim = skin and skin.RimColor or INK
	headerGrad.Color = ColorSequence.new(top, bottom)
	pillGrad.Color = ColorSequence.new(top, bottom)
	cardGrad.Color = ColorSequence.new(bottom:Lerp(BLACK, 0.3), bottom:Lerp(BLACK, 0.62))
	cardStroke.Color, headerStroke.Color, pillStroke.Color = rim, rim, rim
	titleText.TextColor3 = skin and skin.TitleColor or c.Accent
	chapterText.Text = "CH." .. tostring(lastChapter) .. " " .. string.upper(c.Name) -- номер главы: видно, что это глава квестов, а не текущий мир
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
	applyTheme(nil)
end)

local function bump(scaleObj, amount)
	local up = TweenService:Create(scaleObj, TweenInfo.new(0.09, Enum.EasingStyle.Quad), { Scale = amount })
	up.Completed:Connect(function()
		TweenService:Create(scaleObj, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
	up:Play()
end

local function updateVisibility()
	local modal = (player:GetAttribute("UIScreen") or "") ~= ""
	root.Visible = stepIndex() ~= nil and not modal
	card.Visible = not collapsed
	pill.Visible = collapsed
end

local function render()
	if animating then
		return
	end
	local i = stepIndex()
	updateVisibility()
	if not i then
		return
	end
	local s = Q.Steps[i]
	local total = #Q.Steps
	if not s then
		-- Вся линия пройдена.
		applyTheme(#Q.Chapters)
		chapterText.Text = "🏆 QUEST LINE"
		stepText.Text = total .. "/" .. total
		titleText.Text = "🏆 All quests complete!"
		goalText.Text = "You finished every chapter."
		hintText.Text = "More adventures coming soon!"
		barBack.Visible = false
		claimBtn.Visible = false
		local bonus = player:GetAttribute(A.Bonus)
		rewardText.Text = "⭐ Quest bonus: x" .. string.format("%g", type(bonus) == "number" and bonus or 1) .. " coins"
		pillText.Text = "🏆 QUESTS DONE"
		pillDot.Visible = false
		readyNow = false
		shownStep = i
		return
	end
	applyTheme(s.Chapter)
	stepText.Text = i .. "/" .. total
	titleText.Text = "📜 " .. s.Title
	goalText.Text = Q.GoalText(s.Goal)
	hintText.Text = s.Hint or ""
	rewardText.Text = "🎁 " .. table.concat(Q.RewardParts(s.Reward), "  ")

	local goal = player:GetAttribute(A.Goal)
	goal = type(goal) == "number" and goal > 0 and goal or Q.GoalAmount(s.Goal)
	local prog = player:GetAttribute(A.Progress)
	prog = type(prog) == "number" and prog or 0
	local ready = player:GetAttribute(A.Ready) == true
	if ready then
		prog = goal
	end
	local frac = math.clamp(prog / goal, 0, 1)
	local width = frac > 0 and math.max(24, BAR_W * frac) or 0
	if shownStep ~= i then
		barFill.Size = UDim2.fromOffset(width, 24) -- новый шаг: без анимации
	else
		TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(width, 24) }):Play()
	end
	if s.Goal.Type == "world" then
		barText.Text = ready and "Arrived!" or "Not there yet"
	else
		barText.Text = Q.Format(prog) .. " / " .. Q.Format(goal)
	end
	barBack.Visible = not ready
	claimBtn.Visible = ready
	claimLabel.Text = pending and "..." or "🎁 CLAIM!"
	pillText.Text = ready and "🎁 QUEST DONE!" or ("📜 QUESTS  " .. i .. "/" .. total)
	pillDot.Visible = ready
	readyNow = ready
	-- Только что выполнили — подпрыгиваем.
	if ready and lastReadyStep ~= i and shownStep == i then
		bump(cardScale, 1.07)
		bump(pillScale, 1.15)
	end
	if ready then
		lastReadyStep = i
	end
	shownStep = i
end

-- ===== Эффекты награды =====
local particles = {}
local CONFETTI = { rgb(255, 90, 110), rgb(255, 210, 60), rgb(90, 220, 120), rgb(80, 180, 255), rgb(200, 120, 255), WHITE }

local function fxPoint(obj: GuiObject): Vector2
	return obj.AbsolutePosition + obj.AbsoluteSize / 2 - fx.AbsolutePosition
end

local function confetti(origin: Vector2, amount: number)
	for _ = 1, amount do
		local piece = Instance.new("Frame")
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Size = UDim2.fromOffset(math.random(6, 10), math.random(10, 16))
		piece.BackgroundColor3 = CONFETTI[math.random(1, #CONFETTI)]
		piece.BorderSizePixel = 0
		piece.Rotation = math.random(0, 360)
		piece.ZIndex = 21
		piece.Position = UDim2.fromOffset(origin.X, origin.Y)
		piece.Parent = fx
		local angle = math.rad(math.random(-160, -20))
		local speed = math.random(260, 560)
		table.insert(particles, {
			obj = piece,
			pos = origin,
			vel = Vector2.new(math.cos(angle) * speed, math.sin(angle) * speed),
			spin = math.random(-540, 540),
			age = 0,
			life = 1 + math.random() * 0.6,
		})
	end
end

local function sparkle(origin: Vector2, amount: number)
	for _ = 1, amount do
		local star = Instance.new("TextLabel")
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.BackgroundTransparency = 1
		star.Text = "✨"
		star.TextSize = math.random(16, 26)
		star.ZIndex = 22
		star.Position = UDim2.fromOffset(origin.X + math.random(-110, 110), origin.Y + math.random(-50, 30))
		star.Parent = fx
		local scale = Instance.new("UIScale")
		scale.Scale = 0
		scale.Parent = star
		local grow = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 })
		grow:Play()
		task.delay(0.25 + math.random() * 0.3, function()
			local fade = TweenService:Create(star, TweenInfo.new(0.35), { TextTransparency = 1, Rotation = 90 })
			fade.Completed:Connect(function()
				star:Destroy()
			end)
			fade:Play()
		end)
	end
end

-- Куда летят монеты: плитка монет MainHUD (если есть), иначе левый низ.
local function coinTarget(): Vector2
	local hud = player.PlayerGui:FindFirstChild("MainHUD")
	local column = hud and hud:FindFirstChild("Panels")
	if column then
		for _, child in ipairs(column:GetChildren()) do
			if child:IsA("Frame") and child.LayoutOrder == 1 then
				return fxPoint(child)
			end
		end
	end
	return Vector2.new(120, fx.AbsoluteSize.Y - 300)
end

local function coinBurst(origin: Vector2, amount: number)
	local target = coinTarget()
	for n = 1, amount do
		task.delay((n - 1) * 0.05, function()
			local coin = Instance.new("TextLabel")
			coin.AnchorPoint = Vector2.new(0.5, 0.5)
			coin.BackgroundTransparency = 1
			coin.Text = "🪙"
			coin.TextSize = 30
			coin.ZIndex = 23
			local start = origin + Vector2.new(math.random(-60, 60), math.random(-20, 20))
			coin.Position = UDim2.fromOffset(start.X, start.Y)
			coin.Parent = fx
			-- Сначала разлёт в стороны, потом полёт к плитке монет.
			local mid = start + Vector2.new(math.random(-50, 50), math.random(-70, -30))
			local out = TweenService:Create(coin, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(mid.X, mid.Y) })
			out.Completed:Connect(function()
				local fly = TweenService:Create(coin, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(target.X, target.Y), TextSize = 18 })
				fly.Completed:Connect(function()
					coin:Destroy()
				end)
				fly:Play()
			end)
			out:Play()
		end)
	end
end

local function bigPop(origin: Vector2, text: string)
	local pop = Instance.new("TextLabel")
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.BackgroundTransparency = 1
	pop.Position = UDim2.fromOffset(origin.X, origin.Y - 20)
	pop.Size = UDim2.fromOffset(360, 40)
	pop.Font = Enum.Font.FredokaOne
	pop.TextSize = 30
	pop.TextColor3 = rgb(255, 235, 120)
	pop.Text = text
	pop.ZIndex = 24
	pop.Parent = fx
	local s = Instance.new("UIStroke")
	s.Color = rgb(70, 40, 10)
	s.Thickness = 3
	s.Parent = pop
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = pop
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(0.7, function()
		local rise = TweenService:Create(pop, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(origin.X, origin.Y - 80), TextTransparency = 1 })
		TweenService:Create(s, TweenInfo.new(0.7), { Transparency = 1 }):Play()
		rise.Completed:Connect(function()
			pop:Destroy()
		end)
		rise:Play()
	end)
end

local function playClaim(index: number)
	local s = Q.Steps[index]
	if not s then
		animating = false
		render()
		return
	end
	local origin = fxPoint(claimBtn.Visible and claimBtn or card)
	confetti(origin, 36)
	sparkle(origin, 8)
	if s.Reward.Coins then
		coinBurst(origin, 10)
	end
	local parts = Q.RewardParts(s.Reward)
	bigPop(origin, "+" .. (parts[1] or "Reward!"))
	claimLabel.Text = "✔ CLAIMED!"
	bump(cardScale, 1.08)
	task.delay(0.75, function()
		-- Старый квест уезжает влево, новый въезжает на его место.
		local out = TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.fromOffset(-W - 40, 0) })
		out.Completed:Connect(function()
			animating = false
			render()
			card.Position = UDim2.fromOffset(-W - 40, 0)
			TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }):Play()
		end)
		out:Play()
	end)
end

-- ===== Ввод =====
claimBtn.Activated:Connect(function()
	if pending or animating or not readyNow then
		return
	end
	pending = true
	animating = true -- сервер сменит шаг раньше ответа: держим старую карточку до анимации
	claimLabel.Text = "..."
	remote:FireServer("claim")
	task.delay(3, function()
		-- Ответа нет: возвращаем кнопку и показываем то, что сейчас на сервере.
		if pending then
			pending = false
			animating = false
			render()
		end
	end)
end)
claimBtn.MouseEnter:Connect(function()
	claimStroke.Color = rgb(255, 255, 200)
end)
claimBtn.MouseLeave:Connect(function()
	claimStroke.Color = WHITE
end)

remote.OnClientEvent:Connect(function(kind, index)
	if kind ~= "claimed" or type(index) ~= "number" then
		return
	end
	pending = false
	animating = true
	if collapsed then
		-- В свёрнутом виде — только конфетти у таблетки.
		local origin = fxPoint(pill)
		confetti(origin, 24)
		local s = Q.Steps[index]
		if s and s.Reward.Coins then
			coinBurst(origin, 8)
		end
		animating = false
		render()
		bump(pillScale, 1.15)
		return
	end
	playClaim(index)
end)

local function setCollapsed(value: boolean)
	collapsed = value
	updateVisibility()
	if value then
		pillScale.Scale = 0.6
		TweenService:Create(pillScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	else
		cardScale.Scale = 0.6
		TweenService:Create(cardScale, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end
collapseBtn.Activated:Connect(function()
	setCollapsed(true)
end)
pill.Activated:Connect(function()
	setCollapsed(false)
end)

for _, name in ipairs({ A.Step, A.Progress, A.Goal, A.Ready, A.Bonus }) do
	player:GetAttributeChangedSignal(name):Connect(render)
end
player:GetAttributeChangedSignal("UIScreen"):Connect(updateVisibility)
render()

-- ===== Кадр: масштаб, пульс кнопки, частицы =====
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		rootScale.Scale = ResponsiveHUD.Scale() -- общий масштаб HUD (было Y/720, на сенсоре не меньше 0.8)
	end
	local t = os.clock()
	if readyNow and root.Visible then
		local wave = (math.sin(t * 6) + 1) / 2
		claimScale.Scale = 1 + 0.02 * wave
		claimStroke.Thickness = 2 + 2 * wave
		glowStroke.Transparency = 0.2 + 0.6 * (1 - wave)
		glowStroke.Thickness = 3 + 3 * wave
		shineGrad.Offset = Vector2.new(((t * 0.8) % 1.6) - 0.8, 0)
		if collapsed then
			pillScale.Scale = 1 + 0.04 * wave
		end
	elseif glowStroke.Transparency < 1 then
		glowStroke.Transparency = 1
	end
	for i = #particles, 1, -1 do
		local p = particles[i]
		p.age += dt
		if p.age >= p.life then
			p.obj:Destroy()
			table.remove(particles, i)
		else
			p.vel += Vector2.new(0, 900 * dt)
			p.pos += p.vel * dt
			p.obj.Position = UDim2.fromOffset(p.pos.X, p.pos.Y)
			p.obj.Rotation += p.spin * dt
			p.obj.BackgroundTransparency = math.clamp((p.age - p.life * 0.6) / (p.life * 0.4), 0, 1)
		end
	end
end)
