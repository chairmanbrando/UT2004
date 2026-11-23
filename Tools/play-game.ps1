# play <game> [map filter] [?Option=Value...]
#
# Starts an offline match of <game> on a random map of that type, with the
# mutators last picked in the game's Instant Action menu (User.ini,
# [GUI2K4.UT2K4Tab_MutatorSP] LastActiveMutators). Launching with a map on the
# command line skips the menu, so its mutators have to be passed along here.
# Everything else (time limit, goal score, bots, ...) comes from each game
# type's saved settings, as the menu leaves them.
#
#   play ctf                 random CTF map
#   play dm rank             random DM map with "rank" in its name
#   play ctf face ?NumBots=8?Difficulty=5   extra URL options (see RandomDM.ps1)
#   play tdm ?Mutator=UT2026.UT2026Mutator  your own mutator list instead
#
# Run through play.cmd beside it, like build.cmd: this file isn't named
# play.ps1 so that "play" in PowerShell finds play.cmd, which bypasses the
# script execution policy.

param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Words)

# game types: class, and the map name prefix they play on
$Games = [ordered]@{
    dm   = @('XGame.xDeathMatch',             'DM')
    tdm  = @('XGame.xTeamGame',               'DM')
    ctf  = @('XGame.xCTFGame',                'CTF')
    ictf = @('XGame.InstagibCTF',             'CTF')
    vctf = @('XGame.xVehicleCTFGame',         'VCTF')
    br   = @('XGame.xBombingRun',             'BR')
    dom  = @('XGame.xDoubleDom',              'DOM')
    ons  = @('Onslaught.ONSOnslaughtGame',    'ONS')
    as   = @('UT2k4Assault.ASGameInfo',       'AS')
    lms  = @('BonusPack.xLastManStandingGame', 'DM')
    mut  = @('BonusPack.xMutantGame',         'DM')
    inv  = @('SkaarjPack.Invasion',           'DM')
    gg   = @('GunGame.GunGame',               'DM')
}

function Show-Usage {
    Write-Host 'usage: play <game> [map filter] [?Option=Value...]'
    Write-Host ('games: ' + ($Games.Keys -join ', '))
}

$Root = Split-Path $PSScriptRoot -Parent
$System = Join-Path $Root 'System'

$Type = $null; $Filter = $null; $Options = ''
foreach ($W in $Words) {
    if ($W.StartsWith('?')) { $Options += $W }
    elseif (-not $Type) { $Type = $W.ToLower() }
    elseif (-not $Filter) { $Filter = $W }
    else { Show-Usage; exit 1 }
}
if (-not $Type -or -not $Games.Contains($Type)) { Show-Usage; exit 1 }
$Game, $Prefix = $Games[$Type]

if (Get-Process UT2004 -ErrorAction SilentlyContinue) {
    Write-Host 'UT2004 is already running.' -ForegroundColor Red
    exit 1
}

$Maps = @(Get-ChildItem (Join-Path $Root 'Maps') -Filter "$Prefix-*.ut2")
if ($Filter) { $Maps = @($Maps | Where-Object { $_.BaseName -like "*$Filter*" }) }
if ($Maps.Count -eq 0) {
    $What = "$Prefix-*"
    if ($Filter) { $What += " matching '$Filter'" }
    Write-Host "no $What maps in Maps\" -ForegroundColor Red
    exit 1
}
$Map = ($Maps | Get-Random).BaseName

$Url = "${Map}?Game=$Game"
if ($Options -notmatch '(?i)\?Mutator=') {
    # the Instant Action menu's (MutatorSP), not the host-a-server one's (MutatorMP)
    $Section = ''
    foreach ($Line in Get-Content (Join-Path $System 'User.ini')) {
        if ($Line -match '^\s*\[') { $Section = $Line.Trim(); continue }
        if ($Section -eq '[GUI2K4.UT2K4Tab_MutatorSP]' -and $Line -match '^\s*LastActiveMutators\s*=\s*(.*)$') {
            if ($Matches[1].Trim()) { $Url += '?Mutator=' + $Matches[1].Trim() }
            break
        }
    }
}
$Url += $Options

Write-Host "$Map ($Game)" -ForegroundColor Green
if ($Url -match '\?Mutator=([^?]*)') { Write-Host ('mutators: ' + ($Matches[1] -replace ',', ', ')) -ForegroundColor DarkGray }
Start-Process (Join-Path $System 'UT2004.exe') -ArgumentList $Url -WorkingDirectory $System
