# Installation scripts

This directory contains scripts for installing and configuring Arch Linux.

## Prerequisites

Run commands from Arch ISO unless stated otherwise.

- Booted into Arch ISO.
- Internet available.
- Target disk identified (for example `/dev/nvme0n1`).
- `installation_scripts` present on the live system.

<a id=INSTALL_DIR></a>Export script root:

```bash
export INSTALL_DIR="$(pwd -P)"
```

## Execution Sequence

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
./disk_formatting.sh -i
```

Non-interactive:

```bash
./disk_formatting.sh \
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
./install_dependencies.sh
```

### 3) Configure timezone, locale, hostname, vconsole

Interactive:

```bash
./system_configuration.sh -i
```

Non-interactive:

```bash
./system_configuration.sh \
  --timezone Europe/Minsk \
  --hostname arch-host
```

### 4) Create user and sudo access

Interactive:

```bash
./add_user.sh -i
```

Non-interactive:

```bash
./add_user.sh --username youruser --password -
```

If you pass `--password -`, export password first:

```bash
export PASSWORD='your_user_password'
```

### 5) Configure initramfs and GRUB

```bash
./boot_configuration.sh
```

### 6) Copy scripts into installed system user home

```bash
./self_deploy.sh --username youruser
```

## Post-Install (inside installed system)

There are scripts in `mnt_scripts/` intended for post-install tasks:

- `mnt_scripts/misc.sh`
- `mnt_scripts/symlinks.sh`

Before running `mnt_scripts/*`, set [INSTALL_DIR](#INSTALL_DIR).

### 1) Miscelaneous tasks

- Enable user/system services.
- Set shell profile snippets.
- Clone and build `lua-language-server`.

Run:

```bash
./misc.sh
```

### 2) Create or delete symlinks

Purpose:
- Create or delete symlinks from a config file with lines in format:
  `absolute_target absolute_link`

Interactive:

```bash
./symlinks.sh -i
```

Non-interactive create:

```bash
./symlinks.sh \
  --config-path /absolute/path/to/symlinks.conf \
  --action create
```

Non-interactive delete:

```bash
./symlinks.sh \
  --config-path /absolute/path/to/symlinks.conf \
  --action delete
```

