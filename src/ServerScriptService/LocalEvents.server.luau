-- Локальные ивенты миров (настройки — ReplicatedStorage.LocalEvents). Сервер: по расписанию
-- ставит конец ивента в атрибут workspace, раскладывает бонусы у монет мира, выдаёт награду.
-- x2 монет во время ивента считает PlayerSystems.CoinMultiplier.
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
	if def.Key == "Meadow" then
		core.Transparency = 1
		-- цветок стоит «лицом» вбок: лепестки по кругу в вертикальной плоскости, сердцевина светится
		deco(Vector3.new(1.4, 1.4, 1.4), CFrame.new(), def.Color2, Enum.Material.Neon, Enum.PartType.Ball)
		for k = 0, 5 do
			deco(Vector3.new(0.35, 1.9, 1.9), CFrame.Angles(0, 0, k * math.pi / 3) * CFrame.new(0, 1.25, 0) * CFrame.Angles(0, math.pi / 2, 0), def.Color, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
	elseif def.Key == "Neon" then
		core.Shape = Enum.PartType.Ball
		core.Material = Enum.Material.Foil
		core.Color = Color3.fromRGB(220, 220, 240)
		core.Reflectance = 0.4
		deco(Vector3.new(0.2, 1.2, 0.2), CFrame.new(0, 1.8, 0), Color3.fromRGB(150, 150, 160), Enum.Material.Metal)
	elseif def.Key == "Sky" then
		core.Transparency = 1
		for k = 0, 4 do
			deco(Vector3.new(0.6, 2.2, 0.6), CFrame.Angles(0, 0, k * math.pi * 2 / 5) * CFrame.new(0, 0.9, 0), def.Color, Enum.Material.Neon)
		end
		deco(Vector3.new(1.2, 1.2, 1.2), CFrame.new(), def.Color, Enum.Material.Neon, Enum.PartType.Ball)
	elseif def.Key == "Volcano" then
		core.Material = Enum.Material.Neon
		core.Color = def.Color2
		core.Size = Vector3.new(2.2, 1.8, 2)
		deco(Vector3.new(1.6, 1.4, 1.8), CFrame.new(0.8, 0.4, 0.3) * CFrame.Angles(0.4, 0.6, 0.2), def.Color, Enum.Material.Neon)
		deco(Vector3.new(1.3, 1.1, 1.3), CFrame.new(-0.7, -0.2, -0.4) * CFrame.Angles(0.2, 1.2, 0.5), Color3.fromRGB(60, 30, 25), Enum.Material.Basalt)
	else
		core.Shape = Enum.PartType.Ball
		core.Material = Enum.Material.Slate
		core.Color = Color3.fromRGB(70, 60, 90)
		deco(Vector3.new(2.9, 2.9, 2.9), CFrame.new(), def.Color, Enum.Material.ForceField, Enum.PartType.Ball)
	end
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
	core.Touched:Connect(function(hit)
		if taken then
			return
		end
		local char = hit:FindFirstAncestorOfClass("Model")
		local p = char and Players:GetPlayerFromCharacter(char)
		local stats = p and p:FindFirstChild("leaderstats")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not (stats and root) or (root.Position - core.Position).Magnitude > 12 then
			return
		end
		if not p:GetAttribute("ProfileReady") or not unlocked(p, name) or p:GetAttribute("CurrentWorld") ~= name then
			return
		end
		local cap = folder:GetAttribute("Cap_" .. p.UserId) or 0
		if cap >= E.Cap then
			return
		end
		folder:SetAttribute("Cap_" .. p.UserId, cap + 1)
		taken = true
		local earned = math.floor(baseValue(def) * E.Reward * PlayerSystems.CoinMultiplier(p))
		stats.Coins.Value += earned
		p:SetAttribute("LifetimeEarned", (p:GetAttribute("LifetimeEarned") or 0) + earned)
		holder:SetAttribute("LastPickup", core.Position) -- клиент проигрывает вспышку
		holder:SetAttribute("LastPickupColor", def.Color)
		m:Destroy()
	end)
	m.Parent = folder
end

local function run(name: string, def, ends: number)
	workspace:SetAttribute(E.AttrEnd(name), ends)
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("CurrentWorld") == name then
			feedback:FireClient(p, def.Icon .. " " .. def.Name .. "! x2 coins and " .. def.Item .. " for 60s!", true)
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = def.Key
	folder.Parent = holder
	local spots = coinSpots(name)
	if #spots > 0 then
		local rng = Random.new()
		for wave = 1, 3 do
			for _ = 1, math.floor(E.Pickups / 3) do
				local base = spots[rng:NextInteger(1, #spots)]
				makePickup(name, def, base + Vector3.new(rng:NextNumber(-3, 3), -1.2, rng:NextNumber(-3, 3)), folder)
			end
			if wave < 3 then
				task.wait(15)
			end
		end
	end
	task.wait(math.max(0, ends - workspace:GetServerTimeNow()))
	folder:Destroy()
end

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
