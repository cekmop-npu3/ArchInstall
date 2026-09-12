-- Hyprland 0.55+ configuration.  Files below are deliberately separate Lua
-- scopes: a failure in one does not prevent the remaining configuration loading.

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

require("variables")
require("permissions")
require("keybinds")

hl.on("hyprland.start", function()
    for _, command in ipairs({
        "waybar",
        "swaync",
        "alacritty",
        "hyprpaper",
        "copyq",
        "pypr",
        "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'",
    }) do
        hl.exec_cmd(command)
    end
end)
