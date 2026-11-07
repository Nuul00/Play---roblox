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

-- ===== окно (стиль UIKit, как DAILY / инвентарь / киоск) =====
local K = require(ReplicatedStorage:WaitForChild("UIKit"))
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local gui = Instance.new("ScreenGui")
gui.Name = "StoreUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 45
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local W, H = 920, 510
local panel, close, pScale = K.window(gui, "StoreWindow", W, H, "🛒 STORE", K.ORANGE, 300)
panel.Position = UDim2.fromScale(0.5, 0.53)
close.Activated:Connect(function()
	player:SetAttribute("UIScreen", "")
end)

-- вкладки
local tab = "passes"
local tabSet = {}
local pages = {}
for i, t in ipairs({ { "passes", "⭐ GAMEPASSES" }, { "boosts", "⚡ BOOSTS" } }) do
	local b, _, set = K.button(panel, t[2], UDim2.fromOffset(24 + (i - 1) * 186, 46), UDim2.fromOffset(176, 40), K.GRAY, 19)
	tabSet[t[1]] = set
	b.Activated:Connect(function()
		tab = t[1]
		for k, pg in pairs(pages) do
			pg.Visible = k == tab
		end
		for k, f in pairs(tabSet) do
			f(k == tab and K.ORANGE or K.GRAY)
		end
	end)
end
local hint = K.text(panel, "Gamepasses are forever · boosts can be bought again", UDim2.new(0, 400, 0, 52), UDim2.new(1, -480, 0, 28), 15, rgb(210, 195, 255), 0)
hint.Font = Enum.Font.GothamBold
hint.TextXAlignment = Enum.TextXAlignment.Right

local function page(key)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.fromOffset(20, 98)
	scroll.Size = UDim2.new(1, -40, 1, -114)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = rgb(255, 220, 120)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Visible = key == tab
	scroll.Parent = panel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingLeft = UDim.new(0, 8), UDim.new(0, 4)
	pad.Parent = scroll
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(278, 172)
	g.CellPadding = UDim2.fromOffset(14, 14)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = scroll
	pages[key] = scroll
	return scroll
end

local refreshFn -- задаётся ниже (refresh)
local TAGS = { Coins2x = "POPULAR", VIP = "BEST", MythicLuck = "MAX LUCK", CoinsHuge = "BEST VALUE" }
local cards = {}
local function card(parent, def, isPass, order)
	local c = K.frame(parent, UDim2.new(), UDim2.new(), WHITE, 20)
	c.LayoutOrder = order
	K.grad(c, K.CARD:Lerp(def.Color, 0.28), K.CARD2)
	local st = K.stroke(c, def.Color, 3)
	-- светящийся шар с картинкой
	local orb = K.frame(c, UDim2.fromOffset(12, 18), UDim2.fromOffset(104, 104), WHITE, UDim.new(1, 0))
	K.grad(orb, def.Color:Lerp(WHITE, 0.45), def.Color:Lerp(BLACK, 0.35))
	K.stroke(orb, WHITE, 3)
	local shine = K.frame(orb, UDim2.fromScale(0.18, 0.08), UDim2.fromScale(0.64, 0.32), WHITE, UDim.new(1, 0))
	shine.BackgroundTransparency = 0.75
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Size = UDim2.fromOffset(96, 96)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = def.Image or ""
	img.Parent = orb
	local name = K.text(c, def.Name, UDim2.fromOffset(124, 12), UDim2.new(1, -134, 0, 30), 24, nil, 2.5)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local desc = K.text(c, def.Desc, UDim2.fromOffset(124, 44), UDim2.new(1, -134, 0, 62), 14, rgb(240, 232, 255), 0)
	desc.Font = Enum.Font.GothamBold
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	local buy, buyLabel, setBuy = K.button(c, "...", UDim2.new(0, 124, 1, -52), UDim2.new(1, -136, 0, 42), K.GREEN, 22)
	if TAGS[def.Key] then
		local tg = K.frame(c, UDim2.new(0, 4, 0, -10), UDim2.fromOffset(96, 24), WHITE, 12)
		tg.Rotation = -6
		tg.ZIndex = 5
		K.grad(tg, rgb(255, 120, 150), rgb(220, 40, 90))
		K.stroke(tg, K.INK, 2.5)
		K.text(tg, TAGS[def.Key], UDim2.fromOffset(4, 2), UDim2.new(1, -8, 1, -4), 14, nil, 1.5).ZIndex = 6
	end
	-- лёгкое покачивание иконки
	img.Rotation = -4
	TweenService:Create(img, TweenInfo.new(1.3 + (order % 3) * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 4 }):Play()
	local entry = { def = def, pass = isPass, buy = buy, label = buyLabel, set = setBuy, img = img, price = nil, frame = c, stroke = st }
	table.insert(cards, entry)
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, def.Id, isPass and Enum.InfoType.GamePass or Enum.InfoType.Product)
		if ok and info then
			if not def.Image and info.IconImageAssetId and info.IconImageAssetId > 0 then
				img.Image = "rbxassetid://" .. info.IconImageAssetId
			end
			entry.price = info.PriceInRobux
			if panel.Visible then
				task.defer(function()
					if refreshFn then
						refreshFn()
					end
				end)
			end
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

local passPage = page("passes")
for i, def in ipairs(StoreConfig.Passes) do
	if def.Id > 0 then
		card(passPage, def, true, i)
	end
end
local boostPage = page("boosts")
for i, def in ipairs(StoreConfig.Products) do
	if def.Id > 0 and not def.Hidden then
		card(boostPage, def, false, i)
	end
end
tabSet.passes(K.ORANGE)

local function refresh()
	for _, e in ipairs(cards) do
		-- товары, влияющие на случайные награды, скрыты, где они запрещены (и пока сервер не проверил)
		e.frame.Visible = not (e.def.Random and player:GetAttribute("NoPaidRandom") ~= false)
			and not (e.def.Kind == "starter" and player:GetAttribute("Save_StarterBought"))
		local owned = e.pass and player:GetAttribute("Pass_" .. e.def.Key)
		if owned then
			e.label.Text = "✔ OWNED"
			e.set(K.GRAY)
			e.stroke.Color = K.GOLD
		else
			e.label.Text = e.price and ("R$ " .. e.price) or "BUY"
			e.set(K.GREEN)
			e.stroke.Color = e.def.Color
		end
	end
end

refreshFn = refresh

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
		local base = math.min(1, (v.X - 30) / W, (v.Y - 90) / (H + 30))
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
		local base = math.min(1, (v.X - 30) / W, (v.Y - 90) / (H + 30))
		if os.clock() - storeOpenedAt > 0.3 then
			pScale.Scale = base -- подстраиваемся под поворот/размер экрана
		end
	end
end)
