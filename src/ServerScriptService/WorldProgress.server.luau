-- Published games save profiles and global top-100. Local Studio uses server rankings.
local Players=game:GetService("Players")
local DS=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage:WaitForChild("GameConfig"))
local world=workspace:WaitForChild("CoinSpeedWorld")
local persistent=game.GameId>0 and (not RunService:IsStudio() or Config.EnableStudioDataStores)
local store=persistent and DS:GetDataStore("CoinSprint_Profiles_V3")
local sessions={}
local token=game.JobId~="" and game.JobId or game:GetService("HttpService"):GenerateGUID(false)
local function number(v) return type(v)=="number" and v==v and math.abs(v)<1e15 and math.max(0,v) or 0 end
local function snapshot(p)
 local data={Coins=p.leaderstats.Coins.Value,Speed=p.leaderstats.SpeedLevel.Value,Owned={}}
 for _,name in ipairs({"MagnetLevel","IncomeLevel","PetLevel","LifetimeEarned","CoinsCollected","EggsOpened"}) do data[name]=p:GetAttribute(name) or 0 end
 for i=1,#Config.Pets do data.Owned[tostring(i)]=p:GetAttribute("PetOwned"..i) or 0 end
 return data
end
local function load(p)
 local stats=p:WaitForChild("leaderstats",20)
 if not stats then return end
 if not persistent then p:SetAttribute("ProfileReady",true);p:SetAttribute("SaveStatus","SESSION ONLY");return end
 local loaded
 for attempt=1,4 do
  local ok,data=pcall(function()
   return store:UpdateAsync(tostring(p.UserId),function(old)
    old=type(old)=="table" and old or {}
    if old.Session and old.Session~=token and os.time()-(old.Lease or 0)<180 then return nil end
    old.Session=token;old.Lease=os.time();return old
   end)
  end)
  if ok and data and data.Session==token then loaded=data;break end
  task.wait(attempt*2)
 end
 if not loaded then p:Kick("Your profile is unavailable or still open on another server. Please rejoin shortly.");return end
 sessions[p]={busy=false,release=false}
 stats.Coins.Value=number(loaded.Coins)
 stats.SpeedLevel.Value=math.clamp(math.floor(number(loaded.Speed)),0,Config.MaxSpeedLevel)
 p:SetAttribute("MagnetLevel",math.clamp(math.floor(number(loaded.MagnetLevel)),0,Config.MaxMagnetLevel))
 p:SetAttribute("IncomeLevel",math.clamp(math.floor(number(loaded.IncomeLevel)),0,Config.MaxIncomeLevel))
 for _,name in ipairs({"LifetimeEarned","CoinsCollected","EggsOpened"}) do p:SetAttribute(name,number(loaded[name])) end
 local best=0
 for i=1,#Config.Pets do
  local count=math.floor(number(type(loaded.Owned)=="table" and loaded.Owned[tostring(i)]))
  p:SetAttribute("PetOwned"..i,count)
  if count>0 and Config.GetPetMultiplier(i)>Config.GetPetMultiplier(best) then best=i end
 end
 p:SetAttribute("PetLevel",best)
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if h then h.WalkSpeed=Config.GetWalkSpeed(stats.SpeedLevel.Value) end
 p:SetAttribute("ProfileReady",true);p:SetAttribute("SaveStatus","SAVING ENABLED")
end
local function save(p,release)
 local session=sessions[p]
 if not session then return end
 session.release=session.release or release
 if session.busy then if not release then return end;repeat task.wait(0.1) until not session.busy end
 session.busy=true
 local data=snapshot(p)
 if session.release then data.Session=nil else data.Session=token end
 data.Lease=os.time()
 local ok,err=pcall(function()
  store:UpdateAsync(tostring(p.UserId),function(old)
   if type(old)~="table" or old.Session~=token then return nil end
   return data
  end)
 end)
 session.busy=false
 if not ok then warn("[Profiles] Save failed: "..tostring(err));p:SetAttribute("SaveStatus","SAVE RETRY PENDING") end
 if session.release and ok then sessions[p]=nil end
end
Players.PlayerAdded:Connect(function(p) task.spawn(load,p) end)
Players.PlayerRemoving:Connect(function(p) save(p,true) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(load,p) end
task.spawn(function() while true do task.wait(60);for p in pairs(sessions) do task.spawn(save,p,false) end end end)
game:BindToClose(function()
 if not persistent then return end
 for p in pairs(sessions) do task.spawn(save,p,true) end
 local deadline=os.clock()+25
 while next(sessions) and os.clock()<deadline do task.wait(0.2) end
end)
local defs={{Part="BoardCoins",Title="TOP 100 · COINS",Stat="LifetimeEarned",Scale=100},{Part="BoardEggs",Title="TOP 100 · EGGS",Stat="EggsOpened",Scale=1},{Part="BoardPickups",Title="TOP 100 · PICKUPS",Stat="CoinsCollected",Scale=1}}
local names={}
local function label(parent,text,pos,size,fontSize,color)
 local x=Instance.new("TextLabel")
 x.BackgroundTransparency=1;x.Position=pos;x.Size=size;x.Text=text
 x.Font=Enum.Font.GothamBold;x.TextSize=fontSize;x.TextColor3=color or Color3.fromRGB(239,245,232);x.Parent=parent;return x
end
for _,def in ipairs(defs) do
 local gui=Instance.new("SurfaceGui")
 gui.Name="Rankings";gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(860,360);gui.MaxDistance=130;gui.Active=true;gui.Parent=world:WaitForChild(def.Part)
 label(gui,def.Title,UDim2.fromOffset(0,8),UDim2.fromOffset(860,45),32,Color3.fromRGB(255,220,133))
 def.subtitle=label(gui,persistent and "GLOBAL · refreshes every 120s" or "THIS SERVER · publish for global rankings",UDim2.fromOffset(0,55),UDim2.fromOffset(860,30),18)
 local list=Instance.new("ScrollingFrame")
 list.Position=UDim2.fromOffset(25,95);list.Size=UDim2.fromOffset(810,250);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=8;list.Parent=gui;def.list=list
 if persistent then def.store=DS:GetOrderedDataStore("CoinSprint_TopV3_"..def.Stat) end
end
local function render(def,rows)
 def.list:ClearAllChildren();def.list.CanvasSize=UDim2.fromOffset(0,math.max(250,#rows*32))
 if #rows==0 then label(def.list,"Be the first on this board!",UDim2.fromOffset(0,50),UDim2.fromOffset(780,40),23);return end
 for i,row in ipairs(rows) do
  label(def.list,string.format("#%d   %s",i,row.Name),UDim2.fromOffset(8,(i-1)*32),UDim2.fromOffset(560,30),21).TextXAlignment=Enum.TextXAlignment.Left
  label(def.list,string.format("%g",row.Value),UDim2.fromOffset(570,(i-1)*32),UDim2.fromOffset(200,30),21).TextXAlignment=Enum.TextXAlignment.Right
 end
end
local function refresh()
 for _,def in ipairs(defs) do
  local rows={}
  for _,p in ipairs(Players:GetPlayers()) do
   table.insert(rows,{Name=p.DisplayName,Value=p:GetAttribute(def.Stat) or 0})
   if def.store and p:GetAttribute("ProfileReady") then pcall(function() def.store:UpdateAsync(tostring(p.UserId),function(old) return math.max(old or 0,math.floor((p:GetAttribute(def.Stat) or 0)*def.Scale)) end) end) end
  end
  table.sort(rows,function(a,b) return a.Value>b.Value end)
  if def.store then
   local ok,pages=pcall(function() return def.store:GetSortedAsync(false,100) end)
   if ok then
    rows={}
    for _,entry in ipairs(pages:GetCurrentPage()) do
     local id=tonumber(entry.key)
     local name=names[id]
     if not name then local success,result=pcall(function() return Players:GetNameFromUserIdAsync(id) end);name=success and result or ("User "..entry.key);names[id]=name end
     table.insert(rows,{Name=name,Value=entry.value/def.Scale})
    end
    def.subtitle.Text="GLOBAL · refreshes every 120s"
   else def.subtitle.Text="THIS SERVER · global service unavailable" end
  end
  render(def,rows)
 end
end
task.spawn(function() while true do refresh();task.wait(persistent and 120 or 8) end end)
