-- Модель подковообразного магнита: для инструмента в руке и для витрины магазина.
-- Корень — деталь "Handle" (рукоять). Остальные детали приварены к ней WeldConstraint.
local ShopConfig = require(script.Parent:WaitForChild("ShopConfig"))

local MagnetVisuals = {}

function MagnetVisuals.Build(tier: number): Model
	local def = ShopConfig.Magnets[tier] or ShopConfig.Magnets[1]
	local model = Instance.new("Model")
	model.Name = def.Name
	local function piece(name, size, cf, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.CFrame = cf
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local bodyMat = def.Glow and Enum.Material.Neon or (tier == 3 and Enum.Material.Foil or Enum.Material.SmoothPlastic)
	local handle = piece("Handle", Vector3.new(0.45, 1.1, 0.45), CFrame.identity, Color3.fromRGB(45, 40, 40), Enum.Material.SmoothPlastic)
	-- Дуга подковы из 7 сегментов, открытая вверх (по +Y), над рукоятью.
	local radius = 0.9
	local center = Vector3.new(0, 1.55, 0)
	for i = 0, 6 do
		local a = math.pi + i / 6 * math.pi
		local pos = center + Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
		piece("Arc", Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos) * CFrame.Angles(0, 0, a), def.Body, bodyMat)
	end
	for _, side in ipairs({ -1, 1 }) do
		piece("Arm", Vector3.new(0.5, 0.9, 0.5), CFrame.new(center + Vector3.new(side * radius, 0.45, 0)), def.Body, bodyMat)
		piece("Tip", Vector3.new(0.52, 0.42, 0.52), CFrame.new(center + Vector3.new(side * radius, 1.1, 0)), def.Tip, Enum.Material.Metal)
	end
	if def.Glow then
		local light = Instance.new("PointLight")
		light.Color = def.Body
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = handle
	end
	for _, p in ipairs(model:GetChildren()) do
		if p ~= handle and p:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
		end
	end
	model.PrimaryPart = handle
	return model
end

return MagnetVisuals
