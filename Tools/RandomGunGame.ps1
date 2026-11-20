# Launches Gun Game on a random DM map with the settings and mutators below.
# Comment out (#) or add lines to change them. Extra URL options can also be
# passed as an argument, e.g. RandomGunGame.ps1 "?NumBots=8?Difficulty=5"
#
# URL options DM-based games read (Name=Value; True/False for on/off):
#   NumBots=6            bots at the start (0-32); turns bAutoNumBots off
#   bAutoNumBots=False   True: bot count from the map's recommended players
#   MinPlayers=4         bots join/leave to keep at least this many players
#   Difficulty=3         bot skill: 0 Novice, 1 Average, 2 Experienced,
#                        3 Skilled, 4 Adept, 5 Masterful, 6 Inhuman, 7 Godlike
#   AutoAdjust=True      bot skill adjusts to how you're doing
#   TimeLimit=15         minutes; 0 none
#   WeaponStay=True      weapon pickups stay after being taken
#   Translocator=True    everyone gets a translocator
#   GameSpeed=1.0        1.0 normal
#   AllowThrowing=True   players can throw their weapons
#   AllowBehindview=True third-person view allowed
#   QuickStart=True      the match starts without waiting
#   DMTeam=<roster>      the bots come from this roster (xRosterEntry class)
#   GameStats=False      stats logging
#   Mutator=a.b,c.d      built from the list below
# Gun Game sets GoalScore (its tier count) and MaxLives itself; its own
# settings (tiers etc.) are in its config, not the URL.

param([string]$Options = "")

$Game = "GunGame.GunGame"

$Settings = @(
    "bAutoNumBots=False"
    "NumBots=6"
)

$Mutators = @(
    "DamageNumbers.MutDamageNumbers"
)

$Root = Split-Path $PSScriptRoot -Parent
$System = Join-Path $Root "System"
$Map = Get-ChildItem (Join-Path $Root "Maps") -Filter "DM-*.ut2" | Get-Random
$Url = "$($Map.BaseName)?Game=$Game"
foreach ($S in $Settings) { $Url += "?$S" }
if ($Mutators.Count -gt 0) { $Url += "?Mutator=" + ($Mutators -join ",") }
$Url += $Options
Start-Process (Join-Path $System "UT2004.exe") -ArgumentList $Url -WorkingDirectory $System
