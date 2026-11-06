---@diagnostic disable: undefined-global

-- The reproductions of 2026-11-05-contract-and-errors, moved here from that folder's repro/repro.lua with their helpers
-- in ../harness.lua: the contract written down, an addon's errors contained, the shared window state in sync.

local h = ...
local Read, Run, Replace, Noop, NIL = h.Read, h.Run, h.Replace, h.Noop, h.NIL
local root, handled, libraryFiles = h.root, h.handled, h.libraryFiles
local LoadCopy, Option, Config, Window, StandInWindows = h.LoadCopy, h.Option, h.Config, h.Window, h.StandInWindows
local Recorder, Called, RecordFrames, PointOf, Check = h.Recorder, h.Called, h.RecordFrames, h.PointOf, h.Check
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
    h.now = 300
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
    for key in pairs(handled) do handled[key] = nil end
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

-- [[ From the code review and the taint review of the fix (2026-11-05): the same requirements, further call sites ]] --
Check("12b", "a saved anchor that is no anchor point is ignored, and every tab's OnCreated still runs", function()
    local lib = LoadCopy()
    local built = StandInWindows(lib)
    local created = false
    local tab = lib.CreateWindow(Config({ Saved = { Window = { Point = { "FOO", "BAR", 1, 2 }, Changed = 5 } },
        OnCreated = function() created = true end }))
    local ok, message = pcall(lib.GetFrame, tab)
    local placed = built.Point and tostring(built.Point[1]) or "nowhere"
    return ok and placed == "nowhere" and created, ("placed %s, OnCreated %s%s"):format(placed, created and "ran" or "skipped",
        ok and "" or "; raised: " .. tostring(message))
end)

Check("13d", "another tab whose Saved errors leaves the window, its opening and its changes working", function()
    local lib = LoadCopy()
    StandInWindows(lib)
    local good = {}
    local opening = lib.CreateWindow(Config({ TabName = "A", Saved = good }))
    lib.CreateWindow(Config({ TabName = "B", Saved = function() error("B's own Saved error") end }))
    local opened, message = pcall(lib.GetFrame, opening)
    local changed, changeMessage = pcall(lib.SetShared, "PaneCollapsed", true)
    local written = type(good.Window) == "table" and good.Window.PaneCollapsed == true
    return opened and changed and written and #handled >= 1, ("open %s, change %s, A's block %s, %d error(s) to the handler"):format(
        opened and "fine" or ("raised: " .. tostring(message)), changed and "fine" or ("raised: " .. tostring(changeMessage)),
        written and "written" or "not written", #handled)
end)

Check("13e", "a tab registered late whose Saved errors is still returned, with its OnCreated run", function()
    local lib = LoadCopy()
    StandInWindows(lib)
    lib.GetFrame(lib.CreateWindow(Config({ TabName = "A" })))
    local created = false
    local ok, tab = pcall(lib.CreateWindow, Config({ TabName = "Late", Saved = function() error("Late's own Saved error") end,
        OnCreated = function() created = true end }))
    return ok and type(tab) == "table" and created, ("%s, OnCreated %s"):format(ok and "returned" or ("raised: " .. tostring(tab)),
        created and "ran" or "skipped")
end)

-- The page's header as the window draws it, on stand-ins that measure what they hold
local function Footer()
    local text = { ClearAllPoints = Noop, SetPoint = Noop, SetFontObject = Noop, SetText = Noop, SetShown = Noop }
    local function Plain() return { SetShown = Noop, SetEnabled = Noop, SetText = Noop } end
    return {
        CancelButton = Plain(), PageTitle = { SetShown = Noop, SetText = Noop }, ChangedText = text,
        DefaultsButton = { SetText = Noop, SetEnabled = Noop, SetShown = Noop, SetWidth = Noop,
            GetFontString = function() return { GetStringWidth = function() return 50 end } end },
        ReloadBackground = Plain(), ReloadText = Plain(), ReloadButton = Plain(),
        ConfirmingHere = function() return nil end, InCombat = function() return false end,
        NavScrollBox = { SetDataProvider = Noop },
    }
end

Check("16g", "a section opens and ends its fill when SectionName, IsNew or ChangedCount errors", function()
    local lib = LoadCopy()
    local lines, all = {}, true
    for _, case in ipairs({
        { "SectionName", { SectionName = function() error("SectionName's own error") end } },
        { "IsNew", { IsNew = function() error("IsNew's own error") end } },
        { "ChangedCount", { ChangedCount = function() error("ChangedCount's own error") end } },
    }) do
        for key in pairs(handled) do handled[key] = nil end
        local fields = Footer()
        fields.RefreshNav, fields.RefreshFooter = lib.Mixins.Window.RefreshNav, lib.Mixins.Window.RefreshFooter
        fields.Saved, fields.Config, fields.SectionId = {}, Config(case[2]), "first"
        fields.EndFill = function(window) window.Filled = true end
        fields.ShowSectionHelp = lib.Mixins.Window.ShowSectionHelp
        local window = Window(lib, fields)
        local ok, message = pcall(window.ShowSection, window, "first")
        local clean = ok and window.Filled == true
        all = all and clean
        lines[#lines + 1] = ("%s: %s"):format(case[1], ok and (window.Filled and "opened" or "fill left open") or ("raised: " .. tostring(message)))
    end
    return all, table.concat(lines, "; ")
end)

Check("16h", "a tab whose Landing errors opens on the overview", function()
    local lib = LoadCopy()
    local shown
    local tab = lib.CreateWindow(Config({ Landing = function() error("Landing's own error") end }))
    local window = Window(lib, { Show = Noop, ReleaseShowMe = Noop, ApplyStrings = Noop,
        ShowSection = function(_, id) shown = id end })
    local ok, message = pcall(window.ShowTab, window, tab)
    return ok and shown == "overview", ok and ("opened on " .. tostring(shown)) or ("raised: " .. tostring(message))
end)

-- [[ From the code review of the review fixes (2026-11-05) ]] --
-- The Show me part of the help pane, on stand-ins that record what is set
local function ShowMeWindow(lib, help)
    local note = { Text = nil }
    return Window(lib, {
        Help = help, PaneCollapsed = false, InCombat = function() return false end,
        ShowMeButton = { SetShown = Noop, SetEnabled = Noop },
        ShowMeNote = { ClearAllPoints = Noop, SetPoint = Noop, SetShown = Noop, SetText = function(_, text) note.Text = text end },
        HelpBackground = {}, UpdateShowMe = lib.Mixins.Window.UpdateShowMe, ReleaseShowMe = lib.Mixins.Window.ReleaseShowMe,
    }), note
end

Check("16i", "a ShowMeNote function that errors leaves no note and no error of the window's own", function()
    local lib = LoadCopy()
    local window, note = ShowMeWindow(lib, { ShowMeSecure = function() return false end, ShowMeNote = function() error("ShowMeNote's own error") end })
    local ok, message = pcall(window.UpdateShowMe, window)
    return ok and note.Text == "" and #handled == 1, ("%s, note %s, %d error(s) to the handler"):format(ok and "drawn" or ("raised: " .. tostring(message)),
        tostring(note.Text), #handled)
end)

Check("16j", "a ShowMeSecure that errors is still let go when its section's help goes", function()
    local lib = LoadCopy()
    local released = false
    local help = { ShowMeSecure = function(button) if button == nil then released = true return end error("ShowMeSecure's own error") end }
    local window = ShowMeWindow(lib, help)
    window:UpdateShowMe()
    window.Help = nil
    local ok, message = pcall(window.UpdateShowMe, window)
    return ok and released, ok and (released and "let go" or "left laid") or ("raised: " .. tostring(message))
end)

Check("13f", "another tab whose Saved errors is reported once, not on every change", function()
    local lib = LoadCopy()
    StandInWindows(lib)
    local opening = lib.CreateWindow(Config({ TabName = "A" }))
    lib.CreateWindow(Config({ TabName = "B", Saved = function() error("B's own Saved error") end }))
    lib.GetFrame(opening)
    for i = 1, 3 do lib.SetShared("PaneCollapsed", i % 2 == 0) end
    return #handled == 1, ("%d error(s) to the handler over the open and three changes"):format(#handled)
end)

Check("16k", "a ResetSection that errors shows the reload bar, since a setting it reset may need one", function()
    local lib = LoadCopy()
    local window = SectionWindow(lib, Config({ ResetSection = function() error("ResetSection's own error") end }))
    window.ReloadSection = Noop
    local ok, message = pcall(window.ResetSection, window, "first")
    return ok and window.ReloadPending == true, ok and ("ReloadPending = " .. tostring(window.ReloadPending)) or ("raised: " .. tostring(message))
end)