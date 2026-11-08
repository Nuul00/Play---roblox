// Собирает открываемый в Roblox Studio проект из шести Luau-исходников.
// Запуск из любой папки: node tools/build-place.mjs
// Нужен только Node.js; сторонние пакеты и сеть не используются.

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sources = [
  "src/ReplicatedStorage/GameConfig.luau",
  "src/ServerScriptService/GameServer.server.luau",
  "src/StarterPlayer/StarterPlayerScripts/GameHUD.client.luau",
  "src/StarterPlayer/StarterPlayerScripts/GameEffects.client.luau",
  "src/ReplicatedStorage/PetVisuals.luau",
  "src/StarterPlayer/StarterPlayerScripts/ShopUI.client.luau",
  "src/ServerScriptService/WorldProgress.server.luau",
  "src/ServerScriptService/Environment.server.luau",
];

function xmlText(value) {
  return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}

function protectedSource(source) {
  // Каждый фрагмент ]]> закрывает CDATA, поэтому разбиваем его на две секции.
  return `<ProtectedString name="Source"><![CDATA[${source.replaceAll("]]>", "]]]]><![CDATA[>")}]]></ProtectedString>`;
}

function item(className, referent, name, extraProperties = "", children = "") {
  return `<Item class="${className}" referent="${referent}">
<Properties>
<string name="Name">${xmlText(name)}</string>
${extraProperties}
</Properties>
${children}
</Item>`;
}

function coordinateFrame(name, position, matrix) {
  const [x, y, z] = position;
  const entries = matrix.map((value, index) => {
    return `<R${Math.floor(index / 3)}${index % 3}>${value}</R${Math.floor(index / 3)}${index % 3}>`;
  });
  return `<CoordinateFrame name="${name}"><X>${x}</X><Y>${y}</Y><Z>${z}</Z>${entries.join("")}</CoordinateFrame>`;
}

function vector3(name, [x, y, z]) {
  return `<Vector3 name="${name}"><X>${x}</X><Y>${y}</Y><Z>${z}</Z></Vector3>`;
}

function color3(name, [r, g, b]) {
  return `<Color3 name="${name}"><R>${r / 255}</R><G>${g / 255}</G><B>${b / 255}</B></Color3>`;
}

function udim2(name, xScale, xOffset, yScale, yOffset) {
  return `<UDim2 name="${name}"><XS>${xScale}</XS><XO>${xOffset}</XO><YS>${yScale}</YS><YO>${yOffset}</YO></UDim2>`;
}

function createLabel(referent, text, offset, options = {}) {
  const labelProperties = [
    udim2("Size", 1, 0, 1, 0),
    '<float name="BackgroundTransparency">1</float>',
    '<token name="Font">19</token>', // Enum.Font.GothamBold.
    `<float name="TextSize">${options.textSize ?? 20}</float>`,
    color3("TextColor3", [255, 255, 255]),
    '<float name="TextStrokeTransparency">0.35</float>',
    `<string name="Text">${xmlText(text)}</string>`,
  ].join("\n");
  const billboardProperties = [
    udim2("Size", 0, options.width ?? 240, 0, options.height ?? 64),
    vector3("StudsOffset", offset),
    '<bool name="AlwaysOnTop">true</bool>',
    '<bool name="Enabled">true</bool>',
    '<float name="MaxDistance">85</float>',
  ].join("\n");
  return item("BillboardGui", referent, "GameLabel", billboardProperties,
    item("TextLabel", `${referent}_TEXT`, "TextLabel", labelProperties));
}

function createPart(referent, name, size, position, color, options = {}) {
  const [r, g, b] = color;
  // Для BasePart Roblox сохраняет Size, Shape и Color под этими XML-именами.
  const packedColor = 0xff000000 + r * 0x10000 + g * 0x100 + b;
  const properties = [
    vector3("size", size),
    coordinateFrame("CFrame", position, options.rotation ?? [1, 0, 0, 0, 1, 0, 0, 0, 1]),
    `<Color3uint8 name="Color3uint8">${packedColor}</Color3uint8>`,
    '<bool name="Anchored">true</bool>',
    `<bool name="CanCollide">${options.canCollide ?? true}</bool>`,
    `<bool name="CanTouch">${options.canTouch ?? true}</bool>`,
    `<bool name="CanQuery">${options.canQuery ?? true}</bool>`,
    `<bool name="CastShadow">${options.castShadow ?? true}</bool>`,
    `<token name="Material">${options.material ?? 256}</token>`,
    `<token name="shape">${options.shape ?? 1}</token>`,
    '<token name="TopSurface">0</token>',
    '<token name="BottomSurface">0</token>',
    options.properties ?? "",
  ].join("\n");
  return item(options.className ?? "Part", referent, name, properties, options.children ?? "");
}

function createPrompt(referent, name, action, objectText) {
  return item("ProximityPrompt", referent, name, [
    `<string name="ActionText">${xmlText(action)}</string>`,
    `<string name="ObjectText">${xmlText(objectText)}</string>`,
    '<token name="KeyboardKeyCode">101</token>', // Enum.KeyCode.E.
    '<float name="HoldDuration">0</float>',
    '<float name="MaxActivationDistance">10</float>',
    '<bool name="RequiresLineOfSight">false</bool>',
    '<bool name="Enabled">true</bool>',
  ].join("\n"));
}


const catalog=[{"Id":1,"Name":"Meadow Egg","World":"island","Price":125,"X":40,"Z":132,"Color":[106,205,151],"Pets":[{"Id":1,"Name":"Clover Bunny","Rarity":"Common","Chance":32,"Visual":"bunny","Multiplier":1.15,"Color":[81,197,160]},{"Id":2,"Name":"Honey Pup","Rarity":"Common","Chance":30,"Visual":"dog","Multiplier":1.25,"Color":[112,228,126]},{"Id":3,"Name":"Meadow Cat","Rarity":"Uncommon","Chance":14,"Visual":"cat","Multiplier":1.5,"Color":[143,194,157]},{"Id":4,"Name":"Acorn Fox","Rarity":"Uncommon","Chance":12,"Visual":"fox","Multiplier":1.7,"Color":[109,225,188]},{"Id":5,"Name":"Moss Owl","Rarity":"Rare","Chance":7,"Visual":"owl","Multiplier":2,"Color":[140,191,154]},{"Id":6,"Name":"Bloom Deer","Rarity":"Epic","Chance":2.4,"Visual":"dragon","Multiplier":2.6,"Color":[106,222,185]},{"Id":7,"Name":"Fern Griffin","Rarity":"Epic","Chance":1.499,"Visual":"deer","Multiplier":3.2,"Color":[137,188,151]},{"Id":8,"Name":"Golden Stag","Rarity":"Legendary","Chance":1,"Visual":"lion","Multiplier":5,"Color":[103,219,182]},{"Id":9,"Name":"Sun Phoenix","Rarity":"Legendary","Chance":0.1,"Visual":"phoenix","Multiplier":7,"Color":[134,185,148]},{"Id":10,"Name":"World Tree Spirit","Rarity":"Mythic","Chance":0.001,"Visual":"spirit","Multiplier":12,"Color":[100,216,179]}]},{"Id":2,"Name":"Blossom Egg","World":"island","Price":150,"X":71,"Z":132,"Color":[255,155,166],"Pets":[{"Id":11,"Name":"Peach Kitten","Rarity":"Common","Chance":32,"Visual":"bunny","Multiplier":2.3,"Color":[230,147,175]},{"Id":12,"Name":"Berry Bunny","Rarity":"Common","Chance":30,"Visual":"dog","Multiplier":2.5,"Color":[255,178,141]},{"Id":13,"Name":"Rose Panda","Rarity":"Uncommon","Chance":14,"Visual":"cat","Multiplier":3,"Color":[255,144,172]},{"Id":14,"Name":"Tulip Fox","Rarity":"Uncommon","Chance":12,"Visual":"fox","Multiplier":3.4,"Color":[255,175,203]},{"Id":15,"Name":"Orchid Owl","Rarity":"Rare","Chance":7,"Visual":"owl","Multiplier":4,"Color":[255,141,169]},{"Id":16,"Name":"Blossom Drake","Rarity":"Epic","Chance":2.4,"Visual":"dragon","Multiplier":5.2,"Color":[255,172,200]},{"Id":17,"Name":"Lotus Kirin","Rarity":"Epic","Chance":1.499,"Visual":"deer","Multiplier":6.4,"Color":[255,138,166]},{"Id":18,"Name":"Amber Lion","Rarity":"Legendary","Chance":1,"Visual":"lion","Multiplier":10,"Color":[252,169,197]},{"Id":19,"Name":"Spring Phoenix","Rarity":"Legendary","Chance":0.1,"Visual":"phoenix","Multiplier":14,"Color":[255,135,163]},{"Id":20,"Name":"Celestial Blossom","Rarity":"Mythic","Chance":0.001,"Visual":"spirit","Multiplier":24,"Color":[249,166,194]}]},{"Id":3,"Name":"Ancient Egg","World":"island","Price":1000,"X":102,"Z":132,"Color":[100,205,227],"Pets":[{"Id":21,"Name":"Crystal Cub","Rarity":"Common","Chance":32,"Visual":"bunny","Multiplier":3.45,"Color":[75,197,236]},{"Id":22,"Name":"Jade Bunny","Rarity":"Common","Chance":30,"Visual":"dog","Multiplier":3.75,"Color":[106,228,202]},{"Id":23,"Name":"Emerald Fox","Rarity":"Uncommon","Chance":14,"Visual":"cat","Multiplier":4.5,"Color":[137,194,233]},{"Id":24,"Name":"Pearl Panda","Rarity":"Uncommon","Chance":12,"Visual":"fox","Multiplier":5.1,"Color":[103,225,255]},{"Id":25,"Name":"Sapphire Owl","Rarity":"Rare","Chance":7,"Visual":"owl","Multiplier":6,"Color":[134,191,230]},{"Id":26,"Name":"Prism Dragon","Rarity":"Epic","Chance":2.4,"Visual":"dragon","Multiplier":7.8,"Color":[100,222,255]},{"Id":27,"Name":"Amethyst Kirin","Rarity":"Epic","Chance":1.499,"Visual":"deer","Multiplier":9.6,"Color":[131,188,227]},{"Id":28,"Name":"Diamond Lion","Rarity":"Legendary","Chance":1,"Visual":"lion","Multiplier":15,"Color":[97,219,255]},{"Id":29,"Name":"Aurora Phoenix","Rarity":"Legendary","Chance":0.1,"Visual":"phoenix","Multiplier":21,"Color":[128,185,224]},{"Id":30,"Name":"Ancient Forest God","Rarity":"Mythic","Chance":0.001,"Visual":"spirit","Multiplier":36,"Color":[94,216,255]}]},{"Id":4,"Name":"Circuit Egg","World":"neon","Price":2500,"X":540,"Z":132,"Color":[62,213,255],"Pets":[{"Id":31,"Name":"Byte Cat","Rarity":"Common","Chance":32,"Visual":"bunny","Multiplier":4.6,"Color":[37,205,255]},{"Id":32,"Name":"Circuit Pup","Rarity":"Common","Chance":30,"Visual":"dog","Multiplier":5,"Color":[68,236,230]},{"Id":33,"Name":"Pixel Fox","Rarity":"Uncommon","Chance":14,"Visual":"cat","Multiplier":6,"Color":[99,202,255]},{"Id":34,"Name":"Laser Bunny","Rarity":"Uncommon","Chance":12,"Visual":"fox","Multiplier":6.8,"Color":[65,233,255]},{"Id":35,"Name":"Holo Owl","Rarity":"Rare","Chance":7,"Visual":"owl","Multiplier":8,"Color":[96,199,255]},{"Id":36,"Name":"Volt Dragon","Rarity":"Epic","Chance":2.4,"Visual":"dragon","Multiplier":10.4,"Color":[62,230,255]},{"Id":37,"Name":"Cyber Griffin","Rarity":"Epic","Chance":1.499,"Visual":"deer","Multiplier":12.8,"Color":[93,196,255]},{"Id":38,"Name":"Solar Lion","Rarity":"Legendary","Chance":1,"Visual":"lion","Multiplier":20,"Color":[59,227,255]},{"Id":39,"Name":"Nova Phoenix","Rarity":"Legendary","Chance":0.1,"Visual":"phoenix","Multiplier":28,"Color":[90,193,252]},{"Id":40,"Name":"Quantum Spirit","Rarity":"Mythic","Chance":0.001,"Visual":"spirit","Multiplier":48,"Color":[56,224,255]}]},{"Id":5,"Name":"Plasma Egg","World":"neon","Price":10000,"X":571,"Z":132,"Color":[195,105,255],"Pets":[{"Id":41,"Name":"Ion Bunny","Rarity":"Common","Chance":32,"Visual":"bunny","Multiplier":5.75,"Color":[170,97,255]},{"Id":42,"Name":"Plasma Cat","Rarity":"Common","Chance":30,"Visual":"dog","Multiplier":6.25,"Color":[201,128,230]},{"Id":43,"Name":"Chrome Fox","Rarity":"Uncommon","Chance":14,"Visual":"cat","Multiplier":7.5,"Color":[232,94,255]},{"Id":44,"Name":"Glitch Panda","Rarity":"Uncommon","Chance":12,"Visual":"fox","Multiplier":8.5,"Color":[198,125,255]},{"Id":45,"Name":"Pulse Owl","Rarity":"Rare","Chance":7,"Visual":"owl","Multiplier":10,"Color":[229,91,255]},{"Id":46,"Name":"Vortex Dragon","Rarity":"Epic","Chance":2.4,"Visual":"dragon","Multiplier":13,"Color":[195,122,255]},{"Id":47,"Name":"Neon Kirin","Rarity":"Epic","Chance":1.499,"Visual":"deer","Multiplier":16,"Color":[226,88,255]},{"Id":48,"Name":"Cosmic Lion","Rarity":"Legendary","Chance":1,"Visual":"lion","Multiplier":25,"Color":[192,119,255]},{"Id":49,"Name":"Supernova Phoenix","Rarity":"Legendary","Chance":0.1,"Visual":"phoenix","Multiplier":35,"Color":[223,85,252]},{"Id":50,"Name":"Singularity","Rarity":"Mythic","Chance":0.001,"Visual":"spirit","Multiplier":60,"Color":[189,116,255]}]},{"Id":6,"Name":"Galaxy Egg","World":"neon","Price":50000,"X":602,"Z":132,"Color":[255,116,207],"Pets":[{"Id":51,"Name":"Star Cub","Rarity":"Common","Chance":32,"Visual":"bunny","Multiplier":6.9,"Color":[230,108,216]},{"Id":52,"Name":"Void Bunny","Rarity":"Common","Chance":30,"Visual":"dog","Multiplier":7.5,"Color":[255,139,182]},{"Id":53,"Name":"Astro Fox","Rarity":"Uncommon","Chance":14,"Visual":"cat","Multiplier":9,"Color":[255,105,213]},{"Id":54,"Name":"Lunar Panda","Rarity":"Uncommon","Chance":12,"Visual":"fox","Multiplier":10.2,"Color":[255,136,244]},{"Id":55,"Name":"Comet Owl","Rarity":"Rare","Chance":7,"Visual":"owl","Multiplier":12,"Color":[255,102,210]},{"Id":56,"Name":"Orbit Dragon","Rarity":"Epic","Chance":2.4,"Visual":"dragon","Multiplier":15.6,"Color":[255,133,241]},{"Id":57,"Name":"Galaxy Griffin","Rarity":"Epic","Chance":1.499,"Visual":"deer","Multiplier":19.2,"Color":[255,99,207]},{"Id":58,"Name":"Celestial Lion","Rarity":"Legendary","Chance":1,"Visual":"lion","Multiplier":30,"Color":[252,130,238]},{"Id":59,"Name":"Eternal Phoenix","Rarity":"Legendary","Chance":0.1,"Visual":"phoenix","Multiplier":42,"Color":[255,96,204]},{"Id":60,"Name":"Astral Sovereign","Rarity":"Mythic","Chance":0.001,"Visual":"spirit","Multiplier":72,"Color":[249,127,235]}]}];
let serial=0;
const nextId=()=> 'LAND_'+(++serial);
function part(name,size,pos,color,opt={}) {return createPart(nextId(),name,size,pos,color,opt);}
function model(name,children,props='') {return item('Model',nextId(),name,props,children.join('\n'));}
const yaw=a=>[Math.cos(a),0,Math.sin(a),0,1,0,-Math.sin(a),0,Math.cos(a)];
const verticalCylinder=[0,-1,0,1,0,0,0,0,1];
function tree(x,z,scale=1,city=false) {
 const c=city?[80,210,240]:[48,117,65];
 const pieces=[part('Trunk',[10*scale,1.8*scale,1.8*scale],[x,5*scale,z],[104,73,49],{shape:2,rotation:verticalCylinder})];
 for(let i=0;i<7;i++) {
  const angle=i*2.4, r=(i%3)*1.5*scale;
  pieces.push(part('Canopy',[7*scale,5.5*scale,6.5*scale],[x+Math.cos(angle)*r,(10+(i%3)*1.4)*scale,z+Math.sin(angle)*r],c.map((v,k)=>Math.min(255,v+(i%3)*9)),{shape:0,material:city?288:256,canCollide:false}));
 }
 for(const side of [-1,1]) pieces.push(part('Branch',[4*scale,0.8*scale,0.8*scale],[x+side*1.5*scale,8*scale,z],[104,73,49],{rotation:yaw(side*0.7)}));
 return model('Tree',pieces);
}
function kiosk(centerX,city) {
 const x=centerX-45,z=145,wood=city?[42,49,74]:[147,103,68],accent=city?[67,221,248]:[111,179,128];
 const out=[part('Deck',[0.35,30,20],[x,0.175,z-5],[192,162,112],{shape:2,rotation:verticalCylinder}),
 part('Counter',[17,1.7,2.4],[x,0.95,z],wood,{children:createPrompt(nextId(),'OpenShop','Browse upgrades','Upgrade Kiosk')}),
 part('CounterTop',[18,0.35,3],[x,1.95,z],[242,215,166])];
 for(const side of [-1,1]) {
  out.push(part('CounterWing',[4,1.7,3],[x+side*9,0.95,z-1.4],wood,{rotation:yaw(side*0.5)}));
  out.push(part('AwningPost',[0.65,9,0.65],[x+side*10.5,4.5,z-6],wood,{shape:2,rotation:verticalCylinder}));
 }
 for(let i=0;i<11;i++) out.push(part('CurvedCanopy',[2,0.32,13],[x-10+i*2,9+Math.sin(i/10*Math.PI)*1.4,z-4],i%2?accent:[247,237,202]));
 out.push(part('VendorAnchor',[0.1,0.1,0.1],[x,0.4,z-5.5],[255,255,255],{canCollide:false,canQuery:false,properties:'<float name="Transparency">1</float>'}));
 const npc=[part('Body',[1.8,2,1],[x,3,z-5.5],accent),part('Head',[1.2,1.2,1.2],[x,4.6,z-5.5],[239,198,157],{shape:0})];
 for(const side of [-1,1]) {npc.push(part('Arm',[0.6,2,0.7],[x+side*1.2,3,z-5.5],[239,198,157]));npc.push(part('Leg',[0.7,2,0.7],[x+side*0.45,1,z-5.5],[41,51,68]));}
 out.push(model('VendorPlaceholder',npc));
 out.push(part('PlantPot',[2,2,2],[x-12,1,z+1],[199,140,101],{shape:2,rotation:verticalCylinder}));
 out.push(part('Plant',[3.5,4,3.5],[x-12,3,z+1],[65,153,91],{shape:0,canCollide:false}));
 return model('UpgradeShop',out);
}
function eggStand(e) {
 const x=e.X,z=e.Z,out=[];
 out.push(part('Interact',[5,4,3],[x,2,z+3.5],[255,255,255],{canCollide:false,canTouch:false,properties:'<float name="Transparency">1</float>',children:createPrompt(nextId(),'OpenEggMenu','View egg',e.Name)}));
 // Small ground ring; no platform or sign above the egg.
 for(let i=0;i<18;i++) {const t=i/18*Math.PI*2;out.push(part('Rune',[0.2,0.06,0.7],[x+Math.cos(t)*2.2,0.07,z+Math.sin(t)*2.2],e.Color,{material:288,canCollide:false,canTouch:false,rotation:yaw(-t)}));}
 const pivotId=nextId();
 const shell=[createPart(pivotId,'EggPivot',[0.1,0.1,0.1],[x,1.95,z],[255,255,255],{canCollide:false,canQuery:false,properties:'<float name="Transparency">1</float>'})];
 const tier=(e.Id-1)%3;
 for(let i=0;i<48;i++) {
  const t=-1+(i+0.5)*2/48;
  const r=(1.12+tier*0.08)*Math.sqrt(1-t*t)*(1-(0.2+tier*0.035)*t);
  const col=(i%12<3||tier===2&&i%9<2)?e.Color:e.Color.map(v=>Math.round(v*0.28+180));
  shell.push(part('Shell',[0.075,r*2,r*2],[x,1.95+t*(1.65+tier*0.05),z],col,{shape:2,rotation:verticalCylinder,canCollide:false,canTouch:false,material:e.World==='neon'?288:256}));
 }
 if(tier>0) for(let i=0;i<5;i++){const t=i/5*Math.PI*2;shell.push(part(tier===2?'Crystal':'Petal',[0.4,0.7+tier*0.4,0.4],[x+Math.cos(t)*0.65,3.55,z+Math.sin(t)*0.65],e.Color,{shape:tier===1?0:1,material:288,canCollide:false}));}
 out.push(model('EggDisplay',shell,'<Ref name="PrimaryPart">'+pivotId+'</Ref>'));
 return model('EggStand'+e.Id,out);
}
function portal(name,x,z,neon,textValue) {
 const accent=neon?[115,92,255]:[103,209,136];
 const parts=[];
 for(const side of [-1,1]) {
  parts.push(part('ArchPillar',[2.5,15,3.5],[x+side*6,7.5,z],neon?[35,37,65]:[176,169,139]));
  parts.push(part('Light',[0.4,13,3.7],[x+side*4.8,7.5,z],accent,{material:288,canCollide:false}));
 }
 for(let i=0;i<9;i++){const t=Math.PI+i/8*Math.PI;parts.push(part('ArchCrown',[2.5,2.5,3.5],[x+Math.cos(t)*6,15-Math.sin(t)*3,z],accent,{shape:0,material:neon?288:256,canCollide:false}));}
 parts.push(part('GateMist',[9.5,13,0.3],[x,7,z],accent,{material:288,canCollide:false,canTouch:false,properties:'<float name="Transparency">0.65</float>'}));
 const pad=part(name,[9,12,1],[x,6,z],accent,{canCollide:false,canTouch:false,properties:'<float name="Transparency">1</float>',children:createLabel(nextId(),textValue,[0,9,0],{width:250,height:60,textSize:17})+'\n'+createPrompt(nextId(),'EnterWorld','Travel',neon?'Neon District':'Meadow Isles')});
 return {art:model(name+'Arch',parts),pad};
}
function zoneParts(cx,city) {
 const out=[part('Floor',[300,4,460],[cx,-2.2,0],city?[37,43,63]:[79,144,85],{material:city?256:1280}),kiosk(cx,city)];
 out.push(part('MainPath',[16,0.18,390],[cx,0.1,0],city?[26,30,45]:[211,190,145]));
 out.push(part('EggPath',[135,0.18,8],[cx+65,0.1,150],city?[26,30,45]:[211,190,145]));
 out.push(part('ShopPath',[75,0.18,8],[cx-37,0.1,158],city?[26,30,45]:[211,190,145]));
 out.push(part('ArrivalPlaza',[92,0.2,44],[cx,0.1,186],city?[47,52,78]:[225,211,171]));
 for(const e of catalog.filter(e=>e.World===(city?'neon':'island'))) out.push(eggStand(e));
 let coin=0;
 for(let row=0;row<12;row++) for(const side of [-1,1]) for(const lane of [0,1]) {
  const x=cx+side*(24+lane*22+Math.sin(row*1.7)*5),z=108-row*24;
  out.push(part('Coin_'+(++coin),[0.45,2.1,2.1],[x,1.8,z],[255,208,73],{shape:2,material:288,canCollide:false,children:createLabel(nextId(),'+'+(city?25:5)+' BASE',[0,2.4,0],{width:110,height:28,textSize:14}).replace('<float name="MaxDistance">85</float>','<float name="MaxDistance">13</float>').replace('<bool name="Enabled">true</bool>','<bool name="Enabled">false</bool>')}));
 }
 for(let i=0;i<36;i++) {
  const side=i%2?1:-1,x=cx+side*(92+(i%4)*12),z=-194+Math.floor(i/2)*23;
  if(city) {
   const h=15+(i%5)*6;
   out.push(part('Tower',[13,h,15],[x,h/2,z],[29,35,55]));
   out.push(part('TowerGlow',[13.5,0.4,15.5],[x,h,z],i%3?[84,229,255]:[225,105,255],{material:288}));
   for(let k=0;k<3;k++) out.push(part('Window',[0.15,h-3,0.5],[x-side*6.6,h/2,z-4+k*4],[92,215,249],{material:288,canCollide:false}));
  } else out.push(tree(x,z,0.8+(i%4)*0.18));
 }
 for(let i=0;i<42;i++) {
  const side=i%2?1:-1,x=cx+side*(72+(i%5)*12),z=-202+Math.floor(i/2)*19;
  out.push(part('Shrub',[5+(i%3),2.5,4],[x,1.2,z],city?[67,100,145]:[73,149,80],{shape:0,canCollide:false}));
  for(let j=0;j<3;j++) out.push(part('Flower',[0.65,0.5,0.65],[x+j*0.8-0.8,2.5,z+1],city?[130,140,255]:[[255,209,116],[239,164,185],[200,188,255]][i%3],{shape:0,material:city?288:256,canCollide:false}));
 }
 for(const z of [-165,-100,-35,30,95,170]) for(const side of [-1,1]) {
  out.push(part('LampPost',[0.35,7,0.35],[cx+side*11,3.5,z],city?[55,65,91]:[122,95,61]));
  out.push(part('Lamp',[1.2,1.4,1.2],[cx+side*11,7.2,z],city?[127,224,255]:[255,224,153],{material:288,shape:0,canCollide:false}));
 }
 // Comfortable benches and rocks away from the collection paths.
 for(const side of [-1,1]) {
  out.push(part('Bench',[12,0.5,3],[cx+side*58,1.3,178],[146,101,62]));
  out.push(part('BenchBack',[12,2,0.5],[cx+side*58,2.1,179.5],[146,101,62]));
 }
 if(!city) {
  out.push(part('PondPreview',[47,0.1,55],[cx-95,-0.02,-30],[72,157,179],{canCollide:false}));
  for(let i=0;i<14;i++){const t=i/14*Math.PI*2;out.push(part('PondRock',[5,2,4],[cx-95+Math.cos(t)*27,0.6,-30+Math.sin(t)*31],[141,151,132],{shape:0}));}
 }
 return out;
}
function createWorld() {
 const island=zoneParts(0,false);
 island.push(part('Start',[6,0.2,6],[0,0.4,185],[255,255,255],{className:'SpawnLocation',canCollide:false,properties:'<bool name="Neutral">true</bool><int name="Duration">0</int><float name="Transparency">1</float>'}));
 const toNeon=portal('PortalToNeon',0,-185,true,'NEON DISTRICT\nSPEED 28 · LEVEL 3');island.push(toNeon.art,toNeon.pad);
 for(const [i,name] of ['BoardCoins','BoardEggs','BoardPickups'].entries()) {
  island.push(part(name,[43,18,1.3],[-57+i*57,11,212],[46,66,60]));
  for(const side of [-1,1]) island.push(part('BoardPost',[1.5,22,2],[-57+i*57+side*22,11,212],[137,102,65]));
 }
 const city=zoneParts(500,true);
 const back=portal('PortalToIsland',500,-185,false,'MEADOW ISLES');city.push(back.art,back.pad);
 island.push(model('NeonCity',city));
 return model('CoinSpeedWorld',island);
}

function createCamera() {
  // Аналог CFrame.lookAt(Vector3.new(170, 135, 170), Vector3.new(90, 0, 0)).
  const position = [270, 240, 340];
  const target = [0, 0, 20];
  const delta = position.map((value, index) => value - target[index]);
  const length = Math.hypot(...delta);
  const back = delta.map((value) => value / length);
  const horizontalLength = Math.hypot(back[0], back[2]);
  const right = [back[2] / horizontalLength, 0, -back[0] / horizontalLength];
  const up = [
    back[1] * right[2],
    back[2] * right[0] - back[0] * right[2],
    -back[1] * right[0],
  ];
  const matrix = [
    right[0], up[0], back[0],
    right[1], up[1], back[1],
    right[2], up[2], back[2],
  ];
  const properties = [
    coordinateFrame("CFrame", position, matrix),
    coordinateFrame("Focus", target, [1, 0, 0, 0, 1, 0, 0, 0, 1]),
    '<token name="CameraType">0</token>',
    '<float name="FieldOfView">70</float>',
  ].join("\n");
  return item("Camera", "RBX_CAMERA", "Camera", properties);
}

function main() {
  const missing = sources.filter((relativePath) => !existsSync(resolve(projectRoot, relativePath)));
  if (missing.length > 0) {
    throw new Error(`Не найдены исходники:\n${missing.map((path) => `  ${path}`).join("\n")}\nСначала добавьте все шесть скриптов.`);
  }

  const [config, server, hud, effects, petVisuals, shopUI, progress, environment] = sources.map((relativePath) => {
    const source = readFileSync(resolve(projectRoot, relativePath), "utf8");
    if (/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/u.test(source)) {
      throw new Error(`В ${relativePath} есть управляющий символ, недопустимый в XML.`);
    }
    return protectedSource(source);
  });

  let petLibrary='';
  const assetPath=resolve(projectRoot,'assets/PetAssets.xml');
  if(existsSync(assetPath)) petLibrary=readFileSync(assetPath,'utf8');
  const services = [
    item("Workspace", "RBX_WORKSPACE", "Workspace", '<Ref name="CurrentCamera">RBX_CAMERA</Ref>', createCamera() + "\n" + createWorld() + item('Terrain','RBX_TERRAIN','Terrain','<bool name="Decoration">true</bool><float name="GrassLength">0.22</float>')),
    item("ReplicatedStorage", "RBX_REPLICATED_STORAGE", "ReplicatedStorage", "",
      item("ModuleScript", "RBX_GAME_CONFIG", "GameConfig", config) + "\n" + item("ModuleScript", "RBX_PET_VISUALS", "PetVisuals", petVisuals) + petLibrary),
    item("ServerScriptService", "RBX_SERVER_SCRIPT_SERVICE", "ServerScriptService", "",
      item("Script", "RBX_GAME_SERVER", "GameServer", server) + "\n" + item("Script", "RBX_WORLD_PROGRESS", "WorldProgress", progress) + "\n" + item("Script", "RBX_ENVIRONMENT", "Environment", environment)),
    item("StarterPlayer", "RBX_STARTER_PLAYER", "StarterPlayer", "",
      item("StarterPlayerScripts", "RBX_STARTER_PLAYER_SCRIPTS", "StarterPlayerScripts", "",
        item("LocalScript", "RBX_GAME_HUD", "GameHUD", hud) + "\n"
        + item("LocalScript", "RBX_GAME_EFFECTS", "GameEffects", effects) + "\n" + item("LocalScript", "RBX_SHOP_UI", "ShopUI", shopUI))),
  ];

  const xml = `<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
<Meta name="ExplicitAutoJoints">true</Meta>
<External>null</External>
<External>nil</External>
${services.join("\n")}
</roblox>
`;
  for (const filename of ["CoinSprint.rbxlx", "CoinSprint_Upgrades.rbxlx", "CoinSprint_World.rbxlx", "CoinSprint_Shops.rbxlx", "CoinSprint_Remastered.rbxlx"]) {
    const output = resolve(projectRoot, filename);
    writeFileSync(output, xml, "utf8");
    console.log(`Готово: ${output}`);
  }
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
