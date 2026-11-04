-- Атмосфера миров: своя фоновая музыка у каждого мира (плавная смена при переходе)
-- и свой свет у Neon District и Frozen Peaks. Свет Sky Isles ставит SkyIslesFX,
-- а свет Meadow (с выбором времени суток в настройках) — GameHUD; здесь мы его только
-- запоминаем при уходе с луга и возвращаем при возвращении.
-- Музыка — лицензированные треки APM из библиотеки Roblox (можно использовать в играх).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local MUSIC_VOLUME = 0.3
local WORLDS = {
	["Meadow Isles"] = { music = 1836759150 }, -- Sunny Side Up
	["Neon District"] = {
		music = 1836646815, -- Electronic Night
		light = { ClockTime = 0.4, Brightness = 1.1, Ambient = Color3.fromRGB(60, 50, 105), OutdoorAmbient = Color3.fromRGB(80, 70, 140), ExposureCompensation = 0.1 },
		tint = { TintColor = Color3.fromRGB(240, 225, 255), Saturation = 0.15, Contrast = 0.05 },
	},
	["Sky Isles"] = { music = 1841593944 }, -- Enchanted Kingdom
	["Magma Volcano"] = {
		music = 1836646815, -- пока трек Неонграда; свой подберём
		light = { ClockTime = 18.3, Brightness = 1.6, Ambient = Color3.fromRGB(120, 60, 40), OutdoorAmbient = Color3.fromRGB(150, 80, 50), ExposureCompensation = 0.1 },
		tint = { TintColor = Color3.fromRGB(255, 232, 215), Saturation = 0.12, Contrast = 0.08 },
		atmosphere = { Density = 0.33, Haze = 1.4, Color = Color3.fromRGB(255, 140, 90), Decay = Color3.fromRGB(120, 40, 30) },
	},
	["Cosmic Galaxy"] = {
		music = 1841593944, -- пока трек Sky Isles; свой подберём
		light = { ClockTime = 0, Brightness = 1.2, Ambient = Color3.fromRGB(70, 60, 130), OutdoorAmbient = Color3.fromRGB(90, 80, 170), ExposureCompensation = 0.15 },
		tint = { TintColor = Color3.fromRGB(235, 230, 255), Saturation = 0.18, Contrast = 0.06 },
		atmosphere = { Density = 0.3, Haze = 0.4, Color = Color3.fromRGB(80, 60, 160), Decay = Color3.fromRGB(30, 20, 80) },
	},
	["Frozen Peaks"] = {
		music = 9046740461, -- Winter Holidays
		light = { ClockTime = 19.6, Brightness = 2.2, Ambient = Color3.fromRGB(125, 145, 190), OutdoorAmbient = Color3.fromRGB(150, 175, 220), ExposureCompensation = 0.15 },
		tint = { TintColor = Color3.fromRGB(228, 242, 255), Saturation = -0.05, Contrast = 0.06 },
		atmosphere = { Density = 0.28, Haze = 0.7, Color = Color3.fromRGB(175, 200, 240), Decay = Color3.fromRGB(120, 150, 220) },
	},
}
local LIGHT_KEYS = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation" }

------------------------------------------------------------------ музыка
local tracks = {}
for name, def in pairs(WORLDS) do
	local s = Instance.new("Sound")
	s.Name = "Music_" .. name:gsub(" ", "")
	s.SoundId = "rbxassetid://" .. def.music
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	tracks[name] = s
end
local playing: Sound? = nil
local function playMusic(world: string)
	local nextTrack = tracks[world]
	if nextTrack == playing then
		return
	end
	if playing then
		local old = playing
		local fade = TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 })
		fade.Completed:Connect(function()
			if old ~= playing then
				old:Pause()
			end
		end)
		fade:Play()
	end
	playing = nextTrack
	if nextTrack then
		if not nextTrack.IsPlaying then
			nextTrack:Play()
		end
		TweenService:Create(nextTrack, TweenInfo.new(1.5), { Volume = player:GetAttribute("MusicOff") and 0 or MUSIC_VOLUME }):Play()
	end
end
player:GetAttributeChangedSignal("MusicOff"):Connect(function()
	if playing then
		playing.Volume = player:GetAttribute("MusicOff") and 0 or MUSIC_VOLUME
	end
end)

------------------------------------------------------------------ свет
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "WorldAmbienceTint"
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "WorldAmbienceAtmosphere"
local hiddenAtmospheres = {}
local meadowLight = nil
local lastWorld = nil
local FADE = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function snapshot()
	local t = {}
	for _, k in ipairs(LIGHT_KEYS) do
		t[k] = (Lighting :: any)[k]
	end
	return t
end
local function applyLight(world: string)
	local def = WORLDS[world]
	if lastWorld == "Meadow Isles" and world ~= "Meadow Isles" then
		meadowLight = snapshot()
	end
	lastWorld = world
	if def and def.light then
		TweenService:Create(Lighting, FADE, def.light):Play()
		tint.TintColor = Color3.new(1, 1, 1)
		tint.Saturation = 0
		tint.Contrast = 0
		tint.Parent = Lighting
		TweenService:Create(tint, FADE, def.tint):Play()
		if def.atmosphere then
			-- Чужие атмосферы (например, базовую) прячем, пока мы в этом мире.
			for _, a in ipairs(Lighting:GetChildren()) do
				if a:IsA("Atmosphere") and a ~= atmosphere then
					hiddenAtmospheres[a] = true
					a.Parent = nil
				end
			end
			for k, v in pairs(def.atmosphere) do
				(atmosphere :: any)[k] = v
			end
			atmosphere.Parent = Lighting
		else
			atmosphere.Parent = nil
		end
	else
		tint.Parent = nil
		atmosphere.Parent = nil
		if world == "Meadow Isles" and meadowLight then
			TweenService:Create(Lighting, FADE, meadowLight):Play()
		end
	end
	if not (def and def.atmosphere) then
		for a in pairs(hiddenAtmospheres) do
			a.Parent = Lighting
		end
		table.clear(hiddenAtmospheres)
	end
end

local function onWorld()
	local world = player:GetAttribute("CurrentWorld") or "Meadow Isles"
	playMusic(world)
	-- Свет ставим чуть позже: SkyIslesFX при выходе из облаков сначала возвращает свой свет.
	task.delay(0.5, function()
		if (player:GetAttribute("CurrentWorld") or "Meadow Isles") == world then
			applyLight(world)
		end
	end)
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(onWorld)
task.delay(2, onWorld)

-- Проверка в Studio: загрузились ли треки.
if game:GetService("RunService"):IsStudio() then
	task.delay(8, function()
		for name, s in pairs(tracks) do
			print("[WorldAmbience]", name, s.IsLoaded and "loaded" or "NOT loaded", math.floor(s.TimeLength))
		end
	end)
end
