--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The test addon's runner, after Krowi_AchievementFilter's Tests/Tests.lua, with one suite: the library's options suite.
-- It registers the fixture tab (Fixtures.lua) with the copy of the library in this addon's Libs folder.
--   /kotest              the scenarios (Scenarios.lua), then every live step (Steps.lua)
--   /kotest <what>       the scenarios and some steps: smoke, behaviour, a step's name, the start of names, a number
--   /kotest run <entry>[, <entry> ...]
--                        several in order (an entry is what /kotest takes, "all" for everything), then a summary panel
--                        with each entry's counts and failed and skipped lines is screenshotted and the kit's marker
--                        (KrowiGameInput) is told the run is done; .claude/tools/Run-GameTests.ps1 types it
-- Results go to chat and to KrowiOptionsTests_Debug.Tests: LastRun, Runs[<entry>] (the latest run of each entry, "all"
-- for everything) and History (the last 10 runs, oldest first), which the game writes on the next /reload or logout;
-- .claude/tools/Read-GameTests.ps1 prints them with each step's screenshot and marks the scenario lines that differ from
-- the headless run. A result with GameOnly set is a live step, which the reader shows without comparing it.
-- Refuses to run in combat, and combat stops a run. Nothing here sets a CVar.

local addonName, addon = ...
addon.Tests = addon.Tests or {}
local tests = addon.Tests
local fixtures = tests.Fixtures

local prefix = "|cFF1D92C2Krowi_Options test:|r "
local keepRuns = 10 -- runs kept in History
-- Addons that embed the library too: one loaded before this addon serves its copy's files where the minors are equal
local consumers = { "Krowi_AchievementFilter", "Krowi_ExtendedVendorUI" }
local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local IsLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

local loaded -- this addon's saved variables are there (ADDON_LOADED)

-- The table the fixture tab hands the library as config.Saved, in this addon's saved variable; nothing until that loads,
-- so the library asks again later
function tests.SavedOptions()
    if not loaded then return nil end
    KrowiOptionsTests_Debug.Options = KrowiOptionsTests_Debug.Options or {}
    return KrowiOptionsTests_Debug.Options
end

local function GetDb()
    KrowiOptionsTests_Debug = KrowiOptionsTests_Debug or {}
    KrowiOptionsTests_Debug.Tests = KrowiOptionsTests_Debug.Tests or {}
    return KrowiOptionsTests_Debug.Tests
end

-- Each of the library's LibStub entries with the minor that won, so a run shows which copy's files it tested
local function LibraryMinors()
    local entries = {}
    if LibStub and LibStub.IterateLibraries then
        for name in LibStub:IterateLibraries() do
            if name:find("^Krowi_Options_2") then
                local _, minor = LibStub:GetLibrary(name, true)
                tinsert(entries, ("%s %s"):format(name:gsub("^Krowi_Options_2_?", ""):gsub("^$", "core"), tostring(minor)))
            end
        end
    end
    table.sort(entries)
    return table.concat(entries, ", ")
end

local function HostObservations()
    local observations = {}
    for _, name in ipairs(consumers) do
        if IsLoaded and IsLoaded(name) then
            tinsert(observations, name .. " is loaded too: it loads before this addon, so where its copy of the library has the same minor"
                .. " as this one, its copy's file is the one under test (minors: " .. LibraryMinors() .. ")")
        end
    end
    return observations
end

local statusColors = {
    PASS = "|cFF00FF00",
    FAIL = "|cFFFF0000",
    SKIP = "|cFFFFFF00"
}

-- argument: what was typed after /kotest, nil for everything
local function Report(results, observations, argument)
    local counts = {PASS = 0, FAIL = 0, SKIP = 0}
    local open = 0
    local lines, gameOnly, screenshots = {}, {}, {}
    for i, result in ipairs(results) do
        counts[result.Status] = counts[result.Status] + 1
        if result.TargetMet == false then
            open = open + 1
        end
        lines[i] = result.Line
        gameOnly[i] = result.GameOnly
        screenshots[i] = result.Screenshot
        print(prefix .. (statusColors[result.Status] or "") .. result.Line .. "|r")
    end
    local summary = ("options%s: %d passed, %d failed, %d skipped; %d open against the target behaviour"):format(argument and (" " .. argument) or "",
        counts.PASS, counts.FAIL, counts.SKIP, open)
    print(prefix .. summary)
    for _, observation in ipairs(observations or {}) do
        print(prefix .. "observed: " .. observation)
    end
    print(prefix .. "written to the saved variables on the next /reload; read with .claude/tools/Read-GameTests.ps1")

    local db = GetDb()
    db.LastRun = {
        Suite = "options",
        Argument = argument,
        Version = GetMetadata and GetMetadata(addonName, "Version"),
        Library = LibraryMinors(),
        Build = (GetBuildInfo()),
        Time = date("%Y-%m-%d %H:%M:%S"),
        Passed = counts.PASS,
        Failed = counts.FAIL,
        Skipped = counts.SKIP,
        Open = open,
        Lines = lines,
        GameOnly = gameOnly, -- index = line index; steps the headless run does not have
        Screenshots = screenshots, -- index = line index; the screenshot taken after that line's check
        Observations = observations and CopyTable(observations) or nil
    }
    db.Runs = db.Runs or {}
    db.Runs[argument or "all"] = db.LastRun
    db.History = db.History or {}
    tinsert(db.History, db.LastRun)
    while #db.History > keepRuns do
        tremove(db.History, 1)
    end
end

-- onDone(ran, reason): called once the run reported, or could not run and why
function tests.Run(argument, onDone)
    local function NotRun(reason)
        print(prefix .. reason)
        if onDone then
            onDone(false, reason)
        end
    end
    if InCombatLockdown() then
        NotRun("not while in combat")
        return
    end
    if not fixtures.Tab then
        NotRun("Krowi_Options is not loaded: Libs\\Krowi_Util and Libs\\Krowi_Options are deployed by .claude/tools/Deploy-TestAddon.ps1")
        return
    end
    if not tests.SavedOptions() then
        NotRun("the saved variables are not loaded yet")
        return
    end
    if tests.Steps.IsRunning() then
        NotRun("the previous run is still going")
        return
    end
    tests.Steps.Start(function(results, observations)
        Report(results, observations, argument)
        if onDone then
            onDone(true)
        end
    end, argument, HostObservations())
end

-- [[ Several runs in one go: /kotest run ]] --
-- The saved variables reach disk only at the next /reload or logout, so when the runs are done a panel shows each one's
-- counts and its failed and skipped lines and a screenshot is taken, which Read-GameScreenshot.ps1 finds while the game
-- still runs. Then the kit's marker addon (KrowiGameInput, Krowi_ClaudeKit's docs/work/2026-11-05-kit-test-runs) is told
-- the run is done, and the kit's Send-GameInput.ps1 -WaitForDone, which .claude/tools/Run-GameTests.ps1 runs, types /reload.

local summaryPanel

local function ShowSummary(lines)
    if not summaryPanel then
        summaryPanel = CreateFrame("Frame", nil, UIParent)
        summaryPanel:SetFrameStrata("FULLSCREEN_DIALOG")
        summaryPanel:SetPoint("TOP", 0, -120)
        local background = summaryPanel:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(0, 0, 0, 0.9)
        summaryPanel.Text = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        summaryPanel.Text:SetPoint("TOPLEFT", 16, -16)
        summaryPanel.Text:SetWidth(1200)
        summaryPanel.Text:SetJustifyH("LEFT")
    end
    summaryPanel.Text:SetText(table.concat(lines, "\n"))
    summaryPanel:SetSize(1232, summaryPanel.Text:GetStringHeight() + 32)
    summaryPanel:Show()
    C_Timer.After(1, function()
        GetDb().RequestSummary = {Time = date("%Y-%m-%d %H:%M:%S"), Lines = lines}
        Screenshot()
        print(prefix .. "run done; the full results reach the saved variables at the next /reload or logout")
        if KrowiGameInput then
            KrowiGameInput.Done()
        end
    end)
    C_Timer.After(20, function()
        summaryPanel:Hide()
    end)
end

local function RunEntries(entries)
    local lines = {("Krowi_Options test run, %s, build %s"):format(date("%Y-%m-%d %H:%M:%S"), (GetBuildInfo()))}
    local index, ranAny = 0, false
    local function Next()
        index = index + 1
        local entry = entries[index]
        if not entry then
            if ranAny then -- the steps drive Blizzard's frames from addon code, some of it taints until a reload
                tinsert(lines, "/reload before entering combat")
            end
            ShowSummary(lines)
            return
        end
        local argument = entry ~= "all" and entry or nil
        tests.Run(argument, function(ran, reason)
            local run = GetDb().LastRun
            ranAny = ranAny or ran
            if ran and run then
                tinsert(lines, ("%s: %d passed, %d failed, %d skipped; %d open"):format(entry, run.Passed, run.Failed, run.Skipped, run.Open))
                for _, line in ipairs(run.Lines) do
                    if line:find(": FAIL ", 1, true) or line:find(": SKIP ", 1, true) then
                        tinsert(lines, "    " .. line:sub(1, 180))
                    end
                end
            else
                tinsert(lines, ("%s: did not run, %s"):format(entry, tostring(reason)))
            end
            Next()
        end)
    end
    Next()
end

-- The entries of /kotest run, split on commas: "smoke, toggle" -> {"smoke", "toggle"}
function tests.RunEntriesOf(text)
    local entries = {}
    for entry in (text or ""):gmatch("[^,]+") do
        entry = strtrim(entry)
        if entry ~= "" then
            tinsert(entries, entry)
        end
    end
    return entries
end

local function StartRun(text)
    local entries = tests.RunEntriesOf(text)
    if #entries == 0 then
        print(prefix .. "/kotest run <all, smoke, behaviour, a step or the start of names>[, ...]")
        return
    end
    print(prefix .. "running " .. table.concat(entries, ", "))
    -- A "done" left on the kit's marker by an earlier run must not end this one's wait (-WaitForDone)
    if KrowiGameInput then
        KrowiGameInput.Clear()
    end
    RunEntries(entries)
end

SLASH_KROWIOPTIONSTESTS1 = "/kotest"
SlashCmdList.KROWIOPTIONSTESTS = function(msg)
    local text = strtrim(msg or "")
    local command = strsplit(" ", text)
    if command == "run" then
        StartRun(text:match("^run%s+(.+)$"))
    elseif text == "" or text == "all" then
        tests.Run(nil)
    else
        tests.Run(command)
    end
end

-- The fixture tab, registered while the addon loads, on the copy of the library LibStub serves
local lib = KROWI_LIBMAN and KROWI_LIBMAN:GetLibrary("Krowi_Options_2", true)
if lib then
    fixtures.Register(lib, tests.SavedOptions)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    KrowiOptionsTests_Debug = KrowiOptionsTests_Debug or {}
    loaded = true
end)