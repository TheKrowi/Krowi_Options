--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The test addon's frame-free scenarios (Tests/Scenarios.lua, on Tests/Fixtures.lua) on the headless harness of
-- Tests/headless/harness.lua: each scenario on a game with no copy loaded, then this checkout's copy (h.LoadCopy) and the
-- fixture tab registered, as the test addon has them at login. Never deployed (Deploy-TestAddon.ps1 leaves it out).
--
-- local results = assert(loadfile("Tests/Krowi_OptionsTests/Headless.lua"))(h[, asSuite])
--   results: { { Name, Status = "PASS" | "FAIL" | "SKIP", TargetMet, Value, Error, Line } }, Line as the game writes it
--   asSuite: each scenario also goes through h.Scenario, so the harness prints and counts it (a suite in run.lua:
--            assert(loadfile(folder .. "../Krowi_OptionsTests/Headless.lua"))(h, true))
-- Run-Headless.lua beside it prints the lines and exits 1 on a failed one.

local h, asSuite = ...
local folder = debug.getinfo(1, "S").source:match("^@(.-)[^/\\]*$") or ""

local addon = { Tests = {} }
for _, file in ipairs({ "Fixtures.lua", "Scenarios.lua" }) do
    assert(loadfile(folder .. "Tests/" .. file))("Krowi_OptionsTests", addon)
end
local tests, fixtures = addon.Tests, addon.Tests.Fixtures

-- The saved table config.Saved gives: a plain table here, as the test addon's saved variable is after login
local function Prepare()
    local lib = h.LoadCopy()
    fixtures.Reset()
    fixtures.Register(lib, {})
end

local results = {}
for i, scenario in ipairs(tests.Scenarios) do
    local result
    local function Observe()
        Prepare()
        result = tests.RunScenario(scenario)
        if result.Error then error(result.Error, 0) end
        return result.Value
    end
    if asSuite then
        h.Scenario(i, scenario.Name, { Observe = Observe, Recorded = scenario.Recorded, Target = scenario.Target })
    else
        h.Fresh()
        local ok, err = pcall(Observe)
        if not ok and not result then
            result = { Name = scenario.Name, Status = "FAIL", TargetMet = false, Error = tostring(err),
                Line = ("options/%s: FAIL error=[%s]"):format(scenario.Name, tostring(err)) }
        end
    end
    results[#results + 1] = result
end
return results