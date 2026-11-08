-- След сбора монет (фидбэк 2026-11): когда твой магнит забирает монету, из неё к магниту летит
-- золотой огонёк со шлейфом — видно, что монету «втянуло». Заменяет прежнюю волну-вспышку.
-- Только свои сборы рядом (≤ радиус магнита + 12), не больше 12 огоньков одновременно.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("CoinSpeedWorld")

local live = 0
-- когда у меня последний раз вырос счётчик собранных монет (чужие сборы рядом не рисуем)
local myCollectAt = -math.huge
local lastCount = player:GetAttribute("CoinsCollected") or 0
player:GetAttributeChangedSignal("CoinsCollected"):Connect(function()
	local n = player:GetAttribute("CoinsCollected") or 0
	if n > lastCount then
		myCollectAt = os.clock()
	end
	lastCount = n
end)
local flying = {}

local function magnetPoint(): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	local tool = char:FindFirstChildOfClass("Tool")
	local h = tool and tool:FindFirstChild("Handle")
	if h and h:IsA("BasePart") then
		return h
	end
	local r = char:FindFirstChild("HumanoidRootPart")
	return r and r:IsA("BasePart") and r or nil
end

local function spark(from: Vector3, color: Color3)
	local target = magnetPoint()
	if not target or live >= 12 then
		return
	end
	local radius = math.clamp(tonumber(player:GetAttribute("MagnetRadius")) or 6, 3, 60)
	if (from - target.Position).Magnitude > radius + 12 then
		return
	end
	live += 1
	local p = Instance.new("Part")
	p.Name = "CoinSpark"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.55, 0.55, 0.55)
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Position = from
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.22, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.22, 0)
	a1.Parent = p
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.28
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(color, Color3.fromRGB(255, 250, 220))
	trail.Transparency = NumberSequence.new(0.05, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = p
	p.Parent = workspace
	-- лёгкая дуга: вверх, потом к магниту
	table.insert(flying, { part = p, from = from, target = target, t = 0, dur = 0.32, lift = 1.5 + math.random() * 1.5 })
end

local function watch(coin: Instance)
	if not (coin:IsA("BasePart") and string.match(coin.Name, "^Coin_%d+$")) then
		return
	end
	coin:GetAttributeChangedSignal("Available"):Connect(function()
		if coin:GetAttribute("Available") == false then
			-- монета исчезла: если рядом с нами — значит, это наш магнит её забрал
			local c = coin.Color
			if c.R + c.G + c.B < 0.6 then
				c = Color3.fromRGB(255, 210, 70)
			end
			local pos, col = coin.Position, c:Lerp(Color3.fromRGB(255, 220, 90), 0.4)
			local at = os.clock()
			task.delay(0.12, function()
				if math.abs(myCollectAt - at) < 0.4 then
					spark(pos, col)
				end
			end)
		end
	end)
end
for _, d in ipairs(world:GetDescendants()) do
	watch(d)
end
world.DescendantAdded:Connect(watch)

RunService.RenderStepped:Connect(function(dt)
	for i = #flying, 1, -1 do
		local f = flying[i]
		f.t += dt
		local k = math.min(f.t / f.dur, 1)
		local to = f.target.Parent and f.target.Position or f.from
		local e = k * k * (3 - 2 * k)
		local pos = f.from:Lerp(to, e) + Vector3.new(0, math.sin(k * math.pi) * f.lift, 0)
		f.part.Position = pos
		f.part.Size = Vector3.one * (0.55 * (1 - 0.6 * k))
		if k >= 1 then
			f.part.Transparency = 1
			local part = f.part
			task.delay(0.3, function()
				part:Destroy()
			end)
			table.remove(flying, i)
			live -= 1
		end
	end
end)
