--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The window's layout (WindowMixin.lua is the window's core): its width, which follows the help pane, and its scale on
-- a small screen; the game's inner frame drawn in slices; where every part of the window stands (Layout); the
-- navigation's and the page's lists and the navigation's scroll bar; measuring text; the help pane's collapse; resize
-- and drag. Its state on the window: PaneCollapsed, NavScrollShown, Filling, LayoutPending, InnerSlices and Measure.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("WindowLayout", 0)
if not sub then return end

-- The navigation is as wide as the game's category list, so its header bars (199 px) end at the divider; the help pane
-- is lib.Geometry.HelpWidth wide (Kinds.lua), and collapsed it leaves a strip
local navWidth, stripWidth = 199, 30
-- The game's Options window is 920 wide (Blizzard_SettingsPanel.xml); ours adds the help pane, or its strip, to the right
-- of that and resizes in height only, down to lib.Geometry.MinHeight (docs/work/2026-11-02-options-widths)
local gameWidth = 920
local dividerWidth = 630 -- Options_HorizontalDivider at its own size, measured with the kit's Get-Atlas.ps1
-- The page as the game's settings list lays it out (Blizzard_SettingsPanel.xml, Blizzard_SettingsList.lua): its
-- container from 16 after the navigation to 22 before the window's edge, here 4 before the help pane, and the list in it
-- from 15 left of the container to 20 before its right, its rows padded 25 on the left, so a row is 635 wide
local pageInsets = { Left = 16 - 15, Right = 4 + 20, Pad = 25 }

function lib.WindowWidth(collapsed)
    return gameWidth + (collapsed and stripWidth or lib.Geometry.HelpWidth)
end

-- [[ The window ]] --
-- Every file of the window adds its methods to this one table (WindowMixin.lua)
lib.Mixins.Window = lib.Mixins.Window or {}
local WindowMixin = lib.Mixins.Window

-- The page's list draws the element kinds (lib.Kinds, Kinds.lua); the navigation and the help pane (WindowHelp.lua)
-- draw their own, in the same shape: the builder of each row (WindowFrame.lua) and its height. All three are pooled by
-- lib.InitList (Kinds.lua).
local navKinds = {
    NavHeader = { Build = "NavHeader", Height = 30 },
    NavButton = { Build = "NavButton", Height = 20 },
    NavSpacer = { Build = "NavSpacer", Height = 18 },
}
-- The navigation's leftPad and spacing as the game's category list uses them (Blizzard_CategoryList.lua): its scroll box
-- reaches 50 px left of the list, so a NEW label hanging left of a section is not clipped, and the rows move back by as
-- much.
local navLeftPad = 50

-- [[ The inner frame ]] --
-- The game's own inner frame (Options_InnerFrame, 886 x 618 and the same on every client), which
-- Blizzard_SettingsPanel.xml draws at its size in a window of fixed size. Ours is wider for the help pane and resizable,
-- so it is drawn in slices: the shaded edges and the 2 px divider keep their size and only the flat parts stretch, and
-- the divider is drawn at the end of the navigation and again at the start of the help pane. The cuts were measured on
-- the atlas with the kit's Get-Atlas.ps1: x from, x to, and y from, y to, in its pixels.
local innerColumns = { Left = { 0, 30 }, Nav = { 30, 199 }, Divider = { 199, 201 }, Flat = { 201, 856 }, Right = { 856, 886 } }
local innerRows = { Top = { 0, 90 }, Middle = { 90, 440 }, Bottom = { 440, 618 } }
local innerSlices = { -- left to right: a slice's piece of the atlas
    { Key = "Left", Atlas = "Left" }, { Key = "Nav", Atlas = "Nav" }, { Key = "Divider", Atlas = "Divider" },
    { Key = "Page", Atlas = "Flat" }, { Key = "HelpDivider", Atlas = "Divider" }, { Key = "Help", Atlas = "Flat" },
    { Key = "Right", Atlas = "Right" },
}

function WindowMixin:CreateInnerFrame()
    local info = C_Texture.GetAtlasInfo("Options_InnerFrame")
    if not info then return end
    local function U(x) return info.leftTexCoord + (info.rightTexCoord - info.leftTexCoord) * x / info.width end
    local function V(y) return info.topTexCoord + (info.bottomTexCoord - info.topTexCoord) * y / info.height end
    self.InnerSlices = {}
    for _, column in ipairs(innerSlices) do
        local x = innerColumns[column.Atlas]
        for row, y in next, innerRows do
            -- Under the window's own text (the page title, the labels): the game draws its text in child frames above the art
            local slice = self:CreateTexture(nil, "BACKGROUND", nil, 1)
            slice:SetTexture(info.file or info.filename)
            slice:SetTexCoord(U(x[1]), U(x[2]), V(y[1]), V(y[2]))
            self.InnerSlices[column.Key .. row] = slice
        end
    end
end

-- Each slice spans an edge and offset of the inner frame to another, across and down
local innerRowAnchors = { Top = { "TOP", 0, "TOP", -90 }, Middle = { "TOP", -90, "BOTTOM", 178 }, Bottom = { "BOTTOM", 178, "BOTTOM", 0 } }

function WindowMixin:LayoutInnerFrame(navEnd, right)
    if not self.InnerSlices then return end
    -- The frame starts 1 px left of the body: the divider's 2 px straddle the navigation's end and the help pane's start
    local divider, help = navEnd, right + 2
    local columns = {
        Left = { "LEFT", 0, "LEFT", 30 },
        Nav = { "LEFT", 30, "LEFT", divider },
        Divider = { "LEFT", divider, "LEFT", divider + 2 },
        Page = { "LEFT", divider + 2, "RIGHT", -help },
        HelpDivider = { "RIGHT", -help, "RIGHT", -help + 2 },
        Help = { "RIGHT", -help + 2, "RIGHT", -30 },
        Right = { "RIGHT", -30, "RIGHT", 0 },
    }
    local frame = self.InnerFrame
    for key, x in next, columns do
        for row, y in next, innerRowAnchors do
            local slice = self.InnerSlices[key .. row]
            slice:ClearAllPoints()
            slice:SetPoint("TOPLEFT", frame, y[1] .. x[1], x[2], y[2])
            slice:SetPoint("BOTTOMRIGHT", frame, y[3] .. x[3], x[4], y[4])
            slice:SetShown(key ~= "Help" or -help + 2 < -30) -- a collapsed pane leaves no room between its divider and the edge
        end
    end
end

-- Drag, the inner frame, the text the window measures with, the navigation's and the page's lists, the help pane's
-- chevrons and resize, set up as the window is built (OnLoad, WindowMixin.lua)
function WindowMixin:LoadLayout()
    self:RegisterForDrag("LeftButton")
    self:CreateInnerFrame()

    self.Measure = self:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    self.Measure:Hide()
    self.Measure:SetJustifyH("LEFT")

    local navBar = lib.InitList(self, self.NavScrollBox, self.NavScrollBar, navKinds, navLeftPad, 2)
    self.NavScrollShown = self.NavScrollBar:IsShown()
    navBar:RegisterCallback(ManagedScrollBarVisibilityBehaviorMixin.Event.OnVisibilityChanged, function(_, shown) self:OnNavScrollBarShown(shown) end, self)
    lib.InitList(self, self.PageScrollBox, self.PageScrollBar, lib.Kinds, pageInsets.Pad)

    self.CollapseButton:SetScript("OnClick", function() self:SetPaneCollapsed(true) end)
    self.ExpandButton:SetScript("OnClick", function() self:SetPaneCollapsed(false) end)
    -- « hides the pane and » brings it back, the way the window's right edge moves; gold, white under the mouse, as the
    -- window's other links
    self.CollapseButton.Arrow:SetText("\194\171")
    self.ExpandButton.Arrow:SetText("\194\187")
    self.ExpandButton.Label:SetRotation(-math.pi / 2) -- reads downwards
    for _, button in ipairs({ self.CollapseButton, self.ExpandButton }) do
        button:SetScript("OnEnter", function()
            button.Arrow:SetFontObject("GameFontHighlightLarge")
            if button.Label then button.Label:SetFontObject("GameFontHighlightSmall") end
        end)
        button:SetScript("OnLeave", function()
            button.Arrow:SetFontObject("GameFontNormalLarge")
            if button.Label then button.Label:SetFontObject("GameFontDisableSmall") end
        end)
    end
    self.ResizeButton:SetScript("OnMouseDown", function() self:StartSizing("BOTTOM") end) -- in height only
    self.ResizeButton:SetScript("OnMouseUp", function()
        self:StopMovingOrSizing()
        lib.SetShared("Size", { self:GetWidth(), self:GetHeight() })
        self:SavePoint() -- sizing re-anchors the window
        self:ReloadSection()
        self:UpdateShowMe() -- a secure Show me button placed over ours follows it
    end)
end

-- The game's width plus the help pane or its strip; a window wider than the screen (a large UI scale) is scaled down to
-- fit, and one taller than it (a height saved on a larger screen) comes back inside it. keepLeft: the window grows and
-- shrinks to the right, its top left staying where it is, and that place is saved.
function WindowMixin:ApplyWidth(keepLeft)
    local minHeight = lib.Geometry.MinHeight
    local width = lib.WindowWidth(self.PaneCollapsed)
    local screen = UIParent:GetWidth()
    local scale = screen > 0 and math.min(1, (screen - 40) / width) or 1
    local left, top = self:GetLeft(), self:GetTop()
    local moves = keepLeft and left and top and (math.abs(self:GetScale() - scale) > 0.001 or math.abs(self:GetWidth() - width) > 0.5)
    if moves then
        -- The edges in the window's own units, which its scale sets
        local ratio = self:GetScale() / scale
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * ratio, top * ratio)
    end
    self:SetScale(scale)
    self:SetWidth(width)
    local maxHeight = math.max(minHeight, UIParent:GetHeight() / scale)
    if self:GetHeight() > maxHeight then self:SetHeight(maxHeight) end
    if self.SetResizeBounds then
        self:SetResizeBounds(width, minHeight, width, maxHeight)
    else
        self:SetMinResize(width, minHeight)
        self:SetMaxResize(width, maxHeight)
    end
    if moves then self:SavePoint() end
end

function WindowMixin:MeasureText(text, font, width)
    self.Measure:SetFontObject(font)
    self.Measure:SetWidth(math.max(width, 50))
    self.Measure:SetText(text or "")
    return math.ceil(self.Measure:GetStringHeight())
end

-- The body: under the tabs and above the bottom row, where the game's window has its category list and its settings
-- (Blizzard_SettingsPanel.xml: the list at 18, -76, the bottom buttons at 16)
local bodyInsets = { Left = 18, Top = -76, Right = -18, Bottom = 46 }
local navBarSpace = 16 -- what the game's list keeps for its scroll bar; the divider and the page move right by it while it shows
-- The list's scroll bar, 8 wide, from the list's end: halfway between the edge of the header art (197, measured on the
-- atlas) and the divider (214 while the bar shows)
local navBarX = 2.5

-- Where the navigation ends and its divider stands: right after the list, where the game's window has it, or past the
-- list's scroll bar while not all of it fits
function WindowMixin:NavEnd()
    return self.NavScrollShown and navWidth + navBarSpace or navWidth
end

function WindowMixin:OnNavScrollBarShown(shown)
    if self.NavScrollShown == shown then return end
    self.NavScrollShown = shown
    -- Showing a section or a search fills the page after the navigation, already at the new width: it lays out once
    -- it is done (EndFill), instead of building the page twice
    if self.Filling then
        self.LayoutPending = true
        return
    end
    self:Layout()
    self:ReloadSection() -- the page is wider or narrower, so its notes are measured again
end

function WindowMixin:EndFill()
    self.Filling = nil
    if self.LayoutPending then
        self.LayoutPending = nil
        self:Layout()
    end
end

-- A row's width: the page's scroll box (pageInsets) without its rows' left padding
function WindowMixin:PageWidth()
    return self:GetWidth() - (bodyInsets.Left - bodyInsets.Right) - self:NavEnd()
        - (self.PaneCollapsed and stripWidth or lib.Geometry.HelpWidth) - pageInsets.Left - pageInsets.Right - pageInsets.Pad
end

function WindowMixin:Layout()
    local body = self.Body
    local right = self.PaneCollapsed and stripWidth or lib.Geometry.HelpWidth
    local navEnd = self:NavEnd()

    body:ClearAllPoints()
    body:SetPoint("TOPLEFT", self, "TOPLEFT", bodyInsets.Left, bodyInsets.Top)
    body:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", bodyInsets.Right, bodyInsets.Bottom)
    self:LayoutInnerFrame(navEnd, right)

    -- The search box sits in the tab row at the right, as the game's does
    self.SearchBox:ClearAllPoints()
    self.SearchBox:SetPoint("BOTTOMRIGHT", body, "TOPRIGHT", 0, 20)

    -- The scroll bars sit as the game's lists place theirs (Blizzard_CategoryList.xml, Blizzard_SettingsList.xml), each
    -- just inside the divider or edge after its list, apart from the navigation's, which stands halfway to its divider
    self.NavScrollBox:ClearAllPoints()
    self.NavScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", -navLeftPad, -4)
    self.NavScrollBox:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", -navLeftPad, 4)
    self.NavScrollBox:SetWidth(navLeftPad + navWidth)
    self.NavScrollBar:ClearAllPoints()
    self.NavScrollBar:SetPoint("TOPLEFT", self.NavScrollBox, "TOPRIGHT", navBarX, 2)
    self.NavScrollBar:SetPoint("BOTTOMLEFT", self.NavScrollBox, "BOTTOMRIGHT", navBarX, 7)

    self.HelpBackground:ClearAllPoints()
    self.HelpBackground:SetPoint("TOPRIGHT", body, "TOPRIGHT")
    self.HelpBackground:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT")
    self.HelpBackground:SetWidth(right)
    -- « stands at the pane's left, on the spot where the strip's » comes (15 in, as the strip is 30 wide), so a second
    -- click finds it under the mouse; "How it works" follows it, part of the button
    self.CollapseButton:ClearAllPoints()
    self.CollapseButton:SetPoint("TOPLEFT", self.HelpBackground, "TOPLEFT", 4, -3)
    self.ExpandButton:ClearAllPoints()
    self.ExpandButton:SetPoint("TOP", self.HelpBackground, "TOP", 0, -3)
    self.HelpScrollBox:ClearAllPoints()
    self.HelpScrollBox:SetPoint("TOPLEFT", self.HelpBackground, "TOPLEFT", 12, -32)
    self.HelpScrollBox:SetPoint("BOTTOMRIGHT", self.HelpBackground, "BOTTOMRIGHT", -22, 44)
    self.HelpScrollBar:ClearAllPoints()
    self.HelpScrollBar:SetPoint("TOPLEFT", self.HelpScrollBox, "TOPRIGHT", 0, -4)
    self.HelpScrollBar:SetPoint("BOTTOMLEFT", self.HelpScrollBox, "BOTTOMRIGHT", -1, 7)
    self.ShowMeButton:ClearAllPoints()
    self.ShowMeButton:SetPoint("BOTTOMLEFT", self.HelpBackground, "BOTTOMLEFT", 14, 12)
    self.ShowMeNote:ClearAllPoints()
    self.ShowMeNote:SetPoint("LEFT", self.ShowMeButton, "RIGHT", 8, 0)
    self.ShowMeNote:SetPoint("RIGHT", self.HelpBackground, "RIGHT", -10, 0)

    for _, region in ipairs({ self.CollapseButton, self.HelpScrollBox }) do
        region:SetShown(not self.PaneCollapsed)
    end
    -- The help's scroll bar hides with the pane, and comes back only when the help is longer than the pane
    if self.PaneCollapsed then
        self.HelpScrollBar:Hide()
    elseif self.HelpBar then
        self.HelpBar:EvaluateVisibility(true)
    end
    self.ExpandButton:SetShown(self.PaneCollapsed)
    self:UpdateShowMe()

    -- The page's header as the game's settings list draws it (Blizzard_SettingsList.xml), on its container (pageInsets):
    -- the title 7 into it, Defaults 36 before its right, and the divider at its own size, centred under both
    local pageLeft = navEnd + 16
    local pageRight = self:GetWidth() - (bodyInsets.Left - bodyInsets.Right) - right - 4
    self.PageTitle:ClearAllPoints()
    self.PageTitle:SetPoint("TOPLEFT", body, "TOPLEFT", pageLeft + 7, -22)
    self.PageTitle:SetPoint("RIGHT", self.DefaultsButton, "LEFT", -6, 0)
    self.DefaultsButton:ClearAllPoints()
    self.DefaultsButton:SetPoint("TOPRIGHT", self.HelpBackground, "TOPLEFT", -4 - 36, -16)
    self.CancelButton:ClearAllPoints()
    self.CancelButton:SetPoint("RIGHT", self.DefaultsButton, "LEFT", -6, 0)
    self.Divider:ClearAllPoints()
    self.Divider:SetWidth(math.min(dividerWidth, pageRight - pageLeft))
    self.Divider:SetPoint("TOP", body, "TOPLEFT", (pageLeft + pageRight) / 2, -50)
    self.PageScrollBox:ClearAllPoints()
    self.PageScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", navEnd + pageInsets.Left, -58)
    self.PageScrollBox:SetPoint("BOTTOMRIGHT", self.HelpBackground, "BOTTOMLEFT", -pageInsets.Right, 0)
    self.PageScrollBar:ClearAllPoints()
    self.PageScrollBar:SetPoint("TOPLEFT", self.PageScrollBox, "TOPRIGHT", 0, -4)
    self.PageScrollBar:SetPoint("BOTTOMLEFT", self.PageScrollBox, "BOTTOMRIGHT", -1, 7)

    -- The bottom row: the reload bar, the search breadth and scope check boxes, and Close
    self.SearchAllLabel:ClearAllPoints()
    self.SearchAllLabel:SetPoint("RIGHT", self.CloseButton, "LEFT", -16, 0)
    self.SearchAll:ClearAllPoints()
    self.SearchAll:SetPoint("RIGHT", self.SearchAllLabel, "LEFT", -2, 0)
    self.SearchBroad:ClearAllPoints()
    self.SearchBroad:SetPoint("RIGHT", self.SearchBroadLabel, "LEFT", -2, 0)
    self.ReloadBackground:ClearAllPoints()
    self.ReloadBackground:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -6)
    self:UpdateSearchAll()
    self.ReloadText:ClearAllPoints()
    self.ReloadText:SetPoint("LEFT", self.ReloadBackground, "LEFT", 12, 0)
    self.ReloadButton:ClearAllPoints()
    self.ReloadButton:SetPoint("LEFT", self.ReloadText, "RIGHT", 12, 0)
end

function WindowMixin:SetPaneCollapsed(collapsed)
    self.PaneCollapsed = collapsed
    lib.SetShared("PaneCollapsed", collapsed)
    self:ApplyWidth(true) -- "How it works" widens the window to the right
    self:Layout()
    self:ReloadSection()
end

function WindowMixin:OnSizeChanged()
    if self:IsShown() then self:UpdateShowMe() end -- also when the screen clamps the window
end

function WindowMixin:OnDragStart()
    self:StartMoving()
end

function WindowMixin:OnDragStop()
    self:StopMovingOrSizing()
    self:SavePoint()
    self:UpdateShowMe() -- a secure Show me button placed over ours follows it
end

function WindowMixin:SavePoint()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    lib.SetShared("Point", { point, relativePoint, x, y })
end