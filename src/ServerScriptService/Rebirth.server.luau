-- Ребёрс: игрок отдаёт монеты и прокачку, получает постоянный множитель монет (Config.GetRebirthBonus).
-- Сохраняется: питомцы, яйца, магниты, зелья, индекс, достижения, открытые миры (скорость остаётся достаточной).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))
local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
local world = workspace:WaitForChild("CoinSpeedWorld")

local remote = Instance.new("RemoteEvent")
remote.Name = "GameRebirth"
remote.Parent = ReplicatedStorage

local last = {}
Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
end)

remote.OnServerEvent:Connect(function(p)
	if not p:GetAttribute("ProfileReady") or os.clock() - (last[p] or -10) < 2 then
		return
	end
	local stats = p:FindFirstChild("leaderstats")
	local character = p.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not stats or not humanoid or humanoid.Health <= 0 then
		return
	end
	local count = p:GetAttribute("Rebirths") or 0
	if count >= Config.MaxRebirths then
		feedback:FireClient(p, "You reached the maximum rebirth!", false)
		return
	end
	local cost = Config.GetRebirthCost(count)
	if stats.Coins.Value < cost then
		feedback:FireClient(p, "Rebirth needs " .. string.format("%d", cost) .. " coins", false)
		return
	end
	last[p] = os.clock()
	stats.Coins.Value = 0
	stats.SpeedLevel.Value = math.max(Config.RebirthStartSpeed, 0)
	for _, name in ipairs({ "MagnetLevel", "IncomeLevel", "DoubleLevel" }) do
		p:SetAttribute(name, 0)
	end
	p:SetAttribute("Rebirths", count + 1)
	PlayerSystems.ApplySpeed(p)
	-- Возвращаем на старт Meadow Isles.
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		character:PivotTo(CFrame.new(0, 4 + (world:GetAttribute("GroundY") or 0), 180))
		root.AssemblyLinearVelocity = Vector3.zero
		p:SetAttribute("CurrentWorld", "Meadow Isles")
	end
end)
