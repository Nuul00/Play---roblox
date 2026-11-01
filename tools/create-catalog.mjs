import {writeFileSync,readFileSync} from 'node:fs';
// Каждое яйцо — свои 4 питомца из разных моделей PetAssets (без повторов между яйцами).
// Чем дороже яйцо, тем сильнее питомцы и тем выше шанс редких.
const rarities=['Common','Uncommon','Rare','Legendary'];
const odds=[[60,30,9,1],[56,30,12,2],[52,30,14,4],[48,30,16,6],[44,30,18,8],[40,30,20,10]];
const powers=[1,2,4,7,12,20];
const factors=[1.2,1.5,2,3.5];
const defs=[
 {Name:'Meadow Egg',World:'island',Price:50,Color:[106,205,151],Pets:[['Clover Bunny','Bunny'],['Field Mouse','Mouse'],['Mud Piggy','Piggy'],['Amber Fox','Fox']]},
 {Name:'Blossom Egg',World:'island',Price:250,Color:[255,155,166],Pets:[['Honey Pup','Dog'],['Garden Cat','Cat'],['Bandit Raccoon','Raccoon'],['Blossom Deer','Deer']]},
 {Name:'Ancient Egg',World:'island',Price:1000,Color:[100,205,227],Pets:[['Grizzly Bear','Bear'],['Moon Wolf','Wolf'],['Bamboo Panda','Panda'],['Ancient Unicorn','Unicorn']]},
 {Name:'Frost Egg',World:'neon',Price:2500,Color:[62,213,255],Pets:[['Ice Penguin','Penguin'],['Polar Bear','Polar Bear'],['Neon Reindeer','Reindeer'],['Sky Pegasus','Pegasus']]},
 {Name:'Shadow Egg',World:'neon',Price:10000,Color:[195,105,255],Pets:[['Night Bat','Bat'],['Web Spider','Spider'],['Phantom Spectre','Spectre'],['Volt Dragon','Dragon']]},
 {Name:'Galaxy Egg',World:'neon',Price:50000,Color:[255,116,207],Pets:[['Gummy Bear','Gummy Bear'],['Cosmo Dino','Dinosaur'],['Star Angel','Angel'],['Galaxy Phoenix','phoenix']],Top:'Mythic'},
];
const eggs=defs.map((d,i)=>({Id:i+1,Name:d.Name,World:d.World,Price:d.Price,X:(d.World==='island'?0:500)+40+(i%3)*31,Z:132,Color:d.Color,
 Pets:d.Pets.map(([Name,Visual],j)=>({Id:i*4+j+1,Name,Rarity:j===3&&d.Top?d.Top:rarities[j],Chance:odds[i][j],Visual,Multiplier:Number((powers[i]*factors[j]).toFixed(2)),
  Color:d.Color.map((v,k)=>Math.min(255,Math.max(35,v+((j*31+k*17)%65)-25)))}))}));
for(const e of eggs){const total=e.Pets.reduce((a,p)=>a+p.Chance,0);if(total!==100) throw new Error(e.Name+' odds total '+total);}
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
