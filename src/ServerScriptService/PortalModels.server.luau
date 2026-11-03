-- Ставит 3D-модели порталов (ReplicatedStorage/CustomPortals) на порталы Неонграда и Sky Isles.
-- Детали-триггеры и ProximityPrompt остаются на месте, прячется только старое оформление.
-- Нет модели в CustomPortals — портал остаётся как был. Арку Meadow → Neon ставит PortalArt.server.
local PortalDecor = require(script.Parent:WaitForChild("PortalDecor"))

local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity", 60)
local rgb = Color3.fromRGB

-- Неонград → Meadow Isles: магический портал вместо кольца.
task.spawn(function()
	local disc = city and city:WaitForChild("PortalToIsland", 30)
	if not disc or not PortalDecor.Template("IslandGate") then
		return
	end
	local floor = city:WaitForChild("Floor")
	local bottom = Vector3.new(disc.Position.X, floor.Position.Y + floor.Size.Y / 2, disc.Position.Z)
	-- Диск — цилиндр, его ось (X) смотрит на игрока.
	PortalDecor.Dress(city, "IslandGate", { Name = "IslandGateModel", Bottom = bottom, Facing = disc.CFrame.RightVector, Yaw = math.pi, Height = 17, Glow = rgb(110, 255, 190) })
	disc:SetAttribute("Dressed", true) -- NeonRoadFX перестаёт его мигать
	disc.Transparency = 1
	local old = city:FindFirstChild("IslandPortal")
	if old then
		PortalDecor.HideOld(old, { Sign = true })
	end
end)

-- Неонград → Sky Isles: облачная сцена вместо облаков из шаров.
task.spawn(function()
	local portal = city and city:WaitForChild("CloudPortal", 30)
	local trigger = portal and portal:WaitForChild("SkyTrigger", 30)
	if not trigger or not PortalDecor.Template("CloudGate") then
		return
	end
	portal:SetAttribute("Dressed", true) -- CloudPortalStyle больше не трогает прозрачность
	local floor = city:WaitForChild("Floor")
	local bottom = Vector3.new(trigger.Position.X, floor.Position.Y + floor.Size.Y / 2, trigger.Position.Z)
	-- Неонград и так яркий: свет слабее, чтобы розовая сцена не выгорала.
	local height = 21
	PortalDecor.Dress(portal, "CloudGate", { Name = "CloudGateModel", Bottom = bottom, Facing = trigger.CFrame.LookVector, Yaw = math.pi, Height = height, Glow = rgb(255, 170, 225), LightBrightness = 0.5, SwirlRate = 5 })
	PortalDecor.HideOld(portal, { CloudSign = true, CloudGateModel = true })
	-- Табличка SKY ISLES стояла внутри старых облаков: поднимаем её над моделью.
	local sign = portal:FindFirstChild("CloudSign")
	if sign and (sign:IsA("BasePart") or sign:IsA("Model")) then
		local cf, size
		if sign:IsA("BasePart") then
			cf, size = sign.CFrame, sign.Size
		else
			cf, size = sign:GetBoundingBox()
		end
		sign:PivotTo(sign:GetPivot() + Vector3.new(0, bottom.Y + height + size.Y / 2 + 1 - cf.Position.Y, 0))
	end
end)

-- Sky Isles → Неонград: та же неоновая арка, что ведёт в Неонград из Meadow.
task.spawn(function()
	local sky = world:WaitForChild("SkyIsles", 60)
	local gate = sky and sky:WaitForChild("PortalToNeon", 30)
	-- Своя арка для Sky Isles (CustomPortals/SkyGate), иначе та же неоновая, что в Meadow.
	local template = PortalDecor.Template("SkyGate") and "SkyGate" or "NeonGate"
	if not gate or not PortalDecor.Template(template) then
		return
	end
	PortalDecor.Dress(sky, template, { Name = "NeonGateModel", Bottom = (gate.CFrame * CFrame.new(0, -gate.Size.Y / 2, 0)).Position, Facing = gate.CFrame.LookVector, Yaw = math.pi, Height = 24, Glow = rgb(190, 140, 255), Fancy = true })
	gate.Transparency = 1
end)
