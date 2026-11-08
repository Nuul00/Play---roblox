-- Жетоны ⚡ (хранит QuestService партнёра: состояние QuestState.tokens / .trails):
-- * прокачка купленного трейла до 5 уровня (TrailBonus), обмен на ключи Coin Rush и супер-зелья;
-- * новые источники жетонов: забег Coin Rush +1, ребёрс +3, ежедневная награда +2.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS:WaitForChild("TrailBonus"))
local feedback = RS:WaitForChild("GameFeedback")

local function qs()
	local m = script.Parent:FindFirstChild("QuestService", true)
	if not m then
		return nil
	end
	local ok, mod = pcall(require, m)
	return ok and mod or nil
end
local function withState(p, fn)
	local Q = qs()
	local st = Q and Q.GetState(p)
	if not st then
		return false, "Tokens are not loaded yet"
	end
	local ok, msg = fn(st)
	if ok then
		Q.Commit(p)
	end
	return ok, msg
end

local function give(p, n, why)
	withState(p, function(st)
		st.tokens = (st.tokens or 0) + n
		return true
	end)
	feedback:FireClient(p, "⚡ +" .. n .. " trail token" .. (n > 1 and "s" or "") .. " · " .. why, true)
end

local remote = Instance.new("RemoteFunction")
remote.Name = "TokenShop"
remote.Parent = RS
local last = {}
remote.OnServerInvoke = function(p, kind, arg)
	if os.clock() - (last[p] or 0) < 0.3 or type(arg) ~= "string" then
		return { Ok = false, Message = "Wait" }
	end
	last[p] = os.clock()
	local ok, msg = withState(p, function(st)
		local tokens = st.tokens or 0
		if kind == "upgrade" then
			if not T.List[arg] or not table.find(st.trails or {}, arg) then
				return false, "Buy this trail first"
			end
			local lv = T.Level(p, arg)
			if lv >= T.MaxLevel then
				return false, "Max level"
			end
			local cost = T.UpgradeCost(arg, lv)
			if tokens < cost then
				return false, "Need " .. (cost - tokens) .. " more ⚡"
			end
			st.tokens = tokens - cost
			p:SetAttribute(T.LevelAttr(arg), lv + 1)
			return true, "Trail upgraded to LV " .. (lv + 1) .. "!"
		elseif kind == "exchange" then
			local item
			for _, e in ipairs(T.Exchange) do
				if e.Key == arg then
					item = e
				end
			end
			if not item then
				return false, "Unknown item"
			end
			if tokens < item.Cost then
				return false, "Need " .. (item.Cost - tokens) .. " more ⚡"
			end
			st.tokens = tokens - item.Cost
			if item.Key == "RushKey" then
				p:SetAttribute("Save_RushKeys", (p:GetAttribute("Save_RushKeys") or 0) + 1)
			else
				local key = "Potion" .. item.Key
				p:SetAttribute(key, (p:GetAttribute(key) or 0) + 1)
			end
			return true, "Got 1 " .. item.Name .. "!"
		end
		return false, "?"
	end)
	return { Ok = ok, Message = msg }
end

-- новые источники жетонов: следим за счётчиками (после загрузки профиля)
local function watch(p)
	local seen = {}
	local function track(attr, n, why)
		p:GetAttributeChangedSignal(attr):Connect(function()
			local v = p:GetAttribute(attr)
			if not p:GetAttribute("ProfileReady") then
				seen[attr] = v
				return
			end
			local before = seen[attr]
			if type(v) == "number" and before == nil then
				before = 0 -- первый забег / ребёрс: счётчика ещё не было
			end
			if before ~= nil and v ~= nil and v ~= before and (type(v) ~= "number" or v > before) then
				give(p, n, why)
			end
			seen[attr] = v
		end)
		seen[attr] = p:GetAttribute(attr)
	end
	track("Save_RushRuns", T.Sources.Rush, "Coin Rush run")
	track("Rebirths", T.Sources.Rebirth, "Rebirth")
	track("DailyClaimedAt", T.Sources.Daily, "Daily reward")
	p:GetAttributeChangedSignal("ProfileReady"):Connect(function()
		for _, a in ipairs({ "Save_RushRuns", "Rebirths", "DailyClaimedAt" }) do
			seen[a] = p:GetAttribute(a)
		end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(watch, p)
end
Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
end)
