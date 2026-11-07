-- Эффекты супер-способностей питомцев (только оформление, награды выдаёт сервер).
-- Coin Rain — вокруг игрока сыплются монеты; Vacuum — кольцо магнита схлопывается к игроку.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local PetAbilities = require(ReplicatedStorage:WaitForChild("PetAbilities"))
local remote = ReplicatedStorage:WaitForChild("PetSuperFX")

local folder = Instance.new("Folder")
folder.Name = "PetSuperFX"
folder.Parent = workspace

local random = Random.new()

local function abbreviate(n: number): string
	local units = { { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] * 0.999995 then
			return (string.format("%.2f", n / u[1]):gsub("%.?0+$", "")) .. u[2]
		end
	end
	return tostring(math.floor(n + 0.5))
end

-- Эффект виден, только если владелец недалеко от камеры.
local function rootNear(owner)
	local character = owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not camera or (camera.CFrame.Position - root.Position).Magnitude > 200 then
		return nil
	end
	return root
end

-- Надпись над головой своего игрока.
local function popText(root: BasePart, value: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = root.Position + Vector3.new(0, 4, 0)
	anchor.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 46)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = value
	label.TextColor3 = color
	label.Parent = gui
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = Color3.fromRGB(30, 30, 40)
	s.Parent = label
	TweenService:Create(anchor, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = anchor.Position + Vector3.new(0, 5, 0) }):Play()
	task.delay(1.1, function()
		TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(s, TweenInfo.new(0.5), { Transparency = 1 }):Play()
	end)
	Debris:AddItem(anchor, 1.7)
end

-- Одна падающая монета: летит сверху вниз, кружится, у земли гаснет.
local function fallingCoin(center: Vector3, groundY: number)
	local angle = random:NextNumber(0, math.pi * 2)
	local dist = random:NextNumber(1.5, 11)
	local x, z = center.X + math.cos(angle) * dist, center.Z + math.sin(angle) * dist
	local coin = Instance.new("Part")
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.25, 1.5, 1.5)
	coin.Material = Enum.Material.Neon
	coin.Color = Color3.fromRGB(255, 205, 50)
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanQuery = false
	coin.CanTouch = false
	coin.CastShadow = false
	local startY = groundY + random:NextNumber(16, 26)
	coin.CFrame = CFrame.new(x, startY, z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), math.rad(90))
	coin.Parent = folder
	local time = random:NextNumber(0.8, 1.4)
	local endCF = CFrame.new(x, groundY + 0.8, z) * CFrame.Angles(random:NextNumber(0, math.pi * 2), random:NextNumber(0, math.pi * 2), math.rad(90))
	local fall = TweenService:Create(coin, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = endCF })
	fall:Play()
	fall.Completed:Connect(function()
		TweenService:Create(coin, TweenInfo.new(0.35), { Transparency = 1, Size = Vector3.new(0.1, 0.4, 0.4) }):Play()
	end)
	Debris:AddItem(coin, time + 0.5)
end

local function coinRain(owner, earned: number, level: number)
	local root = rootNear(owner)
	if not root then
		return
	end
	local count = level >= 2 and 32 or 18
	local groundY = root.Position.Y - 3
	for i = 1, count do
		task.delay((i - 1) * 0.05, function()
			local r = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
			fallingCoin(r and r.Position or root.Position, groundY)
		end)
	end
	if owner == player then
		local params = PetAbilities.SuperParams("CoinRain", level)
		popText(root, PetAbilities.Supers.CoinRain.Icon .. " " .. string.upper(params and params.Name or "Coin Rain") .. "  +" .. abbreviate(earned), Color3.fromRGB(255, 220, 80))
	end
end

local function vacuum(owner, count: number, radius: number)
	local root = rootNear(owner)
	if not root then
		return
	end
	radius = math.clamp(radius or 10, 4, 120)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = PetAbilities.Supers.Vacuum.Color
	ring.Transparency = 0.55
	ring.Size = Vector3.new(0.2, radius * 2, radius * 2)
	ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(0.2, 1, 1), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.5)
	if owner == player then
		popText(root, PetAbilities.Supers.Vacuum.Icon .. " +" .. count .. " coins", PetAbilities.Supers.Vacuum.Color)
	end
end

remote.OnClientEvent:Connect(function(owner, key, amount, extra)
	if typeof(owner) ~= "Instance" or not owner:IsA("Player") then
		return
	end
	if key == "CoinRain" then
		coinRain(owner, tonumber(amount) or 0, tonumber(extra) or 1)
	elseif key == "Vacuum" then
		vacuum(owner, tonumber(amount) or 0, tonumber(extra) or 10)
	end
end)
