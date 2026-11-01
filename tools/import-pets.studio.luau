-- Studio Command Bar only: read free models; import geometry, never their gameplay scripts.
local bank=Instance.new("Model")
bank.Name="PetAssets"
local seen={}
local accepted={dog=true,bunny=true,mouse=true,wolf=true,cat=true,penguin=true,raccoon=true,bear=true,piggy=true,spider=true,deer=true,fox=true,bat=true,["polar bear"]=true,panda=true,unicorn=true,dragon=true,dinosaur=true,["gummy bear"]=true,pegasus=true,spectre=true,reindeer=true,angel=true}
local packs=_G.PetPacks or {_G.PetPack}
for _,pack in ipairs(packs) do
 for _,source in ipairs(pack:GetDescendants()) do
  if source:IsA("Model") and accepted[string.lower(source.Name)] and not seen[string.lower(source.Name)] then
   local direct=source:FindFirstChildWhichIsA("BasePart")
   if direct then
    local clone=source:Clone()
    for _,node in ipairs(clone:GetDescendants()) do
     if node:IsA("LuaSourceContainer") or node:IsA("RemoteEvent") or node:IsA("RemoteFunction") or node:IsA("BindableEvent") or node:IsA("BindableFunction") or node:IsA("Humanoid") or node:IsA("AnimationController") or node:IsA("Sound") or node:IsA("ProximityPrompt") or node:IsA("ClickDetector") then node:Destroy() end
    end
    local largest
    for _,part in ipairs(clone:GetDescendants()) do
     if part:IsA("BasePart") then
      part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
      if not largest or part.Size.Magnitude>largest.Size.Magnitude then largest=part end
     end
    end
    if largest then
     clone.PrimaryPart=largest
     clone:PivotTo(CFrame.identity)
     clone.Name=source.Name
     clone:SetAttribute("CreatorStoreSource",pack==packs[1] and "14776469645" or "12731405251")
     clone.Parent=bank
     seen[string.lower(source.Name)]=true
    else clone:Destroy() end
   end
  end
 end
end
bank.Parent=game.ReplicatedStorage
game:GetService("Selection"):Set({bank})
print("[PetImport] CLEAN LIBRARY "..#bank:GetChildren().." models; scripts="..tostring(bank:FindFirstChildWhichIsA("LuaSourceContainer",true)))
