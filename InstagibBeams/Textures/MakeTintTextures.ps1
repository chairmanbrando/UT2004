# Builds the white textures InstagibBeams tints to the Beam Colour setting
# (IBTintedBeam), so they take any colour, white included: tinting stock's
# purple ones could only make shades of purple. Drawn additively, which
# ignores alpha; the alpha is for dark colours, drawn alpha-blended instead.
# Made from scratch here (no stock texture data), to stock's shapes:
#   WhiteBeam.tga   32x256: the beam, the red beam's narrow bell across it
#   WhiteFlare.tga  128x128: the impact flash, a glow with six faint rays
#   WhiteRing.tga   128x128: the impact's expanding ring
#   WhiteCore.tga   128x128: the impact's soft core
#   WhiteScorch.tga 128x128: the scorch mark, a soft uneven glow (a decal)
# Rebuild InstagibBeams after.
#   powershell -File MakeTintTextures.ps1

function Write-Tga([string]$Name, [int]$W, [int]$H, [scriptblock]$Pixel)
{
    $out = New-Object byte[] (18 + 4 * $W * $H)
    $out[2] = 2
    $out[12] = $W % 256; $out[13] = [int][Math]::Floor($W / 256)
    $out[14] = $H % 256; $out[15] = [int][Math]::Floor($H / 256)
    $out[16] = 32
    $out[17] = 8
    for ( $y = 0; $y -lt $H; $y++ )
    {
        for ( $x = 0; $x -lt $W; $x++ )
        {
            # value and alpha, 0-1
            $va = & $Pixel $x $y
            $v = [byte][Math]::Round(255 * [Math]::Min(1.0, [Math]::Max(0.0, $va[0])))
            $a = [byte][Math]::Round(255 * [Math]::Min(1.0, [Math]::Max(0.0, $va[1])))
            $i = 18 + 4 * ($y * $W + $x)
            $out[$i] = $v; $out[$i + 1] = $v; $out[$i + 2] = $v; $out[$i + 3] = $a
        }
    }
    $Path = Join-Path $PSScriptRoot $Name
    [IO.File]::WriteAllBytes($Path, $out)
    "wrote $Path"
}

# (Min and Max take 1.0 and 0.0: with an int first, PowerShell picks the int
# overloads and rounds the value)

# a square texture's point as radius (0 centre, 1 edge midpoint) and angle
function Get-Polar([int]$x, [int]$y, [int]$S)
{
    $dx = ($x - ($S - 1) / 2.0) / ($S / 2.0)
    $dy = ($y - ($S - 1) / 2.0) / ($S / 2.0)
    return @([Math]::Sqrt($dx * $dx + $dy * $dy), [Math]::Atan2($dy, $dx))
}

# fades a square texture's value to nothing by its edge
function Get-EdgeFade([double]$r)
{
    return [Math]::Max(0.0, 1 - [Math]::Pow($r, 4))
}

Write-Tga 'WhiteBeam.tga' 32 256 {
    param($x, $y)
    $d = $x - 15.5
    $p = [Math]::Exp(-($d * $d) / (2 * 4.25 * 4.25))
    $v = [Math]::Min(1.0, 1.1 * [Math]::Pow($p, 0.85))
    @($v, $v)
}

Write-Tga 'WhiteFlare.tga' 128 128 {
    param($x, $y)
    $r, $t = Get-Polar $x $y 128
    $glow = [Math]::Exp(-($r * $r) / (2 * 0.12 * 0.12)) + 0.35 * [Math]::Exp(-$r / 0.22)
    $rays = 0.5 * [Math]::Pow([Math]::Abs([Math]::Cos(3 * $t)), 40) * [Math]::Exp(-$r / 0.35)
    $v = ($glow + $rays) * (Get-EdgeFade $r)
    @($v, $v)
}

Write-Tga 'WhiteRing.tga' 128 128 {
    param($x, $y)
    $r, $t = Get-Polar $x $y 128
    $v = ([Math]::Exp(-[Math]::Pow(($r - 0.72) / 0.07, 2)) + 0.15 * [Math]::Exp(-[Math]::Pow(($r - 0.72) / 0.2, 2))) * (Get-EdgeFade $r)
    @($v, $v)
}

Write-Tga 'WhiteCore.tga' 128 128 {
    param($x, $y)
    $r, $t = Get-Polar $x $y 128
    $v = ([Math]::Exp(-($r * $r) / (2 * 0.22 * 0.22)) + 0.3 * [Math]::Exp(-($r * $r) / (2 * 0.06 * 0.06))) * (Get-EdgeFade $r)
    @($v, $v)
}

Write-Tga 'WhiteScorch.tga' 128 128 {
    param($x, $y)
    $r, $t = Get-Polar $x $y 128
    $uneven = 0.8 + 0.2 * [Math]::Sin(5 * $t + 7 * $r) * [Math]::Cos(3 * $t - 4 * $r)
    $v = 0.55 * [Math]::Pow([Math]::Max(0.0, 1 - $r), 1.5) * $uneven
    @($v, (1.5 * $v))
}
