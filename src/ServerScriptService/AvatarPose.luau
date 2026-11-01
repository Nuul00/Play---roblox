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

local function bend(model: Model, partName: string, jointName: string, angles: CFrame)
	local part = model:FindFirstChild(partName, true)
	local joint = part and part:FindFirstChild(jointName)
	if joint and joint:IsA("Motor6D") then
		joint.C0 = joint.C0 * angles
	end
end

-- Сидячая поза: бёдра вперёд, голени вниз (R15), прямые ноги вперёд (R6).
function AvatarPose.Sit(model: Model)
	bend(model, "LeftUpperLeg", "LeftHip", CFrame.Angles(math.rad(90), 0, 0))
	bend(model, "RightUpperLeg", "RightHip", CFrame.Angles(math.rad(90), 0, 0))
	bend(model, "LeftLowerLeg", "LeftKnee", CFrame.Angles(math.rad(-90), 0, 0))
	bend(model, "RightLowerLeg", "RightKnee", CFrame.Angles(math.rad(-90), 0, 0))
	bend(model, "Torso", "Left Hip", CFrame.Angles(0, 0, math.rad(-90)))
	bend(model, "Torso", "Right Hip", CFrame.Angles(0, 0, math.rad(90)))
end

-- Ставит модель так, чтобы самая низкая точка выбранных частей легла на высоту y.
-- facing — CFrame только с поворотом (куда смотрит персонаж).
function AvatarPose.Place(model: Model, position: Vector3, facing: CFrame, y: number, sitting: boolean?)
	model:PivotTo(CFrame.new(position + Vector3.new(0, 4, 0)) * facing)
	RunService.Heartbeat:Wait()
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
