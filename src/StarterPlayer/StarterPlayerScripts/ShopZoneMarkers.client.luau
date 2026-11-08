-- Видимые метки входа в магазины. Игровой тест: круг «встань сюда — откроется прокачка» у киоска
-- Meadow был полностью прозрачным (и надпись выключена) — новичок стоял у прилавка, и ничего
-- не открывалось. Теперь у каждого ShopZone (прокачка и магниты во всех мирах) у себя рисуем:
-- светящееся кольцо на земле, мягкий круг внутри, бегущие к центру стрелки и табличку над ним.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

local rgb = Color3.fromRGB
local STYLE = {
	UpgradeShop = { text = "⬆ UPGRADES", color = rgb(255, 200, 60) },
	MagnetShop = { text = "🧲 MAGNETS", color = rgb(120, 170, 255) },
}

local markers = {}
local function part(parent, size, cf, color, transp, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transp
	p.Size = size
	p.CFrame = cf
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function mark(zone: BasePart)
	if markers[zone] then
		return
	end
	local style = STYLE[zone.Parent and zone.Parent.Name or ""]
	if not style then
		return
	end
	local d = math.max(zone.Size.Y, zone.Size.Z)
	local m = Instance.new("Model")
	m.Name = "ShopZoneMarker"
	-- 2026-11 (фидбэк): круг уходил под дорожку — кладём его на верх того, что под зоной
	-- (дорожка, лёд, площадь), а не на высоту самой зоны
	local c = zone.Position
	local rp = RaycastParams.new()
	local skip = { zone }
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			table.insert(skip, pl.Character)
		end
	end
	for _, mk in pairs(markers) do
		table.insert(skip, mk.model)
	end
	rp.FilterDescendantsInstances = skip
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(c + Vector3.new(0, 4, 0), Vector3.new(0, -10, 0), rp)
	local floor = Vector3.new(c.X, hit and hit.Position.Y + 0.03 or c.Y, c.Z)
	local flat = CFrame.new(floor.X, floor.Y + 0.05, floor.Z) * CFrame.Angles(0, 0, math.pi / 2)
	-- внешнее кольцо из 24 сегментов и полупрозрачный круг
	local ring = {}
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local seg = part(m, Vector3.new(0.25, 0.5, d * math.pi / 24 + 0.15), CFrame.new(floor + Vector3.new(math.cos(a) * d / 2, 0.15, math.sin(a) * d / 2)) * CFrame.Angles(0, -a, 0), style.color, 0.1)
		table.insert(ring, seg)
	end
	part(m, Vector3.new(0.1, d, d), flat, style.color, 0.8, Enum.PartType.Cylinder)
	-- стрелки к центру (4 шт.)
	local arrows = {}
	for k = 0, 3 do
		local a = k * math.pi / 2
		local ar = part(m, Vector3.new(1.4, 0.2, 0.5), CFrame.new(), Color3.new(1, 1, 1), 0.2)
		table.insert(arrows, { p = ar, a = a })
	end
	-- табличка — над крышей магазина (раньше висела у земли над кругом)
	local labelPos = zone.Position + Vector3.new(0, 7, 0)
	local tm = zone.Parent:FindFirstChild("TripoModel")
	if tm and tm:IsA("Model") then
		local cf, sz = tm:GetBoundingBox()
		labelPos = Vector3.new(cf.X, cf.Y + sz.Y / 2 + 2.5, cf.Z)
	end
	local anchor = part(m, Vector3.new(0.5, 0.5, 0.5), CFrame.new(labelPos), style.color, 1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(5.5, 50, 1.5, 14) -- в студах (+ пиксели): дальние таблички меньше и не налезают на ближние
	bb.MaxDistance = 120
	bb.LightInfluence = 0
	bb.Adornee = anchor
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = style.color
	l.BackgroundTransparency = 0.05
	l.Text = style.text
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Parent = bb
	Instance.new("UICorner", l).CornerRadius = UDim.new(0, 14)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = rgb(30, 16, 60)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = l
	local ts = Instance.new("UIStroke")
	ts.Thickness = 2.5
	ts.Color = rgb(30, 16, 60)
	ts.Parent = l
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	pad.Parent = l
	m.Parent = workspace
	markers[zone] = { model = m, ring = ring, arrows = arrows, center = zone.Position, floor = floor, d = d, bb = anchor, base = anchor.Position }
end

local function scan()
	for _, d in ipairs(world:GetDescendants()) do
		if d.Name == "ShopZone" and d:IsA("BasePart") then
			mark(d)
		end
	end
end
task.spawn(function()
	task.wait(3)
	scan()
	world.DescendantAdded:Connect(function(d)
		if d.Name == "ShopZone" and d:IsA("BasePart") then
			task.defer(mark, d)
		end
	end)
	task.delay(15, scan) -- миры, собираемые кодом позже
end)

local t = 0
Run.RenderStepped:Connect(function(dt)
	t += dt
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for zone, mk in pairs(markers) do
		if not zone.Parent or (zone.Position - mk.center).Magnitude > 0.5 then
			-- круг передвинули (WorldPolish ставит его перед прилавком) — перерисуем
			mk.model:Destroy()
			markers[zone] = nil
			if zone.Parent then
				task.defer(mark, zone)
			end
		elseif root and (root.Position - mk.center).Magnitude < 160 then
			-- стрелки бегут к центру, табличка покачивается, кольцо «дышит»
			local r = mk.d / 2
			for _, a in ipairs(mk.arrows) do
				local k = (t * 0.6 + a.a) % 1
				local dist = r + 3 - k * 3
				local pos = mk.floor + Vector3.new(math.cos(a.a) * dist, 0.25, math.sin(a.a) * dist)
				a.p.CFrame = CFrame.lookAt(pos, mk.floor + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, math.pi / 2, 0)
				a.p.Transparency = 0.2 + k * 0.7
			end
			local glow = 0.05 + 0.25 * (0.5 + 0.5 * math.sin(t * 3))
			for _, seg in ipairs(mk.ring) do
				seg.Transparency = glow
			end
			mk.bb.Position = mk.base + Vector3.new(0, math.sin(t * 2) * 0.4, 0)
		end
	end
end)
