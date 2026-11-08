-- Кнопки сверху слева (Индекс, Статистика, Настройки), окно статистики, настройки времени суток,
local NumberFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberFormat"))
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

-- Статистика: карточки в три раздела (прогресс / сила / рекорды), у каждой иконка, подпись и крупное значение.
local rgb=Color3.fromRGB
local INK=rgb(35,22,60)
local panel,scale,closeStats=window("Statistics","",UDim2.fromOffset(600,420))
panel:SetAttribute("NoTheme",true);panel.BackgroundColor3=Color3.new(1,1,1) -- свой фиолетовый стиль, как у DAILY
do
 local g=Instance.new("UIGradient");g.Rotation=90;g.Color=ColorSequence.new(rgb(62,36,130),rgb(20,12,52));g.Parent=panel
 panel:FindFirstChildOfClass("UIStroke").Color=INK
 local head=Instance.new("Frame");head.Name="TitlePill";head.AnchorPoint=Vector2.new(0.5,0);head.Position=UDim2.new(0.5,0,0,-26);head.Size=UDim2.fromOffset(330,58);head.BackgroundColor3=rgb(80,160,255);head.Parent=panel
 Instance.new("UICorner",head).CornerRadius=UDim.new(0,18);stroke(head,4,INK)
 local hg=Instance.new("UIGradient");hg.Rotation=90;hg.Color=ColorSequence.new(rgb(140,215,255),rgb(50,115,235));hg.Parent=head
 local ht=Instance.new("TextLabel");ht.BackgroundTransparency=1;ht.Size=UDim2.fromScale(1,1);ht.Text="📊 YOUR STATS";ht.Font=Enum.Font.FredokaOne;ht.TextSize=30;ht.TextColor3=Color3.new(1,1,1);ht.Parent=head;stroke(ht,2.5,INK)
end
local statCells={}
local SECTIONS={
 {"PROGRESS",rgb(255,205,80),{{"coins","💰","Coins"},{"rebirths","🔄","Rebirths"},{"index","📖","Pet index"},{"eggs","🥚","Eggs"}}},
 {"POWER",rgb(120,220,255),{{"speed","⚡","Speed"},{"magnet","🧲","Magnet"},{"income","💵","Income"},{"double","🎲","Double coin"}}},
 {"RECORDS",rgb(255,140,200),{{"pet","🐾","Best pet"},{"combo","🔥","Best combo"},{"rush","🏆","Rush best"},{"picked","✨","Coins picked"}}},
}
local CW,CH,GX=132,64,8
for si,sec in ipairs(SECTIONS) do
 local y=50+(si-1)*102
 local cap=Instance.new("TextLabel");cap.BackgroundTransparency=1;cap.Position=UDim2.fromOffset(24,y);cap.Size=UDim2.fromOffset(300,22);cap.Text=sec[1];cap.Font=Enum.Font.FredokaOne;cap.TextSize=18;cap.TextColor3=sec[2];cap.TextXAlignment=Enum.TextXAlignment.Left;cap.Parent=panel;stroke(cap,2,INK)
 for ci,c in ipairs(sec[3]) do
  local card=Instance.new("Frame");card.Name="Stat_"..c[1];card.Position=UDim2.fromOffset(24+(ci-1)*(CW+GX),y+26);card.Size=UDim2.fromOffset(CW,CH);card.BackgroundColor3=rgb(24,16,52);card.BackgroundTransparency=0.15;card.Parent=panel
  Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
  local cs=stroke(card,2.5,sec[2]);cs.Transparency=0.25;cs.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
  local badge=Instance.new("TextLabel");badge.Position=UDim2.fromOffset(7,12);badge.Size=UDim2.fromOffset(40,40);badge.BackgroundColor3=sec[2];badge.BackgroundTransparency=0.55;badge.Text=c[2];badge.TextSize=24;badge.Font=Enum.Font.FredokaOne;badge.Parent=card
  Instance.new("UICorner",badge).CornerRadius=UDim.new(1,0)
  local lab=Instance.new("TextLabel");lab.BackgroundTransparency=1;lab.Position=UDim2.fromOffset(52,8);lab.Size=UDim2.fromOffset(CW-58,18);lab.Text=c[3];lab.Font=Enum.Font.FredokaOne;lab.TextSize=14;lab.TextColor3=rgb(200,190,235);lab.TextXAlignment=Enum.TextXAlignment.Left;lab.TextTruncate=Enum.TextTruncate.AtEnd;lab.Parent=card
  local val=Instance.new("TextLabel");val.BackgroundTransparency=1;val.Position=UDim2.fromOffset(52,26);val.Size=UDim2.fromOffset(CW-58,30);val.Text="-";val.Font=Enum.Font.FredokaOne;val.TextScaled=true;val.TextColor3=Color3.new(1,1,1);val.TextXAlignment=Enum.TextXAlignment.Left;val.Parent=card;stroke(val,2,INK)
  local vc=Instance.new("UITextSizeConstraint");vc.MaxTextSize=24;vc.Parent=val
  statCells[c[1]]=val
 end
end
local content=Instance.new("TextLabel");content.Name="SaveStatus";content.BackgroundTransparency=1;content.Position=UDim2.fromOffset(28,370);content.Size=UDim2.fromOffset(250,24);content.Font=Enum.Font.FredokaOne;content.TextSize=14;content.TextColor3=rgb(170,160,210);content.TextXAlignment=Enum.TextXAlignment.Left;content.Parent=panel
local range=button(panel,"🧲 Show magnet range: OFF",UDim2.fromOffset(270,40),UDim2.fromOffset(306,362));range.BackgroundColor3=rgb(90,70,170);range.TextSize=17;range:FindFirstChildOfClass("UIStroke").Color=INK;range:FindFirstChildOfClass("UIStroke").ApplyStrokeMode=Enum.ApplyStrokeMode.Border
player:SetAttribute("ShowMagnetRange",false)
range.Activated:Connect(function() local visible=not player:GetAttribute("ShowMagnetRange");player:SetAttribute("ShowMagnetRange",visible);range.Text="🧲 Show magnet range: "..(visible and "ON" or "OFF");range.BackgroundColor3=visible and rgb(70,170,90) or rgb(90,70,170) end)

-- Настройки: время суток меняется только у этого игрока.
local settings,settingsScale,closeSettings=window("Settings","",UDim2.fromOffset(420,250))
-- оформление как у остальных окон: фиолетовый градиент и плашка-заголовок
do
 settings:SetAttribute("NoTheme",true);settings.BackgroundColor3=Color3.new(1,1,1)
 local g=Instance.new("UIGradient");g.Rotation=90;g.Color=ColorSequence.new(rgb(62,36,130),rgb(20,12,52));g.Parent=settings
 settings:FindFirstChildOfClass("UIStroke").Color=INK
 local head=Instance.new("Frame");head.AnchorPoint=Vector2.new(0.5,0);head.Position=UDim2.new(0.5,0,0,-26);head.Size=UDim2.fromOffset(260,56);head.BackgroundColor3=Color3.new(1,1,1);head.Parent=settings
 Instance.new("UICorner",head).CornerRadius=UDim.new(0,18);stroke(head,4,INK)
 local hg=Instance.new("UIGradient");hg.Rotation=90;hg.Color=ColorSequence.new(rgb(215,215,235),rgb(115,110,160));hg.Parent=head
 local ht=Instance.new("TextLabel");ht.BackgroundTransparency=1;ht.Size=UDim2.fromScale(1,1);ht.Text="⚙ SETTINGS";ht.Font=Enum.Font.FredokaOne;ht.TextSize=28;ht.TextColor3=Color3.new(1,1,1);ht.Parent=head;stroke(ht,2.5,INK)
end
local timeTitle=Instance.new("TextLabel");timeTitle.BackgroundTransparency=1;timeTitle.Position=UDim2.fromOffset(20,70);timeTitle.Size=UDim2.fromOffset(380,30);timeTitle.Text="Time of day";timeTitle.Font=Enum.Font.FredokaOne;timeTitle.TextSize=20;timeTitle.TextColor3=Color3.new(1,1,1);timeTitle.TextXAlignment=Enum.TextXAlignment.Left;timeTitle.Parent=settings
local modes={{"Day","☀ DAY",Color3.fromRGB(110,190,255)},{"Evening","🌇 EVENING",Color3.fromRGB(245,140,80)},{"Night","🌙 NIGHT",Color3.fromRGB(80,70,170)}}
local modeButtons,modeStrokes={},{}
local skies=ReplicatedStorage:FindFirstChild("WorldSkies")
local serverSky=Lighting:FindFirstChildOfClass("Sky")
local localSky
-- 2026-11 (фидбэк «пересвет»): окружающий свет плейса (128 серого) заливал картинку — берём мягче
local defaults={Brightness=math.min(Lighting.Brightness,1.75),ClockTime=Lighting.ClockTime,OutdoorAmbient=Color3.fromRGB(110,110,120),Ambient=Color3.fromRGB(72,72,82)}
local function applyTime(mode)
 player:SetAttribute("TimeOfDay",mode)
 if localSky then localSky:Destroy();localSky=nil end
 if serverSky then serverSky.Parent=Lighting end
 if mode=="Day" then
  if serverSky then serverSky.Parent=nil end
  Lighting.ClockTime=13;Lighting.Brightness=2.2;Lighting.OutdoorAmbient=Color3.fromRGB(125,125,132);Lighting.Ambient=Color3.fromRGB(85,85,92) -- 2026-11: было 2.8/150/120 — пересвет
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
 if modeStrokes[m[1]] then modeStrokes[m[1]].ApplyStrokeMode=Enum.ApplyStrokeMode.Border end -- рамка выбранного режима — по краю кнопки, а не вокруг букв
 modeButtons[m[1]]=b
 b.Activated:Connect(function() applyTime(m[1]) end)
end
local hint=Instance.new("TextLabel");hint.BackgroundTransparency=1;hint.Position=UDim2.fromOffset(20,184);hint.Size=UDim2.fromOffset(380,26);hint.TextWrapped=true;hint.Text="Only changes what you see. Street lamps glow at night.";hint.Font=Enum.Font.Gotham;hint.TextSize=14;hint.TextColor3=Color3.fromRGB(200,210,220);hint.Parent=settings
applyTime("Evening")
-- Музыка миров (WorldAmbience): вкл/выкл только у этого игрока.
local music=button(settings,"🎵 Music: ON",UDim2.fromOffset(380,34),UDim2.fromOffset(20,214));music.BackgroundColor3=Color3.fromRGB(90,160,110)
-- сторона вкладки зелий: для левшей и правшей (сохраняется с профилем)
settings.Size=UDim2.fromOffset(420,460)
-- ивенты миров (LocalEventsFX, сохраняется): баннер полный/маленький/скрыт, где он, метки бонусов
local GA=ReplicatedStorage:WaitForChild("GameAction")
local function cycle(attr,kind,list,default)
 local cur=player:GetAttribute(attr) or default
 local i=table.find(list,cur) or 1
 local nxt=list[i%#list+1]
 player:SetAttribute(attr,nxt);GA:FireServer(kind,nxt)
end
local evBtn=button(settings,"",UDim2.fromOffset(380,34),UDim2.fromOffset(20,292));evBtn.BackgroundColor3=Color3.fromRGB(220,100,170)
local posBtn=button(settings,"",UDim2.fromOffset(380,34),UDim2.fromOffset(20,331));posBtn.BackgroundColor3=Color3.fromRGB(200,110,60)
local mrkBtn=button(settings,"",UDim2.fromOffset(380,34),UDim2.fromOffset(20,370));mrkBtn.BackgroundColor3=Color3.fromRGB(80,150,200)
local pillBtn=button(settings,"",UDim2.fromOffset(380,34),UDim2.fromOffset(20,409));pillBtn.BackgroundColor3=Color3.fromRGB(190,150,50)
local function evText()
 local m=player:GetAttribute("Save_EventBanner") or "full"
 evBtn.Text="🌸 Event banner: "..(m=="mini" and "SMALL" or m=="hidden" and "HIDDEN" or "FULL")
 local p=player:GetAttribute("Save_EventPos") or "top"
 posBtn.Text="📍 Event banner place: "..(p=="bottom" and "BOTTOM" or p=="right" and "RIGHT" or "TOP")
 mrkBtn.Text="🎯 Event pickup markers: "..(player:GetAttribute("Save_EventMarkers")=="off" and "OFF" or "ON")
 pillBtn.Text="⏳ Server event bar: "..(player:GetAttribute("Save_EventPill")=="off" and "OFF" or "ON")
end
evText()
for _,a in ipairs({"Save_EventBanner","Save_EventPos","Save_EventMarkers","Save_EventPill"}) do player:GetAttributeChangedSignal(a):Connect(evText) end
evBtn.Activated:Connect(function() cycle("Save_EventBanner","eventbanner",{"full","mini","hidden"},"full") end)
posBtn.Activated:Connect(function() cycle("Save_EventPos","eventpos",{"top","bottom","right"},"top") end)
mrkBtn.Activated:Connect(function() cycle("Save_EventMarkers","eventmarkers",{"on","off"},"on") end)
pillBtn.Activated:Connect(function() cycle("Save_EventPill","eventpill",{"on","off"},"on") end)
local sideBtn=button(settings,"🧪 Potion tab: RIGHT",UDim2.fromOffset(380,34),UDim2.fromOffset(20,253));sideBtn.BackgroundColor3=Color3.fromRGB(120,80,200)
local function sideText() sideBtn.Text="🧪 Potion tab: "..(player:GetAttribute("Save_PotionSide")=="L" and "LEFT" or "RIGHT") end
sideText();player:GetAttributeChangedSignal("Save_PotionSide"):Connect(sideText)
sideBtn.Activated:Connect(function()
 local new=player:GetAttribute("Save_PotionSide")=="L" and "R" or "L"
 player:SetAttribute("Save_PotionSide",new) -- сразу у себя, сервер сохранит
 ReplicatedStorage:WaitForChild("GameAction"):FireServer("potionside",new)
end)
music.Activated:Connect(function()
 local off=not player:GetAttribute("MusicOff");player:SetAttribute("MusicOff",off)
 music.Text=off and "🔇 Music: OFF" or "🎵 Music: ON";music.BackgroundColor3=off and Color3.fromRGB(150,80,80) or Color3.fromRGB(90,160,110)
end)
-- Качество графики (2026-11): AUTO / LOW / MEDIUM / ULTRA — применяет GraphicsQuality.client сразу
local gfxBtn=button(settings,"",UDim2.fromOffset(380,34),UDim2.fromOffset(20,448))
local GFX_NAMES={auto="AUTO",low="LOW",medium="MEDIUM",ultra="ULTRA"}
local function gfxText() gfxBtn.Text="🖥 Graphics: "..(GFX_NAMES[player:GetAttribute("Save_Graphics") or "auto"] or "AUTO") end
-- под строкой — что именно включено на этом уровне (текст отдаёт GraphicsQuality.client)
local gfxInfo=Instance.new("TextLabel");gfxInfo.BackgroundTransparency=1;gfxInfo.Position=UDim2.fromOffset(20,484);gfxInfo.Size=UDim2.fromOffset(380,22);gfxInfo.Font=Enum.Font.GothamBold;gfxInfo.TextSize=13;gfxInfo.TextColor3=Color3.fromRGB(200,210,235);gfxInfo.TextWrapped=true;gfxInfo.Parent=settings
local function gfxInfoText()
 local f=player.PlayerGui:FindFirstChild("GraphicsInfo")
 local ok,txt=pcall(function() return f and f:Invoke() end)
 gfxInfo.Text=ok and txt or ""
end
gfxText();player:GetAttributeChangedSignal("Save_Graphics"):Connect(function() gfxText();task.delay(0.1,gfxInfoText) end)
task.delay(4,gfxInfoText)
gfxBtn.Activated:Connect(function() cycle("Save_Graphics","graphics",{"auto","low","medium","ultra"},"auto") end)
-- Стрелка квестов (2026-11, фидбэк: «постоянно за тобой бегает»): шевроны к цели и значок над ней
local qaBtn=button(settings,"",UDim2.fromOffset(380,34),UDim2.fromOffset(20,512))
local function qaText() qaBtn.Text="🧭 Quest arrow: "..(player:GetAttribute("Save_QuestArrow")=="off" and "OFF" or "ON") end
qaText();player:GetAttributeChangedSignal("Save_QuestArrow"):Connect(qaText)
qaBtn.Activated:Connect(function() cycle("Save_QuestArrow","questarrow",{"on","off"},"on") end)
settings.Size=UDim2.fromOffset(420,560)
-- Единый вид переключателей (фидбэк 2026-11: «кнопки разноцветные»): тёмная строка, слева название,
-- справа плашка со значением — зелёная ON, серая OFF/HIDDEN, фиолетовая для остальных вариантов.
do
 local ROW=rgb(52,34,110)
 local function styleRow(b)
  b.BackgroundColor3=ROW;b.AutoButtonColor=true;b.TextTransparency=1
  local st=b:FindFirstChildOfClass("UIStroke");if st then st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;st.Color=INK;st.Thickness=2 end
  local name=Instance.new("TextLabel");name.BackgroundTransparency=1;name.Position=UDim2.fromOffset(14,0);name.Size=UDim2.new(1,-150,1,0);name.Font=Enum.Font.FredokaOne;name.TextSize=17;name.TextColor3=Color3.new(1,1,1);name.TextXAlignment=Enum.TextXAlignment.Left;name.Parent=b
  local pill=Instance.new("Frame");pill.AnchorPoint=Vector2.new(1,0.5);pill.Position=UDim2.new(1,-8,0.5,0);pill.Size=UDim2.fromOffset(112,24);pill.Parent=b
  Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0);stroke(pill,2,INK)
  local val=Instance.new("TextLabel");val.BackgroundTransparency=1;val.Size=UDim2.fromScale(1,1);val.Font=Enum.Font.FredokaOne;val.TextSize=15;val.TextColor3=Color3.new(1,1,1);val.Parent=pill
  local function sync()
   local left,right=string.match(b.Text,"^(.-):%s*(.+)$")
   name.Text=left or b.Text;val.Text=right or ""
   pill.Visible=right~=nil
   pill.BackgroundColor3=(right=="ON" and rgb(70,180,95)) or ((right=="OFF" or right=="HIDDEN") and rgb(110,105,135)) or rgb(150,95,240)
   if b.BackgroundColor3~=ROW then b.BackgroundColor3=ROW end
  end
  sync();b:GetPropertyChangedSignal("Text"):Connect(sync);b:GetPropertyChangedSignal("BackgroundColor3"):Connect(sync)
 end
 for _,b in ipairs({music,sideBtn,evBtn,posBtn,mrkBtn,pillBtn,gfxBtn,qaBtn}) do styleRow(b) end
end

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
 local total=0
 for i=1,Config.MaxPetId do if not Config.Pets[i] then continue end
  if not Config.Pets[i].Super then
   total+=1
   for _,k in ipairs({"PetOwned","PetGold","PetDiamond","PetRainbow","PetShiny"}) do if (player:GetAttribute(k..i) or 0)>0 then owned=owned+1 break end end
  end
 end
 local function ab(n) return NumberFormat.Short(n) end
 local v={
  coins=ab(stats.Coins.Value),
  rebirths=tostring(player:GetAttribute("Rebirths") or 0),
  index=owned.." / "..total,
  eggs=ab(player:GetAttribute("EggsOpened") or 0),
  speed=string.format("%g · lvl %d",Config.GetWalkSpeed(stats.SpeedLevel.Value),stats.SpeedLevel.Value),
  magnet=string.format("%.1f",(player:GetAttribute("MagnetRadius") or Config.GetMagnetRadius(player:GetAttribute("MagnetLevel") or 0))),
  income="x"..ab(Config.GetIncomeMultiplier(player:GetAttribute("IncomeLevel") or 0)*(player:GetAttribute("PetBonus") or 1)),
  double=string.format("%g%%",math.floor(Config.GetDoubleChance(player:GetAttribute("DoubleLevel") or 0)*1000+0.5)/10),
  pet=pet and pet.Name or "None",
  combo="x"..tostring(player:GetAttribute("Save_BestCombo") or 0),
  rush=ab(player:GetAttribute("Save_RushBest") or 0),
  picked=ab(player:GetAttribute("CoinsCollected") or 0),
 }
 for k,t in pairs(v) do if statCells[k] then statCells[k].Text=t end end
 local s=player:GetAttribute("SaveStatus") or "LOADING PROFILE"
 content.Text="💾 "..s
end
-- Панель статистики пересобираем, только когда она открыта (монеты меняются десятки раз в секунду).
local statsPanel=screens and screens.stats
local function updateIfShown() if not statsPanel or statsPanel.Visible then update() end end
stats.Coins.Changed:Connect(updateIfShown);stats.SpeedLevel.Changed:Connect(updateIfShown);player.AttributeChanged:Connect(updateIfShown);update()
if statsPanel then statsPanel:GetPropertyChangedSignal("Visible"):Connect(function() if statsPanel.Visible then update() end end) end
-- Сообщения сервера (2026-11, фидбэк: жёлтая полоса на всю ширину лезла поверх окон):
-- компактная карточка выезжает справа, над нижними кнопками. Слева цветная полоса:
-- золотая — успех (титул, награда, покупка), красная — отказ/ошибка. Идут по очереди.
local TweenService=game:GetService("TweenService")
local toastGui=Instance.new("ScreenGui");toastGui.Name="ToastHUD";toastGui.ResetOnSpawn=false;toastGui.DisplayOrder=60;toastGui.IgnoreGuiInset=false;toastGui.Parent=gui.Parent
local toast=Instance.new("Frame");toast.AnchorPoint=Vector2.new(1,1);toast.Position=UDim2.new(1,400,1,-120);toast.Size=UDim2.fromOffset(340,0);toast.AutomaticSize=Enum.AutomaticSize.Y;toast.BackgroundColor3=Color3.fromRGB(24,22,36);toast.BackgroundTransparency=0.05;toast.Visible=false;toast.Parent=toastGui
Instance.new("UICorner",toast).CornerRadius=UDim.new(0,12)
local toastStroke=Instance.new("UIStroke");toastStroke.Thickness=2;toastStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;toastStroke.Parent=toast
local accent=Instance.new("Frame");accent.Position=UDim2.fromOffset(7,8);accent.Size=UDim2.new(0,4,1,-16);accent.BorderSizePixel=0;accent.Parent=toast -- внутри карточки, не выпирает за скругление
Instance.new("UICorner",accent).CornerRadius=UDim.new(1,0)
local toastText=Instance.new("TextLabel");toastText.BackgroundTransparency=1;toastText.Position=UDim2.fromOffset(20,0);toastText.Size=UDim2.new(1,-30,0,0);toastText.AutomaticSize=Enum.AutomaticSize.Y;toastText.TextWrapped=true;toastText.TextXAlignment=Enum.TextXAlignment.Left;toastText.Font=Enum.Font.GothamBold;toastText.TextSize=15;toastText.TextColor3=Color3.fromRGB(245,240,230);toastText.Parent=toast
local tp=Instance.new("UIPadding");tp.PaddingTop=UDim.new(0,10);tp.PaddingBottom=UDim.new(0,10);tp.Parent=toastText
local toastScale=Instance.new("UIScale");toastScale.Parent=toast
local queue,showing={},false
local SHOWN=UDim2.new(1,-16,1,-120);local HIDDEN=UDim2.new(1,400,1,-120)
local function nextToast()
 if showing or #queue==0 then return end
 showing=true
 local item=table.remove(queue,1)
 toastText.Text=item.text
 local c=item.ok and Color3.fromRGB(255,196,60) or Color3.fromRGB(235,80,95)
 accent.BackgroundColor3=c;toastStroke.Color=c:Lerp(Color3.new(0,0,0),0.35)
 toast.Position=HIDDEN;toast.Visible=true
 TweenService:Create(toast,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=SHOWN}):Play()
 task.delay(item.ok and 3 or 2.4,function()
  local tw=TweenService:Create(toast,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=HIDDEN});tw:Play();tw.Completed:Wait()
  toast.Visible=false;showing=false;nextToast()
 end)
end
local function push(message,ok)
 -- одинаковые подряд не дублируем, очередь не длиннее 3
 local last=queue[#queue];if last and last.text==message then return end
 if #queue>=3 then table.remove(queue,1) end
 table.insert(queue,{text=message,ok=ok});nextToast()
end
ReplicatedStorage:WaitForChild("GameFeedback").OnClientEvent:Connect(function(message,success)
 if type(message)~="string" or string.sub(message,1,7)=="World: " then return end -- о смене мира и так видно
 push(message,success==true)
end)
RunService.RenderStepped:Connect(function()
 local cam=workspace.CurrentCamera;if cam then toastScale.Scale=math.clamp(cam.ViewportSize.X/1100,0.7,1) end
end)
local hidden=false
local previous=true
RunService.RenderStepped:Connect(function()
 local camera=workspace.CurrentCamera
 if camera then
  -- по высоте окна + место под нижние кнопки (STORE/TRAILS) и плашку сверху, иначе нижняя строка уходит под них
  local s=math.clamp(math.min(camera.ViewportSize.X/450,(camera.ViewportSize.Y-240)/settings.Size.Y.Offset),0.3,1)
  settingsScale.Scale=s
  scale.Scale=math.clamp(math.min(camera.ViewportSize.X/640,(camera.ViewportSize.Y-60)/460),0.3,1)
 end
 local modal=(player:GetAttribute("UIScreen") or "")~=""
 if modal and not hidden then local ok,value=pcall(function() return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) end);previous=not ok or value;pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end);hidden=true
 elseif not modal and hidden then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,previous) end);hidden=false end
end)
gui.Destroying:Connect(function() if hidden then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,previous) end) end end)
