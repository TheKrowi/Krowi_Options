--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

if not KROWI_LIBMAN then return end -- a standalone install loaded before any Krowi addon (Krowi_Options.lua)
local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- true: every copy of the library adds its phrases, so a newer copy's code finds the ones it added; where two copies
-- have the same phrase, the last-loaded copy's translation stays (CLAUDE.md, known debt)
local L = lib.Localization.NewLocale("deDE", true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "Alle"
L["Default: {value}"] = "Standard: {value}"
L["Defaults"] = "Standardwerte"
L["Help Search Broad"] = "Aktiviere „Beschreibungen durchsuchen“, um Optionen auch anhand ihrer Wirkung zu finden."
L["Help Search Names"] = "Findet Optionen anhand ihres Namens. Ändere sie direkt hier oder klicke auf den Namen eines Abschnitts, um ihn zu öffnen."
L["How it works"] = "So funktioniert es"
L["None"] = "Keine"
L["Not bound"] = "Nicht belegt"
L["Not in combat"] = "Nicht im Kampf"
L["Nothing found."] = "Nichts gefunden."
L["Overview"] = "Übersicht"
L["Press a key"] = "Taste drücken"
L["Reload now"] = "Jetzt neu laden"
L["Requires a reload"] = "Funktioniert erst nach einem /reload."
L["Search"] = "Suche"
L["Search all tabs"] = "Alle Reiter durchsuchen"
L["Search descriptions"] = "Beschreibungen durchsuchen"
L["Search results"] = "Suchergebnisse"
L["Set every option of {section} back to its default?"] = "Alle Optionen von {section} auf den Standard zurücksetzen?"
L["Show me"] = "Zeig es mir"
L["Some changes take effect after a reload."] = "Einige Änderungen werden erst nach einem Reload wirksam."
L["{count} changed"] = "{count} geändert"