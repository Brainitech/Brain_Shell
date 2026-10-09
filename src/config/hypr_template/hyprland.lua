-- ################################################################################
-- # hyprland.lua — Entry point
-- # https://wiki.hypr.land/Configuring/Start/
-- #
-- # Structure:
-- #   config/colors.lua        — theme palette reference
-- #   config/monitors.lua      — monitor setup
-- #   config/autostart.lua     — exec-once equivalents
-- #   config/look_and_feel.lua — general, decoration, layouts, misc
-- #   config/animations.lua    — curves + animation config (was me.conf)
-- #   config/input.lua         — keyboard, touchpad, gestures, devices
-- #   config/binds.lua         — all keybindings
-- #   config/rules.lua         — window rules + workspace rules
-- ################################################################################

---------------------------------
---- ENVIRONMENT VARIABLES ------
---------------------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

---------------------------------
-------- MODULE SOURCES ----------
---------------------------------

require("config.monitors")
require("config.autostart")
require("config.look_and_feel")
require("config.animations")
require("config.input")
require("config.binds")
require("config.rules")

---------------------------------
---- EXTERNAL CONFIGURATIONS ----
---------------------------------
-- Source any .lua files placed in lua.d/ (e.g. by Home Manager)
local f = io.popen('ls -1 ~/.config/hypr/lua.d/*.lua 2>/dev/null')
if f then
    for file in f:lines() do
        dofile(file)
    end
    f:close()
end
