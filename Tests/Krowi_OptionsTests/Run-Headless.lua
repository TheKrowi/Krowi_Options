--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- Prints the test addon's frame-free scenarios as the game writes them (Headless.lua) and exits 1 when one fails.
-- Read-GameTests.ps1 runs it to mark each game line that differs from the headless one. Never deployed.
--
-- Run: <Krowi_ClaudeKit>\tools\lua51\lua.exe Tests\Krowi_OptionsTests\Run-Headless.lua   (from the repo root or a worktree's,
-- or with the script's full path from anywhere)

local here = ((arg and arg[0]) or ""):gsub("\\", "/")
local root = here:match("^(.-)Tests/Krowi_OptionsTests/") or ""
local folder = here:match("^(.-)[^/]*$") or ""

-- harness.lua finds the repo root from the running script's path, which it expects under Tests/headless/
arg[0] = root .. "Tests/headless/run.lua"
local h = assert(loadfile(root .. "Tests/headless/harness.lua"))()
local results = assert(loadfile(folder .. "Headless.lua"))(h)

local counts, open = { PASS = 0, FAIL = 0, SKIP = 0 }, 0
for _, result in ipairs(results) do
    counts[result.Status] = counts[result.Status] + 1
    if result.TargetMet == false then open = open + 1 end
    print(result.Line)
end
print(("options (headless): %d passed, %d failed, %d skipped; %d open against the target behaviour"):format(counts.PASS, counts.FAIL, counts.SKIP, open))
if counts.FAIL > 0 then os.exit(1) end