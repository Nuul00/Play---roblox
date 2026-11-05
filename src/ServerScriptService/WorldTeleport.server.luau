-- Телепорт между мирами из окна TELEPORT. Сервер сам проверяет уровень скорости, мир и паузу.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Worlds = require(RS:WaitForChild("WorldsConfig"))
local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity")
local feedback = RS:WaitForChild("GameFeedback")
local Config = require(RS:WaitForChild("GameConfig"))
local ShopConfig = require(RS:WaitForChild("ShopConfig"))
local CONFIG_WORLD = { ["Meadow Isles"] = "island", ["Neon District"] = "neon", ["Sky Isles"] = "sky", ["Frozen Peaks"] = "frozen", ["Magma Volcano"] = "volcano", ["Cosmic Galaxy"] = "galaxy" }
local function short(n)
	for _, u in ipairs({ { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then
			return (string.format("%.2f", n / u[1]):gsub("%.?0+$", "")) .. u[2]
		end
	end
	return tostring(math.floor(n))
end
-- Старые профили: если у игрока уже есть питомцы из яиц мира, мир считается открытым.
local function grandfather(p)
	for _, def in ipairs(Worlds.Worlds) do
		local key = Worlds.UnlockKey(def.Id)
		if (def.Cost or 0) > 0 and not p:GetAttribute(key) then
			local cw = CONFIG_WORLD[def.Id]
			for id, pet in pairs(Config.Pets) do
				local egg = Config.Eggs[pet.EggId]
				if egg and egg.World == cw and not pet.Super and ShopConfig.Discovered(p, id) then
					p:SetAttribute(key, true)
					break
				end
			end
		end
	end
end
local function onPlayer(p)
	if p:GetAttribute("ProfileReady") then
		grandfather(p)
	else
		-- ProfileReady сначала ставится в false — ждём именно true
		local conn
		conn = p:GetAttributeChangedSignal("ProfileReady"):Connect(function()
			if p:GetAttribute("ProfileReady") then
				conn:Disconnect()
				grandfather(p)
			end
		end)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end

local remote = Instance.new("RemoteFunction")
remote.Name = "WorldTeleport"
remote.Parent = RS

local function destination(id)
	if id == "Meadow Isles" then
		return Vector3.new(0, 3 + (world:GetAttribute("GroundY") or 0), 180)
	elseif id == "Neon District" then
		return Vector3.new(city:WaitForChild("Floor").Position.X, 3, 180)
	elseif id == "Sky Isles" then
		local sky = world:FindFirstChild("SkyIsles")
		return sky and sky:GetAttribute("Spawn")
	elseif id == "Frozen Peaks" then
		local frozen = world:FindFirstChild("FrozenPeaks")
		return frozen and frozen:GetAttribute("Spawn")
	elseif id == "Magma Volcano" then
		local m = world:FindFirstChild("MagmaVolcano")
		return m and m:GetAttribute("Spawn")
	elseif id == "Cosmic Galaxy" then
		local m = world:FindFirstChild("CosmicGalaxy")
		return m and m:GetAttribute("Spawn")
	end
	return nil
end

local last = {}
Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
end)

local function teleport(p, id, buy)
	if type(id) ~= "string" then
		return { Ok = false, Message = "Unknown world" }
	end
	local def = Worlds.Find(id)
	if not def then
		return { Ok = false, Message = "Unknown world" }
	end
	if not def.Open then
		return { Ok = false, Message = def.Name .. " is coming soon!" }
	end
	local stats = p:FindFirstChild("leaderstats")
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not stats or not root or not hum or hum.Health <= 0 then
		return { Ok = false, Message = "Try again in a moment" }
	end
	if p:GetAttribute("CurrentWorld") == id then
		return { Ok = false, Message = "You are already here" }
	end
	if stats.SpeedLevel.Value < def.Speed then
		return { Ok = false, Message = "Requires speed level " .. def.Speed }
	end
	local now = os.clock()
	if last[p] and now - last[p] < 3 then
		return { Ok = false, Message = "Wait a moment before teleporting again" }
	end
	local target = destination(id)
	if not target then
		return { Ok = false, Message = "Destination is not ready" }
	end
	-- Разовая покупка мира: только из окна TELEPORT (buy = true), портал лишь подсказывает цену.
	local cost = def.Cost or 0
	local key = Worlds.UnlockKey(id)
	if cost > 0 and not p:GetAttribute(key) then
		if buy ~= true then
			return { Ok = false, Message = "Requires unlock: open TELEPORT (" .. short(cost) .. " coins)" }
		end
		if stats.Coins.Value < cost then
			return { Ok = false, Message = "Need " .. short(cost - stats.Coins.Value) .. " more coins to unlock " .. def.Name }
		end
		stats.Coins.Value -= cost
		p:SetAttribute(key, true)
		feedback:FireClient(p, "🔓 " .. def.Name .. " unlocked!", true)
	end
	last[p] = now
	char:PivotTo(CFrame.new(target))
	root.AssemblyLinearVelocity = Vector3.zero
	p:SetAttribute("CurrentWorld", id)
	feedback:FireClient(p, "World: " .. id, true)
	return { Ok = true, Message = "Teleported to " .. id }
end

remote.OnServerInvoke = function(p, id)
	local result = teleport(p, id, true)
	if result and not result.Ok and result.Message ~= "You are already here" then
		feedback:FireClient(p, result.Message, false)
	end
	return result
end

-- Порталы срабатывают, когда игрок входит в проём: без кнопки E, с той же проверкой уровня скорости.
-- Подсказки EnterWorld выключаем, чтобы не путали. Отказ («Requires speed level N») — не чаще раза в 2 с.
local warned = {}
Players.PlayerRemoving:Connect(function(p)
	warned[p] = nil
end)
local function walkIn(part, id)
	if not part then
		return
	end
	part.CanTouch = true
	local prompt = part:FindFirstChild("EnterWorld")
	if prompt then
		prompt.Enabled = false
	end
	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local p = character and Players:GetPlayerFromCharacter(character)
		if not p or p:GetAttribute("CurrentWorld") == id then
			return
		end
		local result = teleport(p, id)
		if result and not result.Ok and result.Message:find("Requires") then
			local now = os.clock()
			if not warned[p] or now - warned[p] > 2 then
				warned[p] = now
				feedback:FireClient(p, result.Message, false)
			end
		end
	end)
end

walkIn(world:WaitForChild("PortalToNeon", 30), "Neon District")
walkIn(city:WaitForChild("PortalToIsland", 30), "Meadow Isles")
task.spawn(function()
	local portal = city:WaitForChild("CloudPortal", 30)
	walkIn(portal and portal:WaitForChild("SkyTrigger", 30), "Sky Isles")
end)
task.spawn(function()
	local sky = world:WaitForChild("SkyIsles", 60)
	walkIn(sky and sky:WaitForChild("PortalToNeon", 30), "Neon District")
	local arch = sky and sky:WaitForChild("PortalToFrozenArch", 30)
	walkIn(arch and arch:WaitForChild("PortalToFrozen", 30), "Frozen Peaks")
end)
task.spawn(function()
	local frozen = world:WaitForChild("FrozenPeaks", 60)
	local arch = frozen and frozen:WaitForChild("PortalToSkyArch", 30)
	walkIn(arch and arch:WaitForChild("PortalToSky", 30), "Sky Isles")
	local toVolcano = frozen and frozen:WaitForChild("PortalToVolcanoArch", 30)
	walkIn(toVolcano and toVolcano:WaitForChild("PortalToVolcano", 30), "Magma Volcano")
end)
task.spawn(function()
	local volcano = world:WaitForChild("MagmaVolcano", 60)
	local a1 = volcano and volcano:WaitForChild("PortalToFrozenArch", 30)
	walkIn(a1 and a1:WaitForChild("PortalToFrozen", 30), "Frozen Peaks")
	local a2 = volcano and volcano:WaitForChild("PortalToGalaxyArch", 30)
	walkIn(a2 and a2:WaitForChild("PortalToGalaxy", 30), "Cosmic Galaxy")
end)
task.spawn(function()
	local galaxy = world:WaitForChild("CosmicGalaxy", 60)
	local a = galaxy and galaxy:WaitForChild("PortalToVolcanoArch", 30)
	walkIn(a and a:WaitForChild("PortalToVolcano", 30), "Magma Volcano")
end)
