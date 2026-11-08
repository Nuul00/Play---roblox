-- Бонусы и прокачка трейлов в окне магазина трейлов партнёра (PlayerGui.TrailShop):
-- * в карточке Card_<Id> — плашка бонуса с учётом уровня и кнопка «⬆ LV n · N⚡» (если трейл куплен);
-- * внизу окна — кнопка «⚡ SPEND TOKENS»: обмен жетонов на ключи Coin Rush и супер-зелья;
-- * подсказка, откуда брать жетоны. Покупки проверяет сервер (TokenShop.server).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local T = require(RS:WaitForChild("TrailBonus"))
local K = require(RS:WaitForChild("UIKit"))
local remote = RS:WaitForChild("TokenShop")
local player = Players.LocalPlayer

local EXTRA = 54 -- на столько выше каждая карточка
local cardsUi = {} -- id → { pill, label, up, upLabel, setUp }

local function state()
	local ok, st = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("QuestState") or "{}")
	return ok and type(st) == "table" and st or {}
end
local function refresh()
	local st = state()
	local owned = {}
	for _, id in ipairs(st.trails or {}) do
		owned[id] = true
	end
	local tokens = st.tokens or player:GetAttribute("SpeedTokens") or 0
	for id, u in pairs(cardsUi) do
		local lv = T.Level(player, id)
		u.label.Text = (lv > 1 and ("LV" .. lv .. " · ") or "") .. T.Text(id, lv)
		if not owned[id] then
			u.up.Visible = false
		else
			u.up.Visible = true
			if lv >= T.MaxLevel then
				u.upLabel.Text = "⭐ MAX LEVEL"
				u.setUp(K.GRAY)
			else
				local cost = T.UpgradeCost(id, lv)
				u.upLabel.Text = "⬆ LV" .. (lv + 1) .. " · " .. cost .. "⚡"
				u.setUp(tokens >= cost and K.PURPLE or K.GRAY)
			end
		end
	end
end

local function patchCard(card: Instance)
	if not card:IsA("GuiObject") or card:GetAttribute("BonusPatched") then
		return
	end
	local id = card.Name:match("^Card_(.+)$")
	if not id or not T.List[id] then
		return
	end
	card:SetAttribute("BonusPatched", true)
	local action = card:FindFirstChild("Action")
	if action and action:IsA("GuiObject") then
		action.Position = action.Position + UDim2.fromOffset(0, EXTRA)
	end
	local pill = K.frame(card, UDim2.new(0, 10, 0, 92), UDim2.new(1, -20, 0, 22), Color3.new(1, 1, 1), 11)
	pill.Name = "TrailBonus"
	K.grad(pill, Color3.fromRGB(255, 215, 90), Color3.fromRGB(235, 130, 30))
	K.stroke(pill, K.INK, 2)
	local label = K.text(pill, "", UDim2.fromOffset(6, 2), UDim2.new(1, -12, 1, -4), 14, nil, 1.5)
	local up, upLabel, setUp = K.button(card, "", UDim2.new(0, 10, 0, 120), UDim2.new(1, -20, 0, 26), K.PURPLE, 15)
	up.Name = "TrailUpgrade"
	up.Activated:Connect(function()
		local r = remote:InvokeServer("upgrade", id)
		if r and not r.Ok and r.Message then
			upLabel.Text = r.Message
			task.delay(1.2, refresh)
		end
	end)
	cardsUi[id] = { label = label, up = up, upLabel = upLabel, setUp = setUp }
	refresh()
end

-- обмен жетонов
local function buildExchange(window: GuiObject)
	local panel = K.frame(window, UDim2.new(0, 14, 0, 58), UDim2.new(1, -28, 1, -110), Color3.new(1, 1, 1), 18)
	panel.Name = "TokenExchange"
	panel.Visible = false
	panel.ZIndex = 20
	K.grad(panel, Color3.fromRGB(70, 44, 150), K.CARD2)
	K.stroke(panel, K.GOLD, 3)
	local t = K.text(panel, "⚡ SPEND TOKENS", UDim2.fromOffset(0, 8), UDim2.new(1, 0, 0, 30), 26, K.GOLD, 2.5)
	t.ZIndex = 21
	local n = #T.Exchange
	for i, e in ipairs(T.Exchange) do
		local w = 120
		local x = (i - 1) * (w + 12) - (n * (w + 12) - 12) / 2
		local c = K.frame(panel, UDim2.new(0.5, x, 0, 48), UDim2.fromOffset(w, 170), Color3.new(1, 1, 1), 16)
		c.ZIndex = 21
		K.grad(c, K.CARD:Lerp(Color3.fromRGB(255, 200, 80), 0.15), K.CARD2)
		K.stroke(c, Color3.fromRGB(150, 110, 255), 2)
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = e.Image
		img.Position = UDim2.new(0.5, -40, 0, 6)
		img.Size = UDim2.fromOffset(80, 80)
		img.ZIndex = 22
		img.Parent = c
		K.text(c, e.Name, UDim2.fromOffset(4, 88), UDim2.new(1, -8, 0, 24), 17, nil, 2).ZIndex = 22
		local b, bl = K.button(c, e.Cost .. " ⚡", UDim2.new(0, 10, 1, -50), UDim2.new(1, -20, 0, 40), K.GREEN, 20)
		b.ZIndex = 22
		for _, d in ipairs(b:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.ZIndex = 23
			end
		end
		b.Activated:Connect(function()
			local r = remote:InvokeServer("exchange", e.Key)
			bl.Text = r and r.Ok and "✔ GOT IT!" or (r and r.Message or "...")
			task.delay(1.2, function()
				bl.Text = e.Cost .. " ⚡"
			end)
		end)
	end
	local src = K.text(panel, string.format("Get ⚡ from quests, Coin Rush (+%d), Rebirth (+%d), Daily reward (+%d)", T.Sources.Rush, T.Sources.Rebirth, T.Sources.Daily), UDim2.new(0, 10, 1, -34), UDim2.new(1, -20, 0, 22), 14, Color3.fromRGB(225, 215, 255), 0)
	src.Font = Enum.Font.GothamBold
	src.ZIndex = 21
	return panel
end

local function patch(shop: ScreenGui)
	local window = shop:WaitForChild("Window", 10)
	local cards = window and window:WaitForChild("Cards", 10)
	if not cards then
		return
	end
	if not window:GetAttribute("BonusPatched") then
		window:SetAttribute("BonusPatched", true)
		window.Size = window.Size + UDim2.fromOffset(0, EXTRA * 2 + 34)
		local grid = cards:FindFirstChildOfClass("UIGridLayout")
		if grid then
			grid.CellSize = grid.CellSize + UDim2.fromOffset(0, EXTRA)
		end
		local panel = buildExchange(window)
		local toggle, tl = K.button(window, "⚡ SPEND TOKENS", UDim2.new(0.5, -110, 1, -46), UDim2.fromOffset(220, 38), K.ORANGE, 18)
		toggle.ZIndex = 25
		for _, d in ipairs(toggle:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.ZIndex = 26
			end
		end
		toggle.Activated:Connect(function()
			panel.Visible = not panel.Visible
			tl.Text = panel.Visible and "⬅ BACK TO TRAILS" or "⚡ SPEND TOKENS"
		end)
	end
	for _, c in ipairs(cards:GetChildren()) do
		patchCard(c)
	end
	cards.ChildAdded:Connect(function(c)
		task.defer(patchCard, c)
	end)
end

player.AttributeChanged:Connect(function(n)
	if n == "QuestState" or n == "SpeedTokens" or n:sub(1, 13) == "Save_TrailLv_" then
		refresh()
	end
end)

local pg = player:WaitForChild("PlayerGui")
local existing = pg:FindFirstChild("TrailShop")
if existing then
	task.spawn(patch, existing)
end
pg.ChildAdded:Connect(function(g)
	if g.Name == "TrailShop" then
		task.spawn(patch, g)
	end
end)
