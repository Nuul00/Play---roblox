-- Меню яйца: питомцы с шансами, открытие ×1 / ×3, автооткрытие и автоудаление по видам.
-- Цены и броски проверяет сервер (GameShopBuy); клиент только показывает и отправляет запросы.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Config = require(RS:WaitForChild("GameConfig"))
local PetVisuals = require(RS:WaitForChild("PetVisuals"))
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

local function fmt(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function corner(f, r)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, r or 16)
end
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
local single = button(panel, "", 18, 598, 198, 52, Color3.fromRGB(130, 90, 220))
local triple = button(panel, "", 226, 598, 210, 52, Color3.fromRGB(240, 140, 70))
local auto = button(panel, "", 446, 598, 196, 52, Color3.fromRGB(70, 170, 110))

-- Облачный пастельный стиль окна для яиц Sky Isles: светлый фон с градиентом розовый → небесный,
-- белая обводка, пастельные кнопки и ячейки. Для остальных миров окно остаётся тёмным.
local PASTEL_BG = ColorSequence.new(Color3.fromRGB(255, 226, 244), Color3.fromRGB(200, 228, 255))
local panelGrad = Instance.new("UIGradient", panel)
panelGrad.Rotation = 90
panelGrad.Color = PASTEL_BG
panelGrad.Enabled = false
local DARK_PANEL = panel.BackgroundColor3
local BUTTON_COLORS = {
	dark = { single = Color3.fromRGB(130, 90, 220), triple = Color3.fromRGB(240, 140, 70), auto = Color3.fromRGB(70, 170, 110) },
	sky = { single = Color3.fromRGB(165, 140, 255), triple = Color3.fromRGB(255, 140, 200), auto = Color3.fromRGB(95, 195, 255) },
}
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
	auto.BackgroundColor3 = set.auto
	gallery.ScrollBarImageColor3 = sky and Color3.fromRGB(170, 140, 255) or Color3.fromRGB(205, 150, 255)
end

-- Плашка автооткрытия: видна, пока режим включён, даже когда окно скрыто анимацией.
local autoChip = box(gui, 0, 0, 300, 46, Color3.fromRGB(40, 140, 90))
autoChip.AnchorPoint = Vector2.new(0.5, 0)
autoChip.Position = UDim2.new(0.5, 0, 0, 6)
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
	subtitle.Text = string.format("%d PETS  ·  💰 %s EACH", #egg.Pool, fmt(egg.Cost))
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
	for _, pair in ipairs({ { single, 1 }, { triple, 3 } }) do
		local b, n = pair[1], pair[2]
		local affordable = coins.Value >= egg.Cost * n
		b.Text = waiting and "OPENING…" or string.format("OPEN ×%d\n💰 %s", n, fmt(egg.Cost * n))
		b.Active = affordable and not waiting and not autoEgg
		b.AutoButtonColor = b.Active
		b.BackgroundTransparency = b.Active and 0 or 0.45
	end
	local on = autoEgg == eggId
	auto.Text = on and "AUTO: ON\ntap to stop" or "AUTO OPEN\n×3 when possible"
	auto.BackgroundColor3 = on and Color3.fromRGB(220, 70, 90) or (skyTheme and BUTTON_COLORS.sky.auto or BUTTON_COLORS.dark.auto)
end

local function hatch(n)
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
auto.Activated:Connect(function()
	if autoEgg == eggId then
		stopAuto()
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
		local name = label(cell, def.Name, 6, cellH - 42, 188, 18, 14, WHITE, Enum.Font.FredokaOne)
		stroke(name, INK, 1.5, 0)
		local toggle = button(cell, "", 8, cellH - 22, 184, 18)
		toggle.TextSize = 11
		toggle.Font = Enum.Font.GothamBold
		toggle.Activated:Connect(function()
			action:FireServer("autodelete", entry.Pet)
		end)
		table.insert(cells, { id = entry.Pet, toggle = toggle, owned = owned, frame = cell })
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
		local zone = egg.World == "neon" and world:WaitForChild("NeonCity") or egg.World == "sky" and world:WaitForChild("SkyIsles") or world
		local stand = zone:WaitForChild("EggStand" .. id, 60)
		if not stand then
			return
		end
		while not stand:GetAttribute("EggReady") do
			stand.AttributeChanged:Wait()
		end
		local display = stand:WaitForChild("EggDisplay")
		local size = display:GetExtentsSize()
		displays[id] = { model = display, base = display:GetPivot(), radius = math.max(size.X, size.Z) / 2 }
	end)
end
RS:WaitForChild("GameHatched").OnClientEvent:Connect(function(batch, sourceEgg)
	if type(batch) ~= "table" or #batch < 1 or #batch > 3 or not displays[sourceEgg] then
		return
	end
	for _, result in ipairs(batch) do
		if not Config.Pets[result.Pet] then
			return
		end
	end
	local auto = autoEgg == sourceEgg
	hide()
	dismissed = not auto and sourceEgg or nil
	player:SetAttribute("UIScreen", "hatch")
	revealArea:ClearAllChildren()
	results, scenes, models, resultLabels, glows = batch, {}, {}, {}, {}
	sparks = {}
	rarityIdx, rayHolders, bestIdx = {}, {}, 1
	for i, result in ipairs(batch) do
		rarityIdx[i] = RARITY_ORDER[Config.Pets[result.Pet].Rarity] or 1
		bestIdx = math.max(bestIdx, rarityIdx[i])
	end
	revealStroke.Color = Config.Eggs[sourceEgg].Color
	-- Яйца Sky Isles открываются на пастельном фоне-небе, каждое на облачке, искры радужные.
	local skyHatch = Config.Eggs[sourceEgg].World == "sky"
	dim.BackgroundColor3 = skyHatch and WHITE or Color3.fromRGB(8, 6, 20) -- у неба цвет даёт градиент
	dim.BackgroundTransparency = skyHatch and 0.3 or 0.45
	dimGrad.Enabled = skyHatch
	revealTitleStroke.Color = skyHatch and Color3.fromRGB(150, 110, 220) or INK
	local width = 900 / #batch
	for i = 1, #batch do
		local x = (i - 1) * width
		local glow = Instance.new("Frame")
		glow.BackgroundColor3 = WHITE
		glow.BackgroundTransparency = 1
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.fromOffset(x + width / 2, 160)
		glow.Size = UDim2.fromOffset(250, 250)
		glow.Parent = revealArea
		corner(glow, 125)
		glows[i] = glow
		if rarityIdx[i] >= 4 then
			local holder = Instance.new("Frame")
			holder.BackgroundTransparency = 1
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.fromOffset(x + width / 2, 160)
			holder.Size = UDim2.fromOffset(10, 10)
			holder.Parent = revealArea
			for k = 0, 3 do
				local bar = Instance.new("Frame")
				bar.BorderSizePixel = 0
				bar.AnchorPoint = Vector2.new(0.5, 0.5)
				bar.Position = UDim2.fromScale(0.5, 0.5)
				bar.Size = UDim2.new(0, 18, 1, 0)
				bar.Rotation = k * 45
				bar.BackgroundColor3 = WHITE
				bar.BackgroundTransparency = 0
				bar.Parent = holder
				local g = Instance.new("UIGradient")
				g.Rotation = 90
				g.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0.15),
					NumberSequenceKeypoint.new(1, 1),
				})
				g.Parent = bar
			end
			holder.Visible = false
			rayHolders[i] = holder
		end
		if skyHatch then
			-- Облачко под яйцом: белый овал с пушистыми боками.
			for k, off in ipairs({ { 0, 0, 190, 54 }, { -70, -12, 90, 60 }, { 70, -10, 96, 62 }, { 0, -22, 110, 70 } }) do
				local puff = Instance.new("Frame")
				puff.AnchorPoint = Vector2.new(0.5, 0.5)
				puff.Position = UDim2.fromOffset(x + width / 2 + off[1], 286 + off[2])
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
		local scene = viewport(revealArea, x, 0, width, 330)
		scenes[i] = scene
		local egg = displays[sourceEgg].model:Clone()
		egg:ScaleTo(egg:GetScale() * 2.8 / egg:GetExtentsSize().Y)
		egg:PivotTo(CFrame.identity)
		egg.Parent = scene
		models[i] = egg
		modelScales[i] = egg:GetScale()
		local sparkCount = 12 + (rarityIdx[i] >= 3 and 10 or 0) + (rarityIdx[i] >= 5 and 14 or 0) + (rarityIdx[i] >= 7 and 14 or 0)
		for j = 1, sparkCount do
			local spark = Instance.new("Frame")
			spark.BorderSizePixel = 0
			spark.AnchorPoint = Vector2.new(.5, .5)
			spark.Size = UDim2.fromOffset(j % 3 == 0 and 7 or 4, j % 3 == 0 and 7 or 4)
			spark.BackgroundColor3 = skyHatch and SKY_SPARKS[j % #SKY_SPARKS + 1] or Config.Eggs[sourceEgg].Color
			spark.BackgroundTransparency = 1
			spark.ZIndex = 3
			spark.Parent = revealArea
			corner(spark, 4)
			table.insert(sparks, { frame = spark, angle = j * math.pi * 2 / sparkCount, center = x + width / 2, egg = i, reach = 150 + 28 * (rarityIdx[i] - 1) + (j % 3) * 22 })
		end
		resultLabels[i] = label(revealArea, "", x + 5, 334, width - 10, 100, 20, WHITE, Enum.Font.FredokaOne)
	end
	local extra = ({ 0, 0, 0.25, 0.55, 0.8, 1.1, 1.5 })[bestIdx]
	crackAt = (auto and 1.7 or 2.1) + (auto and extra * 0.5 or extra)
	revealLength = crackAt + (auto and 1.9 or 2.3) + (bestIdx >= 6 and 0.7 or 0)
	started = os.clock()
	finished = false
	busy = started + revealLength
	revealTitle.Text = #batch == 3 and "THREE EGGS…" or "OPENING…"
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
		scale.Scale = math.min(1, (size.X - 28) / 660, (size.Y - 60) / 664)
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
				if d < reach and math.abs(offset.Y) < entry.radius * 2 + 4 and (not distance or d < distance) then
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
		local t = os.clock() - started
		local crack = crackAt
		if t >= crack and not finished then
			finished = true
			local best = "Common"
			local order = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Mythic = 5, Legendary = 6, Secret = 7 }
			for i, result in ipairs(results) do
				models[i]:Destroy()
				models[i] = PetVisuals.Build(result.Pet)
				models[i].Parent = scenes[i]
				modelScales[i] = models[i]:GetScale()
				local def = Config.Pets[result.Pet]
				local c = colors[def.Rarity] or WHITE
				if (order[def.Rarity] or 1) > (order[best] or 1) then
					best = def.Rarity
				end
				local l = resultLabels[i]
				l.TextColor3 = c
				l.Text = string.format("%s\n%s · ×%g\n%s", def.Name, def.Rarity:upper(), def.Multiplier, result.Deleted and "AUTO-DELETED" or ("OWNED ×" .. result.Count))
				stroke(l, INK, 2, 0)
				glows[i].BackgroundColor3 = c
				glows[i].BackgroundTransparency = 0.45
				local ri = rarityIdx[i]
				for _, sp in ipairs(sparks) do
					if sp.egg == i then
						sp.frame.BackgroundColor3 = ri >= 7 and Color3.fromHSV((sp.angle / (math.pi * 2)) % 1, 0.45, 1) or c
					end
				end
				if rayHolders[i] then
					rayHolders[i].Visible = true
					for _, bar in ipairs(rayHolders[i]:GetChildren()) do
						if bar:IsA("Frame") then
							bar.BackgroundColor3 = c
						end
					end
				end
				TweenService:Create(glows[i], TweenInfo.new(0.9, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.82 }):Play()
				TweenService:Create(glows[i], TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(320, 320) }):Play()
			end
			if bestIdx >= 3 then
				local strength = ({ 0, 0, 0.22, 0.38, 0.5, 0.62, 0.8 })[bestIdx]
				flash.BackgroundColor3 = bestIdx >= 7 and WHITE or (colors[best] or WHITE):Lerp(WHITE, 0.55)
				flash.BackgroundTransparency = 1 - strength
				TweenService:Create(flash, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			end
			revealTitle.Text = (best == "Secret" and "✨ SECRET! ✨") or (best == "Legendary" and "🌟 LEGENDARY! 🌟") or (#results == 3 and "TRIPLE HATCH!" or "YOU HATCHED!")
			revealTitle.TextColor3 = colors[best] or WHITE
		end
		local function smooth(x)
			x = math.clamp(x, 0, 1)
			return x * x * (3 - 2 * x)
		end
		local fadeIn = smooth(t / 0.45)
		local fadeOut = smooth((revealLength - t) / 0.5)
		local alpha = math.min(fadeIn, fadeOut)
		dim.BackgroundTransparency = 1 - 0.55 * alpha
		revealTitle.TextTransparency = 1 - alpha
		for i, m in ipairs(models) do
			local lift = 1 - fadeOut -- лёгкое «уплывание» в конце
			if t < crack then
				local u = math.clamp((t - (i - 1) * 0.12) / crack, 0, 1)
				local arrive = 1 - (1 - math.clamp(u / .3, 0, 1)) ^ 5
				local tension = smooth((u - .3) / .7)
				local ri = rarityIdx[i] or 1
				local wobble = math.sin(t * (4 + 6 * tension + ri * 0.8) + i * 1.7) * tension * (0.7 + 0.12 * ri)
				local turn = math.pi * 2 * smooth(u / .85)
				m:ScaleTo(modelScales[i] * (.7 + .3 * arrive + .03 * tension * math.sin(t * 8)) * (0.94 + 0.06 * fadeIn))
				m:PivotTo(CFrame.new(0, (1 - arrive) * 1.2 + math.sin(t * 2.2 + i * 2) * .07, 0) * CFrame.Angles(.03 * wobble, turn, wobble * (.03 + .1 * tension)))
				glows[i].BackgroundColor3 = ri >= 3 and revealStroke.Color:Lerp(colors[Config.Pets[results[i].Pet].Rarity] or WHITE, tension) or revealStroke.Color
				glows[i].BackgroundTransparency = 1 - (.14 + .03 * ri) * tension * alpha
			else
				local age = t - crack
				local u = math.clamp(age / .7, 0, 1)
				local back = 1 + 1.9 * (u - 1) ^ 3 + .9 * (u - 1) ^ 2
				m:ScaleTo(modelScales[i] * math.max(.05, back) * (1 - .1 * lift))
				m:PivotTo(CFrame.new(0, math.sin(age * 1.6) * .06 + lift * .25, 0) * CFrame.Angles(0, -.4 * (1 - smooth(u)) + math.sin(age * 1.1) * .12, 0))
				resultLabels[i].TextTransparency = math.max(1 - smooth((age - .2) / .45), lift)
			end
		end
		for _, particle in ipairs(sparks) do
			local age = t - crack
			local u = math.clamp(age / .85, 0, 1)
			local radius = 40 + (particle.reach or 150) * (1 - (1 - u) ^ 3)
			particle.frame.Position = UDim2.fromOffset(particle.center + math.cos(particle.angle) * radius, 160 + math.sin(particle.angle) * radius + u * u * 40)
			particle.frame.BackgroundTransparency = age >= 0 and u * u or 1
			particle.frame.Rotation = age * 100
		end
		for _, g in ipairs(glows) do
			g.Rotation += dt * 40
		end
		local postAge = t - crack
		for i, holder in pairs(rayHolders) do
			if holder.Parent and postAge >= 0 then
				local grow = 1 - (1 - math.clamp(postAge / 0.7, 0, 1)) ^ 3
				local size = (300 + 70 * (rarityIdx[i] - 4)) * grow
				holder.Size = UDim2.fromOffset(size, size)
				holder.Rotation = postAge * 28
				local fade = math.clamp((revealLength - t) / 0.6, 0, 1)
				for _, bar in ipairs(holder:GetChildren()) do
					if bar:IsA("Frame") then
						bar.BackgroundTransparency = 1 - fade * 0.9 * math.clamp(1.2 - postAge / 3, 0.65, 1)
					end
				end
			end
		end
		if bestIdx >= 6 and postAge >= 0 and postAge < 0.5 then
			local k = (1 - postAge / 0.5) * 7
			reveal.Position = UDim2.new(0.5, math.sin(postAge * 70) * k, 0.5, math.cos(postAge * 61) * k)
		else
			reveal.Position = UDim2.fromScale(0.5, 0.5)
		end
		if bestIdx >= 7 and postAge >= 0 then
			revealTitle.TextColor3 = Color3.fromHSV((t * 0.6) % 1, 0.5, 1)
		end
		if t > revealLength then
			reveal.Position = UDim2.fromScale(0.5, 0.5)
			reveal.Visible = false
			dim.Visible = false
			revealTitle.TextColor3 = WHITE
			revealTitle.TextTransparency = 0
			revealArea:ClearAllChildren()
			models = {}
			player:SetAttribute("UIScreen", "")
		end
	end
end)
