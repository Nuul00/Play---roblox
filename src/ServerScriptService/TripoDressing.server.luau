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
		pcall(dressEgg, stand, id)
	end
end

local sky = world:WaitForChild("SkyIsles", 30)
local frozen = world:WaitForChild("FrozenPeaks", 30)
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
	put("PenguinStatue", 12, Vector3.new(-26, 0, 60), math.rad(200))
	put("FrozenSled", 10, Vector3.new(26, 0, 62), math.rad(160))
	put("FrozenMachine", 14, Vector3.new(-60, 0, -10), math.rad(90))
	for k = 0, 5 do
		put("FrozenLamp", 11, Vector3.new(k % 2 == 0 and -12 or 12, 0, 30 + math.floor(k / 2) * 34), 0)
	end
end
print("[TripoDressing] eggs, shops and Frozen decor dressed")
