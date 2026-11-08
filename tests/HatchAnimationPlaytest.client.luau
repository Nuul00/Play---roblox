-- Run only in a disposable Studio session with a funded player.
task.spawn(function()
 local RS=game.ReplicatedStorage
 local p=game.Players.LocalPlayer
 local C=require(RS.GameConfig)
 local received
 local connection=RS.GameHatched.OnClientEvent:Connect(function(batch,id) received={batch=batch,id=id} end)
 for id,egg in ipairs(C.Eggs) do
  local zone=egg.World=="neon" and workspace.CoinSpeedWorld.NeonCity or workspace.CoinSpeedWorld
  local stand=zone["EggStand"..id]
  p.Character:PivotTo(CFrame.new(stand.Interact.Position+Vector3.new(0,0,4)))
  task.wait(.7)
  for _,amount in ipairs({1,3}) do
   received=nil
   local count=p:GetAttribute("EggsOpened") or 0
   RS.GameShopBuy:FireServer("egg",egg.World,id,amount)
   local deadline=os.clock()+5
   repeat task.wait(.02) until received or os.clock()>deadline
   assert(received and received.id==id and #received.batch==amount,"Missing hatch response")
   task.wait(.4)
   assert(p:GetAttribute("UIScreen")=="hatch","Animation failed to open")
   local function modelCount()
    local n=0
    for _,v in ipairs(p.PlayerGui:GetDescendants()) do
     if v:IsA("ViewportFrame") and v.Visible and v:FindFirstChildOfClass("WorldModel") then
      local wm=v:FindFirstChildOfClass("WorldModel")
      if #wm:GetChildren()>0 then n+=1 end
     end
    end
    return n
   end
   assert(modelCount()>=amount,"Missing egg models")
   task.wait(2)
   assert(modelCount()>=amount,"Missing revealed pets")
   assert(p:GetAttribute("EggsOpened")==count+amount,"Incorrect hatch count")
   task.wait(2)
   assert(p:GetAttribute("UIScreen")~="hatch","Animation failed to finish")
   print("[HatchAnimation] PASS",id,amount)
  end
 end
 connection:Disconnect()
 print("[HatchAnimation] ALL PASS")
end)
