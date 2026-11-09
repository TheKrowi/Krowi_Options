--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The rows' frames, built in Lua as Rows.xml declared them up to 1.0. An XML virtual template is a global name: a second
-- copy of the library, embedded by another addon, declared each one again, and the game warned that it already existed
-- (docs/work/2026-11-04-krowi-options-library). A builder makes the regions and child frames the template declared, in
-- its order, mixes in the row's mixin (RowMixins.lua), sets the scripts the template named and runs OnLoad last, as XML
-- did once the children existed. A row is built hidden, so no edit box in it takes the keyboard while it is made.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("RowFrames", 1)
if not sub then return end

-- What is not the public surface lives under lib.Internal (Krowi_Options.lua)
lib.Internal = lib.Internal or {}

local build = lib.Internal.Build

-- [[ Pieces ]] --

-- A font string with the template's font and justification
local function Text(frame, layer, font, justifyH, justifyV)
    local text = frame:CreateFontString(nil, layer, font)
    if justifyH then text:SetJustifyH(justifyH) end
    if justifyV then text:SetJustifyV(justifyV) end
    return text
end
build.Text = Text

-- A flat colour, as a template's <Color>
local function Color(frame, layer, r, g, b, a, subLevel)
    local texture = frame:CreateTexture(nil, layer, nil, subLevel)
    texture:SetColorTexture(r, g, b, a)
    return texture
end
build.Color = Color

-- A button's state texture from an atlas: a template's state texture without anchors fills its button
local function StateAtlas(button, atlas)
    local texture = button:CreateTexture()
    texture:SetAtlas(atlas)
    texture:SetAllPoints()
    return texture
end

-- The mixin, the scripts the template named ({ Script = "Method" }) and its OnLoad last
local function Finish(frame, mixin, scripts)
    Mixin(frame, mixin)
    for script, method in next, scripts or {} do
        if script ~= "OnLoad" then frame:SetScript(script, assert(frame[method], method)) end
    end
    if scripts and scripts.OnLoad then frame[scripts.OnLoad](frame) end
    return frame
end
build.Finish = Finish

-- A list row, hidden until the list hangs it on its frame. It has no height of its own: the list sets it to all of its
-- frame (lib.Internal.InitList, Kinds.lua) before it is shown, and sizes that frame by the element's kind.
local function Row(frameType, parent)
    local row = CreateFrame(frameType, nil, parent)
    row:Hide()
    return row
end
build.Row = Row

-- [[ Controls ]] --

-- The minimal check box of Blizzard's own settings (Blizzard_SettingControls.xml), which fires its hover while greyed out
-- too (motionScriptsWhileDisabled), so the help still says what a disabled option is
function build.CheckButton(parent)
    local button = CreateFrame("CheckButton", nil, parent)
    button:SetMotionScriptsWhileDisabled(true)
    button:SetSize(30, 29)
    button:SetNormalTexture(StateAtlas(button, "checkbox-minimal"))
    button:SetPushedTexture(StateAtlas(button, "checkbox-minimal"))
    button:SetCheckedTexture(StateAtlas(button, "checkmark-minimal"))
    button:SetDisabledCheckedTexture(StateAtlas(button, "checkmark-minimal-disabled"))
    return button
end

-- The key button of the game's Keybindings page (Blizzard_Keybindings.xml): UIMenuButtonStretchTemplate's silver art
-- (SharedUIPanelTemplates.xml) in pieces without names, and its light while it waits for a key
local silver = "Interface\\Buttons\\UI-Silver-Button-Up"
local keyCorners = { -- piece, point, tex coords
    { "TopLeft", "TOPLEFT", 0, 0.09375, 0, 0.1875 },
    { "TopRight", "TOPRIGHT", 0.53125, 0.625, 0, 0.1875 },
    { "BottomLeft", "BOTTOMLEFT", 0, 0.09375, 0.625, 0.8125 },
    { "BottomRight", "BOTTOMRIGHT", 0.53125, 0.625, 0.625, 0.8125 },
}
local keyEdges = { -- piece, two anchors (point, relative piece, relative point), tex coords
    { "TopMiddle", "TOPLEFT", "TopLeft", "TOPRIGHT", "BOTTOMRIGHT", "TopRight", "BOTTOMLEFT", 0.09375, 0.53125, 0, 0.1875 },
    { "MiddleLeft", "TOPRIGHT", "TopLeft", "BOTTOMRIGHT", "BOTTOMLEFT", "BottomLeft", "TOPLEFT", 0, 0.09375, 0.1875, 0.625 },
    { "MiddleRight", "TOPRIGHT", "TopRight", "BOTTOMRIGHT", "BOTTOMLEFT", "BottomRight", "TOPLEFT", 0.53125, 0.625, 0.1875, 0.625 },
    { "BottomMiddle", "TOPLEFT", "BottomLeft", "TOPRIGHT", "BOTTOMRIGHT", "BottomRight", "BOTTOMLEFT", 0.09375, 0.53125, 0.625, 0.8125 },
    { "MiddleMiddle", "TOPLEFT", "TopLeft", "BOTTOMRIGHT", "BOTTOMRIGHT", "BottomRight", "TOPLEFT", 0.09375, 0.53125, 0.1875, 0.625 },
}

function build.KeyButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(160, 22)
    for _, corner in ipairs(keyCorners) do
        local piece = button:CreateTexture(nil, "BACKGROUND")
        piece:SetTexture(silver)
        piece:SetSize(12, 6)
        piece:SetPoint(corner[2])
        piece:SetTexCoord(corner[3], corner[4], corner[5], corner[6])
        button[corner[1]] = piece
    end
    for _, edge in ipairs(keyEdges) do
        local piece = button:CreateTexture(nil, "BACKGROUND")
        piece:SetTexture(silver)
        piece:SetPoint(edge[2], button[edge[3]], edge[4])
        piece:SetPoint(edge[5], button[edge[6]], edge[7])
        piece:SetTexCoord(edge[8], edge[9], edge[10], edge[11])
        button[edge[1]] = piece
    end
    local selected = button:CreateTexture(nil, "OVERLAY")
    selected:SetTexture("Interface\\Buttons\\UI-Silver-Button-Select")
    selected:SetBlendMode("ADD")
    selected:SetSize(160, 20)
    selected:SetPoint("CENTER", 0, -3)
    selected:Hide()
    button.SelectedHighlight = selected

    local text = button:CreateFontString()
    text:SetWidth(150)
    text:SetPoint("CENTER", 0, -1)
    text:SetMaxLines(1)
    button:SetFontString(text)
    button.Text = text
    button:SetNormalFontObject(GameFontHighlightSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
    button:SetDisabledFontObject(GameFontDisableSmall)
    button:SetHighlightTexture("Interface\\Buttons\\UI-Silver-Button-Highlight", "ADD")
    button:GetHighlightTexture():SetTexCoord(0, 1, 0.03, 0.7175)
    return Finish(button, lib.Internal.Mixins.KeyButton,
        { OnMouseDown = "OnMouseDown", OnMouseUp = "Lift", OnShow = "Lift", OnEnable = "Lift" })
end

-- The game's settings dropdown with an arrow on each side (DropdownWithSteppersTemplate, as
-- Metal2DropdownWithSteppersAndLabelTemplate builds it). The template's OnLoad needs its Dropdown child, which XML adds
-- before OnLoad and CreateFrame cannot, and its arrows' OnLoad needs their atlases, which XML gives as KeyValues; so the
-- frame is put together here from the same pieces with Blizzard's own mixins (Blizzard_SharedXML SharedUIPanelTemplates,
-- Blizzard_Menu MenuTemplates; the same on Retail, Mists and Titan)
local iconButtonScripts = { "OnShow", "OnMouseDown", "OnMouseUp", "OnEnter", "OnLeave", "OnEnable", "OnDisable" }

local function IconButton(parent, normalAtlas, disabledAtlas)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(26, 25)
    button.Background = button:CreateTexture(nil, "BACKGROUND")
    button.Background:SetPoint("CENTER")
    button.Icon = button:CreateTexture(nil, "OVERLAY")
    button.Icon:SetPoint("CENTER")
    Mixin(button, WowStyle2IconButtonMixin)
    button.normalAtlas, button.disabledAtlas = normalAtlas, disabledAtlas
    for _, script in ipairs(iconButtonScripts) do
        if button[script] then button:SetScript(script, button[script]) end
    end
    button:OnLoad()
    return button
end

function build.Select(parent)
    local select = CreateFrame("Frame", nil, parent)
    select:SetSize(250, 26)
    select.IncrementButton = IconButton(select, "common-dropdown-icon-next", "common-dropdown-icon-next-disabled")
    select.DecrementButton = IconButton(select, "common-dropdown-icon-back", "common-dropdown-icon-back-disabled")
    select.Dropdown = CreateFrame("DropdownButton", nil, select, "WowStyle2DropdownTemplate")
    select.Dropdown:SetSize(220, 26)
    select.Dropdown:SetPoint("CENTER")
    Mixin(select, DropdownWithSteppersMixin)
    select:OnLoad()
    return select
end

-- [[ Header, sub-heading, note ]] --

function build.HeaderRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontHighlightLarge", "LEFT")
    row.Text:SetPoint("BOTTOMLEFT", 6, 6)
    row.Text:SetPoint("RIGHT", -6, 0)
    return Finish(row, lib.Internal.Mixins.TextRow)
end

function build.SubHeadingRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontHighlight", "LEFT")
    row.Text:SetPoint("LEFT", 16, 0)
    row.Text:SetPoint("RIGHT", -16, 0)
    return Finish(row, lib.Internal.Mixins.TextRow)
end

function build.NoteRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontDisable", "LEFT", "TOP")
    row.Text:SetPoint("TOPLEFT", 16, -4)
    row.Text:SetPoint("BOTTOMRIGHT", -16, 0)
    return Finish(row, lib.Internal.Mixins.TextRow)
end

-- The row's light under the mouse
local function Hover(row, layer, subLevel)
    local hover = Color(row, layer or "BACKGROUND", 1, 1, 1, 0.05, subLevel)
    hover:SetAllPoints()
    hover:Hide()
    return hover
end

-- [[ An option ]] --

function build.OptionRow(parent)
    local row = Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = Hover(row)
    row.Label = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(true)
    row.Label:SetMaxLines(2)
    row.Label:SetPoint("LEFT", 16, 0)
    row.ReloadIcon = row:CreateTexture(nil, "ARTWORK")
    row.ReloadIcon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    row.ReloadIcon:SetSize(12, 12)
    row.ReloadIcon:SetPoint("LEFT", row.Label, "RIGHT", 6, 0)
    row.ReloadIcon:Hide()
    -- A changed option: a gold line along the row's left edge, as VS Code marks a modified setting
    -- (docs/work/2026-10-31-options-markers)
    row.ChangedBar = Color(row, "ARTWORK", 1, 0.82, 0, 1)
    row.ChangedBar:SetWidth(2)
    row.ChangedBar:SetPoint("TOPLEFT", 0, -4)
    row.ChangedBar:SetPoint("BOTTOMLEFT", 0, 4)
    row.ChangedBar:Hide()

    -- Sets a changed option back; shown while the mouse is on its row, in the margin before the name
    local reset = CreateFrame("Button", nil, row)
    reset:SetSize(12, 12)
    reset:SetPoint("RIGHT", row.Label, "LEFT", -2, 0)
    reset:SetNormalAtlas("common-icon-undo")
    reset:SetHighlightAtlas("common-icon-undo", "ADD")
    reset:Hide()
    row.Reset = reset
    -- The controls are placed by the row's geometry (RowMixins.lua) at the sizes of the game's Options window
    -- (docs/work/2026-11-02-options-widths)
    row.Toggle = build.CheckButton(row)
    row.Toggle:Hide()
    row.Range = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    row.Range:SetSize(lib.Internal.Geometry.SliderWidth, 20)
    row.Range:Hide()
    row.Select = build.Select(row)
    row.Select:Hide()
    row.Execute = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.Execute:SetSize(200, 22)
    row.Execute:Hide()
    -- A dropdown's button (a select's With): the same red button, narrow, with the » of the help pane's "How it works"
    -- strip (WindowLayout.lua); its option's name says what it does under the mouse (docs/work/2026-11-09-select-with-button)
    row.Go = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.Go:SetSize(32, 22)
    row.Go:SetText("\194\187")
    row.Go:Hide()
    row.Input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.Input:SetAutoFocus(false)
    row.Input:SetSize(240, 20)
    row.Input:Hide()
    -- Side by side, as the game's Keybindings page has them (Blizzard_Keybindings.xml)
    row.Key1 = build.KeyButton(row)
    row.Key1:Hide()
    row.Key2 = build.KeyButton(row)
    row.Key2:SetPoint("LEFT", row.Key1, "RIGHT")
    row.Key2:Hide()
    return Finish(row, lib.Internal.Mixins.OptionRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ A family heading or a group's All / None ]] --

function build.SubRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontHighlight", "LEFT")
    row.Text:SetPoint("LEFT", 16, 0)
    row.All = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.All:SetSize(70, 20)
    row.None = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.None:SetSize(70, 20)
    row.None:SetPoint("LEFT", row.All, "RIGHT", 6, 0)
    return Finish(row, lib.Internal.Mixins.SubRow, { OnLoad = "OnLoad" })
end

-- [[ A grid ]] --

function build.GridHeaderRow(parent)
    local row = Row("Frame", parent)
    return Finish(row, lib.Internal.Mixins.GridHeaderRow, { OnLoad = "OnLoad" })
end

function build.GridRow(parent)
    local row = Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = Hover(row)
    row.Label = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(false)
    row.Label:SetWidth(180)
    row.Label:SetPoint("LEFT", 16, 0)
    return Finish(row, lib.Internal.Mixins.GridRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ A tab's place ]] --

local function ArrowButton(parent, direction)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(22, 22)
    button:SetNormalTexture("Interface\\Buttons\\Arrow-" .. direction .. "-Up")
    button:SetPushedTexture("Interface\\Buttons\\Arrow-" .. direction .. "-Down")
    button:SetDisabledTexture("Interface\\Buttons\\Arrow-" .. direction .. "-Disabled")
    return button
end

function build.TabRow(parent)
    local row = Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = Hover(row)
    row.Position = Text(row, "ARTWORK", "GameFontDisable", "RIGHT")
    row.Position:SetWidth(20)
    row.Position:SetPoint("LEFT", 10, 0)
    row.Label = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(false)
    row.Label:SetPoint("LEFT", 70, 0)
    row.Source = Text(row, "ARTWORK", "GameFontDisableSmall", "LEFT")
    row.Source:SetPoint("LEFT", row.Label, "RIGHT", 8, 0)
    row.ShowCheck = build.CheckButton(row)
    row.ShowCheck:SetPoint("LEFT", lib.Internal.Geometry.TabCheckX, 0)
    row.Up = ArrowButton(row, "Up")
    row.Down = ArrowButton(row, "Down")
    row.Down:SetPoint("LEFT", row.Up, "RIGHT", 4, 0)
    return Finish(row, lib.Internal.Mixins.TabRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ The search results ]] --

-- A section's name above its rows, as the game's SettingsListSearchCategoryTemplate (Blizzard_SettingsList.xml, the same on
-- every client) draws it; never inherited, see docs/backlog.md
function build.SearchHeadingRow(parent)
    local row = Row("Button", parent)
    row.MouseoverOverlay = Color(row, "BACKGROUND", 0.1, 0.1, 0.1, 1)
    row.MouseoverOverlay:SetBlendMode("ADD")
    row.MouseoverOverlay:SetAllPoints()
    row.MouseoverOverlay:Hide()
    row.Title = Text(row, "ARTWORK", "GameFontNormalLarge", "LEFT", "TOP")
    row.Title:SetPoint("TOPLEFT", 16, -16)
    return Finish(row, lib.Internal.Mixins.SearchHeadingRow,
        { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

function build.LinkRow(parent)
    local row = Row("Button", parent)
    row.Text = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Text:SetWordWrap(false)
    row.Text:SetPoint("LEFT", 16, 0)
    row.Detail = Text(row, "ARTWORK", "GameFontDisableSmall", "LEFT")
    row.Detail:SetWordWrap(false)
    row.Detail:SetPoint("LEFT", row.Text, "RIGHT", 10, 0)
    row.Detail:SetPoint("RIGHT", -16, 0)
    local highlight = row:CreateTexture()
    highlight:SetColorTexture(1, 1, 1, 0.08)
    highlight:SetBlendMode("ADD") -- an XML HighlightTexture's own
    highlight:SetAllPoints()
    row:SetHighlightTexture(highlight)
    return Finish(row, lib.Internal.Mixins.LinkRow, { OnClick = "OnClick" })
end

-- [[ Cards ]] --

-- A card (docs/work/2026-11-02-overview-cards): a section's picture, or a game icon, on a dark area at the top, its name
-- and NEW, and a line on what it covers, on a dark fill inside a 1 px border that lights under the mouse. RowMixins.lua
-- places the name and the line, and cuts the picture to the area.
local cardEdges = { -- size (width or height), two anchors (point, x, y)
    { nil, 1, "TOPLEFT", 0, 0, "TOPRIGHT", 0, 0 },
    { nil, 1, "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", 0, 0 },
    { 1, nil, "TOPLEFT", 0, -1, "BOTTOMLEFT", 0, 1 },
    { 1, nil, "TOPRIGHT", 0, -1, "BOTTOMRIGHT", 0, 1 },
}

function build.Card(parent)
    local geometry = lib.Internal.Geometry
    local card = CreateFrame("Button", nil, parent)
    card.Fill = Color(card, "BACKGROUND", 0, 0, 0, 0.35)
    card.Fill:SetAllPoints()
    card.PictureArea = Color(card, "BORDER", 0, 0, 0, 0.5)
    card.PictureArea:SetHeight(geometry.CardPictureHeight)
    card.PictureArea:SetPoint("TOPLEFT", 1, -1)
    card.PictureArea:SetPoint("TOPRIGHT", -1, -1)
    card.Hover = Hover(card, "BORDER", 1)
    card.Picture = card:CreateTexture(nil, "ARTWORK")
    card.Picture:SetPoint("TOPLEFT", card.PictureArea)
    card.Picture:SetPoint("BOTTOMRIGHT", card.PictureArea)
    card.Icon = card:CreateTexture(nil, "ARTWORK")
    card.Icon:SetSize(48, 48)
    card.Icon:SetPoint("CENTER", card.PictureArea)
    card.Icon:Hide()
    card.Name = Text(card, "ARTWORK", "GameFontNormal", "LEFT")
    card.Name:SetWordWrap(false)
    card.Line = Text(card, "ARTWORK", "GameFontDisableSmall", "LEFT", "TOP")
    card.Line:SetPoint("TOPLEFT", card.Name, "BOTTOMLEFT", 0, -3)
    card.PictureLine = Color(card, "OVERLAY", unpack(geometry.CardBorderColor))
    card.PictureLine:SetHeight(1)
    card.PictureLine:SetPoint("TOPLEFT", card.PictureArea, "BOTTOMLEFT")
    card.PictureLine:SetPoint("TOPRIGHT", card.PictureArea, "BOTTOMRIGHT")
    card.Edges = {}
    for _, spec in ipairs(cardEdges) do
        local edge = Color(card, "OVERLAY", unpack(geometry.CardBorderColor))
        if spec[1] then edge:SetWidth(spec[1]) else edge:SetHeight(spec[2]) end
        edge:SetPoint(spec[3], spec[4], spec[5])
        edge:SetPoint(spec[6], spec[7], spec[8])
        tinsert(card.Edges, edge)
    end
    -- The navigation's NEW (WindowFrame.lua), at the right end of the name's line; its offsets are in its own .8 scale
    card.NewFeature = CreateFrame("Frame", nil, card, "NewFeatureLabelTemplate")
    card.NewFeature:SetScale(0.8)
    card.NewFeature:SetSize(1, 1)
    card.NewFeature:SetPoint("RIGHT", card.PictureArea, "BOTTOMRIGHT", -11.25, -17.5)
    card.NewFeature:Hide()
    return Finish(card, lib.Internal.Mixins.Card, { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- A row of cards, made in OnLoad (RowMixins.lua) as the grid row makes its check boxes
function build.CardRow(parent)
    local row = Row("Frame", parent)
    return Finish(row, lib.Internal.Mixins.CardRow, { OnLoad = "OnLoad" })
end