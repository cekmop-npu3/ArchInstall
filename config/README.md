# Configuration and dotfiles

This directory stores application configuration, package manifests, and setup hooks. `symlinks.json` is the deployment manifest, and `symlinks.sh` creates or deletes the corresponding links in the current user's home directory.

## Deploy configuration

Run deployment from an installed Arch system, not the live ISO:

```bash
cd /path/to/ArchInstall
source ./setup.sh
./config/symlinks.sh --interactive
```

Interactive mode prompts for the manifest path, action, and sudo password. Use the repository manifest when prompted:

```text
/path/to/ArchInstall/config/symlinks.json
```

Choose `create` to deploy links or `delete` to remove them. The script installs `jq` when it is missing and invokes an entry's setup hook after creating or deleting its link.

> The deployed files remain inside this repository. Moving or deleting the checkout will break the symbolic links.

## Managed configuration

The default manifest deploys:

| Component | Destination |
| --- | --- |
| Alacritty | `~/.config/alacritty` |
| CopyQ | `~/.config/copyq` |
| Hyprland | `~/.config/hypr` |
| Neovim | `~/.config/nvim` |
| Waybar | `~/.config/waybar` |
| Rofi | `~/.config/rofi` |
| Rofi themes | `~/.local/share/rofi/themes` |
| btop | `~/.config/btop` |
| GTK 3 and GTK 4 | `~/.config/gtk-3.0`, `~/.config/gtk-4.0` |
| Zsh | `~/.zshrc`, `~/.zprofile` |
| Bash | `~/.bashrc`, `~/.bash_profile` |

The setup hooks for Alacritty, btop, CopyQ, Hyprland, Neovim, Rofi, Waybar, and Zsh install their associated packages. Neovim's hook additionally builds development versions of Neovim and Lua Language Server and installs Bash Language Server. Zsh's hook changes the login shell and installs Oh My Zsh.

## Directory convention

A component generally has this shape:

```text
config/<component>/
├── application files
├── packages.txt       # Optional pacman package manifest
└── setup.sh           # Optional install/delete hook
```

Setup hooks share the behavior implemented by `scripts/utils/setup.sh`. They accept `--delete`, read a sudo password from standard input, and call the system package helper as needed.

## Add a component

1. Create `config/<component>/` and place the application's configuration inside it.
2. Add `packages.txt` if packages should be managed with the component.
3. Add an executable `setup.sh` only when symlinking alone is insufficient.
4. Add an object to the `symlinks` array in `symlinks.json`.

Each manifest object requires absolute paths after shell expansion:

```json
{
  "target": "$ROOT_DIR/config/example",
  "link": "~/.config/example",
  "setup": "$ROOT_DIR/config/example/setup.sh"
}
```

Omit `setup` when no hook is needed. The deployment script expands `$ROOT_DIR` and `~`, creates the link's parent directory, and uses a forced symbolic link for creation.

## Remove deployed configuration

Run the interactive command and select `delete`:

```bash
./config/symlinks.sh --interactive
```

Deletion unlinks paths listed in the manifest and calls each setup hook with `--delete`. Review the affected package manifests first, because hook cleanup may remove installed packages. Application-generated or sensitive state should be ignored in the component's `.gitignore` rather than committed.
