# Иконки геймпассов для страницы игры Roblox из тех же картинок, что в игровом магазине
# (assets/hud/store, ChatGPT): фиолетовый круг с золотым ободом, картинка в центре, лента с названием,
# кружок с бонусом (x2, +3) справа сверху. Результат: assets/store_roblox/<Key>.png (512x512).
# Запуск: powershell -ExecutionPolicy Bypass -File tools/make-pass-icons.ps1
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "assets/hud/store"
$out = Join-Path $root "assets/store_roblox"
New-Item -ItemType Directory -Force $out | Out-Null

$passes = @(
  @{ Key="Coins2x";     Art="coins2x";     Label="2X COINS";     Tag="x2" },
  @{ Key="Luck2x";      Art="luck2x";      Label="2X LUCK";      Tag="x2" },
  @{ Key="PetSlots";    Art="petslots";    Label="+3 PETS";      Tag="+3" },
  @{ Key="VIP";         Art="vip";         Label="VIP";          Tag="" },
  @{ Key="FastHatch";   Art="fasthatch";   Label="FAST HATCH";   Tag="" },
  @{ Key="SuperMagnet"; Art="supermagnet"; Label="SUPER MAGNET"; Tag="x2" },
  @{ Key="SuperLuck";   Art="superluck";   Label="SUPER LUCK";   Tag="+2" },
  @{ Key="Hatch9";      Art="hatch9";      Label="X9 HATCH";     Tag="9" },
  @{ Key="AutoHatch";   Art="autohatch";   Label="AUTO HATCH";   Tag="" },
  @{ Key="GoldenHatch"; Art="goldenhatch"; Label="GOLDEN HATCH"; Tag="" },
  @{ Key="QuickTravel"; Art="quicktravel"; Label="QUICK TRAVEL"; Tag="" },
  @{ Key="RoyalAura";   Art="royalaura";   Label="ROYAL AURA";   Tag="" },
  @{ Key="MythicLuck";  Art="mythicluck";  Label="MYTHIC LUCK";  Tag="+3" }
)
$gold = [System.Drawing.Color]::FromArgb(255,200,70)
$ink = [System.Drawing.Color]::FromArgb(60,25,95)
$tagCol = [System.Drawing.Color]::FromArgb(240,70,110)
function RoundRect([float]$x,[float]$y,[float]$w,[float]$h,[float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x,$y,2*$r,2*$r,180,90); $p.AddArc($x+$w-2*$r,$y,2*$r,2*$r,270,90)
  $p.AddArc($x+$w-2*$r,$y+$h-2*$r,2*$r,2*$r,0,90); $p.AddArc($x,$y+$h-2*$r,2*$r,2*$r,90,90)
  $p.CloseFigure(); return $p
}
function OutlinedText($g,[string]$text,[string]$fontName,[float]$size,[System.Drawing.RectangleF]$rect,$fill,$outline,[float]$ow) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  $path.AddString($text,(New-Object System.Drawing.FontFamily($fontName)),[int][System.Drawing.FontStyle]::Bold,$size,$rect,$fmt)
  $pen = New-Object System.Drawing.Pen($outline,$ow); $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $g.DrawPath($pen,$path); $g.FillPath((New-Object System.Drawing.SolidBrush($fill)),$path)
}
$font = "Segoe UI Black"
foreach ($c in $passes) {
  $art = [System.Drawing.Image]::FromFile((Join-Path $src ($c.Art + ".png")))
  $bmp = New-Object System.Drawing.Bitmap 512,512
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = "AntiAlias"; $g.InterpolationMode = "HighQualityBicubic"
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.FillEllipse((New-Object System.Drawing.SolidBrush($gold)),8,8,496,496)
  $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(250,240,255))),18,18,476,476)
  $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(28,28,456,456)),[System.Drawing.Color]::FromArgb(170,110,240),[System.Drawing.Color]::FromArgb(110,50,200),90)
  $g.FillEllipse($grad,28,28,456,456)
  $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45,255,255,255))),90,60,330,150)
  $g.DrawImage($art,96,48,320,320)
  $rib = RoundRect 52 352 408 86 34
  $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(95,40,170))),$rib)
  $g.DrawPath((New-Object System.Drawing.Pen($gold,7)),$rib)
  $size = if ($c.Label.Length -gt 10) { 46 } else { 56 }
  OutlinedText $g $c.Label $font $size (New-Object System.Drawing.RectangleF(52,352,408,86)) ([System.Drawing.Color]::White) $ink 9
  if ($c.Tag -ne "") {
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)),344,40,130,130)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($tagCol)),353,49,112,112)
    OutlinedText $g $c.Tag $font 54 (New-Object System.Drawing.RectangleF(344,40,130,130)) ([System.Drawing.Color]::White) $ink 8
  }
  $g.Dispose()
  $bmp.Save((Join-Path $out ($c.Key + ".png")),[System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $art.Dispose()
}
Write-Output ("done: " + (Get-ChildItem $out -Filter *.png).Count + " icons in " + $out)
