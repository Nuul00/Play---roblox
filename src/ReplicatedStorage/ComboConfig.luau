-- Coin Combo: собирай монеты без пауз — растёт комбо и множитель монет.
-- Пауза дольше Window секунд — комбо сгорает. Общий для сервера (GameServer) и клиента (ComboHUD).
local ComboConfig = {}
ComboConfig.Window = 2.5 -- сек между монетами, чтобы комбо не сгорело
-- ступени: с какого комбо какой множитель монет (максимум ×1.5 — экономика не ломается)
ComboConfig.Tiers = {
	{ At = 15, Mult = 1.1, Name = "NICE", Color = Color3.fromRGB(120, 230, 255) },
	{ At = 40, Mult = 1.2, Name = "GREAT", Color = Color3.fromRGB(110, 240, 130) },
	{ At = 80, Mult = 1.35, Name = "AMAZING", Color = Color3.fromRGB(255, 200, 60) },
	{ At = 150, Mult = 1.5, Name = "UNSTOPPABLE", Color = Color3.fromRGB(255, 90, 200) },
}
function ComboConfig.TierOf(combo: number): number
	local t = 0
	for i, tier in ipairs(ComboConfig.Tiers) do
		if combo >= tier.At then
			t = i
		end
	end
	return t
end
function ComboConfig.MultOf(combo: number): number
	local t = ComboConfig.TierOf(combo)
	return t > 0 and ComboConfig.Tiers[t].Mult or 1
end
return ComboConfig
