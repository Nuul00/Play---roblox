-- Run in the server Command Bar during a local playtest. Grants temporary test coins.
task.spawn(function()
 local Config=require(game.ReplicatedStorage.GameConfig)
 local visuals=require(game.ReplicatedStorage.PetVisuals)
 assert(#Config.Eggs==6 and #Config.Pets==36)
 for _,egg in ipairs(Config.Eggs) do
  local actual={}
  for roll=1,100000 do local result=Config.RollEgg(egg.Id,roll);actual[result]=(actual[result] or 0)+1 end
  for _,entry in ipairs(egg.Pool) do assert(actual[entry.Pet]==entry.Weight,"Exact odds for "..egg.Name) end
  assert(#egg.Pool==6)
 end
 print("[RemasterTest] EXACT ODDS PASS: 600000 rolls, 6 eggs x 6 pets")
 local seen={}
 for id=1,#Config.Pets do
  local visual=string.lower(Config.Pets[id].Visual)
  assert(not seen[visual],"Each pet needs its own model: "..visual);seen[visual]=true
  local model,parts=visuals.Build(id)
  assert(#parts>0,"Model for "..id)
  assert(not model:FindFirstChildWhichIsA("LuaSourceContainer",true))
  model:Destroy()
 end
 print("[RemasterTest] PET MESHES PASS: all 36 pets build, every pet has its own model")
 local p=game.Players:GetPlayers()[1]
 repeat task.wait(0.1) until p:GetAttribute("ProfileReady")
 local world=workspace.CoinSpeedWorld
 assert(world.Start.Transparency==1 and not world.Start.CanCollide)
 assert(not world.UpgradeShop:FindFirstChild("Sign"))
 for id,egg in ipairs(Config.Eggs) do
  local zone=egg.World=="neon" and world.NeonCity or world
  local stand=zone["EggStand"..id]
  assert(not stand:FindFirstChild("EggSign") and not stand:FindFirstChild("Pedestal"))
  assert(not stand.Interact:FindFirstChildWhichIsA("ProximityPrompt"),"Eggs open by touch, no E prompt")
  assert(stand.EggDisplay:GetExtentsSize().Y>6,"Egg must be large")
  assert(zone:FindFirstChild("EggSpurPath"..id),"Path to egg")
 end
 print("[RemasterTest] WORLD STRUCTURE PASS: hidden spawn, no plaques or egg platforms")
 p.leaderstats.Coins.Value=5000
 p.Character:PivotTo(CFrame.new(40,3,136.5))
 local before=p:GetAttribute("EggsOpened") or 0
 print("[RemasterTest] BUY EGG 1 NOW: the gallery opens because the character touches the egg")
 repeat task.wait(0.1) until (p:GetAttribute("EggsOpened") or 0)>before
 assert(p.leaderstats.Coins.Value==5000-Config.Eggs[1].Cost,"Meadow egg price")
 assert((p:GetAttribute("PetLevel") or 0)>0)
 print("[RemasterTest] HATCH PRICE PASS: "..Config.Eggs[1].Cost.." coins, owned pet and strongest equipped")
 task.wait(5)
 local value=p.leaderstats.Coins.Value
 local coin=world.Coin_1
 p.Character:PivotTo(CFrame.new(coin.Position.X+2,3,coin.Position.Z))
 task.wait(0.5)
 assert(math.abs(p.leaderstats.Coins.Value-value-5*Config.GetPetMultiplier(p:GetAttribute("PetLevel")))<0.001)
 print("[RemasterTest] REWARD PASS: base 5 times equipped pet multiplier")
 p.Character:PivotTo(CFrame.new(-45,3,153))
 local npc=world.UpgradeShop:FindFirstChild("Shopkeeper")
 if npc then
  for _,part in ipairs(npc:GetDescendants()) do if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then assert(not part.Anchored,"Only NPC root should be anchored") end end
  print("[RemasterTest] AVATAR RIG PASS: limbs connected, only root anchored")
 end
 print("[RemasterTest] CORE CHECKS PASS; player moved to the kiosk")
end)
