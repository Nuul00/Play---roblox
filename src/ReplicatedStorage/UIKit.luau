-- Общий стиль окон (как у DAILY REWARDS v2): тёмная витрина с градиентом и звёздами,
-- заголовок-плашка с лентой, глянцевые кнопки, секции с цветной шапкой.
-- Окна с этим стилем помечены NoTheme — WorldWindowTheme их не перекрашивает.
local TweenService = game:GetService("TweenService")
local K = {}
local rgb = Color3.fromRGB
K.INK = rgb(30, 16, 60)
K.GOLD = rgb(255, 205, 70)
K.GREEN = { rgb(150, 245, 110), rgb(50, 170, 60) }
K.RED = { rgb(255, 120, 120), rgb(215, 50, 65) }
K.BLUE = { rgb(140, 215, 255), rgb(50, 115, 235) }
K.ORANGE = { rgb(255, 210, 90), rgb(240, 120, 40) }
K.PURPLE = { rgb(200, 150, 255), rgb(110, 60, 210) }
K.GRAY = { rgb(140, 130, 175), rgb(80, 70, 120) }
K.CARD = rgb(44, 30, 92)
K.CARD2 = rgb(26, 18, 60)

function K.corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 12)
	c.Parent = o
	return c
end
function K.stroke(o, col, th, contextual)
	local s = Instance.new("UIStroke")
	s.Color = col or K.INK
	s.Thickness = th or 2
	s.ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end
function K.grad(o, a, b, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rot or 90
	g.Parent = o
	return g
end
function K.frame(parent, pos, size, col, r)
	local f = Instance.new("Frame")
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = col or Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	f.Parent = parent
	if r then
		K.corner(f, r)
	end
	return f
end
-- текст: масштабируется, но не больше max; обводка INK (strokeW=0 — без обводки)
function K.text(parent, s, pos, size, max, col, strokeW)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = s
	l.TextWrapped = true
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = col or Color3.new(1, 1, 1)
	l.Parent = parent
	local k = Instance.new("UITextSizeConstraint")
	k.MaxTextSize = max or 18
	k.Parent = l
	if strokeW ~= 0 then
		K.stroke(l, K.INK, strokeW or 2, true)
	end
	return l
end

-- глянцевая кнопка: градиент, блик, надпись отдельной меткой (градиент не красит текст),
-- пружина при наведении/нажатии. Возвращает кнопку, метку и функцию смены цвета.
function K.button(parent, s, pos, size, colors, max)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.Text = ""
	b.AutoButtonColor = false
	b.BackgroundColor3 = Color3.new(1, 1, 1)
	b.Parent = parent
	K.corner(b, 14)
	K.stroke(b, K.INK, 3)
	local g = K.grad(b, colors[1], colors[2])
	local gloss = K.frame(b, UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0.38, 0), Color3.new(1, 1, 1), 10)
	gloss.BackgroundTransparency = 0.72
	local label = K.text(b, s, UDim2.fromOffset(6, 2), UDim2.new(1, -12, 1, -4), max or 20, nil, 2.5)
	local sc = Instance.new("UIScale")
	sc.Parent = b
	local function to(v)
		-- Base — масштаб HUD из Responsive.Bind: hover умножается на него, а не сбрасывает кнопку в 1
		local base = tonumber(sc:GetAttribute("Base")) or 1
		TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Back), { Scale = v * base }):Play()
	end
	b.MouseEnter:Connect(function()
		to(1.06)
	end)
	b.MouseLeave:Connect(function()
		to(1)
	end)
	b.MouseButton1Down:Connect(function()
		to(0.93)
	end)
	b.MouseButton1Up:Connect(function()
		to(1.06)
	end)
	local function setColors(c)
		g.Color = ColorSequence.new(c[1], c[2])
	end
	return b, label, setColors
end

-- окно: панель + плашка-заголовок + крестик. Возвращает panel, close, scale, title-label.
function K.window(parent, name, w, h, title, titleColors, pillW)
	local panel = K.frame(parent, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(w, h), Color3.new(1, 1, 1), 26)
	panel.Name = name
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Visible = false
	panel:SetAttribute("NoTheme", true)
	K.stroke(panel, K.INK, 5)
	K.grad(panel, rgb(62, 36, 130), rgb(20, 12, 52))
	local inner = K.frame(panel, UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), Color3.new(0, 0, 0), 20)
	inner.BackgroundTransparency = 1
	local is = K.stroke(inner, rgb(150, 110, 255), 2)
	is.Transparency = 0.55
	-- звёзды
	local rng = Random.new(#name * 31)
	local stars = {}
	for _ = 1, math.floor(w * h / 9000) do
		local sz = rng:NextInteger(2, 4)
		local st = K.frame(panel, UDim2.fromOffset(rng:NextInteger(16, w - 16), rng:NextInteger(16, h - 16)), UDim2.fromOffset(sz, sz), Color3.new(1, 1, 1), UDim.new(1, 0))
		st.BackgroundTransparency = 0.5
		table.insert(stars, { f = st, ph = rng:NextNumber(0, 6) })
	end
	panel:SetAttribute("StarCount", #stars)
	-- плашка
	local tw = pillW or math.clamp(#title * 17 + 70, 240, w - 140)
	for _, side in ipairs({ -1, 1 }) do
		local t = K.frame(panel, UDim2.new(0.5, side * (tw / 2 + 4) - 34, 0, -4), UDim2.fromOffset(68, 42), Color3.new(1, 1, 1), 10)
		t.Rotation = side * 8
		K.stroke(t, K.INK, 4)
		K.grad(t, titleColors[1]:Lerp(rgb(0, 0, 0), 0.1), titleColors[2]:Lerp(rgb(0, 0, 0), 0.25))
	end
	local head = K.frame(panel, UDim2.new(0.5, -tw / 2, 0, -30), UDim2.fromOffset(tw, 66), Color3.new(1, 1, 1), 20)
	head.Name = "TitlePill"
	K.stroke(head, K.INK, 5)
	K.grad(head, titleColors[1], titleColors[2])
	local hs = K.frame(head, UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 20), Color3.new(1, 1, 1), 12)
	hs.BackgroundTransparency = 0.7
	local titleLabel = K.text(head, title, UDim2.fromOffset(10, 6), UDim2.new(1, -20, 1, -10), 34, nil, 3)
	-- крестик
	local close = Instance.new("TextButton")
	close.Position = UDim2.new(1, -62, 0, 16)
	close.Size = UDim2.fromOffset(46, 46)
	close.Text = ""
	close.BackgroundColor3 = rgb(235, 70, 80)
	close.Modal = true
	close.Parent = panel
	K.corner(close, 14)
	K.stroke(close, K.INK, 4)
	K.text(close, "X", UDim2.fromOffset(0, 3), UDim2.fromOffset(46, 40), 28, nil, 2)
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	-- мерцание звёзд, пока окно открыто
	task.spawn(function()
		local t = 0
		while panel.Parent do
			local dt = task.wait(0.05)
			if panel.Visible then
				t += dt
				for _, s in ipairs(stars) do
					s.f.BackgroundTransparency = 0.45 + 0.45 * math.sin(t * 2 + s.ph)
				end
			end
		end
	end)
	return panel, close, scale, titleLabel
end

-- секция: тёмная карточка с цветной полосой сверху и подписью
function K.section(parent, pos, size, title, accent)
	local f = K.frame(parent, pos, size, Color3.new(1, 1, 1), 18)
	K.grad(f, K.CARD, K.CARD2)
	local s = K.stroke(f, accent, 2.5)
	s.Transparency = 0.2
	local band = K.frame(f, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 32), accent, 18)
	K.grad(band, accent:Lerp(Color3.new(1, 1, 1), 0.25), accent:Lerp(Color3.new(0, 0, 0), 0.25))
	local fill = K.frame(band, UDim2.new(0, 0, 1, -12), UDim2.new(1, 0, 0, 12), accent)
	K.grad(fill, accent:Lerp(Color3.new(0, 0, 0), 0.15), accent:Lerp(Color3.new(0, 0, 0), 0.25))
	local label = K.text(band, title, UDim2.fromOffset(14, 3), UDim2.new(1, -28, 1, -6), 20, nil, 2)
	label.TextXAlignment = Enum.TextXAlignment.Left
	return f, label, band
end

-- окно не больше экрана
function K.fit(scale, w, h)
	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.ViewportSize
		scale.Scale = math.min(1, (v.X - 26) / w, (v.Y - 90) / (h + 40))
	end
end

return K
