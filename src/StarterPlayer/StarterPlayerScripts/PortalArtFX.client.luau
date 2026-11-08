local Run=game:GetService("RunService")
local player=game.Players.LocalPlayer
local art=workspace:WaitForChild("CoinSpeedWorld"):WaitForChild("NeonGatewayArt")
local veil=art:FindFirstChild("PortalVeil") -- нет, если стоит своя 3D-модель арки
local lines={}
for _,part in ipairs(art:GetChildren()) do if part.Name=="FlowLine" then table.insert(lines,{part=part,base=part.CFrame,phase=part:GetAttribute("Phase")}) end end
local label=art:WaitForChild("TitleAnchor"):WaitForChild("GatewaySign"):WaitForChild("Frame"):WaitForChild("Requirement")
local function refresh() local ready=player:WaitForChild("leaderstats").SpeedLevel.Value>=3;label.Text=ready and "READY · WALK IN" or "SPEED 28 · LEVEL 3";label.TextColor3=ready and Color3.fromRGB(145,239,179) or Color3.fromRGB(248,202,115) end
player:WaitForChild("leaderstats"):WaitForChild("SpeedLevel").Changed:Connect(refresh);refresh()
local t=0
Run.RenderStepped:Connect(function(dt)
 t+=dt
 if veil and workspace.CurrentCamera and (workspace.CurrentCamera.CFrame.Position-veil.Position).Magnitude<120 then
  veil.LocalTransparencyModifier=.08+.05*math.sin(t*1.2)
  for _,v in ipairs(lines) do v.part.CFrame=v.base+Vector3.new(0,math.sin(t*.7+v.phase)*.25,0);v.part.LocalTransparencyModifier=.15+.15*math.sin(t+v.phase) end
 end
end)
