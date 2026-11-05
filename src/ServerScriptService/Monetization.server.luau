-- Донаты: геймпассы и продукты (StoreConfig). Владение геймпассом — атрибут Pass_<Key> у игрока
-- (его читают PlayerSystems, GameServer, ShopUI, StoreUI). Продукты выдаются в ProcessReceipt;
-- каждая покупка записывается в DataStore, чтобы при повторе Roblox её не выдало дважды.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))

local receipts = nil
pcall(function()
	receipts = DataStoreService:GetDataStore("CoinSprintReceipts_v1")
end)

local function applyPass(p: Player, def)
	if p:GetAttribute("Pass_" .. def.Key) then
		return
	end
	p:SetAttribute("Pass_" .. def.Key, true)
	if def.Key == "PetSlots" then
		p:SetAttribute("MaxEquipped", PlayerSystems.MaxEquipped(p))
	end
end

local function checkPasses(p: Player)
	for _, def in ipairs(StoreConfig.Passes) do
		if def.Id and def.Id > 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, p.UserId, def.Id)
			if ok and owns then
				applyPass(p, def)
			end
		end
	end
end
Players.PlayerAdded:Connect(checkPasses)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(checkPasses, p)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, passId, purchased)
	if not purchased then
		return
	end
	for _, def in ipairs(StoreConfig.Passes) do
		if def.Id == passId then
			applyPass(p, def)
		end
	end
end)

-- ===== продукты =====
local byId = {}
for _, def in ipairs(StoreConfig.Products) do
	if def.Id and def.Id > 0 then
		byId[def.Id] = def
	end
end

local function grant(p: Player, def): boolean
	if not p:GetAttribute("ProfileReady") then
		return false
	end
	if def.Kind == "coins" then
		local stats = p:FindFirstChild("leaderstats")
		if not stats then
			return false
		end
		local earned = p:GetAttribute("LifetimeEarned") or 0
		local amount = math.floor(math.max(def.Min, earned * def.Share))
		stats.Coins.Value += amount
		return true
	elseif def.Kind == "potions" then
		for _, name in ipairs({ "Coins", "Speed", "Luck" }) do
			p:SetAttribute("Potion" .. name, (p:GetAttribute("Potion" .. name) or 0) + def.Count)
		end
		return true
	elseif def.Kind == "luck" then
		local start = math.max(os.time(), p:GetAttribute("Save_LuckBoostEnd") or 0)
		p:SetAttribute("Save_LuckBoostEnd", start + def.Seconds)
		return true
	end
	return false
end

MarketplaceService.ProcessReceipt = function(info)
	local def = byId[info.ProductId]
	local p = Players:GetPlayerByUserId(info.PlayerId)
	if not def or not p then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- уже выдавали эту покупку?
	if receipts then
		local ok, done = pcall(receipts.GetAsync, receipts, info.PurchaseId)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if done then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	if not grant(p, def) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if receipts then
		pcall(receipts.SetAsync, receipts, info.PurchaseId, true)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
