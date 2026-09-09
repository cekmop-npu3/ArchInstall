# ArchInstall

ArchInstall is a personal Arch Linux installation and workstation-configuration repository. It provides Bash scripts for partitioning and provisioning a fresh system, then deploys the configuration stored in this checkout through symbolic links.

The installer supports GPT/UEFI and MBR/BIOS layouts, optional LUKS and LVM, separate root and home filesystems, optional swap, GRUB, package installation, user creation, and desktop configuration deployment.

## Repository layout

```text
.
├── setup.sh                 # Exports ROOT_DIR and marks project scripts executable
├── scripts/
│   ├── install/             # Live-ISO installation stages
│   ├── system/              # Provisioning and administration commands
│   └── utils/               # Shared Bash helpers
├── config/                  # Dotfiles, package lists, and deployment hooks
├── ventoy/                  # Live-ISO injection files
└── .github/workflows/       # Tagged-release build and publishing workflow
```

- [Installation scripts](scripts/install/README.md)
- [System scripts](scripts/system/README.md)
- [Configuration deployment](config/README.md)

## Requirements

For a fresh installation, use an Arch Linux live environment, work as root, and have an internet connection. Clone this repository or otherwise copy it into that environment before running the scripts.

The scripts use `/mnt` as the target filesystem and call Arch tools such as `pacstrap`, `arch-chroot`, `mkinitcpio`, and `grub-install`. Read the script help before supplying non-interactive options:

```bash
source ./setup.sh
./scripts/install/disk_formatting.sh --help
./scripts/system/install_packages.sh --help
```

`setup.sh` must be sourced, not executed, so that `ROOT_DIR` remains available to the other scripts.

## Fresh-install workflow

Run these commands from the repository root in the live environment:

```bash
source ./setup.sh
./scripts/install/disk_formatting.sh --interactive
./scripts/install/system_configuration.sh --interactive
./scripts/install/boot_configuration.sh
./scripts/system/add_user.sh --interactive
./scripts/system/self_deploy.sh --interactive
```

`disk_formatting.sh` unmounts `/mnt`, destroys existing partition data on the selected disk, and creates the target layout. Verify the device name and back up data before starting. The detailed order, supported layouts, and boot behavior are documented in [scripts/install/README.md](scripts/install/README.md).

After booting the installed system, source `setup.sh` from the copied checkout and deploy the desired configuration:

```bash
cd ~/ArchInstall
source ./setup.sh
./config/symlinks.sh --interactive
```

## Release and Ventoy artifacts

Pushing a tag that begins with `v` runs the release workflow. It builds a current Arch Linux ISO with `git` included, packages the live-environment injection, and publishes these assets:

| Asset | Purpose |
| --- | --- |
| `arch_linux.iso` | Bootable Arch Linux ISO. |
| `arch_linux.iso.sha256` | SHA-256 checksum for the ISO. |
| `live_injection.tar.gz` | Ventoy LiveInjection archive containing the live-environment additions. |
| `ventoy.json` | Ventoy configuration that associates the ISO with the injection archive. |

Verify the ISO before use:

```bash
sha256sum -c arch_linux.iso.sha256
```

To use the release with Ventoy, copy `arch_linux.iso`, `live_injection.tar.gz`, and `ventoy.json` to the root of the Ventoy data partition. The configuration refers to `/arch_linux.iso` and `/live_injection.tar.gz`, so those filenames and locations must remain unchanged.

The workflow publishes the ISO directly because Ventoy boots it directly. GitHub allows release assets smaller than 2 GiB; the workflow checks this limit before publishing and disables redundant artifact compression for the already-compressed ISO.

The workflow caches the completed ISO. A push to `main` creates the cache when it is missing; later pushes reuse it. Tag releases can reuse the cache from `main` and only rebuild when it has expired or is otherwise unavailable. GitHub removes caches that have not been accessed for seven days.
