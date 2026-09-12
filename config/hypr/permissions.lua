-- Permission rules are intentionally explicit. Hyprland applies changes to
-- these only after a compositor restart, for security reasons.
for _, binary in ipairs({
    "/usr/local/bin/hyprshot",
    "/usr/bin/grim",
    "/usr/bin/hyprlock",
    "/usr/bin/hyprpicker",
}) do
    hl.permission({ binary = binary, type = "screencopy", mode = "allow" })
end
