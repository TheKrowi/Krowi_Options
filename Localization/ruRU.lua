--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- true: every copy of the library adds its phrases, so a newer copy's code finds its own; AceLocale keeps an English
-- text already set
local L = lib.Localization.NewLocale('ruRU', true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "Все"
L["Default: {value}"] = "По умолчанию: {value}"
L["Defaults"] = "По умолчанию"
L["Help Search Broad"] = "Отметьте «Искать в описаниях», чтобы находить также настройки по тому, что они делают."
L["Help Search Names"] = "Находит настройки по названию. Меняйте их прямо здесь или нажмите на название раздела, чтобы открыть его."
L["How it works"] = "Как это работает"
L["None"] = "Нету"
L["Not bound"] = "Не назначено"
L["Not in combat"] = "Не в бою"
L["Nothing found."] = "Ничего не найдено."
L["Overview"] = "Обзор"
L["Press a key"] = "Нажмите клавишу"
L["Reload now"] = "Перезагрузить сейчас"
L["Search"] = "Поиск"
L["Search all tabs"] = "Искать во всех вкладках"
L["Search descriptions"] = "Искать в описаниях"
L["Search results"] = "Результаты Поиска"
L["Set every option of {section} back to its default?"] = "Вернуть все настройки раздела {section} к значениям по умолчанию?"
L["Show me"] = "Показать"
L["Some changes take effect after a reload."] = "Некоторые изменения вступят в силу после перезагрузки."
L["{count} changed"] = "Изменено: {count}"