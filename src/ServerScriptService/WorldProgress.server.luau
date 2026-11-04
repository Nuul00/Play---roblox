-- Published games save profiles and global top-100. Local Studio uses server rankings.
local Players=game:GetService("Players")
local DS=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig=require(game.ReplicatedStorage:WaitForChild("ShopConfig"))
local PlayerSystems=require(script.Parent:WaitForChild("PlayerSystems"))
local BADGES={}
for _,b in ipairs(ShopConfig.Badges) do table.insert(BADGES,b.Id) end
local world=workspace:WaitForChild("CoinSpeedWorld")
local persistent=game.GameId>0 and (not RunService:IsStudio() or Config.EnableStudioDataStores)
local store=persistent and DS:GetDataStore("CoinSprint_Profiles_V3")
local sessions={}
local token=game.JobId~="" and game.JobId or game:GetService("HttpService"):GenerateGUID(false)
local function number(v) return type(v)=="number" and v==v and math.abs(v)<1e15 and math.max(0,v) or 0 end
local function snapshot(p)
 local data={Coins=p.leaderstats.Coins.Value,Speed=p.leaderstats.SpeedLevel.Value,Owned={},AutoDelete={}}
 data.DailyDay=p:GetAttribute("DailyDay") or 0
 data.DailyClaimedAt=p:GetAttribute("DailyClaimedAt") or 0
 data.QuestState=p:GetAttribute("QuestState") or ""
 for i=1,#Config.Pets do data.AutoDelete[tostring(i)]=p:GetAttribute("AutoDelete"..i)==true end
 for _,name in ipairs({"MagnetLevel","IncomeLevel","DoubleLevel","Rebirths","PetLevel","LifetimeEarned","CoinsCollected","EggsOpened"}) do data[name]=p:GetAttribute(name) or 0 end
 for i=1,#Config.Pets do data.Owned[tostring(i)]=p:GetAttribute("PetOwned"..i) or 0 end
 data.Equipped=p:GetAttribute("Equipped") or ""
 data.Potions={};data.PotionLeft={}
 for _,name in ipairs({"Coins","Speed","Luck"}) do
  data.Potions[name]=p:GetAttribute("Potion"..name) or 0
  data.PotionLeft[name]=math.max(0,(p:GetAttribute("PotionEnd"..name) or 0)-os.time())
 end
 data.Badges={}
 for _,name in ipairs(BADGES) do data.Badges[name]=p:GetAttribute("Badge"..name)==true end
 data.MagnetTier=p:GetAttribute("MagnetTier") or 1
 data.MagnetEquipped=p:GetAttribute("MagnetEquipped") or 1
 data.IndexClaimed={}
 for i=1,#Config.Eggs do data.IndexClaimed[tostring(i)]=p:GetAttribute("IndexClaimed"..i)==true end
 data.Variants={}
 for _,v in ipairs(ShopConfig.Variants) do
  local t={}
  for i=1,#Config.Pets do local n=p:GetAttribute("Pet"..v.Key..i) or 0; if n>0 then t[tostring(i)]=n end end
  data.Variants[v.Key]=t
 end
 data.Pity={}
 for _,tier in ipairs(ShopConfig.Pity) do data.Pity[tier.Rarity]=p:GetAttribute("Pity"..tier.Rarity) or 0 end
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
 p:SetAttribute("DailyDay",math.clamp(math.floor(number(loaded.DailyDay)),0,7))
 p:SetAttribute("DailyClaimedAt",math.floor(number(loaded.DailyClaimedAt)))
 p:SetAttribute("QuestState",type(loaded.QuestState)=="string" and loaded.QuestState or "")
 stats.SpeedLevel.Value=math.clamp(math.floor(number(loaded.Speed)),0,Config.MaxSpeedLevel)
 p:SetAttribute("MagnetLevel",math.clamp(math.floor(number(loaded.MagnetLevel)),0,Config.MaxMagnetLevel))
 p:SetAttribute("IncomeLevel",math.clamp(math.floor(number(loaded.IncomeLevel)),0,Config.MaxIncomeLevel))
 p:SetAttribute("DoubleLevel",math.clamp(math.floor(number(loaded.DoubleLevel)),0,Config.MaxDoubleLevel))
 p:SetAttribute("Rebirths",math.clamp(math.floor(number(loaded.Rebirths)),0,Config.MaxRebirths))
 for _,name in ipairs({"LifetimeEarned","CoinsCollected","EggsOpened"}) do p:SetAttribute(name,number(loaded[name])) end
 -- Улучшенные питомцы (золото/алмаз/радуга) грузим до команды, чтобы их можно было надеть.
 for _,v in ipairs(ShopConfig.Variants) do
  local t=type(loaded.Variants)=="table" and type(loaded.Variants[v.Key])=="table" and loaded.Variants[v.Key] or {}
  for i=1,#Config.Pets do p:SetAttribute("Pet"..v.Key..i,math.floor(number(t[tostring(i)]))) end
 end
 local best=0
 for i=1,#Config.Pets do
  p:SetAttribute("AutoDelete"..i,type(loaded.AutoDelete)=="table" and loaded.AutoDelete[tostring(i)]==true)
  local count=math.floor(number(type(loaded.Owned)=="table" and loaded.Owned[tostring(i)]))
  p:SetAttribute("PetOwned"..i,count)
  if count>0 and Config.GetPetMultiplier(i)>Config.GetPetMultiplier(best) then best=i end
 end
 p:SetAttribute("PetLevel",best)
 if type(loaded.Potions)=="table" then
  for _,name in ipairs({"Coins","Speed","Luck"}) do
   p:SetAttribute("Potion"..name,math.floor(number(loaded.Potions[name])))
   p:SetAttribute("PotionEnd"..name,os.time()+math.floor(number(type(loaded.PotionLeft)=="table" and loaded.PotionLeft[name])))
  end
 end
 if type(loaded.Badges)=="table" then for _,name in ipairs(BADGES) do p:SetAttribute("Badge"..name,loaded.Badges[name]==true) end end
 p:SetAttribute("MagnetTier",math.clamp(math.floor(number(loaded.MagnetTier)),1,#ShopConfig.Magnets))
 p:SetAttribute("MagnetEquipped",math.clamp(math.floor(number(loaded.MagnetEquipped)),1,p:GetAttribute("MagnetTier")))
 -- Команда питомцев; у старых профилей её нет — надеваем трёх лучших.
 local team=ShopConfig.ParseEquipped(type(loaded.Equipped)=="string" and loaded.Equipped or "")
 if #team>0 then PlayerSystems.SetEquipped(p,team) else PlayerSystems.EquipBest(p) end
 PlayerSystems.GiveMagnet(p)
 for i=1,#Config.Eggs do p:SetAttribute("IndexClaimed"..i,type(loaded.IndexClaimed)=="table" and loaded.IndexClaimed[tostring(i)]==true) end
 PlayerSystems.RefreshIndexBonus(p)
 for _,tier in ipairs(ShopConfig.Pity) do
  p:SetAttribute("Pity"..tier.Rarity,math.clamp(math.floor(number(type(loaded.Pity)=="table" and loaded.Pity[tier.Rarity])),0,tier.Threshold))
 end
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
-- Доски есть в обоих мирах: одинаковые таблицы рисуются на каждой найденной доске.
local city=world:WaitForChild("NeonCity")
for _,def in ipairs(defs) do
 def.lists={};def.subtitles={}
 for _,zone in ipairs({world,city}) do
  local board=zone:FindFirstChild(def.Part)
  if board then
   local neon=zone==city
   local gui=Instance.new("SurfaceGui")
   gui.Name="Rankings";gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(860,360);gui.MaxDistance=130;gui.Active=true;gui.Parent=board
   if neon then gui.LightInfluence=0 end
   label(gui,def.Title,UDim2.fromOffset(0,8),UDim2.fromOffset(860,45),32,neon and Color3.fromRGB(255,120,230) or Color3.fromRGB(255,220,133))
   table.insert(def.subtitles,label(gui,persistent and "GLOBAL · refreshes every 120s" or "THIS SERVER · publish for global rankings",UDim2.fromOffset(0,55),UDim2.fromOffset(860,30),18,neon and Color3.fromRGB(120,235,255) or nil))
   local list=Instance.new("ScrollingFrame")
   list.Position=UDim2.fromOffset(25,95);list.Size=UDim2.fromOffset(810,250);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=8;list.Parent=gui
   table.insert(def.lists,list)
  end
 end
 if persistent then def.store=DS:GetOrderedDataStore("CoinSprint_TopV3_"..def.Stat) end
end
local function render(def,rows)
 for _,list in ipairs(def.lists) do
  list:ClearAllChildren();list.CanvasSize=UDim2.fromOffset(0,math.max(250,#rows*32))
  if #rows==0 then label(list,"Be the first on this board!",UDim2.fromOffset(0,50),UDim2.fromOffset(780,40),23)
  else
   for i,row in ipairs(rows) do
    label(list,string.format("#%d   %s",i,row.Name),UDim2.fromOffset(8,(i-1)*32),UDim2.fromOffset(560,30),21).TextXAlignment=Enum.TextXAlignment.Left
    label(list,string.format("%g",row.Value),UDim2.fromOffset(570,(i-1)*32),UDim2.fromOffset(200,30),21).TextXAlignment=Enum.TextXAlignment.Right
   end
  end
 end
end
-- Пьедестал: топ-3 по заработанным монетам стоят аватарами на ступенях 1-2-3 в обоих мирах.
local AvatarPose=require(script.Parent:WaitForChild("AvatarPose"))
local avatarCache={}
local podiumShown={}
local function avatarFor(userId)
 if avatarCache[userId]==nil then
  local ok,model=pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(userId) end)
  avatarCache[userId]=ok and model or false
 end
 return avatarCache[userId] or nil
end
-- Под каждой доской свой пьедестал (Podium_BoardCoins и т.д.) с топ-3 именно этой доски.
local function updatePodiums(def,rows)
 for _,zone in ipairs({world,city}) do
  local podium=zone:FindFirstChild("Podium_"..def.Part)
  if podium then
   for place=1,3 do
    local step=podium:FindFirstChild("Place"..place)
    local row=rows[place]
    local key=zone.Name..def.Part..place
    local wanted=row and row.UserId or 0
    if step and podiumShown[key]~=wanted then
     podiumShown[key]=wanted
     local old=podium:FindFirstChild("Winner"..place)
     if old then old:Destroy() end
     -- Имя победителя пишется на табличке спереди ступени (Plate1..3).
     local plate=podium:FindFirstChild("Plate"..place)
     local tagText=plate and plate:FindFirstChild("PlayerName",true)
     if tagText then tagText.Text=row and row.Name or "—" end
     local template=row and row.UserId>0 and avatarFor(row.UserId)
     if template then
      local npc=template:Clone()
      npc.Name="Winner"..place
      AvatarPose.Prepare(npc)
      npc.Parent=podium
      local top=step.Position+Vector3.new(0,step.Size.Y/2,0)
      if step:IsA("Part") and step.Shape==Enum.PartType.Cylinder then top=step.Position+Vector3.new(0,step.Size.X/2,0) end
      AvatarPose.Place(npc,top,CFrame.Angles(0,0,0),top.Y,false)
     end
    end
   end
  end
 end
end
local function refresh()
 for _,def in ipairs(defs) do
  local rows={}
  for _,p in ipairs(Players:GetPlayers()) do
   table.insert(rows,{Name=p.DisplayName,UserId=p.UserId,Value=p:GetAttribute(def.Stat) or 0})
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
     table.insert(rows,{Name=name,UserId=id or 0,Value=entry.value/def.Scale})
    end
    for _,sub in ipairs(def.subtitles) do sub.Text="GLOBAL · refreshes every 120s" end
   else for _,sub in ipairs(def.subtitles) do sub.Text="THIS SERVER · global service unavailable" end end
  end
  render(def,rows)
  task.spawn(updatePodiums,def,rows)
 end
end
task.spawn(function() while true do refresh();task.wait(persistent and 120 or 8) end end)
