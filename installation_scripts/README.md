# Installation scripts

This directory contains scripts for installing and configuring Arch Linux.

## Prerequisites

<a id=INSTALL_DIR></a>Export absolute path of a root directory:

```bash
source ./setup.sh
```

## Execution Sequence

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

### 2) Update pacman mirrorlist and install packages

```bash
./install_dependencies.sh --file packages.txt
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

## Inside mounted system

There are scripts in `mnt_scripts/` intended for post-install tasks:

- `mnt_scripts/misc.sh`
- `mnt_scripts/symlinks.sh`

Change root into the mounted system and switch to your user:

```bash
arch-chroot /mnt
su - youruser
```

Before running `mnt_scripts/*`, set [INSTALL_DIR](#INSTALL_DIR).

### 1) Miscelaneous tasks

- Set shell profile snippets.
- Clone and build `lua-language-server`.

Run:

```bash
./misc.sh
```

### 2) Create or delete symlinks

Purpose:
- Create or delete symlinks from a JSON config file.
- Example config: `mnt_scripts/symlinks.example.json`

Interactive:

```bash
./symlinks.sh -i
```

Non-interactive create:

```bash
./symlinks.sh \
  --config-path path/to/symlinks.json \
  --action create
```

Non-interactive delete:

```bash
./symlinks.sh \
  --config-path path/to/symlinks.json \
  --action delete
```

Config format (`JSON`):

```json
{
  "symlinks": [
    {
      "target": "/home/youruser/.dotfiles/nvim",
      "link": "/home/youruser/.config/nvim"
    },
    {
      "target": "/home/youruser/.dotfiles/alacritty.toml",
      "link": "/home/youruser/.config/alacritty/alacritty.toml",
      "force": true
    }
  ]
}
```
