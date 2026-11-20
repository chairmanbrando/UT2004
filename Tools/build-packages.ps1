# build <package> [<package> ...] | build all
#
# Rebuilds UnrealScript packages: deletes System\<Package>.u for each one named
# and runs "ucc make" from System, which compiles every EditPackages entry
# whose .u is missing. Names are matched against UT2004.ini's EditPackages,
# ignoring case. "all" means every package with its source in the game folder
# (a <Package>\Classes folder). Run through build.cmd beside it: this file
# isn't named build.ps1 so that "build" in PowerShell finds build.cmd, which
# bypasses the script execution policy, rather than this.

param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Names)

$Root = Split-Path $PSScriptRoot -Parent
$System = Join-Path $Root 'System'
$Ini = Join-Path $System 'UT2004.ini'

$EditPackages = @(Select-String -Path $Ini -Pattern '^\s*EditPackages\s*=\s*(\S+)' |
    ForEach-Object { $_.Matches[0].Groups[1].Value })
$Own = @($EditPackages | Where-Object { Test-Path (Join-Path $Root "$_\Classes") })

if (-not $Names -or $Names.Count -eq 0) {
    Write-Host 'usage: build <package> [<package> ...]   or   build all'
    Write-Host ('packages: ' + ($Own -join ', '))
    exit 1
}

$Packages = @()
foreach ($Name in $Names) {
    if ($Name -eq 'all') { $Packages += $Own; continue }
    $Match = $EditPackages | Where-Object { $_ -eq $Name } | Select-Object -First 1
    if (-not $Match) {
        Write-Host "no EditPackages entry named '$Name' in System\UT2004.ini" -ForegroundColor Red
        Write-Host ('packages: ' + ($Own -join ', '))
        exit 1
    }
    $Packages += $Match
}
$Packages = @($Packages | Select-Object -Unique)

if (Get-Process UT2004 -ErrorAction SilentlyContinue) {
    Write-Host 'UT2004 is running; close it first (its packages are loaded).' -ForegroundColor Red
    exit 1
}

foreach ($Pkg in $Packages) {
    $U = Join-Path $System "$Pkg.u"
    if (Test-Path $U) {
        try { Remove-Item $U -Force -ErrorAction Stop }
        catch { Write-Host "can't delete $Pkg.u: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
        Write-Host "deleted $Pkg.u" -ForegroundColor DarkGray
    }
}

Push-Location $System
try {
    & .\ucc.exe make | ForEach-Object {
        $Line = $_.TrimEnd()
        # blank lines and ucc's "---- Package - Release ----" banner for every package
        if ($Line -eq '' -or $Line -match '^-+.* - Release-+$') { return }
        if ($Line -match ': Error|^Error|Failure|error\(s\)' -and $Line -notmatch '\b0 error\(s\)') {
            Write-Host $Line -ForegroundColor Red
        } elseif ($Line -match ': Warning|[1-9]\d* warning\(s\)') {
            Write-Host $Line -ForegroundColor Yellow
        } elseif ($Line -match '^Success') {
            Write-Host $Line -ForegroundColor Green
        } else {
            Write-Host $Line
        }
    }
    $Code = $LASTEXITCODE
}
finally {
    Pop-Location
}

foreach ($Pkg in $Packages) {
    if (-not (Test-Path (Join-Path $System "$Pkg.u"))) {
        Write-Host "$Pkg.u wasn't built" -ForegroundColor Red
        $Code = 1
    }
}
exit $Code
