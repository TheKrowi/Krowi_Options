--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

-- [[ https://legacy.curseforge.com/wow/addons/krowi-options/localization ]] --

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- The phrases of every copy loaded so far, in the player's language, English where it has none
lib.L = lib.Localization.GetLocale()