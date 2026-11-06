-- Зелья справа: выдвижная вкладка у правого края (стрелка + бутылка + число зелий).
-- Клик — выезжает панель со всеми зельями игрока (обычные и СУПЕР): картинка, сколько есть,
-- таймер и кнопка USE. Под вкладкой — столбик активных зелий с таймерами (мигают в конце).
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

-- корень у правого края; всё внутри масштабируется вместе
local root = Instance.new("Frame")
root.Name = "PotionDock"
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(1, 0)
root.Position = UDim2.new(1, 0, 0.42, 0)
root.Size = UDim2.fromOffset(380, 420)
root.Parent = gui
local rootScale = Instance.new("UIScale")
rootScale.Parent = root

------------------------------------------------------------------ вкладка
local TAB_W, TAB_H = 50, 92
local tab = Instance.new("TextButton")
tab.Name = "PotionTab"
tab.AnchorPoint = Vector2.new(1, 0)
tab.Position = UDim2.new(1, 0, 0, 0)
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
local arrow = K.text(tab, "◀", UDim2.fromOffset(2, 6), UDim2.fromOffset(TAB_W - 4, 22), 20, nil, 2)
arrow.ZIndex = 3
local bottle = Instance.new("ImageLabel")
bottle.BackgroundTransparency = 1
bottle.Image = ShopConfig.Potions.SuperLuck.Image or ""
bottle.Position = UDim2.fromOffset(3, 30)
bottle.Size = UDim2.fromOffset(44, 44)
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
local panel = K.frame(root, UDim2.new(1, -(TAB_W + 8), 0, 0), UDim2.fromOffset(PW, PH), Color3.new(1, 1, 1), 20)
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
active.Position = UDim2.new(1, -6, 0, TAB_H + 10)
active.Size = UDim2.fromOffset(64, 6 * 76)
active.Parent = root
local lay = Instance.new("UIListLayout")
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
local open = false
local function setOpen(v)
	open = v
	arrow.Text = v and "▶" or "◀"
	if v then
		panel.Visible = true
		panelScale.Scale = 1
		panel.Position = UDim2.new(1, -(TAB_W + 8) + 40, 0, 0)
		Tween:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Position = UDim2.new(1, -(TAB_W + 8), 0, 0) }):Play()
	else
		panel.Visible = false
	end
	active.Visible = not v -- панель сама показывает таймеры
end
tab.Activated:Connect(function()
	setOpen(not open)
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
local mainHud = player.PlayerGui:WaitForChild("MainHUD", 20)
local column = mainHud and mainHud:FindFirstChild("Panels")
local t = 0
Run.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.ViewportSize
		rootScale.Scale = math.clamp(math.min(v.X / 1000, v.Y / 620), 0.55, 1)
		-- на телефоне колонка статов у правого края по центру: ставим док над ней
		if column and column.Parent and column.AbsolutePosition.X > v.X / 2 then
			local top = column.AbsolutePosition.Y - gui.AbsolutePosition.Y
			root.Position = UDim2.new(1, 0, 0, math.max(150, top - (TAB_H + 14) * rootScale.Scale))
		end
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
