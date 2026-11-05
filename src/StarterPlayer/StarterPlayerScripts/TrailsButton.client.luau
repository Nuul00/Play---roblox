-- Кнопка магазина трейлов. Раньше она была на панели ежедневных заданий (QuestUI партнёра),
-- панель отключена — теперь кнопка живёт отдельно, под шестерёнкой настроек справа сверху.
-- Показывает ⚡ жетоны (атрибут SpeedTokens, их выдаёт квестовая линия) и открывает TrailShopUI
-- через BindableEvent QuestRemotes.OpenTrailShop (если его не создал QuestUI — создаём сами).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
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

local Skins = require(ReplicatedStorage:WaitForChild("HudSkins"))
-- Кнопка живёт в том же углу, что и шестерёнка настроек (MenuHUD.TopRight из HudSkin):
-- ровно под ней, выровнена по правому краю и масштабируется вместе с ней.
local playerGui = player:WaitForChild("PlayerGui")
local topRight = playerGui:WaitForChild("MenuHUD", 30) and playerGui.MenuHUD:WaitForChild("TopRight", 30)
local gui
if not topRight then
	gui = Instance.new("ScreenGui")
	gui.Name = "TrailsButtonHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 12
	gui.Parent = playerGui
end

local btn = Instance.new("TextButton")
btn.Name = "Trails"
btn.AnchorPoint = Vector2.new(1, 0)
btn.Position = topRight and UDim2.new(1, 0, 1, 10) or UDim2.new(1, -16, 0, 86)
btn.Size = UDim2.fromOffset(128, 38)
btn.AutoButtonColor = false
btn.Text = ""
btn.BackgroundColor3 = Color3.new(1, 1, 1)
btn.Parent = topRight or gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Parent = btn
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = btn
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.new(1, -16, 1, -8)
label.Position = UDim2.fromOffset(8, 4)
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = btn
local ls = Instance.new("UIStroke")
ls.Thickness = 2
ls.Color = Color3.fromRGB(30, 30, 40)
ls.Parent = label
local scale = Instance.new("UIScale")
scale.Parent = btn

-- цвета как у меню «≡» текущего мира
local function theme()
	local skin = Skins[player:GetAttribute("CurrentWorld") or ""]
	grad.Color = ColorSequence.new(skin and skin.MenuTop or Color3.fromRGB(255, 205, 70), skin and skin.MenuBottom or Color3.fromRGB(240, 140, 30))
	stroke.Color = skin and skin.RimColor or Color3.fromRGB(30, 30, 40)
	label.TextColor3 = skin and skin.TitleColor or Color3.new(1, 1, 1)
	ls.Color = skin and skin.InkColor or Color3.fromRGB(30, 30, 40)
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(theme)
theme()
local function refresh()
	label.Text = "✨ TRAILS  ⚡" .. tostring(player:GetAttribute("SpeedTokens") or 0)
end
player:GetAttributeChangedSignal("SpeedTokens"):Connect(function()
	refresh()
	scale.Scale = 1.2
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)
refresh()

btn.MouseEnter:Connect(function()
	TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
end)
btn.MouseLeave:Connect(function()
	TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
end)
btn.Activated:Connect(function()
	open:Fire()
end)
-- пока открыто другое окно (магазин, яйцо, меню) — кнопку прячем
local function onScreen()
	local s = player:GetAttribute("UIScreen")
	btn.Visible = s == nil or s == ""
end
player:GetAttributeChangedSignal("UIScreen"):Connect(onScreen)
onScreen()
