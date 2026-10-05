-- Brain Shell Autostarts
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("quickshell -p " .. os.getenv("HOME") .. "/.local/src/Brain_Shell")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

hl.layer_rule({
    match   = { namespace = "^brain-shell.*" },
    no_anim = true,
})

hl.layer_rule({
    match        = { namespace = "selection" },
    no_anim      = true,
    ignore_alpha = 1,
})

local kb_path = os.getenv("HOME") .. "/.config/Brain_Shell/Brain_ShellKeybinds.lua"
local f = io.open(kb_path, "r")
if f then
    f:close()
    dofile(kb_path)
end
