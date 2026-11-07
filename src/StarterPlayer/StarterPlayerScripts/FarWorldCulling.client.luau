-- Прячет на клиенте мир Sky Isles, пока игрок не в нём (фидбэк 2026-11: «мусор в небе» над Meadow —
-- это острова Sky Isles в ~700 студах, StreamingEnabled выключен). Детали получают
-- LocalTransparencyModifier = 1, частицы/свет/билборды выключаются; при входе в Sky всё возвращается.
-- Серверу и другим скриптам мир виден как раньше (ничего не переносим и не удаляем).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

local HIDE_WHEN_NOT_IN = { SkyIsles = "Sky Isles" }

local saved = {} -- [instance] = прежнее Enabled (для эффектов)
local hiddenRoots = {} -- [root] = DescendantAdded-соединение

local function hideOne(d: Instance)
	if d:IsA("BasePart") then
		d.LocalTransparencyModifier = 1
	elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Light") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
		if saved[d] == nil then
			saved[d] = (d :: any).Enabled
		end
		(d :: any).Enabled = false
	end
end

local function hide(root: Instance)
	if hiddenRoots[root] then
		return
	end
	hiddenRoots[root] = root.DescendantAdded:Connect(hideOne)
	for i, d in ipairs(root:GetDescendants()) do
		hideOne(d)
		if i % 2000 == 0 then
			task.wait()
		end
	end
end

local function show(root: Instance)
	local conn = hiddenRoots[root]
	if not conn then
		return
	end
	conn:Disconnect()
	hiddenRoots[root] = nil
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 0
		elseif saved[d] ~= nil then
			(d :: any).Enabled = saved[d]
			saved[d] = nil
		end
	end
end

local function update()
	local current = player:GetAttribute("CurrentWorld") or "Meadow Isles"
	for name, worldName in pairs(HIDE_WHEN_NOT_IN) do
		local root = world:FindFirstChild(name)
		if root then
			if current == worldName then
				show(root)
			else
				hide(root)
			end
		end
	end
end

player:GetAttributeChangedSignal("CurrentWorld"):Connect(update)
world.ChildAdded:Connect(function(c)
	if HIDE_WHEN_NOT_IN[c.Name] then
		update()
	end
end)
update()
