--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The rows of the options page. A section's elements (config.GetElements, Krowi_Options.lua), each a table with Kind:
--   Header, SubHeading, Note  { Text }: a heading, a smaller heading, a line of text
--   Option     { Option, With }: an option row (the interface below); With only on a toggle
--   Sub        { Text, Members }: a family heading with All / None, which set its member options
--   Grid       { Columns, Rows = { { Label, Cells } } }: column titles, then a row of check boxes (options) per line
--   TabList    { Items = { { Position, Show, Source, MoveUp, MoveDown } } }: a tab's place, its Show option (none: no
--              check box), where it comes from, and the functions that move it
--   Link       { Text, Detail, OnClick }: a line that opens something
--   Cards      { Cards = { { Name, Text, IsNew, OnClick, Picture, Width, Height, TexCoords, Part | Icon } } }: three to a
--              row (CardMixin below)
-- A kind the window does not know draws nothing. Each element picks its row (WindowMixin.lua, rowKinds); an option row
-- reads the option's interface:
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
-- docs/work/2026-11-02-options-widths).
-- Every change goes through window:OnOptionChanged, which redraws the rows, their changed lines and the reload bar.
-- Every text an option or element gives (labels, descriptions, values) is a plain string, never a secret value (12.x).
-- A key option's Slots[n]:Set(key) runs from the key row: an addon's Set that writes bindings (SetBinding, SaveBindings)
-- fires UPDATE_BINDINGS from addon code, which runs Blizzard's binding displays tainted for the session (accepted,
-- Krowi_AchievementFilter #197).
-- RowFrames.lua builds each row and applies its mixin, kept on lib.Mixins rather than as a global, so the newest copy of
-- the library decides.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("RowMixins", 0)
if not sub then return end

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

function lib.RowGeometry(indent)
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
function lib.RowX(spec, width)
    return relativeX[spec[1]] * width + spec[2]
end

local function Place(region, row, spec)
    region:ClearAllPoints()
    region:SetPoint("LEFT", row, spec[1], spec[2], 0)
end

-- The option row's controls by their place in the geometry, and the one each option type shows
local placedControls = { Toggle = "Toggle", Range = "Range", Select = "Select", Execute = "Execute", Input = "Input", Key = "Key1" }
local controlOfType = { toggle = "Toggle", range = "Range", select = "Select", execute = "Execute", input = "Input", key = "Key" }

-- [[ A key button ]] --
-- The game's key binding button (KeyBindingFrameBindingButtonTemplate on UIMenuButtonStretchTemplate, the same on every
-- client): silver art that presses down under the mouse. RowFrames.lua copies its art with pieces that carry no names;
-- the template's $parent names would make a global per piece for every row.
-- Each mixin table on lib.Mixins is added to, never replaced: a newer copy of this file loaded second would otherwise
-- empty a table an older copy filled (WindowMixin.lua, the same for the window's).
lib.Mixins.KeyButton = lib.Mixins.KeyButton or {}
local KeyButtonMixin = lib.Mixins.KeyButton

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
lib.Mixins.TextRow = lib.Mixins.TextRow or {}
local TextRowMixin = lib.Mixins.TextRow

function TextRowMixin:Init(element)
    self.Text:SetText(element.Text or "")
end

-- [[ An option ]] --
lib.Mixins.OptionRow = lib.Mixins.OptionRow or {}
local OptionRowMixin = lib.Mixins.OptionRow

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

-- The control that draws With, the option after the check box
local function WithControl(row)
    return row.With and (row.With.Type == "range" and row.Range or row.Execute)
end

function OptionRowMixin:OnLoad()
    self.Reset:SetScript("OnClick", function()
        self.Option:Reset()
        if self.With then self.With:Reset() end
        self.Window:OnOptionChanged(self.Option)
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

    self.Input:SetScript("OnEnterPressed", function(editBox)
        self.Option:Set(editBox:GetText())
        editBox:ClearFocus()
        self.Window:OnOptionChanged(self.Option)
    end)
    self.Input:SetScript("OnEscapePressed", function(editBox)
        editBox:SetText(self.Option:Get() or "")
        editBox:ClearFocus()
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

local function InitRange(row, option)
    local min, max, step = option:GetRange()
    row.Updating = true
    local steps = step and step > 0 and math.floor((max - min) / step + 0.5) or (max - min)
    row.Range:Init(option:Get() or min, min, max, steps, {
        [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            return option.Format and option:Format(value) or tostring(math.floor(value * 100 + 0.5) / 100)
        end),
    })
    row.Updating = nil
    row.Range:Show()
end

local function RefreshRange(row, option, disabled)
    row.Updating = true
    row.Range:SetValue(option:Get() or 0)
    row.Updating = nil
    row.Range:SetEnabled(not disabled)
end

function OptionRowMixin:Init(element, window)
    -- A recycled row must not bind the next key to its new option, nor refresh the option it showed before
    self.Option = nil
    self:EndKeyCapture()
    self.Element, self.Window, self.Option = element, window, element.Option
    local option = self.Option
    self.With = element.With and not element.With:IsHidden() and element.With or nil
    for _, control in ipairs({ self.Toggle, self.Range, self.Select, self.Execute, self.Input, self.Key1, self.Key2 }) do
        control:Hide()
    end
    local geometry = lib.RowGeometry(option.Indent)
    self.Geometry = geometry
    self.Label:ClearAllPoints()
    self.Label:SetPoint("LEFT", self, geometry.NameLeft[1], geometry.NameLeft[2], 0)
    self.Label:SetPoint("RIGHT", self, geometry.NameRight[1], geometry.NameRight[2], 0)
    for place, key in next, placedControls do
        Place(self[key], self, geometry[place])
    end
    self.Range:SetWidth(250) -- the row may have drawn a check box's slider before
    self.Label:SetText(option:GetLabel())

    local t = option.Type
    if t == "toggle" then
        self.Toggle:Show()
    elseif t == "range" then
        InitRange(self, option)
    elseif t == "select" then
        -- The arrows step through the menu's radios, so a choice made with them asks and sets as a click in the list does
        local dropdown = self.Select.Dropdown
        dropdown:SetupMenu(function(_, root)
            for _, pair in ipairs(option:GetValues()) do
                root:CreateRadio(tostring(pair[2]), function() return option:Get() == pair[1] end, function()
                    local function Choose()
                        option:Set(pair[1])
                        window:OnOptionChanged(option)
                    end
                    -- option.Confirm(value) -> the question the window asks before the choice is made
                    if option.Confirm then window:AskConfirm(option:Confirm(pair[1]), Choose) else Choose() end
                end)
            end
        end)
        if dropdown.SetDefaultText then dropdown:SetDefaultText(option.Placeholder or "") end
        self.Select:Show()
    elseif t == "execute" then
        self.Execute:SetText(option:GetButtonText())
        self.Execute:Show()
    elseif t == "input" then
        self.Input:Show()
    elseif t == "key" then
        self.Key1:Show()
        self.Key2:SetShown(option.Slots and option.Slots[2] ~= nil)
    end
    local with, control = self.With, WithControl(self)
    if with then
        control:ClearAllPoints()
        control:SetPoint("LEFT", self.Toggle, "RIGHT", 5, 0)
        if with.Type == "range" then
            self.Range:SetWidth(214)
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

    local with = self.With
    local needsReload = option:GetNeedsReload() or with ~= nil and with:GetNeedsReload()
    self.ReloadIcon:SetShown(needsReload)
    if needsReload then
        self.ReloadIcon:SetPoint("LEFT", self.Label, "LEFT", math.min(self.Label:GetStringWidth(), self.Label:GetWidth()) + 6, 0)
    end
    local changed = Changed(self)
    self.ChangedBar:SetShown(changed)
    self.Reset:SetShown(changed and UnderMouse(self)) -- a change made under the mouse shows the arrow at once

    local t = option.Type
    if t == "toggle" then
        self.Toggle:SetChecked(option:Get() and true or false)
        self.Toggle:SetEnabled(not disabled)
    elseif t == "range" then
        RefreshRange(self, option, disabled)
    elseif t == "select" then
        self.Select.Dropdown:GenerateMenu()
        self.Select:SetEnabled(not disabled) -- the arrows' frame enables its dropdown and its arrows
    elseif t == "execute" then
        self.Execute:SetEnabled(not disabled)
    elseif t == "input" then
        if not self.Input:HasFocus() then self.Input:SetText(option:Get() or "") end
        self.Input:SetEnabled(not disabled)
    elseif t == "key" then
        local inCombat = self.Window:InCombat()
        for slot, button in ipairs({ self.Key1, self.Key2 }) do
            local slotOption = option.Slots and option.Slots[slot]
            if slotOption then
                -- As the game's Keybindings page shows them (BindingUtil.lua): no key in grey and a little faded, the button
                -- waiting for a key lit
                local key = slotOption:Get()
                local text = self.Capturing == slot and strings.PressAKey or key and key ~= "" and GetBindingText(key)
                button:SetText(text or GRAY_FONT_COLOR:WrapTextInColorCode(strings.NotBound))
                button:SetAlpha(text and 1 or 0.8)
                button.SelectedHighlight:SetShown(self.Capturing == slot)
                button:SetEnabled(not disabled and not inCombat)
            end
        end
    end
    -- With greys out with the toggle, or by itself (a threshold while its check box is off)
    if with then
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
    local combo = key == "ESCAPE" and "" or (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
    self.Option.Slots[slot]:Set(combo)
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
    local kind = self.Geometry and self.Option and controlOfType[self.Option.Type]
    self.Window:OnRowEnter(self.Option, self, kind and lib.RowX(self.Geometry[kind], self:GetWidth()))
end

-- Moving onto one of the row's own controls leaves the row too: the arrow stays while the mouse is on the row
function OptionRowMixin:OnLeave()
    self.Hover:Hide()
    if not UnderMouse(self) then self.Reset:Hide() end
    self.Window:OnRowLeave(self.Option)
end

-- [[ A family heading or a group's All / None ]] --
lib.Mixins.SubRow = lib.Mixins.SubRow or {}
local SubRowMixin = lib.Mixins.SubRow

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
    Place(self.All, self, lib.RowGeometry(0).Sub)
    local strings = window.Strings
    self.All:SetText(strings.All)
    self.None:SetText(strings.None)
end

-- [[ A grid: column titles, then a row of check boxes per line ]] --
local gridLeft, gridColumn, gridColumns = 200, 72, 5

lib.Mixins.GridHeaderRow = lib.Mixins.GridHeaderRow or {}
local GridHeaderRowMixin = lib.Mixins.GridHeaderRow

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

lib.Mixins.GridRow = lib.Mixins.GridRow or {}
local GridRowMixin = lib.Mixins.GridRow

function GridRowMixin:OnLoad()
    self.Cells = {}
    for i = 1, gridColumns do
        local cell = lib.Build.CheckButton(self)
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
lib.Mixins.TabRow = lib.Mixins.TabRow or {}
local TabRowMixin = lib.Mixins.TabRow

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
    self.Label:SetText(item.Show and item.Show:GetLabel() or "?")
    self.Source:SetText(item.Source or "")
    Place(self.Up, self, lib.RowGeometry(0).TabArrows)
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
    self.Window:OnRowEnter(self.Element.Item.Show, self, 34) -- where ShowCheck stands (RowFrames.lua)
end

function TabRowMixin:OnLeave()
    self.Hover:Hide()
    self.Window:OnRowLeave()
end

-- [[ A section's name in the search results, as the game's (SettingsListSearchCategoryMixin): a click opens it ]] --
lib.Mixins.SearchHeadingRow = lib.Mixins.SearchHeadingRow or {}
local SearchHeadingRowMixin = lib.Mixins.SearchHeadingRow

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
lib.Mixins.LinkRow = lib.Mixins.LinkRow or {}
local LinkRowMixin = lib.Mixins.LinkRow

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
-- CardCrop) or { Icon }, and Name, Text, IsNew and OnClick. The cards and the 12 between them fill the row. A picture fills the 86 high area inside the card's 1 px
-- border, cut to it from its top left, as the mockup's thumbnails were (object-fit: cover); the name and the line stand 10
-- in from the card's sides. The fonts are RowFrames.lua's.
lib.CardColumns = 3
local cardGap, cardBorder, pictureHeight = 12, 1, 86
local cardTextInset, nameTop, lineGap, cardBottom, newGap = 10, 8, 3, 10, 6
local borderColor, borderHoverColor = { 1, 1, 1, 0.12 }, { 1, 0.82, 0, 0.6 }

function lib.CardWidth(rowWidth)
    return (rowWidth - (lib.CardColumns - 1) * cardGap) / lib.CardColumns
end

-- The texture coordinates that fill the picture area of a card this wide; TexCoords is the part of its power-of-two
-- texture a picture fills (the help pictures' Pictures.lua). Part = { X, Y } moves the cut from the top left (0) to the
-- bottom right (1) of what does not fit, as CSS's object-position does.
function lib.CardCrop(picture, cardWidth)
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
function lib.CardRowHeight(window, element)
    local lineWidth = lib.CardWidth(window:PageWidth()) - 2 * cardTextInset
    local nameHeight, lineHeight = 0, 0
    for _, card in ipairs(element.Cards) do
        nameHeight = math.max(nameHeight, window:MeasureText(card.Name, "GameFontNormal", 1000))
        if card.Text and card.Text ~= "" then lineHeight = math.max(lineHeight, window:MeasureText(card.Text, "GameFontDisableSmall", lineWidth)) end
    end
    return 2 * cardBorder + pictureHeight + nameTop + nameHeight + (lineHeight > 0 and lineGap + lineHeight or 0) + cardBottom + cardGap
end

lib.Mixins.CardRow = lib.Mixins.CardRow or {}
local CardRowMixin = lib.Mixins.CardRow

function CardRowMixin:OnLoad()
    self.Cards = {}
    for i = 1, lib.CardColumns do
        self.Cards[i] = lib.Build.Card(self)
    end
end

-- The row's own width is the page's, which the window knows before the view has sized the row
function CardRowMixin:Init(element, window)
    self.Element = element
    local width = lib.CardWidth(window:PageWidth())
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

lib.Mixins.Card = lib.Mixins.Card or {}
local CardMixin = lib.Mixins.Card

function CardMixin:Init(card, width)
    self.Card = card
    self.Picture:SetShown(card.Picture ~= nil)
    self.Icon:SetShown(card.Picture == nil and card.Icon ~= nil)
    if card.Picture then
        self.Picture:SetTexture(card.Picture)
        self.Picture:SetTexCoord(lib.CardCrop(card, width))
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
    local color = hovered and borderHoverColor or borderColor
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