-- Brain Shell Autostarts
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.local/src/Brain_Shell")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

hl.layer_rule({
    match   = { namespace = "quickshell" },
    no_anim = true,
})

local kb_path = os.getenv("HOME") .. "/.config/Brain_Shell/Brain_ShellKeybinds.lua"
local f = io.open(kb_path, "r")
if f then
    f:close()
    dofile(kb_path)
end
