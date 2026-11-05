-- Основной HUD: отдельные панели слева (монеты, скорость, бонус питомца, магнит).
-- Только отображение: значения приходят из leaderstats и атрибутов, которые ставит сервер.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local stats = player:WaitForChild("leaderstats")
local coins = stats:WaitForChild("Coins")
local speedLevel = stats:WaitForChild("SpeedLevel")

local gui = Instance.new("ScreenGui")
gui.Name = "MainHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local column = Instance.new("Frame")
column.Name = "Panels"
column.BackgroundTransparency = 1
column.AnchorPoint = Vector2.new(0, 1)
column.Position = UDim2.new(0, 14, 1, -14)
column.Size = UDim2.fromOffset(230, 340)
column.Parent = gui
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 16) -- круглые иконки выступают за плитку: место, чтобы не касались
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = column
local uiScale = Instance.new("UIScale")
uiScale.Parent = column

local function abbreviate(n: number): string
	local units = { { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			return string.format("%.2f", n / u[1]):gsub("%.?0+$", "") .. u[2]
		end
	end
	return string.format("%g", math.floor(n * 10 + 0.5) / 10)
end

local function panel(order: number, height: number, top: Color3, bottom: Color3, iconColor: Color3, iconText: string)
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Parent = column
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = 90
	gradient.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(30, 30, 40)
	stroke.Transparency = 0.15
	stroke.Parent = frame

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromOffset(height - 12, height - 12)
	icon.Position = UDim2.fromOffset(6, 6)
	icon.BackgroundColor3 = iconColor
	icon.Text = iconText
	icon.Font = Enum.Font.FredokaOne
	icon.TextScaled = true
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = frame
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Thickness = 2.5
	iconStroke.Color = Color3.fromRGB(30, 30, 40)
	iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	iconStroke.Parent = icon
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = icon

	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Position = UDim2.fromOffset(height + 2, 0)
	value.Size = UDim2.new(1, -height - 10, 1, 0)
	value.Font = Enum.Font.FredokaOne
	value.TextScaled = true
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextColor3 = Color3.new(1, 1, 1)
	value.Parent = frame
	local valuePad = Instance.new("UIPadding")
	valuePad.PaddingTop = UDim.new(0.2, 0)
	valuePad.PaddingBottom = UDim.new(0.2, 0)
	valuePad.Parent = value
	local valueStroke = Instance.new("UIStroke")
	valueStroke.Thickness = 2.5
	valueStroke.Color = Color3.fromRGB(30, 30, 40)
	valueStroke.Parent = value
	return frame, value
end

local coinFrame, coinText = panel(1, 64, Color3.fromRGB(255, 214, 72), Color3.fromRGB(240, 150, 20), Color3.fromRGB(255, 190, 30), "$")
local _, speedText = panel(2, 48, Color3.fromRGB(110, 200, 255), Color3.fromRGB(45, 120, 230), Color3.fromRGB(60, 150, 255), "»")
local _, petText = panel(3, 48, Color3.fromRGB(255, 150, 200), Color3.fromRGB(215, 80, 160), Color3.fromRGB(240, 100, 180), "×")
local _, magnetText = panel(4, 48, Color3.fromRGB(190, 140, 255), Color3.fromRGB(120, 70, 220), Color3.fromRGB(150, 90, 255), "◎")

-- Монеты считаются «прокруткой» к новому значению, а прибавка всплывает над панелью.
local shown = coins.Value
local target = coins.Value
local function popGain(amount: number)
	local pop = Instance.new("TextLabel")
	pop.BackgroundTransparency = 1
	pop.Text = "+" .. abbreviate(amount)
	pop.Font = Enum.Font.FredokaOne
	pop.TextSize = 26
	pop.TextColor3 = Color3.fromRGB(255, 235, 120)
	pop.Position = UDim2.new(1, 8, 0, 6)
	pop.Size = UDim2.fromOffset(100, 30)
	pop.TextXAlignment = Enum.TextXAlignment.Left
	pop.Parent = coinFrame
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Color = Color3.fromRGB(60, 40, 10)
	s.Parent = pop
	local tween = TweenService:Create(pop, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(1, 8, 0, -26), TextTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		pop:Destroy()
	end)
	s.Parent = pop
	TweenService:Create(s, TweenInfo.new(0.9), { Transparency = 1 }):Play()
	local bump = TweenService:Create(coinFrame, TweenInfo.new(0.08), { Size = UDim2.new(1, 8, 0, 70) })
	bump:Play()
	bump.Completed:Connect(function()
		TweenService:Create(coinFrame, TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, 64) }):Play()
	end)
end
coins.Changed:Connect(function(v)
	if v > target then
		popGain(v - target)
	end
	target = v
end)

local function refreshStats()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local walk = humanoid and humanoid.WalkSpeed or Config.GetWalkSpeed(speedLevel.Value)
	speedText.Text = string.format("%d  speed", walk)
	-- Итоговый множитель монет: команда питомцев × доход × достижения × зелье монет.
	local bonus = (player:GetAttribute("PetBonus") or 1) * Config.GetIncomeMultiplier(player:GetAttribute("IncomeLevel") or 0) * (player:GetAttribute("BadgeBonus") or 1) * Config.GetRebirthBonus(player:GetAttribute("Rebirths") or 0)
	bonus *= (player:GetAttribute("IndexBonus") or 1) * (player:GetAttribute("FriendBonus") or 1)
	bonus *= player:GetAttribute("Save_QuestLineBonus") or 1
	if workspace:GetAttribute("EventId") == "Golden" and (workspace:GetAttribute("EventEnd") or 0) > workspace:GetServerTimeNow() then
		bonus *= 2
	end
	if (player:GetAttribute("PotionEndCoins") or 0) > workspace:GetServerTimeNow() then
		bonus *= 2
	end
	bonus *= 1 + (player:GetAttribute("AbilCoins") or 0) -- способность питомцев (как в PlayerSystems.CoinMultiplier)
	petText.Text = "x" .. abbreviate(bonus) .. "  coins"
	magnetText.Text = string.format("%.1f  magnet", player:GetAttribute("MagnetRadius") or Config.GetMagnetRadius(player:GetAttribute("MagnetLevel") or 0))
end
speedLevel.Changed:Connect(refreshStats)
workspace:GetAttributeChangedSignal("EventId"):Connect(refreshStats)
workspace:GetAttributeChangedSignal("EventEnd"):Connect(refreshStats)
-- только атрибуты, влияющие на панель (иначе пересчёт на каждую монету и каждого питомца)
local STAT_ATTRS = { PetBonus = true, IncomeLevel = true, BadgeBonus = true, Rebirths = true, IndexBonus = true, FriendBonus = true, Save_QuestLineBonus = true, PotionEndCoins = true, AbilCoins = true, MagnetRadius = true, MagnetLevel = true, Pass_Coins2x = true, Pass_VIP = true, CurrentWorld = true }
player.AttributeChanged:Connect(function(name)
	if STAT_ATTRS[name] then
		refreshStats()
	end
end)
task.spawn(function() -- зелья и события кончаются по времени
	while true do
		task.wait(2)
		refreshStats()
	end
end)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid"):GetPropertyChangedSignal("WalkSpeed"):Connect(refreshStats)
	refreshStats()
end)
if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
	player.Character:FindFirstChildOfClass("Humanoid"):GetPropertyChangedSignal("WalkSpeed"):Connect(refreshStats)
end
refreshStats()

RunService.RenderStepped:Connect(function(dt)
	shown = shown + (target - shown) * math.min(1, dt * 10)
	if math.abs(target - shown) < 0.05 then
		shown = target
	end
	coinText.Text = abbreviate(shown)
	local camera = workspace.CurrentCamera
	if camera then
		uiScale.Scale = math.clamp(camera.ViewportSize.Y / 720, 0.6, 1.1)
	end
end)
