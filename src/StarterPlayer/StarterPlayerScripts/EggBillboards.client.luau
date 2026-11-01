-- Табло над каждым яйцом (оба мира): название, цена и питомцы, которых можно выбить, с шансами.
-- Плюс оживление яиц: парят, крутятся, вокруг летают огоньки, голо-кольцо вращается.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity")

local rarityColors = {
	Common = Color3.fromRGB(182, 203, 190),
	Uncommon = Color3.fromRGB(128, 218, 147),
	Rare = Color3.fromRGB(110, 179, 255),
	Epic = Color3.fromRGB(198, 135, 255),
	Legendary = Color3.fromRGB(255, 206, 101),
	Mythic = Color3.fromRGB(255, 126, 191),
	Secret = Color3.fromRGB(255, 255, 255),
}

local function fmt(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function stroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or Color3.fromRGB(20, 20, 30)
	s.ApplyStrokeMode = parent:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end
local function label(parent, text, pos, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextScaled = true
	l.Font = font or Enum.Font.FredokaOne
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Parent = parent
	stroke(l, 2)
	return l
end

local boards = {}
local function buildBoard(id, stand)
	local egg = Config.Eggs[id]
	local anchor = stand:FindFirstChild("SignAnchor")
	if not anchor then
		local cf, size = stand.EggDisplay:GetBoundingBox()
		anchor = Instance.new("Attachment")
		anchor.Name = "SignAnchorLocal"
		anchor.Parent = stand:FindFirstChild("Interact") or stand.EggDisplay.PrimaryPart
		anchor.WorldPosition = cf.Position + Vector3.new(0, size.Y / 2 + 4.6, 0)
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EggBoard"
	gui.Size = UDim2.fromScale(13, 7.4)
	gui.MaxDistance = 75
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Adornee = anchor
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(22, 24, 40)
	panel.BackgroundTransparency = 0.15
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0.08, 0)
	stroke(panel, 3, egg.Color)

	-- Шапка: название и цена.
	local head = Instance.new("Frame")
	head.Size = UDim2.fromScale(1, 0.24)
	head.BackgroundColor3 = egg.Color
	head.Parent = panel
	Instance.new("UICorner", head).CornerRadius = UDim.new(0.3, 0)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(egg.Color:Lerp(Color3.new(1, 1, 1), 0.25), egg.Color:Lerp(Color3.new(0, 0, 0), 0.25))
	grad.Rotation = 90
	grad.Parent = head
	label(head, string.upper(egg.Name), UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.56, 0.84))
	local price = label(head, "💰 " .. fmt(egg.Cost), UDim2.fromScale(0.6, 0.12), UDim2.fromScale(0.37, 0.76), Color3.fromRGB(255, 230, 90))
	price.TextXAlignment = Enum.TextXAlignment.Right

	-- Питомцы: 6 ячеек в ряд, под каждой шанс выпадения.
	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromScale(0.025, 0.29)
	grid.Size = UDim2.fromScale(0.95, 0.62)
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(0.155, 1)
	layout.CellPadding = UDim2.fromScale(0.014, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	for i, entry in ipairs(egg.Pool) do
		local def = Config.Pets[entry.Pet]
		local color = rarityColors[def.Rarity] or Color3.new(1, 1, 1)
		local cell = Instance.new("Frame")
		cell.LayoutOrder = i
		cell.BackgroundColor3 = Color3.fromRGB(40, 44, 66)
		cell.Parent = grid
		Instance.new("UICorner", cell).CornerRadius = UDim.new(0.14, 0)
		stroke(cell, 2, color)
		local view = Instance.new("ViewportFrame")
		view.BackgroundTransparency = 1
		view.Size = UDim2.fromScale(1, 0.66)
		view.Ambient = Color3.fromRGB(200, 200, 215)
		view.LightColor = Color3.fromRGB(255, 248, 230)
		view.LightDirection = Vector3.new(-1, -1, -2)
		view.Parent = cell
		local cam = Instance.new("Camera")
		cam.FieldOfView = 38
		cam.CFrame = CFrame.lookAt(Vector3.new(4, 2.8, -6), Vector3.new(0, 0.2, 0))
		cam.Parent = view
		view.CurrentCamera = cam
		local scene = Instance.new("WorldModel")
		scene.Parent = view
		local ok, model = pcall(PetVisuals.Build, entry.Pet)
		if ok and model then
			model.Parent = scene
		end
		label(cell, string.format("%g%%", entry.Chance), UDim2.fromScale(0.04, 0.64), UDim2.fromScale(0.92, 0.2), color)
		label(cell, def.Rarity, UDim2.fromScale(0.04, 0.83), UDim2.fromScale(0.92, 0.14), color, Enum.Font.GothamBold)
	end
	label(panel, "Touch the egg to open", UDim2.fromScale(0.1, 0.915), UDim2.fromScale(0.8, 0.07), Color3.fromRGB(200, 205, 225), Enum.Font.GothamMedium)
	table.insert(boards, { gui = gui, anchor = anchor })
end

-- Оживление яиц.
local eggs = {}
local function setupEgg(id, stand)
	local display = stand:FindFirstChild("EggDisplay")
	if not display then
		return
	end
	local entry = { model = display, base = display:GetPivot(), phase = id * 1.3, holo = {}, orbs = {} }
	local ped = stand:FindFirstChild("Pedestal")
	if ped then
		local center = ped:FindFirstChild("Base") and ped.Base.Position or entry.base.Position
		for _, p in ipairs(ped:GetChildren()) do
			if p.Name == "HoloRing" then
				table.insert(entry.holo, { part = p, base = p.CFrame, center = center })
			end
		end
	end
	local color = Config.Eggs[id].Color
	for k = 1, 3 do
		local orb = Instance.new("Part")
		orb.Name = "EggOrb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(0.55, 0.55, 0.55)
		orb.Material = Enum.Material.Neon
		orb.Color = color:Lerp(Color3.new(1, 1, 1), 0.3)
		orb.Anchored = true
		orb.CanCollide = false
		orb.CanQuery = false
		orb.CanTouch = false
		orb.CastShadow = false
		orb.Parent = stand
		table.insert(entry.orbs, orb)
	end
	table.insert(eggs, entry)
end

for id in ipairs(Config.Eggs) do
	local zone = Config.Eggs[id].World == "neon" and city or world
	local stand = zone:WaitForChild("EggStand" .. id, 10)
	if stand then
		local ok, err = pcall(buildBoard, id, stand)
		if not ok then
			warn("[EggBillboards] " .. tostring(err))
		end
		setupEgg(id, stand)
	end
end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local camera = workspace.CurrentCamera
	local camPos = camera and camera.CFrame.Position or Vector3.zero
	for _, e in ipairs(eggs) do
		local center = e.base.Position
		if (center - camPos).Magnitude < 160 then
			local bob = math.sin(t * 1.6 + e.phase) * 0.35
			e.model:PivotTo(e.base * CFrame.new(0, 0.35 + bob, 0) * CFrame.Angles(0, t * 0.5, 0))
			for _, h in ipairs(e.holo) do
				local rot = CFrame.new(h.center) * CFrame.Angles(0, t * 0.7, 0) * CFrame.new(-h.center)
				h.part.CFrame = rot * h.base
			end
			for k, orb in ipairs(e.orbs) do
				local a = t * 1.2 + k / 3 * math.pi * 2 + e.phase
				orb.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * 3.6, math.sin(t * 2 + k) * 0.8, math.sin(a) * 3.6))
			end
		end
	end
end)
