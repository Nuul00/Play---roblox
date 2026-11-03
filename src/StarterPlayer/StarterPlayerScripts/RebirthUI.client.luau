-- Окно REBIRTH: прогресс к цене, что теряется / что сохраняется, бонус монет. Сервер всё проверяет (Rebirth.server).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local Config = require(RS:WaitForChild("GameConfig"))
local remote = RS:WaitForChild("GameRebirth")
local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local rgb = Color3.fromRGB
local ink = rgb(45, 25, 80)

local gui = Instance.new("ScreenGui")
gui.Name = "RebirthUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 41
gui.Parent = player:WaitForChild("PlayerGui")

local function round(f, r)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, r)
end
local function stroke(f, c, w)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = w
	s.Parent = f
	return s
end
local function frame(parent, x, y, w, h, c, r)
	local f = Instance.new("Frame")
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = c
	f.BorderSizePixel = 0
	f.Parent = parent
	round(f, r or 14)
	return f
end
local function text(parent, s, x, y, w, h, size, c, xAlign)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.Text = s
	l.TextWrapped = true
	l.TextSize = size
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = c or Color3.new(1, 1, 1)
	l.TextXAlignment = xAlign or Enum.TextXAlignment.Center
	l.Parent = parent
	local st = stroke(l, ink, 2)
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	return l
end
local function grad(f, a, b)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = 90
	g.Parent = f
	return g
end
local function fmt(n)
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			local v = n / u[1]
			return (string.format(v >= 100 and "%.0f" or "%.1f", v):gsub("%.0$", "")) .. u[2]
		end
	end
	return string.format("%d", n)
end

local panel = frame(gui, 0, 0, 700, 430, rgb(255, 140, 70), 26)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Visible = false
stroke(panel, ink, 5)
grad(panel, rgb(120, 85, 215), rgb(55, 30, 125))
local scale = Instance.new("UIScale", panel)

local head = frame(panel, 150, -28, 400, 64, rgb(255, 190, 70), 18)
stroke(head, ink, 4)
grad(head, rgb(255, 225, 110), rgb(240, 150, 40))
text(head, "🔄 REBIRTH", 0, 5, 400, 54, 34)

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(642, 12)
close.Size = UDim2.fromOffset(44, 44)
close.Text = "×"
close.Font = Enum.Font.FredokaOne
close.TextSize = 32
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = rgb(235, 70, 80)
close.Modal = true
close.Parent = panel
round(close, 12)
stroke(close, ink, 3)
close.Activated:Connect(function()
	player:SetAttribute("UIScreen", "")
end)

-- Блок «сейчас -> после».
local statBox = frame(panel, 24, 56, 652, 86, rgb(70, 45, 150), 18)
stroke(statBox, ink, 3)
local countLabel = text(statBox, "", 10, 8, 200, 34, 22, rgb(255, 235, 150))
local countSub = text(statBox, "REBIRTHS", 10, 42, 200, 26, 15, rgb(215, 200, 255))
local arrow = text(statBox, "COIN BONUS", 230, 8, 410, 26, 16, rgb(215, 200, 255))
local bonusLabel = text(statBox, "", 230, 32, 410, 44, 30, rgb(140, 255, 150))

-- Прогресс монет.
local barBack = frame(panel, 24, 154, 652, 40, rgb(30, 18, 70), 20)
stroke(barBack, ink, 3)
local barFill = frame(barBack, 0, 0, 10, 40, rgb(110, 225, 120), 20)
grad(barFill, rgb(170, 255, 150), rgb(70, 190, 90))
local barText = text(barBack, "", 0, 4, 652, 32, 20)
barText.ZIndex = 3

-- Что теряется / что остаётся.
local function column(x, title, color, lines)
	local f = frame(panel, x, 208, 318, 138, color, 16)
	stroke(f, ink, 3)
	text(f, title, 0, 6, 318, 28, 20)
	for i, line in ipairs(lines) do
		text(f, line, 14, 32 + (i - 1) * 20, 296, 20, 15, rgb(255, 255, 255), Enum.TextXAlignment.Left)
	end
end
column(24, "YOU LOSE", rgb(165, 60, 90), { "💰 All coins", "⚡ Speed level (back to level 6)", "🧲 Magnet radius upgrade", "💰 Coin income upgrade", "✨ Double coin upgrade" })
column(358, "YOU KEEP", rgb(50, 140, 90), { "🐾 Pets, eggs and pet index", "🧲 Magnets you bought", "🧪 Potions and achievements", "🌍 Access to all worlds", "⭐ Permanent coin bonus!" })

local button = Instance.new("TextButton")
button.Position = UDim2.fromOffset(190, 358)
button.Size = UDim2.fromOffset(320, 58)
button.Font = Enum.Font.FredokaOne
button.TextSize = 28
button.TextColor3 = Color3.new(1, 1, 1)
button.AutoButtonColor = false
button.Parent = panel
round(button, 16)
stroke(button, ink, 4)
local btnGrad = grad(button, rgb(150, 150, 160), rgb(100, 100, 115))
local btnScale = Instance.new("UIScale", button)

local confirmUntil = 0
local function state()
	local r = player:GetAttribute("Rebirths") or 0
	local maxed = r >= Config.MaxRebirths
	local cost = maxed and 0 or Config.GetRebirthCost(r)
	return r, maxed, cost, (not maxed) and coins.Value >= cost
end
local function refresh()
	local r, maxed, cost, ready = state()
	countLabel.Text = tostring(r) .. " / " .. Config.MaxRebirths
	if maxed then
		bonusLabel.Text = "x" .. string.format("%g", Config.GetRebirthBonus(r)) .. "  MAX"
		barFill.Size = UDim2.fromOffset(652, 40)
		barText.Text = "ALL REBIRTHS DONE"
	else
		bonusLabel.Text = "x" .. string.format("%g", Config.GetRebirthBonus(r)) .. "  →  x" .. string.format("%g", Config.GetRebirthBonus(r + 1))
		barFill.Size = UDim2.fromOffset(math.max(20, 652 * math.clamp(coins.Value / cost, 0, 1)), 40)
		barText.Text = "💰 " .. fmt(coins.Value) .. " / " .. fmt(cost)
	end
	if maxed then
		button.Text = "MAXED"
		btnGrad.Color = ColorSequence.new(rgb(150, 150, 160), rgb(100, 100, 115))
	elseif not ready then
		button.Text = "NEED " .. fmt(cost - coins.Value) .. " MORE"
		btnGrad.Color = ColorSequence.new(rgb(150, 150, 160), rgb(100, 100, 115))
	elseif os.clock() < confirmUntil then
		button.Text = "TAP AGAIN TO CONFIRM"
		btnGrad.Color = ColorSequence.new(rgb(255, 150, 120), rgb(225, 70, 60))
	else
		button.Text = "REBIRTH!"
		btnGrad.Color = ColorSequence.new(rgb(170, 255, 140), rgb(60, 190, 80))
	end
end
button.Activated:Connect(function()
	local _, maxed, _, ready = state()
	if maxed or not ready then
		return
	end
	if os.clock() < confirmUntil then
		confirmUntil = 0
		remote:FireServer()
	else
		confirmUntil = os.clock() + 2.5
	end
	refresh()
end)

-- Праздничная плашка после ребёрса.
local celebrate = Instance.new("TextLabel")
celebrate.AnchorPoint = Vector2.new(0.5, 0.5)
celebrate.Position = UDim2.fromScale(0.5, 0.35)
celebrate.Size = UDim2.fromOffset(640, 110)
celebrate.BackgroundTransparency = 1
celebrate.Font = Enum.Font.FredokaOne
celebrate.TextSize = 54
celebrate.TextColor3 = rgb(255, 230, 110)
celebrate.TextTransparency = 1
celebrate.Parent = gui
local celebrateScale = Instance.new("UIScale", celebrate)
local celebrateStroke = stroke(celebrate, ink, 4)
celebrateStroke.Transparency = 1
local lastRebirths = player:GetAttribute("Rebirths") or 0
player:GetAttributeChangedSignal("Rebirths"):Connect(function()
	local r = player:GetAttribute("Rebirths") or 0
	if r > lastRebirths and player:GetAttribute("ProfileReady") then
		celebrate.Text = "🔄 REBIRTH " .. r .. "!\nCOINS x" .. string.format("%g", Config.GetRebirthBonus(r))
		celebrate.TextTransparency = 0
		celebrateStroke.Transparency = 0
		celebrateScale.Scale = 0.4
		Tween:Create(celebrateScale, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		task.delay(2.2, function()
			Tween:Create(celebrate, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
			Tween:Create(celebrateStroke, TweenInfo.new(0.8), { Transparency = 1 }):Play()
		end)
		player:SetAttribute("UIScreen", "")
	end
	lastRebirths = r
	refresh()
end)
coins.Changed:Connect(refresh)

local function update()
	local open = player:GetAttribute("UIScreen") == "rebirth"
	panel.Visible = open
	if open then
		confirmUntil = 0
		refresh()
	end
end
player:GetAttributeChangedSignal("UIScreen"):Connect(update)
update()

local t = 0
Run.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		local size = camera.ViewportSize
		scale.Scale = math.min(1, (size.X - 28) / 700, (size.Y - 70) / 440)
	end
	if panel.Visible then
		t += dt
		local _, _, _, ready = state()
		btnScale.Scale = ready and 1 + 0.03 * math.sin(t * 5) or 1
		if os.clock() > confirmUntil and button.Text == "TAP AGAIN TO CONFIRM" then
			refresh()
		end
	end
end)
