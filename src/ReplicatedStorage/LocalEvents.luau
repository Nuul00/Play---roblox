-- Локальные ивенты миров: у каждого мира свой. Во время ивента в этом мире монеты x2, а по миру
-- разбросаны тематические бонусы — подобрал = как 40 обычных монет мира (с бонусами игрока).
-- Frozen Peaks — своя «Метель» (FrozenEvent.server, атрибут FrozenStormEnd), здесь остальные миры.
-- Расписание общее для всех серверов (от UTC), миры сдвинуты, чтобы ивенты шли по очереди.
local rgb = Color3.fromRGB
local E = {}
E.Interval = 6 * 60 -- каждый мир раз в 6 минут
E.Duration = 60
E.Pickups = 18 -- бонусов за ивент (волнами)
E.Cap = 8 -- больше одному игроку за ивент не дать
E.Reward = 40 -- в обычных монетах мира

E.Worlds = {
	["Meadow Isles"] = {
		Key = "Meadow", Name = "BLOSSOM RAIN", Icon = "🌸", Item = "golden blossoms",
		Color = rgb(255, 140, 200), Color2 = rgb(255, 225, 120), Coin = "Meadow", Offset = 0,
	},
	["Neon District"] = {
		Key = "Neon", Name = "DISCO FEVER", Icon = "🪩", Item = "disco balls",
		Color = rgb(255, 80, 220), Color2 = rgb(80, 230, 255), Coin = "Neon", Offset = 72,
	},
	["Sky Isles"] = {
		Key = "Sky", Name = "STAR FALL", Icon = "🌠", Item = "fallen stars",
		Color = rgb(255, 220, 110), Color2 = rgb(190, 150, 255), Coin = "Sky", Offset = 144,
	},
	["Magma Volcano"] = {
		Key = "Volcano", Name = "LAVA GOLD", Icon = "🔥", Item = "molten gold",
		Color = rgb(255, 120, 40), Color2 = rgb(255, 220, 90), Coin = "Volcano", Offset = 216,
	},
	["Cosmic Galaxy"] = {
		Key = "Galaxy", Name = "METEOR SHOWER", Icon = "☄️", Item = "meteorites",
		Color = rgb(150, 110, 255), Color2 = rgb(90, 220, 255), Coin = "Galaxy", Offset = 288,
	},
}

-- атрибут workspace с концом ивента мира
function E.AttrEnd(world: string): string
	local d = E.Worlds[world]
	return "LocalEventEnd_" .. (d and d.Key or "?")
end
-- идёт ли ивент в мире сейчас
function E.Active(world: string?): boolean
	if not world or not E.Worlds[world] then
		return false
	end
	return (workspace:GetAttribute(E.AttrEnd(world)) or 0) > workspace:GetServerTimeNow()
end
-- когда начнётся следующий ивент мира (секунды сервера)
function E.NextStart(world: string, now: number): number
	local d = E.Worlds[world]
	local base = math.floor((now - d.Offset) / E.Interval) * E.Interval + d.Offset
	if base <= now then
		base += E.Interval
	end
	return base
end
return E
