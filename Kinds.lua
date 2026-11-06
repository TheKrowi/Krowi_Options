--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The element kinds of a section's page (what an addon writes in each: RowMixins.lua's header), one entry each in
-- lib.Kinds:
--   Build         the builder of the kind's row: a name on lib.Build (RowFrames.lua), looked up for each row
--   Height        the row's height in the list: a number, or function(window, element) for a row as tall as its content
--   Expand        function(element, list): a kind drawn as several rows (cards, a grid, a tab list) adds them to list
--   Hidden        function(element): true leaves the element out of the page and the search
--   Names         function(element): the texts the search finds the row by (strings; anything else is skipped), as the
--                 game's search tags a setting (Blizzard_SettingControls.lua); a kind without Names is not searched
--   Descriptions  function(element): the texts the broad search finds it by too
--   Options       function(element): the option the row stands for and the one beside it (an option's With), which the
--                 page's signature and the hovered row's help follow (WindowMixin.lua)
--   Cells         function(element): the options in a grid row's check boxes
--   Search       where a row stands for the search (Search.lua): Heading (1 for a heading that also ends the indents and
--                 the grid above it, 2 for one that does not), Indented (it hangs under its option's parent or the row
--                 above it with a smaller indent), BringsMembers (found, it brings its member options), Columns (a grid's
--                 column titles) and UnderColumns (a grid row, which hangs under the titles above it)
-- Only this file writes lib.Kinds, and each entry whole, so the newest copy of this file decides every kind and no entry
-- mixes two copies. A newer copy that adds a kind raises this file, RowFrames.lua and RowMixins.lua together. What the
-- kinds make of a section's elements (lib.Flatten) and the lists' pooling (lib.InitList) are here too: they need the
-- kinds, not the window.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
-- Not "Kinds": LibMan hangs the submodule on lib under its name, where lib.Kinds is the table of kinds below
local sub, lib = KROWI_LIBMAN:NewSubmodule("ElementKinds", 0)
if not sub then return end

lib.Kinds = lib.Kinds or {}
local kinds = lib.Kinds

-- [[ Headings and text ]] --
kinds.Header = { Build = "HeaderRow", Height = 34, Search = { Heading = 1 } }
kinds.SubHeading = { Build = "SubHeadingRow", Height = 26, Search = { Heading = 2 } }
-- As tall as its text, wrapped to the page's width
kinds.Note = { Build = "NoteRow", Height = function(window, element)
    return window:MeasureText(element.Text, "GameFontDisable", window:PageWidth() - 32) + 8
end }

-- [[ An option ]] --
kinds.Option = {
    Build = "OptionRow",
    Height = 30,
    Hidden = function(element) return element.Option:IsHidden() end,
    -- Its name, and its check box's button text or slider name
    Names = function(element)
        local with = element.With
        local withName = with and not with:IsHidden() and (with.Type == "execute" and with:GetButtonText() or with:GetLabel()) or nil
        return element.Option:GetLabel(), withName
    end,
    Descriptions = function(element)
        local option, with = element.Option, element.With
        local withDescription = with and not with:IsHidden() and with.GetDescription and with:GetDescription() or nil
        return option.GetDescription and option:GetDescription(), withDescription
    end,
    Options = function(element) return element.Option, element.With end,
    Search = { Indented = true },
}

-- [[ A family heading or a group's All / None ]] --
kinds.Sub = {
    Build = "SubRow",
    Height = 28,
    Names = function(element) return element.Text end,
    Search = { Indented = true, BringsMembers = true },
}

-- [[ A grid: its column titles, then a row of check boxes per line ]] --
kinds.Grid = { Expand = function(element, list)
    list[#list + 1] = { Kind = "GridHeader", Columns = element.Columns }
    for _, row in ipairs(element.Rows) do
        list[#list + 1] = { Kind = "GridRow", Label = row.Label, Cells = row.Cells }
    end
end }
kinds.GridHeader = { Build = "GridHeaderRow", Height = 34, Search = { Columns = true } }
kinds.GridRow = {
    Build = "GridRow",
    Height = 28,
    Names = function(element) return element.Label end,
    Cells = function(element) return element.Cells end,
    Search = { UnderColumns = true },
}

-- [[ A tab list: a row per tab ]] --
kinds.TabList = { Expand = function(element, list)
    for _, item in ipairs(element.Items) do
        list[#list + 1] = { Kind = "TabRow", Item = item }
    end
end }
kinds.TabRow = {
    Build = "TabRow",
    Height = 28,
    Names = function(element)
        local show = element.Item.Show
        return show and show:GetLabel()
    end,
    -- Its Show check box's option; a tab without one stands for no option
    Options = function(element) return element.Item and element.Item.Show end,
}

-- [[ A link ]] --
kinds.Link = { Build = "LinkRow", Height = 26 }

-- [[ Cards: three to a row (lib.CardColumns, RowMixins.lua), each row as tall as its tallest card ]] --
kinds.Cards = { Expand = function(element, list)
    local cards, columns = element.Cards, lib.CardColumns
    for first = 1, #cards, columns do
        local row, names = { Kind = "CardRow", Cards = {} }, {}
        for i = first, math.min(first + columns - 1, #cards) do
            row.Cards[#row.Cards + 1] = cards[i]
            names[#names + 1] = cards[i].Name or ""
        end
        row.Key = table.concat(names, ",")
        list[#list + 1] = row
    end
end }
kinds.CardRow = { Build = "CardRow", Height = function(window, element)
    return lib.CardRowHeight(window, element)
end }

-- [[ A section's name in the search results ]] --
kinds.SearchHeading = { Build = "SearchHeadingRow", Height = 45 }

-- [[ A section's rows ]] --
-- A section's elements as rows: a kind that expands as several rows, a hidden element left out. known: the kinds the
-- page draws (lib.Kinds), nil keeps every kind (the search's rows). A section without elements (GetElements gives nil)
-- has no rows.
function lib.Flatten(elements, known)
    local list = {}
    for _, element in ipairs(elements or {}) do
        local kind = lib.Kinds[element.Kind]
        if kind and kind.Expand then
            kind.Expand(element, list)
        elseif kind and kind.Hidden then
            if not kind.Hidden(element) then list[#list + 1] = element end
        elseif not known or known[element.Kind] then
            list[#list + 1] = element
        end
    end
    return list
end

-- [[ The lists ]] --
-- An element's height in its list: its kind's number, or what its kind's function measures
local function Extent(window, listKinds, element)
    local height = listKinds[element.Kind].Height
    if type(height) == "function" then return height(window, element) end
    return height
end

-- The rows are built in Lua, without a template, and a list pools the frames it hands out by frame type alone, so a
-- header's frame could come back for an option row (Blizzard_SharedXMLBase FrameFactory.lua). So the list hands out a
-- plain frame, and the row of the element's kind hangs on it as frame.Row, from a pool per kind; when the list lets the
-- frame go, its row goes back (docs/work/2026-11-04-krowi-options-library). Code that walks a list's frames reads
-- frame.Row. listKinds: lib.Kinds for the page, or a table in its shape (Build, Height) for the window's other lists
-- (WindowMixin.lua); leftPad and spacing as CreateScrollBoxListLinearView takes them.
function lib.InitList(window, scrollBox, scrollBar, listKinds, leftPad, spacing)
    local free = {} -- per kind, the rows not hung on a frame
    local function Release(host)
        local row = host.Row
        if not row then return end
        row:Hide()
        row:ClearAllPoints()
        free[row.ListKind] = free[row.ListKind] or {}
        tinsert(free[row.ListKind], row)
        host.Row = nil
    end
    local view = CreateScrollBoxListLinearView(0, 0, leftPad or 0, 0, spacing or 0)
    view:SetElementFactory(function(factory, element)
        local kind = element.Kind
        factory("Frame", function(host, data)
            if host.Row and host.Row.ListKind ~= kind then Release(host) end
            local row = host.Row
            if not row then
                row = free[kind] and tremove(free[kind])
                if not row then
                    row = lib.Build[listKinds[kind].Build](host)
                    row.ListKind = kind
                end
                row:SetParent(host)
                row:SetAllPoints(host)
                row:Show()
                host.Row = row
            end
            if row.Init then row:Init(data, window) end
        end)
    end)
    -- A resetter replaces the pool's own, which hides the frame and clears its anchors
    view:SetFrameFactoryResetter(function(_, host)
        Release(host)
        host:Hide()
        host:ClearAllPoints()
    end)
    view:SetElementExtentCalculator(function(_, element) return Extent(window, listKinds, element) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
    return ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar)
end