-- Окно DAILY REWARDS v2: тёмная «витрина» с 7 карточками-слотами, день 7 — большой джекпот с лучами.
-- Текущий день светится и подпрыгивает, полученные — со штампом ✓, снизу дорожка серии и золотая кнопка.
-- Логика наград: DailyConfig + DailyRewards.server (сервер всё проверяет сам).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local p = Players.LocalPlayer
local D = require(RS:WaitForChild("DailyConfig"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local remote = RS:WaitForChild("DailyRewardClaim")
local rgb = Color3.fromRGB
local INK = rgb(30, 16, 60)
local GOLD = rgb(255, 205, 70)

local gui = Instance.new("ScreenGui")
gui.Name = "DailyRewardsUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.Parent = p:WaitForChild("PlayerGui")

local function round(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r)
	c.Parent = f
end
local function stroke(f, c, w, contextual)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = w
	s.ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
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
local function text(parent, s, x, y, w, h, size, c, strokeW)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.Text = s
	l.TextWrapped = true
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = c or Color3.new(1, 1, 1)
	l.Parent = parent
	local k = Instance.new("UITextSizeConstraint")
	k.MaxTextSize = size
	k.Parent = l
	if strokeW ~= 0 then
		stroke(l, INK, strokeW or 2, true)
	end
	return l
end
local function grad(f, a, b, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rot or 90
	g.Parent = f
	return g
end

-- цвет и иконка по типу награды
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local function potionImage(name)
	local d = ShopConfig.Potions[name]
	return d and d.Image
end
local IMG = ShopConfig.RewardImages
local KIND = {
	Coins = { icon = "💰", col = rgb(255, 196, 50), image = IMG.CoinBag },
	CoinPile = { icon = "💰", col = rgb(255, 150, 40), image = IMG.CoinPile },
	SuperLuck = { icon = "🍀", col = rgb(60, 215, 100), image = potionImage("SuperLuck") },
	SuperCoins = { icon = "💰", col = rgb(255, 170, 30), image = potionImage("SuperCoins") },
	SuperSpeed = { icon = "⚡", col = rgb(70, 160, 255), image = potionImage("SuperSpeed") },
	Key = { icon = "🔑", col = rgb(235, 80, 200), image = IMG.Keys2 },
	Star = { icon = "🎁", col = GOLD, image = IMG.Gift },
}
-- подпись награды из её содержимого (монеты, супер-зелья, ключи, яйца)
local function describe(reward, coins)
	local parts = {}
	if coins then
		table.insert(parts, coins .. " coins")
	end
	for _, name in ipairs(ShopConfig.SuperPotionOrder) do
		local n = reward.Potions and reward.Potions[name]
		if n then
			table.insert(parts, (n > 1 and (n .. "× ") or "") .. ShopConfig.Potions[name].Short)
		end
	end
	if reward.RushKeys then
		table.insert(parts, reward.RushKeys .. " Rush key" .. (reward.RushKeys > 1 and "s" or ""))
	end
	if reward.FreeHatch then
		local n = reward.FreeHatch == true and 1 or reward.FreeHatch
		table.insert(parts, n .. " free top eggs")
	end
	return table.concat(parts, "\n+ ")
end

------------------------------------------------------------------ окно
local W, H = 920, 470
local panel = frame(gui, 0, 0, W, H, rgb(255, 255, 255), 28)
panel.Name = "DailyPanel"
panel:SetAttribute("NoTheme", true)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Visible = false
stroke(panel, INK, 5)
grad(panel, rgb(62, 36, 130), rgb(20, 12, 52))
local scale = Instance.new("UIScale", panel)
-- внутренняя рамка-свечение
local inner = frame(panel, 8, 8, W - 16, H - 16, rgb(0, 0, 0), 22)
inner.BackgroundTransparency = 1
local innerStroke = stroke(inner, rgb(150, 110, 255), 2)
innerStroke.Transparency = 0.55
-- звёздочки на фоне
local stars = {}
local rng = Random.new(7)
for i = 1, 26 do
	local sz = rng:NextInteger(2, 4)
	local st = frame(panel, rng:NextInteger(20, W - 20), rng:NextInteger(20, H - 20), sz, sz, rgb(255, 255, 255), UDim.new(1, 0))
	st.BackgroundTransparency = 0.5
	table.insert(stars, { f = st, ph = rng:NextNumber(0, 6) })
end

-- заголовок-плашка с «хвостами» ленты
local function tail(x, flip)
	local t = frame(panel, x, -6, 70, 44, rgb(200, 70, 40), 10)
	t.Rotation = flip and 8 or -8
	stroke(t, INK, 4)
	grad(t, rgb(240, 120, 60), rgb(180, 55, 35))
end
tail(W / 2 - 250, false)
tail(W / 2 + 180, true)
local head = frame(panel, W / 2 - 215, -32, 430, 70, rgb(255, 255, 255), 20)
stroke(head, INK, 5)
grad(head, rgb(255, 200, 90), rgb(240, 95, 45))
local headShine = frame(head, 10, 6, 410, 22, rgb(255, 255, 255), 12)
headShine.BackgroundTransparency = 0.7
text(head, "🎁 DAILY REWARDS", 0, 6, 430, 58, 36, nil, 3)

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(W - 62, 16)
close.Size = UDim2.fromOffset(46, 46)
close.Text = ""
close.BackgroundColor3 = rgb(235, 70, 80)
close.Modal = true
close.Parent = panel
round(close, 14)
stroke(close, INK, 4)
text(close, "X", 0, 3, 46, 40, 28, nil, 2)
close.Activated:Connect(function()
	p:SetAttribute("UIScreen", "")
end)

text(panel, "Come back every day — day 7 is the JACKPOT!", 40, 46, W - 80, 28, 22, rgb(225, 210, 255), 2)

------------------------------------------------------------------ карточки
local cells = {}
local CW, BIG, GAP, CY, CH = 106, 176, 10, 86, 236
local x = 24
for day, reward in ipairs(D.Rewards) do
	local big = day == 7
	local w = big and BIG or CW
	local kind = KIND[reward.Icon] or KIND.Star
	local holder = frame(panel, x, CY, w, CH, rgb(0, 0, 0))
	holder.BackgroundTransparency = 1
	local hs = Instance.new("UIScale", holder)
	local c = frame(holder, 0, 0, w, CH, rgb(255, 255, 255), 18)
	c.ClipsDescendants = true
	local cg = grad(c, big and rgb(255, 225, 120) or rgb(58, 40, 118), big and rgb(225, 130, 30) or rgb(32, 22, 72))
	local cs = stroke(c, big and rgb(255, 240, 170) or kind.col, 3)
	-- цветная шапка «DAY N»
	local band = frame(c, 0, 0, w, 34, kind.col)
	grad(band, kind.col:Lerp(Color3.new(1, 1, 1), 0.25), kind.col:Lerp(Color3.new(0, 0, 0), 0.2))
	if big then
		band.BackgroundTransparency = 1
	end
	local dayText = text(c, big and "DAY 7 · JACKPOT" or ("DAY " .. day), 0, 4, w, 28, 20, nil, 2)
	-- лучи за иконкой (только джекпот)
	local rays
	if big then
		rays = frame(c, w / 2 - 80, 40, 160, 160, rgb(0, 0, 0))
		rays.BackgroundTransparency = 1
		for i = 0, 5 do
			local r = frame(rays, 68, 0, 24, 160, rgb(255, 250, 225))
			r.BackgroundTransparency = 0.15
			r.Rotation = i * 30
			local rg = Instance.new("UIGradient")
			rg.Rotation = 90
			rg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
			rg.Parent = r
		end
	end
	-- светящийся круг с иконкой
	local orbSize = big and 96 or 72
	local orb = frame(c, (w - orbSize) / 2, big and 56 or 46, orbSize, orbSize, kind.col, UDim.new(1, 0))
	orb.BackgroundTransparency = big and 0.35 or 0.7
	local os = stroke(orb, kind.col, 3)
	os.Transparency = 0.2
	local icon
	local image = kind.image
	if image then
		-- картинка зелья чуть больше круга — бутылка «выходит» за его край
		icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Image = image
		icon.Position = UDim2.fromOffset(-14, -16)
		icon.Size = UDim2.fromOffset(orbSize + 28, orbSize + 28)
		icon.Parent = orb
	else
		icon = text(orb, kind.icon, 0, 0, orbSize, orbSize, big and 64 or 46, nil, 0)
	end
	local iconBase = icon.Position
	-- плашка SUPER: эту награду не купить за монеты
	local hasSuper = false
	for name in pairs(reward.Potions or {}) do
		if ShopConfig.Potions[name] and ShopConfig.Potions[name].Super then
			hasSuper = true
		end
	end
	if hasSuper and not big then
		local tag = frame(c, w / 2 - 30, 36, 60, 18, rgb(255, 255, 255), 9)
		grad(tag, rgb(255, 235, 120), rgb(240, 150, 30))
		stroke(tag, INK, 2)
		tag.ZIndex = 4
		local tt = text(tag, "SUPER", 0, 1, 60, 16, 14, nil, 1.5)
		tt.ZIndex = 5
	end
	-- сумма / название
	local name = text(c, reward.Name, 6, big and 150 or 124, w - 12, big and 54 or 52, big and 19 or 18, nil, 2)
	-- статус внизу
	local pill = frame(c, 10, CH - 42, w - 20, 30, INK, 12)
	pill.BackgroundTransparency = 0.2
	local status = text(pill, "", 0, 2, w - 20, 26, 17, nil, 0)
	-- блик, бегущий по текущей карточке
	local shine = frame(c, -80, -20, 40, CH + 40, rgb(255, 255, 255))
	shine.Rotation = 18
	shine.BackgroundTransparency = 0.75
	shine.Visible = false
	-- штамп «получено»
	local stamp = frame(holder, w / 2 - 34, 58, 68, 68, rgb(70, 200, 90), UDim.new(1, 0))
	stroke(stamp, rgb(20, 80, 30), 4)
	stamp.Rotation = -12
	stamp.ZIndex = 5
	local stampText = text(stamp, "✓", 0, 0, 68, 68, 50, nil, 2)
	stampText.ZIndex = 6
	stamp.Visible = false
	if big then
		local crown = text(holder, "👑", w / 2 - 24, -34, 48, 44, 40, nil, 0)
		crown.ZIndex = 4
	end
	cells[day] = {
		holder = holder, scale = hs, card = c, grad = cg, stroke = cs, band = band, orb = orb, icon = icon, iconBase = iconBase,
		name = name, pill = pill, status = status, shine = shine, stamp = stamp, rays = rays, reward = reward, kind = kind, big = big, w = w,
	}
	x += w + GAP
end

------------------------------------------------------------------ дорожка серии
local TRACK_Y = CY + CH + 18
local trackBack = frame(panel, 60, TRACK_Y + 8, W - 120, 10, rgb(20, 10, 45), 5)
local trackFill = frame(trackBack, 0, 0, 0, 10, GOLD, 5)
grad(trackFill, rgb(255, 235, 120), rgb(245, 160, 40), 0)
local nodes = {}
for day = 1, 7 do
	local cx = cells[day].holder.Position.X.Offset + cells[day].w / 2
	local n = frame(panel, cx - 13, TRACK_Y, 26, 26, rgb(40, 26, 80), UDim.new(1, 0))
	stroke(n, INK, 3)
	local nt = text(n, tostring(day), 0, 1, 26, 24, 16, nil, 0)
	nodes[day] = { f = n, t = nt, x = cx }
end

------------------------------------------------------------------ кнопка
local note = text(panel, "", 40, TRACK_Y + 34, W - 80, 22, 17, rgb(210, 195, 245), 0)
local claim = Instance.new("TextButton")
claim.Position = UDim2.fromOffset(W / 2 - 190, H - 70)
claim.Size = UDim2.fromOffset(380, 58)
claim.Text = ""
claim.AutoButtonColor = false
claim.BackgroundColor3 = rgb(255, 255, 255)
claim.ClipsDescendants = true
claim.Parent = panel
round(claim, 18)
local claimStroke = stroke(claim, INK, 4)
local claimScale = Instance.new("UIScale", claim)
local claimGrad = grad(claim, rgb(255, 225, 90), rgb(240, 140, 30))
local claimGloss = frame(claim, 8, 5, 364, 20, rgb(255, 255, 255), 10)
claimGloss.BackgroundTransparency = 0.7
local claimShine = frame(claim, -60, -10, 34, 80, rgb(255, 255, 255))
claimShine.Rotation = 20
claimShine.BackgroundTransparency = 0.6
local claimLabel = text(claim, "", 0, 4, 380, 50, 30, nil, 3)
claim.MouseEnter:Connect(function()
	if claim.Active then
		Tween:Create(claimScale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1.06 }):Play()
	end
end)
claim.MouseLeave:Connect(function()
	Tween:Create(claimScale, TweenInfo.new(0.1), { Scale = 1 }):Play()
end)

------------------------------------------------------------------ состояние
local busy = false
local current = 1
local ready = false
local function refresh()
	local now = workspace:GetServerTimeNow()
	local day = p:GetAttribute("DailyDay") or 0
	local state = D.State(day, p:GetAttribute("DailyClaimedAt"), now)
	ready = state.Ready and p:GetAttribute("ProfileReady") == true
	current = state.Day
	local shownDay = (state.Ready and state.Day == 1) and 0 or day -- новая неделя: прошлые галочки не показываем
	for i, c in ipairs(cells) do
		local amount = c.reward.Coins and NumberFormat.Short(D.CoinsFor(c.reward, p:GetAttribute("LifetimeEarned")))
		if c.big then
			-- джекпот: коротко в две строки
			local supers = 0
			for _, n in pairs(c.reward.Potions or {}) do
				supers += n
			end
			local eggs = c.reward.FreeHatch == true and 1 or (c.reward.FreeHatch or 0)
			c.name.Text = (amount and (amount .. " coins") or "") .. (eggs > 0 and ("\n+ " .. eggs .. " top eggs") or "") .. "\n+ " .. supers .. " Super potions" .. (c.reward.RushKeys and " + key" or "")
		else
			c.name.Text = describe(c.reward, amount)
		end
		local isNow = i == current
		local claimed = i <= shownDay and not (isNow and state.Ready)
		c.stamp.Visible = claimed
		if c.icon:IsA("ImageLabel") then
			c.icon.ImageTransparency = claimed and 0.6 or 0
		else
			c.icon.TextTransparency = claimed and 0.6 or 0
		end
		c.orb.BackgroundTransparency = claimed and 0.9 or (c.big and 0.35 or 0.7)
		c.name.TextTransparency = claimed and 0.45 or 0
		c.shine.Visible = isNow and ready
		if isNow and ready then
			c.stroke.Color = rgb(255, 245, 140)
			c.stroke.Thickness = 5
			c.status.Text = "CLAIM NOW!"
			c.pill.BackgroundColor3 = rgb(60, 170, 60)
		elseif claimed then
			c.stroke.Color = rgb(80, 70, 110)
			c.stroke.Thickness = 3
			c.status.Text = "CLAIMED"
			c.pill.BackgroundColor3 = rgb(40, 110, 50)
		elseif isNow then
			c.stroke.Color = c.big and rgb(255, 240, 170) or c.kind.col
			c.stroke.Thickness = 3
			c.status.Text = "TOMORROW"
			c.pill.BackgroundColor3 = INK
		else
			c.stroke.Color = c.big and rgb(255, 240, 170) or c.kind.col
			c.stroke.Thickness = 3
			c.status.Text = ""
			c.pill.BackgroundColor3 = INK
		end
		c.pill.Visible = c.status.Text ~= ""
		if not (isNow and ready) then
			c.scale.Scale = 1
			c.icon.Position = c.iconBase
		end
	end
	-- дорожка серии
	local done = math.clamp(shownDay, 0, 7)
	local last = done > 0 and nodes[done].x - 60 or 0
	trackFill.Size = UDim2.fromOffset(math.max(0, last), 10)
	for i, n in ipairs(nodes) do
		local on = i <= done
		n.f.BackgroundColor3 = on and GOLD or (i == current and rgb(90, 200, 90) or rgb(40, 26, 80))
		n.t.Text = on and "✓" or tostring(i)
	end
	if busy then
		claimLabel.Text = "CLAIMING..."
	elseif ready then
		claimLabel.Text = "CLAIM DAY " .. current .. "!"
	else
		local r = state.Remaining
		claimLabel.Text = string.format("⏰ NEXT IN %02d:%02d:%02d", math.floor(r / 3600), math.floor(r / 60) % 60, math.floor(r) % 60)
	end
	claim.Active = (ready and not busy) and true or false
	claimGrad.Color = claim.Active and ColorSequence.new(rgb(255, 225, 90), rgb(240, 140, 30)) or ColorSequence.new(rgb(110, 95, 160), rgb(70, 58, 120))
	claimShine.Visible = claim.Active
	if not busy then
		note.Text = ready and "Your gift is ready! Missing a day never resets your streak." or "See you tomorrow! A new gift every day at 00:00 UTC."
	end
end

-- салют из иконок награды при получении
local function burst(c)
	local base = c.holder.AbsolutePosition - panel.AbsolutePosition
	for i = 1, 14 do
		local s = text(panel, c.kind.icon, 0, 0, 34, 34, 30, nil, 0)
		local sx = (base.X / scale.Scale) + c.w / 2 - 17
		local sy = (base.Y / scale.Scale) + 80
		s.Position = UDim2.fromOffset(sx, sy)
		s.ZIndex = 20
		local a = (i / 14) * math.pi * 2
		local d = math.random(90, 170)
		Tween:Create(s, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(sx + math.cos(a) * d, sy + math.sin(a) * d * 0.7),
			Rotation = math.random(-90, 90),
			TextTransparency = 1,
		}):Play()
		task.delay(0.75, function()
			s:Destroy()
		end)
	end
	c.scale.Scale = 1.25
	Tween:Create(c.scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

claim.Activated:Connect(function()
	local state = D.State(p:GetAttribute("DailyDay"), p:GetAttribute("DailyClaimedAt"), workspace:GetServerTimeNow())
	if busy or not state.Ready or not p:GetAttribute("ProfileReady") then
		return
	end
	local cell = cells[state.Day]
	busy = true
	refresh()
	local ok, result = pcall(function()
		return remote:InvokeServer()
	end)
	busy = false
	refresh()
	note.Text = ok and result.Message or "Couldn't reach the server. Please try again."
	if ok and result.Ok and cell then
		burst(cell)
		claimScale.Scale = 1.15
		Tween:Create(claimScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end)

local function setOpen(open)
	if open == panel.Visible then
		return
	end
	panel.Visible = open
	if open then
		refresh()
		-- появление: карточки по очереди «выпрыгивают»
		for i, c in ipairs(cells) do
			c.scale.Scale = 0.6
			task.delay(0.04 * i, function()
				Tween:Create(c.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			end)
		end
	end
end
p:GetAttributeChangedSignal("UIScreen"):Connect(function()
	setOpen(p:GetAttribute("UIScreen") == "daily")
end)

local elapsed, t = 0, 0
Run.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		local v = camera.ViewportSize
		scale.Scale = math.min(1, (v.X - 26) / W, (v.Y - 90) / (H + 40))
	end
	if not panel.Visible then
		return
	end
	t += dt
	for _, s in ipairs(stars) do
		s.f.BackgroundTransparency = 0.45 + 0.45 * math.sin(t * 2 + s.ph)
	end
	local c7 = cells[7]
	if c7 and c7.rays then
		c7.rays.Rotation = t * 25
	end
	local c = cells[current]
	if c and ready and not busy then
		c.icon.Position = c.iconBase + UDim2.fromOffset(0, math.sin(t * 4) * 5)
		if c.scale.Scale > 0.99 then
			c.scale.Scale = 1.04 + math.sin(t * 3) * 0.02
		end
		c.stroke.Transparency = 0.25 * (1 + math.sin(t * 5)) / 2
		c.shine.Position = UDim2.fromOffset(((t * 140) % (c.w + 260)) - 120, -20)
	end
	if claim.Active then
		claimShine.Position = UDim2.fromOffset(((t * 260) % 700) - 120, -10)
	end
	elapsed += dt
	if elapsed > 1 then
		elapsed = 0
		if not busy then
			refresh()
		end
	end
end)
