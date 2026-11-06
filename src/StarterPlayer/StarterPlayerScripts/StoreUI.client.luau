-- Донат-магазин STORE: кнопка внизу слева от TRAILS (в стиле HUD мира) и окно с геймпассами и
-- бустами. Иконки и цены берём из Roblox (GetProductInfo). Купленные геймпассы — «OWNED».
-- Здесь же тег [VIP] в чате для владельцев VIP.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
local Skins = require(ReplicatedStorage:WaitForChild("HudSkins"))
local playerGui = player:WaitForChild("PlayerGui")
local rgb = Color3.fromRGB
local INK = rgb(40, 22, 70)

-- ===== тег VIP в чате =====
TextChatService.OnIncomingMessage = function(message)
	local props = Instance.new("TextChatMessageProperties")
	local src = message.TextSource
	local who = src and Players:GetPlayerByUserId(src.UserId)
	if who and who:GetAttribute("Pass_VIP") then
		props.PrefixText = '<font color="#FFD24A">[VIP]</font> ' .. message.PrefixText
	end
	return props
end

-- ===== кнопка STORE =====
local menu = playerGui:WaitForChild("MenuHUD", 30)
local dock = menu and menu:WaitForChild("Dock", 30)
local holder = dock
if not holder then
	local g = Instance.new("ScreenGui")
	g.Name = "StoreButtonHUD"
	g.ResetOnSpawn = false
	g.DisplayOrder = 12
	g.Parent = playerGui
	holder = g
end
local SIZE = 76
local btn = Instance.new("TextButton")
btn.Name = "StoreButton"
btn.AnchorPoint = Vector2.new(1, 1)
btn.Position = dock and UDim2.new(0.5, -38 - 14 - SIZE - 12, 1, 0) or UDim2.new(0.5, -140, 1, -82)
btn.Size = UDim2.fromOffset(SIZE, SIZE)
btn.AutoButtonColor = false
btn.Text = ""
btn.BackgroundColor3 = Color3.new(1, 1, 1)
btn.Parent = holder
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 22)
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new(rgb(255, 215, 90), rgb(240, 140, 30))
grad.Parent = btn
local rim = Instance.new("UIStroke")
rim.Thickness = 4
rim.Color = rgb(255, 250, 220)
rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rim.Parent = btn
local icon = Instance.new("TextLabel")
icon.BackgroundTransparency = 1
icon.Size = UDim2.new(1, 0, 0, 52)
icon.Text = "🛒"
icon.TextScaled = true
icon.Parent = btn
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -3)
label.Size = UDim2.new(1, -8, 0, 19)
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.Text = "STORE"
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = btn
local ls = Instance.new("UIStroke")
ls.Thickness = 2
ls.Color = rgb(120, 60, 10)
ls.Parent = label
local bscale = Instance.new("UIScale")
bscale.Parent = btn
-- мягкое «дыхание», чтобы магазин замечали
task.spawn(function()
	while btn.Parent do
		TweenService:Create(bscale, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Scale = 1.06 }):Play()
		task.wait(0.9)
		TweenService:Create(bscale, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
		task.wait(2.6)
	end
end)

-- ===== окно =====
local gui = Instance.new("ScreenGui")
gui.Name = "StoreUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 45
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.52)
panel.Size = UDim2.fromOffset(900, 470)
panel.BackgroundColor3 = Color3.new(1, 1, 1)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 26)
local pStroke = Instance.new("UIStroke")
pStroke.Thickness = 5
pStroke.Color = INK
pStroke.Parent = panel
local pGrad = Instance.new("UIGradient")
pGrad.Rotation = 90
pGrad.Parent = panel
local pScale = Instance.new("UIScale")
pScale.Parent = panel

local head = Instance.new("TextLabel")
head.AnchorPoint = Vector2.new(0.5, 0)
head.Position = UDim2.new(0.5, 0, 0, -28)
head.Size = UDim2.fromOffset(380, 62)
head.BackgroundColor3 = rgb(255, 180, 50)
head.Font = Enum.Font.FredokaOne
head.Text = "🛒 STORE"
head.TextSize = 34
head.TextColor3 = Color3.new(1, 1, 1)
head.Parent = panel
Instance.new("UICorner", head).CornerRadius = UDim.new(0, 18)
local hs = Instance.new("UIStroke")
hs.Thickness = 4
hs.Color = INK
hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hs.Parent = head
local hg = Instance.new("UIGradient")
hg.Rotation = 90
hg.Color = ColorSequence.new(rgb(255, 225, 110), rgb(240, 140, 30))
hg.Parent = head
local hts = Instance.new("UIStroke")
hts.Thickness = 2.5
hts.Color = rgb(120, 60, 10)
hts.Parent = head

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -56, 0, 12)
close.Size = UDim2.fromOffset(42, 42)
close.Text = "×"
close.Font = Enum.Font.FredokaOne
close.TextSize = 30
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = rgb(235, 70, 80)
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 12)
local cs = Instance.new("UIStroke")
cs.Thickness = 3
cs.Color = INK
cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cs.Parent = close
close.Activated:Connect(function()
	player:SetAttribute("UIScreen", "")
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(20, 50)
scroll.Size = UDim2.new(1, -40, 1, -66)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.ScrollBarImageColor3 = rgb(255, 220, 120)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 10)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local function section(text, order)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 30)
	l.Font = Enum.Font.FredokaOne
	l.TextSize = 24
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.TextColor3 = rgb(255, 230, 150)
	l.LayoutOrder = order
	l.Parent = scroll
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = INK
	s.Parent = l
end
local function grid(order)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, -10, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = order
	f.Parent = scroll
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(260, 150)
	g.CellPadding = UDim2.fromOffset(14, 14)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = f
	return f
end

local cards = {}
local function card(parent, def, isPass, order)
	local c = Instance.new("Frame")
	c.BackgroundColor3 = Color3.new(1, 1, 1)
	c.LayoutOrder = order
	c.Parent = parent
	Instance.new("UICorner", c).CornerRadius = UDim.new(0, 18)
	local st = Instance.new("UIStroke")
	st.Thickness = 3.5
	st.Color = INK
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = c
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(def.Color:Lerp(Color3.new(1, 1, 1), 0.25), def.Color:Lerp(rgb(40, 20, 80), 0.45))
	g.Parent = c
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Position = UDim2.fromOffset(8, 10)
	img.Size = UDim2.fromOffset(104, 104)
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = c
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(116, 8)
	name.Size = UDim2.new(1, -124, 0, 30)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = def.Name
	name.TextColor3 = Color3.new(1, 1, 1)
	name.Parent = c
	local ns = Instance.new("UIStroke")
	ns.Thickness = 2.5
	ns.Color = INK
	ns.Parent = name
	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.fromOffset(116, 40)
	desc.Size = UDim2.new(1, -124, 0, 52)
	desc.Font = Enum.Font.GothamBold
	desc.TextSize = 13
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Text = def.Desc
	desc.TextColor3 = rgb(255, 250, 235)
	desc.Parent = c
	local ds = Instance.new("UIStroke")
	ds.Thickness = 1.5
	ds.Color = INK
	ds.Parent = desc
	local buy = Instance.new("TextButton")
	buy.AnchorPoint = Vector2.new(1, 1)
	buy.Position = UDim2.new(1, -10, 1, -10)
	buy.Size = UDim2.new(1, -126, 0, 38)
	buy.Font = Enum.Font.FredokaOne
	buy.TextSize = 20
	buy.Text = "..."
	buy.TextColor3 = Color3.new(1, 1, 1)
	buy.BackgroundColor3 = rgb(80, 200, 90)
	buy.AutoButtonColor = true
	buy.Parent = c
	Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 12)
	local bs = Instance.new("UIStroke")
	bs.Thickness = 3
	bs.Color = INK
	bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bs.Parent = buy
	local bts = Instance.new("UIStroke")
	bts.Thickness = 2
	bts.Color = rgb(20, 80, 30)
	bts.Parent = buy
	local entry = { def = def, pass = isPass, buy = buy, img = img, price = nil, frame = c }
	table.insert(cards, entry)
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, def.Id, isPass and Enum.InfoType.GamePass or Enum.InfoType.Product)
		if ok and info then
			if info.IconImageAssetId and info.IconImageAssetId > 0 then
				img.Image = "rbxassetid://" .. info.IconImageAssetId
			end
			entry.price = info.PriceInRobux
		end
	end)
	buy.Activated:Connect(function()
		if def.Random and player:GetAttribute("NoPaidRandom") ~= false then
			return
		end
		if isPass then
			if not player:GetAttribute("Pass_" .. def.Key) then
				MarketplaceService:PromptGamePassPurchase(player, def.Id)
			end
		elseif not (def.Kind == "starter" and player:GetAttribute("Save_StarterBought")) then
			MarketplaceService:PromptProductPurchase(player, def.Id)
		end
	end)
	return entry
end

section("⭐ GAMEPASSES — forever", 1)
local passGrid = grid(2)
for i, def in ipairs(StoreConfig.Passes) do
	if def.Id > 0 then
		card(passGrid, def, true, i)
	end
end
local anyProduct = false
for _, def in ipairs(StoreConfig.Products) do
	if def.Id > 0 then
		anyProduct = true
	end
end
if anyProduct then
	section("⚡ BOOSTS", 3)
	local prodGrid = grid(4)
	for i, def in ipairs(StoreConfig.Products) do
		if def.Id > 0 then
			card(prodGrid, def, false, i)
		end
	end
end

local function refresh()
	for _, e in ipairs(cards) do
		-- товары, влияющие на случайные награды, скрыты, где они запрещены (и пока сервер не проверил)
		e.frame.Visible = not (e.def.Random and player:GetAttribute("NoPaidRandom") ~= false)
			and not (e.def.Kind == "starter" and player:GetAttribute("Save_StarterBought"))
		local owned = e.pass and player:GetAttribute("Pass_" .. e.def.Key)
		if owned then
			e.buy.Text = "✅ OWNED"
			e.buy.BackgroundColor3 = rgb(120, 115, 150)
			e.buy.AutoButtonColor = false
		else
			e.buy.Text = e.price and ("R$ " .. e.price) or "BUY"
			e.buy.BackgroundColor3 = rgb(80, 200, 90)
			e.buy.AutoButtonColor = true
		end
	end
end

local function theme()
	local skin = Skins[player:GetAttribute("CurrentWorld") or ""]
	local top = skin and skin.MenuTop or rgb(125, 85, 235)
	local bottom = skin and skin.MenuBottom or rgb(55, 30, 125)
	pGrad.Color = ColorSequence.new(top, bottom)
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(theme)
theme()

btn.Activated:Connect(function()
	bscale.Scale = 0.9
	player:SetAttribute("UIScreen", player:GetAttribute("UIScreen") == "store" and "" or "store")
end)
local storeOpenedAt = 0
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	local s = player:GetAttribute("UIScreen")
	panel.Visible = s == "store"
	btn.Visible = s == nil or s == "" or s == "store"
	if panel.Visible then
		refresh()
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(1000, 600)
		local base = math.min(1, (v.X - 30) / 900, (v.Y - 90) / 480)
		pScale.Scale = base * 0.7
		TweenService:Create(pScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = base }):Play()
		storeOpenedAt = os.clock()
	end
end)
player.AttributeChanged:Connect(function(n)
	if (string.sub(n, 1, 5) == "Pass_" or n == "NoPaidRandom" or n == "Save_StarterBought") and panel.Visible then
		refresh()
	end
end)
task.delay(3, refresh)
RunService.RenderStepped:Connect(function()
	if not panel.Visible then
		return
	end
	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.ViewportSize
		local base = math.min(1, (v.X - 30) / 900, (v.Y - 90) / 480)
		if os.clock() - storeOpenedAt > 0.3 then
			pScale.Scale = base -- подстраиваемся под поворот/размер экрана
		end
	end
end)
