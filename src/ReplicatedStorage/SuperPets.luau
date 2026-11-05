-- Супер-секретные питомцы: по 3 на каждый мир, выпадают из ЛЮБОГО яйца этого мира
-- с шансом 1 на 3 / 10 / 30 миллионов. В пулы яиц не входят, поэтому индекс и гарантия
-- (pity) не меняются. Внешне — главный Secret-питомец мира, крупнее и в особом облике.
-- Подключается в конце GameConfig: require(SuperPets)(Config) — дописывает Config.Pets.
local TIERS = {
	{ Key = "Celestial", Odds = 3_000_000, Mult = 3, Scale = 1.12, Look = 2, Icon = "💎" },
	{ Key = "Divine", Odds = 10_000_000, Mult = 6, Scale = 1.22, Look = 1, Icon = "👑" },
	{ Key = "Infinity", Odds = 30_000_000, Mult = 12, Scale = 1.32, Look = 3, Icon = "🌌" },
}
local WORLD_ORDER = { "island", "neon", "sky", "volcano", "galaxy", "frozen" }

return function(Config)
	Config.SuperTiers = TIERS
	Config.SuperByWorld = {}
	local worlds = {}
	for _, egg in ipairs(Config.Eggs) do
		worlds[egg.World] = worlds[egg.World] or {}
		table.insert(worlds[egg.World], egg)
	end
	local order = table.clone(WORLD_ORDER)
	for w in pairs(worlds) do
		if not table.find(order, w) then
			table.insert(order, w)
		end
	end
	for _, world in ipairs(order) do
		local eggs = worlds[world]
		if eggs then
			-- Основа — самый сильный Secret-питомец мира (из последнего яйца).
			local base, best = nil, -1
			for _, egg in ipairs(eggs) do
				for _, entry in ipairs(egg.Pool) do
					local def = Config.Pets[entry.Pet]
					if def and def.Rarity == "Secret" and def.Multiplier > best then
						base, best = entry.Pet, def.Multiplier
					end
				end
			end
			if base then
				local b = Config.Pets[base]
				local list = {}
				for tierIndex, tier in ipairs(TIERS) do
					local id = #Config.Pets + 1
					Config.Pets[id] = {
						Name = tier.Key .. " " .. b.Name,
						Rarity = "Secret",
						Multiplier = b.Multiplier * tier.Mult,
						Visual = b.Visual,
						Color = b.Color,
						EggId = b.EggId,
						Base = base,
						Super = tierIndex,
						SuperKey = tier.Key,
						Odds = tier.Odds,
						Scale = tier.Scale,
						Look = tier.Look,
						World = world,
					}
					list[tierIndex] = id
				end
				Config.SuperByWorld[world] = list
			end
		end
	end
	-- Бросок супер-питомца: luckMult умножает шансы (геймпассы удачи). Возвращает id или nil.
	function Config.RollSuper(eggId, r01, luckMult)
		local egg = Config.Eggs[eggId]
		local list = egg and Config.SuperByWorld[egg.World]
		if not list then
			return nil
		end
		local acc = 0
		for tierIndex = #TIERS, 1, -1 do
			acc += (luckMult or 1) / TIERS[tierIndex].Odds
			if r01 < acc then
				return list[tierIndex]
			end
		end
		return nil
	end
	function Config.FormatOdds(n)
		return n >= 1e6 and string.format("1 in %gM", n / 1e6) or string.format("1 in %d", n)
	end
end
