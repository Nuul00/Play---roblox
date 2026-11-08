-- «Живые» миры на клиенте: деревья качаются от ветра (с порывами), декоративные островки Sky Isles
-- парят, фонари во всех мирах светятся по-своему. Всё считается только рядом с камерой и не каждый кадр,
-- чтобы не вернуть лаги (см. оптимизацию SkyIslesFX).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local camera = workspace.CurrentCamera

local NEAR = 260 -- дальше этого не анимируем
-- Уровень графики (Settings → Graphics, FxBudget): LOW — деревья стоят, листья не падают, фонари не
-- мерцают; MEDIUM — деревья качаются, фонари мерцают, без листопада; ULTRA — всё (2026-11)
local FxBudget = require(game:GetService("ReplicatedStorage"):WaitForChild("FxBudget"))
local STEP = 1 / 30 -- 30 раз в секунду

------------------------------------------------------------------ деревья
-- Дерево: модель, в имени которой есть Tree/Pine/Palm. Качаем «листву» — детали, которые выше
-- середины дерева или названы Leaves/Leaf/Canopy/Crown; ствол стоит.
local trees = {}
-- Имя «дерева»: Tree/Pine/Palm, но не StreetLamp/NeonStreets — в «s-TREE-t» тоже есть «tree»,
-- из-за этого фонари качались как деревья (2026-11).
local function isTreeName(n: string): boolean
	if string.find(n, "street") or string.find(n, "lamp") or string.find(n, "light") then
		return false
	end
	return string.find(n, "tree") ~= nil or string.find(n, "pine") ~= nil or string.find(n, "palm") ~= nil
end
-- Листопад: только у зелёной листвы (сосны в снегу, кристаллы и т.п. — без листьев).
local LEAF_NEAR = 120 -- эмиттер работает только у деревьев рядом с камерой
local function isGreen(c: Color3): boolean
	return c.G > c.R * 1.05 and c.G > c.B * 1.05
end
local function addLeafFall(canopy: { BasePart }, pivot: Vector3, size: Vector3)
	local r, g, b, n = 0, 0, 0, 0
	for _, p in ipairs(canopy) do
		r, g, b, n = r + p.Color.R, g + p.Color.G, b + p.Color.B, n + 1
	end
	local avg = Color3.new(r / n, g / n, b / n)
	if not isGreen(avg) then
		return nil
	end
	local top = 0
	for _, p in ipairs(canopy) do
		top = math.max(top, p.Position.Y)
	end
	local src = Instance.new("Part")
	src.Name = "LeafFall"
	src.Anchored, src.CanCollide, src.CanQuery, src.CanTouch = true, false, false, false
	src.Transparency = 1
	src.Size = Vector3.new(math.max(size.X, 4) * 0.7, 0.2, math.max(size.Z, 4) * 0.7)
	src.CFrame = CFrame.new(pivot.X, top - 1, pivot.Z)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(avg:Lerp(Color3.fromRGB(255, 220, 90), 0.25), avg:Lerp(Color3.fromRGB(200, 120, 40), 0.35))
	e.LightInfluence = 1
	e.Rate = 1.6
	e.Lifetime = NumberRange.new(4, 6)
	e.Speed = NumberRange.new(0.5, 1.2)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Acceleration = Vector3.new(0.8, -1.1, 0.3)
	e.Drag = 0.6
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Size = NumberSequence.new(0.35)
	e.Squash = NumberSequence.new(-0.5) -- вытянутая «листовая» форма из круглой искры
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Enabled = false
	e.Parent = src
	src.Parent = workspace.CurrentCamera -- клиентский декор, на сервер не уходит
	return e
end
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
		-- 2026-11: раскачка примерно вдвое слабее (было 2.2/h, 0.012–0.05) — деревья «тряслись»
		amp = math.clamp(1.2 / size.Y, 0.006, 0.025),
		cfs = table.create(#parts),
		leaves = addLeafFall(parts, pivot, size),
	})
end
local function scanTrees(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Model") then
			local n = string.lower(d.Name)
			if isTreeName(n) and not d:FindFirstAncestorWhichIsA("Model", true) then
				addTree(d)
			elseif isTreeName(n) then
				local parentModel = d.Parent and d.Parent:IsA("Model") and string.lower(d.Parent.Name)
				if not (parentModel and isTreeName(parentModel)) then
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
	local lvl = FxBudget.Level()
	for _, tr in ipairs(trees) do
		local dist = (tr.pivot - camPos).Magnitude
		if tr.leaves then
			local on = dist < LEAF_NEAR and lvl >= 3
			if tr.leaves.Enabled ~= on then
				tr.leaves.Enabled = on
			end
		end
		if dist < NEAR and lvl >= 2 then
			local sway = math.sin(t * 1.3 + tr.phase) * tr.amp * (1 + gust * 1.2) + math.sin(t * 2.9 + tr.phase * 2) * tr.amp * 0.3
			local twist = math.sin(t * 0.9 + tr.phase) * tr.amp * 0.6
			local rot = CFrame.new(tr.pivot) * CFrame.Angles(sway, 0, twist) * CFrame.new(-tr.pivot)
			for i, p in ipairs(tr.parts) do
				table.insert(moveParts, p)
				table.insert(moveCFs, rot * tr.bases[i])
			end
			tr.still = false
		elseif lvl < 2 and not tr.still then
			-- графика LOW: дерево один раз возвращаем в ровное положение и больше не двигаем
			tr.still = true
			for i, p in ipairs(tr.parts) do
				table.insert(moveParts, p)
				table.insert(moveCFs, tr.bases[i])
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
		if lvl >= 2 and light.Parent and light.Enabled and (l.part.Position - camPos).Magnitude < 60 then
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
