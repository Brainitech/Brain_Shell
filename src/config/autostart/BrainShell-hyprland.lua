-- Brain Shell Autostarts
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.local/src/Brain_Shell")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)