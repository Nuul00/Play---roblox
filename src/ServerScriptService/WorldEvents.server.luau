-- Мировые события: Golden Hour (x2 монет) и Lucky Hour (удача на яйцах) по ОБЩЕМУ расписанию —
-- от часов UTC, поэтому на всех серверах событие идёт одновременно и время следующего известно
-- заранее (раньше отсчёт шёл от запуска сервера, и у каждого сервера было своё время).
-- Каждые EventInterval (15 мин) начинается следующее событие по кругу; в выходные (сб, вс по UTC)
-- события длятся вдвое дольше. Бонусы применяет PlayerSystems (по EventId).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local INTERVAL = ShopConfig.EventInterval
local EVENTS = ShopConfig.Events

local function isWeekend(t: number): boolean
	local wd = os.date("!*t", t).wday -- 1 = воскресенье, 7 = суббота
	return wd == 1 or wd == 7
end

local function slotInfo(t: number)
	local slot = math.floor(t / INTERVAL)
	local def = EVENTS[slot % #EVENTS + 1]
	local start = slot * INTERVAL
	local duration = def.Duration * (isWeekend(start) and 2 or 1)
	return def, start, math.min(duration, INTERVAL - 30)
end

workspace:SetAttribute("EventId", "")
workspace:SetAttribute("EventEnd", 0)
while true do
	local now = os.time()
	local def, start, duration = slotInfo(now)
	if now < start + duration then
		if workspace:GetAttribute("EventId") ~= def.Id then
			workspace:SetAttribute("EventEnd", start + duration)
			workspace:SetAttribute("EventId", def.Id)
		end
	elseif workspace:GetAttribute("EventId") ~= "" then
		workspace:SetAttribute("EventId", "")
		workspace:SetAttribute("EventEnd", 0)
	end
	local nextDef, nextStart = slotInfo(start + INTERVAL)
	workspace:SetAttribute("NextEventId", nextDef.Id)
	workspace:SetAttribute("NextEventAt", nextStart)
	workspace:SetAttribute("EventWeekend", isWeekend(now))
	task.wait(1)
end
