-- Качество графики из настроек (Save_Graphics: auto / low / medium / ultra). Фидбэк 2026-11:
-- переключатель должен давать ЗАМЕТНУЮ разницу сразу, без перезахода:
--   LOW    — без теней, без свечения (Bloom), частицы ×0.35;
--   MEDIUM — тени, мягкое свечение, частицы ×0.7;
--   ULTRA  — тени, сильное свечение, лучи солнца (SunRays), лёгкое размытие дали, все частицы.
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
	Lighting.GlobalShadows = current.shadows
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		local base = bloom:GetAttribute("GfxBase")
		if base == nil then
			base = bloom.Intensity
			bloom:SetAttribute("GfxBase", base)
		end
		bloom.Enabled = current.bloom > 0
		bloom.Intensity = base * current.bloom
	end
	sunRays.Enabled = current.sunRays
	dof.Enabled = current.dof
	pcall(function()
		workspace.Terrain.Decoration = current.grass
	end)
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
