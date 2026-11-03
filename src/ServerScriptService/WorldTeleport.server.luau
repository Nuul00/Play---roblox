-- Телепорт между мирами из окна TELEPORT. Сервер сам проверяет уровень скорости, мир и паузу.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Worlds = require(RS:WaitForChild("WorldsConfig"))
local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity")
local feedback = RS:WaitForChild("GameFeedback")

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
	end
	return nil
end

local last = {}
Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
end)

local function teleport(p, id)
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
	last[p] = now
	char:PivotTo(CFrame.new(target))
	root.AssemblyLinearVelocity = Vector3.zero
	p:SetAttribute("CurrentWorld", id)
	feedback:FireClient(p, "World: " .. id, true)
	return { Ok = true, Message = "Teleported to " .. id }
end

remote.OnServerInvoke = teleport

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
end)
