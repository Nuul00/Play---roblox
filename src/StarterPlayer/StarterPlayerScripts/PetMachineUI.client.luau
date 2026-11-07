-- Окно машины улучшения: открывается подсказкой у машины (E / касание).
-- Показывает питомцев нужной ступени, сколько их есть из 5, и кнопку FUSE.
-- Решает всё сервер (GamePetFuse); здесь только отображение и эффекты.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PetVisuals = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local fuse = ReplicatedStorage:WaitForChild("GamePetFuse")

local INK = Color3.fromRGB(30, 18, 50)

local gui = Instance.new("ScreenGui")
gui.Name = "PetMachineUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.fromOffset(640, 440)
window.BackgroundColor3 = Color3.new(1, 1, 1)
window.Visible = false
window.Parent = gui
Instance.new("UICorner", window).CornerRadius = UDim.new(0, 26)
local windowGradient = Instance.new("UIGradient")
windowGradient.Rotation = 90
windowGradient.Parent = window
local windowRim = Instance.new("UIStroke")
windowRim.Thickness = 5
windowRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
windowRim.Parent = window
local windowScale = Instance.new("UIScale")
windowScale.Parent = window

local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3?, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextScaled = true
	l.Font = font or Enum.Font.FredokaOne
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = INK
	s.Parent = l
	return l
end

local title = label(window, "", UDim2.fromOffset(24, 14), UDim2.fromOffset(520, 46))
title.TextXAlignment = Enum.TextXAlignment.Left
local subtitle = label(window, "", UDim2.fromOffset(24, 60), UDim2.fromOffset(590, 24), Color3.fromRGB(255, 250, 235), Enum.Font.GothamBold)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -16, 0, 16)
close.Size = UDim2.fromOffset(44, 44)
close.Text = "X"
close.Font = Enum.Font.FredokaOne
close.TextSize = 26
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(235, 70, 90)
close.Parent = window
Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)
local cs = Instance.new("UIStroke")
cs.Thickness = 3
cs.Color = INK
cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cs.Parent = close

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(20, 96)
list.Size = UDim2.fromOffset(600, 326)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = window
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(186, 200)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list

local currentTier: number? = nil
local currentMachine: Model? = nil
local spinning = {}

local function count(id: number, tier: number): number
	return player:GetAttribute(ShopConfig.OwnedAttr(id, tier)) or 0
end
local function multOf(id: number, tier: number): number
	return Config.GetPetMultiplier(id) * ShopConfig.VariantMult(tier)
end

local function viewport(parent: Instance, code: number)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromOffset(8, 6)
	view.Size = UDim2.fromOffset(170, 96)
	view.Ambient = Color3.fromRGB(210, 210, 220)
	view.LightDirection = Vector3.new(-1, -1, -2)
	view.Parent = parent
	local wm = Instance.new("WorldModel")
	wm.Parent = view
	local model = PetVisuals.BuildCode(code)
	model.Parent = wm
	local _, ext = model:GetBoundingBox()
	local d = math.max(ext.X, ext.Y, ext.Z)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(d * 0.9, d * 0.5, -d * 1.6), Vector3.zero)
	cam.Parent = view
	view.CurrentCamera = cam
	table.insert(spinning, model)
end

local function render()
	for _, c in ipairs(list:GetChildren()) do
		if not c:IsA("UIGridLayout") then
			c:Destroy()
		end
	end
	table.clear(spinning)
	local tier = currentTier
	if not tier then
		return
	end
	local def = ShopConfig.Variants[tier]
	local fromTier = tier - 1
	local fromName = fromTier == 0 and "normal" or ShopConfig.Variants[fromTier].Name
	local ids = {}
	for id = 1, Config.MaxPetId do if not Config.Pets[id] then continue end
		if count(id, fromTier) > 0 and not Config.Pets[id].Super then -- супер-секретки не улучшаются
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local ra, rb = count(a, fromTier) >= def.Need, count(b, fromTier) >= def.Need
		if ra ~= rb then
			return ra
		end
		return multOf(a, fromTier) > multOf(b, fromTier)
	end)
	if #ids == 0 then
		local empty = label(list, "You have no " .. fromName .. " pets yet.\nGet " .. def.Need .. " of the same pet to make a " .. def.Name .. " one!", UDim2.fromOffset(0, 60), UDim2.fromOffset(600, 80), Color3.new(1, 1, 1), Enum.Font.GothamBold)
		empty.TextWrapped = true
		return
	end
	for order, id in ipairs(ids) do
		local pet = Config.Pets[id]
		local have = count(id, fromTier)
		local ready = have >= def.Need
		local card = Instance.new("Frame")
		card.LayoutOrder = order
		card.BackgroundColor3 = Color3.fromRGB(30, 22, 55)
		card.BackgroundTransparency = 0.2
		card.Parent = list
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
		local st = Instance.new("UIStroke")
		st.Thickness = 3
		st.Color = ready and def.Color or Color3.fromRGB(90, 80, 120)
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = card
		viewport(card, ShopConfig.PetCode(id, fromTier))
		local prefix = fromTier > 0 and (ShopConfig.Variants[fromTier].Name .. " ") or ""
		label(card, prefix .. pet.Name, UDim2.fromOffset(6, 100), UDim2.fromOffset(174, 22), Color3.new(1, 1, 1))
		label(card, string.format("x%g  >>  x%g", multOf(id, fromTier), multOf(id, tier)), UDim2.fromOffset(6, 122), UDim2.fromOffset(174, 18), def.Color:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Font.GothamBold)
		-- Полоска «сколько есть из нужных».
		local bar = Instance.new("Frame")
		bar.Position = UDim2.fromOffset(12, 144)
		bar.Size = UDim2.fromOffset(162, 14)
		bar.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
		bar.Parent = card
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(math.clamp(have / def.Need, 0.06, 1), 1)
		fill.BackgroundColor3 = def.Color
		fill.BorderSizePixel = 0
		fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
		local amount = label(bar, have .. " / " .. def.Need, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.new(1, 1, 1))
		amount.ZIndex = 2
		local button = Instance.new("TextButton")
		button.Position = UDim2.fromOffset(12, 164)
		button.Size = UDim2.fromOffset(162, 30)
		button.Text = ready and ("FUSE " .. def.Icon) or "NEED " .. (def.Need - have) .. " MORE"
		button.Font = Enum.Font.FredokaOne
		button.TextScaled = true
		button.TextColor3 = Color3.new(1, 1, 1)
		button.AutoButtonColor = ready
		button.BackgroundColor3 = ready and Color3.fromRGB(70, 190, 95) or Color3.fromRGB(85, 80, 105)
		button.Parent = card
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
		local bs = Instance.new("UIStroke")
		bs.Thickness = 2
		bs.Color = INK
		bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		bs.Parent = button
		local bp = Instance.new("UIPadding")
		bp.PaddingTop = UDim.new(0, 4)
		bp.PaddingBottom = UDim.new(0, 4)
		bp.Parent = button
		button.Activated:Connect(function()
			if ready then
				fuse:FireServer(tier, id)
			end
		end)
	end
end

local function closeWindow()
	if not window.Visible then
		return
	end
	window.Visible = false
	currentTier = nil
	currentMachine = nil
	if player:GetAttribute("UIScreen") == "machine" then
		player:SetAttribute("UIScreen", "")
	end
end
close.Activated:Connect(closeWindow)

local function open(tier: number, machine: Model)
	local def = ShopConfig.Variants[tier]
	if not def then
		return
	end
	currentTier = tier
	currentMachine = machine
	title.Text = def.Icon .. " " .. string.upper(def.Name) .. " MACHINE"
	local fromName = tier == 1 and "normal" or ShopConfig.Variants[tier - 1].Name
	subtitle.Text = string.format("%d same %s pets = 1 %s pet with x%g power", def.Need, fromName, def.Name, def.Mult)
	windowGradient.Color = ColorSequence.new(def.Color:Lerp(Color3.fromRGB(40, 20, 70), 0.35), Color3.fromRGB(28, 16, 54))
	windowRim.Color = def.Color
	player:SetAttribute("UIScreen", "machine")
	render()
	window.Visible = true
	windowScale.Scale = 0.6
	TweenService:Create(windowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name ~= "PetMachinePrompt" then
		return
	end
	local machine = prompt:FindFirstAncestorOfClass("Model")
	local tier = prompt:GetAttribute("Tier")
	if machine and type(tier) == "number" then
		open(tier, machine)
	end
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	if player:GetAttribute("UIScreen") ~= "machine" then
		closeWindow()
	end
end)
-- Без кнопки E: встал на место перед машиной (невидимая метка MachineMarker) — окно открылось,
-- отошёл — закрылось. Повторно открывается только после того, как игрок ушёл с метки.
task.spawn(function()
	local machinesFolder = workspace:WaitForChild("PetMachines", 60)
	if not machinesFolder then
		return
	end
	local onSpot = {}
	while true do
		task.wait(0.15)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			for _, m in ipairs(machinesFolder:GetChildren()) do
				local tier = m:GetAttribute("Tier")
				local marker = m:FindFirstChild("MachineMarker")
				local spot = marker and marker.Position or (m.PrimaryPart and m.PrimaryPart.Position)
				if spot and type(tier) == "number" then
					local o = root.Position - spot
					local flat = Vector2.new(o.X, o.Z).Magnitude
					if flat < 5.5 and math.abs(o.Y) < 7 then
						if not onSpot[m] then
							onSpot[m] = true
							local screen = player:GetAttribute("UIScreen")
							if screen == nil or screen == "" then
								open(tier, m)
							end
						end
					elseif flat > 7 then
						onSpot[m] = nil
						if currentMachine == m and window.Visible and flat > 16 then
							closeWindow()
						end
					end
				end
			end
		end
	end
end)
local pending = false
player.AttributeChanged:Connect(function(name)
	if window.Visible and not pending and string.sub(name, 1, 3) == "Pet" then
		pending = true
		task.defer(function()
			pending = false
			if window.Visible then
				render()
			end
		end)
	end
end)

-- ===== Показ превращения в 3D =====
-- Нужные питомцы вылетают от игрока и залетают в машину, кружатся внутри и сжимаются, машина
-- трясётся и светится цветом ступени; вспышка, ударная волна — и новый питомец поднимается
-- из машины, светясь, с подписью, и улетает к игроку.
local PetVisualsFS = require(ReplicatedStorage:WaitForChild("PetVisuals"))
local GameConfigFS = require(ReplicatedStorage:WaitForChild("GameConfig"))
local function fsPet(code: number, color: Color3?)
	local ok, m = pcall(PetVisualsFS.BuildCode, code)
	if not ok or not m then
		return nil
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	if color then
		local hl = Instance.new("Highlight")
		hl.FillColor = color
		hl.FillTransparency = 0.8
		hl.OutlineColor = Color3.new(1, 1, 1)
		hl.OutlineTransparency = 0.2
		hl.Parent = m
	end
	m.Parent = workspace
	return m
end
local function fuseShow(tier: number, id: number?)
	local machine = workspace:FindFirstChild("PetMachines") and workspace.PetMachines:FindFirstChild("PetMachine" .. tostring(tier))
	local body = machine and (machine:FindFirstChild("TripoModel") or machine)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (body and root and id) then
		return
	end
	local def = ShopConfig.Variants[tier]
	local color = def.Color
	local prevColor = tier > 1 and ShopConfig.Variants[tier - 1].Color or nil
	local cf, size = body:GetBoundingBox()
	local chamber = cf.Position + Vector3.new(0, size.Y * 0.12, 0)
	local need = def.Need or 5
	-- 1) питомцы летят в машину
	local pets = {}
	for i = 1, need do
		local m = fsPet(ShopConfig.PetCode(id, tier - 1), prevColor)
		if m then
			local a = i / need * math.pi * 2
			local start = root.Position + Vector3.new(math.cos(a) * 3, 3.5, math.sin(a) * 3)
			table.insert(pets, { m = m, start = start, a = a, scale = m:GetScale() })
		end
	end
	local glow = Instance.new("Part")
	glow.Anchored, glow.CanCollide, glow.CanQuery, glow.CanTouch, glow.CastShadow = true, false, false, false, false
	glow.Transparency = 1
	glow.Size = Vector3.new(1, 1, 1)
	glow.Position = chamber
	glow.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 24
	light.Brightness = 0
	light.Parent = glow
	local swirl = Instance.new("ParticleEmitter")
	swirl.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	swirl.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	swirl.LightEmission = 1
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	swirl.Lifetime = NumberRange.new(0.4, 0.8)
	swirl.Speed = NumberRange.new(-6, -3) -- к центру
	swirl.Shape = Enum.ParticleEmitterShape.Sphere
	swirl.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	swirl.Rate = 0
	swirl.Parent = glow
	local base = body:GetPivot()
	local t0 = os.clock()
	local FLY, SPIN = 0.9, 1.3
	while true do
		local t = os.clock() - t0
		if t > FLY + SPIN then
			break
		end
		for i, p in ipairs(pets) do
			if t < FLY then
				local k = t / FLY
				local arc = Vector3.new(0, math.sin(k * math.pi) * 6, 0)
				p.m:PivotTo(CFrame.new(p.start:Lerp(chamber, k * k) + arc) * CFrame.Angles(0, k * 8, 0))
			else
				local k = (t - FLY) / SPIN
				local r = 2.6 * (1 - k)
				local a = p.a + k * 18
				p.m:PivotTo(CFrame.new(chamber + Vector3.new(math.cos(a) * r, math.sin(k * 12 + i) * 0.5, math.sin(a) * r)) * CFrame.Angles(0, a, 0))
				p.m:ScaleTo(p.scale * math.max(0.05, 0.7 * (1 - k)))
			end
		end
		if t > FLY then
			local k = (t - FLY) / SPIN
			swirl.Rate = 80
			light.Brightness = 1 + k * 6
			-- машина дрожит (только у этого игрока)
			body:PivotTo(base * CFrame.new(math.sin(t * 60) * 0.12 * k, 0, math.cos(t * 53) * 0.12 * k))
		end
		task.wait()
	end
	body:PivotTo(base)
	for _, p in ipairs(pets) do
		p.m:Destroy()
	end
	swirl.Rate = 0
	-- 2) вспышка и ударная волна
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = color
	flash.Anchored, flash.CanCollide, flash.CanQuery, flash.CanTouch, flash.CastShadow = true, false, false, false, false
	flash.Size = Vector3.new(2, 2, 2)
	flash.Position = chamber
	flash.Parent = workspace
	TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(16, 16, 16), Transparency = 1 }):Play()
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(cf.Position.X, cf.Position.Y - size.Y / 2 + 0.3, cf.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.2, 30, 30), Transparency = 1 }):Play()
	TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 0 }):Play()
	-- 3) новый питомец поднимается и улетает к игроку
	local result = fsPet(ShopConfig.PetCode(id, tier), color)
	if result then
		local sc = result:GetScale()
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(260, 50)
		gui.StudsOffset = Vector3.new(0, 4, 0)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextScaled = true
		lbl.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3)
		local pet = GameConfigFS.Pets[id]
		lbl.Text = (def.Icon or "✨") .. " " .. string.upper(def.Name) .. " " .. (pet and pet.Name or "") .. "!"
		local st = Instance.new("UIStroke")
		st.Thickness = 3
		st.Color = Color3.fromRGB(30, 20, 50)
		st.Parent = lbl
		lbl.Parent = gui
		gui.Adornee = result.PrimaryPart or result:FindFirstChildWhichIsA("BasePart", true)
		gui.Parent = result
		local top = chamber + Vector3.new(0, size.Y * 0.55 + 3, 0)
		local t1 = os.clock()
		while os.clock() - t1 < 1.6 do
			local k = (os.clock() - t1) / 1.6
			local pos = k < 0.6 and chamber:Lerp(top, math.sin(k / 0.6 * math.pi / 2)) or top
			result:PivotTo(CFrame.new(pos + Vector3.new(0, math.sin(k * 10) * 0.2, 0)) * CFrame.Angles(0, k * math.pi * 4, 0))
			result:ScaleTo(sc * math.min(1.3, 0.3 + k * 1.6))
			task.wait()
		end
		local r2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local from = result:GetPivot().Position
		local t2 = os.clock()
		while os.clock() - t2 < 0.6 do
			local k = (os.clock() - t2) / 0.6
			local target = r2 and r2.Position + Vector3.new(0, 2, 0) or from
			result:PivotTo(CFrame.new(from:Lerp(target, k * k)) * CFrame.Angles(0, k * 10, 0))
			result:ScaleTo(sc * math.max(0.05, 1.3 * (1 - k)))
			task.wait()
		end
		result:Destroy()
	end
	task.delay(1, function()
		glow:Destroy()
		flash:Destroy()
		ring:Destroy()
	end)
end

-- Успешное превращение: 3D-показ и вспышка ядра и купола у машины.
fuse.OnClientEvent:Connect(function(tier, id)
	task.spawn(fuseShow, tier, id)
	local machine = workspace:FindFirstChild("PetMachines") and workspace.PetMachines:FindFirstChild("PetMachine" .. tostring(tier))
	local core = machine and machine:FindFirstChild("Core")
	if not core then
		return
	end
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = ShopConfig.Variants[tier].Color
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CanTouch = false
	flash.CastShadow = false
	flash.Size = Vector3.new(2, 2, 2)
	flash.CFrame = core.CFrame
	flash.Transparency = 0.2
	flash.Parent = workspace
	local grow = TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(12, 12, 12), Transparency = 1 })
	grow.Completed:Connect(function()
		flash:Destroy()
	end)
	grow:Play()
	local att = Instance.new("Attachment")
	att.Parent = core
	local fx = Instance.new("ParticleEmitter")
	fx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	fx.Color = ColorSequence.new(ShopConfig.Variants[tier].Color)
	fx.LightEmission = 1
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	fx.Lifetime = NumberRange.new(0.6, 1)
	fx.Speed = NumberRange.new(10, 20)
	fx.SpreadAngle = Vector2.new(180, 180)
	fx.Enabled = false
	fx.Parent = att
	fx:Emit(40)
	task.delay(1.5, function()
		att:Destroy()
	end)
end)

-- Анимация: ядро машин пульсирует, кольца крутятся, у радужной машины переливаются цвета.
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	if window.Visible then -- скрытое окно не крутит модели
		for _, model in ipairs(spinning) do
			if model.Parent then
				model:PivotTo(CFrame.Angles(0, t * 0.8, 0))
			end
		end
	end
	if window.Visible then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not currentMachine or (root.Position - currentMachine:GetPivot().Position).Magnitude > 24 then
			closeWindow()
		end
		local camera = workspace.CurrentCamera
		if camera and windowScale.Scale > 0.99 then
			windowScale.Scale = math.clamp(math.min(camera.ViewportSize.X / 720, camera.ViewportSize.Y / 520), 0.55, 1)
		end
	end
end)
local machinesFolder = workspace:WaitForChild("PetMachines", 30)
if machinesFolder then
	local rings = {}
	local function scan()
		table.clear(rings)
		for _, m in ipairs(machinesFolder:GetChildren()) do
			for _, d in ipairs(m:GetChildren()) do
				if d:IsA("BasePart") and (string.sub(d.Name, 1, 4) == "Ring" or string.sub(d.Name, 1, 11) == "RainbowRing" or d.Name == "Core") then
					table.insert(rings, { part = d, base = d.CFrame, k = #rings, rainbow = string.sub(d.Name, 1, 7) == "Rainbow" })
				end
			end
		end
	end
	machinesFolder.ChildAdded:Connect(function()
		task.wait(1)
		scan()
	end)
	task.delay(2, scan)
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 1 / 30 then
			return
		end
		acc = 0
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		for _, r in ipairs(rings) do
			if r.part.Parent and (r.part.Position - camera.CFrame.Position).Magnitude < 150 then
				if r.part.Name == "Core" then
					local s = 1 + 0.08 * math.sin(t * 3)
					r.part.Size = Vector3.new(2.4, 2.4, 2.4) * s
				else
					local center = r.base.Position
					r.part.CFrame = CFrame.new(center) * CFrame.Angles(0, t * (0.6 + r.k * 0.15), 0) * (r.base - center)
					if r.rainbow then
						r.part.Color = Color3.fromHSV((t * 0.2 + r.k * 0.2) % 1, 0.65, 1)
					end
				end
			end
		end
	end)
end
