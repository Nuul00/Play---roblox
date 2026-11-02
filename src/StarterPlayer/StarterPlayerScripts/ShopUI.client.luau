-- Shared egg gallery: server-priced single/triple hatch and per-species auto-delete.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(RS:WaitForChild("GameConfig"))
local PetVisuals=require(RS:WaitForChild("PetVisuals"))
local coins=player:WaitForChild("leaderstats"):WaitForChild("Coins")
local buy=RS:WaitForChild("GameShopBuy")
local action=RS:WaitForChild("GameAction")
local gui=Instance.new("ScreenGui");gui.Name="WorkshopUI";gui.ResetOnSpawn=false;gui.DisplayOrder=30;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=player:WaitForChild("PlayerGui")
local colors={Common=Color3.fromRGB(188,203,224),Uncommon=Color3.fromRGB(116,227,173),Rare=Color3.fromRGB(105,193,255),Epic=Color3.fromRGB(201,143,255),Legendary=Color3.fromRGB(255,204,104),Mythic=Color3.fromRGB(255,135,202),Secret=Color3.new(1,1,1)}
local function box(parent,x,y,w,h,c)
 local f=Instance.new("Frame");f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h);f.BackgroundColor3=c or Color3.fromRGB(33,26,57);f.BorderSizePixel=0;f.Parent=parent;Instance.new("UICorner",f).CornerRadius=UDim.new(0,16);return f
end
local function label(parent,s,x,y,w,h,size,c)
 local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(x,y);t.Size=UDim2.fromOffset(w,h);t.Text=s;t.TextColor3=c or Color3.fromRGB(251,239,255);t.TextSize=size or 16;t.Font=Enum.Font.GothamBold;t.TextWrapped=true;t.Parent=parent;return t
end
local function button(parent,s,x,y,w,h,c)
 local b=Instance.new("TextButton");b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,h);b.Text=s;b.Font=Enum.Font.GothamBold;b.TextSize=15;b.TextColor3=Color3.new(1,1,1);b.BackgroundColor3=c or Color3.fromRGB(140,83,188);b.BorderSizePixel=0;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,12);return b
end
local function stroke(f,c,t) local s=Instance.new("UIStroke");s.Color=c;s.Thickness=t or 1.5;s.Transparency=.25;s.Parent=f;return s end
local function viewport(parent,x,y,w,h)
 local v=Instance.new("ViewportFrame");v.BackgroundTransparency=1;v.Position=UDim2.fromOffset(x,y);v.Size=UDim2.fromOffset(w,h);v.Ambient=Color3.fromRGB(210,195,224);v.LightColor=Color3.fromRGB(255,230,203);v.LightDirection=Vector3.new(-1,-1,-2);v.Parent=parent
 local camera=Instance.new("Camera");camera.FieldOfView=38;camera.CFrame=CFrame.lookAt(Vector3.new(3,1.8,-5.8),Vector3.zero);camera.Parent=v;v.CurrentCamera=camera
 local scene=Instance.new("WorldModel",v);return scene
end
local panel=box(gui,0,0,650,646);panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Visible=false;stroke(panel,Color3.fromRGB(239,167,236),2)
local scale=Instance.new("UIScale",panel)
local header=box(panel,8,8,634,90,Color3.fromRGB(137,80,173))
local gradient=Instance.new("UIGradient",header);gradient.Color=ColorSequence.new(Color3.fromRGB(155,104,233),Color3.fromRGB(255,160,152));gradient.Rotation=20
local title=label(header,"",18,11,530,32,25);title.TextXAlignment=Enum.TextXAlignment.Left
local subtitle=label(header,"",18,49,530,24,14);subtitle.TextXAlignment=Enum.TextXAlignment.Left
local close=button(header,"×",581,13,38,38,Color3.fromRGB(76,48,108));close.Modal=true
local gallery=box(panel,18,112,614,450);gallery.BackgroundTransparency=1
local hint=label(panel,"AUTO-DELETE removes only future hatches. Tap KEEP to mark a pet.",18,566,614,26,12,Color3.fromRGB(220,196,232))
local single=button(panel,"",18,602,297,32,Color3.fromRGB(133,88,204))
local triple=button(panel,"",329,602,303,32,Color3.fromRGB(218,132,84))
local eggId,mode,dismissed
local cells={}
local busy=0
local function hide() panel.Visible=false;dismissed=eggId;mode=nil;if player:GetAttribute("UIScreen")=="egg" then player:SetAttribute("UIScreen","") end end
close.Activated:Connect(hide)
local function refresh()
 if not eggId then return end
 local egg=Config.Eggs[eggId]
 title.Text=string.upper(egg.Name)
 subtitle.Text=string.format("%d COMPANIONS  ·  %g COINS EACH  ·  WALLET %g",#egg.Pool,egg.Cost,coins.Value)
 for _,cell in ipairs(cells) do
  local deleting=player:GetAttribute("AutoDelete"..cell.id)==true
  cell.toggle.Text=deleting and "✕ AUTO-DELETE" or "✓ KEEP"
  cell.toggle.BackgroundColor3=deleting and Color3.fromRGB(172,65,93) or Color3.fromRGB(61,77,106)
  cell.owned.Text="OWNED ×"..(player:GetAttribute("PetOwned"..cell.id) or 0)
 end
 local waiting=os.clock()<busy
 for _,pair in ipairs({{single,1},{triple,3}}) do
  local b,n=pair[1],pair[2];local affordable=coins.Value>=egg.Cost*n
  b.Text=waiting and "OPENING…" or string.format("OPEN ×%d  ·  %g COINS",n,egg.Cost*n)
  b.Active=affordable and not waiting;b.AutoButtonColor=b.Active;b.BackgroundTransparency=b.Active and 0 or .5
 end
end
local function hatch(n)
 if not eggId or os.clock()<busy or coins.Value<Config.Eggs[eggId].Cost*n then return end
 busy=os.clock()+.7;refresh();buy:FireServer("egg",Config.Eggs[eggId].World,eggId,n)
end
single.Activated:Connect(function() hatch(1) end);triple.Activated:Connect(function() hatch(3) end)
local function showEgg(id)
 if mode=="egg" and eggId==id and panel.Visible then return end
 eggId=id;mode="egg";gallery:ClearAllChildren();cells={}
 for i,entry in ipairs(Config.Eggs[id].Pool) do
  local def=Config.Pets[entry.Pet];local c=colors[def.Rarity] or colors.Common
  local cell=box(gallery,(i-1)%3*208,math.floor((i-1)/3)*150,198,142,Color3.fromRGB(45,37,68));stroke(cell,c)
  local grad=Instance.new("UIGradient",cell);grad.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(150,132,180));grad.Rotation=90
  local scene=viewport(cell,3,14,110,91);local model=PetVisuals.Build(entry.Pet);model.Parent=scene
  label(cell,def.Rarity:upper(),5,5,105,15,10,c)
  label(cell,string.format("%g%%",entry.Chance),118,9,72,24,20,c)
  label(cell,string.format("×%g COINS",def.Multiplier),114,38,78,20,11,Color3.fromRGB(255,216,158))
  local owned=label(cell,"",112,65,82,16,10,Color3.fromRGB(218,200,231))
  label(cell,def.Name,4,97,190,20,12)
  local toggle=button(cell,"",8,118,182,18);toggle.TextSize=9
  toggle.Activated:Connect(function() action:FireServer("autodelete",entry.Pet) end)
  table.insert(cells,{id=entry.Pet,toggle=toggle,owned=owned})
 end
 player:SetAttribute("UIScreen","egg");panel.Visible=true;refresh()
end
RS:WaitForChild("GameShopOpen").OnClientEvent:Connect(function(newMode,_,id) if newMode=="egg" then showEgg(id) end end)
coins.Changed:Connect(refresh)
player.AttributeChanged:Connect(function(name) if name:sub(1,8)=="PetOwned" or name:sub(1,10)=="AutoDelete" then refresh() end end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function() if player:GetAttribute("UIScreen")~="egg" then panel.Visible=false;mode=nil end end)
local reveal=box(gui,0,0,760,365);reveal.AnchorPoint=Vector2.new(.5,.5);reveal.Position=UDim2.fromScale(.5,.5);reveal.Visible=false;stroke(reveal,Color3.fromRGB(239,167,236),2)
local revealScale=Instance.new("UIScale",reveal)
local revealTitle=label(reveal,"",15,12,730,40,24)
local revealArea=box(reveal,12,60,736,285);revealArea.BackgroundTransparency=1
local results,scenes,models,resultLabels={}, {}, {}, {}
local started,finished=0,false
local displays={}
local world=workspace:WaitForChild("CoinSpeedWorld")
for id,egg in ipairs(Config.Eggs) do
 local zone=egg.World=="neon" and world:WaitForChild("NeonCity") or world
 local stand=zone:WaitForChild("EggStand"..id)
 if id==1 then while not stand:GetAttribute("SunsetReady") do stand:GetAttributeChangedSignal("SunsetReady"):Wait() end end
 local display=stand:WaitForChild("EggDisplay");local size=display:GetExtentsSize()
 displays[id]={model=display,base=display:GetPivot(),radius=math.max(size.X,size.Z)/2}
end
RS:WaitForChild("GameHatched").OnClientEvent:Connect(function(batch,sourceEgg)
 if type(batch)~="table" or #batch<1 or #batch>3 or not displays[sourceEgg] then return end
 for _,result in ipairs(batch) do if not Config.Pets[result.Pet] then return end end
 hide();dismissed=sourceEgg;player:SetAttribute("UIScreen","hatch")
 revealArea:ClearAllChildren();results=batch;scenes={};models={};resultLabels={}
 local width=736/#batch
 for i=1,#batch do
  local x=(i-1)*width
  local scene=viewport(revealArea,x,0,width,202);scenes[i]=scene
  local egg=displays[sourceEgg].model:Clone();egg:ScaleTo(egg:GetScale()*2.8/egg:GetExtentsSize().Y);egg:PivotTo(CFrame.identity);egg.Parent=scene;models[i]=egg
  resultLabels[i]=label(revealArea,"",x+5,205,width-10,75,14)
 end
 started=os.clock();finished=false;busy=started+4.2;revealTitle.Text=#batch==3 and "THREE NEW POSSIBILITIES…" or "A NEW COMPANION AWAITS…";reveal.Visible=true
end)
local scan=0
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera
 if camera then local size=camera.ViewportSize;scale.Scale=math.min(1,(size.X-28)/650,(size.Y-60)/646);revealScale.Scale=math.min(1,(size.X-28)/760,(size.Y-60)/365) end
 scan+=dt
 if scan>.15 then
  scan=0;refresh()
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local nearest,distance
  if root then for id,entry in pairs(displays) do
   local offset=root.Position-entry.base.Position;local d=Vector2.new(offset.X,offset.Z).Magnitude-entry.radius
   if d<(mode=="egg" and eggId==id and 5 or 2.2) and math.abs(offset.Y)<entry.radius*2+4 and (not distance or d<distance) then nearest=id;distance=d end
  end end
  if not nearest then dismissed=nil;if mode=="egg" then hide();dismissed=nil end
  elseif nearest~=dismissed and ((player:GetAttribute("UIScreen") or "")=="" or mode=="egg") then showEgg(nearest) end
 end
 if reveal.Visible then
  local t=os.clock()-started
  if t>=1.5 and not finished then
   finished=true;revealTitle.Text=#results==3 and "TRIPLE HATCH" or "YOU HATCHED"
   for i,result in ipairs(results) do
    models[i]:Destroy();models[i]=PetVisuals.Build(result.Pet);models[i].Parent=scenes[i]
    local def=Config.Pets[result.Pet];local l=resultLabels[i];l.TextColor3=colors[def.Rarity]
    l.Text=string.format("%s\n%s · ×%g\n%s",def.Name,def.Rarity,def.Multiplier,result.Deleted and "AUTO-DELETED" or ("KEPT · OWNED ×"..result.Count))
   end
  end
  for i,m in ipairs(models) do m:PivotTo(CFrame.Angles(0,t<1.5 and t*3 or math.sin(t)*.3,t<1.5 and math.sin(t*25+i)*.12 or 0)) end
  if t>4.1 then reveal.Visible=false;revealArea:ClearAllChildren();models={};player:SetAttribute("UIScreen","") end
 end
end)
