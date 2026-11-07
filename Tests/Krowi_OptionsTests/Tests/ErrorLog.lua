--[[
    Copyright (c) 2026 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

-- The session's Lua errors on a client without BugGrabber (Era with it switched off, Anniversary): the game's error
-- handler is chained to one that keeps each message, so the run's lua-errors step (Steps.lua) can report an error that
-- names the library, also one from this addon's own load. Loaded first (Krowi_OptionsTests.xml), before the library.
-- Where BugGrabber is loaded it is the log and this does nothing. Dev-only addon: a player never has it.

local _, addon = ...
addon.Tests = addon.Tests or {}
addon.Tests.ErrorLog = {}

if BugGrabber or type(seterrorhandler) ~= "function" or type(geterrorhandler) ~= "function" then return end

local log = addon.Tests.ErrorLog
local previous = geterrorhandler()
seterrorhandler(function(message)
    log[#log + 1] = tostring(message)
    if previous then return previous(message) end
end)
log.Installed = true
