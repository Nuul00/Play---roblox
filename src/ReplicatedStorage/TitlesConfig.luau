-- Титулы над головой игрока: VIP, за главы квестов и за достижения.
-- Игрок выбирает титул во вкладке TITLES инвентаря (сервер проверяет, что он открыт),
-- выбор хранится в Save_Title. Без выбора VIP показывает [VIP], остальные — ничего.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local rgb = Color3.fromRGB
local T = {}

T.Attr = "Save_Title"

-- последний шаг каждой главы квестов
local chapterLast = {}
do
	local Q = require(ReplicatedStorage:WaitForChild("QuestLineConfig"))
	for i, s in ipairs(Q.Steps) do
		chapterLast[s.Chapter] = i
	end
end
local function chapterDone(p, ch)
	local last = chapterLast[ch]
	return last ~= nil and (p:GetAttribute("Save_QuestLineStep") or 1) > last
end
-- сколько уровней цепочки достижений открыто (Coin Collector I, II, III…)
local function chainLevel(p, stat)
	local n = 0
	for _, b in ipairs(ShopConfig.Badges) do
		if b.Chain == stat and p:GetAttribute("Badge" .. b.Id) then
			n = math.max(n, b.Level)
		end
	end
	return n
end
local function badgeCount(p)
	local n = 0
	for _, b in ipairs(ShopConfig.Badges) do
		if p:GetAttribute("Badge" .. b.Id) then
			n += 1
		end
	end
	return n
end

-- Icon — эмодзи в табличке; A/B — градиент плашки; Group — раздел во вкладке
T.List = {
	{ Id = "VIP", Text = "VIP", Icon = "⭐", A = rgb(255, 230, 110), B = rgb(235, 150, 30), Group = "Special", Desc = "Own the VIP gamepass",
		Has = function(p) return p:GetAttribute("Pass_VIP") == true end },
	{ Id = "Meadow", Text = "Meadow Explorer", Icon = "🌸", A = rgb(150, 245, 120), B = rgb(40, 160, 80), Group = "Quests", Desc = "Finish the Meadow Isles quests",
		Has = function(p) return chapterDone(p, 1) end },
	{ Id = "Neon", Text = "Neon Runner", Icon = "🌃", A = rgb(255, 120, 240), B = rgb(120, 50, 220), Group = "Quests", Desc = "Finish the Neon District quests",
		Has = function(p) return chapterDone(p, 2) end },
	{ Id = "Sky", Text = "Sky Walker", Icon = "☁️", A = rgb(160, 225, 255), B = rgb(110, 120, 245), Group = "Quests", Desc = "Finish the Sky Isles quests",
		Has = function(p) return chapterDone(p, 3) end },
	{ Id = "Frozen", Text = "Frost Skater", Icon = "❄️", A = rgb(210, 245, 255), B = rgb(60, 150, 225), Group = "Quests", Desc = "Finish the Frozen Peaks quests",
		Has = function(p) return chapterDone(p, 4) end },
	{ Id = "Volcano", Text = "Lava Lord", Icon = "🔥", A = rgb(255, 200, 80), B = rgb(215, 50, 30), Group = "Quests", Desc = "Finish the Magma Volcano quests",
		Has = function(p) return chapterDone(p, 5) end },
	{ Id = "Galaxy", Text = "Cosmic Legend", Icon = "🌌", A = rgb(150, 235, 255), B = rgb(110, 50, 220), Group = "Quests", Desc = "Finish the Cosmic Galaxy quests",
		Has = function(p) return chapterDone(p, 6) end },
	{ Id = "Coins", Text = "Coin Hunter", Icon = "💰", A = rgb(255, 230, 120), B = rgb(220, 150, 30), Group = "Achievements", Desc = "Coin Collector V",
		Has = function(p) return chainLevel(p, "CoinsCollected") >= 5 end },
	{ Id = "Eggs", Text = "Egg Master", Icon = "🥚", A = rgb(255, 210, 240), B = rgb(200, 110, 220), Group = "Achievements", Desc = "Egg Master IV",
		Has = function(p) return chainLevel(p, "EggsOpened") >= 4 end },
	{ Id = "Rich", Text = "Tycoon", Icon = "💎", A = rgb(160, 250, 255), B = rgb(40, 160, 230), Group = "Achievements", Desc = "Rich V",
		Has = function(p) return chainLevel(p, "LifetimeEarned") >= 5 end },
	{ Id = "Index", Text = "Pet Scholar", Icon = "📖", A = rgb(255, 225, 170), B = rgb(190, 120, 60), Group = "Achievements", Desc = "Explorer V",
		Has = function(p) return chainLevel(p, "PetsDiscovered") >= 5 end },
	{ Id = "Reborn", Text = "Reborn", Icon = "🔄", A = rgb(200, 170, 255), B = rgb(110, 60, 210), Group = "Achievements", Desc = "Reborn IV (10 rebirths)",
		Has = function(p) return chainLevel(p, "Rebirths") >= 4 end },
	{ Id = "Magnet", Text = "Magnet Maniac", Icon = "🧲", A = rgb(255, 140, 140), B = rgb(200, 40, 60), Group = "Achievements", Desc = "Magnet Fan IV",
		Has = function(p) return chainLevel(p, "MagnetTier") >= 4 end },
	{ Id = "Vault", Text = "Vault Raider", Icon = "🏆", A = rgb(255, 225, 120), B = rgb(200, 120, 30), Group = "Achievements", Desc = "Vault Raider III (25 Coin Rush runs)",
		Has = function(p) return chainLevel(p, "Save_RushRuns") >= 3 end },
	{ Id = "Combo", Text = "Combo King", Icon = "⚡", A = rgb(255, 200, 90), B = rgb(240, 80, 40), Group = "Achievements", Desc = "Combo King IV (150 combo)",
		Has = function(p) return chainLevel(p, "Save_BestCombo") >= 4 end },
	{ Id = "Hunter", Text = "Badge Hunter", Icon = "🏅", A = rgb(255, 240, 160), B = rgb(230, 170, 40), Group = "Achievements", Desc = "Unlock 25 achievements",
		Has = function(p) return badgeCount(p) >= 25 end },
	{ Id = "Legend", Text = "LEGEND", Icon = "👑", A = rgb(255, 245, 170), B = rgb(255, 120, 200), Group = "Achievements", Desc = "Unlock every achievement",
		Has = function(p) return badgeCount(p) >= #ShopConfig.Badges end },
}
-- герб для карточки титула (картинки достижений)
local IMG = { VIP = { "Legend" }, Coins = { "CoinsCollected", 5 }, Eggs = { "EggsOpened", 4 }, Rich = { "LifetimeEarned", 5 }, Index = { "PetsDiscovered", 5 },
	Reborn = { "Rebirths", 4 }, Magnet = { "MagnetTier", 4 }, Vault = { "Save_RushRuns", 3 }, Combo = { "Save_BestCombo", 4 }, Hunter = { "Legend" }, Legend = { "Legend" } }
for _, t in ipairs(T.List) do
	local m = IMG[t.Id]
	-- герб той стадии, на которой титул открывается
	t.Image = m and (m[2] and ShopConfig.BadgeImage(m[1], m[2]) or ShopConfig.BadgeImages[m[1]]) or nil
end
T.ById = {}
for i, t in ipairs(T.List) do
	t.Order = i
	T.ById[t.Id] = t
end

-- какой титул показать над головой: выбранный (если открыт), иначе VIP у VIP-игроков
function T.Shown(p)
	local id = p:GetAttribute(T.Attr)
	local t = id and T.ById[id]
	if t and t.Has(p) then
		return t
	end
	if id == "none" then
		return nil
	end
	local vip = T.ById.VIP
	return vip.Has(p) and vip or nil
end

return T
