-- Same profile/session lock as currency: reward and claim timestamp save together.
local RS=game:GetService("ReplicatedStorage")
local D=require(RS:WaitForChild("DailyConfig"))
local remote=Instance.new("RemoteFunction");remote.Name="DailyRewardClaim";remote.Parent=RS
remote.OnServerInvoke=function(p)
 if not p:GetAttribute("ProfileReady") then return {Ok=false,Message="Your profile is loading"} end
 local stats=p:FindFirstChild("leaderstats")
 if not stats then return {Ok=false,Message="Your profile is loading"} end
 local now=os.time()
 local state=D.State(p:GetAttribute("DailyDay"),p:GetAttribute("DailyClaimedAt"),now)
 if not state.Ready then return {Ok=false,Message="Your next reward is available in 24 hours"} end
 -- No yields between eligibility check, timestamp and reward, so parallel claims cannot duplicate it.
 local reward=D.Rewards[state.Day]
 p:SetAttribute("DailyDay",state.Day);p:SetAttribute("DailyClaimedAt",now)
 stats.Coins.Value+=reward.Coins or 0
 for name,count in pairs(reward.Potions or {}) do p:SetAttribute("Potion"..name,(p:GetAttribute("Potion"..name) or 0)+count) end
 return {Ok=true,Day=state.Day,Message="Claimed: "..reward.Name}
end
