local mod = "SUPER"

local function bind(keys, dispatcher, options)
    hl.bind(keys, dispatcher, options)
end

bind(mod .. " + T", hl.dsp.exec_cmd("alacritty"))
-- No release/click flag: both actions run as soon as the key is pressed.
bind(mod .. " + C", hl.dsp.window.close())
bind(mod .. " + SHIFT + C", hl.dsp.window.kill())
bind(mod .. " + F", hl.dsp.exec_cmd("rofi -show drun"))
bind(mod .. " + Q", hl.dsp.exec_cmd("hyprlock --config $HOME/.config/hypr/hyprlock.conf --quiet"))
bind(mod .. " + P", hl.dsp.exec_cmd("copyq toggle"))
bind(mod .. " + S", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
bind(mod .. " + SHIFT + S", hl.dsp.window.center())
bind(mod .. " + N", hl.dsp.exec_cmd("nautilus"))
bind(mod .. " + I", hl.dsp.exec_cmd("hyprpicker --autocopy"))
bind(mod .. " + B", hl.dsp.exec_cmd("alacritty -e btop"))
bind(mod .. " + W", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client --toggle-panel --skip-wait"))

local gromit = "flatpak run net.christianbeier.Gromit-MPX"
bind(mod .. " + D", hl.dsp.exec_cmd("pgrep -x gromit-mpx >/dev/null && " .. gromit .. " -q || " .. gromit .. " --active --opacity 1.0"))
bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd(gromit .. " -c"))
bind(mod .. " + CTRL + D", hl.dsp.exec_cmd(gromit .. " -z"))

bind("PRINT", hl.dsp.exec_cmd("sh -c 'hyprshot -m output --raw | satty --filename - --fullscreen --initial-tool brush --copy-command wl-copy'"))
bind(mod .. " + PRINT", hl.dsp.exec_cmd("sh -c 'hyprshot -m region --raw | satty --filename - --fullscreen --initial-tool brush --copy-command wl-copy'"))

for key, direction in pairs({ h = "l", l = "r", k = "u", j = "d" }) do
    bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

bind(mod .. " + EQUAL", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
bind(mod .. " + SHIFT + EQUAL", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
bind(mod .. " + MINUS", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
bind(mod .. " + SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })

bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mod .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })
bind(mod .. " + mouse_up", hl.dsp.exec_cmd("pypr zoom --1"), { locked = true })
bind(mod .. " + mouse_down", hl.dsp.exec_cmd("pypr zoom ++1"), { locked = true })
bind(mod .. " + Z", hl.dsp.exec_cmd("pypr zoom"))

for workspace = 1, 10 do
    local key = workspace % 10
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

local repeating_locked = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), repeating_locked)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), repeating_locked)
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), repeating_locked)
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), repeating_locked)
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), repeating_locked)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), repeating_locked)
