-- Generated catalog: edit tools/catalog.json generator for pet names, odds and prices.
local Config = {}
Config.CoinValue=5
Config.CoinRespawnSeconds=8
Config.BaseWalkSpeed=16
Config.SpeedPerLevel=4
Config.MaxSpeedLevel=10
Config.FirstUpgradeCost=10
Config.ShopDistance=14
Config.PurchaseCooldown=0.4
Config.ShopkeeperUserId=1361632228
Config.MaxIncomeLevel=10
Config.BaseMagnetRadius=3
Config.MagnetRadiusGrowth=0.10
Config.MaxMagnetLevel=10
Config.EnableGlobalBoards=true
Config.EnableStudioDataStores=false
Config.Worlds={island={Name="Meadow Isles",CenterX=0,Width=300,Depth=460,BaseValue=5},neon={Name="Neon District",CenterX=500,Width=300,Depth=460,BaseValue=25}}
Config.Pets={
[1]={Name="Clover Bunny",Rarity="Common",Multiplier=1.15,Visual="bunny",Color=Color3.fromRGB(81,197,160),EggId=1},
[2]={Name="Honey Pup",Rarity="Common",Multiplier=1.25,Visual="dog",Color=Color3.fromRGB(112,228,126),EggId=1},
[3]={Name="Meadow Cat",Rarity="Uncommon",Multiplier=1.5,Visual="cat",Color=Color3.fromRGB(143,194,157),EggId=1},
[4]={Name="Acorn Fox",Rarity="Uncommon",Multiplier=1.7,Visual="fox",Color=Color3.fromRGB(109,225,188),EggId=1},
[5]={Name="Moss Penguin",Rarity="Rare",Multiplier=2,Visual="penguin",Color=Color3.fromRGB(140,191,154),EggId=1},
[6]={Name="Bloom Deer",Rarity="Epic",Multiplier=2.6,Visual="dragon",Color=Color3.fromRGB(106,222,185),EggId=1},
[7]={Name="Fern Deer",Rarity="Epic",Multiplier=3.2,Visual="deer",Color=Color3.fromRGB(137,188,151),EggId=1},
[8]={Name="Golden Stag",Rarity="Legendary",Multiplier=5,Visual="bear",Color=Color3.fromRGB(103,219,182),EggId=1},
[9]={Name="Sun Pegasus",Rarity="Legendary",Multiplier=7,Visual="pegasus",Color=Color3.fromRGB(134,185,148),EggId=1},
[10]={Name="World Tree Spirit",Rarity="Mythic",Multiplier=12,Visual="spectre",Color=Color3.fromRGB(100,216,179),EggId=1},
[11]={Name="Peach Kitten",Rarity="Common",Multiplier=2.3,Visual="bunny",Color=Color3.fromRGB(230,147,175),EggId=2},
[12]={Name="Berry Bunny",Rarity="Common",Multiplier=2.5,Visual="dog",Color=Color3.fromRGB(255,178,141),EggId=2},
[13]={Name="Rose Panda",Rarity="Uncommon",Multiplier=3,Visual="cat",Color=Color3.fromRGB(255,144,172),EggId=2},
[14]={Name="Tulip Fox",Rarity="Uncommon",Multiplier=3.4,Visual="fox",Color=Color3.fromRGB(255,175,203),EggId=2},
[15]={Name="Orchid Penguin",Rarity="Rare",Multiplier=4,Visual="penguin",Color=Color3.fromRGB(255,141,169),EggId=2},
[16]={Name="Blossom Drake",Rarity="Epic",Multiplier=5.2,Visual="dragon",Color=Color3.fromRGB(255,172,200),EggId=2},
[17]={Name="Lotus Kirin",Rarity="Epic",Multiplier=6.4,Visual="deer",Color=Color3.fromRGB(255,138,166),EggId=2},
[18]={Name="Amber Bear",Rarity="Legendary",Multiplier=10,Visual="bear",Color=Color3.fromRGB(252,169,197),EggId=2},
[19]={Name="Spring Pegasus",Rarity="Legendary",Multiplier=14,Visual="pegasus",Color=Color3.fromRGB(255,135,163),EggId=2},
[20]={Name="Celestial Blossom",Rarity="Mythic",Multiplier=24,Visual="spectre",Color=Color3.fromRGB(249,166,194),EggId=2},
[21]={Name="Crystal Cub",Rarity="Common",Multiplier=3.45,Visual="bunny",Color=Color3.fromRGB(75,197,236),EggId=3},
[22]={Name="Jade Bunny",Rarity="Common",Multiplier=3.75,Visual="dog",Color=Color3.fromRGB(106,228,202),EggId=3},
[23]={Name="Emerald Fox",Rarity="Uncommon",Multiplier=4.5,Visual="cat",Color=Color3.fromRGB(137,194,233),EggId=3},
[24]={Name="Pearl Panda",Rarity="Uncommon",Multiplier=5.1,Visual="fox",Color=Color3.fromRGB(103,225,255),EggId=3},
[25]={Name="Sapphire Penguin",Rarity="Rare",Multiplier=6,Visual="penguin",Color=Color3.fromRGB(134,191,230),EggId=3},
[26]={Name="Prism Dragon",Rarity="Epic",Multiplier=7.8,Visual="dragon",Color=Color3.fromRGB(100,222,255),EggId=3},
[27]={Name="Amethyst Kirin",Rarity="Epic",Multiplier=9.6,Visual="deer",Color=Color3.fromRGB(131,188,227),EggId=3},
[28]={Name="Diamond Bear",Rarity="Legendary",Multiplier=15,Visual="bear",Color=Color3.fromRGB(97,219,255),EggId=3},
[29]={Name="Aurora Pegasus",Rarity="Legendary",Multiplier=21,Visual="pegasus",Color=Color3.fromRGB(128,185,224),EggId=3},
[30]={Name="Ancient Forest God",Rarity="Mythic",Multiplier=36,Visual="spectre",Color=Color3.fromRGB(94,216,255),EggId=3},
[31]={Name="Byte Cat",Rarity="Common",Multiplier=4.6,Visual="bunny",Color=Color3.fromRGB(37,205,255),EggId=4},
[32]={Name="Circuit Pup",Rarity="Common",Multiplier=5,Visual="dog",Color=Color3.fromRGB(68,236,230),EggId=4},
[33]={Name="Pixel Fox",Rarity="Uncommon",Multiplier=6,Visual="cat",Color=Color3.fromRGB(99,202,255),EggId=4},
[34]={Name="Laser Bunny",Rarity="Uncommon",Multiplier=6.8,Visual="fox",Color=Color3.fromRGB(65,233,255),EggId=4},
[35]={Name="Holo Penguin",Rarity="Rare",Multiplier=8,Visual="penguin",Color=Color3.fromRGB(96,199,255),EggId=4},
[36]={Name="Volt Dragon",Rarity="Epic",Multiplier=10.4,Visual="dragon",Color=Color3.fromRGB(62,230,255),EggId=4},
[37]={Name="Cyber Deer",Rarity="Epic",Multiplier=12.8,Visual="deer",Color=Color3.fromRGB(93,196,255),EggId=4},
[38]={Name="Solar Bear",Rarity="Legendary",Multiplier=20,Visual="bear",Color=Color3.fromRGB(59,227,255),EggId=4},
[39]={Name="Nova Pegasus",Rarity="Legendary",Multiplier=28,Visual="pegasus",Color=Color3.fromRGB(90,193,252),EggId=4},
[40]={Name="Quantum Spirit",Rarity="Mythic",Multiplier=48,Visual="spectre",Color=Color3.fromRGB(56,224,255),EggId=4},
[41]={Name="Ion Bunny",Rarity="Common",Multiplier=5.75,Visual="bunny",Color=Color3.fromRGB(170,97,255),EggId=5},
[42]={Name="Plasma Cat",Rarity="Common",Multiplier=6.25,Visual="dog",Color=Color3.fromRGB(201,128,230),EggId=5},
[43]={Name="Chrome Fox",Rarity="Uncommon",Multiplier=7.5,Visual="cat",Color=Color3.fromRGB(232,94,255),EggId=5},
[44]={Name="Glitch Panda",Rarity="Uncommon",Multiplier=8.5,Visual="fox",Color=Color3.fromRGB(198,125,255),EggId=5},
[45]={Name="Pulse Penguin",Rarity="Rare",Multiplier=10,Visual="penguin",Color=Color3.fromRGB(229,91,255),EggId=5},
[46]={Name="Vortex Dragon",Rarity="Epic",Multiplier=13,Visual="dragon",Color=Color3.fromRGB(195,122,255),EggId=5},
[47]={Name="Neon Kirin",Rarity="Epic",Multiplier=16,Visual="deer",Color=Color3.fromRGB(226,88,255),EggId=5},
[48]={Name="Cosmic Bear",Rarity="Legendary",Multiplier=25,Visual="bear",Color=Color3.fromRGB(192,119,255),EggId=5},
[49]={Name="Supernova Pegasus",Rarity="Legendary",Multiplier=35,Visual="pegasus",Color=Color3.fromRGB(223,85,252),EggId=5},
[50]={Name="Singularity",Rarity="Mythic",Multiplier=60,Visual="spectre",Color=Color3.fromRGB(189,116,255),EggId=5},
[51]={Name="Star Cub",Rarity="Common",Multiplier=6.9,Visual="bunny",Color=Color3.fromRGB(230,108,216),EggId=6},
[52]={Name="Void Bunny",Rarity="Common",Multiplier=7.5,Visual="dog",Color=Color3.fromRGB(255,139,182),EggId=6},
[53]={Name="Astro Fox",Rarity="Uncommon",Multiplier=9,Visual="cat",Color=Color3.fromRGB(255,105,213),EggId=6},
[54]={Name="Lunar Panda",Rarity="Uncommon",Multiplier=10.2,Visual="fox",Color=Color3.fromRGB(255,136,244),EggId=6},
[55]={Name="Comet Penguin",Rarity="Rare",Multiplier=12,Visual="penguin",Color=Color3.fromRGB(255,102,210),EggId=6},
[56]={Name="Orbit Dragon",Rarity="Epic",Multiplier=15.6,Visual="dragon",Color=Color3.fromRGB(255,133,241),EggId=6},
[57]={Name="Galaxy Deer",Rarity="Epic",Multiplier=19.2,Visual="deer",Color=Color3.fromRGB(255,99,207),EggId=6},
[58]={Name="Celestial Bear",Rarity="Legendary",Multiplier=30,Visual="bear",Color=Color3.fromRGB(252,130,238),EggId=6},
[59]={Name="Eternal Pegasus",Rarity="Legendary",Multiplier=42,Visual="pegasus",Color=Color3.fromRGB(255,96,204),EggId=6},
[60]={Name="Astral Sovereign",Rarity="Mythic",Multiplier=72,Visual="spectre",Color=Color3.fromRGB(249,127,235),EggId=6},
}
Config.Eggs={
[1]={Id=1,Name="Meadow Egg",World="island",Cost=125,Position=Vector3.new(40,2,132),Color=Color3.fromRGB(106,205,151),Pool={{Pet=1,Chance=32,Weight=32000},{Pet=2,Chance=30,Weight=30000},{Pet=3,Chance=14,Weight=14000},{Pet=4,Chance=12,Weight=12000},{Pet=5,Chance=7,Weight=7000},{Pet=6,Chance=2.4,Weight=2400},{Pet=7,Chance=1.499,Weight=1499},{Pet=8,Chance=1,Weight=1000},{Pet=9,Chance=0.1,Weight=100},{Pet=10,Chance=0.001,Weight=1}}},
[2]={Id=2,Name="Blossom Egg",World="island",Cost=150,Position=Vector3.new(71,2,132),Color=Color3.fromRGB(255,155,166),Pool={{Pet=11,Chance=32,Weight=32000},{Pet=12,Chance=30,Weight=30000},{Pet=13,Chance=14,Weight=14000},{Pet=14,Chance=12,Weight=12000},{Pet=15,Chance=7,Weight=7000},{Pet=16,Chance=2.4,Weight=2400},{Pet=17,Chance=1.499,Weight=1499},{Pet=18,Chance=1,Weight=1000},{Pet=19,Chance=0.1,Weight=100},{Pet=20,Chance=0.001,Weight=1}}},
[3]={Id=3,Name="Ancient Egg",World="island",Cost=1000,Position=Vector3.new(102,2,132),Color=Color3.fromRGB(100,205,227),Pool={{Pet=21,Chance=32,Weight=32000},{Pet=22,Chance=30,Weight=30000},{Pet=23,Chance=14,Weight=14000},{Pet=24,Chance=12,Weight=12000},{Pet=25,Chance=7,Weight=7000},{Pet=26,Chance=2.4,Weight=2400},{Pet=27,Chance=1.499,Weight=1499},{Pet=28,Chance=1,Weight=1000},{Pet=29,Chance=0.1,Weight=100},{Pet=30,Chance=0.001,Weight=1}}},
[4]={Id=4,Name="Circuit Egg",World="neon",Cost=2500,Position=Vector3.new(540,2,132),Color=Color3.fromRGB(62,213,255),Pool={{Pet=31,Chance=32,Weight=32000},{Pet=32,Chance=30,Weight=30000},{Pet=33,Chance=14,Weight=14000},{Pet=34,Chance=12,Weight=12000},{Pet=35,Chance=7,Weight=7000},{Pet=36,Chance=2.4,Weight=2400},{Pet=37,Chance=1.499,Weight=1499},{Pet=38,Chance=1,Weight=1000},{Pet=39,Chance=0.1,Weight=100},{Pet=40,Chance=0.001,Weight=1}}},
[5]={Id=5,Name="Plasma Egg",World="neon",Cost=10000,Position=Vector3.new(571,2,132),Color=Color3.fromRGB(195,105,255),Pool={{Pet=41,Chance=32,Weight=32000},{Pet=42,Chance=30,Weight=30000},{Pet=43,Chance=14,Weight=14000},{Pet=44,Chance=12,Weight=12000},{Pet=45,Chance=7,Weight=7000},{Pet=46,Chance=2.4,Weight=2400},{Pet=47,Chance=1.499,Weight=1499},{Pet=48,Chance=1,Weight=1000},{Pet=49,Chance=0.1,Weight=100},{Pet=50,Chance=0.001,Weight=1}}},
[6]={Id=6,Name="Galaxy Egg",World="neon",Cost=50000,Position=Vector3.new(602,2,132),Color=Color3.fromRGB(255,116,207),Pool={{Pet=51,Chance=32,Weight=32000},{Pet=52,Chance=30,Weight=30000},{Pet=53,Chance=14,Weight=14000},{Pet=54,Chance=12,Weight=12000},{Pet=55,Chance=7,Weight=7000},{Pet=56,Chance=2.4,Weight=2400},{Pet=57,Chance=1.499,Weight=1499},{Pet=58,Chance=1,Weight=1000},{Pet=59,Chance=0.1,Weight=100},{Pet=60,Chance=0.001,Weight=1}}},
}
function Config.GetUpgradeCost(level) return Config.FirstUpgradeCost*(level+1) end
function Config.GetWalkSpeed(level) return Config.BaseWalkSpeed+Config.SpeedPerLevel*level end
function Config.GetMagnetRadius(level) return Config.BaseMagnetRadius*(1+Config.MagnetRadiusGrowth)^level end
function Config.GetMagnetUpgradeCost(level) return 5*(level+1) end
function Config.GetIncomeMultiplier(level) return 1+0.25*level end
function Config.GetIncomeUpgradeCost(level) return 15*(level+1) end
function Config.GetPetMultiplier(id) return Config.Pets[id] and Config.Pets[id].Multiplier or 1 end
function Config.RollEgg(eggId,roll)
 local egg=assert(Config.Eggs[eggId],"Unknown egg")
 assert(roll>=1 and roll<=100000 and roll==math.floor(roll),"Roll must be 1..100000")
 local total=0
 for _,entry in ipairs(egg.Pool) do total=total+entry.Weight; if roll<=total then return entry.Pet end end
 error("Egg weights must total 100000")
end
return Config
