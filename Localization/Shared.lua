--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

if not KROWI_LIBMAN then return end -- a standalone install loaded before any Krowi addon (Krowi_Options.lua)
local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- The phrases of every copy loaded so far, in the player's language, English where it has none; translated on
-- https://legacy.curseforge.com/wow/addons/krowi-options/localization
lib.L = lib.Localization.GetLocale()