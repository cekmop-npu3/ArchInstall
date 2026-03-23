# installation_scripts

This directory contains scripts for installing and configuring Arch Linux.

## Prerequisites

Run commands from Arch ISO unless stated otherwise.

- Booted into Arch ISO.
- Internet available.
- Target disk identified (for example `/dev/nvme0n1`).
- `installation_scripts` present on the live system.

Export script root once:

```bash
export INSTALL_DIR="$(pwd -P)"
```

Run this command inside the `installation_scripts` directory.

## Execution Sequence (Arch ISO phase)

Run scripts in this order:

1. `archiso_scripts/disk_formatting.sh`
2. `archiso_scripts/install_dependencies.sh`
3. `archiso_scripts/system_configuration.sh`
4. `archiso_scripts/add_user.sh`
5. `archiso_scripts/boot_configuration.sh`
6. `archiso_scripts/self_deploy.sh`

### 1) Partition, encrypt/LVM, and mount

Interactive:

```bash
bash archiso_scripts/disk_formatting.sh -i
```

Non-interactive example:

```bash
bash archiso_scripts/disk_formatting.sh \
  --disk /dev/nvme0n1 \
  --root 80 \
  --swap 16 \
  --partition GPT \
  --lvm \
  --luks -
```

If you pass `--luks -`, export password first:

```bash
export PASSWORD='your_luks_password'
```

### 2) Install base and desktop packages

```bash
bash archiso_scripts/install_dependencies.sh
```

### 3) Configure timezone, locale, hostname, vconsole

Interactive:

```bash
bash archiso_scripts/system_configuration.sh -i
```

Non-interactive example:

```bash
bash archiso_scripts/system_configuration.sh \
  --timezone Europe/Minsk \
  --hostname arch-host
```

### 4) Create user and sudo access

Interactive:

```bash
bash archiso_scripts/add_user.sh -i
```

Non-interactive example:

```bash
bash archiso_scripts/add_user.sh --username youruser --password -
```

If you pass `--password -`, export password first:

```bash
export PASSWORD='your_user_password'
```

### 5) Configure initramfs and GRUB

```bash
bash archiso_scripts/boot_configuration.sh
```

### 6) Copy scripts into installed system user home

```bash
bash archiso_scripts/self_deploy.sh --username youruser
```

## Optional Post-Install (inside installed system)

There are scripts in `mnt_scripts/` intended for post-install tasks:

- `mnt_scripts/misc.sh`
- `mnt_scripts/symlinks.sh`

