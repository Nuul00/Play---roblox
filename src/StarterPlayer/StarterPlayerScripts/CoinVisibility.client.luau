-- Монета на респавне невидима полностью. Сервер прячет только саму деталь (Transparency = 1),
-- а подписи (SurfaceGui), сияние, искры и свет оставались включены — на месте собранной монеты
-- висела «метка», где она скоро появится (2026-11). Здесь гасим их, пока Available == false,
-- и включаем обратно, когда монета вернулась (только в мире, где сейчас игрок — см. WorldCulling).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

-- CoinWorld (атрибут монеты) → CurrentWorld игрока
local WORLD_NAME = {
	Meadow = "Meadow Isles",
	Neon = "Neon District",
	Sky = "Sky Isles",
	Frozen = "Frozen Peaks",
	Volcano = "Magma Volcano",
	Galaxy = "Cosmic Galaxy",
}

local tracked = setmetatable({}, { __mode = "k" })

local function effectsOf(coin: BasePart)
	local list = {}
	for _, d in ipairs(coin:GetDescendants()) do
		if d:IsA("LayerCollector") or d:IsA("ParticleEmitter") or d:IsA("Light") then
			table.insert(list, d)
		end
	end
	return list
end

-- 3D-монеты (TripoCoins) прячут свои плоские значки сами — их не включаем обратно
local function isModelCoin(coin: BasePart): boolean
	return coin:FindFirstChildWhichIsA("Model") ~= nil
end

local function apply(coin: BasePart)
	local available = coin:GetAttribute("Available") ~= false
	local inWorld = WORLD_NAME[coin:GetAttribute("CoinWorld") or ""] == nil
		or WORLD_NAME[coin:GetAttribute("CoinWorld")] == player:GetAttribute("CurrentWorld")
	local modelCoin = isModelCoin(coin)
	for _, d in ipairs(effectsOf(coin)) do
		local on = available and inWorld
		if d:IsA("LayerCollector") and modelCoin then
			on = false
		end
		if (d :: any).Enabled ~= on then
			(d :: any).Enabled = on
		end
	end
end

local function track(coin: Instance)
	if tracked[coin] or not coin:IsA("BasePart") or not string.match(coin.Name, "^Coin_%d+$") then
		return
	end
	tracked[coin] = true
	coin:GetAttributeChangedSignal("Available"):Connect(function()
		apply(coin)
	end)
	if coin:GetAttribute("Available") == false then
		apply(coin)
	end
end

for _, d in ipairs(world:GetDescendants()) do
	track(d)
end
world.DescendantAdded:Connect(function(d)
	task.defer(track, d)
end)

-- WorldCulling включает эффекты мира при входе в него — у монет на респавне гасим их снова
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
	task.delay(0.1, function()
		for coin in pairs(tracked) do
			if coin.Parent and coin:GetAttribute("Available") == false then
				apply(coin)
			end
		end
	end)
end)
