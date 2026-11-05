-- Studio-only QA: checks that props stand level, sit on the ground and egg rows are symmetric.
-- Usage (Play → Server command bar): require(game.ServerScriptService.Dev.LayoutAudit)()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SKIP = { "Reeds", "LilyPad", "Rock", "Flower", "Grass", "Pebble", "Mushroom", "Cloud", "Leaf", "Bush", "Crystal", "Spark" }
local IGNORE = { Coins = true, CoinFX = true, EggFX = true, Pets = true, Sparks = true, Clouds = true, Stars = true, Particles = true }
local KEY = { "EggStand", "Machine", "Shop", "Chest", "Portal", "Board", "Sign", "Leaderboard", "Fountain", "Statue", "Lamp", "Bench", "Arch", "Gate", "Tree", "House", "Booth", "Kiosk", "Stand", "Pedestal", "Tripo" }

local function isKey(name)
	for _, k in KEY do
		if string.find(name, k, 1, true) then return true end
	end
	return false
end

local function path(inst)
	local s, n = inst.Name, inst.Parent
	for _ = 1, 3 do
		if not n or n == workspace then break end
		s = n.Name .. "/" .. s; n = n.Parent
	end
	return s
end

return function(opts)
	assert(RunService:IsStudio(), "Studio only")
	opts = opts or {}
	local tiltLim, gapLim = opts.tilt or 1.5, opts.gap or 0.6
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.RespectCanCollide = true
	local chars = {}
	for _, p in Players:GetPlayers() do if p.Character then table.insert(chars, p.Character) end end

	local issues, stats, stands = {}, { checked = 0 }, {}
	local seen = {}
	local function add(sev, msg) table.insert(issues, { sev, msg }) end

	local function check(m)
		if seen[m] then return end
		for _, k in SKIP do if string.find(m.Name, k, 1, true) then return end end
		seen[m] = true
		local ok, cf, size = pcall(function()
			if m:IsA("Model") then return m:GetBoundingBox() end
			return m.CFrame, m.Size
		end)
		if not ok or size.Magnitude < 2 or size.Magnitude > 400 then return end
		stats.checked += 1
		local pivot = m:IsA("Model") and m:GetPivot() or m.CFrame
		local tilt = math.deg(math.acos(math.clamp(pivot.UpVector:Dot(Vector3.yAxis), -1, 1)))
		if tilt > tiltLim and tilt < 60 then
			add(tilt > 5 and 2 or 1, string.format("TILT %.1f° %s", tilt, path(m)))
		end
		-- ground contact
		local bottom = cf.Position.Y - size.Y / 2
		local f = { m }
		for _, c in chars do table.insert(f, c) end
		rp.FilterDescendantsInstances = f
		local origin = Vector3.new(cf.Position.X, bottom + size.Y, cf.Position.Z)
		local hit = workspace:Raycast(origin, Vector3.new(0, -(size.Y + 40), 0), rp)
		if hit then
			local gap = bottom - hit.Position.Y
			if gap > gapLim and gap < 30 then
				add(gap > 2 and 2 or 1, string.format("FLOAT %.1f %s (over %s)", gap, path(m), hit.Instance.Name))
			elseif gap < -math.max(1.5, size.Y * 0.35) then
				add(1, string.format("SUNK %.1f %s (in %s)", -gap, path(m), hit.Instance.Name))
			end
		elseif string.find(m.Name, "EggStand", 1, true) or string.find(m.Name, "Machine", 1, true) then
			add(2, "NO GROUND " .. path(m))
		end
		local id = string.match(m.Name, "^EggStand(%d+)$")
		if id then
			local root = m.Parent
			stands[root] = stands[root] or {}
			table.insert(stands[root], { id = tonumber(id), pos = pivot.Position, yaw = math.deg(math.atan2(-pivot.LookVector.X, -pivot.LookVector.Z)) })
		end
	end

	local function walk(node, depth)
		for _, c in node:GetChildren() do
			if IGNORE[c.Name] or c:IsA("Terrain") or c:IsA("Camera") or Players:GetPlayerFromCharacter(c) then continue end
			if c:IsA("Model") then
				if isKey(c.Name) or depth <= 2 then check(c) end
				if depth < 4 and not string.find(c.Name, "Tripo", 1, true) then walk(c, depth + 1) end
			elseif c:IsA("Folder") then
				if depth < 5 then walk(c, depth + 1) end
			elseif c:IsA("BasePart") and depth <= 2 and c.Anchored and c.Size.Y > 3 and isKey(c.Name) then
				check(c)
			end
		end
	end
	walk(workspace, 0)

	-- symmetry of egg rows: equal spacing + consistent facing
	for root, list in stands do
		if #list < 2 then continue end
		table.sort(list, function(a, b) return a.id < b.id end)
		local gaps, mn, mx = {}, math.huge, 0
		for i = 2, #list do
			local d = (list[i].pos - list[i - 1].pos) * Vector3.new(1, 0, 1)
			local g = d.Magnitude
			table.insert(gaps, string.format("%.1f", g)); mn = math.min(mn, g); mx = math.max(mx, g)
		end
		local yaws, ys = {}, {}
		for _, s in list do table.insert(yaws, string.format("%d", math.floor(s.yaw + 0.5))); table.insert(ys, string.format("%.1f", s.pos.Y)) end
		local line = string.format("EGGS %s ids=%d..%d gaps=[%s] yaw=[%s] y=[%s]", path(root), list[1].id, list[#list].id, table.concat(gaps, ","), table.concat(yaws, ","), table.concat(ys, ","))
		add((mx - mn > 0.5) and 2 or 0, line)
	end

	local order = { EGGS = 0, TILT = 1, FLOAT = 2, ["NO GROUND"] = 3, SUNK = 4 }
	local function kind(msg) return string.match(msg, "^(%u+ ?%u*)") or "" end
	-- collapse duplicates (same kind + same path) into one line with a counter
	local agg, list = {}, {}
	for _, it in issues do
		local key = string.gsub(it[2], "[%d%.%-]+", "#", 1)
		if agg[key] then agg[key].n += 1 else agg[key] = { sev = it[1], msg = it[2], n = 1 }; table.insert(list, agg[key]) end
	end
	table.sort(list, function(a, b)
		local ka, kb = order[kind(a.msg)] or 9, order[kind(b.msg)] or 9
		if ka ~= kb then return ka < kb end
		return a.msg < b.msg
	end)
	local lines = { string.format("LAYOUT AUDIT  checked=%d  issues=%d (unique %d)", stats.checked, #issues, #list) }
	for _, it in list do
		table.insert(lines, (it.sev == 2 and "! " or it.sev == 1 and "- " or "  ") .. it.msg .. (it.n > 1 and ("  x" .. it.n) or ""))
	end
	local text = table.concat(lines, "\n")
	print("[AUD]\n" .. text)
	for _, p in Players:GetPlayers() do
		local pg = p:FindFirstChild("PlayerGui")
		if pg then
			local old = pg:FindFirstChild("LayoutAuditGui"); if old then old:Destroy() end
			local g = Instance.new("ScreenGui"); g.Name = "LayoutAuditGui"; g.DisplayOrder = 1e6; g.IgnoreGuiInset = true
			local f = Instance.new("TextLabel"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = Color3.new(0, 0, 0); f.BackgroundTransparency = 0.05
			f.TextColor3 = Color3.new(1, 1, 1); f.Font = Enum.Font.Code; f.TextSize = opts.size or 14; f.TextXAlignment = Enum.TextXAlignment.Left
			f.TextYAlignment = Enum.TextYAlignment.Top; f.Text = text; f.Parent = g
			g.Parent = pg
		end
	end
	return issues
end
