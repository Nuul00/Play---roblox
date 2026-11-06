-- Окно Royal Egg (яйцо за Robux): вращающееся 3D-яйцо на фоне золотых лучей, 6 питомцев с шансами
-- и силой (доля от главной Secret лучшего открытого мира), кнопки ×1 / ×3. Открывается кнопкой
-- «👑 ROYAL EGG» справа. Где платные случайные предметы запрещены (NoPaidRandom), окна нет.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
local Worlds = require(ReplicatedStorage:WaitForChild("WorldsConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local RoyalEggModel = require(ReplicatedStorage:WaitForChild("RoyalEggModel"))
local player = Players.LocalPlayer

local R = Config.RobuxEgg
local function product(key)
	for _, d in ipairs(StoreConfig.Products) do
		if d.Key == key then
			return d
		end
	end
end
local P1, P3 = product("RoyalEgg1"), product("RoyalEgg3")
if not (R and P1 and P3) then
	return
end
local live = (P1.Id or 0) > 0 or RunService:IsStudio() -- в Studio окно видно и без товаров (для проверки)

local SHORT = { ["Meadow Isles"] = "island", ["Neon District"] = "neon", ["Sky Isles"] = "sky", ["Frozen Peaks"] = "frozen", ["Magma Volcano"] = "volcano", ["Cosmic Galaxy"] = "galaxy" }
local function bestWorld()
	local best, name = "island", "Meadow Isles"
	for _, w in ipairs(Worlds.Worlds) do
		if w.Open and SHORT[w.Id] and ((w.Cost or 0) <= 0 or player:GetAttribute(Worlds.UnlockKey(w.Id))) then
			best, name = SHORT[w.Id], w.Name
		end
	end
	return best, name
end

local RARITY = {
	Common = Color3.fromRGB(190, 195, 210),
	Uncommon = Color3.fromRGB(110, 220, 120),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 190, 50),
	Secret = Color3.fromRGB(255, 90, 160),
}
local GOLD, INK = Color3.fromRGB(255, 205, 70), Color3.fromRGB(45, 20, 60)

local gui = Instance.new("ScreenGui")
gui.Name = "RoyalEggUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 45
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(o, r)
	Instance.new("UICorner", o).CornerRadius = UDim.new(0, r)
end
local function stroke(o, c, t)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = t
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end
local function text(parent, str, pos, size, ts, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = str
	l.TextSize = ts
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = font or Enum.Font.FredokaOne
	l.TextWrapped = true
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = ts >= 18 and 2 or 1.2
	s.Color = INK
	s.Parent = l
	return l
end

-- ===== кнопка на экране =====
local open = Instance.new("TextButton")
open.Name = "RoyalEggButton"
open.AnchorPoint = Vector2.new(0, 0.5)
open.Position = UDim2.new(0, 16, 0.5, -118) -- слева, между квестом и плашками статистики
open.Size = UDim2.fromOffset(118, 58)
open.BackgroundColor3 = GOLD
open.Font = Enum.Font.FredokaOne
open.TextSize = 17
open.TextColor3 = Color3.new(1, 1, 1)
open.Text = "👑 ROYAL\nEGG"
open.Visible = false
open.Parent = gui
corner(open, 16)
stroke(open, Color3.fromRGB(150, 80, 10), 3)
do
	local ts = Instance.new("UIStroke")
	ts.Thickness = 2
	ts.Color = Color3.fromRGB(120, 60, 0)
	ts.Parent = open
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 235, 140), Color3.fromRGB(255, 160, 30))
	g.Rotation = 90
	g.Parent = open
end
local openScale = Instance.new("UIScale", open)

-- ===== окно =====
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(760, 520)
panel.BackgroundColor3 = Color3.fromRGB(70, 30, 110)
panel.Visible = false
panel.ClipsDescendants = true
panel.Parent = gui
corner(panel, 26)
stroke(panel, GOLD, 5)
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(120, 50, 170), Color3.fromRGB(40, 15, 70))
	g.Rotation = 90
	g.Parent = panel
end
local scale = Instance.new("UIScale", panel)

-- вращающиеся лучи за яйцом
local rays = Instance.new("Frame")
rays.BackgroundTransparency = 1
rays.AnchorPoint = Vector2.new(0.5, 0.5)
rays.Position = UDim2.fromOffset(150, 250)
rays.Size = UDim2.fromOffset(520, 520)
rays.Parent = panel
for i = 1, 12 do
	local r = Instance.new("Frame")
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Position = UDim2.fromScale(0.5, 0.5)
	r.Size = UDim2.fromOffset(34, 520)
	r.Rotation = i * 15
	r.BackgroundColor3 = Color3.fromRGB(255, 215, 110)
	r.BackgroundTransparency = 0.86
	r.BorderSizePixel = 0
	r.Parent = rays
end

local title = text(panel, "👑 ROYAL EGG", UDim2.fromOffset(20, 12), UDim2.fromOffset(500, 50), 40, GOLD)
title.TextXAlignment = Enum.TextXAlignment.Left
local sub = text(panel, "", UDim2.fromOffset(22, 60), UDim2.fromOffset(480, 22), 15, Color3.fromRGB(240, 225, 255), Enum.Font.GothamBold)
sub.TextXAlignment = Enum.TextXAlignment.Left
local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -62, 0, 14)
close.Size = UDim2.fromOffset(46, 46)
close.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
close.Text = "×"
close.TextSize = 30
close.Font = Enum.Font.FredokaOne
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = panel
corner(close, 23)
stroke(close, Color3.fromRGB(90, 20, 20), 3)

-- 3D-яйцо
local eggView = Instance.new("ViewportFrame")
eggView.BackgroundTransparency = 1
eggView.Position = UDim2.fromOffset(20, 92)
eggView.Size = UDim2.fromOffset(260, 300)
eggView.Ambient = Color3.fromRGB(255, 240, 225) -- светлее: яйцо освещено со всех сторон
eggView.LightColor = Color3.fromRGB(255, 240, 210)
eggView.LightDirection = Vector3.new(-1, -1, -2)
eggView.Parent = panel
local eggWorld = Instance.new("WorldModel", eggView)
local egg = RoyalEggModel.Build()
egg.Parent = eggWorld
local ecf, esize = egg:GetBoundingBox()
local eggCam = Instance.new("Camera")
eggCam.FieldOfView = 34
local dist = math.max(esize.Y, esize.X) * 2.2
eggCam.CFrame = CFrame.lookAt(ecf.Position + Vector3.new(0, esize.Y * 0.1, -dist), ecf.Position)
eggCam.Parent = eggView
eggView.CurrentCamera = eggCam
local eggBase = egg:GetPivot()
-- в окне яйцо по кругу показывает свои ступени эволюции (1 → 2 → 3), подпись снизу
local stageNames = { "ROYAL EGG", "💎 EVOLVED", "👑 DIVINE" }
local stageText = text(panel, "Evolves up to 2 times while opening — rarer pet!", UDim2.fromOffset(20, 388), UDim2.fromOffset(260, 36), 13, Color3.fromRGB(255, 225, 140), Enum.Font.GothamBold)
local stageTag = text(panel, stageNames[1], UDim2.fromOffset(20, 96), UDim2.fromOffset(260, 26), 18, Color3.fromRGB(255, 230, 150))
local stage, stageAt, eggScale0 = 1, 0, egg:GetScale()
local function showStage(n)
	local m = RoyalEggModel.Build(n)
	local _, sz = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * esize.Y / math.max(sz.Y, 0.1))
	m:PivotTo(eggBase)
	egg:Destroy()
	egg = m
	egg.Parent = eggWorld
	eggScale0 = egg:GetScale()
	stageTag.Text = stageNames[n]
end
local _ = stageText

-- карточки питомцев
local cards = {}
local grid = Instance.new("Frame")
grid.BackgroundTransparency = 1
grid.Position = UDim2.fromOffset(300, 92)
grid.Size = UDim2.fromOffset(444, 300)
grid.Parent = panel
local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(142, 146)
layout.CellPadding = UDim2.fromOffset(9, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid
for t, tier in ipairs(R.Tiers) do
	local c = Instance.new("Frame")
	c.LayoutOrder = t
	c.BackgroundColor3 = Color3.fromRGB(40, 20, 65)
	c.Parent = grid
	corner(c, 14)
	local st = stroke(c, RARITY[tier.Rarity], t >= 5 and 4 or 3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(RARITY[tier.Rarity]:Lerp(Color3.fromRGB(40, 20, 65), 0.55), Color3.fromRGB(30, 15, 50))
	g.Rotation = 90
	g.Parent = c
	local v = Instance.new("ViewportFrame")
	v.BackgroundTransparency = 1
	v.Position = UDim2.fromOffset(4, 16)
	v.Size = UDim2.fromOffset(134, 82)
	v.Ambient = Color3.fromRGB(210, 195, 224)
	v.LightColor = Color3.fromRGB(255, 236, 214)
	v.LightDirection = Vector3.new(-1, -1, -2)
	v.Parent = c
	local cam = Instance.new("Camera")
	cam.FieldOfView = 38
	cam.CFrame = CFrame.lookAt(Vector3.new(3, 1.8, -5.8), Vector3.zero)
	cam.Parent = v
	v.CurrentCamera = cam
	local wm = Instance.new("WorldModel", v)
	local chance = text(c, (tier.Chance >= 1 and string.format("%g%%", tier.Chance) or string.format("%g%%", tier.Chance)), UDim2.fromOffset(70, 2), UDim2.fromOffset(68, 22), 18, RARITY[tier.Rarity])
	chance.TextXAlignment = Enum.TextXAlignment.Right
	local pill = text(c, tier.Rarity:upper(), UDim2.fromOffset(6, 2), UDim2.fromOffset(70, 18), 11, RARITY[tier.Rarity], Enum.Font.GothamBlack)
	pill.TextXAlignment = Enum.TextXAlignment.Left
	local name = text(c, tier.Name, UDim2.fromOffset(4, 96), UDim2.fromOffset(134, 20), 15)
	local power = text(c, "", UDim2.fromOffset(4, 118), UDim2.fromOffset(134, 22), 13, Color3.fromRGB(255, 225, 140), Enum.Font.GothamBold)
	cards[t] = { frame = c, wm = wm, name = name, power = power, stroke = st, id = nil, model = nil }
end
text(panel, "Power = % of the best Secret pet of your best world · Royal pets are not in the Index and can't be fused", UDim2.fromOffset(300, 394), UDim2.fromOffset(444, 30), 11, Color3.fromRGB(210, 195, 235), Enum.Font.Gotham)

-- кнопки покупки
local function buyButton(pos, label, def)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = UDim2.fromOffset(330, 72)
	b.BackgroundColor3 = Color3.fromRGB(80, 200, 90)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 26
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = label
	b.Parent = panel
	corner(b, 18)
	stroke(b, Color3.fromRGB(20, 80, 30), 4)
	local ts = Instance.new("UIStroke")
	ts.Thickness = 2
	ts.Color = Color3.fromRGB(20, 80, 30)
	ts.Parent = b
	local s = Instance.new("UIScale", b)
	b.Activated:Connect(function()
		s.Scale = 0.92
		TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		if (def.Id or 0) > 0 and player:GetAttribute("NoPaidRandom") == false then
			MarketplaceService:PromptProductPurchase(player, def.Id)
		end
	end)
	task.spawn(function()
		if (def.Id or 0) <= 0 then
			return
		end
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, def.Id, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			b.Text = label .. "   R$ " .. info.PriceInRobux
		end
	end)
	return b
end
buyButton(UDim2.fromOffset(40, 432), "OPEN ×1", P1)
local b3 = buyButton(UDim2.fromOffset(390, 432), "OPEN ×3", P3)
b3.BackgroundColor3 = Color3.fromRGB(255, 160, 40)

local shownWorld = nil
local function fill()
	local w, worldName = bestWorld()
	sub.Text = "Pets scale with your best world: " .. worldName
	if shownWorld == w then
		return
	end
	shownWorld = w
	local ids = R.ByWorld[w] or R.ByWorld.island
	local topMult = Config.Pets[ids[#ids]].Multiplier / R.Tiers[#R.Tiers].Pct
	for t, c in ipairs(cards) do
		local id = ids[t]
		c.id = id
		if c.model then
			c.model:Destroy()
		end
		local ok, m = pcall(PetVisuals.Build, id)
		if ok and m then
			m.Parent = c.wm
			c.model = m
		end
		local def = Config.Pets[id]
		c.power.Text = string.format("×%s · %d%%", NumberFormat.Short(def.Multiplier), math.floor(def.Multiplier / topMult * 100 + 0.5))
	end
end

local function show(v)
	if v and player:GetAttribute("NoPaidRandom") ~= false then
		return
	end
	panel.Visible = v
	if v then
		fill()
		player:SetAttribute("UIScreen", "royalegg")
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local base = math.min(1, (vs.X - 30) / 760, (vs.Y - 40) / 520)
		scale.Scale = base * 0.6
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = base }):Play()
	elseif player:GetAttribute("UIScreen") == "royalegg" then
		player:SetAttribute("UIScreen", "")
	end
end
open.Activated:Connect(function()
	local ok, err = pcall(show, not panel.Visible)
	if not ok then
		warn("[RoyalEggUI] open failed: " .. tostring(err))
	end
end)
close.Activated:Connect(function()
	show(false)
end)
-- открыть окно из мира (круг у пьедестала Royal Egg — RoyalEggStandFX)
local openEvent = Instance.new("BindableEvent")
openEvent.Name = "OpenRoyalEgg"
openEvent.Parent = player:WaitForChild("PlayerGui")
openEvent.Event:Connect(function()
	if live and not panel.Visible and (player:GetAttribute("UIScreen") or "") == "" then
		show(true)
	end
end)
local function refreshButton()
	open.Visible = live and player:GetAttribute("NoPaidRandom") == false and (player:GetAttribute("UIScreen") or "") == ""
end
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	if player:GetAttribute("UIScreen") ~= "royalegg" then
		panel.Visible = false
	end
	refreshButton()
end)
player:GetAttributeChangedSignal("NoPaidRandom"):Connect(refreshButton)
refreshButton()

-- анимация: яйцо качается и вращается, лучи крутятся, кнопка «дышит», питомцы поворачиваются
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	if open.Visible then
		openScale.Scale = 1 + 0.05 * math.sin(t * 3)
	end
	if not panel.Visible then
		return
	end
	rays.Rotation = (t * 12) % 360
	-- свет обходит яйцо по кругу — блики бегут по глянцу
	eggView.LightDirection = Vector3.new(math.cos(t * 0.8), -0.6, math.sin(t * 0.8))
	-- смена ступени каждые 3 с: «сжатие → вспышка → новая модель с отскоком»
	if t - stageAt > 3 then
		stageAt = t
		stage = stage % 3 + 1
		showStage(stage)
	end
	local since = t - stageAt
	local pop = since < 0.4 and (1 + math.sin(since / 0.4 * math.pi) * 0.2) or 1
	pcall(function()
		egg:ScaleTo(eggScale0 * pop)
	end)
	egg:PivotTo(eggBase * CFrame.new(0, math.sin(t * 2) * 0.25, 0) * CFrame.Angles(0, t * 0.9, math.sin(t * 1.6) * 0.08))
	for i, c in ipairs(cards) do
		if c.model then
			c.model:PivotTo(CFrame.Angles(0, t * 0.8 + i, 0))
		end
		if i >= 5 then
			c.stroke.Transparency = 0.25 + 0.25 * math.sin(t * 4 + i)
		end
	end
end)
