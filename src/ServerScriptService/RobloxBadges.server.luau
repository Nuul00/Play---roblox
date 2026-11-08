-- Выдача настоящих бейджей Roblox за ачивки игры (таблица соответствий — RobloxBadgeIds.luau).
-- Ачивка в игре открывается атрибутом Badge<Id> = true (PlayerSystems). Как только он стал true —
-- выдаём бейдж Roblox. При входе выдаём и те, что игрок открыл раньше, до появления бейджей.
-- BadgeService сам не выдаёт бейдж дважды; в Studio выдача не работает (это нормально).
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local MAP = require(script.Parent:WaitForChild("RobloxBadgeIds"))

local given = {} -- [player][badgeId] = true — чтобы не дёргать API повторно за сессию

local function award(p: Player, achId: string)
	local badgeId = tonumber(MAP[achId]) or 0
	if badgeId <= 0 or p.Parent ~= Players then
		return
	end
	given[p] = given[p] or {}
	if given[p][badgeId] then
		return
	end
	given[p][badgeId] = true
	task.spawn(function()
		for attempt = 1, 3 do
			local okHas, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, p.UserId, badgeId)
			if okHas and has then
				return
			end
			local ok, err = pcall(BadgeService.AwardBadge, BadgeService, p.UserId, badgeId)
			if ok then
				return
			end
			if attempt == 3 then
				warn("[RobloxBadges] award failed", achId, badgeId, err)
				given[p][badgeId] = nil -- попробуем при следующем входе
			end
			task.wait(attempt * 2)
		end
	end)
end

local function watch(p: Player)
	for achId in pairs(MAP) do
		local attr = "Badge" .. achId
		p:GetAttributeChangedSignal(attr):Connect(function()
			if p:GetAttribute(attr) == true then
				award(p, achId)
			end
		end)
	end
	-- уже открытые ачивки (после загрузки профиля)
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent == Players and not p:GetAttribute("ProfileReady") and os.clock() - t0 < 120 do
			task.wait(1)
		end
		for achId in pairs(MAP) do
			if p:GetAttribute("Badge" .. achId) == true then
				award(p, achId)
				task.wait(0.2)
			end
		end
	end)
end

Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(watch, p)
end
Players.PlayerRemoving:Connect(function(p)
	given[p] = nil
end)
