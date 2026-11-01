-- Запустить в Command Bar на вкладке Server во время Play.
-- Только тест: временно перемещает персонажа и выдаёт деньги на покупки.
task.spawn(function()
 local p = game.Players:GetPlayers()[1]
 local stats = p.leaderstats
 local config = require(game.ReplicatedStorage.GameConfig)
 assert(stats.Coins.Value == 0 and (p:GetAttribute("MagnetLevel") or 0) == 0)
 local function move(x,z) p.Character:PivotTo(CFrame.new(x,3,z)) end
 move(-24.8,-15)
 task.wait(0.5)
 assert(stats.Coins.Value == 0, "outside base magnet")
 move(-25.2,-15)
 task.wait(0.5)
 assert(stats.Coins.Value == 5, "inside base magnet")
 move(-28,-24)
 print("[UpgradeTest] BASE MAGNET PASS; buy magnet with E")
 repeat task.wait(0.1) until p:GetAttribute("MagnetLevel") == 1
 assert(stats.Coins.Value == 0)
 assert(math.abs(config.GetMagnetRadius(1)-5.5)<0.001)
 move(-24.7,0)
 task.wait(0.5)
 assert(stats.Coins.Value == 5, "upgraded magnet radius")
 move(28,-24)
 stats.Coins.Value = 25
 print("[UpgradeTest] MAGNET PURCHASE PASS; buy fox with E")
 repeat task.wait(0.1) until p:GetAttribute("PetLevel") == 1
 assert(stats.Coins.Value == 0, "pet price")
 move(-24.7,15)
 task.wait(0.5)
 assert(stats.Coins.Value == 7.5, "pet x1.5 reward")
 move(34,22)
 print("[UpgradeTest] PET PURCHASE AND x1.5 PASS; test locked portal with E")
 task.wait(4)
 assert(p.Character.HumanoidRootPart.Position.X < 60, "locked world")
 stats.SpeedLevel.Value = 3
 p.Character.Humanoid.WalkSpeed = 28
 print("[UpgradeTest] LOCKED PORTAL PASS; level set to 3, enter portal with E")
 repeat task.wait(0.1) until p.Character.HumanoidRootPart.Position.X > 100
 move(155.3,-15)
 local before = stats.Coins.Value
 task.wait(0.5)
 assert(stats.Coins.Value == before + 15, "neon reward x1.5")
 move(180,30)
 print("[UpgradeTest] NEON PORTAL AND REWARD PASS; ALL CORE CHECKS PASS")
end)
