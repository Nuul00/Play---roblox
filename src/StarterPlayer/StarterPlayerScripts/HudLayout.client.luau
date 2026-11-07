-- HudLayout: выстраивает колонки кнопок HUD друг под другом на любом экране.
-- Раньше кнопки были привязаны к разным точкам (квест — к верху, Royal Egg и Trade — к середине
-- экрана), и на невысоком экране середина «заезжала» на панель квестов.
-- Теперь каждая кнопка стоит сразу под предыдущей видимой (скрытые пропускаются), отступ
-- масштабируется вместе с HUD (Responsive). Элементы остаются в своих ScreenGui — меняем только Y.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local R = require(ReplicatedStorage:WaitForChild("Responsive"))
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

local GAP = 8
-- { ScreenGui, элемент } сверху вниз; первый — якорь колонки, его не двигаем.
-- Limit — элемент, выше которого колонка должна закончиться; не влезает — кнопки встают в ряд
-- под якорем от левого края (телефон и другие низкие экраны).
local COLUMNS = {
	{ Items = { { "QuestLineUI", "QuestTracker" }, { "RoyalEggUI", "RoyalEggButton" }, { "TradeUI", "TradeOpen" } }, Limit = { "MainHUD", "Panels" } },
	{ Items = { { "MenuHUD", "TopRight" }, { "InviteHUD", "Invite" }, { "QuickTravelHUD", "TravelOpen" }, { "QuickTravelHUD", "TravelList" } } },
}

local function find(path)
	local g = pg:FindFirstChild(path[1])
	return g and g:FindFirstChild(path[2])
end

local function shown(o): boolean
	if not (o and o:IsA("GuiObject") and o.Visible) then
		return false
	end
	local g = o:FindFirstAncestorWhichIsA("ScreenGui")
	return g ~= nil and g.Enabled and o.AbsoluteSize.Y > 1
end

-- Высота без «дыхания» и hover: у кнопок с Responsive.Bind берём Size * Base, иначе AbsoluteSize.
local function height(o: GuiObject): number
	local sc = o:FindFirstChildWhichIsA("UIScale")
	local base = sc and tonumber(sc:GetAttribute("Base"))
	if base and o.Size.Y.Scale == 0 and o.AutomaticSize == Enum.AutomaticSize.None then
		return o.Size.Y.Offset * base
	end
	return o.AbsoluteSize.Y
end

local function width(o: GuiObject): number
	local sc = o:FindFirstChildWhichIsA("UIScale")
	local base = sc and tonumber(sc:GetAttribute("Base"))
	if base and o.Size.X.Scale == 0 and o.AutomaticSize == Enum.AutomaticSize.None then
		return o.Size.X.Offset * base
	end
	return o.AbsoluteSize.X
end

-- Исходная X-позиция (для возврата из «ряда» в колонку) и якорь по верхнему краю:
-- тогда пульсация кнопки не дёргает то, что под ней.
local prepared = setmetatable({}, { __mode = "k" })
local function prepare(o: GuiObject)
	local info = prepared[o]
	if info then
		return info
	end
	if o.AnchorPoint.Y ~= 0 then
		local top = o.AbsolutePosition.Y
		o.AnchorPoint = Vector2.new(o.AnchorPoint.X, 0)
		o.Position += UDim2.fromOffset(0, top - o.AbsolutePosition.Y)
	end
	info = { x = o.Position.X }
	prepared[o] = info
	return info
end

local function layoutColumn(column)
	local items = {}
	for _, path in ipairs(column.Items) do
		local o = find(path)
		if shown(o) then
			table.insert(items, o)
		end
	end
	if #items < 2 then
		return
	end
	local gap = GAP * R.Scale()
	local first = items[1]
	local top = first.AbsolutePosition.Y
	-- влезает ли вертикальная стопка над Limit
	local need = top + height(first)
	for i = 2, #items do
		need += gap + height(items[i])
	end
	local limitObj = column.Limit and find(column.Limit)
	local limit = shown(limitObj) and (limitObj.AbsolutePosition.Y - gap) or math.huge
	local row = need > limit
	local bottom = top + height(first)
	-- ряд — под якорем от левого края (у стенки), а не справа от квеста посреди экрана (баг 2026-11)
	local right = first.AbsolutePosition.X - gap
	local rowTop = bottom + gap
	for i = 2, #items do
		local o = items[i]
		local info = prepare(o)
		local ty = row and rowTop or (bottom + gap)
		local dy = math.floor(ty - o.AbsolutePosition.Y + 0.5)
		local pos = o.Position
		if row then
			local ax = o.AbsolutePosition.X
			local dx = math.floor(right + gap - ax + 0.5)
			if dx ~= 0 or dy ~= 0 then
				o.Position = pos + UDim2.fromOffset(dx, dy)
			end
			right = ax + dx + width(o)
		else
			if pos.X ~= info.x or dy ~= 0 then
				o.Position = UDim2.new(info.x, pos.Y + UDim.new(0, dy))
			end
			bottom = ty + height(o)
		end
	end
end

local function layout()
	for _, column in ipairs(COLUMNS) do
		layoutColumn(column)
	end
end

-- дешево (десяток элементов), зато сразу ловим смену экрана, сворачивание квеста, показ/скрытие кнопок
RunService.RenderStepped:Connect(function()
	local ok, err = pcall(layout)
	if not ok then
		warn("[HudLayout]", err)
	end
end)
