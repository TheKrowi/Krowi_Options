--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- true: every copy of the library adds its phrases, so a newer copy's code finds the ones it added; where two copies
-- have the same phrase, the last-loaded copy's translation stays (CLAUDE.md, known debt)
local L = lib.Localization.NewLocale("frFR", true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "Tous"
L["Default: {value}"] = "Par défaut : {value}"
L["Defaults"] = "Par défaut"
L["Help Search Broad"] = "Cochez « Rechercher dans les descriptions » pour trouver aussi les options selon ce qu'elles font."
L["Help Search Names"] = "Trouve les options par leur nom. Modifiez-les directement ici, ou cliquez sur le nom d'une section pour l'ouvrir."
L["How it works"] = "Fonctionnement"
L["None"] = "Aucun"
L["Not bound"] = "Non assigné"
L["Not in combat"] = "Pas en combat"
L["Nothing found."] = "Aucun résultat."
L["Overview"] = "Vue d'ensemble"
L["Press a key"] = "Appuyez sur une touche"
L["Reload now"] = "Recharger maintenant"
L["Requires a reload"] = "Nécessite un /reload"
L["Search"] = "Rechercher"
L["Search all tabs"] = "Rechercher dans tous les onglets"
L["Search descriptions"] = "Rechercher dans les descriptions"
L["Search results"] = "Résultats de la recherche"
L["Set every option of {section} back to its default?"] = "Remettre toutes les options de {section} à leur valeur par défaut ?"
L["Show me"] = "Montrer"
L["Some changes take effect after a reload."] = "Certaines modifications prennent effet après un rechargement de l'interface."
L["{count} changed"] = "{count} modifié(s)"