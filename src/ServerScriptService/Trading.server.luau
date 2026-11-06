-- Обмен питомцами между игроками. Всё решает сервер:
--  • запрос → у второго игрока всплывает «Принять / Отклонить» (20 с);
--  • каждый кладёт до 9 видов питомцев; класть можно только НЕ надетых (свободных) питомцев;
--  • любое изменение снимает «READY» у обоих; когда оба READY — 5 с отсчёта, затем сервер ещё раз
--    проверяет, что всё на месте, и меняет питомцев за один шаг (без пауз), сразу сохраняет оба профиля;
--  • выход, смерть, данж, телепорт в другой сервер — обмен отменяется, ничего не теряется.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))

local MAX_KINDS = 9
local COUNTDOWN = 5
local REQUEST_TTL = 20

local remote = Instance.new("RemoteEvent")
remote.Name = "TradeRemote"
remote.Parent = ReplicatedStorage

local trades = {} -- [player] = trade (у обоих участников одна и та же таблица)
local requests = {} -- [target] = { from = player, at = os.clock() }
local lastAction = {}

local function notify(p, text, ok)
	local fb = ReplicatedStorage:FindFirstChild("GameFeedback")
	if fb then
		fb:FireClient(p, text, ok or false)
	end
end
local function other(t, p)
	return t.a == p and t.b or t.a
end
local function validCode(code): boolean
	if type(code) ~= "number" or code ~= code or code ~= math.floor(code) or code < 1 then
		return false
	end
	local id, tier = ShopConfig.SplitPet(code)
	return Config.Pets[id] ~= nil and tier >= 0 and tier <= #ShopConfig.Variants
end
local function owned(p, code): number
	local id, tier = ShopConfig.SplitPet(code)
	return p:GetAttribute(ShopConfig.OwnedAttr(id, tier)) or 0
end
-- свободные = есть, но не в команде
local function free(p, code): number
	local inTeam = 0
	for _, c in ipairs(PlayerSystems.GetEquipped(p)) do
		if c == code then
			inTeam += 1
		end
	end
	return math.max(0, owned(p, code) - inTeam)
end
local function busy(p): boolean
	return p:GetAttribute("InRush") == true or not p:GetAttribute("ProfileReady")
end

local function snapshot(t)
	local function list(p)
		local out = {}
		for code, n in pairs(t.offer[p]) do
			table.insert(out, { Code = code, Count = n })
		end
		table.sort(out, function(x, y)
			return x.Code < y.Code
		end)
		return out
	end
	return t, list
end
local function push(t)
	local _, list = snapshot(t)
	for _, p in ipairs({ t.a, t.b }) do
		local o = other(t, p)
		if p.Parent == Players then
			remote:FireClient(p, "state", {
				With = o.UserId,
				WithName = o.DisplayName,
				Mine = list(p),
				Theirs = list(o),
				MyReady = t.ready[p] == true,
				TheirReady = t.ready[o] == true,
				Ends = t.ends and (workspace:GetServerTimeNow() + (t.ends - os.clock())) or nil,
			})
		end
	end
end
local function close(t, reason: string?, okText: string?)
	if t.closed then
		return
	end
	t.closed = true
	for _, p in ipairs({ t.a, t.b }) do
		if trades[p] == t then
			trades[p] = nil
		end
		if p.Parent == Players then
			p:SetAttribute("Trading", nil)
			remote:FireClient(p, "closed", { Reason = reason, Done = okText })
		end
	end
end
local function unready(t)
	t.ready[t.a], t.ready[t.b], t.ends = nil, nil, nil
end

local function execute(t)
	-- финальная проверка: у каждого всё ещё есть свободные питомцы на весь его оффер
	for _, p in ipairs({ t.a, t.b }) do
		if p.Parent ~= Players or busy(p) then
			close(t, "Trade cancelled")
			return
		end
		for code, n in pairs(t.offer[p]) do
			if free(p, code) < n then
				close(t, "Trade cancelled: pets changed")
				return
			end
		end
	end
	if next(t.offer[t.a]) == nil and next(t.offer[t.b]) == nil then
		close(t, "Nothing to trade")
		return
	end
	-- обмен одним шагом (без yield между списанием и начислением)
	local moves = {}
	for _, from in ipairs({ t.a, t.b }) do
		local to = other(t, from)
		for code, n in pairs(t.offer[from]) do
			local id, tier = ShopConfig.SplitPet(code)
			local attr = ShopConfig.OwnedAttr(id, tier)
			from:SetAttribute(attr, (from:GetAttribute(attr) or 0) - n)
			to:SetAttribute(attr, (to:GetAttribute(attr) or 0) + n)
			table.insert(moves, { to = to, code = code })
		end
	end
	for _, m in ipairs(moves) do
		pcall(PlayerSystems.OnHatched, m.to, m.code)
	end
	for _, p in ipairs({ t.a, t.b }) do
		pcall(PlayerSystems.SetEquipped, p, PlayerSystems.GetEquipped(p))
		p:SetAttribute("Save_Trades", (p:GetAttribute("Save_Trades") or 0) + 1)
	end
	print("[Trade] " .. t.a.Name .. " <-> " .. t.b.Name .. ": " .. #moves .. " pet kinds moved")
	local saveNow = ServerStorage:FindFirstChild("SaveProfileNow")
	if saveNow then
		for _, p in ipairs({ t.a, t.b }) do
			task.spawn(pcall, saveNow.Invoke, saveNow, p)
		end
	end
	close(t, nil, "Trade complete!")
end

remote.OnServerEvent:Connect(function(p, action, a1, a2)
	local now = os.clock()
	if lastAction[p] and now - lastAction[p] < 0.12 then
		return -- антиспам
	end
	lastAction[p] = now
	if action == "request" then
		local target = type(a1) == "number" and Players:GetPlayerByUserId(a1)
		if not target or target == p then
			return
		end
		if trades[p] or trades[target] then
			notify(p, "That player is already trading")
			return
		end
		if busy(p) or busy(target) then
			notify(p, "Can't trade right now")
			return
		end
		local r = requests[target]
		if r and r.from == p and now - r.at < 3 then
			return
		end
		requests[target] = { from = p, at = now }
		remote:FireClient(target, "request", { From = p.UserId, Name = p.DisplayName, TTL = REQUEST_TTL })
		notify(p, "Trade request sent to " .. target.DisplayName, true)
	elseif action == "respond" then
		local from = type(a1) == "number" and Players:GetPlayerByUserId(a1)
		local r = requests[p]
		if not from or not r or r.from ~= from or now - r.at > REQUEST_TTL then
			return
		end
		requests[p] = nil
		if a2 ~= true then
			notify(from, p.DisplayName .. " declined the trade")
			return
		end
		if trades[p] or trades[from] or busy(p) or busy(from) then
			notify(p, "Can't trade right now")
			return
		end
		local t = { a = from, b = p, offer = { [from] = {}, [p] = {} }, ready = {} }
		trades[from], trades[p] = t, t
		from:SetAttribute("Trading", true)
		p:SetAttribute("Trading", true)
		push(t)
	elseif action == "set" then
		local t = trades[p]
		if not t or t.closed or not validCode(a1) or type(a2) ~= "number" or a2 ~= a2 then
			return
		end
		local n = math.clamp(math.floor(a2), 0, free(p, a1))
		local mine = t.offer[p]
		local kinds = 0
		for _ in pairs(mine) do
			kinds += 1
		end
		if n > 0 and not mine[a1] and kinds >= MAX_KINDS then
			notify(p, "Max " .. MAX_KINDS .. " kinds of pets per trade")
			return
		end
		mine[a1] = n > 0 and n or nil
		unready(t)
		push(t)
	elseif action == "ready" then
		local t = trades[p]
		if not t or t.closed then
			return
		end
		t.ready[p] = a1 == true or nil
		if t.ready[t.a] and t.ready[t.b] then
			t.ends = now + COUNTDOWN
			local token = {}
			t.token = token
			task.delay(COUNTDOWN, function()
				if not t.closed and t.token == token and t.ready[t.a] and t.ready[t.b] then
					execute(t)
				end
			end)
		else
			t.ends = nil
			t.token = nil
		end
		push(t)
	elseif action == "cancel" then
		local t = trades[p]
		if t then
			close(t, p.DisplayName .. " cancelled the trade")
		end
	end
end)

-- отмена, если кто-то ушёл в данж или вышел
task.spawn(function()
	while true do
		task.wait(0.5)
		for p, t in pairs(trades) do
			if not t.closed and (p.Parent ~= Players or busy(p)) then
				close(t, "Trade cancelled")
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p)
	local t = trades[p]
	if t then
		close(t, p.DisplayName .. " left")
	end
	requests[p] = nil
	lastAction[p] = nil
end)
