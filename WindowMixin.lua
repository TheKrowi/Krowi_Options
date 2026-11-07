--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The window: a tab per registered addon on top, the open addon's navigation on the left, the section's rows in the
-- middle, the help pane on the right, in the frame and art of the game's own Options window. Its strings are the
-- library's own (lib.GetStrings in Krowi_Options.lua, translated on the library's CurseForge project), the same on every
-- tab; the game's RESET_TO_DEFAULT names the undo arrow. WindowFrame.lua builds the window and its list rows.
-- This file is the window's core: it sets the window up (OnLoad) and its state (Init), its tabs and strings, shows and
-- hides it and follows its events. Its parts add their methods to the same mixin: WindowLayout.lua (where everything
-- stands), WindowPage.lua (the navigation and the page), WindowSearch.lua (the search) and WindowHelp.lua (the help
-- pane). Its state on the window: Tab, Config, Strings, Saved, TabButtons and CombatStarting.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("WindowMixin", 0)
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

-- [[ The window ]] --
-- Every file of the window adds its methods to this one table: this core, and its parts (WindowLayout.lua,
-- WindowPage.lua, WindowSearch.lua, WindowHelp.lua). Each mixin table on lib.Internal.Mixins is added to, never
-- replaced: a newer copy of a file loaded second would otherwise empty a table an older copy filled, and with the
-- window's code split over several files an unchanged file at an equal minor never runs again to fill it.
lib.Internal.Mixins.Window = lib.Internal.Mixins.Window or {}
local WindowMixin = lib.Internal.Mixins.Window

function WindowMixin:OnLoad()
    -- A plain Hide on both: HideUIPanel, the template's own, refuses addon code in combat
    self.ClosePanelButton:SetScript("OnClick", function() self:Hide() end)
    self.CloseButton:SetScript("OnClick", function() self:Hide() end)
    self.CloseButton:SetText(CLOSE)
    self.NineSlice.Text:SetText(SETTINGS_TITLE) -- the game's own Options window's title
    self.TabButtons = {}
    -- Each part sets up its own frames; the lists are made in the order they always were, the navigation's and the
    -- page's (the layout's) before the help pane's
    self:LoadLayout() -- drag, the inner frame, measuring, both lists, the pane's chevrons, resize (WindowLayout.lua)
    self:LoadHelp() -- the help pane's list, the lightbox and Show me (WindowHelp.lua)
    self:LoadSearch() -- the search box and its check boxes (WindowSearch.lua)
    self:LoadPage() -- the page header's buttons and the reload bar's (WindowPage.lua)
end

-- The window's own state: the newest of the addons' blocks, its fields checked already (Krowi_Options.lua, ReadWindow);
-- every addon keeps a copy (lib.Internal.SetShared). Of the size only the height is kept, at least
-- lib.Internal.Geometry.MinHeight (Kinds.lua) as in the layout (WindowLayout.lua): the width follows the pane alone.
function WindowMixin:Init(window)
    if window.Size then self:SetHeight(math.max(window.Size[2], lib.Internal.Geometry.MinHeight)) end
    self.PaneCollapsed = window.PaneCollapsed and true or false
    self:ApplyWidth()
    if window.Point then
        self:ClearAllPoints()
        self:SetPoint(window.Point[1], UIParent, window.Point[2], window.Point[3], window.Point[4])
    end
    self.SearchEveryTab = window.SearchAll and true or false
    self.SearchAll:SetChecked(self.SearchEveryTab)
    self.BroadSearch = window.SearchBroad and true or false
    self.SearchBroad:SetChecked(self.BroadSearch)
    self:Layout()
end

-- [[ Tabs ]] --
-- A tab per registered addon where the game's window has Game and AddOns (Blizzard_SettingsPanel.xml). Our own click
-- replaces MinimalTabTemplate's, which would let a click on the open tab unselect it.
function WindowMixin:RefreshTabs()
    local tabs = lib.Internal.Tabs
    for i, tab in ipairs(tabs) do
        local button = self.TabButtons[i]
        if not button then
            button = CreateFrame("Button", nil, self, "MinimalTabTemplate")
            button:SetHeight(37)
            if i == 1 then
                button:SetPoint("TOPLEFT", self, "TOPLEFT", 32, -27)
            else
                button:SetPoint("TOPLEFT", self.TabButtons[i - 1], "TOPRIGHT", 5, 0)
            end
            button:SetScript("OnClick", function(clicked)
                if clicked.Tab == self.Tab then return end
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
                self:ShowTab(clicked.Tab)
            end)
            self.TabButtons[i] = button
        end
        button.Tab = tab
        button.Text:SetText(tab.Config.TabName)
        button:SetWidth(button.Text:GetStringWidth() + 40)
        button:SetSelected(tab == self.Tab)
        button:Show()
    end
    for i = #tabs + 1, #self.TabButtons do
        self.TabButtons[i]:Hide()
    end
    self:UpdateSearchAll()
    -- The open tab went (a test's): the first one takes its place
    if self.Tab and not tContains(tabs, self.Tab) then
        self.Tab = nil
        if self:IsShown() and tabs[1] then self:ShowTab(tabs[1]) end
    end
end

-- Searching every tab means something only with a second tab: the check box shows from then on. The broad search's
-- check box stands before it, or before Close until then, and the reload bar reaches to it.
function WindowMixin:UpdateSearchAll()
    local several = #lib.Internal.Tabs > 1
    self.SearchAll:SetShown(several)
    self.SearchAllLabel:SetShown(several)
    self.SearchBroadLabel:ClearAllPoints()
    self.SearchBroadLabel:SetPoint("RIGHT", several and self.SearchAll or self.CloseButton, "LEFT", -16, 0)
    self.ReloadBackground:SetPoint("BOTTOMRIGHT", self.SearchBroad, "BOTTOMLEFT", -12, -2)
end

-- Shows the window on an addon's tab: its sections, strings and saved table, at sectionId or the addon's landing section
function WindowMixin:ShowTab(tab, sectionId, optionId)
    if self.Tab ~= tab then
        local saved = tab:GetSaved() -- first: a tab without a saved table errors with the window left as it was
        self:EndKeyCaptures()
        self:ReleaseShowMe()
        self.Tab = tab
        self.Config, self.Strings, self.Saved = tab.Config, lib.GetStrings(), saved
        self.SectionId, self.Help, self.Searching, self.Confirming = nil, nil, nil, nil
        self:ApplyStrings()
        self:RefreshTabs()
    end
    self:Show()
    self:ShowSection(sectionId or Ask("overview", self.Config.Landing) or "overview", optionId)
end

-- Defaults is as wide as the game's (96, Blizzard_SettingsList.xml), wider only for a text that does not fit in it
local function FitButton(button)
    button:SetWidth(math.max(96, button:GetFontString():GetStringWidth() + 24))
end

function WindowMixin:ApplyStrings()
    local strings = self.Strings
    self.SearchBox.Instructions:SetText(strings.Search)
    self.SearchAllLabel:SetText(strings.SearchAll)
    self.SearchAll:SetHitRectInsets(0, -(self.SearchAllLabel:GetStringWidth() + 4), 0, 0) -- the label ticks it too
    self.SearchBroadLabel:SetText(strings.SearchBroad)
    self.SearchBroad:SetHitRectInsets(0, -(self.SearchBroadLabel:GetStringWidth() + 4), 0, 0)
    -- The collapsed pane's strip: the chevron, then the pane's name down the strip; the whole strip brings the pane back.
    -- A turned text turns about its centre, so it hangs below the chevron by half its length; its letters sit off the
    -- line's middle, so it moves right to stand under the chevron (measured in game, 2026-10-30)
    local label = self.ExpandButton.Label
    label:SetText(strings.HowItWorks) -- as the open pane writes it; upper() would leave non-English letters small
    local length = label:GetStringWidth()
    label:ClearAllPoints()
    label:SetPoint("CENTER", self.ExpandButton, "TOP", 6, -(28 + length / 2))
    self.ExpandButton:SetHeight(34 + length)
    self.DefaultsButton:SetText(strings.Defaults)
    FitButton(self.DefaultsButton)
    self.ReloadButton:SetText(strings.ReloadNow)
    self.ReloadText:SetText(lib.Markup.Reload .. " " .. strings.ReloadText) -- the rows' reload arrow, explained
    self.ShowMeButton:SetText(strings.ShowMe)
    self.CancelButton:SetText(NO)
end

-- Events only while shown: combat greys what cannot run in it, a scale or resolution change moves a secure Show me
-- button laid over ours along
local shownEvents = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }

function WindowMixin:OnShow()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    for _, event in ipairs(shownEvents) do self:RegisterEvent(event) end
    self:ApplyWidth(true) -- the scale or resolution may have changed while the window was hidden
    -- Shown again with its parent (the interface back after Alt+Z): OnHide released Show me, so lay it over again
    if self.SectionId then self:UpdateShowMe() end
end

function WindowMixin:OnHide()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    for _, event in ipairs(shownEvents) do self:UnregisterEvent(event) end
    self:EndKeyCaptures()
    self.Confirming = nil
    self:HideTooltip()
    self:ReleaseShowMe()
end

-- PLAYER_REGEN_DISABLED runs just before the lockdown starts, so InCombatLockdown() is still false inside it
function WindowMixin:OnEvent(event)
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        self:ApplyWidth(true) -- the screen may have room for the whole window now, or no longer
        self:UpdateShowMe()
        return
    end
    -- The flag holds for this refresh only, also when an option errors in it; a key row's error while its capture ends
    -- still lets the page refresh into combat
    self.CombatStarting = event == "PLAYER_REGEN_DISABLED"
    if self.CombatStarting then Protected(self.EndKeyCaptures, self) end
    Protected(self.Refresh, self)
    self.CombatStarting = nil
end

function WindowMixin:InCombat()
    return self.CombatStarting or InCombatLockdown()
end

-- On the open tab, or the first one before any is open
function WindowMixin:Open(sectionId)
    self:ShowTab(self.Tab or lib.Internal.Tabs[1], sectionId)
end