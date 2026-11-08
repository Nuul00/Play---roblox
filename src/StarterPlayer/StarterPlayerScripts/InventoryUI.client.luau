-- Инвентарь: вкладки «Питомцы», «Зелья», «Достижения».
-- Клиент только показывает и просит сервер (GameAction); проверки — на сервере.
-- короткая запись множителя команды: x50.5K вместо x50504.1 (фидбэк 2026-11)
local function teamText(v: number): string
	if v < 1000 then
		return tostring(math.floor(v * 100 + 0.5) / 100)
	end
	return require(game:GetService("ReplicatedStorage"):WaitForChild("NumberFormat")).Short(v)
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local PetAbilities = require(ReplicatedStorage:WaitForChild("PetAbilities"))
local action = ReplicatedStorage:WaitForChild("GameAction")

local rarityColors = {
	Common = Color3.fromRGB(170, 175, 180),
	Uncommon = Color3.fromRGB(90, 200, 110),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 80, 160),
	Secret = Color3.fromRGB(190, 120, 255),
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

-- окно в общем стиле UIKit (звёздная витрина, плашка-заголовок, глянцевые вкладки)
local K = require(ReplicatedStorage:WaitForChild("UIKit"))
local window, close, scale = K.window(gui, "InventoryWindow", 800, 500, "🎒 INVENTORY", K.GREEN, 290)
window.Position = UDim2.fromScale(0.5, 0.53)
do
	-- плашка заголовка — слева, вкладки справа от неё
	local pill = window:FindFirstChild("TitlePill")
	if pill then
		pill.Position = UDim2.fromOffset(22, -30)
	end
	for _, c in ipairs(window:GetChildren()) do
		-- «ленточки» по бокам плашки рассчитаны на плашку по центру — убираем
		if c:IsA("Frame") and c.Size == UDim2.fromOffset(68, 42) then
			c.Visible = false
		end
	end
end

local tabNames = { { "pets", "🐾 PETS" }, { "potions", "🧪 POTIONS" }, { "badges", "🏅 BADGES" }, { "titles", "👑 TITLES" } }
local tabButtons = {}
local tabSet = {}
for i, t in ipairs(tabNames) do
	local b, _, set = K.button(window, t[2], UDim2.fromOffset(330 + (i - 1) * 104, 16), UDim2.fromOffset(98, 38), K.GRAY, 15)
	tabButtons[t[1]] = b
	tabSet[t[1]] = set
end
local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(26, 74)
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
	-- с уровнем вида питомца (ShopConfig.PetLevel): как считает сервер для бонуса команды
	return Config.GetPetMultiplier(id) * ShopConfig.VariantMult(tier) * ShopConfig.LevelMult(ShopConfig.PetLevelOf(player, id))
end

-- ===== Питомцы =====
local function buildPets()
	local equipped = ShopConfig.ParseEquipped(player:GetAttribute("Equipped"))
	local equippedCount = {}
	for _, id in ipairs(equipped) do
		equippedCount[id] = (equippedCount[id] or 0) + 1
	end
	-- Размер команды растёт с ребёрсами: сервер пишет его в атрибут MaxEquipped.
	local maxEquipped = player:GetAttribute("MaxEquipped") or ShopConfig.MaxEquipped
	-- шапка: плашки «надето» и «бонус команды», строка способностей, кнопки
	local function chip(x, w, icon, text, colA, colB)
		local c = K.frame(body, UDim2.fromOffset(x, 0), UDim2.fromOffset(w, 34), Color3.new(1, 1, 1), 17)
		K.grad(c, colA, colB)
		K.stroke(c, K.INK, 2.5)
		local t = K.text(c, icon .. " " .. text, UDim2.fromOffset(10, 3), UDim2.new(1, -20, 1, -6), 18, nil, 2)
		return c, t
	end
	chip(0, 168, "🐾", string.format("EQUIPPED %d/%d", #equipped, maxEquipped), Color3.fromRGB(120, 200, 255), Color3.fromRGB(50, 110, 220))
	chip(176, 190, "💰", "TEAM x" .. teamText(player:GetAttribute("PetBonus") or 1), Color3.fromRGB(255, 220, 110), Color3.fromRGB(230, 140, 30))
	-- Строка способностей команды; при наведении на карточку показывает способность питомца.
	local teamText = PetAbilities.TeamText(player)
	if teamText == "" then
		teamText = "Every pet has an ability · Legendary & Secret pets have a SUPER ability"
	end
	local teamLine = K.text(body, teamText, UDim2.fromOffset(2, 38), UDim2.fromOffset(440, 18), 13, Color3.fromRGB(255, 230, 150), 0)
	teamLine.Font = Enum.Font.GothamBold
	teamLine.TextXAlignment = Enum.TextXAlignment.Left
	local best = K.button(body, "⭐ EQUIP BEST", UDim2.fromOffset(452, 0), UDim2.fromOffset(150, 38), K.GREEN, 17)
	local none = K.button(body, "UNEQUIP ALL", UDim2.fromOffset(610, 0), UDim2.fromOffset(138, 38), K.RED, 17)
	best.Activated:Connect(function()
		action:FireServer("best")
	end)
	none.Activated:Connect(function()
		action:FireServer("none")
	end)
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(0, 62)
	list.Size = UDim2.fromOffset(748, 344)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.Parent = body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(138, 188)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.Parent = list
	local ids = {}
	for id = 1, Config.MaxPetId do if not Config.Pets[id] then continue end
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
		-- пустое состояние: большая картинка яиц, подсказка и кнопка к яйцам
		local empty = K.frame(body, UDim2.new(0.5, -230, 0, 112), UDim2.fromOffset(460, 286), Color3.new(1, 1, 1), 24)
		K.grad(empty, Color3.fromRGB(70, 44, 150), K.CARD2)
		K.stroke(empty, K.GOLD, 3)
		local glow = K.frame(empty, UDim2.new(0.5, -70, 0, -40), UDim2.fromOffset(140, 140), Color3.fromRGB(255, 210, 110), UDim.new(1, 0))
		glow.BackgroundTransparency = 0.75
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = "rbxthumb://type=Asset&id=127549130694833&w=420&h=420"
		img.AnchorPoint = Vector2.new(0.5, 0)
		img.Position = UDim2.new(0.5, 0, 0, -44)
		img.Size = UDim2.fromOffset(150, 150)
		img.Parent = empty
		img.Rotation = -4
		game:GetService("TweenService"):Create(img, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 4 }):Play()
		K.text(empty, "No pets yet!", UDim2.fromOffset(0, 114), UDim2.new(1, 0, 0, 44), 36, nil, 3)
		local d = K.text(empty, "Walk up to an egg stand and press E to hatch your first pet. Pets multiply every coin you pick up!", UDim2.fromOffset(34, 160), UDim2.new(1, -68, 0, 56), 17, Color3.fromRGB(225, 215, 255), 0)
		d.Font = Enum.Font.GothamBold
		local go = K.button(empty, "🥚 FIND AN EGG", UDim2.new(0.5, -110, 1, -70), UDim2.fromOffset(220, 50), K.GREEN, 22)
		go.Activated:Connect(function()
			-- закрываем инвентарь, стрелка квеста 25 с ведёт к ближайшему яйцу
			player:SetAttribute("GuideEggUntil", os.clock() + 25)
			player:SetAttribute("UIScreen", "")
		end)
	end
	for _, id in ipairs(ids) do
		local baseId, tier = ShopConfig.SplitPet(id)
		local def = Config.Pets[baseId]
		local variant = ShopConfig.Variants[tier]
		local rc = variant and variant.Color or rarityColors[def.Rarity] or dark
		local isOn = (equippedCount[id] or 0) > 0
		local card = Instance.new("TextButton")
		card.Text = ""
		card.AutoButtonColor = false
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		K.grad(card, (isOn and Color3.fromRGB(60, 140, 90) or K.CARD):Lerp(rc, 0.22), K.CARD2)
		card.Parent = list
		corner(card, 16)
		K.stroke(card, isOn and K.GOLD or rc, isOn and 3.5 or 2.5)
		-- мягкий круг цвета редкости за питомцем
		local halo = K.frame(card, UDim2.fromOffset(24, 8), UDim2.fromOffset(90, 90), rc, UDim.new(1, 0))
		halo.BackgroundTransparency = 0.72
		local cs = Instance.new("UIScale")
		cs.Parent = card
		card.MouseEnter:Connect(function()
			cs.Scale = 1.04
		end)
		card.MouseLeave:Connect(function()
			cs.Scale = 1
		end)
		viewport(card, UDim2.fromOffset(14, 4), UDim2.fromOffset(110, 92), id)
		-- уровень вида: значок «Lv N» и полоска опыта до следующего уровня
		do
			local lv, into, need = ShopConfig.LevelFromXP(player:GetAttribute(ShopConfig.PetXPAttr(baseId)))
			local pill = K.frame(card, UDim2.fromOffset(6, 6), UDim2.fromOffset(44, 20), Color3.new(1, 1, 1), 10)
			K.grad(pill, Color3.fromRGB(120, 230, 140), Color3.fromRGB(40, 150, 80))
			K.stroke(pill, K.INK, 2)
			pill.ZIndex = 6
			local lt = K.text(pill, "Lv " .. lv, UDim2.fromOffset(2, 1), UDim2.new(1, -4, 1, -2), 13, nil, 1.5)
			lt.ZIndex = 7
			local bar = K.frame(card, UDim2.fromOffset(14, 92), UDim2.fromOffset(110, 4), Color3.fromRGB(30, 25, 50), 2)
			bar.ZIndex = 6
			local fill = K.frame(bar, UDim2.new(), UDim2.fromScale(need > 0 and math.clamp(into / need, 0, 1) or 1, 1), Color3.fromRGB(120, 230, 140), 2)
			fill.ZIndex = 7
		end
		label(card, (variant and (variant.Name .. " ") or "") .. def.Name, UDim2.fromOffset(4, 96), UDim2.fromOffset(130, 20), 15, variant and variant.Color:Lerp(Color3.new(1, 1, 1), 0.35) or nil)
		label(card, ((baseId >= 222 and baseId <= 227) and "VAULT SECRET" or def.Exclusive and ("ROYAL " .. def.Rarity:upper()) or def.Super and (def.SuperKey:upper() .. " SECRET") or def.Rarity) .. " · x" .. string.format("%g", codeMult(id)), UDim2.fromOffset(4, 116), UDim2.fromOffset(130, 16), 13, rarityColors[def.Rarity])
		-- Способность питомца и (у Legendary/Secret) значок супер-способности.
		local ability = PetAbilities.Get(baseId, tier)
		local abilityLine = label(card, ability.Text, UDim2.fromOffset(6, 133), UDim2.fromOffset(126, 15), 13, Color3.fromRGB(255, 235, 160))
		abilityLine.TextScaled = true
		local super = PetAbilities.Super(baseId)
		if super then
			local pill = Instance.new("Frame")
			pill.Position = UDim2.fromOffset(6, 150)
			pill.Size = UDim2.fromOffset(126, 17)
			pill.BackgroundColor3 = Color3.new(1, 1, 1)
			pill.Parent = card
			corner(pill, 8)
			stroke(pill, 1.5)
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new(super.Color, super.Color:Lerp(Color3.new(0, 0, 0), 0.45))
			g.Rotation = 90
			g.Parent = pill
			local superText = label(pill, "⭐ SUPER: " .. super.Name, UDim2.fromOffset(4, 1), UDim2.new(1, -8, 1, -2), 12)
			superText.TextScaled = true
			local ts = Instance.new("UIStroke")
			ts.Thickness = 1.2
			ts.Color = dark
			ts.Parent = superText
		end
		card.MouseEnter:Connect(function()
			teamLine.Text = ability.Text .. (super and ("   ·   " .. super.Icon .. " " .. super.Name .. ": " .. super.Text) or "")
		end)
		card.MouseLeave:Connect(function()
			teamLine.Text = teamText
		end)
		label(card, "own " .. count(id), UDim2.fromOffset(4, 166), UDim2.fromOffset(60, 20), 13, Color3.fromRGB(210, 210, 220), Enum.Font.GothamMedium)
		if (equippedCount[id] or 0) > 0 then
			-- надетый питомец: плашка сверху, чтобы было видно с первого взгляда
			local on = label(card, "✔ EQUIPPED", UDim2.fromOffset(8, 6), UDim2.fromOffset(84, 18), 12)
			on.BackgroundTransparency = 0
			on.BackgroundColor3 = Color3.fromRGB(70, 190, 90)
			on.ZIndex = 3
			corner(on, 9)
			stroke(on, 1.5)
			local tag = label(card, "✔ x" .. equippedCount[id], UDim2.fromOffset(70, 166), UDim2.fromOffset(62, 20), 14, Color3.fromRGB(150, 255, 150))
			tag.TextXAlignment = Enum.TextXAlignment.Right
		end
		card.Activated:Connect(function()
			-- Клик: надеть ещё одного (если есть свободный экземпляр), иначе снять.
			local canAdd = #equipped < maxEquipped and (equippedCount[id] or 0) < count(id)
			if canAdd then
				action:FireServer("equip", id)
			elseif (equippedCount[id] or 0) > 0 then
				action:FireServer("unequip", id)
			else
				action:FireServer("equip", id)
			end
		end)
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#ids / 5) * 198)
end

-- ===== Зелья =====
local potionTimers = {}
local function buildPotions()
	-- два ряда: обычные (магазин за монеты) и СУПЕР (только награды и Robux)
	local rows = {
		{ ShopConfig.PotionOrder, "POTIONS · 5 min · from quests and rewards", Color3.fromRGB(200, 190, 240) },
		{ ShopConfig.SuperPotionOrder, "⭐ SUPER POTIONS · 10 min · Daily Rewards, Coin Rush vault, Rebirths", Color3.fromRGB(255, 215, 90) },
	}
	-- Ключи Coin Rush (фидбэк 2026-11: «отдельная метка, сколько у тебя ключей»): плашка справа
	-- в строке заголовка, по нажатию — откуда их брать.
	do
		local keys = player:GetAttribute("Save_RushKeys") or 0
		local pill = Instance.new("TextButton")
		pill.Name = "RushKeysPill"
		pill.AutoButtonColor = true
		pill.Text = ""
		pill.Position = UDim2.fromOffset(548, -2)
		pill.Size = UDim2.fromOffset(196, 28)
		pill.BackgroundColor3 = Color3.fromRGB(60, 40, 120)
		pill.ZIndex = 4
		pill.Parent = body
		corner(pill, 14)
		stroke(pill, 2.5, Color3.fromRGB(255, 205, 70))
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.fromOffset(4, -4)
		icon.Size = UDim2.fromOffset(34, 34)
		icon.Image = "rbxassetid://106655154523737"
		icon.ZIndex = 5
		icon.Parent = pill
		local txt = label(pill, "Rush Keys: " .. keys .. "  ⓘ", UDim2.fromOffset(40, 0), UDim2.new(1, -46, 1, 0), 16, keys > 0 and Color3.fromRGB(255, 225, 120) or Color3.fromRGB(200, 195, 225))
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.ZIndex = 5
		local tip = Instance.new("Frame")
		tip.Name = "RushKeysInfo"
		tip.Visible = false
		tip.Position = UDim2.fromOffset(392, 30)
		tip.Size = UDim2.fromOffset(352, 176)
		tip.BackgroundColor3 = Color3.fromRGB(30, 20, 62)
		tip.ZIndex = 10
		tip.Parent = body
		corner(tip, 14)
		stroke(tip, 2.5, Color3.fromRGB(255, 205, 70))
		local info = label(tip, "🔑 1 key = 1 Coin Rush run (enter at the Coin Rush portal)\n"
			.. "• 1 free run every day\n"
			.. "• Daily Rewards: days 3, 5 and 7 (more each week)\n"
			.. "• Trail Shop: exchange 3 ⚡ for a key\n"
			.. "• 3★ on Coin Rush floor 5 or 10: +2 keys\n"
			.. "• Starter Pack: +3 keys\n"
			.. "• No key? Buy a run for coins at the portal", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 1, -16), 15, Color3.fromRGB(235, 230, 255), Enum.Font.GothamBold)
		info.TextWrapped = true
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextYAlignment = Enum.TextYAlignment.Top
		info.ZIndex = 11
		pill.Activated:Connect(function()
			tip.Visible = not tip.Visible
		end)
	end
	for r, row in ipairs(rows) do
		local y0 = (r - 1) * 200
		local cap = label(body, row[2], UDim2.fromOffset(4, y0), UDim2.fromOffset(r == 1 and 536 or 740, 24), 17, row[3])
		cap.TextXAlignment = Enum.TextXAlignment.Left
		for i, name in ipairs(row[1]) do
			local def = ShopConfig.Potions[name]
			local have = player:GetAttribute("Potion" .. name) or 0
			local card = Instance.new("Frame")
			card.Position = UDim2.fromOffset((i - 1) * 252, y0 + 28)
			card.Size = UDim2.fromOffset(244, 164)
			card.BackgroundColor3 = Color3.new(1, 1, 1)
			card.Parent = body
			corner(card, 16)
			stroke(card, def.Super and 3.5 or 2.5, def.Super and Color3.fromRGB(255, 205, 70) or def.Color)
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Color = ColorSequence.new(def.Color:Lerp(Color3.fromRGB(48, 32, 100), def.Super and 0.55 or 0.75), Color3.fromRGB(24, 16, 56))
			g.Parent = card
			local glow = Instance.new("Frame")
			glow.Position = UDim2.fromOffset(14, 26)
			glow.Size = UDim2.fromOffset(100, 100)
			glow.BackgroundColor3 = def.Color
			glow.BackgroundTransparency = 0.7
			glow.Parent = card
			corner(glow, 50)
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Position = UDim2.fromOffset(2, 12)
			img.Size = UDim2.fromOffset(124, 124)
			img.Image = def.Image or ""
			img.ImageTransparency = have > 0 and 0 or 0.35
			img.Parent = card
			local n = label(card, def.Name, UDim2.fromOffset(124, 10), UDim2.fromOffset(114, 40), 18)
			n.TextScaled = true
			local ns = Instance.new("UITextSizeConstraint")
			ns.MaxTextSize = 18
			ns.Parent = n
			local nst = Instance.new("UIStroke")
			nst.Thickness = 2
			nst.Color = dark
			nst.Parent = n
			label(card, def.Effect, UDim2.fromOffset(124, 50), UDim2.fromOffset(114, 20), 15, def.Color:Lerp(Color3.new(1, 1, 1), 0.35))
			label(card, "Owned: " .. have, UDim2.fromOffset(124, 72), UDim2.fromOffset(114, 20), 16, Color3.fromRGB(225, 220, 245), Enum.Font.GothamBold)
			potionTimers[name] = label(card, "", UDim2.fromOffset(124, 94), UDim2.fromOffset(114, 20), 15, Color3.fromRGB(150, 255, 150))
			local use = button(card, have > 0 and "USE" or (def.Super and "FROM REWARDS" or "BUY IN SHOP"), UDim2.fromOffset(128, 120), UDim2.fromOffset(106, 34), have > 0 and Color3.fromRGB(70, 180, 90) or Color3.fromRGB(90, 80, 130))
			use.TextScaled = have <= 0
			use.Activated:Connect(function()
				if have > 0 then
					action:FireServer("potion", name)
				end
			end)
			if def.Super then
				local tag = label(card, "SUPER", UDim2.fromOffset(10, 8), UDim2.fromOffset(60, 18), 13, Color3.new(1, 1, 1))
				tag.BackgroundTransparency = 0
				tag.BackgroundColor3 = Color3.fromRGB(235, 150, 30)
				tag.ZIndex = 3
				corner(tag, 9)
				stroke(tag, 1.5)
			end
		end
	end
end

-- ===== Достижения =====
local NumberFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberFormat"))
local function short(n: number): string
	return NumberFormat.Short(n)
end

local function buildBadges()
	local unlocked = 0
	for _, b in ipairs(ShopConfig.Badges) do
		if player:GetAttribute("Badge" .. b.Id) then
			unlocked += 1
		end
	end
	local header = label(body, string.format("Unlocked %d / %d   ·   Coin bonus x%.3f", unlocked, #ShopConfig.Badges, ShopConfig.BadgeBonus ^ unlocked), UDim2.fromOffset(0, 0), UDim2.fromOffset(748, 34), 19)
	header.TextXAlignment = Enum.TextXAlignment.Left
	-- Достижений много (цепочки с уровнями) — прокручиваемый список по две в ряд.
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 44)
	list.Size = UDim2.new(1, 0, 1, -44)
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = Color3.fromRGB(240, 160, 50)
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#ShopConfig.Badges / 2) * 118)
	list.Parent = body
	-- сразу прокручиваем к первому неоткрытому
	local firstOpen
	for i, b in ipairs(ShopConfig.Badges) do
		if not player:GetAttribute("Badge" .. b.Id) then
			firstOpen = firstOpen or i
		end
	end
	for i, b in ipairs(ShopConfig.Badges) do
		local done = player:GetAttribute("Badge" .. b.Id) == true
		local value = math.min(player:GetAttribute(b.Stat) or 0, b.Goal)
		local row = Instance.new("Frame")
		row.Position = UDim2.fromOffset(((i - 1) % 2) * 378, math.floor((i - 1) / 2) * 118)
		row.Size = UDim2.fromOffset(362, 108)
		row.BackgroundColor3 = done and Color3.fromRGB(70, 110, 70) or Color3.fromRGB(48, 32, 100)
		row.Parent = list
		corner(row, 14)
		stroke(row, 3, done and Color3.fromRGB(255, 210, 80) or dark)
		-- герб цепочки; ступень (I–II бронза, III–IV серебро, V–VI золото, VII+ алмаз) — цвет подложки
		local tierColor = ({ Color3.fromRGB(205, 127, 50), Color3.fromRGB(200, 205, 215), Color3.fromRGB(255, 200, 50), Color3.fromRGB(110, 230, 255) })[ShopConfig.BadgeStage(b.Chain, b.Level)]
		local glow = Instance.new("Frame")
		glow.Position = UDim2.fromOffset(10, 10)
		glow.Size = UDim2.fromOffset(84, 84)
		glow.BackgroundColor3 = done and tierColor or Color3.fromRGB(60, 50, 90)
		glow.BackgroundTransparency = done and 0.55 or 0.3
		glow.Parent = row
		corner(glow, 42)
		local img = ShopConfig.BadgeImage(b.Chain, b.Level) -- герб «растёт» с уровнем
		if img then
			local mi = Instance.new("ImageLabel")
			mi.BackgroundTransparency = 1
			mi.Image = img
			mi.Position = UDim2.fromOffset(4, 2)
			mi.Size = UDim2.fromOffset(96, 96)
			mi.ImageColor3 = done and Color3.new(1, 1, 1) or Color3.fromRGB(120, 110, 150)
			mi.ImageTransparency = done and 0 or 0.35
			mi.Parent = row
			local lv = label(row, ({ "I", "II", "III", "IV", "V", "VI", "VII", "VIII" })[b.Level] or "", UDim2.fromOffset(34, 78), UDim2.fromOffset(36, 22), 15, done and tierColor or Color3.fromRGB(170, 160, 200))
			local lst = Instance.new("UIStroke")
			lst.Thickness = 2
			lst.Color = Color3.fromRGB(30, 16, 60)
			lst.Parent = lv
		else
			local mi = label(glow, b.Icon, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 38)
			mi.TextTransparency = done and 0 or 0.45
		end
		local n = label(row, b.Name .. (done and "  ✔" or ""), UDim2.fromOffset(100, 8), UDim2.fromOffset(260, 28), 20)
		n.TextXAlignment = Enum.TextXAlignment.Left
		local d = label(row, b.Desc .. string.format(" · x%g coins", ShopConfig.BadgeBonus), UDim2.fromOffset(100, 36), UDim2.fromOffset(260, 22), 14, Color3.fromRGB(210, 215, 230), Enum.Font.GothamMedium)
		d.TextXAlignment = Enum.TextXAlignment.Left
		local barBack = Instance.new("Frame")
		barBack.Position = UDim2.fromOffset(100, 68)
		barBack.Size = UDim2.fromOffset(250, 20)
		barBack.BackgroundColor3 = Color3.fromRGB(22, 14, 48)
		barBack.Parent = row
		corner(barBack, 10)
		local bar = Instance.new("Frame")
		bar.Size = UDim2.fromScale(value / b.Goal, 1)
		bar.BackgroundColor3 = done and Color3.fromRGB(255, 210, 80) or Color3.fromRGB(90, 200, 120)
		bar.Parent = barBack
		corner(bar, 10)
		label(barBack, string.format("%s / %s", short(math.floor(value)), short(b.Goal)), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 13)
	end
	if firstOpen then
		list.CanvasPosition = Vector2.new(0, math.max(math.floor((firstOpen - 1) / 2) - 1, 0) * 118)
	end
end

-- ===== Титулы =====
local Titles = require(ReplicatedStorage:WaitForChild("TitlesConfig"))
local function plate(parent, t, pos, w)
	local pill = K.frame(parent, pos, UDim2.fromOffset(w, 32), Color3.new(1, 1, 1), UDim.new(1, 0))
	K.grad(pill, t.A, t.B)
	K.stroke(pill, K.INK, 3)
	local gl = K.frame(pill, UDim2.fromOffset(10, 3), UDim2.new(1, -20, 0.38, 0), Color3.new(1, 1, 1), UDim.new(1, 0))
	gl.BackgroundTransparency = 0.7
	K.text(pill, t.Icon .. " " .. t.Text, UDim2.fromOffset(8, 3), UDim2.new(1, -16, 1, -6), 20, nil, 2)
	return pill
end
local function buildTitles()
	local shown = Titles.Shown(player)
	local owned = 0
	for _, t in ipairs(Titles.List) do
		if t.Has(player) then
			owned += 1
		end
	end
	local header = label(body, string.format("Titles show above your head · unlocked %d / %d", owned, #Titles.List), UDim2.fromOffset(0, 0), UDim2.fromOffset(560, 34), 19)
	header.TextXAlignment = Enum.TextXAlignment.Left
	local none = K.button(body, "NO TITLE", UDim2.fromOffset(600, 0), UDim2.fromOffset(140, 34), shown == nil and K.ORANGE or K.GRAY, 16)
	none.Activated:Connect(function()
		action:FireServer("title", "none")
	end)
	local list = Instance.new("ScrollingFrame")
	list.Name = "TitleList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 44)
	list.Size = UDim2.new(1, 0, 1, -44)
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = Color3.fromRGB(240, 160, 50)
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#Titles.List / 3) * 128)
	list.Parent = body
	for i, t in ipairs(Titles.List) do
		local has = t.Has(player)
		local on = shown == t
		local card = K.frame(list, UDim2.fromOffset(((i - 1) % 3) * 248, math.floor((i - 1) / 3) * 128), UDim2.fromOffset(238, 118), Color3.new(1, 1, 1), 16)
		K.grad(card, has and K.CARD:Lerp(t.B, 0.25) or K.CARD, K.CARD2)
		K.stroke(card, on and K.GOLD or (has and t.B or Color3.fromRGB(70, 60, 110)), on and 3.5 or 2)
		local pl = plate(card, t, UDim2.fromOffset(12, 10), 214)
		if not has then
			pl.BackgroundTransparency = 0.5
			for _, d in ipairs(pl:GetDescendants()) do
				if d:IsA("TextLabel") then
					d.TextTransparency = 0.45
				end
			end
		end
		local d = K.text(card, (has and "" or "🔒 ") .. t.Desc, UDim2.fromOffset(10, 46), UDim2.new(1, -20, 0, 22), 14, has and Color3.fromRGB(225, 220, 245) or Color3.fromRGB(170, 160, 200), 0)
		d.Font = Enum.Font.GothamBold
		local crest = Instance.new("ImageLabel")
		crest.BackgroundTransparency = 1
		crest.Image = t.Image or ""
		crest.Position = UDim2.fromOffset(10, 64)
		crest.Size = UDim2.fromOffset(50, 50)
		crest.ImageTransparency = has and 0 or 0.5
		crest.Visible = t.Image ~= nil
		crest.Parent = card
		if not t.Image then
			K.text(card, t.Icon, UDim2.fromOffset(14, 70), UDim2.fromOffset(42, 40), 32, nil, 0).TextTransparency = has and 0 or 0.5
		end
		local b = K.button(card, on and "EQUIPPED" or has and "EQUIP" or "LOCKED", UDim2.fromOffset(68, 74), UDim2.fromOffset(158, 34), on and K.ORANGE or has and K.GREEN or K.GRAY, 17)
		b.Activated:Connect(function()
			if has and not on then
				action:FireServer("title", t.Id)
			end
		end)
	end
end

local lastRendered = nil
local function render()
	-- запоминаем прокрутку: раньше после каждого «надеть» список прыгал наверх
	local keep = {}
	if lastRendered == current then
		for _, d in ipairs(body:GetDescendants()) do
			if d:IsA("ScrollingFrame") then
				keep[d.Name] = d.CanvasPosition
			end
		end
	end
	lastRendered = current
	body:ClearAllChildren()
	spinning = {}
	potionTimers = {}
	for name, set in pairs(tabSet) do
		set(name == current and K.ORANGE or K.GRAY)
	end
	if current == "pets" then
		buildPets()
	elseif current == "potions" then
		buildPotions()
	elseif current == "titles" then
		buildTitles()
	else
		buildBadges()
	end
	if next(keep) then
		task.defer(function()
			for _, d in ipairs(body:GetDescendants()) do
				if d:IsA("ScrollingFrame") and keep[d.Name] then
					d.CanvasPosition = keep[d.Name]
				end
			end
		end)
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
		lastRendered = nil -- новое открытие — с начала списка
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
	if name == "Equipped" or name == "PetBonus" or name == "MaxEquipped" or name == "PetSupers" or name:sub(1, 4) == "Abil" or name:sub(1, 8) == "PetOwned" or name:sub(1, 7) == "PetGold" or name:sub(1, 10) == "PetDiamond" or name:sub(1, 10) == "PetRainbow" or name:sub(1, 6) == "Potion" or name:sub(1, 5) == "Badge" or name == "Save_Title" or name == "Save_QuestLineStep" or name == "Save_RushKeys" then
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
		scale.Scale = math.clamp(math.min(camera.ViewportSize.X / 860, camera.ViewportSize.Y / 580), 0.35, 1)
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
		local left = (player:GetAttribute("PotionEnd" .. name) or 0) - workspace:GetServerTimeNow()
		l.Text = left > 0 and string.format("Active %d:%02d", left // 60, left % 60) or ""
	end
end)
