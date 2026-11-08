-- Приглушает облачный портал Неонграда (раньше он выжигал экран в белый) и держит
-- подпись в актуальном виде. Работает из кода, поэтому не зависит от правок в самом месте.
local world = workspace:WaitForChild("CoinSpeedWorld")
local city = world:WaitForChild("NeonCity", 60)
local portal = city and city:WaitForChild("CloudPortal", 30)
if not portal then
	return
end

local function style(d)
	if portal:GetAttribute("Dressed") and (d:IsA("BasePart") or d:FindFirstAncestor("CloudGateModel")) then
		return -- стоит 3D-модель (PortalModels.server), старые облака спрятаны
	end
	if d:IsA("BasePart") then
		if d.Name:find("Cloud") and d.Name ~= "CloudSign" then
			d.Material = Enum.Material.SmoothPlastic
			d.Color = Color3.fromRGB(176, 192, 232)
		elseif d.Name == "Swirl" then
			d.Material = Enum.Material.SmoothPlastic
			d.Color = Color3.fromRGB(150, 170, 235)
			d.Transparency = 0.8
		end
	elseif d:IsA("PointLight") or d:IsA("SpotLight") then
		d.Brightness = math.min(d.Brightness, 0.25)
		d.Range = math.min(d.Range, 14)
	elseif d:IsA("TextLabel") and d.Text:upper():find("SKY ISLES") then
		d.Text = "SKY ISLES · SPEED 6"
	end
end
for _, d in ipairs(portal:GetDescendants()) do
	style(d)
end
portal.DescendantAdded:Connect(style)
