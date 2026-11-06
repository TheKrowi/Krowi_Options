--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- [[ Game only: the window itself ]] --
-- The live steps of Krowi_AchievementFilter's options suite on the library's internals (KAF's Tests/Options.lua, the B
-- steps), on the fixture tab (Fixtures.lua), the /kevutest way (Krowi_ExtendedVendorUI): each step sets a state through
-- the window's own functions, names itself in a banner over the window, checks what the window shows and takes a
-- screenshot, which Read-GameTests.ps1 pairs with its file. The scenarios (Scenarios.lua) run first.
--   open: the tab's Open opens the window where Landing says (the first open after a /reload also builds it)
--   library-globals-window: with the window made, no global but its name and the children Blizzard's templates name
--     after it (docs/work/2026-11-05-contract-and-errors)
--   tabs: a tab per addon that registered with the window, the fixture's selected, under the game's Options title
--   sizes: the window, its rows and its controls at the sizes of the game's Options window
--   section-<id>: Overview and every section draw their rows, and every drawn check box, slider and text box shows its
--     option's value; overview-cards, overview-cards-end: Overview's cards at its first group and at its end, each inside
--     its row, as wide as the others, with a picture or icon (docs/work/2026-11-02-overview-cards)
--   toggle, range, input: one row of each changed through its own control: the value is stored, and the changed line and
--     the footer's count follow it; toggle-reset: the toggle's row shows its arrow on enter, before the name, and the
--     arrow sets the option back (docs/work/2026-10-31-options-markers); toggle-help-follows: the help pane's Reset to
--     Default line comes and goes with a change made under the mouse, toggle-help-follows-grid the same on a grid's check
--     box; toggle-reset-clipped, the one step that needs the mouse (the kit's marker serves it, else the player's within
--     30 s): the arrow goes when the mouse leaves a row through its part scrolled out of view
--   slider-help: over a check box's slider the help explains the slider
--   greyed-help, greyed-help-collapsed: a greyed-out check box, dropdown, dropdown arrow and tab arrow still fire their
--     hover and explain their option, in the pane and in the collapsed pane's tooltip
--   search: the found options drawn as rows under their section's name (docs/work/2026-11-03-blizzard-search);
--     search-letter: from the first letter; search-pane: the pane explains the search, a hovered row with its section;
--     search-broad: Search descriptions finds a word only a description holds; search-change: a check box changed in
--     the results greys its child and the rows stay; search-confirm, -no: a question asked in the results, and No;
--     search-showif: turning Verbose mode off in the results takes its child row away, on brings it back
--   pane: the help pane collapses to its strip; close: the close button hides the window
-- /kotest <what> runs only some steps (SelectSteps, at the end of the file): a set (smoke, behaviour), a step's name, the
-- start of names (toggle, search, section), or a step's number in the banner, each with the steps it builds on and the
-- open first.
-- At the end every value the steps changed and the window's saved state (place, pane, search breadth, last section) are
-- put back, and the Lua errors of the session that name Krowi_Options are reported from BugGrabber. Combat stops the
-- run; the values go back once it ends. The run never sets a CVar.

local _, addon = ...
addon.Tests = addon.Tests or {}
local tests = addon.Tests
local fixtures = tests.Fixtures
local steps = {}
tests.Steps = steps

local settle = 1 -- a state change -> its check and screenshot
local afterShot = 1 -- a screenshot -> the next step
local mouseWait, pollEvery = 30, 0.1 -- a step that needs the player's mouse waits this long, looking this often
local toggleId = "window.centerTitle"
local rangeId = "window.indentation"
local inputId = "window.dateFormat"
local errorPattern = "Krowi_Options" -- the library's folder, and this addon's (Krowi_OptionsTests)

local live -- the run in progress
local runToken = 0 -- bumped by every stop, so a stopped run's timers do nothing
local banner
local chosenSteps

local function Lib()
    return KROWI_LIBMAN:GetLibrary("Krowi_Options_2")
end

local function Add(status, text)
    tinsert(live.Results, {
        Name = "live-" .. live.StepName,
        Status = status,
        GameOnly = true,
        Line = ("options/live-%s: %s %s"):format(live.StepName, status, text)
    })
end

local function After(seconds, func)
    local token = runToken
    C_Timer.After(seconds, function()
        if live and token == runToken then
            func()
        end
    end)
end

-- The options window by the name its library gives it (lib.WindowName)
local function Window()
    return _G[Lib().WindowName]
end

-- The page's drawn rows: the library hangs each row on a plain frame of its list, as frame.Row
-- (docs/work/2026-11-04-krowi-options-library)
local function ForEachRow(func)
    Window().PageScrollBox:ForEachFrame(function(frame)
        if frame.Row then func(frame.Row) end
    end)
end

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in next, value do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- The section that draws an option, and the option
local function FindOption(optionId)
    for _, sectionId in ipairs(fixtures.Sections) do
        for _, element in ipairs(fixtures.GetElements(sectionId)) do
            if element.Option and element.Option.Id == optionId then
                return sectionId, element.Option
            end
        end
    end
end

-- The first option whose check box carries a slider, and its section
local function FindSliderPair()
    for _, sectionId in ipairs(fixtures.Sections) do
        for _, element in ipairs(fixtures.GetElements(sectionId)) do
            if element.With and element.With.Type == "range" and not element.Option:IsHidden() then
                return sectionId, element.Option
            end
        end
    end
end

-- The drawn row of an option on the current page
local function RowOf(option)
    local found
    ForEachRow(function(row)
        if row.Option == option then
            found = row
        end
    end)
    return found
end

-- The first value change of an option keeps its value, which Restore puts back
local function Remember(option)
    if not live.Before[option] then
        live.Before[option] = { Value = option:Get() }
    end
end

-- The game's control widths (docs/work/2026-11-02-options-widths), by the row's key; the dropdown's is inside Select
local controlWidths = { Toggle = 30, Range = 250, Execute = 200, Key1 = 160, Key2 = 160 }
local rowControlKeys = { "Toggle", "Range", "Execute", "Input", "Key1", "Key2", "All", "None", "Up", "Down" }

-- How far a name's text reaches, whatever its anchors: a sub row's text spans the row
local function NameEnd(name)
    return name:GetLeft() + math.min(name:GetStringWidth(), name:GetWidth())
end

-- Where a drawn row breaks the layout: a control of the wrong width, one past the row's right edge, a name's text that
-- runs into the first control, a dropdown whose left arrow is off the check boxes' line (the game's stands 2.5 in from
-- it); and whether the name is cut short
local function RowLayout(row)
    local right = row:GetRight()
    if not right then
        return nil
    end
    local wrong, firstLeft = {}, nil
    if row.Geometry and row.Select and row.Select:IsShown() then
        local line = row:GetLeft() + Lib().RowX(row.Geometry.Toggle, row:GetWidth())
        if math.abs(row.Select.DecrementButton:GetLeft() - line - 2.5) > 0.5 then
            tinsert(wrong, ("arrow %g from the check boxes' line"):format(row.Select.DecrementButton:GetLeft() - line))
        end
    end
    -- The option after a check box 5 after it, as the game's Tutorials and Mouse Sensitivity rows
    local withControl = row.With and (row.With.Type == "range" and row.Range or row.Execute)
    if withControl and withControl:IsShown() and math.abs(withControl:GetLeft() - row.Toggle:GetRight() - 5) > 0.5 then
        tinsert(wrong, ("%s %g after its check box"):format(row.With.Type, withControl:GetLeft() - row.Toggle:GetRight()))
    end
    local function Control(key, control, width)
        if not control or not control:IsShown() or not control:GetRight() then
            return
        end
        if width and math.abs(control:GetWidth() - width) > 0.5 then
            tinsert(wrong, ("%s %g wide"):format(key, control:GetWidth()))
        end
        if control:GetRight() > right + 0.5 then
            tinsert(wrong, key .. " past the row's edge")
        end
        firstLeft = math.min(firstLeft or control:GetLeft(), control:GetLeft())
    end
    for _, key in ipairs(rowControlKeys) do
        -- the game's slider after a check box is 214 (SettingsCheckboxSliderControlMixin)
        Control(key, row[key], key == "Range" and withControl == row.Range and 214 or controlWidths[key])
    end
    if row.Select and row.Select:IsShown() then
        Control("Dropdown", row.Select.Dropdown, 220)
        Control("arrow", row.Select.DecrementButton)
        Control("arrow", row.Select.IncrementButton)
    end
    local name = row.Source and row.Source:GetText() ~= "" and row.Source or row.Label or row.Text
    local cut = false
    if name and name:IsShown() and name:GetLeft() and firstLeft and not row.Cells then
        if NameEnd(name) > firstLeft + 0.5 then
            tinsert(wrong, "name into the control")
        end
        cut = name.IsTruncated and name:IsTruncated() or false
    end
    return wrong, cut
end

-- The slider moves in whole steps: a value saved between them shows on the nearest step
local function SliderShows(row, option)
    local value = option:Get()
    local min, max, step = option:GetRange()
    if value and step and step > 0 then
        value = math.min(math.max(min + math.floor((value - min) / step + 0.5) * step, min), max)
    end
    return value == nil or math.abs(row.Range.Slider:GetValue() - value) < 0.001
end

-- Drawn rows whose control does not show its option's value, rows that break the layout, and names cut short
local function CheckDrawnRows()
    local drawn, differ, misfit, cut = 0, {}, {}, {}
    ForEachRow(function(row)
        drawn = drawn + 1
        local wrong, isCut = RowLayout(row)
        local id = row.Option and row.Option.Id or (row.Element and (row.Element.Text or row.Element.Label)) or tostring(drawn)
        if wrong and #wrong > 0 then
            tinsert(misfit, id .. ": " .. table.concat(wrong, ", "))
        end
        if isCut then
            tinsert(cut, id)
        end
        local option = row.Option
        if not option or not option.Type then
            return
        end
        local value = option:Get()
        local shows
        if option.Type == "toggle" then
            shows = (row.Toggle:GetChecked() and true or false) == (value and true or false)
                and (not row.With or row.With.Type ~= "range" or SliderShows(row, row.With))
        elseif option.Type == "range" then
            shows = SliderShows(row, option)
        elseif option.Type == "input" then
            shows = row.Input:HasFocus() or row.Input:GetText() == tostring(value or "")
        elseif option.Type == "select" then
            -- the dropdowns never show GameTooltip from our rows (docs/work/2026-10-30-options-settings-look)
            shows = not row.Select.Dropdown:ShouldShowTooltip()
        else
            shows = true
        end
        if not shows then
            tinsert(differ, option.Id)
        end
    end)
    return drawn, differ, misfit, cut
end

local function SectionStep(sectionId, name)
    return {
        Name = "section-" .. sectionId,
        Text = name,
        Run = function()
            Window():ShowSection(sectionId)
        end,
        Check = function()
            local rows = #(Window().Elements or {})
            local drawn, differ, misfit, cut = CheckDrawnRows()
            local ok = (rows == 0 or drawn > 0) and #differ == 0 and #misfit == 0
            Add(ok and "PASS" or "FAIL", ("%d rows, %d drawn%s%s%s"):format(rows, drawn,
                #differ > 0 and (", controls that do not show their value: [" .. table.concat(differ, ",") .. "]") or "",
                #misfit > 0 and (", rows out of the layout: [" .. table.concat(misfit, "; ") .. "]") or "",
                #cut > 0 and (", names cut short: [" .. table.concat(cut, ",") .. "]") or ""))
        end
    }
end

-- Overview's drawn cards (docs/work/2026-11-02-overview-cards): as wide as the others of their row and inside it, each
-- with its picture or icon; a name or line cut short is listed without failing, as SectionStep lists names. Scroll(window)
-- shows the part of the page to check.
local function CardsStep(name, text, Scroll)
    return {
        Name = name,
        Text = text,
        Run = function()
            Window():ShowSection("overview")
            Scroll(Window())
        end,
        Check = function()
            local cards, misfit, empty, cut = 0, {}, {}, {}
            ForEachRow(function(row)
                if not row.Cards then
                    return
                end
                local width
                for _, card in ipairs(row.Cards) do
                    if card:IsShown() then
                        cards = cards + 1
                        local cardName = card.Name:GetText() or "?"
                        width = width or card:GetWidth()
                        if math.abs(card:GetWidth() - width) > 0.5 or card:GetLeft() < row:GetLeft() - 0.5 or card:GetRight() > row:GetRight() + 0.5 then
                            tinsert(misfit, cardName)
                        end
                        if not (card.Picture:IsShown() and card.Picture:GetTexture() or card.Icon:IsShown() and card.Icon:GetTexture()) then
                            tinsert(empty, cardName)
                        end
                        if card.Name:IsTruncated() or card.Line:IsTruncated() then
                            tinsert(cut, cardName)
                        end
                    end
                end
            end)
            local ok = cards > 0 and #misfit == 0 and #empty == 0
            Add(ok and "PASS" or "FAIL", ("%d cards drawn%s%s%s"):format(cards,
                #misfit > 0 and (", out of their row: [" .. table.concat(misfit, ",") .. "]") or "",
                #empty > 0 and (", without a picture or icon: [" .. table.concat(empty, ",") .. "]") or "",
                #cut > 0 and (", text cut short: [" .. table.concat(cut, ",") .. "]") or ""))
        end
    }
end

local function ScrollToFirstCards(frame)
    for index, element in ipairs(frame.Elements or {}) do
        if element.Kind == "CardRow" then
            frame.PageScrollBox:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignBegin, nil, ScrollBoxConstants.NoScrollInterpolation)
            return
        end
    end
end

local function ScrollToEnd(frame)
    frame.PageScrollBox:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation)
end

-- The footer names the section's changed options
local function FooterAgrees(sectionId)
    local window = Window()
    local count = fixtures.ChangedCount(sectionId)
    local expected = count > 0 and window.Strings.ChangedCount:format(count) or ""
    return (window.ChangedText:GetText() or "") == expected, count
end

-- Shows the option's section scrolled to it, then changes it through its row's control in Change(row, option)
local function ChangeSteps(kind, optionId, Change)
    local sectionId, option
    return {
        Name = kind .. "-shown",
        Text = ("the %s row to change"):format(kind),
        Run = function()
            sectionId, option = FindOption(optionId)
            if not option then
                return optionId .. " is in no section"
            end
            Window():ShowSection(sectionId, optionId)
        end,
        Check = function()
            Add(RowOf(option) and "PASS" or "FAIL", ("%s is drawn in %s"):format(optionId, sectionId))
        end
    }, {
        Name = kind,
        Needs = kind .. "-shown",
        Text = ("a %s changed through its own control"):format(kind),
        Run = function()
            local row = option and RowOf(option)
            if not row then
                return "its row is not drawn"
            end
            Remember(option)
            Change(row, option)
        end,
        Check = function()
            local row = RowOf(option)
            local stored = option:Get() ~= live.Before[option].Value
            local line = row and row.ChangedBar:IsShown() == option:IsChanged()
            local footer, count = FooterAgrees(sectionId)
            Add(stored and line and footer and "PASS" or "FAIL", ("%s: %s -> %s, changed line %s, footer %s (%d changed)"):format(optionId,
                tostring(live.Before[option].Value), tostring(option:Get()), line and "follows" or "wrong", footer and "follows" or "wrong", count))
        end
    }
end

-- The arrow on a changed row sets its option back to the default (docs/work/2026-10-31-options-markers). A test does not
-- move the mouse, so the step runs the row's own enter and leave and the arrow's click. An option still at its default
-- is changed through its control first. The arrow is hidden away from the mouse, shows on enter with its atlas in the
-- margin before the name, and its click sets the option back and takes the line away.
local function ResetStep(kind, optionId, Change)
    local sectionId, option, arrow
    return {
        Name = kind .. "-reset",
        Needs = kind .. "-shown",
        Text = ("the %s set back by its row's arrow"):format(kind),
        Run = function()
            sectionId, option = FindOption(optionId)
            local row = option and RowOf(option)
            if not row then
                return "its row is not drawn"
            end
            Remember(option)
            if not option:IsChanged() then
                Change(row, option)
            end
            local reset = row.Reset
            local hiddenAway = row:IsMouseOver() or not reset:IsShown()
            row:OnEnter()
            local texture = reset:GetNormalTexture()
            arrow = {
                Hidden = hiddenAway,
                Shown = reset:IsShown(),
                Atlas = texture and texture:GetAtlas() == "common-icon-undo" or false,
                Margin = (reset:GetLeft() or -1) >= (row:GetLeft() or 0) and (reset:GetRight() or 1e9) <= (row.Label:GetLeft() or 0) + 0.5,
            }
            reset:GetScript("OnClick")(reset, "LeftButton")
            row:OnLeave()
        end,
        Check = function()
            local row = RowOf(option)
            local back = not option:IsChanged()
            local line = row and not row.ChangedBar:IsShown()
            local shows = arrow.Hidden and arrow.Shown and arrow.Atlas and arrow.Margin
            local footer, count = FooterAgrees(sectionId)
            Add(back and line and shows and footer and "PASS" or "FAIL", ("%s: %s, changed line %s, arrow %s, footer %s (%d changed)"):format(optionId,
                back and "back at its default" or "still changed", line and "gone" or "still shown",
                shows and "hidden away from the mouse and shown on enter before the name" or ("wrong (hidden away %s, shown on enter %s, atlas %s, in the margin %s)"):format(
                    tostring(arrow.Hidden), tostring(arrow.Shown), tostring(arrow.Atlas), tostring(arrow.Margin)),
                footer and "follows" or "wrong", count))
        end
    }
end

-- Whether the help pane holds the arrow's line, "Reset to Default"
local function HelpHasReset()
    local provider = Window().HelpScrollBox:GetDataProvider()
    for i = 1, provider and provider:GetSize() or 0 do
        local data = provider:Find(i)
        if type(data) == "table" and type(data.Text) == "string" and data.Text:find(RESET_TO_DEFAULT, 1, true) then
            return true
        end
    end
    return false
end

-- The help pane follows a change made under the mouse (from the markers review, docs/work/2026-11-04-krowi-options-library):
-- the row's enter is played, the option changed through its check box and set back, and before and after each change the
-- pane is read for the arrow's line, which shows exactly while the option is changed
local function HelpFollowsStep(optionId)
    local seen
    return {
        Name = "toggle-help-follows",
        Needs = "toggle-shown",
        Text = "the help pane follows a change made under the mouse",
        Run = function()
            local _, option = FindOption(optionId)
            local row = option and RowOf(option)
            if not row then
                return "its row is not drawn"
            end
            Remember(option)
            row:OnEnter()
            seen = { Was = option:IsChanged(), Before = HelpHasReset() }
            row.Toggle:Click()
            seen.Changed, seen.AfterChange = option:IsChanged(), HelpHasReset()
            row.Toggle:Click()
            seen.Back, seen.AfterBack = option:IsChanged(), HelpHasReset()
            row:OnLeave()
        end,
        Check = function()
            local follows = seen.Before == seen.Was and seen.AfterChange == seen.Changed and seen.AfterBack == seen.Back
            Add(follows and "PASS" or "FAIL", ("%s: the Reset to Default line %s before (changed %s), %s after the change (changed %s), %s after setting it back (changed %s)"):format(
                optionId, seen.Before and "shows" or "is absent", tostring(seen.Was), seen.AfterChange and "shows" or "is absent", tostring(seen.Changed),
                seen.AfterBack and "shows" or "is absent", tostring(seen.Back)))
        end
    }
end

-- The same on a grid's check box (from the code review of Krowi_Options 2.0): a grid row holds its options in its
-- element, not as the row's Option, and the help did not follow a change there. The first grid row of Events with a
-- check box that can be changed.
local function GridHelpFollowsStep()
    local seen
    return {
        Name = "toggle-help-follows-grid",
        Text = "the help pane follows a change in a grid made under the mouse",
        Run = function()
            Window():ShowSection("events")
            local row, column
            ForEachRow(function(candidate)
                local element = candidate.Element
                if row or not element or element.Kind ~= "GridRow" then
                    return
                end
                for i, option in ipairs(element.Cells) do
                    if not row and not option:IsDisabled() then
                        row, column = candidate, i
                    end
                end
            end)
            if not row then
                return "no grid check box to change in events"
            end
            local option = row.Element.Cells[column]
            Remember(option)
            row:OnEnter(column)
            seen = { Id = option.Id, Was = option:IsChanged(), Before = HelpHasReset() }
            row.Cells[column]:Click()
            seen.Changed, seen.AfterChange = option:IsChanged(), HelpHasReset()
            row.Cells[column]:Click()
            seen.Back, seen.AfterBack = option:IsChanged(), HelpHasReset()
            row:OnLeave()
        end,
        Check = function()
            local follows = seen.Before == seen.Was and seen.AfterChange == seen.Changed and seen.AfterBack == seen.Back
            Add(follows and "PASS" or "FAIL", ("%s: the Reset to Default line %s before (changed %s), %s after the change (changed %s), %s after setting it back (changed %s)"):format(
                seen.Id, seen.Before and "shows" or "is absent", tostring(seen.Was), seen.AfterChange and "shows" or "is absent", tostring(seen.Changed),
                seen.AfterBack and "shows" or "is absent", tostring(seen.Back)))
        end
    }
end

-- The undo arrow goes when the mouse leaves a row through its part scrolled out of view (from the markers review): the
-- last plain check box of the longest section that has one (the fixture's Tooltips) is changed and scrolled half below
-- the list's bottom edge, the player (or the kit's marker) hovers it and moves straight down off the list, and the step
-- reads the arrow once the mouse is on the hidden half
local function ClippedResetStep()
    local option, hovered
    return {
        Name = "toggle-reset-clipped",
        Text = ("hover the half-shown row at the list's bottom, then move straight down off the list (%d s)"):format(mouseWait),
        Run = function()
            local frame = Window()
            local sections = {}
            for _, sectionId in ipairs(fixtures.Sections) do
                tinsert(sections, { Id = sectionId, Count = #fixtures.GetElements(sectionId) })
            end
            table.sort(sections, function(a, b) return a.Count > b.Count end)
            local index
            for _, entry in ipairs(sections) do
                frame:ShowSection(entry.Id)
                for i, element in ipairs(frame.Elements or {}) do
                    local o = element.Option
                    if o and o.Type == "toggle" and not element.With and not o:IsDisabled() and not (o.GetNeedsReload and o:GetNeedsReload()) then
                        option, index = o, i
                    end
                end
                if option then
                    break
                end
            end
            if not option then
                return "no section has a plain check box"
            end
            local box = frame.PageScrollBox
            box:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignEnd, nil, ScrollBoxConstants.NoScrollInterpolation)
            local row = RowOf(option)
            if not row then
                return "its row is not drawn"
            end
            box:ScrollToOffset(box:GetDerivedScrollOffset() - row:GetHeight() / 2, ScrollBoxConstants.NoScrollInterpolation)
            Remember(option)
            if not option:IsChanged() then
                row.Toggle:Click()
            end
            hovered = false
        end,
        -- For the kit: the visible half of the row inside the list, then its hidden half below the list's bottom edge
        Hover = function(kit)
            local row = RowOf(option)
            if row then
                kit.HoverAt(row, 0, (hovered and -1 or 1) * row:GetHeight() / 4)
            end
        end,
        -- First the mouse on the row inside the list, then on the row's part below the list
        Mouse = function()
            local row = RowOf(option)
            if not row then
                return false
            end
            local inList = Window().PageScrollBox:IsMouseOver()
            if row:IsMouseOver() and inList then
                hovered = true
            end
            return hovered and row:IsMouseOver() and not inList
        end,
        Check = function()
            local row = RowOf(option)
            local shown = row and row.Reset:IsShown()
            Add(row and not shown and "PASS" or "FAIL", ("%s: with the mouse on the row's hidden half the arrow is %s"):format(option.Id,
                not row and "not drawn" or shown and "still shown" or "gone"))
        end
    }
end

-- The search as the game's Options window searches (docs/work/2026-11-03-blizzard-search), through the window's own
-- functions: the rows it draws, from the first letter, the help pane beside them, the broad search, a change made in the
-- results, a question asked there, and a row that a change in them hides
local tabPriorityId = "debug.tabPriority"
local tabPriorityChildId = "debug.priorityOrder"
local debugId = "debug.verbose"
local traceId = "debug.trace"
local testQuestion = "Krowi_Options test question?"

-- As the player types it
local function Search(text)
    local frame = Window()
    frame.SearchBox:SetText(text)
    frame:OnSearch(text)
end

-- Through its check box, as the player ticks it
local function SetBroad(on)
    local frame = Window()
    if (frame.BroadSearch and true or false) ~= on then frame.SearchBroad:Click() end
end

local function Kinds()
    local kinds = {}
    for _, element in ipairs(Window().Elements or {}) do kinds[element.Kind] = (kinds[element.Kind] or 0) + 1 end
    return kinds
end

local function InResults(option)
    for _, element in ipairs(Window().Elements or {}) do
        if element.Option == option then return true end
    end
    return false
end

local function HelpTitle()
    local provider = Window().HelpScrollBox:GetDataProvider()
    local first = provider and provider:Find(1)
    return first and first.Text
end

-- A word of an option's description that no option's name holds, so only the broad search finds it
local function DescriptionOnlyWord()
    local lib = Lib()
    for _, optionId in ipairs({ toggleId, rangeId, tabPriorityId }) do
        local _, option = FindOption(optionId)
        for word in (option and option:GetDescription() or ""):gmatch("[^%s%p]+") do
            if #word >= 5 and #lib.Search(word, false, fixtures.Tab, false) == 0 and #lib.Search(word, false, fixtures.Tab, true) > 0 then return word end
        end
    end
end

local function SearchSteps()
    local searchText, pane, broad, change, confirm, showIf
    return {
        {
            Name = "search",
            Text = "a search draws the found options as rows under their section's name",
            Run = function()
                SetBroad(false)
                local _, option = FindOption(toggleId)
                searchText = option and option:GetLabel():match("^(%S+)") or "a"
                Search(searchText)
            end,
            Check = function()
                local frame = Window()
                local kinds = Kinds()
                local first = frame.Elements and frame.Elements[1]
                local drawn, differ, misfit = CheckDrawnRows()
                local ok = frame.Searching and (kinds.Option or 0) > 0 and (kinds.SearchHeading or 0) > 0 and not kinds.Link and first
                    and (first.Kind == "SearchHeading" or first.Kind == "Header") and not frame.DefaultsButton:IsShown() and #differ == 0 and #misfit == 0
                Add(ok and "PASS" or "FAIL", ("'%s': %d rows under %d section names, %d links, Defaults %s, %d drawn%s%s"):format(searchText,
                    kinds.Option or 0, kinds.SearchHeading or 0, kinds.Link or 0, frame.DefaultsButton:IsShown() and "shown" or "hidden", drawn,
                    #differ > 0 and (", controls that do not show their value: [" .. table.concat(differ, ",") .. "]") or "",
                    #misfit > 0 and (", rows out of the layout: [" .. table.concat(misfit, "; ") .. "]") or ""))
            end
        },
        {
            Name = "search-letter",
            Needs = "search",
            Text = "one letter already searches, as the game's",
            Run = function()
                searchText = searchText:match("^[%z\1-\127\194-\244][\128-\191]*") -- one letter, also when it takes several bytes
                Search(searchText)
            end,
            Check = function()
                local kinds = Kinds()
                Add(Window().Searching and (kinds.Option or 0) > 0 and "PASS" or "FAIL", ("'%s' finds %d rows in %d sections"):format(searchText,
                    kinds.Option or 0, kinds.SearchHeading or 0))
            end
        },
        {
            Name = "search-pane",
            Text = "the help pane explains the search, and a hovered row with its own section",
            Run = function()
                local frame = Window()
                if frame.PaneCollapsed then frame:SetPaneCollapsed(false) end
                local _, child = FindOption(tabPriorityChildId)
                Search(child:GetLabel())
                pane = { Before = HelpTitle() }
                local row = RowOf(child)
                if not row then return "its row is not drawn" end
                row:OnEnter()
                pane.Hover, pane.Kicker = frame.HoverOption == child, frame.CollapseButton.Label:GetText()
                row:OnLeave()
                pane.After = HelpTitle()
            end,
            Check = function()
                local frame = Window()
                local search, section = frame.Strings.Search, frame.Config.SectionName((FindOption(tabPriorityChildId)))
                Add(pane.Before == search and pane.Hover and pane.Kicker == section and pane.After == search and "PASS" or "FAIL",
                    ("before '%s', on the row %s under '%s' (%s expected), after '%s'"):format(tostring(pane.Before),
                        pane.Hover and "its description" or "not its description", tostring(pane.Kicker), section, tostring(pane.After)))
            end
        },
        {
            Name = "search-broad",
            Text = "Search descriptions also finds options by their description, and no section by its explanation",
            Run = function()
                local word = DescriptionOnlyWord()
                if not word then return "no word of a description that no name holds" end
                SetBroad(false)
                Search(word)
                broad = { Word = word, Names = Kinds() }
                SetBroad(true)
            end,
            Check = function()
                local frame = Window()
                local kinds = Kinds()
                local kept = (fixtures.Tab:GetSaved().Window or {}).SearchBroad == true and frame.SearchBroad:GetChecked()
                Add(not broad.Names.Option and broad.Names.Note == 1 and (kinds.Option or 0) > 0 and not kinds.Link and kept and "PASS" or "FAIL",
                    ("'%s': by name %d rows, ticked %d rows and %d links, %s"):format(broad.Word, broad.Names.Option or 0, kinds.Option or 0,
                        kinds.Link or 0, kept and "kept with the window's state" or "not kept"))
            end
        },
        {
            Name = "search-change",
            Text = "a check box changed in the results greys its child row, and the rows stay",
            Run = function()
                SetBroad(false)
                local _, parent = FindOption(tabPriorityId)
                local _, child = FindOption(tabPriorityChildId)
                Search(parent:GetLabel())
                change = { Parent = parent, Child = child, Signature = Window().Signature }
                local row = RowOf(parent)
                if not row then return "its row is not drawn" end
                Remember(parent)
                row.Toggle:Click()
            end,
            Check = function()
                local frame = Window()
                local childRow = RowOf(change.Child)
                local greyed = childRow and (childRow.Label:GetFontObject() == GameFontDisable) == change.Child:IsDisabled()
                local stored = change.Parent:Get() ~= live.Before[change.Parent].Value
                local same = frame.Signature == change.Signature
                Add(stored and greyed and same and "PASS" or "FAIL", ("%s %s, %s %s, the rows %s"):format(change.Parent:GetLabel(),
                    stored and "changed" or "not changed", change.Child:GetLabel(), greyed and "follows it" or "does not follow it",
                    same and "stayed" or "were drawn again"))
            end
        },
        {
            Name = "search-confirm",
            Needs = "search",
            Text = "a question asked in the results shows in the header",
            Run = function()
                Search(searchText)
                confirm = {}
                -- The box reports its new text a frame later, which searches again and drops a question asked before it;
                -- a player picks the choice that asks only after typing
                After(0.2, function() Window():AskConfirm(testQuestion, function() confirm.Yes = true end) end)
            end,
            Check = function()
                local frame = Window()
                local asked = frame.CancelButton:IsShown() and frame.DefaultsButton:IsShown() and frame.ChangedText:GetText() == testQuestion
                Add(asked and "PASS" or "FAIL", ("the question %s, Yes %s, No %s"):format(frame.ChangedText:GetText() == testQuestion and "shows" or "does not show",
                    frame.DefaultsButton:IsShown() and "shown" or "hidden", frame.CancelButton:IsShown() and "shown" or "hidden"))
            end
        },
        {
            Name = "search-confirm-no",
            Needs = "search-confirm",
            Text = "No ends the question and does nothing",
            Run = function()
                Window().CancelButton:Click()
            end,
            Check = function()
                local frame = Window()
                local gone = not frame.CancelButton:IsShown() and not frame.DefaultsButton:IsShown() and frame.PageTitle:IsShown()
                Add(gone and not confirm.Yes and "PASS" or "FAIL", ("the question %s, its answer %s"):format(gone and "is gone" or "stays",
                    confirm.Yes and "ran" or "did not run"))
            end
        },
        {
            Name = "search-showif",
            Text = "a row that a change in the results hides goes, and comes back",
            Run = function()
                SetBroad(false)
                local _, debug = FindOption(debugId)
                local _, trace = FindOption(traceId)
                Search(trace:GetLabel())
                showIf = { Trace = trace, Before = InResults(trace) }
                Remember(debug)
                debug:Set(false)
                Window():OnOptionChanged(debug)
                showIf.Off = InResults(trace)
                debug:Set(true)
                Window():OnOptionChanged(debug)
            end,
            Check = function()
                local back = InResults(showIf.Trace)
                Add(showIf.Before and not showIf.Off and back and "PASS" or "FAIL", ("%s: %s, with %s off %s, on again %s"):format(
                    showIf.Trace:GetLabel(), showIf.Before and "found" or "not found", fixtures.Options[debugId]:GetLabel(),
                    showIf.Off and "still there" or "gone", back and "back" or "not back"))
            end
        },
    }
end

-- A greyed-out setting still explains itself under the mouse (the code review of Krowi_Options 2.0, #8): the game runs a
-- greyed button's OnEnter only when the button asks for it (SetMotionScriptsWhileDisabled, as the game's own settings
-- check box does). A test does not move the mouse, so the steps read the flag and play the button's own enter and leave:
-- with the pane open the pane explains the option, collapsed the row's tooltip does. The cases: a check box and a
-- dropdown under a parent check box that is off (turned off for the run when it is on), and the first tab's Up arrow,
-- greyed always. Each step holds its last hover for its screenshot.
local greyedCases = {
    { Name = "check box", OptionId = "tooltips.ifCompleted", Control = function(row) return row.Toggle end },
    { Name = "dropdown", OptionId = tabPriorityChildId, Control = function(row) return row.Select.Dropdown end },
    { Name = "dropdown's arrow", OptionId = tabPriorityChildId, Control = function(row) return row.Select.IncrementButton end },
    { Name = "tab list's Up arrow", TabRow = true, Control = function(row) return row.Up end },
}

local function RowOfElement(element)
    local found
    ForEachRow(function(row)
        if row.Element == element then found = row end
    end)
    return found
end

-- Shows a case's row in view and greyed: its row, its control and the option the help names; or nil and why not. A
-- parent it turns off goes into turnedOff.
local function ShowGreyed(case, turnedOff)
    local frame = Window()
    if case.TabRow then
        for _, sectionId in ipairs(fixtures.Sections) do
            for _, element in ipairs(fixtures.GetElements(sectionId)) do
                if element.Kind == "TabList" then
                    frame:ShowSection(sectionId)
                    for index, shown in ipairs(frame.Elements or {}) do
                        if shown.Kind == "TabRow" and shown.Item.MoveUp == nil then
                            frame.PageScrollBox:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignCenter, nil, ScrollBoxConstants.NoScrollInterpolation)
                            local row = RowOfElement(shown)
                            if not row then return nil, "the first tab's row is not drawn" end
                            return row, case.Control(row), shown.Item.Show
                        end
                    end
                    return nil, "the tab list has no first tab"
                end
            end
        end
        return nil, "no section has the tab list"
    end
    local sectionId, option = FindOption(case.OptionId)
    if not option then return nil, case.OptionId .. " is in no section" end
    frame:ShowSection(sectionId, case.OptionId)
    local parent = option:GetParent()
    if parent and parent:Get() then
        Remember(parent)
        parent:Set(false)
        frame:OnOptionChanged(parent)
        tinsert(turnedOff, parent)
    end
    local row = RowOf(option)
    if not row then return nil, "its row is not drawn" end
    return row, case.Control(row), option
end

-- As the game runs it when the mouse comes onto the control or leaves it: the script and the hooks on it
local function Play(control, script)
    local handler = control:GetScript(script)
    if handler then handler(control, true) end
end

local function GreyedSteps()
    local seen, held, turnedOff = {}, nil, {}
    -- After the screenshot: the held hover ends and the parents the step turned off are on again, so the steps after it
    -- (search-change clicks Tab priority) start from the values before
    local function Release()
        if held then
            Play(held, "OnLeave")
            held = nil
        end
        for _, parent in ipairs(turnedOff) do
            parent:Set(true)
            Window():OnOptionChanged(parent)
        end
        wipe(turnedOff)
    end
    local function Measure(collapsed)
        local frame = Window()
        Release()
        if frame.PaneCollapsed ~= collapsed then frame:SetPaneCollapsed(collapsed) end
        seen = {}
        for i, case in ipairs(greyedCases) do
            local row, control, option = ShowGreyed(case, turnedOff)
            local result = { Case = case, Missing = not row and control or nil }
            if row then
                result.Label = option and option:GetLabel() or "?"
                result.Greyed = not control:IsEnabled()
                result.Asks = control:GetMotionScriptsWhileDisabled() and true or false
                Play(control, "OnEnter")
                local tooltip = frame.TooltipShown
                if collapsed then
                    result.Explains = option ~= nil and tooltip ~= nil and tooltip:IsShown() and tooltip:GetOwner() == row
                else
                    result.Explains = option ~= nil and frame.HoverOption == option
                end
                if i < #greyedCases then
                    Play(control, "OnLeave")
                    result.Ends = collapsed and not (tooltip and tooltip:IsShown()) or not collapsed and frame.HoverOption == nil
                else
                    held = control -- the last case stays hovered for the screenshot
                end
            end
            seen[i] = result
        end
    end
    local function Report(collapsed)
        for _, result in ipairs(seen) do
            if result.Missing then
                Add("SKIP", ("%s: %s"):format(result.Case.Name, result.Missing))
            else
                local ok = result.Greyed and result.Asks and result.Explains and result.Ends ~= false
                Add(ok and "PASS" or "FAIL", ("%s (%s): %s, %s, on enter %s%s"):format(result.Case.Name, result.Label,
                    result.Greyed and "greyed" or "not greyed", result.Asks and "hovers while greyed" or "no hover while greyed",
                    result.Explains and (collapsed and "its tooltip shows" or "the pane explains it") or (collapsed and "no tooltip" or "the pane does not explain it"),
                    result.Ends == false and ", and the help stays after leaving" or ""))
            end
        end
    end
    -- The screenshot is taken right after the check with the hover held; the next step starts afterShot after it
    return {
        Name = "greyed-help",
        Text = "a greyed-out check box, dropdown and arrow explain themselves under the mouse",
        Run = function() Measure(false) end,
        Check = function()
            Report(false)
            After(afterShot / 2, Release)
        end
    }, {
        Name = "greyed-help-collapsed",
        Text = "the same with the help pane collapsed: the row's tooltip",
        Run = function() Measure(true) end,
        Check = function()
            Report(true)
            After(afterShot / 2, function()
                Release()
                Window():SetPaneCollapsed(false)
            end)
        end
    }
end

local function BuildSteps()
    local list = {
        {
            Name = "open",
            Required = true,
            Text = "the tab's Open opens the window",
            Run = function()
                live.FirstOpen = Window() == nil
                live.Landing = fixtures.Tab.Config.Landing()
                if Window() then
                    Window():Hide()
                end
                fixtures.Tab:Open()
            end,
            Check = function()
                local frame = Window()
                local shown = frame and frame:IsShown()
                Add(shown and frame.SectionId == live.Landing and "PASS" or "FAIL", ("the window opens on %s, the landing section %s (first open after a /reload: %s)"):format(
                    tostring(frame and frame.SectionId), live.Landing, live.FirstOpen and "yes" or "no"))
            end
        },
        {
            -- With the window made: the globals Blizzard's templates add under the window's name ($parent), which the
            -- load-time scenario library-globals cannot see (docs/work/2026-11-05-contract-and-errors)
            Name = "library-globals-window",
            Text = "the window adds no global but its own name and its children's",
            Run = function() end,
            Check = function()
                local windowName = Lib().WindowName
                local children, others = {}, {}
                for name in next, _G do
                    if type(name) == "string" and name:find("^Krowi_Options") and name ~= windowName then
                        tinsert(name:sub(1, #windowName) == windowName and children or others, name)
                    end
                end
                table.sort(children)
                table.sort(others)
                Add(#others == 0 and "PASS" or "FAIL", ("under the window's name: %s; others: %s"):format(
                    #children > 0 and table.concat(children, ", ") or "none", #others > 0 and table.concat(others, ", ") or "none"))
            end
        },
        {
            Name = "tabs",
            Text = "a tab per addon, the fixture's selected",
            Run = function() end,
            Check = function()
                local frame = Window()
                local lib = Lib()
                local shown, selected = 0, "none"
                for _, button in ipairs(frame.TabButtons) do
                    if button:IsShown() then
                        shown = shown + 1
                        if button:IsSelected() then selected = button.Tab.Config.TabName end
                    end
                end
                local title = frame.NineSlice.Text:GetText()
                local searchAll = frame.SearchAll:IsShown()
                local ok = shown == #lib.Tabs and frame.Tab == fixtures.Tab and selected == fixtures.TabName
                    and title == SETTINGS_TITLE and searchAll == (#lib.Tabs > 1)
                Add(ok and "PASS" or "FAIL", ("%d of %d tabs shown, %s selected, title '%s', Search all tabs %s"):format(shown, #lib.Tabs, selected,
                    tostring(title), searchAll and "shown" or "hidden"))
            end
        },
        -- The game's Options window's sizes (docs/work/2026-11-02-options-widths)
        {
            Name = "sizes",
            Text = "the window, its rows and its controls at the sizes of the game's Options window",
            Run = function() end,
            Check = function()
                local frame = Window()
                local lib = Lib()
                local function Is(value, expected) return math.abs(value - expected) < 0.5 end
                local width = lib.WindowWidth(frame.PaneCollapsed)
                local minWidth, _, maxWidth = width, nil, width
                if frame.GetResizeBounds then minWidth, _, maxWidth = frame:GetResizeBounds() end
                local rows = frame.NavScrollShown and 619 or 635
                local defaults = frame.DefaultsButton
                local fitsIn96 = defaults:GetFontString():GetStringWidth() + 24 <= 96
                local ok = Is(frame:GetWidth(), width) and Is(minWidth, width) and Is(maxWidth, width) and Is(frame:PageWidth(), rows)
                    and Is(frame.SearchBox:GetWidth(), 350) and (fitsIn96 and Is(defaults:GetWidth(), 96) or not fitsIn96 and defaults:GetWidth() > 96)
                    and Is(frame.SearchAll:GetWidth(), 30) and Is(frame.SearchAll:GetHeight(), 29) and Is(frame.Divider:GetWidth(), 630)
                Add(ok and "PASS" or "FAIL", ("window %g wide (resizes from %g to %g), rows %g, search box %g, Defaults %g, check box %gx%g, divider %g, scale %.2f"):format(
                    frame:GetWidth(), minWidth, maxWidth, frame:PageWidth(), frame.SearchBox:GetWidth(), defaults:GetWidth(),
                    frame.SearchAll:GetWidth(), frame.SearchAll:GetHeight(), frame.Divider:GetWidth(), frame:GetScale()))
            end
        },
        SectionStep("overview", Lib().GetStrings().Overview),
        CardsStep("overview-cards", "Overview's first cards", ScrollToFirstCards),
        CardsStep("overview-cards-end", "Overview's last cards", ScrollToEnd)
    }
    for _, sectionId in ipairs(fixtures.Sections) do
        tinsert(list, SectionStep(sectionId, fixtures.SectionName(sectionId)))
    end
    for _, step in ipairs({ ChangeSteps("toggle", toggleId, function(row) row.Toggle:Click() end) }) do tinsert(list, step) end
    tinsert(list, ResetStep("toggle", toggleId, function(row) row.Toggle:Click() end))
    tinsert(list, HelpFollowsStep(toggleId))
    tinsert(list, GridHelpFollowsStep())
    for _, step in ipairs({ ChangeSteps("range", rangeId, function(row, option)
        local min, max = option:GetRange()
        row.Range:SetValue(option:Get() ~= min and min or max)
    end) }) do tinsert(list, step) end
    for _, step in ipairs({ ChangeSteps("input", inputId, function(row, option)
        row.Input:SetText((option:Get() or "") .. " x")
        row.Input:GetScript("OnEnterPressed")(row.Input)
    end) }) do tinsert(list, step) end
    -- Over a check box's slider the help pane explains the slider, not the check box (Krowi, 2026-11-02: KAF's Force two
    -- columns threshold, the fixture's too); the mouse's arrival on the bar is played through the row's own handler
    local pairSection, pairOption
    tinsert(list, {
        Name = "slider-help",
        Text = "a check box's slider explains itself",
        Run = function()
            local frame = Window()
            pairSection, pairOption = FindSliderPair()
            if frame.PaneCollapsed then frame:SetPaneCollapsed(false) end
            if pairSection then frame:ShowSection(pairSection, pairOption.Id) end
        end,
        Check = function()
            local row = pairOption and RowOf(pairOption)
            if not row then
                Add("FAIL", "no drawn row whose check box carries a slider")
                return
            end
            row:OnEnter(row.Range.Slider)
            local shown = Window().HoverOption
            row:OnLeave()
            Add(shown == row.With and "PASS" or "FAIL", ("over %s's slider the help explains %s"):format(pairOption:GetLabel(),
                shown and shown:GetLabel() or "the section"))
        end
    })
    for _, step in ipairs({ GreyedSteps() }) do tinsert(list, step) end
    for _, step in ipairs(SearchSteps()) do tinsert(list, step) end
    tinsert(list, ClippedResetStep())
    tinsert(list, {
        Name = "pane",
        Text = "the help pane collapsed to its strip",
        Run = function()
            local frame = Window()
            frame:ShowSection("window")
            frame:SetPaneCollapsed(not frame.PaneCollapsed)
        end,
        Check = function()
            local frame = Window()
            local agrees = frame.ExpandButton:IsShown() == frame.PaneCollapsed and frame.HelpScrollBox:IsShown() == not frame.PaneCollapsed
            -- The pane adds its own width to the game's window (docs/work/2026-11-02-options-widths)
            local width = Lib().WindowWidth(frame.PaneCollapsed)
            local wide = math.abs(frame:GetWidth() - width) < 0.5 and math.abs(frame:PageWidth() - (frame.NavScrollShown and 619 or 635)) < 0.5
            Add(agrees and wide and "PASS" or "FAIL", ("the pane is %s and shows it, the window %g wide (%g expected), rows %g"):format(
                frame.PaneCollapsed and "collapsed" or "open", frame:GetWidth(), width, frame:PageWidth()))
        end
    })
    tinsert(list, {
        Name = "close",
        Text = "the close button hides the window",
        Run = function()
            Window().CloseButton:Click()
        end,
        Check = function()
            Add(not Window():IsShown() and "PASS" or "FAIL", "the window is hidden")
        end
    })
    return list
end

-- The session's Lua errors that name the library or this addon, also from before the run (the window's first draw)
local function CheckErrors()
    if not (BugGrabber and type(BugGrabber.GetDB) == "function" and type(BugGrabber.GetSessionId) == "function") then
        tinsert(live.Observations, "no BugGrabber, so Lua errors are not checked")
        return
    end
    local session = BugGrabber:GetSessionId()
    local found = 0
    for _, err in ipairs(BugGrabber:GetDB()) do
        if err.session == session and ((type(err.message) == "string" and err.message:find(errorPattern, 1, true))
            or (type(err.stack) == "string" and err.stack:find(errorPattern, 1, true))) then
            found = found + 1
            Add("FAIL", ("Lua error x%d: %s"):format(err.counter or 1, tostring(err.message):sub(1, 300)))
        end
    end
    if found == 0 then
        Add("PASS", "no Lua error naming " .. errorPattern .. " this session (BugGrabber)")
    end
end

-- The window state every addon shares, as it stood before the run: the library's own copy and every registered addon's
-- saved block (internals, read knowingly; docs/work/2026-11-05-contract-and-errors). Restore puts them back as they
-- were, so neither this addon's table nor another's keeps the run's values or a newer change time.
local function SnapshotShared()
    local lib = Lib()
    local blocks = {}
    for _, registered in ipairs(lib.Tabs) do
        local ok, saved = pcall(registered.GetSaved, registered)
        if ok then blocks[registered] = saved.Window and DeepCopy(saved.Window) or false end
    end
    return { Shared = DeepCopy(lib.Shared), Blocks = blocks }
end

-- Every value the steps changed goes back, then the window's saved state as it was before the run
local function Restore()
    local frame = Window()
    local notBack = {}
    for option, before in next, live.Before do
        pcall(option.Set, option, before.Value)
        if option:Get() ~= before.Value then
            tinsert(notBack, option.Id)
        end
    end
    local shared = live.SharedBefore
    local before = shared.Shared or live.SavedWindow.Window or {} -- the block the window showed before the run
    if frame then
        if frame.PaneCollapsed ~= (before.PaneCollapsed and true or false) then
            frame:SetPaneCollapsed(before.PaneCollapsed and true or false)
        end
        -- The search scope and breadth the window reads, and their check boxes; the saved fields go back below
        frame.BroadSearch = before.SearchBroad and true or false
        frame.SearchBroad:SetChecked(frame.BroadSearch)
        frame.SearchEveryTab = before.SearchAll and true or false
        frame.SearchAll:SetChecked(frame.SearchEveryTab)
        local was = live.WasShown
        if was and tContains(Lib().Tabs, was.Tab) then
            frame:ShowTab(was.Tab, was.Section)
        end
    end
    local saved = fixtures.Tab:GetSaved() -- the window keeps this table, so its fields go back in place
    wipe(saved)
    for k, v in next, live.SavedWindow do
        saved[k] = v
    end
    -- The shared block: every addon's as it was, and the library's own copy, which a nil sends back to the newest of them
    for registered, block in next, shared.Blocks do
        local ok, savedTable = pcall(registered.GetSaved, registered)
        if ok then savedTable.Window = block and DeepCopy(block) or nil end
    end
    Lib().Shared = DeepCopy(shared.Shared)
    return notBack
end

local function Finish()
    banner:UnregisterAllEvents()
    live.StepName = "restore"
    local ok, notBack = pcall(Restore)
    if not ok then
        Add("FAIL", "could not put the values back: " .. tostring(notBack))
    else
        Add(#notBack == 0 and "PASS" or "FAIL", "the changed values and the window's saved state are as before the run"
            .. (#notBack > 0 and (", except [" .. table.concat(notBack, ",") .. "]") or ""))
    end
    live.StepName = "lua-errors"
    local checked, err = pcall(CheckErrors)
    if not checked then
        Add("FAIL", "test error: " .. tostring(err))
    end
    local finish, results, observations = live.Finish, live.Results, live.Observations
    live = nil
    finish(results, observations)
end

local function Stop(reason, combatStarted)
    runToken = runToken + 1
    banner:Hide()
    if reason then
        tinsert(live.Observations, "stopped: " .. reason)
    end
    if combatStarted or InCombatLockdown() then
        banner:UnregisterAllEvents()
        banner:RegisterEvent("PLAYER_REGEN_ENABLED")
        print("|cFF1D92C2Krowi_Options test:|r stopped for combat; the changed values go back when it ends")
        return
    end
    Finish()
end

local RunStep

local function Capture()
    local ok, err = pcall(chosenSteps[live.StepIndex].Check)
    if not ok then
        Add("FAIL", "test error: " .. tostring(err))
    end
    live.Shot = { Time = date("%Y-%m-%d %H:%M:%S") }
    live.Results[#live.Results].Screenshot = live.Shot
    Screenshot()
    After(afterShot, function()
        RunStep(live.StepIndex + 1)
    end)
end

-- A step that needs the player's mouse checks as soon as its Mouse() holds, or is skipped after mouseWait. While the
-- kit's marker addon is loaded (KrowiGameInput, Krowi_ClaudeKit's docs/work/2026-11-05-kit-test-runs), its Hover(kit)
-- asks the kit for the hover on every poll, so an unattended run gets it; the request is cleared once the step is over.
local function WaitForMouse(step, waited)
    local ok, ready = pcall(step.Mouse)
    if ok and ready then
        if KrowiGameInput then
            KrowiGameInput.Clear()
        end
        Capture()
        return
    end
    if not ok or waited >= mouseWait then
        if KrowiGameInput then
            KrowiGameInput.Clear()
        end
        Add(ok and "SKIP" or "FAIL", ok and ("waited %d s for the mouse: %s"):format(mouseWait, step.Text) or ("test error: " .. tostring(ready)))
        After(afterShot, function()
            RunStep(live.StepIndex + 1)
        end)
        return
    end
    if KrowiGameInput and step.Hover then
        pcall(step.Hover, KrowiGameInput)
    end
    After(pollEvery, function()
        WaitForMouse(step, waited + pollEvery)
    end)
end

RunStep = function(n)
    local step = chosenSteps[n]
    if not step then
        Stop()
        return
    end
    live.StepIndex, live.StepName = n, step.Name
    banner.Text:SetText(("Krowi_Options test %d/%d: %s"):format(step.Number or n, live.AllSteps or #chosenSteps, step.Text))
    local ok, skip = pcall(step.Run)
    if not ok or (skip and step.Required) then
        Add("FAIL", ok and skip or ("test error: " .. tostring(skip)))
        Stop("step " .. step.Name .. " failed")
        return
    end
    if skip then -- the steps after it do not build on it
        Add("SKIP", skip)
        RunStep(n + 1)
        return
    end
    if n == 1 then
        banner:ClearAllPoints()
        banner:SetPoint("BOTTOM", Window(), "TOP", 0, 6)
        banner:Show()
    end
    if step.Mouse then
        WaitForMouse(step, 0)
    else
        After(settle, Capture)
    end
end

local function CreateBanner()
    banner = CreateFrame("Frame", nil, UIParent)
    banner:SetFrameStrata("DIALOG")
    banner:SetSize(620, 26)
    local background = banner:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.85)
    banner.Text = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    banner.Text:SetPoint("CENTER")
    banner:SetScript("OnEvent", function(_, event)
        if not live then
            return
        end
        if event == "SCREENSHOT_FAILED" and live.Shot then
            live.Shot.Failed = true
        elseif event == "PLAYER_REGEN_DISABLED" then
            Stop("combat started", true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            Finish()
        end
    end)
    banner:Hide()
end

function steps.IsRunning()
    return live ~= nil
end

-- The named sets of steps, for Krowi_ClaudeKit's two-copy release gate, whose mixed cases need no full run (Krowi,
-- 2026-11-05: the full run with equal copies, a short one elsewhere): smoke opens the window, shows its tabs, changes a
-- check box, searches, collapses the pane and closes; behaviour is every step but the walk through the sections, keeping
-- the two sections whose rows are of their own kind (the tab list and the keys)
local smokeSteps = { open = true, ["library-globals-window"] = true, tabs = true, toggle = true, search = true, pane = true, close = true }
local keptSections = { ["section-tabs"] = true, ["section-keys"] = true }
local stepSets = {
    smoke = function(step) return smokeSteps[step.Name] end,
    behaviour = function(step) return not step.Name:find("^section%-") or keptSections[step.Name] end
}

-- /kotest <what>: a set's steps (smoke, behaviour), only the steps named what or whose name starts with "what-" (toggle:
-- every toggle step; section: every section), or the step with that number in the banner, each with the steps it builds
-- on (Needs) and with the window's open first; nil when nothing matches. The scenarios before the steps run either way:
-- they take no time.
local function SelectSteps(list, what)
    if not what or what == "" then
        return list
    end
    local wanted, number = what:lower(), tonumber(what)
    local InSet = stepSets[wanted]
    local byName, chosen, any = {}, {}, false
    for _, step in ipairs(list) do
        byName[step.Name] = step
    end
    local function Choose(step)
        while step and not chosen[step] do
            chosen[step] = true
            step = byName[step.Needs]
        end
    end
    for i, step in ipairs(list) do
        if InSet and InSet(step) or not InSet and (i == number or step.Name == wanted or step.Name:sub(1, #wanted + 1) == wanted .. "-") then
            Choose(step)
            any = true
        end
    end
    if not any then
        return nil
    end
    Choose(byName.open)
    local selected = {}
    for _, step in ipairs(list) do
        if chosen[step] then
            tinsert(selected, step)
        end
    end
    return selected
end

-- done(results, observations) once the run is over; what: what was typed after /kotest (nil for everything)
function steps.Start(done, what, observations)
    local all = BuildSteps()
    for i, step in ipairs(all) do
        step.Number = i
    end
    local chosen = SelectSteps(all, what)
    if not chosen then
        local names = {}
        for _, step in ipairs(all) do
            tinsert(names, ("%d %s"):format(step.Number, step.Name))
        end
        done({{Name = "select", Status = "SKIP", GameOnly = true,
            Line = ("options/select: SKIP no step '%s'; one of: %s"):format(what, table.concat(names, ", "))}}, observations or {})
        return
    end
    local frame = Window()
    -- Both before the scenarios, which write the shared block and this addon's saved table too (window-second-tab)
    local sharedBefore = SnapshotShared()
    local savedWindow = DeepCopy(fixtures.Tab:GetSaved())
    live = {
        SharedBefore = sharedBefore,
        Results = tests.RunScenarios(),
        Observations = observations or {},
        Finish = done,
        Before = {},
        SavedWindow = savedWindow,
        WasShown = frame and frame:IsShown() and { Tab = frame.Tab, Section = frame.SectionId } or nil,
        AllSteps = #all
    }
    if not banner then
        CreateBanner()
    end
    banner:RegisterEvent("SCREENSHOT_FAILED")
    banner:RegisterEvent("PLAYER_REGEN_DISABLED")
    chosenSteps = chosen
    print(("|cFF1D92C2Krowi_Options test:|r %d of %d steps, about %d s; the options it changes go back at the end.%s"):format(#chosenSteps, #all,
        #chosenSteps * (settle + afterShot), what and "" or " /kotest <smoke, behaviour, a name, start of a name or number> runs only those steps."))
    RunStep(1)
end