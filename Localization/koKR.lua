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
local L = lib.Localization.NewLocale("koKR", true)
if not L then return end

-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["All"] = "모두"
L["Default: {value}"] = "기본값: {value}"
L["Defaults"] = "기본값"
L["Help Search Broad"] = "'설명 검색'을 체크하면 하는 일로도 옵션을 찾을 수 있습니다."
L["Help Search Names"] = "이름으로 옵션을 찾습니다. 여기에서 바로 변경하거나, 섹션 이름을 클릭해 그 섹션을 여세요."
L["How it works"] = "작동 방식"
L["Not bound"] = "지정 안 됨"
L["Not in combat"] = "전투 중에는 불가"
L["Nothing found."] = "검색 결과가 없습니다."
L["Overview"] = "개요"
L["Press a key"] = "키를 누르세요"
L["Reload now"] = "지금 리로드"
L["Search"] = "검색"
L["Search all tabs"] = "모든 탭 검색"
L["Search descriptions"] = "설명 검색"
L["Search results"] = "검색 결과"
L["Set every option of {section} back to its default?"] = "{section}의 모든 설정을 기본값으로 되돌리시겠습니까?"
L["Show me"] = "보여 주기"
L["Some changes take effect after a reload."] = "일부 변경 사항은 리로드 후 적용됩니다."
L["{count} changed"] = "{count}개 변경됨"