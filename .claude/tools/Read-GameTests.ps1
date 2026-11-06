<#
.SYNOPSIS
    Shows a /kotest run of the library's test addon (Krowi_OptionsTests) with each step's screenshot, and marks every
    scenario line that differs from the headless run, so a build is checked on a client from one in-game pass:
    Deploy-TestAddon.ps1 -> /reload -> /kotest -> /reload -> Read-GameTests.ps1 (or Run-GameTests.ps1 for all of it).

.DESCRIPTION
    Finds the most recently written Krowi_OptionsTests.lua under the client's WTF\Account\*\SavedVariables (the game names
    the file after the addon; it holds KrowiOptionsTests_Debug) and reads it with the kit's Lua 5.1 (read-tests.lua).
    Prints KrowiOptionsTests_Debug.Tests.LastRun, or a kept run, line by line: = for a scenario line equal to the headless
    one (Tests\Krowi_OptionsTests\Run-Headless.lua, run here on this checkout), ! for one that differs, g for a live step,
    which only the game runs. A step that took a screenshot gets the path of the file from the client's Screenshots
    folder, to open with the Read tool: the game names the file after the second it was written (WoWScrnShot_MMddyy_HHmmss),
    the same second or the next, and the steps are seconds apart, so the nearest file within 2 s is it.

    The game writes saved variables on /reload and logout only, so a run that just finished is not in the file until the
    next /reload. The header shows when the file was last written.

.PARAMETER Client
    Retail (default), Ptr, Xptr, Beta, Classic (Mists), ClassicPtr, Era, EraPtr, Anniversary or Forever.

.PARAMETER Account
    Account folder name (e.g. 133658957#1) instead of the most recently written file.

.PARAMETER Run
    Shows the nth newest of the kept runs (1 = the newest) instead of the last one; the reader lists them all.

.EXAMPLE
    & ".claude\tools\Read-GameTests.ps1"
    & ".claude\tools\Read-GameTests.ps1" -Client Era -Run 2
#>
[CmdletBinding()]
param(
    [ValidateSet('Retail', 'Ptr', 'Xptr', 'Beta', 'Classic', 'ClassicPtr', 'Era', 'EraPtr', 'Anniversary', 'Forever')][string]$Client = 'Retail',
    [string]$Account,
    [int]$Run
)

$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent   # .claude\tools -> the checkout's root
$reader = Join-Path $PSScriptRoot 'read-tests.lua'
$headlessRunner = Join-Path $root 'Tests\Krowi_OptionsTests\Run-Headless.lua'
$kitTools = if ($env:KROWI_CLAUDEKIT) { Join-Path $env:KROWI_CLAUDEKIT 'tools' } else { 'E:\World of Warcraft Addon Development\Krowi_ClaudeKit\tools' }
. (Join-Path $kitTools 'AddonContext.ps1')   # Get-ClientFolder, $Lua
if (-not (Test-Path -LiteralPath $Lua)) { throw "The kit's Lua 5.1 not found at $Lua." }

$wtf = Join-Path (Get-ClientFolder $Client) 'WTF\Account'
if (-not (Test-Path -LiteralPath $wtf)) { throw "No WTF\Account folder for $Client at $wtf" }
$candidates = if ($Account) {
    Get-Item -LiteralPath (Join-Path $wtf "$Account\SavedVariables\Krowi_OptionsTests.lua")
} else {
    Get-ChildItem -LiteralPath $wtf -Directory | ForEach-Object { Join-Path $_.FullName 'SavedVariables\Krowi_OptionsTests.lua' } |
        Where-Object { Test-Path -LiteralPath $_ } | Get-Item | Sort-Object LastWriteTime -Descending
}
$file = $candidates | Select-Object -First 1
if (-not $file) { throw "No Krowi_OptionsTests.lua found under $wtf; has the client been reloaded since the test addon was installed?" }

$age = (Get-Date) - $file.LastWriteTime
"Saved variables: $($file.FullName)"
"  last written $($file.LastWriteTime) ($([int]$age.TotalMinutes) min ago; the game only writes it on /reload or logout)"
""

# The headless lines of the scenarios, so the game's lines can be marked against them
$headless = Join-Path ([IO.Path]::GetTempPath()) 'Krowi_OptionsTests-headless.txt'
$ErrorActionPreference = 'Continue'
$headlessLines = @(& $Lua $headlessRunner 2>&1 | ForEach-Object { "$_" })
$ErrorActionPreference = 'Stop'
[IO.File]::WriteAllLines($headless, [string[]]$headlessLines, [Text.UTF8Encoding]::new($false))

$shotDir = Join-Path (Get-ClientFolder $Client) 'Screenshots'
$shots = @(if (Test-Path -LiteralPath $shotDir) {
    Get-ChildItem -LiteralPath $shotDir -File -Filter 'WoWScrnShot_*' | ForEach-Object {
        $t = [datetime]::MinValue
        if ($_.BaseName -match '^WoWScrnShot_(\d{6})_(\d{6})$' -and
            [datetime]::TryParseExact($Matches[1] + $Matches[2], 'MMddyyHHmmss', [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$t)) {
            [pscustomobject]@{ Time = $t; Path = $_.FullName }
        }
    }
})
$encoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [Text.Encoding]::UTF8
try {
    $readerArgs = @($file.FullName, $headless) + @(if ($Run -gt 0) { "$Run" })
    $output = & $Lua $reader @readerArgs
    $code = $LASTEXITCODE
} finally {
    [Console]::OutputEncoding = $encoding
}
foreach ($line in $output) {
    if ("$line" -match '^(\s+)screenshot at (\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)(.*)$') {
        $at = [datetime]::ParseExact($Matches[2], 'yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
        $indent, $tail = $Matches[1], $Matches[3]
        $best = $shots | Where-Object { ($_.Time - $at).TotalSeconds -ge -1 -and ($_.Time - $at).TotalSeconds -le 2 } |
            Sort-Object { [math]::Abs(($_.Time - $at).TotalSeconds) } | Select-Object -First 1
        "${indent}screenshot at $($at.ToString('HH:mm:ss')): $(if ($best) { $best.Path } else { 'none found' })$tail"
    } else {
        "$line"
    }
}
Remove-Item -LiteralPath $headless -ErrorAction SilentlyContinue
exit $code