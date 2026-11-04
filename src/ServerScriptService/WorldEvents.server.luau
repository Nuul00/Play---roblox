-- Мировые события: по расписанию из ShopConfig.Events включает Golden Hour (x2 монет)
-- и Lucky Hour (удача на яйцах) для всего сервера. Сами бонусы применяет PlayerSystems.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

workspace:SetAttribute("EventId", "")
workspace:SetAttribute("EventEnd", 0)

local function run(def)
	workspace:SetAttribute("EventEnd", workspace:GetServerTimeNow() + def.Duration)
	workspace:SetAttribute("EventId", def.Id)
	task.wait(def.Duration)
	if workspace:GetAttribute("EventId") == def.Id then
		workspace:SetAttribute("EventId", "")
		workspace:SetAttribute("EventEnd", 0)
	end
end

task.spawn(function()
	task.wait(ShopConfig.EventFirstDelay)
	local index = 0
	while true do
		index = index % #ShopConfig.Events + 1
		local def = ShopConfig.Events[index]
		run(def)
		task.wait(math.max(ShopConfig.EventInterval - def.Duration, 30))
	end
end)
