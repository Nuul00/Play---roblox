# Иконки бейджей Roblox в стиле иконок геймпассов: фиолетовый круг с золотым ободом и бликом,
# эмблема ачивки (assets/hud/badges/*.png) в центре, лента с названием снизу, кружок с уровнем справа.
# Запуск: powershell -ExecutionPolicy Bypass -File tools/make-badge-icons.ps1
# Результат: assets/badges_roblox/<Id ачивки>.png (512x512)
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "assets/hud/badges"
$out = Join-Path $root "assets/badges_roblox"
New-Item -ItemType Directory -Force $out | Out-Null

$chains = @(
  @{ Art = "coins";  Label = "COLLECTOR";    Ids = @("Pickup100","Pickup1000","CoinsCollected10000","CoinsCollected50000","CoinsCollected250000","CoinsCollected1000000","CoinsCollected5000000") },
  @{ Art = "eggs";   Label = "EGG MASTER";   Ids = @("Eggs10","Eggs100","EggsOpened500","EggsOpened2500","EggsOpened10000","EggsOpened50000") },
  @{ Art = "rich";   Label = "RICH";         Ids = @("Rich","LifetimeEarned100000000","LifetimeEarned10000000000","LifetimeEarned1000000000000","LifetimeEarned100000000000000","LifetimeEarned10000000000000000","LifetimeEarned1000000000000000000") },
  @{ Art = "index";  Label = "EXPLORER";     Ids = @("Index12","PetsDiscovered25","PetsDiscovered40","PetsDiscovered60","PetsDiscovered80","PetsDiscovered100") },
  @{ Art = "reborn"; Label = "REBORN";       Ids = @("Rebirths1","Rebirths3","Rebirths5","Rebirths10","Rebirths15","Rebirths25","Rebirths35","Rebirths50") },
  @{ Art = "magnet"; Label = "MAGNET FAN";   Ids = @("MagnetTier5","MagnetTier10","MagnetTier20","MagnetTier30","MagnetTier40","MagnetTier50","MagnetTier60") },
  @{ Art = "vault";  Label = "VAULT RAIDER"; Ids = @("Rush1","Rush5","Rush25","Rush100") },
  @{ Art = "combo";  Label = "COMBO KING";   Ids = @("Combo15","Combo40","Combo80","Combo150") }
)
$roman = @("I","II","III","IV","V","VI","VII","VIII")
# цвет кружка уровня растёт с уровнем: зелёный -> голубой -> фиолетовый -> красный -> золотой
$tierCols = @(
  [System.Drawing.Color]::FromArgb(70,200,110), [System.Drawing.Color]::FromArgb(60,170,240),
  [System.Drawing.Color]::FromArgb(150,90,240), [System.Drawing.Color]::FromArgb(240,80,120),
  [System.Drawing.Color]::FromArgb(250,150,40), [System.Drawing.Color]::FromArgb(240,60,60),
  [System.Drawing.Color]::FromArgb(230,190,30), [System.Drawing.Color]::FromArgb(255,215,60)
)
$gold = [System.Drawing.Color]::FromArgb(255,200,70)
$ink = [System.Drawing.Color]::FromArgb(60,25,95)

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
  $ff = New-Object System.Drawing.FontFamily($fontName)
  $path.AddString($text,$ff,[int][System.Drawing.FontStyle]::Bold,$size,$rect,$fmt)
  $pen = New-Object System.Drawing.Pen($outline,$ow); $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $g.DrawPath($pen,$path); $g.FillPath((New-Object System.Drawing.SolidBrush($fill)),$path)
}
$font = "Segoe UI Black"
try { [void](New-Object System.Drawing.FontFamily($font)) } catch { $font = "Arial Black" }

foreach ($c in $chains) {
  $art = [System.Drawing.Image]::FromFile((Join-Path $src ($c.Art + ".png")))
  for ($i = 0; $i -lt $c.Ids.Count; $i++) {
    $bmp = New-Object System.Drawing.Bitmap 512,512
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = "AntiAlias"; $g.InterpolationMode = "HighQualityBicubic"; $g.TextRenderingHint = "AntiAliasGridFit"
    $g.Clear([System.Drawing.Color]::Transparent)
    # золотой обод и белая кайма
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($gold)),8,8,496,496)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(250,240,255))),18,18,476,476)
    # фиолетовый круг с градиентом
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(28,28,456,456)),[System.Drawing.Color]::FromArgb(170,110,240),[System.Drawing.Color]::FromArgb(110,50,200),90)
    $g.FillEllipse($grad,28,28,456,456)
    # блик сверху
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45,255,255,255))),90,60,330,150)
    # эмблема
    $g.DrawImage($art,96,52,320,320)
    # лента с названием
    $rib = RoundRect 52 352 408 86 34
    $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(95,40,170))),$rib)
    $g.DrawPath((New-Object System.Drawing.Pen($gold,7)),$rib)
    $size = if ($c.Label.Length -gt 10) { 46 } else { 54 }
    OutlinedText $g $c.Label $font $size (New-Object System.Drawing.RectangleF(52,352,408,86)) ([System.Drawing.Color]::White) $ink 9
    # кружок с уровнем
    $tc = $tierCols[[Math]::Min($i,$tierCols.Count-1)]
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)),334,40,140,140)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($tc)),344,50,120,120)
    $rsize = if ($roman[$i].Length -ge 3) { 44 } else { 58 }
    OutlinedText $g $roman[$i] $font $rsize (New-Object System.Drawing.RectangleF(334,40,140,140)) ([System.Drawing.Color]::White) $ink 8
    $g.Dispose()
    $bmp.Save((Join-Path $out ($c.Ids[$i] + ".png")),[System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
  }
  $art.Dispose()
}
Write-Output ("done: " + (Get-ChildItem $out -Filter *.png).Count + " icons in " + $out)
