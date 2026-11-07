-- Кнопка «🧭 TRAVEL» (геймпасс Quick Travel): список яиц, магазинов и машин текущего мира,
-- нажатие — телепорт туда. Без пасса кнопка предлагает его купить. Пока пасс не создан
-- (Id = 0), кнопка не показывается.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
local player = Players.LocalPlayer
local def = StoreConfig.PassByKey("QuickTravel")
if not def or (def.Id or 0) <= 0 then
	return
end
local remote = ReplicatedStorage:WaitForChild("QuickTravel")

local gui = Instance.new("ScreenGui")
gui.Name = "QuickTravelHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.Parent = player:WaitForChild("PlayerGui")

local function btn(parent, text, pos, size, color)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 17
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = Color3.fromRGB(20, 40, 70)
	s.Parent = b
	return b
end

local open = btn(gui, "🧭 TRAVEL", UDim2.new(1, -132, 0, 160), UDim2.fromOffset(118, 44), Color3.fromRGB(70, 160, 230))
local list = Instance.new("Frame")
list.AnchorPoint = Vector2.new(1, 0)
list.Position = UDim2.new(1, -14, 0, 210)
list.Size = UDim2.fromOffset(220, 10)
list.AutomaticSize = Enum.AutomaticSize.Y
list.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
list.Visible = false
list.Parent = gui
-- имена — для HudLayout (кнопка под Invite, список под кнопкой), масштаб — общий для HUD
open.Name = "TravelOpen"
-- по правому краю, как Invite: при масштабе HUD кнопки стоят ровной колонкой
open.AnchorPoint = Vector2.new(1, 0)
open.Position = UDim2.new(1, -14, 0, 160)
list.Name = "TravelList"
do
	local ResponsiveHUD = require(ReplicatedStorage:WaitForChild("Responsive"))
	for _, o in ipairs({ open, list }) do
		local s = Instance.new("UIScale")
		s.Parent = o
		ResponsiveHUD.Bind(s)
	end
end
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 12)
local pad = Instance.new("UIPadding")
pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6), UDim.new(0, 6), UDim.new(0, 6)
pad.Parent = list
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function refreshVisible()
	open.Visible = (player:GetAttribute("UIScreen") or "") == ""
	if not open.Visible then
		list.Visible = false
	end
end
player:GetAttributeChangedSignal("UIScreen"):Connect(refreshVisible)
refreshVisible()

open.Activated:Connect(function()
	if list.Visible then
		list.Visible = false
		return
	end
	if player:GetAttribute("Pass_QuickTravel") ~= true then
		MarketplaceService:PromptGamePassPurchase(player, def.Id)
		return
	end
	local ok, res = pcall(remote.InvokeServer, remote)
	if not ok or not res or not res.List then
		return
	end
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	for i, name in ipairs(res.List) do
		local b = btn(list, name, UDim2.new(), UDim2.new(1, 0, 0, 36), Color3.fromRGB(80, 110, 170))
		b.LayoutOrder = i
		b.TextSize = 15
		b.Activated:Connect(function()
			list.Visible = false
			pcall(remote.InvokeServer, remote, i)
		end)
	end
	list.Visible = #res.List > 0
end)
