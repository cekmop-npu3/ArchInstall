# System scripts

This directory contains reusable provisioning and administration scripts. Some work both from an Arch live ISO against `/mnt` and from an already installed Arch system.

## Setup

From the repository root, initialize the shared environment first:

```bash
source ./setup.sh
```

Use each script's `--help` output for its complete options and exit codes.

## Commands

### `add_user.sh`

Creates a user, sets its password, adds it to the `wheel`, `video`, `render`, and `input` groups, and enables sudo access for `wheel` through `/etc/sudoers.d/10-wheel`.

```bash
./scripts/system/add_user.sh --interactive
```

When run from the live ISO it operates inside `/mnt` through `arch-chroot`. On an installed system it must be run with sufficient privileges.

### `install_packages.sh`

Installs packages supplied as operands or parsed from a manifest. In the live ISO it uses `pacstrap` against `/mnt`; on an installed system it uses `pacman` and `sudo` when needed.

```bash
./scripts/system/install_packages.sh git rsync
./scripts/system/install_packages.sh --file ./config/waybar/packages.txt
```

For installed-system operations that require sudo, the script reads the password from standard input:

```bash
./scripts/system/install_packages.sh git <<< "$PASSWORD"
```

Package files may contain whitespace-separated names and `#` comments. The `--delete` option removes packages from a manifest on an installed system; deletion is not supported through `pacstrap`.

### `mirrorlist.sh`

Installs `reflector` if necessary and generates a mirror list from recent HTTPS mirrors in the Netherlands, Germany, France, and Belgium, sorted by rate.

```bash
./scripts/system/mirrorlist.sh <<< "$PASSWORD"
```

From the live ISO it writes `/mnt/etc/pacman.d/mirrorlist`; otherwise it writes `/etc/pacman.d/mirrorlist` through sudo.

### `self_deploy.sh`

Copies the complete repository to a selected user's home using `rsync`, preserving ownership for that user. In the live environment the destination is beneath `/mnt`; on an installed system it is the user's normal home directory.

```bash
./scripts/system/self_deploy.sh --interactive
```

The default target user is `root`. Select the regular account created by `add_user.sh` if that account should own and use the repository.

## Typical live-ISO continuation

After the scripts in `scripts/install/` have created and configured `/mnt`:

```bash
./scripts/system/add_user.sh --interactive
./scripts/system/self_deploy.sh --interactive
```

After reboot, source `setup.sh` from the copied repository before running package or configuration commands.

