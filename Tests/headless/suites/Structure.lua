--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The safety net of phase 2 of docs/work/2026-11-06-finish-2-0 (plan.md, step 0), which splits WindowMixin.lua and moves
-- the code of each element kind into a table of kinds without changing behaviour. Recorded on the code before the split,
-- by running it, it holds what the library offers, not which file defines it:
--   S1  the names on each of lib.Internal.Mixins' tables and on lib.Internal.Build: a method lost in a move shows as
--       missing
--   S2  lib.Internal.Search on the test addon's fixture tab (Tests/Krowi_OptionsTests/Tests/Fixtures.lua) and its
--       second tab, and the page the window makes of it (SearchElements)
--   S3  each section's page signature, as the window's FillPage computes it
--   S4  two copies mixed (h.LoadCopy): every window method recorded in S1 is still there
--   S5  no file keeps another file's field in a local at load (CLAUDE.md, Versioning): the kit's static two-copy check
--       (skills/release/TwoCopy.ps1, Find-LoadTimeCaptures) ported, with the same rules
--   S6  the keys on lib and on lib.Internal: a name added to lib is a decision (public, so frozen with the contract)
-- A snapshot passes while the code gives what is recorded. On a difference it names what changed and prints all that the
-- code gives now, to be recorded in the same change when the difference is meant (a method added or renamed on purpose).
-- Step 10 of the plan moved the internals under lib.Internal; Internal() reads them there, or on lib on a copy from
-- before.

local h = ...
local Check, Scenario, LoadCopy, Window = h.Check, h.Scenario, h.LoadCopy, h.Window

-- An internal of the library, on lib.Internal once it is there, on lib until then
local function Internal(lib, name)
    local internal = lib.Internal
    if type(internal) == "table" and internal[name] ~= nil then return internal[name] end
    return lib[name]
end

-- [[ Snapshots ]] --
local function Trim(text)
    return (text:match("^%s*(.-)%s*$"))
end

local function Split(text, pattern)
    local list = {}
    for item in text:gmatch(pattern) do
        item = Trim(item)
        if item ~= "" then list[#list + 1] = item end
    end
    return list
end

local function NameList(text)
    return Split(text, "[^%s,]+")
end

local function LineList(text)
    return Split(text, "[^\n]+")
end

local function SortedKeys(t)
    local keys = {}
    for key in next, t do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    return keys
end

-- Names as they are recorded below: comma-separated, a line at most 116 wide
local function Wrap(names)
    local lines, line = {}, ""
    for _, name in ipairs(names) do
        local longer = line == "" and name or (line .. ", " .. name)
        if #longer > 116 and line ~= "" then
            lines[#lines + 1] = line .. ","
            line = name
        else
            line = longer
        end
    end
    lines[#lines + 1] = line
    return table.concat(lines, "\n")
end

-- A set of names: passes while observe() (a list) holds the recorded names, no more and no fewer
local function Names(id, title, observe, recorded)
    Check(id, title, function()
        local now, was = observe(), NameList(recorded)
        local inNow, inWas = {}, {}
        for _, name in ipairs(now) do inNow[name] = true end
        for _, name in ipairs(was) do inWas[name] = true end
        local missing, new = {}, {}
        for _, name in ipairs(was) do
            if not inNow[name] then missing[#missing + 1] = name end
        end
        for _, name in ipairs(now) do
            if not inWas[name] then new[#new + 1] = name end
        end
        if #missing == 0 and #new == 0 then return true, ("%d names"):format(#now) end
        return false, ("missing [%s], new [%s]; now:\n%s"):format(table.concat(missing, ", "), table.concat(new, ", "), Wrap(now))
    end)
end

-- Lines in order: passes while observe() (a list) gives the recorded lines
local function Snapshot(id, title, observe, recorded)
    Check(id, title, function()
        local now, was = LineList(table.concat(observe(), "\n")), LineList(recorded)
        for i = 1, math.max(#now, #was) do
            if now[i] ~= was[i] then
                return false, ("line %d: recorded [%s], now [%s]; now:\n%s"):format(i, tostring(was[i]), tostring(now[i]),
                    table.concat(now, "\n"))
            end
        end
        return true, ("%d line(s)"):format(#now)
    end)
end

-- [[ S1: the names on the mixins and the builders ]] --
-- Every key of each table on lib.Internal.Mixins (the window's and the rows'; Tab's __index is its tabs' metatable
-- link), as recorded; S1.Mixins checks that the library has these tables and no other
local mixins = {
    Card = [[
Init, OnClick, OnEnter, OnLeave, SetHovered]],
    CardRow = [[
Init, OnLoad]],
    GridHeaderRow = [[
Init, OnLoad]],
    GridRow = [[
Init, OnEnter, OnLeave, OnLoad, Refresh]],
    HelpPicture = [[
Init, OnClick, OnEnter, OnLeave]],
    HelpText = [[
Init]],
    KeyButton = [[
Lift, OnMouseDown, SetPieces]],
    LinkRow = [[
Init, OnClick]],
    NavButton = [[
Init, OnClick, OnEnter, OnLeave, UpdateState]],
    NavHeader = [[
Init]],
    OptionRow = [[
EndKeyCapture, Init, OnEnter, OnKeyCaptured, OnLeave, OnLoad, Refresh, StartKeyCapture]],
    SearchHeadingRow = [[
Init, OnClick, OnEnter, OnLeave]],
    SubRow = [[
Init, OnLoad]],
    Tab = [[
GetFrame, GetSaved, IsShown, Open, Refresh, Toggle, Unregister, __index]],
    TabRow = [[
Init, OnEnter, OnLeave, OnLoad, Refresh]],
    TextRow = [[
Init]],
    Window = [[
ApplyStrings, ApplyWidth, AskConfirm, CancelConfirm, ConfirmingHere, CreateInnerFrame, EndFill, EndKeyCaptures,
FillHelp, FillPage, HideTooltip, InCombat, Init, Layout, LayoutInnerFrame, LoadHelp, LoadLayout, LoadPage,
LoadSearch, MeasureText, NavEnd, OnDefaultsClick, OnDragStart, OnDragStop, OnEvent, OnHide, OnLoad,
OnNavScrollBarShown, OnOptionChanged, OnRowEnter, OnRowLeave, OnSearch, OnShow, OnSizeChanged, Open, PageWidth,
Refresh, RefreshFooter, RefreshHover, RefreshNav, RefreshTabs, ReleaseShowMe, ReloadSection, ResetSection, SavePoint,
ScrollToOption, SearchElements, SetKicker, SetPaneCollapsed, ShowPicture, ShowSearchHelp, ShowSection,
ShowSectionHelp, ShowTab, UpdateSearchAll, UpdateShowMe]],
}

local builders = [[
Card, CardRow, CheckButton, Color, Finish, GridHeaderRow, GridRow, HeaderRow, HelpPicture, HelpText, KeyButton,
LinkRow, NavButton, NavHeader, NavSpacer, NoteRow, OptionRow, Row, SearchHeadingRow, Select, SubHeadingRow, SubRow,
TabRow, Text, Window]]

Names("S1.Mixins", "the tables on lib.Internal.Mixins", function() return SortedKeys(Internal(LoadCopy(), "Mixins")) end,
    table.concat(SortedKeys(mixins), ", "))

for _, name in ipairs(SortedKeys(mixins)) do
    Names("S1." .. name, ("the names on lib.Internal.Mixins.%s"):format(name), function()
        local mixin = Internal(LoadCopy(), "Mixins")[name]
        return type(mixin) == "table" and SortedKeys(mixin) or {}
    end, mixins[name])
end

Names("S1.Build", "the builders on lib.Internal.Build", function() return SortedKeys(Internal(LoadCopy(), "Build")) end,
    builders)

-- [[ The fixture tab ]] --
-- Loaded as Tests/Krowi_OptionsTests/Headless.lua loads it, without running the test addon's scenarios
local addon = { Tests = {} }
assert(loadfile(h.root .. "Tests/Krowi_OptionsTests/Tests/Fixtures.lua"))("Krowi_OptionsTests", addon)
local fixtures = addon.Tests.Fixtures

-- This checkout's copy with the fixture tab registered, as Headless.lua's Prepare has it, and the second tab, as the
-- window-second-tab scenario makes it, so a search of every tab has two
local function FixtureTabs()
    local lib = LoadCopy()
    fixtures.Reset()
    fixtures.Register(lib, {})
    fixtures.SecondTab = lib.CreateWindow(fixtures.SecondConfig({}))
    return lib
end

-- What a row or a page element shows: an option's name (and the name of the one beside it), the column titles, a tab's
-- name, or its text
local function Label(element)
    if element.Option then
        local label = element.Option:GetLabel()
        if element.With then label = label .. " + " .. element.With:GetLabel() end
        return label
    end
    if element.Kind == "GridHeader" then return table.concat(element.Columns or {}, "/") end
    if element.Kind == "TabRow" then
        local show = element.Item and element.Item.Show
        return show and show:GetLabel() or ("position " .. tostring(element.Item and element.Item.Position))
    end
    return tostring(element.Text or element.Label)
end

-- [[ S2: the search ]] --
-- A found row per line, in the order lib.Internal.Search gives them: tab > section > heading > kind: name
local count = 0
local function Search(text, all, broad, recorded)
    count = count + 1
    Snapshot("S2." .. count, ("lib.Internal.Search %q, %s, %s"):format(text, all and "every tab" or "this tab",
        broad and "names and descriptions" or "names"),
        function()
            local lib = FixtureTabs()
            local lines = {}
            for _, group in ipairs(Internal(lib, "Search")(text, all, fixtures.Tab, broad)) do
                for _, section in ipairs(group.Sections) do
                    for _, row in ipairs(section.Rows) do
                        local heading = row.Heading ~= "" and (tostring(row.Heading) .. " > ") or ""
                        local whose = (row.Tab ~= group.Tab or row.SectionId ~= section.Id) and " (row of another tab or section)" or ""
                        lines[#lines + 1] = ("%s > %s > %s%s: %s%s"):format(group.Tab.Config.TabName, section.Name, heading, row.Kind,
                            Label(row), whose)
                    end
                end
            end
            if #lines == 0 then lines[1] = "nothing found" end
            return lines
        end, recorded)
end

-- The page the window makes of a search: tab names (every tab), each section's name, the headings and the rows
local function WindowSearch(text, everyTab, broad, recorded)
    count = count + 1
    Snapshot("S2." .. count, ("the window's search page for %q, %s, %s"):format(text, everyTab and "every tab" or "this tab",
        broad and "names and descriptions" or "names"), function()
        local lib = FixtureTabs()
        local window = Window(lib, { Tab = fixtures.Tab, SearchEveryTab = everyTab, BroadSearch = broad })
        local lines = {}
        for _, element in ipairs(window:SearchElements(text)) do
            lines[#lines + 1] = element.Kind .. ": " .. Label(element)
        end
        return lines
    end, recorded)
end

-- Each text this tab and every tab, by names and with descriptions too. Where modes find the same rows today, they share
-- one recorded text: a change that sets them apart gives the mode its own.
local nothing = "nothing found"
-- The second tab's one option, found by every-tab searches; it sorts first ("Aa Test")
local second = "Aa Test > Second > Option: Second tooltip\n"

Search("", false, false, nothing)
Search("", false, true, nothing)
Search("", true, false, nothing)
Search("", true, true, nothing)

-- Nearly every name and description holds an A; a found row brings the row it hangs under
local aNames = [[
Options Test > Window > General > Option: Indentation
Options Test > Window > General > Option: Date format
Options Test > Window > Position > Option: Remember main window position + Reset main window position
Options Test > Window > Position > Option: Remember calendar position + Reset calendar position
Options Test > Window > Position > Option: Button: horizontal position
Options Test > Window > Position > Option: Button: vertical position
Options Test > Tooltips > Unit tooltips > Option: Show details
Options Test > Tooltips > Show details if > Option: Quest was not done by me
Options Test > Tooltips > Display > Option: Compact lines
Options Test > Debug > Output > Option: Verbose mode
Options Test > Debug > Output > Option: Trace calls
Options Test > Debug > Priority > Option: Tab priority
Options Test > Events > Seasons > Sub: All seasons
Options Test > Events > Seasons > Option: Spring
Options Test > Events > Seasons > Option: Summer
Options Test > Events > Seasons > Option: Autumn
Options Test > Events > Seasons > Option: Winter
Options Test > Events > Calendar grid > GridHeader: Show/Remind/Sound
Options Test > Events > Calendar grid > GridRow: Market day
Options Test > Events > Calendar grid > GridRow: Harvest fair
Options Test > Events > Calendar grid > GridRow: Moon festival
Options Test > Tabs > Order > TabRow: Summary
Options Test > Tabs > Order > TabRow: Watch list
Options Test > Tabs > Order > TabRow: Statistics
Options Test > Tabs > Behaviour > Option: Remember the last tab
Options Test > Other addons > Alpha UI > Option: Loaded
Options Test > Other addons > Beta Bars > Option: Loaded
Options Test > Other addons > Beta Bars > Option: Restyle bars
Options Test > Other addons > Gamma Maps > Option: Loaded]]
local aBroad = [[
Options Test > Window > General > Option: Indentation
Options Test > Window > General > Option: Date format
Options Test > Window > General > Option: Center the title
Options Test > Window > General > Option: Force two columns + Column threshold
Options Test > Window > General > Option: Use the old look
Options Test > Window > Position > Option: Remember main window position + Reset main window position
Options Test > Window > Position > Option: Remember calendar position + Reset calendar position
Options Test > Window > Position > Option: Button: horizontal position
Options Test > Window > Position > Option: Button: vertical position
Options Test > Window > Position > Option: Remember log position + Reset log position
Options Test > Window > Position > Option: Reset view on open
Options Test > Tooltips > Unit tooltips > Option: Show details
Options Test > Tooltips > Show details if > Option: Quest is completed
Options Test > Tooltips > Show details if > Option: Quest was not done by me
Options Test > Tooltips > Show details if > Option: Step is completed
Options Test > Tooltips > Display > Option: Compact lines
Options Test > Tooltips > Display > Option: Show in tooltip
Options Test > Tooltips > Points tooltip > Option: Sort priority 1
Options Test > Tooltips > Points tooltip > Option: Reverse sort
Options Test > Tooltips > Points tooltip > Option: Sort priority 2
Options Test > Tooltips > Points tooltip > Option: Reverse sort
Options Test > Tooltips > Points tooltip > Option: Sort priority 3
Options Test > Tooltips > Points tooltip > Option: Reverse sort
Options Test > Tooltips > Skins > Option: Skin tooltip
Options Test > Tooltips > Skins > Option: Thin border
Options Test > Debug > Output > Option: Verbose mode
Options Test > Debug > Output > Option: Trace calls
Options Test > Debug > Priority > Option: Tab priority
Options Test > Debug > Profiles > Option: Reset everything
Options Test > Events > Seasons > Sub: All seasons
Options Test > Events > Seasons > Option: Spring
Options Test > Events > Seasons > Option: Summer
Options Test > Events > Seasons > Option: Autumn
Options Test > Events > Seasons > Option: Winter
Options Test > Events > Calendar grid > GridHeader: Show/Remind/Sound
Options Test > Events > Calendar grid > GridRow: Market day
Options Test > Events > Calendar grid > GridRow: Harvest fair
Options Test > Events > Calendar grid > GridRow: Moon festival
Options Test > Tabs > Order > TabRow: Summary
Options Test > Tabs > Order > TabRow: Watch list
Options Test > Tabs > Order > TabRow: Statistics
Options Test > Tabs > Behaviour > Option: Remember the last tab
Options Test > Other addons > Alpha UI > Option: Loaded
Options Test > Other addons > Alpha UI > Option: Skin tooltip
Options Test > Other addons > Beta Bars > Option: Loaded
Options Test > Other addons > Beta Bars > Option: Restyle bars
Options Test > Other addons > Gamma Maps > Option: Loaded
Options Test > Key bindings > Window > Option: Open the window
Options Test > Key bindings > List > Option: Toggle the list]]
Search("a", false, false, aNames)
Search("a", false, true, aBroad)
Search("a", true, false, aNames)
Search("a", true, true, second .. aBroad)

local tooltip = [[
Options Test > Tooltips > Display > Option: Show in tooltip
Options Test > Tooltips > Skins > Option: Skin tooltip
Options Test > Other addons > Alpha UI > Option: Skin tooltip]]
Search("tooltip", false, false, tooltip)
Search("tooltip", false, true, tooltip)
Search("tooltip", true, false, second .. tooltip)
Search("tooltip", true, true, second .. tooltip)

local showNames = [[
Options Test > Tooltips > Unit tooltips > Option: Show details
Options Test > Tooltips > Display > Option: Show in tooltip]]
local showBroad = showNames .. "\n" .. "Options Test > Key bindings > List > Option: Toggle the list"
Search("show", false, false, showNames)
Search("show", false, true, showBroad)
Search("show", true, false, showNames)
Search("show", true, true, showBroad)

-- A button's text is its check box's name
local reset = [[
Options Test > Window > Position > Option: Remember main window position + Reset main window position
Options Test > Window > Position > Option: Remember calendar position + Reset calendar position
Options Test > Window > Position > Option: Remember log position + Reset log position
Options Test > Window > Position > Option: Reset view on open
Options Test > Debug > Profiles > Option: Reset everything]]
Search("reset", false, false, reset)
Search("reset", false, true, reset)
Search("reset", true, false, reset)
Search("reset", true, true, reset)

-- Inside a word; Reverse sort brings the Sort priority above it
local ver = [[
Options Test > Window > Position > Option: Button: vertical position
Options Test > Tooltips > Points tooltip > Option: Sort priority 1
Options Test > Tooltips > Points tooltip > Option: Reverse sort
Options Test > Tooltips > Points tooltip > Option: Sort priority 2
Options Test > Tooltips > Points tooltip > Option: Reverse sort
Options Test > Tooltips > Points tooltip > Option: Sort priority 3
Options Test > Tooltips > Points tooltip > Option: Reverse sort
Options Test > Debug > Output > Option: Verbose mode
Options Test > Debug > Profiles > Option: Reset everything]]
Search("ver", false, false, ver)
Search("ver", false, true, ver)
Search("ver", true, false, ver)
Search("ver", true, true, ver)

-- Retail's named colour code goes from the text searched for as from the names (Bugs B7), which leaves "x", in no name
-- or description
Search("|cnHIGHLIGHT_FONT_COLOR:x|r", false, false, nothing)
Search("|cnHIGHLIGHT_FONT_COLOR:x|r", false, true, nothing)
Search("|cnHIGHLIGHT_FONT_COLOR:x|r", true, false, nothing)
Search("|cnHIGHLIGHT_FONT_COLOR:x|r", true, true, nothing)

WindowSearch("tooltip", true, true, [[
Header: Aa Test
SearchHeading: Second
Option: Second tooltip
Header: Options Test
SearchHeading: Tooltips
SubHeading: Display
Option: Show in tooltip
SubHeading: Skins
Option: Skin tooltip
SearchHeading: Other addons
SubHeading: Alpha UI
Option: Skin tooltip]])
WindowSearch("reset", false, false, [[
SearchHeading: Window
SubHeading: Position
Option: Remember main window position + Reset main window position
Option: Remember calendar position + Reset calendar position
Option: Remember log position + Reset log position
Option: Reset view on open
SearchHeading: Debug
SubHeading: Profiles
Option: Reset everything]])
WindowSearch("zzz", false, false, "Note: Nothing found.")

-- [[ S3: the page signatures ]] --
-- What the window compares after a change to tell whether the page keeps its rows (WindowPage.lua, Signature), on a
-- stand-in window whose FillPage reads the section as the real one does; a line per row
local function Signature(id, sectionId, title, prepare, recorded)
    Snapshot("S3." .. id, title, function()
        local lib = FixtureTabs()
        if prepare then prepare() end
        local window = Window(lib, { Saved = {}, SectionId = sectionId, Config = fixtures.Tab.Config })
        if not window:FillPage(ScrollBoxConstants.DiscardScrollPosition) then return { "not filled" } end
        return LineList(window.Signature)
    end, recorded)
end

local function Page(id, recorded)
    Signature(id, id, ("the signature of the %s page"):format(id), nil, recorded)
end

-- A card row by its cards' names, then each card's line and NEW
Page("overview", [=[
Header:General
CardRow:Window,Tooltips,Debug [The title, the columns, dates and where the windows stand., What a unit's tooltip shows, and in which order., Output, priorities and profiles.]
Header:Lists
CardRow:Events,Tabs,Key bindings [The seasons and the calendar grid., Which tabs show, and their order. (New), The keys of the window and the list.]
CardRow:Other addons [What this tab does with other addons.]
Header:About
CardRow:About [Who made it.]]=])

-- An option by its id and name, and the id of the one beside it
Page("window", [[
Header:General
Option:window.centerTitle|Center the title
Option:window.indentation|Indentation
Option:window.dateFormat|Date format
Option:window.twoColumns|Force two columns+window.columnThreshold
Option:window.oldLook|Use the old look
Header:Position
Option:window.rememberMain|Remember main window position+window.resetMain
Option:window.rememberCalendar|Remember calendar position+window.resetCalendar
Option:window.rememberLog|Remember log position+window.resetLog
Option:window.buttonX|Button: horizontal position
Option:window.buttonY|Button: vertical position
Option:window.resetView|Reset view on open]])

Page("tooltips", [[
Header:Unit tooltips
Option:tooltips.details|Show details
SubHeading:Show details if
Option:tooltips.ifCompleted|Quest is completed
Option:tooltips.ifNotDone|Quest was not done by me
Option:tooltips.ifStep|Step is completed
Header:Points tooltip
Option:tooltips.sort1|Sort priority 1
Option:tooltips.reverse1|Reverse sort
Option:tooltips.sort2|Sort priority 2
Option:tooltips.reverse2|Reverse sort
Option:tooltips.sort3|Sort priority 3
Option:tooltips.reverse3|Reverse sort
Header:Display
Option:tooltips.showIn|Show in tooltip
Option:tooltips.compact|Compact lines
Header:Skins
Option:tooltips.skin|Skin tooltip
Option:tooltips.thinBorder|Thin border]])

local debugPage = [[
Header:Output
Option:debug.verbose|Verbose mode
Option:debug.trace|Trace calls
Option:debug.logFile|Log file
Header:Priority
Option:debug.tabPriority|Tab priority
Option:debug.priorityOrder|Priority order
Header:Profiles
Option:debug.profile|Profile
Option:debug.resetAll|Reset everything]]
Page("debug", debugPage)
Signature("debug-hidden", "debug", "the signature of the debug page with Verbose mode off, which hides Trace calls", function()
    fixtures.Options["debug.verbose"]:Set(false)
end, (debugPage:gsub("Option:debug%.trace|Trace calls\n", "")))

-- The grid's column titles sign as their kind alone (the signature leaves out a grid's columns), a grid row by its name
-- and its check boxes' ids and names, a tab by its Show's id and name and its position, the tab without a Show
-- (Blizzard's) by its position alone (Bugs B4, B18)
Page("events", [=[
Header:Seasons
Sub:All seasons
Option:events.spring|Spring
Option:events.summer|Summer
Option:events.autumn|Autumn
Option:events.winter|Winter
Header:Calendar grid
GridHeader:
GridRow:Market day [events.Market day.show|Market day: Show, events.Market day.remind|Market day: Remind, events.Market day.sound|Market day: Sound]
GridRow:Harvest fair [events.Harvest fair.show|Harvest fair: Show, events.Harvest fair.remind|Harvest fair: Remind]
GridRow:Moon festival [events.Moon festival.show|Moon festival: Show, events.Moon festival.remind|Moon festival: Remind, events.Moon festival.sound|Moon festival: Sound]]=])

Page("tabs", [[
Header:Order
TabRow:tabs.summary|Summary [1]
TabRow:tabs.watch|Watch list [2]
TabRow:tabs.stats|Statistics [3]
TabRow: [4]
Header:Behaviour
Option:tabs.rememberTab|Remember the last tab]])

Page("keys", [[
Note:The keys set here stay in this test addon: no key of the game is bound.
Header:Window
Option:keys.open|Open the window
Header:List
Option:keys.list|Toggle the list]])

Page("addons", [[
Header:Alpha UI
Option:addons.alpha.loaded|Loaded
Option:addons.alpha.skin|Skin tooltip
Header:Beta Bars
Option:addons.beta.loaded|Loaded
Option:addons.beta.bars|Restyle bars
Header:Gamma Maps
Option:addons.gamma.loaded|Loaded]])

Page("about", [=[
Header:Credits
Note:Made for the tests of Krowi_Options.
SubHeading:Thanks
Note:To everyone who reports a bug.
Header:Links
Link:Debug settings [Opens the Debug section]
Link:Key bindings [Opens the Key bindings section]]=])

-- Every section of the fixture tab has its page above
Check("S3.sections", "every section of the fixture tab has a recorded signature", function()
    local recorded = { "overview", "window", "tooltips", "debug", "events", "tabs", "keys", "addons", "about" }
    local now = { "overview", unpack(fixtures.Sections) }
    return table.concat(now, ",") == table.concat(recorded, ","), table.concat(now, ",")
end)

-- [[ S4: two copies mixed ]] --
local function Minors()
    local _, core = LibStub:GetLibrary("Krowi_Options_2")
    local _, window = LibStub:GetLibrary("Krowi_Options_2_WindowMixin")
    return ("core minor %s, WindowMixin minor %s"):format(tostring(core), tostring(window))
end

local function WindowMethods(lib)
    local window = Internal(lib, "Mixins").Window or {}
    local missing = {}
    for _, name in ipairs(NameList(mixins.Window)) do
        if window[name] == nil then missing[#missing + 1] = name end
    end
    return #missing == 0 and "every window method of S1 present" or ("missing " .. table.concat(missing, ", "))
end

Scenario("S4a", "a full copy, then a copy whose only newer file is the core (Krowi_Options.lua)", {
    Observe = function()
        local first = Internal(LoadCopy(), "Mixins").Window
        local lib = LoadCopy({ ["Krowi_Options.lua"] = 1 })
        local same = Internal(lib, "Mixins").Window == first
        return ("%s; %s; %s"):format(Minors(), WindowMethods(lib), same and "the same table" or "another table")
    end,
    Recorded = "core minor 1, WindowMixin minor 0; every window method of S1 present; the same table",
    Target = "core minor 1, WindowMixin minor 0; every window method of S1 present; the same table",
})

Scenario("S4b", "a copy whose only newer file is WindowMixin.lua, then a full copy", {
    Observe = function()
        local first = Internal(LoadCopy({ ["WindowMixin.lua"] = 1 }), "Mixins").Window
        local lib = LoadCopy()
        local same = Internal(lib, "Mixins").Window == first
        return ("%s; %s; %s"):format(Minors(), WindowMethods(lib), same and "the same table" or "another table")
    end,
    Recorded = "core minor 0, WindowMixin minor 1; every window method of S1 present; the same table",
    Target = "core minor 0, WindowMixin minor 1; every window method of S1 present; the same table",
})

-- Whether lib.Internal.Mixins.Window stays the same table is left out here: when this was recorded the newer
-- WindowMixin.lua replaced it, and step 1 of the plan made every window file add to it instead
Scenario("S4c", "a full copy, then a copy whose only newer file is WindowMixin.lua", {
    Observe = function()
        LoadCopy()
        local lib = LoadCopy({ ["WindowMixin.lua"] = 1 })
        return ("%s; %s"):format(Minors(), WindowMethods(lib))
    end,
    Recorded = "core minor 0, WindowMixin minor 1; every window method of S1 present",
    Target = "core minor 0, WindowMixin minor 1; every window method of S1 present",
})

-- [[ S5: no load-time captures ]] --
-- The kit's Find-LoadTimeCaptures (skills/release/TwoCopy.ps1) in Lua, on the column-0 statements of the files: the
-- names a file binds to the library (its registration's locals, file-level aliases such as
-- `local build = lib.Internal.Build`), the fields each file defines (`function build.Finish(`) or assigns
-- (`lib.Internal.Mixins.Row = RowMixin`), and the file-level locals that take a field (`local Finish = build.Finish`,
-- one of several in `local a, Finish = 0, build.Finish`, or `Finish = build.Finish` into a local declared before). A
-- local fails when another file defines or replaces that field: with copies mixed it keeps the older copy's. A field
-- only ever set as `X = X or {}` (lib.Internal and its Mixins, Build and Tabs) is fine, since every copy fills the same
-- table. Not seen, as in the kit: a capture in an indented line.
local registrars = { KROWI_LIBMAN = true, LibStub = true }
local registrations = { NewLibrary = true, NewSubmodule = true, GetCurrentLibrary = true }

local function IsDotted(text)
    return text:match("^[%a_][%w_]*%.[%w_%.]+$") ~= nil and not text:find("..", 1, true) and text:sub(-1) ~= "."
end

local function Resolve(aliases, expression)
    local first, rest = expression:match("^([%w_]+)(.*)$")
    if not first or not aliases[first] then return nil end
    return aliases[first] .. rest
end

-- sources: { { File, Text } } in load order. Returns a line per capture of another file's field.
local function Captures(sources)
    local captures, defined = {}, {}
    local function Define(path, file, kind)
        defined[path] = defined[path] or {}
        table.insert(defined[path], { File = file, Kind = kind })
    end
    for _, source in ipairs(sources) do
        local aliases, locals = {}, {}
        local function Capture(name, expression)
            local path = Resolve(aliases, expression)
            if path then
                aliases[name] = path
                captures[#captures + 1] = { File = source.File, Local = name, Path = path }
            end
        end
        for line in (source.Text .. "\n"):gmatch("([^\n]*)\n") do
            line = line:gsub("\r$", "")
            local code = Trim((line:gsub("%-%-.*$", "")))
            local first, second, registrar, method, rest = line:match("^local%s+([%w_]+)%s*,?%s*([%w_]*)%s*=%s*([%w_]+):([%w_]+)%((.*)$")
            if first and registrars[registrar] and registrations[method] then
                if method == "NewSubmodule" then
                    aliases[first] = "lib." .. tostring(rest:match("^%s*[\"']([^\"']+)[\"']"))
                    if second ~= "" then aliases[second] = "lib" end
                else
                    aliases[first] = "lib"
                end
            elseif line:match("^local%s") then
                if not line:match("^local%s+function[^%w_]") then
                    local namesText, right = code:match("^local%s+([%w_,%s]-)%s*=%s*(.-)$")
                    namesText = namesText or code:match("^local%s+([%w_,%s]-)$")
                    if namesText then
                        local names = Split(namesText, "[^,]+")
                        for _, name in ipairs(names) do locals[name] = true end
                        if right and right ~= "" and not right:find("[%(%)%[%]{}\"']") then
                            local values = Split(right, "[^,]+")
                            for i = 1, math.min(#names, #values) do
                                if IsDotted(values[i]) then Capture(names[i], values[i]) end
                            end
                        end
                    end
                end
            elseif line:match("^function%s") then
                local base, member = line:match("^function%s+([%a_][%w_%.]*)[%.:]([%w_]+)%s*%(")
                local path = base and Resolve(aliases, base)
                if path then Define(path .. "." .. member, source.File, "function") end
            else
                local name, expression = code:match("^([%w_]+)%s*=%s*([%w_%.]+)$")
                if name and locals[name] and IsDotted(expression) then
                    Capture(name, expression)
                else
                    local left, right = code:match("^([%a_][%w_]*%.[%w_%.]+)%s*=%s*(.-)$")
                    if left and right:sub(1, 1) ~= "=" then
                        local path = Resolve(aliases, left)
                        if path then
                            local orSelf = right:match("^" .. left:gsub("%.", "%%.") .. "%s+or%s+{%s*}$") ~= nil
                            Define(path, source.File, orSelf and "or-self" or "replace")
                        end
                    end
                end
            end
        end
    end
    local found = {}
    for _, capture in ipairs(captures) do
        local elsewhere, seen = {}, {}
        for _, definition in ipairs(defined[capture.Path] or {}) do
            if definition.File ~= capture.File and definition.Kind ~= "or-self" and not seen[definition.File] then
                seen[definition.File] = true
                elsewhere[#elsewhere + 1] = definition.File
            end
        end
        if #elsewhere > 0 then
            table.sort(elsewhere)
            found[#found + 1] = ("%s: %s = %s (defined in %s)"):format(capture.File, capture.Local, capture.Path, table.concat(elsewhere, ", "))
        end
    end
    return found
end

local function LibrarySources(edits)
    local sources = {}
    for _, file in ipairs(h.libraryFiles) do
        local text = h.Read(h.root .. file)
        if edits and edits[file] then text = edits[file](text) end
        sources[#sources + 1] = { File = file, Text = text }
    end
    return sources
end

Scenario("S5a", "no library file keeps another file's field in a local at load", {
    Observe = function()
        local found = Captures(LibrarySources())
        return #found == 0 and "none" or table.concat(found, "; ")
    end,
    Recorded = "none",
    Target = "none",
})

-- The scan itself: a capture planted at the end of Search.lua is found, a local of a table every copy fills is not
Scenario("S5b", "the scan finds a capture planted in Search.lua, and passes a shared table", {
    Observe = function()
        local found = Captures(LibrarySources({ ["Search.lua"] = function(text)
            return text .. "\nlocal CreateWindow = lib.CreateWindow\nlocal mixins = lib.Internal.Mixins"
        end }))
        return #found == 0 and "none" or table.concat(found, "; ")
    end,
    Recorded = "Search.lua: CreateWindow = lib.CreateWindow (defined in Krowi_Options.lua)",
    Target = "Search.lua: CreateWindow = lib.CreateWindow (defined in Krowi_Options.lua)",
})

-- [[ S6: the keys on lib and on lib.Internal ]] --
-- lib holds the public surface (CreateWindow, GetStrings, Markup, WindowName), Internal, what LibMan puts on a library
-- (Name, Version, Localization; L, the phrases) and the submodules LibMan hangs on it under their names (ElementKinds,
-- SearchModule, RowMixins, ...). A key added to lib is a decision to record here: public, and then frozen with the
-- contract (CLAUDE.md), or under lib.Internal, which can change in any version.
local libKeys = [[
CreateWindow, ElementKinds, GetStrings, Internal, L, Localization, Markup, Name, RowFrames, RowMixins, SearchModule,
Version, WindowFrame, WindowHelp, WindowLayout, WindowMixin, WindowName, WindowPage, WindowSearch]]
local internalKeys = [[
Build, CardColumns, CardCrop, CardRowHeight, CardWidth, Flatten, Geometry, GetFrame, InitList, Kinds, Mixins,
RowGeometry, RowX, Search, SetShared, Tabs, WindowWidth]]

Names("S6.lib", "the keys on lib after a full load", function() return SortedKeys(LoadCopy()) end, libKeys)

Names("S6.Internal", "the keys on lib.Internal after a full load", function()
    local internal = LoadCopy().Internal
    return type(internal) == "table" and SortedKeys(internal) or {}
end, internalKeys)

-- With a tab registered and the window made (a stand-in for its frame), the window and the state it shows join
-- lib.Internal (Frame, Shared), and lib keeps its keys
Names("S6.window", "the keys on lib and on lib.Internal once the window is made", function()
    local lib = LoadCopy()
    h.StandInWindows(lib)
    lib.Internal.GetFrame(lib.CreateWindow(h.Config()))
    local keys = {}
    for _, key in ipairs(SortedKeys(lib)) do keys[#keys + 1] = key end
    for _, key in ipairs(SortedKeys(lib.Internal)) do keys[#keys + 1] = "Internal." .. key end
    return keys
end, libKeys .. ", " .. ((internalKeys .. ", Frame, Shared"):gsub("([%w_]+)", "Internal.%1")))