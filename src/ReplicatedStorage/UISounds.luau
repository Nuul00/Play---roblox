-- Звуки интерфейса (клиент). Только встроенные звуки Roblox (rbxasset://sounds/...): они есть у
-- всех и не требуют загрузки ассетов. UISounds.Play("buy") — короткий звук без задержки.
local SoundService = game:GetService("SoundService")
local UISounds = {}

local DEFS = {
	click = { "switch.wav", 0.35, 1.1 },
	buy = { "electronicpingshort.wav", 0.45, 1.35 },
	fail = { "bass.wav", 0.35, 0.8 },
	reward = { "electronicpingshort.wav", 0.5, 1.7 },
	crack = { "snap.wav", 0.5, 1 },
	hatch = { "electronicpingshort.wav", 0.5, 1.1 },
	rare = { "victory.wav", 0.45, 1.25 },
	fanfare = { "victory.wav", 0.6, 1 },
	unlock = { "victory.wav", 0.55, 0.9 },
}

local cache = {}
local last = {}
function UISounds.Play(name: string)
	local def = DEFS[name]
	if not def then
		return
	end
	-- один и тот же звук не чаще раза в 60 мс (×9 открытие, MAX-прокачка и т.п.)
	local now = os.clock()
	if last[name] and now - last[name] < 0.06 then
		return
	end
	last[name] = now
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.Name = "UI_" .. name
		s.SoundId = "rbxasset://sounds/" .. def[1]
		s.Volume = def[2]
		s.PlaybackSpeed = def[3]
		s.Parent = SoundService
		cache[name] = s
	end
	SoundService:PlayLocalSound(s)
end

return UISounds
