-- Оживление места Royal Egg: яйцо парит и вращается над пьедесталом, вокруг кружат искры и
-- золотые лучи, на щите — витрина с 3D-питомцами (лучший мир игрока), шансами и надписью;
-- встал на золотой круг — открылось окно покупки (RoyalEggUI).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Worlds = require(ReplicatedStorage:WaitForChild("WorldsConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer
local R = Config.RobuxEgg
if not R then
	return
end

local RARITY = {
	Common = Color3.fromRGB(200, 205, 220),
	Uncommon = Color3.fromRGB(110, 220, 120),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 190, 50),
	Secret = Color3.fromRGB(255, 90, 160),
}
local SHORT = { ["Meadow Isles"] = "island", ["Neon District"] = "neon", ["Sky Isles"] = "sky", ["Frozen Peaks"] = "frozen", ["Magma Volcano"] = "volcano", ["Cosmic Galaxy"] = "galaxy" }
local function bestWorld()
	local best = "island"
	for _, w in ipairs(Worlds.Worlds) do
		if w.Open and SHORT[w.Id] and ((w.Cost or 0) <= 0 or player:GetAttribute(Worlds.UnlockKey(w.Id))) then
			best = SHORT[w.Id]
		end
	end
	return best
end

local stands = {}

local function label(parent, text, pos, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextScaled = true
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = font or Enum.Font.FredokaOne
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = Color3.fromRGB(40, 15, 60)
	s.Parent = l
	return l
end

local function setup(m: Model)
	local board = m:WaitForChild("Board", 10)
	local egg = m:WaitForChild("DisplayEgg", 10)
	local zone = m:WaitForChild("RoyalZone", 10)
	if not (board and egg and zone) then
		return
	end
	local st = { model = m, egg = egg, base = egg:GetPivot(), cards = {}, world = nil, zone = zone, inside = false }
	-- витрина
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(1100, 550)
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	gui.Adornee = board
	gui.Parent = player:WaitForChild("PlayerGui")
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(70, 25, 110)
	bg.Parent = gui
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 90, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 45, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 20, 130)) })
	g.Rotation = 90
	g.Parent = bg
	-- 2026-11 (фидбэк 8): ярче — золотая рамка внутри доски и блик сверху
	local goldEdge = Instance.new("UIStroke")
	goldEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	goldEdge.Thickness = 10
	goldEdge.Color = Color3.fromRGB(255, 205, 80)
	goldEdge.Parent = bg
	local shine = Instance.new("Frame")
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.82
	shine.BorderSizePixel = 0
	shine.Position = UDim2.fromOffset(14, 10)
	shine.Size = UDim2.new(1, -28, 0, 120)
	shine.Parent = bg
	Instance.new("UICorner", shine).CornerRadius = UDim.new(0, 30)
	label(bg, "👑 ROYAL EGG 👑", UDim2.fromOffset(0, 10), UDim2.new(1, 0, 0, 90), Color3.fromRGB(255, 215, 90))
	st.sub = label(bg, "Stand on the golden circle to open!", UDim2.fromOffset(0, 98), UDim2.new(1, 0, 0, 40), Color3.fromRGB(240, 225, 255), Enum.Font.GothamBold)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(20, 150)
	row.Size = UDim2.new(1, -40, 0, 380)
	row.Parent = bg
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = row
	for t, tier in ipairs(R.Tiers) do
		local c = Instance.new("Frame")
		c.LayoutOrder = t
		c.Size = UDim2.fromOffset(165, 370)
		c.BackgroundColor3 = RARITY[tier.Rarity]:Lerp(Color3.fromRGB(40, 15, 70), 0.72)
		c.Parent = row
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 18)
		local s = Instance.new("UIStroke")
		s.Thickness = 5
		s.Color = RARITY[tier.Rarity]
		s.Parent = c
		local v = Instance.new("ViewportFrame")
		v.BackgroundTransparency = 1
		v.Position = UDim2.fromOffset(4, 50)
		v.Size = UDim2.fromOffset(157, 180)
		v.Ambient = Color3.fromRGB(210, 195, 224)
		v.LightColor = Color3.fromRGB(255, 236, 214)
		v.LightDirection = Vector3.new(-1, -1, -2)
		v.Parent = c
		local cam = Instance.new("Camera")
		cam.FieldOfView = 38
		cam.CFrame = CFrame.lookAt(Vector3.new(3, 1.8, -5.8), Vector3.zero)
		cam.Parent = v
		v.CurrentCamera = cam
		local wm = Instance.new("WorldModel", v)
		label(c, tier.Rarity:upper(), UDim2.fromOffset(6, 8), UDim2.new(1, -12, 0, 36), RARITY[tier.Rarity], Enum.Font.GothamBlack)
		local name = label(c, tier.Name, UDim2.fromOffset(6, 236), UDim2.new(1, -12, 0, 40))
		local chance = label(c, string.format("%g%%", tier.Chance), UDim2.fromOffset(6, 278), UDim2.new(1, -12, 0, 44), RARITY[tier.Rarity])
		local power = label(c, "", UDim2.fromOffset(6, 324), UDim2.new(1, -12, 0, 34), Color3.fromRGB(255, 225, 140), Enum.Font.GothamBold)
		st.cards[t] = { wm = wm, power = power, stroke = s, name = name, chance = chance }
	end
	-- искры и лучи вокруг яйца
	local anchor = m:FindFirstChild("EggAnchor")
	if anchor then
		local a = Instance.new("Attachment", anchor)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(255, 225, 120), Color3.fromRGB(220, 160, 255))
		e.LightEmission = 1
		e.Rate = 25
		e.Lifetime = NumberRange.new(1, 2)
		e.Speed = NumberRange.new(1.5, 3)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = a
		-- кольца-орбиты вокруг яйца (золотое и фиолетовое), медленно вращаются
		st.rays = {}
		for i = 1, 2 do
			local segs = {}
			for k = 1, 28 do
				local s = Instance.new("Part")
				s.Anchored, s.CanCollide, s.CanQuery, s.CanTouch, s.CastShadow = true, false, false, false, false
				s.Material = Enum.Material.Neon
				s.Color = i == 1 and Color3.fromRGB(255, 215, 110) or Color3.fromRGB(210, 150, 255)
				s.Transparency = 0.3
				s.Size = Vector3.new(0.22, 0.22, (12 + i * 1.5) * math.pi / 28 * 1.05)
				s.Parent = m
				segs[k] = s
			end
			st.rays[i] = { segs = segs, radius = (12 + i * 1.5) / 2, tilt = i == 1 and 0.35 or -0.5 }
		end
		st.center = anchor.Position
	end
	table.insert(stands, st)
end

local function fill(st)
	local w = bestWorld()
	if st.world == w then
		return
	end
	st.world = w
	local ids = R.ByWorld[w] or R.ByWorld.island
	local topMult = Config.Pets[ids[#ids]].Multiplier / R.Tiers[#R.Tiers].Pct
	for t, c in ipairs(st.cards) do
		c.wm:ClearAllChildren()
		local ok, model = pcall(PetVisuals.Build, ids[t])
		if ok and model then
			model.Parent = c.wm
			c.model = model
		end
		local def = Config.Pets[ids[t]]
		c.power.Text = "×" .. NumberFormat.Short(def.Multiplier) .. " · " .. math.floor(def.Multiplier / topMult * 100 + 0.5) .. "%"
	end
end

CollectionService:GetInstanceAddedSignal("RoyalEggStand"):Connect(setup)
for _, m in ipairs(CollectionService:GetTagged("RoyalEggStand")) do
	task.spawn(setup, m)
end
for _, n in ipairs({ "CurrentWorld" }) do
	player:GetAttributeChangedSignal(n):Connect(function()
		for _, st in ipairs(stands) do
			st.world = nil
		end
	end)
end

local t, acc = 0, 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	acc += dt
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	for _, st in ipairs(stands) do
		local near = root and st.center and (root.Position - st.center).Magnitude < 140
		if near then
			if not st.world then
				fill(st)
			end
			if st.egg.Parent and not st.hidden then
				st.egg:PivotTo(st.base * CFrame.new(0, math.sin(t * 1.8) * 0.6, 0) * CFrame.Angles(0, t * 0.8, math.sin(t * 1.3) * 0.06))
			end
			for i, ring in ipairs(st.rays or {}) do
				local frame = CFrame.new(st.center) * CFrame.Angles(ring.tilt + 0.1 * math.sin(t + i), t * (i == 1 and 0.5 or -0.4), 0)
				for k, s in ipairs(ring.segs) do
					local a = k / #ring.segs * math.pi * 2
					local p = frame * Vector3.new(math.cos(a) * ring.radius, 0, math.sin(a) * ring.radius)
					local tangent = frame:VectorToWorldSpace(Vector3.new(-math.sin(a), 0, math.cos(a)))
					s.CFrame = CFrame.lookAt(p, p + tangent)
				end
			end
			for i, c in ipairs(st.cards) do
				if c.model then
					c.model:PivotTo(CFrame.Angles(0, t * 0.7 + i, 0))
				end
				if i >= 5 then
					c.stroke.Transparency = 0.2 + 0.3 * math.sin(t * 4 + i)
				end
			end
			-- круг входа
			local d = root.Position - st.zone.Position
			local inside = Vector2.new(d.X, d.Z).Magnitude < st.zone.Size.Y / 2 and math.abs(d.Y) < 8
			if inside and not st.inside then
				local ev = player.PlayerGui:FindFirstChild("OpenRoyalEgg")
				if ev then
					ev:Fire()
				end
			end
			st.inside = inside
			st.zone.Transparency = 0.35 + 0.2 * math.sin(t * 3)
		end
	end
end)

-- для анимации открытия (RoyalHatch): где сейчас ближайшее яйцо на пьедестале
local api = Instance.new("BindableFunction")
api.Name = "RoyalEggStandInfo"
api.OnInvoke = function(cmd)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local best, bd
	for _, st in ipairs(stands) do
		if st.center and root then
			local d = (root.Position - st.center).Magnitude
			if not bd or d < bd then
				best, bd = st, d
			end
		end
	end
	if cmd == "hide" and best then
		best.hidden = true
		for _, p in ipairs(best.egg:GetDescendants()) do
			if p:IsA("BasePart") then
				p.LocalTransparencyModifier = 1
			end
		end
	elseif cmd == "show" then
		for _, st in ipairs(stands) do
			st.hidden = false
			for _, p in ipairs(st.egg:GetDescendants()) do
				if p:IsA("BasePart") then
					p.LocalTransparencyModifier = 0
				end
			end
		end
	end
	return best and best.egg:GetPivot().Position, bd
end
api.Parent = player:WaitForChild("PlayerGui")
