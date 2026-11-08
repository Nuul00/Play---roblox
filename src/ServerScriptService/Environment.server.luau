-- Official Roblox-owned Synty Nature Pack: free for use in Roblox games.
-- Only visual geometry is cloned; source scripts are never parented into the world.
local world=workspace:WaitForChild("CoinSpeedWorld")
local ok,asset=pcall(function() return game:GetService("AssetService"):LoadAssetAsync(6933438443) end)
if not ok then warn("[Environment] Nature meshes unavailable; authored trees remain: "..tostring(asset));return end
local templates={}
for _,candidate in ipairs(asset:GetDescendants()) do
 if candidate:IsA("Model") and string.find(string.lower(candidate.Name),"tree",1,true) then
  local direct=0
  for _,child in ipairs(candidate:GetChildren()) do if child:IsA("BasePart") then direct=direct+1 end end
  if direct>0 and direct<=12 then table.insert(templates,candidate) end
 end
end
if #templates==0 then
 for _,candidate in ipairs(asset:GetDescendants()) do
  if candidate:IsA("MeshPart") and string.find(string.lower(candidate.Name),"tree",1,true) and not string.find(string.lower(candidate.Name),"stump",1,true) then
   local model=Instance.new("Model");model.Name=candidate.Name;candidate:Clone().Parent=model;table.insert(templates,model)
  end
 end
end
table.sort(templates,function(a,b) return a.Name<b.Name end)
local targets={}
for _,tree in ipairs(world:GetChildren()) do if tree:IsA("Model") and tree.Name=="Tree" then table.insert(targets,tree) end end
local replaced=0
for i,tree in ipairs(targets) do
 local template=templates[(i-1)%math.max(#templates,1)+1]
 local trunk=tree:FindFirstChild("Trunk")
 if template and trunk then
  local model=template:Clone()
  for _,node in ipairs(model:GetDescendants()) do
   if node:IsA("LuaSourceContainer") or node:IsA("Sound") or node:IsA("ProximityPrompt") or node:IsA("ClickDetector") then node:Destroy()
   elseif node:IsA("BasePart") then
    node.Anchored=true;node.CanTouch=false;node.CanQuery=true
    local name=string.lower(node.Name)
    if string.find(name,"leaf",1,true) or string.find(name,"leav",1,true) then node.Color=Color3.fromRGB(106,181,111) end
   end
  end
  local size=model:GetExtentsSize()
  if size.Y>0.1 then
   model:ScaleTo(model:GetScale()*(15+i%5*2)/size.Y)
   local x,z=trunk.Position.X,trunk.Position.Z
   model:PivotTo(CFrame.new(x,10,z)*CFrame.Angles(0,i*1.73,0))
   local bounds,dimensions=model:GetBoundingBox()
   model:PivotTo(model:GetPivot()+Vector3.new(0,(world:GetAttribute("GroundY") or 0)-(bounds.Position.Y-dimensions.Y/2),0))
   model.Name="SyntyTree_"..i;model.Parent=world
   tree:Destroy();replaced=replaced+1
  else model:Destroy() end
 end
end
print("[Environment] Official tree meshes: "..replaced..", templates: "..#templates)
asset:Destroy()
