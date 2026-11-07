-- Сундуки на островках Sky Isles (тег "SkyChest" ставит SkyIsles.luau): открыл — получил монеты,
-- потом сундук у этого игрока перезаряжается COOLDOWN секунд. Всё проверяет сервер: профиль загружен,
-- игрок рядом с сундуком, перезарядка прошла. Перезарядка живёт в памяти сервера (не сохраняется).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local COOLDOWN = 600
local MAX_DISTANCE = 14

local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
-- Клиент (ChestFX) играет анимацию открытия и «сон» сундука до конца перезарядки.
local openedRemote = Instance.new("RemoteEvent")
openedRemote.Name = "SkyChestOpened"
openedRemote.Parent = ReplicatedStorage
local openedAt: { [Player]: { [number]: number } } = {}

local function comma(n: number): string
	for _, u in ipairs({ { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" } }) do
		if n >= u[1] * 0.999995 then
			return (string.format("%.2f", n / u[1]):gsub("%.?0+$", "")) .. u[2]
		end
	end
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function popLid(base: BasePart)
	local lid = base.Parent and base.Parent:FindFirstChild("ChestLid")
	if not lid or lid:GetAttribute("Popping") then
		return
	end
	lid:SetAttribute("Popping", true)
	local rest = lid.CFrame
	local up = TweenService:Create(lid, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = rest + Vector3.new(0, 1.2, 0) })
	up:Play()
	up.Completed:Wait()
	local down = TweenService:Create(lid, TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = rest })
	down:Play()
	down.Completed:Wait()
	lid:SetAttribute("Popping", nil)
end

local Worlds = require(game:GetService("ReplicatedStorage"):WaitForChild("WorldsConfig"))
local function unlocked(p, name)
	local def = Worlds.Find(name)
	return not def or (def.Cost or 0) <= 0 or p:GetAttribute(Worlds.UnlockKey(name)) == true
end
local function open(p: Player, base: BasePart)
	local id, reward = base:GetAttribute("ChestId"), base:GetAttribute("Reward")
	if type(id) ~= "number" or type(reward) ~= "number" then
		return
	end
	if not p:GetAttribute("ProfileReady") or not unlocked(p, "Sky Isles") then
		return
	end
	local stats = p:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not coins or not root or (root.Position - base.Position).Magnitude > MAX_DISTANCE then
		return
	end
	local mine = openedAt[p] or {}
	openedAt[p] = mine
	-- перезарядка сохраняется в профиле (Save_Chest<id>): перезаход не обнуляет сундуки
	local last = math.max(mine[id] or -math.huge, p:GetAttribute("Save_Chest" .. id) or -math.huge)
	local left = COOLDOWN - (os.time() - last)
	if left > 0 then
		feedback:FireClient(p, string.format("This chest refills in %d:%02d", left // 60, left % 60), false)
		return
	end
	-- Без yield между проверкой и выдачей: двойной клик не даст награду дважды.
	-- награда растёт с прогрессом: не меньше базы, иначе доля от всего заработанного (база одна на всех)
	reward = math.max(reward, math.floor((tonumber(p:GetAttribute("LifetimeEarned")) or 0) * (base:GetAttribute("Share") or 0)))
	mine[id] = os.time()
	p:SetAttribute("Save_Chest" .. id, os.time())
	coins.Value += reward
	feedback:FireClient(p, "Treasure! +" .. comma(reward) .. " coins", true)
	local burst = base:FindFirstChild("Burst")
	if burst and burst:IsA("ParticleEmitter") then
		burst:Emit(40)
	end
	task.spawn(popLid, base)
	openedRemote:FireClient(p, id, reward, os.time() + COOLDOWN)
end

local function hook(base: Instance)
	if not base:IsA("BasePart") then
		return
	end
	local prompt = base:WaitForChild("OpenChest", 10)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(p)
			open(p, base)
		end)
	end
end

for _, base in ipairs(CollectionService:GetTagged("SkyChest")) do
	task.spawn(hook, base)
end
CollectionService:GetInstanceAddedSignal("SkyChest"):Connect(hook)
Players.PlayerRemoving:Connect(function(p)
	openedAt[p] = nil
end)
