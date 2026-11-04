-- Окна и HUD в цвет мира: инвентарь, индекс, ребитх, телепорт, магазины, машины, кнопки.
-- Перекрашиваем только «подложки» — тёмные и приглушённые цвета фонов, обводок и градиентов.
-- Яркие кнопки (купить/закрыть), цвета редкости и текст не трогаем, чтобы всё читалось как раньше.
-- Окно ежедневных заданий (DailyUI) не трогаем.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUIS = {
	Inventory = true,
	PetIndexBook = true,
	RebirthUI = true,
	TeleportUI = true,
	ShopPanels = true,
	WorkshopUI = true,
	PetMachineUI = true,
	CoinSprintHUD = true,
	CornerMenuHUD = true,
	MainHUD = true,
}

-- hue/sat — подложки, edgeHue/edgeSat — обводки, light — во сколько раз светлее.
local THEMES = {
	["Meadow Isles"] = { hue = 0.31, sat = 0.6, edgeHue = 0.13, edgeSat = 0.7, light = 1.25 },
	["Neon District"] = { hue = 0.78, sat = 0.72, edgeHue = 0.52, edgeSat = 0.8, light = 1.0 },
	["Sky Isles"] = { hue = 0.79, sat = 0.48, edgeHue = 0.12, edgeSat = 0.7, light = 1.7 },
	["Frozen Peaks"] = { hue = 0.58, sat = 0.6, edgeHue = 0.53, edgeSat = 0.3, light = 1.55 },
}

local theme = nil

-- Подходит ли цвет под «подложку»: тёмный/приглушённый или почти серый светлый.
local function remap(c: Color3, edge: boolean): Color3?
	if not theme then
		return nil
	end
	local h, s, v = c:ToHSV()
	local hue = edge and theme.edgeHue or theme.hue
	local sat = edge and theme.edgeSat or theme.sat
	if v < 0.62 and s < 0.78 then
		return Color3.fromHSV(hue, sat, math.min(1, v * theme.light))
	elseif s < 0.15 and v >= 0.62 and not edge then
		-- светлые серые плашки — лёгкий оттенок мира
		return Color3.fromHSV(hue, 0.12, v)
	end
	return nil
end

-- Для каждого свойства помним исходный цвет и тот, что поставили сами: если цвет поменял
-- другой скрипт (HudSkin, наведение мыши), берём его новым исходным.
local orig: { [Instance]: { [string]: any } } = setmetatable({}, { __mode = "k" }) :: any
local mine: { [Instance]: { [string]: any } } = setmetatable({}, { __mode = "k" }) :: any

local function source(inst: Instance, prop: string, current: any)
	local o, m = orig[inst], mine[inst]
	if not o then
		o, m = {}, {}
		orig[inst], mine[inst] = o, m
	end
	if o[prop] == nil or m[prop] ~= current then
		o[prop] = current
	end
	return o[prop]
end

local function setColor(inst: Instance, prop: string, edge: boolean)
	local current = (inst :: any)[prop]
	local base = source(inst, prop, current)
	local new = remap(base, edge) or base
	mine[inst][prop] = new
	if current ~= new then
		(inst :: any)[prop] = new
	end
end

local function setSequence(g: UIGradient)
	local current = g.Color
	local base = source(g, "Color", current)
	local keys = {}
	for i, k in ipairs(base.Keypoints) do
		keys[i] = ColorSequenceKeypoint.new(k.Time, remap(k.Value, false) or k.Value)
	end
	local new = ColorSequence.new(keys)
	mine[g].Color = new
	g.Color = new
end

local function paint(inst: Instance)
	if inst:IsA("GuiObject") then
		if inst.BackgroundTransparency < 1 then
			setColor(inst, "BackgroundColor3", false)
		end
	elseif inst:IsA("UIStroke") then
		setColor(inst, "Color", true)
	elseif inst:IsA("UIGradient") then
		setSequence(inst)
	end
end

local roots = {}
local function paintAll()
	for gui in pairs(roots) do
		if gui.Parent then
			for _, d in ipairs(gui:GetDescendants()) do
				paint(d)
			end
		end
	end
end

local function hook(gui: Instance)
	if not (gui:IsA("ScreenGui") and GUIS[gui.Name]) or roots[gui] then
		return
	end
	roots[gui] = true
	gui.DescendantAdded:Connect(function(d)
		task.defer(paint, d) -- ячейки инвентаря и списков появляются на лету
	end)
	for _, d in ipairs(gui:GetDescendants()) do
		paint(d)
	end
end

local function onWorld()
	theme = THEMES[player:GetAttribute("CurrentWorld") or ""]
	paintAll()
end

player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
playerGui.ChildAdded:Connect(function(g)
	task.wait(0.5) -- даём окну достроиться
	hook(g)
end)
task.wait(1)
theme = THEMES[player:GetAttribute("CurrentWorld") or ""]
for _, g in ipairs(playerGui:GetChildren()) do
	hook(g)
end
-- Некоторые окна пересобирают кнопки при открытии: раз в пару секунд докрашиваем.
while true do
	task.wait(2)
	if theme then
		paintAll()
	end
end
