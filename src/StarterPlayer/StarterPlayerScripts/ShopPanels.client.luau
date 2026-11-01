-- Меню прокачки в киоске (скорость, магнит, доход) и магазин магнитов (магниты, прокачка, зелья).
-- Открывает сервер, когда игрок заходит в зелёный круг; закрывается, когда игрок выходит из круга.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local MagnetVisuals = require(ReplicatedStorage:WaitForChild("MagnetVisuals"))
local buy = ReplicatedStorage:WaitForChild("GameShopBuy")
local stats = player:WaitForChild("leaderstats")
local coins = stats:WaitForChild("Coins")
local speed = stats:WaitForChild("SpeedLevel")
local dark = Color3.fromRGB(30, 30, 42)

local gui = Instance.new("ScreenGui")
gui.Name = "ShopPanels"
gui.ResetOnSpawn = false
gui.DisplayOrder = 22
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(p, r)
	Instance.new("UICorner", p).CornerRadius = UDim.new(0, r)
end
local function stroke(p, t, c)
	local s = Instance.new("UIStroke")
	s.Thickness = t
	s.Color = c or dark
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end
local function label(parent, text, pos, size, textSize, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextSize = textSize
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = font or Enum.Font.FredokaOne
	l.TextWrapped = true
	l.Parent = parent
	return l
end
local function button(parent, text, pos, size, color)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.Text = text
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 18
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color
	b.Parent = parent
	corner(b, 12)
	stroke(b, 2.5)
	return b
end
local function fmt(n)
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3):gsub("%.0K", "K")
	end
	return string.format("%g", n)
end

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(1, 0.5)
window.Position = UDim2.new(1, -20, 0.5, 0)
window.Size = UDim2.fromOffset(640, 430)
window.BackgroundColor3 = Color3.fromRGB(36, 44, 66)
window.Visible = false
window.Parent = gui
corner(window, 20)
stroke(window, 4)
local scale = Instance.new("UIScale", window)
local title = label(window, "", UDim2.fromOffset(20, 8), UDim2.fromOffset(420, 44), 28, Color3.fromRGB(255, 230, 150))
title.TextXAlignment = Enum.TextXAlignment.Left
local wallet = label(window, "", UDim2.fromOffset(330, 12), UDim2.fromOffset(240, 36), 20, Color3.fromRGB(255, 215, 80))
wallet.TextXAlignment = Enum.TextXAlignment.Right
local close = button(window, "×", UDim2.new(1, -52, 0, 10), UDim2.fromOffset(40, 40), Color3.fromRGB(220, 70, 70))
close.TextSize = 28
close.Modal = true
local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(14, 60)
body.Size = UDim2.fromOffset(612, 360)
body.Parent = window

local mode, zoneId
local zonePart
local spinning = {}

-- Карточка прокачки: иконка в круге цвета ступени, 10 делений уровня, значения до/после, кнопка.
local upgradeDefs = {
	speed = { Title = "SPEED", Icon = "⚡", Accent = Color3.fromRGB(80, 170, 255), Max = function() return Config.MaxSpeedLevel end,
		Level = function() return speed.Value end, Cost = Config.GetUpgradeCost,
		Value = function(l) return tostring(Config.GetWalkSpeed(l)) end, Unit = "walk speed" },
	magnet = { Title = "MAGNET", Icon = "🧲", Accent = Color3.fromRGB(230, 80, 90), Max = function() return Config.MaxMagnetLevel end,
		Level = function() return player:GetAttribute("MagnetLevel") or 0 end, Cost = Config.GetMagnetUpgradeCost,
		Value = function(l) return string.format("%.1f", Config.GetMagnetRadius(l)) end, Unit = "studs radius" },
	income = { Title = "COINS", Icon = "💰", Accent = Color3.fromRGB(255, 190, 40), Max = function() return Config.MaxIncomeLevel end,
		Level = function() return player:GetAttribute("IncomeLevel") or 0 end, Cost = Config.GetIncomeUpgradeCost,
		Value = function(l) return "x" .. string.format("%g", Config.GetIncomeMultiplier(l)) end, Unit = "coin income" },
}
local function upgradeCard(parent, kind, pos, size)
	local d = upgradeDefs[kind]
	local level, max = d.Level(), d.Max()
	local tier = ShopConfig.TierColor(level, max)
	local card = Instance.new("Frame")
	card.Position = pos
	card.Size = size
	card.BackgroundColor3 = Color3.fromRGB(54, 62, 90)
	card.Parent = parent
	corner(card, 16)
	stroke(card, 3, tier)
	local head = Instance.new("Frame")
	head.Size = UDim2.new(1, 0, 0, 38)
	head.BackgroundColor3 = d.Accent
	head.Parent = card
	corner(head, 16)
	label(head, d.Title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 22)
	-- Иконка растёт и меняет цвет обводки по мере прокачки.
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.new(0.5, 0, 0, 48)
	local iconSize = 70 + math.floor(level / math.max(max, 1) * 16)
	ring.Size = UDim2.fromOffset(iconSize, iconSize)
	ring.BackgroundColor3 = tier
	ring.Parent = card
	corner(ring, iconSize)
	stroke(ring, 3)
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(0.8, 0.8)
	inner.BackgroundColor3 = d.Accent
	inner.Parent = ring
	corner(inner, iconSize)
	label(inner, d.Icon, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), math.floor(iconSize * 0.48))
	label(card, string.format("LEVEL %d / %d", level, max), UDim2.fromOffset(0, 140), UDim2.new(1, 0, 0, 24), 17, tier)
	-- Деления уровня.
	local pips = Instance.new("Frame")
	pips.BackgroundTransparency = 1
	pips.AnchorPoint = Vector2.new(0.5, 0)
	pips.Position = UDim2.new(0.5, 0, 0, 166)
	pips.Size = UDim2.fromOffset(max * 15, 12)
	pips.Parent = card
	for i = 1, max do
		local pip = Instance.new("Frame")
		pip.Position = UDim2.fromOffset((i - 1) * 15, 0)
		pip.Size = UDim2.fromOffset(12, 12)
		pip.BackgroundColor3 = i <= level and ShopConfig.TierColor(i - 1, max) or Color3.fromRGB(35, 38, 52)
		pip.Parent = pips
		corner(pip, 4)
	end
	local nowText = d.Value(level)
	local nextText = level < max and d.Value(level + 1) or nowText
	label(card, level < max and (nowText .. "  →  " .. nextText) or (nowText .. "  MAX"), UDim2.fromOffset(0, 186), UDim2.new(1, 0, 0, 30), 24)
	label(card, d.Unit, UDim2.fromOffset(0, 214), UDim2.new(1, 0, 0, 20), 14, Color3.fromRGB(200, 205, 220), Enum.Font.GothamMedium)
	local price = level < max and d.Cost(level) or 0
	local affordable = coins.Value >= price
	local b = button(card, level >= max and "MAXED" or ("BUY  💰 " .. fmt(price)), UDim2.new(0, 12, 1, -58), UDim2.new(1, -24, 0, 46),
		level >= max and Color3.fromRGB(120, 120, 130) or (affordable and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(150, 80, 80)))
	b.Activated:Connect(function()
		if level < max then
			buy:FireServer(kind, zoneId)
			TweenService:Create(ring, TweenInfo.new(0.12), { Size = UDim2.fromOffset(iconSize + 10, iconSize + 10) }):Play()
		end
	end)
end

local function magnetViewport(parent, tier, pos, size)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = pos
	view.Size = size
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.Parent = parent
	local model = MagnetVisuals.Build(tier)
	model.Parent = view
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.6, -6.2), Vector3.new(0, 1.3, 0))
	cam.Parent = view
	view.CurrentCamera = cam
	table.insert(spinning, model)
end

local function renderUpgrades()
	title.Text = "⬆ UPGRADE KIOSK"
	for i, kind in ipairs({ "speed", "magnet", "income" }) do
		upgradeCard(body, kind, UDim2.fromOffset((i - 1) * 206, 0), UDim2.fromOffset(196, 356))
	end
end

local magnetTab = "magnets"
local function renderMagnets()
	title.Text = "🧲 MAGNET SHOP"
	local tabs = { { "magnets", "MAGNETS" }, { "upgrade", "UPGRADE" }, { "potions", "POTIONS" } }
	for i, t in ipairs(tabs) do
		local b = button(body, t[2], UDim2.fromOffset((i - 1) * 140, 0), UDim2.fromOffset(132, 34), t[1] == magnetTab and Color3.fromRGB(240, 160, 50) or Color3.fromRGB(70, 80, 110))
		b.TextSize = 16
		b.Activated:Connect(function()
			magnetTab = t[1]
			window:SetAttribute("Dirty", true)
		end)
	end
	local area = Instance.new("Frame")
	area.BackgroundTransparency = 1
	area.Position = UDim2.fromOffset(0, 44)
	area.Size = UDim2.fromOffset(612, 316)
	area.Parent = body
	if magnetTab == "magnets" then
		local ownedTier = player:GetAttribute("MagnetTier") or 1
		local equipped = player:GetAttribute("MagnetEquipped") or 1
		for i, def in ipairs(ShopConfig.Magnets) do
			local card = Instance.new("Frame")
			card.Position = UDim2.fromOffset((i - 1) * 122, 0)
			card.Size = UDim2.fromOffset(114, 312)
			card.BackgroundColor3 = i == equipped and Color3.fromRGB(60, 110, 70) or Color3.fromRGB(54, 62, 90)
			card.Parent = area
			corner(card, 14)
			stroke(card, 3, def.Body)
			magnetViewport(card, i, UDim2.fromOffset(4, 6), UDim2.fromOffset(106, 110))
			label(card, def.Name, UDim2.fromOffset(4, 118), UDim2.fromOffset(106, 40), 16)
			label(card, def.Bonus > 0 and ("+" .. def.Bonus .. " radius") or "basic pull", UDim2.fromOffset(4, 160), UDim2.fromOffset(106, 22), 14, def.Body)
			local text, color
			if i == equipped then
				text, color = "IN HAND", Color3.fromRGB(110, 110, 120)
			elseif i <= ownedTier then
				text, color = "EQUIP", Color3.fromRGB(70, 140, 220)
			elseif i == ownedTier + 1 then
				text, color = "💰 " .. fmt(def.Price), coins.Value >= def.Price and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(150, 80, 80)
			else
				text, color = "🔒 LOCKED", Color3.fromRGB(80, 80, 90)
			end
			local b = button(card, text, UDim2.fromOffset(8, 258), UDim2.fromOffset(98, 42), color)
			b.TextSize = 15
			b.Activated:Connect(function()
				if i ~= equipped and i <= ownedTier + 1 then
					buy:FireServer("magnettool", "magnets", i)
				end
			end)
		end
	elseif magnetTab == "upgrade" then
		upgradeCard(area, "magnet", UDim2.fromOffset(0, 0), UDim2.fromOffset(196, 312))
		local info = label(area, "Your pull radius = magnet upgrade + bonus of the magnet in your hand.\n\nHold the magnet (it is always in your hand) to collect coins from further away.", UDim2.fromOffset(220, 20), UDim2.fromOffset(380, 200), 18, Color3.fromRGB(220, 225, 235), Enum.Font.GothamMedium)
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextYAlignment = Enum.TextYAlignment.Top
		label(area, string.format("Current radius: %.1f studs", player:GetAttribute("MagnetRadius") or 0), UDim2.fromOffset(220, 230), UDim2.fromOffset(380, 40), 24, Color3.fromRGB(255, 215, 80))
	else
		for i, name in ipairs(ShopConfig.PotionOrder) do
			local def = ShopConfig.Potions[name]
			local card = Instance.new("Frame")
			card.Position = UDim2.fromOffset((i - 1) * 206, 0)
			card.Size = UDim2.fromOffset(196, 312)
			card.BackgroundColor3 = Color3.fromRGB(54, 62, 90)
			card.Parent = area
			corner(card, 16)
			stroke(card, 3, def.Color)
			local bottle = Instance.new("Frame")
			bottle.AnchorPoint = Vector2.new(0.5, 0)
			bottle.Position = UDim2.new(0.5, 0, 0, 16)
			bottle.Size = UDim2.fromOffset(90, 90)
			bottle.BackgroundColor3 = def.Color
			bottle.Parent = card
			corner(bottle, 45)
			stroke(bottle, 3)
			label(bottle, def.Icon, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 44)
			label(card, def.Name, UDim2.fromOffset(0, 116), UDim2.new(1, 0, 0, 28), 20)
			label(card, def.Effect .. " · 5 min", UDim2.fromOffset(0, 146), UDim2.new(1, 0, 0, 22), 15, def.Color)
			label(card, "You have: " .. (player:GetAttribute("Potion" .. name) or 0), UDim2.fromOffset(0, 176), UDim2.new(1, 0, 0, 22), 16, Color3.fromRGB(220, 225, 235), Enum.Font.GothamBold)
			local b = button(card, "BUY  💰 " .. fmt(def.Price), UDim2.new(0, 12, 1, -58), UDim2.new(1, -24, 0, 46), coins.Value >= def.Price and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(150, 80, 80))
			b.Activated:Connect(function()
				buy:FireServer("potion", "magnets", name)
			end)
		end
	end
end

local function render()
	body:ClearAllChildren()
	spinning = {}
	wallet.Text = "💰 " .. fmt(coins.Value)
	if mode == "upgrades" then
		renderUpgrades()
	elseif mode == "magnets" then
		renderMagnets()
	end
end

local function hide()
	window.Visible = false
	mode = nil
	local s = player:GetAttribute("UIScreen")
	if s == "upgrades" or s == "magnets" then
		player:SetAttribute("UIScreen", "")
	end
end
close.Activated:Connect(hide)

ReplicatedStorage:WaitForChild("GameShopOpen").OnClientEvent:Connect(function(newMode, newZone)
	if newMode ~= "upgrades" and newMode ~= "magnets" then
		return
	end
	mode, zoneId = newMode, newMode == "magnets" and "magnets" or newZone
	local world = workspace:WaitForChild("CoinSpeedWorld")
	if newMode == "magnets" then
		zonePart = world:FindFirstChild("MagnetShop") and world.MagnetShop:FindFirstChild("ShopZone")
	else
		local zone = newZone == "neon" and world:FindFirstChild("NeonCity") or world
		zonePart = zone.UpgradeShop:FindFirstChild("ShopZone") or zone.UpgradeShop:FindFirstChild("Counter")
	end
	player:SetAttribute("UIScreen", newMode)
	window.Visible = true
	render()
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	local s = player:GetAttribute("UIScreen")
	if window.Visible and s ~= mode then
		window.Visible = false
		mode = nil
	end
end)
local function dirty()
	if window.Visible then
		window:SetAttribute("Dirty", true)
	end
end
coins.Changed:Connect(dirty)
speed.Changed:Connect(dirty)
player.AttributeChanged:Connect(function(name)
	if name == "MagnetLevel" or name == "IncomeLevel" or name == "MagnetTier" or name == "MagnetEquipped" or name:sub(1, 6) == "Potion" or name == "MagnetRadius" then
		dirty()
	end
end)

local spin, check = 0, 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		scale.Scale = math.clamp(math.min(camera.ViewportSize.X / 700, camera.ViewportSize.Y / 500), 0.35, 1)
	end
	if not window.Visible then
		return
	end
	if window:GetAttribute("Dirty") then
		window:SetAttribute("Dirty", false)
		render()
	end
	spin += dt
	for _, m in ipairs(spinning) do
		if m.Parent then
			m:PivotTo(CFrame.Angles(0, spin, 0))
		end
	end
	check += dt
	if check > 0.2 then
		check = 0
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if zonePart and root then
			local o = root.Position - zonePart.Position
			local radius = math.max(zonePart.Size.Y, zonePart.Size.Z) / 2
			if Vector2.new(o.X, o.Z).Magnitude > radius + 3 then
				hide()
			end
		elseif not root then
			hide()
		end
	end
end)
