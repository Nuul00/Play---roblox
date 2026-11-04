-- Жизнь в окнах Neon District: свет в квартирах гаснет и включается, где-то притухает,
-- задёргиваются шторы, за стеклом проходит тень человека (иногда останавливается и машет).
-- Только на клиенте и только пока игрок в Neon District; живут не все окна, а примерно треть.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity")

local LIVE_SHARE = 0.35
local MAX_LIVE = 220
local NEAR = 320

local CURTAINS = {
	Color3.fromRGB(255, 120, 170),
	Color3.fromRGB(150, 110, 255),
	Color3.fromRGB(255, 170, 90),
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(255, 90, 120),
}

local FACE = {
	X = { [1] = Enum.NormalId.Right, [-1] = Enum.NormalId.Left },
	Y = { [1] = Enum.NormalId.Top, [-1] = Enum.NormalId.Bottom },
	Z = { [1] = Enum.NormalId.Back, [-1] = Enum.NormalId.Front },
}

local function tween(obj, time, props, style)
	local tw = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), props)
	tw:Play()
	return tw
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in pairs(props) do
		(f :: any)[k] = v
	end
	f.Parent = parent
	return f
end

-- Накладка на окно: тонкая невидимая деталь чуть снаружи стекла с SurfaceGui (шторы и тень).
local function overlay(win: BasePart, center: Vector3)
	local s = win.Size
	local axis, thin = "X", s.X
	if s.Y < thin then
		axis, thin = "Y", s.Y
	end
	if s.Z < thin then
		axis, thin = "Z", s.Z
	end
	local dir = (axis == "X" and win.CFrame.RightVector) or (axis == "Y" and win.CFrame.UpVector) or -win.CFrame.LookVector
	local out = win.Position - center
	local sign = dir:Dot(out) >= 0 and 1 or -1
	local part = Instance.new("Part")
	part.Name = "WindowLife"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Transparency = 1
	part.Size = s
	part.CFrame = win.CFrame + dir * sign * (thin / 2 + 0.04)
	local gui = Instance.new("SurfaceGui")
	gui.Face = FACE[axis][sign]
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.PixelsPerStud = 40
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.ClipsDescendants = true
	gui.Parent = part

	local color = CURTAINS[math.random(#CURTAINS)]
	local function curtain(left)
		local c = frame(gui, {
			AnchorPoint = Vector2.new(left and 0 or 1, 0),
			Position = UDim2.fromScale(left and 0 or 1, 0),
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.15,
		})
		local g = Instance.new("UIGradient")
		-- складки ткани
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(200, 200, 200)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(200, 200, 200)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		})
		g.Parent = c
		return c
	end
	local left, right = curtain(true), curtain(false)

	-- Тень человека: голова и плечи, тёмные и полупрозрачные.
	local person = frame(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(-0.3, 1.05),
		Size = UDim2.fromScale(0.42, 0.78),
		BackgroundTransparency = 1,
	})
	local body = frame(person, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 0.55),
		BackgroundColor3 = Color3.fromRGB(10, 6, 20),
		BackgroundTransparency = 1,
	})
	Instance.new("UICorner", body).CornerRadius = UDim.new(0.45, 0)
	local head = frame(person, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromScale(0.5, 0.42),
		BackgroundColor3 = Color3.fromRGB(10, 6, 20),
		BackgroundTransparency = 1,
	})
	Instance.new("UICorner", head).CornerRadius = UDim.new(1, 0)
	local arm = frame(person, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.86, 0.62),
		Size = UDim2.fromScale(0.18, 0.5),
		BackgroundColor3 = Color3.fromRGB(10, 6, 20),
		BackgroundTransparency = 1,
		Rotation = 15,
	})
	Instance.new("UICorner", arm).CornerRadius = UDim.new(1, 0)
	part.Parent = workspace
	return { part = part, left = left, right = right, person = person, shadow = { body, head }, arm = arm }
end

local live = {}
local active = false

local function setLight(w, k, time)
	tween(w.win, time or 0.25, { Color = w.base:Lerp(Color3.fromRGB(8, 6, 16), 1 - k) })
end

local function showPerson(w, alpha)
	for _, p in ipairs(w.fx.shadow) do
		tween(p, 0.4, { BackgroundTransparency = alpha })
	end
	tween(w.fx.arm, 0.4, { BackgroundTransparency = alpha })
end

local function closeCurtains(w, closed)
	local size = UDim2.fromScale(closed and 0.52 or 0, 1)
	tween(w.fx.left, 1.4, { Size = size })
	tween(w.fx.right, 1.4, { Size = size })
end

-- Одна «история» в окне, выбранная случайно.
local function story(w)
	local r = math.random()
	if r < 0.22 then
		-- свет выключили и через время включили
		setLight(w, 0, 0.15)
		task.wait(4 + math.random() * 8)
		setLight(w, 1, 0.15)
	elseif r < 0.38 then
		-- свет притух (ночник), потом снова ярко
		setLight(w, 0.45, 1.5)
		task.wait(5 + math.random() * 6)
		setLight(w, 1, 1.5)
	elseif r < 0.62 then
		-- задёрнули шторы, свет мягче, за шторой тень
		closeCurtains(w, true)
		setLight(w, 0.6, 1.4)
		task.wait(1.6)
		if math.random() < 0.6 then
			w.fx.person.Position = UDim2.fromScale(0.35 + math.random() * 0.3, 1.05)
			showPerson(w, 0.55)
			task.wait(2 + math.random() * 3)
			showPerson(w, 1)
		end
		task.wait(3 + math.random() * 6)
		closeCurtains(w, false)
		setLight(w, 1, 1.4)
		task.wait(1.4)
	else
		-- человек проходит мимо окна, иногда останавливается и машет
		local fromLeft = math.random() < 0.5
		local p = w.fx.person
		p.Position = UDim2.fromScale(fromLeft and -0.3 or 1.3, 1.05)
		showPerson(w, 0.12)
		local stop = math.random() < 0.5
		if stop then
			tween(p, 1.6, { Position = UDim2.fromScale(0.5, 1.05) }).Completed:Wait()
			for _ = 1, 3 do
				tween(w.fx.arm, 0.22, { Rotation = 45 }).Completed:Wait()
				tween(w.fx.arm, 0.22, { Rotation = 0 }).Completed:Wait()
			end
			task.wait(0.6)
			tween(p, 1.6, { Position = UDim2.fromScale(fromLeft and 1.3 or -0.3, 1.05) }).Completed:Wait()
		else
			tween(p, 3, { Position = UDim2.fromScale(fromLeft and 1.3 or -0.3, 1.05) }, Enum.EasingStyle.Linear).Completed:Wait()
		end
		showPerson(w, 1)
	end
end

local function runner(w)
	task.wait(math.random() * 10)
	while true do
		if active and w.win.Parent then
			local cam = workspace.CurrentCamera
			if cam and (cam.CFrame.Position - w.win.Position).Magnitude < NEAR then
				if not w.fx then
					w.fx = overlay(w.win, w.center)
				end
				story(w)
			end
		end
		task.wait(3 + math.random() * 9)
	end
end

task.defer(function()
	task.wait(4)
	for _, b in ipairs(city:GetDescendants()) do
		if b:IsA("Model") and string.match(b.Name, "^Building_%d+$") then
			local cf = b:GetBoundingBox()
			for _, w in ipairs(b:GetChildren()) do
				if w:IsA("BasePart") and w.Name == "Window" and #live < MAX_LIVE and math.random() < LIVE_SHARE then
					local entry = { win = w, base = w.Color, center = cf.Position }
					table.insert(live, entry)
					task.spawn(runner, entry)
				end
			end
		end
	end
end)

local function onWorld()
	active = player:GetAttribute("CurrentWorld") == "Neon District"
	for _, w in ipairs(live) do
		if w.fx then
			w.fx.part.Parent = active and workspace or nil
		end
	end
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
onWorld()
