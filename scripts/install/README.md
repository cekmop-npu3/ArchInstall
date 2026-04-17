# Installation scripts

This directory contains scripts to install Arch Linux.

## Prerequisites

Export absolute path of a root directory:

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

### 2) Install packages

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

### 4) Configure initramfs and GRUB

```bash
./boot_configuration.sh
```

### 5) Copy scripts into installed system user home

Before copying the scripts, you may want to create your user, otherwise they will be copied to root account.
See /system directory

```bash
./self_deploy.sh --username youruser
```

