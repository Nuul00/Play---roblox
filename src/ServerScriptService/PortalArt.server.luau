-- Visuals only: the original PortalToNeon part and EnterWorld prompt stay intact.
local world=workspace:WaitForChild("CoinSpeedWorld")
while not world:GetAttribute("GroundAligned") do world.AttributeChanged:Wait() end
local gate=world:WaitForChild("PortalToNeon")
local previous=world:FindFirstChild("PortalToNeonArch")
if previous then for _,p in ipairs(previous:GetDescendants()) do if p:IsA("BasePart") then p.Transparency=1 elseif p:IsA("BillboardGui") or p:IsA("SurfaceGui") then p.Enabled=false end end end
for _,ui in ipairs(gate:GetChildren()) do if ui:IsA("BillboardGui") then ui.Enabled=false end end
local art=Instance.new("Model");art.Name="NeonGatewayArt"
local rgb=Color3.fromRGB
local stone=rgb(56,43,85);local edge=rgb(122,91,181);local glow=rgb(163,106,255);local gold=rgb(248,202,115)
local function part(name,size,cf,color,material,shape)
 local p=Instance.new(shape=="wedge" and "WedgePart" or "Part");p.Name=name;p.Size=size;p.CFrame=gate.CFrame*cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 if shape=="ball" then p.Shape=Enum.PartType.Ball end
 p.Parent=art;return p
end
-- Своя 3D-модель арки (ReplicatedStorage/CustomPortals/NeonGate) важнее арки из деталей.
local PortalDecor=require(script.Parent:WaitForChild("PortalDecor"))
local titleY=14.5
if PortalDecor.Template("NeonGate") then
 local height=19
 PortalDecor.Dress(art,"NeonGate",{Name="GateModel",Bottom=(gate.CFrame*CFrame.new(0,-gate.Size.Y/2,0)).Position,Facing=gate.CFrame.LookVector,Yaw=math.pi,Height=height,Glow=glow})
 gate.Transparency=1
 titleY=height-gate.Size.Y/2+2.5
else
for _,side in ipairs({-1,1}) do
 part("Foundation",Vector3.new(3.8,1,5),CFrame.new(side*6.5,-5.5,0),stone,Enum.Material.Slate)
 part("Pillar",Vector3.new(2.6,11,3.8),CFrame.new(side*6.5,.5,0),stone,Enum.Material.Marble)
 for j=0,4 do part("StoneJoint",Vector3.new(2.85,.18,4),CFrame.new(side*6.5,-4+j*2.2,0),edge) end
 part("InnerLight",Vector3.new(.22,11,3.9),CFrame.new(side*5.14,.6,0),glow,Enum.Material.Neon)
 part("Capital",Vector3.new(3.3,.8,4.2),CFrame.new(side*6.5,6,0),edge)
 part("PillarGem",Vector3.new(.8,1.15,.35),CFrame.new(side*6.5,3.2,2.05)*CFrame.Angles(0,0,math.pi/4),gold,Enum.Material.Neon)
end
for j=0,16 do
 local a=math.pi+j/16*math.pi
 local cf=CFrame.new(math.cos(a)*6.5,6-math.sin(a)*4,0)*CFrame.Angles(0,0,-a-math.pi/2)
 part("ArchStone",Vector3.new(1.65,2.4,3.8),cf,j%2==0 and stone or edge,Enum.Material.Marble)
 part("ArchInlay",Vector3.new(.2,1.7,3.95),cf,gold)
 local inner=CFrame.new(math.cos(a)*5.12,6-math.sin(a)*3.15,0)
 part("ArcLight",Vector3.new(1.02,.2,3.95),inner*CFrame.Angles(0,0,-a-math.pi/2),glow,Enum.Material.Neon)
end
local veil=part("PortalVeil",Vector3.new(9.7,12,.12),CFrame.new(0,.3,0),rgb(111,65,222),Enum.Material.Neon);veil.Transparency=.55
for j=1,7 do
 local p=part("FlowLine",Vector3.new(8.9,.055,.08),CFrame.new(0,-5+j*1.55,.14),rgb(214,170,255),Enum.Material.Neon);p.Transparency=.72;p:SetAttribute("Phase",j)
end
local keystone=part("CrownCrystal",Vector3.new(1.5,2,.8),CFrame.new(0,10.5,0)*CFrame.Angles(0,0,math.pi/4),glow,Enum.Material.Neon)
local light=Instance.new("PointLight",keystone);light.Color=glow;light.Range=18;light.Brightness=.8
local emitter=Instance.new("ParticleEmitter",veil);emitter.Texture="rbxasset://textures/particles/sparkles_main.dds";emitter.Rate=5;emitter.Lifetime=NumberRange.new(1.5,2.5);emitter.Speed=NumberRange.new(.5,1.5);emitter.SpreadAngle=Vector2.new(60,20);emitter.Color=ColorSequence.new(glow,gold);emitter.LightEmission=.65;emitter.Size=NumberSequence.new(.12);emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.2),NumberSequenceKeypoint.new(1,1)})
end
local anchor=part("TitleAnchor",Vector3.new(.1,.1,.1),CFrame.new(0,titleY,0),stone);anchor.Transparency=1
local board=Instance.new("BillboardGui",anchor);board.Name="GatewaySign";board.Size=UDim2.fromScale(17,4.8);board.MaxDistance=90;board.LightInfluence=0
local panel=Instance.new("Frame",board);panel.Size=UDim2.fromScale(1,1);panel.BackgroundColor3=rgb(41,29,69);panel.BackgroundTransparency=.08;Instance.new("UICorner",panel).CornerRadius=UDim.new(0,18)
local border=Instance.new("UIStroke",panel);border.Color=gold;border.Thickness=2
for i,s in ipairs({"NEON DISTRICT","SPEED 28 · LEVEL 3"}) do
 local l=Instance.new("TextLabel",panel);l.Name=i==2 and "Requirement" or "Title";l.BackgroundTransparency=1;l.Position=UDim2.fromScale(.03,i==1 and .08 or .57);l.Size=UDim2.fromScale(.94,i==1 and .44 or .27);l.Font=Enum.Font.FredokaOne;l.TextScaled=true;l.TextColor3=i==1 and rgb(241,222,255) or gold;l.Text=s
end
art.Parent=world
