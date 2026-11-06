-- Предложение покупки в нужный момент (а не только по кнопке STORE):
--  • сервер ответил «не хватает монет» — карточка набора монет, который как раз про это;
--  • сразу после ребёрса (монеты обнулились) — большой набор (он считается от всего заработанного).
-- Не чаще раза в 4 минуты, не в первые 3 минуты игры, закрывается крестиком или сама через 8 с.
-- Где платные случайные предметы запрещены (NoPaidRandom), наборы монет не предлагаются.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer

local COOLDOWN, GRACE, SHOW = 240, 180, 8
local joinedAt = os.clock()
local lastShown = -1e9

local function product(key: string)
	for _, d in ipairs(StoreConfig.Products) do
		if d.Key == key and d.Id > 0 then
			return d
		end
	end
	return nil
end

local gui = Instance.new("ScreenGui")
gui.Name = "StoreOffer"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(1, 1)
card.Position = UDim2.new(1, -16, 1, -120)
card.Size = UDim2.fromOffset(270, 112)
card.BackgroundColor3 = Color3.fromRGB(60, 40, 110)
card.Visible = false
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
local cs = Instance.new("UIStroke")
cs.Thickness = 3
cs.Color = Color3.fromRGB(255, 200, 70)
cs.Parent = card
local scale = Instance.new("UIScale")
scale.Parent = card

local function text(y, h, size, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(14, y)
	l.Size = UDim2.new(1, -50, 0, h)
	l.Font = Enum.Font.FredokaOne
	l.TextSize = size
	l.TextColor3 = color
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Parent = card
	return l
end
local title = text(8, 24, 19, Color3.fromRGB(255, 220, 90))
local body = text(32, 22, 15, Color3.fromRGB(235, 230, 255))
local buy = Instance.new("TextButton")
buy.Position = UDim2.fromOffset(14, 62)
buy.Size = UDim2.new(1, -28, 0, 40)
buy.BackgroundColor3 = Color3.fromRGB(80, 200, 90)
buy.Font = Enum.Font.FredokaOne
buy.TextSize = 18
buy.TextColor3 = Color3.new(1, 1, 1)
buy.Parent = card
Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 12)
local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -6, 0, 6)
close.Size = UDim2.fromOffset(30, 30)
close.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
close.Text = "×"
close.Font = Enum.Font.FredokaOne
close.TextSize = 22
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = card
Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

local currentId, version = nil, 0
local function hide()
	card.Visible = false
	currentId = nil
end
close.Activated:Connect(hide)
buy.Activated:Connect(function()
	if currentId then
		MarketplaceService:PromptProductPurchase(player, currentId)
	end
	hide()
end)

local function offer(def, why: string)
	if not def or player:GetAttribute("NoPaidRandom") ~= false then
		return
	end
	local now = os.clock()
	if now - joinedAt < GRACE or now - lastShown < COOLDOWN then
		return
	end
	lastShown = now
	local amount = math.floor(math.max(def.Min or 0, (tonumber(player:GetAttribute("LifetimeEarned")) or 0) * (def.Share or 0)))
	title.Text = "💰 " .. def.Name
	body.Text = why .. " Get +" .. NumberFormat.Short(amount) .. " coins now!"
	buy.Text = "BUY"
	currentId = def.Id
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, def.Id, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux and currentId == def.Id then
			buy.Text = "BUY  R$ " .. info.PriceInRobux
		end
	end)
	card.Visible = true
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	version += 1
	local v = version
	task.delay(SHOW, function()
		if version == v then
			hide()
		end
	end)
end

ReplicatedStorage:WaitForChild("GameFeedback").OnClientEvent:Connect(function(message, success)
	if success or type(message) ~= "string" or not string.find(message, "Not enough coins", 1, true) then
		return
	end
	offer(product("CoinsSmall"), "Short on coins?")
end)
local rebirths = player:GetAttribute("Rebirths") or 0
player:GetAttributeChangedSignal("Rebirths"):Connect(function()
	local r = player:GetAttribute("Rebirths") or 0
	if r > rebirths then
		task.delay(3, function()
			offer(product("CoinsHuge"), "Fresh start!")
		end)
	end
	rebirths = r
end)
