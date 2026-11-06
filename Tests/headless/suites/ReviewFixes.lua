---@diagnostic disable: undefined-global

-- The reproductions of the 2.0 code review's findings (docs/work/2026-11-05-review-fixes), moved here from that folder's
-- repro/repro.lua with their helpers in ../harness.lua. #3 was fixed in de2cb58; #8 is checked in game too (only the
-- client shows whether a greyed-out control fires its hover).

local h = ...
local Read, Run, Replace, Noop, NIL = h.Read, h.Run, h.Replace, h.Noop, h.NIL
local root, handled, libraryFiles = h.root, h.handled, h.libraryFiles
local LoadCopy, Option, Config, Window, StandInWindows = h.LoadCopy, h.Option, h.Config, h.Window, h.StandInWindows
local Recorder, Called, RecordFrames, PointOf, Check = h.Recorder, h.Called, h.RecordFrames, h.PointOf, h.Check
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
    -- The shared keys live in saved.Window since 2026-11-05-contract-and-errors
    local point = type(saved.Window) == "table" and saved.Window.Point
    return ok and point ~= nil, ok and (point and "A's table has Point" or "A's table lacks Point") or tostring(message)
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