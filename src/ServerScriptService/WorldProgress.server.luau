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
-- Числа из сохранения: отбрасываем только NaN и бесконечность (раньше всё ≥1e15 обнулялось — поздняя игра теряла монеты).
local function number(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge and math.clamp(v,0,1e300) or 0 end
local function snapshot(p)
 local data={Version=1,Coins=number(p.leaderstats.Coins.Value),Speed=p.leaderstats.SpeedLevel.Value,Owned={},AutoDelete={}}
 data.DailyDay=p:GetAttribute("DailyDay") or 0
 data.DailyClaimedAt=p:GetAttribute("DailyClaimedAt") or 0
 data.QuestState=p:GetAttribute("QuestState") or ""
 for i=1,#Config.Pets do data.AutoDelete[tostring(i)]=p:GetAttribute("AutoDelete"..i)==true end
 for _,name in ipairs({"MagnetLevel","IncomeLevel","DoubleLevel","Rebirths","PetLevel","LifetimeEarned","CoinsCollected","EggsOpened"}) do data[name]=number(p:GetAttribute(name)) end
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
 -- Новые системы (квестовая линия, ребёрс-награды, способности) хранят состояние в атрибутах
 -- с префиксом Save_: они сохраняются и загружаются автоматически.
 data.Extra={}
 for k,v in pairs(p:GetAttributes()) do
  if string.sub(k,1,5)=="Save_" and (type(v)=="number" or type(v)=="string" or type(v)=="boolean") then data.Extra[k]=v end
 end
 return data
end
local function load(p)
 local stats=p:WaitForChild("leaderstats",20)
 if not stats then return end
 if not persistent then p:SetAttribute("ProfileReady",true);p:SetAttribute("SaveStatus","SESSION ONLY");return end
 local loaded
 -- Замок профиля — на сессию игрока, а не на сервер: быстрый перезаход на тот же сервер
 -- ждёт, пока старая сессия сохранится и снимет замок (иначе сохранения новой молча отбрасывались).
 local myToken=token..":"..game:GetService("HttpService"):GenerateGUID(false)
 for attempt=1,6 do
  local ok,data=pcall(function()
   return store:UpdateAsync(tostring(p.UserId),function(old)
    old=type(old)=="table" and old or {}
    if old.Session and old.Session~=myToken and os.time()-(old.Lease or 0)<180 then return nil end
    old.Session=myToken;old.Lease=os.time();return old
   end)
  end)
  if ok and data and data.Session==myToken then loaded=data;break end
  if p.Parent~=Players then break end
  task.wait(attempt*2)
 end
 -- игрок ушёл, пока профиль грузился: сразу снимаем замок, иначе он висел бы до конца жизни сервера
 if loaded and p.Parent~=Players then
  pcall(function() store:UpdateAsync(tostring(p.UserId),function(old) if type(old)=="table" and old.Session==myToken then old.Session=nil;return old end;return nil end) end)
  return
 end
 if p.Parent~=Players then return end
 if not loaded then p:Kick("Your profile is unavailable or still open on another server. Please rejoin shortly.");return end
 sessions[p]={busy=false,release=false,token=myToken}
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
 if type(loaded.Extra)=="table" then
  for k,v in pairs(loaded.Extra) do
   if type(k)=="string" and string.sub(k,1,5)=="Save_" and (type(v)=="string" and #v<4000 or type(v)=="boolean" or type(v)=="number" and v==v and v~=math.huge and v~=-math.huge) then p:SetAttribute(k,v) end
  end
 end
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if h then h.WalkSpeed=Config.GetWalkSpeed(stats.SpeedLevel.Value) end
 p:SetAttribute("ProfileReady",true);p:SetAttribute("SaveStatus","SAVING ENABLED")
end
local function save(p,release)
 local session=sessions[p]
 if not session then return true end
 session.release=session.release or release
 if session.busy then if not release then return false end;repeat task.wait(0.1) until not session.busy end
 session.busy=true
 local okSnap,data=pcall(snapshot,p)
 if not okSnap then session.busy=false;warn("[Profiles] Snapshot failed: "..tostring(data));return false end
 if session.release then data.Session=nil else data.Session=session.token end
 data.Lease=os.time()
 -- при выходе и выключении сервера пробуем несколько раз с паузой: прогресс не должен теряться
 local ok,err
 for attempt=1,(session.release and 4 or 1) do
  local rejected=false
  ok,err=pcall(function()
   store:UpdateAsync(tostring(p.UserId),function(old)
    if type(old)~="table" or old.Session~=session.token then rejected=true;return nil end
    rejected=false;return data
   end)
  end)
  -- замок забрала другая сессия: это не «успех», дальше сохранять нельзя
  if ok and rejected then ok=false;err="session lock lost";break end
  if ok then break end
  task.wait(attempt*1.5)
 end
 session.busy=false
 if not ok then warn("[Profiles] Save failed: "..tostring(err));pcall(function() p:SetAttribute("SaveStatus","SAVE RETRY PENDING") end) end
 if session.release and ok then sessions[p]=nil end
 return ok
end
-- Монетизация просит сохранить профиль сразу после покупки (чтобы купленное не пропало при падении сервера).
local saveNow=Instance.new("BindableFunction")
saveNow.Name="SaveProfileNow"
saveNow.OnInvoke=function(p)
 if not persistent then return true end
 local session=sessions[p]
 if not session then return false end
 local t0=os.clock()
 while session.busy and os.clock()-t0<10 do task.wait(0.1) end
 if sessions[p]~=session then return false end -- профиль уже выгружен (выход/выключение)
 return save(p,false)
end
saveNow.Parent=game:GetService("ServerStorage")
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
local defs={{Part="BoardCoins",Title="TOP 100 · COINS",Stat="LifetimeEarned",Scale=100,Log=true},{Part="BoardEggs",Title="TOP 100 · EGGS",Stat="EggsOpened",Scale=1},{Part="BoardPickups",Title="TOP 100 · PICKUPS",Stat="CoinsCollected",Scale=1}}
local names={}
local function label(parent,text,pos,size,fontSize,color)
 local x=Instance.new("TextLabel")
 x.BackgroundTransparency=1;x.Position=pos;x.Size=size;x.Text=text
 x.Font=Enum.Font.GothamBold;x.TextSize=fontSize;x.TextColor3=color or Color3.fromRGB(239,245,232);x.Parent=parent;return x
end
-- 3D-оформление досок: объёмная табличка-заголовок сверху и крутящаяся эмблема над ней
-- (монета / яйцо / кристалл). Вращение и покачивание делает клиент (LeaderboardFX) по тегу BoardEmblem.
local CollectionService=game:GetService("CollectionService")
local EMBLEM={
 BoardCoins={Text="🪙 COINS",Plate=Color3.fromRGB(255,196,60),Ink=Color3.fromRGB(120,70,0)},
 BoardEggs={Text="🥚 EGGS",Plate=Color3.fromRGB(120,220,255),Ink=Color3.fromRGB(20,70,130)},
 BoardPickups={Text="✨ PICKUPS",Plate=Color3.fromRGB(200,130,255),Ink=Color3.fromRGB(70,20,120)},
}
local function dpart(parent,name,size,cf,color,mat,shape)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Size=size;p.CFrame=cf;p.Color=color;p.Material=mat or Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
local function decorate(board,neon)
 local e=EMBLEM[board.Name]
 if not e or board.Parent:FindFirstChild(board.Name.."_3D") then return end
 local m=Instance.new("Model");m.Name=board.Name.."_3D";m.Parent=board.Parent
 local cf=board.CFrame
 local w=board.Size.X
 -- верх рамки доски (балка над доской выше самой доски): ищем самую высокую деталь прямо над ней
 local topY=board.Position.Y+board.Size.Y/2
 local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Exclude;op.FilterDescendantsInstances={board,m}
 for _,q in ipairs(workspace:GetPartBoundsInBox(cf*CFrame.new(0,board.Size.Y/2+3,0),Vector3.new(w,8,4),op)) do
  if q.Transparency<1 then topY=math.max(topY,q.Position.Y+q.Size.Y/2) end
 end
 local top=cf*CFrame.new(0,topY-board.Position.Y,0)
 -- объёмная табличка: основа + светящийся кант + текст спереди и сзади
 local plateCf=top*CFrame.new(0,2.6,0)
 local plate=dpart(m,"TitlePlate",Vector3.new(math.min(w*0.55,24),4.4,1.6),plateCf,e.Plate,Enum.Material.SmoothPlastic)
 dpart(m,"TitleRim",plate.Size+Vector3.new(0.6,0.6,-0.4),plateCf*CFrame.new(0,0,0.1),board:GetAttribute("TrimColor") or (neon and Color3.fromRGB(255,90,220) or Color3.new(1,1,1)),Enum.Material.Neon)
 for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
  local g=Instance.new("SurfaceGui");g.Face=face;g.CanvasSize=Vector2.new(500,82);g.LightInfluence=0;g.Brightness=1.4;g.MaxDistance=160;g.Parent=plate
  local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Font=Enum.Font.FredokaOne;t.TextScaled=true
  t.Text=e.Text;t.TextColor3=Color3.new(1,1,1);t.Parent=g
  local st=Instance.new("UIStroke");st.Thickness=5;st.Color=e.Ink;st.Parent=t
 end
 -- эмблема над табличкой
 local base=plateCf*CFrame.new(0,6.4,0)
 local emb
 if board.Name=="BoardCoins" then
  emb=dpart(m,"Emblem",Vector3.new(1.1,6.5,6.5),base*CFrame.Angles(0,math.rad(90),0),Color3.fromRGB(255,200,40),Enum.Material.Metal,Enum.PartType.Cylinder)
  emb.Reflectance=0.15
  for _,face in ipairs({Enum.NormalId.Left,Enum.NormalId.Right}) do
   local g=Instance.new("SurfaceGui");g.Face=face;g.CanvasSize=Vector2.new(200,200);g.LightInfluence=0;g.Parent=emb
   local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Font=Enum.Font.FredokaOne;t.TextScaled=true
   t.Text="$";t.TextColor3=Color3.fromRGB(255,245,190);t.Parent=g
   local st=Instance.new("UIStroke");st.Thickness=6;st.Color=Color3.fromRGB(170,100,0);st.Parent=t
  end
  emb:SetAttribute("Spin",90)
 elseif board.Name=="BoardEggs" then
  emb=dpart(m,"Emblem",Vector3.new(4.6,5.8,4.6),base,Color3.fromRGB(150,225,255),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=emb
  local band=dpart(m,"EmblemBand",Vector3.new(4.7,1,4.7),base*CFrame.new(0,-0.4,0),Color3.fromRGB(255,240,120),Enum.Material.Neon,Enum.PartType.Ball)
  local bm=Instance.new("SpecialMesh");bm.MeshType=Enum.MeshType.Sphere;bm.Scale=Vector3.new(1,0.25,1);bm.Parent=band
  band:SetAttribute("Bob",0.6);CollectionService:AddTag(band,"BoardEmblem")
  emb:SetAttribute("Bob",0.6)
 else
  emb=dpart(m,"Emblem",Vector3.new(4.2,4.2,4.2),base*CFrame.Angles(math.rad(45),0,math.rad(35.26)),Color3.fromRGB(190,110,255),Enum.Material.Glass)
  emb.Transparency=0.15
  local core=dpart(m,"EmblemCore",Vector3.new(2,2,2),emb.CFrame,Color3.fromRGB(230,180,255),Enum.Material.Neon)
  core:SetAttribute("Spin",-70);CollectionService:AddTag(core,"BoardEmblem")
  emb:SetAttribute("Spin",60)
 end
 local l=Instance.new("PointLight");l.Color=emb.Color;l.Range=14;l.Brightness=1.6;l.Parent=emb
 local sp=Instance.new("ParticleEmitter");sp.Texture="rbxasset://textures/particles/sparkles_main.dds";sp.Color=ColorSequence.new(emb.Color,Color3.new(1,1,1))
 sp.LightEmission=1;sp.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,0)});sp.Lifetime=NumberRange.new(0.8,1.5)
 sp.Speed=NumberRange.new(0.5,1.5);sp.SpreadAngle=Vector2.new(180,180);sp.Rate=6;sp.Parent=emb
 CollectionService:AddTag(emb,"BoardEmblem")
end
-- Доски есть в обоих мирах: одинаковые таблицы рисуются на каждой найденной доске.
local city=world:WaitForChild("NeonCity")
-- Meadow и Neon: доски стоят в плейсе. Sky/Frozen/Volcano/Galaxy: строит LeaderboardBuilder (свой стиль каждого мира).
local zones={world,city}
do
 task.wait(2) -- миры строит GameServer на старте; даём монетам и декору появиться, чтобы место нашлось честно
 local ok,extra=pcall(function() return require(script.Parent:WaitForChild("LeaderboardBuilder")).Build(world) end)
 if ok then for _,z in ipairs(extra) do table.insert(zones,z) end else warn("[Leaderboards]",extra) end
end
local function zoneBoard(zone,name)
 if zone==world or zone==city then return zone:FindFirstChild(name) end
 return zone:FindFirstChild(name,true)
end
-- Лёгкая анимация досок Meadow (листики) и Neon (пульс неоновых рамок) — у остальных миров своя из LeaderboardBuilder.
local function themeOldBoard(zone,board)
 if zone==world then
  local src=Instance.new("Part");src.Name="LeafFX";src.Anchored=true;src.CanCollide=false;src.CanQuery=false;src.CanTouch=false;src.Transparency=1
  src.Size=Vector3.new(board.Size.X,0.2,2);src.CFrame=board.CFrame*CFrame.new(0,board.Size.Y/2+1.5,-1);src.Parent=board.Parent
  local e=Instance.new("ParticleEmitter");e.Texture="rbxasset://textures/particles/sparkles_main.dds"
  e.Color=ColorSequence.new(Color3.fromRGB(150,230,110),Color3.fromRGB(255,200,90));e.LightEmission=0.4;e.Rate=2.5
  e.Lifetime=NumberRange.new(3,5);e.Speed=NumberRange.new(0.3,0.8);e.SpreadAngle=Vector2.new(60,60);e.EmissionDirection=Enum.NormalId.Bottom
  e.Acceleration=Vector3.new(0.4,-0.5,0);e.RotSpeed=NumberRange.new(-90,90);e.Rotation=NumberRange.new(0,360)
  e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(1,0.2)})
  e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(0.85,0.2),NumberSequenceKeypoint.new(1,1)});e.Parent=src
 elseif zone==city then
  -- неоновые детали рамки этой доски (BoardCoinsFrame и т.п.) мягко пульсируют на клиенте
  local frame=zone:FindFirstChild(board.Name.."Frame")
  for _,d in ipairs(frame and frame:GetDescendants() or {}) do
   if d:IsA("BasePart") and d.Material==Enum.Material.Neon then game:GetService("CollectionService"):AddTag(d,"BoardPulse") end
  end
  if frame and frame:IsA("BasePart") and frame.Material==Enum.Material.Neon then game:GetService("CollectionService"):AddTag(frame,"BoardPulse") end
 end
end
for _,def in ipairs(defs) do
 def.lists={};def.subtitles={}
 for _,zone in ipairs(zones) do
  local board=zoneBoard(zone,def.Part)
  if board then
   local neon=zone==city
   local noLight=neon or board:GetAttribute("NoLight")==true
   local titleColor=board:GetAttribute("TitleColor") or (neon and Color3.fromRGB(255,120,230) or Color3.fromRGB(255,220,133))
   local subColor=board:GetAttribute("SubColor") or (neon and Color3.fromRGB(120,235,255) or nil)
   local gui=Instance.new("SurfaceGui")
   gui.Name="Rankings";gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(860,360);gui.MaxDistance=130;gui.Active=true;gui.Parent=board
   if noLight then gui.LightInfluence=0 end
   label(gui,def.Title,UDim2.fromOffset(0,8),UDim2.fromOffset(860,45),32,titleColor)
   table.insert(def.subtitles,label(gui,persistent and "GLOBAL · refreshes every 120s" or "THIS SERVER · publish for global rankings",UDim2.fromOffset(0,55),UDim2.fromOffset(860,30),18,subColor))
   pcall(themeOldBoard,zone,board)
   local list=Instance.new("ScrollingFrame")
   list.Position=UDim2.fromOffset(25,95);list.Size=UDim2.fromOffset(810,250);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=8;list.Parent=gui
   table.insert(def.lists,list)
   pcall(decorate,board,neon)
  end
 end
 -- Монеты к концу игры доходят до 1e20 — больше предела OrderedDataStore (9e18), поэтому храним логарифм.
 if persistent then def.store=DS:GetOrderedDataStore((def.Log and "CoinSprint_TopV4_" or "CoinSprint_TopV3_")..def.Stat) end
end
local function encode(def,v)
 v=math.max(0,tonumber(v) or 0)
 if def.Log then return math.floor(math.log10(v+1)*1e15) end
 return math.floor(math.min(v*def.Scale,9e18))
end
local function decode(def,x)
 if def.Log then return 10^(x/1e15)-1 end
 return x/def.Scale
end
local function shortNum(n)
 for _,u in ipairs({{1e21,"Sx"},{1e18,"Qi"},{1e15,"Qa"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do
  if n>=u[1] then return (string.format("%.2f",n/u[1]):gsub("%.?0+$",""))..u[2] end
 end
 return tostring(math.floor(n))
end
-- Строки таблицы создаём один раз и потом только меняем текст (раньше ~1200 меток пересоздавались каждые 2 минуты).
local function render(def,rows)
 for _,list in ipairs(def.lists) do
  list.CanvasSize=UDim2.fromOffset(0,math.max(250,#rows*32))
  if not list:GetAttribute("Built") then
   list:SetAttribute("Built",true)
   local empty=label(list,"Be the first on this board!",UDim2.fromOffset(0,50),UDim2.fromOffset(780,40),23);empty.Name="Empty"
   for i=1,100 do
    local n=label(list,"",UDim2.fromOffset(8,(i-1)*32),UDim2.fromOffset(560,30),21);n.Name="N"..i;n.TextXAlignment=Enum.TextXAlignment.Left
    local v=label(list,"",UDim2.fromOffset(570,(i-1)*32),UDim2.fromOffset(200,30),21);v.Name="V"..i;v.TextXAlignment=Enum.TextXAlignment.Right
   end
  end
  list.Empty.Visible=#rows==0
  for i=1,100 do
   local row=rows[i]
   local n,v=list["N"..i],list["V"..i]
   n.Visible=row~=nil;v.Visible=row~=nil
   if row then
    local t1,t2=string.format("#%d   %s",i,row.Name),shortNum(tonumber(row.Value) or 0)
    if n.Text~=t1 then n.Text=t1 end
    local medal=({Color3.fromRGB(255,215,80),Color3.fromRGB(215,225,240),Color3.fromRGB(235,150,90)})[i]
    if medal and n.TextColor3~=medal then n.TextColor3=medal;v.TextColor3=medal end
    if v.Text~=t2 then v.Text=t2 end
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
-- Топ-3 на пьедестале не стоят столбом: первый танцует, второй радуется, третий машет.
local EMOTES={
 {R15="rbxassetid://507771019",R6="rbxassetid://182435998"},
 {R15="rbxassetid://507770677",R6="rbxassetid://129423030"},
 {R15="rbxassetid://507770239",R6="rbxassetid://128777973"},
}
-- Пьедестал ярче: ступени светятся своим цветом (золото/серебро/бронза), сверху прожектор,
-- кромки неоновые, таблички с именами не темнеют ночью, над первым местом искры.
local brightened={}
local function brighten(podium)
 if brightened[podium] then return end
 brightened[podium]=true
 for _,d in ipairs(podium:GetChildren()) do
  if d:IsA("BasePart") then
   local place=tonumber(string.match(d.Name,"^Place(%d)$"))
   if d.Name=="Rim" then d.Material=Enum.Material.Neon end
   if place then
    local l=Instance.new("PointLight");l.Color=d.Color;l.Range=12;l.Brightness=2.2;l.Parent=d
    local spot=Instance.new("Part");spot.Name="PodiumSpot"..place;spot.Anchored=true;spot.CanCollide=false;spot.CanQuery=false;spot.CanTouch=false;spot.Transparency=1;spot.Size=Vector3.new(1,1,1)
    spot.CFrame=CFrame.lookAt(d.Position+Vector3.new(0,16,-4),d.Position+Vector3.new(0,3,0));spot.Parent=podium
    local sl=Instance.new("SpotLight");sl.Face=Enum.NormalId.Front;sl.Angle=40;sl.Range=24;sl.Brightness=place==1 and 6 or 4;sl.Color=Color3.new(1,0.97,0.9):Lerp(d.Color,0.3);sl.Parent=spot
    if place==1 then
     local e=Instance.new("ParticleEmitter");e.Texture="rbxasset://textures/particles/sparkles_main.dds";e.Color=ColorSequence.new(Color3.fromRGB(255,230,120),Color3.new(1,1,1))
     e.LightEmission=1;e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)});e.Lifetime=NumberRange.new(1,2);e.Speed=NumberRange.new(1,3)
     e.SpreadAngle=Vector2.new(180,180);e.Rate=10;e.Parent=d
    end
   end
   if string.match(d.Name,"^Plate%d$") then
    d.Color=Color3.fromRGB(48,44,86)
    for _,g in ipairs(d:GetDescendants()) do if g:IsA("SurfaceGui") then g.LightInfluence=0;g.Brightness=1.6 end end
   end
  end
 end
end
-- Под каждой доской свой пьедестал (Podium_BoardCoins и т.д.) с топ-3 именно этой доски.
local function updatePodiums(def,rows)
 for _,zone in ipairs(zones) do
  local podium=zone:FindFirstChild("Podium_"..def.Part)
  if podium then
   pcall(brighten,podium)
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
      AvatarPose.Place(npc,top,CFrame.Angles(0,podium:GetAttribute("Yaw") or 0,0),top.Y,false)
      pcall(AvatarPose.Emote,npc,EMOTES[place])
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
   if def.store and p:GetAttribute("ProfileReady") then pcall(function() def.store:UpdateAsync(tostring(p.UserId),function(old) return math.max(old or 0,encode(def,p:GetAttribute(def.Stat) or 0)) end) end) end
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
     table.insert(rows,{Name=name,UserId=id or 0,Value=decode(def,entry.value)})
    end
    for _,sub in ipairs(def.subtitles) do sub.Text="GLOBAL · refreshes every 120s" end
   else for _,sub in ipairs(def.subtitles) do sub.Text="THIS SERVER · global service unavailable" end end
  end
  render(def,rows)
  task.spawn(updatePodiums,def,rows)
 end
end
task.spawn(function() while true do refresh();task.wait(persistent and 120 or 8) end end)
