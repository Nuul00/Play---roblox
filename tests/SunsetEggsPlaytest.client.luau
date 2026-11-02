-- Run in the CLIENT command bar during a local Studio playtest.
-- Server preparation: give player 1,000,000 coins, speed level 3+, anchor at EggStand1.
-- Uses real server remotes; tests only the disposable local test session.
task.spawn(function()
 local RS=game.ReplicatedStorage
 local p=game.Players.LocalPlayer
 local C=require(RS.GameConfig)
 local buy=RS.GameShopBuy
 local received
 local connection=RS.GameHatched.OnClientEvent:Connect(function(batch,egg) received={batch=batch,egg=egg} end)
 local function waitFor(fn)
  local deadline=os.clock()+8
  repeat if fn() then return end;task.wait(.05) until os.clock()>deadline
  error("Timed out waiting for server")
 end
 waitFor(function() return p:GetAttribute("ProfileReady") end)
 -- Exact coverage of every integer roll, including each probability boundary.
 for id,egg in ipairs(C.Eggs) do
  local counts={}
  for roll=1,100000 do local pet=C.RollEgg(id,roll);counts[pet]=(counts[pet] or 0)+1 end
  for _,e in ipairs(egg.Pool) do assert(counts[e.Pet]==e.Weight,"Incorrect odds") end
 end
 assert(#C.Eggs[1].Pool==9)
 local rarity={}
 for _,e in ipairs(C.Eggs[1].Pool) do local r=C.Pets[e.Pet].Rarity;rarity[r]=(rarity[r] or 0)+1 end
 assert(rarity.Common==2 and rarity.Uncommon==2 and rarity.Rare==2 and rarity.Epic==1 and rarity.Legendary==2)
 for id=1,#C.Pets do local m=require(RS.PetVisuals).Build(id);assert(m.PrimaryPart);m:Destroy() end
 -- Auto-delete toggle is acknowledged by server and only affects future hatches.
 for _,entry in ipairs(C.Eggs[1].Pool) do
  if not p:GetAttribute("AutoDelete"..entry.Pet) then
   RS.GameAction:FireServer("autodelete",entry.Pet)
   waitFor(function() return p:GetAttribute("AutoDelete"..entry.Pet)==true end);task.wait(.18)
  end
 end
 for id,egg in ipairs(C.Eggs) do
  local world=workspace.CoinSpeedWorld;local zone=egg.World=="neon" and world.NeonCity or world
  p.Character:PivotTo(CFrame.new(zone["EggStand"..id].Interact.Position+Vector3.new(0,0,3)))
  task.wait(.6)
  local before=p.leaderstats.Coins.Value;local opened=p:GetAttribute("EggsOpened") or 0
  local owned={};for _,e in ipairs(egg.Pool) do owned[e.Pet]=p:GetAttribute("PetOwned"..e.Pet) or 0 end
  received=nil;buy:FireServer("egg",egg.World,id,3)
  waitFor(function() return received~=nil end)
  assert(received.egg==id and #received.batch==3,"Triple hatch response")
  waitFor(function() return p:GetAttribute("EggsOpened")==opened+3 end)
  assert(p.leaderstats.Coins.Value==before-egg.Cost*3,"Triple price")
  local expected={}
  for _,r in ipairs(received.batch) do
   assert(C.Pets[r.Pet].EggId==id,"Wrong egg result")
   if id==1 then assert(r.Deleted,"Auto-delete missing") else expected[r.Pet]=(expected[r.Pet] or 0)+1 end
  end
  for pet,count in pairs(owned) do assert(p:GetAttribute("PetOwned"..pet)==count+(expected[pet] or 0),"Inventory count") end
  task.wait(4.3)
  local balance=p.leaderstats.Coins.Value;local total=p:GetAttribute("EggsOpened")
  received=nil;buy:FireServer("egg",egg.World,id,2);task.wait(.5)
  assert(not received and p.leaderstats.Coins.Value==balance and p:GetAttribute("EggsOpened")==total,"Invalid amount accepted")
  print("[SunsetTests] PASS egg",id,"triple price, independent results, inventory, invalid amount")
 end
 connection:Disconnect()
 print("[SunsetTests] ALL PASS: all 600000 rolls; 39 models; 6 triple hatches; auto-delete; input validation")
end)
