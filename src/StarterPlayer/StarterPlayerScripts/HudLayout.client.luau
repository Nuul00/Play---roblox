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
	{ Items = { { "QuestLineUI", "QuestTracker" }, { "RoyalEggUI", "RoyalEggButton" }, { "TradeUI", "TradeOpen" } }, Limit = { "MainHUD", "Panels" }, Align = "left" },
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
	-- 2026-11: кнопки всегда колонкой у левой стены (ряд уводил TRADE от стены — фидбэк)
	local row = false
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
		elseif column.Align == "left" then
			-- левая колонка: левый край кнопки = левый край якоря (у стены), а не исходная X кнопки
			local dx = math.floor(first.AbsolutePosition.X - o.AbsolutePosition.X + 0.5)
			if dx ~= 0 or dy ~= 0 then
				o.Position = pos + UDim2.fromOffset(dx, dy)
			end
			bottom = ty + height(o)
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

-- ===== Список игроков (Tab) =====
-- 2026-11 (фидбэк: «значок настроек влезает в таб»): Roblox рисует список игроков в правом верхнем углу
-- поверх шестерёнки, INVITE и TRAVEL. Пока список открыт, правая колонка плавно уезжает под него,
-- а вкладка зелий справа — ещё ниже, если колонка до неё достаёт. Закрыли список — всё возвращается.
-- Открыт ли список, Roblox не сообщает (GetCore такого не знает), поэтому следим за клавишей Tab
-- (на телефоне список открывается из меню Roblox — там он и так компактный).
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local listOpen = false
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab and not UserInputService:GetFocusedTextBox() then
		listOpen = not listOpen
	end
end)
-- размеры списка Roblox (замер в Studio): шапка ~40 px, строка игрока ~44 px, верх в 4 px под панелью
local LIST_TOP, LIST_HEAD, LIST_ROW = 4, 40, 44
local applied = setmetatable({}, { __mode = "k" }) -- [элемент] = сколько px мы сейчас добавили к Y
local shiftNow = 0
local function setShift(o: GuiObject?, dy: number)
	if not o then
		return
	end
	local was = applied[o] or 0
	local d = math.floor(dy + 0.5) - was
	if d ~= 0 then
		o.Position += UDim2.fromOffset(0, d)
		applied[o] = was + d
	end
end
local function listShift(dt: number)
	local gear = find({ "MenuHUD", "TopRight" })
	if not gear then
		return
	end
	local open = listOpen and StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	local target = 0
	local cam = workspace.CurrentCamera
	local vh = cam and cam.ViewportSize.Y - GuiService:GetGuiInset().Y or 600
	if open then
		local h = math.min(LIST_HEAD + LIST_ROW * #Players:GetPlayers(), vh * 0.5)
		local baseTop = gear.AbsolutePosition.Y - (applied[gear] or 0)
		target = math.max(0, LIST_TOP + h + GAP - baseTop)
	end
	-- плавно (≈0.15 с), без рывка
	shiftNow += (target - shiftNow) * math.min(1, dt * 14)
	if math.abs(target - shiftNow) < 0.5 then
		shiftNow = target
	end
	setShift(gear, shiftNow)
	-- вкладка зелий справа: если низ колонки (последняя видимая кнопка) до неё дошёл — опускаем и её
	local dock = find({ "PotionHUD", "PotionDock" })
	if dock and cam and dock.AbsolutePosition.X > cam.ViewportSize.X / 2 then
		local last = gear
		for _, path in ipairs(COLUMNS[2].Items) do
			local o = find(path)
			if shown(o) and o.AbsolutePosition.Y > last.AbsolutePosition.Y then
				last = o
			end
		end
		local colBottom = last.AbsolutePosition.Y + height(last) + GAP * R.Scale()
		local dockBase = dock.AbsolutePosition.Y - (applied[dock] or 0)
		setShift(dock, shiftNow > 0 and math.max(0, colBottom - dockBase) or 0)
	elseif dock then
		setShift(dock, 0)
	end
end

-- дешево (десяток элементов), зато сразу ловим смену экрана, сворачивание квеста, показ/скрытие кнопок
RunService.RenderStepped:Connect(function(dt)
	pcall(listShift, dt)
	local ok, err = pcall(layout)
	if not ok then
		warn("[HudLayout]", err)
	end
end)
