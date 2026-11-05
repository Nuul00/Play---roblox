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
local orig: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- исходный Enabled
-- Эффекты монет: сервер больше не включает/выключает их сам, видимость решает клиент
-- (свой мир + монета доступна). Так собранные и чужие монеты не тратят кадры.
local coinOf: { [Instance]: BasePart } = setmetatable({}, { __mode = "k" }) :: any
local current = player:GetAttribute("CurrentWorld") or "Meadow Isles"

local function worldOf(d: Instance): string
	local node = d
	while node and node.Parent ~= world do
		node = node.Parent
	end
	return node and GROUPS[node.Name] or "Meadow Isles"
end
local function findCoin(d: Instance): BasePart?
	local node = d.Parent
	for _ = 1, 4 do
		if not node then
			return nil
		end
		if node:IsA("BasePart") and string.match(node.Name, "^Coin_%d+$") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function desired(d: Instance): boolean
	if not orig[d] then
		return false
	end
	local coin = coinOf[d]
	if coin and coin:GetAttribute("Available") == false then
		return false
	end
	-- у монет Frozen/Volcano/Galaxy вместо плоской монеты 3D-модель (TripoCoins): её значки не показываем
	if coin and d:IsA("LayerCollector") and coin:FindFirstChildWhichIsA("Model") then
		return false
	end
	return owner[d] == current
end
local function sync(d: Instance)
	local want = desired(d)
	if (d :: any).Enabled ~= want then
		(d :: any).Enabled = want
	end
end

local coinFx: { [BasePart]: { Instance } } = setmetatable({}, { __mode = "k" }) :: any
local function add(d: Instance)
	local coin = findCoin(d)
	local isFx = FX[d.ClassName] or (coin ~= nil and d:IsA("SurfaceGui"))
	if not isFx or owner[d] then
		return
	end
	local id = worldOf(d)
	owner[d] = id
	orig[d] = (d :: any).Enabled
	table.insert(lists[id], d)
	if coin then
		coinOf[d] = coin
		local list = coinFx[coin]
		if not list then
			list = {}
			coinFx[coin] = list
			coin:GetAttributeChangedSignal("Available"):Connect(function()
				for _, x in ipairs(list) do
					if x.Parent then
						sync(x)
					end
				end
			end)
		end
		table.insert(list, d)
	end
	sync(d)
end

local function apply(id: string)
	if id == current then
		return
	end
	local old = current
	current = id
	for _, wid in ipairs({ id, old }) do
		for k, d in ipairs(lists[wid] or {}) do
			if d.Parent then
				sync(d)
			end
			if k % 3000 == 0 then
				task.wait()
			end
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

-- подписка раньше обхода: эффекты, созданные пока идёт обход (с паузами), тоже попадут в списки
world.DescendantAdded:Connect(function(d)
	if FX[d.ClassName] or d:IsA("SurfaceGui") then
		task.defer(add, d)
	end
end)
for k, d in ipairs(world:GetDescendants()) do
	add(d)
	if k % 4000 == 0 then
		task.wait()
	end
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
	apply(player:GetAttribute("CurrentWorld") or "Meadow Isles")
end)
