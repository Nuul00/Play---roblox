-- Script в ServerScriptService. Все награды и покупки проверяет сервер.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local AvatarPose = require(script.Parent:WaitForChild("AvatarPose"))
local PlayerSystems = require(script.Parent:WaitForChild("PlayerSystems"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local PetAbilities = require(ReplicatedStorage:WaitForChild("PetAbilities"))
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
-- Третий мир Sky Isles строится кодом высоко в небе (модуль SkyIsles).
local SkyIsles=require(script.Parent:WaitForChild("SkyIsles"))
local sky=SkyIsles.Build(world)
-- Четвёртый мир Frozen Peaks (модуль FrozenPeaks), вход — ледяная арка на Sky Isles.
local FrozenPeaks=require(script.Parent:WaitForChild("FrozenPeaks"))
local frozen=FrozenPeaks.Build(world)
FrozenPeaks.BuildSkyPortal(sky)
-- Пятый и шестой миры: Magma Volcano (вход — арка во Frozen Peaks) и Cosmic Galaxy (арка в вулкане).
local MagmaVolcano=require(script.Parent:WaitForChild("MagmaVolcano"))
local volcano=MagmaVolcano.Build(world)
MagmaVolcano.BuildFrozenPortal(frozen)
local CosmicGalaxy=require(script.Parent:WaitForChild("CosmicGalaxy"))
local galaxy=CosmicGalaxy.Build(world)
-- Камни, камыши, кувшинки, мостик и причал ставим уже на готовый рельеф.
task.spawn(Pond.Decorate,world)
local sunsetStand=world:WaitForChild("EggStand1")
local oldEgg=sunsetStand:WaitForChild("EggDisplay")
local sunsetEgg=require(ReplicatedStorage:WaitForChild("SunsetVisuals")).BuildEgg()
local eggBounds=oldEgg:GetBoundingBox()
sunsetEgg:PivotTo(CFrame.new(eggBounds.Position));oldEgg:Destroy();sunsetEgg.Parent=sunsetStand
sunsetStand:SetAttribute("SunsetReady",true)
-- Яйца Sakura и Starlight (2 и 3) строятся так же, на месте старых моделей.
for id,theme in pairs({[2]="Sakura",[3]="Starlight"}) do
 local stand=world:WaitForChild("EggStand"..id)
 local old=stand:WaitForChild("EggDisplay")
 local egg=require(ReplicatedStorage:WaitForChild("ThemedVisuals")).BuildEgg(theme)
 local bounds=old:GetBoundingBox()
 egg:PivotTo(CFrame.new(bounds.Position));old:Destroy();egg.Parent=stand
 stand:SetAttribute("EggReady",true)
end
sunsetStand:SetAttribute("EggReady",true)
-- Three independent neon collections. Keep stand positions and interaction parts intact.
local NeonVisuals=require(ReplicatedStorage:WaitForChild("NeonVisuals"))
for id,theme in pairs({[4]="Disco",[5]="Tech",[6]="City"}) do
 local stand=city:WaitForChild("EggStand"..id)
 local old=stand:WaitForChild("EggDisplay")
 local bounds=old:GetBoundingBox()
 local egg=NeonVisuals.BuildEgg(theme)
 egg:PivotTo(CFrame.new(bounds.Position));old:Destroy();egg.Parent=stand
 stand:SetAttribute("EggReady",true)
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
-- Серверные сигналы для других систем (квестовая линия, ребёрс): кто сколько яиц открыл и монет собрал.
local signals = game:GetService("ServerStorage"):FindFirstChild("ServerSignals") or Instance.new("Folder")
signals.Name = "ServerSignals"
signals.Parent = game:GetService("ServerStorage")
local function signal(name)
 local e = signals:FindFirstChild(name) or Instance.new("BindableEvent")
 e.Name = name
 e.Parent = signals
 return e
end
local eggsSignal = signal("EggsHatched") -- (player, eggId, amount, results)
local coinSignal = signal("CoinCollected") -- (player, earned, worldName)
local hatched = Instance.new("RemoteEvent")
hatched.Name = "GameHatched"
-- Объявление всем игрокам о редком выпадении (Legendary и выше).
local announce = Instance.new("RemoteEvent")
announce.Name = "GameAnnounce"
announce.Parent = ReplicatedStorage
local superAnnounce = Instance.new("RemoteEvent")
superAnnounce.Name = "SuperSecretAnnounce"
superAnnounce.Parent = ReplicatedStorage
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
 player:SetAttribute("DoubleLevel", 0)
 player:SetAttribute("Rebirths", 0)
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
  local maxEquipped = PlayerSystems.MaxEquipped(p)
  if #list >= maxEquipped then notify(p, "Only " .. maxEquipped .. " pets can follow you. Unequip one first."); return end
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
 elseif kind == "autodelete" and type(arg) == "number" and Config.Pets[arg] then
  p:SetAttribute("AutoDelete" .. arg, not p:GetAttribute("AutoDelete" .. arg))
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
 PlayerSystems.RefreshIndexBonus(p)
 stats.Coins.Value = stats.Coins.Value + reward
 notify(p, "Index reward: +" .. reward .. " coins and +" .. math.floor(ShopConfig.IndexBonusPerPage * 100 + 0.5) .. "% coins forever!", true)
end)
Players.PlayerRemoving:Connect(function(p) claimCooldown[p] = nil end)
local function interact(p, part, prompt, minLevel)
 -- У яиц нет подсказки E: меню открывается касанием, поэтому prompt может быть nil.
 if p.Parent ~= Players or (prompt and not prompt.Enabled) then return end
 if not p:GetAttribute("ProfileReady") then return end
 local h, root = alive(p)
 if not h or (root.Position - part.Position).Magnitude > Config.ShopDistance then return end
 local stats = p:FindFirstChild("leaderstats")
 if not stats then return end
 local need = type(minLevel) == "number" and minLevel or (minLevel and 3 or 0)
 if stats.SpeedLevel.Value < need then return end
 local now = os.clock()
 if now - (cooldown[p] or -math.huge) < Config.PurchaseCooldown then return end
 cooldown[p] = now
 return stats, h, root
end
-- Открытие меню не списывает деньги. Каждая покупка снова проверяет расстояние.
local zones = {island=world, neon=city, sky=sky, frozen=frozen, volcano=volcano, galaxy=galaxy}
local ZONE_LEVEL = {[city]=3, [sky]=6, [frozen]=10, [volcano]=13, [galaxy]=16}
local function shopPart(zone, mode, eggId)
 if mode == "egg" then
  local egg=Config.Eggs[eggId]
  if not egg or zones[egg.World]~=zone then return end
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
  if interact(p,part,prompt,ZONE_LEVEL[zone]) then openMenu:FireClient(p,"upgrades",id) end
 end) end
end
-- Меню яйца открывает клиент, когда персонаж касается яйца (ShopUI); покупку проверяет сервер ниже.
-- Апгрейды киоска: у каждого свой уровень, цена и максимум; предел зоны — Config.ZoneMax.
local UPGRADES = {
 speed = { name = "Speed", max = Config.MaxSpeedLevel, cost = Config.GetUpgradeCost,
  get = function(_p, stats) return stats.SpeedLevel.Value end,
  set = function(p, stats, v) stats.SpeedLevel.Value = v; PlayerSystems.ApplySpeed(p) end },
 magnet = { name = "Magnet", max = Config.MaxMagnetLevel, cost = Config.GetMagnetUpgradeCost,
  get = function(p) return p:GetAttribute("MagnetLevel") or 0 end,
  set = function(p, _s, v) p:SetAttribute("MagnetLevel", v) end },
 income = { name = "Coins", max = Config.MaxIncomeLevel, cost = Config.GetIncomeUpgradeCost,
  get = function(p) return p:GetAttribute("IncomeLevel") or 0 end,
  set = function(p, _s, v) p:SetAttribute("IncomeLevel", v) end },
 double = { name = "Double coin", max = Config.MaxDoubleLevel, cost = Config.GetDoubleUpgradeCost,
  get = function(p) return p:GetAttribute("DoubleLevel") or 0 end,
  set = function(p, _s, v) p:SetAttribute("DoubleLevel", v) end },
}
buy.OnServerEvent:Connect(function(p, kind, zoneId, eggId, amount)
 if kind == "egg" then
  amount = amount == nil and 1 or amount
  if amount ~= 1 and amount ~= 3 and amount ~= 9 then return end -- ×1 [E], ×3 [R], ×9 [T]
 end
 if type(kind) ~= "string" or type(zoneId) ~= "string" then return end
 if kind == "magnettool" or kind == "potion" then
  -- Магазин магнитов: магниты и зелья, только рядом с его зелёным кругом.
  -- Какой магазин магнитов рядом: от него зависит, какие магниты можно купить (def.World).
  local stats, shopWorld
  for _, candidate in ipairs({{world, 0, "Meadow Isles"}, {sky, 6, "Sky Isles"}, {frozen, 10, "Frozen Peaks"}, {volcano, 13, "Magma Volcano"}, {galaxy, 16, "Cosmic Galaxy"}}) do
   local shop = candidate[1] and candidate[1]:FindFirstChild("MagnetShop")
   local zonePart = shop and shop:FindFirstChild("ShopZone")
   if zonePart then
    stats = interact(p, zonePart, nil, candidate[2])
    if stats then shopWorld = candidate[3]; break end
   end
  end
  if not stats then return end
  local cost, name
  if kind == "magnettool" then
   local def = type(eggId) == "number" and ShopConfig.Magnets[eggId]
   if not def then return end
   if eggId <= (p:GetAttribute("MagnetTier") or 1) then
    -- Повторное нажатие на магнит в руках снимает его, на любой другой купленный — надевает.
    if eggId == (p:GetAttribute("MagnetEquipped") or 1) and not p:GetAttribute("MagnetOff") then
     PlayerSystems.UnequipMagnet(p)
    else
     PlayerSystems.EquipMagnet(p, eggId)
    end
    return
   end
   if def.World and def.World ~= shopWorld then notify(p, "This magnet is sold in " .. def.World); return end
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
 if not UPGRADES[kind] and kind ~= "egg" then return end
 local zone = zones[zoneId]
 if not zone then return end
 if kind=="egg" and (type(eggId)~="number" or eggId~=math.floor(eggId)) then return end
 local part, prompt = shopPart(zone, kind == "egg" and "egg" or "upgrades",eggId)
 if not part then return end
 local stats, h = interact(p, part, prompt, ZONE_LEVEL[zone])
 if not stats then return end
 local value, cost
 if kind == "egg" then
  if os.clock() < (hatchUntil[p] or 0) then return end
  cost = Config.Eggs[eggId].Cost * amount
 else
  local up = UPGRADES[kind]
  value = up.get(p, stats)
  if value >= up.max then notify(p, up.name .. " is maxed!"); return end
  if value >= (Config.ZoneMax[zoneId] or Config.BaseMaxLevel) then notify(p, "Higher levels are sold in the next world"); return end
  cost = up.cost(value)
 end
 if stats.Coins.Value < cost then notify(p,"Not enough coins. Need " .. string.format("%g",cost-stats.Coins.Value)); return end
 stats.Coins.Value = stats.Coins.Value - cost
 if kind ~= "egg" then
  UPGRADES[kind].set(p, stats, value + 1) else
  hatchUntil[p] = os.clock()+(p:GetAttribute("Pass_FastHatch") and 1.2 or 3.5) -- Fast Hatch: открытие в 3 раза быстрее
  local results={}
  -- Удача питомцев (AbilLuck) и ребёрсов (RebirthLuck): шанс лишнего броска, остаётся лучший.
  -- Супер «Lucky Aura» даёт лишний бросок всегда и ещё немного удачи сверху.
  local extraLuck=(p:GetAttribute("AbilLuck") or 0)+(tonumber(p:GetAttribute("RebirthLuck")) or 0)
  local aura=PetAbilities.ParseSupers(p:GetAttribute("PetSupers")).LuckyAura
  if aura then extraLuck+=1+PetAbilities.SuperParams("LuckyAura",aura).Luck end
  extraLuck=math.clamp(extraLuck,0,3)
  -- Геймпассы «Super Luck» (+2 броска, шанс супер-секреток ×2) и «Mythic Luck» (+1 бросок, ×5).
  if p:GetAttribute("Pass_SuperLuck") then extraLuck+=2 end
  if p:GetAttribute("Pass_MythicLuck") then extraLuck+=1 end
  local superMult=(p:GetAttribute("Pass_SuperLuck") and 2 or 1)*(p:GetAttribute("Pass_MythicLuck") and 5 or 1)
  if RunService:IsStudio() then superMult*=tonumber(workspace:GetAttribute("DebugSuperOdds")) or 1 end
  local superHits={}
  for _=1,amount do
  local result=Config.RollEgg(eggId,random:NextInteger(1,100000))
  local superPet=Config.RollSuper(eggId,random:NextNumber(),superMult)
  -- Зелье удачи: два броска, остаётся более редкий питомец.
  if PlayerSystems.PotionActive(p, "Luck") or PlayerSystems.EventActive("Lucky") then
   local second=Config.RollEgg(eggId,random:NextInteger(1,100000))
   if Config.GetPetMultiplier(second)>Config.GetPetMultiplier(result) then result=second end
  end
  -- Геймпасс «2x Luck» и буст удачи из магазина: ещё один бросок, остаётся лучший.
  if p:GetAttribute("Pass_Luck2x") or p:GetAttribute("LuckBoostActive") then
   local again=Config.RollEgg(eggId,random:NextInteger(1,100000))
   if Config.GetPetMultiplier(again)>Config.GetPetMultiplier(result) then result=again end
  end
  local luckLeft=extraLuck
  while luckLeft>0 do
   if luckLeft>=1 or random:NextNumber()<luckLeft then
    local again=Config.RollEgg(eggId,random:NextInteger(1,100000))
    if Config.GetPetMultiplier(again)>Config.GetPetMultiplier(result) then result=again end
   end
   luckLeft-=1
  end
  -- Гарантия: после N питомцев без нужной редкости выдаём её из пула этого яйца.
  local forced
  result, forced = PlayerSystems.ApplyPity(p, eggId, result)
  if superPet then result=superPet; forced=false; table.insert(superHits,superPet) end
  local attribute = "PetOwned" .. result
  local deleted=p:GetAttribute("AutoDelete"..result)==true
  local count = (p:GetAttribute(attribute) or 0)+(deleted and 0 or 1)
  if not deleted then p:SetAttribute(attribute,count) end
  -- Автоматически сопровождает самый сильный из открытых питомцев.
  if not deleted then PlayerSystems.OnHatched(p, result) end
  table.insert(results,{Pet=result,Count=count,Deleted=deleted,Forced=forced})
  end
  p:SetAttribute("EggsOpened",(p:GetAttribute("EggsOpened") or 0)+amount)
  hatched:FireClient(p,results,eggId)
  eggsSignal:Fire(p,eggId,amount,results)
  -- Лучшее редкое выпадение из пачки видят все на сервере.
  local best
  for _,r in ipairs(results) do
   if PlayerSystems.RarityRank(r.Pet)>=ShopConfig.AnnounceRank and (not best or PlayerSystems.RarityRank(r.Pet)>PlayerSystems.RarityRank(best.Pet)) then best=r end
  end
  if best then announce:FireAllClients(p.DisplayName,best.Pet,best.Forced==true) end
  -- Супер-секретки: отдельное объявление в чат всем на сервере.
  for _,id in ipairs(superHits) do superAnnounce:FireAllClients(p.DisplayName,id) end
 end
end)

-- Загружаем именно аватар владельца; при ошибке сети остаётся видимый манекен.
task.spawn(function()
 local ok, avatar = pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(Config.ShopkeeperUserId) end)
 if not ok then warn("[CoinSprint] Не удалось загрузить аватар продавца: " .. tostring(avatar)); return end
 for _, zone in pairs(zones) do
  local shop = zone.UpgradeShop
  if shop:GetAttribute("NoVendor") then continue end -- пустой прилавок без продавца (Sky Isles)
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
   AvatarPose.Place(npc,anchor,CFrame.Angles(0,shop.VendorAnchor:GetAttribute("Yaw") or math.pi,0),anchor.Y,false)
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
 local skyMagnets = sky:FindFirstChild("MagnetShop")
 local skyZone = skyMagnets and skyMagnets:FindFirstChild("ShopZone")
 if skyZone then shopZones.skymagnets = skyZone end
 local frozenMagnets = frozen and frozen:FindFirstChild("MagnetShop")
 local frozenZone = frozenMagnets and frozenMagnets:FindFirstChild("ShopZone")
 if frozenZone then shopZones.frozenmagnets = frozenZone end
 for key, m in pairs({volcanomagnets = volcano, galaxymagnets = galaxy}) do
  local shop = m and m:FindFirstChild("MagnetShop")
  local z = shop and shop:FindFirstChild("ShopZone")
  if z then shopZones[key] = z end
 end
end
local SHOP_LEVEL = {neon = 3, sky = 6, skymagnets = 6, frozen = 10, frozenmagnets = 10, volcano = 13, volcanomagnets = 13, galaxy = 16, galaxymagnets = 16}
Players.PlayerRemoving:Connect(function(p) for key in pairs(insideZone) do if string.find(key, ":" .. p.UserId, 1, true) then insideZone[key] = nil end end end)

-- Виды монет Meadow и Неонграда (CoinTypes): ценность, размер, цвет и сияние. Монеты стоят в месте,
-- здесь им только раздаются виды; Sky Isles раздаёт виды сам при постройке.
local CoinTypes = require(ReplicatedStorage:WaitForChild("CoinTypes"))
-- Монет в Meadow и Неонграде было втрое реже, чем в Sky/Frozen (40 на большой мир). Досыпаем копии
-- имеющихся монет на землю в границах, где они уже лежат, чтобы плотность была ~1.4 на 1000 кв. стадов.
do
 local rayP = RaycastParams.new()
 rayP.FilterType = Enum.RaycastFilterType.Exclude
 local function fill(zone, target)
  local list = {}
  for _, c in ipairs(zone:GetChildren()) do
   if c:IsA("BasePart") and string.match(c.Name, "^Coin_%d+$") then table.insert(list, c) end
  end
  if #list == 0 or #list >= target then return end
  local x0, x1, z0, z1, maxN = math.huge, -math.huge, math.huge, -math.huge, 0
  for _, c in ipairs(list) do
   x0, x1 = math.min(x0, c.Position.X), math.max(x1, c.Position.X)
   z0, z1 = math.min(z0, c.Position.Z), math.max(z1, c.Position.Z)
   maxN = math.max(maxN, tonumber(string.match(c.Name, "%d+")) or 0)
  end
  rayP.FilterDescendantsInstances = list
  -- высота монеты над землёй берём с первой монеты
  local t = list[1]
  local g = workspace:Raycast(t.Position + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), rayP)
  local lift = g and (t.Position.Y - g.Position.Y) or 2.6
  local rng = Random.new(77)
  local spots = {}
  for _, c in ipairs(list) do table.insert(spots, c.Position) end
  local n = #list
  for _ = 1, target * 40 do
   if n >= target then break end
   local x, z = rng:NextNumber(x0, x1), rng:NextNumber(z0, z1)
   local hit = workspace:Raycast(Vector3.new(x, t.Position.Y + 80, z), Vector3.new(0, -160, 0), rayP)
   -- только открытая земля: ровная, большая деталь или Terrain (не крыша/лавка/дерево)
   local ok = hit and hit.Normal.Y > 0.9 and (hit.Instance:IsA("Terrain") or (hit.Instance:IsA("BasePart") and math.max(hit.Instance.Size.X, hit.Instance.Size.Z) > 30))
   if ok and math.abs(hit.Position.Y + lift - t.Position.Y) < 12 then
    local pos = Vector3.new(x, hit.Position.Y + lift, z)
    local free = true
    for _, q in ipairs(spots) do
     if (q - pos).Magnitude < 7 then free = false; break end
    end
    if free then
     n += 1; maxN += 1
     local c = t:Clone()
     c.Name = "Coin_" .. maxN
     c.Position = pos
     for _, d in ipairs(c:GetChildren()) do
      if d:IsA("Light") or d:IsA("ParticleEmitter") then d:Destroy() end -- сияние раздаст CoinTypes ниже
     end
     c.Parent = zone
     table.insert(spots, pos)
    end
   end
  end
 end
 fill(world, 115)
 fill(city, 90)
end
for zone, worldId in pairs({[world] = "Meadow", [city] = "Neon"}) do
 for _, coin in ipairs(zone:GetChildren()) do
  if coin:IsA("BasePart") and string.match(coin.Name, "^Coin_%d+$") then
   local kind, rarity = CoinTypes.Pick(worldId, tonumber(string.match(coin.Name, "%d+")))
   local d = CoinTypes.BaseSize[worldId] * kind.Scale
   coin.Size = Vector3.new(coin.Size.X, d, d) -- ось цилиндра — X, диаметр — Y и Z
   coin.Color = kind.Color
   CoinTypes.Mark(coin, worldId, kind, rarity)
   CoinTypes.AddGlow(coin, kind.Color, rarity)
  end
 end
end

-- У каждой монеты одно серверное состояние для всех игроков.
local records = {}
for _, zone in ipairs({world, city, sky, frozen, volcano, galaxy}) do
 for _, coin in ipairs(zone:GetChildren()) do
  if coin:IsA("BasePart") and string.match(coin.Name, "^Coin_%d+$") then
   local record = {part = coin, available = true, value = coin:GetAttribute("Value") or (zone == city and 25 or 5), required = ZONE_LEVEL[zone] or 0, zone = zone}
   table.insert(records, record)
   coin.CanCollide = false
   coin.CanTouch = false
   coin:SetAttribute("Available", true)
  end
 end
end
-- Монеты по мирам: каждый игрок проверяется только с монетами своего мира (было: все ~800 × все игроки).
local ZONE_NAME = {}
for _, pair in ipairs({{world, "Meadow Isles"}, {city, "Neon District"}, {sky, "Sky Isles"}, {frozen, "Frozen Peaks"}, {volcano, "Magma Volcano"}, {galaxy, "Cosmic Galaxy"}}) do
 if pair[1] then ZONE_NAME[pair[1]] = pair[2] end
end
local recordsByWorld = {}
for _, record in ipairs(records) do
 local name = ZONE_NAME[record.zone] or "Meadow Isles"
 recordsByWorld[name] = recordsByWorld[name] or {}
 table.insert(recordsByWorld[name], record)
end
-- Супер-способности питомцев приходят строкой: разбираем один раз на каждую новую строку.
local superMemo = {}
local function supersOf(p)
 local raw = p:GetAttribute("PetSupers")
 local key = tostring(raw)
 local parsed = superMemo[key]
 if not parsed then
  parsed = PetAbilities.ParseSupers(raw)
  superMemo[key] = parsed
 end
 return parsed
end
-- Монета состоит из детали и её украшений (SurfaceGui, свет): прячем и показываем всё вместе.
-- Список украшений собираем один раз на монету, а не обходим потомков при каждом сборе.
local coinFX = setmetatable({}, {__mode = "k"})
local function setCoinVisible(part, visible)
 part.Transparency = visible and 0 or 1
 local list = coinFX[part]
 if not list then
  list = {}
  for _, d in ipairs(part:GetDescendants()) do
   if d:IsA("LayerCollector") or d:IsA("Light") or d:IsA("ParticleEmitter") then table.insert(list, d) end
  end
  coinFX[part] = list
 end
 for _, d in ipairs(list) do d.Enabled = visible end
end
local function collect(record, p)
 if not record.available then return end
 local stats = p:FindFirstChild("leaderstats")
 if not stats then return end
 record.available = false
 record.part:SetAttribute("Available", false)
 setCoinVisible(record.part, false)
 local earned=record.value*PlayerSystems.CoinMultiplier(p)
 -- Апгрейд «двойная монета» + способность питомцев: шанс получить награду x2.
 local doubleChance=Config.GetDoubleChance(p:GetAttribute("DoubleLevel") or 0)+(p:GetAttribute("AbilDouble") or 0)
 if random:NextNumber()<math.min(doubleChance,0.95) then earned*=2 end
 stats.Coins.Value=stats.Coins.Value+earned
 p:SetAttribute("LifetimeEarned",(p:GetAttribute("LifetimeEarned") or 0)+earned)
 p:SetAttribute("CoinsCollected",(p:GetAttribute("CoinsCollected") or 0)+1)
 coinSignal:Fire(p,earned,p:GetAttribute("CurrentWorld"))
 task.delay(Config.CoinRespawnSeconds, function()
  if record.part.Parent then
   setCoinVisible(record.part, true)
   record.available = true
   record.part:SetAttribute("Available", true)
  end
 end)
end
-- ===== Супер-способности питомцев =====
-- FX для клиентов: (владелец, ключ способности, сумма/число монет, радиус).
local superFX = Instance.new("RemoteEvent")
superFX.Name = "PetSuperFX"
superFX.Parent = ReplicatedStorage
local nextVacuum, nextRain = {}, {}
Players.PlayerRemoving:Connect(function(p) nextVacuum[p] = nil; nextRain[p] = nil end)
-- Средняя ценность монеты в каждом мире — для «дождя монет».
local ZONE_WORLD = {}
for _, pair in ipairs({{world, "Meadow Isles"}, {city, "Neon District"}, {sky, "Sky Isles"}, {frozen, "Frozen Peaks"}, {volcano, "Magma Volcano"}, {galaxy, "Cosmic Galaxy"}}) do
 if pair[1] then ZONE_WORLD[pair[1]] = pair[2] end
end
local worldCoinValue = {}
do
 local sum, count = {}, {}
 for _, record in ipairs(records) do
  local name = ZONE_WORLD[record.zone]
  if name then
   sum[name] = (sum[name] or 0) + record.value
   count[name] = (count[name] or 0) + 1
  end
 end
 for name, total in pairs(sum) do worldCoinValue[name] = total / count[name] end
end
-- Coin Rain: раз в Interval секунд игрок получает монеты на Pickups подборов в текущем мире.
task.spawn(function()
 while world.Parent do
  task.wait(1)
  local now = os.clock()
  for _, p in ipairs(Players:GetPlayers()) do
   local level = supersOf(p).CoinRain
   local stats = p:FindFirstChild("leaderstats")
   if not level or not stats or not p:GetAttribute("ProfileReady") then
    nextRain[p] = nil
   else
    local params = PetAbilities.SuperParams("CoinRain", level)
    if not nextRain[p] then
     nextRain[p] = now + params.Interval
    elseif now >= nextRain[p] and alive(p) then
     nextRain[p] = now + params.Interval
     local worldName = p:GetAttribute("CurrentWorld")
     local earned = params.Pickups * (worldCoinValue[worldName] or 5) * PlayerSystems.CoinMultiplier(p)
     stats.Coins.Value = stats.Coins.Value + earned
     p:SetAttribute("LifetimeEarned", (p:GetAttribute("LifetimeEarned") or 0) + earned)
     coinSignal:Fire(p, earned, worldName)
     superFX:FireAllClients(p, "CoinRain", earned, level)
    end
   end
  end
 end
end)

task.spawn(function()
 while world.Parent do
  local candidates = {}
  for _, p in ipairs(Players:GetPlayers()) do
   local h, root = alive(p)
   local stats = p:FindFirstChild("leaderstats")
   if h and stats and p:GetAttribute("ProfileReady") then
    local radius = PlayerSystems.MagnetRadius(p)
    -- Супер «Vacuum»: раз в Interval секунд забирает все монеты в Range радиусах магнита.
    local vacuum = 0
    local vacuumLevel = supersOf(p).Vacuum
    if vacuumLevel then
     local params = PetAbilities.SuperParams("Vacuum", vacuumLevel)
     if os.clock() >= (nextVacuum[p] or 0) then
      nextVacuum[p] = os.clock() + params.Interval
      vacuum = math.min(radius * params.Range, radius + params.MaxExtra) -- потолок для огромных магнитов
     end
    end
    table.insert(candidates, {p=p, root=root, level=stats.SpeedLevel.Value, radius=radius, vacuum=vacuum, sucked=0})
    -- Зелёная метка у киоска: зашёл в круг — меню магазина открылось (один раз на вход).
    for id, zonePart in pairs(shopZones) do
     local offset = root.Position - zonePart.Position
     local inside = Vector2.new(offset.X, offset.Z).Magnitude <= zonePart.Size.Z / 2 and math.abs(offset.Y) < 8
     local key = id .. ":" .. p.UserId
     if inside and not insideZone[key] and stats.SpeedLevel.Value >= (SHOP_LEVEL[id] or 0) then
      if id == "magnets" then openMenu:FireClient(p, "magnets", "island") elseif id == "skymagnets" then openMenu:FireClient(p, "magnets", "sky") elseif id == "frozenmagnets" then openMenu:FireClient(p, "magnets", "frozen") elseif id == "volcanomagnets" then openMenu:FireClient(p, "magnets", "volcano") elseif id == "galaxymagnets" then openMenu:FireClient(p, "magnets", "galaxy") else openMenu:FireClient(p, "upgrades", id) end
     end
     insideZone[key] = inside or nil
    end
    if root.Position.Y > 200 then
     p:SetAttribute("CurrentWorld", "Sky Isles")
    elseif math.abs(root.Position.X - FrozenPeaks.Center.X) <= 240 and math.abs(root.Position.Z) <= 240 then
     p:SetAttribute("CurrentWorld", "Frozen Peaks")
    elseif math.abs(root.Position.X - MagmaVolcano.Center.X) <= 240 and math.abs(root.Position.Z) <= 240 then
     p:SetAttribute("CurrentWorld", "Magma Volcano")
    elseif math.abs(root.Position.X - CosmicGalaxy.Center.X) <= 240 and math.abs(root.Position.Z) <= 240 then
     p:SetAttribute("CurrentWorld", "Cosmic Galaxy")
    elseif math.abs(root.Position.Z) <= 230 then
     if math.abs(root.Position.X) <= 150 then p:SetAttribute("CurrentWorld", "Meadow Isles")
     elseif math.abs(root.Position.X - neonX) <= 150 then p:SetAttribute("CurrentWorld", "Neon District") end
    end
   end
  end
  local byWorld = {}
  for _, candidate in ipairs(candidates) do
   local w = candidate.p:GetAttribute("CurrentWorld") or "Meadow Isles"
   byWorld[w] = byWorld[w] or {}
   table.insert(byWorld[w], candidate)
  end
  for worldName, here in pairs(byWorld) do
  for _, record in ipairs(recordsByWorld[worldName] or {}) do
   if record.available and record.part.Parent then
    local nearest, nearestDistance, nearestCandidate
    for _, candidate in ipairs(here) do
     local delta = candidate.root.Position - record.part.Position
     local distance = delta.X * delta.X + delta.Z * delta.Z
     local inMagnet = math.abs(delta.Y) <= 6 and distance <= candidate.radius ^ 2
     local inVacuum = candidate.vacuum > 0 and math.abs(delta.Y) <= 12 and distance <= candidate.vacuum ^ 2
     if candidate.level >= record.required and (inMagnet or inVacuum) and (not nearestDistance or distance < nearestDistance) then
      nearest, nearestDistance, nearestCandidate = candidate.p, distance, candidate
     end
    end
    if nearest then
     if nearestDistance > nearestCandidate.radius ^ 2 then nearestCandidate.sucked += 1 end
     collect(record, nearest)
    end
   end
  end
  end
  for _, candidate in ipairs(candidates) do
   if candidate.sucked > 0 then
    superFX:FireAllClients(candidate.p, "Vacuum", candidate.sucked, candidate.vacuum)
   end
  end
  task.wait(0.1)
 end
end)
print("[CoinSprint] Ready: 4 worlds, "..#records.." coins, "..#Config.Eggs.." eggs, "..#Config.Pets.." pets")
