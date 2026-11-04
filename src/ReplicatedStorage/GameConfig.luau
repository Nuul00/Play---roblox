-- Generated catalog: edit tools/catalog.json generator for pet names, odds and prices.
local Config = {}
Config.CoinValue=5
Config.CoinRespawnSeconds=8
Config.BaseWalkSpeed=16
Config.SpeedPerLevel=4
Config.MaxSpeedLevel=50
Config.FirstUpgradeCost=10
Config.ShopDistance=14
Config.PurchaseCooldown=0.4
Config.ShopkeeperUserId=1361632228
Config.MaxIncomeLevel=50
Config.BaseMagnetRadius=3
Config.MagnetRadiusGrowth=0.10
Config.MaxMagnetLevel=50
Config.MaxDoubleLevel=50
Config.MaxUpgradeLevel=50
-- Предел прокачки в магазине каждого мира: Meadow 10, Neon 25, Sky 50.
Config.ZoneMax={island=10,neon=25,sky=50,frozen=50}
Config.BaseMaxLevel=10
Config.EnableGlobalBoards=true
Config.EnableStudioDataStores=false
Config.Worlds={island={Name="Meadow Isles",CenterX=0,Width=300,Depth=460,BaseValue=5},neon={Name="Neon District",CenterX=500,Width=300,Depth=460,BaseValue=25},sky={Name="Sky Isles",CenterX=1100,Width=300,Depth=300,BaseValue=150}}
Config.Pets={
[1]={Name="Cloud Puff",Rarity="Common",Multiplier=1.2,Visual="SunsetCloud",Color=Color3.fromRGB(232,137,220),EggId=1},
[2]={Name="Sunset Bunny",Rarity="Common",Multiplier=1.3,Visual="SunsetBunny",Color=Color3.fromRGB(232,137,220),EggId=1},
[3]={Name="Dusk Kitty",Rarity="Uncommon",Multiplier=1.5,Visual="SunsetCat",Color=Color3.fromRGB(232,137,220),EggId=1},
[4]={Name="Amber Deer",Rarity="Uncommon",Multiplier=1.7,Visual="SunsetDeer",Color=Color3.fromRGB(232,137,220),EggId=1},
[5]={Name="Twilight Unicorn",Rarity="Rare",Multiplier=2.2,Visual="SunsetUnicorn",Color=Color3.fromRGB(232,137,220),EggId=1},
[6]={Name="Rosy Sky Whale",Rarity="Rare",Multiplier=2.6,Visual="SunsetWhale",Color=Color3.fromRGB(232,137,220),EggId=1},
[37]={Name="Sunset Dragon",Rarity="Epic",Multiplier=3.5,Visual="SunsetDragon",Color=Color3.fromRGB(232,137,220),EggId=1},
[38]={Name="Dawn Phoenix",Rarity="Legendary",Multiplier=8,Visual="SunsetPhoenix",Color=Color3.fromRGB(232,137,220),EggId=1},
[39]={Name="Celestial Castle",Rarity="Secret",Multiplier=15,Visual="SunsetCastle",Color=Color3.fromRGB(232,137,220),EggId=1},
[7]={Name="Blossom Bunny",Rarity="Common",Multiplier=2.4,Visual="SakuraBunny",Color=Color3.fromRGB(255,140,200),EggId=2},
[8]={Name="Petal Fox",Rarity="Common",Multiplier=2.6,Visual="SakuraFox",Color=Color3.fromRGB(255,140,200),EggId=2},
[9]={Name="Sakura Cat",Rarity="Uncommon",Multiplier=3,Visual="SakuraCat",Color=Color3.fromRGB(255,140,200),EggId=2},
[10]={Name="Bloom Deer",Rarity="Uncommon",Multiplier=3.4,Visual="SakuraDeer",Color=Color3.fromRGB(255,140,200),EggId=2},
[11]={Name="Cherry Sheep",Rarity="Rare",Multiplier=4.2,Visual="SakuraSheep",Color=Color3.fromRGB(255,140,200),EggId=2},
[12]={Name="Rose Panda",Rarity="Rare",Multiplier=5,Visual="SakuraPanda",Color=Color3.fromRGB(255,140,200),EggId=2},
[40]={Name="Flora Butterfly",Rarity="Epic",Multiplier=7,Visual="SakuraButterfly",Color=Color3.fromRGB(255,140,200),EggId=2},
[41]={Name="Sakura Dragon",Rarity="Legendary",Multiplier=14,Visual="SakuraDragon",Color=Color3.fromRGB(255,140,200),EggId=2},
[42]={Name="Blossom Spirit",Rarity="Secret",Multiplier=32,Visual="SakuraSpirit",Color=Color3.fromRGB(255,140,200),EggId=2},
[13]={Name="Starlight Cat",Rarity="Common",Multiplier=4.8,Visual="StarlightCat",Color=Color3.fromRGB(150,100,255),EggId=3},
[14]={Name="Celestial Wolf",Rarity="Common",Multiplier=5.2,Visual="StarlightWolf",Color=Color3.fromRGB(150,100,255),EggId=3},
[15]={Name="Cosmic Owl",Rarity="Uncommon",Multiplier=6,Visual="StarlightOwl",Color=Color3.fromRGB(150,100,255),EggId=3},
[16]={Name="Nova Unicorn",Rarity="Uncommon",Multiplier=7,Visual="StarlightUnicorn",Color=Color3.fromRGB(150,100,255),EggId=3},
[17]={Name="Galaxy Whale",Rarity="Rare",Multiplier=8.5,Visual="StarlightWhale",Color=Color3.fromRGB(150,100,255),EggId=3},
[18]={Name="Solar Lion",Rarity="Rare",Multiplier=10,Visual="StarlightLion",Color=Color3.fromRGB(150,100,255),EggId=3},
[43]={Name="Nebula Dragon",Rarity="Epic",Multiplier=14,Visual="StarlightDragon",Color=Color3.fromRGB(150,100,255),EggId=3},
[44]={Name="Star Cloud",Rarity="Legendary",Multiplier=28,Visual="StarlightCloud",Color=Color3.fromRGB(150,100,255),EggId=3},
[45]={Name="Astral Spirit",Rarity="Secret",Multiplier=65,Visual="StarlightSpirit",Color=Color3.fromRGB(150,100,255),EggId=3},
[19]={Name="Pixel Cat",Rarity="Common",Multiplier=8.4,Visual="NeonDisco_Cat",Color=Color3.fromRGB(232,68,255),EggId=4},
[21]={Name="Neon Raccoon",Rarity="Uncommon",Multiplier=10.5,Visual="NeonDisco_Raccoon",Color=Color3.fromRGB(232,68,255),EggId=4},
[22]={Name="Grid Panda",Rarity="Uncommon",Multiplier=11.9,Visual="NeonDisco_Panda",Color=Color3.fromRGB(232,68,255),EggId=4},
[23]={Name="Holo Wolf",Rarity="Rare",Multiplier=15.4,Visual="NeonDisco_Wolf",Color=Color3.fromRGB(232,68,255),EggId=4},
[24]={Name="Laser Owl",Rarity="Rare",Multiplier=18.2,Visual="NeonDisco_Owl",Color=Color3.fromRGB(232,68,255),EggId=4},
[46]={Name="Disco Lion",Rarity="Epic",Multiplier=24.5,Visual="NeonDisco_Lion",Color=Color3.fromRGB(232,68,255),EggId=4},
[47]={Name="Synth Shark",Rarity="Epic",Multiplier=35,Visual="NeonDisco_Shark",Color=Color3.fromRGB(232,68,255),EggId=4},
[48]={Name="Cube Dragon",Rarity="Legendary",Multiplier=56,Visual="NeonDisco_Dragon",Color=Color3.fromRGB(232,68,255),EggId=4},
[49]={Name="Matrix Bot",Rarity="Secret",Multiplier=105,Visual="NeonDisco_Robot",Color=Color3.fromRGB(232,68,255),EggId=4},
[25]={Name="Core Cat",Rarity="Common",Multiplier=14.4,Visual="NeonTech_Cat",Color=Color3.fromRGB(54,205,255),EggId=5},
[27]={Name="Security Dog",Rarity="Uncommon",Multiplier=18,Visual="NeonTech_Dog",Color=Color3.fromRGB(54,205,255),EggId=5},
[28]={Name="Repair Panda",Rarity="Uncommon",Multiplier=20.4,Visual="NeonTech_Panda",Color=Color3.fromRGB(54,205,255),EggId=5},
[29]={Name="Drone Fox",Rarity="Rare",Multiplier=26.4,Visual="NeonTech_Fox",Color=Color3.fromRGB(54,205,255),EggId=5},
[30]={Name="AI Owl",Rarity="Rare",Multiplier=31.2,Visual="NeonTech_Owl",Color=Color3.fromRGB(54,205,255),EggId=5},
[50]={Name="Cyber Lion",Rarity="Epic",Multiplier=42,Visual="NeonTech_Lion",Color=Color3.fromRGB(54,205,255),EggId=5},
[51]={Name="Data Shark",Rarity="Epic",Multiplier=60,Visual="NeonTech_Shark",Color=Color3.fromRGB(54,205,255),EggId=5},
[52]={Name="Nano Dragon",Rarity="Legendary",Multiplier=96,Visual="NeonTech_Dragon",Color=Color3.fromRGB(54,205,255),EggId=5},
[53]={Name="Core Robot",Rarity="Secret",Multiplier=180,Visual="NeonTech_Robot",Color=Color3.fromRGB(54,205,255),EggId=5},
[31]={Name="Skyline Cat",Rarity="Common",Multiplier=24,Visual="NeonCity_Cat",Color=Color3.fromRGB(192,88,255),EggId=6},
[33]={Name="Metro Fox",Rarity="Uncommon",Multiplier=30,Visual="NeonCity_Fox",Color=Color3.fromRGB(192,88,255),EggId=6},
[34]={Name="Street Owl",Rarity="Uncommon",Multiplier=34,Visual="NeonCity_Owl",Color=Color3.fromRGB(192,88,255),EggId=6},
[35]={Name="Tower Wolf",Rarity="Rare",Multiplier=44,Visual="NeonCity_Wolf",Color=Color3.fromRGB(192,88,255),EggId=6},
[36]={Name="Neon Deer",Rarity="Rare",Multiplier=52,Visual="NeonCity_Deer",Color=Color3.fromRGB(192,88,255),EggId=6},
[54]={Name="Sky Lion",Rarity="Epic",Multiplier=70,Visual="NeonCity_Lion",Color=Color3.fromRGB(192,88,255),EggId=6},
[55]={Name="Hover Whale",Rarity="Epic",Multiplier=100,Visual="NeonCity_Whale",Color=Color3.fromRGB(192,88,255),EggId=6},
[56]={Name="Sky Dragon",Rarity="Legendary",Multiplier=160,Visual="NeonCity_Dragon",Color=Color3.fromRGB(192,88,255),EggId=6},
[57]={Name="Aerial Bot",Rarity="Secret",Multiplier=300,Visual="NeonCity_Robot",Color=Color3.fromRGB(192,88,255),EggId=6},
[58]={Name="Nimbus Cloud",Rarity="Common",Multiplier=40,Visual="CloudCloud",Color=Color3.fromRGB(190,225,255),EggId=7},
[59]={Name="Aviator Bear",Rarity="Common",Multiplier=46,Visual="CloudBear",Color=Color3.fromRGB(190,225,255),EggId=7},
[60]={Name="Balloon Hamster",Rarity="Uncommon",Multiplier=55,Visual="CloudBalloon",Color=Color3.fromRGB(190,225,255),EggId=7},
[61]={Name="Breeze Tornado",Rarity="Uncommon",Multiplier=65,Visual="CloudTornado",Color=Color3.fromRGB(190,225,255),EggId=7},
[62]={Name="Rainbow Kitty",Rarity="Rare",Multiplier=80,Visual="CloudRainbowCat",Color=Color3.fromRGB(190,225,255),EggId=7},
[63]={Name="Cloud Unicorn",Rarity="Epic",Multiplier=110,Visual="CloudUnicorn",Color=Color3.fromRGB(190,225,255),EggId=7},
[64]={Name="Sky Griffin",Rarity="Legendary",Multiplier=220,Visual="CloudGriffin",Color=Color3.fromRGB(190,225,255),EggId=7},
[65]={Name="Angel Cat",Rarity="Secret",Multiplier=500,Visual="CloudAngelCat",Color=Color3.fromRGB(190,225,255),EggId=7},
[66]={Name="Moon Cat",Rarity="Common",Multiplier=62,Visual="CelestialMoonCat",Color=Color3.fromRGB(160,110,255),EggId=8},
[67]={Name="Storm Cloud",Rarity="Common",Multiplier=72,Visual="CelestialStorm",Color=Color3.fromRGB(160,110,255),EggId=8},
[68]={Name="Blossom Sprite",Rarity="Uncommon",Multiplier=86,Visual="CelestialBlossom",Color=Color3.fromRGB(160,110,255),EggId=8},
[69]={Name="Sky Castle",Rarity="Uncommon",Multiplier=100,Visual="CelestialCastle",Color=Color3.fromRGB(160,110,255),EggId=8},
[70]={Name="Ruins Isle",Rarity="Rare",Multiplier=125,Visual="CelestialRuins",Color=Color3.fromRGB(160,110,255),EggId=8},
[71]={Name="Winged Wolf",Rarity="Epic",Multiplier=160,Visual="CelestialWolf",Color=Color3.fromRGB(160,110,255),EggId=8},
[72]={Name="Celestial Dragon",Rarity="Legendary",Multiplier=360,Visual="CelestialDragon",Color=Color3.fromRGB(160,110,255),EggId=8},
[73]={Name="Galaxy Whale",Rarity="Secret",Multiplier=850,Visual="CelestialWhale",Color=Color3.fromRGB(160,110,255),EggId=8},
[74]={Name="Pegasus",Rarity="Common",Multiplier=100,Visual="CrystalPegasus",Color=Color3.fromRGB(110,215,255),EggId=9},
[75]={Name="Space Whale",Rarity="Common",Multiplier=115,Visual="CrystalWhale",Color=Color3.fromRGB(110,215,255),EggId=9},
[76]={Name="Sun Lion",Rarity="Uncommon",Multiplier=135,Visual="CrystalLion",Color=Color3.fromRGB(110,215,255),EggId=9},
[77]={Name="Winged Stag",Rarity="Uncommon",Multiplier=160,Visual="CrystalStag",Color=Color3.fromRGB(110,215,255),EggId=9},
[78]={Name="Clockwork Chest",Rarity="Rare",Multiplier=200,Visual="CrystalClock",Color=Color3.fromRGB(110,215,255),EggId=9},
[79]={Name="Crystal Golem",Rarity="Epic",Multiplier=260,Visual="CrystalGolem",Color=Color3.fromRGB(110,215,255),EggId=9},
[80]={Name="Phoenix",Rarity="Legendary",Multiplier=560,Visual="CrystalPhoenix",Color=Color3.fromRGB(110,215,255),EggId=9},
[81]={Name="Angel Queen",Rarity="Secret",Multiplier=1400,Visual="CrystalQueen",Color=Color3.fromRGB(110,215,255),EggId=9},
[20]={Name="Disco Bunny",Rarity="Common",Multiplier=9.1,Visual="NeonDisco_Bunny",Color=Color3.fromRGB(232,68,255),EggId=4},
[26]={Name="Mecha Bunny",Rarity="Common",Multiplier=15.6,Visual="NeonTech_Bunny",Color=Color3.fromRGB(54,205,255),EggId=5},
[32]={Name="City Panda",Rarity="Common",Multiplier=26,Visual="NeonCity_Panda",Color=Color3.fromRGB(192,88,255),EggId=6},
}
Config.Eggs={
[1]={Id=1,Name="Sunset Sky Egg",World="island",Cost=50,Position=Vector3.new(40,2,132),Color=Color3.fromRGB(232,137,220),Pool={{Pet=1,Chance=30,Weight=30000},{Pet=2,Chance=25,Weight=25000},{Pet=3,Chance=18,Weight=18000},{Pet=4,Chance=12,Weight=12000},{Pet=5,Chance=7,Weight=7000},{Pet=6,Chance=5,Weight=5000},{Pet=37,Chance=2,Weight=2000},{Pet=38,Chance=0.9,Weight=900},{Pet=39,Chance=0.1,Weight=100}}},
[2]={Id=2,Name="Sakura Egg",World="island",Cost=250,Position=Vector3.new(71,2,132),Color=Color3.fromRGB(255,140,200),Pool={{Pet=7,Chance=32,Weight=32000},{Pet=8,Chance=24,Weight=24000},{Pet=9,Chance=17,Weight=17000},{Pet=10,Chance=12,Weight=12000},{Pet=11,Chance=7.5,Weight=7500},{Pet=12,Chance=4.5,Weight=4500},{Pet=40,Chance=2,Weight=2000},{Pet=41,Chance=0.9,Weight=900},{Pet=42,Chance=0.1,Weight=100}}},
[3]={Id=3,Name="Starlight Egg",World="island",Cost=1000,Position=Vector3.new(102,2,132),Color=Color3.fromRGB(150,100,255),Pool={{Pet=13,Chance=30,Weight=30000},{Pet=14,Chance=24,Weight=24000},{Pet=15,Chance=18,Weight=18000},{Pet=16,Chance=12,Weight=12000},{Pet=17,Chance=8,Weight=8000},{Pet=18,Chance=5,Weight=5000},{Pet=43,Chance=2.3,Weight=2300},{Pet=44,Chance=0.6,Weight=600},{Pet=45,Chance=0.1,Weight=100}}},
[4]={Id=4,Name="Disco Grid Egg",World="neon",Cost=2500,Position=Vector3.new(540,2,132),Color=Color3.fromRGB(232,68,255),Pool={{Pet=19,Chance=54,Weight=54000},{Pet=21,Chance=18,Weight=18000},{Pet=22,Chance=12,Weight=12000},{Pet=23,Chance=7,Weight=7000},{Pet=24,Chance=5,Weight=5000},{Pet=46,Chance=2,Weight=2000},{Pet=47,Chance=1,Weight=1000},{Pet=48,Chance=0.9,Weight=900},{Pet=49,Chance=0.1,Weight=100}}},
[5]={Id=5,Name="Tech Core Egg",World="neon",Cost=10000,Position=Vector3.new(571,2,132),Color=Color3.fromRGB(54,205,255),Pool={{Pet=25,Chance=54,Weight=54000},{Pet=27,Chance=18,Weight=18000},{Pet=28,Chance=12,Weight=12000},{Pet=29,Chance=7,Weight=7000},{Pet=30,Chance=5,Weight=5000},{Pet=50,Chance=2,Weight=2000},{Pet=51,Chance=1,Weight=1000},{Pet=52,Chance=0.9,Weight=900},{Pet=53,Chance=0.1,Weight=100}}},
[6]={Id=6,Name="City Lights Egg",World="neon",Cost=50000,Position=Vector3.new(602,2,132),Color=Color3.fromRGB(192,88,255),Pool={{Pet=31,Chance=54,Weight=54000},{Pet=33,Chance=18,Weight=18000},{Pet=34,Chance=12,Weight=12000},{Pet=35,Chance=7,Weight=7000},{Pet=36,Chance=5,Weight=5000},{Pet=54,Chance=2,Weight=2000},{Pet=55,Chance=1,Weight=1000},{Pet=56,Chance=0.9,Weight=900},{Pet=57,Chance=0.1,Weight=100}}},
[7]={Id=7,Name="Cloud Egg",World="sky",Cost=150000,Position=Vector3.new(1048,2,112),Color=Color3.fromRGB(190,225,255),Pool={{Pet=58,Chance=30,Weight=30000},{Pet=59,Chance=25,Weight=25000},{Pet=60,Chance=18,Weight=18000},{Pet=61,Chance=12,Weight=12000},{Pet=62,Chance=8,Weight=8000},{Pet=63,Chance=5,Weight=5000},{Pet=64,Chance=1.9,Weight=1900},{Pet=65,Chance=0.1,Weight=100}}},
[8]={Id=8,Name="Celestial Egg",World="sky",Cost=500000,Position=Vector3.new(1100,2,112),Color=Color3.fromRGB(160,110,255),Pool={{Pet=66,Chance=30,Weight=30000},{Pet=67,Chance=25,Weight=25000},{Pet=68,Chance=18,Weight=18000},{Pet=69,Chance=12,Weight=12000},{Pet=70,Chance=8,Weight=8000},{Pet=71,Chance=5,Weight=5000},{Pet=72,Chance=1.9,Weight=1900},{Pet=73,Chance=0.1,Weight=100}}},
[9]={Id=9,Name="Crystal Egg",World="sky",Cost=1500000,Position=Vector3.new(1152,2,112),Color=Color3.fromRGB(110,215,255),Pool={{Pet=74,Chance=30,Weight=30000},{Pet=75,Chance=25,Weight=25000},{Pet=76,Chance=18,Weight=18000},{Pet=77,Chance=12,Weight=12000},{Pet=78,Chance=8,Weight=8000},{Pet=79,Chance=5,Weight=5000},{Pet=80,Chance=1.9,Weight=1900},{Pet=81,Chance=0.1,Weight=100}}},
}
-- Цена уровня растёт по экспоненте, а на границах миров (10 и 25) умножается: x3 и x8.
local function tierMult(level) if level>=25 then return 8 elseif level>=10 then return 3 end return 1 end
local function upCost(base,growth,level) return math.floor(base*growth^level*tierMult(level)+0.5) end
function Config.GetUpgradeCost(level) return upCost(10,1.34,level) end
function Config.GetWalkSpeed(level) return Config.BaseWalkSpeed+4*math.min(level,10)+2*math.clamp(level-10,0,15)+math.clamp(level-25,0,25) end
function Config.GetMagnetRadius(level) return Config.BaseMagnetRadius+0.4*level end
function Config.GetMagnetUpgradeCost(level) return upCost(8,1.34,level) end
function Config.GetIncomeMultiplier(level) return 1+0.25*level end
function Config.GetIncomeUpgradeCost(level) return upCost(20,1.36,level) end
-- Шанс, что подобранная монета даст двойную награду.
function Config.GetDoubleChance(level) return math.min(1,0.015*level) end
function Config.GetDoubleUpgradeCost(level) return upCost(40,1.36,level) end
-- Ребёрс: за монеты сбрасывает прокачку, но даёт постоянный множитель монет.
Config.MaxRebirths=15
Config.RebirthStartSpeed=6
function Config.GetRebirthCost(r) return math.floor(200000*3^r) end
function Config.GetRebirthBonus(r) return 1+0.75*r end
function Config.GetIndexReward(eggId) return Config.Eggs[eggId].Cost*20 end
function Config.GetPetMultiplier(id) return Config.Pets[id] and Config.Pets[id].Multiplier or 1 end
function Config.RollEgg(eggId,roll)
 local egg=assert(Config.Eggs[eggId],"Unknown egg")
 assert(roll>=1 and roll<=100000 and roll==math.floor(roll),"Roll must be 1..100000")
 local total=0
 for _,entry in ipairs(egg.Pool) do total=total+entry.Weight; if roll<=total then return entry.Pet end end
 error("Egg weights must total 100000")
end
return Config
