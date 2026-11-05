--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- true: every copy of the library adds its phrases, so a newer copy's code finds the ones it added; where two copies
-- have the same phrase, the last-loaded copy's translation stays (CLAUDE.md, known debt)
local L = lib.Localization.NewLocale("zhCN", true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "全部"
L["Default: {value}"] = "默认：{value}"
L["Defaults"] = "默认设置"
L["Help Search Broad"] = "勾选“搜索描述”后，还可以按作用查找选项。"
L["Help Search Names"] = "按名称查找选项。可直接在此更改，或点击部分名称打开该部分。"
L["How it works"] = "工作原理"
L["None"] = "无"
L["Not bound"] = "未绑定"
L["Not in combat"] = "战斗中不可用"
L["Nothing found."] = "未找到结果。"
L["Overview"] = "概览"
L["Press a key"] = "请按下按键"
L["Reload now"] = "立即重新加载"
L["Requires a reload"] = "需要重载界面"
L["Search"] = "搜索"
L["Search all tabs"] = "搜索所有标签页"
L["Search descriptions"] = "搜索描述"
L["Search results"] = "搜索结果"
L["Set every option of {section} back to its default?"] = "将{section}的所有选项恢复为默认值？"
L["Show me"] = "查看效果"
L["Some changes take effect after a reload."] = "部分更改需重新加载后生效。"
L["{count} changed"] = "已更改 {count} 项"