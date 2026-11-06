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
-- Id супер-питомцев ЗАКРЕПЛЕНЫ (они хранятся в профилях): 154 + (номер мира − 1) * 3 + (ступень − 1).
-- Новых обычных питомцев добавлять с id 172 и дальше, порядок WORLD_ORDER не менять.
local SUPER_BASE = 154

-- Мифические секретки (id 172-179, закреплены): 8 уникальных питомцев с собственным обликом.
-- Шесть — по одному на мир (1 на 15 млн), две «космические» — только из яиц Galaxy (1 на 50 млн).
-- Base — чья модель берётся, Look — особый облик (PetVisuals.ApplyLook), Mult — от силы основы.
local SPECIALS = {
	{ Id = 172, Name = "Blossom Hologram", Base = 42, Look = "hologram", World = "island", Odds = 15_000_000, Mult = 25 },
	{ Id = 173, Name = "Glitch Core", Base = 53, Look = "void", World = "neon", Odds = 15_000_000, Mult = 25 },
	{ Id = 174, Name = "Starlight Leviathan", Base = 73, Look = "starlight", World = "sky", Odds = 15_000_000, Mult = 25 },
	{ Id = 175, Name = "Frostbite Wyvern", Base = 145, Look = "frost", World = "frozen", Odds = 15_000_000, Mult = 25 },
	{ Id = 176, Name = "Molten Colossus", Base = 97, Look = "molten", World = "volcano", Odds = 15_000_000, Mult = 25 },
	{ Id = 177, Name = "Void Phoenix", Base = 121, Look = "shadow", World = "galaxy", Odds = 15_000_000, Mult = 25 },
	{ Id = 178, Name = "Prism Phoenix King", Base = 89, Look = "prism", World = "galaxy", Odds = 50_000_000, Mult = 24 },
	{ Id = 179, Name = "Empress of Eternity", Base = 81, Look = "blossom", World = "galaxy", Odds = 50_000_000, Mult = 60 },
}

return function(Config)
	Config.SuperTiers = TIERS
	Config.SuperByWorld = {}
	local worlds = {}
	for _, egg in ipairs(Config.Eggs) do
		worlds[egg.World] = worlds[egg.World] or {}
		table.insert(worlds[egg.World], egg)
	end
	for worldIndex, world in ipairs(WORLD_ORDER) do
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
					local id = SUPER_BASE + (worldIndex - 1) * #TIERS + (tierIndex - 1)
					assert(Config.Pets[id] == nil, "SuperPets: id " .. id .. " is taken")
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
	-- Мифические и космические секретки.
	Config.SuperTiers = table.clone(TIERS)
	Config.SuperTiers[4] = { Key = "Mythic", Icon = "🔮" }
	Config.SuperTiers[5] = { Key = "Cosmic", Icon = "🌠" }
	Config.Specials = {}
	for _, sp in ipairs(SPECIALS) do
		local b = Config.Pets[sp.Base]
		assert(b and Config.Pets[sp.Id] == nil, "SuperPets: special id " .. sp.Id)
		Config.Pets[sp.Id] = {
			Name = sp.Name,
			Rarity = "Secret",
			Multiplier = b.Multiplier * sp.Mult,
			Visual = b.Visual,
			Color = b.Color,
			EggId = b.EggId,
			Base = sp.Base,
			Super = sp.World and 4 or 5,
			SuperKey = sp.World and "Mythic" or "Cosmic",
			Odds = sp.Odds,
			Scale = sp.World and 1.3 or 1.45,
			Look = sp.Look,
			World = sp.World,
			Special = true,
		}
		table.insert(Config.Specials, sp.Id)
	end
	-- Эксклюзивные питомцы за Robux (id 180-185, закреплены): по одному на мир, из яиц не выпадают.
	-- Покупка выдаёт питомца лучшего открытого мира — поэтому он полезен на любом этапе.
	-- Сила: ×1.5 от главной Secret мира (слабее супер-секреток ×3+). В индекс не входят (Super).
	local EXCLUSIVE_LOOK = { island = "blossom", neon = "void", sky = "prism", frozen = "frost", volcano = "molten", galaxy = "starlight" }
	Config.Exclusives = {}
	for worldIndex, world in ipairs(WORLD_ORDER) do
		local list = Config.SuperByWorld[world]
		local baseId = list and Config.Pets[list[1]] and Config.Pets[list[1]].Base
		local b = baseId and Config.Pets[baseId]
		if b then
			local id = 179 + worldIndex
			assert(Config.Pets[id] == nil, "SuperPets: exclusive id " .. id)
			Config.Pets[id] = {
				Name = "Royal " .. b.Name,
				Rarity = "Secret",
				Multiplier = b.Multiplier * 1.5,
				Visual = b.Visual,
				Color = b.Color,
				EggId = b.EggId,
				Base = baseId,
				Super = 4,
				SuperKey = "Exclusive",
				Scale = 1.35,
				Look = EXCLUSIVE_LOOK[world],
				World = world,
				Exclusive = true,
			}
			Config.Exclusives[world] = id
		end
	end
	-- Vault Golem — редкая награда данжа Coin Rush (id 222-227, закреплены: по одному на мир).
	-- Выдаётся питомец лучшего открытого мира игрока; сила ×1.6 от главной Secret этого мира.
	Config.VaultPets = {}
	for worldIndex, world in ipairs(WORLD_ORDER) do
		local list = Config.SuperByWorld[world]
		local baseId = list and Config.Pets[list[1]] and Config.Pets[list[1]].Base
		local b = baseId and Config.Pets[baseId]
		if b then
			local id = 221 + worldIndex
			assert(Config.Pets[id] == nil, "SuperPets: vault id " .. id)
			Config.Pets[id] = {
				Name = "Vault Golem",
				Rarity = "Secret",
				Multiplier = math.floor(b.Multiplier * 1.6 * 100 + 0.5) / 100,
				Visual = b.Visual,
				Color = b.Color,
				EggId = b.EggId,
				Base = baseId,
				Super = 4,
				SuperKey = "Exclusive",
				Scale = 1.35,
				Look = "molten",
				World = world,
				Exclusive = true,
			}
			Config.VaultPets[world] = id
		end
	end
	-- Royal Egg — яйцо за Robux (id питомцев 186-221, закреплены: 186 + (мир−1)·6 + (ступень−1)).
	-- 6 питомцев; сила — доля от главной Secret лучшего открытого мира игрока, поэтому яйцо полезно
	-- на любом этапе. Шансы фиксированы (их показывает окно яйца). В индекс и машины не входят.
	local ROYAL = {
		{ Rarity = "Common", Chance = 50, Pct = 0.5, Name = "Crown Pup", Model = "RoyalEgg1" },
		{ Rarity = "Uncommon", Chance = 30, Pct = 0.8, Name = "Velvet Fox", Model = "RoyalEgg2" },
		{ Rarity = "Rare", Chance = 13.9, Pct = 1.1, Name = "Sapphire Owl", Model = "RoyalEgg3" },
		{ Rarity = "Epic", Chance = 5, Pct = 1.4, Name = "Emerald Griffin", Model = "RoyalEgg4" },
		{ Rarity = "Legendary", Chance = 1, Pct = 2, Name = "Golden Phoenix", Model = "RoyalEgg5" },
		{ Rarity = "Secret", Chance = 0.1, Pct = 3, Name = "Imperial Dragon", Model = "RoyalEgg6" },
	}
	-- пока нет моделей Tripo — облик берём у питомцев последнего яйца мира (по редкости)
	local FALLBACK_SLOT = { 1, 3, 5, 6, 7, 8 }
	local ROYAL_LOOK = { nil, nil, "prism", "frost", "blossom", "starlight" }
	Config.RobuxEgg = { Name = "Royal Egg", Color = Color3.fromRGB(255, 200, 70), World = "royal", Tiers = ROYAL, ByWorld = {} }
	for worldIndex, world in ipairs(WORLD_ORDER) do
		local list = Config.SuperByWorld[world]
		local topId = list and Config.Pets[list[1]] and Config.Pets[list[1]].Base
		local top = topId and Config.Pets[topId]
		local lastEgg
		for id, egg in ipairs(Config.Eggs) do
			if egg.World == world then
				lastEgg = id
			end
		end
		if top and lastEgg then
			local ids = {}
			for t, tier in ipairs(ROYAL) do
				local id = 185 + (worldIndex - 1) * 6 + t
				assert(Config.Pets[id] == nil, "SuperPets: royal egg id " .. id)
				local pool = Config.Eggs[lastEgg].Pool
				local base = pool[math.min(FALLBACK_SLOT[t], #pool)].Pet
				local b = Config.Pets[base]
				Config.Pets[id] = {
					Name = tier.Name,
					Rarity = tier.Rarity,
					Multiplier = math.floor(top.Multiplier * tier.Pct * 100 + 0.5) / 100,
					Visual = b.Visual,
					Color = b.Color,
					EggId = lastEgg,
					Base = base,
					Template = tier.Model,
					Super = 4,
					SuperKey = "Royal",
					Scale = 1.1 + t * 0.05,
					Look = ROYAL_LOOK[t] or 1, -- 1 = золотая отделка (ApplyVariant)
					World = world,
					Exclusive = true,
					RoyalTier = t,
				}
				ids[t] = id
			end
			Config.RobuxEgg.ByWorld[world] = ids
		end
	end
	function Config.RollRobuxEgg(world, r100)
		local ids = Config.RobuxEgg.ByWorld[world] or Config.RobuxEgg.ByWorld.island
		local acc = 0
		for t = #ROYAL, 1, -1 do -- сначала редкие: при сумме 100 порядок не важен, но так нагляднее
			acc += ROYAL[t].Chance
			if r100 <= acc then
				return ids[t]
			end
		end
		return ids[1]
	end
	function Config.RollSuper(eggId, r01, luckMult)
		local egg = Config.Eggs[eggId]
		local list = egg and Config.SuperByWorld[egg.World]
		if not list then
			return nil
		end
		local acc = 0
		-- сначала самые редкие: мифическая секретка мира и две космические (из любого яйца)
		for _, id in ipairs(Config.Specials) do
			local def = Config.Pets[id]
			if def.World == nil or def.World == egg.World then
				acc += (luckMult or 1) / def.Odds
				if r01 < acc then
					return id
				end
			end
		end
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
