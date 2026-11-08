import {readFileSync,writeFileSync} from 'node:fs';
let b=readFileSync('tools/build-place.mjs','utf8');
b=b.replace("[30,0.35,20],[x,0.175,z-5]","[0.35,30,20],[x,0.175,z-5]").replace("[1.8*scale,10*scale,1.8*scale]","[10*scale,1.8*scale,1.8*scale]");
writeFileSync('tools/build-place.mjs',b);
let s=readFileSync('src/ServerScriptService/GameServer.server.luau','utf8');
s=s.replace('player:SetAttribute("CurrentWorld", "Зелёный остров")','player:SetAttribute("CurrentWorld", "Meadow Isles")').replaceAll('"Зелёный остров"','"Meadow Isles"').replaceAll('"Неонград"','"Neon District"');
s=s.replace('player:SetAttribute("IncomeLevel", 0)','player:SetAttribute("IncomeLevel", 0)\n player:SetAttribute("LifetimeEarned", 0)\n player:SetAttribute("CoinsCollected", 0)\n player:SetAttribute("EggsOpened", 0)');
s=s.replace('local function shopPart(zone, mode)\n if mode == "egg" then return zone.EggStand.Interact, zone.EggStand.Interact.OpenEggMenu end','local function shopPart(zone, mode, eggId)\n if mode == "egg" then\n  local egg=Config.Eggs[eggId]\n  if not egg or (egg.World=="neon")~=(zone==city) then return end\n  local stand=zone:FindFirstChild("EggStand"..eggId)\n  if not stand then return end\n  return stand.Interact,stand.Interact.OpenEggMenu\n end');
const loopA=s.indexOf('for id, zone in pairs(zones) do'),loopB=s.indexOf('buy.OnServerEvent:Connect',loopA);
s=s.slice(0,loopA)+`for id,zone in pairs(zones) do
 local part,prompt=shopPart(zone,"upgrades")
 prompt.Triggered:Connect(function(p)
  if interact(p,part,prompt,zone==city) then openMenu:FireClient(p,"upgrades",id) end
 end)
 for eggId,egg in ipairs(Config.Eggs) do
  if egg.World==id then
   local eggPart,eggPrompt=shopPart(zone,"egg",eggId)
   eggPrompt.Triggered:Connect(function(p)
    if interact(p,eggPart,eggPrompt,zone==city) then openMenu:FireClient(p,"egg",id,eggId) end
   end)
  end
 end
end
`+s.slice(loopB);
s=s.replace('function(p, kind, zoneId)','function(p, kind, zoneId, eggId)');
s=s.replace('local part, prompt = shopPart(zone, kind == "egg" and "egg" or "upgrades")','if kind=="egg" and (type(eggId)~="number" or eggId~=math.floor(eggId)) then return end\n local part, prompt = shopPart(zone, kind == "egg" and "egg" or "upgrades",eggId)\n if not part then return end');
s=s.replace('cost = Config.EggCost','cost = Config.Eggs[eggId].Cost');
const rollA=s.indexOf('  local roll, cumulative, result'),rollB=s.indexOf('  local attribute =',rollA);
s=s.slice(0,rollA)+'  local result=Config.RollEgg(eggId,random:NextInteger(1,100000))\n'+s.slice(rollB);
s=s.replace('if result > (p:GetAttribute("PetLevel") or 0) then p:SetAttribute("PetLevel",result) end','if Config.GetPetMultiplier(result)>Config.GetPetMultiplier(p:GetAttribute("PetLevel") or 0) then p:SetAttribute("PetLevel",result) end\n  p:SetAttribute("EggsOpened",(p:GetAttribute("EggsOpened") or 0)+1)');
s=s.replace('hatched:FireClient(p,result,count)','hatched:FireClient(p,result,count,eggId)');
const anchorA=s.indexOf('  for _, part in ipairs(npc:GetDescendants())'),anchorB=s.indexOf('  local placeholder',anchorA);
s=s.slice(0,anchorA)+`  local root=npc:FindFirstChild("HumanoidRootPart")
  for _,part in ipairs(npc:GetDescendants()) do
   if part:IsA("BasePart") then
    part.Anchored=part==root;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
   end
  end
  local humanoid=npc:FindFirstChildOfClass("Humanoid")
  if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;humanoid.AutoRotate=false end
  npc.Parent=shop
  local anchor=shop.VendorAnchor.Position
  npc:PivotTo(CFrame.new(anchor.X,anchor.Y+3,anchor.Z)*CFrame.Angles(0,math.pi,0))
  game:GetService("RunService").Heartbeat:Wait()
  local lowest=math.huge
  for _,name in ipairs({"LeftFoot","RightFoot","Left Leg","Right Leg"}) do
   local foot=npc:FindFirstChild(name)
   if foot then lowest=math.min(lowest,foot.Position.Y-foot.Size.Y/2) end
  end
  if lowest<math.huge then npc:PivotTo(npc:GetPivot()+Vector3.new(0,anchor.Y-lowest,0)) end
`+s.slice(anchorB);
s=s.replace('Vector3.new(180, 3, 30)','Vector3.new(500, 3, 180)').replace('Vector3.new(0, 3, 30)','Vector3.new(0, 3, 180)');
s=s.replace('Нужна скорость 28: купи 3 улучшения скорости.','Requires speed 28 · buy 3 speed upgrades.');
s=s.replace('value = zone == city and 10 or 5','value = zone == city and 25 or 5');
const earn='stats.Coins.Value = stats.Coins.Value + record.value * Config.GetPetMultiplier(p:GetAttribute("PetLevel") or 0) * Config.GetIncomeMultiplier(p:GetAttribute("IncomeLevel") or 0)';
s=s.replace(earn,`local earned=record.value*Config.GetPetMultiplier(p:GetAttribute("PetLevel") or 0)*Config.GetIncomeMultiplier(p:GetAttribute("IncomeLevel") or 0)
 stats.Coins.Value=stats.Coins.Value+earned
 p:SetAttribute("LifetimeEarned",(p:GetAttribute("LifetimeEarned") or 0)+earned)
 p:SetAttribute("CoinsCollected",(p:GetAttribute("CoinsCollected") or 0)+1)`);
s=s.replace('if math.abs(root.Position.Z) <= 50 then','if math.abs(root.Position.Z) <= 230 then').replace('math.abs(root.Position.X) <= 50','math.abs(root.Position.X) <= 150').replace('math.abs(root.Position.X - 180) <= 50','math.abs(root.Position.X - 500) <= 150');
s=s.replace('part:WaitForChild("EnterWorld")','part:WaitForChild("EnterWorld")');
// Local terrain is part of the game environment; Decoration is baked in the place XML.
s=s.replace('local city = world:WaitForChild("NeonCity")',`local city = world:WaitForChild("NeonCity")
workspace.GlobalWind=Vector3.new(8,0,3)
workspace.Terrain:FillBlock(CFrame.new(0,-6,0),Vector3.new(300,12,460),Enum.Material.Grass)
workspace.Terrain:FillBlock(CFrame.new(-95,-2,-30),Vector3.new(48,4,56),Enum.Material.Water)`);
// English feedback strings; no floating plaques or static billboard spam.
const translations={'Скорость уже максимальная!':'Speed is maxed!','Магнит уже максимальный!':'Magnet is maxed!','Доход уже максимальный!':'Income is maxed!','Не хватает монет! Нужно ещё ':'Not enough coins. Need ','Скорость: ':'Speed: ','Радиус магнита: ':'Magnet radius: ','Доход: x':'Income: x','Мир: ':'World: '};
for(const [from,to] of Object.entries(translations))s=s.replaceAll(from,to);
writeFileSync('src/ServerScriptService/GameServer.server.luau',s);
let fx=readFileSync('src/StarterPlayer/StarterPlayerScripts/GameEffects.client.luau','utf8');
fx=fx.replace('local segmentCount = 48','local segmentCount = 24').replace('Vector3.new(0.1, 0.07, chord)','Vector3.new(0.045, 0.03, chord)').replace('visible and 0.25 or 1','visible and 0.86 or 1');
fx=fx.replace('local radius = Config.GetMagnetRadius(getMagnetLevel())','if not localPlayer:GetAttribute("ShowMagnetRange") then setRingVisible(false); return end\n\tlocal radius = Config.GetMagnetRadius(getMagnetLevel())');
// Show a base-value label only when physically close to a coin.
fx+=`\nlocal nearbyCoins={}
local rootWorld=Workspace:WaitForChild("CoinSpeedWorld")
for _,zone in ipairs({rootWorld,rootWorld:WaitForChild("NeonCity")}) do
 for _,coin in ipairs(zone:GetChildren()) do
  if coin:IsA("BasePart") and string.match(coin.Name,"^Coin_%d+$") then table.insert(nearbyCoins,coin) end
 end
end
task.spawn(function()
 while effectsFolder.Parent do
  local root=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
  for _,coin in ipairs(nearbyCoins) do
   local label=coin:FindFirstChild("GameLabel")
   if label then label.Enabled=root~=nil and coin:GetAttribute("Available")~=false and (root.Position-coin.Position).Magnitude<12 end
  end
  task.wait(0.12)
 end
end)
`;
writeFileSync('src/StarterPlayer/StarterPlayerScripts/GameEffects.client.luau',fx);
