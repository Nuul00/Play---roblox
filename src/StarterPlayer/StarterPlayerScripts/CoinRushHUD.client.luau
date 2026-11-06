-- HUD данжа Coin Rush: сверху — комната, таймер, собранные монеты и сколько осталось; удар лазера —
-- красная вспышка; Хранилище — полоска «собрано / нужно»; в конце — окно награды и лута.
-- Подсказка портала показывает цену ключа (FREE раз в день). Монеты забега крутятся на клиенте.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local UISounds = require(ReplicatedStorage:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("CoinRushEvent")

local GOLD = Color3.fromRGB(255, 205, 70)
local DARK = Color3.fromRGB(30, 18, 50)
local WHITE = Color3.new(1, 1, 1)

local gui = Instance.new("ScreenGui")
gui.Name = "CoinRushHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function stroke(o, t)
	local s = Instance.new("UIStroke")
	s.Thickness = t or 3
	s.Color = DARK
	s.Parent = o
	return s
end
local function label(parent, text, size, pos, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Text = text
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = color or WHITE
	l.Parent = parent
	stroke(l)
	return l
end

-- верхняя панель
local top = Instance.new("Frame")
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.new(0.5, 0, 0, 58)
top.Size = UDim2.fromOffset(420, 92)
top.BackgroundColor3 = DARK
top.BackgroundTransparency = 0.25
top.Visible = false
top.Parent = gui
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 16)
local ts = Instance.new("UIStroke")
ts.Color = GOLD
ts.Thickness = 2.5
ts.Parent = top
local roomL = label(top, "ROOM 1/3", UDim2.new(1, -20, 0, 26), UDim2.fromOffset(10, 6), GOLD)
local timerL = label(top, "25", UDim2.new(0, 90, 0, 44), UDim2.new(1, -100, 0, 36), WHITE)
timerL.TextXAlignment = Enum.TextXAlignment.Right
local bankL = label(top, "💰 0", UDim2.new(0, 250, 0, 36), UDim2.fromOffset(14, 38), Color3.fromRGB(255, 235, 150))
bankL.TextXAlignment = Enum.TextXAlignment.Left
local leftL = label(top, "", UDim2.new(0, 160, 0, 18), UDim2.fromOffset(14, 72), Color3.fromRGB(200, 190, 230))
leftL.TextXAlignment = Enum.TextXAlignment.Left
-- полоса Хранилища
local vbar = Instance.new("Frame")
vbar.Position = UDim2.new(0, 14, 1, 6)
vbar.Size = UDim2.new(1, -28, 0, 14)
vbar.BackgroundColor3 = DARK
vbar.Visible = false
vbar.Parent = top
Instance.new("UICorner", vbar).CornerRadius = UDim.new(1, 0)
local vfill = Instance.new("Frame")
vfill.Size = UDim2.fromScale(0, 1)
vfill.BackgroundColor3 = GOLD
vfill.Parent = vbar
Instance.new("UICorner", vfill).CornerRadius = UDim.new(1, 0)

-- крупные надписи по центру
local big = label(gui, "", UDim2.fromOffset(640, 70), UDim2.new(0.5, 0, 0.3, 0), GOLD)
big.AnchorPoint = Vector2.new(0.5, 0.5)
big.Visible = false
local bigScale = Instance.new("UIScale")
bigScale.Parent = big
local function shout(text, color, dur)
	big.Text = text
	big.TextColor3 = color or GOLD
	big.TextTransparency = 0
	big.Visible = true
	bigScale.Scale = 0.4
	TweenService:Create(bigScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(dur or 1.6, function()
		if big.Text == text then
			local tw = TweenService:Create(big, TweenInfo.new(0.4), { TextTransparency = 1 })
			tw.Completed:Connect(function()
				if big.TextTransparency >= 0.99 then
					big.Visible = false -- обводка (UIStroke) сама не гаснет
				end
			end)
			tw:Play()
		end
	end)
end

-- красная вспышка при ударе
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 30, 60)
flash.BackgroundTransparency = 1
flash.Parent = gui

-- окно награды
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(420, 260)
panel.BackgroundColor3 = DARK
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
local ps = Instance.new("UIStroke")
ps.Color = GOLD
ps.Thickness = 3
ps.Parent = panel
local pTitle = label(panel, "COIN RUSH", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 12), GOLD)
local pCoins = label(panel, "", UDim2.new(1, -20, 0, 46), UDim2.fromOffset(10, 62), Color3.fromRGB(255, 235, 150))
local pInfo = label(panel, "", UDim2.new(1, -30, 0, 60), UDim2.fromOffset(15, 112), WHITE)
pInfo.TextWrapped = true
local ok = Instance.new("TextButton")
ok.AnchorPoint = Vector2.new(0.5, 1)
ok.Position = UDim2.new(0.5, 0, 1, -14)
ok.Size = UDim2.fromOffset(160, 46)
ok.BackgroundColor3 = Color3.fromRGB(90, 200, 90)
ok.Text = "OK"
ok.TextScaled = true
ok.Font = Enum.Font.FredokaOne
ok.TextColor3 = WHITE
ok.Parent = panel
Instance.new("UICorner", ok).CornerRadius = UDim.new(0, 12)
stroke(ok, 2)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
ok.Activated:Connect(function()
	panel.Visible = false
end)

local worth, endsAt, vault = 1, 0, nil
local function coins(weight)
	return NumberFormat.Short(math.floor(weight * worth))
end

remote.OnClientEvent:Connect(function(kind, d)
	if kind == "room" then
		worth = d.Worth or worth
		endsAt = d.Ends
		vault = nil
		top.Visible = true
		vbar.Visible = false
		roomL.Text = "ROOM " .. d.Room .. "/" .. d.Rooms .. " · " .. d.Name
		leftL.Text = d.Total .. " coins left"
		shout("ROOM " .. d.Room .. ": " .. d.Name, GOLD, 1.4)
		UISounds.Play("unlock")
	elseif kind == "bank" then
		bankL.Text = "💰 " .. coins(d.Bank)
		leftL.Text = d.Left .. " coins left"
		if vault then
			vfill.Size = UDim2.fromScale(math.clamp(d.Bank / vault.Need, 0, 1), 1)
		end
	elseif kind == "hit" then
		bankL.Text = "💰 " .. coins(d.Bank)
		flash.BackgroundTransparency = 0.45
		TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		shout("ZAPPED!  -" .. coins(d.Lost), Color3.fromRGB(255, 90, 110), 0.9)
		UISounds.Play("fail")
	elseif kind == "vault" then
		worth = d.Worth or worth
		endsAt = d.Ends
		vault = d
		roomL.Text = "THE VAULT · step into the gold circle"
		leftL.Text = "need " .. coins(d.Need)
		vbar.Visible = true
		vfill.Size = UDim2.fromScale(math.clamp(d.Have / math.max(d.Need, 0.001), 0, 1), 1)
		vfill.BackgroundColor3 = d.Have >= d.Need and Color3.fromRGB(110, 240, 130) or GOLD
		shout(d.Have >= d.Need and "🔓 ENOUGH COINS — OPEN THE VAULT!" or "🔒 THE VAULT", GOLD, 1.6)
	elseif kind == "vaultResult" then
		if d.Open then
			shout("💥 VAULT OPENED!  ×2 COINS", Color3.fromRGB(255, 220, 80), 2.4)
			UISounds.Play("fanfare")
		else
			shout("🔒 Not enough coins for the vault", Color3.fromRGB(255, 150, 150), 2)
			UISounds.Play("fail")
		end
	elseif kind == "result" then
		top.Visible = false
		endsAt = 0
		pTitle.Text = d.Vault and "💰 VAULT CRACKED!" or "COIN RUSH OVER"
		pCoins.Text = "+" .. NumberFormat.Short(d.Coins) .. " coins"
		local info = {}
		if d.Hits and d.Hits > 0 then
			table.insert(info, "Zapped " .. d.Hits .. "×")
		end
		for _, l in ipairs(d.Loot or {}) do
			table.insert(info, l)
		end
		pInfo.Text = #info > 0 and table.concat(info, "\n") or (d.Vault and "Lucky next time for loot!" or "Collect more coins to open the vault (×2 + loot)")
		panel.Visible = true
		panelScale.Scale = 0.5
		TweenService:Create(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		UISounds.Play("reward")
		task.delay(8, function()
			panel.Visible = false
		end)
	end
end)

-- таймер и вращение монет своего забега
local myRun
RunService.RenderStepped:Connect(function(dt)
	if endsAt > 0 then
		local left = math.max(0, endsAt - workspace:GetServerTimeNow())
		timerL.Text = string.format("%d", math.ceil(left))
		timerL.TextColor3 = left < 5 and Color3.fromRGB(255, 100, 100) or WHITE
	end
	if not myRun or not myRun.Parent then
		myRun = workspace:FindFirstChild("CoinRush_" .. player.UserId)
	end
	if myRun then
		local spin = CFrame.Angles(0, dt * 3, 0)
		for _, f in ipairs(myRun:GetChildren()) do
			if f:IsA("Folder") then
				for _, c in ipairs(f:GetChildren()) do
					if c.Name == "RushBar" then -- монеты крутит CoinRushFX (модели Tripo), слитки — здесь
						c.CFrame = c.CFrame * spin
					end
				end
			end
		end
	end
end)

-- подсказка портала: цена ключа
local function updatePrompt()
	local portal = workspace:FindFirstChild("CoinRushPortal", true)
	local field = portal and portal:FindFirstChild("Field")
	local prompt = field and field:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		local cost = player:GetAttribute("RushKeyCost") or 0
		prompt.ObjectText = cost <= 0 and "FREE run today!" or ("🔑 Key: " .. NumberFormat.Short(cost) .. " coins")
	end
	local sign = portal and portal:FindFirstChild("RushSign", true)
	local sub = sign and sign:FindFirstChild("Sub")
	if sub then
		local cost = player:GetAttribute("RushKeyCost") or 0
		sub.Text = cost <= 0 and "✨ FREE RUN TODAY ✨" or ("🔑 " .. NumberFormat.Short(cost) .. " coins")
	end
end
-- вихрь портала крутится (только у себя)
task.spawn(function()
	local portal = workspace:WaitForChild("CoinSpeedWorld"):WaitForChild("CoinRushPortal", 60)
	if not portal then
		return
	end
	local field, core = portal:WaitForChild("Field", 10), portal:WaitForChild("Core", 10)
	if not field then
		return
	end
	-- рельеф (Terrain) поверх пола рисуется у клиента: поднимаем портал и каждую плиту тропинки
	-- до поверхности, иначе они тонут в траве
	task.wait(2)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Terrain }
	local function lift(pos: Vector3, baseY: number): number
		local h = workspace:Raycast(Vector3.new(pos.X, baseY + 60, pos.Z), Vector3.new(0, -120, 0), rp)
		local d = h and (h.Position.Y - baseY) or 0
		return (d > 0.2 and d < 12) and d or 0
	end
	local floor = workspace.CoinSpeedWorld:FindFirstChild("Floor")
	local floorY = floor and floor.Position.Y + floor.Size.Y / 2 or 0
	local dPortal = lift(field.Position, floorY)
	for _, c in ipairs(portal:GetChildren()) do
		if c.Name ~= "RushPath" then
			if c:IsA("Model") then
				c:PivotTo(c:GetPivot() + Vector3.new(0, dPortal, 0))
			elseif c:IsA("BasePart") then
				c.CFrame = c.CFrame + Vector3.new(0, dPortal, 0)
			end
		end
	end
	local pm = portal:FindFirstChild("RushPath")
	if pm then
		-- под тропинкой и перед аркой трава → земля (иначе высокая трава прячет плиты)
		local T = workspace.Terrain
		local function clearGrass(pos: Vector3, r: number)
			local h = workspace:Raycast(Vector3.new(pos.X, floorY + 60, pos.Z), Vector3.new(0, -120, 0), rp)
			if not h then
				return
			end
			local y = h.Position.Y
			local reg = Region3.new(Vector3.new(pos.X - r, y - 6, pos.Z - r), Vector3.new(pos.X + r, y + 4, pos.Z + r)):ExpandToGrid(4)
			for _, m in ipairs({ Enum.Material.Grass, Enum.Material.LeafyGrass }) do
				pcall(function()
					T:ReplaceMaterial(reg, 4, m, Enum.Material.Ground)
				end)
			end
		end
		for _, c in ipairs(pm:GetChildren()) do
			if c.Name == "PathStone" then
				clearGrass(c.Position, 3)
			end
		end
		clearGrass(field.Position, 6)
		for _, c in ipairs(pm:GetChildren()) do
			if c:IsA("Model") then
				c:PivotTo(c:GetPivot() + Vector3.new(0, lift(c:GetPivot().Position, floorY), 0))
			elseif c:IsA("BasePart") then
				c.CFrame = c.CFrame + Vector3.new(0, lift(c.Position, floorY), 0)
			end
		end
	end
	local f0, c0 = field.CFrame, core and core.CFrame
	-- тропинка: монеты парят и крутятся, огоньки бегут волной к порталу
	local pathModel = portal:WaitForChild("RushPath", 10)
	local floats, lights = {}, {}
	if pathModel then
		for _, d in ipairs(pathModel:GetChildren()) do
			if d.Name == "FloatCoin" and d:IsA("Model") then
				table.insert(floats, { m = d, cf = d:GetPivot(), k = d:GetAttribute("Float") or 1 })
			elseif d.Name == "PathLight" then
				table.insert(lights, { p = d, w = d:GetAttribute("Wave") or 0 })
			end
		end
	end
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, f in ipairs(floats) do
			f.m:PivotTo(f.cf * CFrame.new(0, math.sin(t * 2 + f.k) * 0.5, 0) * CFrame.Angles(0, t * 1.8 + f.k, 0))
		end
		for _, l in ipairs(lights) do
			local wave = (math.sin((l.w - t * 0.6) * math.pi * 2) + 1) / 2
			l.p.Transparency = 0.6 - 0.6 * wave
			l.p.Size = Vector3.new(0.9, 0.9, 0.9) * (0.8 + 0.45 * wave)
		end
		field.CFrame = f0 * CFrame.Angles(t * 1.5, 0, 0)
		if core then
			core.CFrame = c0 * CFrame.Angles(-t * 2.2, 0, 0)
			core.Transparency = 0.5 + 0.1 * math.sin(t * 3)
		end
	end)
end)
player:GetAttributeChangedSignal("RushKeyCost"):Connect(updatePrompt)
task.delay(5, updatePrompt)
