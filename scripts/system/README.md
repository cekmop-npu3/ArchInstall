# System scripts

These commands provision a mounted installation from the live ISO or manage an already-installed Arch system. Initialize the repository first:

```bash
source ./setup.sh
```

Each command provides its complete arguments and exit codes through `--help`.

## Commands

### `add_user.sh`

Creates a user, sets its password, adds it to `wheel`, `video`, `render`, and `input`, and enables password-based sudo access for the `wheel` group.

```bash
./scripts/system/add_user.sh --interactive
```

From the live ISO, the account is created inside `/mnt` through `arch-chroot`. On an installed system, run it with sufficient privileges.

### `install_packages.sh`

Installs package operands or package names from a manifest:

```bash
./scripts/system/install_packages.sh git rsync
./scripts/system/install_packages.sh --file ./config/waybar/packages.txt
```

In the live ISO, it uses `pacstrap` against `/mnt`; on an installed system, it runs `pacman` and reads a sudo password from standard input when required:

```bash
./scripts/system/install_packages.sh git <<< "$PASSWORD"
```

Package manifests accept whitespace-separated package names and `#` comments. `--delete` is available only on an installed system.

### `mirrorlist.sh`

Installs `reflector` when needed and writes a mirror list using recent HTTPS mirrors from the Netherlands, Germany, France, and Belgium, sorted by rate.

```bash
./scripts/system/mirrorlist.sh <<< "$PASSWORD"
```

In the live environment it writes `/mnt/etc/pacman.d/mirrorlist`; otherwise it writes `/etc/pacman.d/mirrorlist` through sudo.

### `self_deploy.sh`

Copies the complete repository with `rsync` into a selected account's home directory and applies that account's ownership. The default account is `root`.

```bash
./scripts/system/self_deploy.sh --interactive
```

From the live ISO, the destination is below `/mnt`; on an installed system it is the selected account's normal home directory. Use the regular account created by `add_user.sh` when it should own and deploy the dotfiles.

## Typical live-ISO continuation

After `scripts/install/` has mounted and configured `/mnt`:

```bash
./scripts/system/add_user.sh --interactive
./scripts/system/self_deploy.sh --interactive
```

After reboot, source `setup.sh` from the copied checkout before running system or configuration commands.
