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

local gui = Instance.new("ScreenGui")
gui.Name = "TrailsButtonHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Name = "Trails"
btn.AnchorPoint = Vector2.new(1, 0)
btn.Position = UDim2.new(1, -14, 0, 118)
btn.Size = UDim2.fromOffset(150, 40)
btn.AutoButtonColor = false
btn.Text = ""
btn.BackgroundColor3 = Color3.new(1, 1, 1)
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Color3.fromRGB(255, 205, 70), Color3.fromRGB(240, 140, 30))
grad.Rotation = 90
grad.Parent = btn
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(30, 30, 40)
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
ls.Color = Color3.fromRGB(90, 45, 10)
ls.Parent = label
local scale = Instance.new("UIScale")
scale.Parent = btn

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
