-- Кнопка «Пригласить друга»: каждый друг на сервере даёт +10% монет (FriendBonus, до +50%).
-- Справа под шестерёнкой настроек. Окно приглашения — стандартное Roblox (SocialService).
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "InviteHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.Parent = player:WaitForChild("PlayerGui")

local b = Instance.new("TextButton")
b.Name = "Invite"
b.AnchorPoint = Vector2.new(1, 0)
b.Position = UDim2.new(1, -14, 0, 104)
b.Size = UDim2.fromOffset(118, 50)
b.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
b.Font = Enum.Font.FredokaOne
b.TextSize = 17
b.TextColor3 = Color3.new(1, 1, 1)
b.Text = "👥 INVITE\n+" .. math.floor(ShopConfig.FriendBonusEach * 100 + 0.5) .. "% coins"
b.Visible = false
b.Parent = gui
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 14)
local st = Instance.new("UIStroke")
st.Thickness = 3
st.Color = Color3.fromRGB(30, 90, 50)
st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
st.Parent = b
local ts = Instance.new("UIStroke")
ts.Thickness = 1.5
ts.Color = Color3.fromRGB(20, 70, 35)
ts.Parent = b
local scale = Instance.new("UIScale")
scale.Parent = b

local canInvite = false
task.spawn(function()
	local ok, res = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	canInvite = ok and res == true
	b.Visible = canInvite and (player:GetAttribute("UIScreen") or "") == ""
end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
	b.Visible = canInvite and (player:GetAttribute("UIScreen") or "") == ""
end)
b.Activated:Connect(function()
	scale.Scale = 0.9
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	pcall(SocialService.PromptGameInvite, SocialService, player)
end)
-- раз в минуту кнопка коротко «подпрыгивает», пока у игрока нет друзей на сервере
task.spawn(function()
	while true do
		task.wait(60)
		if b.Visible and (player:GetAttribute("FriendsOnline") or 0) == 0 then
			scale.Scale = 1.15
			TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), { Scale = 1 }):Play()
		end
	end
end)
