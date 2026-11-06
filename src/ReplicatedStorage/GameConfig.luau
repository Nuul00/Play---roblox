-- Каталог: питомцы, яйца, цены. Цены яиц и ребёрса перебалансированы вручную (2026-11, симулятор экономики);
-- create-catalog.mjs устарел — не перегенерировать без переноса этих цен.
local Config = {}
Config.CoinValue=5
Config.CoinRespawnSeconds=8
Config.BaseWalkSpeed=16
Config.SpeedPerLevel=4
Config.MaxSpeedLevel=125
Config.FirstUpgradeCost=10
Config.ShopDistance=14
Config.PurchaseCooldown=0.4
Config.ShopkeeperUserId=1361632228
Config.MaxIncomeLevel=125
Config.BaseMagnetRadius=3
Config.MagnetRadiusGrowth=0.10
Config.MaxMagnetLevel=125
Config.MaxDoubleLevel=125
Config.MaxUpgradeLevel=125
-- Предел прокачки в магазине каждого мира: Meadow 10, Neon 25, Sky 50, Frozen 75, Volcano 100, Galaxy 125.
Config.ZoneMax={island=10,neon=25,sky=50,frozen=75,volcano=100,galaxy=125}
Config.BaseMaxLevel=10
Config.EnableGlobalBoards=true
Config.EnableStudioDataStores=false
Config.Worlds={island={Name="Meadow Isles",CenterX=0,Width=300,Depth=460,BaseValue=5},neon={Name="Neon District",CenterX=500,Width=300,Depth=460,BaseValue=25},sky={Name="Sky Isles",CenterX=1100,Width=300,Depth=300,BaseValue=150},frozen={Name="Frozen Peaks",CenterX=3000,Width=440,Depth=440,BaseValue=900},volcano={Name="Magma Volcano",CenterX=6000,Width=440,Depth=440,BaseValue=6000},galaxy={Name="Cosmic Galaxy",CenterX=7500,Width=440,Depth=440,BaseValue=40000}}
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
[17]={Name="Starlight Whale",Rarity="Rare",Multiplier=8.5,Visual="StarlightWhale",Color=Color3.fromRGB(150,100,255),EggId=3},
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
[82]={Name="Ember Pup",Rarity="Common",Multiplier=480,Visual="VolcanoPup",Color=Color3.fromRGB(255,120,40),EggId=10},
[83]={Name="Lava Bunny",Rarity="Common",Multiplier=555,Visual="VolcanoBunny",Color=Color3.fromRGB(255,120,40),EggId=10},
[84]={Name="Ash Kitty",Rarity="Uncommon",Multiplier=645,Visual="VolcanoKitty",Color=Color3.fromRGB(255,120,40),EggId=10},
[85]={Name="Magma Fox",Rarity="Uncommon",Multiplier=765,Visual="VolcanoFox",Color=Color3.fromRGB(255,120,40),EggId=10},
[86]={Name="Fire Salamander",Rarity="Rare",Multiplier=960,Visual="VolcanoSalamander",Color=Color3.fromRGB(255,120,40),EggId=10},
[87]={Name="Flame Wolf",Rarity="Epic",Multiplier=1260,Visual="VolcanoWolf",Color=Color3.fromRGB(255,120,40),EggId=10},
[88]={Name="Lava Dragon",Rarity="Legendary",Multiplier=2700,Visual="VolcanoDragon",Color=Color3.fromRGB(255,120,40),EggId=10},
[89]={Name="Phoenix King",Rarity="Secret",Multiplier=6600,Visual="VolcanoPhoenix",Color=Color3.fromRGB(255,120,40),EggId=10},
[90]={Name="Obsidian Bear",Rarity="Common",Multiplier=750,Visual="VolcanoBear",Color=Color3.fromRGB(230,60,30),EggId=11},
[91]={Name="Lava Golem",Rarity="Common",Multiplier=870,Visual="VolcanoGolem",Color=Color3.fromRGB(230,60,30),EggId=11},
[92]={Name="Fire Owl",Rarity="Uncommon",Multiplier=1020,Visual="VolcanoOwl",Color=Color3.fromRGB(230,60,30),EggId=11},
[93]={Name="Molten Turtle",Rarity="Uncommon",Multiplier=1200,Visual="VolcanoTurtle",Color=Color3.fromRGB(230,60,30),EggId=11},
[94]={Name="Volcano Crab",Rarity="Rare",Multiplier=1500,Visual="VolcanoCrab",Color=Color3.fromRGB(230,60,30),EggId=11},
[95]={Name="Inferno Lion",Rarity="Epic",Multiplier=1950,Visual="VolcanoLion",Color=Color3.fromRGB(230,60,30),EggId=11},
[96]={Name="Magma Hydra",Rarity="Legendary",Multiplier=4200,Visual="VolcanoHydra",Color=Color3.fromRGB(230,60,30),EggId=11},
[97]={Name="Flame Titan",Rarity="Secret",Multiplier=10500,Visual="VolcanoTitan",Color=Color3.fromRGB(230,60,30),EggId=11},
[98]={Name="Obsidian Panther",Rarity="Common",Multiplier=1200,Visual="VolcanoPanther",Color=Color3.fromRGB(130,60,190),EggId=12},
[99]={Name="Crystal Imp",Rarity="Common",Multiplier=1380,Visual="VolcanoImp",Color=Color3.fromRGB(130,60,190),EggId=12},
[100]={Name="Ember Bat",Rarity="Uncommon",Multiplier=1620,Visual="VolcanoBat",Color=Color3.fromRGB(130,60,190),EggId=12},
[101]={Name="Lava Unicorn",Rarity="Uncommon",Multiplier=1920,Visual="VolcanoUnicorn",Color=Color3.fromRGB(130,60,190),EggId=12},
[102]={Name="Smoke Serpent",Rarity="Rare",Multiplier=2400,Visual="VolcanoSerpent",Color=Color3.fromRGB(130,60,190),EggId=12},
[103]={Name="Obsidian Griffin",Rarity="Epic",Multiplier=3150,Visual="VolcanoGriffin",Color=Color3.fromRGB(130,60,190),EggId=12},
[104]={Name="Volcano Spirit",Rarity="Legendary",Multiplier=6600,Visual="VolcanoSpirit",Color=Color3.fromRGB(130,60,190),EggId=12},
[105]={Name="Eclipse Dragon",Rarity="Secret",Multiplier=16500,Visual="VolcanoEclipseDragon",Color=Color3.fromRGB(130,60,190),EggId=12},
[106]={Name="Astro Pup",Rarity="Common",Multiplier=1950,Visual="GalaxyPup",Color=Color3.fromRGB(120,170,255),EggId=13},
[107]={Name="Rocket Cat",Rarity="Common",Multiplier=2250,Visual="GalaxyCat",Color=Color3.fromRGB(120,170,255),EggId=13},
[108]={Name="Moon Bunny",Rarity="Uncommon",Multiplier=2640,Visual="GalaxyBunny",Color=Color3.fromRGB(120,170,255),EggId=13},
[109]={Name="Alien Blob",Rarity="Uncommon",Multiplier=3120,Visual="GalaxyBlob",Color=Color3.fromRGB(120,170,255),EggId=13},
[110]={Name="UFO Hamster",Rarity="Rare",Multiplier=3900,Visual="GalaxyHamster",Color=Color3.fromRGB(120,170,255),EggId=13},
[111]={Name="Comet Fox",Rarity="Epic",Multiplier=5100,Visual="GalaxyFox",Color=Color3.fromRGB(120,170,255),EggId=13},
[112]={Name="Robo Astronaut",Rarity="Legendary",Multiplier=10800,Visual="GalaxyRobot",Color=Color3.fromRGB(120,170,255),EggId=13},
[113]={Name="Star Whale",Rarity="Secret",Multiplier=27000,Visual="GalaxyWhale",Color=Color3.fromRGB(120,170,255),EggId=13},
[114]={Name="Nebula Kitty",Rarity="Common",Multiplier=3000,Visual="GalaxyKitty",Color=Color3.fromRGB(220,110,230),EggId=14},
[115]={Name="Planet Turtle",Rarity="Common",Multiplier=3450,Visual="GalaxyTurtle",Color=Color3.fromRGB(220,110,230),EggId=14},
[116]={Name="Galaxy Owl",Rarity="Uncommon",Multiplier=4050,Visual="GalaxyOwl",Color=Color3.fromRGB(220,110,230),EggId=14},
[117]={Name="Cosmic Jelly",Rarity="Uncommon",Multiplier=4800,Visual="GalaxyJelly",Color=Color3.fromRGB(220,110,230),EggId=14},
[118]={Name="Saturn Bear",Rarity="Rare",Multiplier=6000,Visual="GalaxyBear",Color=Color3.fromRGB(220,110,230),EggId=14},
[119]={Name="Meteor Wolf",Rarity="Epic",Multiplier=7800,Visual="GalaxyWolf",Color=Color3.fromRGB(220,110,230),EggId=14},
[120]={Name="Nebula Wyrm",Rarity="Legendary",Multiplier=16500,Visual="GalaxyDragon",Color=Color3.fromRGB(220,110,230),EggId=14},
[121]={Name="Starlight Phoenix",Rarity="Secret",Multiplier=42000,Visual="GalaxyPhoenix",Color=Color3.fromRGB(220,110,230),EggId=14},
[122]={Name="Black Hole Cat",Rarity="Common",Multiplier=4800,Visual="GalaxyCat",Color=Color3.fromRGB(255,215,110),EggId=15},
[123]={Name="Quasar Lion",Rarity="Common",Multiplier=5550,Visual="GalaxyLion",Color=Color3.fromRGB(255,215,110),EggId=15},
[124]={Name="Solar Pegasus",Rarity="Uncommon",Multiplier=6450,Visual="GalaxyPegasus",Color=Color3.fromRGB(255,215,110),EggId=15},
[125]={Name="Cosmic Kraken",Rarity="Uncommon",Multiplier=7650,Visual="GalaxyKraken",Color=Color3.fromRGB(255,215,110),EggId=15},
[126]={Name="Star Guardian",Rarity="Rare",Multiplier=9600,Visual="GalaxyGuardian",Color=Color3.fromRGB(255,215,110),EggId=15},
[127]={Name="Galaxy Unicorn",Rarity="Epic",Multiplier=12600,Visual="GalaxyUnicorn",Color=Color3.fromRGB(255,215,110),EggId=15},
[128]={Name="Supernova Dragon",Rarity="Legendary",Multiplier=27000,Visual="GalaxyDragon",Color=Color3.fromRGB(255,215,110),EggId=15},
[129]={Name="Universe Spirit",Rarity="Secret",Multiplier=66000,Visual="GalaxySpirit",Color=Color3.fromRGB(255,215,110),EggId=15},
[130]={Name="Snow Bunny",Rarity="Common",Multiplier=143,Visual="FrozenBunny",Color=Color3.fromRGB(200,235,255),EggId=16},
[131]={Name="Penguin Chick",Rarity="Common",Multiplier=162,Visual="FrozenPenguin",Color=Color3.fromRGB(200,235,255),EggId=16},
[132]={Name="Arctic Fox",Rarity="Uncommon",Multiplier=188,Visual="FrozenFox",Color=Color3.fromRGB(200,235,255),EggId=16},
[133]={Name="Snowy Owl",Rarity="Uncommon",Multiplier=228,Visual="FrozenOwl",Color=Color3.fromRGB(200,235,255),EggId=16},
[134]={Name="Polar Cub",Rarity="Rare",Multiplier=286,Visual="FrozenPolarCub",Color=Color3.fromRGB(200,235,255),EggId=16},
[135]={Name="Ice Kitten",Rarity="Epic",Multiplier=370,Visual="FrozenKitten",Color=Color3.fromRGB(200,235,255),EggId=16},
[136]={Name="Frost Fairy",Rarity="Legendary",Multiplier=793,Visual="FrozenFairy",Color=Color3.fromRGB(200,235,255),EggId=16},
[137]={Name="Snowflake Spirit",Rarity="Secret",Multiplier=1950,Visual="FrozenSpirit",Color=Color3.fromRGB(200,235,255),EggId=16},
[138]={Name="Aurora Fox",Rarity="Common",Multiplier=247,Visual="FrozenAuroraFox",Color=Color3.fromRGB(110,230,190),EggId=17},
[139]={Name="Husky Pup",Rarity="Common",Multiplier=285,Visual="FrozenHusky",Color=Color3.fromRGB(110,230,190),EggId=17},
[140]={Name="Seal Pup",Rarity="Uncommon",Multiplier=332,Visual="FrozenSeal",Color=Color3.fromRGB(110,230,190),EggId=17},
[141]={Name="Reindeer",Rarity="Uncommon",Multiplier=399,Visual="FrozenReindeer",Color=Color3.fromRGB(110,230,190),EggId=17},
[142]={Name="Narwhal",Rarity="Rare",Multiplier=494,Visual="FrozenNarwhal",Color=Color3.fromRGB(110,230,190),EggId=17},
[143]={Name="Aurora Wolf",Rarity="Epic",Multiplier=646,Visual="FrozenWolf",Color=Color3.fromRGB(110,230,190),EggId=17},
[144]={Name="Aurora Phoenix",Rarity="Legendary",Multiplier=1387,Visual="FrozenPhoenix",Color=Color3.fromRGB(110,230,190),EggId=17},
[145]={Name="Northern Dragon",Rarity="Secret",Multiplier=3420,Visual="FrozenAuroraDragon",Color=Color3.fromRGB(110,230,190),EggId=17},
[146]={Name="Yeti",Rarity="Common",Multiplier=377,Visual="FrozenYeti",Color=Color3.fromRGB(90,170,255),EggId=18},
[147]={Name="Ice Golem",Rarity="Common",Multiplier=442,Visual="FrozenGolem",Color=Color3.fromRGB(90,170,255),EggId=18},
[148]={Name="Frost Tiger",Rarity="Uncommon",Multiplier=507,Visual="FrozenTiger",Color=Color3.fromRGB(90,170,255),EggId=18},
[149]={Name="Woolly Mammoth",Rarity="Uncommon",Multiplier=611,Visual="FrozenMammoth",Color=Color3.fromRGB(90,170,255),EggId=18},
[150]={Name="Penguin King",Rarity="Rare",Multiplier=754,Visual="FrozenPenguinKing",Color=Color3.fromRGB(90,170,255),EggId=18},
[151]={Name="Glacier Griffin",Rarity="Epic",Multiplier=988,Visual="FrozenGriffin",Color=Color3.fromRGB(90,170,255),EggId=18},
[152]={Name="Frost Dragon",Rarity="Legendary",Multiplier=2132,Visual="FrozenDragon",Color=Color3.fromRGB(90,170,255),EggId=18},
[153]={Name="Ice Queen",Rarity="Secret",Multiplier=5200,Visual="FrozenQueen",Color=Color3.fromRGB(90,170,255),EggId=18},
[20]={Name="Disco Bunny",Rarity="Common",Multiplier=9.1,Visual="NeonDisco_Bunny",Color=Color3.fromRGB(232,68,255),EggId=4},
[26]={Name="Mecha Bunny",Rarity="Common",Multiplier=15.6,Visual="NeonTech_Bunny",Color=Color3.fromRGB(54,205,255),EggId=5},
[32]={Name="City Panda",Rarity="Common",Multiplier=26,Visual="NeonCity_Panda",Color=Color3.fromRGB(192,88,255),EggId=6},
}
Config.Eggs={
[1]={Id=1,Name="Sunset Sky Egg",World="island",Cost=50,Position=Vector3.new(40,2,132),Color=Color3.fromRGB(232,137,220),Pool={{Pet=1,Chance=30,Weight=30000},{Pet=2,Chance=25,Weight=25000},{Pet=3,Chance=18,Weight=18000},{Pet=4,Chance=12,Weight=12000},{Pet=5,Chance=7,Weight=7000},{Pet=6,Chance=5,Weight=5000},{Pet=37,Chance=2,Weight=2000},{Pet=38,Chance=0.9,Weight=900},{Pet=39,Chance=0.1,Weight=100}}},
[2]={Id=2,Name="Sakura Egg",World="island",Cost=250,Position=Vector3.new(71,2,132),Color=Color3.fromRGB(255,140,200),Pool={{Pet=7,Chance=32,Weight=32000},{Pet=8,Chance=24,Weight=24000},{Pet=9,Chance=17,Weight=17000},{Pet=10,Chance=12,Weight=12000},{Pet=11,Chance=7.5,Weight=7500},{Pet=12,Chance=4.5,Weight=4500},{Pet=40,Chance=2,Weight=2000},{Pet=41,Chance=0.9,Weight=900},{Pet=42,Chance=0.1,Weight=100}}},
[3]={Id=3,Name="Starlight Egg",World="island",Cost=1000,Position=Vector3.new(102,2,132),Color=Color3.fromRGB(150,100,255),Pool={{Pet=13,Chance=30,Weight=30000},{Pet=14,Chance=24,Weight=24000},{Pet=15,Chance=18,Weight=18000},{Pet=16,Chance=12,Weight=12000},{Pet=17,Chance=8,Weight=8000},{Pet=18,Chance=5,Weight=5000},{Pet=43,Chance=2.3,Weight=2300},{Pet=44,Chance=0.6,Weight=600},{Pet=45,Chance=0.1,Weight=100}}},
[4]={Id=4,Name="Disco Grid Egg",World="neon",Cost=2500,Position=Vector3.new(540,2,132),Color=Color3.fromRGB(232,68,255),Pool={{Pet=19,Chance=30,Weight=30000},{Pet=20,Chance=24,Weight=24000},{Pet=21,Chance=18,Weight=18000},{Pet=22,Chance=12,Weight=12000},{Pet=23,Chance=7,Weight=7000},{Pet=24,Chance=5,Weight=5000},{Pet=46,Chance=2,Weight=2000},{Pet=47,Chance=1,Weight=1000},{Pet=48,Chance=0.9,Weight=900},{Pet=49,Chance=0.1,Weight=100}}},
[5]={Id=5,Name="Tech Core Egg",World="neon",Cost=100000,Position=Vector3.new(571,2,132),Color=Color3.fromRGB(54,205,255),Pool={{Pet=25,Chance=30,Weight=30000},{Pet=26,Chance=24,Weight=24000},{Pet=27,Chance=18,Weight=18000},{Pet=28,Chance=12,Weight=12000},{Pet=29,Chance=7,Weight=7000},{Pet=30,Chance=5,Weight=5000},{Pet=50,Chance=2,Weight=2000},{Pet=51,Chance=1,Weight=1000},{Pet=52,Chance=0.9,Weight=900},{Pet=53,Chance=0.1,Weight=100}}},
[6]={Id=6,Name="City Lights Egg",World="neon",Cost=5000000,Position=Vector3.new(602,2,132),Color=Color3.fromRGB(192,88,255),Pool={{Pet=31,Chance=30,Weight=30000},{Pet=32,Chance=24,Weight=24000},{Pet=33,Chance=18,Weight=18000},{Pet=34,Chance=12,Weight=12000},{Pet=35,Chance=7,Weight=7000},{Pet=36,Chance=5,Weight=5000},{Pet=54,Chance=2,Weight=2000},{Pet=55,Chance=1,Weight=1000},{Pet=56,Chance=0.9,Weight=900},{Pet=57,Chance=0.1,Weight=100}}},
[7]={Id=7,Name="Cloud Egg",World="sky",Cost=15000000,Position=Vector3.new(1048,2,112),Color=Color3.fromRGB(190,225,255),Pool={{Pet=58,Chance=30,Weight=30000},{Pet=59,Chance=25,Weight=25000},{Pet=60,Chance=18,Weight=18000},{Pet=61,Chance=12,Weight=12000},{Pet=62,Chance=8,Weight=8000},{Pet=63,Chance=5,Weight=5000},{Pet=64,Chance=1.9,Weight=1900},{Pet=65,Chance=0.1,Weight=100}}},
[8]={Id=8,Name="Celestial Egg",World="sky",Cost=250000000,Position=Vector3.new(1100,2,112),Color=Color3.fromRGB(160,110,255),Pool={{Pet=66,Chance=30,Weight=30000},{Pet=67,Chance=25,Weight=25000},{Pet=68,Chance=18,Weight=18000},{Pet=69,Chance=12,Weight=12000},{Pet=70,Chance=8,Weight=8000},{Pet=71,Chance=5,Weight=5000},{Pet=72,Chance=1.9,Weight=1900},{Pet=73,Chance=0.1,Weight=100}}},
[9]={Id=9,Name="Crystal Egg",World="sky",Cost=5e9,Position=Vector3.new(1152,2,112),Color=Color3.fromRGB(110,215,255),Pool={{Pet=74,Chance=30,Weight=30000},{Pet=75,Chance=25,Weight=25000},{Pet=76,Chance=18,Weight=18000},{Pet=77,Chance=12,Weight=12000},{Pet=78,Chance=8,Weight=8000},{Pet=79,Chance=5,Weight=5000},{Pet=80,Chance=1.9,Weight=1900},{Pet=81,Chance=0.1,Weight=100}}},
[10]={Id=10,Name="Ember Egg",World="volcano",Cost=1.3e12,Position=Vector3.new(5948,2,112),Color=Color3.fromRGB(255,120,40),Pool={{Pet=82,Chance=30,Weight=30000},{Pet=83,Chance=25,Weight=25000},{Pet=84,Chance=18,Weight=18000},{Pet=85,Chance=12,Weight=12000},{Pet=86,Chance=8,Weight=8000},{Pet=87,Chance=5,Weight=5000},{Pet=88,Chance=1.9,Weight=1900},{Pet=89,Chance=0.1,Weight=100}}},
[11]={Id=11,Name="Magma Egg",World="volcano",Cost=1e13,Position=Vector3.new(6000,2,112),Color=Color3.fromRGB(230,60,30),Pool={{Pet=90,Chance=30,Weight=30000},{Pet=91,Chance=25,Weight=25000},{Pet=92,Chance=18,Weight=18000},{Pet=93,Chance=12,Weight=12000},{Pet=94,Chance=8,Weight=8000},{Pet=95,Chance=5,Weight=5000},{Pet=96,Chance=1.9,Weight=1900},{Pet=97,Chance=0.1,Weight=100}}},
[12]={Id=12,Name="Obsidian Egg",World="volcano",Cost=8e13,Position=Vector3.new(6052,2,112),Color=Color3.fromRGB(130,60,190),Pool={{Pet=98,Chance=30,Weight=30000},{Pet=99,Chance=25,Weight=25000},{Pet=100,Chance=18,Weight=18000},{Pet=101,Chance=12,Weight=12000},{Pet=102,Chance=8,Weight=8000},{Pet=103,Chance=5,Weight=5000},{Pet=104,Chance=1.9,Weight=1900},{Pet=105,Chance=0.1,Weight=100}}},
[13]={Id=13,Name="Rocket Egg",World="galaxy",Cost=3e14,Position=Vector3.new(7448,2,112),Color=Color3.fromRGB(120,170,255),Pool={{Pet=106,Chance=30,Weight=30000},{Pet=107,Chance=25,Weight=25000},{Pet=108,Chance=18,Weight=18000},{Pet=109,Chance=12,Weight=12000},{Pet=110,Chance=8,Weight=8000},{Pet=111,Chance=5,Weight=5000},{Pet=112,Chance=1.9,Weight=1900},{Pet=113,Chance=0.1,Weight=100}}},
[14]={Id=14,Name="Nebula Egg",World="galaxy",Cost=2.4e15,Position=Vector3.new(7500,2,112),Color=Color3.fromRGB(220,110,230),Pool={{Pet=114,Chance=30,Weight=30000},{Pet=115,Chance=25,Weight=25000},{Pet=116,Chance=18,Weight=18000},{Pet=117,Chance=12,Weight=12000},{Pet=118,Chance=8,Weight=8000},{Pet=119,Chance=5,Weight=5000},{Pet=120,Chance=1.9,Weight=1900},{Pet=121,Chance=0.1,Weight=100}}},
[15]={Id=15,Name="Supernova Egg",World="galaxy",Cost=1.8e16,Position=Vector3.new(7552,2,112),Color=Color3.fromRGB(255,215,110),Pool={{Pet=122,Chance=30,Weight=30000},{Pet=123,Chance=25,Weight=25000},{Pet=124,Chance=18,Weight=18000},{Pet=125,Chance=12,Weight=12000},{Pet=126,Chance=8,Weight=8000},{Pet=127,Chance=5,Weight=5000},{Pet=128,Chance=1.9,Weight=1900},{Pet=129,Chance=0.1,Weight=100}}},
[16]={Id=16,Name="Snowflake Egg",World="frozen",Cost=1.8e10,Position=Vector3.new(2948,2,112),Color=Color3.fromRGB(200,235,255),Pool={{Pet=130,Chance=30,Weight=30000},{Pet=131,Chance=25,Weight=25000},{Pet=132,Chance=18,Weight=18000},{Pet=133,Chance=12,Weight=12000},{Pet=134,Chance=8,Weight=8000},{Pet=135,Chance=5,Weight=5000},{Pet=136,Chance=1.9,Weight=1900},{Pet=137,Chance=0.1,Weight=100}}},
[17]={Id=17,Name="Aurora Egg",World="frozen",Cost=9e10,Position=Vector3.new(3000,2,112),Color=Color3.fromRGB(110,230,190),Pool={{Pet=138,Chance=30,Weight=30000},{Pet=139,Chance=25,Weight=25000},{Pet=140,Chance=18,Weight=18000},{Pet=141,Chance=12,Weight=12000},{Pet=142,Chance=8,Weight=8000},{Pet=143,Chance=5,Weight=5000},{Pet=144,Chance=1.9,Weight=1900},{Pet=145,Chance=0.1,Weight=100}}},
[18]={Id=18,Name="Glacier Egg",World="frozen",Cost=3.8e11,Position=Vector3.new(3052,2,112),Color=Color3.fromRGB(90,170,255),Pool={{Pet=146,Chance=30,Weight=30000},{Pet=147,Chance=25,Weight=25000},{Pet=148,Chance=18,Weight=18000},{Pet=149,Chance=12,Weight=12000},{Pet=150,Chance=8,Weight=8000},{Pet=151,Chance=5,Weight=5000},{Pet=152,Chance=1.9,Weight=1900},{Pet=153,Chance=0.1,Weight=100}}},
}
-- Экономика 2026-11 (v2): цена уровня привязана к деньгам мира, где этот уровень продаётся
-- (ZoneMax: Meadow до 10, Neon до 25, Sky до 50, Frozen до 75, Volcano до 100, Galaxy до 125).
-- Опорные точки — log10 цены: последний уровень мира стоит примерно как его самое дорогое яйцо ×2,
-- поэтому прокачка остаётся заметной тратой всю игру, а не копейками рядом с миллионами.
local UP_ANCHORS = { {0, 1.2}, {10, 3.1}, {25, 7.1}, {50, 10.2}, {75, 11.9}, {100, 14.1}, {125, 16.2}, {200, 19} }
local function upCost(mult, level)
	local a, b = UP_ANCHORS[1], UP_ANCHORS[#UP_ANCHORS]
	for i = 1, #UP_ANCHORS - 1 do
		if level <= UP_ANCHORS[i + 1][1] then a, b = UP_ANCHORS[i], UP_ANCHORS[i + 1] break end
	end
	local k = (level - a[1]) / math.max(1, b[1] - a[1])
	local x = 10 ^ (a[2] + (b[2] - a[2]) * k) * mult
	if x < 100 then return math.floor(x + 0.5) end
	local mag = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / mag + 0.5) * mag
end
function Config.GetUpgradeCost(level) return upCost(1, level) end
function Config.GetWalkSpeed(level) return math.floor((Config.BaseWalkSpeed+2*math.min(level,10)+0.6*math.clamp(level-10,0,40)+0.12*math.clamp(level-50,0,75))*10+0.5)/10 end
function Config.GetSpeedCoinBonus(level) return 1+0.01*level end
function Config.GetMagnetRadius(level) return Config.BaseMagnetRadius+0.12*level end
function Config.GetMagnetUpgradeCost(level) return upCost(0.8, level) end
function Config.GetIncomeMultiplier(level) return 1+0.25*level end
function Config.GetIncomeUpgradeCost(level) return upCost(1.6, level) end
-- Шанс, что подобранная монета даст двойную награду.
function Config.GetDoubleChance(level) if level<=50 then return 0.015*level end return math.min(0.9,0.75+0.002*(level-50)) end
function Config.GetDoubleUpgradeCost(level) return upCost(2.5, level) end
-- Ребёрс: за монеты И яйца, открытые с прошлого ребёрса, сбрасывает прокачку,
-- но даёт постоянный множитель монет, удачу яиц и награды на вехах (дорога наград).
Config.MaxRebirths=50
Config.RebirthStartSpeed=6
-- Округление до двух значащих цифр: цены выглядят «красиво» (250K, 6.6M, 1.2B...).
local function niceRound(x) if x<100 then return math.floor(x+0.5) end local mag=10^(math.floor(math.log10(x))-1) return math.floor(x/mag+0.5)*mag end
-- Цена в монетах: плавная кривая, рост за ребёрс от x2.6 в начале до x1.35 к 50-му.
-- Баланс 2026-11: первый ребёрс ~316M (примерно в Sky Isles), дальше ×2.1 → ×1.3 за ребёрс.
function Config.GetRebirthCost(r) return niceRound(10^(8.4+0.33*r-0.001*r*r)) end -- 1-й ребёрс 250M: ~10-я минута первой сессии
-- Сколько яиц нужно открыть с прошлого ребёрса (округляем до 5).
function Config.GetRebirthEggs(r) return math.max(10,math.floor((10+15*r+1.2*r*r)/5+0.5)*5) end
-- Множитель монет: первые 10 как раньше (+0.75), дальше ускоряется.
function Config.GetRebirthBonus(r) return 1+0.75*r+0.05*math.max(0,r-10)^2 end
-- Вехи: подарки (зелья) выдаются один раз; слоты, удача, титул и аура действуют постоянно.
Config.RebirthMilestones={
 {At=1,Icon="🧪",Name="Starter Potions",Desc="1 Coin + 1 Luck potion",Potions={Coins=1,Luck=1}},
 {At=3,Icon="🐾",Name="Pet Slot",Desc="+1 pet team slot",Slots=1},
 {At=5,Icon="🍀",Name="Luck Pack",Desc="3 Luck potions",Potions={Luck=3}},
 {At=7,Icon="🏷️",Name="Title: Reborn",Desc="Title over your head",Title="Reborn"},
 {At=10,Icon="🐾",Name="Pet Slot",Desc="+1 slot, 2 Coin + 2 Speed potions",Slots=1,Potions={Coins=2,Speed=2}},
 {At=15,Icon="🔥",Name="Bronze Aura",Desc="Aura + 10% egg luck",Aura=1,Luck=0.10},
 {At=20,Icon="🎁",Name="Potion Chest",Desc="3 of each potion + title Ascended",Title="Ascended",Potions={Coins=3,Speed=3,Luck=3}},
 {At=25,Icon="🐾",Name="Pet Slot",Desc="+1 pet team slot",Slots=1},
 {At=30,Icon="🌟",Name="Golden Aura",Desc="Gold aura + 5 Luck potions",Aura=2,Potions={Luck=5}},
 {At=35,Icon="🍀",Name="Lucky Star",Desc="+15% egg luck",Luck=0.15},
 {At=40,Icon="👑",Name="Title: Mythic",Desc="Title + 5 of each potion",Title="Mythic",Potions={Coins=5,Speed=5,Luck=5}},
 {At=45,Icon="🌈",Name="Rainbow Aura",Desc="Rainbow aura",Aura=3},
 {At=50,Icon="🌌",Name="Eternal",Desc="Cosmic aura, title, +25% luck, 10 of each potion",Title="Eternal",Aura=4,Luck=0.25,Potions={Coins=10,Speed=10,Luck=10}},
}
Config.RebirthAuraNames={"Bronze","Golden","Rainbow","Cosmic"}
-- Доп. удача яиц (доля): +1% за каждый ребёрс плюс бонусы вех.
function Config.GetRebirthLuck(r) local l=0.01*r for _,m in ipairs(Config.RebirthMilestones) do if r>=m.At and m.Luck then l=l+m.Luck end end return math.floor(l*1000+0.5)/1000 end
-- Доп. слоты команды питомцев.
function Config.GetRebirthSlots(r) local s=0 for _,m in ipairs(Config.RebirthMilestones) do if r>=m.At and m.Slots then s=s+m.Slots end end return s end
function Config.GetRebirthTitle(r) local t="" for _,m in ipairs(Config.RebirthMilestones) do if r>=m.At and m.Title then t=m.Title end end return t end
function Config.GetRebirthAura(r) local a=0 for _,m in ipairs(Config.RebirthMilestones) do if r>=m.At and m.Aura then a=math.max(a,m.Aura) end end return a end
function Config.GetIndexReward(eggId) return Config.Eggs[eggId].Cost*20 end
function Config.GetPetMultiplier(id) return Config.Pets[id] and Config.Pets[id].Multiplier or 1 end
function Config.RollEgg(eggId,roll)
 local egg=assert(Config.Eggs[eggId],"Unknown egg")
 assert(roll>=1 and roll<=100000 and roll==math.floor(roll),"Roll must be 1..100000")
 local total=0
 for _,entry in ipairs(egg.Pool) do total=total+entry.Weight; if roll<=total then return entry.Pet end end
 error("Egg weights must total 100000")
end
require(script.Parent:WaitForChild("SuperPets"))(Config)
return Config
