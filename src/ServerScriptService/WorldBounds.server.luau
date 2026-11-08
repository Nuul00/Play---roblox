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
	return p
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

-- Стена вдоль оси X (на линии z) от x0 до x1 с проходом [g0, g1] (если он задан).
local function wallX(name: string, x0: number, x1: number, z: number, y: number, g0: number?, g1: number?)
	if g0 and g1 and g1 > x0 and g0 < x1 then
		if g0 > x0 then
			wall(name .. "A", Vector3.new(g0 - x0, HEIGHT, THICK), Vector3.new((x0 + g0) / 2, y, z))
		end
		if x1 > g1 then
			wall(name .. "B", Vector3.new(x1 - g1, HEIGHT, THICK), Vector3.new((g1 + x1) / 2, y, z))
		end
	else
		wall(name, Vector3.new(x1 - x0, HEIGHT, THICK), Vector3.new((x0 + x1) / 2, y, z))
	end
end
local function wallZ(name: string, z0: number, z1: number, x: number, y: number, g0: number?, g1: number?)
	if g0 and g1 and g1 > z0 and g0 < z1 then
		if g0 > z0 then
			wall(name .. "A", Vector3.new(THICK, HEIGHT, g0 - z0), Vector3.new(x, y, (z0 + g0) / 2))
		end
		if z1 > g1 then
			wall(name .. "B", Vector3.new(THICK, HEIGHT, z1 - g1), Vector3.new(x, y, (g1 + z1) / 2))
		end
	else
		wall(name, Vector3.new(THICK, HEIGHT, z1 - z0), Vector3.new(x, y, (z0 + z1) / 2))
	end
end

-- Как box, но с островом (iMin..iMax), который примыкает к одной из сторон: в этой стороне
-- проход шириной с остров, вокруг острова — три своих стены.
local function islandBox(name: string, minV: Vector3, maxV: Vector3, floorY: number, iMin: Vector3, iMax: Vector3)
	local y = floorY + HEIGHT / 2 - 20
	local T2 = THICK / 2
	local side
	-- остров выходит за эту сторону пола (может и заходить на пол, как в Неонграде)
	if iMax.Z > maxV.Z + 5 then
		side = "N"
	elseif iMin.Z < minV.Z - 5 then
		side = "S"
	elseif iMax.X > maxV.X + 5 then
		side = "E"
	elseif iMin.X < minV.X - 5 then
		side = "W"
	end
	local x0, x1, z0, z1 = minV.X - THICK, maxV.X + THICK, minV.Z, maxV.Z
	local gx0, gx1 = math.max(iMin.X, minV.X), math.min(iMax.X, maxV.X)
	local gz0, gz1 = math.max(iMin.Z, minV.Z), math.min(iMax.Z, maxV.Z)
	wallX(name .. "North", x0, x1, maxV.Z + T2, y, side == "N" and gx0 or nil, side == "N" and gx1 or nil)
	wallX(name .. "South", x0, x1, minV.Z - T2, y, side == "S" and gx0 or nil, side == "S" and gx1 or nil)
	wallZ(name .. "East", z0, z1, maxV.X + T2, y, side == "E" and gz0 or nil, side == "E" and gz1 or nil)
	wallZ(name .. "West", z0, z1, minV.X - T2, y, side == "W" and gz0 or nil, side == "W" and gz1 or nil)
	if side == "N" or side == "S" then
		local a, b = side == "N" and maxV.Z or iMin.Z, side == "N" and iMax.Z or minV.Z
		wallZ(name .. "IslandW", a, b, gx0 - T2, y)
		wallZ(name .. "IslandE", a, b, gx1 + T2, y)
		local zEnd = side == "N" and iMax.Z + T2 or iMin.Z - T2
		wallX(name .. "IslandEnd", gx0 - THICK, gx1 + THICK, zEnd, y)
	elseif side == "E" or side == "W" then
		local a, b = side == "E" and maxV.X or iMin.X, side == "E" and iMax.X or minV.X
		wallX(name .. "IslandS", a, b, gz0 - T2, y)
		wallX(name .. "IslandN", a, b, gz1 + T2, y)
		local xEnd = side == "E" and iMax.X + T2 or iMin.X - T2
		wallZ(name .. "IslandEnd", gz0 - THICK, gz1 + THICK, xEnd, y)
	end
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
		-- остров лидеров примыкает к краю пола: в стене на его ширину проход, а сам остров
		-- обнесён своими стенами (раньше стена отрезала доски)
		local island = world:WaitForChild("LeaderboardIsland_Meadow", 30)
		if island and island:IsA("Model") then
			local cf, sz = island:GetBoundingBox()
			islandBox("Meadow", minV, maxV, maxV.Y, cf.Position - sz / 2, cf.Position + sz / 2)
		else
			box("Meadow", minV, maxV, maxV.Y)
		end
	end
	if city then
		local parts = {}
		local f = city:FindFirstChild("Floor")
		if f and f:IsA("BasePart") then
			table.insert(parts, f)
		end
		-- 2026-11: стены — по краю пола с квадратиками (Floor). Раньше их ставили по краю тёмной
		-- OuterGround (на 24–66 студов дальше), и игрок уходил в «чёрную бездну» за полом.
		-- Остров лидеров по-прежнему с проходом (islandBox).
		if #parts > 0 then
			local minV, maxV = bounds(parts)
			-- 2026-11 (фидбэк «пустота ничего не меняет»): город уже — стены сразу за рядами зданий
			-- (здания до x−123 и x+135 от центра), тёмные полосы за ними убраны.
			local cx = f.Position.X
			local west, east = cx - 126, cx + 140
			minV = Vector3.new(math.max(minV.X, west), minV.Y, minV.Z)
			maxV = Vector3.new(math.min(maxV.X, east), maxV.Y, maxV.Z)
			-- видимые стены города (CityWalls) и тёмный пол вокруг — к новым границам
			local walls = city:FindFirstChild("CityWalls")
			if walls then
				for _, p in ipairs(walls:GetDescendants()) do
					if p:IsA("BasePart") then
						if p.Size.Z > 400 and p.Size.X < 10 then
							-- продольные стены и их неоновые полосы: сохраняем отступ от старой стены
							if p.Position.X < cx then
								p.Position = Vector3.new(west - 2 + (p.Position.X - (cx - 212)), p.Position.Y, p.Position.Z)
							else
								p.Position = Vector3.new(east + 2 - ((cx + 212) - p.Position.X), p.Position.Y, p.Position.Z)
							end
						elseif p.Size.X > 60 then
							-- поперечные стены, полосы и OuterGround: обрезаем по X
							local x0, x1 = p.Position.X - p.Size.X / 2, p.Position.X + p.Size.X / 2
							local n0, n1 = math.max(x0, west - 4), math.min(x1, east + 4)
							if n1 - n0 > 0.5 then
								p.Size = Vector3.new(n1 - n0, p.Size.Y, p.Size.Z)
								p.Position = Vector3.new((n0 + n1) / 2, p.Position.Y, p.Position.Z)
							end
						end
					end
				end
			end
			local island = city:WaitForChild("LeaderboardIsland_NeonCity", 30)
			if island and island:IsA("Model") then
				local cf, sz = island:GetBoundingBox()
				islandBox("Neon", minV, maxV, maxV.Y, cf.Position - sz / 2, cf.Position + sz / 2)
			else
				box("Neon", minV, maxV, maxV.Y)
			end
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

-- ===== Sky Isles: край острова у моста к лидербордам =====
-- Фидбэк 2026-11: с края острова рядом с мостом спрыгивали в пустоту (и вставали на невидимые
-- шары облаков). Невидимая стена дугой по краю (радиус ~166 от центра острова) на ±45° от моста,
-- с проёмом ровно под мост.
task.spawn(function()
	local sky = world:WaitForChild("SkyIsles", 120)
	local island = sky and sky:WaitForChild("LeaderboardIsland_SkyIsles", 120)
	local deck = island and island:WaitForChild("BridgeDeck", 30)
	local ground = sky and sky:FindFirstChild("Ground")
	if not (deck and ground) then
		return
	end
	local deckTopY = deck.Position.Y + deck.Size.Y / 2
	local center = Vector3.new(1100, deckTopY, 0)
	local ok, cf = pcall(function()
		return (ground:IsA("Model") and ground:GetBoundingBox()) or ground.CFrame
	end)
	if ok and cf then
		center = Vector3.new(cf.Position.X, deckTopY, cf.Position.Z)
	end
	local R = 166
	local bridgeAng = math.atan2(deck.Position.Z - center.Z, deck.Position.X - center.X)
	local gap = (deck.Size.X / 2 + 0.4) / R -- полуширина проёма (рад)
	local step = math.rad(3)
	for a = bridgeAng - math.rad(45), bridgeAng + math.rad(45), step do
		local a0, a1 = a, a + step
		-- вырезаем проём под мост
		if not (a1 > bridgeAng - gap and a0 < bridgeAng + gap) then
			local p0 = center + Vector3.new(math.cos(a0), 0, math.sin(a0)) * R
			local p1 = center + Vector3.new(math.cos(a1), 0, math.sin(a1)) * R
			local mid = (p0 + p1) / 2
			local w = wall("SkyRimGuard", Vector3.new(THICK, 60, (p1 - p0).Magnitude + 1), mid + Vector3.new(0, 26, 0))
			w.CFrame = CFrame.lookAt(mid + Vector3.new(0, 26, 0), mid + Vector3.new(0, 26, 0) + (p1 - p0))
		end
	end
end)
