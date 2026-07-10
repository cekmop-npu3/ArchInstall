# Installation scripts

These scripts perform the destructive and live-environment stages of an Arch Linux installation. They are intended to run from the Arch ISO, with the target system mounted at `/mnt`.

> `disk_formatting.sh` erases and repartitions the selected disk. Verify the device name and back up anything important before continuing.

## Files

| File | Purpose |
| --- | --- |
| `disk_formatting.sh` | Partitions, encrypts, formats, and mounts the target disk. |
| `system_configuration.sh` | Installs core packages and configures the target OS. |
| `boot_configuration.sh` | Generates mount and boot configuration and installs GRUB. |
| `packages.txt` | Base package manifest parsed by the system package installer. |

## Preparation

Clone or copy the repository into the live environment, change to its root, and source the initializer:

```bash
source ./setup.sh
```

This exports `ROOT_DIR` and makes the repository scripts executable. Every script in this directory expects that environment variable.

## Recommended order

### 1. Partition, format, and mount

The safest way to explore the available choices is interactive mode:

```bash
./scripts/install/disk_formatting.sh --interactive
```

The script supports:

- GPT or MBR partition tables
- A separate root and home filesystem, plus optional swap
- Optional LVM
- Optional LUKS encryption
- ext4 for root and home
- mounting the completed layout beneath `/mnt`

For automation, provide options directly:

```bash
./scripts/install/disk_formatting.sh \
  --disk /dev/nvme0n1 \
  --root 64 \
  --swap 8 \
  --partition GPT \
  --lvm \
  --luks -
```

When `--luks -` is used, the passphrase is read from the `PASSWORD` environment variable. Avoid placing secrets directly in shell history. Run `--help` for the authoritative option and exit-code list.

### 2. Install and configure the base system

```bash
./scripts/install/system_configuration.sh --interactive
```

This installs the packages listed in `packages.txt`, sets the timezone and hostname, generates the `en_US.UTF-8` and `ru_RU.UTF-8` locales, configures the console keymap and hosts file, and pins the LTS kernel packages in `pacman.conf`.

Non-interactive example:

```bash
./scripts/install/system_configuration.sh \
  --timezone Europe/Minsk \
  --hostname archbox
```

Review `packages.txt` first. It currently enables Intel CPU microcode; switch to `amd-ucode` when installing on an AMD system.

### 3. Configure boot

```bash
./scripts/install/boot_configuration.sh
```

This generates `/etc/fstab`, detects LUKS and LVM from the mounted root, installs GRUB dependencies, configures initramfs hooks, installs GRUB, and generates its configuration. GPT layouts use the EFI partition mounted at `/boot`; MBR layouts install GRUB to the disk.

### 4. Continue with system provisioning

Create a user and optionally copy this repository into the installed system:

```bash
./scripts/system/add_user.sh --interactive
./scripts/system/self_deploy.sh --interactive
```

See [../system/README.md](../system/README.md) for details.

