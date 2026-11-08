-- Качество графики (Settings → Graphics: AUTO / LOW / MEDIUM / ULTRA). Фидбэк 2026-11: «как в настоящих
-- играх» — каждый уровень заметно меняет картинку, основные анимации (персонажи, питомцы, монеты, UI)
-- не трогаются, меняется «поверхностное»:
--   LOW    — фонари мира не светят (лампы матовые, без света), деревья не качаются, листья не падают,
--            фонари не мерцают, частиц втрое меньше, эффекты миров упрощены;
--   MEDIUM — светит каждый второй фонарь, деревья качаются, фонари мерцают, без листопада, частиц меньше;
--   ULTRA  — светит всё, всё шевелится, листопад, все частицы, мягкое свечение неона, лучи солнца и
--            лёгкое размытие дали.
-- Деревья/листопад/мерцание — WorldLife.client (по FxBudget.Level), небо Galaxy, сияние и лава — по
-- FxBudget (эти полностью — после перезахода). AUTO выбирает уровень по устройству и FPS.
-- GraphicsInfo (BindableFunction в PlayerGui) отдаёт окну настроек описание текущего уровня.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local FxBudget = require(game:GetService("ReplicatedStorage"):WaitForChild("FxBudget"))
local world = workspace:WaitForChild("CoinSpeedWorld")

local PRESET = {
	low = { lights = 0, particles = 0.35, glow = false, sunRays = false, dof = false },
	medium = { lights = 0.5, particles = 0.7, glow = false, sunRays = false, dof = false },
	ultra = { lights = 1, particles = 1, glow = true, sunRays = true, dof = true },
}
local INFO = {
	low = "LOW: lamps off · trees still · fewer particles · simple effects",
	medium = "MEDIUM: some lamps glow · trees sway · lamps flicker",
	ultra = "ULTRA: all lamps glow · falling leaves · sun rays · full effects",
}
local AUTO_FROM_TIER = { low = "low", mid = "medium", high = "ultra" }

-- свои эффекты (Bloom мира не трогаем: им управляет DayNight)
local function effect(class: string, name: string)
	local e = Lighting:FindFirstChild(name) or Instance.new(class)
	e.Name = name
	e.Parent = Lighting
	return e
end
local sunRays = effect("SunRaysEffect", "GfxSunRays")
sunRays.Intensity = 0.06
sunRays.Spread = 0.6
local dof = effect("DepthOfFieldEffect", "GfxDepthOfField")
dof.FarIntensity = 0.12
dof.FocusDistance = 120
dof.InFocusRadius = 80
dof.NearIntensity = 0
local glow = effect("BloomEffect", "GfxGlow") -- мягкое свечение неона только на ULTRA
glow.Intensity = 0.35
glow.Threshold = 0.92
glow.Size = 18

local mode = "ultra"
local current = PRESET.ultra

-- ===== фонари мира: свет + «лампа» (неоновая деталь, в которой этот свет) =====
local lamps = {} -- { light, part, neon = был ли Neon, idx }
local seen = {}
local function addLamp(l: Instance)
	if seen[l] or not (l:IsA("PointLight") or l:IsA("SpotLight") or l:IsA("SurfaceLight")) then
		return
	end
	local part = l.Parent
	-- только неподвижные детали мира (как в WorldLife): не питомцы, не монеты, не эффекты
	if not (part and part:IsA("BasePart") and part.Anchored) or string.find(part.Name, "^Coin_") or part:FindFirstAncestor("Pets") then
		return
	end
	seen[l] = true
	table.insert(lamps, { light = l, part = part, neon = part.Material == Enum.Material.Neon, idx = #lamps + 1 })
end
local function applyLamp(rec)
	local on
	if current.lights >= 1 then
		on = true
	elseif current.lights <= 0 then
		on = false
	else
		on = rec.idx % 2 == 0 -- каждый второй
	end
	-- свет: выключаем мы; включаем только если мы же его выключали (DayNight сам гасит днём)
	if not on then
		if rec.light.Enabled then
			rec.light.Enabled = false
			rec.offByGfx = true
		end
	elseif rec.offByGfx then
		rec.light.Enabled = true
		rec.offByGfx = false
	end
	-- лампа: при выключенном свете — матовая (не светится)
	if rec.neon and rec.part.Parent then
		local want = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		if rec.part.Material ~= want then
			rec.part.Material = want
		end
	end
end

-- ===== частицы =====
local function scaleEmitter(e: ParticleEmitter)
	local base = e:GetAttribute("GfxBaseRate")
	if base == nil then
		base = e.Rate
		e:SetAttribute("GfxBaseRate", base)
	end
	e.Rate = base * current.particles
end

local function apply()
	mode = player:GetAttribute("Save_Graphics") or "auto"
	if mode == "auto" or not PRESET[mode] then
		mode = AUTO_FROM_TIER[FxBudget.Tier()] or "medium"
	end
	current = PRESET[mode]
	-- прошлая версия могла обнулить Bloom мира и выключить тени — возвращаем как было
	local bloom = Lighting:FindFirstChild("Bloom")
	if bloom and bloom:IsA("BloomEffect") and bloom:GetAttribute("GfxBase") ~= nil then
		bloom.Enabled = true
		bloom:SetAttribute("GfxBase", nil)
	end
	Lighting.GlobalShadows = true
	glow.Enabled = current.glow
	sunRays.Enabled = current.sunRays
	dof.Enabled = current.dof
	for _, rec in ipairs(lamps) do
		applyLamp(rec)
	end
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			scaleEmitter(d)
		end
	end
end

local info = Instance.new("BindableFunction")
info.Name = "GraphicsInfo"
info.OnInvoke = function()
	return INFO[mode] or ""
end
info.Parent = player:WaitForChild("PlayerGui")

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ParticleEmitter") and current.particles < 1 then
		task.defer(scaleEmitter, d)
	elseif d:IsDescendantOf(world) and (d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight")) then
		task.defer(function()
			addLamp(d)
			if seen[d] then
				applyLamp(lamps[#lamps])
			end
		end)
	end
end)
player:GetAttributeChangedSignal("Save_Graphics"):Connect(apply)
player:GetAttributeChangedSignal("TimeOfDay"):Connect(function()
	task.delay(1.5, apply) -- DayNight включает фонари вечером/ночью — повторяем выбор уровня
end)
FxBudget.Changed:Connect(apply)
task.delay(3, function()
	for _, d in ipairs(world:GetDescendants()) do
		addLamp(d)
	end
	apply()
end)
