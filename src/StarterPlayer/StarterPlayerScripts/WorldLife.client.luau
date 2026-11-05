-- «Живые» миры на клиенте: деревья качаются от ветра (с порывами), декоративные островки Sky Isles
-- парят, фонари во всех мирах светятся по-своему. Всё считается только рядом с камерой и не каждый кадр,
-- чтобы не вернуть лаги (см. оптимизацию SkyIslesFX).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local camera = workspace.CurrentCamera

local NEAR = 260 -- дальше этого не анимируем
local STEP = 1 / 30 -- 30 раз в секунду

------------------------------------------------------------------ деревья
-- Дерево: модель, в имени которой есть Tree/Pine/Palm. Качаем «листву» — детали, которые выше
-- середины дерева или названы Leaves/Leaf/Canopy/Crown; ствол стоит.
local trees = {}
local function isLeaf(p: BasePart, bottom: number, height: number)
	local n = string.lower(p.Name)
	if string.find(n, "leaf") or string.find(n, "leaves") or string.find(n, "canopy") or string.find(n, "crown") or string.find(n, "foliage") then
		return true
	end
	if string.find(n, "trunk") or string.find(n, "stem") or string.find(n, "root") then
		return false
	end
	return p.Position.Y > bottom + height * 0.45
end
local function addTree(m: Model)
	if m:GetAttribute("NoSway") then
		return
	end
	local cf, size = m:GetBoundingBox()
	if size.Y < 6 or size.Y > 120 then
		return
	end
	local bottom = cf.Position.Y - size.Y / 2
	local parts, bases = {}, {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Anchored and isLeaf(d, bottom, size.Y) then
			table.insert(parts, d)
			table.insert(bases, d.CFrame)
		end
	end
	if #parts == 0 then
		return
	end
	local pivot = Vector3.new(cf.Position.X, bottom + size.Y * 0.35, cf.Position.Z)
	table.insert(trees, {
		parts = parts,
		bases = bases,
		pivot = pivot,
		phase = (pivot.X * 0.13 + pivot.Z * 0.07) % (math.pi * 2),
		amp = math.clamp(2.2 / size.Y, 0.012, 0.05),
		cfs = table.create(#parts),
	})
end
local function scanTrees(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Model") then
			local n = string.lower(d.Name)
			if (string.find(n, "tree") or string.find(n, "pine") or string.find(n, "palm")) and not d:FindFirstAncestorWhichIsA("Model", true) then
				addTree(d)
			elseif string.find(n, "tree") or string.find(n, "pine") or string.find(n, "palm") then
				local parentModel = d.Parent and d.Parent:IsA("Model") and string.lower(d.Parent.Name)
				if not (parentModel and (string.find(parentModel, "tree") or string.find(parentModel, "pine"))) then
					addTree(d)
				end
			end
		end
	end
end

------------------------------------------------------------------ островки Sky Isles
local islets = {}
local function scanIslets()
	local sky = world:FindFirstChild("SkyIsles")
	local folder = sky and sky:FindFirstChild("Islets")
	if not folder then
		return
	end
	for i, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") then
			table.insert(islets, { model = m, base = m:GetPivot(), phase = i * 1.7, amp = 1.6 + (i % 3) * 0.6, spin = ((i % 2) * 2 - 1) * 0.04 })
		end
	end
end

------------------------------------------------------------------ фонари
-- Источник света (PointLight/SpotLight/SurfaceLight) — фонарь. Стиль зависит от мира, в котором он стоит.
local lights = {}
local function styleFor(light: Light)
	local sky = world:FindFirstChild("SkyIsles")
	local frozen = world:FindFirstChild("FrozenPeaks")
	local city = world:FindFirstChild("NeonCity")
	if sky and light:IsDescendantOf(sky) then
		return "Sky"
	elseif frozen and light:IsDescendantOf(frozen) then
		return "Frozen"
	elseif city and light:IsDescendantOf(city) then
		return "Neon"
	end
	return "Meadow"
end
local function addLight(l: Instance)
	if not (l:IsA("PointLight") or l:IsA("SpotLight") or l:IsA("SurfaceLight")) then
		return
	end
	local holder = l.Parent
	if not (holder and holder:IsA("BasePart")) then
		return
	end
	-- Свет питомцев, монет и эффектов не трогаем: только неподвижные детали мира.
	if not holder.Anchored or string.find(holder.Name, "^Coin_") or holder:FindFirstAncestor("Pets") then
		return
	end
	table.insert(lights, { light = l, part = holder, base = l.Brightness, range = l.Range, style = styleFor(l), phase = math.random() * 10, blinkUntil = 0 })
end

task.defer(function()
	task.wait(3)
	scanTrees(world)
	-- островки Sky Isles анимирует SkyIslesFX (два скрипта давали дрожание)
	for _, d in ipairs(world:GetDescendants()) do
		addLight(d)
	end
	world.DescendantAdded:Connect(function(d)
		task.defer(addLight, d)
	end)
end)

------------------------------------------------------------------ цикл
local acc, t = 0, 0
local gust, gustUntil, nextGust = 0, 0, 6
local moveParts, moveCFs = {}, {}
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	t += dt
	if acc < STEP then
		return
	end
	acc = 0
	local camPos = camera.CFrame.Position
	-- Порыв ветра раз в 8–16 секунд: деревья 2 секунды качаются сильнее.
	if t > nextGust then
		gustUntil = t + 2.2
		nextGust = t + 8 + math.random() * 8
	end
	local target = t < gustUntil and 1 or 0
	gust += (target - gust) * 0.08

	table.clear(moveParts)
	table.clear(moveCFs)
	for _, tr in ipairs(trees) do
		if (tr.pivot - camPos).Magnitude < NEAR then
			local sway = math.sin(t * 1.3 + tr.phase) * tr.amp * (1 + gust * 2.2) + math.sin(t * 2.9 + tr.phase * 2) * tr.amp * 0.3
			local twist = math.sin(t * 0.9 + tr.phase) * tr.amp * 0.6
			local rot = CFrame.new(tr.pivot) * CFrame.Angles(sway, 0, twist) * CFrame.new(-tr.pivot)
			for i, p in ipairs(tr.parts) do
				table.insert(moveParts, p)
				table.insert(moveCFs, rot * tr.bases[i])
			end
		end
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveCFs, Enum.BulkMoveMode.FireCFrameChanged)
	end

	for _, it in ipairs(islets) do
		if it.model.Parent and (it.base.Position - camPos).Magnitude < NEAR * 2 then
			it.model:PivotTo(it.base * CFrame.new(0, math.sin(t * 0.6 + it.phase) * it.amp, 0) * CFrame.Angles(0, math.sin(t * 0.25 + it.phase) * it.spin, math.sin(t * 0.4 + it.phase) * 0.015))
		end
	end

	for _, l in ipairs(lights) do
		local light = l.light
		-- мерцаем только светом рядом (60 студов): изменение света заставляет пересчитывать освещение
		if light.Parent and light.Enabled and (l.part.Position - camPos).Magnitude < 60 then
			local k
			if l.style == "Meadow" then
				-- тёплое пламя свечи: мелкое неровное мерцание
				k = 0.85 + 0.1 * math.sin(t * 7 + l.phase) + 0.06 * math.sin(t * 13.7 + l.phase * 3)
			elseif l.style == "Neon" then
				-- неон пульсирует и иногда коротко «моргает», как вывеска
				if t > l.blinkUntil and math.random() < 0.002 then
					l.blinkUntil = t + 0.25
				end
				k = (t < l.blinkUntil and (math.floor(t * 20) % 2 == 0) and 0.15) or (0.8 + 0.25 * math.sin(t * 2.4 + l.phase))
			elseif l.style == "Sky" then
				-- мягкое золотое «дыхание»
				k = 0.8 + 0.25 * math.sin(t * 1.1 + l.phase)
			else
				-- холодный ровный свет с медленным переливом
				k = 0.85 + 0.15 * math.sin(t * 0.7 + l.phase)
			end
			light.Brightness = l.base * k
		end
	end
end)
