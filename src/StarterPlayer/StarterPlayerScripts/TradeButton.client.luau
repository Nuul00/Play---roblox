-- Кнопка TRADE справа от «≡»: торговля питомцами пока в разработке («coming soon»).
-- Картинка в стиле текущего мира (assets/trade/Btn_Trade_<мир>.png).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ICONS = {
	["Meadow Isles"] = "rbxassetid://109323098573748",
	["Neon District"] = "rbxassetid://124876590779860",
	["Sky Isles"] = "rbxassetid://130544433077527",
	["Frozen Peaks"] = "rbxassetid://139525662883277",
	["Magma Volcano"] = "rbxassetid://137040842294882",
	["Cosmic Galaxy"] = "rbxassetid://113056388217809",
}

local menu = playerGui:WaitForChild("MenuHUD", 30)
local dock = menu and menu:WaitForChild("Dock", 30)
if not dock then
	return
end
local SIZE = 86 -- у картинки прозрачные поля, поэтому чуть больше соседних кнопок
local btn = Instance.new("ImageButton")
btn.Name = "TradeButton"
btn.AnchorPoint = Vector2.new(0, 1)
btn.Position = UDim2.new(0.5, 38 + 14 + 12, 1, 0) -- зеркально кнопке STORE
btn.Size = UDim2.fromOffset(SIZE, SIZE)
btn.BackgroundTransparency = 1
btn.Image = ICONS["Meadow Isles"]
btn.ScaleType = Enum.ScaleType.Fit
btn.Parent = dock
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
	btn.Image = ICONS[player:GetAttribute("CurrentWorld") or ""] or ICONS["Meadow Isles"]
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
