--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- true: every copy of the library adds its phrases, so a newer copy's code finds the ones it added; where two copies
-- have the same phrase, the last-loaded copy's translation stays (CLAUDE.md, known debt)
local L = lib.Localization.NewLocale("esES", true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "Todos"
L["Default: {value}"] = "Por defecto: {value}"
L["Defaults"] = "Por defecto"
L["Help Search Broad"] = "Marca Buscar en las descripciones para encontrar también opciones por lo que hacen."
L["Help Search Names"] = "Encuentra opciones por su nombre. Cámbialas aquí mismo o haz clic en el nombre de una sección para abrirla."
L["How it works"] = "Cómo funciona"
L["Not bound"] = "Sin asignar"
L["Not in combat"] = "No en combate"
L["Nothing found."] = "No se ha encontrado nada."
L["Overview"] = "Vista general"
L["Press a key"] = "Pulsa una tecla"
L["Reload now"] = "Recargar ahora"
L["Search all tabs"] = "Buscar en todas las pestañas"
L["Search descriptions"] = "Buscar en las descripciones"
L["Search results"] = "Resultados de búsqueda"
L["Set every option of {section} back to its default?"] = "¿Restablecer todas las opciones de {section} a sus valores por defecto?"
L["Show me"] = "Muéstramelo"
L["Some changes take effect after a reload."] = "Algunos cambios se aplican tras recargar la interfaz."
L["{count} changed"] = "{count} cambiado(s)"