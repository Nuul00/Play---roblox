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

local INK = Color3.fromRGB(25, 20, 45)
local PANEL = Color3.fromRGB(45, 55, 95)
local CARD = Color3.fromRGB(65, 78, 125)
local GREEN = Color3.fromRGB(80, 200, 100)
local RED = Color3.fromRGB(230, 80, 90)
local GOLD = Color3.fromRGB(255, 205, 70)
local RARITY = {
	Common = Color3.fromRGB(200, 205, 215), Uncommon = Color3.fromRGB(110, 230, 120), Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255), Mythic = Color3.fromRGB(255, 120, 80), Legendary = Color3.fromRGB(255, 190, 50), Secret = Color3.fromRGB(255, 90, 170),
}

local gui = Instance.new("ScreenGui")
gui.Name = "TradeUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50 -- выше кнопки Royal Egg (45)
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = o
end
local function stroke(o, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col or INK
	s.Thickness = th or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end
local function text(parent, t, size, pos, ts, col)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Text = t
	l.Font = Enum.Font.FredokaOne
	l.TextSize = ts or 18
	l.TextColor3 = col or Color3.new(1, 1, 1)
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = INK
	s.Parent = l
	return l
end
local function button(parent, t, size, pos, col, ts)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = col
	b.Text = t
	b.Font = Enum.Font.FredokaOne
	b.TextSize = ts or 18
	b.TextColor3 = Color3.new(1, 1, 1)
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 10)
	stroke(b, INK, 2)
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = b
	return b
end
local function codeInfo(code)
	local id, tier = ShopConfig.SplitPet(code)
	local def = Config.Pets[id]
	local mult = Config.GetPetMultiplier(id) * ShopConfig.VariantMult(tier)
	local prefix = tier > 0 and (ShopConfig.Variants[tier].Name .. " ") or ""
	return def, prefix .. (def and def.Name or "?"), mult, tier
end
local function petCard(parent, code, count, size)
	local def, name, mult, tier = codeInfo(code)
	local card = Instance.new("TextButton")
	card.Size = size
	card.BackgroundColor3 = CARD
	card.Text = ""
	card.AutoButtonColor = true
	card.Parent = parent
	corner(card, 10)
	stroke(card, tier > 0 and ShopConfig.Variants[tier].Color or (def and RARITY[def.Rarity]) or INK, 2.5)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Size = UDim2.new(1, 0, 1, -26)
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
	local n = text(card, name, UDim2.new(1, -6, 0, 14), UDim2.new(0, 3, 1, -26), 12, def and RARITY[def.Rarity] or nil)
	n.TextScaled = true
	text(card, "×" .. NumberFormat.Short(mult), UDim2.new(1, -6, 0, 12), UDim2.new(0, 3, 1, -13), 11, Color3.fromRGB(255, 230, 150))
	if count and count > 1 then
		local badge = text(card, "x" .. count, UDim2.fromOffset(34, 18), UDim2.new(1, -36, 0, 2), 15, GOLD)
		badge.TextXAlignment = Enum.TextXAlignment.Right
	end
	return card
end

-- ===== кнопка =====
local open = button(gui, "🤝 TRADE", UDim2.fromOffset(118, 40), UDim2.new(0, 16, 0.5, -54), Color3.fromRGB(70, 150, 230), 17)
open.AnchorPoint = Vector2.new(0, 0.5)

-- ===== список игроков =====
local list = Instance.new("Frame")
list.AnchorPoint = Vector2.new(0.5, 0.5)
list.Position = UDim2.fromScale(0.5, 0.5)
list.Size = UDim2.fromOffset(360, 380)
list.BackgroundColor3 = PANEL
list.Visible = false
list.Parent = gui
corner(list, 18)
stroke(list, GOLD, 3)
text(list, "🤝 TRADE WITH...", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 8), 24, GOLD)
local listClose = button(list, "X", UDim2.fromOffset(36, 36), UDim2.new(1, -44, 0, 8), RED, 20)
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(12, 56)
scroll.Size = UDim2.new(1, -24, 1, -68)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = list
local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 8)
lay.Parent = scroll
local function fillList()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local any = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			any = true
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 50)
			row.BackgroundColor3 = CARD
			row.Parent = scroll
			corner(row, 10)
			local nm = text(row, p.DisplayName, UDim2.new(1, -120, 1, 0), UDim2.fromOffset(12, 0), 18)
			nm.TextXAlignment = Enum.TextXAlignment.Left
			local b = button(row, "TRADE", UDim2.fromOffset(96, 36), UDim2.new(1, -104, 0, 7), GREEN, 17)
			b.Activated:Connect(function()
				remote:FireServer("request", p.UserId)
				list.Visible = false
				UISounds.Play("click")
			end)
		end
	end
	if not any then
		local l = text(scroll, "No other players here yet.\nInvite a friend!", UDim2.new(1, 0, 0, 60), UDim2.new(), 18)
		l.TextWrapped = true
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
local req = Instance.new("Frame")
req.AnchorPoint = Vector2.new(0.5, 0)
req.Position = UDim2.new(0.5, 0, 0, 110)
req.Size = UDim2.fromOffset(400, 104)
req.BackgroundColor3 = PANEL
req.Visible = false
req.Parent = gui
corner(req, 14)
stroke(req, GOLD, 3)
local reqText = text(req, "", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 6), 20)
reqText.TextWrapped = true
local accept = button(req, "✔ ACCEPT", UDim2.fromOffset(170, 42), UDim2.fromOffset(18, 52), GREEN, 18)
local decline = button(req, "✖ DECLINE", UDim2.fromOffset(170, 42), UDim2.new(1, -188, 0, 52), RED, 18)
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
local win = Instance.new("Frame")
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.Position = UDim2.fromScale(0.5, 0.5)
win.Size = UDim2.fromOffset(780, 520)
win.BackgroundColor3 = PANEL
win.Visible = false
win.Parent = gui
corner(win, 20)
stroke(win, GOLD, 4)
local title = text(win, "TRADE", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 8), 26, GOLD)
local winClose = button(win, "X", UDim2.fromOffset(38, 38), UDim2.new(1, -46, 0, 8), RED, 20)
local function side(x, label)
	local f = Instance.new("Frame")
	f.Position = UDim2.fromOffset(x, 50)
	f.Size = UDim2.fromOffset(372, 236)
	f.BackgroundColor3 = Color3.fromRGB(35, 42, 75)
	f.Parent = win
	corner(f, 14)
	local h = text(f, label, UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, 4), 18)
	h.TextXAlignment = Enum.TextXAlignment.Left
	local st = text(f, "", UDim2.fromOffset(150, 26), UDim2.new(1, -158, 0, 4), 18, GREEN)
	st.TextXAlignment = Enum.TextXAlignment.Right
	local grid = Instance.new("Frame")
	grid.Position = UDim2.fromOffset(8, 34)
	grid.Size = UDim2.new(1, -16, 1, -42)
	grid.BackgroundTransparency = 1
	grid.Parent = f
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(112, 60)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.Parent = grid
	return grid, st, h
end
local myGrid, myStatus = side(12, "YOUR OFFER")
local theirGrid, theirStatus, theirHead = side(396, "THEIR OFFER")
local ready = button(win, "READY", UDim2.fromOffset(200, 46), UDim2.new(0.5, -100, 0, 292), GREEN, 22)
local countdown = text(win, "", UDim2.fromOffset(250, 26), UDim2.new(0.5, 110, 0, 302), 16, GOLD)
countdown.TextXAlignment = Enum.TextXAlignment.Left
local hint = text(win, "Click your pets below to add · click your offer to remove · only pets not in your team", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 342), 13, Color3.fromRGB(200, 205, 230))
hint.TextXAlignment = Enum.TextXAlignment.Left
local inv = Instance.new("ScrollingFrame")
inv.Position = UDim2.fromOffset(12, 366)
inv.Size = UDim2.new(1, -24, 0, 142)
inv.BackgroundColor3 = Color3.fromRGB(35, 42, 75)
inv.ScrollBarThickness = 6
inv.AutomaticCanvasSize = Enum.AutomaticSize.Y
inv.CanvasSize = UDim2.new()
inv.Parent = win
corner(inv, 12)
local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize = UDim2.fromOffset(112, 64)
invGrid.CellPadding = UDim2.fromOffset(6, 6)
invGrid.Parent = inv
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingTop = UDim.new(0, 6), UDim.new(0, 6)
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
	clear(myGrid)
	clear(theirGrid)
	for _, e in ipairs(state.Mine) do
		local c = petCard(myGrid, e.Code, e.Count, UDim2.fromOffset(112, 60))
		c.Activated:Connect(function()
			remote:FireServer("set", e.Code, e.Count - 1)
			UISounds.Play("click")
		end)
	end
	for _, e in ipairs(state.Theirs) do
		petCard(theirGrid, e.Code, e.Count, UDim2.fromOffset(112, 60))
	end
	myStatus.Text = state.MyReady and "READY ✓" or ""
	theirStatus.Text = state.TheirReady and "READY ✓" or ""
	ready.Text = state.MyReady and "UNREADY" or "READY"
	ready.BackgroundColor3 = state.MyReady and Color3.fromRGB(200, 150, 60) or GREEN
	-- инвентарь: свободные питомцы, сильнейшие сначала
	clear(inv)
	local codes = {}
	for id = 1, #Config.Pets do
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
		text(inv, "No free pets (pets in your team can't be traded)", UDim2.fromOffset(500, 30), UDim2.new(), 15)
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
		local toast = text(gui, d.Done or d.Reason or "Trade closed", UDim2.fromOffset(500, 40), UDim2.new(0.5, -250, 0.25, 0), 24, d.Done and GOLD or Color3.fromRGB(255, 160, 160))
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
		countdown.Text = state and "Both players must press READY" or ""
	end
end)
-- окна не больше экрана (телефоны, маленькие окна)
local function fit()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	for _, f in ipairs({ win, list, req }) do
		local sc = f:FindFirstChild("Fit") or Instance.new("UIScale")
		sc.Name = "Fit"
		sc.Scale = math.min(1, (vp.X - 24) / f.Size.X.Offset, (vp.Y - 70) / f.Size.Y.Offset)
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
