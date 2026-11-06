-- Вкладки большой доски лидеров на островах (SurfaceGui «Rankings» с атрибутом Tabbed):
-- нажал на COINS / EGGS / PICKUPS — показывается эта таблица; если никто не трогает, вкладки
-- сами переключаются по кругу каждые 10 секунд. Всё локально: у каждого игрока своя вкладка.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ORDER = { "BoardCoins", "BoardEggs", "BoardPickups" }
local boards = {} -- gui -> { current, idleUntil, content }

local function show(st, part)
	st.current = part
	for _, name in ORDER do
		local page = st.content:FindFirstChild("Page_" .. name)
		local tab = st.content:FindFirstChild("Tab_" .. name)
		local on = name == part
		if page then page.Visible = on end
		if tab then
			TweenService:Create(tab, TweenInfo.new(0.2), { BackgroundTransparency = on and 0 or 0.45 }):Play()
			local rim = tab:FindFirstChild("Rim")
			if rim then rim.Thickness = on and 5 or 0 end
		end
	end
end

local function hook(gui)
	if boards[gui] or not gui:GetAttribute("Tabbed") then return end
	local content = gui:WaitForChild("Content", 10)
	if not content then return end
	local st = { current = "BoardCoins", idleUntil = 0, content = content }
	boards[gui] = st
	for _, name in ORDER do
		local tab = content:WaitForChild("Tab_" .. name, 10)
		if tab then
			tab.Activated:Connect(function()
				st.idleUntil = os.clock() + 30 -- выбрал сам — 30 с не листаем
				show(st, name)
			end)
		end
	end
	gui.AncestryChanged:Connect(function()
		if not gui:IsDescendantOf(workspace) then boards[gui] = nil end
	end)
end

local world = workspace:WaitForChild("CoinSpeedWorld")
for _, d in world:GetDescendants() do
	if d:IsA("SurfaceGui") and d.Name == "Rankings" then task.spawn(hook, d) end
end
world.DescendantAdded:Connect(function(d)
	if d:IsA("SurfaceGui") and d.Name == "Rankings" then task.defer(hook, d) end
end)

while true do
	task.wait(10)
	for _, st in boards do
		if os.clock() > st.idleUntil then
			local i = table.find(ORDER, st.current) or 1
			show(st, ORDER[i % #ORDER + 1])
		end
	end
end
