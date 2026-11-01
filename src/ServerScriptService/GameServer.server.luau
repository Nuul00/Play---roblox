-- Script в ServerScriptService. Все награды и покупки проверяет сервер.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local world = workspace:WaitForChild("CoinSpeedWorld")
if world:GetAttribute("ServerRunning") then return end
world:SetAttribute("ServerRunning", true)
local city = world:WaitForChild("NeonCity")
workspace.GlobalWind=Vector3.new(8,0,3)
workspace.Terrain:FillBlock(CFrame.new(250,-15,0),Vector3.new(1000,10,650),Enum.Material.Water)
workspace.Terrain:FillBlock(CFrame.new(0,-6,0),Vector3.new(300,12,460),Enum.Material.Grass)
workspace.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(86,155,82))
workspace.Terrain:FillBlock(CFrame.new(-95,-2,-30),Vector3.new(48,4,56),Enum.Material.Water)
-- Grass belongs beside the paths, never through the plaza, shop or egg approach.
for _,name in ipairs({"MainPath","EggPath","ShopPath","ArrivalPlaza"}) do
 local path=world:FindFirstChild(name)
 if path then workspace.Terrain:FillBlock(CFrame.new(path.Position.X,-2,path.Position.Z),Vector3.new(path.Size.X+2,4,path.Size.Z+2),Enum.Material.Sand) end
end
workspace.Terrain:FillBlock(CFrame.new(-45,-2,140),Vector3.new(31,4,24),Enum.Material.Ground)
for _,egg in ipairs(Config.Eggs) do
 if egg.World=="island" then workspace.Terrain:FillBlock(CFrame.new(egg.Position.X,-2,140),Vector3.new(7,4,21),Enum.Material.Sand) end
end
-- Smooth terrain is voxel-aligned: place authored props on its actual surface.
local terrainOnly=RaycastParams.new()
terrainOnly.FilterType=Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances={workspace.Terrain}
local surface=workspace:Raycast(Vector3.new(0,80,180),Vector3.new(0,-160,0),terrainOnly)
local groundY=surface and surface.Position.Y or 0
world:SetAttribute("GroundY",groundY)
if not world:GetAttribute("GroundAligned") then
 for _,child in ipairs(world:GetChildren()) do
  if child~=city then
   if child:IsA("BasePart") then child.CFrame=child.CFrame+Vector3.new(0,groundY,0)
   elseif child:IsA("Model") then child:PivotTo(child:GetPivot()+Vector3.new(0,groundY,0)) end
  end
 end
 world:SetAttribute("GroundAligned",true)
end
local feedback = Instance.new("RemoteEvent")
feedback.Name = "GameFeedback"
feedback.Parent = ReplicatedStorage
local cooldown = {}
local hatchUntil = {}
local random = Random.new()
local openMenu = Instance.new("RemoteEvent")
openMenu.Name = "GameShopOpen"
openMenu.Parent = ReplicatedStorage
local buy = Instance.new("RemoteEvent")
buy.Name = "GameShopBuy"
buy.Parent = ReplicatedStorage
local hatched = Instance.new("RemoteEvent")
hatched.Name = "GameHatched"
hatched.Parent = ReplicatedStorage
local function alive(player)
 local character = player.Character
 if not character then return end
 local h = character:FindFirstChildOfClass("Humanoid")
 local root = character:FindFirstChild("HumanoidRootPart")
 if h and root and h.Health > 0 then return h, root end
end
local function setup(player)
 if player:FindFirstChild("leaderstats") then return end
 player:SetAttribute("ProfileReady",false)
 player:SetAttribute("MagnetLevel", 0)
 player:SetAttribute("PetLevel", 0)
 player:SetAttribute("IncomeLevel", 0)
 player:SetAttribute("LifetimeEarned", 0)
 player:SetAttribute("CoinsCollected", 0)
 player:SetAttribute("EggsOpened", 0)
 for i=1,#Config.Pets do player:SetAttribute("PetOwned" .. i, 0) end
 player:SetAttribute("CurrentWorld", "Meadow Isles")
 local stats = Instance.new("Folder")
 stats.Name = "leaderstats"
 local coins = Instance.new("NumberValue") -- Поддерживает 7.5 монеты при множителе x1.5.
 coins.Name = "Coins"
 coins.Parent = stats
 local level = Instance.new("IntValue")
 level.Name = "SpeedLevel"
 level.Parent = stats
 stats.Parent = player
 player.RespawnLocation = world.Start
 local function characterAdded(character)
  local h = character:WaitForChild("Humanoid", 10)
  if h and player.Character == character then h.WalkSpeed = Config.GetWalkSpeed(level.Value) end
  player:SetAttribute("CurrentWorld", "Meadow Isles")
 end
 player.CharacterAdded:Connect(characterAdded)
 if player.Character then task.spawn(characterAdded, player.Character) end
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(p) cooldown[p] = nil; hatchUntil[p] = nil end)
for _, p in ipairs(Players:GetPlayers()) do setup(p) end

local function notify(p, text, success) feedback:FireClient(p, text, success or false) end
local function interact(p, part, prompt, cityOnly)
 if p.Parent ~= Players or not prompt.Enabled then return end
 if not p:GetAttribute("ProfileReady") then return end
 local h, root = alive(p)
 if not h or (root.Position - part.Position).Magnitude > Config.ShopDistance then return end
 local stats = p:FindFirstChild("leaderstats")
 if not stats then return end
 if cityOnly and stats.SpeedLevel.Value < 3 then return end
 local now = os.clock()
 if now - (cooldown[p] or -math.huge) < Config.PurchaseCooldown then return end
 cooldown[p] = now
 return stats, h, root
end
-- Открытие меню не списывает деньги. Каждая покупка снова проверяет расстояние.
local zones = {island=world, neon=city}
local function shopPart(zone, mode, eggId)
 if mode == "egg" then
  local egg=Config.Eggs[eggId]
  if not egg or (egg.World=="neon")~=(zone==city) then return end
  local stand=zone:FindFirstChild("EggStand"..eggId)
  if not stand then return end
  return stand.Interact,stand.Interact.OpenEggMenu
 end
 return zone.UpgradeShop.Counter, zone.UpgradeShop.Counter.OpenShop
end
for id,zone in pairs(zones) do
 local part,prompt=shopPart(zone,"upgrades")
 prompt.Triggered:Connect(function(p)
  if interact(p,part,prompt,zone==city) then openMenu:FireClient(p,"upgrades",id) end
 end)
 for eggId,egg in ipairs(Config.Eggs) do
  if egg.World==id then
   local eggPart,eggPrompt=shopPart(zone,"egg",eggId)
   eggPrompt.Triggered:Connect(function(p)
    if interact(p,eggPart,eggPrompt,zone==city) then openMenu:FireClient(p,"egg",id,eggId) end
   end)
  end
 end
end
buy.OnServerEvent:Connect(function(p, kind, zoneId, eggId)
 if type(kind) ~= "string" or type(zoneId) ~= "string" then return end
 if kind ~= "speed" and kind ~= "magnet" and kind ~= "income" and kind ~= "egg" then return end
 local zone = zones[zoneId]
 if not zone then return end
 if kind=="egg" and (type(eggId)~="number" or eggId~=math.floor(eggId)) then return end
 local part, prompt = shopPart(zone, kind == "egg" and "egg" or "upgrades",eggId)
 if not part then return end
 local stats, h = interact(p, part, prompt, zone == city)
 if not stats then return end
 local value, cost
 if kind == "speed" then
  value = stats.SpeedLevel.Value
  if value >= Config.MaxSpeedLevel then notify(p,"Speed is maxed!"); return end
  cost = Config.GetUpgradeCost(value)
 elseif kind == "magnet" then
  value = p:GetAttribute("MagnetLevel") or 0
  if value >= Config.MaxMagnetLevel then notify(p,"Magnet is maxed!"); return end
  cost = Config.GetMagnetUpgradeCost(value)
 elseif kind == "income" then
  value = p:GetAttribute("IncomeLevel") or 0
  if value >= Config.MaxIncomeLevel then notify(p,"Income is maxed!"); return end
  cost = Config.GetIncomeUpgradeCost(value)
 else
  if os.clock() < (hatchUntil[p] or 0) then return end
  cost = Config.Eggs[eggId].Cost
 end
 if stats.Coins.Value < cost then notify(p,"Not enough coins. Need " .. string.format("%g",cost-stats.Coins.Value)); return end
 stats.Coins.Value = stats.Coins.Value - cost
 if kind == "speed" then
  stats.SpeedLevel.Value = value+1
  h.WalkSpeed = Config.GetWalkSpeed(value+1)
  notify(p,"Speed: " .. h.WalkSpeed,true)
 elseif kind == "magnet" then
  p:SetAttribute("MagnetLevel",value+1)
  notify(p,string.format("Magnet radius: %.2f",Config.GetMagnetRadius(value+1)),true)
 elseif kind == "income" then
  p:SetAttribute("IncomeLevel",value+1)
  notify(p,"Income: x" .. Config.GetIncomeMultiplier(value+1),true)
 else
  hatchUntil[p] = os.clock()+3.5
  local result=Config.RollEgg(eggId,random:NextInteger(1,100000))
  local attribute = "PetOwned" .. result
  local count = (p:GetAttribute(attribute) or 0)+1
  p:SetAttribute(attribute,count)
  -- Автоматически сопровождает самый сильный из открытых питомцев.
  if Config.GetPetMultiplier(result)>Config.GetPetMultiplier(p:GetAttribute("PetLevel") or 0) then p:SetAttribute("PetLevel",result) end
  p:SetAttribute("EggsOpened",(p:GetAttribute("EggsOpened") or 0)+1)
  hatched:FireClient(p,result,count,eggId)
 end
end)

-- Загружаем именно аватар владельца; при ошибке сети остаётся видимый манекен.
task.spawn(function()
 local ok, avatar = pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(Config.ShopkeeperUserId) end)
 if not ok then warn("[CoinSprint] Не удалось загрузить аватар продавца: " .. tostring(avatar)); return end
 for _, zone in pairs(zones) do
  local shop = zone.UpgradeShop
  local npc = avatar:Clone()
  npc.Name = "Shopkeeper"
  local root=npc:FindFirstChild("HumanoidRootPart")
  for _,part in ipairs(npc:GetDescendants()) do
   if part:IsA("BasePart") then
    part.Anchored=part==root;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
   end
  end
  local humanoid=npc:FindFirstChildOfClass("Humanoid")
  if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;humanoid.AutoRotate=false end
  npc.Parent=shop
  local anchor=shop.VendorAnchor.Position
  npc:PivotTo(CFrame.new(anchor.X,anchor.Y+3,anchor.Z)*CFrame.Angles(0,math.pi,0))
  game:GetService("RunService").Heartbeat:Wait()
  local lowest=math.huge
  for _,name in ipairs({"LeftFoot","RightFoot","Left Leg","Right Leg"}) do
   local foot=npc:FindFirstChild(name)
   if foot then lowest=math.min(lowest,foot.Position.Y-foot.Size.Y/2) end
  end
  if lowest<math.huge then npc:PivotTo(npc:GetPivot()+Vector3.new(0,anchor.Y-lowest,0)) end
  local placeholder = shop:FindFirstChild("VendorPlaceholder")
  if placeholder then placeholder:Destroy() end
 end
 avatar:Destroy()
end)
local function portal(zone, name, target, needsLevel, destination)
 local part = zone:WaitForChild(name)
 local prompt = part:WaitForChild("EnterWorld")
 prompt.Triggered:Connect(function(p)
  local stats, _, root = interact(p, part, prompt, false)
  if not stats then return end
  if stats.SpeedLevel.Value < needsLevel then notify(p, "Requires speed 28 · buy 3 speed upgrades."); return end
  p.Character:PivotTo(CFrame.new(target))
  root.AssemblyLinearVelocity = Vector3.zero
  p:SetAttribute("CurrentWorld", destination)
  notify(p, "World: " .. destination, true)
 end)
end
portal(world, "PortalToNeon", Vector3.new(500, 3, 180), 3, "Neon District")
portal(city, "PortalToIsland", Vector3.new(0, 3+groundY, 180), 0, "Meadow Isles")

-- У каждой монеты одно серверное состояние для всех игроков.
local records = {}
for _, zone in ipairs({world, city}) do
 for _, coin in ipairs(zone:GetChildren()) do
  if coin:IsA("BasePart") and string.match(coin.Name, "^Coin_%d+$") then
   local record = {part = coin, available = true, value = zone == city and 25 or 5, required = zone == city and 3 or 0}
   table.insert(records, record)
   coin.CanCollide = false
   coin.CanTouch = false
   coin:SetAttribute("Available", true)
  end
 end
end
local function collect(record, p)
 if not record.available then return end
 local stats = p:FindFirstChild("leaderstats")
 if not stats then return end
 record.available = false
 record.part:SetAttribute("Available", false)
 record.part.Transparency = 1
 local label = record.part:FindFirstChild("GameLabel")
 if label then label.Enabled = false end
 local earned=record.value*Config.GetPetMultiplier(p:GetAttribute("PetLevel") or 0)*Config.GetIncomeMultiplier(p:GetAttribute("IncomeLevel") or 0)
 stats.Coins.Value=stats.Coins.Value+earned
 p:SetAttribute("LifetimeEarned",(p:GetAttribute("LifetimeEarned") or 0)+earned)
 p:SetAttribute("CoinsCollected",(p:GetAttribute("CoinsCollected") or 0)+1)
 task.delay(Config.CoinRespawnSeconds, function()
  if record.part.Parent then
   record.part.Transparency = 0
   if label then label.Enabled = true end
   record.available = true
   record.part:SetAttribute("Available", true)
  end
 end)
end
task.spawn(function()
 while world.Parent do
  local candidates = {}
  for _, p in ipairs(Players:GetPlayers()) do
   local h, root = alive(p)
   local stats = p:FindFirstChild("leaderstats")
   if h and stats and p:GetAttribute("ProfileReady") then
    table.insert(candidates, {p=p, root=root, level=stats.SpeedLevel.Value, radius=Config.GetMagnetRadius(p:GetAttribute("MagnetLevel") or 0)})
    if math.abs(root.Position.Z) <= 230 then
     if math.abs(root.Position.X) <= 150 then p:SetAttribute("CurrentWorld", "Meadow Isles")
     elseif math.abs(root.Position.X - 500) <= 150 then p:SetAttribute("CurrentWorld", "Neon District") end
    end
   end
  end
  for _, record in ipairs(records) do
   if record.available and record.part.Parent then
    local nearest, nearestDistance
    for _, candidate in ipairs(candidates) do
     local delta = candidate.root.Position - record.part.Position
     local distance = delta.X * delta.X + delta.Z * delta.Z
     if candidate.level >= record.required and math.abs(delta.Y) <= 6 and distance <= candidate.radius ^ 2 and (not nearestDistance or distance < nearestDistance) then
      nearest, nearestDistance = candidate.p, distance
     end
    end
    if nearest then collect(record, nearest) end
   end
  end
  task.wait(0.1)
 end
end)
print("[CoinSprint] Ready: 2 worlds, "..#records.." coins, 6 eggs, 60 pets")
