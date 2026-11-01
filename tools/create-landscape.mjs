import {readFileSync,writeFileSync} from 'node:fs';
const eggs=JSON.parse(readFileSync('tools/catalog.json','utf8'));
let b=readFileSync('tools/build-place.mjs','utf8');
// Keep the XML primitives and source-packaging code; replace the authored environment.
const a=b.indexOf('function createWorkshop('),z=b.indexOf('function createCamera()',a);
const worldCode=`
const catalog=${JSON.stringify(eggs)};
let serial=0;
const nextId=()=> 'LAND_'+(++serial);
function part(name,size,pos,color,opt={}) {return createPart(nextId(),name,size,pos,color,opt);}
function model(name,children,props='') {return item('Model',nextId(),name,props,children.join('\\n'));}
const yaw=a=>[Math.cos(a),0,Math.sin(a),0,1,0,-Math.sin(a),0,Math.cos(a)];
const verticalCylinder=[0,-1,0,1,0,0,0,0,1];
function tree(x,z,scale=1,city=false) {
 const c=city?[80,210,240]:[48,117,65];
 const pieces=[part('Trunk',[1.8*scale,10*scale,1.8*scale],[x,5*scale,z],[104,73,49],{shape:2,rotation:verticalCylinder})];
 for(let i=0;i<7;i++) {
  const angle=i*2.4, r=(i%3)*1.5*scale;
  pieces.push(part('Canopy',[7*scale,5.5*scale,6.5*scale],[x+Math.cos(angle)*r,(10+(i%3)*1.4)*scale,z+Math.sin(angle)*r],c.map((v,k)=>Math.min(255,v+(i%3)*9)),{shape:0,material:city?288:256,canCollide:false}));
 }
 for(const side of [-1,1]) pieces.push(part('Branch',[4*scale,0.8*scale,0.8*scale],[x+side*1.5*scale,8*scale,z],[104,73,49],{rotation:yaw(side*0.7)}));
 return model('Tree',pieces);
}
function kiosk(centerX,city) {
 const x=centerX-45,z=145,wood=city?[42,49,74]:[147,103,68],accent=city?[67,221,248]:[111,179,128];
 const out=[part('Deck',[30,0.35,20],[x,0.175,z-5],[192,162,112],{shape:2,rotation:verticalCylinder}),
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
 const pad=part(name,[9,12,1],[x,6,z],accent,{canCollide:false,canTouch:false,properties:'<float name="Transparency">1</float>',children:createLabel(nextId(),textValue,[0,9,0],{width:250,height:60,textSize:17})+'\\n'+createPrompt(nextId(),'EnterWorld','Travel',neon?'Neon District':'Meadow Isles')});
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
 const toNeon=portal('PortalToNeon',0,-185,true,'NEON DISTRICT\\nSPEED 28 · LEVEL 3');island.push(toNeon.art,toNeon.pad);
 for(const [i,name] of ['BoardCoins','BoardEggs','BoardPickups'].entries()) {
  island.push(part(name,[43,18,1.3],[-57+i*57,11,212],[46,66,60]));
  for(const side of [-1,1]) island.push(part('BoardPost',[1.5,22,2],[-57+i*57+side*22,11,212],[137,102,65]));
 }
 const city=zoneParts(500,true);
 const back=portal('PortalToIsland',500,-185,false,'MEADOW ISLES');city.push(back.art,back.pad);
 island.push(model('NeonCity',city));
 return model('CoinSpeedWorld',island);
}

`;
b=b.slice(0,a)+worldCode+b.slice(z);
b=b.replace('const position = [170, 135, 170];','const position = [270, 240, 340];').replace('const target = [90, 0, 0];','const target = [0, 0, 20];');
b=b.replace('"src/StarterPlayer/StarterPlayerScripts/ShopUI.client.luau",','"src/StarterPlayer/StarterPlayerScripts/ShopUI.client.luau",\n  "src/ServerScriptService/WorldProgress.server.luau",');
b=b.replace('const [config, server, hud, effects, petVisuals, shopUI]','const [config, server, hud, effects, petVisuals, shopUI, progress]');
b=b.replace('item("Script", "RBX_GAME_SERVER", "GameServer", server))','item("Script", "RBX_GAME_SERVER", "GameServer", server) + "\\n" + item("Script", "RBX_WORLD_PROGRESS", "WorldProgress", progress))');
b=b.replace("createCamera() + \"\\n\" + createWorld()","createCamera() + \"\\n\" + createWorld() + item('Terrain','RBX_TERRAIN','Terrain','<bool name=\"Decoration\">true</bool><float name=\"GrassLength\">0.45</float>')");
b=b.replace('"CoinSprint_Shops.rbxlx"]','"CoinSprint_Shops.rbxlx", "CoinSprint_Remastered.rbxlx"]');
// Optional sanitized, Studio-exported pet mesh library; never includes executable scripts.
b=b.replace('const services = [',`let petLibrary='';
  const assetPath=resolve(projectRoot,'assets/PetAssets.xml');
  if(existsSync(assetPath)) petLibrary=readFileSync(assetPath,'utf8');
  const services = [`);
b=b.replace('item("ModuleScript", "RBX_PET_VISUALS", "PetVisuals", petVisuals))','item("ModuleScript", "RBX_PET_VISUALS", "PetVisuals", petVisuals) + petLibrary)');
writeFileSync('tools/build-place.mjs',b);
