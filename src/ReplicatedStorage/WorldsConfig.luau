-- Список миров для окна телепорта. Позиции сервер берёт сам (WorldTeleport.server.luau).
local W = {}
W.Worlds = {
	{ Id = "Meadow Isles", Name = "Meadow Isles", Emoji = "🌴", Top = Color3.fromRGB(130, 235, 120), Bottom = Color3.fromRGB(40, 150, 70), Desc = "Coins, eggs and pets", Speed = 0, Open = true },
	{ Id = "Neon District", Name = "Neon District", Emoji = "🌃", Top = Color3.fromRGB(230, 120, 255), Bottom = Color3.fromRGB(95, 40, 200), Desc = "Neon city and rare eggs", Speed = 0, Cost = 1000, Open = true },
	{ Id = "Sky Isles", Name = "Sky Isles", Emoji = "☁️", Top = Color3.fromRGB(150, 215, 255), Bottom = Color3.fromRGB(110, 120, 240), Desc = "Cloud world, sky eggs and magnets", Speed = 0, Cost = 25e6, Open = true },
	{ Id = "Frozen Peaks", Name = "Frozen Peaks", Emoji = "❄️", Top = Color3.fromRGB(170, 235, 255), Bottom = Color3.fromRGB(60, 140, 220), Desc = "Ice peaks, crystals and aurora", Speed = 0, Cost = 18e9, Open = true },
	{ Id = "Magma Volcano", Name = "Magma Volcano", Emoji = "🌋", Top = Color3.fromRGB(255, 150, 60), Bottom = Color3.fromRGB(170, 40, 20), Desc = "Lava rivers, fire pets and magnets", Speed = 0, Cost = 1.2e12, Open = true },
	{ Id = "Cosmic Galaxy", Name = "Cosmic Galaxy", Emoji = "🌌", Top = Color3.fromRGB(150, 140, 255), Bottom = Color3.fromRGB(60, 30, 140), Desc = "Planets, stars and cosmic pets", Speed = 0, Cost = 3e14, Open = true },
}
-- Cost — разовая цена открытия мира (монеты). v2: ≈2–2.5× самого дорогого яйца прошлого мира, без «стены». Открытые миры остаются после ребёрса
-- (атрибут Save_Unlock_<ключ> сохраняется в профиле).
function W.UnlockKey(id)
	return "Save_Unlock_" .. string.gsub(id, "%s", "")
end
function W.Find(id)
	for _, w in ipairs(W.Worlds) do
		if w.Id == id then
			return w
		end
	end
	return nil
end
return W
