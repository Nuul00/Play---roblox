-- Время суток и небо (только у этого игрока).
-- Режим берётся из атрибута игрока TimeOfDay ("Day" / "Evening" / "Night"), его ставят кнопки в Settings (GameHUD).
-- Мир берётся из атрибута CurrentWorld. В Neon District всегда своё неоновое небо и свет.
-- Небо лежит в ReplicatedStorage.WorldSkies: "Meadow Day", "Meadow Isles" (вечер), "Meadow Night", "Neon District".
-- Важно: Roblox затемняет любой скайбокс ночью (ClockTime около 0), поэтому ночь сделана так:
-- ночное звёздное небо + время 14:00 + тёмный голубоватый свет. Иначе вместо звёзд было бы чёрное небо.
-- 2026-11: скрипт перенесён из плейса в src (Rojo); пресеты Day/Evening приглушены (фидбэк «пересвет»).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local skies = ReplicatedStorage:WaitForChild("WorldSkies")
local world = Workspace:WaitForChild("CoinSpeedWorld")
local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
local baseBloom = bloom and bloom.Intensity or 0

local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "DayNightTint"
tint.Parent = Lighting

local BLACK = Color3.new(0, 0, 0)
local PRESETS = {
	Day = {
		Sky = "Meadow Day",
		ClockTime = 13,
		Brightness = 2.1, -- было 2.6 / 110 / 140
		Ambient = Color3.fromRGB(82, 82, 92),
		OutdoorAmbient = Color3.fromRGB(118, 118, 128),
		Exposure = 0,
		ColorShiftTop = BLACK,
		Tint = Color3.new(1, 1, 1),
		Saturation = 0,
		Contrast = 0,
		Lamps = "off",
		Fireflies = 0.4,
	},
	Evening = { -- закатное небо (по умолчанию)
		Sky = "Meadow Isles",
		ClockTime = 13,
		Brightness = 1.7, -- было 1.98 и окружающий свет 127 — картинку заливало серым
		Ambient = Color3.fromRGB(72, 72, 82),
		OutdoorAmbient = Color3.fromRGB(108, 108, 118),
		Exposure = -0.05,
		ColorShiftTop = BLACK,
		Tint = Color3.new(1, 1, 1),
		Saturation = 0,
		Contrast = 0.04,
		Lamps = "dim",
		Fireflies = 1,
	},
	Night = {
		Sky = "Meadow Night",
		ClockTime = 14,
		Brightness = 0.2,
		Ambient = Color3.fromRGB(38, 42, 75),
		OutdoorAmbient = Color3.fromRGB(45, 52, 95),
		Exposure = -0.15,
		ColorShiftTop = Color3.fromRGB(120, 140, 220),
		Tint = Color3.fromRGB(190, 200, 255),
		Saturation = -0.2,
		Contrast = 0.08,
		Lamps = "on",
		Fireflies = 2.5,
	},
	Neon = { -- Neon District не зависит от времени суток
		Sky = "Neon District",
		ClockTime = 18.3,
		Brightness = 1.4,
		Ambient = Color3.fromRGB(95, 80, 140),
		OutdoorAmbient = Color3.fromRGB(110, 95, 165),
		Exposure = 0,
		ColorShiftTop = BLACK,
		Tint = Color3.fromRGB(215, 205, 255),
		Saturation = 0,
		Contrast = 0,
		Bloom = 0.7,
	},
}

-- ===== Фонари острова =====
-- Светится сама лампа (Neon + Bloom даёт мягкий ореол), PointLight освещает всё вокруг,
-- а SpotLight вниз рисует на дорожке пятно тёплого света.
local LAMP = {
	off = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(225, 220, 205), light = false, brightness = 0, range = 0, spot = 0 },
	dim = { material = Enum.Material.Neon, color = Color3.fromRGB(255, 205, 140), light = true, brightness = 1.6, range = 20, spot = 2 },
	on = { material = Enum.Material.Neon, color = Color3.fromRGB(255, 190, 110), light = true, brightness = 2.6, range = 26, spot = 4 },
}
local lamps = {}
local function collectLamps()
	for _, model in ipairs(world:GetChildren()) do
		local bulb = model.Name == "StreetLamp" and model:FindFirstChild("Light")
		if bulb and bulb:IsA("BasePart") and not lamps[model] then
			local spot = Instance.new("SpotLight")
			spot.Name = "LampSpot"
			spot.Face = Enum.NormalId.Bottom
			spot.Angle = 110
			spot.Range = 16
			spot.Shadows = false
			spot.Enabled = false
			spot.Parent = bulb
			lamps[model] = { bulb = bulb, light = bulb:FindFirstChildOfClass("PointLight"), spot = spot }
		end
	end
end

local lampState
local lampVersion = 0
local function setLamp(lamp, s)
	lamp.bulb.Material = s.material
	lamp.bulb.Color = s.color
	if lamp.light then
		lamp.light.Enabled = s.light
		lamp.light.Brightness = s.brightness
		lamp.light.Range = s.range
		lamp.light.Color = s.color
	end
	lamp.spot.Enabled = s.light
	lamp.spot.Brightness = s.spot
	lamp.spot.Color = s.color
end
local function setLamps(stateName, animate)
	collectLamps()
	if stateName == lampState then
		return
	end
	local wasOff = lampState == nil or lampState == "off"
	lampState = stateName
	lampVersion += 1
	local version = lampVersion
	local s = LAMP[stateName]
	for _, lamp in pairs(lamps) do
		if animate and wasOff and stateName ~= "off" then
			-- фонари загораются не все сразу и чуть мигают, как настоящие
			task.delay(math.random() * 0.8, function()
				for _, step in ipairs({ "dim", "off", "dim", "off" }) do
					if version ~= lampVersion then
						return
					end
					setLamp(lamp, LAMP[step])
					task.wait(0.05 + math.random() * 0.07)
				end
				if version == lampVersion then
					setLamp(lamp, s)
				end
			end)
		else
			setLamp(lamp, s)
		end
	end
end

-- ===== Светлячки (эффекты острова из IslandLife); громкость звуков природы считает сам IslandLife =====
local function setNature(p)
	local fx = Workspace:FindFirstChild("IslandLifeFX")
	if not fx then
		return
	end
	for _, e in ipairs(fx:GetDescendants()) do
		if e:IsA("ParticleEmitter") and e.Parent.Name == "FireflyZone" then
			local base = e:GetAttribute("BaseRate")
			if not base then
				base = e.Rate
				e:SetAttribute("BaseRate", base)
			end
			e.Rate = base * (p.Fireflies or 1)
		end
	end
end

-- ===== Применение =====
local function setSky(name)
	local template = skies:FindFirstChild(name)
	if not template then
		warn("[DayNight] Нет неба " .. name .. " в ReplicatedStorage.WorldSkies")
		return
	end
	local current = Lighting:FindFirstChildOfClass("Sky")
	if current and current.Name == name then
		return
	end
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end
	template:Clone().Parent = Lighting
end

local applied
local function apply(animate)
	local worldName = player:GetAttribute("CurrentWorld") or "Meadow Isles"
	local mode = player:GetAttribute("TimeOfDay")
	if not PRESETS[mode] or mode == "Neon" then
		mode = "Evening"
	end
	local key = worldName == "Neon District" and "Neon" or mode
	if key == applied then
		return
	end
	applied = key
	local p = PRESETS[key]
	setSky(p.Sky)
	local goal = {
		ClockTime = p.ClockTime,
		Brightness = p.Brightness,
		Ambient = p.Ambient,
		OutdoorAmbient = p.OutdoorAmbient,
		ExposureCompensation = p.Exposure,
		ColorShift_Top = p.ColorShiftTop,
	}
	local tintGoal = { TintColor = p.Tint, Saturation = p.Saturation, Contrast = p.Contrast }
	if animate and key ~= "Neon" then
		local info = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		goal.ClockTime = nil -- время ставим сразу, иначе солнце «проезжает» по небу
		Lighting.ClockTime = p.ClockTime
		TweenService:Create(Lighting, info, goal):Play()
		TweenService:Create(tint, info, tintGoal):Play()
	else
		for k, v in pairs(goal) do
			Lighting[k] = v
		end
		for k, v in pairs(tintGoal) do
			tint[k] = v
		end
	end
	if bloom then
		bloom.Intensity = p.Bloom or baseBloom
	end
	if key ~= "Neon" then
		setLamps(p.Lamps, animate)
		setNature(p)
	end
end

player:GetAttributeChangedSignal("TimeOfDay"):Connect(function()
	apply(true)
end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
	apply(false)
end)
-- IslandLife создаёт светлячков чуть позже: досинхронизируем их.
Workspace.ChildAdded:Connect(function(child)
	if child.Name == "IslandLifeFX" and applied and applied ~= "Neon" then
		task.defer(setNature, PRESETS[applied])
	end
end)
apply(false)
