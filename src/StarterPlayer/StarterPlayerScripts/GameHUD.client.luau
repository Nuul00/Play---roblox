-- Кнопки сверху слева (Индекс, Статистика, Настройки), окно статистики, настройки времени суток,
-- всплывающие сообщения сервера. Индекс-книга живёт в PetIndex.client.luau.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local Config=require(ReplicatedStorage:WaitForChild("GameConfig"))
local stats=player:WaitForChild("leaderstats")
local gui=Instance.new("ScreenGui");gui.Name="CoinSprintHUD";gui.ResetOnSpawn=false;gui.DisplayOrder=12;gui.Parent=player:WaitForChild("PlayerGui")
local openIndex=Instance.new("BindableEvent");openIndex.Name="OpenPetIndex";openIndex.Parent=player.PlayerGui

local function stroke(parent,thickness,color)
 local s=Instance.new("UIStroke");s.Thickness=thickness;s.Color=color or Color3.fromRGB(30,30,40);s.Parent=parent;return s
end
local function button(parent,text,size,pos)
 local b=Instance.new("TextButton");b.Size=size;b.Position=pos;b.Text=text;b.Font=Enum.Font.FredokaOne;b.TextSize=18;b.TextColor3=Color3.fromRGB(255,255,255);b.BackgroundColor3=Color3.fromRGB(60,90,110);b.AutoButtonColor=true;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,12);stroke(b,2.5);return b
end

-- Ряд глянцевых плиток внизу по центру (как на референсе) + маленькая кнопка настроек.
local MENU_W,MENU_H,MENU_GAP=76,84,8
local menuGui=Instance.new("ScreenGui");menuGui.Name="CornerMenuHUD";menuGui.ResetOnSpawn=false;menuGui.DisplayOrder=12;menuGui.Parent=player.PlayerGui
local row=Instance.new("Frame");row.Name="MenuButtons";row.BackgroundTransparency=1;row.AnchorPoint=Vector2.new(0.5,1);row.Position=UDim2.new(0.5,0,1,-76);row.Size=UDim2.fromOffset(6*MENU_W+5*MENU_GAP+64,MENU_H);row.Parent=menuGui
local menuScale=Instance.new("UIScale",row)
local menuInk=Color3.fromRGB(35,22,60)
local function tile(order,caption,emoji,top,bottom,small)
 local w,h=small and 46 or MENU_W,small and 46 or MENU_H
 local x=small and 6*MENU_W+5*MENU_GAP+18 or (order-1)*(MENU_W+MENU_GAP)
 local b=Instance.new("TextButton");b.Name=caption;b.Size=UDim2.fromOffset(w,h);b.Position=UDim2.fromOffset(x,small and MENU_H-h or 0);b.Text="";b.AutoButtonColor=false;b.BackgroundColor3=Color3.new(1,1,1);b.Parent=row
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,small and 14 or 18)
 local g=Instance.new("UIGradient");g.Color=ColorSequence.new(top,bottom);g.Rotation=90;g.Parent=b
 stroke(b,3.5,menuInk)
 local gloss=Instance.new("Frame");gloss.BackgroundColor3=Color3.new(1,1,1);gloss.BackgroundTransparency=0.7;gloss.BorderSizePixel=0;gloss.Position=UDim2.fromOffset(4,4);gloss.Size=UDim2.new(1,-8,0.4,0);gloss.Parent=b
 Instance.new("UICorner",gloss).CornerRadius=UDim.new(0,small and 10 or 14)
 local i=Instance.new("TextLabel");i.BackgroundTransparency=1;i.Position=UDim2.new(0,0,0,small and 0 or 4);i.Size=UDim2.new(1,0,small and 1 or 0.62,0);i.Text=emoji;i.TextScaled=true;i.Font=Enum.Font.FredokaOne;i.TextColor3=Color3.new(1,1,1);i.Parent=b
 Instance.new("UIPadding",i).PaddingTop=UDim.new(0,small and 6 or 4);i:FindFirstChildOfClass("UIPadding").PaddingBottom=UDim.new(0,small and 6 or 0)
 if not small then
  local c=Instance.new("TextLabel");c.BackgroundTransparency=1;c.Position=UDim2.new(0,0,0.64,0);c.Size=UDim2.new(1,0,0.3,0);c.Text=caption;c.TextScaled=true;c.Font=Enum.Font.FredokaOne;c.TextColor3=Color3.new(1,1,1);c.Parent=b
  stroke(c,2,menuInk)
  Instance.new("UIPadding",c).PaddingLeft=UDim.new(0,4);c:FindFirstChildOfClass("UIPadding").PaddingRight=UDim.new(0,4)
 end
 local s=Instance.new("UIScale",b)
 b.MouseEnter:Connect(function() TweenService:Create(s,TweenInfo.new(0.12,Enum.EasingStyle.Back),{Scale=1.1}):Play() end)
 b.MouseLeave:Connect(function() TweenService:Create(s,TweenInfo.new(0.12),{Scale=1}):Play() end)
 b.MouseButton1Down:Connect(function() TweenService:Create(s,TweenInfo.new(0.06),{Scale=0.92}):Play() end)
 b.MouseButton1Up:Connect(function() TweenService:Create(s,TweenInfo.new(0.1),{Scale=1.1}):Play() end)
 return b
end
local indexButton=tile(1,"INDEX","📖",Color3.fromRGB(255,200,90),Color3.fromRGB(235,115,35))
local inventoryButton=tile(2,"ITEMS","🎒",Color3.fromRGB(165,240,120),Color3.fromRGB(55,165,70))
local statButton=tile(3,"STATS","📊",Color3.fromRGB(130,215,255),Color3.fromRGB(50,115,235))
local teleportButton=tile(4,"TELEPORT","🌀",Color3.fromRGB(225,130,255),Color3.fromRGB(105,45,215))
local dailyButton=tile(5,"DAILY","🎁",Color3.fromRGB(255,160,195),Color3.fromRGB(215,65,130))
local rebirthButton=tile(6,"REBIRTH","🔄",Color3.fromRGB(255,225,100),Color3.fromRGB(230,150,40))
local settingsButton=tile(7,"SETTINGS","⚙",Color3.fromRGB(205,205,220),Color3.fromRGB(115,115,145),true)
-- Красная точка на DAILY, когда награда готова.
local DailyConfig=require(ReplicatedStorage:WaitForChild("DailyConfig"))
local dot=Instance.new("TextLabel");dot.Size=UDim2.fromOffset(24,24);dot.Position=UDim2.new(1,-14,0,-8);dot.BackgroundColor3=Color3.fromRGB(235,60,70);dot.Text="!";dot.Font=Enum.Font.FredokaOne;dot.TextSize=18;dot.TextColor3=Color3.new(1,1,1);dot.ZIndex=5;dot.Parent=dailyButton
Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0);stroke(dot,2,menuInk)
local dotTimer=0
local function scaleCorner(dt)
 local camera=workspace.CurrentCamera
 if camera then local v=camera.ViewportSize;menuScale.Scale=math.clamp(math.min(v.X/700,v.Y/520),.5,1) end
 dotTimer+=dt
 if dotTimer>1 then dotTimer=0;dot.Visible=DailyConfig.State(player:GetAttribute("DailyDay"),player:GetAttribute("DailyClaimedAt"),workspace:GetServerTimeNow()).Ready and player:GetAttribute("ProfileReady")==true end
end
RunService.RenderStepped:Connect(scaleCorner)
gui.Destroying:Connect(function() menuGui:Destroy() end)
dailyButton.Activated:Connect(function() player:SetAttribute("UIScreen",player:GetAttribute("UIScreen")=="daily" and "" or "daily") end)
teleportButton.Activated:Connect(function() player:SetAttribute("UIScreen",player:GetAttribute("UIScreen")=="teleport" and "" or "teleport") end)
local rebirthToast=Instance.new("BindableEvent")
rebirthButton.Activated:Connect(function() player:SetAttribute("UIScreen",player:GetAttribute("UIScreen")=="rebirth" and "" or "rebirth") end)
local openInventory=Instance.new("BindableEvent");openInventory.Name="OpenInventory";openInventory.Parent=player.PlayerGui

local function window(name,titleText,size)
 local panel=Instance.new("Frame");panel.Name=name;panel.AnchorPoint=Vector2.new(0.5,0.5);panel.Position=UDim2.fromScale(0.5,0.5);panel.Size=size;panel.BackgroundColor3=Color3.fromRGB(28,40,52);panel.Visible=false;panel.Parent=gui
 Instance.new("UICorner",panel).CornerRadius=UDim.new(0,20);stroke(panel,4)
 local s=Instance.new("UIScale",panel)
 local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-60,0,48);title.Position=UDim2.fromOffset(16,8);title.Text=titleText;title.Font=Enum.Font.FredokaOne;title.TextSize=26;title.TextColor3=Color3.fromRGB(255,230,160);title.BackgroundTransparency=1;title.Parent=panel;stroke(title,2)
 local close=button(panel,"×",UDim2.fromOffset(38,38),UDim2.new(1,-50,0,12));close.BackgroundColor3=Color3.fromRGB(220,70,70);close.TextSize=26;close.Modal=true
 return panel,s,close
end

-- Статистика.
local panel,scale,closeStats=window("Statistics","YOUR STATISTICS",UDim2.fromOffset(420,405))
local content=Instance.new("TextLabel");content.Position=UDim2.fromOffset(26,65);content.Size=UDim2.fromOffset(370,255);content.TextXAlignment=Enum.TextXAlignment.Left;content.TextYAlignment=Enum.TextYAlignment.Top;content.Font=Enum.Font.GothamMedium;content.TextSize=17;content.TextColor3=Color3.fromRGB(224,238,225);content.BackgroundTransparency=1;content.Parent=panel
local range=button(panel,"Magnet range: OFF",UDim2.fromOffset(368,38),UDim2.fromOffset(26,332))
player:SetAttribute("ShowMagnetRange",false)
range.Activated:Connect(function() local visible=not player:GetAttribute("ShowMagnetRange");player:SetAttribute("ShowMagnetRange",visible);range.Text="Magnet range: "..(visible and "ON" or "OFF") end)

-- Настройки: время суток меняется только у этого игрока.
local settings,settingsScale,closeSettings=window("Settings","SETTINGS",UDim2.fromOffset(420,250))
local timeTitle=Instance.new("TextLabel");timeTitle.BackgroundTransparency=1;timeTitle.Position=UDim2.fromOffset(20,70);timeTitle.Size=UDim2.fromOffset(380,30);timeTitle.Text="Time of day";timeTitle.Font=Enum.Font.FredokaOne;timeTitle.TextSize=20;timeTitle.TextColor3=Color3.new(1,1,1);timeTitle.TextXAlignment=Enum.TextXAlignment.Left;timeTitle.Parent=settings
local modes={{"Day","☀ DAY",Color3.fromRGB(110,190,255)},{"Evening","🌇 EVENING",Color3.fromRGB(245,140,80)},{"Night","🌙 NIGHT",Color3.fromRGB(80,70,170)}}
local modeButtons,modeStrokes={},{}
local skies=ReplicatedStorage:FindFirstChild("WorldSkies")
local serverSky=Lighting:FindFirstChildOfClass("Sky")
local localSky
local defaults={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,OutdoorAmbient=Lighting.OutdoorAmbient,Ambient=Lighting.Ambient}
local function applyTime(mode)
 player:SetAttribute("TimeOfDay",mode)
 if localSky then localSky:Destroy();localSky=nil end
 if serverSky then serverSky.Parent=Lighting end
 if mode=="Day" then
  if serverSky then serverSky.Parent=nil end
  Lighting.ClockTime=13;Lighting.Brightness=2.8;Lighting.OutdoorAmbient=Color3.fromRGB(150,150,155);Lighting.Ambient=Color3.fromRGB(120,120,125)
 elseif mode=="Night" then
  local night=skies and skies:FindFirstChild("Neon District")
  if night then
   if serverSky then serverSky.Parent=nil end
   localSky=night:Clone();localSky.Parent=Lighting
  end
  Lighting.ClockTime=0.5;Lighting.Brightness=1.2;Lighting.OutdoorAmbient=Color3.fromRGB(70,80,130);Lighting.Ambient=Color3.fromRGB(60,65,100)
 else
  Lighting.ClockTime=defaults.ClockTime;Lighting.Brightness=defaults.Brightness;Lighting.OutdoorAmbient=defaults.OutdoorAmbient;Lighting.Ambient=defaults.Ambient
  if math.abs(defaults.ClockTime-14)<0.5 then Lighting.ClockTime=17.6 end
 end
 for name,s in pairs(modeStrokes) do s.Thickness=name==mode and 4 or 2.5;s.Color=name==mode and Color3.fromRGB(255,240,120) or Color3.fromRGB(30,30,40) end
end
for i,m in ipairs(modes) do
 local b=button(settings,m[2],UDim2.fromOffset(120,70),UDim2.fromOffset(20+(i-1)*130,110));b.BackgroundColor3=m[3];b.TextSize=17
 modeStrokes[m[1]]=b:FindFirstChildOfClass("UIStroke")
 modeButtons[m[1]]=b
 b.Activated:Connect(function() applyTime(m[1]) end)
end
local hint=Instance.new("TextLabel");hint.BackgroundTransparency=1;hint.Position=UDim2.fromOffset(20,190);hint.Size=UDim2.fromOffset(380,40);hint.TextWrapped=true;hint.Text="Only changes what you see. Street lamps glow at night.";hint.Font=Enum.Font.Gotham;hint.TextSize=14;hint.TextColor3=Color3.fromRGB(200,210,220);hint.Parent=settings
applyTime("Evening")

local screens={stats=panel,settings=settings}
local function hideAll()
 for _,p in pairs(screens) do p.Visible=false end
 local current=player:GetAttribute("UIScreen")
 if current=="stats" or current=="settings" then player:SetAttribute("UIScreen","") end
end
local function toggle(name)
 local p=screens[name]
 if p.Visible then hideAll() else hideAll();player:SetAttribute("UIScreen",name);p.Visible=true end
end
closeStats.Activated:Connect(hideAll);closeSettings.Activated:Connect(hideAll)
statButton.Activated:Connect(function() toggle("stats") end)
settingsButton.Activated:Connect(function() toggle("settings") end)
indexButton.Activated:Connect(function() hideAll();openIndex:Fire() end)
inventoryButton.Activated:Connect(function() hideAll();openInventory:Fire() end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function()
 local current=player:GetAttribute("UIScreen")
 for name,p in pairs(screens) do if current~=name then p.Visible=false end end
end)
local function update()
 local pet=Config.Pets[player:GetAttribute("PetLevel") or 0]
 local owned=0
 for i=1,#Config.Pets do if (player:GetAttribute("PetOwned"..i) or 0)>0 then owned=owned+1 end end
 content.Text=string.format("Coins                  %g\nSpeed                  %d  (level %d)\nMagnet radius      %.2f\nIncome                 x%g\nDouble coin        %g%%\nRebirths              %d\nBest pet               %s\nPet bonus             x%g\nEggs opened        %d\nCoins picked up   %d\nPet index              %d / %d\n%s",stats.Coins.Value,Config.GetWalkSpeed(stats.SpeedLevel.Value),stats.SpeedLevel.Value,Config.GetMagnetRadius(player:GetAttribute("MagnetLevel") or 0),Config.GetIncomeMultiplier(player:GetAttribute("IncomeLevel") or 0),math.floor(Config.GetDoubleChance(player:GetAttribute("DoubleLevel") or 0)*1000+0.5)/10,player:GetAttribute("Rebirths") or 0,pet and pet.Name or "None",Config.GetPetMultiplier(player:GetAttribute("PetLevel") or 0),player:GetAttribute("EggsOpened") or 0,player:GetAttribute("CoinsCollected") or 0,owned,#Config.Pets,player:GetAttribute("SaveStatus") or "LOADING PROFILE")
end
stats.Coins.Changed:Connect(update);stats.SpeedLevel.Changed:Connect(update);player.AttributeChanged:Connect(update);update()
local toast=Instance.new("TextLabel");toast.AnchorPoint=Vector2.new(0.5,1);toast.Position=UDim2.new(0.5,0,1,-190);toast.Size=UDim2.new(0.7,0,0,38);toast.BackgroundColor3=Color3.fromRGB(30,47,50);toast.BackgroundTransparency=0.08;toast.TextColor3=Color3.fromRGB(243,235,207);toast.TextWrapped=true;toast.Font=Enum.Font.GothamBold;toast.TextSize=16;toast.Visible=false;toast.Parent=gui;Instance.new("UICorner",toast).CornerRadius=UDim.new(0,10)
local version=0
local function showToast(message) version=version+1;local current=version;toast.Text=message;toast.Visible=true;task.delay(2.8,function() if version==current then toast.Visible=false end end) end
rebirthToast.Event:Connect(function() showToast("Rebirth is coming soon!") end)
ReplicatedStorage:WaitForChild("GameFeedback").OnClientEvent:Connect(function(message,success) if success then return end version=version+1;local current=version;toast.Text=message;toast.Visible=true;task.delay(2.8,function() if version==current then toast.Visible=false end end) end)
local hidden=false
local previous=true
RunService.RenderStepped:Connect(function()
 local camera=workspace.CurrentCamera
 if camera then
  local s=math.clamp(math.min(camera.ViewportSize.X/450,camera.ViewportSize.Y/460),0.3,1)
  scale.Scale=s;settingsScale.Scale=s
 end
 local modal=(player:GetAttribute("UIScreen") or "")~=""
 if modal and not hidden then local ok,value=pcall(function() return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) end);previous=not ok or value;pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end);hidden=true
 elseif not modal and hidden then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,previous) end);hidden=false end
end)
gui.Destroying:Connect(function() if hidden then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,previous) end) end end)
