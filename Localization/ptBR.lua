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
local L = lib.Localization.NewLocale("ptBR", true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "Todos"
L["Default: {value}"] = "Padrão: {value}"
L["Defaults"] = "Padrões"
L["Help Search Broad"] = "Marque Pesquisar nas descrições para encontrar também opções pelo que fazem."
L["Help Search Names"] = "Encontra opções pelo nome. Altere-as aqui mesmo ou clique no nome de uma seção para abri-la."
L["How it works"] = "Como funciona"
L["None"] = "Nenhum"
L["Not bound"] = "Não atribuído"
L["Not in combat"] = "Não em combate"
L["Nothing found."] = "Nada encontrado."
L["Overview"] = "Visão geral"
L["Press a key"] = "Pressione uma tecla"
L["Reload now"] = "Recarregar agora"
L["Search"] = "Busca"
L["Search all tabs"] = "Pesquisar em todas as abas"
L["Search descriptions"] = "Pesquisar nas descrições"
L["Search results"] = "Resultados da pesquisa"
L["Set every option of {section} back to its default?"] = "Resetar todas as opções de {section} para o padrão?"
L["Show me"] = "Mostre-me"
L["Some changes take effect after a reload."] = "Algumas alterações só têm efeito após recarregar."
L["{count} changed"] = "{count} alterado(s)"