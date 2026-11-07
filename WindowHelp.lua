--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The window's help pane (WindowMixin.lua is the window's core): the open section's help or the search's, with pictures
-- that enlarge in the lightbox; the description of the option under the mouse, or the tooltip with it while the pane is
-- collapsed; and Show me, with the secure button a feature may lay over it. Its state on the window: Help, HoverOption,
-- SecureHelp, HelpBar, HoverRow, HoverRowOption, HoverControlX, HoverChanged and TooltipShown. WindowFrame.lua builds
-- the pane's rows.

-- A standalone install loaded before any Krowi addon has no KROWI_LIBMAN and nothing to serve (Krowi_Options.lua)
if not KROWI_LIBMAN then return end
local sub, lib = KROWI_LIBMAN:NewSubmodule("WindowHelp", 0)
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

-- [[ Help pane blocks ]] --
lib.Internal.Mixins.HelpText = lib.Internal.Mixins.HelpText or {}
local HelpTextMixin = lib.Internal.Mixins.HelpText

function HelpTextMixin:Init(element)
    self.Text:SetFontObject(element.Font)
    self.Text:SetText(element.Text)
end

-- A picture enlarges on click (the window's lightbox); the magnifier cursor says so
lib.Internal.Mixins.HelpPicture = lib.Internal.Mixins.HelpPicture or {}
local HelpPictureMixin = lib.Internal.Mixins.HelpPicture

function HelpPictureMixin:Init(element, window)
    self.Element, self.Window = element, window
    self.Picture:SetTexture(element.Picture)
    self.Picture:SetSize(element.DrawWidth, element.DrawHeight)
    if element.TexCoords then self.Picture:SetTexCoord(unpack(element.TexCoords)) else self.Picture:SetTexCoord(0, 1, 0, 1) end
end

function HelpPictureMixin:OnClick()
    self.Window:ShowPicture(self.Element)
end

function HelpPictureMixin:OnEnter()
    SetCursor("INSPECT_CURSOR")
end

function HelpPictureMixin:OnLeave()
    ResetCursor()
end

-- [[ The window ]] --
-- Every file of the window adds its methods to this one table (WindowMixin.lua)
lib.Internal.Mixins.Window = lib.Internal.Mixins.Window or {}
local WindowMixin = lib.Internal.Mixins.Window

-- The pane is lib.Internal.Geometry.HelpWidth wide (Kinds.lua), as the window lays it out (WindowLayout.lua); its text
-- and pictures are drawn this wide inside it
local function HelpInnerWidth()
    return lib.Internal.Geometry.HelpWidth - 52
end

-- The help pane's list draws its own kinds, in the shape of lib.Internal.Kinds (Kinds.lua): the builder of each row
-- (WindowFrame.lua) and its height. lib.Internal.InitList (Kinds.lua) pools them.
local helpKinds = {
    HelpText = { Build = "HelpText", Height = function(window, element)
        return window:MeasureText(element.Text, element.Font, HelpInnerWidth()) + (element.Gap or 6)
    end },
    HelpPicture = { Build = "HelpPicture", Height = function(_, element) return element.DrawHeight + 10 end },
}

-- The pane's list, the lightbox and Show me, set up as the window is built (OnLoad, WindowMixin.lua)
function WindowMixin:LoadHelp()
    self.HelpBar = lib.Internal.InitList(self, self.HelpScrollBox, self.HelpScrollBar, helpKinds)
    -- The help is filled while the pane is collapsed too, and its scroll bar would then show on the strip
    self.HelpBar:RegisterCallback(ManagedScrollBarVisibilityBehaviorMixin.Event.OnVisibilityChanged, function(_, shown)
        if shown and self.PaneCollapsed then self.HelpScrollBar:Hide() end
    end, self)

    -- The lightbox dims the screen above everything of the window (and a secure Show me button laid over it); a click
    -- closes it, and the consumer's Escape handling can close it like a window (OnCreated gets frame.Lightbox)
    self.Lightbox:SetAllPoints(UIParent)
    self.Lightbox:SetScript("OnClick", function(lightbox) lightbox:Hide() end)

    -- Show me closes the window first, then shows the feature (the help track's decision, plan-help.md). The window stays
    -- while help.CanShowMe() is false (the data still loading), and comes back when ShowMe returns false (its scene had
    -- nothing to open, such as no tab shown).
    self.ShowMeButton:SetScript("OnClick", function()
        local help = self.Help
        if InCombatLockdown() or not (help and help.ShowMe) then return end
        if help.CanShowMe and not Ask(false, help.CanShowMe) then return end
        self:Hide()
        if Ask(false, help.ShowMe) == false then self:Show() end -- also when ShowMe errored: the window comes back
    end)
end

-- [[ The help pane, or the tooltip while the pane is collapsed ]] --
local function TextBlock(text, font, gap)
    return { Kind = "HelpText", Text = text, Font = font, Gap = gap }
end

-- A help picture at its own size, smaller only where the screen is
function WindowMixin:ShowPicture(element)
    local lightbox = self.Lightbox
    local scale = math.min(1, (UIParent:GetWidth() - 80) / element.Width, (UIParent:GetHeight() - 80) / element.Height)
    lightbox.Picture:SetTexture(element.Picture)
    if element.TexCoords then lightbox.Picture:SetTexCoord(unpack(element.TexCoords)) else lightbox.Picture:SetTexCoord(0, 1, 0, 1) end
    scale = scale / self:GetScale() -- the lightbox is the window's: a window scaled down to fit leaves the picture its size
    lightbox.Picture:SetSize(element.Width * scale, element.Height * scale)
    lightbox.Picture:ClearAllPoints()
    lightbox.Picture:SetPoint("CENTER", UIParent, "CENTER")
    lightbox:Show()
end

function WindowMixin:FillHelp(blocks)
    self.HelpScrollBox:SetDataProvider(CreateDataProvider(blocks), ScrollBoxConstants.DiscardScrollPosition)
end

-- The open pane's name after «: a click on it closes the pane too, as the strip's name opens it
function WindowMixin:SetKicker(text)
    local button = self.CollapseButton
    button.Label:SetText(text)
    button:SetHitRectInsets(0, -(button.Label:GetStringWidth() + 2), 0, 0)
end

function WindowMixin:ShowSectionHelp()
    self.HoverOption = nil
    local ok, help = Protected(self.Config.GetHelp, self.SectionId)
    if not ok then help = nil end -- the section's help errored: its title alone
    self.Help = help
    self:SetKicker(self.Strings.HowItWorks)
    local blocks = {}
    local title = help and help.Title or (self.SectionId == "overview" and self.Strings.Overview or Ask(self.SectionId, self.Config.SectionName, self.SectionId))
    blocks[#blocks + 1] = TextBlock(title, "GameFontNormalLarge", 10)
    local innerWidth = HelpInnerWidth()
    for _, block in ipairs(help and help.Blocks or {}) do
        if block.Picture then
            local width = math.min(block.Width or innerWidth, innerWidth)
            local height = (block.Height or width) * width / (block.Width or width)
            blocks[#blocks + 1] = { Kind = "HelpPicture", Picture = block.Picture, DrawWidth = width, DrawHeight = height, TexCoords = block.TexCoords,
                Width = block.Width or width, Height = block.Height or height }
        elseif block.Heading then
            blocks[#blocks + 1] = TextBlock(block.Heading, "GameFontHighlight", 4)
        elseif block.Term then
            blocks[#blocks + 1] = TextBlock(NORMAL_FONT_COLOR:WrapTextInColorCode(block.Term) .. ": " .. (block.Text or ""), "GameFontHighlightSmall", 6)
        elseif block.Text then
            blocks[#blocks + 1] = TextBlock(block.Text, "GameFontHighlightSmall", 8)
        end
    end
    self:FillHelp(blocks)
    self:UpdateShowMe()
end

-- While searching with no row under the mouse: what the search finds, and what the broad search adds
function WindowMixin:ShowSearchHelp()
    self.HoverOption = nil
    self.Help = nil -- no section's help is drawn, so Show me hides
    local strings = self.Strings
    self:SetKicker(strings.HowItWorks)
    local blocks = { TextBlock(strings.Search, "GameFontNormalLarge", 10) }
    if strings.SearchHelp then blocks[#blocks + 1] = TextBlock(strings.SearchHelp, "GameFontHighlightSmall", 8) end
    if strings.SearchHelpBroad and strings.SearchBroad then blocks[#blocks + 1] = TextBlock(strings.SearchHelpBroad, "GameFontHighlightSmall", 8) end
    self:FillHelp(blocks)
    self:UpdateShowMe()
end

-- Show me: help.ShowMe (a plain function), or help.ShowMeSecure(button, close) for a feature that needs a secure
-- button laid over ours (the map's). ShowMeSecure is called only while that section's own help is drawn and
-- ShowMeSecure(nil) releases its button as soon as it is not (another section, an option's description, the pane
-- collapsed, the window hidden). In combat it releases its button itself and returns true: ours stays, greyed. It returns
-- false when it cannot lay one over at all; then ours hides and help.ShowMeNote (a string or a function returning one)
-- explains what to do instead.
function WindowMixin:ReleaseShowMe()
    if self.SecureHelp then
        Protected(self.SecureHelp.ShowMeSecure, nil)
        self.SecureHelp = nil
    end
end

function WindowMixin:UpdateShowMe()
    local help = self.Help
    local visible = self:IsShown() and not self.PaneCollapsed and not self.HoverOption and help and (help.ShowMe ~= nil or help.ShowMeSecure ~= nil)
    local secure = visible and help.ShowMeSecure and help or nil
    if self.SecureHelp ~= secure then self:ReleaseShowMe() end
    local note
    local showButton = visible and true or false
    if secure then
        local ok, laid = Protected(help.ShowMeSecure, self.ShowMeButton, function() self:Hide() end)
        showButton = ok and laid ~= false
        -- One that errored may have laid its button before it failed, so it is let go like one that laid it
        self.SecureHelp = (showButton or not ok) and help or nil
    end
    if visible and not showButton and help.ShowMeNote then
        if type(help.ShowMeNote) == "function" then note = Ask(nil, help.ShowMeNote) else note = help.ShowMeNote end
        if type(note) ~= "string" then note = nil end -- an error, or no text: no note
    end
    local inCombat = self:InCombat()
    if showButton and inCombat then note = self.Strings.NotInCombat end
    self.ShowMeButton:SetShown(showButton)
    self.ShowMeButton:SetEnabled(not inCombat)
    self.ShowMeNote:ClearAllPoints()
    if showButton then
        self.ShowMeNote:SetPoint("LEFT", self.ShowMeButton, "RIGHT", 8, 0)
    else
        self.ShowMeNote:SetPoint("BOTTOMLEFT", self.HelpBackground, "BOTTOMLEFT", 16, 16)
    end
    self.ShowMeNote:SetPoint("RIGHT", self.HelpBackground, "RIGHT", -10, 0)
    self.ShowMeNote:SetText(note or "")
    self.ShowMeNote:SetShown(note ~= nil)
end

-- The option's description and lines, and whether it is changed (its undo arrow's line, which RefreshHover follows)
local function OptionHelpLines(strings, option)
    local lines = {}
    local desc = option.GetDescription and option:GetDescription() or ""
    local hasDefault, default = false, nil
    if option.GetDefault then hasDefault, default = option:GetDefault() end
    if hasDefault then
        local text = option.FormatValue and option:FormatValue(default) or tostring(default)
        lines[#lines + 1] = strings.Default:format(text)
    end
    -- Each of the row's arrows before what it means
    if option.GetNeedsReload and option:GetNeedsReload() then lines[#lines + 1] = lib.Markup.Reload .. " " .. strings.NeedsReload end
    local changed = option.IsChanged and option:IsChanged() or false
    if changed then lines[#lines + 1] = lib.Markup.Reset .. " " .. RESET_TO_DEFAULT end
    return desc, lines, changed
end

-- controlX: where the hovered control starts, from the row's left edge
function WindowMixin:OnRowEnter(option, row, controlX)
    if not option then return end
    self.HoverRow, self.HoverRowOption, self.HoverControlX = row, option, controlX
    local element = row and row.Element
    local desc, lines, changed = OptionHelpLines(self.Strings, option)
    self.HoverChanged = changed
    if self.PaneCollapsed then
        local tooltip = Krowi_Tooltip -- the addon's own tooltip, never GameTooltip (Krowi_Util creates it wherever KROWI_LIBMAN exists)
        -- Above the row, from 10 before its control, where the game's Options window shows a setting's tooltip
        -- (Blizzard_SettingControls.xml and .lua: ANCHOR_RIGHT on the part of the row before the control, x -10)
        tooltip:SetOwner(row, "ANCHOR_NONE")
        tooltip:SetPoint("BOTTOMLEFT", row, "TOPLEFT", (controlX or 0) - 10, 0)
        tooltip:AddLine(option:GetLabel(), 1, 1, 1)
        if desc ~= "" then tooltip:AddLine(desc, nil, nil, nil, true) end
        for _, line in ipairs(lines) do tooltip:AddLine(line, 0.6, 0.6, 0.6, true) end
        tooltip:Show()
        self.TooltipShown = tooltip
        return
    end
    self.HoverOption = option
    -- The row's own section: in the search results it can be any section, or another addon's
    local config = (element and element.Tab or self.Tab).Config
    self:SetKicker(Ask("", config.SectionName, element and element.SectionId or self.SectionId) or "")
    local blocks = { TextBlock(option:GetLabel(), "GameFontNormalLarge", 10) }
    if desc ~= "" then blocks[#blocks + 1] = TextBlock(desc, "GameFontHighlightSmall", 10) end
    for _, line in ipairs(lines) do blocks[#blocks + 1] = TextBlock(line, "GameFontDisableSmall", 4) end
    self:FillHelp(blocks)
    self:UpdateShowMe()
end

function WindowMixin:OnRowLeave()
    self.HoverRow, self.HoverRowOption, self.HoverControlX, self.HoverChanged = nil, nil, nil, nil
    if self.PaneCollapsed then
        self:HideTooltip()
        return
    end
    if not self.HoverOption then return end
    if self.Searching then self:ShowSearchHelp() else self:ShowSectionHelp() end
end

-- Whether a row still shows an option: as its own or the one after its check box as the row drew them, or as the option
-- its kind holds (Kinds.lua: a tab's Show, a grid row's check boxes)
local function RowShows(row, option)
    if row.Option == option or row.With == option then return true end
    local element = row.Element
    local kind = element and lib.Internal.Kinds[element.Kind]
    if not kind then return false end
    if kind.Options and kind.Options(element) == option then return true end
    for _, cell in ipairs(kind.Cells and kind.Cells(element) or {}) do
        if cell == option then return true end
    end
    return false
end

-- A change made under the mouse shows at once in the hovered row's help: its arrow's line comes or goes with it
-- (docs/work/2026-11-04-krowi-options-library). Only that line follows the value, so the help is drawn again only when
-- the option turns changed or back, not on every step of a slider's drag. A rebuilt page may have given the row another
-- option; then it waits for the next enter.
function WindowMixin:RefreshHover()
    local row, option = self.HoverRow, self.HoverRowOption
    if not row or not row:IsVisible() or not RowShows(row, option) then return end
    if (option.IsChanged and option:IsChanged() or false) == self.HoverChanged then return end
    self:HideTooltip()
    self:OnRowEnter(option, row, self.HoverControlX)
end

function WindowMixin:HideTooltip()
    if self.TooltipShown then
        self.TooltipShown:Hide()
        self.TooltipShown = nil
    end
end