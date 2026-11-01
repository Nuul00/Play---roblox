-- Общие функции для неподвижных аватаров (продавец, пьедестал топ-3).
-- Корень закреплён, конечности держатся на суставах, поэтому позу задаём через Motor6D.C0.
local RunService = game:GetService("RunService")

local AvatarPose = {}

local function minY(part: BasePart): number
	local h = part.Size / 2
	local lowest = math.huge
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				lowest = math.min(lowest, part.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end
		end
	end
	return lowest
end

-- Готовит модель из CreateHumanoidModelFromUserIdAsync к роли статуи.
function AvatarPose.Prepare(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart")
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = part == root
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.AutoRotate = false
	end
	if root then
		model.PrimaryPart = root
	end
end

-- Сидячая поза: стандартная анимация сидения Roblox (R15 или R6), зациклена.
-- Анимация двигает суставы через Motor6D.Transform и работает при закреплённом корне.
function AvatarPose.Sit(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local animation = Instance.new("Animation")
	animation.AnimationId = humanoid.RigType == Enum.HumanoidRigType.R15 and "rbxassetid://2506281703" or "rbxassetid://178130996"
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and track then
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Action4
		track:Play(0)
	end
end

-- Ставит модель так, чтобы самая низкая точка выбранных частей легла на высоту y.
-- facing — CFrame только с поворотом (куда смотрит персонаж).
function AvatarPose.Place(model: Model, position: Vector3, facing: CFrame, y: number, sitting: boolean?)
	model:PivotTo(CFrame.new(position + Vector3.new(0, 4, 0)) * facing)
	RunService.Heartbeat:Wait()
	if sitting then
		task.wait(0.4) -- дать анимации сидения согнуть ноги перед замером
	end
	local names = sitting and { "LeftUpperLeg", "RightUpperLeg", "Left Leg", "Right Leg" }
		or { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }
	local lowest = math.huge
	for _, name in ipairs(names) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			lowest = math.min(lowest, minY(part))
		end
	end
	if lowest < math.huge then
		model:PivotTo(model:GetPivot() + Vector3.new(0, y - lowest, 0))
	end
end

return AvatarPose
