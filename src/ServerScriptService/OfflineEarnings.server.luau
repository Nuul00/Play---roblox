-- Доход, пока игрока не было: при входе — 10% от того, сколько он зарабатывал в минуту в прошлой
-- сессии, за каждую минуту отсутствия (от 5 минут, не больше 8 часов). Время — только серверное.
-- Save_LastSeen и Save_OfflineRate обновляются раз в минуту и сохраняются вместе с профилем.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local feedback = ReplicatedStorage:WaitForChild("GameFeedback")

local SHARE = 0.1
local MIN_AWAY, MAX_AWAY = 5 * 60, 8 * 3600

local session = {} -- [player] = { start = os.time(), earned0 = LifetimeEarned }

local function lifetime(p: Player): number
	return tonumber(p:GetAttribute("LifetimeEarned")) or 0
end

local function begin(p: Player)
	local now = os.time()
	local last = tonumber(p:GetAttribute("Save_LastSeen"))
	local rate = tonumber(p:GetAttribute("Save_OfflineRate")) or 0 -- монет в минуту прошлой сессии
	if last and rate > 0 then
		local away = math.clamp(now - last, 0, MAX_AWAY)
		if away >= MIN_AWAY then
			local stats = p:FindFirstChild("leaderstats")
			local coins = stats and stats:FindFirstChild("Coins")
			local reward = math.floor(rate * SHARE * away / 60)
			if coins and reward > 0 then
				coins.Value += reward
				task.delay(4, function()
					if p.Parent == Players then
						local h = math.floor(away / 3600)
						local m = math.floor(away / 60) % 60
						feedback:FireClient(p, string.format("💤 While you were away (%s): +%s coins", h > 0 and (h .. "h " .. m .. "m") or (m .. "m"), NumberFormat.Short(reward)), true)
					end
				end)
			end
		end
	end
	session[p] = { start = now, earned0 = lifetime(p) }
	p:SetAttribute("Save_LastSeen", now)
end

local function tick(p: Player)
	local s = session[p]
	if not s then
		return
	end
	local now = os.time()
	p:SetAttribute("Save_LastSeen", now)
	local minutes = (now - s.start) / 60
	-- скорость считаем после 3 минут игры, чтобы короткий заход не обнулял её
	if minutes >= 3 then
		p:SetAttribute("Save_OfflineRate", math.max(0, (lifetime(p) - s.earned0) / minutes))
	end
end

local function onPlayer(p: Player)
	if p:GetAttribute("ProfileReady") then
		begin(p)
		return
	end
	local conn
	conn = p:GetAttributeChangedSignal("ProfileReady"):Connect(function()
		if p:GetAttribute("ProfileReady") then
			conn:Disconnect()
			begin(p)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end
Players.PlayerRemoving:Connect(function(p)
	tick(p) -- если сохранение профиля успеет — запишется точное время выхода
	session[p] = nil
end)
task.spawn(function()
	while true do
		task.wait(60)
		for p in pairs(session) do
			tick(p)
		end
	end
end)
