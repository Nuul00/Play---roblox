-- 3D-монеты Frozen Peaks из Tripo (ReplicatedStorage.TripoProps/CoinIce, CoinCrystal, CoinAurora).
-- Серверная монета остаётся (сбор, видимость), а на клиенте поверх неё крутится модель Tripo;
-- сам диск прячем через LocalTransparencyModifier. Модель видна, только пока монета доступна.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local props = ReplicatedStorage:WaitForChild("TripoProps", 30)
local world = workspace:WaitForChild("CoinSpeedWorld")
local frozen = world:WaitForChild("FrozenPeaks", 60)
if not (props and frozen) then
	return
end

local KIND = { Ice = "CoinIce", Crystal = "CoinCrystal", Aurora = "CoinAurora" }
local coins = {}

local function attach(part: BasePart)
	local template = props:FindFirstChild(KIND[part:GetAttribute("Kind") or ""] or "")
	if not template then
		return
	end
	local m = template:Clone()
	local _, ext = m:GetBoundingBox()
	local d = math.max(part.Size.Y, part.Size.Z) * 1.15
	m:ScaleTo(m:GetScale() * d / math.max(ext.X, ext.Y, ext.Z, 0.01))
	local bb = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bb.Position)
	local parts = {}
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
			table.insert(parts, p)
		end
	end
	m.Parent = part
	part.LocalTransparencyModifier = 1
	local entry = { part = part, model = m, parts = parts, phase = math.random() * 6 }
	local function sync()
		local visible = part.Transparency < 1
		for _, p in ipairs(parts) do
			p.LocalTransparencyModifier = visible and 0 or 1
		end
	end
	part:GetPropertyChangedSignal("Transparency"):Connect(sync)
	sync()
	table.insert(coins, entry)
end

task.defer(function()
	task.wait(2)
	for _, c in ipairs(frozen:GetChildren()) do
		if c:IsA("BasePart") and string.match(c.Name, "^Coin_%d+$") then
			attach(c)
		end
	end
end)

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	if player == nil then
		return
	end
end)

-- Вращение и лёгкое парение — только в Frozen Peaks и 20 раз в секунду.
local acc = 0
local player = game:GetService("Players").LocalPlayer
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.05 or player:GetAttribute("CurrentWorld") ~= "Frozen Peaks" then
		return
	end
	acc = 0
	for _, e in ipairs(coins) do
		if e.part.Transparency < 1 then
			local p = e.part.Position
			e.model:PivotTo(CFrame.new(p + Vector3.new(0, math.sin(t * 2 + e.phase) * 0.3, 0)) * CFrame.Angles(0, t * 1.8 + e.phase, 0))
		end
	end
end)
