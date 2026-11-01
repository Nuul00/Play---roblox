-- Вставить в Command Bar вкладки Server во время Play.
-- Проверка временно выдаёт деньги и подводит игрока к мастерской/яйцу.
task.spawn(function()
 local p=game.Players:GetPlayers()[1]
 local stats=p.leaderstats
 local config=require(game.ReplicatedStorage.GameConfig)
 stats.Coins.Value=1000
 p.Character:PivotTo(CFrame.new(0,3,-22))
 print("[ShopTest] SETUP: open workshop and buy speed, magnet, income once each")
 repeat task.wait(0.1) until stats.SpeedLevel.Value==1 and p:GetAttribute("MagnetLevel")==1 and p:GetAttribute("IncomeLevel")==1
 assert(stats.Coins.Value==970,"upgrade prices")
 assert(p.Character.Humanoid.WalkSpeed==20,"speed application")
 assert(math.abs(config.GetMagnetRadius(1)-5.5)<0.001,"magnet radius")
 assert(config.GetIncomeMultiplier(1)==1.25,"income multiplier")
 print("[ShopTest] THREE UPGRADES PASS: balance=970, speed=20, radius=5.5, income=1.25")
 p.Character:PivotTo(CFrame.new(30,3,-21))
 print("[ShopTest] OPEN EGG: open egg menu and hatch once")
 repeat task.wait(0.1) until (p:GetAttribute("PetOwned1") or 0)+(p:GetAttribute("PetOwned2") or 0)+(p:GetAttribute("PetOwned3") or 0)==1
 assert(stats.Coins.Value==945,"egg price")
 local pet=p:GetAttribute("PetLevel")
 assert(pet>=1 and pet<=3,"valid egg pet")
 print("[ShopTest] EGG AWARD PASS: balance=945 pet="..pet)
 task.wait(5)
 local before=stats.Coins.Value
 p.Character:PivotTo(CFrame.new(-24.7,3,-15))
 task.wait(0.6)
 local expected=5*config.GetPetMultiplier(pet)*1.25
 assert(math.abs(stats.Coins.Value-before-expected)<0.001,"combined coin reward")
 p.Character:PivotTo(CFrame.new(0,3,30))
 print("[ShopTest] COMBINED REWARD PASS: "..expected.."; CORE CHECKS PASS")
end)
