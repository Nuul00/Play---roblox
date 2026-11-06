-- Активные зелья на экране: иконка бутылки (ChatGPT) с таймером, кольцо-подсветка и мигание
-- в последние 15 секунд. Раньше выпитое зелье никак не было видно, кроме цифры x2 на плитке.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local player = Players.LocalPlayer
local INK = Color3.fromRGB(30, 16, 60)

local gui = Instance.new("ScreenGui")
gui.Name = "PotionHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.Parent = player:WaitForChild("PlayerGui")

local row = Instance.new("Frame")
row.Name = "ActivePotions"
row.BackgroundTransparency = 1
row.AnchorPoint = Vector2.new(0, 1)
row.Position = UDim2.new(0, 14, 1, -232)
row.Size = UDim2.fromOffset(440, 74)
row.Parent = gui
local lay = Instance.new("UIListLayout")
lay.FillDirection = Enum.FillDirection.Horizontal
lay.Padding = UDim.new(0, 8)
lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
lay.Parent = row
local rowScale = Instance.new("UIScale")
rowScale.Parent = row

local chips = {}
for i, name in ipairs(ShopConfig.AllPotions) do
	local def = ShopConfig.Potions[name]
	local chip = Instance.new("Frame")
	chip.Name = name
	chip.LayoutOrder = i
	chip.Size = UDim2.fromOffset(64, 74)
	chip.BackgroundTransparency = 1
	chip.Visible = false
	chip.Parent = row
	local glow = Instance.new("Frame")
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromOffset(32, 28)
	glow.Size = UDim2.fromOffset(54, 54)
	glow.BackgroundColor3 = def.Color
	glow.BackgroundTransparency = 0.45
	glow.Parent = chip
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
	local gs = Instance.new("UIStroke")
	gs.Color = def.Super and Color3.fromRGB(255, 210, 70) or INK -- супер-зелье — золотая рамка
	gs.Thickness = 3
	gs.Parent = glow
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromOffset(32, 26)
	img.Size = UDim2.fromOffset(66, 66)
	img.Image = def.Image or ""
	img.Parent = chip
	local timer = Instance.new("TextLabel")
	timer.BackgroundColor3 = INK
	timer.BackgroundTransparency = 0.15
	timer.AnchorPoint = Vector2.new(0.5, 1)
	timer.Position = UDim2.new(0.5, 0, 1, 0)
	timer.Size = UDim2.fromOffset(58, 20)
	timer.Font = Enum.Font.FredokaOne
	timer.TextSize = 15
	timer.TextColor3 = Color3.new(1, 1, 1)
	timer.Text = ""
	timer.Parent = chip
	Instance.new("UICorner", timer).CornerRadius = UDim.new(0, 8)
	local ts = Instance.new("UIStroke")
	ts.Color = def.Color
	ts.Thickness = 1.5
	ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ts.Parent = timer
	local sc = Instance.new("UIScale")
	sc.Parent = chip
	chips[name] = { chip = chip, img = img, glow = glow, timer = timer, scale = sc }
end

-- ряд стоит сбоку от колонки статов MainHUD (справа от неё; на телефоне колонка справа — тогда слева)
local mainHud = player.PlayerGui:WaitForChild("MainHUD", 20)
local column = mainHud and mainHud:WaitForChild("Panels", 20)
if mainHud then
	gui.IgnoreGuiInset = mainHud.IgnoreGuiInset
end
local t = 0
Run.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if column and column.Parent then
		local cs = column:FindFirstChildOfClass("UIScale")
		local k = cs and cs.Scale or 1
		rowScale.Scale = math.clamp(k, 0.6, 1)
		-- низ последней плитки (рамка колонки выше и ниже плиток, по ней ряд уезжал вниз)
		local ap, as = column.AbsolutePosition, column.AbsoluteSize
		local bottom = 0
		for _, ch in ipairs(column:GetChildren()) do
			if ch:IsA("GuiObject") and ch.Visible then
				bottom = math.max(bottom, ch.AbsolutePosition.Y + ch.AbsoluteSize.Y)
			end
		end
		if bottom > 0 then
			as = Vector2.new(as.X, bottom - ap.Y)
		end
		local guiPos = gui.AbsolutePosition
		local right = cam and (ap.X + as.X / 2) < cam.ViewportSize.X / 2
		if right then
			row.AnchorPoint = Vector2.new(0, 1)
			lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
			row.Position = UDim2.fromOffset(ap.X - guiPos.X + as.X + 12, ap.Y - guiPos.Y + as.Y)
		else
			row.AnchorPoint = Vector2.new(1, 1)
			lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
			row.Position = UDim2.fromOffset(ap.X - guiPos.X - 12, ap.Y - guiPos.Y + as.Y)
		end
	elseif cam then
		rowScale.Scale = math.clamp(math.min(cam.ViewportSize.X / 900, cam.ViewportSize.Y / 600), 0.6, 1)
	end
	local now = os.time()
	for name, c in pairs(chips) do
		local left = (player:GetAttribute("PotionEnd" .. name) or 0) - now
		local on = left > 0
		if on and not c.chip.Visible then
			-- появление с «прыжком»
			c.scale.Scale = 0.3
			Tween:Create(c.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		c.chip.Visible = on
		if on then
			c.timer.Text = string.format("%d:%02d", math.floor(left / 60), left % 60)
			c.img.Rotation = math.sin(t * 2 + #name) * 6
			c.glow.BackgroundTransparency = 0.45 + 0.2 * math.sin(t * 3)
			c.img.ImageTransparency = (left <= 15 and math.sin(t * 10) > 0) and 0.5 or 0
		end
	end
end)
