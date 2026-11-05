-- Крутит и покачивает 3D-эмблемы над досками лидеров (тег BoardEmblem, атрибуты Spin °/с и Bob studs).
-- Только вблизи камеры, чтобы не тратить кадр на далёкие миры.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local items = {}
local function add(p)
	if p:IsA("BasePart") then
		items[p] = { base = p.CFrame, spin = p:GetAttribute("Spin") or 0, bob = p:GetAttribute("Bob") or 0.35 }
	end
end
for _, p in CollectionService:GetTagged("BoardEmblem") do add(p) end
CollectionService:GetInstanceAddedSignal("BoardEmblem"):Connect(add)
CollectionService:GetInstanceRemovedSignal("BoardEmblem"):Connect(function(p) items[p] = nil end)

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if not cam then return end
	local cp = cam.CFrame.Position
	for p, d in items do
		if not p.Parent then items[p] = nil continue end
		if (d.base.Position - cp).Magnitude < 180 then
			local y = math.sin(t * 2) * d.bob
			p.CFrame = CFrame.new(d.base.Position + Vector3.new(0, y, 0)) * CFrame.Angles(0, math.rad(d.spin * t), 0) * d.base.Rotation
		end
	end
end)
