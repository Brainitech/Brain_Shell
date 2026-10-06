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

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal), { description = "Launch Terminal" })
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close(), { description = "Close Window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit(), { description = "Exit Hyprland" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Launch File Manager (CLI)" })
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating" })
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(brcmd), { description = "Launch Browser" })

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
end, { description = "Fit Active Window" })

hl.bind(mainMod .. " + J", function()
    local l = layout()
    if l == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit visible"))
    elseif l == "monocle" or l == "master" then
        hl.dispatch(hl.dsp.layout("cycleprev"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "d" }))
    end
end, { description = "Fit Visible Windows" })

hl.bind(mainMod .. " + K", function()
    local l = layout()
    if l == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit tobeg"))
    elseif l == "monocle" or l == "master" then
        hl.dispatch(hl.dsp.layout("cyclenext"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "u" }))
    end
end, { description = "Fit to Beginning" })

hl.bind(mainMod .. " + SHIFT + K", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit toend"))
    end
end, { description = "Fit to End" })

hl.bind(mainMod .. " + L", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("fit all"))
    else
        hl.dispatch(hl.dsp.focus({ direction = "r" }))
    end
end, { description = "Fit All Windows" })

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
end, { description = "Swap Column Right" })

hl.bind(mainMod .. " + SHIFT + RETURN", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("swapcol l"))
    end
end, { description = "Swap Column Left" })

-- Pseudo / promote
hl.bind(mainMod .. " + P", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("promote"))
    else
        hl.dispatch(hl.dsp.window.pseudo())
    end
end, { description = "Promote Window" })

hl.bind(mainMod .. " + SHIFT + P", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("togglefit"))
    end
end, { description = "Toggle Fit" })

-- togglesplit (dwindle only)
hl.bind(mainMod .. " + Y", function()
    if layout() == "dwindle" then
        hl.dispatch(hl.dsp.layout("togglesplit"))
    end
end, { description = "Toggle Split" })

-- addmaster | consume_or_expel prev
hl.bind(mainMod .. " + I", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("consume_or_expel prev"))
    else
        hl.dispatch(hl.dsp.layout("addmaster"))
    end
end, { description = "Consume/Expel Previous" })

-- removemaster (master only)
hl.bind(mainMod .. " + SHIFT + I", function()
    if layout() == "master" then
        hl.dispatch(hl.dsp.layout("removemaster"))
    end
end, { description = "Remove Master" })

-- consume_or_expel next (scrolling only)
hl.bind(mainMod .. " + O", function()
    if layout() == "scrolling" then
        hl.dispatch(hl.dsp.layout("consume_or_expel next"))
    end
end, { description = "Consume/Expel Next" })

---------------------------------
-------- RESIZE -----------------
-- Works on floating windows and tiled windows in master/dwindle.
-- Hold the bind for continuous resizing.
---------------------------------

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { description = "Resize Left", repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { description = "Resize Right", repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { description = "Resize Up", repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { description = "Resize Down", repeating = true })

hl.bind("SUPER + Up", function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
end, { description = "Toggle Maximized" })

hl.bind(" + F11", function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
end, { description = "Toggle Fullscreen" })
---------------------------------
-------- SCROLLING COLUMNS ------
---------------------------------

hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"), { description = "Move Column Right" })
hl.bind(mainMod .. " + comma", hl.dsp.layout("move -col"), { description = "Move Column Left" })
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("colresize +0.25"), { description = "Increase Column Width" })
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.layout("colresize -0.25"), { description = "Decrease Column Width" })

-- Toggle scroll direction
hl.bind(mainMod .. " + SHIFT + L", function()
    if layout() == "scrolling" then
        scroll_dir = scroll_dir == "right" and "down" or "right"
        hl.config({ scrolling = { direction = scroll_dir } })
    end
end, { description = "Toggle Scroll Direction" })

---------------------------------
-------- WORKSPACES -------------
---------------------------------

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Focus Workspace" })
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }), { description = "Move Window to Workspace" })
end

hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }), { description = "Focus Workspace 10" })
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = false }), { description = "Move Window to Workspace 10" })
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "Focus Previous Workspace" })

---------------------------------
-------- SPECIAL WORKSPACES -----
---------------------------------

hl.bind(mainMod .. " + CTRL + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle Special Workspace (Magic)" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }), { description = "Move Window to Special Workspace (Magic)" })

---------------------------------
-------- MOUSE ------------------
---------------------------------

hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e+1" }), { description = "Focus Next Workspace (Mouse)" })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }), { description = "Focus Previous Workspace (Mouse)" })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { description = "Drag Window", mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { description = "Resize Window (Mouse)", mouse = true })
---------------------------------
-------- MEDIA / HARDWARE -------
---------------------------------

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { description = "Increase Volume", locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { description = "Decrease Volume", locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Mute Volume", locked = true, repeating = true })
hl.bind("SHIFT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -n95 set 5%+"), { description = "Brightness Up", locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -n95 set 5%-"), { description = "Brightness Down", locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { description = "Media Next", locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Media Play/Pause", locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Media Play/Pause", locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { description = "Media Previous", locked = true })