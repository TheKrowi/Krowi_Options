--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The rows of the options page. A section's elements (config.GetElements, Krowi_Options.lua), each a table with Kind:
--   Header, SubHeading, Note  { Text }: a heading, a smaller heading, a line of text
--   Option     { Option, With }: an option row (the interface below); With only on a toggle or a select
--   Sub        { Text, Members }: a family heading with All / None, which set its member options
--   Grid       { Columns, Rows = { { Label, Cells } } }: column titles, then a row of check boxes (options) per line
--   TabList    { Items = { { Position, Show, Name, Source, MoveUp, MoveDown } } }: a tab's place, its Show option (none:
--              no check box), its name for a tab without Show (optional; the row draws Show's name), where it comes
--              from, and the functions that move it
--   Link       { Text, Detail, OnClick }: a line that opens something
--   Cards      { Cards = { { Name, Text, IsNew, OnClick, Picture, Width, Height, TexCoords, Part | Icon } } }: three to a
--              row (CardMixin below)
-- A kind the window does not know draws nothing. Each element picks its row (Kinds.lua, lib.Internal.Kinds); an option
-- row reads the option's interface:
--   every option  Type ("toggle", "range", "select", "execute", "input" or "key"), GetLabel, IsHidden, IsDisabled, Get,
--                 Set (an execute option's runs it), IsChanged, Reset, GetNeedsReload
--   per type      range: GetRange (min, max, step), optionally Format(value); select: GetValues ({ { value, text } }),
--                 optionally Placeholder and Confirm(value) (the question asked before a choice is made); execute:
--                 GetButtonText; key: Slots (two options holding a key each)
--   optionally    GetDescription, GetDefault (returning whether it has one, and the value) with FormatValue(value),
--                 GetParent (the option it hangs under, which the search finds with it), Indent, Id (ScrollToOption)
-- A grid's check boxes and a tab list's Show are options too. A toggle's element may carry With, an execute or range
-- option with the same interface, drawn 5 after the check box as a 200 button or a 214 slider, as the game's check box
-- with a button or a slider (Blizzard_SettingControls.lua, SettingsCheckboxWithButtonControlMixin and
-- SettingsCheckboxSliderControlMixin); the row's name and changed line are the toggle's and With's together. A slider
-- explains itself under the mouse; a button is the check box's, whose name says what it does (Krowi,
-- docs/work/2026-11-02-options-widths). A select's element may carry With, an execute option, drawn 5 after the
-- dropdown's right arrow as a narrow button showing », which explains itself under the mouse (its GetLabel and
-- GetDescription, as any option's; the search finds the row by its GetLabel, its GetButtonText is not shown) and greys
-- out only by its own IsDisabled, not with the dropdown (2.1, docs/work/2026-11-09-select-with-button).
-- A With on any other type is ignored.
-- Every change goes through window:OnOptionChanged, which redraws the rows, their changed lines and the reload bar.
-- Every text an option or element gives (labels, descriptions, values) is a plain string, never a secret value (12.x).
-- A key option's Slots[n]:Set(key) runs from the key row: an addon's Set that writes bindings (SetBinding, SaveBindings)
-- fires UPDATE_BINDINGS from addon code, which runs Blizzard's binding displays tainted for the session (accepted,
-- Krowi_AchievementFilter #197).
-- RowFrames.lua builds each row and applies its mixin, kept on lib.Internal.Mixins rather than as a global, so the
-- newest copy of the library decides.
-- The element kinds and the option interface above are the contract (Krowi_Options.lua's header says what else is
-- public). Everything else this file defines (the mixins, RowGeometry, RowX and the Card functions) is internal, under
-- lib.Internal, and can change in any version.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("RowMixins", 1)
if not sub then return end

-- What is not the public surface lives under lib.Internal (Krowi_Options.lua)
lib.Internal = lib.Internal or {}

-- A call into the addon whose tab is open: its error goes to the game's error handler and the row goes on with what it
-- got (Krowi_Options.lua, Protected; each file that needs it has its own)
local function Protected(func, ...)
    local args, count = { ... }, select("#", ...)
    return xpcall(function() return func(unpack(args, 1, count)) end, CallErrorHandler)
end

-- [[ Where a row's name and controls stand ]] --
-- In a column 330 from the row's right edge, wide enough for the two key buttons (Krowi kept it over the game's placement
-- from the row's centre, docs/work/2026-11-02-options-widths). Each is an anchor on the row, { relativePoint, x }, so a
-- row is placed before it has its width. A check box, a slider's left arrow, the key buttons and the input box's border
-- start on one line, and the dropdown's left arrow 2.5 in from it, as the game has them: the dropdown's frame 18.5 after
-- the line, the input box 6 (its border reaches 5 before it).
local controlColumn = 330
local selectIn, inputIn = 18.5, 6
local placement = {
    Toggle = { "RIGHT", -controlColumn }, Range = { "RIGHT", -controlColumn }, Select = { "RIGHT", -controlColumn + selectIn }, Execute = { "RIGHT", -controlColumn },
    Input = { "RIGHT", -controlColumn + inputIn }, Key = { "RIGHT", -controlColumn }, Sub = { "RIGHT", -controlColumn }, TabArrows = { "RIGHT", -controlColumn },
    NameRight = { "RIGHT", -controlColumn - 12 }, NameLeft = 16, Indent = 20,
}
local geometries = {} -- per indent, made once

function lib.Internal.RowGeometry(indent)
    indent = indent or 0
    local geometry = geometries[indent]
    if not geometry then
        geometry = { NameLeft = { "LEFT", placement.NameLeft + indent * placement.Indent } }
        for key, spec in next, placement do
            if type(spec) == "table" then geometry[key] = spec end
        end
        geometries[indent] = geometry
    end
    return geometry
end

local relativeX = { LEFT = 0, CENTER = 0.5, RIGHT = 1 }

-- A geometry's anchor as x from the left of a row this wide
function lib.Internal.RowX(spec, width)
    return relativeX[spec[1]] * width + spec[2]
end

local function Place(region, row, spec)
    region:ClearAllPoints()
    region:SetPoint("LEFT", row, spec[1], spec[2], 0)
end

-- The option row's controls by their place in the geometry; each option type's place is in optionTypes below
local placedControls = { Toggle = "Toggle", Range = "Range", Select = "Select", Execute = "Execute", Input = "Input", Key = "Key1" }

-- [[ A key button ]] --
-- The game's key binding button (KeyBindingFrameBindingButtonTemplate on UIMenuButtonStretchTemplate, the same on every
-- client): silver art that presses down under the mouse. RowFrames.lua copies its art with pieces that carry no names;
-- the template's $parent names would make a global per piece for every row.
-- Each mixin table on lib.Internal.Mixins is added to, never replaced: a newer copy of this file loaded second would
-- otherwise empty a table an older copy filled (WindowMixin.lua, the same for the window's).
lib.Internal.Mixins.KeyButton = lib.Internal.Mixins.KeyButton or {}
local KeyButtonMixin = lib.Internal.Mixins.KeyButton

local keyButtonPieces = { "TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopMiddle", "MiddleLeft", "MiddleRight", "BottomMiddle", "MiddleMiddle" }

function KeyButtonMixin:SetPieces(file)
    for _, piece in ipairs(keyButtonPieces) do
        self[piece]:SetTexture(file)
    end
end

function KeyButtonMixin:OnMouseDown()
    if self:IsEnabled() then self:SetPieces("Interface\\Buttons\\UI-Silver-Button-Down") end
end

-- On mouse up, and on show and enable in case it was hidden or disabled before the mouse came up
function KeyButtonMixin:Lift()
    self:SetPieces("Interface\\Buttons\\UI-Silver-Button-Up")
end

-- [[ Header, sub-heading, note ]] --
lib.Internal.Mixins.TextRow = lib.Internal.Mixins.TextRow or {}
local TextRowMixin = lib.Internal.Mixins.TextRow

function TextRowMixin:Init(element)
    self.Text:SetText(element.Text or "")
end

-- [[ An option ]] --
lib.Internal.Mixins.OptionRow = lib.Internal.Mixins.OptionRow or {}
local OptionRowMixin = lib.Internal.Mixins.OptionRow

-- A control under the mouse fires its OnEnter while greyed out too, as the game's own settings check box does
-- (SettingsCheckboxTemplate's motionScriptsWhileDisabled, Blizzard_SettingControls.xml), so the help still says what a
-- disabled option is. Only buttons have the setting, not a slider or an edit box.
local function HoverWhileDisabled(control)
    if control.SetMotionScriptsWhileDisabled then control:SetMotionScriptsWhileDisabled(true) end
end

local function Forward(control, row)
    HoverWhileDisabled(control)
    control:HookScript("OnEnter", function() row:OnEnter(control) end)
    control:HookScript("OnLeave", function() row:OnLeave() end)
end

-- The mouse buttons a key can be bound to, as AceGUI's keybinding widget took them; left and right start and stop
local mouseButtons = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

local function NoTooltip()
    return false
end

local function Changed(row)
    return row.Option:IsChanged() or row.With ~= nil and row.With:IsChanged()
end

-- Whether the row's With is a dropdown's button (a select's execute), drawn by row.Go
local function IsSelectButton(row)
    return row.With ~= nil and row.Option ~= nil and row.Option.Type == "select"
end

-- The control that draws With: after the check box, or the dropdown's button
local function WithControl(row)
    if not row.With then return nil end
    if IsSelectButton(row) then return row.Go end
    return row.With.Type == "range" and row.Range or row.Execute
end

-- What an input box shows of its option's value: a string as it is, a number as text, a saved value of another type as
-- nothing
local function InputText(value)
    if type(value) == "string" then return value end
    if type(value) == "number" then return tostring(value) end
    return ""
end

-- A change a row makes while the page's list draws it or lets it go (a select set back to a choice, text kept as its
-- box hides): window:OnOptionChanged could rebuild the page from inside the list's own fill, so only the reload bar
-- learns of it here, and the fill or refresh around it draws the changed lines and the count
local function ChangedQuietly(row, option)
    if option:GetNeedsReload() then row.Window.ReloadPending = true end
end

-- The text typed in an input box, saved as the box loses the focus, as Enter saves it (Krowi, 2026-11-07). Only text
-- typed: what differs from the text the box had when it took the focus or was last drawn (InputStart). A box with the
-- focus keeps its text through a refresh, so after a reset or Defaults that it was not drawn again for, its text is
-- older than its option's and must not be written back. A box hidden with its row (the window closed, the page drawn
-- again) loses the focus inside that hide.
local function SaveInput(row, editBox)
    local option = row.Option
    if not option or option.Type ~= "input" then return end
    local text = editBox:GetText()
    if text == row.InputStart or text == InputText(option:Get()) then return end
    option:Set(text)
    if editBox:IsVisible() then
        row.Window:OnOptionChanged(option)
    else
        ChangedQuietly(row, option)
    end
end

function OptionRowMixin:OnLoad()
    self.Choices = {} -- the choices a select's menu was made from (KeepChoices)

    self.Reset:SetScript("OnClick", function()
        self.Option:Reset()
        if self.With then self.With:Reset() end
        self.Window:OnOptionChanged(self.Option, self.With)
    end)

    self.Toggle:SetScript("OnClick", function()
        self.Option:Set(not self.Option:Get())
        self.Window:OnOptionChanged(self.Option)
    end)

    self.Range:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if self.Updating then return end
        local option = self.With or self.Option
        option:Set(value)
        self.Window:OnOptionChanged(option)
    end, self)

    self.Execute:SetScript("OnClick", function()
        local option = self.With or self.Option
        option:Set()
        self.Window:OnOptionChanged(option)
    end)

    -- A row an older RowFrames.lua built has no dropdown button (two copies, CLAUDE.md)
    if self.Go then
        self.Go:SetScript("OnClick", function()
            local with = self.With
            if not with then return end
            with:Set()
            self.Window:OnOptionChanged(with)
        end)
        Forward(self.Go, self)
    end

    -- Enter and Escape end the typing themselves, so the focus the box loses then saves nothing: Enter saved the text,
    -- Escape put the saved one back. The flag holds until that focus lost, or until the box is focused again when Enter
    -- or Escape came without the focus.
    self.Input:SetScript("OnEnterPressed", function(editBox)
        self.Option:Set(editBox:GetText())
        self.InputKept = true
        editBox:ClearFocus()
        self.Window:OnOptionChanged(self.Option)
    end)
    self.Input:SetScript("OnEscapePressed", function(editBox)
        editBox:SetText(InputText(self.Option:Get()))
        self.InputKept = true
        editBox:ClearFocus()
    end)
    self.Input:HookScript("OnEditFocusGained", function(editBox) self.InputKept, self.InputStart = false, editBox:GetText() end)
    self.Input:HookScript("OnEditFocusLost", function(editBox)
        if self.InputKept then
            self.InputKept = false
            return
        end
        SaveInput(self, editBox)
    end)

    for slot, button in ipairs({ self.Key1, self.Key2 }) do
        button:SetScript("OnClick", function() self:StartKeyCapture(slot) end)
        button:SetScript("OnKeyDown", function(_, key) self:OnKeyCaptured(slot, key) end)
        button:HookScript("OnMouseDown", function(_, mouseButton) -- the template's own OnMouseDown draws the pressed look
            if mouseButtons[mouseButton] then self:OnKeyCaptured(slot, mouseButtons[mouseButton]) end
        end)
        button:SetScript("OnMouseWheel", function(_, delta) self:OnKeyCaptured(slot, delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
        button:EnableKeyboard(false)
        button:EnableMouseWheel(false)
    end

    -- The slider's bar and arrows cover its frame, so the mouse comes onto them, not onto the frame
    for _, control in ipairs({ self.Reset, self.Toggle, self.Range, self.Range.Slider, self.Range.Back, self.Range.Forward, self.Select.Dropdown,
        self.Select.DecrementButton, self.Select.IncrementButton, self.Execute, self.Input, self.Key1, self.Key2 }) do
        Forward(control, self)
    end

    -- A dropdown whose text is cut off shows it in GameTooltip and hides it on leave (DropdownSelectionTextMixin): from
    -- our rows that Hide runs GameTooltip's OnHide tainted, the path of issue #300. The help pane or the row's tooltip
    -- shows the option instead.
    self.Select.Dropdown.ShouldShowTooltip = NoTooltip
end

-- A range option's value as its slider takes it: a number between its ends; a saved value that is no number is its min
local function RangeValue(option, min, max)
    return math.min(math.max(tonumber(option:Get()) or min, min), max)
end

-- The slider steps (max - min) / steps (MinimalSliderWithSteppersMixin:Init). Without a step the range is split into
-- 100, as the game's own sliders without a rate are (Settings.CreateSliderOptions); at least one step, so a slider whose
-- ends are the same steps 0, never 0 / 0.
local function InitRange(row, option)
    local min, max, step = option:GetRange()
    row.Updating = true
    local steps = step and step > 0 and math.floor((max - min) / step + 0.5) or 100
    row.Range:Init(RangeValue(option, min, max), min, max, math.max(steps, 1), {
        [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            return option.Format and option:Format(value) or tostring(math.floor(value * 100 + 0.5) / 100)
        end),
    })
    row.Updating = nil
    row.Range:Show()
end

local function RefreshRange(row, option, disabled)
    local min, max = option:GetRange()
    row.Updating = true
    row.Range:SetValue(RangeValue(option, min, max))
    row.Updating = nil
    row.Range:SetEnabled(not disabled)
end

-- [[ A select's choices ]] --
local function IsChoice(values, value)
    for _, pair in ipairs(values) do
        if pair[1] == value then return true end
    end
    return false
end

-- The choices a select's menu was made from, kept flat (value, text, value, text, ...) in the row's own table, so a
-- refresh tells whether they changed without making anything
local function SameChoices(kept, values)
    local count = 0
    for i, pair in ipairs(values) do
        if kept[2 * i - 1] ~= pair[1] or kept[2 * i] ~= tostring(pair[2]) then return false end
        count = i
    end
    return kept.Count == count
end

local function KeepChoices(kept, values)
    local count = 0
    for i, pair in ipairs(values) do
        kept[2 * i - 1], kept[2 * i] = pair[1], tostring(pair[2])
        count = i
    end
    for i = 2 * count + 1, 2 * (kept.Count or 0) do kept[i] = nil end
    kept.Count = count
end

-- The value a select shows: its saved value, or when that is no longer one of its choices (a profile deleted elsewhere)
-- its default, or its first choice without one, which is then saved through the option's own Set (Krowi, 2026-11-07).
-- Once per stale value, so a Set that does not keep it cannot loop; the Set runs while the list draws the row, so an
-- error in it goes to the error handler and the row is still made. Never set:
-- - a select with no value: one never set, which is not a value that is no longer a choice;
-- - a select with a Placeholder or a Confirm: it shows its placeholder while nothing is chosen, and asks before a choice
--   is made (Krowi_AchievementFilter's Copy From and Delete a Profile hold no value and have both: setting them would
--   copy or delete a profile);
-- - a value that is its option's default, which an addon holds on purpose (Krowi_AchievementFilter's first weekday of
--   the calendar, -1 for the game's own until a reload, also after a profile reset).
local function SelectShown(row, option, values)
    local value = option:Get()
    if value == nil or values[1] == nil or IsChoice(values, value) or option.Placeholder or option.Confirm then
        row.Repaired = false
        return value
    end
    local hasDefault, default
    if option.GetDefault then hasDefault, default = option:GetDefault() end
    if hasDefault and value == default then
        row.Repaired = false
        return value
    end
    local shown = values[1][1]
    if hasDefault then shown = default end
    if not (row.Repaired == true and row.RepairedFrom == value) then
        row.Repaired, row.RepairedFrom = true, value
        if Protected(option.Set, option, shown) then ChangedQuietly(row, option) end
    end
    return shown
end

-- Each option type: Place, its control's place in the row's geometry (where the help says the control starts); Init,
-- which shows the control and sets it up for the option; Refresh, which sets it to the option's value and greys it out
-- with the option. A type not in it draws no control.
local optionTypes = {
    toggle = {
        Place = "Toggle",
        Init = function(row)
            row.Toggle:Show()
        end,
        Refresh = function(row, option, disabled)
            row.Toggle:SetChecked(option:Get() and true or false)
            row.Toggle:SetEnabled(not disabled)
        end,
    },
    range = {
        Place = "Range",
        Init = function(row, option)
            InitRange(row, option)
        end,
        Refresh = function(row, option, disabled)
            RefreshRange(row, option, disabled)
        end,
    },
    select = {
        Place = "Select",
        -- The arrows step through the menu's radios, so a choice made with them asks and sets as a click in the list does.
        -- The menu is made from the kept choices, once per option the row shows and again only when they change: a
        -- refresh that changes only the value has the dropdown read its radios again (DropdownButtonMixin:Update).
        Init = function(row, option, window)
            local dropdown = row.Select.Dropdown
            local values = option:GetValues()
            KeepChoices(row.Choices, values)
            row.SelectShown = SelectShown(row, option, values)
            dropdown:SetupMenu(function(_, root)
                local choices = row.Choices
                for i = 1, choices.Count do
                    local value = choices[2 * i - 1]
                    root:CreateRadio(choices[2 * i], function() return row.SelectShown == value end, function()
                        local function Choose()
                            option:Set(value)
                            window:OnOptionChanged(option)
                        end
                        -- option.Confirm(value) -> the question the window asks before the choice is made
                        if option.Confirm then window:AskConfirm(option:Confirm(value), Choose) else Choose() end
                    end)
                end
            end)
            if dropdown.SetDefaultText then dropdown:SetDefaultText(option.Placeholder or "") end
            row.Select:Show()
        end,
        Refresh = function(row, option, disabled)
            local values = option:GetValues()
            local shown = SelectShown(row, option, values)
            if not SameChoices(row.Choices, values) then
                KeepChoices(row.Choices, values)
                row.SelectShown = shown
                row.Select.Dropdown:GenerateMenu()
            elseif shown ~= row.SelectShown then
                row.SelectShown = shown
                row.Select.Dropdown:Update()
            end
            row.Select:SetEnabled(not disabled) -- the arrows' frame enables its dropdown and its arrows
        end,
    },
    execute = {
        Place = "Execute",
        Init = function(row, option)
            row.Execute:SetText(option:GetButtonText())
            row.Execute:Show()
        end,
        Refresh = function(row, _, disabled)
            row.Execute:SetEnabled(not disabled)
        end,
    },
    input = {
        Place = "Input",
        Init = function(row)
            row.Input:Show()
        end,
        -- A box with the focus keeps what is typed in it, and shows a change made elsewhere (a reset, Defaults)
        Refresh = function(row, option, disabled)
            local text = InputText(option:Get())
            if not row.Input:HasFocus() or text ~= row.InputStart then
                row.Input:SetText(text)
                row.InputStart = text
            end
            row.Input:SetEnabled(not disabled)
        end,
    },
    key = {
        Place = "Key",
        Init = function(row, option)
            row.Key1:Show()
            row.Key2:SetShown(option.Slots and option.Slots[2] ~= nil)
        end,
        Refresh = function(row, option, disabled, strings)
            local inCombat = row.Window:InCombat()
            for slot, button in ipairs({ row.Key1, row.Key2 }) do
                local slotOption = option.Slots and option.Slots[slot]
                if slotOption then
                    -- As the game's Keybindings page shows them (BindingUtil.lua): no key in grey and a little
                    -- faded, the button waiting for a key lit
                    local key = slotOption:Get()
                    local text = row.Capturing == slot and strings.PressAKey
                        or key and key ~= "" and GetBindingText(key)
                    button:SetText(text or GRAY_FONT_COLOR:WrapTextInColorCode(strings.NotBound))
                    button:SetAlpha(text and 1 or 0.8)
                    button.SelectedHighlight:SetShown(row.Capturing == slot)
                    button:SetEnabled(not disabled and not inCombat)
                end
            end
        end,
    },
}

function OptionRowMixin:Init(element, window)
    -- A recycled row must not bind the next key to its new option, nor refresh the option it showed before, nor save
    -- text typed for that one into the new one (its input box loses the focus as it hides)
    self.Option = nil
    self:EndKeyCapture()
    for _, control in ipairs({ self.Toggle, self.Range, self.Select, self.Execute, self.Input, self.Key1, self.Key2 }) do
        control:Hide()
    end
    if self.Go then self.Go:Hide() end
    self.InputKept, self.InputStart, self.Repaired = false, false, false
    self.Element, self.Window, self.Option = element, window, element.Option
    local option = self.Option
    -- With only on a toggle, or an execute on a select where the row has its button (the contract): a slider's or a
    -- button's own control always sets its own option
    local with = element.With
    if with and with:IsHidden() then with = nil end
    if option.Type == "toggle" then
        self.With = with
    elseif option.Type == "select" and with and with.Type == "execute" and self.Go then
        self.With = with
    else
        self.With = nil
    end
    local geometry = lib.Internal.RowGeometry(option.Indent)
    self.Geometry = geometry
    self.Label:ClearAllPoints()
    self.Label:SetPoint("LEFT", self, geometry.NameLeft[1], geometry.NameLeft[2], 0)
    self.Label:SetPoint("RIGHT", self, geometry.NameRight[1], geometry.NameRight[2], 0)
    for place, key in next, placedControls do
        Place(self[key], self, geometry[place])
    end
    self.Range:SetWidth(lib.Internal.Geometry.SliderWidth) -- the row may have drawn a check box's slider before
    self.Label:SetText(option:GetLabel())

    local optionType = optionTypes[option.Type]
    if optionType then optionType.Init(self, option, window) end
    local control
    with, control = self.With, WithControl(self)
    if with and IsSelectButton(self) then
        control:ClearAllPoints()
        control:SetPoint("LEFT", self.Select.IncrementButton, "RIGHT", 5, 0)
        control:Show()
    elseif with then
        control:ClearAllPoints()
        control:SetPoint("LEFT", self.Toggle, "RIGHT", 5, 0)
        if with.Type == "range" then
            self.Range:SetWidth(lib.Internal.Geometry.WithSliderWidth)
            InitRange(self, with)
        else
            self.Execute:SetText(with:GetButtonText())
            self.Execute:Show()
        end
    end
    self:Refresh()
end

-- The mouse on the row where the list shows it: IsMouseOver tests the whole row, also a part scrolled out of the list,
-- so leaving through that part would keep the arrow (docs/work/2026-11-04-krowi-options-library)
local function UnderMouse(row)
    return row:IsMouseOver() and row.Window.PageScrollBox:IsMouseOver()
end

function OptionRowMixin:Refresh()
    local option = self.Option
    if not option then return end
    local disabled = option:IsDisabled()
    local strings = self.Window.Strings
    self.Label:SetFontObject(disabled and "GameFontDisable" or "GameFontNormal")
    -- The control first: a select whose value is no longer a choice is set to one there, which the changed line shows
    local optionType = optionTypes[option.Type]
    if optionType then optionType.Refresh(self, option, disabled, strings) end

    local with = self.With
    local needsReload = option:GetNeedsReload() or with ~= nil and with:GetNeedsReload()
    self.ReloadIcon:SetShown(needsReload)
    if needsReload then
        self.ReloadIcon:SetPoint("LEFT", self.Label, "LEFT", math.min(self.Label:GetStringWidth(), self.Label:GetWidth()) + 6, 0)
    end
    local changed = Changed(self)
    self.ChangedBar:SetShown(changed)
    self.Reset:SetShown(changed and UnderMouse(self)) -- a change made under the mouse shows the arrow at once

    -- A dropdown's button greys out only by itself (the way to a switched-off feature stays open); a check box's With
    -- greys out with the toggle, or by itself (a threshold while its check box is off)
    if with and IsSelectButton(self) then
        self.Go:SetEnabled(not with:IsDisabled())
    elseif with then
        local withDisabled = disabled or with:IsDisabled()
        if with.Type == "range" then
            RefreshRange(self, with, withDisabled)
        else
            self.Execute:SetEnabled(not withDisabled)
        end
    end
end

-- Key capture, as AceGUI's keybinding widget did it: the button takes the next key, mouse button 3 to 5 or wheel turn;
-- Escape clears the binding, a second click cancels. One button captures at a time in the whole window. Out of combat
-- only (the game blocks binding changes in combat, and the buttons are greyed out there).
function OptionRowMixin:StartKeyCapture(slot)
    local cancel = self.Capturing == slot
    self.Window:EndKeyCaptures()
    if cancel or InCombatLockdown() then
        self:Refresh()
        return
    end
    self.Capturing = slot
    local button = slot == 1 and self.Key1 or self.Key2
    button:EnableKeyboard(true)
    button:EnableMouseWheel(true)
    self:Refresh()
end

function OptionRowMixin:EndKeyCapture()
    if not self.Capturing then return end
    self.Capturing = nil
    for _, button in ipairs({ self.Key1, self.Key2 }) do
        button:EnableKeyboard(false)
        button:EnableMouseWheel(false)
    end
    if self.Option then self:Refresh() end
end

local ignoredKeys = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, UNKNOWN = true }
function OptionRowMixin:OnKeyCaptured(slot, key)
    if self.Capturing ~= slot or ignoredKeys[key] then return end
    self:EndKeyCapture()
    if InCombatLockdown() then return end
    -- A key button's scripts on a row of another type (its buttons hidden there) have no slot to set
    local slotOption = self.Option.Slots and self.Option.Slots[slot]
    if not slotOption then return end
    local combo = key == "ESCAPE" and "" or (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
    slotOption:Set(combo)
    self.Window:OnOptionChanged(self.Option)
end

-- control: the row's control the mouse came onto (Forward); the row's own OnEnter passes its motion flag instead
function OptionRowMixin:OnEnter(control)
    self.Hover:Show()
    self.Reset:SetShown(self.Option and Changed(self))
    local onSlider = type(control) == "table" and (control == self.Range or control:GetParent() == self.Range)
    if onSlider and self.With and self.With.Type == "range" then
        self.Window:OnRowEnter(self.With, self, self.Range:GetLeft() - self:GetLeft())
        return
    end
    -- The dropdown's button explains itself, its hover help placed at the control column as the dropdown's is (at the
    -- button itself it would open past the window's edge with the pane collapsed)
    if control ~= nil and control == self.Go and IsSelectButton(self) then
        self.Window:OnRowEnter(self.With, self, self.Geometry and lib.Internal.RowX(self.Geometry.Select, self:GetWidth()))
        return
    end
    local optionType = self.Geometry and self.Option and optionTypes[self.Option.Type]
    local kind = optionType and optionType.Place
    self.Window:OnRowEnter(self.Option, self, kind and lib.Internal.RowX(self.Geometry[kind], self:GetWidth()))
end

-- Moving onto one of the row's own controls leaves the row too: the arrow stays while the mouse is on the row
function OptionRowMixin:OnLeave()
    self.Hover:Hide()
    if not UnderMouse(self) then self.Reset:Hide() end
    self.Window:OnRowLeave(self.Option)
end

-- [[ A family heading or a group's All / None ]] --
lib.Internal.Mixins.SubRow = lib.Internal.Mixins.SubRow or {}
local SubRowMixin = lib.Internal.Mixins.SubRow

function SubRowMixin:OnLoad()
    local function SetAll(value)
        local reloadMember -- one that needs a reload, so the window shows the reload bar
        for _, option in ipairs(self.Element.Members) do
            if not option:IsDisabled() then
                option:Set(value)
                if option:GetNeedsReload() then reloadMember = option end
            end
        end
        self.Window:OnOptionChanged(reloadMember)
    end
    self.All:SetScript("OnClick", function() SetAll(true) end)
    self.None:SetScript("OnClick", function() SetAll(false) end)
end

function SubRowMixin:Init(element, window)
    self.Element, self.Window = element, window
    self.Text:SetText(element.Text or "")
    Place(self.All, self, lib.Internal.RowGeometry(0).Sub)
    local strings = window.Strings
    self.All:SetText(strings.All)
    self.None:SetText(strings.None)
end

-- [[ A grid: column titles, then a row of check boxes per line ]] --
local gridLeft, gridColumn, gridColumns = 200, 72, 5

lib.Internal.Mixins.GridHeaderRow = lib.Internal.Mixins.GridHeaderRow or {}
local GridHeaderRowMixin = lib.Internal.Mixins.GridHeaderRow

function GridHeaderRowMixin:OnLoad()
    self.Columns = {}
    for i = 1, gridColumns do
        local text = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        text:SetSize(gridColumn, 30)
        text:SetPoint("BOTTOMLEFT", gridLeft + (i - 1) * gridColumn, 2)
        text:SetJustifyV("BOTTOM")
        self.Columns[i] = text
    end
end

function GridHeaderRowMixin:Init(element)
    for i, text in ipairs(self.Columns) do
        text:SetText(element.Columns[i] or "")
    end
end

lib.Internal.Mixins.GridRow = lib.Internal.Mixins.GridRow or {}
local GridRowMixin = lib.Internal.Mixins.GridRow

function GridRowMixin:OnLoad()
    self.Cells = {}
    for i = 1, gridColumns do
        local cell = lib.Internal.Build.CheckButton(self)
        cell:SetPoint("CENTER", self, "LEFT", gridLeft + (i - 0.5) * gridColumn, 0)
        cell:SetScript("OnClick", function()
            local option = self.Element.Cells[i]
            option:Set(not option:Get())
            self.Window:OnOptionChanged(option)
        end)
        cell:HookScript("OnEnter", function() self:OnEnter(i) end)
        cell:HookScript("OnLeave", function() self:OnLeave() end)
        self.Cells[i] = cell
    end
end

function GridRowMixin:Init(element, window)
    self.Element, self.Window = element, window
    self.Label:SetText(element.Label or "")
    self:Refresh()
end

function GridRowMixin:Refresh()
    for i, cell in ipairs(self.Cells) do
        local option = self.Element.Cells[i]
        cell:SetShown(option ~= nil)
        if option then
            cell:SetChecked(option:Get() and true or false)
            cell:SetEnabled(not option:IsDisabled())
        end
    end
end

-- column: the hovered check box's; the row itself (its script passes the motion flag) describes the first one
function GridRowMixin:OnEnter(column)
    self.Hover:Show()
    column = type(column) == "number" and column or 1
    self.Window:OnRowEnter(self.Element.Cells[column], self, gridLeft + (column - 0.5) * gridColumn - self.Cells[column]:GetWidth() / 2)
end

function GridRowMixin:OnLeave()
    self.Hover:Hide()
    self.Window:OnRowLeave()
end

-- [[ The tab list: a tab's position, whether it shows, and arrows to move it ]] --
-- The check box is ShowCheck, not Show: a child key named Show replaces the row's own Show method.
lib.Internal.Mixins.TabRow = lib.Internal.Mixins.TabRow or {}
local TabRowMixin = lib.Internal.Mixins.TabRow

function TabRowMixin:OnLoad()
    self.ShowCheck:SetScript("OnClick", function()
        local option = self.Element.Item.Show
        option:Set(not option:Get())
        self.Window:OnOptionChanged(option)
    end)
    self.Up:SetScript("OnClick", function()
        self.Element.Item.MoveUp()
        self.Window:ReloadSection()
    end)
    self.Down:SetScript("OnClick", function()
        self.Element.Item.MoveDown()
        self.Window:ReloadSection()
    end)
    for _, control in ipairs({ self.ShowCheck, self.Up, self.Down }) do
        HoverWhileDisabled(control)
        control:HookScript("OnEnter", function() self:OnEnter() end)
        control:HookScript("OnLeave", function() self:OnLeave() end)
    end
end

function TabRowMixin:Init(element, window)
    self.Element, self.Window = element, window
    local item = element.Item
    self.Position:SetText(item.Position)
    self.Label:SetText(item.Show and item.Show:GetLabel() or item.Name or "")
    self.Source:SetText(item.Source or "")
    Place(self.Up, self, lib.Internal.RowGeometry(0).TabArrows)
    self.Up:SetEnabled(item.MoveUp ~= nil)
    self.Down:SetEnabled(item.MoveDown ~= nil)
    self:Refresh()
end

-- A tab without a Show option has no check box: a pooled row's would keep another tab's state and error on a click
function TabRowMixin:Refresh()
    local option = self.Element.Item.Show
    self.ShowCheck:SetShown(option ~= nil)
    if option then
        self.ShowCheck:SetChecked(option:Get() and true or false)
        self.ShowCheck:SetEnabled(not option:IsDisabled())
    end
end

function TabRowMixin:OnEnter()
    self.Hover:Show()
    -- From where ShowCheck stands (RowFrames.lua)
    self.Window:OnRowEnter(self.Element.Item.Show, self, lib.Internal.Geometry.TabCheckX)
end

function TabRowMixin:OnLeave()
    self.Hover:Hide()
    self.Window:OnRowLeave()
end

-- [[ A section's name in the search results, as the game's (SettingsListSearchCategoryMixin): a click opens it ]] --
lib.Internal.Mixins.SearchHeadingRow = lib.Internal.Mixins.SearchHeadingRow or {}
local SearchHeadingRowMixin = lib.Internal.Mixins.SearchHeadingRow

function SearchHeadingRowMixin:Init(element)
    self.Element = element
    self.Title:SetText(element.Text or "")
end

function SearchHeadingRowMixin:OnClick()
    if self.Element.OnClick then self.Element.OnClick() end
end

function SearchHeadingRowMixin:OnEnter()
    self.MouseoverOverlay:Show()
end

function SearchHeadingRowMixin:OnLeave()
    self.MouseoverOverlay:Hide()
end

-- [[ A link: a New section, an overview entry ]] --
lib.Internal.Mixins.LinkRow = lib.Internal.Mixins.LinkRow or {}
local LinkRowMixin = lib.Internal.Mixins.LinkRow

function LinkRowMixin:Init(element)
    self.Element = element
    self.Text:SetText(element.Text or "")
    self.Detail:SetText(element.Detail or "")
end

function LinkRowMixin:OnClick()
    if self.Element.OnClick then self.Element.OnClick() end
end

-- [[ Cards: a section's picture, name and line, three to a row (docs/work/2026-11-02-overview-cards) ]] --
-- A card is { Picture, Width, Height, TexCoords, Part } (a picture as the help pane draws it, Part optional, see
-- CardCrop) or { Icon }, and Name, Text, IsNew and OnClick. The cards and the 12 between them fill the row. A picture
-- fills the 86 high area inside the card's 1 px border (lib.Internal.Geometry.CardPictureHeight, Kinds.lua), cut to it
-- from its top left, as the mockup's thumbnails were (object-fit: cover); the name and the line stand 10 in from the
-- card's sides. The fonts are RowFrames.lua's.
lib.Internal.CardColumns = 3
local cardGap, cardBorder = 12, 1
local cardTextInset, nameTop, lineGap, cardBottom, newGap = 10, 8, 3, 10, 6
-- The border under the mouse; out of it, lib.Internal.Geometry.CardBorderColor
local borderHoverColor = { 1, 0.82, 0, 0.6 }

function lib.Internal.CardWidth(rowWidth)
    return (rowWidth - (lib.Internal.CardColumns - 1) * cardGap) / lib.Internal.CardColumns
end

-- The texture coordinates that fill the picture area of a card this wide; TexCoords is the part of its power-of-two
-- texture a picture fills (the help pictures' Pictures.lua). Part = { X, Y } moves the cut from the top left (0) to the
-- bottom right (1) of what does not fit, as CSS's object-position does.
function lib.Internal.CardCrop(picture, cardWidth)
    local pictureHeight = lib.Internal.Geometry.CardPictureHeight
    local width = cardWidth - 2 * cardBorder
    local scale = math.max(width / picture.Width, pictureHeight / picture.Height)
    local coords, part = picture.TexCoords or { 0, 1, 0, 1 }, picture.Part or {}
    local shownWidth, shownHeight = width / scale / picture.Width, pictureHeight / scale / picture.Height -- as parts of the picture
    local left = (1 - shownWidth) * (part.X or 0)
    local top = (1 - shownHeight) * (part.Y or 0)
    local u, v = coords[2] - coords[1], coords[4] - coords[3]
    return coords[1] + u * left, coords[1] + u * (left + shownWidth), coords[3] + v * top, coords[3] + v * (top + shownHeight)
end

-- A row as tall as its tallest card, and the gap under it
function lib.Internal.CardRowHeight(window, element)
    local lineWidth = lib.Internal.CardWidth(window:PageWidth()) - 2 * cardTextInset
    local nameHeight, lineHeight = 0, 0
    for _, card in ipairs(element.Cards) do
        nameHeight = math.max(nameHeight, window:MeasureText(card.Name, "GameFontNormal", 1000))
        if card.Text and card.Text ~= "" then lineHeight = math.max(lineHeight, window:MeasureText(card.Text, "GameFontDisableSmall", lineWidth)) end
    end
    return 2 * cardBorder + lib.Internal.Geometry.CardPictureHeight + nameTop + nameHeight
        + (lineHeight > 0 and lineGap + lineHeight or 0) + cardBottom + cardGap
end

lib.Internal.Mixins.CardRow = lib.Internal.Mixins.CardRow or {}
local CardRowMixin = lib.Internal.Mixins.CardRow

function CardRowMixin:OnLoad()
    self.Cards = {}
    for i = 1, lib.Internal.CardColumns do
        self.Cards[i] = lib.Internal.Build.Card(self)
    end
end

-- The row's own width is the page's, which the window knows before the view has sized the row
function CardRowMixin:Init(element, window)
    self.Element = element
    local width = lib.Internal.CardWidth(window:PageWidth())
    for i, frame in ipairs(self.Cards) do
        local card, x = element.Cards[i], (i - 1) * (width + cardGap)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", x, 0)
        frame:SetPoint("BOTTOMLEFT", x, cardGap)
        frame:SetWidth(width)
        frame:SetShown(card ~= nil)
        if card then frame:Init(card, width) end
    end
end

lib.Internal.Mixins.Card = lib.Internal.Mixins.Card or {}
local CardMixin = lib.Internal.Mixins.Card

function CardMixin:Init(card, width)
    self.Card = card
    self.Picture:SetShown(card.Picture ~= nil)
    self.Icon:SetShown(card.Picture == nil and card.Icon ~= nil)
    if card.Picture then
        self.Picture:SetTexture(card.Picture)
        self.Picture:SetTexCoord(lib.Internal.CardCrop(card, width))
    elseif card.Icon then
        self.Icon:SetTexture(card.Icon)
    end
    -- NEW at the right end of the name's line, as the game's list sets it (Blizzard_CategoryList.lua, RefreshNewFeature);
    -- the name stops before it
    local newWidth = 0
    local feature = self.NewFeature
    if card.IsNew then
        feature.BGLabel:SetPoint("RIGHT", 0.5, -0.5)
        feature.Label:SetPoint("RIGHT", 0, 0)
        newWidth = feature.Label:GetStringWidth() * feature:GetScale() + newGap
    end
    feature:SetShown(card.IsNew and true or false)
    self.Name:ClearAllPoints()
    self.Name:SetPoint("TOPLEFT", self.PictureArea, "BOTTOMLEFT", cardTextInset - cardBorder, -nameTop)
    self.Name:SetPoint("TOPRIGHT", self.PictureArea, "BOTTOMRIGHT", -(cardTextInset - cardBorder) - newWidth, -nameTop)
    self.Name:SetText(card.Name or "")
    self.Line:SetWidth(width - 2 * cardTextInset)
    self.Line:SetText(card.Text or "")
    self:SetHovered(self:IsMouseOver())
end

function CardMixin:SetHovered(hovered)
    self.Hover:SetShown(hovered)
    local color = hovered and borderHoverColor or lib.Internal.Geometry.CardBorderColor
    for _, edge in ipairs(self.Edges) do edge:SetColorTexture(unpack(color)) end
end

function CardMixin:OnEnter()
    self:SetHovered(true)
end

function CardMixin:OnLeave()
    self:SetHovered(false)
end

function CardMixin:OnClick()
    if self.Card.OnClick then self.Card.OnClick() end
end