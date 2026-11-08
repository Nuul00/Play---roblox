-- Общий «уровень качества» клиентских эффектов (аудит 2026-11: каждый скрипт сам решал, сколько рисовать,
-- и слабые телефоны тормозили в Galaxy/Frozen/Magma).
--   FxBudget.Tier()        -> "low" | "mid" | "high"
--   FxBudget.Scale(n)      -> n * (0.35 / 0.6 / 1), округлено, не меньше 1
--   FxBudget.Pick(l, m, h) -> значение для текущего уровня
--   FxBudget.Every(hz)     -> троттлер: local tick = FxBudget.Every(10); if tick(dt) then ... end
--   FxBudget.Changed       -> BindableEvent, срабатывает при смене уровня
-- Уровень: телефон без клавиатуры — не выше "mid"; настройка графики Roblox 1–3 -> "low", 4–7 -> "mid";
-- если FPS держится ниже ~40 дольше 5 с — уровень опускается на ступень (только вниз, до перезахода).
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FxBudget = {}
local ORDER = { low = 1, mid = 2, high = 3 }
local NAMES = { "low", "mid", "high" }

local changed = Instance.new("BindableEvent")
FxBudget.Changed = changed.Event

local function qualityTier(): number
	local ok, q = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	q = ok and q or 0
	if q == 0 then
		return 3 -- «Автоматически»: решает адаптивная часть
	elseif q <= 3 then
		return 1
	elseif q <= 7 then
		return 2
	end
	return 3
end

local function baseTier(): number
	local t = qualityTier()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		t = math.min(t, 2) -- телефон/планшет
	end
	return t
end

local current = RunService:IsClient() and baseTier() or 3
local dropped = 0 -- на сколько ступеней опустили из-за низкого FPS

function FxBudget.Tier(): string
	return NAMES[math.clamp(current, 1, 3)]
end
function FxBudget.Level(): number
	return math.clamp(current, 1, 3)
end
function FxBudget.Pick(low, mid, high)
	local t = FxBudget.Level()
	if t == 1 then
		return low
	elseif t == 2 then
		return mid
	end
	return high
end
function FxBudget.Scale(n: number): number
	return math.max(1, math.floor(n * FxBudget.Pick(0.35, 0.6, 1) + 0.5))
end
function FxBudget.Every(hz: number)
	local period = 1 / hz
	local acc = 0
	return function(dt: number): boolean
		acc += dt
		if acc >= period then
			acc = acc % period
			return true
		end
		return false
	end
end

local function set(t: number)
	t = math.clamp(t, 1, 3)
	if t ~= current then
		current = t
		changed:Fire(FxBudget.Tier())
	end
end

if RunService:IsClient() then
	-- адаптивное понижение: скользящее среднее кадра
	local avg, slowFor = 1 / 60, 0
	RunService.Heartbeat:Connect(function(dt)
		avg = avg * 0.95 + dt * 0.05
		if avg > 1 / 40 then
			slowFor += dt
			if slowFor > 5 and current > 1 then
				dropped += 1
				slowFor = 0
				avg = 1 / 60
				set(current - 1)
			end
		else
			slowFor = 0
		end
	end)
	-- игрок поменял настройку графики
	pcall(function()
		UserSettings().GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
			set(baseTier() - dropped)
		end)
	end)
end

return FxBudget
