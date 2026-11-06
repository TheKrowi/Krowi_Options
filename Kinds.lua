--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The element kinds of a section's page (what an addon writes in each: RowMixins.lua's header), one entry each in
-- lib.Kinds:
--   Build   the builder of the kind's row: a name on lib.Build (RowFrames.lua), looked up for each row
--   Height  the row's height in the list: a number, or function(window, element) for a row as tall as its content
-- Only this file writes lib.Kinds, and each entry whole, so the newest copy of this file decides every kind and no entry
-- mixes two copies. A newer copy that adds a kind raises this file, RowFrames.lua and RowMixins.lua together. The lists'
-- pooling (lib.InitList) is here too: it needs the kinds, not the window.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
-- Not "Kinds": LibMan hangs the submodule on lib under its name, where lib.Kinds is the table of kinds below
local sub, lib = KROWI_LIBMAN:NewSubmodule("ElementKinds", 0)
if not sub then return end

lib.Kinds = lib.Kinds or {}
local kinds = lib.Kinds

-- [[ Headings and text ]] --
kinds.Header = { Build = "HeaderRow", Height = 34 }
kinds.SubHeading = { Build = "SubHeadingRow", Height = 26 }
-- As tall as its text, wrapped to the page's width
kinds.Note = { Build = "NoteRow", Height = function(window, element)
    return window:MeasureText(element.Text, "GameFontDisable", window:PageWidth() - 32) + 8
end }

-- [[ An option, a family heading or a group's All / None ]] --
kinds.Option = { Build = "OptionRow", Height = 30 }
kinds.Sub = { Build = "SubRow", Height = 28 }

-- [[ A grid's column titles and its rows ]] --
kinds.GridHeader = { Build = "GridHeaderRow", Height = 34 }
kinds.GridRow = { Build = "GridRow", Height = 28 }

-- [[ A tab list's row ]] --
kinds.TabRow = { Build = "TabRow", Height = 28 }

-- [[ A link ]] --
kinds.Link = { Build = "LinkRow", Height = 26 }

-- [[ A row of cards: as tall as its tallest card (RowMixins.lua) ]] --
kinds.CardRow = { Build = "CardRow", Height = function(window, element)
    return lib.CardRowHeight(window, element)
end }

-- [[ A section's name in the search results ]] --
kinds.SearchHeading = { Build = "SearchHeadingRow", Height = 45 }

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