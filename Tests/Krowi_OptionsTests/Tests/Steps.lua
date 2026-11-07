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
--   public: the public surface no scenario covers, through the public names only: the tab's IsShown and GetFrame (the
--     frame lib.WindowName names), Toggle (hides, then shows again on the tab), Refresh (shown, and hidden: nothing),
--     lib.Markup's three texts and OnCreated's frame with its Lightbox
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
--     box; toggle-reset-clipped, a step that needs the mouse (the kit's marker serves it, else the player's within 30 s):
--     the arrow goes when the mouse leaves a row through its part scrolled out of view
--   undo-reload: the undo arrow of a check box whose slider needs a reload lights the reload bar (Bugs B1)
--   input-focus-lost: a text box saves its typed text as it loses the focus, and Escape reverts it (Bugs B13)
--   select-stale: a dropdown whose saved value is no longer a choice shows its default, which is saved (Bugs B12)
--   dropdown: a dropdown's arrows through their own OnClick (Blizzard's DropdownWithSteppersMixin, the same on every
--     client): the right arrow saves the next choice and the dropdown shows it, the left arrow goes back and greys on the
--     first choice, the changed line and the footer follow; on a dropdown with a Confirm the arrow asks first, No keeps
--     the value and Yes sets it
--   keys: the key row's own capture: StartKeyCapture lights the button with Press a key, a key handed to the row's
--     handler (never the game's key events, so the game binds nothing) is saved and shown, Escape clears the slot;
--     skipped in combat
--   show-me: Show me on Window, whose help answers what the step sets (Fixtures.lua), the pane open: shown and enabled;
--     CanShowMe false, a click runs no ShowMe and the window stays; ShowMe false, it runs once and the window shows again
--     on Window; ShowMe answering nothing, it runs once and the window stays closed (the step opens it again); hidden
--     under an option's help and with the pane collapsed (docs/work/2026-11-07-release-hardening, as the next six)
--   show-me-secure: Tooltips' help lays a secure stand-in over Show me (ShowMeSecure; ShowMeStandIn.lua, made as
--     Krowi_AchievementFilter's map help makes its own): called with Show me's button and a close function, it lies over
--     it within 1 px; the window moved and its drag ended (OnDragStop), it is called again and lies over it at the new
--     place, then the window goes back; let go (called with nil) when another section is drawn, an option's help shows,
--     the pane collapses and the window hides; answering false, Show me hides and the help's ShowMeNote shows
--   combat: the window's own OnEvent told combat starts, then ends (its signal, not a fight): on Key bindings a capture
--     ends and the key buttons and Reload Now grey, on Window Show me greys with the "not in combat" note; all back after
--   defaults: on Window, Yes sets back an option that needs a reload and the reload bar lights; on Debug with two options
--     changed and one in Tooltips: Defaults counts 2 and asks, No changes nothing, Yes runs ResetSection once for Debug,
--     both back at their defaults on their rows, the count 0 and Defaults greyed, Tooltips' change kept
--   execute: Debug's Reset everything runs its option once and lights the reload bar; the button beside Window's
--     Remember main window position runs its own option once and no other
--   all-none: Events' Seasons: None turns its four members off and All turns them on, saved and shown, the changed lines
--     and the footer following
--   tab-arrows: Tabs: the first row's Up and the last row's Down greyed; Down on the first row moves it second (the rows
--     drawn in the fixture's new order), Up moves it back
--   resize: the window's resize bounds (its width fixed, its height from MinHeight to the screen's), and a saved size
--     outside them, applied through the window's Init, comes back inside them and writes nothing to the saved state
--   slider-help: over a check box's slider the help explains the slider
--   greyed-help, greyed-help-collapsed: a greyed-out check box, dropdown, dropdown arrow and tab arrow still fire their
--     hover and explain their option, in the pane and in the collapsed pane's tooltip
--   greyed-slider-input, greyed-slider-input-box: a greyed-out slider bar and input box under the real mouse, which
--     these need as toggle-reset-clipped does: the help pane explains their option (docs/work/2026-11-05-review-fixes,
--     backlog #31)
--   link-highlight, link-highlight-over, link-highlight-away: the link row's highlight is not drawn with the mouse away,
--     is drawn with the mouse on the row and goes again, a screenshot each (the same mouse; backlog #16)
--   show-me-secure-hover, show-me-secure-click: Tooltips' Show me with the stand-in over it and the window raised (as a
--     click into it raises it), under the real mouse (the kit's marker: its hover, and its click where it has ClickAt;
--     else the player's): the stand-in gets the mouse, not the library's button; a click on the spot runs its secure
--     action once (a counting button of this addon) and its close hides the window, which the step opens again
--   search: the found options drawn as rows under their section's name (docs/work/2026-11-03-blizzard-search);
--     search-letter: from the first letter; search-pane: the pane explains the search, a hovered row with its section;
--     search-broad: Search descriptions finds a word only a description holds; search-change: a check box changed in
--     the results greys its child and the rows stay; search-confirm, -no: a question asked in the results, and No;
--     search-showif: turning Verbose mode off in the results takes its child row away, on brings it back
--   pane: the help pane collapses to its strip; close: the close button hides the window
-- /kotest <what> runs only some steps (SelectSteps, at the end of the file): a set (smoke, behaviour), a step's name, the
-- start of names (toggle, search, section), or a step's number in the banner, each with the steps it builds on and the
-- open first.
-- At the end every value the steps changed, the window's saved state (place, pane, search breadth, last section), its
-- reload bar, the height resize changed, the place show-me-secure moved it from, the fixture's tab order and Show me
-- answers and the stand-in's are put back, and the Lua errors of the session that name Krowi_Options are reported from
-- BugGrabber.
-- Combat stops the run; the values go back once it ends. The run never sets a CVar.

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
local selectId = "tooltips.sort1" -- a dropdown with a default, and neither a Placeholder nor a Confirm (select-stale, dropdown)
local errorPattern = "Krowi_Options" -- the library's folder, and this addon's (Krowi_OptionsTests)

local live -- the run in progress
local runToken = 0 -- bumped by every stop, so a stopped run's timers do nothing
local banner
local chosenSteps

local function Lib()
    return KROWI_LIBMAN:GetLibrary("Krowi_Options_2")
end

-- The library's internals: lib.Internal, or lib itself on a copy from before they moved there (a consumer's older
-- embedded copy can be the one under test)
local function Internal(lib)
    lib = lib or Lib()
    return lib.Internal or lib
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
        local line = row:GetLeft() + Internal().RowX(row.Geometry.Toggle, row:GetWidth())
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

-- An input box saves on focus lost and on Enter, and Escape reverts (Krowi, 2026-11-07; Bugs B13,
-- docs/work/2026-11-06-finish-2-0). The mechanism (RowMixins.lua, OptionRowMixin:OnLoad): the box's OnEditFocusLost hook
-- saves the box's text into its option unless it equals the saved value, and refreshes the window through
-- OnOptionChanged. Enter and Escape end the typing themselves and set the row's InputKept flag before they clear the focus,
-- so the focus lost they cause saves nothing: Enter has saved the text already, Escape has put the saved text back in the
-- box. The box's OnEditFocusGained hook lowers the flag, so a box focused again saves on its next focus lost.
-- A test does not type: the step gives the box the focus, sets its text and clears the focus, as a click into the box,
-- typing and a click elsewhere do, without Enter. Then the box gets the focus again, other text, and its own Escape
-- script. In game Escape puts the saved text in the box before the focus goes, so that focus lost would find nothing to
-- save even without the flag; the flag itself is proven headless, on a box whose text does not change (B13b). Part one
-- is read half a settle later, in case the game gives the focus lost a frame later, and part two runs then.
local focusTexts = { "yyyy-mm-dd", "yy-mm-dd" } -- typed before the focus lost: the first that is not the saved value
local escapedText = "mm/dd/yyyy" -- typed after it, then Escape

local function InputFocusLostStep(optionId)
    local sectionId, option, seen
    return {
        Name = "input-focus-lost",
        Needs = "input-shown",
        Text = "text typed in a text box saves as the box loses the focus, and Escape puts the saved text back",
        Run = function()
            sectionId, option = FindOption(optionId)
            local row = option and RowOf(option)
            if not row then
                return "its row is not drawn"
            end
            Remember(option)
            seen = { First = option:Get() ~= focusTexts[1] and focusTexts[1] or focusTexts[2] }
            local box = row.Input
            box:SetFocus()
            box:SetText(seen.First)
            box:ClearFocus() -- no Enter: the focus lost alone saves it
            After(settle / 2, function()
                local shown = RowOf(option)
                seen.Saved = option:Get()
                seen.Drawn = shown ~= nil
                seen.Line = shown and shown.ChangedBar:IsShown() == option:IsChanged()
                seen.Footer, seen.Count = FooterAgrees(sectionId)
                if not shown then
                    return
                end
                shown.Input:SetFocus()
                shown.Input:SetText(escapedText)
                seen.Typed = shown.Input:GetText() == escapedText
                shown.Input:GetScript("OnEscapePressed")(shown.Input)
            end)
        end,
        Check = function()
            if not seen.Drawn then
                Add("FAIL", ("%s: '%s' typed without Enter, after the focus lost the option holds '%s' and its row is not drawn"):format(optionId,
                    seen.First, tostring(seen.Saved)))
                return
            end
            local saved = seen.Saved == seen.First
            Add(saved and seen.Line and seen.Footer and "PASS" or "FAIL", ("%s: '%s' typed without Enter, after the focus lost the option holds '%s', changed line %s, footer %s (%d changed)"):format(
                optionId, seen.First, tostring(seen.Saved), seen.Line and "follows" or "wrong", seen.Footer and "follows" or "wrong", seen.Count))
            local row = RowOf(option)
            local box = row and row.Input
            local kept = option:Get() == seen.First
            local reverted = box and box:GetText() == seen.First and not box:HasFocus()
            Add(seen.Typed and kept and reverted and "PASS" or "FAIL", ("%s: '%s' typed%s, then Escape: the option holds '%s', the box shows '%s'%s"):format(optionId,
                escapedText, seen.Typed and "" or " (the box did not take it)", tostring(option:Get()), box and tostring(box:GetText()) or "nothing, its row is not drawn",
                box and box:HasFocus() and " and keeps the focus" or ""))
        end
    }
end

-- The text a dropdown shows: WowStyle2DropdownTemplate's Text, which the menu's selected radio sets (its default text,
-- the option's Placeholder, with no radio selected)
local function SelectText(row)
    local dropdown = row.Select.Dropdown
    return dropdown.Text and dropdown.Text:GetText() or dropdown:GetText()
end

-- A select whose saved value is no longer one of its choices (a profile deleted elsewhere) shows its default, and the
-- default is saved through the option's own Set (Krowi, 2026-11-07; Bugs B12, docs/work/2026-11-06-finish-2-0): before,
-- the dropdown showed nothing. The option is set to another choice first, so the dropdown's text has to change to show
-- the default. Both values are written where the fixture keeps its option values (Fixtures.lua's own table; config.Saved
-- holds only the window's state) and the window is drawn again through its own Refresh, as after a change made
-- elsewhere: the row's Refresh reads the value, finds it stale and sets the default.
local staleValue = "removed"

local function SelectStaleStep(optionId)
    local sectionId, option, seen
    return {
        Name = "select-stale",
        Text = "a dropdown whose saved value is no longer a choice shows its default and saves it",
        Run = function()
            local frame = Window()
            sectionId, option = FindOption(optionId)
            if not option then
                return optionId .. " is in no section"
            end
            frame:ShowSection(sectionId, optionId)
            local row = RowOf(option)
            if not row then
                return "its row is not drawn"
            end
            Remember(option)
            local _, default = option:GetDefault()
            local other
            for _, pair in ipairs(option:GetValues()) do
                if pair[1] ~= default and other == nil then
                    other = pair[1]
                end
            end
            option:Set(other)
            frame:Refresh()
            seen = { Default = default, Other = option:FormatValue(other), Before = SelectText(row) }
            option:Set(staleValue)
            frame:Refresh()
        end,
        Check = function()
            local row = RowOf(option)
            local text = row and SelectText(row)
            local defaultText = option:FormatValue(seen.Default)
            local before = seen.Before == seen.Other
            local shows = text == defaultText
            local saved = option:Get() == seen.Default
            local line = row and row.ChangedBar:IsShown() == option:IsChanged()
            local footer, count = FooterAgrees(sectionId)
            Add(before and shows and saved and line and footer and "PASS" or "FAIL", ("%s: showing '%s', then '%s' saved, no choice: the dropdown shows '%s' (its default '%s'), the option holds '%s', changed line %s, footer %s (%d changed)"):format(
                optionId, tostring(seen.Before), staleValue, row and tostring(text) or "nothing, its row is not drawn", defaultText, tostring(option:Get()),
                line and "follows" or "wrong", footer and "follows" or "wrong", count))
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

-- The first check box whose option beside it (its With) needs a reload while the check box itself does not, its section
-- and the With
local function FindReloadPair()
    for _, sectionId in ipairs(fixtures.Sections) do
        for _, element in ipairs(fixtures.GetElements(sectionId)) do
            local with = element.With
            if with and with:GetNeedsReload() and not with:IsHidden() and not element.Option:GetNeedsReload() then
                return sectionId, element.Option, with
            end
        end
    end
end

-- The undo arrow sets back the check box and the option beside it, and lights the reload bar when that one needs a
-- reload (Bugs B1, docs/work/2026-11-06-finish-2-0): before, only the check box's own reload was asked. The fixture's
-- Force two columns carries Column threshold, which needs a reload (Fixtures.lua). The threshold is changed through its
-- slider, which lights the bar by itself, so the bar is put out before the arrow: what lights it then is the arrow's
-- click. As toggle-reset, the row's enter and leave and the arrow's click are played. After the screenshot the bar goes
-- back to what it was before the step (Restore too, should combat stop the run first).
local function UndoReloadStep()
    local option, with, seen
    return {
        Name = "undo-reload",
        Text = "the undo arrow lights the reload bar when the option beside the check box needs a reload",
        Run = function()
            local frame = Window()
            local sectionId
            sectionId, option, with = FindReloadPair()
            if not option then
                return "no check box whose slider or button needs a reload"
            end
            frame:ShowSection(sectionId, option.Id)
            local row = RowOf(option)
            if not row then
                return "its row is not drawn"
            end
            Remember(option)
            Remember(with)
            live.ReloadBefore = live.ReloadBefore or { Value = frame.ReloadPending }
            local min, max = with:GetRange()
            row.Range:SetValue(with:Get() ~= max and max or min)
            seen = { Changed = with:IsChanged(), SliderLit = frame.ReloadPending and true or false }
            frame.ReloadPending = nil
            frame:RefreshFooter()
            seen.Out = not frame.ReloadButton:IsShown() and not frame.ReloadBackground:IsShown()
            row = RowOf(option)
            if not row then
                seen.Missing = "its row is not drawn after the slider's change"
                return
            end
            row:OnEnter()
            local reset = row.Reset
            seen.Arrow = reset:IsShown()
            reset:GetScript("OnClick")(reset, "LeftButton")
            row:OnLeave()
        end,
        Check = function()
            local frame = Window()
            local label = ("%s + %s"):format(option:GetLabel(), with:GetLabel())
            if seen.Missing then
                Add("FAIL", ("%s: %s"):format(label, seen.Missing))
            else
                local lit = frame.ReloadPending and frame.ReloadButton:IsShown() and frame.ReloadBackground:IsShown()
                local back = not option:IsChanged() and not with:IsChanged()
                local row = RowOf(option)
                local line = row and not row.ChangedBar:IsShown()
                local ok = seen.Changed and seen.Out and seen.Arrow and lit and back and line
                Add(ok and "PASS" or "FAIL", ("%s: the slider %s (the bar %s), the bar put out %s, the arrow %s on enter; after its click the reload bar %s (pending %s, Reload Now %s, background %s), %s, changed line %s"):format(
                    label, seen.Changed and "changed it" or "did not change it", seen.SliderLit and "lit" or "not lit", seen.Out and "yes" or "no",
                    seen.Arrow and "shown" or "not shown", lit and "lit" or "not lit", tostring(frame.ReloadPending), frame.ReloadButton:IsShown() and "shown" or "hidden",
                    frame.ReloadBackground:IsShown() and "shown" or "hidden", back and "both back at their defaults" or "not back",
                    not row and "not drawn" or line and "gone" or "still shown"))
            end
            After(afterShot / 2, function()
                local shown = Window()
                shown.ReloadPending = live.ReloadBefore.Value
                shown:RefreshFooter()
            end)
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
    local internal = Internal()
    for _, optionId in ipairs({ toggleId, rangeId, tabPriorityId }) do
        local _, option = FindOption(optionId)
        for word in (option and option:GetDescription() or ""):gmatch("[^%s%p]+") do
            if #word >= 5 and #internal.Search(word, false, fixtures.Tab, false) == 0
                and #internal.Search(word, false, fixtures.Tab, true) > 0 then return word end
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

-- [[ Steps with the mouse on a spot: the kit's marker puts it there, else the player within mouseWait ]] --
-- The kit moves the cursor along a path, and the game runs an enter on the next frame: a step checks once the cursor has
-- stayed on its spot this long
local hoverHold = 0.5

-- Mouse() of a step: true once over has held for hoverHold since it last turned true (state: the step's own table)
local function Settled(state, over)
    if not over then
        state.Since = nil
        return false
    end
    state.Since = state.Since or GetTime()
    return GetTime() - state.Since >= hoverHold
end

-- The frame the game gives the mouse to (its enter, its leave, a button's highlight), else none
local function MouseFocus()
    if GetMouseFoci then
        local foci = GetMouseFoci()
        return foci and foci[1]
    end
    return GetMouseFocus and GetMouseFocus()
end

-- Whether a frame has the mouse as the game counts it for its highlight: IsMouseOver only tells where the cursor is
local function HasMouse(frame)
    if frame.IsMouseMotionFocus then return frame:IsMouseMotionFocus() and true or false end
    return MouseFocus() == frame
end

-- What the mouse is on, by the names a step gives the frames it knows ({ [frame] = name })
local function MouseOn(named)
    local focus = MouseFocus()
    if not focus then return "no frame" end
    if named[focus] then return named[focus] end
    local name = focus.GetDebugName and focus:GetDebugName()
    return "another frame" .. (name and name ~= "" and (" (" .. name .. ")") or "")
end

-- The link row's highlight (docs/work/2026-11-05-review-fixes, backlog #16): RowFrames.lua makes it with CreateTexture(),
-- which gives no layer, before SetHighlightTexture, so it may stay drawn as a faint wash. The game draws a texture of the
-- HIGHLIGHT layer only while its button has the mouse, a texture of any other layer whenever it is visible: each step
-- reads the highlight's layer, whether it is shown and visible, its alpha and whether the row has the mouse, and the
-- screenshot shows what is drawn. Three states, a step and a screenshot each: the mouse away (on the help pane), on the
-- row, and away again. The first link of the first section that has one (the fixture's About).
local function LinkRow()
    local frame = Window()
    for _, element in ipairs(frame.Elements or {}) do
        if element.Kind == "Link" then return RowOfElement(element), element end
    end
end

-- Shows the link's section, unless the page shows it already, with the help pane open (the spot away from the row)
local function ShowLink()
    local frame = Window()
    if frame.PaneCollapsed then frame:SetPaneCollapsed(false) end
    local row, element = LinkRow()
    if row and not frame.Searching then return row end
    for _, sectionId in ipairs(fixtures.Sections) do
        for _, candidate in ipairs(fixtures.GetElements(sectionId)) do
            if candidate.Kind == "Link" then
                frame:ShowSection(sectionId)
                row, element = LinkRow()
                if not element then return nil, sectionId .. " shows no link" end
                if not row then return nil, "the link's row is not drawn" end
                return row
            end
        end
    end
    return nil, "no section has a link"
end

local function HighlightState(row)
    local texture = row:GetHighlightTexture()
    local state = { Cursor = row:IsMouseOver() and true or false, Mouse = HasMouse(row) }
    if not texture then
        state.Missing = true
        return state
    end
    state.Layer, state.Shown, state.Visible, state.Alpha = texture:GetDrawLayer(), texture:IsShown(), texture:IsVisible(), texture:GetAlpha()
    state.Drawn = state.Visible and state.Alpha > 0 and (state.Layer ~= "HIGHLIGHT" or state.Mouse)
    return state
end

local function LinkHighlightSteps()
    local seen
    local states = {
        { Name = "link-highlight", State = "mouse away", Text = "link row, mouse away (on the help pane): no highlight" },
        { Name = "link-highlight-over", State = "mouse over", OnRow = true, Text = "link row, mouse over: its highlight shows" },
        { Name = "link-highlight-away", State = "mouse away again", Text = "link row, mouse away again: the highlight goes" },
    }
    local list = {}
    for i, spec in ipairs(states) do
        list[i] = {
            Name = spec.Name,
            Needs = i > 1 and states[i - 1].Name or nil,
            Text = ("%s (%d s)"):format(spec.Text, mouseWait),
            Run = function()
                seen = {}
                local row, why = ShowLink()
                if not row then return why end
            end,
            Hover = function(kit)
                local row = LinkRow()
                if spec.OnRow then
                    if row then kit.HoverAt(row, 0, 0) end
                else
                    kit.HoverAt(Window().HelpScrollBox, 0, 0)
                end
            end,
            Mouse = function()
                local row = LinkRow()
                if not row then return false end
                if spec.OnRow then return Settled(seen, row:IsMouseOver()) end
                return Settled(seen, Window().HelpScrollBox:IsMouseOver() and not row:IsMouseOver())
            end,
            Check = function()
                local row = LinkRow()
                if not row then
                    Add("FAIL", ("%s: the link's row is not drawn"):format(spec.State))
                    return
                end
                local state = HighlightState(row)
                local name = row.Text:GetText() or "?"
                if state.Missing then
                    Add(spec.OnRow and "FAIL" or "PASS", ("%s, link '%s': the row has no highlight texture (cursor on the row %s)"):format(spec.State,
                        name, state.Cursor and "yes" or "no"))
                    return
                end
                local ok = state.Drawn == (spec.OnRow and true or false)
                local verdict = state.Drawn and (spec.OnRow and "drawn" or "drawn without the mouse: a permanent wash")
                    or (spec.OnRow and "not drawn under the mouse" or "not drawn")
                Add(ok and "PASS" or "FAIL", ("%s, link '%s': highlight %s (layer %s, shown %s, visible %s, alpha %.2f; cursor on the row %s, the row has the mouse %s)"):format(
                    spec.State, name, verdict, tostring(state.Layer), state.Shown and "yes" or "no", state.Visible and "yes" or "no", state.Alpha,
                    state.Cursor and "yes" or "no", state.Mouse and "yes" or "no"))
            end
        }
    end
    return list
end

-- A greyed-out slider bar and input box explain themselves under the mouse (docs/work/2026-11-05-review-fixes, backlog
-- #31). greyed-help plays a greyed button's own enter, which the game runs because the button asks for it
-- (SetMotionScriptsWhileDisabled). A slider and an edit box have no such setting (RowMixins.lua, HoverWhileDisabled): whether
-- the game runs their enter while they are greyed shows only under a real mouse. The slider is the one beside a check box
-- that greys while its check box is off (the fixture's Force two columns and Column threshold, as Krowi_AchievementFilter's),
-- the input box one that greys with its parent (Log file under Verbose mode). Each step turns that check box off, waits for
-- the cursor on the greyed control, then reads whether the help pane explains its option, which frame has the mouse and
-- whether the row's light is on (the row's enter ran last, not its leave); after its screenshot the check box is on again.
-- PASS only when the pane explains the greyed control's option: a FAIL is the bug the backlog item asks about.
local function GreyedHoverSteps()
    local turnedOff -- the check box a step turned off, on again after its screenshot (Restore too, should the run stop)
    local function Release()
        if turnedOff then
            turnedOff:Set(true)
            Window():OnOptionChanged(turnedOff)
            turnedOff = nil
        end
    end
    -- The frames of an option row the mouse can be on, by name
    local function RowParts(row)
        return { [row] = "the row", [row.Toggle] = "the check box", [row.Range] = "the slider's frame", [row.Range.Slider] = "the slider bar",
            [row.Range.Back] = "the slider's left arrow", [row.Range.Forward] = "the slider's right arrow", [row.Input] = "the input box" }
    end
    local cases = {
        {
            Name = "greyed-slider-input",
            What = "slider bar",
            -- The first check box whose slider greys while it is off: the section, the check box, the slider's option and the
            -- option whose row draws the slider (the check box's)
            Find = function()
                for _, sectionId in ipairs(fixtures.Sections) do
                    for _, element in ipairs(fixtures.GetElements(sectionId)) do
                        local with = element.With
                        if with and with.Type == "range" and with.DisabledIf and not with:IsHidden() then
                            return sectionId, element.Option, with, element.Option
                        end
                    end
                end
            end,
            Control = function(row) return row.Range.Slider end,
        },
        {
            Name = "greyed-slider-input-box",
            What = "input box",
            -- The first input box that greys with its parent: the section, the parent, the input's option and its row's
            Find = function()
                for _, sectionId in ipairs(fixtures.Sections) do
                    for _, element in ipairs(fixtures.GetElements(sectionId)) do
                        local option = element.Option
                        if option and option.Type == "input" and option.DisabledIf and option:GetParent() and not option:IsHidden() then
                            return sectionId, option:GetParent(), option, option
                        end
                    end
                end
            end,
            Control = function(row) return row.Input end,
        },
    }
    local list = {}
    for i, case in ipairs(cases) do
        local target, seen
        local function Control()
            local row = target and RowOf(target.RowOption)
            return row and case.Control(row), row
        end
        list[i] = {
            Name = case.Name,
            Text = ("greyed-out %s under the mouse: the help explains it (%d s)"):format(case.What, mouseWait),
            Run = function()
                Release()
                local frame = Window()
                if frame.PaneCollapsed then frame:SetPaneCollapsed(false) end
                local sectionId, switch, option, rowOption = case.Find()
                if not option then
                    target = nil
                    return ("no %s that greys with a check box"):format(case.What)
                end
                target, seen = { Switch = switch, Option = option, RowOption = rowOption }, {}
                frame:ShowSection(sectionId, rowOption.Id)
                if switch:Get() then
                    Remember(switch)
                    switch:Set(false)
                    frame:OnOptionChanged(switch)
                    turnedOff = switch
                end
                if not option:IsDisabled() then
                    Release()
                    return ("%s does not grey with %s off"):format(option:GetLabel(), switch:GetLabel())
                end
                if not Control() then return "its row is not drawn" end
            end,
            Hover = function(kit)
                local control = Control()
                if control then kit.HoverAt(control, 0, 0) end
            end,
            -- Where the cursor is, not where the game sends the mouse: a greyed control that takes no enter is the finding
            Mouse = function()
                local control = Control()
                return Settled(seen, control ~= nil and control:IsMouseOver())
            end,
            Check = function()
                local frame = Window()
                local control, row = Control()
                local label = ("%s's %s"):format(target.Option:GetLabel(), case.What)
                if not control then
                    Add("FAIL", label .. ": its row is not drawn")
                else
                    local greyed = not control:IsEnabled()
                    local shown = frame.HoverOption
                    local explains = shown == target.Option
                    local asks = control.GetMotionScriptsWhileDisabled and (control:GetMotionScriptsWhileDisabled() and "asks for its hover while greyed"
                        or "does not ask for its hover while greyed") or "has no setting to hover while greyed"
                    Add(greyed and explains and "PASS" or "FAIL", ("%s, %s (%s off), under the mouse: the pane explains %s; the mouse is on %s, the row's light %s; the %s %s"):format(
                        label, greyed and "greyed" or "not greyed", target.Switch:GetLabel(), explains and "it" or (shown and ("'" .. shown:GetLabel() .. "'") or "the section, not the option"),
                        MouseOn(RowParts(row)), row.Hover:IsShown() and "on" or "off", case.What, asks))
                end
                After(afterShot / 2, Release)
            end
        }
    end
    return list
end

-- The public surface that no scenario and no other step covers (Krowi, 2026-11-07: the library validates itself, its
-- internals and its public surface; no consumer's suite does it for it), read through the public names only, never
-- lib.Internal: the fixture's tab object (fixtures.Tab), lib.WindowName and lib.Markup. On the window the open step
-- opened on the fixture's tab, six checks, a line each, numbered: 1 the tab's IsShown; 2 its GetFrame is the frame the
-- global lib.WindowName names, shown as IsShown says; 3 Toggle hides the window and a second Toggle shows it again on
-- this tab; 4 Refresh runs while the window is shown, and while it is hidden does nothing; 5 lib.Markup's Changed,
-- Reload and Reset are texts; 6 OnCreated ran once for the tab with that frame (Fixtures.lua counts its calls in
-- fixtures.Created and keeps the frame in fixtures.Frame), which carries its Lightbox. Every call of the library runs in
-- a pcall, so its error is that check's FAIL and the run goes on. Each half after the first Toggle starts from a hidden
-- window, hidden through the frame's own Hide when the call before left it shown, so one fault fails one check; a window
-- the toggles left hidden is opened again through the tab's Open for the steps after. No mouse and no wait: it runs
-- unattended in smoke.
local function PublicStep()
    local seen
    -- The error a call raised, or nil when it ran
    local function Try(func, ...)
        local ok, err = pcall(func, ...)
        return not ok and tostring(err) or nil
    end
    local function Named(frame)
        if frame == nil then return "nothing" end
        return type(frame) == "table" and frame.GetName and frame:GetName() or tostring(frame)
    end
    local function Raised(err, otherwise)
        return err and ("raised: " .. err) or otherwise
    end
    return {
        Name = "public",
        Needs = "open",
        Text = "a tab's public methods, lib.Markup and OnCreated's frame",
        Run = function()
            local lib, tab = Lib(), fixtures.Tab
            local global = type(lib.WindowName) == "string" and _G[lib.WindowName] or nil
            local function FrameShown() return global ~= nil and global:IsShown() and true or false end
            local function IsHidden() return not tab:IsShown() and not FrameShown() end
            -- A window a call left shown, hidden through its frame for the next half
            local function HideByFrame()
                if global ~= nil and not IsHidden() then global:Hide() end
            end
            seen = { Global = global }
            -- 1 and 2: as the open step left the window
            seen.Shown = tab:IsShown()
            seen.GetFrame = Try(function() seen.Frame = tab:GetFrame() end)
            seen.FrameShown = seen.Frame ~= nil and seen.Frame:IsShown() and true or false
            -- 4, shown: the page drawn again
            seen.RefreshShown = Try(tab.Refresh, tab)
            -- 3: the first Toggle hides the window
            seen.Hide = Try(tab.Toggle, tab)
            seen.HiddenTab, seen.HiddenFrame = tab:IsShown(), FrameShown()
            seen.WasHidden = not seen.HiddenTab and not seen.HiddenFrame
            HideByFrame()
            -- 4, hidden: nothing happens, the window stays hidden
            seen.TriedHidden = IsHidden()
            if seen.TriedHidden then
                seen.RefreshHidden = Try(tab.Refresh, tab)
                seen.StaysHidden = IsHidden()
                HideByFrame()
            end
            -- 3: the second Toggle shows it again on this tab
            seen.HiddenBefore = IsHidden()
            seen.Show = Try(tab.Toggle, tab)
            seen.AgainTab, seen.AgainFrame = tab:IsShown(), FrameShown()
            -- Left shown for the steps after, whatever the toggles did
            if not tab:IsShown() then
                seen.Reopen = Try(tab.Open, tab) or false
            end
        end,
        Check = function()
            local lib, tab = Lib(), fixtures.Tab
            local frame = seen.Frame
            -- 1
            Add(seen.Shown == true and "PASS" or "FAIL", ("1 IsShown: with the window open on the fixture's tab, the tab's IsShown() is %s"):format(
                tostring(seen.Shown)))
            -- 2
            local same = frame ~= nil and frame == seen.Global
            local agrees = seen.FrameShown == seen.Shown
            Add(not seen.GetFrame and same and agrees and "PASS" or "FAIL", ("2 GetFrame: %s%s"):format(
                Raised(seen.GetFrame, same and ("returns the window, _G[\"%s\"]"):format(tostring(lib.WindowName))
                    or ("returns %s, not _G[\"%s\"] (%s)"):format(Named(frame), tostring(lib.WindowName), Named(seen.Global))),
                frame == nil and "" or ("; the frame is %s, the tab's IsShown() %s"):format(seen.FrameShown and "shown" or "hidden",
                    agrees and "agrees" or ("says " .. tostring(seen.Shown)))))
            -- 3
            local hid = not seen.Hide and seen.WasHidden
            local back = not seen.Show and seen.HiddenBefore and seen.AgainTab == true and seen.AgainFrame
            local left = tab:IsShown()
            Add(hid and back and left and "PASS" or "FAIL", ("3 Toggle: the first %s (IsShown() %s, the frame %s), the second %s (IsShown() %s, the frame %s); at the check the window is %s%s"):format(
                Raised(seen.Hide, hid and "hides the window" or "leaves the window shown"), tostring(seen.HiddenTab), seen.HiddenFrame and "shown" or "hidden",
                Raised(seen.Show, not seen.HiddenBefore and "had no hidden window to show (its frame's Hide did not hide it)"
                    or back and "shows it again on this tab" or "does not show it on this tab"), tostring(seen.AgainTab), seen.AgainFrame and "shown" or "hidden",
                left and "shown on the tab" or "not shown on the tab",
                seen.Reopen == nil and "" or (", opened again through Open" .. (seen.Reopen and (", which raised: " .. seen.Reopen) or ""))))
            -- 4
            local hiddenPart = not seen.TriedHidden and "was not tried: the window could not be hidden"
                or Raised(seen.RefreshHidden, seen.StaysHidden and "does nothing, the window stays hidden" or "shows the window")
            local status = (seen.RefreshShown or seen.TriedHidden and (seen.RefreshHidden or not seen.StaysHidden)) and "FAIL"
                or not seen.TriedHidden and "SKIP" or "PASS"
            Add(status, ("4 Refresh: while shown it %s; while hidden it %s%s"):format(Raised(seen.RefreshShown, "runs"), hiddenPart,
                seen.TriedHidden and not seen.WasHidden and " (hidden through its frame: the first Toggle did not hide it)" or ""))
            -- 5
            local markup = lib.Markup
            local notText = {}
            for _, key in ipairs({ "Changed", "Reload", "Reset" }) do
                local text = type(markup) == "table" and markup[key] or nil
                if type(text) ~= "string" or text == "" then tinsert(notText, key) end
            end
            Add(type(markup) == "table" and #notText == 0 and "PASS" or "FAIL", ("5 Markup: %s"):format(type(markup) ~= "table" and "lib.Markup is no table"
                or #notText == 0 and "Changed, Reload and Reset are texts" or ("no text in " .. table.concat(notText, ", "))))
            -- 6
            local kept = fixtures.Frame
            local lightbox = type(kept) == "table" and kept.Lightbox or nil
            local isFrame = type(lightbox) == "table" and type(lightbox.IsObjectType) == "function" and lightbox:IsObjectType("Frame")
            local created = fixtures.Created or 0
            local ok = created == 1 and frame ~= nil and kept == frame and isFrame
            Add(ok and "PASS" or "FAIL", ("6 OnCreated: called %s for the fixture's tab, with %s, whose Lightbox is %s"):format(
                created == 1 and "once" or (created .. " times"),
                kept == nil and "no frame" or kept == frame and "the frame the tab's GetFrame() returns" or ("%s, not what the tab's GetFrame() returns (%s)"):format(Named(kept), Named(frame)),
                isFrame and ("a " .. lightbox:GetObjectType()) or lightbox == nil and "missing" or "no frame"))
        end
    }
end

-- [[ The code each client runs its own copy of: a dropdown's arrows, a key captured, the window's size ]] --
-- No other step reaches these (the client review of 2026-11-07, CLAUDE.md's Clients). Each step works through the
-- window's own functions and its rows' own handlers, needs no mouse and runs unattended.

-- A dropdown's arrows: build.Select (RowFrames.lua) mixes Blizzard's DropdownWithSteppersMixin into the row's Select, whose
-- OnLoad gives each arrow its OnClick: OnIncrementClicked, the dropdown's Increment, then Pick of the next radio, which
-- runs that radio's responder (RowMixins.lua's select type). The same code on every client (SharedUIPanelTemplates.lua
-- and Blizzard_Menu's DropdownButton.lua on live, classic, classic_era, classic_anniversary, classic_titan and forever).
-- The step clicks an arrow through Click(), as the player's click runs it, and never one that is greyed. Each dropdown is
-- set to its first choice first, through the option and the window's OnOptionChanged as a change made elsewhere, so its
-- right arrow can step. The plain one (Sort priority 1): the right arrow saves the next choice and the dropdown shows it,
-- the left arrow goes back and greys on the first choice, the changed line and the footer following each. The one with a
-- Confirm (Profile): the arrow asks in the window's header and leaves the value, No keeps it, the arrow again and Yes set
-- it. Restore puts both values back.
local confirmSelectId = "debug.profile"

-- What a dropdown's row shows: its option's value, the dropdown's text, its changed line and the footer, its arrows, and
-- the question the window asks (its Confirming, and the header with No beside it)
local function ReadSelect(option, sectionId)
    local frame = Window()
    local row = RowOf(option)
    local footer, count = FooterAgrees(sectionId)
    return {
        Value = option:Get(),
        Text = row and SelectText(row),
        Line = row ~= nil and row.ChangedBar:IsShown() == option:IsChanged(),
        Footer = footer,
        Count = count,
        Back = row ~= nil and row.Select.DecrementButton:IsEnabled() and true or false,
        Forward = row ~= nil and row.Select.IncrementButton:IsEnabled() and true or false,
        Question = frame.Confirming and frame.Confirming.Text,
        Header = frame.CancelButton:IsShown() and frame.ChangedText:GetText() or nil,
    }
end

-- Clicks a dropdown's arrow ("IncrementButton" or "DecrementButton") as the player does: nil once clicked, else why not
local function ClickArrow(option, key)
    local row = RowOf(option)
    if not row then return "its row is not drawn" end
    local arrow = row.Select[key]
    if not arrow:IsEnabled() then return "greyed, so not clicked" end
    arrow:Click()
end

-- A dropdown set to its first choice through the option and the window, as a change made elsewhere, once Restore knows
-- its value; returns its first and second choice
local function ToFirstChoice(option)
    local values = option:GetValues()
    Remember(option)
    if option:Get() ~= values[1][1] then
        option:Set(values[1][1])
        Window():OnOptionChanged(option)
    end
    return values[1][1], values[2][1]
end

local function Follows(read)
    return ("changed line %s, footer %s (%d changed)"):format(read.Line and "follows" or "wrong", read.Footer and "follows" or "wrong", read.Count)
end

local function Quoted(text)
    return text and ("'" .. tostring(text) .. "'") or "nothing"
end

local function DropdownStep(optionId, confirmId)
    local seen
    return {
        Name = "dropdown",
        Text = "a dropdown's arrows step through its choices, and ask first where the option asks",
        Run = function()
            local frame = Window()
            local sectionId, option = FindOption(optionId)
            local confirmSection, confirmOption = FindOption(confirmId)
            if not option or not confirmOption then return ("%s or %s is in no section"):format(optionId, confirmId) end
            if #option:GetValues() < 2 or #confirmOption:GetValues() < 2 or not confirmOption.Confirm then
                return ("%s and %s need two choices each, and %s a Confirm"):format(optionId, confirmId, confirmId)
            end
            seen = { Id = optionId, ConfirmId = confirmId }
            -- 1 and 2: the plain dropdown
            frame:ShowSection(sectionId, optionId)
            if not RowOf(option) then return "its row is not drawn" end
            seen.First, seen.Next = ToFirstChoice(option)
            seen.FirstText, seen.NextText = option:FormatValue(seen.First), option:FormatValue(seen.Next)
            seen.ForwardWhy = ClickArrow(option, "IncrementButton")
            seen.Forward = ReadSelect(option, sectionId)
            seen.BackWhy = ClickArrow(option, "DecrementButton")
            seen.Back = ReadSelect(option, sectionId)
            -- 3 to 5: the dropdown that asks
            frame:ShowSection(confirmSection, confirmId)
            if not RowOf(confirmOption) then
                seen.ConfirmMissing = true
                return
            end
            seen.ConfirmFirst, seen.ConfirmNext = ToFirstChoice(confirmOption)
            seen.ConfirmFirstText, seen.ConfirmNextText = confirmOption:FormatValue(seen.ConfirmFirst), confirmOption:FormatValue(seen.ConfirmNext)
            seen.Question = confirmOption:Confirm(seen.ConfirmNext)
            seen.AskWhy = ClickArrow(confirmOption, "IncrementButton")
            seen.Asked = ReadSelect(confirmOption, confirmSection)
            -- No and Yes answer only the arrow's question: with none asked, Defaults would ask to set the section back
            seen.NoClicked = seen.Asked.Question == seen.Question
            if seen.NoClicked then frame.CancelButton:Click() end
            seen.No = ReadSelect(confirmOption, confirmSection)
            seen.AgainWhy = ClickArrow(confirmOption, "IncrementButton")
            seen.Again = ReadSelect(confirmOption, confirmSection)
            seen.YesClicked = seen.Again.Question == seen.Question
            if seen.YesClicked then frame.DefaultsButton:Click() end
            seen.Yes = ReadSelect(confirmOption, confirmSection)
        end,
        Check = function()
            local forward, back = seen.Forward, seen.Back
            local forwardOk = not seen.ForwardWhy and forward.Value == seen.Next and forward.Text == seen.NextText and forward.Line and forward.Footer
            Add(forwardOk and "PASS" or "FAIL", ("1 right arrow on %s (%s): from '%s' the option holds %s (the next choice is %s), the dropdown shows %s, %s"):format(
                seen.Id, seen.ForwardWhy or "clicked", tostring(seen.FirstText), tostring(forward.Value), tostring(seen.Next), Quoted(forward.Text),
                Follows(forward)))
            local backOk = not seen.BackWhy and back.Value == seen.First and back.Text == seen.FirstText and back.Line and back.Footer
                and not back.Back and back.Forward
            Add(backOk and "PASS" or "FAIL", ("2 left arrow on %s (%s): the option holds %s (the first choice is %s), the dropdown shows %s, %s; on the first choice the left arrow is %s and the right %s"):format(
                seen.Id, seen.BackWhy or "clicked", tostring(back.Value), tostring(seen.First), Quoted(back.Text), Follows(back),
                back.Back and "enabled (greyed expected)" or "greyed", back.Forward and "enabled" or "greyed (enabled expected)"))
            if seen.ConfirmMissing then
                Add("FAIL", ("3 to 5 on %s: its row is not drawn"):format(seen.ConfirmId))
                return
            end
            local asked, no, again, yes = seen.Asked, seen.No, seen.Again, seen.Yes
            local askOk = not seen.AskWhy and asked.Question == seen.Question and asked.Header == seen.Question
                and asked.Value == seen.ConfirmFirst and asked.Text == seen.ConfirmFirstText
            Add(askOk and "PASS" or "FAIL", ("3 right arrow on %s, which asks (%s): the window asks %s ('%s' expected), its header shows %s; the option still holds %s (%s expected), the dropdown shows %s"):format(
                seen.ConfirmId, seen.AskWhy or "clicked", Quoted(asked.Question), tostring(seen.Question), Quoted(asked.Header), tostring(asked.Value),
                tostring(seen.ConfirmFirst), Quoted(asked.Text)))
            local noOk = seen.NoClicked and not no.Question and not no.Header and no.Value == seen.ConfirmFirst and no.Text == seen.ConfirmFirstText
            Add(noOk and "PASS" or "FAIL", ("4 No on %s (%s): the question %s, the option holds %s (%s expected), the dropdown shows %s"):format(
                seen.ConfirmId, seen.NoClicked and "clicked" or "not clicked: nothing was asked", (no.Question or no.Header) and "stays" or "is gone",
                tostring(no.Value), tostring(seen.ConfirmFirst), Quoted(no.Text)))
            local yesOk = not seen.AgainWhy and seen.YesClicked and not yes.Question and not yes.Header and yes.Value == seen.ConfirmNext
                and yes.Text == seen.ConfirmNextText and yes.Line and yes.Footer
            Add(yesOk and "PASS" or "FAIL", ("5 the right arrow again on %s (%s, the window asks %s), then Yes (%s): the question %s, the option holds %s (%s expected), the dropdown shows %s, %s"):format(
                seen.ConfirmId, seen.AgainWhy or "clicked", Quoted(again.Question), seen.YesClicked and "clicked" or "not clicked: nothing was asked",
                (yes.Question or yes.Header) and "stays" or "is gone", tostring(yes.Value), tostring(seen.ConfirmNext), Quoted(yes.Text), Follows(yes)))
        end
    }
end

-- A key captured by the key row (RowMixins.lua, OptionRowMixin): the row's own StartKeyCapture lights the slot's button
-- with Press a key and hands it the keyboard; the key then goes to the row's own handler, OnKeyCaptured, never through
-- the game's key events, so the game binds nothing and the fixture's slot keeps it in its own table (Fixtures.lua). The
-- handler adds the modifiers held at that moment, which are the game's, so the saved key has only to end in F. Escape
-- clears the slot. Out of combat only, as the handler: in combat the step skips. A capture left open ends through the
-- window's own EndKeyCaptures, so no button keeps the keyboard; Restore puts the slot back.
local keyId = "keys.open"
local capturedKey = "F"

local function KeysStep(optionId)
    local seen
    -- What the row shows of its first slot
    local function Read(option, sectionId)
        local row = RowOf(option)
        local button = row and row.Key1
        local footer, count = FooterAgrees(sectionId)
        return {
            Capturing = row and row.Capturing,
            Text = button and button:GetText(),
            Lit = button ~= nil and button.SelectedHighlight:IsShown() and true or false,
            Keyboard = button ~= nil and button:IsKeyboardEnabled() and true or false,
            Value = option.Slots[1]:Get(),
            Line = row ~= nil and row.ChangedBar:IsShown() == option:IsChanged(),
            Footer = footer,
            Count = count,
        }
    end
    -- One of the row's own key methods, on the row the page draws now
    local function OnRow(option, method, ...)
        local row = RowOf(option)
        if row then row[method](row, ...) end
    end
    local function Ended(read)
        return read.Capturing == nil and not read.Keyboard
    end
    return {
        Name = "keys",
        Text = "a key row takes a key through its own capture, and Escape clears it",
        Run = function()
            if InCombatLockdown() then return "in combat: a key row captures a key out of combat only" end
            local frame = Window()
            local sectionId, option = FindOption(optionId)
            if not option or not option.Slots then return optionId .. " is no key option in any section" end
            frame:ShowSection(sectionId, optionId)
            if not RowOf(option) then return "its row is not drawn" end
            local strings = frame.Strings
            Remember(option.Slots[1])
            seen = { Id = optionId, PressAKey = strings.PressAKey, NotBound = GRAY_FONT_COLOR:WrapTextInColorCode(strings.NotBound) }
            OnRow(option, "StartKeyCapture", 1)
            seen.Start = Read(option, sectionId)
            OnRow(option, "OnKeyCaptured", 1, capturedKey)
            seen.Bound = Read(option, sectionId)
            OnRow(option, "StartKeyCapture", 1)
            seen.Again = Read(option, sectionId)
            OnRow(option, "OnKeyCaptured", 1, "ESCAPE")
            seen.Cleared = Read(option, sectionId)
            frame:EndKeyCaptures()
        end,
        Check = function()
            local start, bound, again, cleared = seen.Start, seen.Bound, seen.Again, seen.Cleared
            local startOk = start.Capturing == 1 and start.Text == seen.PressAKey and start.Lit and start.Keyboard
            Add(startOk and "PASS" or "FAIL", ("1 capture on %s's first slot: Capturing %s (1 expected), the button shows %s ('%s' expected), lit %s, takes the keyboard %s"):format(
                seen.Id, tostring(start.Capturing), Quoted(start.Text), seen.PressAKey, start.Lit and "yes" or "no", start.Keyboard and "yes" or "no"))
            local value = bound.Value
            local endsInKey = type(value) == "string" and (value == capturedKey or value:sub(-#capturedKey - 1) == "-" .. capturedKey)
            local boundText = endsInKey and GetBindingText(value) or nil
            local boundOk = endsInKey and bound.Text == boundText and Ended(bound) and bound.Line and bound.Footer
            Add(boundOk and "PASS" or "FAIL", ("2 %s handed to the row's handler: the slot holds %s (ending in %s expected), the button shows %s%s, the capture %s, %s"):format(
                capturedKey, Quoted(value), capturedKey, Quoted(bound.Text), boundText and bound.Text ~= boundText and (" ('" .. boundText .. "' expected)") or "",
                Ended(bound) and "ended" or "still open", Follows(bound)))
            local clearedOk = again.Capturing == 1 and cleared.Value == "" and cleared.Text == seen.NotBound and Ended(cleared) and cleared.Line and cleared.Footer
            Add(clearedOk and "PASS" or "FAIL", ("3 capture again (Capturing %s), then Escape: the slot holds %s ('' expected), the button %s, the capture %s, %s"):format(
                tostring(again.Capturing), Quoted(cleared.Value), cleared.Text == seen.NotBound and "shows Not bound in grey" or ("shows " .. Quoted(cleared.Text) .. ", not Not bound in grey"),
                Ended(cleared) and "ended" or "still open", Follows(cleared)))
        end
    }
end

-- The window's size (WindowLayout.lua): as wide as the game's window plus the help pane, resizable in height only, from
-- lib.Internal.Geometry.MinHeight to the screen's height, the bounds ApplyWidth sets through SetResizeBounds and the game
-- holds a drag to. A saved size comes in through the window's Init, which takes the window's shared block
-- (lib.Internal.GetFrame) and is the only function of the window that takes a size: it keeps the height at least
-- MinHeight, ignores the width, and has ApplyWidth bring the window back onto the screen. The step reads the bounds, gives
-- Init a block with a size below them and one above them (the window's other fields as they are, and no place), and
-- checks the window inside the bounds each time, and that applying a size wrote nothing to the saved state. The large one
-- stays for the screenshot; then the height and place go back (Restore too, should the run stop first). No drag, no mouse.
local smallSize, largeSize = { 400, 100 }, { 5000, 5000 }

-- A value as text whatever its keys' order, to tell whether a saved block changed
local function Flat(value)
    if type(value) ~= "table" then return tostring(value) end
    local parts = {}
    for key, inner in next, value do parts[#parts + 1] = tostring(key) .. "=" .. Flat(inner) end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
end

-- The window's saved state: the library's own copy and the fixture's block (internals, read knowingly)
local function SavedState()
    return Flat(Internal().Shared) .. Flat(fixtures.Tab:GetSaved().Window)
end

-- The window's height and anchors, as resize finds them
local function SizeOf(frame)
    local points = {}
    for i = 1, frame:GetNumPoints() do points[i] = { frame:GetPoint(i) } end
    return { Height = frame:GetHeight(), Points = points }
end

-- Puts back what SizeOf read, through the window's own layout: ApplyWidth without keepLeft saves nothing
local function PutSizeBack(frame, before)
    frame:SetHeight(before.Height)
    frame:ClearAllPoints()
    for _, point in ipairs(before.Points) do frame:SetPoint(point[1], point[2], point[3], point[4], point[5]) end
    frame:ApplyWidth()
    frame:Layout()
    frame:ReloadSection()
    before.Done = true
end

-- The bounds a drag is held to, as the game reports them ({ minWidth, minHeight, maxWidth, maxHeight }), or nil on a
-- client without GetResizeBounds
local function ResizeBounds(frame)
    if not frame.GetResizeBounds then return nil end
    local minWidth, minHeight, maxWidth, maxHeight = frame:GetResizeBounds()
    return { minWidth, minHeight, maxWidth, maxHeight }
end

local function ResizeStep()
    local seen
    -- A saved block with this size, the window's other fields as they are and no place, through the window's Init
    local function Apply(frame, size)
        frame:Init({ Size = { size[1], size[2] }, PaneCollapsed = frame.PaneCollapsed, SearchAll = frame.SearchEveryTab,
            SearchBroad = frame.BroadSearch })
        return { Width = frame:GetWidth(), Height = frame:GetHeight() }
    end
    local function Inside(size, bounds)
        return size.Width >= bounds[1] - 0.5 and size.Width <= bounds[3] + 0.5 and size.Height >= bounds[2] - 0.5 and size.Height <= bounds[4] + 0.5
    end
    local function Near(a, b)
        return math.abs(a - b) < 0.5
    end
    local function Range(bounds)
        return ("%gx%g to %gx%g"):format(bounds[1], bounds[2], bounds[3], bounds[4])
    end
    return {
        Name = "resize",
        Text = "the window's resize bounds, and a saved size outside them brought inside",
        Run = function()
            local frame = Window()
            seen = { Saved = SavedState() }
            live.SizeBefore = live.SizeBefore or SizeOf(frame)
            seen.Bounds = ResizeBounds(frame)
            seen.Small = Apply(frame, smallSize)
            Apply(frame, largeSize)
        end,
        Check = function()
            local frame = Window()
            local internal = Internal()
            local width = internal.WindowWidth(frame.PaneCollapsed)
            local minHeight = internal.Geometry.MinHeight
            local expected = { width, minHeight, width, math.max(minHeight, UIParent:GetHeight() / frame:GetScale()) }
            local bounds = seen.Bounds
            if not bounds then
                Add("SKIP", ("1 bounds: this client has no GetResizeBounds, so the bounds the layout sets cannot be read; 2 and 3 hold the window to the expected %s"):format(
                    Range(expected)))
            else
                local ok = Near(bounds[1], expected[1]) and Near(bounds[2], expected[2]) and Near(bounds[3], expected[3]) and Near(bounds[4], expected[4])
                Add(ok and "PASS" or "FAIL", ("1 bounds: %s (%s expected: the width fixed, the height from MinHeight to the screen's)"):format(
                    Range(bounds), Range(expected)))
            end
            -- Inside the bounds the game reports and the ones the layout means
            local function Report(number, size, measured)
                local ok = Inside(measured, expected) and (not bounds or Inside(measured, bounds))
                Add(ok and "PASS" or "FAIL", ("%d a saved size of %dx%d: the window %gx%g, %s the bounds %s"):format(number, size[1], size[2],
                    measured.Width, measured.Height, ok and "inside" or "outside", Range(bounds or expected)))
            end
            Report(2, smallSize, seen.Small)
            Report(3, largeSize, { Width = frame:GetWidth(), Height = frame:GetHeight() })
            local untouched = SavedState() == seen.Saved
            Add(untouched and "PASS" or "FAIL", ("4 saved state: applying the two sizes %s the window's saved state"):format(untouched and "left" or "changed"))
            After(afterShot / 2, function()
                PutSizeBack(Window(), live.SizeBefore)
            end)
        end
    }
end

-- [[ Show me, the window's combat signal, Defaults, the buttons in rows, All / None and the tab list's arrows ]] --
-- The release hardening (docs/work/2026-11-07-release-hardening, spec requirements 1 to 7), through the window's own
-- functions and the buttons' own OnClick (Click(), as a player's click runs it), as the steps above. Window's Show me
-- answers what the steps set (Fixtures.lua); Tooltips' help lays the test addon's secure stand-in over it
-- (ShowMeStandIn.lua). No step fires a game event, binds a key or sets a CVar.
local standIn = tests.ShowMeStandIn
local showMeSection, secureSection = "window", "tooltips" -- the fixture's help with ShowMe, and the one with ShowMeSecure

-- Where a region stands on the screen: its left, bottom, width and height times its effective scale, or nil while it has
-- no place
local function ScreenRect(region)
    local left, bottom = region:GetLeft(), region:GetBottom()
    if not left or not bottom then return nil end
    local scale = region:GetEffectiveScale()
    return { left * scale, bottom * scale, region:GetWidth() * scale, region:GetHeight() * scale }
end

local function RectText(rect)
    return rect and ("%.0f,%.0f %.0fx%.0f"):format(rect[1], rect[2], rect[3], rect[4]) or "no place"
end

-- Whether the stand-in is shown over the owner, each edge within 1 on the screen, and where both stand
local function LiesOver(owner)
    local shown = standIn ~= nil and standIn.IsShown()
    local mine, theirs = shown and ScreenRect(standIn.Button) or nil, ScreenRect(owner)
    local over = mine ~= nil and theirs ~= nil
    for i = 1, 4 do
        if over and math.abs(mine[i] - theirs[i]) > 1 then over = false end
    end
    return over, ("the stand-in %s, Show me at %s"):format(shown and ("at " .. RectText(mine)) or "hidden", RectText(theirs))
end

-- The stand-in's calls after its first since: whether one handed it owner with a close function, and whether one let it go
local function CallsSince(since, owner)
    local laid, released = false, false
    for i = since + 1, #standIn.Calls do
        local call = standIn.Calls[i]
        if call.Owner == nil then
            released = true
        elseif call.Owner == owner and type(call.Close) == "function" then
            laid = true
        end
    end
    return laid, released
end

-- What the help pane shows of Show me: the button, whether it takes a click, and the note beside it or in its place
local function ShowMeState(frame)
    local note = frame.ShowMeNote
    return { Shown = frame.ShowMeButton:IsShown() and true or false, Enabled = frame.ShowMeButton:IsEnabled() and true or false,
        Note = note:IsShown() and note:GetText() or nil }
end

local function ShowMeText(state)
    return ("Show me %s%s, %s"):format(state.Shown and "shown" or "hidden", state.Shown and (state.Enabled and " and enabled" or " and greyed") or "",
        state.Note and ("the note '" .. state.Note .. "'") or "no note")
end

-- A check read a second after its state was set finds the help of whatever row the resting mouse came to lie on, which
-- hides Show me by design (Mists, 2026-11-07: the window lay under the pointer there). That help goes away as when the
-- mouse leaves the row, and the line names the row; nil when no row had it
local function PutHoverAway(frame)
    local option = frame.HoverOption
    if not option then return nil end
    frame:ShowSectionHelp()
    frame:UpdateShowMe() -- Show me was hidden until just now: a stand-in laid over it finds its place in this call
    local ok, label = pcall(option.GetLabel, option)
    return " (the resting mouse had brought up " .. tostring(ok and label or option.Id) .. "'s help: put away first)"
end

-- The window on a section with the help pane open
local function OnSection(sectionId, optionId)
    local frame = Window()
    if frame.PaneCollapsed then frame:SetPaneCollapsed(false) end
    frame:ShowSection(sectionId, optionId)
    return frame
end

-- The frames Show me's spot can give the mouse to, by name (MouseOn)
local function ShowMeParts(frame)
    local named = { [frame.ShowMeButton] = "the library's Show me button" }
    if standIn and standIn.Button then named[standIn.Button] = "the stand-in" end
    return named
end

-- The window's anchors, and putting them back
local function PointsOf(frame)
    local points = {}
    for i = 1, frame:GetNumPoints() do points[i] = { frame:GetPoint(i) } end
    return points
end

local function PutPointsBack(frame, points)
    frame:ClearAllPoints()
    for _, point in ipairs(points) do frame:SetPoint(point[1], point[2], point[3], point[4], point[5]) end
end

-- An offset toward the screen's middle, so being kept on the screen (SetClampedToScreen) does not stop the move
local function TowardCentre(frame)
    local x, y = frame:GetCenter()
    local midX, midY = UIParent:GetCenter()
    if not x or not midX then return 40, -30 end
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return x * scale < midX and 40 or -40, y * scale < midY and 30 or -30
end

-- Every option of a fixture section that holds a value Restore can put back: rows and what they carry, a family's
-- members, grid cells and tabs' Show; not a button (execute) or a key row, which hold none of their own
local function ValueOptions(sectionId)
    local list, kept = {}, {}
    local function Keep(option)
        if option and not kept[option] and option.Type ~= "execute" and option.Type ~= "key" then
            kept[option] = true
            list[#list + 1] = option
        end
    end
    for _, element in ipairs(fixtures.GetElements(sectionId)) do
        Keep(element.Option)
        Keep(element.With)
        for _, member in ipairs(element.Members or {}) do Keep(member) end
        for _, gridRow in ipairs(element.Rows or {}) do
            for _, cell in ipairs(gridRow.Cells or {}) do Keep(cell) end
        end
        for _, item in ipairs(element.Items or {}) do Keep(item.Show) end
    end
    return list
end

-- The reload bar, lit as the window shows it
local function ReloadLit(frame)
    return frame.ReloadPending and frame.ReloadButton:IsShown() and frame.ReloadBackground:IsShown() and true or false
end

-- After a step's screenshot: the reload bar as it was before the run (live.ReloadBefore, which undo-reload's pattern keeps)
local function ReloadBarBack()
    local frame = Window()
    frame.ReloadPending = live.ReloadBefore.Value
    frame:RefreshFooter()
end

-- Show me on Window (spec requirement 1). Its help's CanShowMe and ShowMe answer what the step sets, and ShowMe counts its
-- runs (Fixtures.lua). A click (WindowHelp.lua, LoadHelp) does nothing while CanShowMe is false; else it closes the window,
-- runs ShowMe and shows the window again when ShowMe answers false. Then an option's help and the collapsed pane hide
-- the button. The answers go back once the clicks are done (Restore too, should the step stop first).
local function ShowMeStep()
    local seen
    -- Show me clicked: how often ShowMe ran, and whether the window is shown and on which section
    local function Click(frame)
        local runs = fixtures.ShowMeRuns or 0
        frame.ShowMeButton:Click()
        return { Runs = (fixtures.ShowMeRuns or 0) - runs, Shown = frame:IsShown() and true or false, Section = frame.SectionId }
    end
    return {
        Name = "show-me",
        Text = "Show me on Window: its answers, and hidden under an option's help or a collapsed pane",
        Run = function()
            if InCombatLockdown() then return "in combat: Show me does nothing in combat" end
            local frame = OnSection(showMeSection, toggleId)
            seen = { Start = ShowMeState(frame) }
            fixtures.CanShowMeAnswer = false
            seen.Cannot = Click(frame)
            fixtures.CanShowMeAnswer, fixtures.ShowMeAnswer = true, false
            seen.False = Click(frame)
            seen.False.State = ShowMeState(frame)
            fixtures.ShowMeAnswer = nil
            seen.Nothing = Click(frame)
            if not frame:IsShown() then fixtures.Tab:Open(showMeSection) end
            seen.Nothing.Reopened = frame:IsShown() and frame.SectionId == showMeSection
            fixtures.ShowMeAnswer, fixtures.CanShowMeAnswer = live.AnswersBefore.ShowMe, live.AnswersBefore.CanShowMe
            local _, option = FindOption(toggleId)
            local row = option and RowOf(option)
            if row then
                row:OnEnter(row.Toggle)
                seen.Hover = { Explains = frame.HoverOption == option, State = ShowMeState(frame) }
                row:OnLeave()
                seen.Hover.After = ShowMeState(frame)
            end
            frame:SetPaneCollapsed(true)
            seen.Collapsed = ShowMeState(frame)
            frame:SetPaneCollapsed(false)
            seen.Open = ShowMeState(frame)
        end,
        Check = function()
            local start, cannot, answered, nothing = seen.Start, seen.Cannot, seen.False, seen.Nothing
            Add(start.Shown and start.Enabled and "PASS" or "FAIL", ("1 on Window with the pane open: %s"):format(ShowMeText(start)))
            Add(cannot.Runs == 0 and cannot.Shown and "PASS" or "FAIL", ("2 CanShowMe answering false, then a click: ShowMe ran %d time(s) (0 expected), the window %s"):format(
                cannot.Runs, cannot.Shown and "stays open" or "closed"))
            local againOk = answered.Runs == 1 and answered.Shown and answered.Section == showMeSection and answered.State.Shown and answered.State.Enabled
            Add(againOk and "PASS" or "FAIL", ("3 ShowMe answering false, then a click: ShowMe ran %d time(s) (1 expected), the window %s on %s, %s"):format(
                answered.Runs, answered.Shown and "shown again" or "closed", tostring(answered.Section), ShowMeText(answered.State)))
            Add(nothing.Runs == 1 and not nothing.Shown and nothing.Reopened and "PASS" or "FAIL", ("4 ShowMe answering nothing, then a click: ShowMe ran %d time(s) (1 expected), the window %s; opened again on Window %s"):format(
                nothing.Runs, nothing.Shown and "stays open" or "stays closed", nothing.Reopened and "yes" or "no"))
            local hover = seen.Hover
            if not hover then
                Add("FAIL", ("5 an option's help: %s's row is not drawn"):format(toggleId))
            else
                Add(hover.Explains and not hover.State.Shown and hover.After.Shown and "PASS" or "FAIL", ("5 the mouse on %s's row: the pane %s, %s; after it left, %s"):format(
                    toggleId, hover.Explains and "explains it" or "does not explain it", ShowMeText(hover.State), ShowMeText(hover.After)))
            end
            Add(not seen.Collapsed.Shown and seen.Open.Shown and "PASS" or "FAIL", ("6 the pane collapsed: %s; open again: %s"):format(
                ShowMeText(seen.Collapsed), ShowMeText(seen.Open)))
        end
    }
end

-- Show me with a secure button laid over it (spec requirement 2), the library's side of KAF's map help: Tooltips' help has
-- ShowMeSecure, served by the stand-in, which records each call. WindowHelp.lua's UpdateShowMe calls it with Show me's
-- button and a close function whenever Tooltips' own help is drawn with the pane open, again after the window's drag ends
-- (WindowLayout.lua, OnDragStop), and with nil as soon as that help is not drawn. The window is moved by its anchors and
-- told its drag ended, as a drag does; then it is put back and told again, so its saved place is the old one (Restore
-- puts the anchors back too, should the step stop between). Each let-go is undone again and the stand-in must lie over
-- Show me again after it. An error in ShowMeSecure is proven headless only (ContractAndErrors 16j): in game a deliberate
-- error would fail the run's lua-errors step.
local secureHoverId = "tooltips.details" -- the row whose help hides Show me

local function ShowMeSecureStep()
    local seen
    -- What act did (a let-go call, the stand-in hidden), then what undo did (laid over Show me again); act returns why it
    -- could not act
    local function LetGo(frame, what, act, undo)
        local button = frame.ShowMeButton
        local mark = #standIn.Calls
        local result = { What = what, Missing = act() }
        if not result.Missing then
            local _, released = CallsSince(mark, button)
            result.Released, result.Hidden = released, not standIn.IsShown()
            mark = #standIn.Calls
            undo()
            result.Again = (CallsSince(mark, button))
            result.Over = (LiesOver(button))
            -- Show me hidden just before can have no place yet in this call: the stand-in then lies over it a frame later,
            -- as KAF's does; check 8 reads the final place
            result.Pending = not result.Over and standIn.Pending
        end
        return result
    end
    return {
        Name = "show-me-secure",
        Text = "Tooltips' Show me with a secure stand-in: laid over, moved along, let go, refused",
        Run = function()
            if InCombatLockdown() then return "in combat: the stand-in is laid over out of combat only" end
            if not standIn then return "no stand-in: ShowMeStandIn.lua did not load" end
            local frame = Window()
            local button = frame.ShowMeButton
            wipe(standIn.Calls)
            seen = {}
            -- 1 drawn with the pane open
            OnSection(secureSection)
            seen.Drawn = { Called = (CallsSince(0, button)) }
            seen.Drawn.Over, seen.Drawn.Where = LiesOver(button)
            -- 2 moved, then back to its place
            local points = PointsOf(frame)
            live.PointBefore = { Points = points }
            local dx, dy = TowardCentre(frame)
            local before = ScreenRect(button)
            local mark = #standIn.Calls
            frame:ClearAllPoints()
            for _, point in ipairs(points) do frame:SetPoint(point[1], point[2], point[3], point[4] + dx, point[5] + dy) end
            frame:OnDragStop()
            local after = ScreenRect(button)
            local moved = before ~= nil and after ~= nil and (math.abs(after[1] - before[1]) > 1 or math.abs(after[2] - before[2]) > 1)
            seen.Moved = { Called = (CallsSince(mark, button)), Moved = moved,
                By = before and after and ("%.0f,%.0f"):format(after[1] - before[1], after[2] - before[2]) or "?" }
            seen.Moved.Over, seen.Moved.Where = LiesOver(button)
            PutPointsBack(frame, points)
            frame:OnDragStop()
            live.PointBefore.Done = true
            seen.Back = {}
            seen.Back.Over, seen.Back.Where = LiesOver(button)
            -- 3 to 6 let go, each undone
            local row
            seen.LetGo = {
                LetGo(frame, "another section drawn (Debug)", function() frame:ShowSection("debug") end,
                    function() frame:ShowSection(secureSection) end),
                LetGo(frame, "an option's help shown", function()
                    local _, option = FindOption(secureHoverId)
                    row = option and RowOf(option)
                    if not row then return secureHoverId .. "'s row is not drawn" end
                    row:OnEnter(row.Toggle)
                end, function() row:OnLeave() end),
                LetGo(frame, "the pane collapsed", function() frame:SetPaneCollapsed(true) end, function() frame:SetPaneCollapsed(false) end),
                LetGo(frame, "the window hidden", function() frame:Hide() end, function() fixtures.Tab:Open(secureSection) end),
            }
            -- 7 answering false, then 8 true again (read at the check, as the screenshot shows it)
            standIn.AnswerFalse = true
            frame:Refresh()
            local help = fixtures.Tab.Config.GetHelp(secureSection)
            seen.Refused = { State = ShowMeState(frame), Hidden = not standIn.IsShown(), Note = help and help.ShowMeNote }
            standIn.AnswerFalse = false
            frame:Refresh()
        end,
        Check = function()
            local frame = Window()
            local drawn, moved = seen.Drawn, seen.Moved
            Add(drawn.Called and drawn.Over and "PASS" or "FAIL", ("1 Tooltips drawn, the pane open: ShowMeSecure %s with Show me's button and a close function; %s"):format(
                drawn.Called and "called" or "not called", drawn.Where))
            if not moved.Moved then
                Add("SKIP", ("2 the window moved by its anchors and its drag end: Show me moved by %s, so the window could not move (it fills the screen)"):format(moved.By))
            else
                Add(moved.Called and moved.Over and seen.Back.Over and "PASS" or "FAIL", ("2 the window moved (Show me by %s) and its drag ended: ShowMeSecure %s; %s; back at its place, %s"):format(
                    moved.By, moved.Called and "called again" or "not called again", moved.Where, seen.Back.Over and "over Show me there too" or seen.Back.Where))
            end
            for i, result in ipairs(seen.LetGo) do
                if result.Missing then
                    Add("FAIL", ("%d %s: %s"):format(2 + i, result.What, result.Missing))
                else
                    Add(result.Released and result.Hidden and result.Again and (result.Over or result.Pending) and "PASS" or "FAIL", ("%d %s: %s, the stand-in %s; after it, %s"):format(
                        2 + i, result.What, result.Released and "let go (called with nil)" or "not let go", result.Hidden and "hidden" or "still shown",
                        result.Again and result.Over and "laid over Show me again"
                            or result.Again and result.Pending and "called again, laid over next frame (Show me had no place yet)"
                            or result.Again and "called again but not over Show me" or "not called again"))
                end
            end
            local refused = seen.Refused
            local note = type(refused.Note) == "string" and refused.Note or nil
            Add(not refused.State.Shown and refused.Hidden and note ~= nil and refused.State.Note == note and "PASS" or "FAIL", ("%d the stand-in answering false: %s ('%s' expected), the stand-in %s"):format(
                3 + #seen.LetGo, ShowMeText(refused.State), tostring(note), refused.Hidden and "hidden" or "shown"))
            local hovered = PutHoverAway(frame)
            local over, where = LiesOver(frame.ShowMeButton)
            local state = ShowMeState(frame)
            Add(over and state.Shown and not state.Note and "PASS" or "FAIL", ("%d answering true again: %s; %s%s"):format(4 + #seen.LetGo, ShowMeText(state), where,
                hovered or ""))
        end
    }
end

-- The window told combat starts and ends (spec requirement 3): its own OnEvent with PLAYER_REGEN_DISABLED, then
-- PLAYER_REGEN_ENABLED, called directly. That is the window's signal, the path the game's event takes, not a fight: a run
-- cannot start one, and the runner stops in a real one. What only InCombatLockdown() guards (Show me's click, a key
-- capture's start and end) is not covered. In the start's refresh the window counts as in combat (CombatStarting,
-- WindowMixin.lua) and greys what cannot run in it; the end's refresh enables it again. On Key bindings, with a capture
-- open: the capture ends, the key buttons and Reload Now grey (Reload Now whether its bar shows or not). On Window, Show
-- me greys with the "not in combat" note. The start is told once more for the screenshot, the end after it (Restore too).
local function CombatStep()
    local seen
    -- The key rows as drawn: how many key buttons show and how many take a click, Reload Now, and the capture of the row
    local function ReadKeys(frame, option)
        local count, enabled = 0, 0
        ForEachRow(function(row)
            if row.Option and row.Option.Type == "key" then
                for _, button in ipairs({ row.Key1, row.Key2 }) do
                    if button:IsShown() then
                        count = count + 1
                        if button:IsEnabled() then enabled = enabled + 1 end
                    end
                end
            end
        end)
        local row = RowOf(option)
        return { Count = count, Enabled = enabled, Reload = frame.ReloadButton:IsEnabled() and true or false,
            Capturing = row and row.Capturing, Keyboard = row ~= nil and row.Key1:IsKeyboardEnabled() and true or false }
    end
    local function KeysText(read)
        return ("%d of %d key buttons enabled, Reload Now %s"):format(read.Enabled, read.Count, read.Reload and "enabled" or "greyed")
    end
    return {
        Name = "combat",
        Text = "the window's own combat signal (no fight): key buttons, Reload Now and Show me grey, then return",
        Run = function()
            if InCombatLockdown() then return "in combat: the step tells the window combat starts, out of combat only" end
            local frame = Window()
            local sectionId, option = FindOption(keyId)
            if not option or not option.Slots then return keyId .. " is no key option in any section" end
            frame:ShowSection(sectionId, keyId)
            local row = RowOf(option)
            if not row then return "its row is not drawn" end
            seen = {}
            row:StartKeyCapture(1)
            seen.Captured = row.Capturing == 1
            frame:OnEvent("PLAYER_REGEN_DISABLED")
            seen.KeysStart = ReadKeys(frame, option)
            frame:EndKeyCaptures() -- should the start have left the capture open, no button keeps the keyboard
            frame:OnEvent("PLAYER_REGEN_ENABLED")
            seen.KeysEnd = ReadKeys(frame, option)
            OnSection(showMeSection)
            seen.Before = ShowMeState(frame)
            frame:OnEvent("PLAYER_REGEN_DISABLED")
            seen.Start = ShowMeState(frame)
            frame:OnEvent("PLAYER_REGEN_ENABLED")
            seen.End = ShowMeState(frame)
            live.CombatSignalled = true
            frame:OnEvent("PLAYER_REGEN_DISABLED")
        end,
        Check = function()
            local frame = Window()
            local notInCombat = frame.Strings.NotInCombat
            local start, ended = seen.KeysStart, seen.KeysEnd
            local captureEnded = seen.Captured and start.Capturing == nil and not start.Keyboard
            Add(start.Count > 0 and start.Enabled == 0 and not start.Reload and captureEnded and "PASS" or "FAIL", ("1 Key bindings, the window's own signal that combat starts (not a fight): %s; the open capture %s"):format(
                KeysText(start), not seen.Captured and "did not start" or captureEnded and "ended" or "stays open"))
            Add(ended.Count > 0 and ended.Enabled == ended.Count and ended.Reload and "PASS" or "FAIL", ("2 the window's signal that combat ends: %s"):format(KeysText(ended)))
            local before, greyed, back = seen.Before, seen.Start, seen.End
            Add(before.Shown and greyed.Shown and not greyed.Enabled and greyed.Note == notInCombat and "PASS" or "FAIL", ("3 Window, combat starts: %s ('%s' expected), before it %s"):format(
                ShowMeText(greyed), tostring(notInCombat), ShowMeText(before)))
            Add(back.Shown and back.Enabled and not back.Note and "PASS" or "FAIL", ("4 Window, combat ends: %s"):format(ShowMeText(back)))
            -- Putting a hovered row's help away refreshes Show me out of the signal, so the signal is sent once more after it
            local hovered = PutHoverAway(frame)
            if hovered then frame:OnEvent("PLAYER_REGEN_DISABLED") end
            local shot = ShowMeState(frame)
            Add(shot.Shown and not shot.Enabled and shot.Note == notInCombat and "PASS" or "FAIL", ("5 told again for the screenshot: %s%s"):format(ShowMeText(shot),
                hovered or ""))
            After(afterShot / 2, function()
                live.CombatSignalled = nil
                Window():OnEvent("PLAYER_REGEN_ENABLED")
            end)
        end
    }
end

-- Defaults (spec requirement 4), clicked through Click(): it asks in the page's header (Yes in its place, No beside it),
-- No ends the question, Yes runs the fixture's ResetSection, which counts its calls per section (Fixtures.lua,
-- ResetCalls) and answers whether an option it set back needs a reload (WindowPage.lua, ResetSection). First Window with
-- Use the old look changed, which needs a reload: the reload bar is put out first, so what lights it is Yes. Then Debug,
-- where the steps before may have left an option changed (dropdown's Profile): those are set back through their options,
-- then Trace calls and Log file are changed through their rows and Tooltips' Compact lines through its option, so Debug
-- counts exactly 2. Every option of both sections is remembered first, since Yes sets them all back. The reload bar goes
-- back after the screenshot (Restore too).
local defaultsToggleId, defaultsInputId, elsewhereId, reloadOptionId = "debug.trace", "debug.logFile", "tooltips.compact", "window.oldLook"
local typedLog = "test.log"

local function DefaultsStep()
    local seen
    -- The page's header: the changed count and whether the footer agrees, its text, Defaults (enabled, or reading Yes) and No
    local function Header(frame, sectionId)
        local footer, count = FooterAgrees(sectionId)
        return { Count = count, Footer = footer, Text = frame.ChangedText:GetText() or "", Enabled = frame.DefaultsButton:IsEnabled() and true or false,
            Yes = frame.DefaultsButton:GetText() == YES, No = frame.CancelButton:IsShown() and true or false }
    end
    local function Resets(sectionId)
        return fixtures.ResetCalls[sectionId] or 0
    end
    return {
        Name = "defaults",
        Text = "Defaults asks, No keeps all, Yes sets the section back; a reload's reset lights the bar",
        Run = function()
            local frame = Window()
            local reloadSection, reloadOption = FindOption(reloadOptionId)
            local debugSection, toggle = FindOption(defaultsToggleId)
            local _, input = FindOption(defaultsInputId)
            local elsewhereSection, elsewhere = FindOption(elsewhereId)
            if not (reloadOption and toggle and input and elsewhere) then
                return ("%s, %s, %s or %s is in no section"):format(reloadOptionId, defaultsToggleId, defaultsInputId, elsewhereId)
            end
            seen = { Section = debugSection, ElsewhereSection = elsewhereSection, Toggle = toggle, Input = input, Elsewhere = elsewhere,
                Question = frame.Strings.ResetSection:format(fixtures.SectionName(debugSection)) }
            -- 1 the reload
            live.ReloadBefore = live.ReloadBefore or { Value = frame.ReloadPending }
            for _, option in ipairs(ValueOptions(reloadSection)) do Remember(option) end
            frame:ShowSection(reloadSection, reloadOptionId)
            local row = RowOf(reloadOption)
            if not row then return reloadOptionId .. "'s row is not drawn" end
            if not reloadOption:IsChanged() then row.Toggle:Click() end
            frame.ReloadPending = nil
            frame:RefreshFooter()
            local before = Resets(reloadSection)
            seen.Reload = { Changed = reloadOption:IsChanged(), Out = not frame.ReloadButton:IsShown() }
            frame.DefaultsButton:Click()
            seen.Reload.Asked = frame.CancelButton:IsShown() and true or false
            frame.DefaultsButton:Click()
            seen.Reload.Resets = Resets(reloadSection) - before
            seen.Reload.Back = not reloadOption:IsChanged()
            seen.Reload.Lit = ReloadLit(frame)
            -- 2 to 5 Debug
            for _, option in ipairs(ValueOptions(debugSection)) do
                Remember(option)
                if option:IsChanged() then option:Reset() end
            end
            Remember(elsewhere)
            if not elsewhere:IsChanged() then elsewhere:Set(not elsewhere:Get()) end
            frame:ShowSection(debugSection, defaultsToggleId)
            row = RowOf(toggle)
            if row then row.Toggle:Click() end
            row = RowOf(input)
            if row then
                row.Input:SetText(typedLog)
                row.Input:GetScript("OnEnterPressed")(row.Input)
            end
            seen.Changed = Header(frame, debugSection)
            seen.Changed.Toggle, seen.Changed.Input = toggle:IsChanged(), input:IsChanged()
            frame.DefaultsButton:Click()
            seen.Asked = Header(frame, debugSection)
            before = Resets(debugSection)
            frame.CancelButton:Click()
            seen.No = Header(frame, debugSection)
            seen.No.Resets, seen.No.Toggle, seen.No.Input = Resets(debugSection) - before, toggle:IsChanged(), input:IsChanged()
            frame.DefaultsButton:Click()
            frame.DefaultsButton:Click()
            seen.YesResets = Resets(debugSection) - before
        end,
        Check = function()
            local frame = Window()
            local reload = seen.Reload
            Add(reload.Changed and reload.Out and reload.Asked and reload.Resets == 1 and reload.Back and reload.Lit and "PASS" or "FAIL",
                ("1 Window with %s changed and the reload bar put out (%s): Defaults %s, Yes ran ResetSection %d time(s) (1 expected), the option %s, the reload bar %s"):format(
                    reloadOptionId, reload.Out and "out" or "still lit", reload.Asked and "asked" or "did not ask", reload.Resets,
                    reload.Back and "back at its default" or "still changed", reload.Lit and "lit" or "not lit"))
            local changed = seen.Changed
            Add(changed.Toggle and changed.Input and changed.Count == 2 and changed.Footer and changed.Enabled and "PASS" or "FAIL",
                ("2 %s with %s and %s changed through their rows (and %s): it counts %d (2 expected), the footer %s ('%s'), Defaults %s"):format(
                    seen.Section, defaultsToggleId, defaultsInputId, elsewhereId, changed.Count, changed.Footer and "follows" or "wrong", changed.Text,
                    changed.Enabled and "enabled" or "greyed"))
            local asked = seen.Asked
            Add(asked.Yes and asked.No and asked.Text == seen.Question and "PASS" or "FAIL", ("3 Defaults: the header asks '%s' ('%s' expected), Defaults reads %s, No %s"):format(
                asked.Text, seen.Question, asked.Yes and "Yes" or "something else", asked.No and "shown" or "hidden"))
            local no = seen.No
            Add(no.Resets == 0 and no.Toggle and no.Input and not no.No and not no.Yes and no.Count == 2 and no.Footer and "PASS" or "FAIL",
                ("4 No: ResetSection ran %d time(s) (0 expected), both options %s, the question %s, the count %d"):format(no.Resets,
                    no.Toggle and no.Input and "still changed" or "set back", not no.No and not no.Yes and "gone" or "still asked", no.Count))
            -- 5 read as the screenshot shows it
            local toggle, input = seen.Toggle, seen.Input
            local toggleRow, inputRow = RowOf(toggle), RowOf(input)
            local back = not toggle:IsChanged() and not input:IsChanged()
            local rows = toggleRow ~= nil and inputRow ~= nil and (toggleRow.Toggle:GetChecked() and true or false) == (toggle:Get() and true or false)
                and not toggleRow.ChangedBar:IsShown() and inputRow.Input:GetText() == tostring(input:Get()) and not inputRow.ChangedBar:IsShown()
            local header = Header(frame, seen.Section)
            local kept = seen.Elsewhere:IsChanged() and fixtures.ChangedCount(seen.ElsewhereSection) > 0
            Add(seen.YesResets == 1 and back and rows and header.Count == 0 and header.Footer and not header.Enabled and kept and "PASS" or "FAIL",
                ("5 Defaults, then Yes: ResetSection ran %d time(s) for %s (1 expected), both options %s, their rows %s, the count %d, Defaults %s, %s %s"):format(
                    seen.YesResets, seen.Section, back and "back at their defaults" or "still changed", rows and "show it" or "do not show it",
                    header.Count, header.Enabled and "enabled" or "greyed", elsewhereId, kept and "still changed" or "set back too"))
            After(afterShot / 2, ReloadBarBack)
        end
    }
end

-- Buttons in rows (spec requirement 5), clicked through Click(): a button row (Debug's Reset everything, which needs a
-- reload) and the button beside a check box (Window's Reset main window position, the With of Remember main window
-- position). The fixture's button options count their runs in Set (Fixtures.lua, Runs), and every button of the fixture
-- is counted before and after each click, so a click that runs another one shows. The reload bar is put out first, so
-- what lights it is the click; it goes back after the screenshot (Restore too).
local plainButtonId, besideButtonId = "debug.resetAll", "window.resetMain"

local function ExecuteStep()
    local seen
    local function Buttons()
        local list = {}
        for _, option in next, fixtures.Options do
            if option.Type == "execute" then list[#list + 1] = option end
        end
        table.sort(list, function(a, b) return a.Id < b.Id end)
        return list
    end
    local function Runs(buttons)
        local runs = {}
        for i, option in ipairs(buttons) do runs[i] = option.Runs or 0 end
        return runs
    end
    -- The buttons that ran since before, as "id xN"
    local function Ran(buttons, before)
        local ran = {}
        for i, option in ipairs(buttons) do
            local count = (option.Runs or 0) - before[i]
            if count ~= 0 then ran[#ran + 1] = ("%s x%d"):format(option.Id, count) end
        end
        return ran
    end
    -- The check box that carries a button as its With: its section, the check box and the button
    local function FindBeside(withId)
        for _, sectionId in ipairs(fixtures.Sections) do
            for _, element in ipairs(fixtures.GetElements(sectionId)) do
                if element.With and element.With.Id == withId then return sectionId, element.Option, element.With end
            end
        end
    end
    local function OnlyOnce(ran, option)
        return #ran == 1 and ran[1] == option.Id .. " x1"
    end
    return {
        Name = "execute",
        Text = "a button row and a check box's button each run their own option once",
        Run = function()
            local frame = Window()
            local plainSection, plain = FindOption(plainButtonId)
            local besideSection, owner, beside = FindBeside(besideButtonId)
            if not plain or not beside then return ("%s or %s is in no section"):format(plainButtonId, besideButtonId) end
            local buttons = Buttons()
            frame:ShowSection(plainSection, plainButtonId)
            local row = RowOf(plain)
            if not row then return plainButtonId .. "'s row is not drawn" end
            seen = { Plain = plain, Beside = beside, Owner = owner }
            live.ReloadBefore = live.ReloadBefore or { Value = frame.ReloadPending }
            frame.ReloadPending = nil
            frame:RefreshFooter()
            seen.Out = not frame.ReloadButton:IsShown()
            local before = Runs(buttons)
            row.Execute:Click()
            seen.PlainRan, seen.Lit = Ran(buttons, before), ReloadLit(frame)
            frame:ShowSection(besideSection, besideButtonId)
            row = RowOf(owner)
            if not row then
                seen.BesideMissing = true
                return
            end
            local value = owner:Get()
            before = Runs(buttons)
            row.Execute:Click()
            seen.BesideRan, seen.Kept = Ran(buttons, before), owner:Get() == value
        end,
        Check = function()
            local plain, beside = seen.Plain, seen.Beside
            Add(OnlyOnce(seen.PlainRan, plain) and seen.Out and seen.Lit and "PASS" or "FAIL", ("1 the %s row's button: ran [%s] (%s x1 expected), the reload bar put out first %s, after the click %s"):format(
                plain.Id, table.concat(seen.PlainRan, ", "), plain.Id, seen.Out and "yes" or "no", seen.Lit and "lit" or "not lit"))
            if seen.BesideMissing then
                Add("FAIL", ("2 the button beside %s: its row is not drawn"):format(seen.Owner.Id))
            else
                Add(OnlyOnce(seen.BesideRan, beside) and seen.Kept and "PASS" or "FAIL", ("2 the button beside %s: ran [%s] (%s x1 expected), the check box %s"):format(
                    seen.Owner.Id, table.concat(seen.BesideRan, ", "), beside.Id, seen.Kept and "unchanged" or "changed"))
            end
            After(afterShot / 2, ReloadBarBack)
        end
    }
end

-- A family's All / None (spec requirement 6): Events' Seasons heading, its buttons clicked through Click(). Each sets
-- every member that is not greyed and redraws through OnOptionChanged (RowMixins.lua, SubRowMixin); then each member is
-- read: its saved value, its check box, its changed line, and the footer's count.
local familySection = "events"

local function AllNoneStep()
    local seen
    -- The first family heading the page draws, and its row
    local function Family()
        for _, element in ipairs(Window().Elements or {}) do
            if element.Kind == "Sub" then return element, RowOfElement(element) end
        end
    end
    local function Read(members, want)
        local wrong = {}
        for _, member in ipairs(members) do
            local row = RowOf(member)
            local saved = (member:Get() and true or false) == want
            local ticked = row ~= nil and (row.Toggle:GetChecked() and true or false) == want
            local line = row ~= nil and row.ChangedBar:IsShown() == member:IsChanged()
            if not (saved and ticked and line) then
                wrong[#wrong + 1] = ("%s (saved %s, %s, changed line %s)"):format(member:GetLabel(), tostring(member:Get()),
                    not row and "not drawn" or row.Toggle:GetChecked() and "ticked" or "unticked", line and "follows" or "wrong")
            end
        end
        local footer, count = FooterAgrees(familySection)
        return { Wrong = wrong, Footer = footer, Count = count }
    end
    return {
        Name = "all-none",
        Text = "a family's None turns every member off and All turns them on, saved and shown",
        Run = function()
            Window():ShowSection(familySection)
            local element, row = Family()
            if not element then return familySection .. " draws no family heading" end
            if not row then return "the family's row is not drawn" end
            seen = { Name = element.Text, Members = element.Members }
            for _, member in ipairs(element.Members) do Remember(member) end
            row.None:Click()
            seen.None = Read(element.Members, false)
            element, row = Family()
            if row then
                row.All:Click()
                seen.All = Read(element.Members, true)
            end
        end,
        Check = function()
            local function Report(number, button, read, state)
                if not read then
                    Add("FAIL", ("%d %s on %s: the family's row is not drawn after None"):format(number, button, tostring(seen.Name)))
                    return
                end
                Add(#read.Wrong == 0 and read.Footer and "PASS" or "FAIL", ("%d %s on %s: its %d members %s%s, the footer %s (%d changed)"):format(
                    number, button, tostring(seen.Name), #seen.Members, state,
                    #read.Wrong > 0 and (", except [" .. table.concat(read.Wrong, "; ") .. "]") or ", saved and shown, their changed lines following",
                    read.Footer and "follows" or "wrong", read.Count))
            end
            Report(1, "None", seen.None, "off")
            Report(2, "All", seen.All, "on")
        end
    }
end

-- The tab list's arrows (spec requirement 7), clicked through Click(): the fixture's tab order moves (Fixtures.lua,
-- TabItems) and the page is drawn again (RowMixins.lua, TabRowMixin). The rows are read as drawn, top first: each row's
-- position and name (its Show's, or its source for Blizzard's tab, which has no Show), against the names the fixture's
-- order gives. Restore puts the order back too.
local tabsSection = "tabs"

local function TabArrowsStep()
    local seen
    local function DrawnTabs()
        local rows = {}
        ForEachRow(function(row)
            if row.Element and row.Element.Kind == "TabRow" and row:IsVisible() then rows[#rows + 1] = row end
        end)
        table.sort(rows, function(a, b) return (a:GetTop() or 0) > (b:GetTop() or 0) end)
        return rows
    end
    local function Drawn(rows)
        local names = {}
        for i, row in ipairs(rows) do
            local name = row.Label:GetText()
            if not name or name == "" then name = row.Source:GetText() end
            names[i] = ("%s %s"):format(tostring(row.Position:GetText()), tostring(name))
        end
        return table.concat(names, ", ")
    end
    -- The fixture's Show options are tabs.<key> (Fixtures.lua); Blizzard's tab has none and its row shows its source
    local function Expected(order)
        local names = {}
        for i, key in ipairs(order) do
            local show = fixtures.Options["tabs." .. key]
            names[i] = ("%d %s"):format(i, show and show:GetLabel() or "Blizzard")
        end
        return table.concat(names, ", ")
    end
    local function Read(rows)
        local order = fixtures.GetTabOrder()
        return { Order = order, Drawn = Drawn(rows), Expected = Expected(order) }
    end
    return {
        Name = "tab-arrows",
        Text = "the tab list's arrows: greyed at the ends, Down and Up move a tab and the rows follow",
        Run = function()
            Window():ShowSection(tabsSection)
            local rows = DrawnTabs()
            if #rows < 2 then return ("%s draws %d tab rows, two or more needed"):format(tabsSection, #rows) end
            seen = { Start = Read(rows) }
            seen.FirstUp, seen.LastDown = rows[1].Up:IsEnabled() and true or false, rows[#rows].Down:IsEnabled() and true or false
            rows[1].Down:Click()
            rows = DrawnTabs()
            seen.Down = Read(rows)
            if rows[2] and rows[2].Up:IsEnabled() then
                rows[2].Up:Click()
            else
                seen.UpWhy = rows[2] and "the second row's Up is greyed" or "no second row"
            end
            seen.Up = Read(DrawnTabs())
        end,
        Check = function()
            local start, down, up = seen.Start, seen.Down, seen.Up
            local order = start.Order
            Add(not seen.FirstUp and not seen.LastDown and start.Drawn == start.Expected and "PASS" or "FAIL", ("1 %s: the first row's Up %s, the last row's Down %s; drawn [%s], the fixture's order [%s]"):format(
                tabsSection, seen.FirstUp and "enabled (greyed expected)" or "greyed", seen.LastDown and "enabled (greyed expected)" or "greyed", start.Drawn, start.Expected))
            local swapped = #down.Order == #order and down.Order[1] == order[2] and down.Order[2] == order[1]
            for i = 3, #order do
                if down.Order[i] ~= order[i] then swapped = false end
            end
            Add(swapped and down.Drawn == down.Expected and "PASS" or "FAIL", ("2 Down on the first row: the fixture's order [%s] (its first two swapped expected), drawn [%s]"):format(
                table.concat(down.Order, ", "), down.Drawn))
            local same = #up.Order == #order
            for i = 1, #order do
                if up.Order[i] ~= order[i] then same = false end
            end
            Add(not seen.UpWhy and same and up.Drawn == start.Expected and "PASS" or "FAIL", ("3 Up on the second row%s: the fixture's order [%s] ([%s] expected), drawn [%s]"):format(
                seen.UpWhy and (" (" .. seen.UpWhy .. ")") or "", table.concat(up.Order, ", "), table.concat(order, ", "), up.Drawn))
        end
    }
end

-- A frame of this addon that hears the game's GLOBAL_MOUSE_UP while show-me-secure-click waits, so a click on Show me's
-- spot that reaches no stand-in is a finding rather than a wait that runs out (every client has the event, its
-- Blizzard_APIDocumentationGenerated says). onUp(mouseButton), or nil to stop listening.
local clickWatcher

local function WatchClicks(onUp)
    if not onUp then
        if clickWatcher then
            clickWatcher.OnUp = nil
            clickWatcher:UnregisterAllEvents()
        end
        return
    end
    if not clickWatcher then
        clickWatcher = CreateFrame("Frame")
        clickWatcher:SetScript("OnEvent", function(self, _, mouseButton)
            if self.OnUp then self.OnUp(mouseButton) end
        end)
    end
    clickWatcher.OnUp = onUp
    pcall(clickWatcher.RegisterEvent, clickWatcher, "GLOBAL_MOUSE_UP")
end

-- Show me's stand-in under the real mouse (spec requirement 2, its mouse part), as toggle-reset-clipped: the kit's marker
-- (KrowiGameInput) serves the hover and, where it has ClickAt (Krowi_ClaudeKit's docs/work/2026-11-07-marker-click), the
-- click; without the marker, or with an older one that cannot click, the player within mouseWait. The window is raised
-- first (Raise, what a click into it does: a toplevel window lifts its own buttons over anything in its strata, which is
-- why the stand-in lies one strata higher). The hover holds once the stand-in's OnEnter ran, or once the cursor stayed
-- on Show me's spot without it (the finding). The click holds once the stand-in's secure action counted, or once a left
-- click on the spot counted nothing (heard as GLOBAL_MOUSE_UP there). The click hides the window through the stand-in's
-- PostClick; the step opens it again on Tooltips for the steps after.
local function SecureMouseSteps()
    local hover, click
    local function Prepare()
        if InCombatLockdown() then return "in combat: the stand-in is laid over out of combat only" end
        if not standIn then return "no stand-in: ShowMeStandIn.lua did not load" end
        local frame = OnSection(secureSection)
        -- Show me was hidden on the section before, so the stand-in may have waited a frame for its place; once more
        -- now that Show me is shown (these steps test the mouse, not that timing)
        frame:UpdateShowMe()
        frame:Raise()
        local over, where = LiesOver(frame.ShowMeButton)
        if not over then return ("the stand-in does not lie over Show me (%s): show-me-secure tells why"):format(where) end
    end
    return {
        Name = "show-me-secure-hover",
        Text = ("hover Show me, the window raised: the secure stand-in over it gets the mouse (%d s)"):format(mouseWait),
        Run = function()
            local why = Prepare()
            if why then return why end
            hover = { EnteredBefore = standIn.Entered }
        end,
        Hover = function(kit)
            kit.HoverAt(Window().ShowMeButton, 0, 0)
        end,
        Mouse = function()
            return Settled(hover, standIn.Entered > hover.EnteredBefore or Window().ShowMeButton:IsMouseOver())
        end,
        Check = function()
            local frame = Window()
            local entered = standIn.Entered > hover.EnteredBefore
            local got = entered or HasMouse(standIn.Button)
            local library = HasMouse(frame.ShowMeButton)
            local _, where = LiesOver(frame.ShowMeButton)
            Add(got and not library and "PASS" or "FAIL", ("with the window raised and the mouse on Show me's spot: the stand-in's OnEnter %s, the mouse is on %s; %s"):format(
                entered and "ran" or "did not run", MouseOn(ShowMeParts(frame)), where))
        end
    }, {
        Name = "show-me-secure-click",
        Text = ("click Show me: the secure stand-in's click runs once and closes the window (%d s)"):format(mouseWait),
        Run = function()
            local why = Prepare()
            if why then return why end
            click = { ClicksBefore = standIn.Clicks, PostClicksBefore = standIn.PostClicks }
            WatchClicks(function(mouseButton)
                local frame = Window()
                if live and live.StepName == "show-me-secure-click" and click and not click.UpAt and mouseButton == "LeftButton"
                    and frame and frame:IsShown() and frame.ShowMeButton:IsMouseOver() then
                    click.UpAt, click.UpOn = GetTime(), MouseOn(ShowMeParts(frame))
                end
            end)
        end,
        -- Once: the marker keeps a request until the step clears it, and serves it once
        Hover = function(kit)
            if kit.ClickAt and not click.Asked then
                click.Asked = kit.ClickAt(Window().ShowMeButton, 0, 0) and true or false
            end
        end,
        Mouse = function()
            -- Either counter: a click that reached the stand-in without its secure action running hides the window too
            if standIn.Clicks > click.ClicksBefore or standIn.PostClicks > click.PostClicksBefore then return true end
            if click.UpAt and GetTime() - click.UpAt >= hoverHold then
                click.Missed = true
                return true
            end
            return false
        end,
        Check = function()
            WatchClicks(nil)
            local frame = Window()
            local clicks = standIn.Clicks - click.ClicksBefore
            local reached = standIn.PostClicks - click.PostClicksBefore
            local hidden = not frame:IsShown()
            local by = click.Asked and "the kit's marker, ClickAt" or "the player's"
            if clicks == 0 and reached > 0 then
                Add("FAIL", ("a click on Show me's spot (%s) reached the stand-in (%d time(s)) but its secure action clicked nothing; the window %s"):format(
                    by, reached, hidden and "hid" or "stayed open"))
            elseif clicks == 0 and click.Missed then
                Add("FAIL", ("a left click on Show me's spot (%s) ran no secure action: the mouse was on %s, and the window %s"):format(by,
                    tostring(click.UpOn), hidden and "hid" or "stayed open"))
            else
                Add(clicks == 1 and hidden and "PASS" or "FAIL", ("a click on Show me's spot (%s): the stand-in's secure action clicked its counting button %d time(s) (1 expected), and its close %s"):format(
                    by, clicks, hidden and "hid the window" or "did not hide the window"))
            end
            if hidden then fixtures.Tab:Open(secureSection) end
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
        PublicStep(),
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
                local internal = Internal()
                local shown, selected = 0, "none"
                for _, button in ipairs(frame.TabButtons) do
                    if button:IsShown() then
                        shown = shown + 1
                        if button:IsSelected() then selected = button.Tab.Config.TabName end
                    end
                end
                local title = frame.NineSlice.Text:GetText()
                local searchAll = frame.SearchAll:IsShown()
                local ok = shown == #internal.Tabs and frame.Tab == fixtures.Tab and selected == fixtures.TabName
                    and title == SETTINGS_TITLE and searchAll == (#internal.Tabs > 1)
                Add(ok and "PASS" or "FAIL", ("%d of %d tabs shown, %s selected, title '%s', Search all tabs %s"):format(shown, #internal.Tabs, selected,
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
                local internal = Internal()
                local function Is(value, expected) return math.abs(value - expected) < 0.5 end
                local width = internal.WindowWidth(frame.PaneCollapsed)
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
    tinsert(list, UndoReloadStep())
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
    tinsert(list, InputFocusLostStep(inputId))
    tinsert(list, SelectStaleStep(selectId))
    tinsert(list, DropdownStep(selectId, confirmSelectId))
    tinsert(list, KeysStep(keyId))
    tinsert(list, ShowMeStep())
    tinsert(list, ShowMeSecureStep())
    tinsert(list, CombatStep())
    tinsert(list, DefaultsStep())
    tinsert(list, ExecuteStep())
    tinsert(list, AllNoneStep())
    tinsert(list, TabArrowsStep())
    tinsert(list, ResizeStep())
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
    -- The steps that need the mouse, toggle-reset-clipped last: it leaves the cursor off the list for pane and close
    for _, step in ipairs(LinkHighlightSteps()) do tinsert(list, step) end
    for _, step in ipairs(GreyedHoverSteps()) do tinsert(list, step) end
    for _, step in ipairs({ SecureMouseSteps() }) do tinsert(list, step) end
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
            local width = Internal().WindowWidth(frame.PaneCollapsed)
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
        -- No BugGrabber: the messages ErrorLog.lua kept since this addon began to load
        local log = tests.ErrorLog
        if not (log and log.Installed) then
            tinsert(live.Observations, "no BugGrabber and no error log, so Lua errors are not checked")
            return
        end
        local found = 0
        for _, message in ipairs(log) do
            if message:find(errorPattern, 1, true) then
                found = found + 1
                Add("FAIL", ("Lua error: %s"):format(message:sub(1, 300)))
            end
        end
        if found == 0 then
            Add("PASS", ("no Lua error naming %s this session (the error handler, %d error(s) in all)"):format(errorPattern, #log))
        end
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
    local internal = Internal()
    local blocks = {}
    for _, registered in ipairs(internal.Tabs) do
        local ok, saved = pcall(registered.GetSaved, registered)
        if ok then blocks[registered] = saved.Window and DeepCopy(saved.Window) or false end
    end
    return { Shared = DeepCopy(internal.Shared), Blocks = blocks }
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
    -- The fixture's tab order and Show me answers and the stand-in's answer as before the run; the click watcher stops
    local answers = live.AnswersBefore
    fixtures.ShowMeAnswer, fixtures.CanShowMeAnswer = answers.ShowMe, answers.CanShowMe
    fixtures.SetTabOrder(live.TabOrderBefore)
    WatchClicks(nil)
    if standIn then
        standIn.AnswerFalse = answers.AnswerFalse
        wipe(standIn.Calls)
    end
    local shared = live.SharedBefore
    local before = shared.Shared or live.SavedWindow.Window or {} -- the block the window showed before the run
    if frame then
        -- The end of the combat signal the combat step gave for its screenshot, also when the run stopped before it ended it
        if live.CombatSignalled then
            live.CombatSignalled = nil
            frame:OnEvent("PLAYER_REGEN_ENABLED")
        end
        -- The place show-me-secure moved the window from, also when the step stopped before it put it back
        local point = live.PointBefore
        if point and not point.Done then
            PutPointsBack(frame, point.Points)
            point.Done = true
        end
        if frame.PaneCollapsed ~= (before.PaneCollapsed and true or false) then
            frame:SetPaneCollapsed(before.PaneCollapsed and true or false)
        end
        -- The search scope and breadth the window reads, and their check boxes; the saved fields go back below
        frame.BroadSearch = before.SearchBroad and true or false
        frame.SearchBroad:SetChecked(frame.BroadSearch)
        frame.SearchEveryTab = before.SearchAll and true or false
        frame.SearchAll:SetChecked(frame.SearchEveryTab)
        -- The reload bar as it was before undo-reload lit it, also when the run stopped before that step put it back
        if live.ReloadBefore then
            frame.ReloadPending = live.ReloadBefore.Value
            frame:RefreshFooter()
        end
        -- The height and place resize changed, also when the run stopped before that step put them back
        local size = live.SizeBefore
        if size then
            local putBack = size.Done or pcall(PutSizeBack, frame, size)
            if not putBack or math.abs(frame:GetHeight() - size.Height) > 0.5 then
                tinsert(notBack, "window height")
            end
        end
        local was = live.WasShown
        if was and tContains(Internal().Tabs, was.Tab) then
            frame:ShowTab(was.Tab, was.Section)
        end
        -- A window left shown draws the tab order as put back, and lays the stand-in over Show me or lets it go as its
        -- section's help asks; a hidden one let it go as it hid
        if frame:IsShown() then
            if frame.SectionId == tabsSection and not frame.Searching then frame:ReloadSection() end
            frame:UpdateShowMe()
        elseif standIn then
            standIn.Release()
        end
    elseif standIn then
        standIn.Release()
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
    Internal().Shared = DeepCopy(shared.Shared)
    return notBack
end

-- Every atlas the library draws (RowFrames.lua, WindowPage.lua, WindowFrame.lua, WindowLayout.lua, and the undo arrow's
-- markup in Krowi_Options.lua), asked of this client's own game data (docs/work/2026-11-05-review-fixes, backlog #17): one
-- the client does not have draws nothing there
local libraryAtlases = { "checkbox-minimal", "checkmark-minimal", "checkmark-minimal-disabled", "common-dropdown-icon-next",
    "common-dropdown-icon-next-disabled", "common-dropdown-icon-back", "common-dropdown-icon-back-disabled", "common-icon-undo",
    "Options_List_Active", "Options_List_Hover", "Options_CategoryHeader_1", "Options_CategoryHeader_2",
    "Options_CategoryHeader_3", "Options_HorizontalDivider", "Options_InnerFrame" }

local function CheckAtlases()
    local missing = {}
    for _, name in ipairs(libraryAtlases) do
        if not C_Texture.GetAtlasInfo(name) then missing[#missing + 1] = name end
    end
    if #missing == 0 then
        Add("PASS", ("the client has all %d atlases the library draws"):format(#libraryAtlases))
    else
        Add("FAIL", ("the client lacks %d of the %d atlases the library draws: %s"):format(#missing, #libraryAtlases,
            table.concat(missing, ", ")))
    end
end

local function Finish()
    banner:UnregisterAllEvents()
    live.StepName = "atlases"
    local atlasesChecked, atlasErr = pcall(CheckAtlases)
    if not atlasesChecked then
        Add("FAIL", "test error: " .. tostring(atlasErr))
    end
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
    -- A stopped run never reaches its mouse step's Clear: a click asked of the kit's marker must not stay for it to serve
    -- later (it retries a refused one), maybe with the window gone
    if KrowiGameInput then
        KrowiGameInput.Clear()
    end
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
-- 2026-11-05: the full run with equal copies, a short one elsewhere): smoke opens the window, checks the public surface,
-- shows its tabs, changes a check box, searches, collapses the pane and closes; behaviour is every step but the walk
-- through the sections, keeping the two sections whose rows are of their own kind (the tab list and the keys)
local smokeSteps = { open = true, public = true, ["library-globals-window"] = true, tabs = true, toggle = true, search = true, pane = true,
    close = true }
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
    -- What the new steps change outside the options' values, which Restore puts back; before the scenarios too
    local tabOrderBefore = fixtures.GetTabOrder()
    local answersBefore = { ShowMe = fixtures.ShowMeAnswer, CanShowMe = fixtures.CanShowMeAnswer,
        AnswerFalse = standIn and standIn.AnswerFalse or false }
    live = {
        SharedBefore = sharedBefore,
        Results = tests.RunScenarios(),
        Observations = observations or {},
        Finish = done,
        Before = {},
        SavedWindow = savedWindow,
        WasShown = frame and frame:IsShown() and { Tab = frame.Tab, Section = frame.SectionId } or nil,
        AllSteps = #all,
        TabOrderBefore = tabOrderBefore,
        AnswersBefore = answersBefore,
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