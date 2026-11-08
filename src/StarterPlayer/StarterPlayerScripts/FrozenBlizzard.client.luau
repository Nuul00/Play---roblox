-- Мини-ивент Frozen Peaks «Метель» на клиенте: баннер с таймером, густой снег с сильным ветром,
-- кристаллы-бонусы мерцают и вращаются, при подборе — вспышка. Сервер: FrozenEvent.server.luau.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
-- кристаллы метели: список держим по сигналам, а не запрашиваем каждый кадр
local crystals = {}
for _, m in ipairs(CollectionService:GetTagged("FrostCrystal")) do
	crystals[m] = true
end
CollectionService:GetInstanceAddedSignal("FrostCrystal"):Connect(function(m)
	crystals[m] = true
end)
CollectionService:GetInstanceRemovedSignal("FrostCrystal"):Connect(function(m)
	crystals[m] = nil
end)

local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")
local frozen = world:WaitForChild("FrozenPeaks", 120)
if not frozen then
	return
end

-- ===== Баннер =====
local gui = Instance.new("ScreenGui")
gui.Name = "BlizzardHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 70)
banner.Size = UDim2.fromOffset(420, 64)
banner.BackgroundColor3 = Color3.fromRGB(40, 90, 170)
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 18)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(220, 245, 255)
stroke.Parent = banner
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(40, 80, 180))
grad.Rotation = 90
grad.Parent = banner
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 4)
title.Size = UDim2.new(1, -28, 0, 32)
title.Font = Enum.Font.FredokaOne
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "❄ BLIZZARD! x2 COINS ❄"
title.Parent = banner
local tStroke = Instance.new("UIStroke")
tStroke.Thickness = 2
tStroke.Color = Color3.fromRGB(20, 50, 120)
tStroke.Parent = title
local sub = title:Clone()
sub.Position = UDim2.fromOffset(14, 36)
sub.Size = UDim2.new(1, -28, 0, 22)
sub.Text = ""
sub.TextColor3 = Color3.fromRGB(210, 240, 255)
sub.Parent = banner
local pop = Instance.new("UIScale")
pop.Parent = banner
-- 2026-11: баннер можно свернуть (общая настройка Save_EventBanner, как у остальных ивентов):
-- в свёрнутом виде остаётся узкая полоска с таймером, тап по ней — развернуть
local fullSize, miniSize = UDim2.fromOffset(420, 64), UDim2.fromOffset(150, 34)
local hideBtn = Instance.new("TextButton")
hideBtn.AnchorPoint = Vector2.new(0.5, 0.5)
hideBtn.Position = UDim2.new(1, -4, 0, 4)
hideBtn.Size = UDim2.fromOffset(28, 28)
hideBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 120)
hideBtn.Text = "▲"
hideBtn.Font = Enum.Font.GothamBlack
hideBtn.TextSize = 13
hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.ZIndex = 5
hideBtn.Parent = banner
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(1, 0)
local expand = Instance.new("TextButton")
expand.BackgroundTransparency = 1
expand.Text = ""
expand.Size = UDim2.fromScale(1, 1)
expand.ZIndex = 6
expand.Parent = banner
local function blizzMini()
	return player:GetAttribute("Save_EventBanner") == "mini"
end
local function applyBlizzMini()
	local m = blizzMini()
	banner.Size = m and miniSize or fullSize
	hideBtn.Visible = not m
	expand.Visible = m
	sub.Visible = not m
	title.Size = m and UDim2.new(1, -16, 1, -8) or UDim2.new(1, -28, 0, 32)
	title.Position = m and UDim2.fromOffset(8, 4) or UDim2.fromOffset(14, 4)
end
local function toggleBlizz()
	local b = player.PlayerGui:FindFirstChild("EventBannerToggle")
	if b then
		b:Invoke(true)
	end
end
hideBtn.Activated:Connect(toggleBlizz)
expand.Activated:Connect(toggleBlizz)
player:GetAttributeChangedSignal("Save_EventBanner"):Connect(applyBlizzMini)
applyBlizzMini()

-- ===== Вспышка при подборе кристалла =====
local folder = frozen:WaitForChild("BlizzardCrystals", 60)
if folder then
	folder:GetAttributeChangedSignal("LastPickup"):Connect(function()
		local pos = folder:GetAttribute("LastPickup")
		if typeof(pos) ~= "Vector3" then
			return
		end
		local a = Instance.new("Part")
		a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch = true, false, false, false
		a.Transparency = 1
		a.Size = Vector3.new(1, 1, 1)
		a.Position = pos
		a.Parent = workspace
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(170, 230, 255), Color3.new(1, 1, 1))
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		e.Lifetime = NumberRange.new(0.6, 1.2)
		e.Speed = NumberRange.new(10, 18)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Drag = 3
		e.Rate = 0
		e.Parent = a
		e:Emit(50)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(150, 220, 255)
		l.Range = 20
		l.Brightness = 6
		l.Parent = a
		TweenService:Create(l, TweenInfo.new(0.8), { Brightness = 0 }):Play()
		task.delay(1.5, function()
			a:Destroy()
		end)
	end)
end

-- ===== Цикл =====
local active = false
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local left = (workspace:GetAttribute("FrozenStormEnd") or 0) - workspace:GetServerTimeNow()
	local inFrozen = player:GetAttribute("CurrentWorld") == "Frozen Peaks"
	local storm = left > 0 and inFrozen
	if storm ~= active then
		active = storm
		gui.Enabled = storm
		if storm then
			pop.Scale = 0.5
			TweenService:Create(pop, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end
	-- снег FrozenFX: в метель гуще и с сильным ветром
	local emitterPart = workspace:FindFirstChild("FrozenSnowEmitter")
	if emitterPart then
		for _, e in ipairs(emitterPart:GetChildren()) do
			if e:IsA("ParticleEmitter") then
				local base = e:GetAttribute("BaseRate")
				if not base then
					base = e.Rate
					e:SetAttribute("BaseRate", base)
				end
				e.Rate = storm and base * 1.8 or base
				if storm then
					local acc = e.Acceleration
					e.Acceleration = Vector3.new(14 * math.sin(t * 0.4), acc.Y, 10 * math.cos(t * 0.33))
				end
			end
		end
	end
	if storm then
		sub.Text = string.format("Frost crystals fall! · %d s left", math.ceil(left))
		title.Text = blizzMini() and string.format("❄ %ds", math.ceil(left)) or "❄ BLIZZARD! x2 COINS ❄"
		stroke.Transparency = 0.2 + 0.3 * math.sin(t * 5)
		for m in pairs(crystals) do
			local core = m.PrimaryPart
			if core then
				local base = m:GetAttribute("BaseCF")
				if not base then
					base = core.CFrame
					m:SetAttribute("BaseCF", base)
				end
				m:PivotTo(base * CFrame.new(0, math.sin(t * 2 + base.Position.X) * 0.4, 0) * CFrame.Angles(0, t * 1.5, 0))
			end
		end
	end
end)
