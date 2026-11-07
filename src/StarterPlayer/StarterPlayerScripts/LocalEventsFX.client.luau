-- Клиент локальных ивентов миров (Blossom Rain, Disco Fever, Star Fall, Lava Gold, Meteor Shower):
-- баннер с таймером под плашкой мировых событий, анонс за 30 с до начала, падающие частицы
-- в цветах ивента вокруг камеры, вращение бонусов и вспышка при подборе.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local E = require(RS:WaitForChild("LocalEvents"))
local K = require(RS:WaitForChild("UIKit"))
local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local gui = Instance.new("ScreenGui")
gui.Name = "LocalEventHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14
gui.Parent = player:WaitForChild("PlayerGui")

-- баннер ивента
local banner = K.frame(gui, UDim2.new(0.5, 0, 0, 72), UDim2.fromOffset(420, 58), Color3.new(1, 1, 1), 18)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Visible = false
local bGrad = K.grad(banner, rgb(255, 140, 200), rgb(140, 60, 120))
K.stroke(banner, K.INK, 3.5)
local bGloss = K.frame(banner, UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 18), Color3.new(1, 1, 1), 10)
bGloss.BackgroundTransparency = 0.75
local bTitle = K.text(banner, "", UDim2.fromOffset(14, 3), UDim2.new(1, -110, 0, 30), 24, nil, 2.5)
bTitle.TextXAlignment = Enum.TextXAlignment.Left
local bSub = K.text(banner, "", UDim2.fromOffset(14, 32), UDim2.new(1, -110, 0, 20), 15, rgb(255, 245, 220), 1.5)
bSub.TextXAlignment = Enum.TextXAlignment.Left
local bTime = K.text(banner, "", UDim2.new(1, -96, 0, 8), UDim2.fromOffset(84, 42), 30, nil, 2.5)
local bScale = Instance.new("UIScale")
bScale.Parent = banner

-- падающие частицы вокруг камеры
local rain = Instance.new("Part")
rain.Name = "LocalEventRain"
rain.Anchored = true
rain.CanCollide = false
rain.CanQuery = false
rain.CanTouch = false
rain.Transparency = 1
rain.Size = Vector3.new(90, 1, 90)
local emitter = Instance.new("ParticleEmitter")
emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
emitter.EmissionDirection = Enum.NormalId.Bottom
emitter.Speed = NumberRange.new(8, 14)
emitter.Lifetime = NumberRange.new(3, 5)
emitter.Rate = 0
emitter.LightEmission = 0.8
emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.3) })
emitter.Rotation = NumberRange.new(0, 360)
emitter.RotSpeed = NumberRange.new(-120, 120)
emitter.SpreadAngle = Vector2.new(25, 25)
emitter.Parent = rain

-- бонусы крутятся и покачиваются (только визуально)
local spinning = {}
local function track(m)
	if not m:IsA("Model") then
		return
	end
	-- детали модели приходят с сервера не сразу: ждём «ядро», иначе центр = (0,0,0) и бонус улетает
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

-- вспышка при подборе
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
		local a = Instance.new("Part")
		a.Anchored = true
		a.CanCollide = false
		a.CanQuery = false
		a.Transparency = 1
		a.Size = Vector3.one
		a.Position = pos
		a.Parent = workspace
		local burst = emitter:Clone()
		burst.EmissionDirection = Enum.NormalId.Top
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Speed = NumberRange.new(10, 22)
		burst.Lifetime = NumberRange.new(0.6, 1)
		burst.Color = ColorSequence.new(holder:GetAttribute("LastPickupColor") or rgb(255, 220, 120))
		burst.Parent = a
		burst:Emit(36)
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Brightness = 5
		l.Color = holder:GetAttribute("LastPickupColor") or rgb(255, 220, 120)
		l.Parent = a
		Tween:Create(l, TweenInfo.new(0.7), { Brightness = 0 }):Play()
		task.delay(1.4, function()
			a:Destroy()
		end)
	end)
end)

local shownKey = nil
local t = 0
Run.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if cam then
		bScale.Scale = math.clamp(cam.ViewportSize.X / 900, 0.6, 1)
	end
	local worldName = player:GetAttribute("CurrentWorld")
	local def = worldName and E.Worlds[worldName]
	local now = workspace:GetServerTimeNow()
	local left = def and ((workspace:GetAttribute(E.AttrEnd(worldName)) or 0) - now) or 0
	local active = def ~= nil and left > 0
	local soon = def and not active and (E.NextStart(worldName, now) - now) or math.huge
	local show = active or soon <= 30
	if show then
		local key = def.Key .. (active and "on" or "soon")
		if shownKey ~= key then
			shownKey = key
			banner.Visible = true
			bGrad.Color = ColorSequence.new(def.Color, def.Color:Lerp(rgb(30, 16, 60), 0.45))
			bScale.Scale = 0.6
			Tween:Create(bScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = cam and math.clamp(cam.ViewportSize.X / 900, 0.6, 1) or 1 }):Play()
		end
		if active then
			bTitle.Text = def.Icon .. " " .. def.Name .. "!"
			bSub.Text = "x2 coins · grab the " .. def.Item
			bTime.Text = string.format("%d:%02d", math.floor(left / 60), math.floor(left) % 60)
			bTime.TextColor3 = Color3.new(1, 1, 1)
		else
			bTitle.Text = def.Icon .. " " .. def.Name .. " soon"
			bSub.Text = "x2 coins in this world"
			bTime.Text = string.format("%d:%02d", math.floor(soon / 60), math.floor(soon) % 60)
			bTime.TextColor3 = def.Color2
		end
	elseif shownKey then
		shownKey = nil
		banner.Visible = false
	end
	-- частицы над камерой
	if active and cam then
		if rain.Parent ~= workspace then
			rain.Parent = workspace
			emitter.Color = ColorSequence.new(def.Color, def.Color2)
		end
		emitter.Rate = 60
		rain.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 30, 0))
	elseif rain.Parent then
		emitter.Rate = 0
		rain.Parent = nil
	end
	-- вращение бонусов
	for m, base in pairs(spinning) do
		if m.Parent then
			m:PivotTo(base * CFrame.new(0, math.sin(t * 2.5 + base.Position.X) * 0.5, 0) * CFrame.Angles(0, t * 2, 0))
		else
			spinning[m] = nil
		end
	end
end)
