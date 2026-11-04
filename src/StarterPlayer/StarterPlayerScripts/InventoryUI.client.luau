-- Инвентарь: вкладки «Питомцы», «Зелья», «Достижения».
-- Клиент только показывает и просит сервер (GameAction); проверки — на сервере.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local action = ReplicatedStorage:WaitForChild("GameAction")

local rarityColors = {
	Common = Color3.fromRGB(170, 175, 180),
	Uncommon = Color3.fromRGB(90, 200, 110),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 80, 160),
	Secret = Color3.fromRGB(30, 30, 30),
}
local dark = Color3.fromRGB(30, 30, 42)

local gui = Instance.new("ScreenGui")
gui.Name = "Inventory"
gui.ResetOnSpawn = false
gui.DisplayOrder = 24
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
	b.TextSize = 17
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color
	b.Parent = parent
	corner(b, 10)
	stroke(b, 2.5)
	return b
end

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.52)
window.Size = UDim2.fromOffset(780, 480)
window.BackgroundColor3 = Color3.fromRGB(40, 48, 70)
window.Visible = false
window.Parent = gui
corner(window, 20)
stroke(window, 4)
local scale = Instance.new("UIScale", window)
local title = label(window, "🎒 INVENTORY", UDim2.fromOffset(20, 8), UDim2.fromOffset(300, 44), 28, Color3.fromRGB(255, 230, 150))
title.TextXAlignment = Enum.TextXAlignment.Left
local close = button(window, "×", UDim2.new(1, -52, 0, 10), UDim2.fromOffset(40, 40), Color3.fromRGB(220, 70, 70))
close.TextSize = 28
close.Modal = true

local tabNames = { { "pets", "🐾 PETS" }, { "potions", "🧪 POTIONS" }, { "badges", "🏅 BADGES" } }
local tabButtons = {}
for i, t in ipairs(tabNames) do
	local b = button(window, t[2], UDim2.fromOffset(330 + (i - 1) * 132, 12), UDim2.fromOffset(124, 36), Color3.fromRGB(70, 80, 110))
	tabButtons[t[1]] = b
end
local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(16, 60)
body.Size = UDim2.fromOffset(748, 406)
body.Parent = window

local current = "pets"
local spinning = {}

local function viewport(parent, pos, size, petCode)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = pos
	view.Size = size
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.LightDirection = Vector3.new(-1, -1, -2)
	view.Parent = parent
	local wm = Instance.new("WorldModel", view)
	local model = PetVisuals.BuildCode(petCode)
	model.Parent = wm
	local _, ext = model:GetBoundingBox()
	local d = math.max(ext.X, ext.Y, ext.Z)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(d * 0.9, d * 0.5, -d * 1.6), Vector3.zero)
	cam.Parent = view
	view.CurrentCamera = cam
	table.insert(spinning, model)
end

-- code = id + ступень*1000 (обычный, золотой, алмазный, радужный).
local function count(code)
	local id, tier = ShopConfig.SplitPet(code)
	return player:GetAttribute(ShopConfig.OwnedAttr(id, tier)) or 0
end
local function codeMult(code)
	local id, tier = ShopConfig.SplitPet(code)
	return Config.GetPetMultiplier(id) * ShopConfig.VariantMult(tier)
end

-- ===== Питомцы =====
local function buildPets()
	local equipped = ShopConfig.ParseEquipped(player:GetAttribute("Equipped"))
	local equippedCount = {}
	for _, id in ipairs(equipped) do
		equippedCount[id] = (equippedCount[id] or 0) + 1
	end
	local header = label(body, string.format("Equipped %d / %d   ·   Team bonus x%g", #equipped, ShopConfig.MaxEquipped, math.floor((player:GetAttribute("PetBonus") or 1) * 100 + 0.5) / 100), UDim2.fromOffset(0, 0), UDim2.fromOffset(440, 36), 19)
	header.TextXAlignment = Enum.TextXAlignment.Left
	local best = button(body, "⭐ EQUIP BEST", UDim2.fromOffset(450, 0), UDim2.fromOffset(150, 36), Color3.fromRGB(70, 180, 90))
	local none = button(body, "UNEQUIP ALL", UDim2.fromOffset(608, 0), UDim2.fromOffset(140, 36), Color3.fromRGB(200, 90, 80))
	best.Activated:Connect(function()
		action:FireServer("best")
	end)
	none.Activated:Connect(function()
		action:FireServer("none")
	end)
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(0, 46)
	list.Size = UDim2.fromOffset(748, 360)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.Parent = body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(138, 168)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.Parent = list
	local ids = {}
	for id = 1, #Config.Pets do
		for tier = 0, #ShopConfig.Variants do
			local code = ShopConfig.PetCode(id, tier)
			if count(code) > 0 then
				table.insert(ids, code)
			end
		end
	end
	table.sort(ids, function(a, b)
		return codeMult(a) > codeMult(b)
	end)
	if #ids == 0 then
		label(body, "No pets yet — open an egg!", UDim2.fromOffset(0, 120), UDim2.fromOffset(748, 40), 24)
	end
	for _, id in ipairs(ids) do
		local baseId, tier = ShopConfig.SplitPet(id)
		local def = Config.Pets[baseId]
		local variant = ShopConfig.Variants[tier]
		local card = Instance.new("TextButton")
		card.Text = ""
		card.BackgroundColor3 = (equippedCount[id] or 0) > 0 and Color3.fromRGB(70, 120, 80) or Color3.fromRGB(58, 66, 92)
		card.Parent = list
		corner(card, 14)
		stroke(card, 3, variant and variant.Color or rarityColors[def.Rarity] or dark)
		viewport(card, UDim2.fromOffset(14, 4), UDim2.fromOffset(110, 92), id)
		label(card, (variant and (variant.Name .. " ") or "") .. def.Name, UDim2.fromOffset(4, 96), UDim2.fromOffset(130, 22), 15, variant and variant.Color:Lerp(Color3.new(1, 1, 1), 0.35) or nil)
		label(card, def.Rarity .. " · x" .. string.format("%g", codeMult(id)), UDim2.fromOffset(4, 118), UDim2.fromOffset(130, 18), 13, rarityColors[def.Rarity] == rarityColors.Secret and Color3.new(1, 1, 1) or rarityColors[def.Rarity])
		label(card, "own " .. count(id), UDim2.fromOffset(4, 140), UDim2.fromOffset(60, 20), 13, Color3.fromRGB(210, 210, 220), Enum.Font.GothamMedium)
		if (equippedCount[id] or 0) > 0 then
			local tag = label(card, "✔ x" .. equippedCount[id], UDim2.fromOffset(70, 140), UDim2.fromOffset(62, 20), 14, Color3.fromRGB(150, 255, 150))
			tag.TextXAlignment = Enum.TextXAlignment.Right
		end
		card.Activated:Connect(function()
			-- Клик: надеть ещё одного (если есть свободный экземпляр), иначе снять.
			local canAdd = #equipped < ShopConfig.MaxEquipped and (equippedCount[id] or 0) < count(id)
			if canAdd then
				action:FireServer("equip", id)
			elseif (equippedCount[id] or 0) > 0 then
				action:FireServer("unequip", id)
			else
				action:FireServer("equip", id)
			end
		end)
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#ids / 5) * 178)
end

-- ===== Зелья =====
local potionTimers = {}
local function buildPotions()
	label(body, "Potions last 5 minutes. Using another one adds more time.", UDim2.fromOffset(0, 0), UDim2.fromOffset(748, 30), 17, Color3.fromRGB(210, 215, 230), Enum.Font.GothamMedium)
	for i, name in ipairs(ShopConfig.PotionOrder) do
		local def = ShopConfig.Potions[name]
		local card = Instance.new("Frame")
		card.Position = UDim2.fromOffset((i - 1) * 252, 44)
		card.Size = UDim2.fromOffset(236, 330)
		card.BackgroundColor3 = Color3.fromRGB(58, 66, 92)
		card.Parent = body
		corner(card, 16)
		stroke(card, 3, def.Color)
		local bottle = Instance.new("Frame")
		bottle.AnchorPoint = Vector2.new(0.5, 0)
		bottle.Position = UDim2.new(0.5, 0, 0, 20)
		bottle.Size = UDim2.fromOffset(96, 96)
		bottle.BackgroundColor3 = def.Color
		bottle.Parent = card
		corner(bottle, 48)
		stroke(bottle, 3)
		label(bottle, def.Icon, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 48)
		label(card, def.Name, UDim2.fromOffset(0, 126), UDim2.new(1, 0, 0, 30), 22)
		label(card, def.Effect, UDim2.fromOffset(0, 156), UDim2.new(1, 0, 0, 24), 17, def.Color)
		label(card, "Owned: " .. (player:GetAttribute("Potion" .. name) or 0), UDim2.fromOffset(0, 186), UDim2.new(1, 0, 0, 24), 18, Color3.fromRGB(220, 225, 235), Enum.Font.GothamBold)
		potionTimers[name] = label(card, "", UDim2.fromOffset(0, 214), UDim2.new(1, 0, 0, 24), 17, Color3.fromRGB(150, 255, 150))
		local use = button(card, "USE", UDim2.fromOffset(28, 262), UDim2.fromOffset(180, 46), (player:GetAttribute("Potion" .. name) or 0) > 0 and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(110, 110, 120))
		use.Activated:Connect(function()
			action:FireServer("potion", name)
		end)
	end
	label(body, "Buy more potions at the Magnet Shop next to the kiosk.", UDim2.fromOffset(0, 380), UDim2.fromOffset(748, 24), 15, Color3.fromRGB(190, 200, 220), Enum.Font.GothamMedium)
end

-- ===== Достижения =====
local function buildBadges()
	local unlocked = 0
	for _, b in ipairs(ShopConfig.Badges) do
		if player:GetAttribute("Badge" .. b.Id) then
			unlocked += 1
		end
	end
	local header = label(body, string.format("Unlocked %d / %d   ·   Coin bonus x%.3f", unlocked, #ShopConfig.Badges, ShopConfig.BadgeBonus ^ unlocked), UDim2.fromOffset(0, 0), UDim2.fromOffset(748, 34), 19)
	header.TextXAlignment = Enum.TextXAlignment.Left
	for i, b in ipairs(ShopConfig.Badges) do
		local done = player:GetAttribute("Badge" .. b.Id) == true
		local value = math.min(player:GetAttribute(b.Stat) or 0, b.Goal)
		local row = Instance.new("Frame")
		row.Position = UDim2.fromOffset(((i - 1) % 2) * 378, 44 + math.floor((i - 1) / 2) * 118)
		row.Size = UDim2.fromOffset(368, 108)
		row.BackgroundColor3 = done and Color3.fromRGB(70, 110, 70) or Color3.fromRGB(58, 66, 92)
		row.Parent = body
		corner(row, 14)
		stroke(row, 3, done and Color3.fromRGB(255, 210, 80) or dark)
		local medal = Instance.new("Frame")
		medal.Position = UDim2.fromOffset(12, 16)
		medal.Size = UDim2.fromOffset(76, 76)
		medal.BackgroundColor3 = done and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(90, 95, 110)
		medal.Parent = row
		corner(medal, 38)
		stroke(medal, 3)
		label(medal, b.Icon, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 38)
		local n = label(row, b.Name .. (done and "  ✔" or ""), UDim2.fromOffset(100, 8), UDim2.fromOffset(260, 28), 20)
		n.TextXAlignment = Enum.TextXAlignment.Left
		local d = label(row, b.Desc .. " · x1.05 coins", UDim2.fromOffset(100, 36), UDim2.fromOffset(260, 22), 14, Color3.fromRGB(210, 215, 230), Enum.Font.GothamMedium)
		d.TextXAlignment = Enum.TextXAlignment.Left
		local barBack = Instance.new("Frame")
		barBack.Position = UDim2.fromOffset(100, 68)
		barBack.Size = UDim2.fromOffset(250, 20)
		barBack.BackgroundColor3 = Color3.fromRGB(35, 38, 52)
		barBack.Parent = row
		corner(barBack, 10)
		local bar = Instance.new("Frame")
		bar.Size = UDim2.fromScale(value / b.Goal, 1)
		bar.BackgroundColor3 = done and Color3.fromRGB(255, 210, 80) or Color3.fromRGB(90, 200, 120)
		bar.Parent = barBack
		corner(bar, 10)
		label(barBack, string.format("%d / %d", math.floor(value), b.Goal), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 13)
	end
end

local function render()
	body:ClearAllChildren()
	spinning = {}
	potionTimers = {}
	for name, b in pairs(tabButtons) do
		b.BackgroundColor3 = name == current and Color3.fromRGB(240, 160, 50) or Color3.fromRGB(70, 80, 110)
	end
	if current == "pets" then
		buildPets()
	elseif current == "potions" then
		buildPotions()
	else
		buildBadges()
	end
end
for name, b in pairs(tabButtons) do
	b.Activated:Connect(function()
		current = name
		render()
	end)
end

local function hide()
	window.Visible = false
	if player:GetAttribute("UIScreen") == "inventory" then
		player:SetAttribute("UIScreen", "")
	end
end
close.Activated:Connect(hide)
player.PlayerGui:WaitForChild("OpenInventory").Event:Connect(function()
	if window.Visible then
		hide()
	else
		player:SetAttribute("UIScreen", "inventory")
		window.Visible = true
		render()
	end
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	if player:GetAttribute("UIScreen") ~= "inventory" then
		window.Visible = false
	end
end)
local pending = false
player.AttributeChanged:Connect(function(name)
	if not window.Visible or pending then
		return
	end
	if name == "Equipped" or name == "PetBonus" or name:sub(1, 8) == "PetOwned" or name:sub(1, 7) == "PetGold" or name:sub(1, 10) == "PetDiamond" or name:sub(1, 10) == "PetRainbow" or name:sub(1, 6) == "Potion" or name:sub(1, 5) == "Badge" then
		pending = true
		task.defer(function()
			pending = false
			if window.Visible then
				render()
			end
		end)
	end
end)

local spin = 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		scale.Scale = math.clamp(math.min(camera.ViewportSize.X / 840, camera.ViewportSize.Y / 540), 0.35, 1)
	end
	if not window.Visible then
		return
	end
	spin += dt
	for _, m in ipairs(spinning) do
		if m.Parent then
			m:PivotTo(CFrame.Angles(0, spin * 0.8, 0))
		end
	end
	for name, l in pairs(potionTimers) do
		local left = (player:GetAttribute("PotionEnd" .. name) or 0) - os.time()
		l.Text = left > 0 and string.format("Active %d:%02d", left // 60, left % 60) or ""
	end
end)
