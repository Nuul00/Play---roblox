-- Бонус за друзей: +10% монет за каждого друга на этом сервере (до +50%).
-- Считает только сервер; дружбу спрашиваем у Roblox один раз на пару игроков и кэшируем.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
local cache = {} -- ["minId:maxId"] = true/false

local function key(a: number, b: number): string
	if a > b then
		a, b = b, a
	end
	return a .. ":" .. b
end

local function areFriends(p: Player, other: Player): boolean
	local k = key(p.UserId, other.UserId)
	if cache[k] == nil then
		local ok, result = pcall(function()
			return p:IsFriendsWith(other.UserId)
		end)
		cache[k] = ok and result == true
	end
	return cache[k]
end

local function refresh()
	local list = Players:GetPlayers()
	for _, p in ipairs(list) do
		local friends = 0
		for _, other in ipairs(list) do
			if other ~= p and other.Parent == Players and areFriends(p, other) then
				friends += 1
			end
		end
		local bonus = 1 + math.min(ShopConfig.FriendBonusMax, friends * ShopConfig.FriendBonusEach)
		local old = p:GetAttribute("FriendBonus") or 1
		p:SetAttribute("FriendBonus", bonus)
		p:SetAttribute("FriendsOnline", friends)
		if bonus > old + 1e-6 then
			feedback:FireClient(p, string.format("👥 Friend boost: x%.1f coins", bonus), true)
		end
	end
end

Players.PlayerAdded:Connect(function()
	task.wait(2)
	refresh()
end)
Players.PlayerRemoving:Connect(function(p)
	task.defer(refresh)
	for k in pairs(cache) do
		if string.find(k, tostring(p.UserId), 1, true) then
			cache[k] = nil
		end
	end
end)
