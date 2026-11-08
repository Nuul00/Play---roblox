-- Бонусы косметических и удобных геймпассов:
--  • VIP — золотая табличка [VIP] над головой и золотые искры вокруг;
--  • Royal Aura — корона над головой и вращающиеся золотые искры (только внешний вид);
--  • Quick Travel — телепорт к любому яйцу / магазину / машине в текущем мире (RemoteFunction).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local StoreConfig = require(ReplicatedStorage:WaitForChild("StoreConfig"))
local Worlds = require(ReplicatedStorage:WaitForChild("WorldsConfig"))
local world = workspace:WaitForChild("CoinSpeedWorld")
local Titles = require(ReplicatedStorage:WaitForChild("TitlesConfig"))

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

-- ===== Внешний вид =====
local function clear(char: Model)
	for _, d in ipairs(char:GetDescendants()) do
		if d:GetAttribute("PassPerk") then
			d:Destroy()
		end
	end
end
local function sparks(root: BasePart, color: Color3, rate: number, name: string)
	local a = Instance.new("Attachment")
	a.Name = name
	a:SetAttribute("PassPerk", true)
	a.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(1, 2.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
	e.Shape = Enum.ParticleEmitterShape.Cylinder
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.Parent = a
end
local function tag(head: BasePart, text: string, color: Color3, offset: number, size: number)
	local g = Instance.new("BillboardGui")
	g.Name = "PerkTag"
	g:SetAttribute("PassPerk", true)
	g.Size = UDim2.fromOffset(size * 3, size)
	g.AlwaysOnTop = false
	g.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	g.MaxDistance = 90
	g.LightInfluence = 0
	g.Adornee = head
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.TextStrokeColor3 = Color3.fromRGB(80, 50, 0)
	l.Parent = g
	g.Parent = head
end
-- табличка титула: глянцевая плашка с градиентом цвета титула, эмодзи и надписью
local INK = Color3.fromRGB(30, 16, 60)
-- Размер в стадах (раньше в пикселях: издалека табличка была огромной). Корона Royal — часть таблички,
-- ровно по центру над ней (раньше отдельный билборд «отрывался» от таблички).
local function titlePlate(head: BasePart, t, offset: number, crown: boolean?)
	local g = Instance.new("BillboardGui")
	g.Name = "TitlePlate"
	g:SetAttribute("PassPerk", true)
	local w = math.clamp(#t.Text * 0.42 + 2.2, 3, 7.5)
	local ph, ch = 1.05, crown and 0.85 or 0
	g.Size = UDim2.fromScale(w, ph + ch)
	g.StudsOffsetWorldSpace = Vector3.new(0, offset + ch / 2, 0)
	g.MaxDistance = 70
	g.LightInfluence = 0
	g.Adornee = head
	if crown then
		local c = Instance.new("TextLabel")
		c.Name = "Crown"
		c.BackgroundTransparency = 1
		c.AnchorPoint = Vector2.new(0.5, 0)
		c.Position = UDim2.fromScale(0.5, 0)
		c.Size = UDim2.fromScale(1, ch / (ph + ch))
		c.Font = Enum.Font.FredokaOne
		c.TextScaled = true
		c.TextXAlignment = Enum.TextXAlignment.Center
		c.Text = "👑"
		c.Parent = g
	end
	local pill = Instance.new("Frame")
	pill.AnchorPoint = Vector2.new(0, 1)
	pill.Position = UDim2.fromScale(0, 1)
	pill.Size = UDim2.fromScale(1, ph / (ph + ch))
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.Parent = g
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(t.A, t.B)
	grad.Parent = pill
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = INK
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = pill
	local gloss = Instance.new("Frame")
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.7
	gloss.Position = UDim2.fromScale(0.08, 0.08)
	gloss.Size = UDim2.fromScale(0.84, 0.36)
	gloss.Parent = pill
	Instance.new("UICorner", gloss).CornerRadius = UDim.new(1, 0)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromScale(0.07, 0.1)
	l.Size = UDim2.fromScale(0.86, 0.8)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = t.Icon .. " " .. t.Text
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Parent = pill
	local ts = Instance.new("UIStroke")
	ts.Thickness = 2
	ts.Color = INK
	ts.Parent = l
	g.Parent = head
end
local function dress(p: Player)
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local head = char and char:FindFirstChild("Head")
	if not (root and head) then
		return
	end
	clear(char)
	local vip, royal = p:GetAttribute("Pass_VIP") == true, p:GetAttribute("Pass_RoyalAura") == true
	local shown = Titles.Shown(p)
	if shown then
		titlePlate(head, shown, 1.9, royal)
	end
	if vip then
		sparks(root, Color3.fromRGB(255, 210, 90), 10, "VipSparks")
	end
	if royal then
		if not shown then
			tag(head, "👑", Color3.fromRGB(255, 225, 120), 1.8, 36)
		end
		sparks(root, Color3.fromRGB(255, 240, 150), 26, "RoyalSparks")
	end
end
local function onPlayer(p: Player)
	p.CharacterAdded:Connect(function(char)
		char:WaitForChild("Head", 10)
		char:WaitForChild("HumanoidRootPart", 10)
		dress(p)
		-- внешность аватара догружается позже и может заменить голову вместе с табличкой — одеваем ещё раз
		task.delay(2, function()
			if p.Character == char then
				dress(p)
			end
		end)
	end)
	p.AttributeChanged:Connect(function(n)
		if n == "Pass_VIP" or n == "Pass_RoyalAura" or n == Titles.Attr then
			dress(p)
		end
	end)
	if p.Character then
		task.spawn(dress, p)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end

-- ===== Quick Travel =====
local MODEL = { ["Meadow Isles"] = "", ["Neon District"] = "NeonCity", ["Sky Isles"] = "SkyIsles", ["Frozen Peaks"] = "FrozenPeaks", ["Magma Volcano"] = "MagmaVolcano", ["Cosmic Galaxy"] = "CosmicGalaxy" }
local SHORT = { ["Meadow Isles"] = "island", ["Neon District"] = "neon", ["Sky Isles"] = "sky", ["Frozen Peaks"] = "frozen", ["Magma Volcano"] = "volcano", ["Cosmic Galaxy"] = "galaxy" }

local function posOf(x: Instance?): Vector3?
	if not x then
		return nil
	end
	if x:IsA("BasePart") then
		return x.Position
	elseif x:IsA("Model") then
		return x:GetPivot().Position
	end
	return nil
end
-- Список мест текущего мира: { Name, Pos }
local function destinations(worldName: string)
	local root = MODEL[worldName] == "" and world or world:FindFirstChild(MODEL[worldName] or "")
	if not root then
		return {}
	end
	local list = {}
	for id, egg in ipairs(Config.Eggs) do
		if egg.World == SHORT[worldName] then
			local stand = world:FindFirstChild("EggStand" .. id, true)
			local pos = posOf(stand and (stand:FindFirstChild("Interact") or stand))
			if pos then
				table.insert(list, { Name = "🥚 " .. egg.Name, Pos = pos })
			end
		end
	end
	for _, s in ipairs({ { "UpgradeShop", "⚡ Upgrades" }, { "MagnetShop", "🧲 Magnets" } }) do
		local shop = root:FindFirstChild(s[1])
		local pos = posOf(shop and (shop:FindFirstChild("ShopZone") or shop))
		if pos then
			table.insert(list, { Name = s[2], Pos = pos })
		end
	end
	local machines = workspace:FindFirstChild("PetMachines")
	for _, m in ipairs(machines and machines:GetChildren() or {}) do
		local pos = posOf(m)
		if pos and #list > 0 and (pos - list[1].Pos).Magnitude < 500 then
			table.insert(list, { Name = "✨ " .. (m:GetAttribute("Tier") == 1 and "Golden" or m:GetAttribute("Tier") == 2 and "Diamond" or "Rainbow") .. " machine", Pos = pos })
		end
	end
	return list
end

local remote = Instance.new("RemoteFunction")
remote.Name = "QuickTravel"
remote.Parent = ReplicatedStorage
local last = {}
Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
end)
remote.OnServerInvoke = function(p, index)
	local worldName = p:GetAttribute("CurrentWorld") or "Meadow Isles"
	local list = destinations(worldName)
	if index == nil then
		local names = {}
		for i, d in ipairs(list) do
			names[i] = d.Name
		end
		return { Ok = true, List = names, Has = p:GetAttribute("Pass_QuickTravel") == true, PassId = StoreConfig.PassByKey("QuickTravel").Id }
	end
	if type(index) ~= "number" or not list[index] then
		return { Ok = false }
	end
	if p:GetAttribute("Pass_QuickTravel") ~= true then
		return { Ok = false, Message = "Quick Travel is a gamepass" }
	end
	local def = Worlds.Find(worldName)
	if def and (def.Cost or 0) > 0 and not p:GetAttribute(Worlds.UnlockKey(worldName)) then
		return { Ok = false }
	end
	local now = os.clock()
	if last[p] and now - last[p] < 2 then
		return { Ok = false, Message = "Wait a moment" }
	end
	last[p] = now
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return { Ok = false }
	end
	p:SetAttribute("ServerTP", os.clock()) -- не считается читом (GameServer)
	char:PivotTo(CFrame.new(list[index].Pos + Vector3.new(0, 4, 6)))
	hrp.AssemblyLinearVelocity = Vector3.zero
	return { Ok = true }
end

-- ===== Новые титулы: сообщаем, когда открылся (раз в 3 с проверяем, что изменилось) =====
local known = {}
task.spawn(function()
	local feedback = ReplicatedStorage:WaitForChild("GameFeedback")
	while true do
		task.wait(3)
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("ProfileReady") then
				local k = known[p]
				local first = k == nil
				k = k or {}
				for _, t in ipairs(Titles.List) do
					if not k[t.Id] and t.Has(p) then
						k[t.Id] = true
						if not first then
							feedback:FireClient(p, "👑 New title: " .. t.Text .. "! Equip it in Inventory → TITLES", true)
						end
					end
				end
				known[p] = k
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p)
	known[p] = nil
end)
