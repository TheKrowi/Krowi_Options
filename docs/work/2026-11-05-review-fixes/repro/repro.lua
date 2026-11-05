-- The reproductions of the 2.0 code review's findings (../spec.md): the library's real files on Krowi_Util's real
-- LibStub, AceLocale and LibMan, the window's methods called on stand-ins for its frames. Each check prints PASS or FAIL;
-- before the fix every check but #3 (fixed in de2cb58) FAILs. #8 is checked in game too: only the client shows whether
-- a greyed-out control fires its hover.
--
-- From the repo root or a worktree's: <Krowi_ClaudeKit>\tools\lua51\lua.exe docs\work\2026-11-05-review-fixes\repro\repro.lua

---@diagnostic disable: undefined-global

local root = ((arg and arg[0]) or ""):gsub("\\", "/"):match("^(.-)docs/work/") or ""
-- Krowi_Util beside the library's main checkout, seen from it or from a worktree under its .claude/worktrees/
local UTIL
for _, up in ipairs({ "../", "../../../../" }) do
    local file = io.open(root .. up .. "Krowi_Util/Libs/LibStub.lua", "rb")
    if file then
        file:close()
        UTIL = root .. up .. "Krowi_Util/"
        break
    end
end
assert(UTIL, "Krowi_Util not found beside the library")

local function Read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return text
end

local function Run(source, chunkName)
    assert(loadstring(source, chunkName))()
end

-- A plain-text replacement that must match exactly once
local function Replace(text, old, new)
    local first, last = text:find(old, 1, true)
    assert(first and not text:find(old, last + 1, true), "not found once: " .. old)
    return text:sub(1, first - 1) .. new .. text:sub(last + 1)
end

local utilFiles = { "Libs/LibStub.lua", "Libs/AceLocale-3.0.lua", "LibMan.lua", "Krowi_Util.lua", "Constants.lua", "Strings.lua",
    "LocalizationHelper.lua" }
local libraryFiles = { "Krowi_Options.lua", "Localization/enUS.lua", "Localization/deDE.lua", "Localization/esES.lua",
    "Localization/esMX.lua", "Localization/frFR.lua", "Localization/itIT.lua", "Localization/koKR.lua", "Localization/ptBR.lua",
    "Localization/ruRU.lua", "Localization/zhCN.lua", "Localization/zhTW.lua", "Localization/Shared.lua", "Search.lua",
    "RowMixins.lua", "RowFrames.lua", "WindowMixin.lua", "WindowFrame.lua" }

local function Noop() end
local handled = {} -- what reached the game's error handler

-- Every global the files and the checks add goes again, so each check starts from a game with no copy loaded
local baseline = {}
for key in pairs(_G) do baseline[key] = true end

local function Fresh()
    for key in pairs(_G) do
        if not baseline[key] then _G[key] = nil end
    end
    handled = {}
    GetLocale = function() return "enUS" end
    geterrorhandler = function() return function(message) handled[#handled + 1] = message end end
    CallErrorHandler = function(...) return geterrorhandler()(...) end -- Blizzard_SharedXMLBase/ErrorUtil.lua
    tinsert, tremove = table.insert, table.remove
    GetBuildInfo = function() return "12.1.5", "1", "", 120105 end
    WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
    strsplittable = function(separator, text)
        local parts = {}
        for part in text:gmatch("[^" .. separator .. "]+") do parts[#parts + 1] = part end
        return parts
    end
    CreateDataProvider = function(list) return list end
    ScrollBoxConstants = { DiscardScrollPosition = 1, RetainScrollPosition = 2, AlignCenter = 3 }
    for _, file in ipairs(utilFiles) do Run(Read(UTIL .. file), file) end
end

-- A copy of the library as an addon embeds it. minors: { [file] = n } raises that file's minor from 0, as a newer copy
-- has it; edits: { [file] = function(source) return source end }
local function LoadCopy(minors, edits)
    minors, edits = minors or {}, edits or {}
    for _, file in ipairs(libraryFiles) do
        local source = Read(root .. file)
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

local NIL = {} -- a Config field left out

-- An option with the methods the window calls (RowMixins.lua's interface); extra fields replace them
local function Option(label, extra)
    local option = { Label = label, Type = "toggle", Indent = 0 }
    function option:GetLabel() return self.Label end
    function option:IsHidden() return false end
    function option:IsDisabled() return false end
    function option:GetDescription() return "" end
    for key, value in pairs(extra or {}) do option[key] = value end
    return option
end

-- A tab's config with every field the library reads
local function Config(extra)
    local config = {
        TabName = "Test", Saved = {}, Groups = { { Name = "Group", Sections = { "first" } } },
        SectionName = function(id) return id end, IsNew = function() return false end, Landing = function() return "first" end,
        OnSectionShown = Noop, GetElements = function() return {} end, GetHelp = function() return nil end,
        ResetSection = Noop, ChangedCount = function() return 0 end,
    }
    for key, value in pairs(extra or {}) do
        if value == NIL then config[key] = nil else config[key] = value end
    end
    return config
end

-- The window's methods (lib.Mixins.Window) on a stand-in for its frames; the parts a check does not look at do nothing
local function Window(lib, fields)
    local window = {
        Strings = lib.GetStrings(),
        SearchBox = { GetText = function() return "" end, SetText = Noop },
        PageTitle = { SetText = Noop }, DefaultsButton = { SetShown = Noop }, PageScrollBox = { SetDataProvider = Noop },
        IsShown = function() return true end,
    }
    for _, method in ipairs({ "RefreshNav", "RefreshFooter", "ShowSectionHelp", "EndFill", "UpdateShowMe", "ScrollToOption", "EndKeyCaptures" }) do
        window[method] = Noop
    end
    for key, value in pairs(fields or {}) do window[key] = value end
    return setmetatable(window, { __index = lib.Mixins.Window })
end

-- A frame that takes every call and logs it: a field read is a child frame made on first read, a call is a method call
local log, methodOf = {}, setmetatable({}, { __mode = "k" })
local function Recorder()
    return setmetatable({}, {
        __index = function(frame, key)
            local child = Recorder()
            methodOf[child] = key
            rawset(frame, key, child)
            return child
        end,
        __call = function(method, frame, ...)
            log[#log + 1] = { Frame = frame, Method = methodOf[method], Args = { ... } }
            return Recorder()
        end,
    })
end

local function Called(frame, method, value)
    for _, call in ipairs(log) do
        if call.Frame == frame and call.Method == method and call.Args[1] == value then return true end
    end
    return false
end

-- Frames for the builders: CreateFrame and Blizzard's mixins as recorders
local function RecordFrames()
    log = {}
    CreateFrame = function() return Recorder() end
    Mixin = function(object, ...)
        for i = 1, select("#", ...) do
            for key, value in pairs((select(i, ...))) do object[key] = value end
        end
        return object
    end
    WowStyle2IconButtonMixin, DropdownWithSteppersMixin, MinimalSliderWithSteppersMixin = Recorder(), Recorder(), Recorder()
end

local failed = 0
local function Check(id, title, check)
    Fresh()
    local ok, passed, detail = pcall(check)
    if not ok then passed, detail = false, "error: " .. tostring(passed) end
    if not passed then failed = failed + 1 end
    print(("%s  #%s %s%s"):format(passed and "PASS" or "FAIL", id, title, detail and (": " .. detail) or ""))
end

Check("1", "the search ends on an option that is its own parent", function()
    local lib = LoadCopy()
    local loop = Option("Loop")
    function loop:GetParent() return self end
    lib.CreateWindow(Config({ GetElements = function() return { { Kind = "Option", Option = loop } } end }))
    local steps = 0
    debug.sethook(function()
        steps = steps + 1
        if steps > 2000 then
            debug.sethook()
            error("no end after 2,000,000 instructions", 0)
        end
    end, "", 1000)
    local ok, result = pcall(lib.Search, "loop", true, nil, false)
    debug.sethook()
    if not ok then return false, result end
    local rows = result[1] and #result[1].Sections[1].Rows or 0
    return rows == 1, ("%d row(s) found"):format(rows)
end)

Check("2", "a tab an older copy made has a newer copy's tab methods", function()
    local tab = LoadCopy().CreateWindow(Config())
    LoadCopy({ ["Krowi_Options.lua"] = 1 }, { ["Krowi_Options.lua"] = function(source)
        return Replace(source, "function tab:GetFrame()", "function tab:Probe() return true end\n\nfunction tab:GetFrame()")
    end })
    return tab.Probe ~= nil, tab.Probe and "the older copy's tab has the newer method" or "the older copy's tab lacks the newer method"
end)

Check("3", "the window's builders use a newer copy's RowFrames.lua (fixed in de2cb58)", function()
    LoadCopy()
    local lib = LoadCopy({ ["RowFrames.lua"] = 1 }, { ["RowFrames.lua"] = function(source)
        return source .. "\nlocal finish = build.Finish\nbuild.Finish = function(...) NEWER_FINISH = true return finish(...) end"
    end })
    RecordFrames()
    lib.Build.HelpText(Recorder())
    return NEWER_FINISH == true, NEWER_FINISH and "the newer Finish ran" or "the older Finish ran"
end)

Check("4a", "a tab whose Saved gives no table: no window is built, the error names the tab", function()
    local lib = LoadCopy()
    local built = 0
    lib.Build.Window = function()
        built = built + 1
        return setmetatable({ RefreshTabs = Noop }, { __index = lib.Mixins.Window })
    end
    local tab = lib.CreateWindow(Config({ TabName = "Broken", Saved = function() return nil end }))
    local _, message = pcall(lib.GetFrame, tab)
    pcall(lib.GetFrame, tab)
    local named = tostring(message):find("Broken", 1, true) ~= nil
    return built == 0 and named, ("%d window(s) built over two opens; %s"):format(built, tostring(message))
end)

Check("4b", "a tab without a saved table leaves the other tabs' shared state saved", function()
    local lib = LoadCopy()
    local saved = {}
    lib.CreateWindow(Config({ TabName = "A", Saved = saved }))
    lib.CreateWindow(Config({ TabName = "B", Saved = function() return nil end }))
    local ok, message = pcall(lib.SetShared, "Point", { "CENTER" })
    return ok and saved.Point ~= nil, ok and (saved.Point and "A's table has Point" or "A's table lacks Point") or tostring(message)
end)

Check("4c", "a config without GetElements is refused at CreateWindow, naming the field", function()
    local lib = LoadCopy()
    local ok, message = pcall(lib.CreateWindow, Config({ GetElements = NIL }))
    local named = not ok and tostring(message):find("GetElements", 1, true) ~= nil
    return named and #lib.Tabs == 0, ok and "accepted" or tostring(message)
end)

Check("5a", "a section whose GetElements gives nil shows an empty page", function()
    local lib = LoadCopy()
    local saved = { LastSection = "first" }
    local window = Window(lib, { Saved = saved, Config = Config({ Saved = saved, GetElements = function(id)
        if id == "first" then return {} end
    end }) })
    local ok, message = pcall(window.ShowSection, window, "gone")
    return ok and window.Elements ~= nil and #window.Elements == 0, ok and "an empty page" or tostring(message)
end)

Check("5b", "a section whose GetElements errors is not saved as the last section", function()
    local lib = LoadCopy()
    local saved = { LastSection = "first" }
    local window = Window(lib, { Saved = saved, Config = Config({ Saved = saved, GetElements = function(id)
        if id == "broken" then error("the addon's own error") end
        return {}
    end }) })
    pcall(window.ShowSection, window, "broken")
    return saved.LastSection ~= "broken", "LastSection = " .. tostring(saved.LastSection)
end)

Check("6a", "the option interface in RowMixins.lua's header names IsHidden", function()
    local header = Read(root .. "RowMixins.lua"):match("^(.-)local sub, lib") or ""
    local named = header:find("IsHidden", 1, true) ~= nil
    return named, named and "named" or "not named"
end)

Check("6b", "a With without Id draws", function()
    local lib = LoadCopy()
    local window = Window(lib, { SectionId = "first", Config = Config({ GetElements = function()
        return { { Kind = "Option", Option = Option("Toggle"), With = Option("Button", { Type = "execute" }) } }
    end }) })
    local ok, message = pcall(window.FillPage, window, ScrollBoxConstants.DiscardScrollPosition)
    return ok, ok and "drawn" or tostring(message)
end)

Check("7a", "one row's error leaves the other rows and the footer refreshed, and reaches the error handler", function()
    local lib = LoadCopy()
    local secondRow, footer = false, false
    local frames = {
        { Row = { Refresh = function() error("the first row's error") end } },
        { Row = { Refresh = function() secondRow = true end } },
    }
    local window = Window(lib, {
        PageScrollBox = { ForEachFrame = function(_, each) for _, frame in ipairs(frames) do each(frame) end end },
        RefreshFooter = function() footer = true end,
    })
    local ok, message = pcall(window.Refresh, window)
    return secondRow and footer and #handled == 1, ("second row %s, footer %s, %d error(s) to the handler%s"):format(
        secondRow and "refreshed" or "not refreshed", footer and "refreshed" or "not refreshed", #handled, ok and "" or "; " .. tostring(message))
end)

Check("7b", "the combat flag clears when the refresh errors", function()
    local lib = LoadCopy()
    local window = Window(lib, { Refresh = function() error("a refresh error") end })
    pcall(window.OnEvent, window, "PLAYER_REGEN_DISABLED")
    return window.CombatStarting == nil, "CombatStarting = " .. tostring(window.CombatStarting)
end)

Check("8", "a greyed-out control still passes the mouse to its row", function()
    local lib = LoadCopy()
    RecordFrames()
    local option, grid, tab = lib.Build.OptionRow(Recorder()), lib.Build.GridRow(Recorder()), lib.Build.TabRow(Recorder())
    local controls = {
        { "Toggle", option.Toggle }, { "Range.Back", option.Range.Back }, { "Range.Forward", option.Range.Forward },
        { "Select.Dropdown", option.Select.Dropdown }, { "Select.DecrementButton", option.Select.DecrementButton },
        { "Select.IncrementButton", option.Select.IncrementButton }, { "Execute", option.Execute }, { "Key1", option.Key1 },
        { "Key2", option.Key2 }, { "grid cell", grid.Cells[1] }, { "tab ShowCheck", tab.ShowCheck }, { "tab Up", tab.Up },
        { "tab Down", tab.Down },
    }
    local missing = {}
    for _, control in ipairs(controls) do
        if not Called(control[2], "SetMotionScriptsWhileDisabled", true) then missing[#missing + 1] = control[1] end
    end
    return #missing == 0, #missing == 0 and "every control" or ("not on " .. table.concat(missing, ", "))
end)

Check("9", "the window's global name is not Krowi_Options 1's, and lib.WindowName says it", function()
    local lib = LoadCopy()
    RecordFrames()
    local named
    CreateFrame = function(_, name, _, template)
        if template == "SettingsFrameTemplate" then named = name end
        return Recorder()
    end
    lib.Build.Finish = function(frame) return frame end -- the window's OnLoad needs a real frame
    lib.Build.Window()
    return named ~= nil and named ~= "Krowi_OptionsWindow" and named == lib.WindowName,
        ("named %s, lib.WindowName %s"):format(tostring(named), tostring(lib.WindowName))
end)

print(failed == 0 and "every check passes" or ("%d check(s) fail"):format(failed))
