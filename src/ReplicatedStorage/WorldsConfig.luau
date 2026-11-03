-- Список миров для окна телепорта. Позиции сервер берёт сам (WorldTeleport.server.luau).
local W = {}
W.Worlds = {
	{ Id = "Meadow Isles", Name = "Meadow Isles", Emoji = "🌴", Top = Color3.fromRGB(130, 235, 120), Bottom = Color3.fromRGB(40, 150, 70), Desc = "Coins, eggs and pets", Speed = 0, Open = true },
	{ Id = "Neon District", Name = "Neon District", Emoji = "🌃", Top = Color3.fromRGB(230, 120, 255), Bottom = Color3.fromRGB(95, 40, 200), Desc = "Neon city and rare eggs", Speed = 3, Open = true },
	{ Id = "Sky Isles", Name = "Sky Isles", Emoji = "☁️", Top = Color3.fromRGB(150, 215, 255), Bottom = Color3.fromRGB(110, 120, 240), Desc = "Cloud world, sky eggs and magnets", Speed = 6, Open = true },
	{ Id = "Frozen Peaks", Name = "Frozen Peaks", Emoji = "❄️", Top = Color3.fromRGB(170, 235, 255), Bottom = Color3.fromRGB(60, 140, 220), Desc = "Ice world", Speed = 99, Open = false },
	{ Id = "Candy Kingdom", Name = "Candy Kingdom", Emoji = "🍭", Top = Color3.fromRGB(255, 170, 215), Bottom = Color3.fromRGB(220, 70, 150), Desc = "Sweet world", Speed = 99, Open = false },
}
function W.Find(id)
	for _, w in ipairs(W.Worlds) do
		if w.Id == id then
			return w
		end
	end
	return nil
end
return W
