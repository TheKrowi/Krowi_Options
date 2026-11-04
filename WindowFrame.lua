--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The window and the rows of its navigation and help pane, built in Lua as Window.xml declared them up to 1.0, for the
-- reason RowFrames.lua gives (docs/work/2026-11-04-krowi-options-library), with RowFrames.lua's pieces.

local sub, lib = KROWI_LIBMAN:NewSubmodule("WindowFrame", 0)
if not sub then return end

-- RowFrames.lua's pieces, looked up on each call: a newer copy's RowFrames.lua replaces them on lib.Build even when this
-- file stays the older copy's
local build = lib.Build
local function Text(...) return build.Text(...) end
local function Color(...) return build.Color(...) end
local function Finish(...) return build.Finish(...) end
local function Row(...) return build.Row(...) end

-- [[ Navigation ]] --
-- The navigation draws as the game's own Options window does (Blizzard_CategoryList.xml), from Blizzard's art only:
-- Blizzard's list templates run code that would taint its window (docs/work/2026-10-30-options-settings-look)

function build.NavButton(parent)
    local button = Row("Button", parent, 20)
    button.Texture = button:CreateTexture(nil, "BACKGROUND")
    button.Texture:SetPoint("CENTER")
    button.Texture:Hide()
    button.Label = Text(button, "ARTWORK", "GameFontNormal", "LEFT")
    button.Label:SetWordWrap(false)
    button.Label:SetPoint("TOPLEFT", 36, 1)
    button.Label:SetPoint("BOTTOMRIGHT", -6, 1)
    button.NewFeature = CreateFrame("Frame", nil, button, "NewFeatureLabelTemplate")
    button.NewFeature:SetScale(0.8)
    button.NewFeature:SetSize(1, 1)
    button.NewFeature:SetPoint("BOTTOMRIGHT", button.Label, "LEFT", -4, -10)
    button.NewFeature:Hide()
    return Finish(button, lib.Mixins.NavButton, { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

function build.NavHeader(parent)
    local header = Row("Frame", parent, 30)
    header.Background = header:CreateTexture(nil, "ARTWORK")
    header.Background:SetPoint("TOPLEFT")
    header.Label = Text(header, "OVERLAY", "GameFontHighlightMedium", "LEFT")
    header.Label:SetPoint("LEFT", 20, -1)
    return Finish(header, lib.Mixins.NavHeader)
end

function build.NavSpacer(parent)
    return Row("Frame", parent, 18)
end

-- [[ Help pane blocks ]] --

function build.HelpText(parent)
    local block = Row("Frame", parent, 20)
    block.Text = Text(block, "ARTWORK", "GameFontHighlight", "LEFT", "TOP")
    block.Text:SetPoint("TOPLEFT", 4, -2)
    block.Text:SetPoint("BOTTOMRIGHT", -4, 0)
    return Finish(block, lib.Mixins.HelpText)
end

function build.HelpPicture(parent)
    local block = Row("Button", parent, 100)
    block.Picture = block:CreateTexture(nil, "ARTWORK")
    block.Picture:SetPoint("TOPLEFT", 4, -4)
    block.Highlight = Color(block, "HIGHLIGHT", 1, 1, 1, 0.12)
    block.Highlight:SetBlendMode("ADD")
    block.Highlight:SetPoint("TOPLEFT", block.Picture)
    block.Highlight:SetPoint("BOTTOMRIGHT", block.Picture)
    return Finish(block, lib.Mixins.HelpPicture, { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ The window ]] --

local function PanelButton(parent, width, hidden)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonNoTooltipTemplate")
    button:SetSize(width, 22)
    if hidden then button:Hide() end
    return button
end

-- The help pane's chevrons; WindowMixin.lua sets their text and the pane's name
local function PaneButton(parent, width, arrowPoint, arrowY)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 22)
    button.Arrow = Text(button, "ARTWORK", "GameFontNormalLarge")
    button.Arrow:SetPoint(arrowPoint, 0, arrowY)
    return button
end

-- The game's own Options frame (SettingsFrameTemplate: each client's border, title strip and background); Blizzard's
-- window is laid out in Blizzard_SettingsPanel.xml, which the anchors in WindowMixin.lua's Layout follow. Hidden before
-- its children are made, so the search box does not take the keyboard.
function build.Window()
    local frame = CreateFrame("Frame", "Krowi_OptionsWindow", UIParent, "SettingsFrameTemplate")
    frame:Hide()
    -- The width follows the help pane (WindowMixin.lua, ApplyWidth): the game's 920 plus the pane's 380
    frame:SetSize(1300, 720)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)

    frame.PageTitle = Text(frame, "ARTWORK", "GameFontHighlightHuge", "LEFT")
    frame.PageTitle:SetWordWrap(false)
    frame.ChangedText = Text(frame, "ARTWORK", "GameFontDisableSmall", "RIGHT")
    frame.ReloadText = Text(frame, "ARTWORK", "GameFontHighlight", "LEFT")
    frame.ShowMeNote = Text(frame, "ARTWORK", "GameFontDisableSmall", "LEFT", "TOP")
    frame.SearchAllLabel = Text(frame, "ARTWORK", "GameFontNormalSmall", "LEFT")
    frame.SearchAllLabel:Hide()
    frame.SearchBroadLabel = Text(frame, "ARTWORK", "GameFontNormalSmall", "LEFT")
    frame.Divider = frame:CreateTexture(nil, "ARTWORK")
    frame.Divider:SetAtlas("Options_HorizontalDivider", true)
    -- Draws nothing: the help pane's place, which the page and the pane's own frames anchor to
    frame.HelpBackground = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    frame.ReloadBackground = Color(frame, "BACKGROUND", 1, 0.82, 0, 0.08, 2)
    frame.ReloadBackground:Hide()

    frame.Body = CreateFrame("Frame", nil, frame)
    -- Where the game's window draws its inner frame (Blizzard_SettingsPanel.xml); WindowMixin.lua draws it in slices
    frame.InnerFrame = CreateFrame("Frame", nil, frame)
    frame.InnerFrame:SetPoint("TOPLEFT", 17, -64)
    frame.InnerFrame:SetPoint("BOTTOMRIGHT", -17, 42)
    frame.SearchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    frame.SearchBox:SetAutoFocus(false)
    frame.SearchBox:SetMaxLetters(60)
    frame.SearchBox:SetSize(350, 22)
    frame.SearchAll = build.CheckButton(frame)
    frame.SearchAll:Hide()
    frame.SearchBroad = build.CheckButton(frame)
    -- The game's window scrolls with the thin MinimalScrollBar (Blizzard_CategoryList.xml, Blizzard_SettingsList.xml)
    for _, list in ipairs({ "Nav", "Page", "Help" }) do
        frame[list .. "ScrollBox"] = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
        frame[list .. "ScrollBar"] = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    end
    -- The help pane hides behind a gold chevron and comes back from a strip reading "How it works" down its length, as in
    -- the mockup (docs/work/2026-10-25-options-revamp/mockup)
    frame.CollapseButton = PaneButton(frame, 22, "CENTER", 1)
    -- The pane's name after the chevron; WindowMixin.lua's SetKicker widens the button's hit rect over it
    frame.CollapseButton.Label = Text(frame.CollapseButton, "ARTWORK", "GameFontDisableSmall", "LEFT")
    frame.CollapseButton.Label:SetPoint("LEFT", frame.CollapseButton, "RIGHT", 2, 0)
    frame.ExpandButton = PaneButton(frame, 26, "TOP", -2)
    frame.ExpandButton.Label = Text(frame.ExpandButton, "ARTWORK", "GameFontDisableSmall")
    frame.ExpandButton:Hide()
    frame.ShowMeButton = PanelButton(frame, 120, true)
    frame.DefaultsButton = PanelButton(frame, 96)
    frame.CancelButton = PanelButton(frame, 80, true)
    frame.ReloadButton = PanelButton(frame, 110, true)
    frame.CloseButton = PanelButton(frame, 96)
    frame.CloseButton:SetPoint("BOTTOMRIGHT", -26, 16)

    local lightbox = CreateFrame("Button", nil, frame)
    lightbox:SetFrameStrata("FULLSCREEN")
    lightbox:Hide()
    lightbox.Scrim = Color(lightbox, "BACKGROUND", 0, 0, 0, 0.75)
    lightbox.Scrim:SetAllPoints()
    lightbox.Picture = lightbox:CreateTexture(nil, "ARTWORK")
    frame.Lightbox = lightbox

    local resize = CreateFrame("Button", nil, frame)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT", -4, 4)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight", "ADD")
    frame.ResizeButton = resize

    return Finish(frame, lib.Mixins.Window, { OnLoad = "OnLoad", OnShow = "OnShow", OnHide = "OnHide", OnEvent = "OnEvent",
        OnSizeChanged = "OnSizeChanged", OnDragStart = "OnDragStart", OnDragStop = "OnDragStop" })
end