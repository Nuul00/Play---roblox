-- Coin Combo HUD: справа по центру счётчик комбо (растёт с каждой монетой, «прыгает»), ступень
-- и её множитель, полоска времени до сгорания, щелчок с растущим тоном. Новая ступень — крупная
-- вспышка по центру; сгорело большое комбо — «COMBO LOST» и рекорд. Числа считает сервер
-- (атрибут Combo, Save_BestCombo), клиент только показывает.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ComboConfig = require(ReplicatedStorage:WaitForChild("ComboConfig"))
local UISounds = require(ReplicatedStorage:WaitForChild("UISounds"))
local player = Players.LocalPlayer

local SHOW_FROM = 3
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(35, 18, 55)

local gui = Instance.new("ScreenGui")
gui.Name = "ComboHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, text, size, pos, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Text = text
	l.TextScaled = true
	l.Font = font or Enum.Font.FredokaOne
	l.TextColor3 = color or WHITE
	l.Parent = parent
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = DARK
	st.Parent = l
	return l, st
end

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(1, 0.5)
box.Position = UDim2.new(1, -20, 0.55, 0)
box.Size = UDim2.fromOffset(200, 120)
box.BackgroundTransparency = 1
box.Visible = false
box.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = box
local title = label(box, "COMBO", UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 0), Color3.fromRGB(255, 235, 170))
title.TextXAlignment = Enum.TextXAlignment.Right
local num, numStroke = label(box, "x0", UDim2.new(1, 0, 0, 56), UDim2.fromOffset(0, 18))
num.TextXAlignment = Enum.TextXAlignment.Right
numStroke.Thickness = 4
local numScale = Instance.new("UIScale")
numScale.Parent = num
local sub = label(box, "", UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 74), WHITE)
sub.TextXAlignment = Enum.TextXAlignment.Right
local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(1, 0)
barBack.Position = UDim2.new(1, 0, 0, 100)
barBack.Size = UDim2.new(0.8, 0, 0, 8)
barBack.BackgroundColor3 = DARK
barBack.BackgroundTransparency = 0.3
barBack.Parent = box
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(1, 0)
bar.Position = UDim2.fromScale(1, 0)
bar.Size = UDim2.fromScale(1, 1)
bar.BackgroundColor3 = WHITE
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

-- крупная вспышка новой ступени по центру экрана
local flash = label(gui, "", UDim2.fromOffset(520, 70), UDim2.new(0.5, 0, 0.32, 0))
flash.AnchorPoint = Vector2.new(0.5, 0.5)
flash.Visible = false
local flashScale = Instance.new("UIScale")
flashScale.Parent = flash

local tick = Instance.new("Sound")
tick.Name = "ComboTick"
tick.SoundId = "rbxasset://sounds/electronicpingshort.wav"
tick.Volume = 0.16
tick.Parent = SoundService

local function tierColor(t: number): Color3
	return t > 0 and ComboConfig.Tiers[t].Color or WHITE
end

local lastCombo, lastTier, lastAt, lastTick = 0, 0, 0, 0
local function showFlash(text: string, color: Color3)
	flash.Text = text
	flash.TextColor3 = color
	flash.TextTransparency = 0
	flash.Visible = true
	flashScale.Scale = 0.4
	TweenService:Create(flashScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(1.1, function()
		if flash.Text == text then
			TweenService:Create(flash, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		end
	end)
end

local function update()
	local combo = player:GetAttribute("Combo") or 0
	if combo > lastCombo then
		lastAt = os.clock()
		local t = ComboConfig.TierOf(combo)
		if combo >= SHOW_FROM then
			box.Visible = true
			num.Text = "x" .. combo
			local col = tierColor(t)
			num.TextColor3 = col
			bar.BackgroundColor3 = col
			local mult = ComboConfig.MultOf(combo)
			if t > 0 then
				sub.Text = ComboConfig.Tiers[t].Name .. " · ×" .. mult .. " coins"
			else
				sub.Text = "next ×" .. ComboConfig.Tiers[1].Mult .. " at " .. ComboConfig.Tiers[1].At
			end
			numScale.Scale = 1.3
			TweenService:Create(numScale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			if os.clock() - lastTick > 0.05 then
				lastTick = os.clock()
				tick.PlaybackSpeed = 0.9 + math.min(combo, 80) * 0.0125
				SoundService:PlayLocalSound(tick)
			end
		end
		if t > lastTier then
			local tier = ComboConfig.Tiers[t]
			showFlash(tier.Name .. "!  ×" .. tier.Mult .. " COINS", tier.Color)
			UISounds.Play("reward")
		end
		lastTier = t
	elseif combo == 0 and lastCombo > 0 then
		if lastCombo >= ComboConfig.Tiers[1].At then
			local best = player:GetAttribute("Save_BestCombo") or lastCombo
			showFlash("COMBO x" .. lastCombo .. (lastCombo >= best and "  NEW RECORD!" or "  ·  best x" .. best), lastCombo >= best and Color3.fromRGB(255, 215, 90) or Color3.fromRGB(255, 140, 140))
		end
		box.Visible = false
		lastTier = 0
	end
	lastCombo = combo
end
player:GetAttributeChangedSignal("Combo"):Connect(update)

RunService.RenderStepped:Connect(function()
	if box.Visible then
		local k = math.clamp(1 - (os.clock() - lastAt) / ComboConfig.Window, 0, 1)
		bar.Size = UDim2.fromScale(k, 1)
		scale.Scale = k < 0.3 and (1 + 0.04 * math.sin(os.clock() * 30)) or 1 -- дрожит перед сгоранием
	end
end)
