--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The window's navigation and page (WindowMixin.lua is the window's core): the open tab's sections in the navigation;
-- the open section's rows on the page, refreshed or rebuilt after a change; the page's header with the section's
-- changed count, Defaults and the reload bar; and the question the window asks there (Defaults, an option's Confirm).
-- Its state on the window: SectionId, Elements, Signature, ReloadPending and Confirming. WindowFrame.lua builds the
-- navigation's rows, RowFrames.lua the page's.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("WindowPage", 0)
if not sub then return end

-- What is not the public surface lives under lib.Internal (Krowi_Options.lua)
lib.Internal = lib.Internal or {}

-- A call into the addon whose tab is open: its error goes to the game's error handler and the window goes on with what
-- it got (Krowi_Options.lua, Protected; each file that needs it has its own)
local function Protected(func, ...)
    local args, count = { ... }, select("#", ...)
    return xpcall(function() return func(unpack(args, 1, count)) end, CallErrorHandler)
end

-- An addon's answer, or fallback when its function errors
local function Ask(fallback, func, ...)
    local ok, result = Protected(func, ...)
    if ok then return result end
    return fallback
end

-- [[ Navigation ]] --
-- The game's category list (Blizzard_CategoryList.lua): a group under a header bar, a section gold, the selected one
-- white on the active bar, the hovered one on the hover bar. Each mixin table on lib.Internal.Mixins is added to, never
-- replaced: a newer copy of a file loaded second would otherwise empty a table an older copy filled, and with the
-- window's code split over several files an unchanged file at an equal minor never runs again to fill it.
lib.Internal.Mixins.NavButton = lib.Internal.Mixins.NavButton or {}
local NavButtonMixin = lib.Internal.Mixins.NavButton

function NavButtonMixin:Init(element, window)
    self.Element, self.Window = element, window
    self.Label:SetText(element.Text)
    if element.IsNew then
        -- Right against the name, as the game's list sets it (Blizzard_CategoryList.lua, RefreshNewFeature): centred, the
        -- label's glow would push it 20 further left, past the window's edge on Mists
        self.NewFeature.BGLabel:SetPoint("RIGHT", 0.5, -0.5)
        self.NewFeature.Label:SetPoint("RIGHT", 0, 0)
    end
    self.NewFeature:SetShown(element.IsNew)
    self.Selected = window.SectionId == element.Id and not window.Searching
    self.Over = self:IsMouseOver()
    self:UpdateState()
end

function NavButtonMixin:UpdateState()
    self.Label:SetFontObject(self.Selected and "GameFontHighlight" or "GameFontNormal")
    if self.Selected or self.Over then
        self.Texture:SetAtlas(self.Selected and "Options_List_Active" or "Options_List_Hover", true)
        self.Texture:Show()
    else
        self.Texture:Hide()
    end
end

function NavButtonMixin:OnEnter()
    self.Over = true
    self:UpdateState()
end

function NavButtonMixin:OnLeave()
    self.Over = nil
    self:UpdateState()
end

function NavButtonMixin:OnClick()
    self.Window:ShowSection(self.Element.Id)
end

lib.Internal.Mixins.NavHeader = lib.Internal.Mixins.NavHeader or {}
local NavHeaderMixin = lib.Internal.Mixins.NavHeader

function NavHeaderMixin:Init(element)
    self.Label:SetText(element.Text)
    self.Background:SetAtlas("Options_CategoryHeader_" .. element.Index, true)
end

-- [[ The window ]] --
-- Every file of the window adds its methods to this one table (WindowMixin.lua)
lib.Internal.Mixins.Window = lib.Internal.Mixins.Window or {}
local WindowMixin = lib.Internal.Mixins.Window

-- The page header's buttons and the reload bar's, set up as the window is built (OnLoad, WindowMixin.lua)
function WindowMixin:LoadPage()
    self.DefaultsButton:SetScript("OnClick", function() self:OnDefaultsClick() end)
    self.CancelButton:SetScript("OnClick", function() self:CancelConfirm() end)
    self.ReloadButton:SetScript("OnClick", function() if not InCombatLockdown() then ReloadUI() end end)
end

-- [[ Navigation and the page ]] --
-- The header bars take turns over Blizzard's three, as the game's list does (Blizzard_CategoryList.lua)
function WindowMixin:RefreshNav()
    local config = self.Config
    local list = { { Kind = "NavButton", Id = "overview", Text = self.Strings.Overview, IsNew = false } }
    for i, group in ipairs(config.Groups) do
        list[#list + 1] = { Kind = "NavSpacer" }
        list[#list + 1] = { Kind = "NavHeader", Text = group.Name, Index = ((i - 1) % 3) + 1 }
        for _, id in ipairs(group.Sections) do
            list[#list + 1] = { Kind = "NavButton", Id = id, Text = Ask(id, config.SectionName, id), IsNew = Ask(false, config.IsNew, id) and true or false }
        end
    end
    self.NavScrollBox:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.RetainScrollPosition)
end

-- A section's rows as drawn (lib.Internal.Flatten, Kinds.lua): grids, tab lists and cards as several rows, hidden
-- options left out, and only the kinds the page draws
local function Flatten(elements)
    return lib.Internal.Flatten(elements, lib.Internal.Kinds)
end

-- A section's rows and their signature, read from the addon (below)
local ReadPage

-- Defaults shows on a section's page. The Overview and the search results have none, as the game's: there it shows only
-- as the Yes of a question asked in them.
local function DefaultsShown(window, confirming)
    return confirming ~= nil or not window.Searching and window.SectionId ~= "overview"
end

-- keepSearchText: a search ended by emptying the box keeps the spaces left in it. A section whose rows cannot be read
-- (the error went to the handler) does not open: the window stays on the section it shows, drawn again. It opens, empty,
-- only when no other section is open to stay on (a tab just shown).
function WindowMixin:ShowSection(id, optionId, keepSearchText)
    local config = self.Config
    local elements, signature = ReadPage(self, id)
    if not elements and self.SectionId and self.SectionId ~= id then
        self:ReloadSection()
        return
    end
    self.SectionId = id
    self.Searching = nil
    self.Confirming = nil
    if not keepSearchText and self.SearchBox:GetText() ~= "" then self.SearchBox:SetText("") end
    Protected(config.OnSectionShown, id)
    self.PageTitle:SetText(id == "overview" and self.Strings.Overview or Ask(id, config.SectionName, id))
    self.DefaultsButton:SetShown(DefaultsShown(self))
    -- Each part of the fill on its own, so an addon's error in one leaves the others drawn and the fill always ends
    self.Filling = true
    Protected(self.RefreshNav, self)
    -- Only a page that filled is the last section: one whose elements error is not opened again on the next open
    local ok = Protected(self.FillPage, self, ScrollBoxConstants.DiscardScrollPosition, elements or {}, signature or "")
    if ok and elements then self.Saved.LastSection = id end
    Protected(self.ShowSectionHelp, self)
    self:EndFill()
    if optionId then self:ScrollToOption(optionId) end
end

-- An option as the signature has it: its id and name
local function Signed(option)
    return (option.Id or "") .. "|" .. option:GetLabel()
end

-- What a row draws as it is made and its Refresh does not draw again: a link's detail, a tab's position, each card's
-- line and NEW, a grid row's check boxes (the kind's Cells, Kinds.lua). A change to any of them draws the page again, so
-- its rows show the new elements.
local function Drawn(element, kind)
    local drawn = {}
    if element.Kind == "Link" then
        drawn[1] = tostring(element.Detail or "")
    elseif element.Kind == "TabRow" then
        drawn[1] = tostring(element.Item and element.Item.Position or "")
    elseif element.Kind == "CardRow" then
        for i, card in ipairs(element.Cards or {}) do drawn[i] = tostring(card.Text or "") .. (card.IsNew and " (New)" or "") end
    elseif kind and kind.Cells then
        for i, cell in ipairs(kind.Cells(element) or {}) do drawn[i] = Signed(cell) end
    end
    return #drawn > 0 and (" [" .. table.concat(drawn, ", ") .. "]") or ""
end

-- The rows a page shows, to tell after a change whether the same rows stay: each row's kind and the option it stands for
-- with the one beside it while that shows (the kinds' Options, Kinds.lua), or its key or text, and what it draws once
local function Signature(elements)
    local parts = {}
    for i, element in ipairs(elements) do
        local kind = lib.Internal.Kinds[element.Kind]
        local option, with
        if kind and kind.Options then option, with = kind.Options(element) end
        local beside = with and not with:IsHidden() and ("+" .. (with.Id or "")) or "" -- shown with its row
        parts[i] = element.Kind .. ":" .. (option and (Signed(option) .. beside) or tostring(element.Key or element.Text or element.Label or ""))
            .. Drawn(element, kind)
    end
    return table.concat(parts, "\n")
end

-- A section's rows and their signature, read from the addon: GetElements, and each option's IsHidden (Flatten) and
-- GetLabel (Signature). nil when any of them errors; the error goes to the error handler.
function ReadPage(window, id)
    local ok, elements, signature = Protected(function()
        local elements = Flatten(window.Config.GetElements(id))
        return elements, Signature(elements)
    end)
    if ok then return elements, signature end
end

-- Rows read already (the search results) and their signature, or nil when an option's GetLabel errors
local function SignatureOf(elements)
    return Ask(nil, Signature, elements)
end

-- elements and signature: rows read already (the search results, a page read again after a change). Returns whether the
-- page filled; a page whose rows could not be read shows empty.
function WindowMixin:FillPage(scrollPosition, elements, signature)
    if not elements then
        elements, signature = ReadPage(self, self.SectionId)
    elseif not signature then
        signature = SignatureOf(elements)
    end
    local filled = elements ~= nil and signature ~= nil
    self.Elements = filled and elements or {}
    self.Signature = filled and signature or ""
    self.PageScrollBox:SetDataProvider(CreateDataProvider(self.Elements), scrollPosition)
    self:RefreshFooter()
    return filled
end

-- Rebuilds the page in place, keeping the scroll position: after a change that can show or hide options
function WindowMixin:ReloadSection()
    if not self:IsShown() or not self.SectionId then return end
    if self.Searching then
        self:OnSearch(self.SearchBox:GetText(), ScrollBoxConstants.RetainScrollPosition)
        return
    end
    self:FillPage(ScrollBoxConstants.RetainScrollPosition)
end

-- A row whose option errors stops only itself: the error goes to the game's error handler with its stack, and the other
-- rows, the changed count and the reload bar still refresh. Called through one function made once rather than
-- Protected, whose closure and argument list a refresh would make for every row.
local refreshing -- the row RefreshRow refreshes
local function RefreshRefreshing()
    refreshing:Refresh()
end

local function RefreshRow(frame)
    local row = frame.Row
    if row and row.Refresh then
        refreshing = row
        xpcall(RefreshRefreshing, CallErrorHandler)
        refreshing = nil
    end
end

function WindowMixin:Refresh()
    if not self:IsShown() then return end
    self.PageScrollBox:ForEachFrame(RefreshRow)
    self:RefreshFooter()
    self:UpdateShowMe()
end

-- Defaults is as wide as the game's (96, Blizzard_SettingsList.xml), wider only for a text that does not fit in it
local function FitButton(button)
    button:SetWidth(math.max(96, button:GetFontString():GetStringWidth() + 24))
end

-- The page's header: the section's changed count and Defaults, or while the window asks, the question with Yes and No
function WindowMixin:RefreshFooter()
    local confirming = self:ConfirmingHere()
    if not confirming then self.Confirming = nil end
    self.CancelButton:SetShown(confirming)
    self.PageTitle:SetShown(not confirming)
    self.ChangedText:ClearAllPoints()
    self.ChangedText:SetPoint("RIGHT", confirming and self.CancelButton or self.DefaultsButton, "LEFT", -8, 0)
    if confirming then
        self.ChangedText:SetPoint("LEFT", self.PageTitle, "LEFT")
        self.ChangedText:SetFontObject("GameFontHighlight")
        self.ChangedText:SetText(confirming.Text)
        self.DefaultsButton:SetText(YES)
        FitButton(self.DefaultsButton)
        self.DefaultsButton:SetEnabled(true)
    else
        local count = (not self.Searching and self.SectionId ~= "overview") and tonumber(Ask(0, self.Config.ChangedCount, self.SectionId)) or 0
        self.ChangedText:SetFontObject("GameFontDisableSmall")
        self.ChangedText:SetText(count > 0 and self.Strings.ChangedCount:format(count) or "")
        self.DefaultsButton:SetText(self.Strings.Defaults)
        FitButton(self.DefaultsButton)
        self.DefaultsButton:SetEnabled(count > 0)
    end
    self.DefaultsButton:SetShown(DefaultsShown(self, confirming))
    local reload = self.ReloadPending and true or false
    self.ReloadBackground:SetShown(reload)
    self.ReloadText:SetShown(reload)
    self.ReloadButton:SetShown(reload)
    self.ReloadButton:SetEnabled(not self:InCombat())
end

local function NeedsReload(option)
    return option ~= nil and option.GetNeedsReload ~= nil and option:GetNeedsReload()
end

-- The rows refresh in place while the page keeps the same rows: rebuilding it re-initialises every row, which ends the
-- drag of a slider that changes its option on every step. Only a change that shows or hides rows, or changes what a row
-- draws once (Signature), rebuilds the page; the search results are found again for that, except after a slider, whose
-- value shows or hides no row, so a drag does not search every section on each step. with: the option beside it on its
-- row, which the undo arrow sets back with it (RowMixins.lua), so its reload lights the reload bar too.
function WindowMixin:OnOptionChanged(option, with)
    if NeedsReload(option) or NeedsReload(with) then self.ReloadPending = true end
    if not self.SectionId or self.Searching and option and option.Type == "range" then
        self:Refresh()
    else
        -- Rows that could not be read keep the page as it is: its rows refresh, and the error went to the handler
        local elements, signature
        if self.Searching then
            elements = self:SearchElements(self.SearchBox:GetText())
            signature = SignatureOf(elements)
        else
            elements, signature = ReadPage(self)
        end
        if signature and signature ~= self.Signature then
            self:FillPage(ScrollBoxConstants.RetainScrollPosition, elements, signature)
            self:UpdateShowMe()
        else
            self:Refresh()
        end
    end
    self:RefreshHover()
end

-- Whether a row shows the option: as its own or the one beside it (an option row's With, a tab's Show) or as one of a
-- grid row's check boxes (the kinds' Options and Cells, Kinds.lua)
local function ShowsOption(element, optionId)
    local kind = lib.Internal.Kinds[element.Kind]
    if not kind then return false end
    if kind.Options then
        local option, with = kind.Options(element)
        if option and option.Id == optionId or with and with.Id == optionId then return true end
    end
    for _, cell in ipairs(kind.Cells and kind.Cells(element) or {}) do
        if cell.Id == optionId then return true end
    end
    return false
end

function WindowMixin:ScrollToOption(optionId)
    for _, element in ipairs(self.Elements or {}) do
        if ShowsOption(element, optionId) then
            self.PageScrollBox:ScrollToElementData(element, ScrollBoxConstants.AlignCenter)
            return
        end
    end
end

-- A key capture ends with the window, at the start of combat, when another key button starts one and when its row is
-- reused
function WindowMixin:EndKeyCaptures()
    self.PageScrollBox:ForEachFrame(function(frame)
        local row = frame.Row
        if row and row.EndKeyCapture then row:EndKeyCapture() end
    end)
end

-- The window asks inside itself (Defaults, and an option with Confirm such as deleting a profile): Defaults turns into
-- Yes, with No and the question beside it. A StaticPopup would write the dialog into Blizzard's shared popup frames and
-- list, where a Blizzard dialog shown at the same time (deleting an item, a summon, a battleground port) reads it and
-- then runs its protected accept tainted. A question asked in the search results belongs to them.
function WindowMixin:AskConfirm(text, onYes)
    if self.Searching then
        self.Confirming = { Search = true, Text = text, OnYes = onYes }
    elseif self.SectionId then
        self.Confirming = { SectionId = self.SectionId, Text = text, OnYes = onYes }
    else
        return
    end
    self:RefreshFooter()
end

function WindowMixin:ConfirmingHere()
    local confirming = self.Confirming
    if not confirming then return nil end
    if self.Searching then return confirming.Search and confirming or nil end
    return confirming.SectionId == self.SectionId and confirming or nil
end

function WindowMixin:CancelConfirm()
    self.Confirming = nil
    self:RefreshFooter()
end

function WindowMixin:OnDefaultsClick()
    local confirming = self:ConfirmingHere()
    if confirming then
        self.Confirming = nil
        confirming.OnYes()
        self:RefreshFooter()
        return
    end
    local id = self.SectionId
    if not id or id == "overview" then return end
    self:AskConfirm(self.Strings.ResetSection:format(tostring(Ask(id, self.Config.SectionName, id))), function() self:ResetSection(id) end)
end

-- Config.ResetSection returns true when an option it set back needs a reload. One that errored may have set back such
-- an option before it failed, so the reload bar shows; the page is drawn again either way.
function WindowMixin:ResetSection(id)
    if Ask(true, self.Config.ResetSection, id) then self.ReloadPending = true end
    self:ReloadSection()
end