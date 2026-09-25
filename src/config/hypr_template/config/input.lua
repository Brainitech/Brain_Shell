-- ################################################################################
-- # config/input.lua — Input, gestures, and per-device config
-- # See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- ################################################################################

hl.config({
    input = {
        kb_layout          = "us",
        kb_variant         = "",
        kb_model           = "",
        kb_options         = "compose:rctrl",
        kb_rules           = "",
        numlock_by_default = true,
        follow_mouse       = 1,
        sensitivity        = 0,
        touchpad           = {
            natural_scroll = true,
        },
    },
    cursor = {
        no_hardware_cursors = 1,
    }
})

---------------------------------
-------- GESTURES ---------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
---------------------------------

-- 4-finger horizontal swipe → switch workspace
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
-- 4-finger vertical swipe   → toggle special:magic
hl.gesture({ fingers = 4, direction = "vertical", action = "special", workspace_name = "magic" })

---------------------------------
-------- DEVICES ----------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
---------------------------------

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
