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
[1]={Name="Clover Bunny",Rarity="Common",Multiplier=1.2,Visual="Bunny",Color=Color3.fromRGB(81,197,160),EggId=1},
[2]={Name="Field Mouse",Rarity="Uncommon",Multiplier=1.5,Visual="Mouse",Color=Color3.fromRGB(112,228,126),EggId=1},
[3]={Name="Mud Piggy",Rarity="Rare",Multiplier=2,Visual="Piggy",Color=Color3.fromRGB(143,194,157),EggId=1},
[4]={Name="Amber Fox",Rarity="Legendary",Multiplier=3.5,Visual="Fox",Color=Color3.fromRGB(109,225,188),EggId=1},
[5]={Name="Honey Pup",Rarity="Common",Multiplier=2.4,Visual="Dog",Color=Color3.fromRGB(230,147,175),EggId=2},
[6]={Name="Garden Cat",Rarity="Uncommon",Multiplier=3,Visual="Cat",Color=Color3.fromRGB(255,178,141),EggId=2},
[7]={Name="Bandit Raccoon",Rarity="Rare",Multiplier=4,Visual="Raccoon",Color=Color3.fromRGB(255,144,172),EggId=2},
[8]={Name="Blossom Deer",Rarity="Legendary",Multiplier=7,Visual="Deer",Color=Color3.fromRGB(255,175,203),EggId=2},
[9]={Name="Grizzly Bear",Rarity="Common",Multiplier=4.8,Visual="Bear",Color=Color3.fromRGB(75,197,236),EggId=3},
[10]={Name="Moon Wolf",Rarity="Uncommon",Multiplier=6,Visual="Wolf",Color=Color3.fromRGB(106,228,202),EggId=3},
[11]={Name="Bamboo Panda",Rarity="Rare",Multiplier=8,Visual="Panda",Color=Color3.fromRGB(137,194,233),EggId=3},
[12]={Name="Ancient Unicorn",Rarity="Legendary",Multiplier=14,Visual="Unicorn",Color=Color3.fromRGB(103,225,255),EggId=3},
[13]={Name="Ice Penguin",Rarity="Common",Multiplier=8.4,Visual="Penguin",Color=Color3.fromRGB(37,205,255),EggId=4},
[14]={Name="Polar Bear",Rarity="Uncommon",Multiplier=10.5,Visual="Polar Bear",Color=Color3.fromRGB(68,236,230),EggId=4},
[15]={Name="Neon Reindeer",Rarity="Rare",Multiplier=14,Visual="Reindeer",Color=Color3.fromRGB(99,202,255),EggId=4},
[16]={Name="Sky Pegasus",Rarity="Legendary",Multiplier=24.5,Visual="Pegasus",Color=Color3.fromRGB(65,233,255),EggId=4},
[17]={Name="Night Bat",Rarity="Common",Multiplier=14.4,Visual="Bat",Color=Color3.fromRGB(170,97,255),EggId=5},
[18]={Name="Web Spider",Rarity="Uncommon",Multiplier=18,Visual="Spider",Color=Color3.fromRGB(201,128,230),EggId=5},
[19]={Name="Phantom Spectre",Rarity="Rare",Multiplier=24,Visual="Spectre",Color=Color3.fromRGB(232,94,255),EggId=5},
[20]={Name="Volt Dragon",Rarity="Legendary",Multiplier=42,Visual="Dragon",Color=Color3.fromRGB(198,125,255),EggId=5},
[21]={Name="Gummy Bear",Rarity="Common",Multiplier=24,Visual="Gummy Bear",Color=Color3.fromRGB(230,108,216),EggId=6},
[22]={Name="Cosmo Dino",Rarity="Uncommon",Multiplier=30,Visual="Dinosaur",Color=Color3.fromRGB(255,139,182),EggId=6},
[23]={Name="Star Angel",Rarity="Rare",Multiplier=40,Visual="Angel",Color=Color3.fromRGB(255,105,213),EggId=6},
[24]={Name="Galaxy Phoenix",Rarity="Mythic",Multiplier=70,Visual="phoenix",Color=Color3.fromRGB(255,136,244),EggId=6},
}
Config.Eggs={
[1]={Id=1,Name="Meadow Egg",World="island",Cost=50,Position=Vector3.new(40,2,132),Color=Color3.fromRGB(106,205,151),Pool={{Pet=1,Chance=60,Weight=60000},{Pet=2,Chance=30,Weight=30000},{Pet=3,Chance=9,Weight=9000},{Pet=4,Chance=1,Weight=1000}}},
[2]={Id=2,Name="Blossom Egg",World="island",Cost=250,Position=Vector3.new(71,2,132),Color=Color3.fromRGB(255,155,166),Pool={{Pet=5,Chance=56,Weight=56000},{Pet=6,Chance=30,Weight=30000},{Pet=7,Chance=12,Weight=12000},{Pet=8,Chance=2,Weight=2000}}},
[3]={Id=3,Name="Ancient Egg",World="island",Cost=1000,Position=Vector3.new(102,2,132),Color=Color3.fromRGB(100,205,227),Pool={{Pet=9,Chance=52,Weight=52000},{Pet=10,Chance=30,Weight=30000},{Pet=11,Chance=14,Weight=14000},{Pet=12,Chance=4,Weight=4000}}},
[4]={Id=4,Name="Frost Egg",World="neon",Cost=2500,Position=Vector3.new(540,2,132),Color=Color3.fromRGB(62,213,255),Pool={{Pet=13,Chance=48,Weight=48000},{Pet=14,Chance=30,Weight=30000},{Pet=15,Chance=16,Weight=16000},{Pet=16,Chance=6,Weight=6000}}},
[5]={Id=5,Name="Shadow Egg",World="neon",Cost=10000,Position=Vector3.new(571,2,132),Color=Color3.fromRGB(195,105,255),Pool={{Pet=17,Chance=44,Weight=44000},{Pet=18,Chance=30,Weight=30000},{Pet=19,Chance=18,Weight=18000},{Pet=20,Chance=8,Weight=8000}}},
[6]={Id=6,Name="Galaxy Egg",World="neon",Cost=50000,Position=Vector3.new(602,2,132),Color=Color3.fromRGB(255,116,207),Pool={{Pet=21,Chance=40,Weight=40000},{Pet=22,Chance=30,Weight=30000},{Pet=23,Chance=20,Weight=20000},{Pet=24,Chance=10,Weight=10000}}},
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
