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
for(const e of eggs){const total=e.Pets.reduce((a,p)=>a+p.Chance,0);if(Math.abs(total-100)>1e-9) throw new Error(e.Name+' odds total '+total);}
writeFileSync('tools/catalog.json',JSON.stringify(eggs,null,2));
const luaString=s=>JSON.stringify(s);
const pets=eggs.flatMap(e=>e.Pets.map(p=>`[${p.Id}]={Name=${luaString(p.Name)},Rarity=${luaString(p.Rarity)},Multiplier=${p.Multiplier},Visual=${luaString(p.Visual)},Color=Color3.fromRGB(${p.Color}),EggId=${e.Id}},`)).join('\n');
const eggLua=eggs.map(e=>`[${e.Id}]={Id=${e.Id},Name=${luaString(e.Name)},World=${luaString(e.World)},Cost=${e.Price},Position=Vector3.new(${e.X},2,${e.Z}),Color=Color3.fromRGB(${e.Color}),Pool={${e.Pets.map(p=>`{Pet=${p.Id},Chance=${p.Chance},Weight=${Math.round(p.Chance*1000)}}`).join(',')}}},`).join('\n');
writeFileSync('src/ReplicatedStorage/GameConfig.luau',`-- Generated catalog: edit tools/catalog.json generator for pet names, odds and prices.
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
${pets}
}
Config.Eggs={
${eggLua}
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
`);
