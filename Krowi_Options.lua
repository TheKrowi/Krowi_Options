--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- An options window that explains each feature next to its settings: sections on the left, the section's options in
-- the middle, a help pane on the right with the section's explanation or the description of the option under the
-- mouse. It knows nothing of the addons that use it: each one registers a tab and passes its sections, the elements of
-- a section (options that answer Get, Set, IsDisabled, ...), the help and a saved table. The window looks like the
-- game's own Options window on every client and holds one tab per registered addon. Its design history is in
-- Krowi_AchievementFilter's docs/work (2026-10-25-options-revamp, 2026-10-30-options-settings-look), where it was made;
-- 2.0 made it a library of its own (2026-11-04-krowi-options-library).
--
-- Two addons can embed different versions: every file registers its own minor through LibMan, so each file comes from
-- the newest copy that has it, and no file defines an XML template or a global besides the window's name.

local lib = KROWI_LIBMAN:NewLibrary('Krowi_Options_2', 0, {
    SetCurrent = true,
    InitLocalization = true,
})
if not lib then return end

-- The registered tabs, sorted by name, and the one window they share (lib.Frame, made on the first open). Both live on
-- lib, which a newer copy of the library keeps.
lib.Tabs = lib.Tabs or {}
-- The tabs' methods (below), the rows' and the window's mixins (RowMixins.lua, WindowMixin.lua) and their builders
-- (RowFrames.lua, WindowFrame.lua)
lib.Mixins = lib.Mixins or {}
lib.Build = lib.Build or {}
-- The window's frame name, its only global, here so an addon can read it before the window is made. Not Krowi_Options
-- 1's Krowi_OptionsWindow, so an older addon's 1.x window keeps its own.
lib.WindowName = "Krowi_Options_2_Window"

-- The markers an option row draws (RowFrames.lua) as text, so the window shows each one beside the text that explains
-- it and an addon's help can show them too (docs/work/2026-10-31-options-markers): the gold line of a changed option,
-- the reload arrow, and the undo arrow that sets a changed option back (Blizzard's, on every client)
lib.Markup = {
    Changed = "|TInterface\\Buttons\\WHITE8X8:12:3:0:0:8:8:0:8:0:8:255:209:0|t",
    Reload = "|TInterface\\Buttons\\UI-RefreshButton:12:12|t",
    Reset = "|A:common-icon-undo:12:12|a",
}

--[[ config (CreateWindow refuses one that lacks a field or has it of the wrong type; only OnCreated may be left out):
    TabName         the tab's text: the addon's name, not translated
    Saved           a table the addon keeps the window's place, size, pane state, search scope and breadth, its last
                    section and the sections seen in, or a function returning it (called on the first need, so it can
                    live in saved variables not loaded yet); the window's own state is written to every tab's table
                    (lib.SetShared)
    Groups          { { Name, Sections = { sectionId, ... } } } for the navigation and the search; "overview" is always
                    first and never searched
    SectionName(id) the navigation name of a section
    IsNew(id)       whether the navigation marks a section New
    Landing()       the section to open when no section is asked for
    OnSectionShown(id)
    GetElements(id) the section's elements, see RowMixins.lua; { Kind = "Cards", Cards } draws its cards three to a row;
                    the search reads them too (Search.lua)
    GetHelp(id)     { Title, Blocks = { {Heading} | {Text} | {Term, Text} | {Picture, Width, Height} }, ShowMe, ShowMeNote } or nil
    ResetSection(id), ChangedCount(id)
    OnCreated(frame) called once per tab: when the window is made, or when the tab registers after that
]]

-- The tabs' methods, kept on lib: an addon registers its tab while it loads, before a later addon's newer copy of this
-- file runs, and that copy's methods replace these on the table every tab's metatable is
lib.Mixins.Tab = lib.Mixins.Tab or {}
local tab = lib.Mixins.Tab
tab.__index = tab

-- The addon's saved table, or nil while config.Saved gives none (a function called before its saved variables load),
-- asked again on the next need
local function FindSaved(registered)
    if not registered.Saved then
        local saved = registered.Config.Saved
        if type(saved) == "function" then saved = saved() end
        if type(saved) == "table" then registered.Saved = saved end
    end
    return registered.Saved
end

function tab:GetSaved()
    return FindSaved(self) or error(("Krowi_Options: tab %q: config.Saved gave no table"):format(tostring(self.Config.TabName)), 2)
end

function tab:GetFrame()
    return lib.GetFrame(self)
end

function tab:Open(sectionId)
    lib.GetFrame(self):ShowTab(self, sectionId)
end

function tab:Toggle(sectionId)
    if self:IsShown() then
        lib.Frame:Hide()
    else
        self:Open(sectionId)
    end
end

-- Shown on this tab; the window can be open on another addon's
function tab:IsShown()
    local frame = lib.Frame
    return frame and frame:IsShown() and frame.Tab == self or false
end

function tab:Refresh()
    if self:IsShown() then lib.Frame:Refresh() end
end

-- For the tests: a tab registered for a scenario goes again
function tab:Unregister()
    for i, registered in ipairs(lib.Tabs) do
        if registered == self then
            tremove(lib.Tabs, i)
            break
        end
    end
    if lib.Frame then lib.Frame:RefreshTabs() end
end

local function SortTabs()
    table.sort(lib.Tabs, function(a, b) return a.Config.TabName < b.Config.TabName end)
end

-- What the window calls on a config: each field and the types it may have
local configFields = {
    { "TabName", "string" }, { "Saved", "table", "function" }, { "Groups", "table" }, { "SectionName", "function" },
    { "IsNew", "function" }, { "Landing", "function" }, { "OnSectionShown", "function" }, { "GetElements", "function" },
    { "GetHelp", "function" }, { "ResetSection", "function" }, { "ChangedCount", "function" }, { "OnCreated", "function", "nil" },
}

-- An addon's mistake in its config shows once, as an error at its own CreateWindow call naming the field, not later
-- inside the window
local function CheckConfig(config)
    if type(config) ~= "table" then error("Krowi_Options: CreateWindow takes a config table", 3) end
    local name = tostring(config.TabName)
    for _, field in ipairs(configFields) do
        local kind = type(config[field[1]])
        if kind ~= field[2] and kind ~= field[3] then
            local allowed = field[3] and field[2] .. " or " .. field[3] or field[2]
            error(("Krowi_Options: tab %q: config.%s must be a %s, not %s"):format(name, field[1], allowed, kind), 3)
        end
    end
    for i, group in ipairs(config.Groups) do
        if type(group) ~= "table" or type(group.Sections) ~= "table" then
            error(("Krowi_Options: tab %q: config.Groups[%d] must be a table with a Sections table"):format(name, i), 3)
        end
    end
end

function lib.CreateWindow(config)
    CheckConfig(config)
    local registered = setmetatable({ Config = config }, tab)
    tinsert(lib.Tabs, registered)
    SortTabs()
    if lib.Frame then
        if config.OnCreated then config.OnCreated(lib.Frame) end
        lib.Frame:RefreshTabs()
    end
    return registered
end

-- A translation's placeholder as string.format's %s or %d; a % the translator wrote stays a %
local function Formattable(text, name, spec)
    return (text:gsub("%%", "%%%%")):K_ReplaceVars{ [name] = spec }
end

-- The window's texts, from the library's own locale files (Localization/), the same for every addon. Built on the first
-- need, when every copy's phrases are loaded; ResetSection, ChangedCount and Default take string.format's %s or %d.
local strings
function lib.GetStrings()
    if not strings then
        local L = lib.L
        strings = {
            Overview = L["Overview"],
            Search = L["Search"],
            SearchAll = L["Search all tabs"],
            SearchBroad = L["Search descriptions"],
            SearchHelp = L["Help Search Names"],
            SearchHelpBroad = L["Help Search Broad"],
            SearchResults = L["Search results"],
            NoResults = L["Nothing found."],
            Defaults = L["Defaults"],
            ResetSection = Formattable(L["Set every option of {section} back to its default?"], "section", "%s"),
            ChangedCount = Formattable(L["{count} changed"], "count", "%d"),
            ReloadText = L["Some changes take effect after a reload."],
            ReloadNow = L["Reload now"],
            ShowMe = L["Show me"],
            HowItWorks = L["How it works"],
            All = L["All"],
            None = L["None"],
            NotBound = L["Not bound"],
            PressAKey = L["Press a key"],
            Default = Formattable(L["Default: {value}"], "value", "%s"),
            NeedsReload = L["Requires a reload"],
            NotInCombat = L["Not in combat"],
        }
    end
    return strings
end

-- The window, made on its first need from the place the opening addon remembers. The saved table comes first: a tab
-- without one stops here, before a frame is made under the window's name.
function lib.GetFrame(opening)
    if not lib.Frame then
        local saved = (opening or lib.Tabs[1]):GetSaved()
        local frame = lib.Build.Window()
        frame:Init(saved)
        lib.Frame = frame
        for _, registered in ipairs(lib.Tabs) do
            if registered.Config.OnCreated then registered.Config.OnCreated(frame) end
        end
        frame:RefreshTabs()
    end
    return lib.Frame
end

-- The window's place, size, pane state and search scope are one for every addon: each addon's saved
-- table gets them, so any one addon alone still opens the window as the player left it. A tab whose saved table is not
-- there yet misses this one; its own open reports it (GetSaved).
function lib.SetShared(key, value)
    for _, registered in ipairs(lib.Tabs) do
        local saved = FindSaved(registered)
        if saved then saved[key] = value end
    end
end