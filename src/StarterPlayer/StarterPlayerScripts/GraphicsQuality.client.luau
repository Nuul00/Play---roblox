-- Качество графики из настроек (Save_Graphics: auto / low / medium / ultra). Фидбэк 2026-11:
-- переключатель должен давать ЗАМЕТНУЮ разницу сразу, без перезахода:
--   LOW    — частицы ×0.35, облегчённые эффекты миров (FxBudget low), без лучей и размытия;
--   MEDIUM — частицы ×0.7, средние эффекты миров;
--   ULTRA  — все частицы, полные эффекты миров, лучи солнца (SunRays) и лёгкое размытие дали.
-- AUTO — как решит FxBudget (телефон / настройка Roblox / FPS). Уровень эффектов миров (небо Galaxy,
-- сияние, лава) берётся из FxBudget, а он учитывает этот выбор (полностью — после перезахода).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local FxBudget = require(game:GetService("ReplicatedStorage"):WaitForChild("FxBudget"))

local PRESET = {
	low = { shadows = false, bloom = 0, sunRays = false, dof = false, grass = false, particles = 0.35 },
	medium = { shadows = true, bloom = 1, sunRays = false, dof = false, grass = true, particles = 0.7 },
	ultra = { shadows = true, bloom = 1.35, sunRays = true, dof = true, grass = true, particles = 1 },
}
local AUTO_FROM_TIER = { low = "low", mid = "medium", high = "ultra" }

-- свои эффекты (не трогаем чужие Bloom/ColorCorrection миров, кроме общего Bloom)
local sunRays = Lighting:FindFirstChild("GfxSunRays") or Instance.new("SunRaysEffect")
sunRays.Name = "GfxSunRays"
sunRays.Intensity = 0.06
sunRays.Spread = 0.6
sunRays.Parent = Lighting
local dof = Lighting:FindFirstChild("GfxDepthOfField") or Instance.new("DepthOfFieldEffect")
dof.Name = "GfxDepthOfField"
dof.FarIntensity = 0.12
dof.FocusDistance = 120
dof.InFocusRadius = 80
dof.NearIntensity = 0
dof.Parent = Lighting

local current = PRESET.ultra
local function scaleEmitter(e: ParticleEmitter)
	local base = e:GetAttribute("GfxBaseRate")
	if base == nil then
		base = e.Rate
		e:SetAttribute("GfxBaseRate", base)
	end
	e.Rate = base * current.particles
end

local function apply()
	local mode = player:GetAttribute("Save_Graphics") or "auto"
	if mode == "auto" or not PRESET[mode] then
		mode = AUTO_FROM_TIER[FxBudget.Tier()] or "medium"
	end
	current = PRESET[mode]
	-- 2026-11 (фидбэк): свечение (Bloom) и общие тени больше не трогаем — без Bloom неоновые фонари
	-- превращались в слепящие белые шары, а сохранённая «база» Bloom обнуляла свечение на MEDIUM/ULTRA.
	-- Свечением управляет DayNight, тенями — плейс. Если прошлая версия успела их испортить — возвращаем.
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom and bloom:GetAttribute("GfxBase") ~= nil then
		bloom.Enabled = true
		if bloom.Intensity == 0 then
			bloom.Intensity = math.max(bloom:GetAttribute("GfxBase"), 0.4)
		end
		bloom:SetAttribute("GfxBase", nil)
	end
	Lighting.GlobalShadows = true
	sunRays.Enabled = current.sunRays
	dof.Enabled = current.dof
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			scaleEmitter(d)
		end
	end
end

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ParticleEmitter") and current.particles < 1 then
		task.defer(scaleEmitter, d)
	end
end)
player:GetAttributeChangedSignal("Save_Graphics"):Connect(apply)
FxBudget.Changed:Connect(apply)
task.delay(3, apply) -- после загрузки профиля и миров
