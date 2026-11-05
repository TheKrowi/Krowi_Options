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
local L = lib.Localization.NewLocale("itIT", true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "Tutti"
L["Default: {value}"] = "Predefinito: {value}"
L["Defaults"] = "Predefiniti"
L["Help Search Broad"] = "Spunta Cerca nelle descrizioni per trovare anche le opzioni in base a ciò che fanno."
L["Help Search Names"] = "Trova le opzioni in base al nome. Modificale direttamente qui o fai clic sul nome di una sezione per aprirla."
L["How it works"] = "Come funziona"
L["Not bound"] = "Non assegnato"
L["Not in combat"] = "Non in combattimento"
L["Nothing found."] = "Nessun risultato."
L["Overview"] = "Panoramica"
L["Press a key"] = "Premi un tasto"
L["Reload now"] = "Ricarica ora"
L["Search all tabs"] = "Cerca in tutte le schede"
L["Search descriptions"] = "Cerca nelle descrizioni"
L["Search results"] = "Risultati della ricerca"
L["Set every option of {section} back to its default?"] = "Ripristinare tutte le opzioni di {section} ai valori predefiniti?"
L["Show me"] = "Mostrami"
L["Some changes take effect after a reload."] = "Alcune modifiche hanno effetto dopo aver ricaricato l'interfaccia."
L["{count} changed"] = "{count} modificate"