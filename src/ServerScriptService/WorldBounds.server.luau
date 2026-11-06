-- Границы миров.
-- 1) Невидимые стены по краю пола Meadow Isles и Неонграда: игрок упирается и дальше не идёт.
--    (Frozen Peaks закрыт стеклом снежного шара, у Sky Isles острова — стены мешали бы прыжкам.)
-- 2) Страховка от падения во всех мирах: запоминаем последнее место, где игрок стоял на земле,
--    и если он упал намного ниже — возвращаем туда.
local Players = game:GetService("Players")

local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity", 60)

local HEIGHT = 400
local THICK = 6

local folder = Instance.new("Folder")
folder.Name = "WorldBounds"
folder.Parent = workspace

local function wall(name: string, size: Vector3, pos: Vector3)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	p.CanQuery = false -- камера и лучи проходят насквозь
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size
	p.Position = pos
	p.Parent = folder
end

-- Прямоугольник из четырёх стен вокруг области min..max (по X и Z), от пола вверх.
local function box(name: string, minV: Vector3, maxV: Vector3, floorY: number)
	local cx, cz = (minV.X + maxV.X) / 2, (minV.Z + maxV.Z) / 2
	local sx, sz = maxV.X - minV.X, maxV.Z - minV.Z
	local y = floorY + HEIGHT / 2 - 20
	wall(name .. "North", Vector3.new(sx + THICK * 2, HEIGHT, THICK), Vector3.new(cx, y, maxV.Z + THICK / 2))
	wall(name .. "South", Vector3.new(sx + THICK * 2, HEIGHT, THICK), Vector3.new(cx, y, minV.Z - THICK / 2))
	wall(name .. "East", Vector3.new(THICK, HEIGHT, sz), Vector3.new(maxV.X + THICK / 2, y, cz))
	wall(name .. "West", Vector3.new(THICK, HEIGHT, sz), Vector3.new(minV.X - THICK / 2, y, cz))
end

local function bounds(parts: { BasePart })
	local minV, maxV
	for _, p in ipairs(parts) do
		local h = p.Size / 2
		local a, b = p.Position - h, p.Position + h
		minV = minV and minV:Min(a) or a
		maxV = maxV and maxV:Max(b) or b
	end
	return minV, maxV
end

task.defer(function()
	local floor = world:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		local minV, maxV = bounds({ floor })
		box("Meadow", minV, maxV, maxV.Y)
	end
	if city then
		local parts = {}
		local f = city:FindFirstChild("Floor")
		if f and f:IsA("BasePart") then
			table.insert(parts, f)
		end
		local walls = city:FindFirstChild("CityWalls")
		local outer = walls and walls:FindFirstChild("OuterGround")
		if outer and outer:IsA("BasePart") then
			table.insert(parts, outer)
		end
		if #parts > 0 then
			local minV, maxV = bounds(parts)
			box("Neon", minV, maxV, maxV.Y)
		end
	end
end)

-- ===== Страховка от падения =====
local FALL = 40 -- насколько ниже последней опоры считаем, что игрок упал
-- Есть ли под игроком хоть что-то твёрдое (если есть — он просто спрыгнул, а не падает в пустоту).
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
local function groundBelow(char: Model, pos: Vector3): boolean
	rayParams.FilterDescendantsInstances = { char, folder }
	local hit = workspace:Raycast(pos, Vector3.new(0, -2000, 0), rayParams)
	return hit ~= nil and hit.Instance.CanCollide
end
local safe: { [Player]: CFrame } = {}
Players.PlayerRemoving:Connect(function(p)
	safe[p] = nil
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local last = safe[p]
				-- телепорт в другой мир: старая опора больше не считается
				if last then
					local d = root.Position - last.Position
					if Vector2.new(d.X, d.Z).Magnitude > 300 then
						last = nil
						safe[p] = nil
					end
				end
				if hum.FloorMaterial ~= Enum.Material.Air and root.AssemblyLinearVelocity.Y > -5 then
					safe[p] = root.CFrame
				elseif last and root.Position.Y < last.Position.Y - FALL and not groundBelow(char, root.Position) then
					root.AssemblyLinearVelocity = Vector3.zero
					p:SetAttribute("ServerTP", os.clock()) -- серверный телепорт: проверка скачков в GameServer его не наказывает
					char:PivotTo(last + Vector3.new(0, 4, 0))
				end
			end
		end
	end
end)
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		safe[p] = nil
	end)
end)
