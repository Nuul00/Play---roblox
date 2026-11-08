-- Звуки на ключевых действиях: щелчок кнопок, покупки прокачки и магнитов, ребёрс, сообщения
-- сервера (успех / ошибка). Звук открытия яйца и редкого питомца — в ShopUI (анимация открытия).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UISounds = require(ReplicatedStorage:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local hooked = setmetatable({}, { __mode = "k" })
local function hook(d: Instance)
	if (d:IsA("TextButton") or d:IsA("ImageButton")) and not hooked[d] then
		hooked[d] = true
		d.Activated:Connect(function()
			UISounds.Play("click")
		end)
	end
end
for _, d in ipairs(gui:GetDescendants()) do
	hook(d)
end
gui.DescendantAdded:Connect(hook)

-- Прокачка и покупки: растущий атрибут = покупка прошла.
local values = {}
local function watch(name: string, sound: string)
	values[name] = player:GetAttribute(name)
	player:GetAttributeChangedSignal(name):Connect(function()
		local v = player:GetAttribute(name)
		local old = values[name]
		values[name] = v
		if type(v) == "number" and type(old) == "number" and v > old then
			UISounds.Play(sound)
		end
	end)
end
for _, n in ipairs({ "MagnetLevel", "IncomeLevel", "DoubleLevel", "MagnetTier" }) do
	watch(n, "buy")
end
watch("Rebirths", "fanfare")
task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 60)
	local speed = stats and stats:WaitForChild("SpeedLevel", 30)
	if speed then
		local old = speed.Value
		speed.Changed:Connect(function(v)
			-- после ребёрса уровень падает — это не покупка
			if v > old and player:GetAttribute("UIScreen") == "upgrades" then
				UISounds.Play("buy")
			end
			old = v
		end)
	end
end)

ReplicatedStorage:WaitForChild("GameFeedback").OnClientEvent:Connect(function(message, success)
	if type(message) ~= "string" or string.sub(message, 1, 7) == "World: " then
		return
	end
	if success then
		UISounds.Play(string.find(message, "unlocked", 1, true) and "unlock" or "reward")
	else
		UISounds.Play("fail")
	end
end)
