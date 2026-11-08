-- Подвесные вывески (тег SwingSign, ставит LeaderboardBuilder) качаются на ветру: щит и цепи —
-- маятник вокруг перекладины (TopBarLong) с порывами, плюс лёгкое закручивание на цепях.
-- Только на клиенте и только рядом с камерой (до 140 студов).
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local signs = {}

local function setup(m: Instance)
	if not m:IsA("Model") then
		return
	end
	local bar = m:WaitForChild("TopBarLong", 10)
	if not (bar and bar:IsA("BasePart")) then
		return
	end
	task.wait(0.5) -- дать дореплицироваться деталям
	-- шарнир: ось X — вдоль перекладины, Y — строго вверх (у детали перекладины свои оси повёрнуты)
	local right = Vector3.new(bar.CFrame.RightVector.X, 0, bar.CFrame.RightVector.Z).Unit
	local hinge = CFrame.fromMatrix(bar.Position, right, Vector3.yAxis)
	local center = (m.PrimaryPart and m.PrimaryPart.Position) or m:GetPivot().Position
	local parts, offsets = {}, {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d ~= bar and d.Position.Y < hinge.Position.Y - 0.25 then
			d.Anchored = true
			table.insert(parts, d)
			table.insert(offsets, hinge:ToObjectSpace(d.CFrame))
		end
	end
	if #parts == 0 then
		return
	end
	table.insert(signs, {
		model = m,
		hinge = hinge,
		center = center,
		parts = parts,
		offsets = offsets,
		seed = math.random() * 100,
		buffer = table.create(#parts),
	})
end

CollectionService:GetInstanceAddedSignal("SwingSign"):Connect(function(m)
	task.spawn(setup, m)
end)
for _, m in ipairs(CollectionService:GetTagged("SwingSign")) do
	task.spawn(setup, m)
end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local camPos = cam.CFrame.Position
	for i = #signs, 1, -1 do
		local s = signs[i]
		if not s.model.Parent then
			table.remove(signs, i)
		elseif (s.center - camPos).Magnitude < 140 then
			local k = t + s.seed
			-- порывы: медленная огибающая 0.35..1 умножает основное качание
			local gust = 0.675 + 0.325 * math.sin(k * 0.23) * math.sin(k * 0.61 + 1.3)
			local swing = math.rad(5.5) * gust * math.sin(k * 1.6) + math.rad(1.2) * math.sin(k * 3.7 + 0.5)
			local twist = math.rad(2.5) * gust * math.sin(k * 1.1 + 2)
			-- маятник вокруг оси перекладины (её X) + закручивание вокруг вертикали
			local rot = s.hinge * CFrame.Angles(swing, twist, 0)
			for j, off in ipairs(s.offsets) do
				s.buffer[j] = rot * off
			end
			workspace:BulkMoveTo(s.parts, s.buffer, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
end)
