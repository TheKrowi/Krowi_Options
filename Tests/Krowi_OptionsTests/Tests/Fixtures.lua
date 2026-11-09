--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The test addon's fixture: a tab with every config field the library reads (Krowi_Options.lua's header) and every
-- element kind and option type (RowMixins.lua's header), in place of Krowi_AchievementFilter's options, on which the
-- library's checks ran before (KAF's Tests/Options.lua). A second tab is made only by the scenario that needs two
-- (window-second-tab, Scenarios.lua).
-- The option values live in this file for the session, never in saved variables: they start at their defaults on every
-- /reload and Reset puts them back there. The window's own state goes into the table config.Saved gives (the library's
-- Window and LastSection keys).
-- Loaded in game (Tests/Files.xml) and by Headless.lua in the headless harness, so nothing here touches a frame or a
-- game API at load or in what the scenarios call (GetElements, the options' getters, the search's names). The one help
-- that lays a secure button over Show me (Tooltips' ShowMeSecure) hands that to the test addon's stand-in
-- (ShowMeStandIn.lua), which only the game loads; headless it lays nothing over.
-- For the live steps (Steps.lua) the fixture also answers what they set and counts what they ask: Window's Show me
-- (ShowMeAnswer, CanShowMeAnswer, ShowMeRuns), ResetSection's calls per section (ResetCalls) and the tab list's order
-- (GetTabOrder, SetTabOrder); Reset puts each back.
-- Words the scenarios search for (Scenarios.lua), by name unless said: "lantern" stands in three descriptions and a help
-- text and in no name, "loaded" only in the Other addons section's three names, "Reset position" only on the Position
-- heading's three buttons, "reverse" only in the Points tooltip names, "tooltip" in names on both tabs, "places" only in
-- Center the title's description (search-broad). Keep them so when adding rows; their Recorded lines show any change.

local _, addon = ...
addon.Tests = addon.Tests or {}
local fixtures = {}
addon.Tests.Fixtures = fixtures

fixtures.TabName = "Options Test"
fixtures.SecondTabName = "Aa Test" -- sorts before the first, so registering it proves the tabs' order

-- [[ Pictures ]] --
-- At the sizes of Krowi_AchievementFilter's NewTabs and CategoryTree help pictures (a wide one, cut at its right, and a
-- tall one, cut at its bottom), and a square one whose card shows its bottom part (Part); any texture serves in game,
-- the sizes decide the cut
local white = "Interface\\Buttons\\WHITE8X8"
local questionMark = "Interface\\Icons\\INV_Misc_QuestionMark"
fixtures.Pictures = {
    Wide = { Picture = white, Width = 808, Height = 134, TexCoords = { 0, 0.947265625, 0, 0.625 } },
    Tall = { Picture = white, Width = 307, Height = 448, TexCoords = { 0, 0.71875, 0, 0.525390625 } },
    Square = { Picture = white, Width = 400, Height = 400, TexCoords = { 0, 1, 0, 1 }, Part = { X = 0, Y = 1 } },
}

-- [[ Options ]] --
-- The option interface of RowMixins.lua's header, every optional method included
local values, defaults = {}, {}
local byId = {}
fixtures.Options = byId

local option = {}
option.__index = option

function option:GetLabel()
    return self.Label
end

function option:IsHidden()
    return self.HiddenIf ~= nil and self.HiddenIf() or false
end

function option:IsDisabled()
    return self.DisabledIf ~= nil and self.DisabledIf() or false
end

function option:GetDescription()
    return self.Description or ""
end

function option:Get()
    if self.Type == "key" then return self.Slots[1]:Get() end
    return values[self.Id]
end

-- An execute option's Set runs it: it counts its runs, and runs OnRun where it has one
function option:Set(value)
    if self.Type == "execute" then
        self.Runs = (self.Runs or 0) + 1
        if self.OnRun then self.OnRun() end
        return
    end
    values[self.Id] = value
end

function option:IsChanged()
    if self.Type == "key" then
        for _, slot in ipairs(self.Slots) do
            if slot:IsChanged() then return true end
        end
        return false
    end
    return values[self.Id] ~= defaults[self.Id]
end

function option:Reset()
    if self.Type == "key" then
        for _, slot in ipairs(self.Slots) do slot:Reset() end
        return
    end
    values[self.Id] = defaults[self.Id]
end

function option:GetNeedsReload()
    return self.NeedsReload or false
end

function option:GetDefault()
    if defaults[self.Id] == nil then return false end
    return true, defaults[self.Id]
end

function option:FormatValue(value)
    if self.Type == "toggle" then return value and "On" or "Off" end
    if self.Type == "range" then return self:Format(value) end
    if self.Type == "select" then
        for _, pair in ipairs(self.Values) do
            if pair[1] == value then return pair[2] end
        end
    end
    return tostring(value)
end

function option:GetParent()
    return self.Parent
end

function option:GetRange()
    return self.Min, self.Max, self.Step
end

function option:Format(value)
    if self.Unit then return ("%d %s"):format(value, self.Unit) end
    return tostring(value)
end

function option:GetValues()
    return self.Values
end

function option:GetButtonText()
    return self.ButtonText
end

local function New(spec)
    spec.Indent = spec.Indent or 0
    setmetatable(spec, option)
    if spec.Default ~= nil then
        defaults[spec.Id], values[spec.Id] = spec.Default, spec.Default
    end
    byId[spec.Id] = spec
    return spec
end

local function Toggle(id, label, default, extra)
    local spec = extra or {}
    spec.Id, spec.Type, spec.Label, spec.Default = id, "toggle", label, default
    spec.Description = spec.Description or ("What " .. label:lower() .. " does.")
    return New(spec)
end

local function Always()
    return true
end

-- Window: the toggle, range and input the change steps use, a check box with a slider that needs a reload while the
-- check box does not (undo-reload, Steps.lua), one that needs a reload, and three check boxes with a button each
local centerTitle = Toggle("window.centerTitle", "Center the title", false, { Description = "Places the window's title in the middle of its bar." })
local indentation = New{ Id = "window.indentation", Type = "range", Label = "Indentation", Default = 15, Min = 0, Max = 40, Step = 5, Unit = "px",
    Description = "How far each level of a list moves in." }
local dateFormat = New{ Id = "window.dateFormat", Type = "input", Label = "Date format", Default = "dd.mm.yyyy", Description = "How the list writes a date." }
local twoColumns = Toggle("window.twoColumns", "Force two columns", true, { Description = "Splits a long list in two columns." })
local columnThreshold = New{ Id = "window.columnThreshold", Type = "range", Label = "Column threshold", Default = 8, Min = 1, Max = 20, Step = 1,
    NeedsReload = true, Description = "The number of rows from which a list splits.", DisabledIf = function() return not twoColumns:Get() end }
local oldLook = Toggle("window.oldLook", "Use the old look", false, { NeedsReload = true,
    Description = "Draws the window as it looked before, lantern art included." })
local function Remember(key, label)
    local remember = Toggle("window.remember" .. key, label, true)
    local reset = New{ Id = "window.reset" .. key, Type = "execute", Label = "Reset " .. label:gsub("^Remember ", ""):gsub(" position$", "") .. " position",
        ButtonText = "Reset position", Description = "Puts it back where it starts." }
    return remember, reset
end
local rememberMain, resetMain = Remember("Main", "Remember main window position")
local rememberCalendar, resetCalendar = Remember("Calendar", "Remember calendar position")
local rememberLog, resetLog = Remember("Log", "Remember log position")
local buttonX = New{ Id = "window.buttonX", Type = "range", Label = "Button: horizontal position", Default = 0, Min = -500, Max = 500, Step = 1 }
local buttonY = New{ Id = "window.buttonY", Type = "range", Label = "Button: vertical position", Default = 0, Min = -500, Max = 500, Step = 1 }
local resetView = Toggle("window.resetView", "Reset view on open", true)

-- Tooltips, the longest section: a check box with children across a sub-heading, rows indented under the row above
-- (the reverse sorts), and two skins
local details = Toggle("tooltips.details", "Show details", true)
local function Detail(id, label, default)
    return Toggle(id, label, default, { Indent = 1, Parent = details, DisabledIf = function() return not details:Get() end })
end
local ifCompleted = Detail("tooltips.ifCompleted", "Quest is completed", true)
local ifNotDone = Detail("tooltips.ifNotDone", "Quest was not done by me", false)
local ifStep = Detail("tooltips.ifStep", "Step is completed", true)
local sortValues = { { "name", "Name" }, { "points", "Points" }, { "date", "Date" } }
local sorts = {}
for i = 1, 3 do
    sorts[i] = {
        New{ Id = "tooltips.sort" .. i, Type = "select", Label = "Sort priority " .. i, Default = sortValues[i][1], Values = sortValues },
        Toggle("tooltips.reverse" .. i, "Reverse sort", false, { Indent = 1 }),
    }
end
local showIn = Toggle("tooltips.showIn", "Show in tooltip", true)
local compact = Toggle("tooltips.compact", "Compact lines", false)
local skin = Toggle("tooltips.skin", "Skin tooltip", true)
local thinBorder = Toggle("tooltips.thinBorder", "Thin border", false)

-- Debug: a child that hides with its parent, an input box greyed with its parent (greyed-slider-input-box, Steps.lua; its
-- name and description hold none of the words the recorded searches look for), a dropdown greyed with its parent, a
-- dropdown that asks before a choice, and a button
local verbose = Toggle("debug.verbose", "Verbose mode", true, { Description = "Prints what the window does, a lantern for debugging." })
local trace = Toggle("debug.trace", "Trace calls", false, { Indent = 1, Parent = verbose, HiddenIf = function() return not verbose:Get() end })
local logFile = New{ Id = "debug.logFile", Type = "input", Label = "Log file", Default = "debug.log", Indent = 1, Parent = verbose,
    DisabledIf = function() return not verbose:Get() end, Description = "The file the log is written to." }
local tabPriority = Toggle("debug.tabPriority", "Tab priority", true, { Description = "Opens the tab with the highest priority first." })
local priorityOrder = New{ Id = "debug.priorityOrder", Type = "select", Label = "Priority order", Default = "first", Indent = 1, Parent = tabPriority,
    Values = { { "first", "First tab first" }, { "last", "Last tab first" } }, DisabledIf = function() return not tabPriority:Get() end,
    Description = "Which end of the list wins." }
-- The dropdown's button (a select's With, 2.1): it opens Key bindings and stays enabled while the dropdown is greyed
local goKeys = New{ Id = "debug.goKeys", Type = "execute", Label = "Go to Key bindings", ButtonText = "Go to Key bindings",
    Description = "Opens the Key bindings section.", OnRun = function() fixtures.Tab:Open("keys") end }
local profile = New{ Id = "debug.profile", Type = "select", Label = "Profile", Default = "default", Placeholder = "Pick a profile",
    Values = { { "default", "Default" }, { "alternate", "Alternate" } }, Description = "The set of settings in use.",
    Confirm = function(self, value) return ("Switch to the %s profile?"):format(self:FormatValue(value)) end }
local resetAll = New{ Id = "debug.resetAll", Type = "execute", Label = "Reset everything", ButtonText = "Reset", NeedsReload = true,
    Description = "Sets every option of this tab back." }

-- Events: a family with All / None, and a grid with a short row and a greyed-out check box
local function Season(name, default, description)
    return Toggle("events." .. name:lower(), name, default, { Indent = 1, Description = description })
end
local seasons = {
    Season("Spring", true, "Lights the spring lantern in the calendar."), Season("Summer", true), Season("Autumn", false), Season("Winter", true),
}
local function Cell(row, column, default, disabled)
    return Toggle(("events.%s.%s"):format(row, column:lower()), ("%s: %s"):format(row, column), default, { DisabledIf = disabled })
end
local gridColumns = { "Show", "Remind", "Sound" }
local gridRows = {
    { Label = "Market day", Cells = { Cell("Market day", "Show", true), Cell("Market day", "Remind", false), Cell("Market day", "Sound", false) } },
    { Label = "Harvest fair", Cells = { Cell("Harvest fair", "Show", true), Cell("Harvest fair", "Remind", true) } },
    { Label = "Moon festival", Cells = { Cell("Moon festival", "Show", false), Cell("Moon festival", "Remind", false), Cell("Moon festival", "Sound", false, Always) } },
}

-- Tabs: a tab list whose first tab cannot move up and whose last has no Show (no check box)
local tabShows = {
    summary = Toggle("tabs.summary", "Summary", true),
    watch = Toggle("tabs.watch", "Watch list", true),
    stats = Toggle("tabs.stats", "Statistics", false),
}
local defaultTabOrder = { "summary", "watch", "stats", "blizzard" }
local tabOrder
local rememberTab = Toggle("tabs.rememberTab", "Remember the last tab", true)

-- Keys: two slots and one, kept here (never a binding of the game)
local function Slot(id, default)
    return New{ Id = id, Type = "slot", Default = default }
end
local openKey = New{ Id = "keys.open", Type = "key", Label = "Open the window", Slots = { Slot("keys.open.1", "CTRL-SHIFT-O"), Slot("keys.open.2", "") },
    Description = "The keys that open the window." }
local listKey = New{ Id = "keys.list", Type = "key", Label = "Toggle the list", Slots = { Slot("keys.list.1", "") }, Description = "The key that shows or hides the list." }

-- Other addons: the same name under three headings
local plugins = {
    { Name = "Alpha UI", Rows = { Toggle("addons.alpha.loaded", "Loaded", true, { DisabledIf = Always }), Toggle("addons.alpha.skin", "Skin tooltip", true) } },
    { Name = "Beta Bars", Rows = { Toggle("addons.beta.loaded", "Loaded", true, { DisabledIf = Always }), Toggle("addons.beta.bars", "Restyle bars", false) } },
    { Name = "Gamma Maps", Rows = { Toggle("addons.gamma.loaded", "Loaded", true, { DisabledIf = Always }) } },
}

-- The second tab's only option (SecondConfig)
local secondTooltip = Toggle("second.tooltip", "Second tooltip", false)

-- [[ Sections ]] --
fixtures.Groups = {
    { Name = "General", Sections = { "window", "tooltips", "debug" } },
    { Name = "Lists", Sections = { "events", "tabs", "keys", "addons" } },
    { Name = "About", Sections = { "about" } },
}
local sectionNames = { window = "Window", tooltips = "Tooltips", debug = "Debug", events = "Events", tabs = "Tabs", keys = "Key bindings",
    addons = "Other addons", about = "About" }
fixtures.Sections = {} -- every section id in the navigation's order
for _, group in ipairs(fixtures.Groups) do
    for _, id in ipairs(group.Sections) do fixtures.Sections[#fixtures.Sections + 1] = id end
end

local function SectionName(id)
    if id == "overview" then return "Overview" end
    return sectionNames[id] or id
end
fixtures.SectionName = SectionName

local function IsNew(id)
    return id == "tabs"
end

local function Header(text)
    return { Kind = "Header", Text = text }
end

local function Row(o, with)
    return { Kind = "Option", Option = o, With = with }
end

-- Overview's cards: a picture (wide, tall, or a square's bottom) or an icon, and a line
local cardLines = {
    window = { "Wide", "The title, the columns, dates and where the windows stand." },
    tooltips = { "Tall", "What a unit's tooltip shows, and in which order." },
    debug = { nil, "Output, priorities and profiles." },
    events = { "Square", "The seasons and the calendar grid." },
    tabs = { "Wide", "Which tabs show, and their order." },
    keys = { nil, "The keys of the window and the list." },
    addons = { "Tall", "What this tab does with other addons." },
    about = { nil, "Who made it." },
}

local function Card(id)
    local line = cardLines[id]
    local card = { Name = SectionName(id), Text = line[2], IsNew = IsNew(id), OnClick = function() fixtures.Tab:Open(id) end }
    local picture = line[1] and fixtures.Pictures[line[1]]
    if picture then
        for key, value in next, picture do card[key] = value end
    else
        card.Icon = questionMark
    end
    return card
end

local function TabItems()
    local items = {}
    for index, key in ipairs(tabOrder) do
        local item = { Position = tostring(index), Show = tabShows[key], Source = key == "blizzard" and "Blizzard" or fixtures.TabName }
        if index > 1 then
            item.MoveUp = function() tabOrder[index - 1], tabOrder[index] = tabOrder[index], tabOrder[index - 1] end
        end
        if index < #tabOrder then
            item.MoveDown = function() tabOrder[index + 1], tabOrder[index] = tabOrder[index], tabOrder[index + 1] end
        end
        items[index] = item
    end
    return items
end

-- The tab list's order, as a copy (tab-arrows and Restore, Steps.lua), and set from one
function fixtures.GetTabOrder()
    return { unpack(tabOrder) }
end

function fixtures.SetTabOrder(order)
    tabOrder = { unpack(order) }
end

local builders = {}

function builders.overview()
    local elements = {}
    for _, group in ipairs(fixtures.Groups) do
        elements[#elements + 1] = Header(group.Name)
        local cards = {}
        for _, id in ipairs(group.Sections) do cards[#cards + 1] = Card(id) end
        elements[#elements + 1] = { Kind = "Cards", Cards = cards }
    end
    return elements
end

function builders.window()
    return {
        Header("General"),
        Row(centerTitle), Row(indentation), Row(dateFormat), Row(twoColumns, columnThreshold), Row(oldLook),
        Header("Position"),
        Row(rememberMain, resetMain), Row(rememberCalendar, resetCalendar), Row(rememberLog, resetLog), Row(buttonX), Row(buttonY), Row(resetView),
    }
end

function builders.tooltips()
    local elements = {
        Header("Unit tooltips"),
        Row(details),
        { Kind = "SubHeading", Text = "Show details if" },
        Row(ifCompleted), Row(ifNotDone), Row(ifStep),
        Header("Points tooltip"),
    }
    for _, pair in ipairs(sorts) do
        elements[#elements + 1] = Row(pair[1])
        elements[#elements + 1] = Row(pair[2])
    end
    for _, element in ipairs({ Header("Display"), Row(showIn), Row(compact), Header("Skins"), Row(skin), Row(thinBorder) }) do
        elements[#elements + 1] = element
    end
    return elements
end

function builders.debug()
    return {
        Header("Output"), Row(verbose), Row(trace), Row(logFile),
        Header("Priority"), Row(tabPriority), Row(priorityOrder, goKeys),
        Header("Profiles"), Row(profile), Row(resetAll),
    }
end

function builders.events()
    local elements = { Header("Seasons"), { Kind = "Sub", Text = "All seasons", Members = seasons } }
    for _, season in ipairs(seasons) do elements[#elements + 1] = Row(season) end
    elements[#elements + 1] = Header("Calendar grid")
    elements[#elements + 1] = { Kind = "Grid", Columns = gridColumns, Rows = gridRows }
    return elements
end

function builders.tabs()
    return { Header("Order"), { Kind = "TabList", Items = TabItems() }, Header("Behaviour"), Row(rememberTab) }
end

function builders.keys()
    return {
        { Kind = "Note", Text = "The keys set here stay in this test addon: no key of the game is bound." },
        Header("Window"), Row(openKey),
        Header("List"), Row(listKey),
    }
end

function builders.addons()
    local elements = {}
    for _, plugin in ipairs(plugins) do
        elements[#elements + 1] = Header(plugin.Name)
        for _, o in ipairs(plugin.Rows) do elements[#elements + 1] = Row(o) end
    end
    return elements
end

function builders.about()
    return {
        Header("Credits"),
        { Kind = "Note", Text = "Made for the tests of Krowi_Options." },
        { Kind = "SubHeading", Text = "Thanks" },
        { Kind = "Note", Text = "To everyone who reports a bug." },
        Header("Links"),
        { Kind = "Link", Text = "Debug settings", Detail = "Opens the Debug section", OnClick = function() fixtures.Tab:Open("debug") end },
        { Kind = "Link", Text = "Key bindings", Detail = "Opens the Key bindings section", OnClick = function() fixtures.Tab:Open("keys") end },
    }
end

local function GetElements(id)
    local build = builders[id]
    return build and build() or {}
end
fixtures.GetElements = GetElements

-- Every option a section shows: rows and what they carry, a family's members, grid cells, tabs' Show
local function SectionOptions(id)
    local list, seen = {}, {}
    local function Add(o)
        if o and not seen[o] then
            seen[o] = true
            list[#list + 1] = o
        end
    end
    for _, element in ipairs(GetElements(id)) do
        Add(element.Option)
        Add(element.With)
        for _, member in ipairs(element.Members or {}) do Add(member) end
        for _, row in ipairs(element.Rows or {}) do
            for _, cell in ipairs(row.Cells or {}) do Add(cell) end
        end
        for _, item in ipairs(element.Items or {}) do Add(item.Show) end
    end
    return list
end

local function ChangedCount(id)
    local count = 0
    for _, o in ipairs(SectionOptions(id)) do
        if o:IsChanged() then count = count + 1 end
    end
    return count
end
fixtures.ChangedCount = ChangedCount

-- Returns whether an option it set back needs a reload. Counts its calls per section (ResetCalls), which the defaults
-- step reads.
local function ResetSection(id)
    fixtures.ResetCalls[id] = (fixtures.ResetCalls[id] or 0) + 1
    local reload = false
    for _, o in ipairs(SectionOptions(id)) do
        if o:IsChanged() then
            if o:GetNeedsReload() then reload = true end
            o:Reset()
        end
    end
    if id == "tabs" then tabOrder = { unpack(defaultTabOrder) } end
    return reload
end

-- [[ Help ]] --
local function Picture(name)
    local picture = fixtures.Pictures[name]
    return { Picture = picture.Picture, Width = picture.Width, Height = picture.Height, TexCoords = picture.TexCoords }
end

-- Window's Show me answers what the show-me step sets and counts its runs (Steps.lua); by default it answers as it did
-- before that step existed (ShowMe false, CanShowMe true). Tooltips' lays a secure button over Show me, as
-- Krowi_AchievementFilter's map help does: in game the test addon's stand-in (ShowMeStandIn.lua), headless none, where
-- it lets go and answers that it cannot lie over Show me.
local helps = {
    overview = { Title = "Options Test", Blocks = {
        { Text = "A tab with every element kind and option type of Krowi_Options, for its tests." },
        { Heading = "Markers" },
        { Term = "Gold line", Text = "the option is changed." },
    } },
    window = { Title = "Window", Blocks = {
        Picture("Wide"),
        { Text = "Where the windows stand and how the list looks. The lantern art comes with the old look." },
        { Heading = "Position" },
        { Term = "Reset position", Text = "puts a window back where it starts." },
    }, ShowMe = function()
        fixtures.ShowMeRuns = (fixtures.ShowMeRuns or 0) + 1
        return fixtures.ShowMeAnswer
    end, CanShowMe = function() return fixtures.CanShowMeAnswer end },
    tooltips = { Title = "Tooltips", Blocks = { Picture("Tall"), { Text = "What a unit's tooltip shows." } },
        ShowMeSecure = function(button, close)
            local standIn = addon.Tests.ShowMeStandIn
            if not standIn then return button == nil end
            return standIn.ShowMeSecure(button, close)
        end,
        ShowMeNote = "No button can lie over Show me here, so this note shows in its place." },
}

-- About has no help: its pane shows its title alone
local function GetHelp(id)
    if id == "about" then return nil end
    return helps[id] or { Title = SectionName(id), Blocks = { { Text = "The help of the " .. SectionName(id) .. " section." } } }
end

-- [[ The tabs ]] --
local savedSource

local function Landing()
    local saved = savedSource
    if type(saved) == "function" then saved = saved() end
    local last = type(saved) == "table" and saved.LastSection
    return sectionNames[last] and last or "overview"
end

-- Every option back at its default, the tab list in its first order, Show me's answers at their defaults, nothing seen
-- or counted yet
function fixtures.Reset()
    for id in next, values do values[id] = defaults[id] end
    for _, o in next, byId do o.Runs = nil end
    tabOrder = { unpack(defaultTabOrder) }
    fixtures.ShowMeAnswer, fixtures.CanShowMeAnswer, fixtures.ShowMeRuns = false, true, 0
    fixtures.ResetCalls = {}
    fixtures.LastShown, fixtures.Created, fixtures.Frame = nil, nil, nil
    fixtures.Tab, fixtures.SecondTab = nil, nil
end
fixtures.Reset()

-- The config of the fixture tab: every field, OnCreated included. saved: config.Saved, a table or a function
function fixtures.Config(saved)
    savedSource = saved
    return {
        TabName = fixtures.TabName,
        Saved = saved,
        Groups = fixtures.Groups,
        SectionName = SectionName,
        IsNew = IsNew,
        Landing = Landing,
        OnSectionShown = function(id) fixtures.LastShown = id end,
        GetElements = GetElements,
        GetHelp = GetHelp,
        ResetSection = ResetSection,
        ChangedCount = ChangedCount,
        OnCreated = function(frame)
            fixtures.Created = (fixtures.Created or 0) + 1
            fixtures.Frame = frame
        end,
    }
end

function fixtures.Register(lib, saved)
    fixtures.Tab = lib.CreateWindow(fixtures.Config(saved))
    return fixtures.Tab
end

-- A second addon's tab, as Krowi_AchievementFilter's window-second-tab scenario made it: only the five fields a config
-- must have, the window's defaults for the rest, and one section with one option
function fixtures.SecondConfig(saved)
    return {
        TabName = fixtures.SecondTabName,
        Saved = saved,
        Groups = { { Name = "Second", Sections = { "second" } } },
        SectionName = function() return "Second" end,
        GetElements = function() return { Row(secondTooltip) } end,
    }
end