--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

if not KROWI_LIBMAN then return end -- a standalone install loaded before any Krowi addon (Krowi_Options.lua)
local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- true: every copy of the library adds its phrases, so a newer copy's code finds the ones it added; where two copies
-- have the same phrase, the first-loaded copy's English stays (CLAUDE.md, known debt)
local L = lib.Localization.NewDefaultLocale(true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = true
L["Default: {value}"] = true
L["Defaults"] = true
L["Help Search Broad"] = "Tick Search descriptions to also find options by what they do."
L["Help Search Names"] = "Finds options by their name. Change them right here, or click a section's name to open it."
L["How it works"] = true
L["None"] = true
L["Not bound"] = true
L["Not in combat"] = true
L["Nothing found."] = true
L["Overview"] = true
L["Press a key"] = true
L["Reload now"] = true
L["Requires a reload"] = "Requires a reload to take full effect."
L["Search"] = true
L["Search all tabs"] = true
L["Search descriptions"] = true
L["Search results"] = true
L["Set every option of {section} back to its default?"] = true
L["Show me"] = true
L["Some changes take effect after a reload."] = true
L["{count} changed"] = true