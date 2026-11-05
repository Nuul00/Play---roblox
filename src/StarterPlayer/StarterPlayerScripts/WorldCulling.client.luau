-- Эффекты (частицы, лучи, свет) работают только в мире, где сейчас игрок. Иначе со спавна видно
-- искры и сияние других миров в небе (Sky Isles висит над Meadow), и на это тратятся кадры.
-- Исходное состояние каждого эффекта запоминаем и возвращаем, когда игрок приходит в мир.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

local GROUPS = {
	["Neon District"] = "NeonCity",
	["Sky Isles"] = "SkyIsles",
	["Frozen Peaks"] = "FrozenPeaks",
	["Magma Volcano"] = "MagmaVolcano",
	["Cosmic Galaxy"] = "CosmicGalaxy",
}
local SUB = {}
for _, name in pairs(GROUPS) do
	SUB[name] = true
end
local FX = { ParticleEmitter = true, Beam = true, Trail = true, Fire = true, Smoke = true, Sparkles = true, PointLight = true, SpotLight = true, SurfaceLight = true }

local culled: { [Instance]: boolean } = {} -- корни групп, которые сейчас выключены

local function off(d: Instance)
	if FX[d.ClassName] and not d:GetAttribute("CullOff") then
		d:SetAttribute("CullWas", (d :: any).Enabled)
		d:SetAttribute("CullOff", true);
		(d :: any).Enabled = false
	end
end
local function on(d: Instance)
	if FX[d.ClassName] and d:GetAttribute("CullOff") then
		(d :: any).Enabled = d:GetAttribute("CullWas") ~= false
		d:SetAttribute("CullOff", nil)
		d:SetAttribute("CullWas", nil)
	end
end

-- корни мира: для Meadow — всё в CoinSpeedWorld, кроме других миров
local function roots(id: string): { Instance }
	local name = GROUPS[id]
	if name then
		local m = world:FindFirstChild(name)
		return m and { m } or {}
	end
	local list = {}
	for _, c in ipairs(world:GetChildren()) do
		if not SUB[c.Name] then
			table.insert(list, c)
		end
	end
	return list
end

local function setWorld(id: string, enabled: boolean)
	for i, r in ipairs(roots(id)) do
		culled[r] = not enabled or nil
		if r:IsA("BasePart") or FX[r.ClassName] then
			if enabled then on(r) else off(r) end
		end
		for k, d in ipairs(r:GetDescendants()) do
			if enabled then on(d) else off(d) end
			if k % 2000 == 0 then
				task.wait()
			end
		end
	end
end

-- всё, что появляется в выключенном мире (новые монеты, искры), тоже гасим
world.DescendantAdded:Connect(function(d)
	if not FX[d.ClassName] then
		return
	end
	task.defer(function()
		for r in pairs(culled) do
			if d:IsDescendantOf(r) then
				off(d)
				return
			end
		end
	end)
end)

local ALL = { "Meadow Isles", "Neon District", "Sky Isles", "Frozen Peaks", "Magma Volcano", "Cosmic Galaxy" }
local current: string? = nil
local busy = false
local function apply()
	if busy then
		return
	end
	busy = true
	local id = player:GetAttribute("CurrentWorld") or "Meadow Isles"
	while current ~= id do
		current = id
		-- сначала включаем свой мир, потом гасим остальные
		setWorld(id, true)
		for _, other in ipairs(ALL) do
			if other ~= id then
				setWorld(other, false)
			end
		end
		id = player:GetAttribute("CurrentWorld") or "Meadow Isles"
	end
	busy = false
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(apply)
-- миры Sky/Frozen/Volcano/Galaxy достраиваются в первые секунды — проходим ещё раз позже
task.delay(4, function()
	current = nil
	apply()
end)
task.delay(20, function()
	current = nil
	apply()
end)
apply()
