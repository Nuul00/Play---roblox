-- Optional temporary Studio gallery for visual review. Not part of StarterPlayer.
local RS=game.ReplicatedStorage
local C=require(RS.GameConfig)
local P=require(RS.PetVisuals)
local N=require(RS.NeonVisuals)
local gui=Instance.new("ScreenGui");gui.Name="NeonVisualReview";gui.DisplayOrder=500;gui.Parent=game.Players.LocalPlayer.PlayerGui
local panel=Instance.new("Frame",gui);panel.Size=UDim2.fromOffset(1200,620);panel.Position=UDim2.fromScale(.5,.5);panel.AnchorPoint=Vector2.new(.5,.5);panel.BackgroundColor3=Color3.fromRGB(15,17,35)
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,18)
local scale=Instance.new("UIScale",panel)
local function resize() local v=workspace.CurrentCamera.ViewportSize;scale.Scale=math.min(1,(v.X-20)/1200,(v.Y-20)/620) end
resize();workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
local content=Instance.new("Frame",panel);content.Position=UDim2.fromOffset(10,66);content.Size=UDim2.fromOffset(1180,544);content.BackgroundTransparency=1
local function label(parent,s,x,y,w,h,color)
 local l=Instance.new("TextLabel",parent);l.Size=UDim2.fromOffset(w,h);l.Position=UDim2.fromOffset(x,y);l.BackgroundTransparency=1;l.Font=Enum.Font.GothamBold;l.TextSize=14;l.TextWrapped=true;l.TextColor3=color or Color3.new(1,1,1);l.Text=s;return l
end
local function view(parent,model,x,y,w,h,egg)
 local v=Instance.new("ViewportFrame",parent);v.Size=UDim2.fromOffset(w,h);v.Position=UDim2.fromOffset(x,y);v.BackgroundColor3=Color3.fromRGB(24,26,49);v.Ambient=Color3.fromRGB(180,182,215);v.LightColor=Color3.fromRGB(240,225,255);v.LightDirection=Vector3.new(-1,-1,-2)
 Instance.new("UICorner",v).CornerRadius=UDim.new(0,12)
 local scene=Instance.new("WorldModel",v);model.Parent=scene
 local cam=Instance.new("Camera",v);cam.FieldOfView=38;cam.CFrame=CFrame.lookAt(egg and Vector3.new(9,3,-15) or Vector3.new(3,1.7,-5.8),Vector3.zero);v.CurrentCamera=cam
end
local function show(id)
 content:ClearAllChildren();local egg=C.Eggs[id]
 view(content,N.BuildEgg(({[4]="Disco",[5]="Tech",[6]="City"})[id]),0,0,230,465,true)
 label(content,egg.Name.." · "..egg.Cost.." coins",0,470,230,50,egg.Color)
 for i,e in ipairs(egg.Pool) do
  local x=244+(i-1)%5*186;local y=math.floor((i-1)/5)*265
  view(content,P.Build(e.Pet),x,y,178,198,false)
  label(content,C.Pets[e.Pet].Name,x,y+199,178,27)
  label(content,C.Pets[e.Pet].Rarity.." · "..e.Chance.."%",x,y+227,178,22,egg.Color)
 end
end
for id=4,6 do
 local b=Instance.new("TextButton",panel);b.Size=UDim2.fromOffset(335,42);b.Position=UDim2.fromOffset(14+(id-4)*344,12);b.BackgroundColor3=C.Eggs[id].Color;b.Text=C.Eggs[id].Name;b.Font=Enum.Font.GothamBold;b.TextSize=19;b.TextColor3=Color3.fromRGB(18,20,40);Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
 b.Activated:Connect(function() show(id) end)
end
local close=Instance.new("TextButton",panel);close.Size=UDim2.fromOffset(110,42);close.Position=UDim2.fromOffset(1076,12);close.Text="CLOSE";close.Activated:Connect(function() gui:Destroy() end)
show(4)
