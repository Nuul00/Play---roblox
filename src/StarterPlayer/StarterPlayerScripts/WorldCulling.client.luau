-- Эффекты (частицы, лучи, свет) работают только в мире, где сейчас игрок. Иначе со спавна видно
-- искры и сияние других миров в небе (Sky Isles висит над Meadow), и на это тратятся кадры.
-- Списки эффектов каждого мира собираем один раз (и пополняем по DescendantAdded), исходное
-- состояние храним в таблице — переход между мирами не обходит десятки тысяч объектов.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

local GROUPS = {
	NeonCity = "Neon District",
	SkyIsles = "Sky Isles",
	FrozenPeaks = "Frozen Peaks",
	MagmaVolcano = "Magma Volcano",
	CosmicGalaxy = "Cosmic Galaxy",
}
local FX = { ParticleEmitter = true, Beam = true, Trail = true, Fire = true, Smoke = true, Sparkles = true, PointLight = true, SpotLight = true, SurfaceLight = true }

local lists: { [string]: { Instance } } = {}
for _, id in pairs(GROUPS) do
	lists[id] = {}
end
lists["Meadow Isles"] = {}
local owner: { [Instance]: string } = setmetatable({}, { __mode = "k" }) :: any
local was: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- исходный Enabled выключенных
local current = player:GetAttribute("CurrentWorld") or "Meadow Isles"

local function worldOf(d: Instance): string
	local node = d
	while node and node.Parent ~= world do
		node = node.Parent
	end
	return node and GROUPS[node.Name] or "Meadow Isles"
end

local function off(d: Instance)
	if was[d] == nil then
		was[d] = (d :: any).Enabled;
		(d :: any).Enabled = false
	end
end
local function on(d: Instance)
	local v = was[d]
	if v ~= nil then
		was[d] = nil;
		(d :: any).Enabled = v
	end
end

local function add(d: Instance)
	if not FX[d.ClassName] or owner[d] then
		return
	end
	local id = worldOf(d)
	owner[d] = id
	table.insert(lists[id], d)
	if id ~= current then
		off(d)
	end
end

local function apply(id: string)
	if id == current then
		return
	end
	local old = current
	current = id
	for k, d in ipairs(lists[id] or {}) do
		on(d)
		if k % 3000 == 0 then
			task.wait()
		end
	end
	for k, d in ipairs(lists[old] or {}) do
		if d.Parent then
			off(d)
		end
		if k % 3000 == 0 then
			task.wait()
		end
	end
	-- чистим удалённые
	for _, list in pairs(lists) do
		for i = #list, 1, -1 do
			if not list[i].Parent then
				table.remove(list, i)
			end
		end
	end
end

for k, d in ipairs(world:GetDescendants()) do
	add(d)
	if k % 4000 == 0 then
		task.wait()
	end
end
world.DescendantAdded:Connect(function(d)
	if FX[d.ClassName] then
		task.defer(add, d)
	end
end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
	apply(player:GetAttribute("CurrentWorld") or "Meadow Isles")
end)
