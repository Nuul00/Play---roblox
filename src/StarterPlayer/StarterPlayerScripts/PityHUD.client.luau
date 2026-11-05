-- Прогресс гарантии — на табло яйца, а не в личном HUD. Над каждым табло (EggBillboards)
-- висит светящаяся плашка в цветах этого яйца: «Legendary in 63 eggs», «Secret in 1963 eggs».
-- Плашка появляется, только когда игрок подходит к яйцу. Счётчики Pity<Редкость> ставит сервер
-- и они общие для всех яиц, поэтому у любого яйца видно один и тот же прогресс.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local NEAR = 24 -- на каком расстоянии от яйца (в студах) показывать плашку
local RARITY = {
	Legendary = { icon = "🌟", a = Color3.fromRGB(255, 222, 110), b = Color3.fromRGB(240, 150, 30) },
	Mythic = { icon = "💎", a = Color3.fromRGB(255, 150, 200), b = Color3.fromRGB(220, 60, 130) },
	Secret = { icon = "✨", a = Color3.fromRGB(220, 170, 255), b = Color3.fromRGB(130, 70, 230) },
}

local strips = {}

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function build(board: BillboardGui)
	local id = board:GetAttribute("EggId")
	local egg = id and Config.Eggs[id]
	if not egg or not board.Adornee then
		return
	end
	local sky = egg.World == "sky"
	local gui = Instance.new("BillboardGui")
	gui.Name = "EggPity" .. id
	gui.Adornee = board.Adornee
	gui.Size = UDim2.fromScale(board.Size.X.Scale * 0.95, 4.4)
	gui.StudsOffsetWorldSpace = board.StudsOffsetWorldSpace + Vector3.new(0, board.Size.Y.Scale / 2 + 2.6, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 75
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = sky and Color3.new(1, 1, 1) or Color3.fromRGB(22, 24, 40)
	panel.BackgroundTransparency = sky and 0.05 or 0.12
	panel.Parent = gui
	corner(panel, 0.22)
	local bg = Instance.new("UIGradient")
	bg.Rotation = 90
	bg.Color = sky and ColorSequence.new(Color3.fromRGB(255, 232, 248), Color3.fromRGB(214, 232, 255))
		or ColorSequence.new(egg.Color:Lerp(Color3.fromRGB(22, 24, 40), 0.55), Color3.fromRGB(22, 24, 40))
	bg.Parent = panel
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = sky and Color3.new(1, 1, 1) or egg.Color
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = panel
	local popScale = Instance.new("UIScale")
	popScale.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.05, 0.04)
	title.Size = UDim2.fromScale(0.9, 0.26)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Text = "GUARANTEE"
	title.TextColor3 = sky and Color3.fromRGB(150, 100, 220) or egg.Color:Lerp(Color3.new(1, 1, 1), 0.4)
	title.Parent = panel
	local ts = Instance.new("UIStroke")
	ts.Thickness = 1.5
	ts.Color = Color3.fromRGB(30, 18, 50)
	ts.Transparency = sky and 0.6 or 0
	ts.Parent = title

	local rows = {}
	local order = 0
	for i = #ShopConfig.Pity, 1, -1 do -- сверху ближняя гарантия (Legendary)
		local tier = ShopConfig.Pity[i]
		local style = RARITY[tier.Rarity] or RARITY.Legendary
		local row = Instance.new("Frame")
		row.Position = UDim2.fromScale(0.05, 0.34 + order * 0.32)
		row.Size = UDim2.fromScale(0.9, 0.26)
		row.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
		row.BackgroundTransparency = sky and 0.55 or 0.3
		row.Parent = panel
		corner(row, 0.5)
		local rs = Instance.new("UIStroke")
		rs.Thickness = 1.5
		rs.Color = style.a
		rs.Parent = row
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = Color3.new(1, 1, 1)
		fill.BorderSizePixel = 0
		fill.Parent = row
		corner(fill, 0.5)
		local fg = Instance.new("UIGradient")
		fg.Color = ColorSequence.new(style.a, style.b)
		fg.Parent = fill
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = Color3.new(1, 1, 1)
		text.ZIndex = 2
		text.Parent = row
		local tp = Instance.new("UIPadding")
		tp.PaddingTop = UDim.new(0.12, 0)
		tp.PaddingBottom = UDim.new(0.12, 0)
		tp.Parent = text
		local txs = Instance.new("UIStroke")
		txs.Thickness = 1.5
		txs.Color = Color3.fromRGB(30, 15, 50)
		txs.Parent = text
		rows[tier.Rarity] = { tier = tier, fill = fill, text = text, icon = style.icon }
		order += 1
	end
	table.insert(strips, { gui = gui, adornee = board.Adornee, rows = rows, glow = glow, pop = popScale, shown = false, phase = id })
end

local function refresh()
	for _, s in ipairs(strips) do
		for rarity, r in pairs(s.rows) do
			local n = math.clamp(player:GetAttribute("Pity" .. rarity) or 0, 0, r.tier.Threshold)
			local left = math.max(r.tier.Threshold - n, 1)
			r.text.Text = string.format("%s %s in %d eggs", r.icon, string.upper(rarity), left)
			local size = UDim2.fromScale(math.max(n / r.tier.Threshold, 0.05), 1)
			if s.shown then
				TweenService:Create(r.fill, TweenInfo.new(0.3), { Size = size }):Play()
			else
				r.fill.Size = size
			end
		end
	end
end

local function consider(child: Instance)
	if child:IsA("BillboardGui") and child.Name == "EggBoard" then
		if child:GetAttribute("EggId") == nil then
			child:GetAttributeChangedSignal("EggId"):Wait()
		end
		build(child)
		refresh()
	end
end
for _, child in ipairs(playerGui:GetChildren()) do
	task.spawn(consider, child)
end
playerGui.ChildAdded:Connect(function(child)
	task.defer(consider, child)
end)
local pendingPity = false
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 4) == "Pity" and not pendingPity then
		pendingPity = true -- пачка яиц меняет счётчики много раз: обновляем один раз
		task.defer(function()
			pendingPity = false
			refresh()
		end)
	end
end)

-- Показываем плашку только рядом с яйцом; пока видна — мягко «светится».
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, s in ipairs(strips) do
		local pos = s.adornee and s.adornee.Parent and (s.adornee:IsA("Attachment") and s.adornee.WorldPosition or s.adornee.Position)
		local near = root ~= nil and pos ~= nil and (root.Position - pos).Magnitude < NEAR
		if near ~= s.shown then
			s.shown = near
			if near then
				s.gui.Enabled = true
				s.pop.Scale = 0.6
				TweenService:Create(s.pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			else
				s.gui.Enabled = false
			end
		end
		if s.shown then
			s.glow.Transparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(t * 3 + s.phase))
		end
	end
end)
