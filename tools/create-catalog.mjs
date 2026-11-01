import {writeFileSync,readFileSync} from 'node:fs';
const odds=[32,30,14,12,7,2.4,1.499,1,0.1,0.001];
const rarities=['Common','Common','Uncommon','Uncommon','Rare','Epic','Epic','Legendary','Legendary','Mythic'];
const names=[
 ['Clover Bunny','Honey Pup','Meadow Cat','Acorn Fox','Moss Owl','Bloom Deer','Fern Griffin','Golden Stag','Sun Phoenix','World Tree Spirit'],
 ['Peach Kitten','Berry Bunny','Rose Panda','Tulip Fox','Orchid Owl','Blossom Drake','Lotus Kirin','Amber Lion','Spring Phoenix','Celestial Blossom'],
 ['Crystal Cub','Jade Bunny','Emerald Fox','Pearl Panda','Sapphire Owl','Prism Dragon','Amethyst Kirin','Diamond Lion','Aurora Phoenix','Ancient Forest God'],
 ['Byte Cat','Circuit Pup','Pixel Fox','Laser Bunny','Holo Owl','Volt Dragon','Cyber Griffin','Solar Lion','Nova Phoenix','Quantum Spirit'],
 ['Ion Bunny','Plasma Cat','Chrome Fox','Glitch Panda','Pulse Owl','Vortex Dragon','Neon Kirin','Cosmic Lion','Supernova Phoenix','Singularity'],
 ['Star Cub','Void Bunny','Astro Fox','Lunar Panda','Comet Owl','Orbit Dragon','Galaxy Griffin','Celestial Lion','Eternal Phoenix','Astral Sovereign']
];
const colors=[[106,205,151],[255,155,166],[100,205,227],[62,213,255],[195,105,255],[255,116,207]];
const visuals=['bunny','dog','cat','fox','penguin','dragon','deer','bear','pegasus','spectre'];
const eggs=names.map((list,i)=>({Id:i+1,Name:['Meadow Egg','Blossom Egg','Ancient Egg','Circuit Egg','Plasma Egg','Galaxy Egg'][i],World:i<3?'island':'neon',Price:[125,150,1000,2500,10000,50000][i],X:(i<3?0:500)+40+(i%3)*31,Z:132,Color:colors[i],Pets:list.map((Name,j)=>({Id:i*10+j+1,Name,Rarity:rarities[j],Chance:odds[j],Visual:visuals[j],Multiplier:Number(((i+1)*[1.15,1.25,1.5,1.7,2,2.6,3.2,5,7,12][j]).toFixed(2)),Color:colors[i].map((v,k)=>Math.min(255,Math.max(35,v+((j*31+k*17)%65)-25)))}))}));
for(const egg of eggs) for(const pet of egg.Pets) pet.Name=pet.Name.replaceAll('Owl','Penguin').replaceAll('Lion','Bear').replaceAll('Phoenix','Pegasus').replaceAll('Griffin','Deer');
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
