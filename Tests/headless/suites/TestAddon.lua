---@diagnostic disable: undefined-global

-- The frame-free scenarios of the test addon (Tests/Krowi_OptionsTests/Tests/Scenarios.lua), the ones that also run in
-- game through /kotest, run here on the fixture tab of Tests/Krowi_OptionsTests/Tests/Fixtures.lua.

local h = ...
assert(loadfile(h.root .. "Tests/Krowi_OptionsTests/Headless.lua"))(h, true)
