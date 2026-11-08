local Icons = {}
local rgb = Color3.fromRGB
function Icons.Draw(button, kind)
 local root=button:FindFirstChildOfClass("TextLabel")
 root.Text=""
 local function part(x,y,w,h,color,r)
  local f=Instance.new("Frame");f.BorderSizePixel=0;f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h);f.BackgroundColor3=color;f.Parent=root
  Instance.new("UICorner",f).CornerRadius=UDim.new(0,r or 3)
  return f
 end
 local purple=rgb(175,67,234)
 if kind=="Daily" then
  local page=part(10,10,35,31,rgb(255,249,255),5)
  local outline=Instance.new("UIStroke",page);outline.Color=rgb(115,43,93);outline.Thickness=2
  part(10,10,35,10,rgb(255,104,135),5)
  part(17,5,4,11,rgb(109,65,103),2);part(34,5,4,11,rgb(109,65,103),2)
  local n=Instance.new("TextLabel",root);n.BackgroundTransparency=1;n.Position=UDim2.fromOffset(13,19);n.Size=UDim2.fromOffset(29,23);n.Font=Enum.Font.FredokaOne;n.Text="7";n.TextSize=25;n.TextColor3=rgb(112,70,153)
 elseif kind=="Teleport" then
  for j=0,1 do
   local ring=part(8+j*4,32+j*3,39-j*8,10-j*2,rgb(101,244,255),20);ring.BackgroundTransparency=1
   local edge=Instance.new("UIStroke",ring);edge.Color=rgb(101,244,255);edge.Thickness=2
  end
  local tip=part(22,23,13,13,rgb(250,103,226),2);tip.Rotation=45
  part(15,5,26,28,rgb(250,103,226),14)
  part(23,12,10,11,rgb(255,243,255),8)
 else
  for arc=0,1 do
   for j=0,15 do
    local a=math.rad(arc*180+20+j*8)
    local f=part(27+math.cos(a)*15-3,24+math.sin(a)*13-3,7,6,purple,3);f.Rotation=math.deg(a)+90
   end
   local a=math.rad(arc*180+148)
   local tip=part(27+math.cos(a)*15-5,24+math.sin(a)*13-5,11,11,purple,2);tip.Rotation=arc*180+25
  end
 end
 -- Small glass highlight ties the three icons to the existing glossy menu.
 local shine=part(7,3,40,3,rgb(255,255,255),3);shine.BackgroundTransparency=.65
end
return Icons
