-- Режим тестера (ТОЛЬКО в Roblox Studio, в живой игре не работает): при входе выдаёт всё,
-- чтобы искать баги: пройдены все квесты всех миров, открыты все миры, много монет,
-- ключи Coin Rush, зелья, жетоны трейлов, все этажи Coin Rush.
-- Включение: GameConfig.DevMaxInStudio. В чате: /max — выдать ещё раз, /coins 1e15 — задать монеты.
-- В Studio данные не сохраняются (EnableStudioDataStores = false), живой сейв это не трогает.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
if not RunService:IsStudio() then
	return
end
local Config = require(RS:WaitForChild("GameConfig"))
local Q = require(RS:WaitForChild("QuestLineConfig"))
local Worlds = require(RS:WaitForChild("WorldsConfig"))
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local feedback = RS:WaitForChild("GameFeedback")

local function max(p)
	local stats = p:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Coins") then
		stats.Coins.Value = 1e18
	end
	p:SetAttribute("LifetimeEarned", math.max(p:GetAttribute("LifetimeEarned") or 0, 1e18))
	-- все миры
	for _, w in ipairs(Worlds.Worlds) do
		if type(w) == "table" and w.Id then
			p:SetAttribute(Worlds.UnlockKey(w.Id), true)
		end
	end
	-- все квесты пройдены (+ постоянный бонус глав)
	local bonus = 1
	for _, s in ipairs(Q.Steps) do
		if s.Reward and s.Reward.Bonus then
			bonus += s.Reward.Bonus
		end
	end
	p:SetAttribute(Q.Attr.Ready, false)
	p:SetAttribute(Q.Attr.Step, #Q.Steps + 1)
	p:SetAttribute(Q.Attr.Bonus, bonus)
	-- Coin Rush: ключи и все этажи
	p:SetAttribute("Save_RushKeys", 50)
	p:SetAttribute("Save_RushFloor", 10)
	-- зелья
	for _, name in ipairs(ShopConfig.AllPotions or {}) do
		p:SetAttribute("Potion" .. name, 20)
	end
	-- жетоны трейлов (хранит QuestService партнёра)
	pcall(function()
		local m = script.Parent:FindFirstChild("QuestService", true)
		local qs = m and require(m)
		local st = qs and qs.GetState(p)
		if st then
			st.tokens = 999
			qs.Commit(p)
		end
	end)
	feedback:FireClient(p, "🛠 DEV MAX: all quests done, all worlds, 1Qi coins, keys, potions, 999 tokens", true)
end

local function onPlayer(p)
	p.Chatted:Connect(function(msg)
		local cmd, arg = msg:match("^/(%w+)%s*(%S*)")
		if cmd == "max" then
			max(p)
		elseif cmd == "coins" and tonumber(arg) then
			local stats = p:FindFirstChild("leaderstats")
			if stats then
				stats.Coins.Value = tonumber(arg)
			end
		end
	end)
	if not Config.DevMaxInStudio then
		return
	end
	task.spawn(function()
		local t = 0
		while p.Parent and not p:GetAttribute("ProfileReady") and t < 30 do
			t += task.wait(0.5)
		end
		task.wait(2) -- пусть остальные системы загрузят профиль
		if p.Parent then
			max(p)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end
