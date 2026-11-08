-- Coin Rush, фаза босса (фидбэк 2026-11): магнит держат двумя руками перед собой и целятся им
-- в босса, как оружием. Атрибуты ставит CoinRush.server: RushAim (true) и RushAimAt (Vector3 босса).
-- Поза рисуется поверх анимации ходьбы для всех таких игроков (у себя видно и чужих).
-- Свой персонаж всё время поворачивается лицом к боссу (ходить можно, бежать боком).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local cache = setmetatable({}, { __mode = "k" })
local function joints(char: Model)
	local c = cache[char]
	if c then
		return c
	end
	c = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
			c[d.Name] = d
		end
	end
	cache[char] = c
	return c
end

local t = 0
local wasAiming = false
RunService.Stepped:Connect(function(_, dt)
	t += dt
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char and p:GetAttribute("RushAim") == true then
			local j = joints(char)
			local sway = math.sin(t * 2) * 0.03 -- лёгкое покачивание прицела
			if j.RightShoulder then -- R15
				-- правая рука вытянута вперёд, левая тянется к магниту снизу
				j.RightShoulder.Transform = CFrame.Angles(math.pi / 2 + sway, 0, -0.45)
				if j.RightElbow then
					j.RightElbow.Transform = CFrame.Angles(0.1, 0, 0)
				end
				if j.LeftShoulder then
					j.LeftShoulder.Transform = CFrame.Angles(math.pi / 2 + sway, 0, 1.2)
				end
				if j.LeftElbow then
					j.LeftElbow.Transform = CFrame.Angles(0.3, 0, 0)
				end
			elseif j["Right Shoulder"] then -- R6: ось плечевого сустава — Z
				j["Right Shoulder"].Transform = CFrame.Angles(0, 0, math.pi / 2 + sway)
				if j["Left Shoulder"] then
					j["Left Shoulder"].Transform = CFrame.Angles(0, 0, -math.pi / 2 + 0.3)
				end
			end
		end
	end
	-- свой персонаж: лицом к боссу
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local aim = player:GetAttribute("RushAimAt")
	local aiming = player:GetAttribute("RushAim") == true and typeof(aim) == "Vector3" and hum and root
	if aiming then
		hum.AutoRotate = false
		local pos = root.Position
		local look = Vector3.new(aim.X, pos.Y, aim.Z)
		if (look - pos).Magnitude > 1 then
			root.CFrame = CFrame.lookAt(pos, look)
		end
	elseif wasAiming and hum then
		hum.AutoRotate = true
	end
	wasAiming = aiming and true or false
end)
