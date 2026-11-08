-- Studio-only QA: ищет декор, который стоит на краю площадки/острова и свисает над пустотой
-- (фонари, деревья, грибы и т.п. за заборчиком или наполовину в воздухе).
-- Usage (Play → Server command bar): require(game.ServerScriptService.Dev.EdgeAudit)()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local KEY = { "Lamp", "Tree", "Mushroom", "Bench", "Fountain", "Windmill", "Statue", "Palm", "Pine", "Snowman", "Igloo", "Crystal",
	"Pillar", "Monolith", "Observatory", "Vending", "Arcade", "Penguin", "Sled", "Decor_", "Bush", "Rock", "Sign", "Chest", "Booth", "Kiosk", "Stand", "TripoModel" }
-- парящее по задумке
local FLOAT = { "Balloon", "HoverCar", "SkyIsland", "Islet", "Cloud", "Star", "Crown", "Trophy", "Emblem", "Asteroid", "Planet", "Coin", "Egg" }

local function has(name, list)
	for _, k in list do
		if string.find(name, k, 1, true) then return true end
	end
	return false
end

return function(opts)
	assert(RunService:IsStudio(), "Studio only")
	opts = opts or {}
	local miss = opts.miss or 2 -- сколько углов из 4 без опоры считается «свисает»
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local chars = {}
	for _, p in Players:GetPlayers() do
		if p.Character then table.insert(chars, p.Character) end
	end
	local found, seen = {}, {}
	local function check(m)
		if seen[m] then return end
		seen[m] = true
		if CollectionService:HasTag(m, "BoardEmblem") or has(m.Name, FLOAT) or m:GetAttribute("Tripo") then return end
		-- спрятанные оригиналы (заменены моделями Tripo) не проверяем
		local visible = false
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 0.95 then visible = true break end
		end
		if not visible then return end
		local ok, cf, size = pcall(m.GetBoundingBox, m)
		if not ok or size.Magnitude < 2 or size.Magnitude > 80 then return end
		rp.FilterDescendantsInstances = { m, table.unpack(chars) }
		local bottom = cf.Position.Y - size.Y / 2
		local hx, hz = size.X / 2 * 0.8, size.Z / 2 * 0.8
		local bad = 0
		local center = workspace:Raycast(Vector3.new(cf.Position.X, bottom + 1.5, cf.Position.Z), Vector3.new(0, -12, 0), rp)
		for _, o in { { hx, hz }, { -hx, hz }, { hx, -hz }, { -hx, -hz } } do
			local p = cf * Vector3.new(o[1], 0, o[2])
			local hit = workspace:Raycast(Vector3.new(p.X, bottom + 1.5, p.Z), Vector3.new(0, -12, 0), rp)
			if not hit then bad += 1 end
		end
		if not center or bad >= miss then
			local s, n = m.Name, m.Parent
			for _ = 1, 3 do
				if not n or n == workspace then break end
				s = n.Name .. "/" .. s
				n = n.Parent
			end
			table.insert(found, string.format("%s  center=%s  corners-without-ground=%d  at %s", s, center and "ok" or "AIR", bad, tostring(Vector3.new(math.floor(cf.Position.X), math.floor(bottom), math.floor(cf.Position.Z)))))
		end
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and has(d.Name, KEY) then
			-- проверяем только самую внешнюю подходящую модель
			local a = d.Parent
			local inner = false
			while a and a ~= workspace do
				if a:IsA("Model") and has(a.Name, KEY) then inner = true break end
				a = a.Parent
			end
			if not inner then check(d) end
		end
	end
	print(("[EdgeAudit] %d suspicious"):format(#found))
	for _, l in found do
		print("[EdgeAudit] " .. l)
	end
	return found
end
