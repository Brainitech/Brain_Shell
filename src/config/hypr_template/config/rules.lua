-- ################################################################################
-- # config/rules.lua — Window rules and workspace rules
-- # See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- # See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- ################################################################################

---------------------------------
-------- WORKSPACE RULES --------
---------------------------------

hl.workspace_rule({ workspace = "special:magic", layout = "master" })

---------------------------------
-------- WINDOW RULES -----------
---------------------------------

hl.window_rule({
    name   = "float-file-upload",
    match  = { initial_title = ".*File Upload.*" },
    float  = true,
    center = true,
    size   = "900 700",
})

hl.window_rule({
    name   = "float-file-download",
    match  = { initial_title = ".*Enter name of file to save.*" },
    float  = true,
    center = true,
    size   = "900 700",
})

hl.window_rule({
    name   = "float-sign-in",
    match  = { initial_title = "^YouTube Music Desktop App" },
    float  = true,
    center = true,
    size   = "1500 900",
})

---------------------------------
--------- LAYER RULES -----------
---------------------------------

hl.layer_rule({
    match        = { namespace = "selection" },
    no_anim      = true,
    ignore_alpha = 1,
})
