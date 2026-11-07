-- Окна и HUD в цвет мира: инвентарь, индекс, ребитх, телепорт, магазины, машины, кнопки.
-- Перекрашиваем только «подложки» — тёмные и приглушённые цвета фонов, обводок и градиентов.
-- Яркие кнопки (купить/закрыть), цвета редкости и текст не трогаем, чтобы всё читалось как раньше.
-- Окно ежедневных наград (DailyRewardsUI) тоже в цвет мира. Ребитх красим без осветления — иначе пересвечен.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUIS = {
	Inventory = true,
	PetIndexBook = true,
	RebirthUI = true,
	TeleportUI = true,
	-- ShopPanels: своё оформление (UIKit)
	WorkshopUI = true,
	PetMachineUI = true,
	CoinSprintHUD = true,
	CornerMenuHUD = true,
	MainHUD = true,
	DailyRewardsUI = true,
}
-- окна, которые не осветляем (только оттенок мира)
local DIM = { RebirthUI = true }
local dimNow = false

-- hue/sat — подложки, edgeHue/edgeSat — обводки, light — во сколько раз светлее.
local THEMES = {
	["Meadow Isles"] = { hue = 0.31, sat = 0.6, edgeHue = 0.13, edgeSat = 0.7, light = 1.25 },
	["Neon District"] = { hue = 0.78, sat = 0.72, edgeHue = 0.52, edgeSat = 0.8, light = 1.0 },
	["Sky Isles"] = { hue = 0.79, sat = 0.48, edgeHue = 0.12, edgeSat = 0.7, light = 1.7 },
	["Frozen Peaks"] = { hue = 0.58, sat = 0.6, edgeHue = 0.53, edgeSat = 0.3, light = 1.55 },
	["Magma Volcano"] = { hue = 0.03, sat = 0.7, edgeHue = 0.09, edgeSat = 0.85, light = 1.25 },
	["Cosmic Galaxy"] = { hue = 0.72, sat = 0.6, edgeHue = 0.52, edgeSat = 0.6, light = 1.2 },
}

local theme = nil

-- Подходит ли цвет под «подложку»: тёмный/приглушённый или почти серый светлый.
local function remap(c: Color3, edge: boolean): Color3?
	if not theme then
		return nil
	end
	local h, s, v = c:ToHSV()
	local hue = edge and theme.edgeHue or theme.hue
	local sat = edge and theme.edgeSat or theme.sat
	local light = theme.light
	if dimNow then
		light = math.min(light, 0.95)
		sat *= 0.8
	end
	if v < 0.62 and s < 0.78 then
		return Color3.fromHSV(hue, sat, math.min(1, v * light))
	elseif s < 0.15 and v >= 0.62 and not edge then
		-- светлые серые плашки — лёгкий оттенок мира
		return Color3.fromHSV(hue, 0.12, v)
	end
	return nil
end

-- Для каждого свойства помним исходный цвет и тот, что поставили сами: если цвет поменял
-- другой скрипт (HudSkin, наведение мыши), берём его новым исходным.
local orig: { [Instance]: { [string]: any } } = setmetatable({}, { __mode = "k" }) :: any
local mine: { [Instance]: { [string]: any } } = setmetatable({}, { __mode = "k" }) :: any

local function source(inst: Instance, prop: string, current: any)
	local o, m = orig[inst], mine[inst]
	if not o then
		o, m = {}, {}
		orig[inst], mine[inst] = o, m
	end
	if o[prop] == nil or m[prop] ~= current then
		o[prop] = current
	end
	return o[prop]
end

local function setColor(inst: Instance, prop: string, edge: boolean)
	local current = (inst :: any)[prop]
	local base = source(inst, prop, current)
	local new = remap(base, edge) or base
	mine[inst][prop] = new
	if current ~= new then
		(inst :: any)[prop] = new
	end
end

local function setSequence(g: UIGradient)
	local current = g.Color
	local base = source(g, "Color", current)
	local keys = {}
	for i, k in ipairs(base.Keypoints) do
		keys[i] = ColorSequenceKeypoint.new(k.Time, remap(k.Value, false) or k.Value)
	end
	local new = ColorSequence.new(keys)
	mine[g].Color = new
	g.Color = new
end

-- окна со своим продуманным оформлением ставят атрибут NoTheme — их не перекрашиваем
local function themed(inst: Instance): boolean
	local a: Instance? = inst
	while a and not a:IsA("ScreenGui") do
		if a:GetAttribute("NoTheme") then
			return false
		end
		a = a.Parent
	end
	return true
end

local function paint(inst: Instance)
	if not themed(inst) then
		return
	end
	if inst:IsA("GuiObject") then
		if inst.BackgroundTransparency < 1 then
			setColor(inst, "BackgroundColor3", false)
		end
	elseif inst:IsA("UIStroke") then
		setColor(inst, "Color", true)
	elseif inst:IsA("UIGradient") then
		setSequence(inst)
	end
end

local roots = {}
local function paintAll()
	for gui in pairs(roots) do
		if gui.Parent then
			dimNow = DIM[gui.Name] == true
			for _, d in ipairs(gui:GetDescendants()) do
				paint(d)
			end
			dimNow = false
		end
	end
end

local function hook(gui: Instance)
	if not (gui:IsA("ScreenGui") and GUIS[gui.Name]) or roots[gui] then
		return
	end
	roots[gui] = true
	local dim = DIM[gui.Name] == true
	gui.DescendantAdded:Connect(function(d)
		task.defer(function() -- ячейки инвентаря и списков появляются на лету
			dimNow = dim
			paint(d)
			dimNow = false
		end)
	end)
	dimNow = dim
	for _, d in ipairs(gui:GetDescendants()) do
		paint(d)
	end
	dimNow = false
end


------------------------------------------------------------------ украшения окон
-- На большие окна (инвентарь, индекс, магазины…) по углам садятся украшения мира:
-- Meadow — цветы и бабочка, Sky — облака, звёзды и радуга, Neon — светящиеся уголки,
-- Frozen — снежинки и лёд. Украшения слегка покачиваются.
local RunService = game:GetService("RunService")
local DECOR = {
	["Meadow Isles"] = { tl = "🌸", tr = "🌼", bl = "🍃", br = "🌷", top = "🦋", row = { "🌼", "🌸", "🌷", "🌸", "🌼" } },
	["Sky Isles"] = { tl = "☁️", tr = "☁️", bl = "⭐", br = "🌈", top = "✨", row = { "☁️", "⭐", "☁️", "⭐", "☁️" } },
	["Frozen Peaks"] = { tl = "❄️", tr = "❄️", bl = "🧊", br = "❄️", top = "✨", row = { "❄️", "✨", "❄️", "✨", "❄️" } },
	["Neon District"] = { neon = true },
	["Magma Volcano"] = { tl = "🔥", tr = "🌋", bl = "🔥", br = "🔥", top = "✨", row = { "🔥", "💥", "🔥", "💥", "🔥" } },
	["Cosmic Galaxy"] = { tl = "🪐", tr = "🌙", bl = "🚀", br = "⭐", top = "🌠", row = { "⭐", "✨", "🪐", "✨", "⭐" } },
}
local CORNER = { tl = Vector2.new(0, 0), tr = Vector2.new(1, 0), bl = Vector2.new(0, 1), br = Vector2.new(1, 1), top = Vector2.new(0.72, 0) }
local decorated: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local wiggles = {}
local decoWorld = nil

local function isWindow(f: Instance): boolean
	if not f:IsA("Frame") or f.BackgroundTransparency > 0.5 or not f:FindFirstChildOfClass("UICorner") then
		return false
	end
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local a = f.AbsoluteSize
	return a.X >= 320 and a.Y >= 200 and a.X < vp.X * 0.9 and a.Y < vp.Y * 0.9
end

local function clearDecor()
	for f in pairs(decorated) do
		local d = f:FindFirstChild("WorldDeco")
		if d then
			d:Destroy()
		end
	end
	table.clear(decorated)
	table.clear(wiggles)
end

local function decorate(f: Frame, set)
	decorated[f] = true
	local holder = Instance.new("Folder")
	holder.Name = "WorldDeco"
	local a = f.AbsoluteSize
	local size = math.clamp(math.min(a.X, a.Y) * 0.2, 42, 84)
	if set.neon then
		-- светящиеся уголки-скобки, розовые и голубые
		for key, c in pairs(CORNER) do
			if key ~= "top" then
				local col = (key == "tl" or key == "br") and Color3.fromRGB(80, 240, 255) or Color3.fromRGB(255, 70, 220)
				for k = 1, 2 do
					local bar = Instance.new("Frame")
					bar.Name = "NeonBracket"
					bar.BorderSizePixel = 0
					bar.BackgroundColor3 = col
					bar.AnchorPoint = c
					bar.Position = UDim2.new(c.X, c.X == 0 and -3 or 3, c.Y, c.Y == 0 and -3 or 3)
					bar.Size = k == 1 and UDim2.fromOffset(size * 1.3, 7) or UDim2.fromOffset(7, size * 1.3)
					bar.ZIndex = 60
					local st = Instance.new("UIStroke")
					st.Color = col
					st.Thickness = 3
					st.Transparency = 0.5
					st.Parent = bar
					bar.Parent = holder
					table.insert(wiggles, { obj = bar, neon = st, phase = math.random() * 6 })
				end
			end
		end
	else
		for key, c in pairs(CORNER) do
			local emoji = set[key]
			-- в правом верхнем углу у всех окон кнопка закрытия — украшение её закрывало
			if emoji and key ~= "tr" then
				local l = Instance.new("TextLabel")
				l.Name = "Deco"
				l.BackgroundTransparency = 1
				l.Text = emoji
				l.TextScaled = true
				l.Font = Enum.Font.GothamBold
				l.AnchorPoint = Vector2.new(0.5, 0.5)
				l.Position = UDim2.new(c.X, c.X == 0 and 6 or (c.X == 1 and -6 or 0), c.Y, c.Y == 0 and 4 or -4)
				local sz = key == "top" and size * 0.7 or size
				l.Size = UDim2.fromOffset(sz, sz)
				l.ZIndex = 60
				l.Parent = holder
				table.insert(wiggles, { obj = l, base = l.Position, phase = math.random() * 6, fly = key == "top" })
			end
		end
		-- гирлянда по нижнему краю
		if set.row then
			for i, emoji in ipairs(set.row) do
				local l = Instance.new("TextLabel")
				l.Name = "Deco"
				l.BackgroundTransparency = 1
				l.Text = emoji
				l.TextScaled = true
				l.Font = Enum.Font.GothamBold
				l.AnchorPoint = Vector2.new(0.5, 0.5)
				l.Position = UDim2.new(i / (#set.row + 1), 0, 1, 0)
				l.Size = UDim2.fromOffset(size * 0.5, size * 0.5)
				l.ZIndex = 60
				l.Parent = holder
				table.insert(wiggles, { obj = l, base = l.Position, phase = i * 0.9 })
			end
		end
	end
	holder.Parent = f
end

local function decorAll()
	local set = DECOR[player:GetAttribute("CurrentWorld") or ""]
	local w = player:GetAttribute("CurrentWorld")
	if w ~= decoWorld then
		decoWorld = w
		clearDecor()
	end
	if not set then
		return
	end
	for gui in pairs(roots) do
		if gui.Parent and gui.Enabled then
			for _, d in ipairs(gui:GetDescendants()) do
				local inside = false
				local a = d.Parent
				while a and a ~= gui do
					if decorated[a] or a.Name == "WorldDeco" then
						inside = true
						break
					end
					a = a.Parent
				end
				if not inside and not decorated[d] and isWindow(d) then
					decorate(d :: Frame, set)
				end
			end
		end
	end
end

local dt0 = 0
RunService.RenderStepped:Connect(function(dt)
	dt0 += dt
	for _, w in ipairs(wiggles) do
		local o = w.obj
		if o.Parent and o.Parent.Parent and (o.Parent.Parent :: GuiObject).Visible then
			if w.neon then
				w.neon.Transparency = 0.35 + 0.35 * math.sin(dt0 * 3 + w.phase)
			elseif w.fly then
				o.Position = w.base + UDim2.fromOffset(math.sin(dt0 * 0.9 + w.phase) * 40, math.sin(dt0 * 2.2 + w.phase) * 6)
				o.Rotation = math.sin(dt0 * 6 + w.phase) * 12
			else
				o.Rotation = math.sin(dt0 * 1.4 + w.phase) * 8
			end
		end
	end
end)

local function onWorld()
	theme = THEMES[player:GetAttribute("CurrentWorld") or ""]
	paintAll()
end

player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
playerGui.ChildAdded:Connect(function(g)
	task.wait(0.5) -- даём окну достроиться
	hook(g)
end)
task.wait(1)
theme = THEMES[player:GetAttribute("CurrentWorld") or ""]
for _, g in ipairs(playerGui:GetChildren()) do
	hook(g)
end
-- Некоторые окна пересобирают кнопки при открытии: докрашиваем, когда окно открылось или сменился мир
-- (раньше — раз в 2 секунды обходом всех окон, это давало подлагивания на телефонах).
local function refreshSoon()
	task.delay(0.25, function()
		if theme then
			paintAll()
		end
		decorAll()
	end)
end
player:GetAttributeChangedSignal("UIScreen"):Connect(refreshSoon)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(refreshSoon)
refreshSoon()
