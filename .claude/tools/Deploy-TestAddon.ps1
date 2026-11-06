<#
.SYNOPSIS
    Deploys the library's test addon, Krowi_OptionsTests, into a game client: its own files from this checkout's
    Tests\Krowi_OptionsTests, this checkout's library into its Libs\Krowi_Options and Krowi_Util into its Libs\Krowi_Util,
    as an addon embeds them. The library is never deployed as an AddOns folder of its own (the workspace CLAUDE.md).

.DESCRIPTION
    1. Tests\Krowi_OptionsTests is mirrored into <client>\Interface\AddOns\Krowi_OptionsTests: every .lua, .xml and .toc
       file, Libs\Files.xml included, but not Headless.lua and Run-Headless.lua (the headless harness's only). Only files
       whose size or content differ are copied (the same size, time and MD5 comparison as the kit's Deploy.ps1); files in
       the destination that the checkout no longer has are deleted, apart from Libs\Krowi_Options and Libs\Krowi_Util,
       which steps 2 and 3 own.
    2. The library from the root of this checkout (the main checkout or the worktree this script runs from) through the
       kit's Deploy.ps1 -Destination ...\Krowi_OptionsTests\Libs\Krowi_Options. The kit's Deploy reads _Packaging/.pkgmeta,
       whose ignore list keeps Tests out, so the folder holds what the release zip holds.
    3. Krowi_Util from its main checkout (Krowi_Libraries\Krowi_Util, on whatever branch it is) through the kit's Deploy.ps1
       -Destination ...\Krowi_OptionsTests\Libs\Krowi_Util.

    The game finds a new addon folder only when it starts: after the first deploy into a client, the client needs a
    restart before /kotest exists. The deployed files load on the next /reload. Another addon that embeds the library
    (Krowi_AchievementFilter) loads before this one, so where its copy has the same minor as this checkout's, its file is
    the one under test: the run notes it (Runner.lua); for a clean run turn that addon off on the test character, or raise
    the minors.

.PARAMETER Consumers
    Also deploys this checkout's library into the Libs\Krowi_Options of every other addon installed in the client that
    embeds one (Krowi_AchievementFilter, Krowi_ExtendedVendorUI, ...), so that every copy of the library the client loads
    is this checkout's and a run tests this checkout whatever the load order is. Without it, a consumer that loads first
    (they all do) wins at equal minors with its own, older copy. The consumer's own deploy (the kit's Deploy.ps1 from its
    checkout) puts its copy back afterwards.

.PARAMETER Client
    Retail (default), Ptr, Xptr, Beta, Classic (Mists), ClassicPtr, Era, EraPtr, Anniversary or Forever.

.PARAMETER WhatIf
    Lists what would be copied and deleted without doing it.

.EXAMPLE
    & ".claude\tools\Deploy-TestAddon.ps1" -WhatIf
    & ".claude\tools\Deploy-TestAddon.ps1" -Client Classic
#>
[CmdletBinding()]
param(
    [ValidateSet('Retail', 'Ptr', 'Xptr', 'Beta', 'Classic', 'ClassicPtr', 'Era', 'EraPtr', 'Anniversary', 'Forever')][string]$Client = 'Retail',
    [switch]$Consumers,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent   # .claude\tools -> the checkout's root
$source = Join-Path $root 'Tests\Krowi_OptionsTests'
# The kit, or a kit worktree named by $env:KROWI_CLAUDEKIT
$kitTools = if ($env:KROWI_CLAUDEKIT) { Join-Path $env:KROWI_CLAUDEKIT 'tools' } else { 'E:\World of Warcraft Addon Development\Krowi_ClaudeKit\tools' }
$deploy = Join-Path $kitTools 'Deploy.ps1'
if (-not (Test-Path -LiteralPath $deploy)) { throw "The kit's Deploy.ps1 not found at $deploy." }
. (Join-Path $kitTools 'AddonContext.ps1')   # Get-ClientFolder, $DevRoot
$util = Join-Path $DevRoot 'Krowi_Libraries\Krowi_Util'
if (-not (Test-Path -LiteralPath (Join-Path $util 'Krowi_Util.xml'))) { throw "Krowi_Util not found at $util." }

$addOns = Join-Path (Get-ClientFolder $Client) 'Interface\AddOns'
if (-not (Test-Path -LiteralPath $addOns)) { throw "AddOns folder not found: $addOns (is the $Client client installed?)" }
$destination = Join-Path $addOns 'Krowi_OptionsTests'

$extensions = @('.lua', '.xml', '.toc')
$headlessOnly = @('Headless.lua', 'Run-Headless.lua')
$embedded = @('Libs\Krowi_Options', 'Libs\Krowi_Util')   # filled by the kit's Deploy, never by the mirror

function Get-Relative([string]$Base, [string]$Full) { $Full.Substring($Base.Length).TrimStart('\') }
function Test-Embedded([string]$Relative) {
    foreach ($folder in $embedded) {
        if ($Relative -eq $folder -or $Relative.StartsWith("$folder\", [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    $false
}
function Get-Commit([string]$Repo) {
    $branch = git -C $Repo branch --show-current 2>$null
    $sha = git -C $Repo rev-parse --short HEAD 2>$null
    $dirty = if (git -C $Repo status --porcelain 2>$null) { ', uncommitted changes' } else { '' }
    "$(if ($branch) { $branch } else { 'detached' }) $sha$dirty"
}

# --- 1. The test addon's own files ------------------------------------------------------------------------------
$sourceFiles = @{}
foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) {
    $relative = Get-Relative $source $file.FullName
    if ($extensions -notcontains $file.Extension.ToLowerInvariant()) { continue }
    if ($headlessOnly -contains $relative -or (Test-Embedded $relative)) { continue }
    $sourceFiles[$relative] = $file
}
if (-not ($sourceFiles.Keys | Where-Object { $_ -eq 'Krowi_OptionsTests.toc' })) { throw "No Krowi_OptionsTests.toc in $source." }

$target = @{}
if (Test-Path -LiteralPath $destination) {
    foreach ($file in Get-ChildItem -LiteralPath $destination -Recurse -File) {
        $relative = Get-Relative $destination $file.FullName
        if (-not (Test-Embedded $relative)) { $target[$relative] = $file }
    }
}

$md5 = [System.Security.Cryptography.MD5]::Create()
function Get-Hash([string]$Path) { [BitConverter]::ToString($md5.ComputeHash([IO.File]::ReadAllBytes($Path))) }
$toCopy = @()
$unchanged = 0
foreach ($relative in $sourceFiles.Keys) {
    $s = $sourceFiles[$relative]; $t = $target[$relative]
    $same = $false
    if ($t -and $t.Length -eq $s.Length) {
        $same = ([math]::Abs(($t.LastWriteTimeUtc - $s.LastWriteTimeUtc).TotalSeconds) -lt 2) -or ((Get-Hash $s.FullName) -eq (Get-Hash $t.FullName))
    }
    if ($same) { $unchanged++ } else { $toCopy += $relative }
}
$toDelete = @($target.Keys | Where-Object { -not $sourceFiles.ContainsKey($_) })

"Deploy $source ($Client) -> $destination"
"  from $(Get-Commit $root)"
"  $($sourceFiles.Count) source files: $unchanged unchanged, $($toCopy.Count) to copy, $($toDelete.Count) to delete"
if ($WhatIf) {
    foreach ($relative in ($toCopy | Sort-Object)) { "  copy   $relative" }
    foreach ($relative in ($toDelete | Sort-Object)) { "  delete $relative" }
} else {
    foreach ($relative in $toCopy) {
        $path = Join-Path $destination $relative
        $folder = Split-Path $path -Parent
        if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
        Copy-Item -LiteralPath $sourceFiles[$relative].FullName -Destination $path -Force
    }
    foreach ($relative in $toDelete) { Remove-Item -LiteralPath (Join-Path $destination $relative) -Force }
    # Folders the deletions left empty, never the embedded libraries' own
    if ($toDelete.Count -gt 0) {
        Get-ChildItem -LiteralPath $destination -Recurse -Directory | Sort-Object FullName -Descending |
            Where-Object { -not (Test-Embedded (Get-Relative $destination $_.FullName)) -and -not (Get-ChildItem -LiteralPath $_.FullName -Force | Select-Object -First 1) } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
    }
    "  done: $($toCopy.Count) copied, $($toDelete.Count) deleted"
}

# --- 2 and 3. The embedded libraries, through the kit's Deploy ---------------------------------------------------
$libs = Join-Path $destination 'Libs'
foreach ($library in @([ordered]@{ Name = 'Krowi_Options'; Repo = $root }, [ordered]@{ Name = 'Krowi_Util'; Repo = $util })) {
    $libraryDestination = Join-Path $libs $library.Name
    ""
    "$($library.Name) from $($library.Repo) ($(Get-Commit $library.Repo))"
    if ($WhatIf -and -not (Test-Path -LiteralPath $libs)) {
        # The kit's Deploy refuses a destination whose parent folder is missing, which only the mirror above makes
        "  Libs is not in the game's copy yet: the kit's Deploy would copy every file of it into $libraryDestination"
        continue
    }
    & $deploy -Client $Client -Repo $library.Repo -Destination $libraryDestination -WhatIf:$WhatIf
}

# --- 4. The same library into the other addons that embed one (-Consumers) --------------------------------------
if ($Consumers) {
    $others = @(Get-ChildItem -LiteralPath $addOns -Directory | Where-Object {
        $_.Name -ne 'Krowi_OptionsTests' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'Libs\Krowi_Options\Krowi_Options.lua')) })
    ""
    if ($others.Count -eq 0) { "-Consumers: no other addon in the $Client client embeds the library." }
    foreach ($other in $others) {
        "-Consumers: $($other.Name)"
        & $deploy -Client $Client -Repo $root -Destination (Join-Path $other.FullName 'Libs\Krowi_Options') -WhatIf:$WhatIf
    }
    if ($others.Count -gt 0 -and -not $WhatIf) { "  Their own deploy (Deploy.ps1 from each addon's checkout) puts their copies back." }
}

# A standalone Krowi_Options folder (a two-copy test's, left behind) loads as a copy of its own
$standalone = Join-Path $addOns 'Krowi_Options'
if (Test-Path -LiteralPath $standalone) {
    ""
    "Warning: $standalone exists: a standalone copy of the library loads too (a two-copy test's leftover?); remove it for a run of this checkout's copy."
}
if (-not $WhatIf) { ""; "Type /reload in the $Client client (a first deploy needs a client restart) to pick the files up." }