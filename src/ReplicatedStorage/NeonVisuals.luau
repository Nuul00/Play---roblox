-- Three authored collections. Local geometry, no asset downloads or scripts in pets.
-- All pets face -Z and are centred to fit the existing inventory and hatch cameras.
local N={}
local V=Vector3.new
local CF=CFrame.new
local A=CFrame.Angles
local pi=math.pi
local rgb=Color3.fromRGB
local dark=rgb(18,21,45)
local white=rgb(218,218,245)
local gold=rgb(255,187,63)
local palettes={
 Disco={coat=rgb(95,53,143),armor=rgb(33,29,66),accent=rgb(246,65,255),secondary=rgb(59,219,255)},
 Tech={coat=rgb(76,91,137),armor=rgb(22,39,65),accent=rgb(40,207,255),secondary=rgb(223,65,249)},
 City={coat=rgb(81,50,135),armor=rgb(31,29,68),accent=rgb(229,76,255),secondary=rgb(74,197,255)},
}
local function builder(name)
 local m=Instance.new("Model");m.Name=name
 local records={}
 local function P(n,size,cf,c,shape,glow)
  local p=Instance.new(shape=="wedge" and "WedgePart" or "Part")
  p.Name=n;p.Size=size;p.CFrame=cf;p.Color=c
  p.Material=(glow or n=="PowerCellGlass") and Enum.Material.Neon or Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  if shape=="ball" then p.Shape=Enum.PartType.Ball elseif shape=="cyl" then p.Shape=Enum.PartType.Cylinder end
  p.Parent=m;table.insert(records,{part=p,transparency=0});return p
 end
 local pivot=P("Pivot",V(.02,.02,.02),CFrame.identity,dark)
 pivot.Transparency=1;records[1].transparency=1;m.PrimaryPart=pivot
 local function line(n,a,b,width,c,glow)
  return P(n,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),c,nil,glow)
 end
 local function ring(n,cf,r,width,c,count)
  count=count or 16
  for i=1,count do
   local a=(i-1)/count*2*pi;local b=i/count*2*pi
   line(n,cf:PointToWorldSpace(V(math.cos(a)*r,math.sin(a)*r,0)),cf:PointToWorldSpace(V(math.cos(b)*r,math.sin(b)*r,0)),width,c,true)
  end
 end
 -- A rounded cuboid assembled with actual rounded edges, rather than a plain block.
 local function round(n,size,cf,c,r)
  r=math.min(r or .13,math.min(size.X,size.Y,size.Z)*.45)
  local inner=size-V(r*2,r*2,r*2)
  P(n,V(size.X,inner.Y,inner.Z),cf,c)
  P(n,V(inner.X,size.Y,inner.Z),cf,c)
  P(n,V(inner.X,inner.Y,size.Z),cf,c)
  for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
   P(n,V(r*2,r*2,r*2),cf*CF(x*inner.X/2,y*inner.Y/2,z*inner.Z/2),c,"ball")
  end end end
  for _,a in ipairs({-1,1}) do for _,b in ipairs({-1,1}) do
   P(n,V(inner.X,r*2,r*2),cf*CF(0,a*inner.Y/2,b*inner.Z/2),c,"cyl")
   P(n,V(inner.Y,r*2,r*2),cf*CF(a*inner.X/2,0,b*inner.Z/2)*A(0,0,pi/2),c,"cyl")
   P(n,V(inner.Z,r*2,r*2),cf*CF(a*inner.X/2,b*inner.Y/2,0)*A(0,pi/2,0),c,"cyl")
  end end
 end
 return m,records,P,line,ring,round
end
function N.BuildPet(theme,kind,name)
 local pal=assert(palettes[theme],"Unknown neon theme")
 local m,records,P,line,ring,round=builder(name)
 local accent,second=pal.accent,pal.secondary
 local coat=kind=="Panda" and white or (kind=="Fox" or kind=="Raccoon") and rgb(164,154,218) or pal.coat
 local isSea=kind=="Shark" or kind=="Whale"
 round("RoundedBody",isSea and V(1.95,1.22,2.15) or V(1.8,1.55,1.65),CF(),coat,.18)
 -- Faceplate and small luminous seams remain readable under the world's bloom.
 round("FaceGlass",V(1.55,1.05,.16),CF(0,.05,isSea and -1.07 or -.84),dark,.07)
 local fz=isSea and -1.18 or -.95
 local function led(x,y,c,s) P("FaceLED",V(s or .075,s or .075,.035),CF(x,y,fz),c,nil,true) end
 local pixel=kind=="Cat" or kind=="Bunny" or kind=="Robot"
 for _,side in ipairs({-1,1}) do
  if pixel then
   for ix=0,1 do for iy=0,2 do led(side*.37+(ix-.5)*.075,.18+iy*.075,second) end end
  elseif kind=="Owl" then
   ring("LensRing",CF(side*.37,.2,fz),.25,.07,second,16)
   P("LensIris",V(.17,.23,.07),CF(side*.37,.2,fz-.01),accent,"ball",true)
  else
   P("BrightEye",V(.37,.16,.055),CF(side*.38,.22,fz)*A(0,0,-side*.26),second,"ball",true)
   P("EyeGlint",V(.09,.09,.035),CF(side*.44,.26,fz-.04),white,"ball")
  end
  if not isSea then
   round("Paw",V(.48,.33,.68),CF(side*.55,-.88,-.28),pal.armor,.1)
   P("PawLight",V(.35,.05,.06),CF(side*.55,-.85,-.64),accent,nil,true)
  end
 end
 if pixel then
  for _,xy in ipairs({{-.15,-.08},{-.08,-.15},{0,-.15},{.08,-.15},{.15,-.08}}) do led(xy[1],xy[2],second,.055) end
 else
  P("Nose",V(.16,.1,.08),CF(0,-.03,fz-.02),accent,"ball")
  line("Smile",V(-.12,-.17,fz),V(.12,-.17,fz),.035,white)
 end
 -- Ear and head silhouettes.
 if kind=="Bunny" then
  for _,s in ipairs({-1,1}) do
   local cf=CF(s*.48,1.25,.04)*A(0,0,-s*.14)
   round("RabbitEar",V(.43,1.25,.37),cf,coat,.17)
   P("EarLight",V(.19,.91,.06),cf*CF(0,0,-.2),accent,"ball",true)
  end
 elseif kind=="Panda" then
  for _,s in ipairs({-1,1}) do
   P("PandaEar",V(.62,.62,.4),CF(s*.63,.82,0),pal.armor,"ball")
   P("EarInset",V(.35,.35,.08),CF(s*.63,.85,-.23),accent,"ball")
  end
 elseif kind=="Dog" then
  for _,s in ipairs({-1,1}) do round("DogEar",V(.42,.95,.64),CF(s*.93,.24,.12)*A(0,0,s*.12),pal.armor,.15) end
 else
  if not isSea and kind~="Robot" and kind~="Owl" and kind~="Lion" then
   for _,s in ipairs({-1,1}) do
    local cf=CF(s*.6,.98,0)*A(0,0,-s*.13)
    P("PointedEar",V(.53,.7,.48),cf,coat,"wedge")
    P("EarInset",V(.28,.42,.08),cf*CF(0,.04,-.25),accent,"wedge",true)
   end
  end
 end
 local function headphones()
  for _,s in ipairs({-1,1}) do
   round("EarCup",V(.3,.7,.74),CF(s*1.02,.16,.05),pal.armor,.12)
   ring("HeadphoneLight",CF(s*1.2,.16,.05)*A(0,pi/2,0),.25,.065,accent,12)
  end
  P("Headband",V(1.7,.16,.3),CF(0,.88,.16),pal.armor)
 end
 if kind=="Cat" or kind=="Bunny" or kind=="Robot" or kind=="Dog" or kind=="Raccoon" or kind=="Panda" then headphones() end
 if kind=="Raccoon" or kind=="Dog" then
  round("Visor",V(1.5,.38,.12),CF(0,.33,fz-.05),rgb(34,90,153),.05)
  line("VisorLight",V(-.66,.48,fz-.13),V(.66,.48,fz-.13),.05,second,true)
  P("Muzzle",V(.6,.35,.4),CF(0,-.22,fz-.04),pal.armor,"ball")
 end
 if kind=="Raccoon" or kind=="Fox" or kind=="Wolf" then
  local cf=CF(.4,-.2,1.05)*A(.45,-.35,0)
  P("FluffyTail",V(.67,.65,1.55),cf,coat,"ball")
  for j=1,3 do P("TailBand",V(.69,.67,.12),cf*CF(0,0,(j-2)*.35),j==3 and white or pal.armor) end
 end
 if kind=="Wolf" or kind=="Dragon" then
  for _,s in ipairs({-1,1}) do for j=1,4 do
   P("CheekSpike",V(.43,.55,.65),CF(s*(.78+j*.09),.34-j*.18,.2)*A(0,0,-s*.75),j%2==0 and pal.armor or accent,"wedge",j%2==1)
  end end
  P("Snout",V(.7,.42,.42),CF(0,-.12,fz-.04),pal.armor,"ball")
 end
 if kind=="Lion" then
  for j=1,14 do
   local a=j/14*2*pi;local cf=CF(math.cos(a)*.96,math.sin(a)*.94,-.08)*A(0,0,a-pi/2)
   P("PrismaticMane",V(.44,.65,.75),cf,theme=="Tech" and white or gold,"wedge")
   P("ManeLED",V(.1,.28,.07),cf*CF(0,.08,-.4),accent,nil,true)
  end
 end
 local function wings(dragon)
  for _,s in ipairs({-1,1}) do
   if dragon then
    local shoulder=V(s*.7,.4,.42)
    local tip=V(s*1.92,1.3,.42)
    P("BatWingMembrane",V(1.05,1.05,.16),CF(s*1.36,.67,.42)*A(0,0,-s*.45),pal.coat,"wedge")
    P("LowerWingMembrane",V(.72,.68,.16),CF(s*1.38,.2,.42)*A(0,0,s*.65),pal.coat,"wedge")
    line("WingLeadingEdge",shoulder,tip,.075,accent,true)
    line("WingRib",shoulder,V(s*1.95,.32,.42),.06,second,true)
    line("WingRib",shoulder,V(s*1.45,-.16,.42),.055,accent,true)
    line("WingOuterEdge",tip,V(s*1.95,.32,.42),.045,second,true)
   else
    for j=1,3 do
     local cf=CF(s*(.78+j*.17),.25+j*.12,.25)*A(0,s*.18,-s*(.5+j*.14))
     P("OwlFeather",V(.35,.85-j*.12,.18),cf,j%2==0 and second or accent,"wedge",true)
     P("FeatherQuill",V(.065,.65-j*.1,.21),cf,pal.armor)
    end
   end
  end
 end
 if kind=="Owl" then wings(false);P("Beak",V(.22,.3,.22),CF(0,-.06,fz-.1),gold,"wedge") end
 if kind=="Dragon" then
  wings(true)
  for _,s in ipairs({-1,1}) do P("DragonHorn",V(.25,.8,.3),CF(s*.5,.94,.24)*A(-.25,0,-s*.3),white,"wedge") end
  for j=1,4 do P("BackSpine",V(.25,.4,.25),CF(0,.6-j*.18,.7+j*.16),accent,"wedge",true) end
 end
 if isSea then
  P("PaleBelly",V(1.8,.58,1.95),CF(0,-.42,-.05),white,"ball")
  for _,s in ipairs({-1,1}) do
   P("SideFin",V(.95,.17,.95),CF(s*1.02,-.1,0)*A(0,s*.5,s*.2),pal.armor,"wedge")
   P("TailFluke",V(.7,.18,.8),CF(s*.36,.15,1.34)*A(0,s*.65,0),accent,"wedge",true)
  end
  P("DorsalFin",V(.22,.9,.8),CF(0,.79,.12),second,"wedge",true)
  if kind=="Shark" then
   P("Mouth",V(1.28,.32,.08),CF(0,-.24,fz-.02),dark)
   for j=1,7 do for _,s in ipairs({-1,1}) do P("Tooth",V(.14,.16,.04),CF((j-4)*.16,-.24+s*.11,fz-.08)*A(0,0,s==1 and pi or 0),white,"wedge") end end
   for _,s in ipairs({-1,1}) do ring("FinReactor",CF(s*1.02,.02,.1)*A(0,pi/2,0),.24,.06,accent,12) end
  end
 end
 if kind=="Deer" then
  for _,s in ipairs({-1,1}) do
   line("Antler",V(s*.5,.6,0),V(s*.67,1.7,.1),.1,accent,true)
   for j=1,3 do line("AntlerBranch",V(s*(.55+j*.03),.9+j*.2,.05),V(s*(.9+j*.06),1.15+j*.2,.05),.08,accent,true) end
  end
 end
 if kind=="Robot" then
  for _,s in ipairs({-1,1}) do
   line("Antenna",V(s*.55,.75,0),V(s*.55,1.16,0),.07,white)
   P("AntennaTip",V(.2,.2,.2),CF(s*.55,1.2,0),second,"ball",true)
  end
  round("RobotBase",V(1.6,.21,1.45),CF(0,-.84,0),pal.armor,.08)
  ring("HoverDrive",CF(0,-1.02,0)*A(pi/2,0,0),.75,.06,accent,20)
  if theme=="City" then
   line("RotorMast",V(0,.75,0),V(0,1.25,0),.09,white)
   ring("Rotor",CF(0,1.33,0)*A(pi/2,0,0),.95,.045,accent,20)
   P("RotorBlade",V(2,.06,.16),CF(0,1.33,0),white)
  end
 end
 if theme=="Disco" then
  -- Reflective tile strips and tiny equalizer lights distinguish this collection.
  for j=1,5 do
   P("DiscoTile",V(.18,.18,.06),CF((j-3)*.3,-.58,-.87),j%2==0 and second or accent,nil,true)
  end
 elseif theme=="Tech" then
  for _,s in ipairs({-1,1}) do
   round("ShoulderArmor",V(.16,.74,.85),CF(s*.91,-.05,.18),pal.armor,.06)
   for j=1,3 do P("CircuitTrace",V(.04,.18,.05),CF(s*(.4+j*.11),-.57,-.87),second,nil,true) end
   P("ArmorBolt",V(.11,.11,.07),CF(s*.68,.62,-.86),white,"cyl")
  end
 else
  -- Small 3D skyline wraps around flanks and back; eyes remain unobstructed.
  for j=1,7 do
   local a=(j-1)/6*pi;local h=.35+(j%3)*.18
   local x,z=math.cos(a)*.92,math.sin(a)*.83
   P("SkylineTower",V(.23,h,.25),CF(x,-.3+h/2,z),pal.armor)
   line("TowerEdge",V(x-.1,-.3,z-.13),V(x-.1,-.3+h,z-.13),.035,accent,true)
   for k=1,2 do P("TowerWindow",V(.07,.055,.035),CF(x,-.2+k*.14,z-.14),second,nil,true) end
   if j%2==0 then line("TowerSpire",V(x,-.3+h,z),V(x,h,z),.03,accent,true) end
  end
  for j=1,5 do
   local x=(j-3)*.32;local h=.28+(j%3)*.13
   P("FrontSkyline",V(.23,h,.16),CF(x,-.76+h/2,-.91),pal.armor)
   line("FrontTowerEdge",V(x-.11,-.76,-1.01),V(x-.11,-.76+h,-1.01),.027,accent,true)
   for k=1,2 do P("FrontWindow",V(.07,.05,.03),CF(x,-.72+k*.1,-1.01),second,nil,true) end
  end
 end
 local bounds,size=m:GetBoundingBox()
 for _,rec in ipairs(records) do if rec.part~=m.PrimaryPart then rec.part.CFrame=rec.part.CFrame-bounds.Position end end
 m:ScaleTo((kind=="Dragon" and 3.15 or 2.8)/math.max(size.X,size.Y,size.Z))
 return m,records
end
function N.BuildEgg(theme)
 local pal=assert(palettes[theme]);local m,_,P,line,ring,round=builder("EggDisplay")
 local function radius(t) return 3.05*math.sqrt(math.max(0,1-(t*2-1)^2))*(1-.24*t) end
 -- Smooth 80-band egg profile; dark shell keeps the luminous geometry readable.
 for i=1,80 do
  local t=(i-.5)/80;local r=radius(t)
  P("Shell",V(7.5/80+.015,r*2,r*2),CF(0,(t-.5)*7.5,0)*A(0,0,pi/2),pal.armor,"cyl")
 end
 if theme=="Disco" then
  for row=1,10 do
   local t=row/11;local r=radius(t)+.035
   for col=1,16 do
    local a=col/16*2*pi;local c=(row+col)%4==0 and pal.secondary or (row+col)%3==0 and pal.accent or pal.coat
    P("MirrorTile",V(2*r*math.sin(pi/16)*.85,.52,.13),CF(math.cos(a)*r,(t-.5)*7.5,math.sin(a)*r)*A(0,pi/2-a,0),c,nil,(row+col)%3==0)
   end
  end
 elseif theme=="Tech" then
  for _,s in ipairs({-1,1}) do
   round("PowerCell",V(.85,2.5,1.5),CF(s*2.68,0,0),pal.coat,.23)
   round("PowerCellGlass",V(.12,1.9,1.05),CF(s*3.15,0,0),pal.accent,.05)
   for y=-1,1 do P("Clamp",V(.95,.15,1.65),CF(s*2.68,y,0),white) end
  end
  for row=1,5 do
   local t=row/6;local r=radius(t)+.08
   for col=1,8 do
    local a=col/8*2*pi
    P("ArmorPanel",V(.85,.75,.17),CF(math.cos(a)*r,(t-.5)*7.5,math.sin(a)*r)*A(0,pi/2-a,0),pal.coat)
    P("CircuitNode",V(.24,.29,.07),CF(math.cos(a)*(r+.12),(t-.5)*7.5,math.sin(a)*(r+.12))*A(0,pi/2-a,0),pal.secondary,nil,true)
    local cf=CF(math.cos(a)*(r+.13),(t-.5)*7.5,math.sin(a)*(r+.13))*A(0,pi/2-a,0)
    line("PanelCircuit",cf:PointToWorldSpace(V(-.3,-.25,0)),cf:PointToWorldSpace(V(-.3,.25,0)),.04,pal.accent,true)
    line("PanelCircuit",cf:PointToWorldSpace(V(-.3,.25,0)),cf:PointToWorldSpace(V(.25,.25,0)),.04,pal.accent,true)
   end
  end
 else
  -- Skyline buildings rise around the bottom half, with lit windows and spires.
  for j=1,14 do
   local a=j/14*2*pi;local h=1.4+(j%5)*.42;local r=2.2
   local cf=CF(math.cos(a)*r,-3.15+h/2,math.sin(a)*r)*A(0,-pi/2-a,0)
   P("Building",V(.58,h,.5),cf,pal.coat)
   for _,s in ipairs({-1,1}) do line("BuildingEdge",cf:PointToWorldSpace(V(s*.3,-h/2,-.27)),cf:PointToWorldSpace(V(s*.3,h/2,-.27)),.05,pal.accent,true) end
   for y=1,math.floor(h/.3) do for x=-1,1,2 do P("Window",V(.11,.1,.045),cf*CF(x*.14,-h/2+y*.28,-.28),y%2==0 and pal.secondary or gold,nil,true) end end
   line("SkylineAntenna",cf:PointToWorldSpace(V(0,h/2,0)),cf:PointToWorldSpace(V(0,h/2+.55,0)),.045,pal.accent,true)
  end
  for j=1,6 do
   local a=j/6*2*pi
   line("SkyArc",V(math.cos(a)*1.9,2.4,math.sin(a)*1.9),V(math.cos(a)*.7,3.5,math.sin(a)*.7),.045,pal.secondary,true)
  end
  for j=1,6 do
   local a=j/6*2*pi
   for k=1,13 do
    local t1=.08+(k-1)/13*.84;local t2=.08+k/13*.84
    line("CityShellRim",V(math.cos(a)*(radius(t1)+.06),(t1-.5)*7.5,math.sin(a)*(radius(t1)+.06)),V(math.cos(a)*(radius(t2)+.06),(t2-.5)*7.5,math.sin(a)*(radius(t2)+.06)),.035,pal.accent,true)
   end
  end
 end
 -- Front jewel on both sides reads clearly while the display rotates.
 for _,s in ipairs({-1,1}) do
  local cf=CF(0,.12,s*2.74)
  round("CoreHousing",V(1.25,1.25,.22),cf,pal.coat,.15)
  P("CoreDiamond",V(.58,.58,.1),cf*CF(0,0,s*.16)*A(0,0,pi/4),pal.accent,nil,true)
 end
 ring("BaseHalo",CF(0,-3.9,0)*A(pi/2,0,0),3.05,.09,pal.accent,48)
 if theme=="Tech" then ring("ReactorRing",CF(0,-3.62,0)*A(pi/2,0,0),2.8,.065,pal.secondary,40) end
 local light=Instance.new("PointLight");light.Color=pal.accent;light.Range=12;light.Brightness=.65;light.Parent=m.PrimaryPart
 return m
end
return N
