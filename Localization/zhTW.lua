--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:GetCurrentLibrary(true)
if not lib then return end

-- true: every copy of the library adds its phrases, so a newer copy's code finds its own; AceLocale keeps an English
-- text already set
local L = lib.Localization.NewLocale('zhTW', true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "全部"
L["Default: {value}"] = "預設：{value}"
L["Defaults"] = "預設值"
L["Help Search Broad"] = "勾選「搜尋描述」後，還可以依作用尋找選項。"
L["Help Search Names"] = "依名稱尋找選項。可直接在此變更，或點擊部分名稱開啟該部分。"
L["How it works"] = "運作方式"
L["None"] = "無"
L["Not bound"] = "未綁定"
L["Not in combat"] = "戰鬥中無法使用"
L["Nothing found."] = "找不到結果。"
L["Overview"] = "概覽"
L["Press a key"] = "請按下按鍵"
L["Reload now"] = "立即重新載入"
L["Search"] = "搜尋"
L["Search all tabs"] = "搜尋所有分頁"
L["Search descriptions"] = "搜尋描述"
L["Search results"] = "搜尋結果"
L["Set every option of {section} back to its default?"] = "將{section}的所有選項還原為預設值？"
L["Show me"] = "查看效果"
L["Some changes take effect after a reload."] = "部分變更需重新載入後生效。"
L["{count} changed"] = "已變更 {count} 項"