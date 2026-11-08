-- Disposable local Studio playtest. Prepare a funded player with SpeedLevel >= 3.
-- Run on the client; published profiles must not be used for this test.
task.spawn(function()
 local RS=game.ReplicatedStorage
 local C=require(RS.GameConfig)
 local P=require(RS.PetVisuals)
 local player=game.Players.LocalPlayer
 local function awaitCondition(fn)
  local deadline=os.clock()+10
  repeat if fn() then return end;task.wait(.05) until os.clock()>deadline
  error("Server response timed out")
 end
 awaitCondition(function() return player:GetAttribute("ProfileReady") end)
 assert(#C.Pets==57)
 local seen={}
 for id,egg in ipairs(C.Eggs) do
  assert(#egg.Pool==9)
  local counts={}
  for roll=1,100000 do local pet=C.RollEgg(id,roll);counts[pet]=(counts[pet] or 0)+1 end
  for _,entry in ipairs(egg.Pool) do
   assert(not seen[entry.Pet],"Repeated pet across eggs");seen[entry.Pet]=true
   assert(counts[entry.Pet]==entry.Weight and entry.Weight==entry.Chance*1000)
   assert(C.Pets[entry.Pet].EggId==id)
   local model,parts=P.Build(entry.Pet)
   assert(model.PrimaryPart and #parts>0)
   local _,size=model:GetBoundingBox()
   assert(math.max(size.X,size.Y,size.Z)<3.6,"Model doesn't fit viewport")
   for _,item in ipairs(model:GetDescendants()) do
    assert(not item:IsA("LuaSourceContainer"),"Script in pet")
    if item:IsA("BasePart") then assert(item.Anchored and not item.CanCollide) end
   end
   model:Destroy()
  end
 end
 print("[NeonTests] PASS: 600000 rolls, 57 unique pets, model bounds and safety")
 local received
 local conn=RS.GameHatched.OnClientEvent:Connect(function(batch,id) received={batch=batch,id=id} end)
 for id=4,6 do
  local egg=C.Eggs[id]
  for _,entry in ipairs(egg.Pool) do
   if not player:GetAttribute("AutoDelete"..entry.Pet) then
    RS.GameAction:FireServer("autodelete",entry.Pet)
    awaitCondition(function() return player:GetAttribute("AutoDelete"..entry.Pet)==true end);task.wait(.18)
   end
  end
  local stand=workspace.CoinSpeedWorld.NeonCity["EggStand"..id]
  player.Character:PivotTo(CFrame.new(stand.Interact.Position+Vector3.new(0,0,4)))
  task.wait(.7)
  for _,amount in ipairs({1,3}) do
   local coins=player.leaderstats.Coins.Value
   local total=player:GetAttribute("EggsOpened") or 0
   local owned={};for _,entry in ipairs(egg.Pool) do owned[entry.Pet]=player:GetAttribute("PetOwned"..entry.Pet) or 0 end
   received=nil;RS.GameShopBuy:FireServer("egg","neon",id,amount)
   awaitCondition(function() return received~=nil end)
   awaitCondition(function() return player:GetAttribute("EggsOpened")==total+amount end)
   assert(received.id==id and #received.batch==amount)
   assert(player.leaderstats.Coins.Value==coins-egg.Cost*amount,"Wrong price")
   for _,r in ipairs(received.batch) do assert(r.Deleted and owned[r.Pet]~=nil) end
   for pet,count in pairs(owned) do assert(player:GetAttribute("PetOwned"..pet)==count,"Auto-delete changed inventory") end
   task.wait(4.5)
  end
  -- Switch deletion off through the same public UI action, then verify kept duplicates.
  for _,entry in ipairs(egg.Pool) do
   RS.GameAction:FireServer("autodelete",entry.Pet)
   awaitCondition(function() return player:GetAttribute("AutoDelete"..entry.Pet)==false end);task.wait(.18)
  end
  local before={};for _,e in ipairs(egg.Pool) do before[e.Pet]=player:GetAttribute("PetOwned"..e.Pet) or 0 end
  received=nil;RS.GameShopBuy:FireServer("egg","neon",id,3)
  awaitCondition(function() return received~=nil end)
  local kept={}
  for _,r in ipairs(received.batch) do assert(not r.Deleted);kept[r.Pet]=(kept[r.Pet] or 0)+1 end
  awaitCondition(function()
   for pet,count in pairs(before) do if player:GetAttribute("PetOwned"..pet)~=count+(kept[pet] or 0) then return false end end
   return true
  end)
  task.wait(4.5)
  local balance=player.leaderstats.Coins.Value
  received=nil;RS.GameShopBuy:FireServer("egg","neon",id,2);task.wait(.6)
  assert(not received and player.leaderstats.Coins.Value==balance)
  print("[NeonTests] PASS egg",id,"single, triple, delete ON/OFF, counts, invalid request")
 end
 conn:Disconnect()
 print("[NeonTests] ALL PASS")
end)
