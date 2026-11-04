-- HUD поверх GameHUD/MainHUD.
-- 1) Раскладка (во всех мирах): настройки — отдельной кнопкой в правом верхнем углу; INDEX, ITEMS,
--    STATS, TELEPORT, DAILY, REBIRTH собраны в одно меню за кнопкой «≡» внизу по центру.
--    Логика кнопок остаётся в GameHUD — мы только переносим их и закрываем меню после выбора.
-- 2) Скин (по миру из HudSkins): картинки на кнопках и плитках статистики, окно меню в стиле мира,
--    «объёмный» отклик кнопок на курсор. В мире без скина остаётся нарисованный кодом вид.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Skins = require(ReplicatedStorage:WaitForChild("HudSkins"))
local playerGui = player:WaitForChild("PlayerGui")
local row = playerGui:WaitForChild("CornerMenuHUD"):WaitForChild("MenuButtons")
local panels = playerGui:WaitForChild("MainHUD"):WaitForChild("Panels")

local MENU_ORDER = { "INDEX", "ITEMS", "STATS", "TELEPORT", "DAILY", "REBIRTH" }
local BUTTON_KEYS = {
	INDEX = "Btn_Index",
	ITEMS = "Btn_Items",
	STATS = "Btn_Stats",
	TELEPORT = "Btn_Teleport",
	DAILY = "Btn_Daily",
	REBIRTH = "Btn_Rebirth",
	SETTINGS = "Btn_Settings",
}
-- Плитки MainHUD различаются по LayoutOrder: монеты, скорость, множитель, магнит.
local PANELS = {
	[1] = { tile = "Tile_Gold", icon = "Icon_Coin" },
	[2] = { tile = "Tile_Blue", icon = "Icon_Speed" },
	[3] = { tile = "Tile_Pink", icon = "Icon_Multiplier" },
	[4] = { tile = "Tile_Purple", icon = "Icon_Magnet" },
}
local CELL, GAP = 92, 12
local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_TOP, DEFAULT_BOTTOM = Color3.fromRGB(90, 110, 140), Color3.fromRGB(45, 60, 85)
local DEFAULT_RIM = Color3.fromRGB(30, 30, 40)
local INK = Color3.fromRGB(35, 22, 60)

------------------------------------------------------------------ раскладка
local menuGui = Instance.new("ScreenGui")
menuGui.Name = "MenuHUD"
menuGui.ResetOnSpawn = false
menuGui.DisplayOrder = 13
menuGui.Parent = playerGui

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

-- Общий контейнер внизу по центру: в нём «≡» и окно меню, масштаб под размер экрана.
local dock = Instance.new("Frame")
dock.Name = "Dock"
dock.AnchorPoint = Vector2.new(0.5, 1)
dock.Position = UDim2.new(0.5, 0, 1, -76) -- выше слота инструментов Roblox
dock.Size = UDim2.fromOffset(384, 420)
dock.BackgroundTransparency = 1
dock.Parent = menuGui
local dockScale = Instance.new("UIScale")
dockScale.Parent = dock

-- Кнопка «≡».
local burger = Instance.new("TextButton")
burger.Name = "MenuToggle"
burger.AnchorPoint = Vector2.new(0.5, 1)
burger.Position = UDim2.new(0.5, 0, 1, 0)
burger.Size = UDim2.fromOffset(76, 76)
burger.Text = ""
burger.AutoButtonColor = false
burger.BackgroundColor3 = Color3.new(1, 1, 1)
burger.Parent = dock
corner(burger, 22)
local burgerGradient = Instance.new("UIGradient")
burgerGradient.Rotation = 90
burgerGradient.Color = ColorSequence.new(DEFAULT_TOP, DEFAULT_BOTTOM)
burgerGradient.Parent = burger
local burgerRim = Instance.new("UIStroke")
burgerRim.Thickness = 4
burgerRim.Color = DEFAULT_RIM
burgerRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
burgerRim.Parent = burger
local gloss = Instance.new("Frame")
gloss.BackgroundColor3 = Color3.new(1, 1, 1)
gloss.BackgroundTransparency = 0.72
gloss.BorderSizePixel = 0
gloss.Position = UDim2.fromOffset(5, 5)
gloss.Size = UDim2.new(1, -10, 0.38, 0)
gloss.Parent = burger
corner(gloss, 16)
local bars = {}
for i = 1, 3 do
	local b = Instance.new("Frame")
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.new(0.5, 0, 0.5, (i - 2) * 14)
	b.Size = UDim2.fromOffset(42, 8)
	b.BackgroundColor3 = Color3.new(1, 1, 1)
	b.BorderSizePixel = 0
	b.ZIndex = 2
	b.Parent = burger
	corner(b, 4)
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = INK
	s.Parent = b
	bars[i] = b
end
local burgerScale = Instance.new("UIScale")
burgerScale.Parent = burger
local burgerDot = Instance.new("TextLabel")
burgerDot.Name = "Dot"
burgerDot.AnchorPoint = Vector2.new(0.5, 0.5)
burgerDot.Position = UDim2.new(1, -6, 0, 6)
burgerDot.Size = UDim2.fromOffset(26, 26)
burgerDot.BackgroundColor3 = Color3.fromRGB(235, 60, 70)
burgerDot.Text = "!"
burgerDot.Font = Enum.Font.FredokaOne
burgerDot.TextSize = 19
burgerDot.TextColor3 = Color3.new(1, 1, 1)
burgerDot.ZIndex = 5
burgerDot.Visible = false
burgerDot.Parent = burger
corner(burgerDot, 13)
local burgerDotStroke = Instance.new("UIStroke")
burgerDotStroke.Thickness = 2
burgerDotStroke.Color = INK
burgerDotStroke.Parent = burgerDot

-- Окно меню — настоящая 3D-«карточка»: SurfaceGui на невидимой пластине прямо перед камерой.
-- Пластина наклоняется к курсору по двум осям (край под курсором уходит вглубь), но не сдвигается.
local BOARD_W, BOARD_H, BOARD_DIST = 384, 312, 4
local board = Instance.new("Part")
board.Name = "MenuBoard"
board.Anchored = true
board.CanCollide = false
board.CanTouch = false
board.CanQuery = true
board.CastShadow = false
board.Transparency = 1
board.Size = Vector3.new(1, 1, 0.05)
local boardGui = Instance.new("SurfaceGui")
boardGui.Name = "MenuBoardGui"
boardGui.Face = Enum.NormalId.Back
boardGui.AlwaysOnTop = true
boardGui.LightInfluence = 0
boardGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
boardGui.CanvasSize = Vector2.new(BOARD_W, BOARD_H)
boardGui.ResetOnSpawn = false
boardGui.Adornee = board
boardGui.Enabled = false
boardGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "MenuPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(BOARD_W, BOARD_H)
panel.BackgroundTransparency = 1
panel.Visible = false
panel.Parent = boardGui
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
local back = Instance.new("Frame")
back.Name = "Back"
back.AnchorPoint = Vector2.new(0.5, 0.5)
back.Position = UDim2.fromScale(0.5, 0.54)
back.Size = UDim2.new(1, -24, 1, -48)
back.BackgroundColor3 = Color3.new(1, 1, 1)
back.Parent = panel
corner(back, 26)
local backGradient = Instance.new("UIGradient")
backGradient.Rotation = 90
backGradient.Color = ColorSequence.new(DEFAULT_TOP, DEFAULT_BOTTOM)
backGradient.Parent = back
local backRim = Instance.new("UIStroke")
backRim.Thickness = 4
backRim.Color = DEFAULT_RIM
backRim.Parent = back
local frameImage = Instance.new("ImageLabel")
frameImage.Name = "Frame"
frameImage.BackgroundTransparency = 1
frameImage.Size = UDim2.fromScale(1, 1)
frameImage.ZIndex = 2
frameImage.Visible = false
frameImage.Parent = panel
local grid = Instance.new("Frame")
grid.Name = "Grid"
grid.AnchorPoint = Vector2.new(0.5, 0.5)
grid.Position = UDim2.fromScale(0.5, 0.56)
grid.Size = UDim2.fromOffset(3 * CELL + 2 * GAP, 2 * CELL + GAP)
grid.BackgroundTransparency = 1
grid.ZIndex = 3
grid.Parent = panel
local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(CELL, CELL)
layout.CellPadding = UDim2.fromOffset(GAP, GAP)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = grid

-- Настройки — в правый верхний угол.
local topRight = Instance.new("Frame")
topRight.Name = "TopRight"
topRight.AnchorPoint = Vector2.new(1, 0)
topRight.Position = UDim2.new(1, -16, 0, 16)
topRight.Size = UDim2.fromOffset(60, 60)
topRight.BackgroundTransparency = 1
topRight.Parent = menuGui
local topScale = Instance.new("UIScale")
topScale.Parent = topRight

local open = false
local function setOpen(value: boolean)
	if open == value then
		return
	end
	open = value
	-- Полоски превращаются в крестик и обратно.
	TweenService:Create(bars[1], FAST, { Rotation = value and 45 or 0, Position = UDim2.new(0.5, 0, 0.5, value and 0 or -14) }):Play()
	TweenService:Create(bars[2], FAST, { BackgroundTransparency = value and 1 or 0 }):Play()
	bars[2]:FindFirstChildOfClass("UIStroke").Transparency = value and 1 or 0
	TweenService:Create(bars[3], FAST, { Rotation = value and -45 or 0, Position = UDim2.new(0.5, 0, 0.5, value and 0 or 14) }):Play()
	if value then
		panel.Visible = true
		panelScale.Scale = 0.55
		TweenService:Create(panelScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		local shrink = TweenService:Create(panelScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.55 })
		shrink.Completed:Connect(function()
			if not open then
				panel.Visible = false
			end
		end)
		shrink:Play()
	end
end
burger.Activated:Connect(function()
	setOpen(not open)
end)
burger.MouseEnter:Connect(function()
	TweenService:Create(burgerScale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1.08 }):Play()
end)
burger.MouseLeave:Connect(function()
	TweenService:Create(burgerScale, FAST, { Scale = 1 }):Play()
end)
burger.MouseButton1Down:Connect(function()
	TweenService:Create(burgerScale, TweenInfo.new(0.06), { Scale = 0.92 }):Play()
end)
burger.MouseButton1Up:Connect(function()
	TweenService:Create(burgerScale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1.08 }):Play()
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	if (player:GetAttribute("UIScreen") or "") ~= "" then
		setOpen(false)
	end
end)

-- Переносим кнопки GameHUD: шесть — в сетку меню, настройки — в угол.
local dailyDot: TextLabel? = nil
for i, name in ipairs(MENU_ORDER) do
	local button = row:WaitForChild(name, 10)
	if button then
		button.LayoutOrder = i
		button.Parent = grid
		button.Activated:Connect(function()
			setOpen(false)
		end)
		for _, child in ipairs(button:GetChildren()) do
			if child:IsA("TextLabel") and child.Text == "!" then
				dailyDot = child
			end
		end
	end
end
local settingsButton = row:WaitForChild("SETTINGS", 10)
if settingsButton then
	settingsButton.AnchorPoint = Vector2.new(0, 0)
	settingsButton.Position = UDim2.fromOffset(0, 0)
	settingsButton.Size = UDim2.fromScale(1, 1)
	settingsButton.Parent = topRight
end
row.Visible = false
-- Красная точка DAILY дублируется на «≡», чтобы награду было видно и при закрытом меню.
if dailyDot then
	local function mirror()
		burgerDot.Visible = dailyDot.Visible
	end
	dailyDot:GetPropertyChangedSignal("Visible"):Connect(mirror)
	mirror()
end
-- Панель инструментов Roblox (слот «1» с магнитом) не нужна: магнит всегда в руках,
-- а снять, надеть или сменить его можно в магазине магнитов.
task.spawn(function()
	for _ = 1, 20 do
		if pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end) then
			break
		end
		task.wait(0.5)
	end
end)

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if camera then
		local v = camera.ViewportSize
		local s = math.clamp(math.min(v.X / 700, v.Y / 520), 0.6, 1)
		dockScale.Scale = s
		topScale.Scale = s
	end
end)

-- Каждый кадр после камеры ставим пластину над кнопкой «≡» и наклоняем её к курсору.
-- Курсор далеко — пластина возвращается и чуть покачивается сама.
local tiltX, tiltY, idleT = 0, 0, 0
RunService:BindToRenderStep("MenuBoard", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local camera = workspace.CurrentCamera
	boardGui.Enabled = panel.Visible
	if not panel.Visible or not camera then
		board.Parent = nil
		return
	end
	if board.Parent ~= camera then
		board.Parent = camera
	end
	idleT += dt
	local vp = camera.ViewportSize
	local s = dockScale.Scale
	local wPx, hPx = BOARD_W * s, BOARD_H * s
	local cx, cy = vp.X / 2, vp.Y - (76 + (90 + BOARD_H / 2) * s)
	local studsPerPixel = 2 * BOARD_DIST * math.tan(math.rad(camera.FieldOfView) / 2) / vp.Y
	board.Size = Vector3.new(wPx * studsPerPixel, hPx * studsPerPixel, 0.05)
	local mouse = UserInputService:GetMouseLocation()
	local rx = (mouse.X - cx) / (wPx / 2)
	local ry = (mouse.Y - cy) / (hPx / 2)
	local near = math.abs(rx) < 1.4 and math.abs(ry) < 1.4
	local targetY = near and math.clamp(rx, -1, 1) * 16 or math.sin(idleT * 0.9) * 3
	local targetX = near and math.clamp(ry, -1, 1) * 12 or math.sin(idleT * 1.3) * 2
	local k = math.min(1, dt * 10)
	tiltY += (targetY - tiltY) * k
	tiltX += (targetX - tiltX) * k
	local ray = camera:ViewportPointToRay(cx, cy)
	local look = camera.CFrame
	board.CFrame = CFrame.fromMatrix(ray.Origin + ray.Direction * BOARD_DIST, look.RightVector, look.UpVector)
		* CFrame.Angles(math.rad(tiltX), math.rad(tiltY), 0)
end)

------------------------------------------------------------------ скин
local restore = {}
local created = {}
local connections = {}
local function set(obj: Instance, prop: string, value: any)
	table.insert(restore, { obj, prop, (obj :: any)[prop] })
	;(obj :: any)[prop] = value
end
local function make(className: string, props: { [string]: any }, parent: Instance): any
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	table.insert(created, inst)
	return inst
end
local function clear()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, inst in ipairs(created) do
		inst:Destroy()
	end
	table.clear(created)
	for i = #restore, 1, -1 do
		local r = restore[i]
		if r[1].Parent then
			r[1][r[2]] = r[3]
		end
	end
	table.clear(restore)
end

-- Оттенок скина (Frozen Peaks берёт картинки Sky Isles и красит их в ледяной цвет).
local currentSkinTint: Color3? = nil
local function skinButton(button: GuiButton, image: string, side: number, dotImage: string?)
	local dot: TextLabel? = nil
	for _, child in ipairs(button:GetChildren()) do
		if child:IsA("TextLabel") and child.Text == "!" then
			dot = child
		end
	end
	set(button, "BackgroundTransparency", 1)
	for _, child in ipairs(button:GetChildren()) do
		if child == dot then
			continue
		elseif child:IsA("UIGradient") or child:IsA("UIStroke") then
			set(child, "Enabled", false)
		elseif child:IsA("GuiObject") then
			set(child, "Visible", false)
		end
	end
	local shadow = make("ImageLabel", {
		Name = "SkinShadow",
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = Color3.fromRGB(40, 12, 70),
		ImageTransparency = 0.6,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 5),
		Size = UDim2.fromOffset(side, side),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 1,
	}, button)
	local img = make("ImageLabel", {
		Name = "SkinImage",
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = (currentSkinTint or Color3.new(1, 1, 1)),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(side, side),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 2,
	}, button)
	if dot and dotImage then
		set(dot, "TextTransparency", 1)
		set(dot, "BackgroundTransparency", 1)
		local s = dot:FindFirstChildOfClass("UIStroke")
		if s then
			set(s, "Enabled", false)
		end
		make("ImageLabel", {
			Name = "SkinDot",
			BackgroundTransparency = 1,
			Image = dotImage,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.5, 1.5),
			ZIndex = 6,
		}, dot)
	end
	-- Псевдо-3D: наклон к курсору, подъём, тень уходит в противоположную сторону.
	local function lean(rel: number, lifted: boolean)
		TweenService:Create(img, FAST, {
			Rotation = rel * 6,
			Position = UDim2.new(0.5, rel * 2, 0.5, lifted and -3 or 0),
		}):Play()
		TweenService:Create(shadow, FAST, {
			Position = UDim2.new(0.5, -rel * 5, 0.5, lifted and 8 or 5),
			ImageTransparency = lifted and 0.45 or 0.6,
		}):Play()
	end
	table.insert(connections, button.MouseMoved:Connect(function(x)
		local half = button.AbsoluteSize.X / 2
		if half > 0 then
			lean(math.clamp((x - button.AbsolutePosition.X - half) / half, -1, 1), true)
		end
	end))
	table.insert(connections, button.MouseEnter:Connect(function()
		lean(0, true)
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		lean(0, false)
	end))
end

local function skinPanel(frame: Frame, skin, def)
	local h = frame.Size.Y.Offset
	local icon, value
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("TextLabel") then
			if child:FindFirstChildOfClass("UICorner") then
				icon = child
			elseif child.TextXAlignment == Enum.TextXAlignment.Left then
				value = child
			end
		end
	end
	set(frame, "BackgroundTransparency", 1)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("UIGradient") or child:IsA("UIStroke") then
			set(child, "Enabled", false)
		end
	end
	if icon then
		set(icon, "Visible", false)
	end
	-- Картинки плиток нарезаны точно под пропорции панели: тянем целиком, без 9-slice.
	make("ImageLabel", {
		Name = "SkinTile",
		BackgroundTransparency = 1,
		Image = skin[def.tile],
		ImageColor3 = skin.Tint or Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
	}, frame)
	make("ImageLabel", {
		Name = "SkinIcon",
		BackgroundTransparency = 1,
		Image = skin[def.icon],
		ImageColor3 = skin.Tint or Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -12, 0.5, 0),
		Size = UDim2.fromOffset(h + 16, h + 16),
		ZIndex = 3,
	}, frame)
	if value then
		local s = value:FindFirstChildOfClass("UIStroke")
		if s and skin.InkColor then
			set(s, "Color", skin.InkColor)
		end
		-- Круглая иконка скина крупнее старой: сдвигаем текст правее, чтобы он не заезжал под неё.
		set(value, "Position", UDim2.fromOffset(h + 12, 0))
		set(value, "Size", UDim2.new(1, -(h + 12) - 14, 1, 0))
	end
end

-- Плашка с названием мира выезжает сверху при входе в мир.
local titleGui = Instance.new("ScreenGui")
titleGui.Name = "WorldTitleHUD"
titleGui.ResetOnSpawn = false
titleGui.DisplayOrder = 15
titleGui.IgnoreGuiInset = true
titleGui.Parent = playerGui
local plate = Instance.new("ImageLabel")
plate.Name = "Plate"
plate.BackgroundTransparency = 1
plate.AnchorPoint = Vector2.new(0.5, 1)
plate.Position = UDim2.new(0.5, 0, 0, -10)
plate.Size = UDim2.fromOffset(380, 108)
plate.Visible = false
plate.Parent = titleGui
local plateText = Instance.new("TextLabel")
plateText.BackgroundTransparency = 1
plateText.AnchorPoint = Vector2.new(0.5, 0.5)
plateText.Position = UDim2.fromScale(0.5, 0.5)
plateText.Size = UDim2.fromScale(0.62, 0.42)
plateText.Font = Enum.Font.FredokaOne
plateText.TextScaled = true
plateText.Parent = plate
local plateStroke = Instance.new("UIStroke")
plateStroke.Thickness = 3
plateStroke.Parent = plateText
local showVersion = 0
local function showTitle(world: string, skin)
	if not skin.Plate_Title then
		return
	end
	showVersion += 1
	local mine = showVersion
	plate.Image = skin.Plate_Title
	plate.ImageColor3 = skin.Tint or Color3.new(1, 1, 1)
	plateText.Text = string.upper(world)
	plateText.TextColor3 = skin.TitleColor or Color3.new(1, 1, 1)
	plateStroke.Color = skin.InkColor or INK
	plate.Position = UDim2.new(0.5, 0, 0, -10)
	plate.Visible = true
	TweenService:Create(plate, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 236), -- ниже плашки события сверху
	}):Play()
	task.delay(2.6, function()
		if showVersion ~= mine then
			return
		end
		local away = TweenService:Create(plate, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -10),
		})
		away.Completed:Connect(function()
			if showVersion == mine then
				plate.Visible = false
			end
		end)
		away:Play()
	end)
end

local current = nil
local function apply(announce: boolean)
	local world = player:GetAttribute("CurrentWorld")
	local skin = world and Skins[world]
	currentSkinTint = skin and skin.Tint or nil
	if skin and not skin.Btn_Index then
		skin = nil
	end
	if skin == current then
		return
	end
	clear()
	current = skin
	if not skin then
		return
	end
	for i, name in ipairs(MENU_ORDER) do
		local button = grid:FindFirstChild(name)
		if button and button:IsA("GuiButton") and skin[BUTTON_KEYS[name]] then
			skinButton(button, skin[BUTTON_KEYS[name]], CELL + 6, name == "DAILY" and skin.Dot_Notify or nil)
		end
	end
	if settingsButton and skin.Btn_Settings then
		skinButton(settingsButton, skin.Btn_Settings, 64, nil)
	end
	-- «≡» и окно меню в цветах мира, рамка окна — картинка из набора.
	if skin.MenuTop and skin.MenuBottom then
		set(burgerGradient, "Color", ColorSequence.new(skin.MenuTop, skin.MenuBottom))
		set(backGradient, "Color", ColorSequence.new(skin.MenuTop, skin.MenuBottom))
	end
	if skin.RimColor then
		set(burgerRim, "Color", skin.RimColor)
		set(backRim, "Color", skin.RimColor)
	end
	if skin.Frame_Window then
		set(frameImage, "Image", skin.Frame_Window)
		set(frameImage, "Visible", true)
		set(backRim, "Enabled", false)
	end
	if skin.Dot_Notify then
		set(burgerDot, "BackgroundTransparency", 1)
		set(burgerDot, "TextTransparency", 1)
		set(burgerDotStroke, "Enabled", false)
		make("ImageLabel", {
			Name = "SkinDot",
			BackgroundTransparency = 1,
			Image = skin.Dot_Notify,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.5, 1.5),
			ZIndex = 6,
		}, burgerDot)
	end
	for _, frame in ipairs(panels:GetChildren()) do
		local def = frame:IsA("Frame") and PANELS[frame.LayoutOrder]
		if def and skin[def.tile] and skin[def.icon] then
			skinPanel(frame, skin, def)
		end
	end
	if announce then
		showTitle(world, skin)
	end
end

player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
	apply(true)
end)
apply(false)
