# Configuration and dotfiles

This directory contains desktop and shell configuration, package manifests, and setup hooks. [`symlinks.json`](symlinks.json) is the deployment manifest; [`symlinks.sh`](symlinks.sh) creates or removes the links listed there.

## Deploy configuration

Run deployment from an installed Arch system, never from the live ISO:

```bash
cd /path/to/ArchInstall
source ./setup.sh
./config/symlinks.sh --interactive
```

Interactive mode asks for the manifest path, action, and sudo password. Use the repository manifest:

```text
/path/to/ArchInstall/config/symlinks.json
```

Select `create` to deploy the configuration or `delete` to remove it. The script installs `jq` if needed and runs an entry's setup hook after the selected link operation.

> Creation uses forced symbolic links and can replace an existing link at a managed path. Review the affected paths before deployment. The checkout must remain at the same path while its links are in use.

## Managed configuration

The default manifest deploys:

| Component | Destination |
| --- | --- |
| Alacritty | `~/.config/alacritty` |
| btop | `~/.config/btop` |
| CopyQ | `~/.config/copyq` |
| Hyprland | `~/.config/hypr` |
| Neovim | `~/.config/nvim` |
| Pyprland | `~/.config/pypr` |
| Rofi | `~/.config/rofi` |
| Rofi themes | `~/.local/share/rofi/themes` |
| SwayNC | `~/.config/swaync` |
| Waybar | `~/.config/waybar` |
| GTK 3 and GTK 4 | `~/.config/gtk-3.0`, `~/.config/gtk-4.0` |
| Git | `~/.gitconfig` |
| Zsh | `~/.zshrc`, `~/.zprofile` |
| Bash | `~/.bashrc`, `~/.bash_profile` |

Setup hooks install dependencies for Alacritty, btop, CopyQ, Hyprland, Neovim, Pyprland, Rofi, SwayNC, Waybar, and Zsh. The Neovim hook installs package dependencies, Bash Language Server, Pyrefly, NeoCMakeLSP, and local builds of Neovim and Lua Language Server. The Zsh hook installs Oh My Zsh and requests Zsh as the login shell.

## Directory convention

Components generally use this structure:

```text
config/<component>/
├── application files
├── packages.txt       # Optional pacman package manifest
└── setup.sh           # Optional create/delete hook
```

Setup hooks use [`scripts/utils/setup.sh`](../scripts/utils/setup.sh). They receive `--delete` during removal and read the sudo password from standard input when package operations need it.

## Add a component

1. Create `config/<component>/` and add the application files.
2. Add `packages.txt` when the component owns Arch packages.
3. Add an executable `setup.sh` when symlinking alone is insufficient.
4. Add an entry to the `symlinks` array in `symlinks.json`.

Each manifest entry uses absolute paths after shell expansion:

```json
{
  "target": "$ROOT_DIR/config/example",
  "link": "~/.config/example",
  "setup": "$ROOT_DIR/config/example/setup.sh"
}
```

`setup` is optional. The deployment script expands `$ROOT_DIR` and `~`, creates the link's parent directory, and verifies the target exists before creating a link.

## Remove deployed configuration

Run interactive deployment again and select `delete`:

```bash
./config/symlinks.sh --interactive
```

This unlinks manifest destinations and invokes configured hooks with `--delete`. Review package manifests before removal because hook cleanup can remove packages.
