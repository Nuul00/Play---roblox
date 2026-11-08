-- Каток Frozen Peaks: на льду (атрибут OnIce ставит WorldPolish.server и надевает коньки)
-- персонаж катается — разгоняется плавно, по инерции скользит, когда отпустил кнопки,
-- слегка наклоняется в повороты, а из-под коньков летит ледяная крошка.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local vel = Vector3.zero
local spray: ParticleEmitter? = nil
local lean = 0

local function sprayFor(root: BasePart)
	if spray and spray.Parent == root then
		return spray
	end
	local a = Instance.new("Attachment")
	a.Name = "SkateSprayAt"
	a.Position = Vector3.new(0, -2.8, 0.4)
	a.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.Name = "SkateSpray"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255), Color3.fromRGB(170, 220, 255))
	e.LightEmission = 0.5
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.Speed = NumberRange.new(3, 6)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Back
	e.Acceleration = Vector3.new(0, -12, 0)
	e.Rate = 0
	e.Parent = a
	spray = e
	return e
end

RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum) then
		return
	end
	-- только на самом льду катка (фидбэк 2026-11: ледяная крошка продолжала лететь на снегу)
	local onIce = player:GetAttribute("OnIce") == true and hum.FloorMaterial == Enum.Material.Ice
	if not onIce then
		vel = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		if spray and spray.Rate > 0 then
			spray.Rate = 0
			spray:Clear()
		end
		if lean ~= 0 then
			lean = 0
			hum.CameraOffset = Vector3.zero
		end
		return
	end
	-- на катке своя скорость: не больше 26, сколько бы ни было прокачано (иначе вылетаешь за бортик)
	local want = hum.MoveDirection * math.min(hum.WalkSpeed, 26)
	-- разгон медленный, торможение ещё медленнее: лёд
	local k = want.Magnitude > 0.1 and 2.2 or 0.55
	vel = vel:Lerp(want, math.clamp(k * dt, 0, 1))
	local y = root.AssemblyLinearVelocity.Y
	root.AssemblyLinearVelocity = Vector3.new(vel.X, y, vel.Z)
	if vel.Magnitude > 4 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + vel.Unit) * CFrame.Angles(0, 0, 0)
	end
	local e = sprayFor(root)
	e.Rate = vel.Magnitude > 8 and math.min(vel.Magnitude * 1.5, 60) or 0
end)

-- Поза конькобежца (фидбэк 2026-11: «ехать двумя ногами сразу, как на настоящем катке»).
-- Поверх анимации ходьбы (в Stepped — после аниматора) ставим ноги: обе вместе, колени чуть
-- согнуты, корпус наклонён вперёд. При разгоне ноги по очереди делают толчок в сторону-назад,
-- на скольжении (кнопки отпущены) стоят рядом. Руки слегка разведены для равновесия.
-- Для всех персонажей с атрибутом OnIce, чтобы и чужие игроки на катке катились, а не шагали.
local poseT = 0
local function motors(char: Model)
	local cache = {}
	for _, d in ipairs(char:GetDescendants()) do
		-- новые риги Roblox: суставы — AnimationConstraint (у него тоже есть Transform)
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
			cache[d.Name] = d
		end
	end
	return cache
end
local motorCache = setmetatable({}, { __mode = "k" })
RunService.Stepped:Connect(function(_, dt)
	poseT += dt
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and p:GetAttribute("OnIce") == true and hum.FloorMaterial == Enum.Material.Ice then
			local m = motorCache[char]
			if not m or not m.LeftHip and not m["Left Hip"] then
				m = motors(char)
				motorCache[char] = m
			end
			local speed = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
			local pushing = hum.MoveDirection.Magnitude > 0.1
			-- фаза толчка: левая — правая, ~0.55 с на толчок
			local ph = math.sin(poseT * 5.7)
			local push = pushing and math.clamp(speed / 10, 0.3, 1) or 0
			local lp, rp = math.max(ph, 0) * push, math.max(-ph, 0) * push
			local crouch = 0.28 + 0.06 * push
			if m.LeftHip then -- R15
				m.LeftHip.Transform = CFrame.Angles(-crouch + lp * 0.35, 0, -lp * 0.3)
				m.RightHip.Transform = CFrame.Angles(-crouch + rp * 0.35, 0, rp * 0.3)
				m.LeftKnee.Transform = CFrame.Angles(crouch * 1.6 - lp * 0.3, 0, 0)
				m.RightKnee.Transform = CFrame.Angles(crouch * 1.6 - rp * 0.3, 0, 0)
				if m.LeftAnkle then
					m.LeftAnkle.Transform = CFrame.Angles(-crouch * 0.6, 0, 0)
					m.RightAnkle.Transform = CFrame.Angles(-crouch * 0.6, 0, 0)
				end
				if m.Waist then
					m.Waist.Transform = CFrame.Angles(-0.22, ph * 0.08 * push, 0)
				end
				if m.LeftShoulder and m.RightShoulder then
					m.LeftShoulder.Transform = CFrame.Angles(ph * 0.35 * push, 0, -0.35)
					m.RightShoulder.Transform = CFrame.Angles(-ph * 0.35 * push, 0, 0.35)
				end
			elseif m["Left Hip"] then -- R6: оси суставов бедра — Y вдоль плеча сустава
				m["Left Hip"].Transform = CFrame.Angles(0, 0, crouch * 0.5 + lp * 0.3)
				m["Right Hip"].Transform = CFrame.Angles(0, 0, -crouch * 0.5 - rp * 0.3)
			end
		end
	end
end)

-- Следы коньков (фидбэк 2026-11): пока катишься, лезвия оставляют на льду тонкие светлые борозды.
-- Следы остаются и после того, как ушёл со льда, и медленно тают (~25 с). Не больше 220 штук.
local TweenService = game:GetService("TweenService")
local marks = Instance.new("Folder")
marks.Name = "SkateMarks"
marks.Parent = workspace
local live = {}
local lastAt = {}
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local markClock = 0
RunService.Heartbeat:Connect(function(dt)
	markClock += dt
	if markClock < 0.06 then
		return
	end
	markClock = 0
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (char and hum) or player:GetAttribute("OnIce") ~= true or hum.FloorMaterial == Enum.Material.Air then
		table.clear(lastAt)
		return
	end
	rp.FilterDescendantsInstances = { char, marks }
	for _, name in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
		local foot = char:FindFirstChild(name)
		if foot and foot:IsA("BasePart") then
			local hit = workspace:Raycast(foot.Position, Vector3.new(0, -4, 0), rp)
			if hit then
				local p = hit.Position + Vector3.new(0, 0.03, 0)
				local prev = lastAt[name]
				if prev and (p - prev).Magnitude > 0.6 and (p - prev).Magnitude < 6 then
					local mid = (prev + p) / 2
					local m = Instance.new("Part")
					m.Name = "SkateMark"
					m.Anchored, m.CanCollide, m.CanQuery, m.CanTouch, m.CastShadow = true, false, false, false, false
					m.Material = Enum.Material.SmoothPlastic
					m.Color = Color3.fromRGB(235, 248, 255)
					m.Transparency = 0.35
					m.Size = Vector3.new(0.09, 0.02, (p - prev).Magnitude + 0.05)
					m.CFrame = CFrame.lookAt(mid, mid + (p - prev))
					m.Parent = marks
					table.insert(live, m)
					TweenService:Create(m, TweenInfo.new(25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
					task.delay(25, function()
						m:Destroy()
					end)
					while #live > 220 do
						local old = table.remove(live, 1)
						if old then
							old:Destroy()
						end
					end
					lastAt[name] = p
				elseif not prev or (p - prev).Magnitude >= 6 then
					lastAt[name] = p
				end
			end
		end
	end
end)
