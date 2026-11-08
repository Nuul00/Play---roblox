-- Прячет на клиенте мир Sky Isles, пока игрок не в нём (фидбэк 2026-11: «мусор в небе» над Meadow —
-- это острова Sky Isles в ~700 студах, StreamingEnabled выключен). Детали получают
-- LocalTransparencyModifier = 1, частицы/свет/билборды выключаются; при входе в Sky всё возвращается.
-- Серверу и другим скриптам мир виден как раньше (ничего не переносим и не удаляем).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

-- 2026-11: прячем все миры, кроме текущего (из Sky Isles внизу были видны «точки» — Meadow и другие миры).
-- Meadow — это прямые дети CoinSpeedWorld, кроме папок других миров (см. MEADOW_SKIP).
local HIDE_WHEN_NOT_IN = {
	SkyIsles = "Sky Isles",
	NeonCity = "Neon District",
	FrozenPeaks = "Frozen Peaks",
	MagmaVolcano = "Magma Volcano",
	CosmicGalaxy = "Cosmic Galaxy",
}
local MEADOW_SKIP = { LocalEventPickups = true }

local saved = {} -- [instance] = прежнее Enabled (для эффектов)
local hiddenRoots = {} -- [root] = DescendantAdded-соединение

local function hideOne(d: Instance)
	if d:IsA("BasePart") then
		d.LocalTransparencyModifier = 1
	elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Light") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
		if saved[d] == nil then
			saved[d] = (d :: any).Enabled
		end
		(d :: any).Enabled = false
	end
end

local function hide(root: Instance)
	if hiddenRoots[root] then
		return
	end
	hiddenRoots[root] = root.DescendantAdded:Connect(hideOne)
	hideOne(root)
	for i, d in ipairs(root:GetDescendants()) do
		hideOne(d)
		if i % 2000 == 0 then
			task.wait()
		end
	end
end

local function show(root: Instance)
	local conn = hiddenRoots[root]
	if not conn then
		return
	end
	conn:Disconnect()
	hiddenRoots[root] = nil
	local all = root:GetDescendants()
	table.insert(all, root)
	for _, d in ipairs(all) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 0
		elseif saved[d] ~= nil then
			(d :: any).Enabled = saved[d]
			saved[d] = nil
		end
	end
end

-- Объекты мира, которые лежат не внутри его папки: круги яиц (EggZoneRing) и метки магазинов
-- (ShopZoneMarker) рисует клиент прямо в Workspace, машины — в Workspace.PetMachines, бонусы
-- событий — в LocalEventPickups. Прячем те из них, что стоят в границах мира.
local boxes = {} -- [worldName] = { min, max }
local function boxOf(name: string, root: Instance)
	if not boxes[name] and root:IsA("Model") then
		local cf, size = root:GetBoundingBox()
		boxes[name] = { cf.Position - size / 2 - Vector3.new(20, 20, 20), cf.Position + size / 2 + Vector3.new(20, 60, 20) }
	end
	return boxes[name]
end
local function inside(pos: Vector3, b): boolean
	return pos.X >= b[1].X and pos.X <= b[2].X and pos.Y >= b[1].Y and pos.Y <= b[2].Y and pos.Z >= b[1].Z and pos.Z <= b[2].Z
end
local function strays(): { Instance }
	local list = {}
	for _, c in ipairs(workspace:GetChildren()) do
		if c.Name == "EggZoneRing" or c.Name == "ShopZoneMarker" then
			table.insert(list, c)
		end
	end
	for _, holder in ipairs({ workspace:FindFirstChild("PetMachines"), world:FindFirstChild("LocalEventPickups"), workspace:FindFirstChild("IslandLifeFX") }) do
		if holder then
			for _, c in ipairs(holder:GetChildren()) do
				table.insert(list, c)
			end
		end
	end
	return list
end
local function update()
	local current = player:GetAttribute("CurrentWorld") or "Meadow Isles"
	-- в Coin Rush миры не трогаем (арена живёт отдельно, её прячет/показывает CoinRush)
	if player:GetAttribute("InRush") then
		current = "Meadow Isles"
	end
	-- Meadow: дети CoinSpeedWorld, не являющиеся другими мирами
	local meadowAway = current ~= "Meadow Isles"
	for _, c in ipairs(world:GetChildren()) do
		if not HIDE_WHEN_NOT_IN[c.Name] and not MEADOW_SKIP[c.Name] and not string.find(c.Name, "CoinRush", 1, true) then
			if meadowAway then
				hide(c)
			else
				show(c)
			end
		end
	end
	for name, worldName in pairs(HIDE_WHEN_NOT_IN) do
		local root = world:FindFirstChild(name)
		if root then
			local away = current ~= worldName
			if away then
				hide(root)
			else
				show(root)
			end
			local b = boxOf(name, root)
			if b then
				-- по каждой детали: одна модель-метка может держать детали сразу в нескольких мирах
				for _, o in ipairs(strays()) do
					local all = o:GetDescendants()
					table.insert(all, o)
					for _, d in ipairs(all) do
						if d:IsA("BasePart") and inside(d.Position, b) then
							if away then
								d.LocalTransparencyModifier = 1
							elseif d.LocalTransparencyModifier == 1 then
								d.LocalTransparencyModifier = 0
							end
							for _, fx in ipairs(d:GetChildren()) do
								if fx:IsA("ParticleEmitter") or fx:IsA("Beam") or fx:IsA("Light") or fx:IsA("BillboardGui") or fx:IsA("SurfaceGui") then
									if away then
										hideOne(fx)
									elseif saved[fx] ~= nil then
										(fx :: any).Enabled = saved[fx]
										saved[fx] = nil
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
-- круги и бонусы появляются со временем — досматриваем раз в 2 секунды
task.spawn(function()
	while true do
		task.wait(2)
		pcall(update)
	end
end)

player:GetAttributeChangedSignal("CurrentWorld"):Connect(update)
world.ChildAdded:Connect(function(c)
	if HIDE_WHEN_NOT_IN[c.Name] then
		update()
	end
end)
update()

-- Метки и эффекты, которые лежат прямо в Workspace (круги яиц, метки магазинов, эффекты яиц, машины,
-- демо-питомцы): дальше 450 студов от игрока — прячем, ближе — показываем (фидбэк 2026-11: «точки» в
-- пустоте под Sky Isles — это метки Meadow\Neon далеко внизу).
local STRAY_NAMES = { EggZoneRing = true, ShopZoneMarker = true, EggFX = true, PetMachines = true }
local FAR = 450
task.spawn(function()
	while true do
		task.wait(1.5)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local here = root.Position
			for _, c in ipairs(workspace:GetChildren()) do
				if STRAY_NAMES[c.Name] or string.match(c.Name, "^SkyPet%d+$") then
					for _, d in ipairs(c:GetDescendants()) do
						if d:IsA("BasePart") then
							local far = (d.Position - here).Magnitude > FAR
							if far then
								d.LocalTransparencyModifier = 1
							elseif d.LocalTransparencyModifier == 1 then
								d.LocalTransparencyModifier = 0
							end
						elseif d:IsA("ParticleEmitter") or d:IsA("BillboardGui") or d:IsA("Light") then
							local p = d.Parent
							if p and p:IsA("BasePart") then
								local far = (p.Position - here).Magnitude > FAR
								if far then
									hideOne(d)
								elseif saved[d] ~= nil then
									(d :: any).Enabled = saved[d]
									saved[d] = nil
								end
							end
						end
					end
				end
			end
		end
	end
end)
