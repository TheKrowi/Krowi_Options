<#
.SYNOPSIS
    Runs the library's test addon (/kotest, Krowi_OptionsTests) in the game from start to results with the kit's
    game-input tools: nothing is written into the game's files and nobody needs to type or move the mouse. After
    Krowi_AchievementFilter's .claude\tools\Run-GameTests.ps1.

.DESCRIPTION
    Deploy first (Deploy-TestAddon.ps1, -WhatIf first): this tool deploys nothing. Then, one client at a time:
    1. The kit's marker addon is installed or updated in the client (Send-GameInput.ps1 -Install).
    2. A running client is used as it is: in the world it gets a /reload first, so the deployed files and the marker
       load; at character select it enters the world. A closed one is started (Start-Game.ps1 -Wait, which refuses
       while another client runs: they share one Battle.net account) and enters the world. The game finds a new addon
       folder only when it starts, so the first run after the first deploy into a client needs a client this tool starts.
    3. /kotest run <entries>, then Send-GameInput.ps1 -WaitForDone: it serves the hovers the mouse steps ask for
       (toggle-reset-clipped, link-highlight, greyed-slider-input) and returns when the summary is up.
    4. /reload, so the results reach the saved variables, then Read-GameTests.ps1 per entry and the kit's
       Read-GameErrors.ps1 for Krowi_Options.
    5. -Quit for a client this tool started, unless -KeepOpen.

    Exits 0 only when every entry left a run, no run has a FAIL and every run passed something (a run whose every step
    was skipped proves nothing), 1 otherwise. A scenario line that differs from the headless run is shown but does not
    fail the run: it asks for a look, not for the build to be stopped.

    The kit's guard holds throughout: a client the kit started takes input after 15 s without input on the PC, any
    other client after 5 minutes. A refusal that says when to try again is retried then, for up to 10 minutes.

.PARAMETER Entries
    What to run, as /kotest run takes it: all (default), a set (smoke, behaviour), a step's name, the start of names
    (toggle, search, section) or a step's number. Several as separate arguments or comma-separated: smoke, toggle.

.PARAMETER Client
    Retail (default), Ptr, Xptr, Beta, Classic (Mists), ClassicPtr, Era, EraPtr, Anniversary or Forever.

.PARAMETER Timeout
    Seconds the run may take, from /kotest run to its summary. Default 900.

.PARAMETER KeepOpen
    Leaves a client this tool started running.

.EXAMPLE
    & ".claude\tools\Run-GameTests.ps1"
    & ".claude\tools\Run-GameTests.ps1" smoke -Client Classic
    & ".claude\tools\Run-GameTests.ps1" toggle-reset-clipped, search
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string[]]$Entries = @('all'),
    [ValidateSet('Retail', 'Ptr', 'Xptr', 'Beta', 'Classic', 'ClassicPtr', 'Era', 'EraPtr', 'Anniversary', 'Forever')][string]$Client = 'Retail',
    [int]$Timeout = 900,
    [switch]$KeepOpen
)

$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent   # .claude\tools -> the checkout's root
$reader = Join-Path $PSScriptRoot 'Read-GameTests.ps1'
$kitTools = if ($env:KROWI_CLAUDEKIT) { Join-Path $env:KROWI_CLAUDEKIT 'tools' } else { 'E:\World of Warcraft Addon Development\Krowi_ClaudeKit\tools' }
. (Join-Path $kitTools 'AddonContext.ps1')
$send = Join-Path $kitTools 'Send-GameInput.ps1'
if (-not (Test-Path -LiteralPath $send)) { throw "The kit's Send-GameInput.ps1 not found at $send." }

$list = @($Entries | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
foreach ($entry in $list) {
    if ($entry -notmatch '^[a-z0-9][a-z0-9-]*$') { throw "Not an entry of /kotest run (all, smoke, behaviour, a step's name or number): '$entry'" }
}
if (-not $list) { throw 'Name at least one entry.' }
$runText = $list -join ', '

# The kit must have -WaitForDone (Krowi_ClaudeKit's docs/work/2026-11-05-kit-test-runs)
if (-not (Get-Command $send).Parameters.ContainsKey('WaitForDone')) {
    throw "The kit's Send-GameInput.ps1 has no -WaitForDone: point `$env:KROWI_CLAUDEKIT at a kit checkout that has it."
}

# One kit call, its lines shown as they come; a refusal that says when to try again is retried then, for up to 10
# minutes per call. Returns only the call's exit code.
function Invoke-Kit([string]$What, [hashtable]$Arguments) {
    $retryUntil = (Get-Date).AddMinutes(10)
    while ($true) {
        $out = @(& $send -Client $Client @Arguments 2>&1 | ForEach-Object { "$_" })
        $code = $LASTEXITCODE
        $out | ForEach-Object { Write-Host "  $_" }
        $last = if ($out) { $out[-1] } else { '' }
        # A refusal that says when to try again, or that someone used the keyboard or mouse while the command ran (the
        # player is at the PC: wait until they are not), is retried; any other refusal is final
        $wait = $null
        if ($last -match 'try again in (\d+) s') { $wait = [int]$Matches[1] + 2 }
        elseif ($last -match 'someone else used the keyboard or mouse') { $wait = 20 }
        if ($code -eq 0 -or $null -eq $wait) { return $code }
        if ((Get-Date) -gt $retryUntil) { Write-Host "  $What gave up: still refused after 10 minutes"; return $code }
        Start-Sleep -Seconds $wait
    }
}
$started = $false
# A client this tool started is closed whatever happens after
function Close-Started {
    if ($script:started -and -not $KeepOpen) {
        "Closing the $Client client this tool started"
        $null = Invoke-Kit 'closing' @{ Quit = $true }
        $script:started = $false
    }
}
function Stop-Run([string]$Reason) { Close-Started; "Run-GameTests: $Reason"; exit 1 }

"Run-GameTests: /kotest run $runText on $Client"
$null = & $send -Client $Client -Install
$state = (& $send -Client $Client -State 2>&1 | Out-String)
if ($state -match 'client: not running') {
    "Starting the $Client client"
    & (Join-Path $kitTools 'Start-Game.ps1') -Client $Client -Wait
    $started = $true
    $state = (& $send -Client $Client -State 2>&1 | Out-String)
}

if ($state -match 'state: in the world') {
    # The game finds a new addon folder only when it starts: a client running since before the folder was made would
    # type /kotest into the void and the run would wait its whole timeout
    $clientFolder = Get-ClientFolder $Client
    $addonFolder = Join-Path $clientFolder 'Interface\AddOns\Krowi_OptionsTests'
    $running = @(Get-Process -Name 'Wow*' -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$clientFolder*" })
    if (-not $started -and (Test-Path -LiteralPath $addonFolder) -and $running.Count -gt 0 -and
        (Get-Item -LiteralPath $addonFolder).CreationTimeUtc -gt ($running | Sort-Object StartTime | Select-Object -First 1).StartTime.ToUniversalTime()) {
        Stop-Run "the $Client client started before the test addon folder was first deployed, so it does not know /kotest: Krowi closes it, and this tool starts it."
    }
    "/reload, so the deployed files and the marker load"
    if ((Invoke-Kit '/reload' @{ Command = '/reload' }) -ne 0) { Stop-Run 'the first /reload failed' }
} elseif ($state -match 'state: character select') {
    'Entering the world'
    if ((Invoke-Kit 'entering the world' @{ EnterWorld = $true }) -ne 0) { Stop-Run 'could not enter the world' }
} else {
    # In the world without the marker: nothing can be typed, and the game only finds a new addon folder when it starts
    $stateLine = ((($state -split "`r?`n") | Where-Object { $_ -match 'state:' }) -join ' ').Trim()
    Stop-Run "the $Client client is neither in the world with the marker nor at character select ($stateLine). If the marker or the test addon was only just installed, the client needs a restart: Krowi closes it, and this tool starts it."
}

"/kotest run $runText"
$runStart = Get-Date
if ((Invoke-Kit '/kotest run' @{ Command = "/kotest run $runText" }) -ne 0) { Stop-Run 'could not type the run' }

'Waiting for the run to be done'
$waited = Invoke-Kit 'waiting' @{ WaitForDone = $true; Timeout = $Timeout }

# Also after a timeout: the entries that finished reach the saved variables
'/reload, so the results reach the saved variables'
$reloaded = Invoke-Kit '/reload' @{ Command = '/reload' }

$ours = @()
$failedRuns = 0
if ($reloaded -eq 0) {
    # Only the kept runs of this run, by their time in the reader's list ("  2. 2026-11-05 17:28:23 ...")
    try { $listing = @(& $reader -Client $Client 2>&1 | ForEach-Object { "$_" }) }
    catch { Stop-Run "Read-GameTests.ps1 could not read the $Client client's runs: $($_.Exception.Message)" }
    $ours = @($listing | ForEach-Object {
        if ($_ -match '^\s+(\d+)\. (\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) ') {
            $time = [datetime]::ParseExact($Matches[2], 'yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
            if ($time -ge $runStart.AddSeconds(-1)) { [int]$Matches[1] }
        }
    } | Sort-Object -Unique -Descending)
    if ($ours.Count -eq 0) { "No run of this session reached the saved variables (the summary's screenshot shows what ran: the kit's Read-GameScreenshot.ps1 -Client $Client)" }
    if ($ours.Count -lt $list.Count) { "Only $($ours.Count) of $($list.Count) entries left a run; the summary's screenshot says why the others did not run" }
    # A run fails on a FAIL line, when nothing in it passed, or when the reader cannot read it; its "suite ..." line has
    # the counts. The verdict reads that line, not the reader's exit code, which also counts differences from headless.
    foreach ($n in $ours) {
        try { $read = @(& $reader -Client $Client -Run $n 2>&1 | ForEach-Object { "$_" }) }
        catch { $read = @("Read-GameTests.ps1 -Run $n threw: $($_.Exception.Message)") }
        $read
        $summary = @($read | Where-Object { $_ -match '^suite .+: \d+ passed, \d+ failed' })[0]
        if (-not $summary) { "Run $n has no 'suite ...: N passed, M failed' line; it counts as failed" }
        $passedSomething = $summary -match '^suite .+: (\d+) passed, 0 failed' -and [int]$Matches[1] -gt 0
        # a run the runner stopped early (combat started) reports the steps it reached only: not a pass
        $stopped = ($read -join "`n") -match 'observed in game: stopped'
        if ($stopped) { "Run $n was stopped before its end (see its observations); it counts as failed" }
        if (-not $passedSomething -or $stopped) { $failedRuns++ }
    }
    # A client without BugGrabber (Anniversary, Era) has no error log to read: say so, and still close the client below
    try { & (Join-Path $kitTools 'Read-GameErrors.ps1') -Client $Client -Repo $root }
    catch { "Read-GameErrors.ps1 could not read the $Client client's errors: $($_.Exception.Message)" }
}

Close-Started
if ($waited -ne 0) { Stop-Run 'the run did not report done in time (see above)' }
if ($reloaded -ne 0) { Stop-Run 'the last /reload failed, so the results are not on disk' }
if ($ours.Count -lt $list.Count) { Stop-Run "only $($ours.Count) of $($list.Count) entries left a run" }
if ($failedRuns -gt 0) { Stop-Run "$failedRuns of $($ours.Count) run(s) failed (see above)" }
'Run-GameTests: done'
exit 0