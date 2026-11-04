import {writeFileSync,readFileSync} from 'node:fs';
// Каждое яйцо — 6 своих питомцев из паков (ReplicatedStorage.PetModels, имя модели = Visual).
// Обычные — простые звери одной серии, мифик — эффектный, секретка — самая редкая и необычная.
// Чем дороже яйцо, тем сильнее питомцы и тем выше шанс редких.
const rarities=['Common','Uncommon','Rare','Epic','Mythic','Secret'];
const odds=[[50,30,12,6,1.9,0.1],[46,30,14,7,2.9,0.1],[42,30,16,8,3.9,0.1],[40,30,17,9,3.9,0.1],[38,30,18,9,4.8,0.2],[35,30,19,10,5.7,0.3]];
const powers=[1,2,4,7,12,20];
const factors=[1.2,1.5,2,3,6,15];
const defs=[
 {Name:'Meadow Egg',World:'island',Price:50,Color:[106,205,151],Pets:[['Meadow Bunny','Bunny'],['Meadow Pup','Dog'],['Meadow Kitty','Cat'],['Meadow Fox','Fox'],['Meadow Unicorn','Unicorn'],['Winged Fairy','Winged Fairy']]},
 {Name:'Jungle Egg',World:'island',Price:250,Color:[120,200,90],Pets:[['Pond Frog','Frog'],['Blue Frog','Blue Frog'],['Red Frog','Red Frog'],['The Monkey','The Monkey'],['Jungle Platinum','Jungle Platinum'],['Jungle Saturn','Jungle Saturn']]},
 {Name:'Coconut Egg',World:'island',Price:1000,Color:[214,170,110],Pets:[['Coconut Cat','Coconut Cat'],['Coconut Dog','Coconut Dog'],['Coconut Bunny','Coconut Bunny'],['Coconut Jellyfish','Coconut Jellyfish'],['The Big Coconut','The Big Coconut'],['Coconut Winged Lord','Coconut Winged Lord']]},
 {Name:'Gummy Egg',World:'neon',Price:2500,Color:[255,120,190],Pets:[['Gummy Kitty','Gummy Kitty'],['Gummy Bunny','Gummy Bunny'],['Gummy Fox','Gummy Fox'],['Gummy Doggy','Gummy Doggy'],['Gummylord','Gummylord'],['Gummy Spacial Star','Gummy Spacial Star']]},
 {Name:'Ice Cream Egg',World:'neon',Price:10000,Color:[150,220,255],Pets:[['Ice Cream Kitty','Ice Cream Kitty'],['Ice Cream Bunny','Ice Cream Bunny'],['Ice Cream Doggy','Ice Cream Doggy'],['Ice Cream Bat','Ice Cream Bat'],['Ice Cream Shock','Ice Cream Shock'],['Ice Cream Doubull','Ice Cream Doubull']]},
 {Name:'Galactic Egg',World:'neon',Price:50000,Color:[160,110,255],Pets:[['Galactic Plushie','Galactic Plushie'],['Galactic Hedgehog','Galactic Hedgehog'],['Galactic Saturn','Galactic Saturn'],['Galactic Angel','Galactic Angel'],['Galactic Queen','Galactic Queen'],['Galactic Overlord','Galactic Overlord']]},
];
const eggs=defs.map((d,i)=>({Id:i+1,Name:d.Name,World:d.World,Price:d.Price,X:(d.World==='island'?0:500)+40+(i%3)*31,Z:132,Color:d.Color,
 Pets:d.Pets.map(([Name,Visual],j)=>({Id:i*6+j+1,Name,Rarity:rarities[j],Chance:odds[i][j],Visual,Multiplier:Number((powers[i]*factors[j]).toFixed(2)),
  Color:d.Color.map((v,k)=>Math.min(255,Math.max(35,v+((j*31+k*17)%65)-25)))}))}));
// Keep every other egg's IDs stable. Three extra sunset pets use appended IDs.
eggs[0].Name='Sunset Sky Egg'; eggs[0].Color=[232,137,220];
eggs[0].Pets=[
 [1,'Cloud Puff','Cloud','Common',30,1.2],
 [2,'Sunset Bunny','Bunny','Common',25,1.3],
 [3,'Dusk Kitty','Cat','Uncommon',18,1.5],
 [4,'Amber Deer','Deer','Uncommon',12,1.7],
 [5,'Twilight Unicorn','Unicorn','Rare',7,2.2],
 [6,'Rosy Sky Whale','Whale','Rare',5,2.6],
 [37,'Sunset Dragon','Dragon','Epic',2,3.5],
 [38,'Dawn Phoenix','Phoenix','Legendary',0.9,8],
 [39,'Celestial Castle','Castle','Secret',0.1,15],
].map(([Id,Name,kind,Rarity,Chance,Multiplier])=>({Id,Name,Visual:'Sunset'+kind,Rarity,Chance,Multiplier,Color:[232,137,220]}));
// Второе и третье яйцо острова — серии Sakura и Starlight по 9 питомцев (модели в ThemedVisuals).
// Первые шесть занимают старые ID яйца, три новых — в конце списка, сохранения не теряются.
eggs[1].Name='Sakura Egg'; eggs[1].Color=[255,140,200];
eggs[1].Pets=[
 [7,'Blossom Bunny','Bunny','Common',32,2.4],
 [8,'Petal Fox','Fox','Common',24,2.6],
 [9,'Sakura Cat','Cat','Uncommon',17,3],
 [10,'Bloom Deer','Deer','Uncommon',12,3.4],
 [11,'Cherry Sheep','Sheep','Rare',7.5,4.2],
 [12,'Rose Panda','Panda','Rare',4.5,5],
 [40,'Flora Butterfly','Butterfly','Epic',2,7],
 [41,'Sakura Dragon','Dragon','Legendary',0.9,14],
 [42,'Blossom Spirit','Spirit','Secret',0.1,32],
].map(([Id,Name,kind,Rarity,Chance,Multiplier])=>({Id,Name,Visual:'Sakura'+kind,Rarity,Chance,Multiplier,Color:[255,140,200]}));
eggs[2].Name='Starlight Egg'; eggs[2].Color=[150,100,255];
eggs[2].Pets=[
 [13,'Starlight Cat','Cat','Common',30,4.8],
 [14,'Celestial Wolf','Wolf','Common',24,5.2],
 [15,'Cosmic Owl','Owl','Uncommon',18,6],
 [16,'Nova Unicorn','Unicorn','Uncommon',12,7],
 [17,'Galaxy Whale','Whale','Rare',8,8.5],
 [18,'Solar Lion','Lion','Rare',5,10],
 [43,'Nebula Dragon','Dragon','Epic',2.3,14],
 [44,'Star Cloud','Cloud','Legendary',0.6,28],
 [45,'Astral Spirit','Spirit','Secret',0.1,65],
].map(([Id,Name,kind,Rarity,Chance,Multiplier])=>({Id,Name,Visual:'Starlight'+kind,Rarity,Chance,Multiplier,Color:[150,100,255]}));
// All ten named companions from each neon reference row are included.
const neonSeries=[
 ['Disco Grid Egg','Disco',[232,68,255],[['Pixel Cat','Cat'],['Disco Bunny','Bunny'],['Neon Raccoon','Raccoon'],['Grid Panda','Panda'],['Holo Wolf','Wolf'],['Laser Owl','Owl'],['Disco Lion','Lion'],['Synth Shark','Shark'],['Cube Dragon','Dragon'],['Matrix Bot','Robot']]],
 ['Tech Core Egg','Tech',[54,205,255],[['Core Cat','Cat'],['Mecha Bunny','Bunny'],['Security Dog','Dog'],['Repair Panda','Panda'],['Drone Fox','Fox'],['AI Owl','Owl'],['Cyber Lion','Lion'],['Data Shark','Shark'],['Nano Dragon','Dragon'],['Core Robot','Robot']]],
 ['City Lights Egg','City',[192,88,255],[['Skyline Cat','Cat'],['City Panda','Panda'],['Metro Fox','Fox'],['Street Owl','Owl'],['Tower Wolf','Wolf'],['Neon Deer','Deer'],['Sky Lion','Lion'],['Hover Whale','Whale'],['Sky Dragon','Dragon'],['Aerial Bot','Robot']]],
];
const neonOdds=[30,24,18,12,7,5,2,1,0.9,0.1];
const neonRarity=['Common','Common','Uncommon','Uncommon','Rare','Rare','Epic','Epic','Legendary','Secret'];
const neonFactors=[1.2,1.3,1.5,1.7,2.2,2.6,3.5,5,8,15];
const retiredPets=[];
neonSeries.forEach(([Name,theme,Color,pets],i)=>{
 const egg=eggs[i+3];Object.assign(egg,{Name,Color});
 egg.Pets=pets.map(([Name,kind],j)=>({Id:j<6?19+i*6+j:46+i*4+j-6,Name,Visual:`Neon${theme}_${kind}`,Rarity:neonRarity[j],Chance:neonOdds[j],Multiplier:Number((powers[i+3]*neonFactors[j]).toFixed(2)),Color}));
 retiredPets.push({...egg.Pets[1],EggId:egg.Id});
 egg.Pets=egg.Pets.filter((_,j)=>j!==1);
 egg.Pets[0].Chance+=24;
});
// Третий мир Sky Isles: три яйца по 8 питомцев (24 питомца по арту владельца; модели — ThemedVisuals, темы Cloud/Celestial/Crystal).
const skyOdds=[30,25,18,12,8,5,1.9,0.1];
const skyRarity=['Common','Common','Uncommon','Uncommon','Rare','Epic','Legendary','Secret'];
const skySeries=[
 ['Cloud Egg','Cloud',150000,[190,225,255],58,[40,46,55,65,80,110,220,500],[['Nimbus Cloud','Cloud'],['Aviator Bear','Bear'],['Balloon Hamster','Balloon'],['Breeze Tornado','Tornado'],['Rainbow Kitty','RainbowCat'],['Cloud Unicorn','Unicorn'],['Sky Griffin','Griffin'],['Angel Cat','AngelCat']]],
 ['Celestial Egg','Celestial',500000,[160,110,255],66,[62,72,86,100,125,160,360,850],[['Moon Cat','MoonCat'],['Storm Cloud','Storm'],['Blossom Sprite','Blossom'],['Sky Castle','Castle'],['Ruins Isle','Ruins'],['Winged Wolf','Wolf'],['Celestial Dragon','Dragon'],['Galaxy Whale','Whale']]],
 ['Crystal Egg','Crystal',1500000,[110,215,255],74,[100,115,135,160,200,260,560,1400],[['Pegasus','Pegasus'],['Space Whale','Whale'],['Sun Lion','Lion'],['Winged Stag','Stag'],['Clockwork Chest','Clock'],['Crystal Golem','Golem'],['Phoenix','Phoenix'],['Angel Queen','Queen']]],
];
skySeries.forEach(([Name,theme,Price,Color,firstId,mults,pets],i)=>{
 eggs.push({Id:7+i,Name,World:'sky',Price,X:1100-52+i*52,Z:112,Color,Pets:pets.map(([pn,kind],j)=>({Id:firstId+j,Name:pn,Visual:theme+kind,Rarity:skyRarity[j],Chance:skyOdds[j],Multiplier:mults[j],Color}))});
});
for(const e of eggs){const total=e.Pets.reduce((a,p)=>a+p.Chance,0);if(Math.abs(total-100)>1e-9) throw new Error(e.Name+' odds total '+total);}
writeFileSync('tools/catalog.json',JSON.stringify(eggs,null,2));
const luaString=s=>JSON.stringify(s);
const pets=[...eggs.flatMap(e=>e.Pets.map(p=>({...p,EggId:e.Id}))),...retiredPets].map(p=>`[${p.Id}]={Name=${luaString(p.Name)},Rarity=${luaString(p.Rarity)},Multiplier=${p.Multiplier},Visual=${luaString(p.Visual)},Color=Color3.fromRGB(${p.Color}),EggId=${p.EggId}},`).join('\n');
const eggLua=eggs.map(e=>`[${e.Id}]={Id=${e.Id},Name=${luaString(e.Name)},World=${luaString(e.World)},Cost=${e.Price},Position=Vector3.new(${e.X},2,${e.Z}),Color=Color3.fromRGB(${e.Color}),Pool={${e.Pets.map(p=>`{Pet=${p.Id},Chance=${p.Chance},Weight=${Math.round(p.Chance*1000)}}`).join(',')}}},`).join('\n');
writeFileSync('src/ReplicatedStorage/GameConfig.luau',`-- Generated catalog: edit tools/catalog.json generator for pet names, odds and prices.
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
${pets}
}
Config.Eggs={
${eggLua}
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
`);
