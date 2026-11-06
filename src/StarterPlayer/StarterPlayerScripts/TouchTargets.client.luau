-- На телефоне окна уменьшаются (UIScale), а вместе с ними и кнопки закрытия — до 22-33 px.
-- Палец в такие не попадает. Кнопкам «×»/«X» (и отмеченным атрибутом TouchMin) добавляем свой
-- UIScale, чтобы на экране они были не меньше 44 px. На ПК ничего не меняется.
local UIS = game:GetService("UserInputService")
if not UIS.TouchEnabled then
	return
end
local player = game:GetService("Players").LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local MIN = 44

local tracked = setmetatable({}, { __mode = "k" })
local function isClose(b: GuiButton): boolean
	if b:GetAttribute("TouchMin") then
		return true
	end
	local t = b:IsA("TextButton") and b.Text or ""
	return t == "×" or t == "X" or t == "✕"
end
local function consider(d: Instance)
	if d:IsA("GuiButton") and not tracked[d] then
		task.defer(function()
			if d.Parent and isClose(d) then
				local s = Instance.new("UIScale")
				s.Name = "TouchBoost"
				s.Parent = d
				tracked[d] = s
			end
		end)
	end
end
for _, d in ipairs(gui:GetDescendants()) do
	consider(d)
end
gui.DescendantAdded:Connect(consider)

while true do
	task.wait(0.4)
	for b, s in pairs(tracked) do
		if b.Parent and b.Visible then
			-- размер на экране без нашего UIScale
			local cur = math.min(b.AbsoluteSize.X, b.AbsoluteSize.Y) / math.max(s.Scale, 0.01)
			local want = cur > 0 and math.clamp(MIN / cur, 1, 2.2) or 1
			if math.abs(s.Scale - want) > 0.03 then
				s.Scale = want
			end
		end
	end
end
