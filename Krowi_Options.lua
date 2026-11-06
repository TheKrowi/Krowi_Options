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

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve: it stays silent
if not KROWI_LIBMAN then return end
local lib = KROWI_LIBMAN:NewLibrary('Krowi_Options_2', 0, {
    SetCurrent = true,
    InitLocalization = true,
})
if not lib then return end

-- Everything that is not the public surface (the config's comment below names it) lives under lib.Internal, so lib
-- holds only the public names and what LibMan hangs on it (Tests/headless/suites/Structure.lua records both). Every
-- file that writes into it makes it as here: it is added to, never replaced.
lib.Internal = lib.Internal or {}
-- The registered tabs, sorted by name, and the one window they share (lib.Internal.Frame, made on the first open). Both
-- live on lib, which a newer copy of the library keeps.
lib.Internal.Tabs = lib.Internal.Tabs or {}
-- The tabs' methods (below), the rows' and the window's mixins (RowMixins.lua, WindowMixin.lua) and their builders
-- (RowFrames.lua, WindowFrame.lua)
lib.Internal.Mixins = lib.Internal.Mixins or {}
lib.Internal.Build = lib.Internal.Build or {}
-- The window's frame name, the library's only global (Blizzard's templates name a few children after it, CLAUDE.md),
-- here so an addon can read it before the window is made. Not Krowi_Options 1's Krowi_OptionsWindow, so an older
-- addon's 1.x window keeps its own.
lib.WindowName = "Krowi_Options_2_Window"

-- The markers an option row draws (RowFrames.lua) as text, so the window shows each one beside the text that explains
-- it and an addon's help can show them too (docs/work/2026-10-31-options-markers): the gold line of a changed option,
-- the reload arrow, and the undo arrow that sets a changed option back (Blizzard's, on every client)
lib.Markup = {
    Changed = "|TInterface\\Buttons\\WHITE8X8:12:3:0:0:8:8:0:8:0:8:255:209:0|t",
    Reload = "|TInterface\\Buttons\\UI-RefreshButton:12:12|t",
    Reset = "|A:common-icon-undo:12:12|a",
}

--[[ The config lib.CreateWindow(config) takes. CreateWindow refuses one that lacks a field or has it of the wrong type,
    with an error at the addon's own line naming the tab and the field; only OnCreated may be left out.
    TabName         the tab's text: the addon's name, not translated
    Saved           the addon's table for the window, or a function returning it, asked until it gives a table (so the
                    table can live in saved variables not loaded yet) and then kept for the session. The library writes
                    two keys in it and leaves every other key to the addon:
                      Window       the window's place, size, help pane and search ticks, which every addon shares:
                                   { Point, Size, PaneCollapsed, SearchAll, SearchBroad, Changed }. Each change goes
                                   into every loaded addon's table with the time() it was made, and the window opens
                                   from the newest, so the addons agree again after one of them was off for a while
                                   (docs/work/2026-11-05-contract-and-errors)
                      LastSection  the section this addon's tab showed last
    Groups          { { Name, Sections = { sectionId, ... } } } for the navigation and the search
    SectionName(id) a section's name in the navigation, the search and the help pane's kicker
    IsNew(id)       whether the navigation marks a section New
    Landing()       the section to open when none is asked for
    OnSectionShown(id)
    GetElements(id) the section's elements (RowMixins.lua's header). It runs on every change and, while searching, for
                    every section of every searched tab on each keystroke, so it builds cheaply and changes nothing.
    GetHelp(id)     nil, or { Title, Blocks, ShowMe, CanShowMe, ShowMeSecure, ShowMeNote }:
                      Blocks       { { Heading } | { Text } | { Term, Text } | { Picture, Width, Height, TexCoords } }
                      ShowMe()     shows the feature after the window closes; false when it had nothing to show,
                                   and the window comes back
                      CanShowMe()  false while the feature cannot be shown yet (its data still loading)
                      ShowMeSecure(button, close)  for a feature that needs a secure button laid over Show me
                                   (WindowMixin.lua, ReleaseShowMe); called with nil to let it go
                      ShowMeNote   a string, or a function returning one, shown where Show me cannot be
    ResetSection(id), ChangedCount(id)
    OnCreated(frame) called once per tab: when the window is made, or when the tab registers after that. frame.Lightbox
                    is the enlarged help picture, which the addon's Escape handling closes like a window.
    "overview" opens every tab and stands in no group: GetElements, GetHelp, OnSectionShown and SectionName get it, Landing
    may return it, and IsNew, ResetSection and ChangedCount never get it.
    Every text an addon hands the window, here and in its elements, is a plain string, never a secret value (12.x): the
    window compares, joins and measures them.
    An addon's error in any of these functions (Saved too, when another tab asks for the shared state), in GetHelp's
    functions, or in an option's IsHidden or GetLabel while a page is read goes to the game's error handler with its
    stack, and the window goes on with what it got: a section that errors opens empty, a tab whose OnCreated or Saved
    errors leaves the other tabs alone. An option's error inside one of its own row's scripts (a click, a hover) is that
    script's error, as any script's is.
    Open the window after PLAYER_LOGIN: a window made while the addons still load keeps the code of the copies loaded so
    far, and a load-on-demand addon finds the window as it was made.
    The public surface: lib.CreateWindow; a tab's Open, Toggle, IsShown, Refresh, GetFrame and GetSaved (Unregister is for
    tests); lib.GetStrings, lib.Markup and lib.WindowName; OnCreated's frame and its Lightbox. Everything else on lib and
    on the window is internal and can change in any version.
]]

-- The tabs' methods, kept on lib: an addon registers its tab while it loads, before a later addon's newer copy of this
-- file runs, and that copy's methods replace these on the table every tab's metatable is
lib.Internal.Mixins.Tab = lib.Internal.Mixins.Tab or {}
local tab = lib.Internal.Mixins.Tab
tab.__index = tab

-- A call into an addon: its error goes to the game's error handler with its stack (BugSack, or the game's error frame
-- through CallErrorHandler, as Blizzard's own xpcalls do) and the caller goes on. A closure rather than the game's
-- xpcall(f, handler, ...): plain Lua 5.1's xpcall, which the headless tests run on, passes no arguments. Each file
-- that needs it has its own, so no file depends on another file's version for it.
local function Protected(func, ...)
    local args, count = { ... }, select("#", ...)
    return xpcall(function() return func(unpack(args, 1, count)) end, CallErrorHandler)
end

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

-- Another addon's saved table, asked for the shared state: an addon whose Saved errors is left out, its error goes to the
-- error handler once, and it is not asked again this session, so it never stops the window of the others
local function OtherSaved(registered)
    if registered.SavedFailed then return nil end
    local ok, saved = Protected(FindSaved, registered)
    if not ok then registered.SavedFailed = true end
    return ok and saved or nil
end

function tab:GetFrame()
    return lib.Internal.GetFrame(self)
end

function tab:Open(sectionId)
    lib.Internal.GetFrame(self):ShowTab(self, sectionId)
end

function tab:Toggle(sectionId)
    if self:IsShown() then
        lib.Internal.Frame:Hide()
    else
        self:Open(sectionId)
    end
end

-- Shown on this tab; the window can be open on another addon's
function tab:IsShown()
    local frame = lib.Internal.Frame
    return frame and frame:IsShown() and frame.Tab == self or false
end

function tab:Refresh()
    if self:IsShown() then lib.Internal.Frame:Refresh() end
end

-- For the tests: a tab registered for a scenario goes again
function tab:Unregister()
    for i, registered in ipairs(lib.Internal.Tabs) do
        if registered == self then
            tremove(lib.Internal.Tabs, i)
            break
        end
    end
    if lib.Internal.Frame then lib.Internal.Frame:RefreshTabs() end
end

local function SortTabs()
    table.sort(lib.Internal.Tabs, function(a, b) return a.Config.TabName < b.Config.TabName end)
end

-- [[ The window's shared state: saved.Window in every addon's table, the newest change winning ]] --
-- SetPoint's anchor points; any other name would error in it
local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOMLEFT = true,
    BOTTOM = true, BOTTOMRIGHT = true }

local function IsPoint(point)
    return type(point) == "table" and anchors[point[1]] == true and anchors[point[2]] == true and type(point[3]) == "number"
        and type(point[4]) == "number"
end

-- An addon's block, with each field checked: a value of the wrong type or shape (an edited file, another version) is
-- left out, so it can never stop the window from opening
local function ReadWindow(saved)
    local block = type(saved) == "table" and saved.Window
    if type(block) ~= "table" then return nil end
    local window = { Changed = type(block.Changed) == "number" and block.Changed or nil }
    if IsPoint(block.Point) then window.Point = { block.Point[1], block.Point[2], block.Point[3], block.Point[4] } end
    if type(block.Size) == "table" and type(block.Size[2]) == "number" then window.Size = { tonumber(block.Size[1]) or 0, block.Size[2] } end
    for _, flag in ipairs({ "PaneCollapsed", "SearchAll", "SearchBroad" }) do
        if type(block[flag]) == "boolean" then window[flag] = block[flag] end
    end
    return window
end

local function CopyWindow(window)
    local copy = {}
    for key, value in next, window do
        if type(value) == "table" then
            local inner = {}
            for i, v in ipairs(value) do inner[i] = v end
            copy[key] = inner
        else
            copy[key] = value
        end
    end
    return copy
end

-- The state the window shows: on its first need the newest block among the tabs' tables (one without a change time
-- counts as the oldest), afterwards the one the window keeps (lib.Internal.Shared). Kept on lib, which a newer copy of
-- this file keeps.
local function Shared()
    if not lib.Internal.Shared then
        local newest
        for _, registered in ipairs(lib.Internal.Tabs) do
            local window = ReadWindow(OtherSaved(registered))
            if window and (not newest or (window.Changed or 0) > (newest.Changed or 0)) then newest = window end
        end
        lib.Internal.Shared = newest or {}
    end
    return lib.Internal.Shared
end

-- Every addon's table gets its own copy, so one addon's table never holds another's
local function WriteShared()
    local window = Shared()
    for _, registered in ipairs(lib.Internal.Tabs) do
        local saved = OtherSaved(registered)
        if saved then saved.Window = CopyWindow(window) end
    end
end

-- One of the window's settings changed: the whole block, stamped with the time, goes into every tab that has its saved
-- table, so any one addon alone still opens the window as the player left it. A tab whose table is not there yet gets
-- the next change.
function lib.Internal.SetShared(key, value)
    local window = Shared()
    window[key] = value
    window.Changed = time()
    WriteShared()
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

-- A tab registered after the window exists takes the window's state as it stands, and its OnCreated runs at once; its
-- error goes to the error handler and the tab stays registered
function lib.CreateWindow(config)
    CheckConfig(config)
    local registered = setmetatable({ Config = config }, tab)
    tinsert(lib.Internal.Tabs, registered)
    SortTabs()
    if lib.Internal.Frame then
        local saved = OtherSaved(registered)
        if saved then saved.Window = CopyWindow(Shared()) end
        if config.OnCreated then Protected(config.OnCreated, lib.Internal.Frame) end
        lib.Internal.Frame:RefreshTabs()
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

-- The window, made on its first need in the place the newest of the addons' blocks remembers. The opening tab's saved
-- table comes first: a tab without one stops here, before a frame is made under the window's name. lib.Internal.Frame
-- is set as soon as the frame exists, so a later error never makes a second window. The OnCreated calls run over the
-- tabs as they were: an OnCreated that registers another tab gets that tab's OnCreated from CreateWindow, once.
function lib.Internal.GetFrame(opening)
    if not lib.Internal.Frame then
        (opening or lib.Internal.Tabs[1]):GetSaved()
        local window = Shared()
        local frame = lib.Internal.Build.Window()
        lib.Internal.Frame = frame
        Protected(frame.Init, frame, window) -- the checked block cannot make it fail; if it does, every tab still gets OnCreated
        WriteShared()
        local tabs = {}
        for i, registered in ipairs(lib.Internal.Tabs) do tabs[i] = registered end
        for _, registered in ipairs(tabs) do
            if registered.Config.OnCreated then Protected(registered.Config.OnCreated, frame) end
        end
        frame:RefreshTabs()
    end
    return lib.Internal.Frame
end