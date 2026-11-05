-- Картинки HUD для каждого мира (загружены в Roblox, исходники в assets/hud/<мир>).
-- Скрипт HudSkin.client.luau надевает скин того мира, где сейчас игрок (атрибут CurrentWorld).
-- Мир без записи (или с пустой таблицей) показывает старый, нарисованный кодом HUD.
local function id(n)
	return "rbxassetid://" .. n
end

local skins = {
	["Sky Isles"] = {
		Btn_Index = id(88641355523431), -- из первого набора, без плашки под надписью
		Btn_Items = id(89863492754384),
		Btn_Stats = id(81896402914065),
		Btn_Teleport = id(122500134734053),
		Btn_Daily = id(121386316202129),
		Btn_Rebirth = id(125684832032023),
		Btn_Settings = id(96260478413145),
		Dot_Notify = id(134536403609138),
		Icon_Coin = id(70577537318809),
		Icon_Speed = id(135198384581197),
		Icon_Multiplier = id(97601189630131),
		Icon_Magnet = id(78428431713161),
		Tile_Gold = id(106995575136587), -- нарезаны под размер плиток 230x64
		Tile_Blue = id(114165190909004), -- 230x48
		Tile_Pink = id(76027179982049),
		Tile_Purple = id(114868347922461),
		Bar_Menu = id(73420073290291),
		Pill_Eggs = id(94370499607707),
		Plate_Title = id(101898875621576),
		Frame_Window = id(116320321540886),
		-- Цвета для кнопки меню «≡» и подложки окна меню (рисуются кодом).
		MenuTop = Color3.fromRGB(176, 110, 240),
		MenuBottom = Color3.fromRGB(110, 50, 200),
		RimColor = Color3.fromRGB(255, 196, 70),
		TitleColor = Color3.fromRGB(255, 244, 214),
		InkColor = Color3.fromRGB(70, 30, 110),
	},
	["Meadow Isles"] = {
		Btn_Index = id(104974236481668),
		Btn_Items = id(114075224596760),
		Btn_Stats = id(123518183999700),
		Btn_Teleport = id(79098521181451),
		Btn_Daily = id(78439314435183),
		Btn_Rebirth = id(101736977090566),
		Btn_Settings = id(133920498319124),
		Dot_Notify = id(112043877481460),
		Icon_Coin = id(72186119049876),
		Icon_Speed = id(140447830456392),
		Icon_Multiplier = id(79453197539387),
		Icon_Magnet = id(119673058489528),
		Tile_Gold = id(118362275782261),
		Tile_Blue = id(104255571541580),
		Tile_Pink = id(125587789218548),
		Tile_Purple = id(88758981347036),
		Plate_Title = id(94507067642184),
		Frame_Window = id(94400832847125),
		MenuTop = Color3.fromRGB(130, 205, 255),
		MenuBottom = Color3.fromRGB(60, 150, 230),
		RimColor = Color3.fromRGB(255, 200, 60),
		TitleColor = Color3.fromRGB(255, 255, 240),
		InkColor = Color3.fromRGB(40, 80, 30),
	},
	["Neon District"] = {
		Btn_Index = id(99144797099074),
		Btn_Items = id(88451603624630),
		Btn_Stats = id(78727752046309),
		Btn_Teleport = id(84340642670683),
		Btn_Daily = id(134649289832916),
		Btn_Rebirth = id(126878844228114),
		Btn_Settings = id(117660781410696),
		Dot_Notify = id(117222460312624),
		Icon_Coin = id(125874103204402),
		Icon_Speed = id(117175588167040),
		Icon_Multiplier = id(140426435069231),
		Icon_Magnet = id(94740712274612),
		Tile_Gold = id(122870591802062),
		Tile_Blue = id(83183227898043),
		Tile_Pink = id(94604081353380),
		Tile_Purple = id(96812786089559),
		Plate_Title = id(117451035153506),
		Frame_Window = id(121764880003429),
		MenuTop = Color3.fromRGB(110, 50, 190),
		MenuBottom = Color3.fromRGB(35, 15, 80),
		RimColor = Color3.fromRGB(255, 80, 220),
		TitleColor = Color3.fromRGB(130, 240, 255),
		InkColor = Color3.fromRGB(40, 10, 70),
	},
}

-- Frozen Peaks: картинки Sky Isles, окрашенные в ледяной цвет, и свои цвета меню.
local frozen = table.clone(skins["Sky Isles"])
frozen.Tint = Color3.fromRGB(185, 225, 255)
frozen.MenuTop = Color3.fromRGB(140, 210, 255)
frozen.MenuBottom = Color3.fromRGB(60, 120, 220)
frozen.RimColor = Color3.fromRGB(230, 248, 255)
frozen.TitleColor = Color3.fromRGB(235, 250, 255)
frozen.InkColor = Color3.fromRGB(20, 60, 120)
skins["Frozen Peaks"] = frozen

-- Magma Volcano: свой набор картинок (ChatGPT, лава и обсидиан), загружен в Roblox 2026-11-05.
-- Bar_Menu и Pill_Eggs не рисовались — берутся от Sky Isles (в HUD сейчас не используются).
local volcano = table.clone(skins["Sky Isles"])
volcano.Tint = nil
volcano.Frame_Window = id(82451449876847)
volcano.Btn_Index = id(120962969762124)
volcano.Btn_Items = id(84394213742041)
volcano.Btn_Stats = id(85210234869160)
volcano.Btn_Teleport = id(139281317732175)
volcano.Btn_Daily = id(107214889217718)
volcano.Btn_Rebirth = id(136589170322886)
volcano.Btn_Settings = id(126281612938448)
volcano.Plate_Title = id(82443586756128)
volcano.Icon_Coin = id(72453585666590)
volcano.Icon_Speed = id(115243081356859)
volcano.Icon_Multiplier = id(124748924960000)
volcano.Icon_Magnet = id(114873251232370)
volcano.Tile_Gold = id(114536206150257)
volcano.Tile_Blue = id(88951605223108)
volcano.Tile_Pink = id(92676642717758)
volcano.Tile_Purple = id(92084641121769)
volcano.Dot_Notify = id(83024592090154)
volcano.MenuTop = Color3.fromRGB(255, 130, 60)
volcano.MenuBottom = Color3.fromRGB(180, 40, 20)
volcano.RimColor = Color3.fromRGB(255, 210, 90)
volcano.TitleColor = Color3.fromRGB(255, 240, 210)
volcano.InkColor = Color3.fromRGB(90, 25, 10)
skins["Magma Volcano"] = volcano
-- Cosmic Galaxy: свой набор картинок (ChatGPT, туманности и планеты), загружен в Roblox 2026-11-05.
local galaxy = table.clone(skins["Sky Isles"])
galaxy.Tint = nil
galaxy.Frame_Window = id(125767747125521)
galaxy.Btn_Index = id(117878625799972)
galaxy.Btn_Items = id(91749231663808)
galaxy.Btn_Stats = id(79247762224247)
galaxy.Btn_Teleport = id(132494773092038)
galaxy.Btn_Daily = id(112884142040422)
galaxy.Btn_Rebirth = id(73036520770468)
galaxy.Btn_Settings = id(135317416314893)
galaxy.Plate_Title = id(93446146678669)
galaxy.Icon_Coin = id(108241238303989)
galaxy.Icon_Speed = id(131727922688856)
galaxy.Icon_Multiplier = id(117568879466133)
galaxy.Icon_Magnet = id(104592704526076)
galaxy.Tile_Gold = id(110963300580359)
galaxy.Tile_Blue = id(128633458715693)
galaxy.Tile_Pink = id(122404622940845)
galaxy.Tile_Purple = id(107129994819385)
galaxy.Dot_Notify = id(134935033021120)
galaxy.MenuTop = Color3.fromRGB(140, 110, 255)
galaxy.MenuBottom = Color3.fromRGB(50, 30, 140)
galaxy.RimColor = Color3.fromRGB(130, 230, 255)
galaxy.TitleColor = Color3.fromRGB(235, 235, 255)
galaxy.InkColor = Color3.fromRGB(25, 15, 70)
skins["Cosmic Galaxy"] = galaxy

return skins
