-- Script в ServerScriptService. Все награды и покупки проверяет сервер.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local AvatarPose = require(script.Parent:WaitForChild("AvatarPose"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local world = workspace:WaitForChild("CoinSpeedWorld")
if world:GetAttribute("ServerRunning") then return end
world:SetAttribute("ServerRunning", true)
local city = world:WaitForChild("NeonCity")
workspace.GlobalWind=Vector3.new(8,0,3)
workspace.Terrain:FillBlock(CFrame.new(250,-15,0),Vector3.new(1000,10,650),Enum.Material.Water)
workspace.Terrain:FillBlock(CFrame.new(0,-6,0),Vector3.new(300,12,460),Enum.Material.Grass)
workspace.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(104,196,84))
workspace.Terrain:SetMaterialColor(Enum.Material.Cobblestone,Color3.fromRGB(198,178,146))
-- Пруд и ручей: рельеф и украшения в модуле Pond (вода ниже травы, песчаный берег).
local Pond=require(script.Parent:WaitForChild("Pond"))
Pond.Terrain()
-- Grass belongs beside the paths, never through the plaza, shop or egg approach.
for _,path in ipairs(world:GetChildren()) do
 if path:IsA("BasePart") and (string.find(path.Name,"Path",1,true) or path.Name=="ArrivalPlaza") then
  -- Дорожка — брусчатка ландшафта шире самой детали: поверхность рельефа выше детали-дорожки,
  -- поэтому видно именно материал ландшафта, а узкую полосу трава закрыла бы целиком.
  workspace.Terrain:FillBlock(CFrame.new(path.Position.X,-2,path.Position.Z),Vector3.new(path.Size.X+6,4,path.Size.Z+6),Enum.Material.Cobblestone)
 end
end
workspace.Terrain:FillBlock(CFrame.new(-45,-2,140),Vector3.new(31,4,24),Enum.Material.Ground)
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
-- Камни, камыши, кувшинки, мостик и причал ставим уже на готовый рельеф.
task.spawn(Pond.Decorate,world)
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
 for i=1,#Config.Eggs do player:SetAttribute("IndexClaimed" .. i, false) end
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
 PlayerSystems.Setup(player)
 player.RespawnLocation = world.Start
 local function characterAdded(character)
  local h = character:WaitForChild("Humanoid", 10)
  if h and player.Character == character then PlayerSystems.ApplySpeed(player) end
  player:SetAttribute("CurrentWorld", "Meadow Isles")
 end
 player.CharacterAdded:Connect(characterAdded)
 if player.Character then task.spawn(characterAdded, player.Character) end
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(p) cooldown[p] = nil; hatchUntil[p] = nil end)
for _, p in ipairs(Players:GetPlayers()) do setup(p) end

local function notify(p, text, success) feedback:FireClient(p, text, success or false) end
PlayerSystems.SetNotifier(notify)
-- Действия из инвентаря: надеть/снять питомца, лучшие, снять всех, выпить зелье, взять магнит.
local action = Instance.new("RemoteEvent")
action.Name = "GameAction"
action.Parent = ReplicatedStorage
local actionCooldown = {}
action.OnServerEvent:Connect(function(p, kind, arg)
 if type(kind) ~= "string" or not p:GetAttribute("ProfileReady") then return end
 if os.clock() - (actionCooldown[p] or 0) < 0.15 then return end
 actionCooldown[p] = os.clock()
 if kind == "equip" and type(arg) == "number" then
  local list = PlayerSystems.GetEquipped(p)
  if #list >= ShopConfig.MaxEquipped then notify(p, "Only 3 pets can follow you. Unequip one first."); return end
  table.insert(list, arg)
  PlayerSystems.SetEquipped(p, list)
 elseif kind == "unequip" and type(arg) == "number" then
  local list = PlayerSystems.GetEquipped(p)
  for i, id in ipairs(list) do if id == arg then table.remove(list, i); break end end
  PlayerSystems.SetEquipped(p, list)
 elseif kind == "best" then
  PlayerSystems.EquipBest(p)
 elseif kind == "none" then
  PlayerSystems.SetEquipped(p, {})
 elseif kind == "potion" and type(arg) == "string" then
  PlayerSystems.UsePotion(p, arg)
 elseif kind == "magnet" and type(arg) == "number" then
  PlayerSystems.EquipMagnet(p, arg)
 end
end)
Players.PlayerRemoving:Connect(function(p) actionCooldown[p] = nil end)
-- Награда за полностью собранную страницу индекса (все питомцы одного яйца). Один раз на яйцо.
local claimIndex = Instance.new("RemoteEvent")
claimIndex.Name = "GameIndexClaim"
claimIndex.Parent = ReplicatedStorage
local claimCooldown = {}
claimIndex.OnServerEvent:Connect(function(p, eggId)
 if type(eggId) ~= "number" or eggId ~= math.floor(eggId) or not Config.Eggs[eggId] then return end
 if not p:GetAttribute("ProfileReady") or p:GetAttribute("IndexClaimed" .. eggId) then return end
 if os.clock() - (claimCooldown[p] or 0) < 1 then return end
 claimCooldown[p] = os.clock()
 for _, entry in ipairs(Config.Eggs[eggId].Pool) do
  if (p:GetAttribute("PetOwned" .. entry.Pet) or 0) <= 0 then notify(p, "Collect every pet from this egg first!"); return end
 end
 local stats = p:FindFirstChild("leaderstats")
 if not stats then return end
 local reward = Config.GetIndexReward(eggId)
 p:SetAttribute("IndexClaimed" .. eggId, true)
 stats.Coins.Value = stats.Coins.Value + reward
 notify(p, "Index reward: +" .. reward .. " coins!", true)
end)
Players.PlayerRemoving:Connect(function(p) claimCooldown[p] = nil end)
local function interact(p, part, prompt, cityOnly)
 -- У яиц нет подсказки E: меню открывается касанием, поэтому prompt может быть nil.
 if p.Parent ~= Players or (prompt and not prompt.Enabled) then return end
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
  return stand.Interact,stand.Interact:FindFirstChild("OpenEggMenu")
 end
 local zonePart = zone.UpgradeShop:FindFirstChild("ShopZone")
 if zonePart then return zonePart, nil end
 return zone.UpgradeShop.Counter, zone.UpgradeShop.Counter:FindFirstChild("OpenShop")
end
for id,zone in pairs(zones) do
 local part,prompt=shopPart(zone,"upgrades")
 if prompt then prompt.Triggered:Connect(function(p)
  if interact(p,part,prompt,zone==city) then openMenu:FireClient(p,"upgrades",id) end
 end) end
end
-- Меню яйца открывает клиент, когда персонаж касается яйца (ShopUI); покупку проверяет сервер ниже.
buy.OnServerEvent:Connect(function(p, kind, zoneId, eggId)
 if type(kind) ~= "string" or type(zoneId) ~= "string" then return end
 if kind == "magnettool" or kind == "potion" then
  -- Магазин магнитов: магниты и зелья, только рядом с его зелёным кругом.
  local shop = world:FindFirstChild("MagnetShop")
  local zonePart = shop and shop:FindFirstChild("ShopZone")
  if not zonePart then return end
  local stats = interact(p, zonePart, nil, false)
  if not stats then return end
  local cost, name
  if kind == "magnettool" then
   local def = type(eggId) == "number" and ShopConfig.Magnets[eggId]
   if not def then return end
   if eggId <= (p:GetAttribute("MagnetTier") or 1) then PlayerSystems.EquipMagnet(p, eggId); return end
   if eggId ~= (p:GetAttribute("MagnetTier") or 1) + 1 then notify(p, "Buy the previous magnet first!"); return end
   cost, name = def.Price, def.Name
  else
   local def = type(eggId) == "string" and ShopConfig.Potions[eggId]
   if not def then return end
   cost, name = def.Price, def.Name
  end
  if stats.Coins.Value < cost then notify(p,"Not enough coins. Need " .. string.format("%g",cost-stats.Coins.Value)); return end
  stats.Coins.Value = stats.Coins.Value - cost
  if kind == "magnettool" then
   p:SetAttribute("MagnetTier", eggId)
   PlayerSystems.EquipMagnet(p, eggId)
  else
   p:SetAttribute("Potion" .. eggId, (p:GetAttribute("Potion" .. eggId) or 0) + 1)
   notify(p, "Bought " .. name .. "! Use it in your inventory.", true)
  end
  return
 end
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
  PlayerSystems.ApplySpeed(p)
  notify(p,"Speed: " .. Config.GetWalkSpeed(value+1),true)
 elseif kind == "magnet" then
  p:SetAttribute("MagnetLevel",value+1)
  notify(p,string.format("Magnet radius: %.2f",Config.GetMagnetRadius(value+1)),true)
 elseif kind == "income" then
  p:SetAttribute("IncomeLevel",value+1)
  notify(p,"Income: x" .. Config.GetIncomeMultiplier(value+1),true)
 else
  hatchUntil[p] = os.clock()+3.5
  local result=Config.RollEgg(eggId,random:NextInteger(1,100000))
  -- Зелье удачи: два броска, остаётся более редкий питомец.
  if PlayerSystems.PotionActive(p, "Luck") then
   local second=Config.RollEgg(eggId,random:NextInteger(1,100000))
   if Config.GetPetMultiplier(second)>Config.GetPetMultiplier(result) then result=second end
  end
  local attribute = "PetOwned" .. result
  local count = (p:GetAttribute(attribute) or 0)+1
  p:SetAttribute(attribute,count)
  -- Автоматически сопровождает самый сильный из открытых питомцев.
  PlayerSystems.OnHatched(p, result)
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
  AvatarPose.Prepare(npc)
  npc.Parent=shop
  -- Если за прилавком есть стул (VendorSeatPoint — точка на сиденье), продавец сидит.
  local seatPoint=shop:FindFirstChild("VendorSeatPoint")
  if seatPoint then
   AvatarPose.Sit(npc)
   AvatarPose.Place(npc,seatPoint.Position,CFrame.Angles(0,math.pi,0),seatPoint.Position.Y,true)
  else
   local anchor=shop.VendorAnchor.Position
   AvatarPose.Place(npc,anchor,CFrame.Angles(0,math.pi,0),anchor.Y,false)
  end
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
-- Неонград можно передвигать в Studio: координаты берём с его пола, а не из кода.
local neonX = city.Floor.Position.X
portal(world, "PortalToNeon", Vector3.new(neonX, 3, 180), 3, "Neon District")
portal(city, "PortalToIsland", Vector3.new(0, 3+groundY, 180), 0, "Meadow Isles")

-- Метки магазина: Cylinder-деталь ShopZone внутри UpgradeShop (ось цилиндра — X, диаметр — Size.Z).
local shopZones, insideZone = {}, {}
for id, zone in pairs(zones) do
 local zonePart = zone.UpgradeShop:FindFirstChild("ShopZone")
 if zonePart then shopZones[id] = zonePart end
end
do
 local magnetShop = world:FindFirstChild("MagnetShop")
 local zonePart = magnetShop and magnetShop:FindFirstChild("ShopZone")
 if zonePart then shopZones.magnets = zonePart end
end
Players.PlayerRemoving:Connect(function(p) for key in pairs(insideZone) do if string.find(key, ":" .. p.UserId, 1, true) then insideZone[key] = nil end end end)

-- У каждой монеты одно серверное состояние для всех игроков.
local records = {}
for _, zone in ipairs({world, city}) do
 for _, coin in ipairs(zone:GetChildren()) do
  if coin:IsA("BasePart") and string.match(coin.Name, "^Coin_%d+$") then
   local record = {part = coin, available = true, value = coin:GetAttribute("Value") or (zone == city and 25 or 5), required = zone == city and 3 or 0}
   table.insert(records, record)
   coin.CanCollide = false
   coin.CanTouch = false
   coin:SetAttribute("Available", true)
  end
 end
end
-- Монета состоит из детали и её украшений (SurfaceGui, свет): прячем и показываем всё вместе.
local function setCoinVisible(part, visible)
 part.Transparency = visible and 0 or 1
 for _, d in ipairs(part:GetDescendants()) do
  if d:IsA("LayerCollector") or d:IsA("Light") or d:IsA("ParticleEmitter") then d.Enabled = visible end
 end
end
local function collect(record, p)
 if not record.available then return end
 local stats = p:FindFirstChild("leaderstats")
 if not stats then return end
 record.available = false
 record.part:SetAttribute("Available", false)
 setCoinVisible(record.part, false)
 local earned=record.value*PlayerSystems.CoinMultiplier(p)
 stats.Coins.Value=stats.Coins.Value+earned
 p:SetAttribute("LifetimeEarned",(p:GetAttribute("LifetimeEarned") or 0)+earned)
 p:SetAttribute("CoinsCollected",(p:GetAttribute("CoinsCollected") or 0)+1)
 task.delay(Config.CoinRespawnSeconds, function()
  if record.part.Parent then
   setCoinVisible(record.part, true)
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
    table.insert(candidates, {p=p, root=root, level=stats.SpeedLevel.Value, radius=PlayerSystems.MagnetRadius(p)})
    -- Зелёная метка у киоска: зашёл в круг — меню магазина открылось (один раз на вход).
    for id, zonePart in pairs(shopZones) do
     local offset = root.Position - zonePart.Position
     local inside = Vector2.new(offset.X, offset.Z).Magnitude <= zonePart.Size.Z / 2 and math.abs(offset.Y) < 8
     local key = id .. ":" .. p.UserId
     if inside and not insideZone[key] and (id ~= "neon" or stats.SpeedLevel.Value >= 3) then
      if id == "magnets" then openMenu:FireClient(p, "magnets", "island") else openMenu:FireClient(p, "upgrades", id) end
     end
     insideZone[key] = inside or nil
    end
    if math.abs(root.Position.Z) <= 230 then
     if math.abs(root.Position.X) <= 150 then p:SetAttribute("CurrentWorld", "Meadow Isles")
     elseif math.abs(root.Position.X - neonX) <= 150 then p:SetAttribute("CurrentWorld", "Neon District") end
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
print("[CoinSprint] Ready: 2 worlds, "..#records.." coins, "..#Config.Eggs.." eggs, "..#Config.Pets.." pets")
