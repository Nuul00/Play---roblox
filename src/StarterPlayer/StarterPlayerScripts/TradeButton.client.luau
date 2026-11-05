-- Кнопка TRADE справа от «≡»: торговля питомцами пока в разработке («coming soon»).
-- Оформление как у TRAILS: цвета HUD-скина текущего мира, ленточка SOON.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Skins = require(game:GetService("ReplicatedStorage"):WaitForChild("HudSkins"))

local menu = playerGui:WaitForChild("MenuHUD", 30)
local dock = menu and menu:WaitForChild("Dock", 30)
if not dock then
	return
end
-- Такая же кнопка, как TRAILS/«≡»/STORE: квадрат 76 со скруглением в цветах HUD-скина мира.
local SIZE = 76
local btn = Instance.new("TextButton")
btn.Name = "TradeButton"
btn.AnchorPoint = Vector2.new(0, 1)
btn.Position = UDim2.new(0.5, 38 + 14 + 12, 1, 0) -- зеркально кнопке STORE
btn.Size = UDim2.fromOffset(SIZE, SIZE)
btn.AutoButtonColor = false
btn.Text = ""
btn.BackgroundColor3 = Color3.new(1, 1, 1)
btn.Parent = dock
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

local icon = Instance.new("TextLabel")
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0.5, 0)
icon.Position = UDim2.new(0.5, 0, 0, 4)
icon.Size = UDim2.fromOffset(46, 46)
icon.Text = "🤝"
icon.TextScaled = true
icon.Parent = btn

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -3)
label.Size = UDim2.new(1, -8, 0, 19)
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.Text = "TRADE"
label.Parent = btn
local ls = Instance.new("UIStroke")
ls.Thickness = 2
ls.Parent = label

-- ленточка «SOON» в правом верхнем углу (как бейдж у соседних кнопок)
local soon = Instance.new("TextLabel")
soon.AnchorPoint = Vector2.new(0.5, 0.5)
soon.Position = UDim2.new(1, -8, 0, 6)
soon.Size = UDim2.fromOffset(50, 20)
soon.Rotation = 18
soon.BackgroundColor3 = Color3.fromRGB(235, 50, 80)
soon.Font = Enum.Font.FredokaOne
soon.TextScaled = true
soon.Text = "SOON"
soon.TextColor3 = Color3.new(1, 1, 1)
soon.ZIndex = 3
soon.Parent = btn
Instance.new("UICorner", soon).CornerRadius = UDim.new(0, 8)
local ss = Instance.new("UIStroke")
ss.Thickness = 2
ss.Color = Color3.new(1, 1, 1)
ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ss.Parent = soon
local sp = Instance.new("UIPadding")
sp.PaddingTop, sp.PaddingBottom = UDim.new(0, 2), UDim.new(0, 2)
sp.Parent = soon

local scale = Instance.new("UIScale")
scale.Parent = btn

-- всплывающая подсказка
local tip = Instance.new("TextLabel")
tip.AnchorPoint = Vector2.new(0.5, 1)
tip.Position = UDim2.new(0.5, 0, 0, -8)
tip.Size = UDim2.fromOffset(230, 44)
tip.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
tip.TextColor3 = Color3.new(1, 1, 1)
tip.Font = Enum.Font.FredokaOne
tip.TextScaled = true
tip.Text = "🤝 Pet trading is coming soon!"
tip.Visible = false
tip.Parent = btn
Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 12)
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
pad.Parent = tip
local st = Instance.new("UIStroke")
st.Color = Color3.fromRGB(255, 220, 120)
st.Thickness = 3
st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
st.Parent = tip

local function refresh()
	local skin = Skins[player:GetAttribute("CurrentWorld") or ""]
	grad.Color = ColorSequence.new(skin and skin.MenuTop or Color3.fromRGB(90, 110, 140), skin and skin.MenuBottom or Color3.fromRGB(45, 60, 85))
	rim.Color = skin and skin.RimColor or Color3.fromRGB(30, 30, 40)
	label.TextColor3 = skin and skin.TitleColor or Color3.new(1, 1, 1)
	ls.Color = skin and skin.InkColor or Color3.fromRGB(30, 30, 40)
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(refresh)
refresh()
-- как и STORE, прячется, пока открыто любое окно
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	local s = player:GetAttribute("UIScreen")
	btn.Visible = s == nil or s == ""
end)

local token = 0
btn.Activated:Connect(function()
	token += 1
	local my = token
	tip.Visible = true
	scale.Scale = 0.85
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.5, function()
		if token == my then
			tip.Visible = false
		end
	end)
end)
btn.MouseEnter:Connect(function()
	TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.08 }):Play()
end)
btn.MouseLeave:Connect(function()
	TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
end)
