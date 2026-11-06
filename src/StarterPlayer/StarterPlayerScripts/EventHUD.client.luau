-- Плашка мирового события сверху по центру: название, что даёт и обратный отсчёт.
-- При старте события плашка «выпрыгивает», за 10 секунд до конца начинает мигать.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local defs = {}
for _, def in ipairs(ShopConfig.Events) do
	defs[def.Id] = def
end

local gui = Instance.new("ScreenGui")
gui.Name = "EventHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14
gui.Parent = player:WaitForChild("PlayerGui")

local pill = Instance.new("Frame")
pill.AnchorPoint = Vector2.new(0.5, 0)
pill.Position = UDim2.new(0.5, 0, 0, 10)
pill.Size = UDim2.fromOffset(360, 54)
pill.BackgroundColor3 = Color3.new(1, 1, 1)
pill.Visible = false
pill.Parent = gui
Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Parent = pill
local rim = Instance.new("UIStroke")
rim.Thickness = 3
rim.Color = Color3.fromRGB(255, 245, 210)
rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rim.Parent = pill
local scale = Instance.new("UIScale")
scale.Parent = pill

local function label(pos: UDim2, size: UDim2): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Parent = pill
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.fromRGB(40, 25, 15)
	s.Parent = l
	return l
end
local title = label(UDim2.fromScale(0.06, 0.08), UDim2.fromScale(0.62, 0.5))
title.TextXAlignment = Enum.TextXAlignment.Left
local desc = label(UDim2.fromScale(0.06, 0.56), UDim2.fromScale(0.62, 0.36))
desc.TextXAlignment = Enum.TextXAlignment.Left
local timer = label(UDim2.fromScale(0.68, 0.14), UDim2.fromScale(0.27, 0.72))

-- Между событиями плашка меньше и показывает, какое будет следующим и через сколько
-- (расписание общее для всех серверов — WorldEvents).
local current = ""
local waiting = false
local function update()
	local id = workspace:GetAttribute("EventId") or ""
	local def = defs[id]
	local key = def and id or ("next:" .. tostring(workspace:GetAttribute("NextEventId")))
	if key == current then
		return
	end
	current = key
	if not def then
		local nextDef = defs[workspace:GetAttribute("NextEventId") or ""]
		waiting = nextDef ~= nil
		pill.Visible = waiting
		if nextDef then
			title.Text = "⏳ NEXT: " .. nextDef.Name
			desc.Text = nextDef.Desc .. (workspace:GetAttribute("EventWeekend") and " · weekend: 2x longer!" or "")
			gradient.Color = ColorSequence.new(Color3.fromRGB(70, 70, 100), Color3.fromRGB(35, 35, 55))
			scale.Scale = 0.7
		end
		return
	end
	waiting = false
	title.Text = def.Icon .. " " .. def.Name
	desc.Text = def.Desc
	gradient.Color = ColorSequence.new(def.Color:Lerp(Color3.new(1, 1, 1), 0.25), def.Color:Lerp(Color3.new(0, 0, 0), 0.3))
	pill.Visible = true
	scale.Scale = 0.4
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end
workspace:GetAttributeChangedSignal("EventId"):Connect(update)
workspace:GetAttributeChangedSignal("NextEventId"):Connect(update)
update()

local t = 0
RunService.RenderStepped:Connect(function(dt)
	if not pill.Visible and not waiting then
		return
	end
	t += dt
	local target = waiting and workspace:GetAttribute("NextEventAt") or workspace:GetAttribute("EventEnd")
	local left = math.max(0, (target or 0) - workspace:GetServerTimeNow())
	local text = string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60))
	if timer.Text ~= text then
		timer.Text = text
	end
	rim.Transparency = (not waiting and left < 10) and (0.5 + 0.5 * math.sin(t * 10)) or (waiting and 0.6 or 0)
	local camera = workspace.CurrentCamera
	-- окна интерфейса открыты — плашку «следующее событие» прячем, чтобы не мешала
	if waiting then
		pill.Visible = (player:GetAttribute("UIScreen") or "") == ""
	end
	if camera and (waiting or scale.Scale >= 0.99) then
		local base = math.clamp(camera.ViewportSize.X / 900, 0.6, 1)
		scale.Scale = waiting and base * 0.7 or base
	end
end)
