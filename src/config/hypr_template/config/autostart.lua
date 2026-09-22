-- ################################################################################
-- # config/autostart.lua — Startup processes
-- # See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- #
-- # hl.on("hyprland.start", ...) is the exec-once equivalent.
-- # Commands here run exactly once when Hyprland launches.
-- ################################################################################

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("systemctl --user is-active hyprland-session.target graphical-session.target")
end)

hl.on("hyprland.shutdown", function()
    os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)
