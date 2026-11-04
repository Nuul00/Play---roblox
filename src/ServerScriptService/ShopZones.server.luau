-- Зона входа в магазин (ShopZone) раньше была отдельным полупрозрачным кругом шире подиума магазина —
-- рядом с «родным» светящимся кругом виднелся второй. Теперь у магазинов с подиумом (Plinth) зона
-- невидима и совпадает с подиумом один в один: магазин открывается, только когда игрок встал на него.
local world = workspace:WaitForChild("CoinSpeedWorld")

local function fit(zone: BasePart)
	local shop = zone.Parent
	local plinth = shop and shop:FindFirstChild("Plinth")
	if not (plinth and plinth:IsA("BasePart")) or zone:GetAttribute("Fitted") then
		return
	end
	zone:SetAttribute("Fitted", true)
	-- диск-цилиндр: ось — X детали (смотрит вверх), диаметр — Size.Y / Size.Z
	local top = plinth.Position + plinth.CFrame.RightVector.Unit * (plinth.Size.X / 2)
	if top.Y < plinth.Position.Y then
		top = plinth.Position - plinth.CFrame.RightVector.Unit * (plinth.Size.X / 2)
	end
	zone.Size = Vector3.new(0.3, plinth.Size.Y, plinth.Size.Z)
	zone.CFrame = CFrame.new(top + Vector3.new(0, 0.2, 0)) * plinth.CFrame.Rotation
	zone.Transparency = 1
	for _, d in ipairs(zone:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		elseif d:IsA("SurfaceGui") or d:IsA("ParticleEmitter") or d:IsA("Beam") then
			(d :: any).Enabled = false
		end
	end
end

local function scan()
	for _, d in ipairs(world:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "ShopZone" then
			fit(d)
		end
	end
end

task.wait(3)
scan()
-- миры, построенные позже (Sky, Frozen, Volcano, Galaxy), подхватываем тоже
world.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and d.Name == "ShopZone" then
		task.defer(fit, d)
	end
end)
task.delay(20, scan)
