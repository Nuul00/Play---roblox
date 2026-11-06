-- Зелья: выдвижная вкладка у края экрана (стрелка + бутылка + число зелий).
-- Клик — выезжает панель со всеми зельями игрока (обычные и СУПЕР): картинка, сколько есть,
-- таймер и кнопка USE. Рядом с вкладкой — ряд активных зелий с таймерами (мигают в конце).
-- Сторона (справа/слева) — в настройках; вкладку можно тянуть вверх-вниз вдоль края.
-- Вкладка никогда не встаёт на другие кнопки: свободные места по краю ищем сканированием
-- экрана (GetGuiObjectsAtPosition) и ставим её на ближайшее свободное к выбранному игроком.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local K = require(RS:WaitForChild("UIKit"))
local action = RS:WaitForChild("GameAction")
local player = Players.LocalPlayer
local INK = K.INK
local rgb = Color3.fromRGB

local gui = Instance.new("ScreenGui")
gui.Name = "PotionHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 13
gui.Parent = player:WaitForChild("PlayerGui")

-- док = вкладка; панель и ряд активных зелий висят рядом с ним (за его границами)
local TAB_W, TAB_H = 50, 76
local root = Instance.new("Frame")
root.Name = "PotionDock"
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(1, 0)
root.Position = UDim2.new(1, 0, 0.42, 0)
root.Size = UDim2.fromOffset(TAB_W, TAB_H)
root.Parent = gui
local rootScale = Instance.new("UIScale")
rootScale.Parent = root

------------------------------------------------------------------ вкладка
local tab = Instance.new("TextButton")
tab.Name = "PotionTab"
tab.Position = UDim2.fromOffset(0, 0)
tab.Size = UDim2.fromOffset(TAB_W, TAB_H)
tab.Text = ""
tab.AutoButtonColor = false
tab.BackgroundColor3 = Color3.new(1, 1, 1)
tab.Parent = root
K.corner(tab, 16)
K.stroke(tab, INK, 3)
K.grad(tab, rgb(190, 130, 255), rgb(100, 50, 200))
-- правый край вкладки «уходит» за экран: прячем правые скругления
local flat = K.frame(tab, UDim2.new(1, -16, 0, 0), UDim2.new(0, 16, 1, 0), Color3.new(1, 1, 1))
K.grad(flat, rgb(190, 130, 255), rgb(100, 50, 200))
local arrow = K.text(tab, "◀", UDim2.fromOffset(2, 3), UDim2.fromOffset(TAB_W - 4, 20), 18, nil, 2)
arrow.ZIndex = 3
local bottle = Instance.new("ImageLabel")
bottle.BackgroundTransparency = 1
bottle.Image = ShopConfig.Potions.SuperLuck.Image or ""
bottle.Position = UDim2.fromOffset(6, 24)
bottle.Size = UDim2.fromOffset(38, 38)
bottle.ZIndex = 3
bottle.Parent = tab
local badge = K.text(tab, "0", UDim2.fromOffset(-10, TAB_H - 22), UDim2.fromOffset(30, 22), 15, nil, 1.5)
badge.BackgroundTransparency = 0
badge.BackgroundColor3 = rgb(235, 60, 80)
badge.ZIndex = 4
K.corner(badge, 11)
K.stroke(badge, INK, 2)
local tabScale = Instance.new("UIScale")
tabScale.Parent = tab
tab.MouseEnter:Connect(function()
	Tween:Create(tabScale, TweenInfo.new(0.1), { Scale = 1.07 }):Play()
end)
tab.MouseLeave:Connect(function()
	Tween:Create(tabScale, TweenInfo.new(0.1), { Scale = 1 }):Play()
end)

------------------------------------------------------------------ панель
local PW = 318
local ROW = 56
local list = ShopConfig.AllPotions
local PH = 52 + #list * (ROW + 6) + 22
local panel = K.frame(root, UDim2.fromOffset(-8, 0), UDim2.fromOffset(PW, PH), Color3.new(1, 1, 1), 20)
panel.AnchorPoint = Vector2.new(1, 0)
panel.Visible = false
panel.Active = true -- клики по панели не считаются «мимо»
K.grad(panel, rgb(62, 36, 130), rgb(20, 12, 52))
K.stroke(panel, INK, 4)
local title = K.text(panel, "🧪 MY POTIONS", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 30), 24, nil, 2.5)
title.TextXAlignment = Enum.TextXAlignment.Left
local hint = K.text(panel, "Super potions come from rewards only", UDim2.new(0, 14, 1, -22), UDim2.new(1, -28, 0, 16), 13, rgb(190, 175, 235), 0)
hint.TextXAlignment = Enum.TextXAlignment.Left
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

local rows = {}
for i, name in ipairs(list) do
	local def = ShopConfig.Potions[name]
	local y = 46 + (i - 1) * (ROW + 6)
	local row = K.frame(panel, UDim2.fromOffset(10, y), UDim2.fromOffset(PW - 20, ROW), Color3.new(1, 1, 1), 14)
	K.grad(row, def.Color:Lerp(K.CARD, def.Super and 0.6 or 0.78), K.CARD2)
	local rs = K.stroke(row, def.Super and K.GOLD or def.Color, def.Super and 2.5 or 1.5)
	rs.Transparency = 0.15
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Image = def.Image or ""
	img.Position = UDim2.fromOffset(4, 3)
	img.Size = UDim2.fromOffset(50, 50)
	img.Parent = row
	local nm = K.text(row, def.Short or def.Name, UDim2.fromOffset(58, 6), UDim2.fromOffset(140, 22), 17, def.Super and rgb(255, 225, 120) or nil, 2)
	nm.TextXAlignment = Enum.TextXAlignment.Left
	local eff = K.text(row, def.Effect, UDim2.fromOffset(58, 30), UDim2.fromOffset(140, 18), 14, def.Color:Lerp(Color3.new(1, 1, 1), 0.4), 0)
	eff.TextXAlignment = Enum.TextXAlignment.Left
	local count = K.text(row, "×0", UDim2.fromOffset(170, 6), UDim2.fromOffset(38, 22), 18, nil, 2)
	local timer = K.text(row, "", UDim2.fromOffset(160, 32), UDim2.fromOffset(52, 18), 14, rgb(140, 255, 140), 1.5)
	local use, useLabel, useColor = K.button(row, "USE", UDim2.fromOffset(PW - 20 - 84, 10), UDim2.fromOffset(76, 36), K.GREEN, 18)
	use.Activated:Connect(function()
		if (player:GetAttribute("Potion" .. name) or 0) > 0 then
			action:FireServer("potion", name)
		end
	end)
	rows[name] = { img = img, count = count, timer = timer, use = use, useLabel = useLabel, useColor = useColor, row = row, nm = nm }
end

------------------------------------------------------------------ активные зелья (под вкладкой)
local active = Instance.new("Frame")
active.Name = "Active"
active.BackgroundTransparency = 1
active.AnchorPoint = Vector2.new(1, 0)
active.Position = UDim2.fromOffset(-8, 3)
active.Size = UDim2.fromOffset(6 * 68, 70)
active.Parent = root
local lay = Instance.new("UIListLayout")
lay.FillDirection = Enum.FillDirection.Horizontal
lay.Padding = UDim.new(0, 6)
lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Parent = active
local chips = {}
for i, name in ipairs(list) do
	local def = ShopConfig.Potions[name]
	local chip = Instance.new("Frame")
	chip.Name = name
	chip.LayoutOrder = i
	chip.Size = UDim2.fromOffset(62, 70)
	chip.BackgroundTransparency = 1
	chip.Visible = false
	chip.Parent = active
	local glow = K.frame(chip, UDim2.fromOffset(31, 27), UDim2.fromOffset(58, 58), def.Color, UDim.new(1, 0))
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 0.45
	K.stroke(glow, def.Super and K.GOLD or INK, 3)
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromOffset(31, 27)
	img.Size = UDim2.fromOffset(54, 54)
	img.Image = def.Image or ""
	img.Parent = chip
	local timer = K.text(chip, "", UDim2.new(0.5, -29, 1, -18), UDim2.fromOffset(58, 18), 14, nil, 0)
	timer.BackgroundTransparency = 0.1
	timer.BackgroundColor3 = INK
	K.corner(timer, 8)
	K.stroke(timer, def.Super and K.GOLD or def.Color, 1.5)
	local sc = Instance.new("UIScale")
	sc.Parent = chip
	chips[name] = { chip = chip, img = img, glow = glow, timer = timer, scale = sc }
end

------------------------------------------------------------------ открыть / закрыть
------------------------------------------------------------------ сторона, высота, свободные места
local open = false
local function side(): string
	return player:GetAttribute("Save_PotionSide") == "L" and "L" or "R"
end
local dockY = 0 -- верх вкладки, пиксели экрана (как AbsolutePosition)
local wantY = nil -- куда поставил игрок (доля высоты экрана)
local free = {} -- free[i] = true: полоса края на высоте i*STEP свободна
local STEP = 6
local function vp(): Vector2
	local cam = workspace.CurrentCamera
	return gui.AbsoluteSize.Magnitude > 0 and gui.AbsoluteSize or (cam and cam.ViewportSize or Vector2.new(1280, 720))
end
local function tabH(): number
	return TAB_H * rootScale.Scale
end
-- что считать «кнопкой/плашкой», которую нельзя закрывать (большие оверлеи и пустые рамки — нет)
local function solid(o: GuiObject, size: Vector2): boolean
	if o:IsDescendantOf(gui) then
		return false
	end
	local a = o.AbsoluteSize
	if a.X > size.X * 0.45 or a.Y > size.Y * 0.45 or a.X < 4 or a.Y < 4 then
		return false
	end
	if o:IsA("GuiButton") then
		return true
	end
	if o.BackgroundTransparency < 0.85 then
		return true
	end
	if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and (o :: any).Image ~= "" and (o :: any).ImageTransparency < 0.85 then
		return true
	end
	if o:IsA("TextLabel") and o.Text ~= "" and o.TextTransparency < 0.85 then
		return true
	end
	return false
end
local function scan()
	local size = vp()
	local w = TAB_W * rootScale.Scale
	local xs = side() == "R" and { size.X - 3, size.X - w / 2, size.X - w + 3 } or { 3, w / 2, w - 3 }
	table.clear(free)
	local pg = player.PlayerGui
	for i = 0, math.floor(size.Y / STEP) do
		local y = i * STEP
		local ok = y > 8 and y < size.Y - 8
		if ok then
			for _, x in ipairs(xs) do
				for _, o in ipairs(pg:GetGuiObjectsAtPosition(x, y)) do
					if solid(o, size) then
						ok = false
						break
					end
				end
				if not ok then
					break
				end
			end
		end
		free[i] = ok
	end
end
-- ближайшая к y высота, где вся вкладка (+ отступ) встаёт на свободное место
local function fits(y: number): boolean
	local h = tabH()
	for yy = y - 4, y + h + 4, STEP do
		if free[math.floor(yy / STEP)] == false or free[math.floor(yy / STEP)] == nil then
			return false
		end
	end
	return true
end
local function nearestFree(y: number): number
	local size = vp()
	y = math.clamp(y, 8, size.Y - tabH() - 8)
	if fits(y) then
		return y
	end
	for d = STEP, size.Y, STEP do
		if y - d >= 8 and fits(y - d) then
			return y - d
		end
		if y + d <= size.Y - tabH() - 8 and fits(y + d) then
			return y + d
		end
	end
	return y -- свободного места нет: оставляем, где просили
end
local function panelY(): number
	-- панель не вылезает за низ/верх экрана
	local size = vp()
	local s = rootScale.Scale
	local y = 0
	if dockY + PH * s > size.Y - 6 then
		y = (size.Y - 6 - dockY) / s - PH
	end
	return math.max(y, (6 - dockY) / s)
end
-- панель открывается в свободное место: правее (или левее) всех кнопок этого края
-- в её высоте — ROYAL EGG, TRADE, плитки статов и т.п. не закрываются
local function panelX(): number
	local size = vp()
	local sc = rootScale.Scale
	local right = side() == "R"
	local y0 = dockY + panelY() * sc
	local y1 = y0 + PH * sc
	local pg = player.PlayerGui
	local reach = right and size.X or 0 -- самый дальний от края край чужих кнопок
	local limit = size.X * 0.45
	for y = math.max(4, y0), math.min(size.Y - 4, y1), 22 do
		for d = TAB_W * sc + 4, limit, 18 do
			local x = right and (size.X - d) or d
			for _, o in ipairs(pg:GetGuiObjectsAtPosition(x, y)) do
				if solid(o, size) then
					local a, b = o.AbsolutePosition.X, o.AbsolutePosition.X + o.AbsoluteSize.X
					if right then
						reach = math.min(reach, a)
					else
						reach = math.max(reach, b)
					end
					break
				end
			end
		end
	end
	if right then
		local edge = math.min(reach, size.X - (TAB_W + 8) * sc) - 8
		return (edge - size.X) / sc + TAB_W -- в координатах дока (якорь панели справа)
	else
		local edge = math.max(reach, (TAB_W + 8) * sc) + 8
		return edge / sc
	end
end
local function applySide()
	local right = side() == "R"
	root.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	-- плоский край вкладки — к краю экрана
	flat.Position = right and UDim2.new(1, -16, 0, 0) or UDim2.fromOffset(0, 0)
	badge.Position = right and UDim2.fromOffset(-10, TAB_H - 22) or UDim2.new(1, -20, 0, TAB_H - 22)
	panel.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	active.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	active.Position = UDim2.fromOffset(right and -8 or TAB_W + 8, 3)
	lay.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
	arrow.Text = (open == right) and "▶" or "◀"
end
local function place()
	local size = vp()
	root.Position = UDim2.new(side() == "R" and 1 or 0, 0, 0, dockY)
	if open then
		panel.Position = UDim2.fromOffset(panelX(), panelY())
	end
	local _ = size
end

local function setOpen(v)
	open = v
	local right = side() == "R"
	arrow.Text = (v == right) and "▶" or "◀"
	if v then
		panel.Visible = true
		panelScale.Scale = 1
		local px = panelX()
		local dir = panel.AnchorPoint.X == 1 and 1 or -1
		panel.Position = UDim2.fromOffset(px + dir * 40, panelY())
		Tween:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Position = UDim2.fromOffset(px, panelY()) }):Play()
	else
		panel.Visible = false
	end
	active.Visible = not v -- панель сама показывает таймеры
	gui.DisplayOrder = v and 55 or 13 -- открытая панель поверх кнопок ROYAL EGG / TRADE
end
local justDragged = false
tab.Activated:Connect(function()
	if justDragged then
		justDragged = false
		return
	end
	setOpen(not open)
end)
-- перетаскивание вкладки вверх-вниз вдоль края (мышь и палец)
local dragging, dragStart, dockStart, moved = false, 0, 0, false
tab.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, moved = true, false
		dragStart, dockStart = input.Position.Y, dockY
	end
end)
UIS.InputChanged:Connect(function(input)
	if not dragging then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local d = input.Position.Y - dragStart
		if math.abs(d) > 8 then
			moved = true
		end
		if moved then
			dockY = nearestFree(dockStart + d) -- перескакивает через чужие кнопки
			place()
		end
	end
end)
UIS.InputEnded:Connect(function(input)
	if not dragging then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		if moved then
			justDragged = true
			task.delay(0.3, function()
				justDragged = false
			end)
			wantY = dockY / vp().Y
			action:FireServer("potiony", wantY)
		end
	end
end)
player:GetAttributeChangedSignal("Save_PotionSide"):Connect(function()
	applySide()
	scan()
	dockY = nearestFree(dockY)
	place()
end)

-- клик мимо панели и вкладки закрывает её
UIS.InputBegan:Connect(function(input, processed)
	if not open or processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setOpen(false)
	end
end)
-- другое окно открылось — прячем панель
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	if (player:GetAttribute("UIScreen") or "") ~= "" and open then
		setOpen(false)
	end
end)

------------------------------------------------------------------ обновление
-- раз в 1.5 с пересканируем край: появилась чужая кнопка — уходим с неё, освободилось — возвращаемся
task.spawn(function()
	task.wait(2) -- даём остальному HUD построиться
	applySide()
	wantY = player:GetAttribute("Save_PotionY") or 0.42
	while gui.Parent do
		if not dragging then
			scan()
			local target = nearestFree((wantY or 0.42) * vp().Y)
			if math.abs(target - dockY) > 1 then
				dockY = target
				place()
			end
		end
		task.wait(1.5)
	end
end)
player:GetAttributeChangedSignal("Save_PotionY"):Connect(function()
	if not dragging then
		wantY = player:GetAttribute("Save_PotionY") or wantY
	end
end)
local t = 0
Run.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.ViewportSize
		rootScale.Scale = math.clamp(math.min(v.X / 1000, v.Y / 620), 0.55, 1)
	end
	local now = os.time()
	local total = 0
	for _, name in ipairs(list) do
		local have = player:GetAttribute("Potion" .. name) or 0
		total += have
		local left = (player:GetAttribute("PotionEnd" .. name) or 0) - now
		local on = left > 0
		local timeText = on and string.format("%d:%02d", math.floor(left / 60), left % 60) or ""
		-- строка в панели
		local r = rows[name]
		r.count.Text = "×" .. have
		r.timer.Text = timeText
		r.img.ImageTransparency = (have > 0 or on) and 0 or 0.55
		r.nm.TextTransparency = (have > 0 or on) and 0 or 0.4
		r.use.Active = have > 0
		r.useLabel.Text = have > 0 and "USE" or "—"
		r.useColor(have > 0 and K.GREEN or K.GRAY)
		-- кружок активного зелья
		local c = chips[name]
		if on and not c.chip.Visible then
			c.scale.Scale = 0.3
			Tween:Create(c.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		c.chip.Visible = on
		if on then
			c.timer.Text = timeText
			c.img.Rotation = math.sin(t * 2 + #name) * 6
			c.glow.BackgroundTransparency = 0.45 + 0.2 * math.sin(t * 3)
			c.img.ImageTransparency = (left <= 15 and math.sin(t * 10) > 0) and 0.5 or 0
		end
	end
	badge.Text = total > 99 and "99+" or tostring(total)
	badge.Visible = total > 0
	-- вкладка подпрыгивает, когда есть непотраченные супер-зелья и панель закрыта
	if not open and total > 0 then
		bottle.Rotation = math.sin(t * 3) * 8
	else
		bottle.Rotation = 0
	end
end)
