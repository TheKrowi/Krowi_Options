---@diagnostic disable: lowercase-global, undefined-global, need-check-nil
-- Reads the test addon's saved variables file (WTF\Account\<account>\SavedVariables\Krowi_OptionsTests.lua), plain Lua
-- assigning KrowiOptionsTests_Debug, and prints a /kotest run (Tests/Krowi_OptionsTests/Tests/Runner.lua) next to the
-- lines the headless run produced for the same scenarios (Tests/Krowi_OptionsTests/Run-Headless.lua). Lines of live steps,
-- which only the game runs, are marked g and not compared; a step's screenshot time is printed for Read-GameTests.ps1 to
-- pair with its file. After Krowi_AchievementFilter's .claude/tools/headless/read-tests.lua.
--
-- Usage: lua.exe read-tests.lua <path to Krowi_OptionsTests.lua> [<file with the headless lines>] [<n: the nth newest kept run>]
-- Exit code 0 when the game run has no FAIL and matches the headless lines, 1 otherwise, 2 when unreadable.

local path, headlessPath, runArg = ...

local chunk, err = loadfile(path)
if not chunk then
    io.stderr:write("cannot load ", tostring(path), ": ", tostring(err), "\n")
    os.exit(2)
end
chunk()
local tests = KrowiOptionsTests_Debug and KrowiOptionsTests_Debug.Tests
local history = tests and type(tests.History) == "table" and tests.History or {}
local run = tests and tests.LastRun
local runIndex = tonumber(runArg) -- 1 = the newest kept run
if runIndex then
    run = history[#history - runIndex + 1]
end
if type(run) ~= "table" then
    io.stdout:write("no test run stored in ", path, runIndex and (" as run " .. runIndex) or "", " (run /kotest in game, then /reload)\n")
    os.exit(2)
end

-- A run of some steps only (/kotest toggle) carries what was typed after /kotest
local function SuiteName(r)
    return tostring(r.Suite) .. (r.Argument and (" " .. tostring(r.Argument)) or "")
end

io.stdout:write(("suite %s, run %s in game, addon %s, build %s: %d passed, %d failed, %d skipped; %d open against the target behaviour%s\n"):format(
    SuiteName(run), tostring(run.Time), tostring(run.Version), tostring(run.Build), run.Passed or 0, run.Failed or 0, run.Skipped or 0, run.Open or 0,
    run.Argument and "; some steps only" or ""))
if run.Library then io.stdout:write("library minors in game: ", tostring(run.Library), "\n") end
io.stdout:write("\n")

local headless
local f = headlessPath and io.open(headlessPath, "rb")
if f then
    headless = {}
    for line in f:read("*a"):gmatch("[^\r\n]+") do
        local scenario, suite = line:match("^(([%w_%-]+)/[%w_%-]+): ") -- "<suite>/<scenario>: ..."; the summary line does not match
        if scenario and suite == tostring(run.Suite) then headless[scenario] = line end
    end
    f:close()
end

local differences, seen = 0, {}
for i, line in ipairs(run.Lines or {}) do
    local scenario = line:match("^(.-): ")
    local gameOnly = run.GameOnly and run.GameOnly[i]
    local mark = "   "
    if gameOnly then
        mark = " g " -- a live step; the headless run has no line for it
    elseif headless then
        seen[scenario] = true
        if headless[scenario] == line then
            mark = " = "
        else
            mark = " ! "
            differences = differences + 1
        end
    end
    io.stdout:write(mark, line, "\n")
    if mark == " ! " and headless[scenario] then io.stdout:write("     headless: ", headless[scenario], "\n") end
    local shot = run.Screenshots and run.Screenshots[i]
    if type(shot) == "table" and shot.Time then -- Read-GameTests.ps1 puts the file's path on this line
        local at = #shot.Time > 8 and shot.Time or (tostring(run.Time):sub(1, 10) .. " " .. shot.Time) -- a time alone: the run's date
        io.stdout:write(("     screenshot at %s%s\n"):format(at, shot.Failed and " (the game reported the screenshot failed)" or ""))
    end
end
for _, observation in ipairs(run.Observations or {}) do
    io.stdout:write("observed in game: ", observation, "\n")
end
if headless then
    for scenario, line in pairs(headless) do
        if not seen[scenario] then
            differences = differences + 1
            io.stdout:write(" ! not run in game: ", line, "\n")
        end
    end
    io.stdout:write(("\n%d difference(s) between the game and the headless run (= same, ! differs, g game only)\n"):format(differences))
end
if #history > 0 then -- also one run: Run-GameTests.ps1 finds a session's runs in this list
    io.stdout:write("\nkept runs, newest first (Read-GameTests.ps1 -Run <n> shows one):\n")
    for n = 1, #history do
        local kept = history[#history - n + 1]
        io.stdout:write(("  %d. %s %s, build %s: %d passed, %d failed, %d skipped\n"):format(n, tostring(kept.Time), SuiteName(kept),
            tostring(kept.Build), kept.Passed or 0, kept.Failed or 0, kept.Skipped or 0))
    end
end
os.exit((differences > 0 or (run.Failed or 0) > 0) and 1 or 0)