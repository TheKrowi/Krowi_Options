--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The defects left after 2.0 (docs/work/2026-11-05-review-fixes/backlog.md and "Backlog for 2.1" in
-- docs/work/2026-11-05-contract-and-errors/plan.md) as scenarios on the library's real code: Recorded is what the code
-- does now, verified by running it, Target what it should do. Phase 3 of docs/work/2026-11-06-finish-2-0 flips each
-- from Recorded to Target with its fix, by id; phase 4 does the same for B16.

local h = ...
local Noop, NIL, handled = h.Noop, h.NIL, h.handled
local LoadCopy, Option, Config, Window = h.LoadCopy, h.Option, h.Config, h.Window
local Recorder, RecordFrames, CallsTo, ScriptOf = h.Recorder, h.RecordFrames, h.CallsTo, h.ScriptOf
local Scenario = h.Scenario
local Internal = h.Internal -- the library's internals, lib.Internal

-- [[ Stand-ins ]] --
-- An option row as RowFrames.lua builds it, on recorders; its name measures as a real font string does
local function OptionRow(lib)
    RecordFrames()
    CreateMinimalSliderFormatter = function() return Noop end
    local row = Internal(lib).Build.OptionRow(Recorder())
    row.Label.GetStringWidth = function() return 100 end
    row.Label.GetWidth = function() return 200 end
    return row
end

-- The window a row hangs in, out of combat
local function RowWindow(lib, fields)
    local base = { InCombat = function() return false end }
    for key, value in pairs(fields or {}) do base[key] = value end
    return Window(lib, base)
end

-- A region that keeps the last text it was given (rawget(region, "Shown")); every other call does nothing
local function Region()
    return setmetatable({}, { __index = function(_, key)
        if key == "SetText" then return function(region, text) rawset(region, "Shown", text) end end
        return Noop
    end })
end

-- The page's list as the game's draws it: a new data provider hangs a row of the element's kind (the real mixin, on
-- regions that keep their text) on a frame per element and initialises it; ForEachFrame walks those frames
local function DrawingPage(lib, window)
    local page = { Frames = {}, IsMouseOver = function() return false end }
    function page:SetDataProvider(list)
        self.Frames = {}
        for i, element in ipairs(list) do
            local row
            if element.Kind == "Link" then
                row = setmetatable({ Text = Region(), Detail = Region() }, { __index = Internal(lib).Mixins.LinkRow })
            elseif element.Kind == "TabRow" then
                row = setmetatable({ Position = Region(), Label = Region(), Source = Region(), Up = Region(), Down = Region(),
                    ShowCheck = Region() }, { __index = Internal(lib).Mixins.TabRow })
            end
            if row then row:Init(element, window) end
            self.Frames[i] = { Row = row }
        end
    end
    function page:ForEachFrame(each)
        for _, frame in ipairs(self.Frames) do each(frame) end
    end
    return page
end

-- The page's header with the real RefreshFooter; shown[name] keeps what each button was last shown as
local function Footer(lib, shown)
    local function Button(name)
        return { SetShown = function(_, value) shown[name] = value and true or false end, SetText = Noop,
            SetEnabled = function(_, value) shown[name .. "Enabled"] = value and true or false end, SetWidth = Noop,
            GetFontString = function() return { GetStringWidth = function() return 50 end } end }
    end
    return {
        DefaultsButton = Button("Defaults"), CancelButton = Button("Cancel"), PageTitle = { SetShown = Noop, SetText = Noop },
        ChangedText = { ClearAllPoints = Noop, SetPoint = Noop, SetFontObject = Noop, SetText = Noop },
        ReloadBackground = Button("ReloadBackground"), ReloadText = Button("ReloadText"), ReloadButton = Button("Reload"),
        InCombat = function() return false end, RefreshFooter = Internal(lib).Mixins.Window.RefreshFooter,
    }
end

-- The window with its real OnLoad run on recorders, so the search box's hooks are the library's own. The box keeps its
-- text and, as the game's does, runs OnTextChanged without user input when SetText changes it; Type is the player typing.
local function LoadedWindow(lib, fields)
    RecordFrames()
    C_Texture = { GetAtlasInfo = function() return nil end }
    CreateScrollBoxListLinearView = function() return Recorder() end
    ScrollUtil, ManagedScrollBarVisibilityBehaviorMixin = Recorder(), Recorder()
    PlaySound, SOUNDKIT = Noop, {}
    local hooks, text = {}, ""
    local box = {
        HookScript = function(_, script, func) hooks[script] = func end,
        GetText = function() return text end,
        SetText = function(self, new)
            local changed = new ~= text
            text = new
            if changed and hooks.OnTextChanged then hooks.OnTextChanged(self, false) end
        end,
        Type = function(self, new)
            text = new
            hooks.OnTextChanged(self, true)
        end,
    }
    local base = { SearchBox = box, RegisterForDrag = Noop, UnregisterEvent = Noop, CreateFontString = function() return Recorder() end }
    for _, child in ipairs({ "ClosePanelButton", "CloseButton", "NineSlice", "NavScrollBox", "NavScrollBar", "PageScrollBar",
        "HelpScrollBox", "HelpScrollBar", "Lightbox", "SearchAll", "SearchBroad", "CollapseButton", "ExpandButton", "ShowMeButton",
        "DefaultsButton", "CancelButton", "ReloadButton", "ResizeButton" }) do
        base[child] = Recorder()
    end
    for key, value in pairs(fields or {}) do base[key] = value end
    local window = Window(lib, base)
    window:OnLoad()
    return window, box, hooks
end

-- [[ B1: the undo arrow and a paired control that needs a reload ]] --
Scenario("B1", "the undo arrow resets the paired control but its reload does not light the reload bar", {
    Observe = function()
        local lib = LoadCopy()
        local row = OptionRow(lib)
        local withReset = false
        local toggle = Option("Show the bar", { Reset = Noop })
        local scale = Option("Scale", { Type = "range", GetRange = function() return 0, 10, 1 end, Get = function() return 5 end,
            GetNeedsReload = function() return true end, Reset = function() withReset = true end })
        local window = RowWindow(lib) -- no section: the change refreshes the rows
        row:Init({ Kind = "Option", Option = toggle, With = scale }, window)
        ScriptOf(row.Reset, "OnClick")()
        return ("Scale reset %s, reload bar %s"):format(withReset and "yes" or "no", window.ReloadPending and "lit" or "not lit")
    end,
    Recorded = "Scale reset yes, reload bar not lit",
    Target = "Scale reset yes, reload bar lit",
})

-- [[ B2: a question asked on the Overview ]] --
Scenario("B2", "a question asked on the Overview hides its Yes (the Defaults button)", {
    Observe = function()
        local lib = LoadCopy()
        local shown = {}
        local fields = Footer(lib, shown)
        fields.Saved, fields.Config = {}, Config()
        local window = Window(lib, fields)
        window:ShowSection("overview")
        window:AskConfirm("Delete the profile?", Noop) -- a select on the Overview with Confirm asks this
        return ("Yes %s, No %s"):format(shown.Defaults and "shown" or "hidden", shown.Cancel and "shown" or "hidden")
    end,
    Recorded = "Yes hidden, No shown",
    Target = "Yes shown, No shown",
})

-- [[ B3: a slider without a step, and one whose ends are the same ]] --
-- MinimalSliderWithSteppersMixin:Init (Blizzard_SharedXML/Shared/Slider/MinimalSlider.lua) sets the value step to
-- (max - min) / steps
local function SliderStep(min, max, step)
    local lib = LoadCopy()
    local row = OptionRow(lib)
    local option = Option("Scale", { Type = "range", GetRange = function() return min, max, step end, Get = function() return min end })
    row:Init({ Kind = "Option", Option = option }, RowWindow(lib))
    local init = CallsTo(row.Range, "Init")[1]
    if not init then return nil end
    return (max - min) / init[4]
end

Scenario("B3a", "a slider from 0 to 1 without a step reaches only its two ends", {
    Observe = function()
        local size = SliderStep(0, 1, nil)
        if not size then return "no Init call" end
        return size > 0 and size <= 0.5 and "reaches values between its ends" or ("only its ends (step " .. size .. ")")
    end,
    Recorded = "only its ends (step 1)",
    Target = "reaches values between its ends",
})

Scenario("B3b", "a slider whose min equals its max divides by zero", {
    Observe = function()
        local size = SliderStep(5, 5, 1)
        if not size then return "no Init call" end
        return size == size and size ~= math.huge and size ~= -math.huge and "a finite step" or "0 steps: its step is 0/0"
    end,
    Recorded = "0 steps: its step is 0/0",
    Target = "a finite step",
})

-- [[ B4: a change that keeps the page's signature keeps the old element data ]] --
Scenario("B4a", "after a change a link keeps its old Detail when the page's rows stay the same", {
    Observe = function()
        local lib = LoadCopy()
        local detail = "1 profile"
        local window = Window(lib, { Saved = {}, SectionId = "first", Config = Config({ GetElements = function()
            return { { Kind = "Link", Text = "Profiles", Detail = detail } }
        end }) })
        window.PageScrollBox = DrawingPage(lib, window)
        window:FillPage(ScrollBoxConstants.DiscardScrollPosition)
        detail = "2 profiles"
        window:OnOptionChanged(Option("Changed"))
        return "the link shows " .. tostring(rawget(window.PageScrollBox.Frames[1].Row.Detail, "Shown"))
    end,
    Recorded = "the link shows 1 profile",
    Target = "the link shows 2 profiles",
})

Scenario("B4b", "after a change a tab row keeps its old Position when the page's rows stay the same", {
    Observe = function()
        local lib = LoadCopy()
        local position = 1
        local show = Option("Achievements", { Id = "tab" })
        local window = Window(lib, { Saved = {}, SectionId = "first", Config = Config({ GetElements = function()
            return { { Kind = "TabList", Items = { { Position = position, Show = show } } } }
        end }) })
        window.PageScrollBox = DrawingPage(lib, window)
        window:FillPage(ScrollBoxConstants.DiscardScrollPosition)
        position = 2
        window:OnOptionChanged(show)
        return "the tab row shows position " .. tostring(rawget(window.PageScrollBox.Frames[1].Row.Position, "Shown"))
    end,
    Recorded = "the tab row shows position 1",
    Target = "the tab row shows position 2",
})

-- [[ B5: With on an option that is not a toggle ]] --
Scenario("B5a", "a range option with an execute With: its own slider sets the With", {
    Observe = function()
        local lib = LoadCopy()
        local row = OptionRow(lib)
        local set = {}
        local volume = Option("Volume", { Type = "range", GetRange = function() return 0, 10, 1 end, Get = function() return 5 end,
            Set = function() set[#set + 1] = "Volume" end })
        local test = Option("Test", { Type = "execute", GetButtonText = function() return "Test" end,
            Set = function() set[#set + 1] = "Test" end })
        row:Init({ Kind = "Option", Option = volume, With = test }, RowWindow(lib, { OnOptionChanged = Noop }))
        CallsTo(row.Range, "RegisterCallback")[1][2](nil, 7) -- the slider moved to 7
        return "the slider sets " .. table.concat(set, ", ")
    end,
    Recorded = "the slider sets Test",
    Target = "the slider sets Volume",
})

Scenario("B5b", "an execute option with a range With: its own button sets the With", {
    Observe = function()
        local lib = LoadCopy()
        local row = OptionRow(lib)
        local set = {}
        local run = Option("Run", { Type = "execute", GetButtonText = function() return "Run" end, Set = function() set[#set + 1] = "Run" end })
        local threshold = Option("Threshold", { Type = "range", GetRange = function() return 0, 10, 1 end, Get = function() return 5 end,
            Set = function() set[#set + 1] = "Threshold" end })
        row:Init({ Kind = "Option", Option = run, With = threshold }, RowWindow(lib, { OnOptionChanged = Noop }))
        ScriptOf(row.Execute, "OnClick")()
        return "the button sets " .. table.concat(set, ", ")
    end,
    Recorded = "the button sets Threshold",
    Target = "the button sets Run",
})

-- [[ B6: closing the window during a search ]] --
-- Which OnHide the game runs first, the window's or its search box's, does not change the outcome: both orders are run
Scenario("B6", "closing the window during a search shows the section again on the hidden window", {
    Observe = function()
        local lib = LoadCopy()
        local lines = {}
        for _, order in ipairs({ "window first", "box first" }) do
            local shown, read, visible = 0, 0, true
            local window, box, hooks = LoadedWindow(lib, { Saved = {}, SectionId = "first", IsShown = function() return visible end,
                Config = Config({ OnSectionShown = function() shown = shown + 1 end, GetElements = function() read = read + 1 return {} end }) })
            box:Type("find")
            shown, read, visible = 0, 0, false
            if order == "window first" then
                window:OnHide()
                hooks.OnHide(box)
            else
                hooks.OnHide(box)
                window:OnHide()
            end
            lines[#lines + 1] = ("%s: OnSectionShown %d, GetElements %d"):format(order, shown, read)
        end
        return table.concat(lines, "; ")
    end,
    Recorded = "window first: OnSectionShown 1, GetElements 1; box first: OnSectionShown 1, GetElements 1",
    Target = "window first: OnSectionShown 0, GetElements 0; box first: OnSectionShown 0, GetElements 0",
})

-- [[ B7: Retail's named colour codes in the search ]] --
Scenario("B7", "the search finds the name inside a named colour code (|cnHIGHLIGHT_FONT_COLOR:...|r)", {
    Observe = function()
        local lib = LoadCopy()
        lib.CreateWindow(Config({ GetElements = function()
            return { { Kind = "Option", Option = Option("|cnHIGHLIGHT_FONT_COLOR:Bright|r") } }
        end }))
        local function Found(text)
            local result = Internal(lib).Search(text, true, nil, false)
            return result[1] and #result[1].Sections[1].Rows or 0
        end
        return ("highlight finds %d row(s), bright %d"):format(Found("highlight"), Found("bright"))
    end,
    Recorded = "highlight finds 1 row(s), bright 1",
    Target = "highlight finds 0 row(s), bright 1",
})

-- [[ B8: what a refresh allocates per row ]] --
-- Counted with the collector stopped, on rows whose Refresh allocates nothing: what is left is the window's own
Scenario("B8", "the window's refresh allocates per row", {
    Observe = function()
        local lib = LoadCopy()
        local frames = {}
        local window = Window(lib, { PageScrollBox = { ForEachFrame = function(_, each)
            for i = 1, #frames do each(frames[i]) end
        end } })
        local function Bytes(rows, refreshes)
            for i = 1, rows do frames[i] = { Row = { Refresh = Noop } } end
            for i = #frames, rows + 1, -1 do frames[i] = nil end
            collectgarbage("collect")
            collectgarbage("stop")
            local before = collectgarbage("count")
            for _ = 1, refreshes do window:Refresh() end
            local after = collectgarbage("count")
            collectgarbage("restart")
            return (after - before) * 1024
        end
        local perRow = (Bytes(10, 100) - Bytes(0, 100)) / (10 * 100)
        return perRow > 0 and "allocates per row on each refresh" or "allocates nothing per row"
    end,
    Recorded = "allocates per row on each refresh",
    Target = "allocates nothing per row",
})

-- [[ B9: the window's strings applied on every tab switch ]] --
-- Counted from the second switch on, so applying them once on the first open or when the window is made both meet Target
Scenario("B9", "ApplyStrings runs on every tab switch, though the strings are the same on every tab", {
    Observe = function()
        local lib = LoadCopy()
        local a = lib.CreateWindow(Config({ TabName = "A" }))
        local b = lib.CreateWindow(Config({ TabName = "B" }))
        local count = 0
        local window = Window(lib, { Show = Noop, ShowSection = Noop, ApplyStrings = function() count = count + 1 end })
        window:ShowTab(a)
        count = 0
        window:ShowTab(b)
        window:ShowTab(a)
        return ("ApplyStrings ran %d time(s) over two switches after the first open"):format(count)
    end,
    Recorded = "ApplyStrings ran 2 time(s) over two switches after the first open",
    Target = "ApplyStrings ran 0 time(s) over two switches after the first open",
})

-- [[ B10: the last tab unregisters ]] --
Scenario("B10", "a window stays shown after its last tab unregisters", {
    Observe = function()
        local lib = LoadCopy()
        tContains = function(list, value)
            for _, item in ipairs(list) do if item == value then return true end end
            return false
        end
        local tab = lib.CreateWindow(Config())
        local visible = true
        local window = Window(lib, { TabButtons = {}, UpdateSearchAll = Noop, RefreshTabs = Internal(lib).Mixins.Window.RefreshTabs,
            IsShown = function() return visible end, Show = function() visible = true end, Hide = function() visible = false end })
        window.Tab = tab
        Internal(lib).Frame = window
        tab:Unregister()
        return visible and "left shown" or "hidden"
    end,
    Recorded = "left shown",
    Target = "hidden",
})

-- [[ B11: a saved value of the wrong type ]] --
Scenario("B11a", "a range option whose saved value is a string passes it to the slider", {
    Observe = function()
        local lib = LoadCopy()
        local row = OptionRow(lib)
        local option = Option("Scale", { Type = "range", GetRange = function() return 0, 10, 1 end, Get = function() return "big" end })
        row:Init({ Kind = "Option", Option = option }, RowWindow(lib))
        local init, set = CallsTo(row.Range, "Init")[1], CallsTo(row.Range, "SetValue")
        return ("the slider is given a %s, then a %s"):format(type(init[1]), type(set[#set][1]))
    end,
    Recorded = "the slider is given a string, then a string",
    Target = "the slider is given a number, then a number",
})

Scenario("B11b", "an input option whose saved value is a table passes it to the edit box", {
    Observe = function()
        local lib = LoadCopy()
        local row = OptionRow(lib)
        row.Input.HasFocus = function() return false end
        local option = Option("Name", { Type = "input", Get = function() return {} end })
        row:Init({ Kind = "Option", Option = option }, RowWindow(lib))
        local set = CallsTo(row.Input, "SetText")
        return "the edit box is given a " .. (set[#set] and type(set[#set][1]) or "nothing")
    end,
    Recorded = "the edit box is given a table",
    Target = "the edit box is given a string",
})

-- [[ B12: a select whose value is no longer one of its choices ]] --
-- What the dropdown shows: the selected radio's text, or with none selected its default text
Scenario("B12", "a select whose value is no longer one of its choices shows blank", {
    Observe = function()
        local lib = LoadCopy()
        local row = OptionRow(lib)
        local option = Option("Profile", { Type = "select", GetValues = function() return { { "a", "Alpha" }, { "b", "Beta" } } end,
            Get = function() return "gone" end })
        row:Init({ Kind = "Option", Option = option }, RowWindow(lib))
        local dropdown = row.Select.Dropdown
        local selected
        CallsTo(dropdown, "SetupMenu")[1][1](dropdown, { CreateRadio = function(_, text, isSelected)
            if isSelected() then selected = text end
        end })
        local default = CallsTo(dropdown, "SetDefaultText")
        local text = selected or (default[#default] and default[#default][1]) or ""
        return text == "" and "blank" or "not blank"
    end,
    Recorded = "blank",
    Target = "not blank",
})

-- [[ B13: text typed in an input box when it loses focus ]] --
Scenario("B13", "text typed in an input box is dropped when the box loses focus; only Enter saves it (by design? ask Krowi)", {
    Observe = function()
        local lib = LoadCopy()
        local row = OptionRow(lib)
        local saved = "old"
        row.Input.HasFocus = function() return false end
        row.Input.GetText = function() return "typed" end
        local option = Option("Name", { Type = "input", Get = function() return saved end, Set = function(_, value) saved = value end })
        row:Init({ Kind = "Option", Option = option }, RowWindow(lib, { OnOptionChanged = Noop }))
        local lost = ScriptOf(row.Input, "OnEditFocusLost")
        if lost then lost(row.Input) end
        row:Refresh()
        return "after the box loses focus the option holds " .. tostring(saved)
    end,
    Recorded = "after the box loses focus the option holds old",
    Target = "after the box loses focus the option holds old",
})

-- [[ B14: a section whose GetElements errors (backlog #27) ]] --
local function BrokenSection()
    local lib = LoadCopy()
    local shownFor = {}
    local window = Window(lib, { Saved = {}, EndFill = Internal(lib).Mixins.Window.EndFill, Config = Config({
        OnSectionShown = function(id) shownFor[#shownFor + 1] = id end,
        GetElements = function(id)
            if id == "broken" then error("broken's own error") end
            return {}
        end }) })
    window:ShowSection("first")
    for key in pairs(shownFor) do shownFor[key] = nil end
    window:ShowSection("broken")
    return window, shownFor
end

Scenario("B14a", "a section whose GetElements errors ends its fill (already fixed in 2.0)", {
    Observe = function()
        local window = BrokenSection()
        return window.Filling and "left filling" or "fill ended"
    end,
    Recorded = "fill ended",
    Target = "fill ended",
})

Scenario("B14b", "a section whose GetElements errors becomes the window's SectionId", {
    Observe = function()
        local window = BrokenSection()
        return "SectionId " .. tostring(window.SectionId)
    end,
    Recorded = "SectionId broken",
    Target = "SectionId first",
})

Scenario("B14c", "a section whose GetElements errors has had its OnSectionShown", {
    Observe = function()
        local _, shownFor = BrokenSection()
        return #shownFor > 0 and ("OnSectionShown ran for " .. table.concat(shownFor, ", ")) or "OnSectionShown did not run"
    end,
    Recorded = "OnSectionShown ran for broken",
    Target = "OnSectionShown did not run",
})

-- [[ B15: where tab:GetSaved()'s error points (backlog #29) ]] --
-- The addon's own line is its chunk, MyAddon.lua; the library's files run as chunks named after them
local function ErrorChunk(lib, tab, call)
    local addon = assert(loadstring("local tab = ... " .. call, "MyAddon.lua"))
    local ok, message = pcall(addon, tab)
    if ok then return "no error" end
    return "the error points at " .. (tostring(message):match('^%[string "(.-)"%]:%d+:') or "no line")
end

Scenario("B15a", "a tab without a saved table: tab:Open() before the window exists errors at the library's line", {
    Observe = function()
        local lib = LoadCopy()
        local tab = lib.CreateWindow(Config({ TabName = "Broken", Saved = function() return nil end }))
        return ErrorChunk(lib, tab, "tab:Open()")
    end,
    Recorded = "the error points at Krowi_Options.lua",
    Target = "the error points at MyAddon.lua",
})

Scenario("B15b", "a tab without a saved table: tab:Open() on a window already made errors at the library's line", {
    Observe = function()
        local lib = LoadCopy()
        local tab = lib.CreateWindow(Config({ TabName = "Broken", Saved = function() return nil end }))
        Internal(lib).Frame = Window(lib, { Show = Noop, ShowSection = Noop })
        return ErrorChunk(lib, tab, "tab:Open()")
    end,
    Recorded = "the error points at WindowMixin.lua",
    Target = "the error points at MyAddon.lua",
})

Scenario("B15c", "a tab without a saved table: the addon's own tab:GetSaved() errors at its line (already right)", {
    Observe = function()
        local lib = LoadCopy()
        local tab = lib.CreateWindow(Config({ TabName = "Broken", Saved = function() return nil end }))
        return ErrorChunk(lib, tab, "tab:GetSaved()")
    end,
    Recorded = "the error points at MyAddon.lua",
    Target = "the error points at MyAddon.lua",
})

-- [[ B16: the config contract (phase 4): five required fields, defaults for the other six, unknown keys refused ]] --
-- A config without the field: refused today; once accepted, the window's real code uses the field the tab ended up
-- with (tab.Config, wherever the default is put) and must not reach the error handler
local optional = {
    { "B16a", "IsNew", "no section marked New", function(lib, tab)
        local list
        local window = Window(lib, { Config = tab.Config, RefreshNav = Internal(lib).Mixins.Window.RefreshNav,
            NavScrollBox = { SetDataProvider = function(_, given) list = given end } })
        window:RefreshNav()
        local new = 0
        for _, element in ipairs(list or {}) do if element.IsNew then new = new + 1 end end
        return new == 0 and "no section marked New" or (new .. " section(s) marked New")
    end },
    { "B16b", "Landing", "opens on the overview", function(lib, tab)
        local opened
        local window = Window(lib, { Show = Noop, ShowSection = function(_, id) opened = id end })
        window:ShowTab(tab)
        return "opens on the " .. tostring(opened)
    end },
    { "B16c", "OnSectionShown", "the section opens", function(lib, tab)
        local window = Window(lib, { Saved = {}, Config = tab.Config, EndFill = function(w) w.Filled = true end })
        window:ShowSection("first")
        return window.Filled and "the section opens" or "the fill did not end"
    end },
    { "B16d", "GetHelp", "no help", function(lib, tab)
        local window = Window(lib, { Config = tab.Config, SectionId = "first", ShowSectionHelp = Internal(lib).Mixins.Window.ShowSectionHelp })
        window:ShowSectionHelp()
        return window.Help == nil and "no help" or "help"
    end },
    { "B16e", "ResetSection", "Defaults resets nothing and needs no reload", function(lib, tab)
        local window = Window(lib, { Config = tab.Config, ReloadSection = Noop })
        window:ResetSection("first")
        return window.ReloadPending and "the reload bar lit" or "Defaults resets nothing and needs no reload"
    end },
    { "B16f", "ChangedCount", "Defaults greyed out", function(lib, tab)
        local shown = {}
        local fields = Footer(lib, shown)
        fields.Config, fields.SectionId, fields.Strings = tab.Config, "first", lib.GetStrings()
        local window = Window(lib, fields)
        window:RefreshFooter()
        return shown.DefaultsEnabled and "Defaults enabled" or "Defaults greyed out"
    end },
}

for _, case in ipairs(optional) do
    local id, field, target, use = case[1], case[2], case[3], case[4]
    Scenario(id, ("a config without %s is refused"):format(field), {
        Observe = function()
            local lib = LoadCopy()
            local ok, tab = pcall(lib.CreateWindow, Config({ [field] = NIL }))
            if not ok then return "refused: " .. tostring(tab) end
            local used, result = pcall(use, lib, tab)
            if not used then return "accepted, then raised: " .. tostring(result) end
            return ("accepted: %s, %d error(s) to the handler"):format(result, #handled)
        end,
        Recorded = ('refused: Krowi_Options: tab "Test": config.%s must be a function, not nil'):format(field),
        Target = ("accepted: %s, 0 error(s) to the handler"):format(target),
    })
end

Scenario("B16g", "a config with a misspelled key (OnSectionShow) is accepted silently", {
    Observe = function()
        local lib = LoadCopy()
        local ok, message = pcall(lib.CreateWindow, Config({ OnSectionShow = Noop }))
        local text = not ok and tostring(message) or handled[1] and tostring(handled[1]) or nil
        if text and text:find('"Test"', 1, true) and text:find("OnSectionShow", 1, true) then return "an error naming the tab and the key" end
        return ok and "accepted silently" or ("refused: " .. tostring(message))
    end,
    Recorded = "accepted silently",
    Target = "an error naming the tab and the key",
})