-- Кнопка TRADE справа от «≡»: торговля питомцами пока в разработке («coming soon»).
-- Оформление как у TRAILS: цвета HUD-скина текущего мира, ленточка SOON.
-- Пока торговли нет, кнопку не показываем (заглушка «SOON» в главной панели путала игроков).
-- Когда трейд будет готов — поставить TRADE_ENABLED = true.
local TRADE_ENABLED = false
if not TRADE_ENABLED then
	return
end
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

-- 3D-иконка: два питомца текущего мира меняются местами по кругу (ViewportFrame).
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))
local PetVisuals = require(game:GetService("ReplicatedStorage"):WaitForChild("PetVisuals"))
local RunService = game:GetService("RunService")
local WORLD_KEY = { ["Meadow Isles"] = "island", ["Neon District"] = "neon", ["Sky Isles"] = "sky", ["Frozen Peaks"] = "frozen", ["Magma Volcano"] = "volcano", ["Cosmic Galaxy"] = "galaxy" }

local view = Instance.new("ViewportFrame")
view.BackgroundTransparency = 1
view.AnchorPoint = Vector2.new(0.5, 0)
view.Position = UDim2.new(0.5, 0, 0, 0)
view.Size = UDim2.fromOffset(76, 56)
view.Ambient = Color3.fromRGB(210, 210, 220)
view.LightColor = Color3.new(1, 1, 1)
view.LightDirection = Vector3.new(-1, -1.5, -2)
view.Parent = btn
local vworld = Instance.new("WorldModel")
vworld.Parent = view
local vcam = Instance.new("Camera")
vcam.FieldOfView = 34
vcam.Parent = view
view.CurrentCamera = vcam
local fallbackIcon = Instance.new("TextLabel") -- если модели не собрались
fallbackIcon.BackgroundTransparency = 1
fallbackIcon.Size = UDim2.fromScale(1, 1)
fallbackIcon.Text = "🤝"
fallbackIcon.TextScaled = true
fallbackIcon.Visible = false
fallbackIcon.Parent = view

local pets = {} -- { model, size }
local function petsFor(worldName)
	local key = WORLD_KEY[worldName or ""] or "island"
	local first
	for id = 1, 30 do
		local e = Config.Eggs[id]
		if e and e.World == key then first = e break end
	end
	if not first then return { 1, 6 } end
	local pool = first.Pool
	return { pool[1].Pet, pool[math.max(1, #pool - 2)].Pet }
end
local function buildPets(worldName)
	vworld:ClearAllChildren()
	table.clear(pets)
	for _, id in petsFor(worldName) do
		local ok, model = pcall(PetVisuals.Build, id)
		if ok and model then
			for _, d in model:GetDescendants() do
				if d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("BillboardGui") then d:Destroy() end
			end
			local _, size = model:GetBoundingBox()
			local k = 2.4 / math.max(size.X, size.Y, size.Z, 0.1)
			pcall(function() model:ScaleTo(model:GetScale() * k) end)
			model.Parent = vworld
			table.insert(pets, model)
		end
	end
	fallbackIcon.Visible = #pets == 0
	vcam.CFrame = CFrame.lookAt(Vector3.new(0, 1.3, -5.6), Vector3.new(0, 0.2, 0))
end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	if #pets == 0 or not btn.Visible then return end
	t += dt
	-- питомцы ходят по кругу друг напротив друга: один уходит назад, другой выходит вперёд
	for i, m in pets do
		local a = t * 1.1 + (i - 1) * math.pi
		local pos = Vector3.new(math.cos(a) * 1.55, 0.1 * math.sin(t * 6 + i), math.sin(a) * 1.1)
		m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.cos(a) > 0 and 0.5 or -0.5, 0))
	end
end)

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
	buildPets(player:GetAttribute("CurrentWorld"))
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
