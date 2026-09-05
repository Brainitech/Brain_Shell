exec-once = awww-daemon
exec-once = hypridle -c $HOME/.local/src/Brain_Shell/src/config/hypridle.conf
exec-once = quickshell -c $HOME/.local/src/Brain_Shell/.
exec-once = systemctl --user start hyprpolkitagent
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

input {
    kb_layout = __KB_LAYOUT__
    kb_variant = __KB_VARIANT__
}
