-- Локальные ивенты миров (настройки — ReplicatedStorage.LocalEvents). Сервер: по расписанию
-- ставит конец ивента в атрибут workspace, раскладывает бонусы у монет мира, выдаёт награду.
-- 2026-11: во время ивента x2 нет; собранные бонусы дают множитель после ивента (E.Tiers, PlayerSystems.CoinMultiplier).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))
local E = require(ReplicatedStorage:WaitForChild("LocalEvents"))
local Worlds = require(ReplicatedStorage:WaitForChild("WorldsConfig"))
local CoinTypes = require(ReplicatedStorage:WaitForChild("CoinTypes"))
local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
local world = workspace:WaitForChild("CoinSpeedWorld")

-- где лежат монеты каждого мира
local FOLDER = { ["Meadow Isles"] = "", ["Neon District"] = "NeonCity", ["Sky Isles"] = "SkyIsles", ["Magma Volcano"] = "MagmaVolcano", ["Cosmic Galaxy"] = "CosmicGalaxy" }
local function coinSpots(name: string): { Vector3 }
	local spots = {}
	local f = FOLDER[name]
	if f == "" then
		for _, c in ipairs(world:GetChildren()) do
			if c:IsA("BasePart") and string.match(c.Name, "^Coin_%d+$") then
				table.insert(spots, c.Position)
			end
		end
	else
		local root = world:FindFirstChild(f)
		if root then
			for _, c in ipairs(root:GetDescendants()) do
				if c:IsA("BasePart") and string.match(c.Name, "^Coin_%d+$") then
					table.insert(spots, c.Position)
				end
			end
		end
	end
	return spots
end
local function unlocked(p, name)
	local def = Worlds.Find(name)
	return not def or (def.Cost or 0) <= 0 or p:GetAttribute(Worlds.UnlockKey(name)) == true
end
local function baseValue(def): number
	local w = CoinTypes.Worlds and CoinTypes.Worlds[def.Coin]
	return w and w.Kinds and w.Kinds[1] and w.Kinds[1].Value or 5
end

local gives = setmetatable({}, { __mode = "k" }) -- модель бонуса → функция выдачи
local holder = Instance.new("Folder")
holder.Name = "LocalEventPickups"
holder.Parent = world

-- тематический бонус: светящийся предмет из деталей, крутится на клиенте (тег LocalEventPickup)
local function makePickup(name: string, def, pos: Vector3, folder: Folder)
	local m = Instance.new("Model")
	m.Name = def.Key .. "Pickup"
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CastShadow = false
	core.Size = Vector3.new(2.6, 2.6, 2.6)
	core.CFrame = CFrame.new(pos + Vector3.new(0, 1.6, 0))
	core.Parent = m
	local function deco(size, cf, color, material, shape)
		local d = Instance.new("Part")
		d.Anchored = true
		d.CanCollide = false
		d.CanQuery = false
		d.CanTouch = false
		d.CastShadow = false
		d.Size = size
		d.CFrame = core.CFrame * cf
		d.Color = color
		d.Material = material
		if shape then
			d.Shape = shape
		end
		d.Parent = m
		return d
	end
	-- Вид бонуса: картинка из ChatGPT на билборде (всегда лицом к камере, как иконки HUD) +
	-- светящееся кольцо на земле и луч вверх, чтобы бонус было видно издалека.
	-- Если картинки нет — простая светящаяся сфера.
	core.Transparency = 1
	if def.Image then
		local bb = Instance.new("BillboardGui")
		bb.Name = "Icon"
		bb.Size = UDim2.fromScale(5.2, 5.2)
		bb.StudsOffset = Vector3.new(0, 1.2, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 260
		bb.Adornee = core
		bb.Parent = core
		local img = Instance.new("ImageLabel")
		img.Name = "Image"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = def.Image
		img.Parent = bb
	else
		deco(Vector3.new(2.2, 2.2, 2.2), CFrame.new(), def.Color, Enum.Material.Neon, Enum.PartType.Ball)
	end
	-- кольцо на земле
	local ring = deco(Vector3.new(0.2, 5, 5), CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, math.pi / 2), def.Color, Enum.Material.Neon, Enum.PartType.Cylinder)
	ring.Name = "Ring"
	ring.Transparency = 0.45
	-- луч света вверх
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, -1.5, 0)
	a0.Parent = core
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 22, 0)
	a1.Parent = core
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 2.4
	beam.Width1 = 0.4
	beam.Segments = 10
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(def.Color, def.Color2)
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	beam.Parent = core
	local light = Instance.new("PointLight")
	light.Color = def.Color
	light.Range = 12
	light.Brightness = 1.6
	light.Parent = core
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Color = ColorSequence.new(def.Color, def.Color2)
	sp.LightEmission = 1
	sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sp.Lifetime = NumberRange.new(0.8, 1.4)
	sp.Speed = NumberRange.new(1, 3)
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.Rate = 8
	sp.Parent = core
	m.PrimaryPart = core
	m:SetAttribute("World", name)
	m:AddTag("LocalEventPickup")
	local taken = false
	-- выдать бонус игроку (касанием или магнитом)
	local function give(p: Player): boolean
		if taken then
			return false
		end
		local stats = p:FindFirstChild("leaderstats")
		if not stats or not p:GetAttribute("ProfileReady") or not unlocked(p, name) or p:GetAttribute("CurrentWorld") ~= name then
			return false
		end
		local cap = folder:GetAttribute("Cap_" .. p.UserId) or 0
		if cap >= E.Cap then
			return false
		end
		folder:SetAttribute("Cap_" .. p.UserId, cap + 1)
		p:SetAttribute("EventPickups", cap + 1) -- счётчик «3/8» в баннере
		taken = true
		-- 2026-11: монет за подбор нет — считаем собранное, множитель выдаётся после ивента (E.Tiers)
		local earned = cap + 1
		holder:SetAttribute("LastPickupColor", def.Color)
		holder:SetAttribute("LastPickupBy", p.UserId)
		holder:SetAttribute("LastPickupAmount", earned)
		holder:SetAttribute("LastPickup", core.Position) -- клиент: вспышка, «+монеты», звук
		m:Destroy()
		return true
	end
	core.Touched:Connect(function(hit)
		local char = hit:FindFirstAncestorOfClass("Model")
		local p = char and Players:GetPlayerFromCharacter(char)
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if p and root and (root.Position - core.Position).Magnitude <= 12 then
			give(p)
		end
	end)
	m:SetAttribute("Pos", core.Position)
	gives[m] = give
	m.Parent = folder
end

local function run(name: string, def, ends: number)
	workspace:SetAttribute(E.AttrEnd(name), ends)
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("CurrentWorld") == name then
			p:SetAttribute("EventPickups", 0)
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = def.Key
	folder.Parent = holder
	-- 2026-11 (фидбэк): все бонусы сразу и по всей локации, в доступных местах — рядом с монетами
	-- (монеты лежат там, куда можно дойти), не ближе 25 студов друг к другу.
	local spots = coinSpots(name)
	if #spots > 0 then
		local rng = Random.new()
		local pool = table.clone(spots)
		local placed = {}
		local minGap = 25
		local made = 0
		while made < E.Pickups and #pool > 0 do
			local base = table.remove(pool, rng:NextInteger(1, #pool))
			local a = rng:NextNumber(0, math.pi * 2)
			local pos = base + Vector3.new(math.cos(a) * 4, -1.2, math.sin(a) * 4)
			local free = true
			for _, q in ipairs(placed) do
				if (q - pos).Magnitude < minGap then
					free = false
					break
				end
			end
			if free then
				makePickup(name, def, pos, folder)
				table.insert(placed, pos)
				made += 1
			end
			if #pool == 0 and made < E.Pickups and minGap > 8 then
				-- маленький мир: ослабляем разнос и добираем
				minGap -= 8
				pool = table.clone(spots)
			end
		end
	end
	task.wait(math.max(0, ends - workspace:GetServerTimeNow()))
	-- итог: собрал 6/12/18 — множитель монет на E.BonusDuration (во время сбора бонуса не было)
	for _, p in ipairs(Players:GetPlayers()) do
		local got = folder:GetAttribute("Cap_" .. p.UserId) or 0
		local tier = E.TierFor(got)
		if tier then
			local now = workspace:GetServerTimeNow()
			local cur = (p:GetAttribute("EventBonusEnd") or 0) > now and (p:GetAttribute("EventBonusMult") or 1) or 1
			if tier.Mult >= cur then
				p:SetAttribute("EventBonusMult", tier.Mult)
				p:SetAttribute("EventBonusEnd", now + E.BonusDuration)
			end
			feedback:FireClient(p, string.format("%s %d %s collected: x%g coins for %d min!", def.Icon, got, def.Item, tier.Mult, E.BonusDuration / 60), true)
		elseif got > 0 then
			feedback:FireClient(p, string.format("%s %d/%d %s — collect %d for a coin bonus next time!", def.Icon, got, E.Pickups, def.Item, E.Tiers[1].Need), false)
		end
		if p:GetAttribute("CurrentWorld") == name then
			p:SetAttribute("EventPickups", nil)
		end
	end
	folder:Destroy()
end

-- Магнит тянет и бонусы ивента: радиус магнита игрока (+3), чтобы не обегать каждый вплотную
task.spawn(function()
	while true do
		task.wait(0.2)
		for _, p in ipairs(Players:GetPlayers()) do
			local w = p:GetAttribute("CurrentWorld")
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if root and w and E.Worlds[w] and E.Active(w) then
				local r = math.min((p:GetAttribute("MagnetRadius") or 6) + 3, 40)
				for m, give in pairs(gives) do
					if m.Parent and m:GetAttribute("World") == w then
						local pos = m:GetAttribute("Pos")
						if pos and (pos - root.Position).Magnitude <= r then
							give(p)
						end
					end
				end
			end
		end
	end
end)

-- общий планировщик: раз в секунду смотрим, не пора ли какому-то миру начать ивент
local running = {}
task.spawn(function()
	task.wait(20) -- миры строятся кодом — даём им появиться
	while true do
		local now = workspace:GetServerTimeNow()
		-- Studio: workspace.LocalEventForce = "Meadow Isles" запускает ивент мира сразу (для теста)
		local force = game:GetService("RunService"):IsStudio() and workspace:GetAttribute("LocalEventForce")
		if force and E.Worlds[force] and not running[force] then
			workspace:SetAttribute("LocalEventForce", nil)
			running[force] = true
			task.spawn(function()
				pcall(run, force, E.Worlds[force], now + E.Duration)
				running[force] = nil
			end)
		end
		for name, def in pairs(E.Worlds) do
			local start = E.NextStart(name, now) - E.Interval -- последний старт
			if not running[name] and now >= start and now < start + E.Duration then
				running[name] = true
				task.spawn(function()
					local ok, err = pcall(run, name, def, start + E.Duration)
					if not ok then
						warn("[LocalEvents] " .. tostring(err))
					end
					running[name] = nil
				end)
			end
		end
		task.wait(1)
	end
end)
