-- Бонусы трейлов в окне магазина трейлов партнёра (PlayerGui.TrailShop, скрипт TrailShopUI есть только в плейсе):
-- в каждой карточке Card_<Id> под ценой — цветная плашка «+10% coins · +5% speed», карточки чуть выше,
-- внизу окна — подсказка. Сам бонус считает сервер (PlayerSystems + TrailBonus).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TrailBonus = require(RS:WaitForChild("TrailBonus"))
local K = require(RS:WaitForChild("UIKit"))
local player = Players.LocalPlayer

local EXTRA = 26 -- на столько выше каждая карточка
local function patchCard(card: Instance)
	if not card:IsA("GuiObject") or card:GetAttribute("BonusPatched") then
		return
	end
	local id = card.Name:match("^Card_(.+)$")
	if not id or not TrailBonus.List[id] then
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
	K.text(pill, TrailBonus.Text(id), UDim2.fromOffset(6, 2), UDim2.new(1, -12, 1, -4), 14, nil, 1.5)
end

local function patch(shop: ScreenGui)
	local window = shop:WaitForChild("Window", 10)
	local cards = window and window:WaitForChild("Cards", 10)
	if not cards then
		return
	end
	if not window:GetAttribute("BonusPatched") then
		window:SetAttribute("BonusPatched", true)
		window.Size = window.Size + UDim2.fromOffset(0, EXTRA * 2 + 22)
		local grid = cards:FindFirstChildOfClass("UIGridLayout")
		if grid then
			grid.CellSize = grid.CellSize + UDim2.fromOffset(0, EXTRA)
		end
		local hint = K.text(window, "Equipped trail gives its bonus forever · earn ⚡ tokens from quests", UDim2.new(0, 20, 1, -30), UDim2.new(1, -40, 0, 20), 14, Color3.fromRGB(255, 230, 150), 1.5)
		hint.Name = "TrailHint"
	end
	for _, c in ipairs(cards:GetChildren()) do
		patchCard(c)
	end
	cards.ChildAdded:Connect(function(c)
		task.defer(patchCard, c)
	end)
end

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
