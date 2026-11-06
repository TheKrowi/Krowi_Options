--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The headless harness of the library's own tests: the library's real files, in the order Krowi_Options.xml lists them
-- (and the Include files it names), on Krowi_Util's real LibStub, AceLocale and LibMan, with the window's methods called
-- on stand-ins for its frames. The suites in suites/ take it as their first argument; run.lua runs them all.
--
-- What it cannot do: build rows or a window. The stand-in has no real CreateFrame scripts, ScrollBox, templates or
-- C_Timer, so everything that draws is proven in game (Tests/Krowi_OptionsTests). What it can: the logic that does run
-- here (Search, Flatten, the signatures, the config checks, the registrations and minors, two copies).
--
-- Run: <Krowi_ClaudeKit>\tools\lua51\lua.exe Tests\headless\run.lua   (from the repo root or a worktree's)

local h = {}

-- The repo root, as a path prefix from where the script runs ("" from the root itself)
h.root = ((arg and arg[0]) or ""):gsub("\\", "/"):match("^(.-)Tests/headless/") or ""

-- Krowi_Util beside the library's main checkout, seen from it or from a worktree under its .claude/worktrees/
local UTIL
for _, up in ipairs({ "../", "../../../../" }) do
    local file = io.open(h.root .. up .. "Krowi_Util/Libs/LibStub.lua", "rb")
    if file then
        file:close()
        UTIL = h.root .. up .. "Krowi_Util/"
        break
    end
end
assert(UTIL, "Krowi_Util not found beside the library")
h.UTIL = UTIL

function h.Read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return text
end
local Read = h.Read

function h.Run(source, chunkName)
    assert(loadstring(source, chunkName))()
end
local Run = h.Run

-- A plain-text replacement that must match exactly once
function h.Replace(text, old, new)
    local first, last = text:find(old, 1, true)
    assert(first and not text:find(old, last + 1, true), "not found once: " .. old)
    return text:sub(1, first - 1) .. new .. text:sub(last + 1)
end

function h.Noop() end
local Noop = h.Noop
h.NIL = {} -- a Config field left out

-- The library's files in load order, from the XML manifest the game reads (a <Script file> runs, an <Include file> is
-- read in its place); paths are relative to the folder of the XML that names them
local function Manifest(xml, folder, files)
    local text = Read(h.root .. folder .. xml):gsub("<!%-%-.-%-%->", "")
    for tag, file in text:gmatch('<(%a+)%s+file="([^"]+)"') do
        file = file:gsub("\\", "/")
        if tag == "Script" then
            files[#files + 1] = folder .. file
        elseif tag == "Include" then
            Manifest(file:match("([^/]+)$"), folder .. (file:match("^(.*/)") or ""), files)
        end
    end
    return files
end
h.libraryFiles = Manifest("Krowi_Options.xml", "", {})
assert(#h.libraryFiles >= 6, "Krowi_Options.xml names " .. #h.libraryFiles .. " files")

local utilFiles = { "Libs/LibStub.lua", "Libs/AceLocale-3.0.lua", "LibMan.lua", "Krowi_Util.lua", "Constants.lua", "Strings.lua",
    "LocalizationHelper.lua" }

h.handled = {} -- what reached the game's error handler; emptied in place, so a suite may keep it in a local
h.now = 1000 -- what time() answers

-- Every global the files and the checks add goes again, so each check starts from a game with no copy loaded
local baseline = {}
for key in pairs(_G) do baseline[key] = true end

function h.Fresh()
    for key in pairs(_G) do
        if not baseline[key] then _G[key] = nil end
    end
    for key in pairs(h.handled) do h.handled[key] = nil end
    h.now = 1000
    GetLocale = function() return "enUS" end
    geterrorhandler = function() return function(message) h.handled[#h.handled + 1] = message end end
    CallErrorHandler = function(...) return geterrorhandler()(...) end -- Blizzard_SharedXMLBase/ErrorUtil.lua
    tinsert, tremove = table.insert, table.remove
    time = function() return h.now end
    GetBuildInfo = function() return "12.1.5", "1", "", 120105 end
    WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
    strsplittable = function(separator, text)
        local parts = {}
        for part in text:gmatch("[^" .. separator .. "]+") do parts[#parts + 1] = part end
        return parts
    end
    CreateDataProvider = function(list) return list end
    ScrollBoxConstants = { DiscardScrollPosition = 1, RetainScrollPosition = 2, AlignCenter = 3 }
    UIParent = {}
    for _, file in ipairs(utilFiles) do Run(Read(UTIL .. file), file) end
end

-- A copy of the library as an addon embeds it. minors: { [file] = n } raises that file's minor from 0, as a newer copy
-- has it; edits: { [file] = function(source) return source end }
function h.LoadCopy(minors, edits)
    minors, edits = minors or {}, edits or {}
    for _, file in ipairs(h.libraryFiles) do
        local source = Read(h.root .. file)
        if minors[file] then
            local count
            source, count = source:gsub("(NewLibrary%('Krowi_Options_2', )0", "%1" .. minors[file])
            if count == 0 then source, count = source:gsub('(NewSubmodule%("%w+", )0%)', "%1" .. minors[file] .. ")") end
            assert(count == 1, "no minor in " .. file)
        end
        if edits[file] then source = edits[file](source) end
        Run(source, file)
    end
    return KROWI_LIBMAN:GetLibrary("Krowi_Options_2")
end

-- An option with every method the window calls (RowMixins.lua's interface); extra fields replace them
function h.Option(label, extra)
    local option = { Label = label, Type = "toggle", Indent = 0 }
    function option:GetLabel() return self.Label end
    function option:IsHidden() return false end
    function option:IsDisabled() return false end
    function option:GetDescription() return "" end
    function option:Get() return false end
    function option:IsChanged() return false end
    function option:GetNeedsReload() return false end
    for key, value in pairs(extra or {}) do option[key] = value end
    return option
end

-- A tab's config with every field the library reads; NIL leaves a field out
function h.Config(extra)
    local config = {
        TabName = "Test", Saved = {}, Groups = { { Name = "Group", Sections = { "first" } } },
        SectionName = function(id) return id end, IsNew = function() return false end, Landing = function() return "first" end,
        OnSectionShown = Noop, GetElements = function() return {} end, GetHelp = function() return nil end,
        ResetSection = Noop, ChangedCount = function() return 0 end,
    }
    for key, value in pairs(extra or {}) do
        if value == h.NIL then config[key] = nil else config[key] = value end
    end
    return config
end

-- The window's methods (lib.Mixins.Window) on a stand-in for its frames; the parts a check does not look at do nothing
function h.Window(lib, fields)
    local window = {
        Strings = lib.GetStrings(),
        SearchBox = { GetText = function() return "" end, SetText = Noop },
        SearchAll = { SetChecked = Noop }, SearchBroad = { SetChecked = Noop },
        PageTitle = { SetText = Noop }, DefaultsButton = { SetShown = Noop },
        PageScrollBox = { SetDataProvider = Noop, ForEachFrame = Noop, IsMouseOver = function() return false end },
        IsShown = function() return true end,
    }
    for _, method in ipairs({ "RefreshNav", "RefreshFooter", "ShowSectionHelp", "EndFill", "UpdateShowMe", "ScrollToOption",
        "EndKeyCaptures", "RefreshTabs", "RefreshHover", "ApplyWidth", "Layout", "SetHeight", "ClearAllPoints", "SetPoint",
        "SetKicker", "FillHelp" }) do
        window[method] = Noop
    end
    for key, value in pairs(fields or {}) do window[key] = value end
    return setmetatable(window, { __index = lib.Mixins.Window })
end

-- lib.Build.Window as a stand-in window that counts how often it is built and records where it is placed
function h.StandInWindows(lib)
    local built = { Count = 0 }
    lib.Build.Window = function()
        built.Count = built.Count + 1
        built.Last = h.Window(lib, {
            SetPoint = function(_, ...) built.Point = { ... } end,
            RefreshTabs = function() built.Strip = (built.Strip or 0) + 1 end,
        })
        return built.Last
    end
    return built
end

-- A frame that takes every call and logs it: a field read is a child frame made on first read, a call is a method call.
-- The fields a row's mixin keeps its data in read as nil until set, as on a real frame.
local log, methodOf = {}, setmetatable({}, { __mode = "k" })
local dataKeys = { With = true, Option = true, Element = true, Window = true, Capturing = true, Updating = true, Geometry = true }
function h.Recorder()
    return setmetatable({}, {
        __index = function(frame, key)
            if dataKeys[key] then return nil end
            local child = h.Recorder()
            methodOf[child] = key
            rawset(frame, key, child)
            return child
        end,
        __call = function(method, frame, ...)
            log[#log + 1] = { Frame = frame, Method = methodOf[method], Args = { ... } }
            return h.Recorder()
        end,
    })
end

function h.Called(frame, method, value)
    for _, call in ipairs(log) do
        if call.Frame == frame and call.Method == method and call.Args[1] == value then return true end
    end
    return false
end

-- The calls a recorded frame got to one method, oldest first, each as the list of its arguments
function h.CallsTo(frame, method)
    local calls = {}
    for _, call in ipairs(log) do
        if call.Frame == frame and call.Method == method then calls[#calls + 1] = call.Args end
    end
    return calls
end

-- The function a recorded frame was last given for a script (SetScript or HookScript), or nil
function h.ScriptOf(frame, script)
    local found
    for _, call in ipairs(log) do
        if call.Frame == frame and (call.Method == "SetScript" or call.Method == "HookScript") and call.Args[1] == script then
            found = call.Args[2]
        end
    end
    return found
end

-- Frames for the builders: CreateFrame and Blizzard's mixins as recorders
function h.RecordFrames()
    log = {}
    CreateFrame = function() return h.Recorder() end
    Mixin = function(object, ...)
        for i = 1, select("#", ...) do
            for key, value in pairs((select(i, ...))) do object[key] = value end
        end
        return object
    end
    WowStyle2IconButtonMixin, DropdownWithSteppersMixin, MinimalSliderWithSteppersMixin = h.Recorder(), h.Recorder(), h.Recorder()
end

function h.PointOf(block)
    return block and type(block.Point) == "table" and tostring(block.Point[1]) or "none"
end

-- Checks: a suite's name is printed before each id, so two suites may both have a #1
h.failed, h.passed, h.suite = 0, 0, ""
function h.BeginSuite(name) h.suite = name end

function h.Check(id, title, check)
    h.Fresh()
    local ok, passed, detail = pcall(check)
    if not ok then passed, detail = false, "error: " .. tostring(passed) end
    if passed then h.passed = h.passed + 1 else h.failed = h.failed + 1 end
    print(("%s  %s #%s %s%s"):format(passed and "PASS" or "FAIL", h.suite, id, title, detail and (": " .. detail) or ""))
end

-- A scenario records behaviour, as KAF's suites do: Observe() returns what the code does now, as a value that prints
-- (a string, a number, a boolean). It passes while that equals Recorded, the behaviour verified (here by running the
-- real code). Target is the behaviour wanted. A scenario whose Recorded differs from Target is an open defect: it passes
-- and is counted as open. The fix flips Recorded to Target in the same change, which is the reviewable diff.
h.open, h.gameOnly = 0, 0

function h.Scenario(id, title, scenario)
    h.Fresh()
    local ok, value = pcall(scenario.Observe)
    value = ok and tostring(value) or ("error: " .. tostring(value))
    local passed = value == scenario.Recorded
    local isOpen = scenario.Recorded ~= scenario.Target
    if passed then h.passed = h.passed + 1 else h.failed = h.failed + 1 end
    if passed and isOpen then h.open = h.open + 1 end
    print(("%s  %s #%s %s: %s%s"):format(passed and "PASS" or "FAIL", h.suite, id, title, value,
        (isOpen and ("  [open: target " .. tostring(scenario.Target) .. "]") or "")
        .. (passed and "" or ("  [recorded " .. tostring(scenario.Recorded) .. "]"))))
end

-- A defect only the game can show (it needs rows or a real frame): listed so it is not forgotten, proven by the
-- test addon in game
function h.GameOnly(id, title, why)
    h.gameOnly = h.gameOnly + 1
    print(("SKIP  %s #%s %s: game only, %s"):format(h.suite, id, title, why))
end

return h
