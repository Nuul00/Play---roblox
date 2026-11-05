-- Индекс питомцев в виде книги: слева страницы-яйца с прогрессом, справа питомцы.
-- Невыбитые питомцы показаны чёрным силуэтом и «???». За полную страницу — награда (проверяет сервер).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local PetAbilities = require(ReplicatedStorage:WaitForChild("PetAbilities"))
local claim = ReplicatedStorage:WaitForChild("GameIndexClaim")

local rarityColors = {
	Common = Color3.fromRGB(170, 175, 180),
	Uncommon = Color3.fromRGB(90, 200, 110),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 80, 160),
	Secret = Color3.fromRGB(190, 120, 255),
}
local paper = Color3.fromRGB(250, 238, 210)
local ink = Color3.fromRGB(80, 55, 35)
local leather = Color3.fromRGB(120, 62, 38)

local gui = Instance.new("ScreenGui")
gui.Name = "PetIndexBook"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(p, r)
	Instance.new("UICorner", p).CornerRadius = UDim.new(0, r)
end
local function stroke(p, t, c)
	local s = Instance.new("UIStroke")
	s.Thickness = t
	s.Color = c
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end
local function text(parent, value, pos, size, fontSize, color, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = pos
	t.Size = size
	t.Text = value
	t.TextSize = fontSize
	t.TextColor3 = color or ink
	t.Font = font or Enum.Font.FredokaOne
	t.TextWrapped = true
	t.Parent = parent
	return t
end

-- Обложка и две страницы.
local book = Instance.new("Frame")
book.AnchorPoint = Vector2.new(0.5, 0.5)
book.Position = UDim2.fromScale(0.5, 0.52)
book.Size = UDim2.fromOffset(820, 500)
book.BackgroundColor3 = leather
book.Visible = false
book.Parent = gui
corner(book, 22)
stroke(book, 5, Color3.fromRGB(60, 30, 18))
local bookScale = Instance.new("UIScale", book)

local ribbon = Instance.new("Frame")
ribbon.AnchorPoint = Vector2.new(0.5, 0.5)
ribbon.Position = UDim2.new(0.5, 0, 0, 0)
ribbon.Size = UDim2.fromOffset(300, 54)
ribbon.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
ribbon.ZIndex = 5
ribbon.Parent = book
corner(ribbon, 14)
stroke(ribbon, 4, Color3.fromRGB(110, 20, 20))
local ribbonText = text(ribbon, "📖 PET INDEX", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 28, Color3.new(1, 1, 1))
ribbonText.ZIndex = 6

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(0.5, 0.5)
close.Position = UDim2.new(1, -6, 0, 6)
close.Size = UDim2.fromOffset(46, 46)
close.Text = "×"
close.TextSize = 30
close.Font = Enum.Font.FredokaOne
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
close.ZIndex = 6
close.Modal = true
close.Parent = book
corner(close, 23)
stroke(close, 3, Color3.fromRGB(110, 20, 20))

local function page(x)
	local p = Instance.new("Frame")
	p.Position = UDim2.fromOffset(x, 18)
	p.Size = UDim2.fromOffset(388, 464)
	p.BackgroundColor3 = paper
	p.Parent = book
	corner(p, 14)
	local shade = Instance.new("UIGradient")
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(235, 220, 190))
	shade.Rotation = x < 400 and 0 or 180
	shade.Parent = p
	return p
end
local left = page(16)
local right = page(416)
local spine = Instance.new("Frame")
spine.Position = UDim2.fromOffset(404, 18)
spine.Size = UDim2.fromOffset(12, 464)
spine.BackgroundColor3 = Color3.fromRGB(90, 45, 28)
spine.BorderSizePixel = 0
spine.Parent = book

text(left, "EGGS", UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 30), 24)
local total = text(left, "", UDim2.fromOffset(0, 426), UDim2.new(1, 0, 0, 26), 18)
local tabs = {}
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(0, 66)
list.Size = UDim2.fromOffset(388, 354)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.fromOffset(0, #Config.Eggs * 58 + 8)
list.Parent = left
-- Порядок миров как в игре: Frozen (16-18) идёт после Sky, до Volcano.
local EGG_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 16, 17, 18, 10, 11, 12, 13, 14, 15 }
for pos, id in ipairs(EGG_ORDER) do
	local egg = Config.Eggs[id]
	local b = Instance.new("TextButton")
	b.Text = ""
	b.Position = UDim2.fromOffset(18, 4 + (pos - 1) * 58)
	b.Size = UDim2.fromOffset(352, 50)
	b.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
	b.Parent = list
	corner(b, 12)
	local s = stroke(b, 2.5, ink)
	local dot = Instance.new("Frame")
	dot.Position = UDim2.fromOffset(10, 9)
	dot.Size = UDim2.fromOffset(28, 32)
	dot.BackgroundColor3 = egg.Color
	dot.Parent = b
	corner(dot, 14)
	stroke(dot, 2, ink)
	local name = text(b, egg.Name, UDim2.fromOffset(48, 4), UDim2.fromOffset(190, 24), 18)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local world = text(b, egg.World == "neon" and "Neon District" or egg.World == "sky" and "Sky Isles" or egg.World == "volcano" and "Magma Volcano" or egg.World == "galaxy" and "Cosmic Galaxy" or egg.World == "frozen" and "Frozen Peaks" or "Meadow Isles", UDim2.fromOffset(48, 26), UDim2.fromOffset(190, 18), 13, Color3.fromRGB(140, 110, 80), Enum.Font.GothamMedium)
	world.TextXAlignment = Enum.TextXAlignment.Left
	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.fromOffset(240, 30)
	barBack.Size = UDim2.fromOffset(100, 10)
	barBack.BackgroundColor3 = Color3.fromRGB(220, 205, 175)
	barBack.Parent = b
	corner(barBack, 5)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = Color3.fromRGB(90, 200, 110)
	bar.Parent = barBack
	corner(bar, 5)
	local count = text(b, "", UDim2.fromOffset(240, 4), UDim2.fromOffset(100, 24), 17)
	count.TextXAlignment = Enum.TextXAlignment.Right
	tabs[id] = { button = b, stroke = s, bar = bar, count = count }
end

local header = text(right, "", UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 30), 24)
local grid = Instance.new("ScrollingFrame")
grid.BorderSizePixel=0
grid.ScrollBarThickness=4
grid.ScrollingDirection=Enum.ScrollingDirection.Y
grid.CanvasSize=UDim2.fromOffset(0,0)
grid.BackgroundTransparency = 1
grid.Position = UDim2.fromOffset(14, 72)
grid.Size = UDim2.fromOffset(360, 318)
grid.Parent = right
local rewardButton = Instance.new("TextButton")
rewardButton.Position = UDim2.fromOffset(24, 404)
rewardButton.Size = UDim2.fromOffset(340, 44)
rewardButton.Font = Enum.Font.FredokaOne
rewardButton.TextSize = 18
rewardButton.TextColor3 = Color3.new(1, 1, 1)
rewardButton.Parent = right
corner(rewardButton, 12)
stroke(rewardButton, 3, ink)

local selected = 1
local cards = {}

-- Считаем все ступени (обычный + Golden/Diamond/Rainbow): слияние не «закрывает» питомца.
local VARIANT_KEYS = { "", "Gold", "Diamond", "Rainbow" }
local function owned(petId)
	local n = 0
	for _, key in ipairs(VARIANT_KEYS) do
		n += player:GetAttribute((key == "" and "PetOwned" or ("Pet" .. key)) .. petId) or 0
	end
	return n
end
local function short(n)
	for _, u in ipairs({ { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then
			return (string.format("%.2f", n / u[1]):gsub("%.?0+$", "")) .. u[2]
		end
	end
	return tostring(math.floor(n))
end
local function progress(eggId)
	local n = 0
	for _, entry in ipairs(Config.Eggs[eggId].Pool) do
		if owned(entry.Pet) > 0 then
			n += 1
		end
	end
	return n, #Config.Eggs[eggId].Pool
end

local function viewport(parent, petId)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromOffset(6, 4)
	view.Size = UDim2.fromOffset(100, 55)
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.LightDirection = Vector3.new(-1, -1, -2)
	view.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = PetVisuals.Build(petId)
	model.Parent = world
	local _, size = model:GetBoundingBox()
	local d = math.max(size.X, size.Y, size.Z)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(d * 0.9, d * 0.55, -d * 1.6), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera
	return view, model
end

local function showPage(eggId)
	selected = eggId
	local egg = Config.Eggs[eggId]
	header.Text = egg.Name
	grid:ClearAllChildren()
	grid.CanvasSize=UDim2.fromOffset(0,math.ceil(#egg.Pool/3)*136)
	grid.CanvasPosition=Vector2.zero
	cards = {}
	for i, entry in ipairs(egg.Pool) do
		local def = Config.Pets[entry.Pet]
		local card = Instance.new("Frame")
		card.Position = UDim2.fromOffset((i - 1) % 3 * 120, math.floor((i - 1) / 3) * 136)
		card.Size = UDim2.fromOffset(112, 130)
		card.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
		card.Parent = grid
		corner(card, 12)
		stroke(card, 3, rarityColors[def.Rarity] or ink)
		local found = owned(entry.Pet) > 0
		local view, model = viewport(card, entry.Pet)
		if not found then
			-- Силуэт: вся модель чёрная, детали и текстуры не видны.
			view.ImageColor3 = Color3.new(0, 0, 0)
			view.Ambient = Color3.new(0, 0, 0)
			view.LightColor = Color3.new(0, 0, 0)
		end
		text(card, found and def.Name or "???", UDim2.fromOffset(4, 58), UDim2.fromOffset(104, 18), found and 14 or 20)
		local rarity = text(card, def.Rarity, UDim2.fromOffset(4, 76), UDim2.fromOffset(104, 16), 13, rarityColors[def.Rarity] or ink)
		if def.Rarity == "Secret" then
			rarity.Text = "SECRET"
		end
		text(card, found and string.format("x%g · %g%% · own %d", def.Multiplier, entry.Chance, owned(entry.Pet)) or string.format("%g%%", entry.Chance), UDim2.fromOffset(4, 89), UDim2.fromOffset(104, 12), 9, Color3.fromRGB(120, 95, 70), Enum.Font.GothamMedium)
		-- Способность питомца (видна, когда он открыт) и значок супер-способности.
		local ability = text(card, found and PetAbilities.Get(entry.Pet, 0).Text or "🔒 ability: ???", UDim2.fromOffset(5, 101), UDim2.fromOffset(102, 13), 11, Color3.fromRGB(150, 95, 30))
		ability.TextScaled = true
		local super = PetAbilities.Super(entry.Pet)
		if super then
			local pill = Instance.new("Frame")
			pill.Position = UDim2.fromOffset(5, 115)
			pill.Size = UDim2.fromOffset(102, 13)
			pill.BackgroundColor3 = Color3.new(1, 1, 1)
			pill.Parent = card
			corner(pill, 6)
			stroke(pill, 1.2, Color3.fromRGB(30, 30, 40))
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new(super.Color, super.Color:Lerp(Color3.new(0, 0, 0), 0.45))
			g.Rotation = 90
			g.Parent = pill
			local label = text(pill, "⭐ SUPER: " .. super.Name, UDim2.fromOffset(3, 0), UDim2.new(1, -6, 1, 0), 10, Color3.new(1, 1, 1))
			label.TextScaled = true
		end
		cards[i] = { model = model, view = view }
	end
	local n, max = progress(eggId)
	local reward = Config.GetIndexReward(eggId)
	if player:GetAttribute("IndexClaimed" .. eggId) then
		rewardButton.Text = "✓ REWARD CLAIMED"
		rewardButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		rewardButton.AutoButtonColor = false
	elseif n >= max then
		rewardButton.Text = "🎁 CLAIM +" .. short(reward) .. " COINS"
		rewardButton.BackgroundColor3 = Color3.fromRGB(70, 190, 90)
		rewardButton.AutoButtonColor = true
	else
		rewardButton.Text = string.format("Collect all %d pets → +%s coins", max, short(reward))
		rewardButton.BackgroundColor3 = Color3.fromRGB(190, 150, 100)
		rewardButton.AutoButtonColor = false
	end
	for id, tab in pairs(tabs) do
		tab.stroke.Thickness = id == eggId and 4 or 2.5
		tab.stroke.Color = id == eggId and Color3.fromRGB(230, 120, 40) or ink
	end
end

local function refreshTabs()
	local all, found = 0, 0
	for id, tab in pairs(tabs) do
		local n, max = progress(id)
		all += max
		found += n
		tab.count.Text = (n >= max and not player:GetAttribute("IndexClaimed" .. id)) and ("🎁 " .. n .. "/" .. max) or (n .. "/" .. max)
		tab.bar.Size = UDim2.fromScale(n / max, 1)
	end
	total.Text = string.format("Discovered %d / %d pets", found, all)
end

for id, tab in pairs(tabs) do
	tab.button.Activated:Connect(function()
		showPage(id)
	end)
end
rewardButton.Activated:Connect(function()
	local n, max = progress(selected)
	if n >= max and not player:GetAttribute("IndexClaimed" .. selected) then
		claim:FireServer(selected)
	end
end)

local function open()
	refreshTabs()
	showPage(selected)
	book.Visible = true
	player:SetAttribute("UIScreen", "index")
end
local function hide()
	book.Visible = false
	if player:GetAttribute("UIScreen") == "index" then
		player:SetAttribute("UIScreen", "")
	end
end
close.Activated:Connect(hide)
player.PlayerGui:WaitForChild("OpenPetIndex").Event:Connect(function()
	if book.Visible then
		hide()
	else
		open()
	end
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	if player:GetAttribute("UIScreen") ~= "index" then
		book.Visible = false
	end
end)
local pendingPage = false
player.AttributeChanged:Connect(function(name)
	if book.Visible and (name:sub(1, 3) == "Pet" or name:sub(1, 12) == "IndexClaimed") and not pendingPage then
		-- пачка из 9 яиц меняет много атрибутов: перерисовываем страницу один раз
		pendingPage = true
		task.defer(function()
			pendingPage = false
			refreshTabs()
			showPage(selected)
		end)
	end
end)

local spin = 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	if camera then
		bookScale.Scale = math.clamp(math.min(camera.ViewportSize.X / 880, camera.ViewportSize.Y / 560), 0.35, 1)
	end
	if book.Visible then
		spin += dt
		for _, card in ipairs(cards) do
			card.model:PivotTo(CFrame.Angles(0, spin * 0.8, 0))
		end
	end
end)
