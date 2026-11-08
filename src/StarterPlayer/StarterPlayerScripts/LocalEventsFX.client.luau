-- Клиент локальных ивентов миров (Blossom Rain, Disco Fever, Star Fall, Lava Gold, Meteor Shower):
-- * заставка при старте: крупная картинка ивента и «x2 COINS» по центру, потом сворачивается в баннер;
-- * баннер с таймером и счётчиком «🌸 3/8», анонс за 30 с до начала;
-- * стрелки у краёв экрана на 3 ближайших бонуса (с расстоянием) — их легко найти;
-- * с неба падают маленькие картинки ивента (цветы, звёзды, метеориты...), лёгкий оттенок мира;
-- * подбор: вспышка, «+монеты» над бонусом и звук (только у того, кто подобрал).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local E = require(RS:WaitForChild("LocalEvents"))
local K = require(RS:WaitForChild("UIKit"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local okSounds, UISounds = pcall(require, RS:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local function sound(name)
	if okSounds then
		pcall(UISounds.Play, name)
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "LocalEventHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

------------------------------------------------------------------ баннер
local banner = K.frame(gui, UDim2.new(0.5, 0, 0, 132), UDim2.fromOffset(440, 62), Color3.new(1, 1, 1), 18)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Visible = false
local bGrad = K.grad(banner, rgb(255, 140, 200), rgb(140, 60, 120))
K.stroke(banner, K.INK, 3.5)
local bGloss = K.frame(banner, UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 18), Color3.new(1, 1, 1), 10)
bGloss.BackgroundTransparency = 0.75
local bIcon = Instance.new("ImageLabel")
bIcon.BackgroundTransparency = 1
bIcon.Position = UDim2.fromOffset(-14, -14)
bIcon.Size = UDim2.fromOffset(78, 78)
bIcon.Parent = banner
local bTitle = K.text(banner, "", UDim2.fromOffset(66, 4), UDim2.new(1, -170, 0, 30), 24, nil, 2.5)
bTitle.TextXAlignment = Enum.TextXAlignment.Left
local bSub = K.text(banner, "", UDim2.fromOffset(66, 34), UDim2.new(1, -170, 0, 20), 15, rgb(255, 245, 220), 1.5)
bSub.TextXAlignment = Enum.TextXAlignment.Left
local bTime = K.text(banner, "", UDim2.new(1, -100, 0, 8), UDim2.fromOffset(88, 46), 30, nil, 2.5)
local bScale = Instance.new("UIScale")
bScale.Parent = banner

-- 2026-11 (фидбэк): баннер можно свернуть в маленький значок (кнопка ▲ на баннере или ⚙ Settings).
-- Выбор сохраняется (Save_EventBanner = "mini"/"full"). Через 6 с после появления ивента — подсказка.
local GameAction = RS:WaitForChild("GameAction")
local function isMini()
	return player:GetAttribute("Save_EventBanner") == "mini"
end
local function setMini(on: boolean)
	player:SetAttribute("Save_EventBanner", on and "mini" or "full")
	GameAction:FireServer("eventbanner", on and "mini" or "full")
end
local hideBtn = Instance.new("TextButton")
hideBtn.Name = "Hide"
hideBtn.AnchorPoint = Vector2.new(0.5, 0.5)
hideBtn.Position = UDim2.new(1, -4, 0, 4)
hideBtn.Size = UDim2.fromOffset(30, 30)
hideBtn.BackgroundColor3 = rgb(40, 24, 60)
hideBtn.Text = "▲"
hideBtn.Font = Enum.Font.GothamBlack
hideBtn.TextSize = 14
hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.ZIndex = 5
hideBtn.Parent = banner
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(1, 0)
K.stroke(hideBtn, Color3.new(1, 1, 1), 2)
hideBtn.Activated:Connect(function()
	setMini(true)
	sound("click")
end)
-- мини-значок: иконка ивента + таймер, тап — развернуть обратно
local mini = Instance.new("ImageButton")
mini.Name = "EventMini"
mini.AnchorPoint = Vector2.new(0.5, 0)
mini.Position = UDim2.new(0.5, 0, 0, 132)
mini.Size = UDim2.fromOffset(120, 44)
mini.BackgroundColor3 = rgb(255, 140, 200)
mini.Visible = false
mini.Parent = gui
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 14)
K.stroke(mini, K.INK, 3)
local mIcon = Instance.new("ImageLabel")
mIcon.BackgroundTransparency = 1
mIcon.Position = UDim2.fromOffset(-8, -8)
mIcon.Size = UDim2.fromOffset(56, 56)
mIcon.Parent = mini
local mTime = K.text(mini, "", UDim2.fromOffset(46, 4), UDim2.fromOffset(70, 36), 22, nil, 2)
mTime.TextXAlignment = Enum.TextXAlignment.Left
local mScale = Instance.new("UIScale")
mScale.Parent = mini
mini.Activated:Connect(function()
	setMini(false)
	sound("click")
end)
-- подсказка: показывается 3 раза за всё время (Save_EventHintSeen), через 6 с после появления баннера
local tip = K.frame(gui, UDim2.new(0.5, 230, 0, 120), UDim2.fromOffset(250, 76), rgb(30, 22, 48), 14)
tip.AnchorPoint = Vector2.new(0, 0)
tip.Visible = false
K.stroke(tip, rgb(255, 210, 90), 2.5)
local tipText = K.text(tip, "", UDim2.fromOffset(10, 4), UDim2.new(1, -20, 1, -8), 15, nil, 1.5)
tipText.TextWrapped = true
tipText.RichText = true
tipText.Text = '<font color="#FFD25A">◀ Banner in the way?</font>\nTap ▲ to shrink it. Change it any time in ⚙ Settings.'
local tipScale = Instance.new("UIScale")
tipScale.Parent = tip
local tipShownAt = nil
local tipDoneThisEvent = false
-- Settings: переключатель там же, где музыка (GameHUD ищет кнопку по имени и вызывает это событие)
local bind = Instance.new("BindableFunction")
bind.Name = "EventBannerToggle"
bind.OnInvoke = function(toggle: boolean?)
	if toggle then
		setMini(not isMini())
	end
	return isMini()
end
bind.Parent = player:WaitForChild("PlayerGui")

------------------------------------------------------------------ заставка старта
local splash = Instance.new("Frame")
splash.BackgroundTransparency = 1
splash.AnchorPoint = Vector2.new(0.5, 0.5)
splash.Position = UDim2.fromScale(0.5, 0.38)
splash.Size = UDim2.fromOffset(520, 300)
splash.Visible = false
splash.Parent = gui
local sScale = Instance.new("UIScale")
sScale.Parent = splash
local sImg = Instance.new("ImageLabel")
sImg.BackgroundTransparency = 1
sImg.AnchorPoint = Vector2.new(0.5, 0)
sImg.Position = UDim2.fromScale(0.5, 0)
sImg.Size = UDim2.fromOffset(170, 170)
sImg.Parent = splash
local sTitle = K.text(splash, "", UDim2.fromOffset(0, 170), UDim2.new(1, 0, 0, 64), 56, nil, 4)
local sSub = K.text(splash, "COLLECT 6 / 12 / 18 FOR A COIN BONUS!", UDim2.fromOffset(0, 232), UDim2.new(1, 0, 0, 40), 30, K.GOLD, 3)

------------------------------------------------------------------ стрелки к бонусам
-- отдельный слой поверх HUD (иначе стрелку у края закрывают кнопки)
local pointerGui = Instance.new("ScreenGui")
pointerGui.Name = "LocalEventPointers"
pointerGui.ResetOnSpawn = false
pointerGui.DisplayOrder = 40
pointerGui.IgnoreGuiInset = true
pointerGui.Parent = player.PlayerGui
local pointers = {}
for i = 1, 3 do
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Size = UDim2.fromOffset(64, 64)
	f.Visible = false
	f.Parent = pointerGui
	local disc = K.frame(f, UDim2.fromScale(-0.1, -0.1), UDim2.fromScale(1.2, 1.2), Color3.new(1, 1, 1), UDim.new(1, 0))
	K.grad(disc, rgb(70, 40, 140), rgb(30, 16, 60))
	local discStroke = K.stroke(disc, K.GOLD, 3)
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Parent = f
	local arrow = K.text(f, "▲", UDim2.new(0.5, -14, 0, -26), UDim2.fromOffset(28, 26), 26, nil, 2)
	local dist = K.text(f, "", UDim2.new(0.5, -40, 1, -4), UDim2.fromOffset(80, 20), 15, nil, 2)
	pointers[i] = { f = f, img = img, arrow = arrow, dist = dist, stroke = discStroke }
end

------------------------------------------------------------------ падающие картинки
local rain = Instance.new("Part")
rain.Name = "LocalEventRain"
rain.Anchored = true
rain.CanCollide = false
rain.CanQuery = false
rain.CanTouch = false
rain.Transparency = 1
rain.Size = Vector3.new(110, 1, 110)
local emitter = Instance.new("ParticleEmitter")
emitter.EmissionDirection = Enum.NormalId.Bottom
emitter.Speed = NumberRange.new(6, 11)
emitter.Lifetime = NumberRange.new(4, 6)
emitter.Rate = 0
emitter.LightEmission = 0.3
emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0.8) })
emitter.Rotation = NumberRange.new(0, 360)
emitter.RotSpeed = NumberRange.new(-90, 90)
emitter.SpreadAngle = Vector2.new(20, 20)
emitter.Acceleration = Vector3.new(2, 0, 1)
emitter.Parent = rain
local sparkle = emitter:Clone()
sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
sparkle.LightEmission = 1
sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2) })
sparkle.Parent = rain
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "LocalEventTint"
tint.Enabled = false

------------------------------------------------------------------ бонусы: покачивание
local spinning = {}
local function track(m)
	if not m:IsA("Model") then
		return
	end
	task.spawn(function()
		local core = m:WaitForChild("Core", 5)
		task.wait(0.2)
		if core and m.Parent then
			m.PrimaryPart = core
			spinning[m] = core.CFrame
		end
	end)
end
CollectionService:GetInstanceAddedSignal("LocalEventPickup"):Connect(track)
CollectionService:GetInstanceRemovedSignal("LocalEventPickup"):Connect(function(m)
	spinning[m] = nil
end)
for _, m in ipairs(CollectionService:GetTagged("LocalEventPickup")) do
	track(m)
end

------------------------------------------------------------------ подбор
local function floatText(pos: Vector3, txt: string, color: Color3)
	local a = Instance.new("Part")
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.Transparency = 1
	a.Size = Vector3.one
	a.Position = pos + Vector3.new(0, 3, 0)
	a.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 60)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = a
	local l = K.text(bb, txt, UDim2.new(), UDim2.fromScale(1, 1), 40, color, 3)
	Tween:Create(a, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = a.Position + Vector3.new(0, 6, 0) }):Play()
	Tween:Create(l, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	task.delay(1.3, function()
		a:Destroy()
	end)
end
task.spawn(function()
	local holder = workspace:WaitForChild("CoinSpeedWorld"):WaitForChild("LocalEventPickups", 60)
	if not holder then
		return
	end
	holder:GetAttributeChangedSignal("LastPickup"):Connect(function()
		local pos = holder:GetAttribute("LastPickup")
		if typeof(pos) ~= "Vector3" then
			return
		end
		local color = holder:GetAttribute("LastPickupColor") or rgb(255, 220, 120)
		local a = Instance.new("Part")
		a.Anchored = true
		a.CanCollide = false
		a.CanQuery = false
		a.Transparency = 1
		a.Size = Vector3.one
		a.Position = pos
		a.Parent = workspace
		local burst = sparkle:Clone()
		burst.EmissionDirection = Enum.NormalId.Top
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Speed = NumberRange.new(10, 24)
		burst.Lifetime = NumberRange.new(0.6, 1)
		burst.Acceleration = Vector3.new(0, -20, 0)
		burst.Color = ColorSequence.new(color)
		burst.Parent = a
		burst:Emit(40)
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Brightness = 5
		l.Color = color
		l.Parent = a
		Tween:Create(l, TweenInfo.new(0.7), { Brightness = 0 }):Play()
		task.delay(1.4, function()
			a:Destroy()
		end)
		if holder:GetAttribute("LastPickupBy") == player.UserId then
			floatText(pos, tostring(holder:GetAttribute("LastPickupAmount") or 0) .. "/" .. E.Cap, color:Lerp(Color3.new(1, 1, 1), 0.4))
			sound("reward")
		end
	end)
end)

------------------------------------------------------------------ цикл
local shownKey = nil
local wasActive = false
local t = 0
Run.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	local uiScale = cam and math.clamp(cam.ViewportSize.X / 900, 0.6, 1) or 1
	local worldName = player:GetAttribute("CurrentWorld")
	local def = worldName and not player:GetAttribute("InRush") and E.Worlds[worldName] or nil -- в Coin Rush ивенты мира не показываем
	local now = workspace:GetServerTimeNow()
	local left = def and ((workspace:GetAttribute(E.AttrEnd(worldName)) or 0) - now) or 0
	local active = def ~= nil and left > 0
	local soon = def and not active and (E.NextStart(worldName, now) - now) or math.huge
	local show = (active or soon <= 30) and (player:GetAttribute("UIScreen") or "") == ""

	-- заставка при старте
	if active and not wasActive and left > E.Duration - 5 then
		splash.Visible = true
		sImg.Image = def.Image or ""
		sTitle.Text = def.Icon .. " " .. def.Name .. "!"
		sTitle.TextColor3 = def.Color:Lerp(Color3.new(1, 1, 1), 0.25)
		sScale.Scale = 0.2
		Tween:Create(sScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = uiScale }):Play()
		sound("rare")
		task.delay(2.6, function()
			Tween:Create(sScale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
			task.delay(0.32, function()
				splash.Visible = false
			end)
		end)
	end
	wasActive = active
	if splash.Visible then
		sImg.Rotation = math.sin(t * 3) * 8
	end

	-- баннер
	if show then
		local key = def.Key .. (active and "on" or "soon")
		if shownKey ~= key then
			shownKey = key
			banner.Visible = true
			bIcon.Image = def.Image or ""
			bGrad.Color = ColorSequence.new(def.Color, def.Color:Lerp(rgb(30, 16, 60), 0.45))
			bScale.Scale = 0.6
			Tween:Create(bScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = uiScale }):Play()
		end
		bIcon.Rotation = math.sin(t * 2.5) * 10
		if active then
			bTitle.Text = def.Name .. "!"
			local got = player:GetAttribute("EventPickups") or 0
			-- 2026-11: бонус после ивента за 6/12/18 собранных
			local nextTier = nil
			for _, tr in ipairs(E.Tiers) do
				if got < tr.Need then
					nextTier = tr
					break
				end
			end
			local cur = E.TierFor(got)
			bSub.Text = def.Icon .. " " .. got .. "/" .. E.Cap .. (nextTier and string.format(" · %d → x%g", nextTier.Need, nextTier.Mult) or "") .. (cur and string.format(" · after: x%g", cur.Mult) or "")
			bTime.Text = string.format("%d:%02d", math.floor(left / 60), math.floor(left) % 60)
			bTime.TextColor3 = left <= 10 and (math.sin(t * 10) > 0 and rgb(255, 120, 120) or Color3.new(1, 1, 1)) or Color3.new(1, 1, 1)
		else
			bTitle.Text = def.Name .. " soon"
			bSub.Text = string.format("collect %s %d/%d/%d → x%g/x%g/x%g coins", def.Icon, E.Tiers[1].Need, E.Tiers[2].Need, E.Tiers[3].Need, E.Tiers[1].Mult, E.Tiers[2].Mult, E.Tiers[3].Mult)
			bTime.Text = string.format("%d:%02d", math.floor(soon / 60), math.floor(soon) % 60)
			bTime.TextColor3 = def.Color2
		end
		-- свёрнутый режим: вместо баннера — маленький значок с таймером
		local miniOn = isMini()
		banner.Visible = not miniOn
		mini.Visible = miniOn
		if miniOn then
			mIcon.Image = def.Image or ""
			mIcon.Rotation = bIcon.Rotation
			mini.BackgroundColor3 = def.Color
			mTime.Text = bTime.Text
			mScale.Scale = uiScale
		end
		-- подсказка через 6 с после появления (3 раза за всё время, раз за ивент)
		if not miniOn and not tipDoneThisEvent and (player:GetAttribute("Save_EventHintSeen") or 0) < 3 then
			tipShownAt = tipShownAt or (os.clock() + 6)
			if os.clock() >= tipShownAt and not tip.Visible then
				tip.Visible = true
				tipScale.Scale = uiScale
				GameAction:FireServer("eventhintseen")
				task.delay(7, function()
					tip.Visible = false
				end)
				tipDoneThisEvent = true
			end
		end
		if tip.Visible then
			-- справа от баннера, стрелка ◀ указывает на кнопку ▲
			local abs = banner.AbsolutePosition + banner.AbsoluteSize
			local vw = cam and cam.ViewportSize.X or 1000
			local tw = tip.AbsoluteSize.X
			if abs.X + 10 + tw > vw - 8 then
				-- не влезает справа — под баннером
				tip.Position = UDim2.fromOffset(math.max(8, abs.X - tw), abs.Y + 6)
			else
				tip.Position = UDim2.fromOffset(abs.X + 10, banner.AbsolutePosition.Y - 4)
			end
			if miniOn then
				tip.Visible = false
			end
		end
	elseif shownKey then
		shownKey = nil
		banner.Visible = false
		mini.Visible = false
		tip.Visible = false
		tipShownAt = nil
		tipDoneThisEvent = false
	end

	-- падающие картинки и оттенок
	if active and cam then
		if rain.Parent ~= workspace then
			rain.Parent = workspace
			emitter.Texture = def.Image or "rbxasset://textures/particles/sparkles_main.dds"
			sparkle.Color = ColorSequence.new(def.Color, def.Color2)
			tint.TintColor = Color3.new(1, 1, 1):Lerp(def.Color, 0.12)
			tint.Saturation = 0.08
			tint.Parent = Lighting
			tint.Enabled = true
		end
		emitter.Rate = 9
		sparkle.Rate = 25
		rain.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 34, 0))
	elseif rain.Parent then
		emitter.Rate = 0
		sparkle.Rate = 0
		rain.Parent = nil
		tint.Enabled = false
		tint.Parent = nil
	end

	-- стрелки у краёв экрана на ближайшие бонусы своего мира
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local list = {}
	if active and root and cam and (player:GetAttribute("UIScreen") or "") == "" then
		for m, base in pairs(spinning) do
			if m.Parent and m:GetAttribute("World") == worldName then
				table.insert(list, { pos = base.Position, d = (base.Position - root.Position).Magnitude })
			end
		end
		table.sort(list, function(a, b)
			return a.d < b.d
		end)
	end
	for i, ptr in ipairs(pointers) do
		local item = list[i]
		local vis = false
		if item and cam and item.d > 12 then
			local sp, onScreen = cam:WorldToViewportPoint(item.pos)
			local vp = cam.ViewportSize
			-- рамка, по которой ездят стрелки: внутри неё нет кнопок HUD (слева плитки, снизу панель)
			local L, R = 190 * uiScale, vp.X - 120 * uiScale
			local T, B = 120 * uiScale, vp.Y - 170 * uiScale
			local inside = onScreen and sp.X > L and sp.X < R and sp.Y > T and sp.Y < B
			if not inside then
				-- направление на бонус от центра рамки; если он сзади — разворачиваем
				local c = Vector2.new((L + R) / 2, (T + B) / 2)
				local dir = Vector2.new(sp.X, sp.Y) - c
				if sp.Z < 0 then
					dir = -dir
				end
				if dir.Magnitude < 1 then
					dir = Vector2.new(0, 1)
				end
				local sx = ((R - L) / 2) / math.max(math.abs(dir.X), 1e-3)
				local sy = ((B - T) / 2) / math.max(math.abs(dir.Y), 1e-3)
				local p = c + dir * math.min(sx, sy)
				ptr.f.Position = UDim2.fromOffset(p.X, p.Y)
				ptr.arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
				ptr.arrow.Position = UDim2.new(0.5, -14 + dir.Unit.X * 40, 0.5, -13 + dir.Unit.Y * 40)
				ptr.img.Image = def.Image or ""
				ptr.stroke.Color = def.Color
				ptr.dist.Text = math.floor(item.d) .. " m"
				ptr.f.Size = UDim2.fromOffset(56 * uiScale, 56 * uiScale)
				vis = true
			end
		end
		ptr.f.Visible = vis
	end

	-- покачивание бонусов
	for m, base in pairs(spinning) do
		if m.Parent then
			m:PivotTo(base * CFrame.new(0, math.sin(t * 2.5 + base.Position.X) * 0.5, 0))
		else
			spinning[m] = nil
		end
	end
end)
