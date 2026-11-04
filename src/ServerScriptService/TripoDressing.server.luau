-- Модели из Tripo (ReplicatedStorage.TripoEggs / TripoProps, вставлены через Tripo Bridge) заменяют
-- процедурные яйца на подставках, магазины и декор Frozen Peaks. Логика (зоны, подсказки, табло)
-- остаётся на старых деталях: их только прячем. Если папки с моделью нет — всё остаётся как было.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eggs = ReplicatedStorage:WaitForChild("TripoEggs", 20)
local props = ReplicatedStorage:WaitForChild("TripoProps", 20)
local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity")

local KEEP = { ShopZone = true, VendorAnchor = true, VendorSeatPoint = true, Interact = true, Counter = true }

-- Копия модели, вписанная в размер size (по самой длинной стороне), стоит низом на bottom.
local function fit(template: Model, size: number, bottom: CFrame, parent: Instance, name: string?)
	local m = template:Clone()
	m.Name = name or template.Name
	local _, ext = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * size / math.max(ext.X, ext.Y, ext.Z, 0.01))
	local cf, ext2 = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(cf)
	m:PivotTo(bottom * CFrame.new(0, ext2.Y / 2, 0) * offset:Inverse())
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end
	m.Parent = parent
	return m
end

local function hide(model: Instance, except: { [string]: boolean }?)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not (except and except[d.Name]) then
			d.Transparency = 1
			d.CanCollide = false
			d.CastShadow = false
		elseif d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceGui") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Light") then
			if not (except and d.Parent and except[d.Parent.Name]) then
				(d :: any).Enabled = false
				if d:IsA("Decal") or d:IsA("Texture") then
					d.Transparency = 1
				end
			end
		end
	end
end

-- Габариты видимых деталей модели (без зон и якорей).
local function visualBox(model: Instance)
	local minV, maxV
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not KEEP[d.Name] and d.Transparency < 1 then
			local cf, s = d.CFrame, d.Size / 2
			for _, c in ipairs({ Vector3.new(s.X, s.Y, s.Z), Vector3.new(-s.X, -s.Y, -s.Z), Vector3.new(s.X, -s.Y, s.Z), Vector3.new(-s.X, s.Y, -s.Z) }) do
				local w = cf:PointToWorldSpace(c)
				minV = minV and minV:Min(w) or w
				maxV = maxV and maxV:Max(w) or w
			end
		end
	end
	return minV, maxV
end

------------------------------------------------------------------ яйца на подставках
local function dressEgg(stand: Instance, id: number)
	local template = eggs and eggs:FindFirstChild("Egg" .. id)
	local display = stand:FindFirstChild("EggDisplay")
	if not (template and display and display:IsA("Model")) or display:GetAttribute("Tripo") then
		return
	end
	local cf, ext = display:GetBoundingBox()
	local bottom = CFrame.new(cf.Position - Vector3.new(0, ext.Y / 2, 0)) * (cf - cf.Position)
	-- Табло и анимации ищут модель по имени EggDisplay, поэтому старую переименовываем и прячем.
	display.Name = "EggDisplayOld"
	hide(display)
	local egg = fit(template, math.max(ext.Y, 4) * 1.05, bottom, stand, "EggDisplay")
	egg:SetAttribute("Tripo", true)
end

------------------------------------------------------------------ подставки под яйцами в цвет мира
-- Старый Pedestal остаётся невидимым (по нему всё так же ходят), сверху — модель Tripo,
-- вписанная по ширине и не выше 4–5 студов. Яйцо ставим на её верх.
local PEDESTAL = { "PedestalMeadow", "PedestalMeadow", "PedestalMeadow", "PedestalNeon", "PedestalNeon", "PedestalNeon", "PedestalSky", "PedestalSky", "PedestalSky" }
local function dressPedestal(stand: Instance, id: number)
	local template = props and props:FindFirstChild(PEDESTAL[id] or "")
	local ped = stand:FindFirstChild("Pedestal")
	if not (template and ped) or stand:GetAttribute("TripoPedestal") then
		return
	end
	local minV, maxV = visualBox(ped)
	if not minV then
		return
	end
	stand:SetAttribute("TripoPedestal", true)
	local width = math.max(maxV.X - minV.X, maxV.Z - minV.Z)
	for _, d in ipairs(ped:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 1
			d.CastShadow = false
		elseif d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Beam") then
			(d :: any).Enabled = false
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		end
	end
	local m = template:Clone()
	m.Name = "TripoPedestal"
	local _, ext = m:GetBoundingBox()
	-- По ширине старого подиума; высокую модель приплющиваем (не больше чем вдвое), а если
	-- и этого мало — уменьшаем.
	local maxH = id >= 7 and 5 or 4
	local k = width / math.max(ext.X, ext.Z, 0.01)
	local squash = 1
	-- слишком плоскую подставку (как монетка) делаем чуть выше, даже если она станет шире
	if ext.Y * k < 1.8 then
		k = math.min(1.8 / ext.Y, k * 1.35)
	end
	if ext.Y * k > maxH then
		squash = maxH / (ext.Y * k)
		if squash < 0.5 then
			squash = 0.5
			k = maxH / 0.5 / ext.Y
		end
	end
	m:ScaleTo(m:GetScale() * k)
	if squash < 1 then
		local bcf, bext = m:GetBoundingBox()
		local floorY = bcf.Position.Y - bext.Y / 2
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				local up = p.CFrame:VectorToObjectSpace(Vector3.yAxis)
				local ax, ay, az = math.abs(up.X), math.abs(up.Y), math.abs(up.Z)
				local sz = p.Size
				if ax >= ay and ax >= az then
					sz = Vector3.new(sz.X * squash, sz.Y, sz.Z)
				elseif ay >= az then
					sz = Vector3.new(sz.X, sz.Y * squash, sz.Z)
				else
					sz = Vector3.new(sz.X, sz.Y, sz.Z * squash)
				end
				local pos = p.Position
				p.Size = sz
				p.CFrame = (p.CFrame - pos) + Vector3.new(pos.X, floorY + (pos.Y - floorY) * squash, pos.Z)
			end
		end
	end
	local cf, ext2 = m:GetBoundingBox()
	local offset = m:GetPivot():ToObjectSpace(cf)
	local center = (minV + maxV) / 2
	m:PivotTo(CFrame.new(center.X, minV.Y + ext2.Y / 2, center.Z) * offset:Inverse())
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		end
	end
	m.Parent = stand
	-- яйцо — на верх новой подставки
	local egg = stand:FindFirstChild("EggDisplay")
	if egg and egg:IsA("Model") then
		local ecf, eext = egg:GetBoundingBox()
		local top = minV.Y + ext2.Y - 0.15
		local dy = top - (ecf.Position.Y - eext.Y / 2)
		egg:PivotTo(egg:GetPivot() + Vector3.new(0, dy, 0))
	end
end


------------------------------------------------------------------ машины улучшения питомцев
-- Golden / Diamond / Rainbow: модели Tripo вместо машин из деталей. Body (с ProximityPrompt)
-- и табличка Sign остаются, остальное прячем. Модель смотрит туда же, куда панель машины.
local MACHINE = { "GoldenMachine", "DiamondMachine", "RainbowMachine" }
local function dressMachine(tier: number)
	local folder = workspace:WaitForChild("PetMachines", 30)
	local model = folder and folder:WaitForChild("PetMachine" .. tier, 30)
	local template = props and props:FindFirstChild(MACHINE[tier])
	if not (model and template) or model:GetAttribute("Tripo") then
		return
	end
	local body, panel = model:FindFirstChild("Body"), model:FindFirstChild("Panel")
	local minV, maxV = visualBox(model)
	if not (body and minV) then
		return
	end
	model:SetAttribute("Tripo", true)
	local look = panel and (panel.Position - body.Position) or body.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	local center = Vector3.new(body.Position.X, minV.Y, body.Position.Z)
	local height = math.min(maxV.Y - minV.Y, 13.5) -- без таблички над машиной
	hide(model, { Body = true, Sign = true })
	body.Transparency = 1
	local tm = fit(template, height * 1.05, CFrame.lookAt(center, center + look.Unit), model, "TripoModel")
	-- табличку — над верхом новой модели
	local sign = model:FindFirstChild("Sign")
	if sign and sign:IsA("BasePart") then
		local cf, ext = tm:GetBoundingBox()
		local top = cf.Position.Y + ext.Y / 2
		sign.CFrame = sign.CFrame + Vector3.new(0, top + sign.Size.Y / 2 + 0.6 - sign.Position.Y, 0)
	end
end

------------------------------------------------------------------ магазины
local function dressShop(shop: Instance?, propName: string)
	local template = props and props:FindFirstChild(propName)
	if not (shop and template) or shop:GetAttribute("Tripo") then
		return
	end
	local minV, maxV = visualBox(shop)
	if not minV then
		return
	end
	shop:SetAttribute("Tripo", true)
	shop:SetAttribute("NoVendor", true) -- продавец-аватар внутри новой модели только мешает
	local size = maxV - minV
	local center = (minV + maxV) / 2
	-- Лицом туда же, куда смотрел прилавок: берём поворот зоны или самой модели.
	local zone = shop:FindFirstChild("ShopZone")
	local facing = shop:IsA("Model") and shop:GetPivot() or CFrame.new()
	local look = zone and (zone.Position - center) or facing.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, 1)
	end
	local bottom = CFrame.lookAt(Vector3.new(center.X, minV.Y, center.Z), Vector3.new(center.X, minV.Y, center.Z) + look.Unit)
	hide(shop, KEEP)
	for _, k in ipairs({ "Counter" }) do
		local p = shop:FindFirstChild(k, true)
		if p and p:IsA("BasePart") then
			p.Transparency = 1
		end
	end
	local npc = shop:FindFirstChild("Shopkeeper")
	if npc then
		npc:Destroy()
	end
	fit(template, math.max(size.X, size.Y, size.Z) * 0.95, bottom, shop, "TripoModel")
end

------------------------------------------------------------------ декор Frozen Peaks
local function swapAll(root: Instance, oldName: string, propName: string, scale: number)
	local template = props and props:FindFirstChild(propName)
	if not template then
		return
	end
	for _, m in ipairs(root:GetDescendants()) do
		if m:IsA("Model") and m.Name == oldName and not m:GetAttribute("Tripo") then
			local cf, ext = m:GetBoundingBox()
			local bottom = CFrame.new(cf.Position - Vector3.new(0, ext.Y / 2, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
			m:SetAttribute("Tripo", true)
			hide(m)
			fit(template, math.max(ext.X, ext.Y, ext.Z) * scale, bottom, m, "TripoModel")
		end
	end
end

task.wait(2)
for id = 1, 9 do
	local holder = (id <= 3 and world) or (id <= 6 and city) or world:WaitForChild("SkyIsles", 30)
	local stand = holder and holder:FindFirstChild("EggStand" .. id, true)
	if stand then
		local ok, err = pcall(dressEgg, stand, id)
		if not ok then
			warn("[TripoDressing] egg", id, err)
		end
		local ok2, err2 = pcall(dressPedestal, stand, id)
		if not ok2 then
			warn("[TripoDressing] pedestal", id, err2)
		end
	else
		print("[TripoDressing] egg", id, "stand not found")
	end
end

local sky = world:WaitForChild("SkyIsles", 30)
local frozen = world:WaitForChild("FrozenPeaks", 30)
for tier = 1, 3 do
	task.spawn(function()
		local ok, err = pcall(dressMachine, tier)
		if not ok then
			warn("[TripoDressing] machine", tier, err)
		end
	end)
end
pcall(dressShop, world:FindFirstChild("UpgradeShop"), "MeadowUpgradeShop")
pcall(dressShop, world:FindFirstChild("MagnetShop"), "MeadowMagnetShop")
pcall(dressShop, city:FindFirstChild("UpgradeShop"), "NeonUpgradeShop")
pcall(dressShop, sky and sky:FindFirstChild("UpgradeShop"), "SkyUpgradeShop")
pcall(dressShop, sky and sky:FindFirstChild("MagnetShop"), "SkyMagnetShop")
pcall(dressShop, frozen and frozen:FindFirstChild("UpgradeShop"), "FrozenShop")

if frozen then
	pcall(swapAll, frozen, "Snowman", "Snowman", 1.15)
	pcall(swapAll, frozen, "Igloo", "Igloo", 1.0)
	pcall(swapAll, frozen, "SnowPine", "SnowPine", 1.1)
	pcall(swapAll, frozen, "CrystalCluster", "IceCrystals", 1.1)
	-- Горы: блочные пирамиды меняем на 3D-горы Tripo (три вида по кругу, разный поворот).
	local peaks = frozen:FindFirstChild("Peaks")
	if peaks and props:FindFirstChild("FrozenMountain1") then
		for k, m in ipairs(peaks:GetChildren()) do
			local t = props:FindFirstChild("FrozenMountain" .. ((k - 1) % 3 + 1))
			if m:IsA("Model") and t then
				local cf, ext = m:GetBoundingBox()
				local bottom = CFrame.new(cf.Position - Vector3.new(0, ext.Y / 2, 0)) * CFrame.Angles(0, k * 1.3, 0)
				hide(m)
				fit(t, math.max(ext.X, ext.Y, ext.Z) * 1.15, bottom, m, "TripoModel")
			end
		end
	end
	-- Новый декор у центральной площади: статуя пингвина, санки с подарками и ледяные фонари.
	local C = Vector3.new(3000, 60, 0)
	local deco = Instance.new("Folder")
	deco.Name = "TripoDecor"
	deco.Parent = frozen
	local function put(name, size, at, yaw)
		local t = props and props:FindFirstChild(name)
		if t then
			fit(t, size, CFrame.new(C + at) * CFrame.Angles(0, yaw, 0), deco)
		end
	end
	-- Пингвин стоит на ледяной подставке.
	put("PedestalFrozen", 11, Vector3.new(-26, 0, 60), 0)
	local fped = deco:FindFirstChild("PedestalFrozen")
	local lift = 0
	if fped then
		local _, e = fped:GetBoundingBox()
		lift = e.Y - 0.2
	end
	put("PenguinStatue", 12, Vector3.new(-26, lift, 60), math.rad(200))
	put("FrozenSled", 10, Vector3.new(26, 0, 62), math.rad(160))
	put("FrozenMachine", 14, Vector3.new(-60, 0, -10), math.rad(90))
	for k = 0, 5 do
		put("FrozenLamp", 11, Vector3.new(k % 2 == 0 and -12 or 12, 0, 30 + math.floor(k / 2) * 34), 0)
	end
end
-- Сундуки на островках Sky Isles: модель Tripo по номеру сундука, ChestBase остаётся для логики.
if sky then
	for _, base in ipairs(game:GetService("CollectionService"):GetTagged("SkyChest")) do
		local id = base:GetAttribute("ChestId")
		local chest = base.Parent
		local template = props and props:FindFirstChild("SkyChest" .. tostring(id))
		if chest and template and not chest:GetAttribute("Tripo") then
			chest:SetAttribute("Tripo", true)
			local look = base.CFrame.LookVector
			local bottom = CFrame.lookAt(base.Position - Vector3.new(0, base.Size.Y / 2, 0), base.Position - Vector3.new(0, base.Size.Y / 2, 0) + Vector3.new(look.X, 0, look.Z))
			hide(chest, { ChestBase = true })
			base.Transparency = 1
			local m = fit(template, ({ 6, 7, 8.5 })[id] or 6, bottom, chest, "TripoModel")
			m:SetAttribute("ChestId", id)
		end
	end
end
print("[TripoDressing] eggs, shops and Frozen decor dressed")
