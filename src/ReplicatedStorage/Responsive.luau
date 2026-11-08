-- Responsive: один масштаб HUD для всего интерфейса + тип устройства. Пересчитывается сразу
-- при смене размера окна (полный экран, поворот телефона, другой монитор) или способа ввода.
-- Раньше каждый скрипт считал свой масштаб (Y/720, X/900, min(X/700,Y/520)...), и при смене экрана
-- элементы росли с разной скоростью и наезжали друг на друга.
-- Окна (магазин, инвентарь...) сами вписываются в экран — модуль для постоянных элементов HUD.
--
-- Использование (на клиенте):
--   local R = require(ReplicatedStorage.Responsive)
--   R.Scale()             -- текущий масштаб HUD (1 = экран 1280×720)
--   R.Device()            -- "Phone" | "Tablet" | "Desktop" | "Console"
--   R.Bind(uiScale, k)    -- держать UIScale = R.Scale()*k (+ атрибут Base для hover-анимаций)
--   R.Changed:Connect(fn) -- масштаб, устройство или размер экрана изменились
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local R = {}

-- Экран, под который рисовался HUD (все размеры в скриптах — в пикселях этого экрана).
R.Reference = Vector2.new(1280, 720)
-- Поправка под устройство: на телефоне кнопки чуть крупнее (палец толще курсора),
-- на консоли тоже (телевизор далеко от игрока).
R.DeviceMult = { Phone = 1.15, Tablet = 1.05, Desktop = 1, Console = 1.2 }
R.Min, R.Max = 0.5, 1.25
-- Левая колонка: панель квестов сверху + плашки статистики снизу ≈ 520 пикселей при масштабе 1.
-- На низком экране масштаб уменьшается, чтобы они не наехали друг на друга. Кнопки Royal Egg
-- и Trade HudLayout ставит между ними, а если там тесно (телефон) — в ряд справа от панели квестов.
R.ColumnHeight, R.ColumnMargin = 520, 40

local changed = Instance.new("BindableEvent")
R.Changed = changed.Event

local current = { scale = 1, device = "Desktop", viewport = R.Reference }

local function viewport(): Vector2
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or R.Reference
	if v.X < 2 or v.Y < 2 then
		return R.Reference
	end
	-- верхняя полоса Roblox (кнопки меню) занимает место по высоте
	local inset = GuiService:GetGuiInset()
	return Vector2.new(v.X, math.max(2, v.Y - inset.Y))
end

-- Тип устройства по тому, чем играют и какой экран. Ноутбук с сенсором и клавиатурой = Desktop.
function R.DetectDevice(v: Vector2?): string
	local vp = v or viewport()
	if GuiService:IsTenFootInterface() then
		return "Console"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return math.min(vp.X, vp.Y) <= 500 and "Phone" or "Tablet"
	end
	return "Desktop"
end

-- Чистая функция: масштаб для данного экрана и устройства (удобно тестировать).
function R.ComputeScale(v: Vector2, device: string): number
	local base = math.min(v.X / R.Reference.X, v.Y / R.Reference.Y) * (R.DeviceMult[device] or 1)
	local fit = (v.Y - R.ColumnMargin) / R.ColumnHeight
	return math.clamp(math.min(base, fit), R.Min, R.Max)
end

local function recompute()
	local v = viewport()
	local device = R.DetectDevice(v)
	local s = math.floor(R.ComputeScale(v, device) * 1000 + 0.5) / 1000
	if s ~= current.scale or device ~= current.device or v ~= current.viewport then
		current.scale, current.device, current.viewport = s, device, v
		local p = Players.LocalPlayer
		if p then
			p:SetAttribute("UIDevice", device)
			p:SetAttribute("UIScale", s)
		end
		changed:Fire(s, device, v)
	end
end

function R.Scale(): number
	return current.scale
end
function R.Device(): string
	return current.device
end
function R.Viewport(): Vector2
	return current.viewport
end
function R.IsTouch(): boolean
	return current.device == "Phone" or current.device == "Tablet"
end

-- Держит UIScale = масштаб HUD * mult. Атрибут Base — тот же масштаб: hover/пульсация
-- (UIKit.button, анимации кнопок) умножаются на него, а не сбрасывают в 1.
function R.Bind(uiScale: UIScale?, mult: number?)
	if not uiScale then
		return nil
	end
	local k = mult or 1
	local function apply()
		if uiScale.Parent then
			local s = current.scale * k
			uiScale:SetAttribute("Base", s)
			uiScale.Scale = s
		end
	end
	apply()
	local conn = changed.Event:Connect(apply)
	uiScale.Destroying:Connect(function()
		conn:Disconnect()
	end)
	return conn
end

-- Базовый масштаб элемента (для hover-анимаций): Base из R.Bind или 1.
function R.BaseOf(uiScale: UIScale): number
	return tonumber(uiScale:GetAttribute("Base")) or 1
end

if RunService:IsClient() then
	local camConn: RBXScriptConnection? = nil
	local function hookCamera()
		if camConn then
			camConn:Disconnect()
		end
		local cam = workspace.CurrentCamera
		if cam then
			camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
		end
		recompute()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)
	UserInputService.LastInputTypeChanged:Connect(recompute)
	hookCamera()
	-- страховка: в первые кадры ViewportSize бывает 1x1, а инсет верхней полосы приходит позже
	task.spawn(function()
		while true do
			task.wait(1)
			recompute()
		end
	end)
end

return R
