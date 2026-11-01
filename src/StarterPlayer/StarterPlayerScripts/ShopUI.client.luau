-- Touch-to-open egg gallery, searchable-by-egg collection index, and optional upgrade menu.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(RS:WaitForChild("GameConfig"))
local PetVisuals=require(RS:WaitForChild("PetVisuals"))
local coins=player:WaitForChild("leaderstats"):WaitForChild("Coins")
local speed=player.leaderstats:WaitForChild("SpeedLevel")
local buy=RS:WaitForChild("GameShopBuy")
local gui=Instance.new("ScreenGui");gui.Name="WorkshopUI";gui.ResetOnSpawn=false;gui.DisplayOrder=20;gui.Parent=player:WaitForChild("PlayerGui")
local function frame(parent,size,pos,color)
 local f=Instance.new("Frame");f.Size=size;f.Position=pos;f.BackgroundColor3=color or Color3.fromRGB(26,40,45);f.BorderSizePixel=0;f.Parent=parent;Instance.new("UICorner",f).CornerRadius=UDim.new(0,16);return f
end
local function text(parent,contents,x,y,w,h,font)
 local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Text=contents;t.Position=UDim2.fromOffset(x,y);t.Size=UDim2.fromOffset(w,h);t.Font=Enum.Font.GothamBold;t.TextSize=font or 16;t.TextColor3=Color3.fromRGB(236,244,239);t.TextWrapped=true;t.Parent=parent;return t
end
local function button(parent,contents,x,y,w,h)
 local b=Instance.new("TextButton");b.Text=contents;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,h);b.Font=Enum.Font.GothamBold;b.TextSize=16;b.TextColor3=Color3.fromRGB(245,249,242);b.BackgroundColor3=Color3.fromRGB(72,142,113);b.BorderSizePixel=0;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,10);return b
end
local function viewport(parent,x,y,w,h)
 local view=Instance.new("ViewportFrame");view.Position=UDim2.fromOffset(x,y);view.Size=UDim2.fromOffset(w,h);view.BackgroundTransparency=1;view.Ambient=Color3.fromRGB(192,196,210);view.LightColor=Color3.fromRGB(255,248,230);view.LightDirection=Vector3.new(-1,-1,-2);view.Parent=parent
 local camera=Instance.new("Camera");camera.CFrame=CFrame.lookAt(Vector3.new(4,2.8,-6),Vector3.new(0,0.2,0));camera.FieldOfView=38;camera.Parent=view;view.CurrentCamera=camera
 local scene=Instance.new("WorldModel",view);return scene
end
local panel=frame(gui,UDim2.fromOffset(560,445),UDim2.new(1,-22,0.5,0));panel.AnchorPoint=Vector2.new(1,0.5);panel.Visible=false
local scale=Instance.new("UIScale",panel)
local title=text(panel,"",16,12,475,32,22)
local wallet=text(panel,"",16,46,475,24,14)
local close=button(panel,"×",512,12,34,34);close.Modal=true
local gallery=frame(panel,UDim2.fromOffset(532,285),UDim2.fromOffset(14,78));gallery.BackgroundTransparency=1
local detail=text(panel,"Hover a pet to see its rarity and coin multiplier",14,365,532,30,14)
local action=button(panel,"",112,405,335,30)
local previous=button(panel,"‹",16,405,42,30)
local nextPage=button(panel,"›",502,405,42,30)
local upgradePanel=frame(panel,UDim2.fromOffset(532,320),UDim2.fromOffset(14,80));upgradePanel.BackgroundTransparency=1;upgradePanel.Visible=false
local cards={}
for i,entry in ipairs({{"speed","SPEED"},{"magnet","MAGNET"},{"income","COIN INCOME"}}) do
 local card=frame(upgradePanel,UDim2.fromOffset(169,305),UDim2.fromOffset((i-1)*180,0),Color3.fromRGB(38,56,61))
 text(card,entry[2],5,16,159,36,18)
 local status=text(card,"",10,70,149,130,16)
 cards[entry[1]]={status=status,button=button(card,"",9,235,151,52)}
end
local rarityColors={Common=Color3.fromRGB(182,203,190),Uncommon=Color3.fromRGB(128,218,147),Rare=Color3.fromRGB(110,179,255),Epic=Color3.fromRGB(198,135,255),Legendary=Color3.fromRGB(255,206,101),Mythic=Color3.fromRGB(255,126,191),Secret=Color3.fromRGB(255,255,255)}
local mode,zoneId,eggId,nearPart,dismissed
local cells={}
local busy=0
local function hide()
 panel.Visible=false;dismissed=eggId;mode=nil
 if player:GetAttribute("UIScreen")~="stats" then player:SetAttribute("UIScreen","") end
end
close.Activated:Connect(hide)
local function request(kind)
 if os.clock()<busy or not zoneId then return end
 busy=os.clock()+0.55;buy:FireServer(kind,zoneId,eggId)
end
for kind,card in pairs(cards) do card.button.Activated:Connect(function() request(kind) end) end
action.Activated:Connect(function() if mode=="egg" then request("egg") end end)
local function refresh()
 wallet.Text=string.format("Coins: %g",coins.Value)
 if eggId then
  local egg=Config.Eggs[eggId]
  title.Text=(mode=="index" and "PET INDEX · " or "")..egg.Name
  action.Text=mode=="index" and "Collect pets by opening eggs" or ("HATCH · "..egg.Cost.." COINS")
  action.Active=mode=="egg"
 end
 for _,cell in ipairs(cells) do cell.owned.Text=(player:GetAttribute("PetOwned"..cell.id) or 0)>0 and ("OWNED ×"..(player:GetAttribute("PetOwned"..cell.id) or 0)) or "UNDISCOVERED" end
 local values={speed=speed.Value,magnet=player:GetAttribute("MagnetLevel") or 0,income=player:GetAttribute("IncomeLevel") or 0}
 for kind,card in pairs(cards) do
  local n=values[kind]
  local maximum=kind=="speed" and Config.MaxSpeedLevel or (kind=="magnet" and Config.MaxMagnetLevel or Config.MaxIncomeLevel)
  local price=kind=="speed" and Config.GetUpgradeCost(n) or (kind=="magnet" and Config.GetMagnetUpgradeCost(n) or Config.GetIncomeUpgradeCost(n))
  local desc=kind=="speed" and (Config.GetWalkSpeed(n).." → "..Config.GetWalkSpeed(math.min(n+1,maximum))) or (kind=="magnet" and string.format("%.2f → %.2f studs",Config.GetMagnetRadius(n),Config.GetMagnetRadius(math.min(n+1,maximum))) or string.format("x%g → x%g",Config.GetIncomeMultiplier(n),Config.GetIncomeMultiplier(math.min(n+1,maximum))))
  card.status.Text=string.format("LEVEL %d / %d\n\n%s",n,maximum,desc)
  card.button.Text=n>=maximum and "MAX" or ("BUY · "..price)
  card.button.Active=n<maximum
  card.button.BackgroundColor3=coins.Value>=price and Color3.fromRGB(72,142,113) or Color3.fromRGB(98,81,81)
 end
end
local function buildGallery()
 gallery:ClearAllChildren();cells={}
 local egg=Config.Eggs[eggId]
 for i,entry in ipairs(egg.Pool) do
  local def=Config.Pets[entry.Pet]
  local x,y=(i-1)%5*107,math.floor((i-1)/5)*140
  local cell=button(gallery,"",x,y,102,132);cell.BackgroundColor3=Color3.fromRGB(37,53,61)
  local border=Instance.new("UIStroke",cell);border.Color=rarityColors[def.Rarity];border.Transparency=0.35
  local scene=viewport(cell,4,1,94,72)
  local model=PetVisuals.Build(entry.Pet);model.Parent=scene
  text(cell,def.Name,3,74,96,27,10)
  text(cell,string.format("%g%% · x%g",entry.Chance,def.Multiplier),3,101,96,15,11).TextColor3=rarityColors[def.Rarity]
  local owned=text(cell,"",3,117,96,12,9)
  table.insert(cells,{id=entry.Pet,owned=owned})
  local function hover() detail.Text=string.format("%s · %s · x%g coins · %g%%",def.Name,def.Rarity,def.Multiplier,entry.Chance) end
  cell.MouseEnter:Connect(hover);cell.Activated:Connect(hover)
 end
 refresh()
end
local function showEgg(id,indexMode)
 if mode==(indexMode and "index" or "egg") and eggId==id and panel.Visible then return end
 eggId=id;zoneId=Config.Eggs[id].World;mode=indexMode and "index" or "egg"
 local rootWorld=workspace:FindFirstChild("CoinSpeedWorld")
 local zone=rootWorld and (zoneId=="neon" and rootWorld:FindFirstChild("NeonCity") or rootWorld)
 local stand=zone and zone:FindFirstChild("EggStand"..id)
 nearPart=stand and stand.Interact
 gallery.Visible=true;upgradePanel.Visible=false;action.Visible=true;detail.Visible=true
 previous.Visible=indexMode;nextPage.Visible=indexMode
 player:SetAttribute("UIScreen",mode);panel.Visible=true;buildGallery()
end
previous.Activated:Connect(function() if mode=="index" then showEgg((eggId-2)%#Config.Eggs+1,true) end end)
nextPage.Activated:Connect(function() if mode=="index" then showEgg(eggId%#Config.Eggs+1,true) end end)
RS:WaitForChild("GameShopOpen").OnClientEvent:Connect(function(newMode,newZone,newEgg)
 if newMode=="egg" then showEgg(newEgg,false);return end
 do return end -- меню киоска и магазина магнитов рисует ShopPanels.client.luau
 mode="shop";zoneId=newZone
 local world=workspace.CoinSpeedWorld
 local zone=newZone=="neon" and world.NeonCity or world
 nearPart=zone.UpgradeShop:FindFirstChild("ShopZone") or zone.UpgradeShop.Counter
 title.Text="UPGRADE KIOSK";player:SetAttribute("UIScreen","shop")
 gallery.Visible=false;upgradePanel.Visible=true;action.Visible=false;detail.Visible=false;previous.Visible=false;nextPage.Visible=false;panel.Visible=true;refresh()
end)
-- Индекс питомцев теперь отдельная книга (PetIndex.client.luau).
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
 local active=player:GetAttribute("UIScreen")
 if active~="shop" and active~="egg" and active~="index" then panel.Visible=false;mode=nil end
end)
coins.Changed:Connect(refresh);speed.Changed:Connect(refresh);player.AttributeChanged:Connect(function(name) if name=="IncomeLevel" or name=="MagnetLevel" or string.sub(name,1,8)=="PetOwned" then refresh() end end)

local reveal=frame(gui,UDim2.fromOffset(385,385),UDim2.fromScale(0.5,0.5),Color3.fromRGB(29,38,57));reveal.AnchorPoint=Vector2.new(0.5,0.5);reveal.Visible=false
local revealScale=Instance.new("UIScale",reveal)
local revealTitle=text(reveal,"HATCHING",10,8,365,40,23)
local revealScene=viewport(reveal,10,48,365,260)
local resultText=text(reveal,"",12,312,361,62,17)
local revealModel,hatchStart,resultId,resultCount
local finished=false
local eggDisplays={}
local world=workspace:WaitForChild("CoinSpeedWorld")
for id,egg in ipairs(Config.Eggs) do
 local zone=egg.World=="neon" and world:WaitForChild("NeonCity") or world
 local stand=zone:WaitForChild("EggStand"..id)
 local size=stand.EggDisplay:GetExtentsSize()
 eggDisplays[id]={model=stand.EggDisplay,base=stand.EggDisplay:GetPivot(),part=stand.Interact,radius=math.max(size.X,size.Z)/2}
end
RS:WaitForChild("GameHatched").OnClientEvent:Connect(function(id,count,sourceEgg)
 if not Config.Pets[id] then return end
 panel.Visible=false;mode=nil;dismissed=sourceEgg
 player:SetAttribute("UIScreen","hatch")
 if revealModel then revealModel:Destroy() end
 revealModel=eggDisplays[sourceEgg].model:Clone();revealModel.Parent=revealScene
 revealModel:ScaleTo(revealModel:GetScale()*3.3/math.max(revealModel:GetExtentsSize().Y,0.1));revealModel:PivotTo(CFrame.identity)
 resultId=id;resultCount=count;hatchStart=os.clock();finished=false
 revealTitle.Text="HATCHING…";resultText.Text="A new companion awaits";reveal.Visible=true;busy=os.clock()+4.2
end)
local elapsed,scan=0,0
RunService.RenderStepped:Connect(function(dt)
 elapsed=elapsed+dt;scan=scan+dt
 local camera=workspace.CurrentCamera
 if camera then local size=camera.ViewportSize;scale.Scale=math.clamp(math.min(size.X/600,size.Y/500),0.3,1);revealScale.Scale=math.clamp(math.min(size.X/420,size.Y/440),0.3,1) end
 for id,entry in pairs(eggDisplays) do entry.model:PivotTo(entry.base*CFrame.new(0,math.sin(elapsed*1.5+id)*0.09,0)*CFrame.Angles(0,elapsed*0.45,0)) end
 if scan>0.15 then
  scan=0
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if mode=="shop" and panel.Visible then
   -- Меню магазина закрывается, когда игрок вышел из зелёной метки (или отошёл от прилавка).
   local far=not root
   if root and nearPart.Name=="ShopZone" then
    local o=root.Position-nearPart.Position
    far=Vector2.new(o.X,o.Z).Magnitude>nearPart.Size.Z/2+3
   elseif root then far=(root.Position-nearPart.Position).Magnitude>Config.ShopDistance+2 end
   if far then hide() end
  end
  -- Меню яйца открывается, только когда персонаж касается яйца, и закрывается, когда он отходит.
  local nearest,distance
  if root then
   for id,entry in pairs(eggDisplays) do
    local offset=root.Position-entry.base.Position
    local d=Vector2.new(offset.X,offset.Z).Magnitude-entry.radius
    local limit=(mode=="egg" and eggId==id) and 5 or 2.2
    if d<limit and math.abs(offset.Y)<entry.radius*2+4 and (not distance or d<distance) then nearest=id;distance=d end
   end
  end
  if not nearest then
   dismissed=nil
   if mode=="egg" then hide();dismissed=nil end
  elseif nearest~=dismissed and ((player:GetAttribute("UIScreen") or "")=="" or mode=="egg") then showEgg(nearest,false) end
 end
 if reveal.Visible then
  local t=os.clock()-hatchStart
  if t<1.5 then revealModel:PivotTo(CFrame.Angles(0,t*3,math.sin(t*25)*0.13))
  elseif not finished then
   finished=true;revealModel:Destroy();revealModel=PetVisuals.Build(resultId);revealModel.Parent=revealScene
   revealTitle.Text=Config.Pets[resultId].Name;revealTitle.TextColor3=rarityColors[Config.Pets[resultId].Rarity]
   resultText.Text=string.format("%s · x%g coins\n%s",Config.Pets[resultId].Rarity,Config.Pets[resultId].Multiplier,resultCount>1 and ("Duplicate · owned "..resultCount) or "New pet discovered!")
  else revealModel:PivotTo(CFrame.Angles(0,math.sin(t)*0.3,0)) end
  if t>4 then reveal.Visible=false;revealModel:Destroy();revealModel=nil;player:SetAttribute("UIScreen","") end
 end
end)
