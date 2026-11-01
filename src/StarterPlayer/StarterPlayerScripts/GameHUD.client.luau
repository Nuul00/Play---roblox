-- Minimal launchers. Detailed statistics are visible only on demand.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(ReplicatedStorage:WaitForChild("GameConfig"))
local stats=player:WaitForChild("leaderstats")
local gui=Instance.new("ScreenGui");gui.Name="CoinSprintHUD";gui.ResetOnSpawn=false;gui.DisplayOrder=12;gui.Parent=player:WaitForChild("PlayerGui")
local openIndex=Instance.new("BindableEvent");openIndex.Name="OpenPetIndex";openIndex.Parent=player.PlayerGui
local function button(parent,text,size,pos)
 local b=Instance.new("TextButton");b.Size=size;b.Position=pos;b.Text=text;b.Font=Enum.Font.GothamBold;b.TextSize=14;b.TextColor3=Color3.fromRGB(244,247,240);b.BackgroundColor3=Color3.fromRGB(35,55,54);b.BackgroundTransparency=0.15;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,12);return b
end
local bar=Instance.new("Frame");bar.Size=UDim2.fromOffset(208,36);bar.AnchorPoint=Vector2.new(0.5,1);bar.Position=UDim2.new(0.5,0,1,-14);bar.BackgroundTransparency=1;bar.Parent=gui
local statButton=button(bar,"STATS",UDim2.fromOffset(98,36),UDim2.fromOffset(0,0))
local indexButton=button(bar,"PET INDEX",UDim2.fromOffset(98,36),UDim2.fromOffset(110,0))
local panel=Instance.new("Frame");panel.Name="Statistics";panel.AnchorPoint=Vector2.new(0.5,0.5);panel.Position=UDim2.fromScale(0.5,0.5);panel.Size=UDim2.fromOffset(420,405);panel.BackgroundColor3=Color3.fromRGB(24,42,42);panel.Visible=false;panel.Parent=gui;Instance.new("UICorner",panel).CornerRadius=UDim.new(0,20)
local scale=Instance.new("UIScale",panel)
local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-60,0,48);title.Position=UDim2.fromOffset(16,8);title.Text="YOUR STATISTICS";title.Font=Enum.Font.GothamBold;title.TextSize=22;title.TextColor3=Color3.fromRGB(244,230,191);title.BackgroundTransparency=1;title.Parent=panel
local close=button(panel,"×",UDim2.fromOffset(34,34),UDim2.fromOffset(374,12));close.Modal=true
local content=Instance.new("TextLabel");content.Position=UDim2.fromOffset(26,65);content.Size=UDim2.fromOffset(370,255);content.TextXAlignment=Enum.TextXAlignment.Left;content.TextYAlignment=Enum.TextYAlignment.Top;content.Font=Enum.Font.GothamMedium;content.TextSize=17;content.TextColor3=Color3.fromRGB(224,238,225);content.BackgroundTransparency=1;content.Parent=panel
local range=button(panel,"Magnet range: OFF",UDim2.fromOffset(368,38),UDim2.fromOffset(26,332))
player:SetAttribute("ShowMagnetRange",false)
range.Activated:Connect(function() local visible=not player:GetAttribute("ShowMagnetRange");player:SetAttribute("ShowMagnetRange",visible);range.Text="Magnet range: "..(visible and "ON" or "OFF") end)
local function hide() panel.Visible=false;if player:GetAttribute("UIScreen")=="stats" then player:SetAttribute("UIScreen","") end end
close.Activated:Connect(hide)
statButton.Activated:Connect(function() if panel.Visible then hide() else player:SetAttribute("UIScreen","stats");panel.Visible=true end end)
indexButton.Activated:Connect(function() hide();openIndex:Fire() end)
player:GetAttributeChangedSignal("UIScreen"):Connect(function() if player:GetAttribute("UIScreen")~="stats" then panel.Visible=false end end)
local function update()
 local pet=Config.Pets[player:GetAttribute("PetLevel") or 0]
 local owned=0
 for i=1,#Config.Pets do if (player:GetAttribute("PetOwned"..i) or 0)>0 then owned=owned+1 end end
 content.Text=string.format("Coins                  %g\nSpeed                  %d  (level %d)\nMagnet radius      %.2f\nIncome                 x%g\nBest pet               %s\nPet bonus             x%g\nEggs opened        %d\nCoins picked up   %d\nPet index              %d / %d\n%s",stats.Coins.Value,Config.GetWalkSpeed(stats.SpeedLevel.Value),stats.SpeedLevel.Value,Config.GetMagnetRadius(player:GetAttribute("MagnetLevel") or 0),Config.GetIncomeMultiplier(player:GetAttribute("IncomeLevel") or 0),pet and pet.Name or "None",Config.GetPetMultiplier(player:GetAttribute("PetLevel") or 0),player:GetAttribute("EggsOpened") or 0,player:GetAttribute("CoinsCollected") or 0,owned,#Config.Pets,player:GetAttribute("SaveStatus") or "LOADING PROFILE")
end
stats.Coins.Changed:Connect(update);stats.SpeedLevel.Changed:Connect(update);player.AttributeChanged:Connect(update);update()
local toast=Instance.new("TextLabel");toast.AnchorPoint=Vector2.new(0.5,1);toast.Position=UDim2.new(0.5,0,1,-64);toast.Size=UDim2.new(0.7,0,0,38);toast.BackgroundColor3=Color3.fromRGB(30,47,50);toast.BackgroundTransparency=0.08;toast.TextColor3=Color3.fromRGB(243,235,207);toast.TextWrapped=true;toast.Font=Enum.Font.GothamBold;toast.TextSize=16;toast.Visible=false;toast.Parent=gui;Instance.new("UICorner",toast).CornerRadius=UDim.new(0,10)
local version=0
ReplicatedStorage:WaitForChild("GameFeedback").OnClientEvent:Connect(function(message) version=version+1;local current=version;toast.Text=message;toast.Visible=true;task.delay(2.8,function() if version==current then toast.Visible=false end end) end)
local hidden=false
local previous=true
RunService.RenderStepped:Connect(function()
 local camera=workspace.CurrentCamera
 if camera then scale.Scale=math.clamp(math.min(camera.ViewportSize.X/450,camera.ViewportSize.Y/460),0.3,1) end
 local modal=(player:GetAttribute("UIScreen") or "")~=""
 if modal and not hidden then local ok,value=pcall(function() return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) end);previous=not ok or value;pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end);hidden=true
 elseif not modal and hidden then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,previous) end);hidden=false end
end)
gui.Destroying:Connect(function() if hidden then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,previous) end) end end)
