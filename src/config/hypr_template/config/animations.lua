-- ################################################################################
-- # config/animations.lua — Bezier curves and animation config
-- # Converted from: animations/me.conf
-- # See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- ################################################################################

hl.config({
    animations = {
        enabled = true,
    },
})

---------------------------------
-------- CURVES -----------------
---------------------------------

hl.curve("overshot",    { type = "bezier", points = { { 0.05, 0.9  }, { 0.1,  1.05 } } })
hl.curve("crazyshot",   { type = "bezier", points = { { 0.1,  1.5  }, { 0.76, 0.92 } } })
hl.curve("crazyout",    { type = "bezier", points = { { 0.3, -0.4  }, { 0.8,  0.92 } } })
hl.curve("softAcDecel", { type = "bezier", points = { { 0.26, 0.26 }, { 0.15, 1.0  } } })

---------------------------------
-------- ANIMATIONS -------------
---------------------------------

hl.animation({ leaf = "windowsMove",         enabled = true, speed = 4, bezier = "crazyshot",   style = "slide"         })
hl.animation({ leaf = "windowsIn",           enabled = true, speed = 4, bezier = "crazyshot",   style = "gnomed"        })
hl.animation({ leaf = "windowsOut",          enabled = true, speed = 4, bezier = "crazyshot",   style = "gnomed"        })
hl.animation({ leaf = "layers",              enabled = true, speed = 3, bezier = "overshot",    style = "slide top"     })
hl.animation({ leaf = "workspaces",          enabled = true, speed = 4, bezier = "softAcDecel", style = "slide"         })
hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 4, bezier = "crazyshot",   style = "slidefadevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "crazyout",    style = "slidefadevert" })
