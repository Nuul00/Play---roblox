-- Обмен питомцами (клиент). Кнопка 🤝 TRADE слева → список игроков сервера → запрос.
-- Входящий запрос — плашка сверху (Accept / Decline). Окно обмена: слева твой оффер, справа — его,
-- снизу твои свободные питомцы (клик — положить 1, клик по своему слоту — убрать 1).
-- READY у обоих → 5 с отсчёт. Всё проверяет сервер (Trading.server), клиент только показывает.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local UISounds = require(ReplicatedStorage:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("TradeRemote")

local K = require(ReplicatedStorage:WaitForChild("UIKit"))
local INK = K.INK
local GREEN = Color3.fromRGB(80, 200, 100)
local RED = Color3.fromRGB(230, 80, 90)
local GOLD = K.GOLD
local RARITY = {
	Common = Color3.fromRGB(200, 205, 215), Uncommon = Color3.fromRGB(110, 230, 120), Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255), Mythic = Color3.fromRGB(255, 120, 80), Legendary = Color3.fromRGB(255, 190, 50), Secret = Color3.fromRGB(255, 90, 170),
}

local gui = Instance.new("ScreenGui")
gui.Name = "TradeUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50 -- выше кнопки Royal Egg (45)
gui.Parent = player:WaitForChild("PlayerGui")

local function text(parent, t, size, pos, ts, col)
	local l = K.text(parent, t, pos, size, ts or 18, col, 2)
	return l
end
local function codeInfo(code)
	local id, tier = ShopConfig.SplitPet(code)
	local def = Config.Pets[id]
	local mult = Config.GetPetMultiplier(id) * ShopConfig.VariantMult(tier)
	local prefix = tier > 0 and (ShopConfig.Variants[tier].Name .. " ") or ""
	return def, prefix .. (def and def.Name or "?"), mult, tier
end
-- карточка питомца: тёмное стекло, рамка цвета редкости, 3D-модель, имя и сила
local function petCard(parent, code, count, size)
	local def, name, mult, tier = codeInfo(code)
	local rc = tier > 0 and ShopConfig.Variants[tier].Color or (def and RARITY[def.Rarity]) or INK
	local card = Instance.new("TextButton")
	card.Size = size
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.Text = ""
	card.AutoButtonColor = false
	card.Parent = parent
	K.corner(card, 12)
	K.grad(card, rc:Lerp(K.CARD, 0.7), K.CARD2)
	K.stroke(card, rc, 2.5)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Size = UDim2.new(1, 0, 1, -24)
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.LightDirection = Vector3.new(-1, -1, -2)
	view.Parent = card
	local ok, model = pcall(PetVisuals.BuildCode, code)
	if ok and model then
		local wm = Instance.new("WorldModel")
		wm.Parent = view
		model.Parent = wm
		local _, ext = model:GetBoundingBox()
		local d = math.max(ext.X, ext.Y, ext.Z)
		local cam = Instance.new("Camera")
		cam.FieldOfView = 40
		cam.CFrame = CFrame.lookAt(model:GetBoundingBox().Position + Vector3.new(d * 0.9, d * 0.5, -d * 1.6), model:GetBoundingBox().Position)
		cam.Parent = view
		view.CurrentCamera = cam
	end
	K.text(card, name, UDim2.new(0, 3, 1, -25), UDim2.new(1, -6, 0, 13), 13, Color3.new(1, 1, 1), 1.5)
	K.text(card, "×" .. NumberFormat.Short(mult), UDim2.new(0, 3, 1, -13), UDim2.new(1, -6, 0, 12), 12, Color3.fromRGB(255, 225, 120), 1.5)
	if count and count > 1 then
		local badge = K.text(card, "x" .. count, UDim2.new(1, -36, 0, 3), UDim2.fromOffset(32, 18), 14, Color3.new(1, 1, 1), 1.5)
		badge.BackgroundTransparency = 0
		badge.BackgroundColor3 = Color3.fromRGB(230, 140, 40)
		K.corner(badge, 9)
	end
	local sc = Instance.new("UIScale")
	sc.Parent = card
	card.MouseEnter:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1.06 }):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	return card
end
-- аватарка игрока (кругом с обводкой)
local function avatar(parent, userId, pos, sz)
	local img = Instance.new("ImageLabel")
	img.Position = pos
	img.Size = UDim2.fromOffset(sz, sz)
	img.BackgroundColor3 = Color3.fromRGB(90, 70, 170)
	img.Parent = parent
	K.corner(img, UDim.new(1, 0))
	K.stroke(img, GOLD, 2.5)
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok then
			img.Image = url
		end
	end)
	return img
end

-- ===== кнопка =====
local open = K.button(gui, "🤝 TRADE", UDim2.new(0, 16, 0.5, -54), UDim2.fromOffset(124, 44), K.BLUE, 19)
-- имя — для HudLayout (ставит кнопку под Royal Egg), масштаб — общий для HUD (Responsive)
open.Name = "TradeOpen"
require(game:GetService("ReplicatedStorage"):WaitForChild("Responsive")).Bind(open:FindFirstChildWhichIsA("UIScale"))
open.AnchorPoint = Vector2.new(0, 0.5)

-- ===== список игроков =====
local list, listClose, listScale = K.window(gui, "TradeList", 420, 380, "🤝 TRADE", K.BLUE)
K.text(list, "Pick a player to send a trade request", UDim2.fromOffset(30, 46), UDim2.new(1, -60, 0, 24), 18, Color3.fromRGB(215, 200, 255), 0)
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(20, 80)
scroll.Size = UDim2.new(1, -40, 1, -100)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = GOLD
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = list
local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 10)
lay.Parent = scroll
local function fillList()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local any = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			any = true
			local row = K.frame(scroll, UDim2.new(), UDim2.new(1, -10, 0, 66), Color3.new(1, 1, 1), 16)
			K.grad(row, K.CARD, K.CARD2)
			K.stroke(row, Color3.fromRGB(120, 90, 220), 2)
			avatar(row, p.UserId, UDim2.fromOffset(10, 9), 48)
			local nm = K.text(row, p.DisplayName, UDim2.fromOffset(68, 10), UDim2.new(1, -190, 0, 26), 20, nil, 2)
			nm.TextXAlignment = Enum.TextXAlignment.Left
			local un = K.text(row, "@" .. p.Name, UDim2.fromOffset(68, 36), UDim2.new(1, -190, 0, 18), 14, Color3.fromRGB(190, 175, 235), 0)
			un.TextXAlignment = Enum.TextXAlignment.Left
			local b = K.button(row, "TRADE", UDim2.new(1, -112, 0, 12), UDim2.fromOffset(100, 42), K.GREEN, 19)
			b.Activated:Connect(function()
				remote:FireServer("request", p.UserId)
				list.Visible = false
				UISounds.Play("click")
			end)
		end
	end
	if not any then
		local box = K.frame(scroll, UDim2.new(), UDim2.new(1, -10, 0, 150), Color3.new(1, 1, 1), 16)
		K.grad(box, K.CARD, K.CARD2)
		K.text(box, "👥", UDim2.fromOffset(0, 12), UDim2.new(1, 0, 0, 56), 50, nil, 0)
		K.text(box, "No other players here yet", UDim2.fromOffset(10, 72), UDim2.new(1, -20, 0, 28), 22)
		K.text(box, "Invite a friend: +10% coins for each friend!", UDim2.fromOffset(10, 104), UDim2.new(1, -20, 0, 22), 16, Color3.fromRGB(200, 185, 245), 0)
	end
end
open.Activated:Connect(function()
	UISounds.Play("click")
	list.Visible = not list.Visible
	if list.Visible then
		fillList()
	end
end)
listClose.Activated:Connect(function()
	list.Visible = false
end)

-- ===== входящий запрос =====
local req = K.frame(gui, UDim2.new(0.5, 0, 0, 110), UDim2.fromOffset(440, 120), Color3.new(1, 1, 1), 20)
req.AnchorPoint = Vector2.new(0.5, 0)
req.Visible = false
K.grad(req, Color3.fromRGB(62, 36, 130), Color3.fromRGB(20, 12, 52))
K.stroke(req, GOLD, 4)
local reqAvatar
local reqText = K.text(req, "", UDim2.fromOffset(84, 12), UDim2.new(1, -96, 0, 40), 22)
reqText.TextXAlignment = Enum.TextXAlignment.Left
local accept = K.button(req, "✔ ACCEPT", UDim2.fromOffset(84, 62), UDim2.fromOffset(160, 44), K.GREEN, 19)
local decline = K.button(req, "DECLINE", UDim2.fromOffset(258, 62), UDim2.fromOffset(160, 44), K.RED, 19)
local reqFrom
accept.Activated:Connect(function()
	if reqFrom then
		remote:FireServer("respond", reqFrom, true)
	end
	req.Visible = false
end)
decline.Activated:Connect(function()
	if reqFrom then
		remote:FireServer("respond", reqFrom, false)
	end
	req.Visible = false
end)

-- ===== окно обмена =====
local win, winClose, winScale, title = K.window(gui, "TradeWindow", 840, 580, "🤝 TRADE", K.BLUE, 560)
local function side(x, label, accent)
	local f, h = K.section(win, UDim2.fromOffset(x, 52), UDim2.fromOffset(372, 250), label, accent)
	local st = K.text(f, "", UDim2.new(1, -128, 0, 4), UDim2.fromOffset(118, 24), 16, Color3.new(1, 1, 1), 1.5)
	st.BackgroundColor3 = Color3.fromRGB(60, 170, 70)
	st.BackgroundTransparency = 1
	K.corner(st, 10)
	local grid = Instance.new("Frame")
	grid.Position = UDim2.fromOffset(10, 42)
	grid.Size = UDim2.new(1, -20, 1, -52)
	grid.BackgroundTransparency = 1
	grid.Parent = f
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(112, 62)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.Parent = grid
	local empty = K.text(f, "Empty", UDim2.fromOffset(10, 120), UDim2.new(1, -20, 0, 26), 20, Color3.fromRGB(150, 135, 200), 0)
	return grid, st, h, f, empty
end
local myGrid, myStatus, _, mySide, myEmpty = side(24, "YOUR OFFER", Color3.fromRGB(255, 180, 50))
local theirGrid, theirStatus, theirHead, theirSide, theirEmpty = side(444, "THEIR OFFER", Color3.fromRGB(90, 170, 255))
-- стрелки обмена между сторонами
local swap = K.frame(win, UDim2.fromOffset(398, 150), UDim2.fromOffset(44, 44), Color3.new(1, 1, 1), UDim.new(1, 0))
K.grad(swap, Color3.fromRGB(255, 225, 90), Color3.fromRGB(240, 140, 30))
K.stroke(swap, INK, 3)
K.text(swap, "⇄", UDim2.fromOffset(0, 2), UDim2.fromOffset(44, 40), 30, nil, 2)
local ready, readyLabel, readyColors = K.button(win, "READY", UDim2.new(0.5, -110, 0, 312), UDim2.fromOffset(220, 52), K.GREEN, 26)
local countdown = K.text(win, "", UDim2.new(0.5, 122, 0, 322), UDim2.fromOffset(260, 30), 18, GOLD, 2)
countdown.TextXAlignment = Enum.TextXAlignment.Left
local invSec = K.section(win, UDim2.fromOffset(24, 376), UDim2.fromOffset(792, 184), "YOUR PETS  ·  click to add, click your offer to remove  ·  team pets can't be traded", Color3.fromRGB(150, 100, 240))
local inv = Instance.new("ScrollingFrame")
inv.Position = UDim2.fromOffset(8, 38)
inv.Size = UDim2.new(1, -16, 1, -44)
inv.BackgroundTransparency = 1
inv.BorderSizePixel = 0
inv.ScrollBarThickness = 6
inv.ScrollBarImageColor3 = GOLD
inv.AutomaticCanvasSize = Enum.AutomaticSize.Y
inv.CanvasSize = UDim2.new()
inv.Parent = invSec
local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize = UDim2.fromOffset(112, 64)
invGrid.CellPadding = UDim2.fromOffset(6, 6)
invGrid.Parent = inv
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingTop = UDim.new(0, 4), UDim.new(0, 4)
pad.Parent = inv

local state
local function clear(f)
	for _, c in ipairs(f:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end
local function freeCount(code)
	local id, tier = ShopConfig.SplitPet(code)
	local n = player:GetAttribute(ShopConfig.OwnedAttr(id, tier)) or 0
	for _, c in ipairs(ShopConfig.ParseEquipped(player:GetAttribute("Equipped"))) do
		if c == code then
			n -= 1
		end
	end
	return math.max(0, n)
end
local function offered(code)
	for _, e in ipairs(state and state.Mine or {}) do
		if e.Code == code then
			return e.Count
		end
	end
	return 0
end
local function render()
	if not state then
		return
	end
	theirHead.Text = string.upper(state.WithName) .. "'S OFFER"
	title.Text = "🤝 TRADE WITH " .. string.upper(state.WithName)
	myEmpty.Visible = #state.Mine == 0
	theirEmpty.Visible = #state.Theirs == 0
	clear(myGrid)
	clear(theirGrid)
	for _, e in ipairs(state.Mine) do
		local c = petCard(myGrid, e.Code, e.Count, UDim2.fromOffset(112, 62))
		c.Activated:Connect(function()
			remote:FireServer("set", e.Code, e.Count - 1)
			UISounds.Play("click")
		end)
	end
	for _, e in ipairs(state.Theirs) do
		petCard(theirGrid, e.Code, e.Count, UDim2.fromOffset(112, 62))
	end
	-- готовность: зелёная плашка и зелёная рамка стороны
	myStatus.Text = state.MyReady and "✔ READY" or ""
	theirStatus.Text = state.TheirReady and "✔ READY" or ""
	myStatus.BackgroundTransparency = state.MyReady and 0 or 1
	theirStatus.BackgroundTransparency = state.TheirReady and 0 or 1
	mySide:FindFirstChildOfClass("UIStroke").Color = state.MyReady and GREEN or Color3.fromRGB(255, 180, 50)
	theirSide:FindFirstChildOfClass("UIStroke").Color = state.TheirReady and GREEN or Color3.fromRGB(90, 170, 255)
	readyLabel.Text = state.MyReady and "UNREADY" or "READY"
	readyColors(state.MyReady and K.ORANGE or K.GREEN)
	-- инвентарь: свободные питомцы, сильнейшие сначала
	clear(inv)
	local codes = {}
	for id = 1, Config.MaxPetId do if not Config.Pets[id] then continue end
		for tier = 0, #ShopConfig.Variants do
			local code = ShopConfig.PetCode(id, tier)
			local left = freeCount(code) - offered(code)
			if left > 0 then
				table.insert(codes, { code = code, left = left, mult = Config.GetPetMultiplier(id) * ShopConfig.VariantMult(tier) })
			end
		end
	end
	table.sort(codes, function(a, b)
		return a.mult > b.mult
	end)
	for i, e in ipairs(codes) do
		if i > 60 then
			break
		end
		local c = petCard(inv, e.code, e.left, UDim2.fromOffset(112, 64))
		c.Activated:Connect(function()
			remote:FireServer("set", e.code, offered(e.code) + 1)
			UISounds.Play("click")
		end)
	end
	if #codes == 0 then
		K.text(inv, "No free pets: pets in your team can't be traded. Unequip some in your inventory.", UDim2.new(), UDim2.fromOffset(760, 40), 17, Color3.fromRGB(200, 185, 245), 0)
	end
end
ready.Activated:Connect(function()
	if state then
		remote:FireServer("ready", not state.MyReady)
		UISounds.Play("click")
	end
end)
winClose.Activated:Connect(function()
	remote:FireServer("cancel")
end)

remote.OnClientEvent:Connect(function(kind, d)
	if kind == "request" then
		reqFrom = d.From
		reqText.Text = d.Name .. " wants to trade with you!"
		if reqAvatar then
			reqAvatar:Destroy()
		end
		reqAvatar = avatar(req, d.From, UDim2.fromOffset(16, 16), 56)
		req.Visible = true
		UISounds.Play("reward")
		local token = d.From
		task.delay(d.TTL or 20, function()
			if reqFrom == token then
				req.Visible = false
			end
		end)
	elseif kind == "state" then
		state = d
		list.Visible = false
		req.Visible = false
		if not win.Visible then
			win.Visible = true
			UISounds.Play("unlock")
		end
		render()
	elseif kind == "closed" then
		state = nil
		win.Visible = false
		if d.Done then
			UISounds.Play("fanfare")
		end
		local toast = K.text(gui, d.Done or d.Reason or "Trade closed", UDim2.new(0.5, -260, 0.25, 0), UDim2.fromOffset(520, 44), 28, d.Done and GOLD or Color3.fromRGB(255, 160, 160), 3)
		task.delay(2.5, function()
			toast:Destroy()
		end)
	end
end)

RunService.RenderStepped:Connect(function()
	if state and state.Ends then
		local left = state.Ends - workspace:GetServerTimeNow()
		countdown.Text = left > 0 and ("Trading in " .. math.ceil(left) .. "...") or "Trading..."
	else
		countdown.Text = state and "Both must press READY" or ""
	end
end)
-- окна не больше экрана (телефоны, маленькие окна)
local function fit()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	-- у окон UIKit уже есть свой UIScale — второй на том же объекте Roblox игнорирует
	for _, f in ipairs({ win, list, req }) do
		local sc = f:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		sc.Scale = math.min(1, (vp.X - 24) / f.Size.X.Offset, (vp.Y - 100) / (f.Size.Y.Offset + 30))
		sc.Parent = f
	end
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
-- инвентарь меняется (вылупил, отдал) — перерисовать
local pending = false
player.AttributeChanged:Connect(function(name)
	if win.Visible and not pending and (name == "Equipped" or name:sub(1, 8) == "PetOwned" or name:sub(1, 7) == "PetGold" or name:sub(1, 10) == "PetDiamond" or name:sub(1, 10) == "PetRainbow") then
		pending = true
		task.delay(0.3, function()
			pending = false
			render()
		end)
	end
end)
