-- ################################################################################
-- # config/look_and_feel.lua — Visuals, layouts, and misc
-- # See https://wiki.hypr.land/Configuring/Basics/Variables/
-- ################################################################################

-- Colors are globals set by config/colors.lua (required before this module).
-- primary / secondary are populated by matugen at generation time.

hl.config({

    ---------------------------------
    -------- GENERAL ----------------
    ---------------------------------
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 2,
        col              = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959B3)",
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "master",
    },

    ---------------------------------
    -------- DECORATION -------------
    ---------------------------------
    decoration = {
        rounding         = 10,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow           = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
        blur             = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },

    ---------------------------------
    -------- DWINDLE LAYOUT ---------
    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
    ---------------------------------
    dwindle = {
        preserve_split = true,
    },

    ---------------------------------
    -------- MASTER LAYOUT ----------
    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
    ---------------------------------
    master = {
        new_status                    = "master",
        orientation                   = "center",
        slave_count_for_center_master = 6,
        center_master_fallback        = "left",
        new_on_top                    = true,
        allow_small_split             = true,
    },

    ---------------------------------
    -------- SCROLLING LAYOUT -------
    -- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
    ---------------------------------
    scrolling = {
        fullscreen_on_one_column = true,
        column_width             = 0.5,
        focus_fit_method         = 1,
        follow_focus             = true,
        follow_min_visible       = 0.4,
        explicit_column_widths   = 0.25, 0.5, 0.75, 1.0,
        direction                = "right",
    },

    ---------------------------------
    -------- MISC -------------------
    ---------------------------------
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        focus_on_activate       = true
    },
})

---------------------------------
-- GTK theming (exec on every reload, equivalent to `exec` in hyprlang)
---------------------------------
-- GTK4 — dark (overridden to light below, kept for reference)
--hl.exec_cmd([[gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"]])
-- GTK3
hl.exec_cmd([[gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"]])
