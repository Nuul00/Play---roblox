-- Same profile/session lock as currency: reward and claim timestamp save together.
local RS=game:GetService("ReplicatedStorage")
local D=require(RS:WaitForChild("DailyConfig"))
local remote=Instance.new("RemoteFunction");remote.Name="DailyRewardClaim";remote.Parent=RS
local lastClaim={}
game:GetService("Players").PlayerRemoving:Connect(function(p) lastClaim[p]=nil end)
remote.OnServerInvoke=function(p)
 if os.clock()-(lastClaim[p] or -1e9)<0.5 then return {Ok=false,Message="Please wait"} end
 lastClaim[p]=os.clock()
 if not p:GetAttribute("ProfileReady") then return {Ok=false,Message="Your profile is loading"} end
 local stats=p:FindFirstChild("leaderstats")
 if not stats then return {Ok=false,Message="Your profile is loading"} end
 local now=os.time()
 local state=D.State(p:GetAttribute("DailyDay"),p:GetAttribute("DailyClaimedAt"),now)
 if not state.Ready then return {Ok=false,Message="Your next reward is available tomorrow"} end
 -- No yields between eligibility check, timestamp and reward, so parallel claims cannot duplicate it.
 local reward=D.RewardFor(state.Day,p:GetAttribute(D.WeekAttr))
 p:SetAttribute("DailyDay",state.Day);p:SetAttribute("DailyClaimedAt",now)
 -- джекпот 7-го дня закрывает неделю: следующая будет щедрее (DailyConfig.RewardFor)
 if state.Day==#D.Rewards then p:SetAttribute(D.WeekAttr,(tonumber(p:GetAttribute(D.WeekAttr)) or 0)+1) end
 stats.Coins.Value+=D.CoinsFor(reward,p:GetAttribute("LifetimeEarned"),p:GetAttribute("Rebirths") or 0)
 for name,count in pairs(reward.Potions or {}) do p:SetAttribute("Potion"..name,(p:GetAttribute("Potion"..name) or 0)+count) end
 if reward.RushKeys then p:SetAttribute("Save_RushKeys",(p:GetAttribute("Save_RushKeys") or 0)+reward.RushKeys) end
 -- 7-й день: бесплатное яйцо (двойная удача) из лучшего открытого мира — через QuestLine (FreeHatch)
 if reward.FreeHatch then
  task.spawn(function()
   local sig=game:GetService("ServerStorage"):FindFirstChild("ServerSignals")
   local fh=sig and sig:FindFirstChild("FreeHatch")
   if fh then pcall(fh.Invoke,fh,p,nil,reward.FreeHatch==true and 1 or reward.FreeHatch,true) end
  end)
 end
 return {Ok=true,Day=state.Day,Message="Claimed: "..reward.Name}
end
