-- Кнопка магазина трейлов. Раньше она была на панели ежедневных заданий (QuestUI партнёра),
-- панель отключена — кнопка живёт внизу по центру, слева от кнопки меню «≡» (MenuHUD.Dock),
-- такого же вида: квадрат со скруглением в цветах HUD-скина мира, иконка-молния скина и
-- счётчик ⚡ жетонов (SpeedTokens, их выдаёт квестовая линия). Открывает TrailShopUI через
-- BindableEvent QuestRemotes.OpenTrailShop (если его не создал QuestUI — создаём сами).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Skins = require(ReplicatedStorage:WaitForChild("HudSkins"))
local remotes = ReplicatedStorage:WaitForChild("QuestRemotes", 60)
if not remotes then
	return
end
local open = remotes:FindFirstChild("OpenTrailShop")
if not open then
	open = Instance.new("BindableEvent")
	open.Name = "OpenTrailShop"
	open.Parent = remotes
end

local playerGui = player:WaitForChild("PlayerGui")
local menu = playerGui:WaitForChild("MenuHUD", 30)
local dock = menu and menu:WaitForChild("Dock", 30)
local gui
if not dock then
	gui = Instance.new("ScreenGui")
	gui.Name = "TrailsButtonHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 12
	gui.Parent = playerGui
end

local SIZE = 76 -- как у «≡»
local btn = Instance.new("TextButton")
btn.Name = "TrailsButton"
btn.AnchorPoint = Vector2.new(1, 1)
-- «≡» 76x76 стоит по центру низа дока: ставим кнопку левее с зазором 14
btn.Position = dock and UDim2.new(0.5, -38 - 14, 1, 0) or UDim2.new(0.5, -52, 1, -82)
btn.Size = UDim2.fromOffset(SIZE, SIZE)
btn.AutoButtonColor = false
btn.Text = ""
btn.BackgroundColor3 = Color3.new(1, 1, 1)
btn.Parent = dock or gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 22)
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Parent = btn
local rim = Instance.new("UIStroke")
rim.Thickness = 4
rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rim.Parent = btn
local gloss = Instance.new("Frame")
gloss.BackgroundColor3 = Color3.new(1, 1, 1)
gloss.BackgroundTransparency = 0.75
gloss.BorderSizePixel = 0
gloss.Position = UDim2.fromScale(0.1, 0.06)
gloss.Size = UDim2.fromScale(0.8, 0.3)
gloss.Parent = btn
Instance.new("UICorner", gloss).CornerRadius = UDim.new(0, 10)

local icon = Instance.new("ImageLabel")
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0.5, 0)
icon.Position = UDim2.new(0.5, 0, 0, 3)
icon.Size = UDim2.fromOffset(48, 48)
icon.ScaleType = Enum.ScaleType.Fit
icon.Parent = btn
local fallback = Instance.new("TextLabel") -- если у мира нет скина: молния текстом
fallback.BackgroundTransparency = 1
fallback.Size = UDim2.fromScale(1, 1)
fallback.Text = "⚡"
fallback.TextScaled = true
fallback.Font = Enum.Font.GothamBold
fallback.TextColor3 = Color3.fromRGB(255, 225, 80)
fallback.Parent = icon

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -3)
label.Size = UDim2.new(1, -8, 0, 19)
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.Text = "TRAILS"
label.Parent = btn
local ls = Instance.new("UIStroke")
ls.Thickness = 2
ls.Parent = label

-- счётчик жетонов — кружок в правом верхнем углу, как красная точка у «≡»
local badge = Instance.new("TextLabel")
badge.AnchorPoint = Vector2.new(0.5, 0.5)
badge.Position = UDim2.new(1, -6, 0, 6)
badge.Size = UDim2.fromOffset(34, 34)
badge.BackgroundTransparency = 0
badge.BackgroundColor3 = Color3.fromRGB(255, 150, 20)
badge.Font = Enum.Font.FredokaOne
badge.TextScaled = true
badge.TextColor3 = Color3.new(1, 1, 1)
badge.ZIndex = 3
badge.Parent = btn
Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
local bs = Instance.new("UIStroke")
bs.Thickness = 2.5
bs.Color = Color3.new(1, 1, 1)
bs.Parent = badge
local bp = Instance.new("UIPadding")
bp.PaddingTop, bp.PaddingBottom = UDim.new(0.16, 0), UDim.new(0.16, 0)
bp.PaddingLeft, bp.PaddingRight = UDim.new(0.1, 0), UDim.new(0.1, 0)
bp.Parent = badge

local scale = Instance.new("UIScale")
scale.Parent = btn

local function theme()
	local skin = Skins[player:GetAttribute("CurrentWorld") or ""]
	grad.Color = ColorSequence.new(skin and skin.MenuTop or Color3.fromRGB(90, 110, 140), skin and skin.MenuBottom or Color3.fromRGB(45, 60, 85))
	rim.Color = skin and skin.RimColor or Color3.fromRGB(30, 30, 40)
	label.TextColor3 = skin and skin.TitleColor or Color3.new(1, 1, 1)
	ls.Color = skin and skin.InkColor or Color3.fromRGB(30, 30, 40)
	icon.Image = skin and skin.Icon_Speed or ""
	icon.ImageColor3 = skin and skin.Tint or Color3.new(1, 1, 1)
	fallback.Visible = not (skin and skin.Icon_Speed)
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(theme)
theme()

local function refresh()
	local n = player:GetAttribute("SpeedTokens") or 0
	badge.Text = tostring(n)
	badge.Visible = n > 0
end
player:GetAttributeChangedSignal("SpeedTokens"):Connect(function()
	refresh()
	scale.Scale = 1.2
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)
refresh()

btn.MouseEnter:Connect(function()
	TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.08 }):Play()
end)
btn.MouseLeave:Connect(function()
	TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
end)
btn.Activated:Connect(function()
	scale.Scale = 0.9
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	open:Fire()
end)
-- пока открыто другое окно (магазин, яйцо, меню) — кнопку прячем
local function onScreen()
	local s = player:GetAttribute("UIScreen")
	btn.Visible = s == nil or s == ""
end
player:GetAttributeChangedSignal("UIScreen"):Connect(onScreen)
onScreen()
