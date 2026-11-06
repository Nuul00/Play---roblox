-- Меню яйца: питомцы с шансами, открытие ×1 / ×3, автооткрытие и автоудаление по видам.
-- Цены и броски проверяет сервер (GameShopBuy); клиент только показывает и отправляет запросы.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Config = require(RS:WaitForChild("GameConfig"))
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local PetVisuals = require(RS:WaitForChild("PetVisuals"))
local Skins = require(RS:WaitForChild("HudSkins"))
local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local buy = RS:WaitForChild("GameShopBuy")
local action = RS:WaitForChild("GameAction")

local gui = Instance.new("ScreenGui")
gui.Name = "WorkshopUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local colors = {
	Common = Color3.fromRGB(188, 203, 224),
	Uncommon = Color3.fromRGB(116, 227, 173),
	Rare = Color3.fromRGB(105, 193, 255),
	Epic = Color3.fromRGB(201, 143, 255),
	Legendary = Color3.fromRGB(255, 204, 104),
	Mythic = Color3.fromRGB(255, 135, 202),
	Secret = Color3.fromRGB(255, 255, 255),
}
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(28, 20, 44)

local NumberFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberFormat"))
local function fmt(n)
	return NumberFormat.Short(n)
end
local function corner(f, r)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, r or 16)
end
local UISounds = require(game:GetService("ReplicatedStorage"):WaitForChild("UISounds"))
local StoreConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("StoreConfig"))
local TOUCH_ONLY = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
local function stroke(f, c, t, tr)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = t or 1.5
	s.Transparency = tr or 0.2
	s.ApplyStrokeMode = f:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end
local function box(parent, x, y, w, h, c)
	local f = Instance.new("Frame")
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = c or Color3.fromRGB(33, 26, 57)
	f.BorderSizePixel = 0
	f.Parent = parent
	corner(f)
	return f
end
local function label(parent, s, x, y, w, h, size, c, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(x, y)
	t.Size = UDim2.fromOffset(w, h)
	t.Text = s
	t.TextColor3 = c or Color3.fromRGB(251, 239, 255)
	t.TextSize = size or 16
	t.Font = font or Enum.Font.GothamBold
	t.TextWrapped = true
	t.Parent = parent
	return t
end
local function button(parent, s, x, y, w, h, c)
	local b = Instance.new("TextButton")
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, h)
	b.Text = s
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 18
	b.TextColor3 = WHITE
	b.BackgroundColor3 = c or Color3.fromRGB(140, 83, 188)
	b.BorderSizePixel = 0
	b.Parent = parent
	corner(b, 12)
	stroke(b, INK, 2.5, 0)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(WHITE, Color3.fromRGB(190, 190, 205))
	g.Rotation = 90
	g.Parent = b
	return b
end
local function viewport(parent, x, y, w, h)
	local v = Instance.new("ViewportFrame")
	v.BackgroundTransparency = 1
	v.Position = UDim2.fromOffset(x, y)
	v.Size = UDim2.fromOffset(w, h)
	v.Ambient = Color3.fromRGB(210, 195, 224)
	v.LightColor = Color3.fromRGB(255, 236, 214)
	v.LightDirection = Vector3.new(-1, -1, -2)
	v.Parent = parent
	local camera = Instance.new("Camera")
	camera.FieldOfView = 38
	camera.CFrame = CFrame.lookAt(Vector3.new(3, 1.8, -5.8), Vector3.zero)
	camera.Parent = v
	v.CurrentCamera = camera
	return Instance.new("WorldModel", v)
end

-- ===== Окно яйца =====
local panel = box(gui, 0, 0, 660, 664, Color3.fromRGB(30, 24, 52))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Visible = false
local panelStroke = stroke(panel, Color3.fromRGB(239, 167, 236), 3, 0)
local scale = Instance.new("UIScale", panel)
local header = box(panel, 8, 8, 644, 92, Color3.new(1, 1, 1))
local headerGrad = Instance.new("UIGradient", header)
headerGrad.Rotation = 20
local title = label(header, "", 20, 10, 470, 38, 30, WHITE, Enum.Font.FredokaOne)
title.TextXAlignment = Enum.TextXAlignment.Left
stroke(title, INK, 2.5, 0)
local subtitle = label(header, "", 20, 52, 470, 26, 15, WHITE)
subtitle.TextScaled = true -- строка с гарантией бывает длинной
do
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 15
	c.Parent = subtitle
end
subtitle.TextXAlignment = Enum.TextXAlignment.Left
stroke(subtitle, INK, 1.5, 0.2)
local wallet = label(header, "", 430, 16, 150, 30, 20, Color3.fromRGB(255, 230, 100), Enum.Font.FredokaOne)
wallet.TextXAlignment = Enum.TextXAlignment.Right
stroke(wallet, INK, 2, 0)
local close = button(header, "X", 592, 22, 42, 42, Color3.fromRGB(220, 70, 90))
close.Modal = true
local gallery = Instance.new("ScrollingFrame")
gallery.BorderSizePixel=0
gallery.ScrollBarThickness=5
gallery.ScrollBarImageColor3=Color3.fromRGB(205,150,255)
gallery.ScrollingDirection=Enum.ScrollingDirection.Y
gallery.CanvasSize=UDim2.fromOffset(0,0)
gallery.BackgroundTransparency = 1
gallery.Position = UDim2.fromOffset(18, 112)
gallery.Size = UDim2.fromOffset(624, 456)
gallery.Parent = panel
local hint = label(panel, "Tap ✓ KEEP on a pet to auto-delete future copies of it (owned pets stay).", 18, 572, 624, 18, 12, Color3.fromRGB(205, 190, 225), Enum.Font.GothamMedium)
-- ×1, ×3, ×9 и автооткрытие: кнопка ×9 нужна телефонам и геймпадам (клавиша T есть только на ПК)
local single = button(panel, "", 18, 598, 146, 52, Color3.fromRGB(130, 90, 220))
local triple = button(panel, "", 172, 598, 146, 52, Color3.fromRGB(240, 140, 70))
local nine = button(panel, "", 326, 598, 146, 52, Color3.fromRGB(230, 80, 160))
local auto = button(panel, "", 480, 598, 162, 52, Color3.fromRGB(70, 170, 110))

-- Облачный пастельный стиль окна для яиц Sky Isles: светлый фон с градиентом розовый → небесный,
-- белая обводка, пастельные кнопки и ячейки. Для остальных миров окно остаётся тёмным.
local PASTEL_BG = ColorSequence.new(Color3.fromRGB(255, 226, 244), Color3.fromRGB(200, 228, 255))
local panelGrad = Instance.new("UIGradient", panel)
panelGrad.Rotation = 90
panelGrad.Color = PASTEL_BG
panelGrad.Enabled = false
local DARK_PANEL = panel.BackgroundColor3
local BUTTON_COLORS = {
	dark = { single = Color3.fromRGB(130, 90, 220), triple = Color3.fromRGB(240, 140, 70), nine = Color3.fromRGB(230, 80, 160), auto = Color3.fromRGB(70, 170, 110) },
	sky = { single = Color3.fromRGB(165, 140, 255), triple = Color3.fromRGB(255, 140, 200), nine = Color3.fromRGB(255, 120, 170), auto = Color3.fromRGB(95, 195, 255) },
}
-- ===== Стиль мира (картинки HUD-скина) =====
-- Рамка окна мира поверх краёв панели, фон и шапка в цветах мира, кнопки OPEN/AUTO — на
-- плашках-плитках того же HUD (как плитки монет/скорости). Без скина остаётся старый вид.
local WORLD_OF = { island = "Meadow Isles", neon = "Neon District", sky = "Sky Isles", frozen = "Frozen Peaks", volcano = "Magma Volcano", galaxy = "Cosmic Galaxy" }
local frameImg = Instance.new("ImageLabel")
frameImg.Name = "SkinFrame"
frameImg.BackgroundTransparency = 1
-- рамка вынесена наружу: её декор (цветы, лава, планеты) не закрывает содержимое окна
frameImg.Position = UDim2.fromOffset(-58, -70)
frameImg.Size = UDim2.new(1, 116, 1, 140)
frameImg.ScaleType = Enum.ScaleType.Stretch -- картинки рамок у миров разного размера: тянем целиком
frameImg.ZIndex = 2
frameImg.Visible = false
frameImg.Parent = panel
local function skinButton(b)
	local img = Instance.new("ImageLabel")
	img.Name = "SkinTile"
	img.BackgroundTransparency = 1
	-- плитка — соседка кнопки в панели (а не её ребёнок): иначе она рисуется поверх текста кнопки
	img.Size = b.Size + UDim2.fromOffset(16, 14)
	img.Position = b.Position - UDim2.fromOffset(8, 7)
	img.ZIndex = 3
	img.Visible = false
	img.Parent = panel
	b.ZIndex = 4
	return img
end
local tiles = { single = skinButton(single), triple = skinButton(triple), nine = skinButton(nine), auto = skinButton(auto) }
header.ZIndex = 3 -- шапка (название, монеты, крестик) поверх рамки мира
-- Компактное окно для телефонов: галерея ниже (она прокручивается), кнопки выше — окно влезает в низкий экран.
local compact = false
local function setCompact(on)
	if on == compact then
		return
	end
	compact = on
	local dy = on and 156 or 0
	panel.Size = UDim2.fromOffset(660, 664 - dy)
	gallery.Size = UDim2.fromOffset(624, 456 - dy)
	hint.Position = UDim2.fromOffset(18, 572 - dy)
	for key, b in pairs({ single = single, triple = triple, nine = nine, auto = auto }) do
		b.Position = UDim2.fromOffset(b.Position.X.Offset, 598 - dy)
		tiles[key].Position = b.Position - UDim2.fromOffset(8, 7)
	end
end
local currentSkin = nil
local function applySkin(world)
	local skin = Skins[WORLD_OF[world] or ""]
	currentSkin = skin and skin.Frame_Window and skin or nil
	local on = currentSkin ~= nil
	frameImg.Visible = on
	panelStroke.Enabled = not on
	if on then
		frameImg.Image = skin.Frame_Window
		frameImg.ImageColor3 = skin.Tint or WHITE
		panelGrad.Enabled = true
		panel.BackgroundColor3 = WHITE
		panelGrad.Color = ColorSequence.new(skin.MenuBottom:Lerp(Color3.new(0, 0, 0), 0.45), skin.MenuBottom:Lerp(Color3.new(0, 0, 0), 0.7))
		headerGrad.Color = ColorSequence.new(skin.MenuTop, skin.MenuBottom)
		title.TextColor3 = skin.TitleColor or WHITE
		for key, img in pairs(tiles) do
			img.Image = skin[key == "triple" and "Tile_Gold" or key == "single" and "Tile_Blue" or key == "nine" and "Tile_Purple" or "Tile_Pink"] or ""
			img.ImageColor3 = skin.Tint or WHITE
			img.Visible = true
		end
		for _, b in ipairs({ single, triple, nine, auto }) do
			b.BackgroundTransparency = 1
			b:FindFirstChildOfClass("UIStroke").Enabled = false
			b.TextColor3 = WHITE
			b.TextStrokeColor3 = skin.InkColor or INK
			b.TextStrokeTransparency = 0
		end
		gallery.ScrollBarImageColor3 = skin.RimColor or gallery.ScrollBarImageColor3
	else
		title.TextColor3 = WHITE
		for _, img in pairs(tiles) do
			img.Visible = false
		end
		for _, b in ipairs({ single, triple, nine, auto }) do
			b:FindFirstChildOfClass("UIStroke").Enabled = true
			b.TextStrokeTransparency = 1
		end
	end
end

local skyTheme = false
local function applyTheme(sky)
	skyTheme = sky
	panelGrad.Enabled = sky
	panel.BackgroundColor3 = sky and WHITE or DARK_PANEL
	panelStroke.Thickness = sky and 5 or 3
	hint.TextColor3 = sky and Color3.fromRGB(140, 110, 200) or Color3.fromRGB(205, 190, 225)
	local set = sky and BUTTON_COLORS.sky or BUTTON_COLORS.dark
	single.BackgroundColor3 = set.single
	triple.BackgroundColor3 = set.triple
	nine.BackgroundColor3 = set.nine
	auto.BackgroundColor3 = set.auto
	gallery.ScrollBarImageColor3 = sky and Color3.fromRGB(170, 140, 255) or Color3.fromRGB(205, 150, 255)
end

-- Плашка автооткрытия: видна, пока режим включён, даже когда окно скрыто анимацией.
local autoChip = box(gui, 0, 0, 300, 46, Color3.fromRGB(40, 140, 90))
autoChip.AnchorPoint = Vector2.new(0.5, 0)
autoChip.Position = UDim2.new(0.5, 0, 0, 72) -- под плашкой событий (EventHUD)
autoChip.ZIndex = 20
autoChip.Visible = false
stroke(autoChip, INK, 2.5, 0)
local autoChipText = label(autoChip, "", 10, 0, 230, 46, 16, WHITE, Enum.Font.FredokaOne)
autoChipText.TextXAlignment = Enum.TextXAlignment.Left
local autoStop = button(autoChip, "STOP", 238, 7, 54, 32, Color3.fromRGB(220, 70, 90))
autoStop.ZIndex = 21
autoChipText.ZIndex = 21
autoStop.TextSize = 14

local eggId, mode, dismissed
local cells = {}
local busy = 0
local autoEgg, autoCount, lastAuto = nil, 0, 0

local function hide()
	panel.Visible = false
	dismissed = eggId
	mode = nil
	if player:GetAttribute("UIScreen") == "egg" then
		player:SetAttribute("UIScreen", "")
	end
end
local function stopAuto(reason)
	if autoEgg then
		autoEgg = nil
		autoChip.Visible = false
		if reason then
			autoChipText.Text = reason
		end
	end
end
close.Activated:Connect(function()
	hide()
end)
autoStop.Activated:Connect(function()
	stopAuto()
end)

local function refresh()
	wallet.Text = "💰 " .. fmt(coins.Value)
	if autoEgg then
		autoChipText.Text = string.format("🥚 AUTO %s · %d opened", Config.Eggs[autoEgg].Name:upper(), autoCount)
	end
	if not eggId then
		return
	end
	local egg = Config.Eggs[eggId]
	title.Text = string.upper(egg.Name)
	-- гарантия (pity): сколько яиц осталось до Legendary / Secret
	local pity = {}
	for _, tier in ipairs(ShopConfig.Pity) do
		local left = math.max(tier.Threshold - (player:GetAttribute("Pity" .. tier.Rarity) or 0), 1)
		table.insert(pity, string.format("%s in %d", tier.Rarity, left))
	end
	subtitle.Text = string.format("%d PETS  ·  💰 %s EACH  ·  🎯 %s", #egg.Pool, fmt(egg.Cost), table.concat(pity, " · "))
	for _, cell in ipairs(cells) do
		local deleting = player:GetAttribute("AutoDelete" .. cell.id) == true
		cell.toggle.Text = deleting and "✕ AUTO-DELETE" or "✓ KEEP"
		cell.toggle.BackgroundColor3 = deleting and Color3.fromRGB(190, 60, 85) or (skyTheme and Color3.fromRGB(150, 130, 230) or Color3.fromRGB(60, 80, 120))
		cell.frame.BackgroundTransparency = deleting and 0.45 or 0
		local owned = player:GetAttribute("PetOwned" .. cell.id) or 0
		cell.owned.Text = owned > 0 and ("OWNED ×" .. owned) or "NEW!"
		cell.owned.TextColor3 = owned > 0 and (skyTheme and Color3.fromRGB(130, 110, 190) or Color3.fromRGB(205, 195, 225)) or (skyTheme and Color3.fromRGB(240, 120, 60) or Color3.fromRGB(255, 225, 90))
	end
	local waiting = os.clock() < busy
	for _, pair in ipairs({ { single, 1 }, { triple, 3 }, { nine, 9 } }) do
		local b, n = pair[1], pair[2]
		local locked = n == 9 and not StoreConfig.HasPassFeature(player, "Hatch9")
		local affordable = coins.Value >= egg.Cost * n or locked
		b.Text = locked and "🔒 OPEN ×9\ngamepass" or waiting and "OPENING…" or (TOUCH_ONLY and string.format("OPEN ×%d\n💰 %s", n, fmt(egg.Cost * n)) or string.format("OPEN ×%d [%s]\n💰 %s", n, n == 1 and "E" or n == 3 and "R" or "T", fmt(egg.Cost * n)))
		b.Active = affordable and not waiting and not autoEgg
		b.AutoButtonColor = b.Active and not currentSkin
		if currentSkin then
			b.BackgroundTransparency = 1
			local img = tiles[b == single and "single" or b == triple and "triple" or "nine"]
			if img then
				img.ImageTransparency = b.Active and 0 or 0.5
			end
			b.TextTransparency = b.Active and 0 or 0.35
		else
			b.BackgroundTransparency = b.Active and 0 or 0.45
		end
	end
	local on = autoEgg == eggId
	auto.Text = on and "AUTO: ON\ntap to stop" or (StoreConfig.HasPassFeature(player, "AutoHatch") and "AUTO OPEN\n×3 when possible" or "🔒 AUTO OPEN\ngamepass")
	auto.BackgroundColor3 = on and Color3.fromRGB(220, 70, 90) or (skyTheme and BUTTON_COLORS.sky.auto or BUTTON_COLORS.dark.auto)
	if currentSkin then
		auto.BackgroundTransparency = 1
		tiles.auto.Image = currentSkin[on and "Tile_Purple" or "Tile_Pink"] or tiles.auto.Image
	end
end

-- ×9 и автооткрытие — геймпассы (StoreConfig.HasPassFeature: бесплатно, пока пасс не создан,
-- и тем, кто играл до их введения). Нет пасса — кнопка предлагает его купить.
local function needPass(key)
	if StoreConfig.HasPassFeature(player, key) then
		return false
	end
	local def = StoreConfig.PassByKey(key)
	if def then
		game:GetService("MarketplaceService"):PromptGamePassPurchase(player, def.Id)
	end
	return true
end
local function hatch(n)
	if n == 9 and needPass("Hatch9") then
		return true
	end
	if not eggId or os.clock() < busy or coins.Value < Config.Eggs[eggId].Cost * n then
		return false
	end
	busy = os.clock() + 0.7
	buy:FireServer("egg", Config.Eggs[eggId].World, eggId, n)
	refresh()
	return true
end
single.Activated:Connect(function()
	hatch(1)
end)
triple.Activated:Connect(function()
	hatch(3)
end)
nine.Activated:Connect(function()
	hatch(9)
end)
-- Клавиши, пока открыто окно яйца: E — ×1, R — ×3, T — ×9.
local KEYS = { [Enum.KeyCode.E] = 1, [Enum.KeyCode.R] = 3, [Enum.KeyCode.T] = 9 }
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
	local n = KEYS[input.KeyCode]
	if processed or not n or mode ~= "egg" or not panel.Visible or autoEgg then
		return
	end
	if not hatch(n) and eggId and coins.Value < Config.Eggs[eggId].Cost * n then
		subtitle.Text = "Not enough coins for ×" .. n
	end
end)
-- подсказка про клавиши — в строке над кнопками (внизу окна её закрывают украшения рамки)
hint.Text = (TOUCH_ONLY and "" or "⌨ E ×1  R ×3  T ×9   ·   ") .. "✓ KEEP / ✕ AUTO-DELETE copies   ·   🌌 Super Secret odds — scroll down"
hint.TextScaled = true
do
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 12
	c.Parent = hint
end
auto.Activated:Connect(function()
	if autoEgg == eggId then
		stopAuto()
	elseif eggId and needPass("AutoHatch") then
		return
	elseif eggId then
		if coins.Value < Config.Eggs[eggId].Cost then
			subtitle.Text = "Not enough coins for auto open"
			return
		end
		autoEgg, autoCount, lastAuto = eggId, 0, 0
		autoChip.Visible = true
	end
	refresh()
end)

local function showEgg(id)
	if mode == "egg" and eggId == id and panel.Visible then
		return
	end
	eggId = id
	mode = "egg"
	local egg = Config.Eggs[id]
	local sky = egg.World == "sky"
	applyTheme(sky)
	headerGrad.Color = sky and ColorSequence.new(egg.Color:Lerp(WHITE, 0.45), egg.Color:Lerp(WHITE, 0.05)) or ColorSequence.new(egg.Color:Lerp(WHITE, 0.15), egg.Color:Lerp(Color3.new(0, 0, 0), 0.35))
	panelStroke.Color = sky and WHITE or egg.Color
	applySkin(egg.World)
	gallery:ClearAllChildren()
	cells = {}
	local count = #egg.Pool
	local cols = 3
	local cellW, cellH = 200, count > 6 and 146 or 220
	gallery.CanvasSize=UDim2.fromOffset(0,math.ceil(count/cols)*(cellH+9)-9)
	gallery.CanvasPosition=Vector2.zero
	for i, entry in ipairs(egg.Pool) do
		local def = Config.Pets[entry.Pet]
		local c = colors[def.Rarity] or colors.Common
		local cellBg = sky and Color3.fromRGB(252, 248, 255) or Color3.fromRGB(46, 38, 72)
		local cell = box(gallery, (i - 1) % cols * 212, math.floor((i - 1) / cols) * (cellH + 9), cellW, cellH, cellBg)
		stroke(cell, c, (def.Rarity == "Secret" or def.Rarity == "Legendary") and 3 or 2, 0)
		local grad = Instance.new("UIGradient", cell)
		grad.Color = sky and ColorSequence.new(c:Lerp(WHITE, 0.45), Color3.fromRGB(236, 232, 255)) or ColorSequence.new(c:Lerp(Color3.fromRGB(46, 38, 72), 0.55), Color3.fromRGB(36, 30, 58))
		grad.Rotation = 90
		local scene = viewport(cell, 2, 18, 112, cellH - 58)
		local ok, model = pcall(PetVisuals.Build, entry.Pet)
		if ok and model then
			model.Parent = scene
		end
		local pill = box(cell, 6, 5, 100, 18, c)
		corner(pill, 9)
		label(pill, def.Rarity:upper(), 0, 0, 100, 18, 11, INK, Enum.Font.GothamBlack)
		local chance = label(cell, string.format("%g%%", entry.Chance), 112, 24, 84, 30, 24, c, Enum.Font.FredokaOne)
		stroke(chance, INK, 2, 0)
		label(cell, string.format("×%g 💰", def.Multiplier), 112, 56, 84, 20, 14, sky and Color3.fromRGB(235, 130, 40) or Color3.fromRGB(255, 220, 140), Enum.Font.FredokaOne)
		local owned = label(cell, "", 112, 78, 84, 18, 11, Color3.fromRGB(205, 195, 225))
		local name = label(cell, def.Name, 6, cellH - 50, 188, 18, 14, WHITE, Enum.Font.FredokaOne)
		stroke(name, INK, 1.5, 0)
		-- выше, чем было (18 px): на телефоне в такой переключатель не попасть
		local toggle = button(cell, "", 8, cellH - 30, 184, 26)
		toggle.TextSize = 12
		toggle.Font = Enum.Font.GothamBold
		toggle.Activated:Connect(function()
			action:FireServer("autodelete", entry.Pet)
		end)
		table.insert(cells, { id = entry.Pet, toggle = toggle, owned = owned, frame = cell })
	end
	-- Шансы супер-секреток этого яйца — до покупки (правило Roblox о платных случайных предметах).
	do
		local rows = {}
		for tierIndex, tier in ipairs(Config.SuperTiers) do
			local id = Config.SuperByWorld[egg.World] and Config.SuperByWorld[egg.World][tierIndex]
			if id and tier.Odds then
				table.insert(rows, string.format("%s %s — %s", tier.Icon, Config.Pets[id].Name, Config.FormatOdds(tier.Odds)))
			end
		end
		for _, id in ipairs(Config.Specials) do
			local def = Config.Pets[id]
			if def.World == nil or def.World == egg.World then
				table.insert(rows, string.format("%s %s (%s) — %s", def.SuperKey == "Cosmic" and "🌠" or "🔮", def.Name, def.SuperKey, Config.FormatOdds(def.Odds)))
			end
		end
		local top = math.ceil(count / cols) * (cellH + 9)
		local h = 30 + #rows * 18 + 34
		local extra = box(gallery, 0, top, 3 * 212 - 12, h, sky and Color3.fromRGB(245, 238, 255) or Color3.fromRGB(36, 28, 60))
		stroke(extra, Color3.fromRGB(190, 140, 255), 2, 0)
		label(extra, "🌌 SUPER SECRETS (from any hatch of this egg)", 10, 4, 600, 22, 15, Color3.fromRGB(200, 160, 255), Enum.Font.FredokaOne)
		for k, text in ipairs(rows) do
			label(extra, text, 14, 28 + (k - 1) * 18, 600, 18, 13, sky and Color3.fromRGB(70, 60, 110) or Color3.fromRGB(225, 220, 245), Enum.Font.GothamBold).TextXAlignment = Enum.TextXAlignment.Left
		end
		label(extra, "Luck boosts (passes, potions, events) raise rare chances. Shown chances are base chances.", 14, h - 30, 600, 18, 11, Color3.fromRGB(170, 160, 200), Enum.Font.Gotham).TextXAlignment = Enum.TextXAlignment.Left
		gallery.CanvasSize = UDim2.fromOffset(0, top + h)
	end
	player:SetAttribute("UIScreen", "egg")
	panel.Visible = true
	refresh()
end
RS:WaitForChild("GameShopOpen").OnClientEvent:Connect(function(newMode, _, id)
	if newMode == "egg" then
		showEgg(id)
	end
end)
coins.Changed:Connect(refresh)
player.AttributeChanged:Connect(function(name)
	if name:sub(1, 8) == "PetOwned" or name:sub(1, 10) == "AutoDelete" then
		refresh()
	end
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	if player:GetAttribute("UIScreen") ~= "egg" then
		panel.Visible = false
		mode = nil
	end
end)
RS:WaitForChild("GameFeedback").OnClientEvent:Connect(function(text)
	-- Сервер ответил «не хватает монет» — автооткрытие останавливаем.
	if autoEgg and type(text) == "string" and text:find("Not enough") then
		stopAuto()
	end
end)

-- ===== Анимация открытия =====
local dim = Instance.new("Frame")
dim.Name = "RevealDim"
dim.BackgroundColor3 = Color3.fromRGB(8, 6, 20)
dim.BackgroundTransparency = 0.45
dim.BorderSizePixel = 0
dim.Size = UDim2.fromScale(1, 1)
dim.Visible = false
dim.ZIndex = 0
dim.Parent = gui
local dimGrad = Instance.new("UIGradient", dim)
dimGrad.Rotation = 90
dimGrad.Color = ColorSequence.new(Color3.fromRGB(255, 225, 245), Color3.fromRGB(190, 225, 255))
dimGrad.Enabled = false
local reveal = box(gui, 0, 0, 900, 520, Color3.fromRGB(30, 24, 52))
reveal.BackgroundTransparency = 1
reveal.AnchorPoint = Vector2.new(0.5, 0.5)
reveal.Position = UDim2.fromScale(0.5, 0.5)
reveal.Visible = false
local revealStroke = stroke(reveal, Color3.fromRGB(239, 167, 236), 3, 1)
local revealScale = Instance.new("UIScale", reveal)
local revealTitle = label(reveal, "", 0, 0, 900, 64, 44, WHITE, Enum.Font.FredokaOne)
local revealTitleStroke = stroke(revealTitle, INK, 2.5, 0)
local revealArea = Instance.new("Frame")
revealArea.BackgroundTransparency = 1
revealArea.Position = UDim2.fromOffset(0, 70)
revealArea.Size = UDim2.fromOffset(900, 440)
revealArea.Parent = reveal
local results, scenes, models, resultLabels, glows = {}, {}, {}, {}, {}
local modelScales, sparks = {}, {}
local started, finished, revealLength = 0, false, 4.1
local crackAt, rarityIdx, rayHolders, bestIdx = 2.1, {}, {}, 1
local SKY_SPARKS = { Color3.fromRGB(255, 150, 210), Color3.fromRGB(150, 205, 255), Color3.fromRGB(190, 160, 255), Color3.fromRGB(255, 220, 130), Color3.fromRGB(160, 240, 210) }
local RARITY_ORDER = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Mythic = 5, Legendary = 6, Secret = 7 }
local flash = Instance.new("Frame")
flash.Name = "RevealFlash"
flash.BackgroundColor3 = WHITE
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Size = UDim2.fromScale(1, 1)
flash.ZIndex = 20
flash.Active = false
flash.Parent = gui
local displays = {}
local world = workspace:WaitForChild("CoinSpeedWorld")
for id, egg in ipairs(Config.Eggs) do
	task.spawn(function()
		local zone = egg.World == "neon" and world:WaitForChild("NeonCity") or egg.World == "sky" and world:WaitForChild("SkyIsles") or egg.World == "volcano" and world:WaitForChild("MagmaVolcano") or egg.World == "galaxy" and world:WaitForChild("CosmicGalaxy") or egg.World == "frozen" and world:WaitForChild("FrozenPeaks") or world
		local stand = zone:WaitForChild("EggStand" .. id, 60)
		if not stand then
			return
		end
		while not stand:GetAttribute("EggReady") do
			stand.AttributeChanged:Wait()
		end
		local display = stand:WaitForChild("EggDisplay")
		local size = display:GetExtentsSize()
		displays[id] = { model = display, base = display:GetPivot(), radius = math.max(size.X, size.Z) / 2, stand = stand }
		-- Модель яйца из Tripo подставляется сервером чуть позже (TripoDressing): берём новую.
		stand.ChildAdded:Connect(function(c)
			if c.Name == "EggDisplay" and c:IsA("Model") then
				local s2 = c:GetExtentsSize()
				displays[id] = { model = c, base = c:GetPivot(), radius = math.max(s2.X, s2.Z) / 2, stand = stand }
			end
		end)
		local newer = stand:FindFirstChild("EggDisplay")
		if newer and newer ~= display then
			local s2 = newer:GetExtentsSize()
			displays[id] = { model = newer, base = newer:GetPivot(), radius = math.max(s2.X, s2.Z) / 2, stand = stand }
		end
	end)
end
-- ===== 3D-открытие яйца =====
-- Яйцо (клон модели Tripo со стенда) падает с отскоком, качается и подпрыгивает, на нём проступают
-- светящиеся трещины (свет внутри намекает на редкость с Epic), затем вспышка: скорлупа разлетается
-- осколками, ударная волна и конфетти, питомец выскакивает с перелётом масштаба.
-- Всё состояние и помощники лежат в таблице H, чтобы не упереться в лимит локальных переменных.
local H = { eggs = {}, vignette = {}, rng = Random.new(), bestIdx = 1, bestName = "Common" }
H.CAM_DIR = Vector3.new(3, 1.8, -5.8).Unit
H.CAM_AZ = math.atan2(H.CAM_DIR.X, H.CAM_DIR.Z)
H.WARM = Color3.fromRGB(255, 214, 120)
H.GOLD = Color3.fromRGB(255, 200, 60)
H.eggColor = WHITE
H.CORNERS = {}
for _, x in ipairs({ -1, 1 }) do
	for _, y in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			table.insert(H.CORNERS, Vector3.new(x, y, z))
		end
	end
end
-- Сигнал для RareFX: кинематографичная вспышка Legendary/Secret совпадает с раскалыванием.
H.burstEvent = Instance.new("BindableEvent")
H.burstEvent.Name = "HatchBurst"
H.burstEvent.Parent = gui
H.titleScale = Instance.new("UIScale")
H.titleScale.Parent = revealTitle
-- Виньетка: четыре края затемнения поверх общего затемнения фона.
for _, spec in ipairs({
	{ UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3), 90 },
	{ UDim2.fromScale(0, 0.7), UDim2.fromScale(1, 0.3), -90 },
	{ UDim2.fromScale(0, 0), UDim2.fromScale(0.25, 1), 0 },
	{ UDim2.fromScale(0.75, 0), UDim2.fromScale(0.25, 1), 180 },
}) do
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BackgroundTransparency = 1
	f.Position = spec[1]
	f.Size = spec[2]
	f.ZIndex = 0
	f.Parent = dim
	local g = Instance.new("UIGradient")
	g.Rotation = spec[3]
	g.Transparency = NumberSequence.new(0.05, 1)
	g.Parent = f
	table.insert(H.vignette, f)
end

function H.smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
function H.backOut(u, c)
	c = c or 2.2
	local v = math.clamp(u, 0, 1) - 1
	return 1 + (c + 1) * v * v * v + c * v * v
end
function H.bounceOut(u)
	local n, d = 7.5625, 2.75
	if u < 1 / d then
		return n * u * u
	elseif u < 2 / d then
		u -= 1.5 / d
		return n * u * u + 0.75
	elseif u < 2.5 / d then
		u -= 2.25 / d
		return n * u * u + 0.9375
	end
	u -= 2.625 / d
	return n * u * u + 0.984375
end
-- Точка и нормаль на эллипсоиде яйца (радиусы r) по азимуту и широте.
function H.surface(r, az, el, push)
	local ce = math.cos(el)
	local p = Vector3.new(ce * math.sin(az) * r.X, math.sin(el) * r.Y, ce * math.cos(az) * r.Z) * (push or 1)
	local n = Vector3.new(p.X / (r.X * r.X), p.Y / (r.Y * r.Y), p.Z / (r.Z * r.Z)).Unit
	return p, n
end
function H.circle(size, color, transparency, z)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency
	f.Size = UDim2.fromOffset(size, size)
	f.ZIndex = z or 1
	f.Parent = revealArea
	corner(f, 999)
	return f
end
-- Удар (подпрыгивание) яйца: b от 0 до 1 → смещение вверх и сжатие по высоте.
function H.beat(b)
	if b < 0.25 then
		return 0, 1 - 0.22 * H.smooth(b / 0.25)
	elseif b < 0.72 then
		local k = (b - 0.25) / 0.47
		return math.sin(k * math.pi) * 0.42, 0.78 + 0.34 * H.smooth(k / 0.25) - 0.12 * H.smooth((k - 0.45) / 0.55)
	end
	local k = (b - 0.72) / 0.28
	return 0, 1 - 0.13 * math.sin(k * math.pi)
end

-- Клон яйца со стенда: убираем скрипты и эффекты, центрируем, высота 2.8 стада.
-- Детали двигаем сами (ScaleTo не умеет сплющивать), поэтому запоминаем смещения и размеры.
function H.prepEgg(disp, wm, fallback)
	local source = disp.model
	local ok, egg = pcall(function()
		return source:Clone()
	end)
	if not ok or not egg then
		return nil
	end
	local pivotNow = source:GetPivot()
	local base = disp.base or pivotNow
	local rest, parts = {}, {}
	local minV, maxV, biggest, bigVol = nil, nil, nil, -1
	for _, d in ipairs(egg:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("ProximityPrompt") or d:IsA("Light") or d:IsA("Beam") or d:IsA("Trail") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.CastShadow = false
			if d.Transparency < 1 then
				-- Положение «в покое»: EggBillboards качает и подбрасывает модель, это убираем.
				local cf = base * pivotNow:ToObjectSpace(d.CFrame)
				rest[d] = cf
				local half = d.Size / 2
				for _, c in ipairs(H.CORNERS) do
					local w = cf:PointToWorldSpace(c * half)
					minV = minV and minV:Min(w) or w
					maxV = maxV and maxV:Max(w) or w
				end
				local vol = d.Size.X * d.Size.Y * d.Size.Z
				if vol > bigVol then
					biggest, bigVol = d, vol
				end
				table.insert(parts, d)
			end
		end
	end
	if not minV then
		egg:Destroy()
		return nil
	end
	local center = (minV + maxV) / 2
	local k = 2.8 / math.max(maxV.Y - minV.Y, 0.05)
	local items = {}
	for _, p in ipairs(parts) do
		local cf = rest[p]
		local it = { part = p, offset = CFrame.new((cf.Position - center) * k) * cf.Rotation, size = p.Size * k }
		local mesh = p:FindFirstChildOfClass("SpecialMesh")
		if mesh and mesh.MeshType == Enum.MeshType.FileMesh then
			it.mesh = mesh
			it.meshScale = mesh.Scale * k
		end
		table.insert(items, it)
	end
	-- Цвет скорлупы — цвет самой крупной детали; у текстурных мешей Tripo берём цвет яйца из конфига.
	local color = fallback
	if biggest and not (biggest:IsA("MeshPart") and biggest.TextureID ~= "") and not biggest:FindFirstChildOfClass("SurfaceAppearance") then
		color = biggest.Color
	end
	egg.Parent = wm
	return { model = egg, items = items, cracks = {}, radii = (maxV - minV) / 2 * k, color = color }
end

-- Трещины: зигзаг вокруг «экватора» со стороны камеры и три ветки вверх/вниз.
-- Каждый отрезок — тонкая неоновая деталь + полупрозрачный ореол; key — когда он начинает расти.
function H.makeCracks(egg)
	local rng, r = H.rng, egg.radii
	local function seg(a, b, key)
		local len = (b.p - a.p).Magnitude
		if len < 0.01 then
			return
		end
		local off = CFrame.lookAt((a.p + b.p) / 2, b.p, (a.n + b.n).Unit)
		for layer = 1, 2 do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Color = H.WARM
			p.Transparency = 1
			p.Size = Vector3.new(0.05, 0.03, len)
			p.Parent = egg.model
			table.insert(egg.cracks, { part = p, offset = off, len = len, key = key, glow = layer == 2 })
		end
	end
	local function point(az, el)
		local p, n = H.surface(r, az, el, 1.05)
		return { p = p, n = n, az = az, el = el }
	end
	local count = 9
	local span = 1.1 + rng:NextNumber(0, 0.25)
	local baseEl = rng:NextNumber(-0.05, 0.15)
	local pts = {}
	for k = 0, count - 1 do
		local az = H.CAM_AZ - span + 2 * span * k / (count - 1) + rng:NextNumber(-0.05, 0.05)
		local el = baseEl + (k % 2 == 0 and 0.13 or -0.11) + rng:NextNumber(-0.04, 0.04)
		pts[k + 1] = point(az, el)
	end
	local mid = (count + 1) / 2
	for k = 1, count - 1 do
		local key = math.abs(k + 0.5 - mid) / (mid - 1) * 0.55
		if k + 0.5 < mid then
			seg(pts[k + 1], pts[k], key)
		else
			seg(pts[k], pts[k + 1], key)
		end
	end
	for _, v in ipairs({ 3, 5, 7 }) do
		local from = pts[v]
		local dir = from.el > baseEl and 1 or -1
		for j = 1, 3 do
			local to = point(from.az + rng:NextNumber(-0.16, 0.16), from.el + dir * rng:NextNumber(0.16, 0.24))
			seg(from, to, 0.5 + 0.12 * (j - 1) + rng:NextNumber(0, 0.05))
			from = to
		end
	end
end

-- Ставит все детали яйца: cf — центр, s — общий масштаб, sq — сплющивание по осям.
function H.applyEgg(egg, cf, s, sq, prog, width, color)
	local changed = s ~= egg.lastS or sq ~= egg.lastSq
	egg.lastS, egg.lastSq, egg.lastCF = s, sq, cf
	for _, it in ipairs(egg.items) do
		local o = it.offset
		it.part.CFrame = cf * CFrame.new(o.Position * sq * s) * o.Rotation
		if changed then
			local f = Vector3.new((o.XVector * sq).Magnitude, (o.YVector * sq).Magnitude, (o.ZVector * sq).Magnitude) * s
			if it.mesh then
				it.mesh.Scale = it.meshScale * f
			else
				it.part.Size = it.size * f
			end
		end
	end
	local core = color:Lerp(WHITE, 0.35)
	for _, c in ipairs(egg.cracks) do
		local grow = math.clamp((prog - c.key) / 0.14, 0, 1)
		if grow <= 0 then
			if c.part.Transparency < 1 then
				c.part.Transparency = 1
			end
		else
			local o = c.offset * CFrame.new(0, 0, (1 - grow) * c.len / 2)
			c.part.CFrame = cf * CFrame.new(o.Position * sq * s) * o.Rotation
			-- Свежий отрезок — волосок, утолщается по мере роста; ореол лишь чуть шире линии.
			local w = (c.glow and width * 2.2 or width) * (0.35 + 0.65 * grow) * s
			c.part.Size = Vector3.new(w, math.min(w, 0.03), math.max(c.len * grow, 0.02) * s)
			c.part.Transparency = c.glow and 0.78 or 0
			c.part.Color = c.glow and color or core
		end
	end
end

-- Осколки скорлупы: создаются заранее спрятанными, чтобы при взрыве не было рывка.
function H.makeShards(e, wm, color, count)
	local rng, r = H.rng, e.egg.radii
	for k = 1, count do
		local wedge = k % 3 ~= 0
		local p = Instance.new(wedge and "WedgePart" or "Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = k % 4 == 0 and color:Lerp(WHITE, 0.4) or (k % 4 == 2 and color:Lerp(Color3.new(0, 0, 0), 0.15) or color)
		local w, h = rng:NextNumber(0.45, 0.85), rng:NextNumber(0.4, 0.75)
		-- У клина треугольник лежит в плоскости YZ, поэтому тонкая сторона — X.
		p.Size = wedge and Vector3.new(0.1, h, w) or Vector3.new(w, h, 0.1)
		p.Transparency = 1
		p.CFrame = CFrame.new(0, -100, 0)
		p.Parent = wm
		-- Направления равномерно по сфере (спираль), чуть сильнее в сторону камеры.
		local y = 1 - (k - 0.5) / count * 2
		local rad = math.sqrt(math.max(0, 1 - y * y))
		local th = k * 2.39996 + rng:NextNumber(-0.2, 0.2)
		local dir = Vector3.new(math.cos(th) * rad, y, math.sin(th) * rad)
		local pos = Vector3.new(dir.X * r.X, dir.Y * r.Y, dir.Z * r.Z)
		table.insert(e.shards, {
			part = p,
			pos = pos,
			dir = dir,
			fix = wedge and CFrame.Angles(0, math.pi / 2, 0) or CFrame.identity,
			speed = rng:NextNumber(3.6, 6.2),
			axis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit,
			spin = rng:NextNumber(5, 12) * (rng:NextNumber() < 0.5 and -1 or 1),
		})
	end
end

-- Одно яйцо открытия (из 1 или 3) со всей графикой вокруг.
function H.makeEgg(i, result, ctx)
	local rng = H.rng
	local def = Config.Pets[result.Pet]
	local ri = RARITY_ORDER[def.Rarity] or 1
	local rc = colors[def.Rarity] or WHITE
	local x = (i - 1) * ctx.width
	local cx, cy = x + ctx.width / 2, 165
	if ctx.grid then
		local col, row = (i - 1) % 3, (i - 1) // 3
		x = col * ctx.width
		cx, cy = x + ctx.width / 2, 70 + row * 128
	end
	local e = { index = i, result = result, def = def, ri = ri, rc = rc, cx = cx, cy = cy, shards = {}, sparks = {}, confetti = {}, rings = {} }
	e.dropAt = (i - 1) * (ctx.auto and 0.08 or 0.12)
	e.dropDur = ctx.auto and 0.4 or 0.6
	e.antStart = e.dropAt + e.dropDur
	e.burstAt = crackAt + (i - 1) * ctx.stagger
	e.beatDur = ctx.auto and 0.26 or 0.34
	e.beats = {}
	local win = math.max(0.3, e.burstAt - 0.28 - e.antStart - e.beatDur)
	for k, f in ipairs(ctx.auto and { 0.3, 0.85 } or { 0.15, 0.5, 0.85 }) do
		e.beats[k] = e.antStart + f * win
	end
	e.phase = rng:NextNumber(0, 6)
	-- Мягкий ореол из трёх кругов в цвет яйца.
	e.halo, e.haloSizes = {}, { 1, 0.72, 0.46 }
	for k = 1, 3 do
		local f = H.circle(0, ctx.eggCfg.Color, 1, 1)
		f.Position = UDim2.fromOffset(cx, cy)
		e.halo[k] = f
	end
	if ri >= 3 then
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromOffset(cx, cy)
		holder.Size = UDim2.fromOffset(10, 10)
		holder.ZIndex = 1
		holder.Visible = false
		holder.Parent = revealArea
		e.rays, e.rayBars = holder, {}
		local bars = ri >= 6 and 6 or 4
		for k = 0, bars - 1 do
			local bar = Instance.new("Frame")
			bar.BorderSizePixel = 0
			bar.AnchorPoint = Vector2.new(0.5, 0.5)
			bar.Position = UDim2.fromScale(0.5, 0.5)
			bar.Size = UDim2.new(0, ri >= 6 and 26 or 18, 1, 0)
			bar.Rotation = k * 180 / bars
			bar.BackgroundColor3 = ri == 6 and H.GOLD or rc
			bar.BackgroundTransparency = 1
			bar.ZIndex = 1
			bar.Parent = holder
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.1),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = bar
			table.insert(e.rayBars, bar)
		end
	end
	if ctx.sky then
		-- Облачко под яйцом: белый овал с пушистыми боками.
		for k, off in ipairs({ { 0, 0, 190, 54 }, { -70, -12, 90, 60 }, { 70, -10, 96, 62 }, { 0, -22, 110, 70 } }) do
			local puff = Instance.new("Frame")
			puff.AnchorPoint = Vector2.new(0.5, 0.5)
			puff.Position = UDim2.fromOffset(cx + off[1], 286 + off[2])
			puff.Size = UDim2.fromOffset(off[3], off[4])
			puff.BackgroundColor3 = WHITE
			puff.BackgroundTransparency = 0.05
			puff.BorderSizePixel = 0
			puff.ZIndex = 0
			puff.Parent = revealArea
			corner(puff, 60)
			if k == 1 then
				stroke(puff, Color3.fromRGB(200, 185, 255), 3, 0)
			end
		end
	end
	-- Вьюпорт шире колонки, чтобы осколки не обрезались; камера дальше — размер яйца тот же.
	local vw, vh = ctx.width + 140, 440
	if ctx.grid then
		vw, vh = ctx.width, 180
	end
	local wm = viewport(revealArea, cx - vw / 2, cy - vh / 2, vw, vh)
	local vp = wm.Parent
	-- Вьюпорт поверх ореола и лучей; свет нейтральный, чтобы текстура Tripo не выцветала.
	vp.ZIndex = 3
	vp.ImageTransparency = 0
	vp.ImageColor3 = WHITE
	vp.Ambient = Color3.fromRGB(200, 200, 215)
	vp.LightColor = Color3.fromRGB(255, 245, 235)
	vp.CurrentCamera.CFrame = CFrame.lookAt(H.CAM_DIR * (6.774 * vh / 330 * (ctx.zoom or 1)), Vector3.zero)
	e.vp, e.wm, e.ambient, e.light = vp, wm, vp.Ambient, vp.LightColor
	e.egg = H.prepEgg(ctx.disp, wm, ctx.eggCfg.Color)
	if e.egg then
		H.makeCracks(e.egg)
		H.makeShards(e, wm, e.egg.color, 12 + (ri >= 4 and 2 or 0) + (ri >= 6 and 2 or 0))
	end
	local ok, pet = pcall(PetVisuals.Build, result.Pet)
	if ok and typeof(pet) == "Instance" and pet:IsA("Model") then
		e.pet, e.petScale = pet, pet:GetScale()
	end
	-- Ударная волна (у редких — две), вспышка-круг, искры и конфетти.
	for k = 1, ri >= 5 and 2 or 1 do
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset(cx, cy)
		f.BackgroundTransparency = 1
		f.ZIndex = 4
		f.Visible = false
		f.Parent = revealArea
		corner(f, 999)
		local s = Instance.new("UIStroke")
		s.Color = k == 1 and WHITE or (ri == 6 and H.GOLD or rc)
		s.Thickness = k == 1 and 7 or 4
		s.Parent = f
		table.insert(e.rings, { frame = f, stroke = s, delay = (k - 1) * 0.1, max = 300 + 80 * (k - 1) + 15 * ri, thick = s.Thickness })
	end
	e.flashDot = H.circle(0, WHITE, 1, 5)
	e.flashDot.Position = UDim2.fromOffset(cx, cy)
	local sparkCount = 12 + (ri >= 3 and 8 or 0) + (ri >= 5 and 10 or 0) + (ri >= 7 and 10 or 0)
	for j = 1, sparkCount do
		local spark = Instance.new("Frame")
		spark.BorderSizePixel = 0
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.Size = UDim2.fromOffset(j % 3 == 0 and 8 or 4, j % 3 == 0 and 8 or 4)
		spark.BackgroundColor3 = ctx.sky and SKY_SPARKS[j % #SKY_SPARKS + 1] or ctx.eggCfg.Color
		spark.BackgroundTransparency = 1
		spark.ZIndex = 5
		spark.Parent = revealArea
		corner(spark, 4)
		table.insert(e.sparks, { frame = spark, angle = j * math.pi * 2 / sparkCount + rng:NextNumber(-0.1, 0.1), reach = 150 + 26 * (ri - 1) + (j % 3) * 22 })
	end
	local palette = ctx.sky and SKY_SPARKS or { rc, ctx.eggCfg.Color, WHITE, rc:Lerp(WHITE, 0.4), Color3.fromRGB(255, 220, 110) }
	for j = 1, 14 + 2 * ri do
		local c = Instance.new("Frame")
		c.BorderSizePixel = 0
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.BackgroundColor3 = ri >= 7 and Color3.fromHSV(rng:NextNumber(), 0.55, 1) or palette[j % #palette + 1]
		c.Visible = false
		c.ZIndex = 5
		c.Parent = revealArea
		local a = rng:NextNumber(-math.pi * 0.95, -math.pi * 0.05)
		local sp = rng:NextNumber(260, 520)
		table.insert(e.confetti, {
			frame = c,
			pos = Vector2.new(cx, cy),
			vel = Vector2.new(math.cos(a) * sp, math.sin(a) * sp),
			w = rng:NextNumber(6, 10),
			h = rng:NextNumber(10, 16),
			spin = rng:NextNumber(-400, 400),
			flip = rng:NextNumber(6, 14),
		})
	end
	e.label = label(revealArea, "", x + 4, ctx.grid and (cy + 34) or 334, ctx.width - 8, ctx.grid and 40 or 100, ctx.grid and 14 or 20, WHITE, Enum.Font.FredokaOne)
	e.label.TextTransparency = 1
	e.label.ZIndex = 6
	e.labelScale = Instance.new("UIScale")
	e.labelScale.Scale = 0.05
	e.labelScale.Parent = e.label
	if result.Count == 1 and not result.Deleted then
		local tag = label(revealArea, "NEW!", 0, 0, 84, 30, 20, INK, Enum.Font.FredokaOne)
		tag.AnchorPoint = Vector2.new(0.5, 0.5)
		tag.Position = UDim2.fromOffset(cx + math.min(70, ctx.width / 2 - 50), cy - (ctx.grid and 50 or 100))
		tag.BackgroundTransparency = 0
		tag.BackgroundColor3 = Color3.fromRGB(255, 225, 70)
		tag.ZIndex = 7
		tag.Visible = false
		corner(tag, 15)
		stroke(tag, INK, 2.5, 0)
		e.newTag = tag
		e.newScale = Instance.new("UIScale")
		e.newScale.Parent = tag
	end
	return e
end

function H.cleanup()
	for _, e in ipairs(H.eggs) do
		if e.pet and not e.pet.Parent then
			e.pet:Destroy()
		end
	end
	H.eggs = {}
	revealArea:ClearAllChildren()
end

function H.start(batch, sourceEgg, auto)
	H.cleanup()
	local eggCfg = Config.Eggs[sourceEgg]
	local n = #batch
	H.auto, H.titled, H.titleAt, H.eggColor = auto, false, nil, eggCfg.Color
	-- Тайминги: обычное ~4.9 с, Legendary ~7 с, Secret ~7.3 с; автооткрытие примерно вдвое быстрее.
	local extra = ({ 0, 0, 0.25, 0.55, 0.8, 1.1, 1.5 })[H.bestIdx] or 0
	crackAt = (auto and 1.5 or 2.6) + extra * (auto and 0.5 or 1)
	local stagger = n > 1 and (auto and 0.1 or 0.16) or 0
	revealLength = crackAt + stagger * (n - 1) + (auto and 1.8 or 2.4) + (H.bestIdx >= 6 and (auto and 0.5 or 0.9) or 0)
	-- 9 яиц — сеткой 3×3 (по 3 в ряд), яйца поменьше
	local grid = n >= 9
	local ctx = { width = grid and 300 or 900 / n, auto = auto, stagger = stagger, eggCfg = eggCfg, disp = displays[sourceEgg], sky = eggCfg.World == "sky" and not grid, zoom = grid and 2.3 or 1, small = grid, grid = grid }
	for i, result in ipairs(batch) do
		H.eggs[i] = H.makeEgg(i, result, ctx)
	end
	if RunService:IsStudio() then
		print(string.format("[Hatch] auto=%s eggs=%d best=%s burst=%.2fs length=%.2fs", tostring(auto), n, H.bestName, crackAt, revealLength))
	end
end

-- Скорлупа лопается: яйцо убираем, осколки летят, питомец появляется, подпись готовится.
function H.burst(e)
	e.burst = true
	UISounds.Play("crack")
	local egg = e.egg
	if egg then
		local cf, s = egg.lastCF or CFrame.identity, egg.lastS or 1
		for _, sh in ipairs(e.shards) do
			local p = cf:PointToWorldSpace(sh.pos * s)
			local dir = cf:VectorToWorldSpace(sh.dir)
			sh.cf = CFrame.lookAt(p, p + dir) * sh.fix
			sh.vel = dir * sh.speed + Vector3.new(0, 3, 0) + H.CAM_DIR * 1.2
			sh.part.Transparency = 0
			sh.part.CFrame = sh.cf
		end
		egg.model:Destroy()
	end
	if e.pet then
		e.pet:ScaleTo(e.petScale * 0.05)
		e.pet:PivotTo(CFrame.identity)
		e.pet.Parent = e.wm
	end
	local def, result = e.def, e.result
	e.label.TextColor3 = e.rc
	e.label.Text = string.format("%s\n%s · ×%g\n%s", def.Name, def.Super and (def.SuperKey:upper() .. " SECRET") or def.Rarity:upper(), def.Multiplier, result.Deleted and "AUTO-DELETED" or ("OWNED ×" .. result.Count))
	stroke(e.label, INK, 2, 0)
	for _, sp in ipairs(e.sparks) do
		sp.frame.BackgroundColor3 = e.ri >= 7 and Color3.fromHSV((sp.angle / (math.pi * 2)) % 1, 0.45, 1) or (e.ri == 6 and H.GOLD:Lerp(WHITE, (sp.angle * 3) % 1 * 0.5) or e.rc)
	end
	for _, c in ipairs(e.confetti) do
		c.frame.Visible = true
	end
end

-- Момент самого редкого яйца: заголовок, общая вспышка, тряска и сигнал для RareFX.
function H.onBest(t)
	H.titled, H.titleAt = true, t
	UISounds.Play(H.bestIdx >= 6 and "rare" or "hatch")
	local best = H.bestName
	local superDef
	for _, e in ipairs(H.eggs) do
		local d = e.result and Config.Pets[e.result.Pet]
		if d and d.Super and (not superDef or d.Super > superDef.Super) then
			superDef = d
		end
	end
	revealTitle.Text = (superDef and string.format("%s %s SECRET! %s", Config.SuperTiers[superDef.Super].Icon, superDef.SuperKey:upper(), Config.FormatOdds(superDef.Odds)))
		or (best == "Secret" and "✨ SECRET! ✨") or (best == "Legendary" and "🌟 LEGENDARY! 🌟") or (#H.eggs == 3 and "TRIPLE HATCH!" or "YOU HATCHED!")
	revealTitle.TextColor3 = colors[best] or WHITE
	local strength = ({ 0.14, 0.18, 0.28, 0.4, 0.5, 0.62, 0.8 })[H.bestIdx] or 0.2
	flash.BackgroundColor3 = H.bestIdx >= 7 and WHITE or (H.bestIdx == 6 and H.GOLD or colors[best] or WHITE):Lerp(WHITE, 0.55)
	flash.BackgroundTransparency = 1 - strength
	TweenService:Create(flash, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	H.burstEvent:Fire()
end

-- До раскалывания: падение с отскоком, покачивание, удары-подпрыгивания, растущие трещины.
function H.stepIntact(e, t, dt, alpha)
	local a = t - e.dropAt
	local y, s, sy, roll, pitch, jx = 0, 1, 1, 0, 0, 0
	local T, prog, pulse = 0, 0, 0
	local yaw = math.sin(t * 0.9 + e.index) * 0.14
	if a < 0 then
		y = 9
	elseif a < e.dropDur then
		local u = a / e.dropDur
		y = (1 - H.bounceOut(u)) * 5.2
		yaw += (1 - H.smooth(u)) * 1.4
		if u < 0.36 then
			sy = 1.12 -- вытягивается в полёте
		end
		s = 0.75 + 0.25 * H.smooth(u / 0.36)
	end
	local ai = a - e.dropDur * 0.3636 -- первое касание «пола»
	if ai > 0 then
		sy *= 1 - 0.2 * math.exp(-7 * ai) * math.cos(17 * ai)
	end
	if a >= e.dropDur then
		T = math.clamp((t - e.antStart) / math.max(0.1, e.burstAt - e.antStart), 0, 1) ^ 1.3
		e.phase += dt * (6 + 15 * T)
		local damp = 1
		local share = 0.86 / #e.beats
		prog = 0.1 * T
		for _, bt in ipairs(e.beats) do
			local b = (t - bt) / e.beatDur
			if b >= 0 and b <= 1 then
				local by, bsy = H.beat(b)
				y += by
				sy *= bsy
				damp = 0.35
			end
			local hit = t - bt - e.beatDur * 0.25
			prog += share * H.smooth(hit / 0.16)
			if hit > 0 then
				pulse = math.max(pulse, math.exp(-hit * 5))
			end
		end
		local amp = (0.035 + 0.2 * T) * damp
		roll = math.sin(e.phase) * amp
		pitch = math.cos(e.phase * 0.73) * amp * 0.45
		local left = e.burstAt - t
		if left < 0.3 then
			-- Последние мгновения: дрожь, яйцо раздувается, трещины на максимуме.
			local k = 1 - left / 0.3
			prog = math.max(prog, 0.9 + 0.1 * k)
			jx = (H.rng:NextNumber() - 0.5) * 0.12 * k
			s *= 1 + 0.07 * k
			pulse = math.max(pulse, k)
		end
	end
	-- Свет из трещин: тёплый белый, с Epic постепенно окрашивается в цвет редкости.
	local hint = H.WARM
	if e.ri >= 7 then
		hint = H.WARM:Lerp(Color3.fromHSV((t * 0.9) % 1, 0.7, 1), math.min(1, T * 1.3))
	elseif e.ri >= 4 then
		hint = H.WARM:Lerp(e.ri == 6 and H.GOLD or e.rc, math.min(1, T * 1.2))
	end
	local appear = H.smooth(a / 0.35)
	local hs = 190 + 50 * T + 40 * pulse
	for k, f in ipairs(e.halo) do
		local size = hs * e.haloSizes[k]
		f.Size = UDim2.fromOffset(size, size)
		f.BackgroundColor3 = H.eggColor:Lerp(hint, e.ri >= 4 and T * 0.7 or T * 0.25)
		f.BackgroundTransparency = 1 - ({ 0.1, 0.13, 0.17 })[k] * appear * alpha * (1 + 0.6 * T + 0.5 * pulse)
	end
	local egg = e.egg
	if egg then
		local sq = Vector3.new(1 / math.sqrt(sy), sy, 1 / math.sqrt(sy))
		local ry = egg.radii.Y
		-- Опора качания — низ яйца.
		local cf = CFrame.new(jx, y - ry, 0) * CFrame.Angles(pitch, yaw, roll) * CFrame.new(0, ry * sy * s, 0)
		H.applyEgg(egg, cf, s, sq, prog, 0.01 + 0.022 * prog + 0.008 * pulse, hint)
	end
end

-- После раскалывания: осколки, питомец, лучи, волна, искры, конфетти, подписи.
function H.stepOpened(e, t, dt, alpha, lift)
	local age = t - e.burstAt
	for _, sh in ipairs(e.shards) do
		if not sh.done then
			sh.vel -= Vector3.new(0, 16 * dt, 0)
			sh.cf = (sh.cf + sh.vel * dt) * CFrame.fromAxisAngle(sh.axis, sh.spin * dt)
			sh.part.CFrame = sh.cf
			local fade = math.clamp((age - 0.65) / 0.5, 0, 1)
			sh.part.Transparency = fade
			if fade >= 1 then
				sh.done = true
				sh.part.CFrame = CFrame.new(0, -100, 0)
			end
		end
	end
	local pet = e.pet
	if pet then
		local u = math.clamp(age / 0.6, 0, 1)
		local pop = math.max(0.05, H.backOut(u, 2.4))
		pet:ScaleTo(e.petScale * pop * (1 - 0.1 * lift))
		local spinIn = 1 - (1 - math.clamp(age / 1, 0, 1)) ^ 3
		local yaw = -math.pi * 2 * (1 - spinIn) + math.sin(age * 1.1) * 0.3
		pet:PivotTo(CFrame.new(0, math.sin(age * 1.8) * 0.09 + lift * 0.3 + 0.12 * H.smooth(age / 0.6), 0) * CFrame.Angles(0, yaw, 0))
	end
	local hs = 230 + 90 * H.smooth(age / 0.8) + math.sin(age * 3) * 8
	local boost = 1 + 0.8 * (1 - H.smooth(age / 0.6))
	for k, f in ipairs(e.halo) do
		local size = hs * e.haloSizes[k]
		f.Size = UDim2.fromOffset(size, size)
		f.BackgroundColor3 = e.ri >= 7 and Color3.fromHSV((t * 0.5 + k * 0.12) % 1, 0.45, 1) or (e.ri == 6 and H.GOLD or e.rc)
		f.BackgroundTransparency = 1 - ({ 0.16, 0.2, 0.26 })[k] * alpha * boost
	end
	if e.rays then
		e.rays.Visible = true
		local grow = 1 - (1 - math.clamp(age / 0.7, 0, 1)) ^ 3
		local size = (300 + 60 * (e.ri - 3)) * grow
		e.rays.Size = UDim2.fromOffset(size, size)
		e.rays.Rotation = age * (e.ri >= 6 and 40 or 26)
		local fade = math.clamp((revealLength - t) / 0.6, 0, 1)
		local strength = (e.ri >= 6 and 0.95 or 0.8) * math.clamp(1.2 - age / 3, 0.65, 1)
		for k, bar in ipairs(e.rayBars) do
			bar.BackgroundTransparency = 1 - fade * strength
			if e.ri >= 7 then
				bar.BackgroundColor3 = Color3.fromHSV((t * 0.4 + k / #e.rayBars) % 1, 0.55, 1)
			end
		end
	end
	for _, rg in ipairs(e.rings) do
		local u = math.clamp((age - rg.delay) / 0.55, 0, 1)
		local active = age >= rg.delay and u < 1
		rg.frame.Visible = active
		if active then
			local size = 40 + rg.max * (1 - (1 - u) ^ 3)
			rg.frame.Size = UDim2.fromOffset(size, size)
			rg.stroke.Transparency = u * u
			rg.stroke.Thickness = rg.thick * (1 - 0.7 * u)
		end
	end
	local fu = age / 0.35
	e.flashDot.Visible = fu < 1
	if fu < 1 then
		local size = 80 + 240 * (1 - (1 - fu) ^ 2)
		e.flashDot.Size = UDim2.fromOffset(size, size)
		e.flashDot.BackgroundTransparency = 0.05 + 0.95 * fu
	end
	local su = math.clamp(age / 0.85, 0, 1)
	for _, sp in ipairs(e.sparks) do
		local radius = 40 + sp.reach * (1 - (1 - su) ^ 3)
		sp.frame.Position = UDim2.fromOffset(e.cx + math.cos(sp.angle) * radius, e.cy + math.sin(sp.angle) * radius + su * su * 40)
		sp.frame.BackgroundTransparency = su * su
		sp.frame.Rotation = age * 100
	end
	for _, c in ipairs(e.confetti) do
		if not c.done then
			c.vel = (c.vel + Vector2.new(0, 640 * dt)) * (1 - 1.2 * dt)
			c.pos += c.vel * dt
			c.frame.Position = UDim2.fromOffset(c.pos.X, c.pos.Y)
			c.frame.Size = UDim2.fromOffset(math.max(1, c.w * math.abs(math.cos(age * c.flip))), c.h)
			c.frame.Rotation += c.spin * dt
			c.frame.BackgroundTransparency = math.clamp((age - 1.1) / 0.6, 0, 1)
			if age > 1.7 then
				c.done = true
				c.frame.Visible = false
			end
		end
	end
	local la = age - 0.25
	e.label.TextTransparency = math.max(1 - H.smooth(la / 0.25), lift)
	e.labelScale.Scale = la > 0 and math.max(0.05, H.backOut(la / 0.4, 2.6)) or 0.05
	if e.newTag then
		local na = age - 0.55
		e.newTag.Visible = na > 0 and lift < 0.95
		if na > 0 then
			e.newScale.Scale = math.max(0.05, H.backOut(na / 0.35, 3)) * (1 + 0.06 * math.sin(age * 6))
			e.newTag.Rotation = 12 + math.sin(age * 4) * 5
		end
	end
end

-- Геймпасс Fast Hatch: вся анимация открытия идёт в 3 раза быстрее.
local function hatchSpeed()
	return player:GetAttribute("Pass_FastHatch") and 3 or 1
end
function H.step(dt)
	local t = (os.clock() - started) * hatchSpeed()
	dt *= hatchSpeed()
	dt = math.min(dt, 1 / 20)
	local fadeIn = H.smooth(t / 0.4)
	local fadeOut = H.smooth((revealLength - t) / 0.5)
	local alpha = math.min(fadeIn, fadeOut)
	local lift = 1 - fadeOut -- лёгкое «уплывание» в конце
	dim.BackgroundTransparency = 1 - 0.6 * alpha
	for _, f in ipairs(H.vignette) do
		f.BackgroundTransparency = 1 - 0.85 * alpha
	end
	revealTitle.TextTransparency = 1 - alpha
	for _, e in ipairs(H.eggs) do
		if not e.burst and t >= e.burstAt then
			H.burst(e)
			if not H.titled and e.ri >= H.bestIdx then
				H.onBest(t)
			end
		end
		if e.burst then
			H.stepOpened(e, t, dt, alpha, lift)
		else
			H.stepIntact(e, t, dt, alpha)
		end
	end
	local postAge = H.titleAt and t - H.titleAt or -1
	H.titleScale.Scale = postAge >= 0 and 1 + 0.45 * math.exp(-postAge * 7) * math.cos(postAge * 14) or 1
	if H.bestIdx >= 6 and postAge >= 0 and postAge < 0.5 then
		local k = (1 - postAge / 0.5) * (H.bestIdx >= 7 and 10 or 7)
		reveal.Position = UDim2.new(0.5, math.sin(postAge * 70) * k, 0.5, math.cos(postAge * 61) * k)
	else
		reveal.Position = UDim2.fromScale(0.5, 0.5)
	end
	if H.bestIdx >= 7 and postAge >= 0 then
		revealTitle.TextColor3 = Color3.fromHSV((t * 0.6) % 1, 0.5, 1)
	end
	if t > revealLength then
		reveal.Position = UDim2.fromScale(0.5, 0.5)
		reveal.Visible = false
		dim.Visible = false
		revealTitle.TextColor3 = WHITE
		revealTitle.TextTransparency = 0
		H.titleScale.Scale = 1
		H.cleanup()
		-- не закрываем окно, которое игрок открыл во время анимации
		if player:GetAttribute("UIScreen") == "hatch" then
			player:SetAttribute("UIScreen", "")
		end
	end
end

RS:WaitForChild("GameHatched").OnClientEvent:Connect(function(batch, sourceEgg)
	-- Без анимации RareFX показывает свой эффект сразу (defer — чтобы он успел подписаться).
	if type(batch) ~= "table" or #batch < 1 or #batch > 9 or not displays[sourceEgg] then
		task.defer(H.burstEvent.Fire, H.burstEvent)
		return
	end
	for _, result in ipairs(batch) do
		if type(result) ~= "table" or not Config.Pets[result.Pet] then
			task.defer(H.burstEvent.Fire, H.burstEvent)
			return
		end
	end
	local auto = autoEgg == sourceEgg
	hide()
	dismissed = not auto and sourceEgg or nil
	player:SetAttribute("UIScreen", "hatch")
	bestIdx = 1
	local bestName = "Common"
	for _, result in ipairs(batch) do
		local rarity = Config.Pets[result.Pet].Rarity
		local ri = RARITY_ORDER[rarity] or 1
		if ri > bestIdx then
			bestIdx, bestName = ri, rarity
		end
	end
	H.bestIdx, H.bestName = bestIdx, bestName
	revealStroke.Color = Config.Eggs[sourceEgg].Color
	-- Яйца Sky Isles открываются на пастельном фоне-небе, каждое на облачке, искры радужные.
	local skyHatch = Config.Eggs[sourceEgg].World == "sky"
	dim.BackgroundColor3 = skyHatch and WHITE or Color3.fromRGB(8, 6, 20) -- у неба цвет даёт градиент
	dim.BackgroundTransparency = 1
	dimGrad.Enabled = skyHatch
	for _, f in ipairs(H.vignette) do
		f.BackgroundColor3 = skyHatch and Color3.fromRGB(150, 120, 215) or Color3.new(0, 0, 0)
		f.BackgroundTransparency = 1
	end
	revealTitleStroke.Color = skyHatch and Color3.fromRGB(150, 110, 220) or INK
	H.start(batch, sourceEgg, auto)
	started = os.clock()
	finished = false
	busy = started + revealLength / hatchSpeed()
	revealTitle.Text = #batch == 9 and "NINE EGGS…" or #batch == 3 and "THREE EGGS…" or "OPENING…"
	revealTitle.TextColor3 = WHITE
	H.titleScale.Scale = 1
	reveal.Visible = true
	dim.Visible = true
	if auto then
		autoCount += #batch
	end
end)

local scan = 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		local size = camera.ViewportSize
		-- телефоны (низкий экран): окно крупнее, украшения рамки могут чуть уйти за край — кнопки важнее
		local small = size.Y < 520
		setCompact(small)
		local padY = small and 6 or 60
		scale.Scale = currentSkin and math.min(1, (size.X - 28) / 800, (size.Y - padY) / (small and 560 or 830)) or math.min(1, (size.X - 28) / 660, (size.Y - padY) / (small and 512 or 664))
		revealScale.Scale = math.min(1, (size.X - 28) / 900, (size.Y - 40) / 520)
	end
	scan += dt
	if scan > 0.15 then
		scan = 0
		refresh()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local nearest, distance
		if root then
			for id, entry in pairs(displays) do
				local offset = root.Position - entry.base.Position
				local d = Vector2.new(offset.X, offset.Z).Magnitude - entry.radius
				local reach = (mode == "egg" and eggId == id or autoEgg == id) and 6 or 2.2
				local heightOk = math.abs(offset.Y) < entry.radius * 2 + 4
				-- Яйцо на широком/высоком постаменте (вулкан, космос, Frozen): до самого яйца не дотянуться,
				-- поэтому считаем расстояние от края постамента и разрешаем стоять у его подножия.
				local stand = entry.stand
				if stand and stand.Parent then
					local cf, sz = stand:GetBoundingBox()
					local standR = math.min(math.max(sz.X, sz.Z) / 2, 14)
					local ds = Vector2.new(root.Position.X - cf.Position.X, root.Position.Z - cf.Position.Z).Magnitude - standR
					if ds < d then
						d = ds
					end
					local bottom = cf.Position.Y - sz.Y / 2
					heightOk = heightOk or (root.Position.Y > bottom - 2 and root.Position.Y < bottom + 10)
				end
				if d < reach and heightOk and (not distance or d < distance) then
					nearest, distance = id, d
				end
			end
		end
		-- Автооткрытие работает, пока игрок стоит у этого яйца.
		if autoEgg and nearest ~= autoEgg then
			stopAuto()
		end
		if autoEgg and not reveal.Visible and os.clock() > busy and os.clock() - lastAuto > 0.8 then
			local cost = Config.Eggs[autoEgg].Cost
			if coins.Value < cost then
				stopAuto()
			else
				eggId = autoEgg
				lastAuto = os.clock()
				hatch(coins.Value >= cost * 3 and 3 or 1)
			end
		end
		if not nearest then
			dismissed = nil
			if mode == "egg" then
				hide()
				dismissed = nil
			end
		elseif nearest ~= dismissed and ((player:GetAttribute("UIScreen") or "") == "" or mode == "egg") and not reveal.Visible and not autoEgg then
			showEgg(nearest)
		end
	end
	if reveal.Visible then
		H.step(dt)
	end
end)
