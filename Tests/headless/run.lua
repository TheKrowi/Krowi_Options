--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- Runs every headless suite of the library and exits 1 when a check fails. A new suite file goes in the list below
-- (Lua 5.1 cannot list a folder).
--
-- Run: <Krowi_ClaudeKit>\tools\lua51\lua.exe Tests\headless\run.lua   (from the repo root or a worktree's)

local folder = ((arg and arg[0]) or ""):gsub("\\", "/"):match("^(.-)run%.lua$") or ""
local h = assert(loadfile(folder .. "harness.lua"))()

local suites = { "ReviewFixes", "ContractAndErrors", "Bugs", "TestAddon" }

for _, name in ipairs(suites) do
    h.BeginSuite(name)
    assert(loadfile(folder .. "suites/" .. name .. ".lua"))(h)
end

print(("%d passed (%d of them open defects: Recorded differs from Target), %d failed, %d game only"):format(h.passed, h.open, h.failed, h.gameOnly))
print(h.failed == 0 and "every check passes" or ("%d check(s) fail"):format(h.failed))
if h.failed > 0 then os.exit(1) end
