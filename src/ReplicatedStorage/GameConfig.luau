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
[1]={Name="Meadow Bunny",Rarity="Common",Multiplier=1.2,Visual="Bunny",Color=Color3.fromRGB(81,197,160),EggId=1},
[2]={Name="Meadow Pup",Rarity="Uncommon",Multiplier=1.5,Visual="Dog",Color=Color3.fromRGB(112,228,126),EggId=1},
[3]={Name="Meadow Kitty",Rarity="Rare",Multiplier=2,Visual="Cat",Color=Color3.fromRGB(143,194,157),EggId=1},
[4]={Name="Meadow Fox",Rarity="Epic",Multiplier=3,Visual="Fox",Color=Color3.fromRGB(109,225,188),EggId=1},
[5]={Name="Meadow Unicorn",Rarity="Mythic",Multiplier=6,Visual="Unicorn",Color=Color3.fromRGB(140,191,154),EggId=1},
[6]={Name="Winged Fairy",Rarity="Secret",Multiplier=15,Visual="Winged Fairy",Color=Color3.fromRGB(106,222,185),EggId=1},
[7]={Name="Pond Frog",Rarity="Common",Multiplier=2.4,Visual="Frog",Color=Color3.fromRGB(95,192,99),EggId=2},
[8]={Name="Blue Frog",Rarity="Uncommon",Multiplier=3,Visual="Blue Frog",Color=Color3.fromRGB(126,223,65),EggId=2},
[9]={Name="Red Frog",Rarity="Rare",Multiplier=4,Visual="Red Frog",Color=Color3.fromRGB(157,189,96),EggId=2},
[10]={Name="The Monkey",Rarity="Epic",Multiplier=6,Visual="The Monkey",Color=Color3.fromRGB(123,220,127),EggId=2},
[11]={Name="Jungle Platinum",Rarity="Mythic",Multiplier=12,Visual="Jungle Platinum",Color=Color3.fromRGB(154,186,93),EggId=2},
[12]={Name="Jungle Saturn",Rarity="Secret",Multiplier=30,Visual="Jungle Saturn",Color=Color3.fromRGB(120,217,124),EggId=2},
[13]={Name="Coconut Cat",Rarity="Common",Multiplier=4.8,Visual="Coconut Cat",Color=Color3.fromRGB(189,162,119),EggId=3},
[14]={Name="Coconut Dog",Rarity="Uncommon",Multiplier=6,Visual="Coconut Dog",Color=Color3.fromRGB(220,193,85),EggId=3},
[15]={Name="Coconut Bunny",Rarity="Rare",Multiplier=8,Visual="Coconut Bunny",Color=Color3.fromRGB(251,159,116),EggId=3},
[16]={Name="Coconut Jellyfish",Rarity="Epic",Multiplier=12,Visual="Coconut Jellyfish",Color=Color3.fromRGB(217,190,147),EggId=3},
[17]={Name="The Big Coconut",Rarity="Mythic",Multiplier=24,Visual="The Big Coconut",Color=Color3.fromRGB(248,156,113),EggId=3},
[18]={Name="Coconut Winged Lord",Rarity="Secret",Multiplier=60,Visual="Coconut Winged Lord",Color=Color3.fromRGB(214,187,144),EggId=3},
[19]={Name="Gummy Kitty",Rarity="Common",Multiplier=8.4,Visual="Gummy Kitty",Color=Color3.fromRGB(230,112,199),EggId=4},
[20]={Name="Gummy Bunny",Rarity="Uncommon",Multiplier=10.5,Visual="Gummy Bunny",Color=Color3.fromRGB(255,143,165),EggId=4},
[21]={Name="Gummy Fox",Rarity="Rare",Multiplier=14,Visual="Gummy Fox",Color=Color3.fromRGB(255,109,196),EggId=4},
[22]={Name="Gummy Doggy",Rarity="Epic",Multiplier=21,Visual="Gummy Doggy",Color=Color3.fromRGB(255,140,227),EggId=4},
[23]={Name="Gummylord",Rarity="Mythic",Multiplier=42,Visual="Gummylord",Color=Color3.fromRGB(255,106,193),EggId=4},
[24]={Name="Gummy Spacial Star",Rarity="Secret",Multiplier=105,Visual="Gummy Spacial Star",Color=Color3.fromRGB(255,137,224),EggId=4},
[25]={Name="Ice Cream Kitty",Rarity="Common",Multiplier=14.4,Visual="Ice Cream Kitty",Color=Color3.fromRGB(125,212,255),EggId=5},
[26]={Name="Ice Cream Bunny",Rarity="Uncommon",Multiplier=18,Visual="Ice Cream Bunny",Color=Color3.fromRGB(156,243,230),EggId=5},
[27]={Name="Ice Cream Doggy",Rarity="Rare",Multiplier=24,Visual="Ice Cream Doggy",Color=Color3.fromRGB(187,209,255),EggId=5},
[28]={Name="Ice Cream Bat",Rarity="Epic",Multiplier=36,Visual="Ice Cream Bat",Color=Color3.fromRGB(153,240,255),EggId=5},
[29]={Name="Ice Cream Shock",Rarity="Mythic",Multiplier=72,Visual="Ice Cream Shock",Color=Color3.fromRGB(184,206,255),EggId=5},
[30]={Name="Ice Cream Doubull",Rarity="Secret",Multiplier=180,Visual="Ice Cream Doubull",Color=Color3.fromRGB(150,237,255),EggId=5},
[31]={Name="Galactic Plushie",Rarity="Common",Multiplier=24,Visual="Galactic Plushie",Color=Color3.fromRGB(135,102,255),EggId=6},
[32]={Name="Galactic Hedgehog",Rarity="Uncommon",Multiplier=30,Visual="Galactic Hedgehog",Color=Color3.fromRGB(166,133,230),EggId=6},
[33]={Name="Galactic Saturn",Rarity="Rare",Multiplier=40,Visual="Galactic Saturn",Color=Color3.fromRGB(197,99,255),EggId=6},
[34]={Name="Galactic Angel",Rarity="Epic",Multiplier=60,Visual="Galactic Angel",Color=Color3.fromRGB(163,130,255),EggId=6},
[35]={Name="Galactic Queen",Rarity="Mythic",Multiplier=120,Visual="Galactic Queen",Color=Color3.fromRGB(194,96,255),EggId=6},
[36]={Name="Galactic Overlord",Rarity="Secret",Multiplier=300,Visual="Galactic Overlord",Color=Color3.fromRGB(160,127,255),EggId=6},
}
Config.Eggs={
[1]={Id=1,Name="Meadow Egg",World="island",Cost=50,Position=Vector3.new(40,2,132),Color=Color3.fromRGB(106,205,151),Pool={{Pet=1,Chance=50,Weight=50000},{Pet=2,Chance=30,Weight=30000},{Pet=3,Chance=12,Weight=12000},{Pet=4,Chance=6,Weight=6000},{Pet=5,Chance=1.9,Weight=1900},{Pet=6,Chance=0.1,Weight=100}}},
[2]={Id=2,Name="Jungle Egg",World="island",Cost=250,Position=Vector3.new(71,2,132),Color=Color3.fromRGB(120,200,90),Pool={{Pet=7,Chance=46,Weight=46000},{Pet=8,Chance=30,Weight=30000},{Pet=9,Chance=14,Weight=14000},{Pet=10,Chance=7,Weight=7000},{Pet=11,Chance=2.9,Weight=2900},{Pet=12,Chance=0.1,Weight=100}}},
[3]={Id=3,Name="Coconut Egg",World="island",Cost=1000,Position=Vector3.new(102,2,132),Color=Color3.fromRGB(214,170,110),Pool={{Pet=13,Chance=42,Weight=42000},{Pet=14,Chance=30,Weight=30000},{Pet=15,Chance=16,Weight=16000},{Pet=16,Chance=8,Weight=8000},{Pet=17,Chance=3.9,Weight=3900},{Pet=18,Chance=0.1,Weight=100}}},
[4]={Id=4,Name="Gummy Egg",World="neon",Cost=2500,Position=Vector3.new(540,2,132),Color=Color3.fromRGB(255,120,190),Pool={{Pet=19,Chance=40,Weight=40000},{Pet=20,Chance=30,Weight=30000},{Pet=21,Chance=17,Weight=17000},{Pet=22,Chance=9,Weight=9000},{Pet=23,Chance=3.9,Weight=3900},{Pet=24,Chance=0.1,Weight=100}}},
[5]={Id=5,Name="Ice Cream Egg",World="neon",Cost=10000,Position=Vector3.new(571,2,132),Color=Color3.fromRGB(150,220,255),Pool={{Pet=25,Chance=38,Weight=38000},{Pet=26,Chance=30,Weight=30000},{Pet=27,Chance=18,Weight=18000},{Pet=28,Chance=9,Weight=9000},{Pet=29,Chance=4.8,Weight=4800},{Pet=30,Chance=0.2,Weight=200}}},
[6]={Id=6,Name="Galactic Egg",World="neon",Cost=50000,Position=Vector3.new(602,2,132),Color=Color3.fromRGB(160,110,255),Pool={{Pet=31,Chance=35,Weight=35000},{Pet=32,Chance=30,Weight=30000},{Pet=33,Chance=19,Weight=19000},{Pet=34,Chance=10,Weight=10000},{Pet=35,Chance=5.7,Weight=5700},{Pet=36,Chance=0.3,Weight=300}}},
}
function Config.GetUpgradeCost(level) return Config.FirstUpgradeCost*(level+1) end
function Config.GetWalkSpeed(level) return Config.BaseWalkSpeed+Config.SpeedPerLevel*level end
function Config.GetMagnetRadius(level) return Config.BaseMagnetRadius*(1+Config.MagnetRadiusGrowth)^level end
function Config.GetMagnetUpgradeCost(level) return 5*(level+1) end
function Config.GetIncomeMultiplier(level) return 1+0.25*level end
function Config.GetIncomeUpgradeCost(level) return 15*(level+1) end
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
