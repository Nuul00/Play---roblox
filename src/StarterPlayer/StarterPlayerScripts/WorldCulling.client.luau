-- Экономия на слабых устройствах: частицы, свет и анимированные текстуры миров, в которых игрока
-- сейчас нет, выключаются (их всё равно не видно — миры стоят в тысячах studs друг от друга).
-- Выключаем только то, что было включено, и при возвращении включаем ровно это же,
-- чтобы не мешать скриптам, которые сами гасят свои эффекты.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

local WORLD_MODEL = {
	["Neon District"] = "NeonCity",
	["Sky Isles"] = "SkyIsles",
	["Frozen Peaks"] = "FrozenPeaks",
	["Magma Volcano"] = "MagmaVolcano",
	["Cosmic Galaxy"] = "CosmicGalaxy",
}

local off: { [Instance]: { Instance } } = {} -- модель мира -> что мы в ней выключили

local function switchable(d: Instance): boolean
	return d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Beam") or d:IsA("Trail")
end

local function hide(m: Instance)
	if off[m] then
		return
	end
	local list = {}
	for _, d in ipairs(m:GetDescendants()) do
		if switchable(d) and (d :: any).Enabled then
			(d :: any).Enabled = false
			table.insert(list, d)
		end
	end
	off[m] = list
end

local function show(m: Instance)
	local list = off[m]
	if not list then
		return
	end
	off[m] = nil
	for _, d in ipairs(list) do
		if d.Parent then
			(d :: any).Enabled = true
		end
	end
end

local function update()
	local current = WORLD_MODEL[player:GetAttribute("CurrentWorld") or ""]
	for _, name in pairs(WORLD_MODEL) do
		local m = world:FindFirstChild(name)
		if m then
			if name == current then
				show(m)
			else
				hide(m)
			end
		end
	end
end

player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
	task.defer(update)
end)
-- миры строятся сервером не сразу: проверяем ещё пару раз после входа
task.spawn(function()
	for _ = 1, 6 do
		update()
		task.wait(10)
	end
end)
-- игрок в мире, где эффекты выключены, а сервер добавил новый — тоже гасим
for _, name in pairs(WORLD_MODEL) do
	task.spawn(function()
		local m = world:WaitForChild(name, 120)
		if not m then
			return
		end
		m.DescendantAdded:Connect(function(d)
			local list = off[m]
			if list and switchable(d) then
				task.defer(function()
					if off[m] == list and (d :: any).Enabled then
						(d :: any).Enabled = false
						table.insert(list, d)
					end
				end)
			end
		end)
	end)
end
