# Installation scripts

These scripts perform the destructive live-environment stages of an Arch Linux installation. Run them from an Arch ISO with the repository initialized by `source ./setup.sh`.

> `disk_formatting.sh` unmounts `/mnt`, wipes the selected disk's partition table, and recreates its filesystems. Confirm the disk path and back up all required data first.

## Files

| File | Purpose |
| --- | --- |
| `disk_formatting.sh` | Partitions, optionally encrypts, formats, and mounts the target disk. |
| `system_configuration.sh` | Installs the base package manifest and configures locale, time, hostname, and console settings. |
| `boot_configuration.sh` | Generates filesystem and boot configuration, then installs GRUB. |
| `packages.txt` | Package manifest installed into the target system. |

## Preparation

Clone or copy the repository into the live environment and source the initializer from the repository root:

```bash
source ./setup.sh
```

This exports `ROOT_DIR`, which every installer script requires, and marks project scripts executable.

## Installation order

### 1. Partition, format, and mount

Use interactive mode to choose the layout:

```bash
./scripts/install/disk_formatting.sh --interactive
```

The script creates a 1 GiB `/boot` partition first. GPT installations format it as FAT32 and assign `sfdisk` type `U` (EFI System Partition); MBR installations use an ext4 boot partition with the bootable flag. Root and home use ext4. The finished target is mounted below `/mnt`.

Supported choices include:

- GPT/UEFI or MBR/BIOS partition tables
- separate root and home filesystems, with optional swap
- LUKS encryption
- LVM, with or without LUKS

For a non-interactive layout, supply options directly:

```bash
./scripts/install/disk_formatting.sh \
  --disk /dev/nvme0n1 \
  --root 64 \
  --swap 8 \
  --partition GPT \
  --lvm \
  --luks -
```

With `--luks -`, the passphrase is read from the `PASSWORD` environment variable. Do not place passphrases in shell history. Use `--help` for the current option and exit-status reference.

### 2. Install and configure the base system

```bash
./scripts/install/system_configuration.sh --interactive
```

This installs `packages.txt`, sets the timezone and hostname, generates `en_US.UTF-8` and `ru_RU.UTF-8`, writes the US console keymap and hosts file, and pins the LTS kernel packages in `pacman.conf`.

Non-interactive use requires both settings:

```bash
./scripts/install/system_configuration.sh \
  --timezone Europe/Minsk \
  --hostname archbox
```

Review `packages.txt` before installation. It currently includes Intel microcode; replace it with `amd-ucode` for an AMD system.

### 3. Configure the bootloader

```bash
./scripts/install/boot_configuration.sh
```

The script generates `/etc/fstab`, detects the mounted root layout, installs needed GRUB, LVM, and LUKS packages, configures initramfs hooks, and generates GRUB configuration. GPT layouts install UEFI GRUB using the ESP mounted at `/boot`; MBR layouts install BIOS GRUB to the selected disk.

### 4. Create a user and copy the repository

```bash
./scripts/system/add_user.sh --interactive
./scripts/system/self_deploy.sh --interactive
```

Choose the new regular account in `self_deploy.sh` when the checkout should be owned by that account. See [../system/README.md](../system/README.md) for command details.
