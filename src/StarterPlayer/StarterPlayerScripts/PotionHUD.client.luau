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
local ResponsiveHUD = require(game:GetService("ReplicatedStorage"):WaitForChild("Responsive"))
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

------------------------------------------------------------------ выдвижная полоса
-- Полоса выезжает прямо из вкладки (та же высота, как продолжение вкладки): в ней все зелья
-- кружками. Клик — выпить, наведение — подсказка с названием и эффектом. Высота полосы та же,
-- что у вкладки, а вкладка стоит только на свободном месте — значит, полоса ничего не закрывает.
local list = ShopConfig.AllPotions
local CELL, GAP = 58, 4
local DW = 14 + #list * (CELL + GAP) + 14 + 10
local panel = K.frame(root, UDim2.fromOffset(10, 0), UDim2.fromOffset(DW, TAB_H), Color3.new(1, 1, 1), 18)
panel.Name = "Drawer"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Visible = false
panel.Active = true -- клики по полосе не считаются «мимо»
panel.ClipsDescendants = true
panel.ZIndex = 1
tab.ZIndex = 2
K.grad(panel, rgb(70, 42, 145), rgb(26, 16, 64))
K.stroke(panel, INK, 3)
local inner = Instance.new("Frame")
inner.Name = "Items"
inner.BackgroundTransparency = 1
inner.Size = UDim2.fromOffset(DW, TAB_H)
inner.Parent = panel
local tip = K.text(root, "", UDim2.fromOffset(0, -30), UDim2.fromOffset(260, 26), 16, nil, 2)
tip.BackgroundTransparency = 0.1
tip.BackgroundColor3 = INK
tip.Visible = false
tip.ZIndex = 5
K.corner(tip, 10)
local tipStroke = K.stroke(tip, K.GOLD, 2)

local rows = {}
for i, name in ipairs(list) do
	local def = ShopConfig.Potions[name]
	local x = 12 + (i - 1) * (CELL + GAP) + (def.Super and 14 or 0)
	local cell = Instance.new("TextButton")
	cell.Name = name
	cell.Text = ""
	cell.AutoButtonColor = false
	cell.BackgroundTransparency = 1
	cell.Position = UDim2.fromOffset(x, 4)
	cell.Size = UDim2.fromOffset(CELL, TAB_H - 8)
	cell.Parent = inner
	local ring = K.frame(cell, UDim2.fromOffset(CELL / 2, 27), UDim2.fromOffset(50, 50), def.Color, UDim.new(1, 0))
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 0.6
	local rs = K.stroke(ring, def.Super and K.GOLD or def.Color:Lerp(INK, 0.3), def.Super and 2.5 or 2)
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromOffset(CELL / 2, 27)
	img.Size = UDim2.fromOffset(48, 48)
	img.Image = def.Image or ""
	img.Parent = cell
	local count = K.text(cell, "0", UDim2.new(1, -22, 0, -1), UDim2.fromOffset(24, 18), 14, nil, 1.5)
	count.BackgroundTransparency = 0
	count.BackgroundColor3 = def.Super and rgb(230, 140, 30) or rgb(90, 70, 170)
	count.ZIndex = 3
	K.corner(count, 9)
	K.stroke(count, INK, 1.5)
	local timer = K.text(cell, "", UDim2.new(0.5, -27, 1, -16), UDim2.fromOffset(54, 16), 13, rgb(150, 255, 150), 1.5)
	timer.BackgroundTransparency = 0.15
	timer.BackgroundColor3 = INK
	timer.ZIndex = 3
	K.corner(timer, 7)
	local sc = Instance.new("UIScale")
	sc.Parent = cell
	cell.MouseEnter:Connect(function()
		Tween:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Back), { Scale = 1.1 }):Play()
		local have = player:GetAttribute("Potion" .. name) or 0
		tip.Text = def.Name .. " · " .. def.Effect .. (have > 0 and "" or (def.Super and " · from rewards" or " · buy in shop"))
		tipStroke.Color = def.Super and K.GOLD or def.Color
		tip.Visible = true
	end)
	cell.MouseLeave:Connect(function()
		Tween:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
		tip.Visible = false
	end)
	cell.Activated:Connect(function()
		if (player:GetAttribute("Potion" .. name) or 0) > 0 then
			action:FireServer("potion", name)
			sc.Scale = 0.8
			Tween:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end)
	rows[name] = { img = img, count = count, timer = timer, ring = ring }
end
-- золотая черта между обычными и СУПЕР
local divider = K.frame(inner, UDim2.fromOffset(12 + 3 * (CELL + GAP) + 3, 12), UDim2.fromOffset(3, TAB_H - 24), K.GOLD, 2)
divider.BackgroundTransparency = 0.3

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
local function applySide()
	local right = side() == "R"
	root.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	-- плоский край вкладки — к краю экрана
	flat.Position = right and UDim2.new(1, -16, 0, 0) or UDim2.fromOffset(0, 0)
	badge.Position = right and UDim2.fromOffset(-10, TAB_H - 22) or UDim2.new(1, -20, 0, TAB_H - 22)
	panel.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	panel.Position = UDim2.fromOffset(right and 10 or TAB_W - 10, 0)
	inner.Position = UDim2.fromOffset(right and 0 or 10, 0)
	tip.AnchorPoint = Vector2.new(right and 1 or 0, 1)
	tip.Position = UDim2.fromOffset(right and 0 or TAB_W, -4)
	active.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	active.Position = UDim2.fromOffset(right and -8 or TAB_W + 8, 3)
	lay.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
	arrow.Text = (open == right) and "▶" or "◀"
end
local function place()
	local size = vp()
	root.Position = UDim2.new(side() == "R" and 1 or 0, 0, 0, dockY)
	local _ = size
end

local function setOpen(v)
	open = v
	local right = side() == "R"
	arrow.Text = (v == right) and "▶" or "◀"
	if v then
		-- полоса «выдвигается» из вкладки
		panel.Visible = true
		panel.Size = UDim2.fromOffset(TAB_W, TAB_H)
		Tween:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(DW, TAB_H) }):Play()
	else
		panel.Visible = false
		tip.Visible = false
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
		rootScale.Scale = ResponsiveHUD.Scale() -- общий масштаб HUD (было min(X/1000, Y/620))
	end
	local now = os.time()
	local total = 0
	for _, name in ipairs(list) do
		local have = player:GetAttribute("Potion" .. name) or 0
		total += have
		local left = (player:GetAttribute("PotionEnd" .. name) or 0) - now
		local on = left > 0
		local timeText = on and string.format("%d:%02d", math.floor(left / 60), left % 60) or ""
		-- кружок в полосе
		local r = rows[name]
		r.count.Text = have > 99 and "99+" or tostring(have)
		r.count.Visible = have > 0
		r.timer.Text = timeText
		r.timer.Visible = on
		r.img.ImageTransparency = (have > 0 or on) and 0 or 0.6
		r.ring.BackgroundTransparency = on and (0.35 + 0.15 * math.sin(t * 3)) or 0.6
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
