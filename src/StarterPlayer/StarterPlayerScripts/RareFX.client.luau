-- Редкие выпадения:
-- 1) баннер для всех игроков сервера («Игрок вылупил Sky Griffin!»), очередь по одному;
-- 2) кинематографичное открытие у самого игрока для Legendary и Secret: размытие мира,
--    вспышка, наезд камеры и тряска. Окно открытия из ShopUI остаётся поверх и не трогается.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local COLORS = {
	Legendary = Color3.fromRGB(255, 196, 80),
	Mythic = Color3.fromRGB(255, 90, 160),
	Secret = Color3.fromRGB(190, 120, 255),
}
local function rankOf(petId: number): number
	local def = Config.Pets[petId]
	return def and ShopConfig.RarityRank[def.Rarity] or 1
end

------------------------------------------------------------------ баннер
local gui = Instance.new("ScreenGui")
gui.Name = "RareAnnounce"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, -80)
banner.Size = UDim2.fromOffset(540, 58)
banner.BackgroundColor3 = Color3.new(1, 1, 1)
banner.Visible = false
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 18)
local gradient = Instance.new("UIGradient")
gradient.Parent = banner
local rim = Instance.new("UIStroke")
rim.Thickness = 3
rim.Color = Color3.fromRGB(255, 240, 200)
rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rim.Parent = banner
local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Position = UDim2.fromOffset(16, 6)
text.Size = UDim2.new(1, -32, 1, -12)
text.Font = Enum.Font.FredokaOne
text.TextScaled = true
text.RichText = true
text.TextColor3 = Color3.new(1, 1, 1)
text.Parent = banner
local textStroke = Instance.new("UIStroke")
textStroke.Thickness = 2.5
textStroke.Color = Color3.fromRGB(40, 20, 60)
textStroke.Parent = text
local bannerScale = Instance.new("UIScale")
bannerScale.Parent = banner

local queue = {}
local showing = false
local rainbow = false
local function showNext()
	if showing or #queue == 0 then
		return
	end
	showing = true
	local item = table.remove(queue, 1)
	local def = Config.Pets[item.pet]
	local rarity = def and def.Rarity or "Legendary"
	local color = COLORS[rarity] or COLORS.Legendary
	rainbow = rarity == "Secret"
	gradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.25), color:Lerp(Color3.new(0, 0, 0), 0.25))
	gradient.Rotation = 90
	local icon = rarity == "Secret" and "✨" or "🌟"
	if def and def.Exclusive then
		icon = "👑"
		text.Text = string.format("%s <b>%s</b> got <b>%s</b>! (ROYAL %s) %s", icon, item.name, def.Name, string.upper(rarity), icon)
	elseif def and def.Super then
		icon = Config.SuperTiers[def.Super].Icon
		text.Text = string.format("%s <b>%s</b> hatched <b>%s</b>! (%s SECRET · %s) %s", icon, item.name, def.Name, string.upper(def.SuperKey), Config.FormatOdds(def.Odds), icon)
	else
		text.Text = string.format("%s <b>%s</b> hatched <b>%s</b>! (%s%s) %s", icon, item.name, def and def.Name or "?", string.upper(rarity), item.forced and " · guaranteed" or "", icon)
	end
	banner.Position = UDim2.new(0.5, 0, 0, -80)
	banner.Visible = true
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 92) }):Play()
	task.delay(3.6, function()
		local away = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -80) })
		away.Completed:Connect(function()
			banner.Visible = false
			showing = false
			showNext()
		end)
		away:Play()
	end)
end
ReplicatedStorage:WaitForChild("GameAnnounce").OnClientEvent:Connect(function(name, pet, forced)
	if type(name) ~= "string" or type(pet) ~= "number" or not Config.Pets[pet] then
		return
	end
	if #queue < 5 then
		table.insert(queue, { name = name, pet = pet, forced = forced == true })
	end
	showNext()
end)
-- Супер-секретка: ещё и системное сообщение в чате у всех на сервере.
ReplicatedStorage:WaitForChild("SuperSecretAnnounce").OnClientEvent:Connect(function(name, pet)
	local def = type(pet) == "number" and Config.Pets[pet]
	if type(name) ~= "string" or not def or not def.Super then
		return
	end
	pcall(function()
		local channels = game:GetService("TextChatService"):FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general then
			local hex = ({ "#9BE8FF", "#FFD34A", "#FF7AF2", "#B98CFF", "#7DF9FF" })[def.Super] or "#FFFFFF"
			general:DisplaySystemMessage(string.format('<font color="%s"><b>%s %s hatched %s! (%s)</b></font>', hex, Config.SuperTiers[def.Super].Icon, name, def.Name, Config.FormatOdds(def.Odds)))
		end
	end)
end)
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	if banner.Visible and rainbow then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(t * 0.25 % 1, 0.55, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromHSV((t * 0.25 + 0.33) % 1, 0.55, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV((t * 0.25 + 0.66) % 1, 0.55, 1)),
		})
		gradient.Rotation = 0
	end
	local camera = workspace.CurrentCamera
	if camera then
		bannerScale.Scale = math.clamp(camera.ViewportSize.X / 900, 0.6, 1)
	end
end)

------------------------------------------------------------------ кинематографичное открытие
local flashGui = Instance.new("ScreenGui")
flashGui.Name = "RareHatchFlash"
flashGui.ResetOnSpawn = false
flashGui.IgnoreGuiInset = true
flashGui.DisplayOrder = 29 -- под окном открытия ShopUI (30), поверх остального HUD
flashGui.Parent = player.PlayerGui
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = flashGui

local busy = false
local function cinematic(rank: number, rarity: string)
	if busy then
		return
	end
	busy = true
	local secret = rank >= ShopConfig.RarityRank.Secret
	local strength = secret and 1 or 0.6
	local duration = secret and 1.6 or 1
	local color = COLORS[rarity] or COLORS.Legendary

	local blur = Instance.new("BlurEffect")
	blur.Name = "RareHatchBlur"
	blur.Size = 0
	blur.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "RareHatchTint"
	cc.Parent = Lighting
	TweenService:Create(blur, TweenInfo.new(0.25), { Size = 18 * strength }):Play()
	TweenService:Create(cc, TweenInfo.new(0.25), {
		Brightness = 0.12 * strength,
		Saturation = 0.35 * strength,
		TintColor = color:Lerp(Color3.new(1, 1, 1), 0.55),
	}):Play()

	flash.BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.6)
	flash.BackgroundTransparency = 0.15
	TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()

	local camera = workspace.CurrentCamera
	local fov = camera and camera.FieldOfView or 70
	if camera then
		TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = fov - 14 * strength }):Play()
		task.delay(0.25, function()
			TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = fov }):Play()
		end)
	end
	-- Тряска через смещение камеры персонажа.
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		task.spawn(function()
			local stop = os.clock() + (secret and 0.9 or 0.45)
			while os.clock() < stop and humanoid.Parent do
				local a = 0.35 * strength
				humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)
				RunService.RenderStepped:Wait()
			end
			humanoid.CameraOffset = Vector3.zero
		end)
	end

	task.delay(duration, function()
		local fade = TweenInfo.new(0.6)
		TweenService:Create(blur, fade, { Size = 0 }):Play()
		local back = TweenService:Create(cc, fade, { Brightness = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) })
		back.Completed:Connect(function()
			blur:Destroy()
			cc:Destroy()
			busy = false
		end)
		back:Play()
	end)
end

ReplicatedStorage:WaitForChild("GameHatched").OnClientEvent:Connect(function(batch, sourceEgg)
	if sourceEgg == "royal" then
		return -- у Royal Egg своя анимация в мире (RoyalHatch)
	end
	if type(batch) ~= "table" then
		return
	end
	local best, bestRarity = 0, nil
	for _, r in ipairs(batch) do
		if type(r) == "table" and type(r.Pet) == "number" and Config.Pets[r.Pet] then
			local rank = rankOf(r.Pet)
			if rank > best then
				best, bestRarity = rank, Config.Pets[r.Pet].Rarity
			end
		end
	end
	if best >= ShopConfig.RarityRank.Legendary then
		-- Ждём момента, когда яйцо в окне ShopUI лопается (сигнал HatchBurst), чтобы вспышка
		-- и тряска совпали с раскалыванием. Если сигнала нет — показываем через несколько секунд.
		local ui = player.PlayerGui:FindFirstChild("WorkshopUI")
		local signal = ui and ui:FindFirstChild("HatchBurst")
		local done, conn = false, nil
		local function go()
			if done then
				return
			end
			done = true
			if conn then
				conn:Disconnect()
			end
			cinematic(best, bestRarity)
		end
		if signal and signal:IsA("BindableEvent") then
			conn = signal.Event:Connect(go)
			task.delay(9, go)
		else
			go()
		end
	end
end)
