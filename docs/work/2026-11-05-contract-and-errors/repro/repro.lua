-- The reproductions of 2026-11-05-contract-and-errors (../spec.md): the library's real files on Krowi_Util's real
-- LibStub, AceLocale and LibMan, the window's methods called on stand-ins for its frames, as the review fixes' repro does
-- (docs/work/2026-11-05-review-fixes/repro/repro.lua, whose helpers this copies). Each check prints PASS or FAIL; before
-- the fix every check FAILs. Exits 1 when a check fails.
--
-- From the repo root or a worktree's: <Krowi_ClaudeKit>\tools\lua51\lua.exe docs\work\2026-11-05-contract-and-errors\repro\repro.lua

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

local utilFiles = { "Libs/LibStub.lua", "Libs/AceLocale-3.0.lua", "LibMan.lua", "Krowi_Util.lua", "Constants.lua", "Strings.lua",
    "LocalizationHelper.lua" }
local libraryFiles = { "Krowi_Options.lua", "Localization/enUS.lua", "Localization/deDE.lua", "Localization/esES.lua",
    "Localization/esMX.lua", "Localization/frFR.lua", "Localization/itIT.lua", "Localization/koKR.lua", "Localization/ptBR.lua",
    "Localization/ruRU.lua", "Localization/zhCN.lua", "Localization/zhTW.lua", "Localization/Shared.lua", "Search.lua",
    "RowMixins.lua", "RowFrames.lua", "WindowMixin.lua", "WindowFrame.lua" }

local function Noop() end
local handled = {} -- what reached the game's error handler
local now = 1000 -- time()

-- Every global the files and the checks add goes again, so each check starts from a game with no copy loaded
local baseline = {}
for key in pairs(_G) do baseline[key] = true end

local function Fresh()
    for key in pairs(_G) do
        if not baseline[key] then _G[key] = nil end
    end
    handled, now = {}, 1000
    GetLocale = function() return "enUS" end
    geterrorhandler = function() return function(message) handled[#handled + 1] = message end end
    CallErrorHandler = function(...) return geterrorhandler()(...) end -- Blizzard_SharedXMLBase/ErrorUtil.lua
    tinsert, tremove = table.insert, table.remove
    time = function() return now end
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

local function LoadCopy()
    for _, file in ipairs(libraryFiles) do Run(Read(root .. file), file) end
    return KROWI_LIBMAN:GetLibrary("Krowi_Options_2")
end

-- An option with every method the window calls (RowMixins.lua's interface); extra fields replace them
local function Option(label, extra)
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

-- A tab's config with every field the library reads
local function Config(extra)
    local config = {
        TabName = "Test", Saved = {}, Groups = { { Name = "Group", Sections = { "first" } } },
        SectionName = function(id) return id end, IsNew = function() return false end, Landing = function() return "first" end,
        OnSectionShown = Noop, GetElements = function() return {} end, GetHelp = function() return nil end,
        ResetSection = Noop, ChangedCount = function() return 0 end,
    }
    for key, value in pairs(extra or {}) do config[key] = value end
    return config
end

-- The window's methods (lib.Mixins.Window) on a stand-in for its frames; the parts a check does not look at do nothing
local function Window(lib, fields)
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
local function StandInWindows(lib)
    local built = { Count = 0 }
    lib.Build.Window = function()
        built.Count = built.Count + 1
        built.Last = Window(lib, {
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
local function Recorder()
    return setmetatable({}, {
        __index = function(frame, key)
            if dataKeys[key] then return nil end
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

local function PointOf(block)
    return block and type(block.Point) == "table" and tostring(block.Point[1]) or "none"
end

-- [[ The contract (requirements 1-7) ]] --
Check("1-7", "the headers name the whole contract", function()
    local config = Read(root .. "Krowi_Options.lua"):match("^(.-)local tab = ") or ""
    local rows = Read(root .. "RowMixins.lua"):match("^(.-)local sub, lib") or ""
    local missing = {}
    for _, word in ipairs({ "ShowMeSecure", "CanShowMe", "ShowMeNote", '"overview"', "Window", "LastSection", "PLAYER_LOGIN",
        "secret", "Lightbox", "WindowName", "internal" }) do
        if not config:find(word, 1, true) then missing[#missing + 1] = "Krowi_Options.lua: " .. word end
    end
    for _, word in ipairs({ "TabList", "Cards", "Link", "Grid", "Sub", "SubHeading", "Note", "UPDATE_BINDINGS", "secret" }) do
        if not rows:find(word, 1, true) then missing[#missing + 1] = "RowMixins.lua: " .. word end
    end
    return #missing == 0, #missing == 0 and "every term named" or ("missing " .. table.concat(missing, ", "))
end)

-- [[ The shared window state (requirements 9-12) ]] --
Check("10", "the newest block wins at the window's first open, and every tab gets it", function()
    local lib = LoadCopy()
    local built = StandInWindows(lib)
    local older = { Window = { Point = { "TOPLEFT", "TOPLEFT", 10, -10 }, Changed = 100 } }
    local newer = { Window = { Point = { "CENTER", "CENTER", 0, 0 }, Changed = 200 } }
    local opening = lib.CreateWindow(Config({ TabName = "A", Saved = older }))
    lib.CreateWindow(Config({ TabName = "B", Saved = newer }))
    lib.GetFrame(opening)
    local placed = built.Point and tostring(built.Point[1]) or "nowhere"
    return placed == "CENTER" and PointOf(older.Window) == "CENTER" and older.Window.Changed == 200,
        ("placed %s; A's block %s at %s"):format(placed, PointOf(older.Window), tostring(older.Window and older.Window.Changed))
end)

Check("11", "a change writes the whole block, stamped, into every tab, each its own copy", function()
    local lib = LoadCopy()
    StandInWindows(lib)
    local a = { Window = { Point = { "CENTER", "CENTER", 0, 0 }, Changed = 200 } }
    local b = {}
    lib.GetFrame(lib.CreateWindow(Config({ TabName = "A", Saved = a })))
    lib.CreateWindow(Config({ TabName = "B", Saved = b }))
    now = 300
    lib.SetShared("PaneCollapsed", true)
    local function Line(saved)
        local block = saved.Window
        return block and ("%s/%s/%s"):format(PointOf(block), tostring(block.PaneCollapsed), tostring(block.Changed)) or "no block"
    end
    local same = Line(a) == "CENTER/true/300" and Line(b) == "CENTER/true/300"
    local separate = a.Window ~= nil and b.Window ~= nil and a.Window ~= b.Window
    return same and separate and a.PaneCollapsed == nil, ("A %s, B %s%s%s"):format(Line(a), Line(b),
        separate and "" or ", one table", a.PaneCollapsed == nil and "" or ", a top-level key written")
end)

Check("12", "a value of the wrong shape is ignored, and one window is built over two opens", function()
    local lib = LoadCopy()
    local built = StandInWindows(lib)
    local saved = { Size = {}, Point = "bad", Window = { Size = {}, Point = "bad", Changed = 5 } }
    local tab = lib.CreateWindow(Config({ Saved = saved }))
    local ok, message = pcall(lib.GetFrame, tab)
    pcall(lib.GetFrame, tab)
    return ok and built.Count == 1, ("%d window(s) built over two opens%s"):format(built.Count, ok and "" or "; " .. tostring(message))
end)

-- [[ Errors (requirements 13-17) ]] --
Check("13a", "one tab's OnCreated error leaves the other tabs' OnCreated and the tab strip running", function()
    local lib = LoadCopy()
    local built = StandInWindows(lib)
    local second = false
    local first = lib.CreateWindow(Config({ TabName = "A", OnCreated = function() error("A's own error") end }))
    lib.CreateWindow(Config({ TabName = "B", OnCreated = function() second = true end }))
    local ok, message = pcall(lib.GetFrame, first)
    local strip = (built.Strip or 0) > 0
    return ok and second and strip and #handled == 1, ("B's OnCreated %s, tab strip %s, %d error(s) to the handler%s"):format(
        second and "ran" or "skipped", strip and "drawn" or "not drawn", #handled, ok and "" or "; raised: " .. tostring(message))
end)

Check("13b", "a tab registered late whose OnCreated errors is still returned and registered once", function()
    local lib = LoadCopy()
    StandInWindows(lib)
    lib.GetFrame(lib.CreateWindow(Config({ TabName = "A" })))
    local ok, tab = pcall(lib.CreateWindow, Config({ TabName = "Late", OnCreated = function() error("Late's own error") end }))
    local count = 0
    for _, registered in ipairs(lib.Tabs) do
        if registered.Config.TabName == "Late" then count = count + 1 end
    end
    return ok and type(tab) == "table" and count == 1 and #handled == 1, ("%s, registered %d time(s), %d error(s) to the handler"):format(
        ok and "returned" or ("raised: " .. tostring(tab)), count, #handled)
end)

Check("13c", "an OnCreated that registers another tab calls that tab's OnCreated once", function()
    local lib = LoadCopy()
    StandInWindows(lib)
    local calls = 0
    local first = lib.CreateWindow(Config({ TabName = "A", OnCreated = function()
        lib.CreateWindow(Config({ TabName = "Zz", OnCreated = function() calls = calls + 1 end }))
    end }))
    lib.GetFrame(first)
    return calls == 1, ("called %d time(s)"):format(calls)
end)

Check("14", "a tab-list row without Show hides its check box", function()
    local lib = LoadCopy()
    RecordFrames()
    local row = lib.Build.TabRow(Recorder())
    local window = Window(lib)
    row:Init({ Kind = "TabRow", Item = { Position = 1 } }, window)
    local hidden = Called(row.ShowCheck, "SetShown", false) or Called(row.ShowCheck, "Hide", nil)
    return hidden, hidden and "hidden" or "left as it was"
end)

Check("15", "a row reused in the middle of a key capture never refreshes the option it showed before", function()
    local lib = LoadCopy()
    RecordFrames()
    local row = lib.Build.OptionRow(Recorder())
    local window = Window(lib, { InCombat = function() return false end })
    local oldAsked = 0
    local old = Option("Old", { Type = "key", Slots = {}, IsDisabled = function() oldAsked = oldAsked + 1 return false end })
    row.Option, row.Window, row.Capturing = old, window, 1
    local ok, message = pcall(row.Init, row, { Kind = "Option", Option = Option("New") }, window)
    return ok and oldAsked == 0, ("the old option asked %d time(s)%s"):format(oldAsked, ok and "" or "; " .. tostring(message))
end)

local function SectionWindow(lib, config)
    return Window(lib, {
        Saved = {}, Config = config, SectionId = "first",
        EndFill = function(window) window.Filled = true end,
        ShowSectionHelp = lib.Mixins.Window.ShowSectionHelp,
    })
end

local function OpensCleanly(lib, title, config)
    local window = SectionWindow(lib, config)
    local ok, message = pcall(window.ShowSection, window, "first")
    local clean = ok and window.Filled == true and #handled >= 1
    return clean, ("%s: %s, fill %s, %d error(s) to the handler"):format(title, ok and "opened" or ("raised: " .. tostring(message)),
        window.Filled and "ended" or "left open", #handled)
end

Check("16a", "a section whose GetElements errors opens empty and ends its fill", function()
    local lib = LoadCopy()
    return OpensCleanly(lib, "GetElements", Config({ GetElements = function() error("GetElements' own error") end }))
end)

Check("16b", "an option whose IsHidden errors leaves the section open", function()
    local lib = LoadCopy()
    local broken = Option("Broken", { IsHidden = function() error("IsHidden's own error") end })
    return OpensCleanly(lib, "IsHidden", Config({ GetElements = function() return { { Kind = "Option", Option = broken } } end }))
end)

Check("16c", "an option whose GetLabel errors leaves the section open", function()
    local lib = LoadCopy()
    local broken = Option("Broken", { GetLabel = function() error("GetLabel's own error") end })
    return OpensCleanly(lib, "GetLabel", Config({ GetElements = function() return { { Kind = "Option", Option = broken } } end }))
end)

Check("16d", "a section whose OnSectionShown or GetHelp errors still opens", function()
    local lib = LoadCopy()
    local shown, shownLine = OpensCleanly(lib, "OnSectionShown", Config({ OnSectionShown = function() error("OnSectionShown's own error") end }))
    handled = {}
    local help, helpLine = OpensCleanly(lib, "GetHelp", Config({ GetHelp = function() error("GetHelp's own error") end }))
    return shown and help, shownLine .. "; " .. helpLine
end)

Check("16e", "a change after which GetElements errors refreshes the rows instead of raising", function()
    local lib = LoadCopy()
    local refreshed = false
    local window = SectionWindow(lib, Config({ GetElements = function() error("GetElements' own error") end }))
    window.Refresh = function() refreshed = true end
    local ok, message = pcall(window.OnOptionChanged, window, Option("Changed"))
    return ok and refreshed and #handled >= 1, ("%s, rows %s, %d error(s) to the handler"):format(ok and "handled" or ("raised: " .. tostring(message)),
        refreshed and "refreshed" or "not refreshed", #handled)
end)

Check("16f", "a search leaves out a section that errors and still finds the others", function()
    local lib = LoadCopy()
    lib.CreateWindow(Config({ TabName = "A", Groups = { { Name = "Group", Sections = { "broken", "fine" } } }, GetElements = function(id)
        if id == "broken" then error("the broken section's own error") end
        return { { Kind = "Option", Option = Option("Findable") } }
    end }))
    local ok, result = pcall(lib.Search, "findable", true, nil, false)
    local found = ok and result[1] and #result[1].Sections or 0
    return ok and found == 1 and #handled >= 1, ("%s, %d section(s) found, %d error(s) to the handler"):format(
        ok and "searched" or ("raised: " .. tostring(result)), found, #handled)
end)

Check("17", "a standalone install with no KROWI_LIBMAN loads nothing and raises nothing", function()
    KROWI_LIBMAN, LibStub = nil, nil
    local errors = {}
    for _, file in ipairs(libraryFiles) do
        if not pcall(Run, Read(root .. file), file) then errors[#errors + 1] = file end
    end
    return #errors == 0, #errors == 0 and "every file silent" or ("errors in " .. table.concat(errors, ", "))
end)

print(failed == 0 and "every check passes" or ("%d check(s) fail"):format(failed))
if failed > 0 then os.exit(1) end
