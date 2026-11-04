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
	for id = 1, #Config.Pets do
		if count(id, fromTier) > 0 then
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

-- Успешное превращение: вспышка ядра и купола у машины.
fuse.OnClientEvent:Connect(function(tier)
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
	for _, model in ipairs(spinning) do
		if model.Parent then
			model:PivotTo(CFrame.Angles(0, t * 0.8, 0))
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
