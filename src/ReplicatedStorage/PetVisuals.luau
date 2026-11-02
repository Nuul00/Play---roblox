-- Sanitized Creator Store meshes take priority; ten rounded fallback species.
local Config=require(script.Parent:WaitForChild("GameConfig"))
local PetVisuals={}
function PetVisuals.Build(id)
 local def=assert(Config.Pets[id],"Unknown pet")
 if string.sub(def.Visual,1,6)=="Sunset" then return require(script.Parent:WaitForChild("SunsetVisuals")).BuildPet(string.sub(def.Visual,7),def.Name) end
 if string.sub(def.Visual,1,6)=="Sakura" then return require(script.Parent:WaitForChild("ThemedVisuals")).BuildPet("Sakura",string.sub(def.Visual,7),def.Name) end
 if string.sub(def.Visual,1,9)=="Starlight" then return require(script.Parent:WaitForChild("ThemedVisuals")).BuildPet("Starlight",string.sub(def.Visual,10),def.Name) end
 -- Visual совпадает с именем модели целиком: сначала паки (PetModels), потом старые PetAssets.
 -- Если модели нет, рисуем запасного питомца из деталей ниже.
 local selected
 for _,folderName in ipairs({"PetModels","PetAssets"}) do
  local library=script.Parent:FindFirstChild(folderName)
  if library and not selected then
   for _,template in ipairs(library:GetChildren()) do if string.lower(template.Name)==string.lower(def.Visual) then selected=template;break end end
  end
 end
 do
  if selected and selected:IsA("Model") and selected:FindFirstChildWhichIsA("BasePart",true) then
   local model=selected:Clone();model.Name=def.Name
   local size=model:GetExtentsSize()
   -- Мифики и секретки крупнее обычных, чтобы редкость было видно сразу.
   local target=({Mythic=3.1,Secret=3.5})[def.Rarity] or 2.5
   model:ScaleTo(model:GetScale()*target/math.max(size.X,size.Y,size.Z,0.1))
   model:PivotTo(CFrame.identity)
   local parts={}
   for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;table.insert(parts,{part=p,transparency=p.Transparency}) end end
   model.PrimaryPart=model.PrimaryPart or parts[1].part
   return model,parts
  end
 end
 local model=Instance.new("Model");model.Name=def.Name
 local parts={}
 local function piece(name,size,pos,color,shape,rotation,material)
  local p=Instance.new(shape=="wedge" and "WedgePart" or "Part")
  p.Name=name;p.Size=size;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  if shape=="ball" then p.Shape=Enum.PartType.Ball end
  p.CFrame=CFrame.new(pos)*(rotation or CFrame.identity);p.Parent=model
  table.insert(parts,{part=p,transparency=0});return p
 end
 local c=def.Color
 local cream=c:Lerp(Color3.new(1,1,1),0.73)
 local dark=Color3.fromRGB(28,37,57)
 model.PrimaryPart=piece("Body",Vector3.new(1.65,1.45,1.65),Vector3.zero,c,"ball")
 piece("Face",Vector3.new(1.38,1.06,0.22),Vector3.new(0,0.1,-0.73),cream,"ball")
 for _,side in ipairs({-1,1}) do
  piece("Eye",Vector3.new(0.34,0.43,0.17),Vector3.new(side*0.38,0.27,-0.87),dark,"ball")
  piece("EyeLight",Vector3.new(0.12,0.14,0.065),Vector3.new(side*0.37,0.38,-0.965),Color3.new(1,1,1),"ball")
  piece("Blush",Vector3.new(0.25,0.12,0.08),Vector3.new(side*0.57,-0.03,-0.85),Color3.fromRGB(255,166,184),"ball")
  piece("Paw",Vector3.new(0.46,0.36,0.58),Vector3.new(side*0.55,-0.67,-0.31),cream,"ball")
 end
 piece("Nose",Vector3.new(0.15,0.12,0.1),Vector3.new(0,0.02,-0.93),dark,"ball")
 local kind=string.lower(def.Visual)
 if kind=="bunny" then
  for _,side in ipairs({-1,1}) do
   piece("LongEar",Vector3.new(0.46,1.35,0.48),Vector3.new(side*0.43,1.16,0),c,"ball",CFrame.Angles(0,0,-side*0.12))
   piece("InnerEar",Vector3.new(0.23,0.98,0.1),Vector3.new(side*0.43,1.2,-0.22),cream,"ball")
  end
 elseif kind=="dog" then
  for _,side in ipairs({-1,1}) do piece("FloppyEar",Vector3.new(0.5,1,0.55),Vector3.new(side*0.83,0.32,0),c:Lerp(dark,0.2),"ball") end
 elseif kind=="owl" or kind=="phoenix" then
  for _,side in ipairs({-1,1}) do piece("Wing",Vector3.new(0.5,1.1,0.85),Vector3.new(side*0.9,0.04,0.12),c,"ball",CFrame.Angles(0,0,side*0.35)) end
  piece("Beak",Vector3.new(0.35,0.35,0.38),Vector3.new(0,0,-1),Color3.fromRGB(255,196,85),"wedge")
  if kind=="phoenix" then for i=1,5 do piece("TailFeather",Vector3.new(0.32,0.45,1.5),Vector3.new((i-3)*0.22,-0.2,1),c:Lerp(Color3.fromRGB(255,214,89),i/7),"ball",CFrame.Angles(0,(i-3)*0.2,0),Enum.Material.Neon) end end
 elseif kind=="dragon" then
  for _,side in ipairs({-1,1}) do
   piece("Wing",Vector3.new(1.3,0.22,1.4),Vector3.new(side*1.08,0.4,0.45),cream,"wedge",CFrame.Angles(0,side*0.3,side*0.45))
   piece("Horn",Vector3.new(0.27,0.7,0.3),Vector3.new(side*0.5,0.95,0),cream,"wedge")
  end
  piece("Tail",Vector3.new(0.45,0.45,1.25),Vector3.new(0,-0.1,1.1),c,"ball")
 elseif kind=="deer" then
  for _,side in ipairs({-1,1}) do
   piece("Antler",Vector3.new(0.15,1,0.15),Vector3.new(side*0.5,1.1,0.1),Color3.fromRGB(219,181,112),nil,CFrame.Angles(0,0,-side*0.25))
   piece("AntlerBranch",Vector3.new(0.55,0.13,0.13),Vector3.new(side*0.58,1.3,0.1),Color3.fromRGB(219,181,112))
  end
 elseif kind=="lion" then
  for i=1,10 do local a=i/10*math.pi*2;piece("Mane",Vector3.new(0.65,0.65,0.6),Vector3.new(math.cos(a)*0.82,math.sin(a)*0.78,-0.1),c:Lerp(Color3.fromRGB(255,187,65),0.6),"ball") end
 elseif kind=="spirit" then
  for i=1,5 do local a=i/5*math.pi*2;piece("OrbitGem",Vector3.new(0.3,0.5,0.3),Vector3.new(math.cos(a)*1.1,0.8,math.sin(a)*1.1),cream,"ball",nil,Enum.Material.Neon) end
 else
  for _,side in ipairs({-1,1}) do piece("Ear",Vector3.new(0.55,0.7,0.5),Vector3.new(side*0.55,0.8,0),c,"wedge",CFrame.Angles(0,0,-side*0.15)) end
  if kind=="fox" then piece("FluffyTail",Vector3.new(0.85,0.8,1.5),Vector3.new(0,0,1),cream,"ball",CFrame.Angles(0.35,0,0)) end
 end
 return model,parts
end
return PetVisuals
