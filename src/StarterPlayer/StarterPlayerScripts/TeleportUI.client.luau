-- Окно TELEPORT: карточки миров. Открывается атрибутом UIScreen = "teleport" (кнопка в GameHUD).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Worlds = require(RS:WaitForChild("WorldsConfig"))
local remote = RS:WaitForChild("WorldTeleport")
local stats = player:WaitForChild("leaderstats")
local rgb = Color3.fromRGB
local ink = rgb(40, 24, 70)

local gui = Instance.new("ScreenGui")
gui.Name = "TeleportUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(f, r)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, r)
end
local function stroke(f, c, t)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = t
	s.Parent = f
	return s
end
local function label(parent, text, pos, size, ts, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextSize = ts
	l.TextWrapped = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Parent = parent
	local s = stroke(l, ink, 2)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	return l
end

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(880, 400)
panel.BackgroundColor3 = rgb(70, 40, 150)
panel.Visible = false
panel:SetAttribute("NoTheme", true) -- свой фиолетовый стиль, как у DAILY
panel.Parent = gui
corner(panel, 26)
stroke(panel, ink, 5)
local pg = Instance.new("UIGradient", panel)
pg.Color = ColorSequence.new(rgb(125, 85, 235), rgb(55, 30, 125))
pg.Rotation = 90
local scale = Instance.new("UIScale", panel)

local head = Instance.new("Frame")
head.Position = UDim2.fromOffset(240, -26)
head.Size = UDim2.fromOffset(400, 62)
head.BackgroundColor3 = rgb(200, 90, 255)
head.Parent = panel
corner(head, 18)
stroke(head, ink, 4)
local hg = Instance.new("UIGradient", head)
hg.Color = ColorSequence.new(rgb(235, 150, 255), rgb(160, 60, 230))
hg.Rotation = 90
label(head, "🌀 TELEPORT", UDim2.fromOffset(0, 4), UDim2.fromOffset(400, 54), 34)

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(822, 12)
close.Size = UDim2.fromOffset(42, 42)
close.Text = "×"
close.Font = Enum.Font.FredokaOne
close.TextSize = 30
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = rgb(235, 70, 80)
close.Modal = true
close.Parent = panel
corner(close, 12)
stroke(close, ink, 3)
close.Activated:Connect(function()
	player:SetAttribute("UIScreen", "")
end)

label(panel, "CHOOSE A WORLD TO TRAVEL TO", UDim2.fromOffset(20, 50), UDim2.fromOffset(840, 24), 17, rgb(225, 205, 255))

local cards = {}
local CW, GAP = 156, 12
-- Карточки едут в полосе с прокруткой: в окно влезает 5, стрелки по бокам листают к остальным.
local VISIBLE = 5
local strip = Instance.new("ScrollingFrame")
strip.Name = "Strip"
strip.Position = UDim2.fromOffset(26, 84)
strip.Size = UDim2.fromOffset(VISIBLE * (CW + GAP) - GAP + 8, 296)
strip.BackgroundTransparency = 1
strip.BorderSizePixel = 0
strip.ScrollBarThickness = 0
strip.ScrollingDirection = Enum.ScrollingDirection.X
strip.ElasticBehavior = Enum.ElasticBehavior.Never
strip.CanvasSize = UDim2.fromOffset(#Worlds.Worlds * (CW + GAP) - GAP + 8, 0)
strip.ClipsDescendants = true
strip.Parent = panel
local function arrow(text, x)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.fromOffset(x, 230)
	b.Size = UDim2.fromOffset(46, 70)
	b.Text = text
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 34
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = rgb(255, 196, 60)
	b.AutoButtonColor = true
	b.ZIndex = 5
	b.Parent = panel
	corner(b, 14)
	stroke(b, ink, 3.5)
	local bg = Instance.new("UIGradient", b)
	bg.Color = ColorSequence.new(rgb(255, 225, 120), rgb(240, 150, 30))
	bg.Rotation = 90
	return b
end
local maxScroll = math.max(0, #Worlds.Worlds - VISIBLE) * (CW + GAP)
local left = arrow("‹", 4)
local right = arrow("›", 876)
local function updateArrows()
	local x = strip.CanvasPosition.X
	left.Visible = x > 4
	right.Visible = x < maxScroll - 4
end
local function scrollTo(x)
	x = math.clamp(x, 0, maxScroll)
	TweenService:Create(strip, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CanvasPosition = Vector2.new(x, 0) }):Play()
end
left.Activated:Connect(function()
	scrollTo(strip.CanvasPosition.X - (CW + GAP) * 2)
end)
right.Activated:Connect(function()
	scrollTo(strip.CanvasPosition.X + (CW + GAP) * 2)
end)
strip:GetPropertyChangedSignal("CanvasPosition"):Connect(updateArrows)
updateArrows()
for i, def in ipairs(Worlds.Worlds) do
	local card = Instance.new("Frame")
	card.Position = UDim2.fromOffset(4 + (i - 1) * (CW + GAP), 6)
	card.Size = UDim2.fromOffset(CW, 280)
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.Parent = strip
	corner(card, 18)
	local cs = stroke(card, ink, 3.5)
	local g = Instance.new("UIGradient", card)
	g.Color = ColorSequence.new(def.Top, def.Bottom)
	g.Rotation = 90
	local gloss = Instance.new("Frame")
	gloss.Position = UDim2.fromOffset(5, 5)
	gloss.Size = UDim2.new(1, -10, 0, 70)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.78
	gloss.BorderSizePixel = 0
	gloss.Parent = card
	corner(gloss, 14)
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(0, 12)
	icon.Size = UDim2.new(1, 0, 0, 80)
	icon.Text = def.Emoji
	icon.TextSize = 62
	icon.Parent = card
	label(card, string.upper(def.Name), UDim2.fromOffset(6, 100), UDim2.new(1, -12, 0, 44), 19)
	local desc = label(card, def.Desc, UDim2.fromOffset(8, 146), UDim2.new(1, -16, 0, 34), 13, rgb(255, 255, 255))
	desc.Font = Enum.Font.GothamBold
	local info = label(card, "", UDim2.fromOffset(6, 182), UDim2.new(1, -12, 0, 24), 14, rgb(255, 245, 160))
	local go = Instance.new("TextButton")
	go.Position = UDim2.fromOffset(12, 222)
	go.Size = UDim2.new(1, -24, 0, 44)
	go.Font = Enum.Font.FredokaOne
	go.TextSize = 20
	go.TextColor3 = Color3.new(1, 1, 1)
	go.AutoButtonColor = false
	go.Parent = card
	corner(go, 12)
	stroke(go, ink, 3)
	local gs = Instance.new("UIScale", go)
	go.MouseEnter:Connect(function()
		if go.Active then
			TweenService:Create(gs, TweenInfo.new(0.1), { Scale = 1.07 }):Play()
		end
	end)
	go.MouseLeave:Connect(function()
		TweenService:Create(gs, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	cards[i] = { def = def, go = go, info = info, stroke = cs }
end

local NumberFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberFormat"))
local function short(n)
	return NumberFormat.Short(n)
end
local busy = false
local confirmId, confirmUntil = nil, 0 -- покупка мира: первое касание спрашивает, второе покупает
local function refresh()
	local current = player:GetAttribute("CurrentWorld")
	local speed = stats.SpeedLevel.Value
	for _, c in ipairs(cards) do
		local d = c.def
		c.stroke.Color = ink
		c.stroke.Thickness = 3.5
		if not d.Open then
			c.info.Text = "🔒 Coming soon"
			c.go.Text = "SOON"
			c.go.BackgroundColor3 = rgb(120, 115, 140)
			c.go.Active = false
		elseif current == d.Id then
			c.info.Text = "📍 You are here"
			c.go.Text = "HERE"
			c.go.BackgroundColor3 = rgb(120, 115, 140)
			c.go.Active = false
			c.stroke.Color = rgb(255, 235, 90)
			c.stroke.Thickness = 5
		elseif speed < d.Speed then
			c.info.Text = "🔒 Needs speed level " .. d.Speed
			c.go.Text = "LOCKED"
			c.go.BackgroundColor3 = rgb(120, 115, 140)
			c.go.Active = false
		elseif (d.Cost or 0) > 0 and not player:GetAttribute(Worlds.UnlockKey(d.Id)) then
			-- мир ещё не куплен: цена на карточке, кнопка покупает и сразу переносит
			local enough = stats.Coins.Value >= d.Cost
			c.info.Text = "🔒 Unlock for 🪙 " .. short(d.Cost)
			local asking = confirmId == d.Id and os.clock() < confirmUntil
			c.go.Text = busy and "..." or (asking and "SURE?" or "UNLOCK")
			if asking then
				c.info.Text = "Tap again: spend 🪙 " .. short(d.Cost)
			end
			c.go.BackgroundColor3 = enough and rgb(255, 170, 40) or rgb(150, 120, 90)
			c.go.Active = not busy
		else
			c.info.Text = "Unlocked"
			c.go.Text = busy and "..." or "GO!"
			c.go.BackgroundColor3 = rgb(95, 200, 70)
			c.go.Active = not busy
		end
	end
end

for _, c in ipairs(cards) do
	c.go.Activated:Connect(function()
		if busy or not c.go.Active then
			return
		end
		local d = c.def
		local locked = (d.Cost or 0) > 0 and not player:GetAttribute(Worlds.UnlockKey(d.Id))
		if locked and stats.Coins.Value >= d.Cost and not (confirmId == d.Id and os.clock() < confirmUntil) then
			confirmId, confirmUntil = d.Id, os.clock() + 3
			refresh()
			task.delay(3.1, refresh)
			return
		end
		confirmId = nil
		busy = true
		refresh()
		local ok, result = pcall(function()
			return remote:InvokeServer(c.def.Id)
		end)
		busy = false
		if ok and result and result.Ok then
			player:SetAttribute("UIScreen", "")
		end
		refresh()
	end)
end

player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	panel.Visible = player:GetAttribute("UIScreen") == "teleport"
	if panel.Visible then
		refresh()
		-- открываем полосу так, чтобы текущий мир был виден
		local current = player:GetAttribute("CurrentWorld")
		for i, c in ipairs(cards) do
			if c.def.Id == current then
				strip.CanvasPosition = Vector2.new(math.clamp((i - 3) * (CW + GAP), 0, maxScroll), 0)
			end
		end
		updateArrows()
	end
end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(refresh)
stats.SpeedLevel.Changed:Connect(refresh)
stats.Coins.Changed:Connect(function()
	if panel.Visible then
		refresh()
	end
end)
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 12) == "Save_Unlock_" then
		refresh()
	end
end)
RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if camera then
		local v = camera.ViewportSize
		scale.Scale = math.min(1, (v.X - 26) / 880, (v.Y - 80) / 420)
	end
end)
refresh()
