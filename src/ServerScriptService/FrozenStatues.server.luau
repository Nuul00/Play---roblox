-- «Скины во льду»: аватары создателя игры и игроков на сервере вморожены в ледяные кристаллы
-- в ряд за садом яиц Frozen Peaks. Центральное место — создатель (Config.ShopkeeperUserId),
-- остальные 6 мест занимают игроки по мере входа (вышел — его кристалл тает и место свободно).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local world = workspace:WaitForChild("CoinSpeedWorld")
local frozen = world:WaitForChild("FrozenPeaks", 120)
if not frozen then
	return
end

local CENTER = Vector3.new(3000, 60, 0)
local ROW_X, ROW_Z = 105, -111
local SLOTS = { 0, -18, 18, -36, 36, -54, 54 } -- x относительно центра; первое — создателю
local ICE = Color3.fromRGB(170, 220, 255)

local folder = Instance.new("Folder")
folder.Name = "FrozenStatues"
folder.Parent = frozen

local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Include
local function groundY(x: number, z: number): number
	ray.FilterDescendantsInstances = { frozen }
	local hit = workspace:Raycast(Vector3.new(x, CENTER.Y + 60, z), Vector3.new(0, -120, 0), ray)
	return hit and hit.Position.Y or CENTER.Y
end

local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local occupied: { [number]: Model } = {}

local function build(slot: number, userId: number, displayName: string)
	local x = CENTER.X + ROW_X + SLOTS[slot]
	local z = CENTER.Z + ROW_Z
	local y = groundY(x, z)
	local m = Instance.new("Model")
	m.Name = "FrozenStatue" .. slot
	m:SetAttribute("UserId", userId)
	-- постамент из снега и льда
	part(m, "Base", Vector3.new(1.2, 9, 9), CFrame.new(x, y + 0.6, z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(240, 248, 255), Enum.Material.Snow, { Shape = Enum.PartType.Cylinder })
	part(m, "BaseGlow", Vector3.new(0.4, 9.6, 9.6), CFrame.new(x, y + 0.25, z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(130, 210, 255), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	-- аватар, застывший в позе
	local ok, avatar = pcall(function()
		return Players:CreateHumanoidModelFromUserIdAsync(userId)
	end)
	if ok and avatar then
		local hum = avatar:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.PlatformStand = true
		end
		for _, d in ipairs(avatar:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
			elseif d:IsA("Script") or d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		avatar:PivotTo(CFrame.new(x, y + 5, z) * CFrame.Angles(0, math.pi, 0)) -- лицом к саду яиц
		-- ставим ровно низом на постамент (рамка модели считается уже после поворота)
		local bcf, bsize = avatar:GetBoundingBox()
		avatar:PivotTo(avatar:GetPivot() + Vector3.new(0, (y + 1.25) - (bcf.Position.Y - bsize.Y / 2), 0))
		avatar.Name = "Avatar"
		avatar.Parent = m
	end
	-- ледяной кристалл вокруг: прозрачные грани и сосульки
	local h = 8.5
	local crystal = part(m, "Ice", Vector3.new(5.4, h, 4.4), CFrame.new(x, y + 1.2 + h / 2, z), ICE, Enum.Material.SmoothPlastic, { Transparency = 0.62, Reflectance = 0.12, CanCollide = true })
	crystal.CastShadow = false
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2
		local sh = 3 + (k % 3)
		part(m, "Shard", Vector3.new(1.2, sh, 1.2), CFrame.new(x + math.cos(a) * 3.2, y + 1.2 + sh / 2 - 0.4, z + math.sin(a) * 2.8) * CFrame.Angles(math.sin(a) * 0.35, a, math.cos(a) * 0.35), ICE, Enum.Material.Ice, { Transparency = 0.3, CanCollide = false, CastShadow = false })
	end
	part(m, "Cap", Vector3.new(2.6, 3.2, 2.6), CFrame.new(x, y + 1.2 + h + 1, z) * CFrame.Angles(0, math.pi / 4, 0), ICE, Enum.Material.Ice, { Transparency = 0.25, CanCollide = false, CastShadow = false })
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(150, 215, 255)
	glow.Range = 14
	glow.Brightness = 1.4
	glow.Parent = crystal
	local frost = Instance.new("ParticleEmitter")
	frost.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	frost.Color = ColorSequence.new(Color3.fromRGB(210, 240, 255))
	frost.LightEmission = 1
	frost.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	frost.Lifetime = NumberRange.new(1, 2)
	frost.Speed = NumberRange.new(0.5, 1.5)
	frost.SpreadAngle = Vector2.new(180, 180)
	frost.Rate = 6
	frost.Parent = crystal
	-- табличка с именем
	local board = part(m, "NameBoard", Vector3.new(7, 1.4, 0.4), CFrame.new(x, y + 1.9, z + 4.7), Color3.fromRGB(40, 90, 170), Enum.Material.SmoothPlastic, { CanCollide = false })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.CanvasSize = Vector2.new(350, 70)
	sg.LightInfluence = 0
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = (slot == 1 and "👑 " or "❄ ") .. displayName
	lbl.Parent = sg
	sg.Parent = board
	m.Parent = folder
	occupied[slot] = m
end

-- центр — создатель игры
task.spawn(function()
	local name = "Creator"
	pcall(function()
		name = Players:GetNameFromUserIdAsync(Config.ShopkeeperUserId)
	end)
	build(1, Config.ShopkeeperUserId, name)
end)

local function freeSlot(): number?
	for i = 2, #SLOTS do
		if not occupied[i] then
			return i
		end
	end
	return nil
end
local function onPlayer(p: Player)
	if p.UserId == Config.ShopkeeperUserId then
		return
	end
	local slot = freeSlot()
	if slot then
		occupied[slot] = folder -- занято, пока строится
		build(slot, p.UserId, p.DisplayName)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end
Players.PlayerRemoving:Connect(function(p)
	for i, m in pairs(occupied) do
		if typeof(m) == "Instance" and m:IsA("Model") and m:GetAttribute("UserId") == p.UserId then
			m:Destroy()
			occupied[i] = nil
		end
	end
end)
