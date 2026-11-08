-- Authored 3D interpretations of the sunset reference; no external assets required.
local S={}
local pink=Color3.fromRGB(240,151,222)
local ivory=Color3.fromRGB(255,231,248)
local gold=Color3.fromRGB(255,189,79)
local purple=Color3.fromRGB(127,72,190)
local function builder(name)
 local m=Instance.new("Model");m.Name=name
 local parts={}
 local pivot=Instance.new("Part");pivot.Name="Pivot";pivot.Size=Vector3.new(.05,.05,.05);pivot.Transparency=1;pivot.Anchored=true;pivot.CanCollide=false;pivot.CanTouch=false;pivot.CanQuery=false;pivot.Parent=m;m.PrimaryPart=pivot
 local function part(n,size,pos,c,shape,rot,neon)
  local p=Instance.new(shape=="wedge" and "WedgePart" or "Part")
  p.Name=n;p.Size=size;p.Color=c;p.Material=neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  if shape=="ball" then p.Shape=Enum.PartType.Ball elseif shape=="cylinder" then p.Shape=Enum.PartType.Cylinder end
  p.CFrame=CFrame.new(pos)*(rot or CFrame.identity);p.Parent=m
  if not m.PrimaryPart then m.PrimaryPart=p end
  table.insert(parts,{part=p,transparency=0});return p
 end
 return m,parts,part
end
function S.BuildPet(kind,name)
 local m,parts,p=builder(name)
 local function ball(n,x,y,z,s,c) return p(n,Vector3.new(s,s,s),Vector3.new(x,y,z),c,"ball") end
 local function cloud(x,y,z,s)
  for i=-1,1 do ball("Cloud",x+i*s*.45,y+(i==0 and s*.18 or 0),z,s,ivory) end
 end
 local body=kind=="Castle" and purple or (kind=="Phoenix" and gold or pink)
 p("Body",Vector3.new(1.55,1.35,1.45),Vector3.zero,body)
 for _,side in ipairs({-1,1}) do
  ball("SoftCorner",side*.58,.44,-.52,.48,body)
  p("Eye",Vector3.new(.3,.4,.12),Vector3.new(side*.38,.14,-.77),gold,"ball",nil,true)
  ball("EyeSpark",side*.4,.25,-.84,.09,ivory)
  p("Cheek",Vector3.new(.24,.11,.1),Vector3.new(side*.57,-.14,-.76),Color3.fromRGB(255,122,174),"ball")
  p("Foot",Vector3.new(.43,.3,.55),Vector3.new(side*.47,-.79,-.3),gold,"ball")
 end
 p("Smile",Vector3.new(.18,.07,.07),Vector3.new(0,-.16,-.79),purple,"ball")
 cloud(-.7,-.5,-.6,.44);cloud(.65,-.5,-.6,.44)
 if kind=="Cloud" then
  for i=1,9 do local a=i/9*math.pi*2;ball("CloudCurl",math.cos(a)*.77,math.sin(a)*.7,0,.7,ivory) end
  ball("TopCurl",0,1,0,.75,ivory);ball("CurlPearl",.15,1,-.32,.34,pink)
 elseif kind=="Bunny" or kind=="Cat" or kind=="Unicorn" then
  for _,side in ipairs({-1,1}) do
   local h=kind=="Bunny" and 1.4 or .7
   p("Ear",Vector3.new(.48,h,.46),Vector3.new(side*.5,.65+h*.35,0),ivory,kind=="Bunny" and "ball" or "wedge",CFrame.Angles(0,0,-side*.16))
   p("EarInset",Vector3.new(.22,h*.65,.08),Vector3.new(side*.5,.65+h*.35,-.24),pink,"ball")
  end
  if kind=="Unicorn" then
   p("GoldenHorn",Vector3.new(.3,1,.3),Vector3.new(0,1.08,-.2),gold,"wedge",nil,true)
   for i=1,5 do ball("RainbowMane",.6,(i-2)*.25,.5,.5,({pink,purple,ivory,gold,pink})[i]) end
  end
 elseif kind=="Deer" then
  for _,side in ipairs({-1,1}) do
   p("Antler",Vector3.new(.13,1.25,.13),Vector3.new(side*.5,1.15,0),gold,nil,CFrame.Angles(0,0,-side*.18))
   for j=1,3 do p("AntlerBranch",Vector3.new(.44,.12,.12),Vector3.new(side*(.48+j*.08),.85+j*.23,0),gold,nil,CFrame.Angles(0,0,side*.4)) end
  end
 elseif kind=="Whale" then
  p("WhaleBelly",Vector3.new(1.5,.7,1.5),Vector3.new(0,-.35,-.05),ivory,"ball")
  for _,side in ipairs({-1,1}) do
   p("Fin",Vector3.new(.85,.24,.65),Vector3.new(side*.95,-.1,.25),pink,"ball",CFrame.Angles(0,0,side*.3))
   p("TailFluke",Vector3.new(.7,.3,.9),Vector3.new(side*.35,.55,1.2),purple,"ball",CFrame.Angles(0,side*.5,0))
  end
 elseif kind=="Dragon" or kind=="Phoenix" then
  for _,side in ipairs({-1,1}) do
   for j=1,5 do
    p("WingFeather",Vector3.new(.35,1.45-j*.13,.5),Vector3.new(side*(.8+j*.16),.3+j*.1,.3),j%2==0 and gold or ivory,"wedge",CFrame.Angles(0,side*.15,-side*(.5+j*.1)))
   end
   p("Horn",Vector3.new(.25,.85,.3),Vector3.new(side*.45,.94,0),gold,"wedge")
  end
  for j=1,4 do p("TailFeather",Vector3.new(.26,.28,1.1),Vector3.new((j-2.5)*.2,-.1,1),j%2==0 and gold or pink,"ball",CFrame.Angles(0,(j-2.5)*.2,0)) end
  if kind=="Phoenix" then p("Beak",Vector3.new(.32,.3,.5),Vector3.new(0,0,-.95),gold,"wedge") end
 elseif kind=="Castle" then
  for _,side in ipairs({-1,1}) do
   p("Tower",Vector3.new(.5,1.45,.6),Vector3.new(side*.75,.9,.2),ivory)
   p("TowerRoof",Vector3.new(.75,.65,.8),Vector3.new(side*.75,1.9,.2),gold,"wedge")
   p("Window",Vector3.new(.16,.35,.05),Vector3.new(side*.75,1,-.12),gold,nil,nil,true)
  end
  p("Spire",Vector3.new(.55,1.25,.6),Vector3.new(0,1.4,.35),ivory)
  p("SpireRoof",Vector3.new(.8,.65,.85),Vector3.new(0,2.3,.35),gold,"wedge")
  cloud(0,-.8,.1,.9)
 end
 if kind=="Phoenix" or kind=="Castle" then
  for i=1,16 do local a=i/16*math.pi*2;p("Halo",Vector3.new(.35,.06,.1),Vector3.new(math.cos(a)*.75,kind=="Castle" and 2.9 or 1.6,math.sin(a)*.75),gold,nil,CFrame.Angles(0,-a,0),true) end
 end
 -- Centre and normalize every species so it fits every inventory/gallery viewport.
 local cf,size=m:GetBoundingBox();local shift=cf.Position
 for _,v in ipairs(parts) do v.part.CFrame=v.part.CFrame-shift end
 m:PivotTo(CFrame.identity);m:ScaleTo(2.8/math.max(size.X,size.Y,size.Z))
 return m,parts
end
function S.BuildEgg()
 local m,_,p=builder("EggDisplay")
 local steps=64
 for i=1,steps do
  local t=(i-.5)/steps
  local radius=3.05*math.sqrt(math.max(0,1-(t*2-1)^2))*(1-.26*t)
  local c=t<.43 and gold:Lerp(Color3.fromRGB(255,157,177),t/.43) or Color3.fromRGB(255,157,177):Lerp(Color3.fromRGB(137,88,227),(t-.43)/.57)
  p("SkyBand",Vector3.new(7.5/steps+.015,radius*2,radius*2),Vector3.new(0,(t-.5)*7.5,0),c,"cylinder",CFrame.Angles(0,0,math.pi/2))
 end
 for row=1,3 do
  for i=1,3 do
   local a=i/3*math.pi*2+row*.65;local y=(row-2)*1.8
   for k=-1,1 do
    local angle=a+k*.17
    p("PinkCloud",Vector3.new(1,.65+(k==0 and .35 or 0),.65),Vector3.new(math.cos(angle)*2.55,y+(k==0 and .18 or 0),math.sin(angle)*2.55),ivory:Lerp(pink,row/5),"ball",CFrame.Angles(0,-angle,0))
   end
  end
 end
 for i=1,40 do local a=i/40*math.pi*2;p("GlowRing",Vector3.new(.48,.08,.1),Vector3.new(math.cos(a)*3.1,-3.85,math.sin(a)*3.1),pink,nil,CFrame.Angles(0,-a,0),true) end
 local light=Instance.new("PointLight");light.Color=pink;light.Range=15;light.Brightness=1.4;light.Parent=m.PrimaryPart
 m:PivotTo(CFrame.identity)
 return m
end
return S
