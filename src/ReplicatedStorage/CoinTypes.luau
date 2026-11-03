-- Виды монет по мирам: доля (Weight, %), ценность (Value), размер относительно обычной (Scale), цвет.
-- Сервер раздаёт виды монетам при старте (одинаково на каждом сервере — по номеру монеты Coin_N)
-- и пишет атрибуты Value, Kind, Rarity, CoinWorld. Клиент берёт отсюда цвета сияния и эффекта сбора.
local CoinTypes = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Диаметр обычной монеты: на 10% меньше прежних (3 студа в Meadow и Неонграде, 3,4 в Sky).
CoinTypes.BaseSize = { Meadow = 2.7, Neon = 2.7, Sky = 3.06 }

CoinTypes.Worlds = {
	Meadow = {
		Theme = { rgb(255, 215, 80), rgb(120, 235, 120) }, -- золото и свежая зелень
		Kinds = {
			{ Id = "Gold", Weight = 75, Value = 5, Scale = 1, Color = rgb(255, 210, 60) },
			{ Id = "Emerald", Weight = 25, Value = 15, Scale = 1.15, Color = rgb(50, 215, 115) },
		},
	},
	Neon = {
		Theme = { rgb(255, 80, 210), rgb(70, 230, 255) }, -- неоновые розовый и голубой
		Kinds = {
			{ Id = "Cyan", Weight = 65, Value = 25, Scale = 1, Color = rgb(70, 225, 255) },
			{ Id = "Pink", Weight = 25, Value = 50, Scale = 1.15, Color = rgb(255, 85, 200) },
			{ Id = "Violet", Weight = 10, Value = 120, Scale = 1.3, Color = rgb(165, 85, 255) },
		},
	},
	Sky = {
		Theme = { rgb(255, 220, 120), rgb(255, 255, 255) }, -- тёплое золото и белые облака
		Kinds = {
			{ Id = "Cloud", Weight = 60, Value = 150, Scale = 1, Color = rgb(255, 200, 110), Model = "Coin1" },
			{ Id = "Star", Weight = 30, Value = 300, Scale = 1.12, Color = rgb(190, 130, 255), Model = "Coin2" },
			{ Id = "Wings", Weight = 10, Value = 600, Scale = 1.25, Color = rgb(255, 225, 120), Model = "Coin3" },
		},
	},
}

-- Вид монеты по её номеру: детерминированно, чтобы раскладка не менялась от сервера к серверу.
function CoinTypes.Pick(worldId: string, index: number)
	local kinds = CoinTypes.Worlds[worldId].Kinds
	local roll = Random.new(index * 7919 + #worldId * 104729):NextNumber(0, 100)
	for rarity, kind in ipairs(kinds) do
		roll -= kind.Weight
		if roll <= 0 then
			return kind, rarity
		end
	end
	return kinds[#kinds], #kinds
end

-- Сияние: искры и мягкий ореол цвета монеты, тёплый свет. GameServer прячет их вместе с монетой.
function CoinTypes.AddGlow(coin: BasePart, color: Color3, rarity: number)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparkles"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 3 + rarity * 2
	sparks.Lifetime = NumberRange.new(0.8, 1.4)
	sparks.Speed = NumberRange.new(0.3, 0.9)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	sparks.Parent = coin
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "Aura"
	aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	aura.Rate = 2
	aura.Lifetime = NumberRange.new(1, 1.4)
	aura.Speed = NumberRange.new(0)
	aura.LockedToPart = true
	aura.Rotation = NumberRange.new(0, 360)
	aura.RotSpeed = NumberRange.new(-40, 40)
	aura.Color = ColorSequence.new(color)
	aura.LightEmission = 1
	local s = coin.Size.Magnitude * 0.55
	aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s), NumberSequenceKeypoint.new(0.5, s * 1.5), NumberSequenceKeypoint.new(1, s * 1.1) })
	aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.7), NumberSequenceKeypoint.new(1, 1) })
	aura.Parent = coin
	local light = coin:FindFirstChildWhichIsA("PointLight")
	if not light then
		light = Instance.new("PointLight")
		light.Range = 7
		light.Shadows = false
		light.Parent = coin
	end
	light.Color = color
	light.Brightness = 1.2 + rarity * 0.3
end

function CoinTypes.Mark(coin: BasePart, worldId: string, kind, rarity: number)
	coin:SetAttribute("Value", kind.Value)
	coin:SetAttribute("Kind", kind.Id)
	coin:SetAttribute("Rarity", rarity)
	coin:SetAttribute("CoinWorld", worldId)
end

return CoinTypes
