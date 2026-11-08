-- Живое сияние у клиента: магниты в руке парят и покачиваются над рукоятью (тег "MagnetGlow",
-- MagnetVisuals), свет магнитов и порталов (тег "PortalGlow", PortalDecor) мягко пульсирует.
-- Каждый клиент анимирует все магниты, которые видит, поэтому движение видно у всех игроков.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local MAX_DISTANCE = 140

local magnets = {}
local portals = {}

local function track(list, inst, extra)
	if list[inst] then
		return
	end
	local entry = extra(inst)
	if entry then
		entry.phase = math.random() * 6
		list[inst] = entry
	end
end

local function magnetEntry(core)
	local weld = core:FindFirstChild("FloatWeld")
	return { weld = weld, base = weld and weld.C0, light = core:FindFirstChild("Glow"), brightness = core:GetAttribute("BaseBrightness") or 1.2 }
end
local function portalEntry(aperture)
	return { light = aperture:FindFirstChildWhichIsA("PointLight"), brightness = aperture:GetAttribute("BaseBrightness") or 1.4 }
end

for _, core in ipairs(CollectionService:GetTagged("MagnetGlow")) do
	track(magnets, core, magnetEntry)
end
CollectionService:GetInstanceAddedSignal("MagnetGlow"):Connect(function(core)
	track(magnets, core, magnetEntry)
end)
CollectionService:GetInstanceRemovedSignal("MagnetGlow"):Connect(function(core)
	magnets[core] = nil
end)
for _, a in ipairs(CollectionService:GetTagged("PortalGlow")) do
	track(portals, a, portalEntry)
end
CollectionService:GetInstanceAddedSignal("PortalGlow"):Connect(function(a)
	track(portals, a, portalEntry)
end)
CollectionService:GetInstanceRemovedSignal("PortalGlow"):Connect(function(a)
	portals[a] = nil
end)

-- Вращающиеся кольца: бусины в проёме портала (PortalSwirl) и кольца на подиумах яиц (PedestalRing).
local spinners = {}
local function addSpinner(m, kind)
	if m:IsA("Model") then
		spinners[m] = { base = m.WorldPivot, kind = kind, phase = math.random() * 6 }
	end
end
for _, kind in ipairs({ "PortalSwirl", "PedestalRing" }) do
	for _, m in ipairs(CollectionService:GetTagged(kind)) do
		addSpinner(m, kind)
	end
	CollectionService:GetInstanceAddedSignal(kind):Connect(function(m)
		addSpinner(m, kind)
	end)
	CollectionService:GetInstanceRemovedSignal(kind):Connect(function(m)
		spinners[m] = nil
	end)
end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local camera = workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position or Vector3.zero
	for core, m in pairs(magnets) do
		-- В рюкзаке и в витрине магазина (ViewportFrame) не анимируем.
		if core.Parent and core:IsDescendantOf(workspace) and (core.Position - eye).Magnitude < MAX_DISTANCE then
			local a = t + m.phase
			if m.weld and m.weld.Parent then
				m.weld.C0 = m.base * CFrame.new(0, 0.12 + math.sin(a * 2.4) * 0.12, 0) * CFrame.Angles(0, math.sin(a * 1.3) * 0.35, math.sin(a * 1.7) * 0.06)
			end
			if m.light then
				m.light.Brightness = m.brightness * (0.75 + 0.35 * math.sin(a * 3))
			end
		end
	end
	for m, s in pairs(spinners) do
		if m.Parent and (s.base.Position - eye).Magnitude < 220 then
			if s.kind == "PortalSwirl" then
				m:PivotTo(s.base * CFrame.Angles(0, 0, t * 1.4))
			else
				m:PivotTo(s.base * CFrame.new(0, math.sin(t * 1.5 + s.phase) * 0.4, 0) * CFrame.Angles(0, t * 0.8, 0))
			end
		end
	end
	for aperture, p in pairs(portals) do
		if p.light and aperture.Parent and (aperture.Position - eye).Magnitude < 260 then
			p.light.Brightness = p.brightness * (0.7 + 0.3 * math.sin(t * 1.6 + p.phase))
		end
	end
end)
