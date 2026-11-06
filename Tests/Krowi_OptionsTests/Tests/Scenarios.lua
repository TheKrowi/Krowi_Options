--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The frame-free checks of the library's internals, which Krowi_AchievementFilter's options suite ran on KAF's own tab
-- (KAF's Tests/Options.lua, the B scenarios), here on the fixture tab (Fixtures.lua). They draw nothing, so the same
-- scenarios run in game (/kotest, before the live steps) and headless (Headless.lua, on the harness of Tests/headless),
-- and their lines can be compared one for one (Read-GameTests.ps1).
-- A scenario is { Name, Observe() -> value | nil, reason, Recorded, Target }, as KAF's: Recorded is the behaviour of the
-- current code (verified by running it), Target the wanted one; it passes while the code behaves as recorded, and one
-- whose Recorded differs from Target is an open defect. Where KAF's line held KAF's own labels, the fixture's take their
-- place and the behaviour under test stays the same (each scenario's comment).
-- In game another addon's tab (KAF's) may be registered too: the lines name the fixture's tabs only, so they are the
-- same with and without it.

local _, addon = ...
addon.Tests = addon.Tests or {}
local tests = addon.Tests
local fixtures = tests.Fixtures

local function Lib()
    return KROWI_LIBMAN:GetLibrary("Krowi_Options_2")
end

-- The library's internals: lib.Internal, or lib itself on a copy from before they moved there (a consumer's older
-- embedded copy can be the one under test)
local function Internal(lib)
    lib = lib or Lib()
    return lib.Internal or lib
end

local function Join(list)
    return #list == 0 and "none" or table.concat(list, ",")
end

local function IsFixtureTab(tab)
    return tab ~= nil and (tab == fixtures.Tab or tab == fixtures.SecondTab)
end

-- The window's tabs that this addon registered, in the registry's order (docs/work/2026-10-30-options-settings-look in KAF)
local function TabNames(lib)
    local names = {}
    for _, tab in ipairs(Internal(lib).Tabs) do
        if IsFixtureTab(tab) then names[#names + 1] = tab.Config.TabName end
    end
    return Join(names)
end

local function GroupNames(groups)
    local names = {}
    for _, group in ipairs(groups) do
        if IsFixtureTab(group.Tab) then names[#names + 1] = group.Tab.Config.TabName end
    end
    return Join(names)
end

-- A second addon's tab, registered for the scenario and taken away again: the tab order, the window's state that every
-- addon keeps (the whole saved.Window block written to each one's saved table, each its own copy with the same change
-- time; docs/work/2026-11-05-contract-and-errors), and a search of the open tab or of every tab
local function SecondTab(lib)
    local saved = {}
    local tab = lib.CreateWindow(fixtures.SecondConfig(saved))
    fixtures.SecondTab = tab
    local ok, line = pcall(function()
        local tabs = TabNames(lib)
        Internal(lib).SetShared("TestShared", true)
        local main = fixtures.Tab:GetSaved()
        local mainBlock, secondBlock = main.Window or {}, saved.Window or {}
        local same = mainBlock.TestShared and secondBlock.TestShared and mainBlock.Changed == secondBlock.Changed and mainBlock ~= secondBlock
        local shared = same and "both" or ("main=" .. tostring(mainBlock.TestShared) .. ",second=" .. tostring(secondBlock.TestShared))
        Internal(lib).SetShared("TestShared", nil)
        local open = GroupNames(Internal(lib).Search("Tooltip", false, tab))
        local all = GroupNames(Internal(lib).Search("Tooltip", true, tab))
        return ("tabs=%s shared=%s open=%s all=%s"):format(tabs, shared, open, all)
    end)
    tab:Unregister()
    local after = TabNames(lib)
    fixtures.SecondTab = nil
    if not ok then error(line, 0) end
    return line .. " after=" .. after
end

-- Where a row's name and controls stand, as x from the row's left, in the right-hand column
-- (docs/work/2026-11-02-options-widths), on the game's 635 rows and the 619 left while the section list shows its scroll
-- bar; the name's left at indent 0 and 1
local rowControls = { "Toggle", "Range", "Select", "Execute", "Input", "Key", "Sub", "TabArrows" }
local function RowGeometryLine(lib)
    local internal = Internal(lib)
    local parts = {}
    for _, width in ipairs({ 635, 619 }) do
        local flat, indented = internal.RowGeometry(0), internal.RowGeometry(1)
        local line = { ("name %g/%g-%g"):format(internal.RowX(flat.NameLeft, width), internal.RowX(indented.NameLeft, width),
            internal.RowX(flat.NameRight, width)) }
        for _, key in ipairs(rowControls) do line[#line + 1] = ("%s %g"):format(key, internal.RowX(flat[key], width)) end
        parts[#parts + 1] = ("column %d [%s]"):format(width, table.concat(line, " "))
    end
    return table.concat(parts, " ")
end

-- A card's width on the game's 635 rows and the 619 left while the section list shows its scroll bar, and the part of a
-- help picture its picture area shows: a wide one (cut at its right) and a tall one (at its bottom), and a square whose
-- own part is its bottom (Fixtures.lua's pictures, at the sizes of KAF's NewTabs and CategoryTree)
local function CardGeometryLine(lib)
    local internal = Internal(lib)
    local pictures = fixtures.Pictures
    local parts = { ("width %g/%g"):format(internal.CardWidth(635), internal.CardWidth(619)) }
    for _, name in ipairs({ "Wide", "Tall" }) do
        parts[#parts + 1] = ("%s %.5f,%.5f,%.5f,%.5f"):format(name, internal.CardCrop(pictures[name], internal.CardWidth(635)))
    end
    parts[#parts + 1] = ("Bottom %.5f,%.5f,%.5f,%.5f"):format(internal.CardCrop(pictures.Square, internal.CardWidth(635)))
    return table.concat(parts, " ")
end

-- A search of the fixture tab (docs/work/2026-11-03-blizzard-search), a result per row in the order shown:
-- "Section>Heading>Name", a row with no heading "Section>Name"
local function SearchRows(text, broad)
    local rows = {}
    for _, group in ipairs(Internal().Search(text, false, fixtures.Tab, broad)) do
        for _, section in ipairs(group.Sections) do
            for _, row in ipairs(section.Rows) do
                local name = row.Option and row.Option:GetLabel() or row.Kind == "GridHeader" and "(columns)"
                    or row.Item and row.Item.Show and row.Item.Show:GetLabel() or row.Text or row.Label
                rows[#rows + 1] = section.Name .. ">" .. (row.Heading and row.Heading ~= "" and (row.Heading .. ">") or "") .. tostring(name)
            end
        end
    end
    return rows
end

-- Observe: a function returning the line's value, or nil and the reason it could not run
tests.Scenarios = {
    -- One window for every addon, a tab each (docs/work/2026-10-30-options-settings-look): the library half of KAF's
    -- window-tabs, its registry holding the tab this addon registered; KAF keeps the half that names its own tab
    {Name = "window-tabs",
        Observe = function()
            local lib = Lib()
            if not Internal(lib).Tabs then return "no tab registry" end
            return "tabs=" .. TabNames(lib)
        end,
        Recorded = "tabs=Options Test", -- KAF: "tabs=Achievement Filter"
        Target = "tabs=Options Test"},
    -- KAF's "Zz Test" sorted after KAF's tab, so the order was never at stake; "Aa Test" sorts before the fixture's tab, so
    -- the registry's sort shows. "Tooltip" stands in a name on both tabs, as on KAF's and its Zz Test.
    {Name = "window-second-tab",
        Observe = function()
            local lib = Lib()
            if not Internal(lib).Tabs then return "no tab registry" end
            return SecondTab(lib)
        end,
        -- KAF: "tabs=Achievement Filter,Zz Test shared=both open=Zz Test all=Achievement Filter,Zz Test after=Achievement Filter"
        Recorded = "tabs=Aa Test,Options Test shared=both open=Aa Test all=Aa Test,Options Test after=Options Test",
        Target = "tabs=Aa Test,Options Test shared=both open=Aa Test all=Aa Test,Options Test after=Options Test"},
    -- The game's Options window's sizes (docs/work/2026-11-02-options-widths): its width with the help pane added
    {Name = "window-width",
        Observe = function()
            local internal = Internal()
            if not internal.WindowWidth then return "resizable from 1000x560" end
            return ("open=%d collapsed=%d"):format(internal.WindowWidth(false), internal.WindowWidth(true))
        end,
        Recorded = "open=1300 collapsed=950",
        Target = "open=1300 collapsed=950"},
    -- The window's texts come from the library's own locale files (docs/work/2026-11-04-krowi-options-library); KAF keeps
    -- the half that its config passes none (config=no)
    {Name = "library-strings",
        Observe = function()
            local lib = Lib()
            if not lib.GetStrings then return "no strings of its own" end
            local count, empty = 0, 0
            for _, text in next, lib.GetStrings() do
                count = count + 1
                if type(text) ~= "string" or text == "" then empty = empty + 1 end
            end
            return ("strings=%d empty=%d"):format(count, empty)
        end,
        Recorded = "strings=22 empty=0", -- KAF: "strings=22 empty=0 config=no"
        Target = "strings=22 empty=0"},
    -- No global but the window's name, so a second copy embedded by another addon finds nothing to collide with. Before
    -- the window is made only: once it is, Blizzard's templates name its children after it (live step
    -- library-globals-window), so a second /kotest in the same session skips this
    {Name = "library-globals",
        Observe = function()
            local lib = Lib()
            if Internal(lib).Frame then return nil, "the window is made already (a run since the last /reload): library-globals-window covers it" end
            local found = {}
            for name in next, _G do
                if type(name) == "string" and name:find("^Krowi_Options") and name ~= lib.WindowName then
                    found[#found + 1] = name
                end
            end
            table.sort(found)
            return #found == 0 and "none" or table.concat(found, ",")
        end,
        Recorded = "none",
        Target = "none"},
    {Name = "row-geometry",
        Observe = function()
            local lib = Lib()
            if not Internal(lib).RowGeometry then return "column 300 from the right, names from 16" end
            return RowGeometryLine(lib)
        end,
        Recorded = "column 635 [name 16/36-293 Toggle 305 Range 305 Select 323.5 Execute 305 Input 311 Key 305 Sub 305 TabArrows 305]"
            .. " column 619 [name 16/36-277 Toggle 289 Range 289 Select 307.5 Execute 289 Input 295 Key 289 Sub 289 TabArrows 289]",
        Target = "column 635 [name 16/36-293 Toggle 305 Range 305 Select 323.5 Execute 305 Input 311 Key 305 Sub 305 TabArrows 305]"
            .. " column 619 [name 16/36-277 Toggle 289 Range 289 Select 307.5 Execute 289 Input 295 Key 289 Sub 289 TabArrows 289]"},
    -- A button that belongs to a check box is found as its check box's row: the three check boxes first, by their buttons'
    -- whole text, then the names holding only "reset" or "position" (each word counts as the game's search counts it)
    {Name = "search-reset-position",
        Observe = function()
            local labels = {}
            for _, row in ipairs(SearchRows("Reset position")) do
                labels[#labels + 1] = row:match("([^>]+)$")
            end
            return Join(labels)
        end,
        -- KAF: "Remember Achievement Window position,Remember Achievement Calendar position,Remember Data Manager position,"
        --     .. "Calendar button: horizontal position,Calendar button: vertical position,Reset view on open,..."
        Recorded = "Remember main window position,Remember calendar position,Remember log position,"
            .. "Button: horizontal position,Button: vertical position,Reset view on open,Reset everything",
        Target = "Remember main window position,Remember calendar position,Remember log position,"
            .. "Button: horizontal position,Button: vertical position,Reset view on open,Reset everything"},
    -- The game's search finds options by their name only; the broad search adds their descriptions, not the sections'
    -- explanations (the window's help holds "lantern" too). A found family member brings its All / None heading.
    {Name = "search-names",
        Observe = function()
            return ("names=%d broad=%s"):format(#SearchRows("lantern", false), table.concat(SearchRows("lantern", true), "; "))
        end,
        -- KAF: "names=0 broad=Event reminders>Reminders>Enable; Event reminders>Pop up position>Position applies to; ..."
        Recorded = "names=0 broad=Window>General>Use the old look; Debug>Output>Verbose mode; Events>Seasons>All seasons; Events>Seasons>Spring",
        Target = "names=0 broad=Window>General>Use the old look; Debug>Output>Verbose mode; Events>Seasons>All seasons; Events>Seasons>Spring"},
    -- A name that only means something under its heading shows that heading above it (option A)
    {Name = "search-headings",
        Observe = function() return table.concat(SearchRows("loaded"), "; ") end,
        -- KAF: "Other addons>Achievements Tab Fixes>Loaded; Other addons>Better Wardrobe>Loaded; ..."
        Recorded = "Other addons>Alpha UI>Loaded; Other addons>Beta Bars>Loaded; Other addons>Gamma Maps>Loaded",
        Target = "Other addons>Alpha UI>Loaded; Other addons>Beta Bars>Loaded; Other addons>Gamma Maps>Loaded"},
    -- A found row that hangs under another (a smaller indent above it) brings that one along, above it, as the game's
    -- search does
    {Name = "search-parent",
        Observe = function() return table.concat(SearchRows("reverse"), "; ") end,
        -- KAF: "Tooltips>Achievement points tooltip>Sort priority 1; Tooltips>Achievement points tooltip>Reverse Sort; ..." (five)
        Recorded = "Tooltips>Points tooltip>Sort priority 1; Tooltips>Points tooltip>Reverse sort;"
            .. " Tooltips>Points tooltip>Sort priority 2; Tooltips>Points tooltip>Reverse sort;"
            .. " Tooltips>Points tooltip>Sort priority 3; Tooltips>Points tooltip>Reverse sort",
        Target = "Tooltips>Points tooltip>Sort priority 1; Tooltips>Points tooltip>Reverse sort;"
            .. " Tooltips>Points tooltip>Sort priority 2; Tooltips>Points tooltip>Reverse sort;"
            .. " Tooltips>Points tooltip>Sort priority 3; Tooltips>Points tooltip>Reverse sort"},
    -- A child option comes with its parent (GetParent) also when a heading stands between them on the page
    {Name = "search-parent-heading",
        Observe = function()
            local rows = {}
            for _, row in ipairs(SearchRows("Quest is completed")) do
                if row:find("^Tooltips>") then rows[#rows + 1] = row end
            end
            return table.concat(rows, "; ")
        end,
        -- KAF: "Criteria on units>Unit tooltips>Show Criteria; Criteria on units>Show criteria if>Achievement is Completed; ..."
        Recorded = "Tooltips>Unit tooltips>Show details; Tooltips>Show details if>Quest is completed;"
            .. " Tooltips>Show details if>Quest was not done by me; Tooltips>Show details if>Step is completed",
        Target = "Tooltips>Unit tooltips>Show details; Tooltips>Show details if>Quest is completed;"
            .. " Tooltips>Show details if>Quest was not done by me; Tooltips>Show details if>Step is completed"},
    -- A found All / None heading brings every option it switches, so its buttons never switch rows the player cannot see.
    -- The library half of KAF's search-all-none (KAF's own holiday list is its half).
    {Name = "search-all-none",
        Observe = function()
            local members = 0
            for _, element in ipairs(fixtures.GetElements("events")) do
                if element.Kind == "Sub" and element.Text == "All seasons" then members = #element.Members end
            end
            local rows = SearchRows("All seasons")
            local under = 0 -- the rows under its heading; "all" finds other headings too
            local heading = rows[1] and rows[1]:match("^(.*>)[^>]+$")
            for _, row in ipairs(rows) do
                if heading and row:sub(1, #heading) == heading then under = under + 1 end
            end
            return ("%s with %d of its %d options"):format(tostring(rows[1]), under - 1, members)
        end,
        Recorded = "Events>Seasons>All seasons with 4 of its 4 options", -- KAF: "Reminder events>Holidays>All holidays with 13 of its 13 options"
        Target = "Events>Seasons>All seasons with 4 of its 4 options"},
    -- Each word counts, a row with more of them first: "Show in tooltip" before "Skin tooltip" (the game puts it after)
    {Name = "search-order",
        Observe = function()
            local names = {}
            for _, row in ipairs(SearchRows("show tooltip")) do
                local name = row:match("([^>]+)$")
                if name == "Show in tooltip" or name == "Skin tooltip" then names[#names + 1] = name end
            end
            return Join(names)
        end,
        Recorded = "Show in tooltip,Skin tooltip,Skin tooltip", -- KAF: "Show in Tooltip,Skin Tooltip,Skin Tooltip"
        Target = "Show in tooltip,Skin tooltip,Skin tooltip"},
    -- The library half of KAF's card-geometry: three cards and two 12 gaps fill the row; a picture fills the 86 high area
    -- inside the card's 1 px border, cut from its top left inside the part of its texture it fills, or from the part its
    -- card names. The same numbers as KAF's, whose NewTabs and CategoryTree the fixture's Wide and Tall copy.
    {Name = "card-geometry",
        Observe = function()
            local lib = Lib()
            if not Internal(lib).CardWidth then return "no card helpers" end
            return CardGeometryLine(lib)
        end,
        -- KAF: "width 203.667/198.333 NewTabs 0.00000,0.36838,0.00000,0.62500 CategoryTree 0.00000,0.71875,0.00000,0.15353 Bottom ..."
        Recorded = "width 203.667/198.333 Wide 0.00000,0.36838,0.00000,0.62500 Tall 0.00000,0.71875,0.00000,0.15353 Bottom 0.00000,1.00000,0.57355,1.00000",
        Target = "width 203.667/198.333 Wide 0.00000,0.36838,0.00000,0.62500 Tall 0.00000,0.71875,0.00000,0.15353 Bottom 0.00000,1.00000,0.57355,1.00000"},
}

-- Result: Name, Status (PASS = behaves as Recorded, FAIL = differs, SKIP = could not run), TargetMet, Value (what it
-- observed), Error, Line; the line is the same in game and headless
function tests.RunScenario(scenario)
    local ok, got, reason = pcall(scenario.Observe)
    if not ok then
        return { Name = scenario.Name, Status = "FAIL", TargetMet = false, Error = tostring(got),
            Line = ("options/%s: FAIL error=[%s]"):format(scenario.Name, tostring(got)) }
    end
    if got == nil then
        return { Name = scenario.Name, Status = "SKIP", Line = ("options/%s: SKIP %s"):format(scenario.Name, reason or "could not run") }
    end
    local status = got == scenario.Recorded and "PASS" or "FAIL"
    local targetMet = got == scenario.Target
    return {
        Name = scenario.Name,
        Status = status,
        TargetMet = targetMet,
        Value = got,
        Line = ("options/%s: %s got=[%s] target=[%s] %s"):format(scenario.Name, status, got, scenario.Target, targetMet and "met" or "open")
    }
end

function tests.RunScenarios()
    local results = {}
    for _, scenario in ipairs(tests.Scenarios) do
        results[#results + 1] = tests.RunScenario(scenario)
    end
    return results
end