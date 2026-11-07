--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- [[ Game only: a consumer's secure Show me button, stood in for ]] --
-- The fixture's Tooltips help asks for a secure button laid over Show me (help.ShowMeSecure, Fixtures.lua), as
-- Krowi_AchievementFilter's map help does (KAF's Options/Window/Help/ShowMe.lua). This is that button, made the way KAF
-- makes its own, so the live steps (Steps.lua: show-me-secure, show-me-secure-hover, show-me-secure-click) can check that
-- the library calls it at the right moments, that it lies over Show me wherever the window stands, and that the mouse
-- and a click reach it there rather than the library's own button (docs/work/2026-11-07-release-hardening).
-- - A SecureActionButtonTemplate button on UIParent, placed by coordinates over the button it is handed: a protected
--   frame cannot anchor to an addon's regions. Strata DIALOG, one above the window's HIGH, since a click into a toplevel
--   window lifts its own buttons over anything in its strata (Krowi_ClaudeKit's WowAddons.md).
-- - Its action is "click" on a plain button of this addon that only counts (Clicks), as KAF's clicks the minimap's map
--   button. That button is never placed or sized, so nothing draws it and no mouse reaches it; it is not hidden with
--   Hide, since whether a secure click's Click() runs a hidden button on every client is not known here.
-- - Its OnEnter counts (Entered); its PostClick runs the close the library handed it, which hides the window.
-- - ShowMeSecure records every call (Calls: { Owner, Close }, Owner nil for a let-go) and answers as the contract says
--   (Krowi_Options.lua's header, WindowHelp.lua's ReleaseShowMe): nil lets go and answers true; with AnswerFalse set it
--   lets go and answers false (no button can lie over Show me, so the help's ShowMeNote shows in its place); else it
--   lies over the button handed to it, a frame later while that button has no place yet, and answers true.
-- - Never made, shown, moved or hidden in combat: there it answers true and does nothing. It lets go on
--   PLAYER_REGEN_DISABLED, which comes before the lockdown, as KAF's does, so a fight during a run does not leave it
--   over the screen.
-- - A light tint shows where it lies in the steps' screenshots. No global name, no hook, no CVar, and no error of its
--   own: the run's lua-errors step fails on any error naming Krowi_Options, which this addon's folder name holds.
-- Loaded in game only (Tests/Files.xml), after Fixtures.lua; the headless harness loads Fixtures.lua without it.

local _, addon = ...
addon.Tests = addon.Tests or {}
local standIn = { Calls = {}, Clicks = 0, PostClicks = 0, Entered = 0, AnswerFalse = false, Pending = false }
addon.Tests.ShowMeStandIn = standIn

local button -- made at the first call that lays it over, out of combat; standIn.Button from then on

local function Release()
    if not button or InCombatLockdown() then return end
    button:UnregisterEvent("PLAYER_REGEN_DISABLED")
    button:Hide()
    button:ClearAllPoints()
    button.Owner, button.Close = nil, nil
    standIn.Pending = false
end
standIn.Release = Release

-- In a fight, or about to be: true inside PLAYER_REGEN_DISABLED too, where the window refreshes Show me before the
-- lockdown starts (KAF's map route reads the same pair)
local function InCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

-- Over the owner, in UIParent's coordinates (KAF's PlaceOver); false while the owner has no place yet (its first draw)
local function PlaceOver(owner)
    local left, bottom = owner:GetLeft(), owner:GetBottom()
    if not left or not bottom then return false end
    local scale = owner:GetEffectiveScale() / UIParent:GetEffectiveScale()
    button:SetFrameStrata("DIALOG")
    button:SetFrameLevel(2)
    button:ClearAllPoints()
    button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * scale, bottom * scale)
    button:SetSize(owner:GetWidth() * scale, owner:GetHeight() * scale)
    return true
end

local function LayOver(owner)
    if not PlaceOver(owner) then return false end
    button:RegisterEvent("PLAYER_REGEN_DISABLED")
    button:Show()
    standIn.Pending = false
    return true
end

local function Create()
    local counter = CreateFrame("Button")
    counter:RegisterForClicks("AnyUp")
    counter:SetScript("OnClick", function() standIn.Clicks = standIn.Clicks + 1 end)

    local made = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    made:RegisterForClicks("LeftButtonUp") -- the left button only, as KAF's
    made:SetAttribute("type", "click")
    made:SetAttribute("useOnKeyDown", false)
    made:SetAttribute("clickbutton", counter)
    made:SetScript("OnEnter", function() standIn.Entered = standIn.Entered + 1 end)
    -- Counted apart from the counting button's clicks, so a click that reached it without its secure action running
    -- shows as one (show-me-secure-click fails on it instead of waiting for a click that already came)
    made:SetScript("PostClick", function(self)
        standIn.PostClicks = standIn.PostClicks + 1
        if self.Close then self.Close() end
    end)
    made:SetScript("OnEvent", function() Release() end) -- PLAYER_REGEN_DISABLED, before the lockdown starts
    local tint = made:CreateTexture(nil, "OVERLAY")
    tint:SetAllPoints()
    tint:SetColorTexture(0, 0.8, 1, 0.25)
    made:Hide()
    standIn.Button = made
    return made
end

-- owner: the window's Show me button, or nil to let go; close: hides the window
function standIn.ShowMeSecure(owner, close)
    standIn.Calls[#standIn.Calls + 1] = { Owner = owner, Close = close }
    -- In a fight it lets go (a no-op once the lockdown runs) and does nothing else, as KAF's map route
    if InCombat() then
        Release()
        return true
    end
    if not owner then
        Release()
        return true
    end
    if standIn.AnswerFalse then
        Release()
        return false
    end
    button = button or Create()
    button.Owner, button.Close = owner, close
    if not LayOver(owner) then
        standIn.Pending = true -- laid over next frame, once the owner has its place
        C_Timer.After(0, function()
            if button.Owner == owner and owner:IsVisible() and not InCombat() then LayOver(owner) end
        end)
    end
    return true
end

function standIn.IsShown()
    return button ~= nil and button:IsShown() and true or false
end