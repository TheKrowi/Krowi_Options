--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The window's search (WindowMixin.lua is the window's core): what lib.Search (Search.lua) finds, as the page's rows; the
-- search box, which starts and ends a search; and the check boxes for its scope and breadth. Its state on the window:
-- Searching, SearchEveryTab and BroadSearch.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("WindowSearch", 0)
if not sub then return end

-- A call into the addon whose tab is open: its error goes to the game's error handler and the window goes on with what
-- it got (Krowi_Options.lua, Protected; each file that needs it has its own)
local function Protected(func, ...)
    local args, count = { ... }, select("#", ...)
    return xpcall(function() return func(unpack(args, 1, count)) end, CallErrorHandler)
end

-- [[ The window ]] --
-- Every file of the window adds its methods to this one table (WindowMixin.lua)
lib.Mixins.Window = lib.Mixins.Window or {}
local WindowMixin = lib.Mixins.Window

-- The search box and its check boxes, set up as the window is built (OnLoad, WindowMixin.lua)
function WindowMixin:LoadSearch()
    -- The search follows what the player types; the box's clear button and the window's OnHide empty it without user
    -- input, which ends a search too
    self.SearchBox:HookScript("OnTextChanged", function(box, userInput) if userInput or self.Searching then self:OnSearch(box:GetText()) end end)
    self.SearchBox:HookScript("OnHide", function(box) box:SetText("") end)
    -- Every tab instead of the selected one (unticked by default); kept for every addon like the window's place
    self.SearchAll:SetScript("OnClick", function(button)
        self.SearchEveryTab = button:GetChecked() and true or false
        lib.SetShared("SearchAll", self.SearchEveryTab)
        if self.Searching then self:OnSearch(self.SearchBox:GetText()) end
    end)
    -- Descriptions too (unticked by default: the game's search finds names only); kept like the scope
    self.SearchBroad:SetScript("OnClick", function(button)
        self.BroadSearch = button:GetChecked() and true or false
        lib.SetShared("SearchBroad", self.BroadSearch)
        if self.Searching then self:OnSearch(self.SearchBox:GetText()) end
    end)
end

-- [[ Search ]] --
-- The results as the game's Options window shows them (docs/work/2026-11-03-blizzard-search): the selected tab, or with
-- "Search all tabs" ticked every tab under its addon's name; each section's name, which opens it, then its found rows,
-- working as on its page, under the headings they stand under there
function WindowMixin:SearchElements(text)
    local everyTab = self.SearchEveryTab and #lib.Tabs > 1
    local list = {}
    local broad = self.BroadSearch
    for _, group in ipairs(lib.Search(text, everyTab, self.Tab, broad)) do
        local tab = group.Tab
        if everyTab then list[#list + 1] = { Kind = "Header", Text = tab.Config.TabName } end
        for _, section in ipairs(group.Sections) do
            local id = section.Id
            list[#list + 1] = { Kind = "SearchHeading", Text = section.Name, OnClick = function() self:ShowTab(tab, id) end }
            local heading = 0
            for _, row in ipairs(section.Rows) do
                if row.HeadingAt ~= heading then
                    heading = row.HeadingAt
                    if row.Heading ~= "" then list[#list + 1] = { Kind = "SubHeading", Text = row.Heading } end
                end
                list[#list + 1] = row
            end
        end
    end
    if #list == 0 then list[1] = { Kind = "Note", Text = self.Strings.NoResults } end
    return list
end

-- From the first letter, as the game's; an empty box goes back to the section. scrollPosition: the results found again
-- after a change keep theirs, and a question asked in them stays
function WindowMixin:OnSearch(text, scrollPosition)
    text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if text == "" then
        if self.Searching then self:ShowSection(self.SectionId, nil, true) end
        return
    end
    self.Searching = true
    if not scrollPosition then self.Confirming = nil end
    self.PageTitle:SetText(self.Strings.SearchResults)
    -- As a section's fill (ShowSection): each part on its own, and the fill always ends
    self.Filling = true
    Protected(self.RefreshNav, self)
    Protected(function() self:FillPage(scrollPosition or ScrollBoxConstants.DiscardScrollPosition, self:SearchElements(text)) end)
    if not scrollPosition then Protected(self.ShowSearchHelp, self) end
    self:EndFill()
end