-- ################################################################################
-- # config/binds.lua — All keybindings
-- # See https://wiki.hypr.land/Configuring/Basics/Binds/
-- # See https://wiki.hypr.land/Configuring/Basics/Dispatchers/
-- ################################################################################

local mainMod        = "SUPER"

---------------------------------
-------- PROGRAMS ---------------
---------------------------------

local terminal       = "kitty"
local fileManager    = ""
local brcmd          = "firefox"

---------------------------------
-------- LAYOUT HELPER ----------
---------------------------------

local function layout()
    return hl.get_active_workspace().tiled_layout
end

---------------------------------
-------- CORE -------------------
---------------------------------

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(brcmd))

---------------------------------
-------- LAYOUT SWITCHING -------
-- hl.get_option does not exist; track state locally.
-- current_layout must match the default set in look_and_feel.lua.
---------------------------------

local current_layout = "dwindle"
local scroll_dir     = "right"

local function set_layout(name)
    current_layout = name
    hl.config({ general = { layout = name } })
end

---------------------------------
-------- NAVIGATION (H/J/K/L) ---
---------------------------------

hl.bind(mainMod .. " + H", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit active"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "l" }))
    end
end)

hl.bind(mainMod .. " + J", function()
    local l = layout()
    if l == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit visible"))
    elseif l == "monocle" or l == "master" then
        hl.dispatch(hl.dsp.layout("cycleprev"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "d" }))
    end
end)

hl.bind(mainMod .. " + K", function()
    local l = layout()
    if l == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit tobeg"))
    elseif l == "monocle" or l == "master" then
        hl.dispatch(hl.dsp.layout("cyclenext"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "u" }))
    end
end)

hl.bind(mainMod .. " + SHIFT + K", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit toend"))
    end
end)

hl.bind(mainMod .. " + L", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit all"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "r" }))
    end
end)

---------------------------------
-------- MANIPULATION -----------
---------------------------------

-- Swap / split
hl.bind(mainMod .. " + RETURN", function()
    local l = layout()
    if l == "scrolling" then
        hl.dispatch(hl.dsp.layout("swapcol r"))
    elseif l == "master" then
        hl.dispatch(hl.dsp.layout("swapwithmaster master"))
    else
        hl.dispatch(hl.dsp.layout("swapsplit"))
    end
end)

hl.bind(mainMod .. " + SHIFT + RETURN", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("swapcol l"))
    end
end)

-- Pseudo / promote
hl.bind(mainMod .. " + P", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("promote"))
    else
        hl.dispatch(hl.dsp.window.pseudo())
    end
end)

hl.bind(mainMod .. " + SHIFT + P", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("togglefit"))
    end
end)

-- togglesplit (dwindle only)
hl.bind(mainMod .. " + Y", function()
    if layout() == "dwindle" then
        hl.dispatch(hl.dsp.layout("togglesplit"))
    end
end)

-- addmaster | consume_or_expel prev
hl.bind(mainMod .. " + I", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("consume_or_expel prev"))
    else
        hl.dispatch(hl.dsp.layout("addmaster"))
    end
end)

-- removemaster (master only)
hl.bind(mainMod .. " + SHIFT + I", function()
    if layout() == "master" then
        hl.dispatch(hl.dsp.layout("removemaster"))
    end
end)

-- consume_or_expel next (scrolling only)
hl.bind(mainMod .. " + O", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("consume_or_expel next"))
    end
end)

---------------------------------
-------- RESIZE -----------------
-- Works on floating windows and tiled windows in master/dwindle.
-- Hold the bind for continuous resizing.
---------------------------------

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

hl.bind("SUPER + Up", function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
end)

hl.bind(" + F11", function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
end)
---------------------------------
-------- SCROLLING COLUMNS ------
---------------------------------

hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + comma", hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("colresize +0.25"))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.layout("colresize -0.25"))

-- Toggle scroll direction
hl.bind(mainMod .. " + SHIFT + L", function()
    if layout() == "scrolling" then
        scroll_dir = scroll_dir == "right" and "down" or "right"
        hl.config({ scrolling = { direction = scroll_dir } })
    end
end)

---------------------------------
-------- WORKSPACES -------------
---------------------------------

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = false }))
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))

---------------------------------
-------- SPECIAL WORKSPACES -----
---------------------------------

hl.bind(mainMod .. " + CTRL + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

---------------------------------
-------- MOUSE ------------------
---------------------------------

hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
---------------------------------
-------- MEDIA / HARDWARE -------
---------------------------------

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true })
hl.bind("SHIFT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -n95 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -n95 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })