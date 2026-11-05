-- Окно DAILY REWARDS: 7 карточек, текущий день зелёный с CLAIM!, день 7 золотой с короной.
-- Логика наград: DailyConfig + DailyRewards.server (сервер всё проверяет сам).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local p = Players.LocalPlayer
local D = require(RS:WaitForChild("DailyConfig"))
local remote = RS:WaitForChild("DailyRewardClaim")
local rgb = Color3.fromRGB
local ink = rgb(45, 25, 80)

local gui = Instance.new("ScreenGui")
gui.Name = "DailyRewardsUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.Parent = p:WaitForChild("PlayerGui")

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
local function text(parent, s, x, y, w, h, size, c)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.Text = s
	l.TextWrapped = true
	l.TextSize = size
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = c or Color3.new(1, 1, 1)
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
end

local panel = frame(gui, 0, 0, 860, 400, rgb(90, 55, 175), 26)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Visible = false
stroke(panel, ink, 5)
grad(panel, rgb(140, 100, 245), rgb(60, 35, 135))
local scale = Instance.new("UIScale", panel)

local head = frame(panel, 230, -28, 400, 64, rgb(255, 120, 60), 18)
stroke(head, ink, 4)
grad(head, rgb(255, 190, 90), rgb(240, 100, 50))
text(head, "🎁 DAILY REWARDS", 0, 5, 400, 54, 32)

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(800, 12)
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
	p:SetAttribute("UIScreen", "")
end)
text(panel, "LOG IN EVERY DAY FOR 7 DAYS OF REWARDS!", 20, 50, 820, 26, 17, rgb(230, 215, 255))

local ICONS = { Coins = "💰", Luck = "🍀", Speed = "⚡", Potion = "🧪", Star = "🎁" }
local cells = {}
local CW, GAP = 108, 10
for day, reward in ipairs(D.Rewards) do
	local c = frame(panel, 20 + (day - 1) * (CW + GAP), 92, CW, 190, rgb(220, 232, 255), 16)
	local cs = stroke(c, ink, 3)
	local g = Instance.new("UIGradient", c)
	g.Rotation = 90
	frame(c, 5, 5, CW - 10, 30, rgb(255, 255, 255), 11).BackgroundTransparency = 0.55
	text(c, "DAY " .. day, 0, 6, CW, 28, 18)
	if day == 7 then
		text(c, "👑", 36, -26, 40, 36, 30)
	end
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(0, 40)
	icon.Size = UDim2.fromOffset(CW, 56)
	icon.Text = ICONS[reward.Icon] or "🎁"
	icon.TextSize = 46
	icon.Parent = c
	local nameLabel = text(c, reward.Name, 4, 98, CW - 8, 44, 14)
	local status = text(c, "", 4, 146, CW - 8, 36, 15)
	local tick = text(c, "✓", 0, 38, CW, 60, 54, rgb(120, 255, 120))
	tick.Visible = false
	cells[day] = { frame = c, grad = g, stroke = cs, status = status, icon = icon, tick = tick, name = nameLabel, reward = reward }
end

local note = text(panel, "", 20, 292, 820, 26, 15, rgb(225, 210, 255))
local claim = Instance.new("TextButton")
claim.Position = UDim2.fromOffset(250, 326)
claim.Size = UDim2.fromOffset(360, 56)
claim.Font = Enum.Font.FredokaOne
claim.TextSize = 26
claim.TextColor3 = Color3.new(1, 1, 1)
claim.AutoButtonColor = false
claim.Parent = panel
round(claim, 16)
stroke(claim, ink, 4)
local claimScale = Instance.new("UIScale", claim)
local claimGrad = Instance.new("UIGradient", claim)
claimGrad.Rotation = 90
claim.MouseEnter:Connect(function()
	if claim.Active then
		Tween:Create(claimScale, TweenInfo.new(0.1), { Scale = 1.05 }):Play()
	end
end)
claim.MouseLeave:Connect(function()
	Tween:Create(claimScale, TweenInfo.new(0.1), { Scale = 1 }):Play()
end)

local function shortNum(n)
	for _, u in ipairs({ { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then
			return (string.format("%.2f", n / u[1]):gsub("%.?0+$", "")) .. u[2]
		end
	end
	return tostring(math.floor(n))
end
local busy = false
local function refresh()
	local now = workspace:GetServerTimeNow()
	local day = p:GetAttribute("DailyDay") or 0
	local state = D.State(day, p:GetAttribute("DailyClaimedAt"), now)
	local ready = state.Ready and p:GetAttribute("ProfileReady")
	for i, c in ipairs(cells) do
		-- монеты награды растут вместе с игроком: показываем настоящую сумму
		if c.reward.Coins then
			local amount = D.CoinsFor(c.reward, p:GetAttribute("LifetimeEarned"))
			local extra = c.reward.Potions and "\n+ 3 potions" or ""
			c.name.Text = shortNum(amount) .. " coins" .. extra
		end
		local current = i == state.Day
		-- новая неделя (готов день 1): галочки прошлой недели не показываем
		local shownDay = (state.Ready and state.Day == 1) and 0 or day
		local claimed = i <= shownDay and not (current and state.Ready)
		c.tick.Visible = claimed
		c.icon.TextTransparency = claimed and 0.55 or 0
		if current and state.Ready then
			c.grad.Color = ColorSequence.new(rgb(190, 255, 150), rgb(80, 195, 70))
			c.stroke.Color = rgb(255, 245, 120)
			c.stroke.Thickness = 5
			c.status.Text = "CLAIM!"
		else
			c.stroke.Color = ink
			c.stroke.Thickness = 3
			if i == 7 then
				c.grad.Color = ColorSequence.new(rgb(255, 240, 160), rgb(250, 185, 60))
			elseif claimed then
				c.grad.Color = ColorSequence.new(rgb(185, 195, 215), rgb(140, 150, 175))
			else
				c.grad.Color = ColorSequence.new(rgb(235, 242, 255), rgb(185, 200, 240))
			end
			c.status.Text = claimed and "CLAIMED" or current and "NEXT" or ""
		end
	end
	claim.Text = busy and "CLAIMING..."
		or ready and "CLAIM!"
		or string.format("NEXT IN %02d:%02d:%02d", math.floor(state.Remaining / 3600), math.floor(state.Remaining / 60) % 60, math.floor(state.Remaining) % 60)
	claim.Active = (ready and not busy) and true or false
	claimGrad.Color = claim.Active and ColorSequence.new(rgb(170, 255, 120), rgb(60, 175, 50)) or ColorSequence.new(rgb(175, 170, 195), rgb(120, 115, 145))
	if not busy then
		note.Text = state.Ready and "Your reward is ready! Missing a day won't reset your progress." or "Reward claimed. Your next gift unlocks after 24 hours."
	end
end

claim.Activated:Connect(function()
	local state = D.State(p:GetAttribute("DailyDay"), p:GetAttribute("DailyClaimedAt"), workspace:GetServerTimeNow())
	if busy or not state.Ready or not p:GetAttribute("ProfileReady") then
		return
	end
	busy = true
	refresh()
	local ok, result = pcall(function()
		return remote:InvokeServer()
	end)
	busy = false
	refresh()
	note.Text = ok and result.Message or "Couldn't reach the server. Please try again."
	if ok and result.Ok then
		Tween:Create(claimScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1.15 }):Play()
		task.delay(0.25, function()
			Tween:Create(claimScale, TweenInfo.new(0.2), { Scale = 1 }):Play()
		end)
	end
end)
p:GetAttributeChangedSignal("UIScreen"):Connect(function()
	panel.Visible = p:GetAttribute("UIScreen") == "daily"
	if panel.Visible then
		refresh()
	end
end)
local elapsed = 0
Run.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		local v = camera.ViewportSize
		scale.Scale = math.min(1, (v.X - 26) / 860, (v.Y - 80) / 420)
	end
	elapsed += dt
	if elapsed > 1 then
		elapsed = 0
		if panel.Visible and not busy then
			refresh()
		end
	end
end)
