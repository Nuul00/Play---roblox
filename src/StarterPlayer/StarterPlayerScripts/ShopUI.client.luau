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
local gallery = Instance.new("Frame")
gallery.BackgroundTransparency = 1
gallery.Position = UDim2.fromOffset(18, 112)
gallery.Size = UDim2.fromOffset(624, 456)
gallery.Parent = panel
local hint = label(panel, "Tap ✓ KEEP on a pet to auto-delete future copies of it (owned pets stay).", 18, 572, 624, 18, 12, Color3.fromRGB(205, 190, 225), Enum.Font.GothamMedium)
local single = button(panel, "", 18, 598, 198, 52, Color3.fromRGB(130, 90, 220))
local triple = button(panel, "", 226, 598, 210, 52, Color3.fromRGB(240, 140, 70))
local auto = button(panel, "", 446, 598, 196, 52, Color3.fromRGB(70, 170, 110))

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
		cell.toggle.BackgroundColor3 = deleting and Color3.fromRGB(190, 60, 85) or Color3.fromRGB(60, 80, 120)
		cell.frame.BackgroundTransparency = deleting and 0.45 or 0
		local owned = player:GetAttribute("PetOwned" .. cell.id) or 0
		cell.owned.Text = owned > 0 and ("OWNED ×" .. owned) or "NEW!"
		cell.owned.TextColor3 = owned > 0 and Color3.fromRGB(205, 195, 225) or Color3.fromRGB(255, 225, 90)
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
	auto.BackgroundColor3 = on and Color3.fromRGB(220, 70, 90) or Color3.fromRGB(70, 170, 110)
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
	headerGrad.Color = ColorSequence.new(egg.Color:Lerp(WHITE, 0.15), egg.Color:Lerp(Color3.new(0, 0, 0), 0.35))
	panelStroke.Color = egg.Color
	gallery:ClearAllChildren()
	cells = {}
	local count = #egg.Pool
	local cols = 3
	local cellW, cellH = 200, count > 6 and 146 or 220
	for i, entry in ipairs(egg.Pool) do
		local def = Config.Pets[entry.Pet]
		local c = colors[def.Rarity] or colors.Common
		local cell = box(gallery, (i - 1) % cols * 212, math.floor((i - 1) / cols) * (cellH + 9), cellW, cellH, Color3.fromRGB(46, 38, 72))
		stroke(cell, c, (def.Rarity == "Secret" or def.Rarity == "Legendary") and 3 or 2, 0)
		local grad = Instance.new("UIGradient", cell)
		grad.Color = ColorSequence.new(c:Lerp(Color3.fromRGB(46, 38, 72), 0.55), Color3.fromRGB(36, 30, 58))
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
		label(cell, string.format("×%g 💰", def.Multiplier), 112, 56, 84, 20, 14, Color3.fromRGB(255, 220, 140), Enum.Font.FredokaOne)
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
local reveal = box(gui, 0, 0, 760, 380, Color3.fromRGB(30, 24, 52))
reveal.AnchorPoint = Vector2.new(0.5, 0.5)
reveal.Position = UDim2.fromScale(0.5, 0.5)
reveal.Visible = false
local revealStroke = stroke(reveal, Color3.fromRGB(239, 167, 236), 3, 0)
local revealScale = Instance.new("UIScale", reveal)
local revealTitle = label(reveal, "", 15, 10, 730, 44, 28, WHITE, Enum.Font.FredokaOne)
stroke(revealTitle, INK, 2.5, 0)
local revealArea = Instance.new("Frame")
revealArea.BackgroundTransparency = 1
revealArea.Position = UDim2.fromOffset(12, 60)
revealArea.Size = UDim2.fromOffset(736, 305)
revealArea.Parent = reveal
local results, scenes, models, resultLabels, glows = {}, {}, {}, {}, {}
local started, finished, revealLength = 0, false, 4.1
local displays = {}
local world = workspace:WaitForChild("CoinSpeedWorld")
for id, egg in ipairs(Config.Eggs) do
	local zone = egg.World == "neon" and world:WaitForChild("NeonCity") or world
	local stand = zone:WaitForChild("EggStand" .. id)
	if id <= 3 then
		while not stand:GetAttribute("EggReady") do
			stand.AttributeChanged:Wait()
		end
	end
	local display = stand:WaitForChild("EggDisplay")
	local size = display:GetExtentsSize()
	displays[id] = { model = display, base = display:GetPivot(), radius = math.max(size.X, size.Z) / 2 }
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
	revealStroke.Color = Config.Eggs[sourceEgg].Color
	local width = 736 / #batch
	for i = 1, #batch do
		local x = (i - 1) * width
		local glow = Instance.new("Frame")
		glow.BackgroundColor3 = WHITE
		glow.BackgroundTransparency = 1
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.fromOffset(x + width / 2, 100)
		glow.Size = UDim2.fromOffset(170, 170)
		glow.Parent = revealArea
		corner(glow, 85)
		glows[i] = glow
		local scene = viewport(revealArea, x, 0, width, 210)
		scenes[i] = scene
		local egg = displays[sourceEgg].model:Clone()
		egg:ScaleTo(egg:GetScale() * 2.8 / egg:GetExtentsSize().Y)
		egg:PivotTo(CFrame.identity)
		egg.Parent = scene
		models[i] = egg
		resultLabels[i] = label(revealArea, "", x + 5, 214, width - 10, 86, 15, WHITE, Enum.Font.FredokaOne)
	end
	revealLength = auto and 3.5 or 4.1
	started = os.clock()
	finished = false
	busy = started + revealLength
	revealTitle.Text = #batch == 3 and "THREE EGGS…" or "OPENING…"
	reveal.Visible = true
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
		revealScale.Scale = math.min(1, (size.X - 28) / 760, (size.Y - 60) / 380)
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
		local crack = revealLength * 0.36
		if t >= crack and not finished then
			finished = true
			local best = "Common"
			local order = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Mythic = 5, Legendary = 6, Secret = 7 }
			for i, result in ipairs(results) do
				models[i]:Destroy()
				models[i] = PetVisuals.Build(result.Pet)
				models[i].Parent = scenes[i]
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
				glows[i].BackgroundTransparency = 0.55
				TweenService:Create(glows[i], TweenInfo.new(0.6, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(200, 200) }):Play()
			end
			revealTitle.Text = (best == "Secret" and "✨ SECRET! ✨") or (best == "Legendary" and "🌟 LEGENDARY! 🌟") or (#results == 3 and "TRIPLE HATCH!" or "YOU HATCHED!")
			revealTitle.TextColor3 = colors[best] or WHITE
		end
		for i, m in ipairs(models) do
			if t < crack then
				m:PivotTo(CFrame.Angles(0, t * 3, math.sin(t * 25 + i) * 0.12 * (t / crack)))
			else
				m:PivotTo(CFrame.Angles(0, math.sin(t * 1.5) * 0.4, 0))
			end
		end
		for _, g in ipairs(glows) do
			g.Rotation += dt * 40
		end
		if t > revealLength then
			reveal.Visible = false
			revealTitle.TextColor3 = WHITE
			revealArea:ClearAllChildren()
			models = {}
			player:SetAttribute("UIScreen", "")
		end
	end
end)
