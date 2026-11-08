-- Local Studio only; DailyTestPrepare is created temporarily by the test runner.
task.spawn(function()
 local RS=game.ReplicatedStorage
 local D=require(RS.DailyConfig)
 local p=game.Players.LocalPlayer
 for day=0,7 do
  local state=D.State(day,100000,100000+D.Interval-1)
  assert(not state.Ready and state.Remaining==1)
  assert(D.State(day,100000,100000+D.Interval).Ready)
  assert(state.Day==day%7+1)
 end
 assert(D.State(nil,nil,os.time()).Ready)
 for day,reward in ipairs(D.Rewards) do
  assert(RS.DailyTestPrepare:InvokeServer(day))
  task.wait(.1)
  local coins=p.leaderstats.Coins.Value
  local potions={};for _,n in ipairs({"Coins","Speed","Luck"}) do potions[n]=p:GetAttribute("Potion"..n) or 0 end
  local result=RS.DailyRewardClaim:InvokeServer(7) -- Client arguments cannot choose the reward.
  assert(result.Ok and result.Day==day)
  task.wait(.1)
  assert(p.leaderstats.Coins.Value==coins+(reward.Coins or 0))
  for n,count in pairs(potions) do assert(p:GetAttribute("Potion"..n)==count+((reward.Potions or {})[n] or 0)) end
  for _=1,4 do assert(not RS.DailyRewardClaim:InvokeServer().Ok) end
  task.wait(.1)
  assert(p.leaderstats.Coins.Value==coins+(reward.Coins or 0))
  for n,count in pairs(potions) do assert(p:GetAttribute("Potion"..n)==count+((reward.Potions or {})[n] or 0)) end
 end
 print("[DailyTests] ALL PASS: seven rewards, coins/potions, duplicate rejection, 24h boundary and cycle")
 p:SetAttribute("UIScreen","")
 local gate=workspace.CoinSpeedWorld.PortalToNeon
 workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
 workspace.CurrentCamera.CFrame=CFrame.lookAt(gate.Position+Vector3.new(15,6,28),gate.Position+Vector3.new(0,3,0))
end)
