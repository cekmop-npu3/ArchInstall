# ArchInstall

ArchInstall is a collection of Bash scripts and personal configuration files for installing and configuring an Arch Linux system. It supports GPT/UEFI and MBR installations, optional LVM and LUKS, base-system provisioning, user creation, package management, and deployment of desktop dotfiles.


## Repository layout

```text
.
├── setup.sh                 # Initializes ROOT_DIR and script permissions
├── scripts/
│   ├── install/             # Live-ISO disk and base-system installation
│   ├── system/              # Reusable system administration commands
│   └── utils/               # Shared option parsing and helper functions
└── config/                  # Dotfiles, package manifests, and setup hooks
```

- [Installation scripts](scripts/install/README.md)
- [System scripts](scripts/system/README.md)
- [Configuration and dotfiles](config/README.md)

## Requirements

- An Arch Linux live environment for a fresh installation
- Bash, an internet connection, and root privileges
- A checked-out copy of this repository
- Familiarity with Arch installation and recovery procedures

The scripts assume the target system is mounted at `/mnt`. Package installation uses official Arch tools such as `pacstrap` and `pacman`.

## Initialize the environment

Run all commands from the repository root. `setup.sh` must be sourced so that its exported `ROOT_DIR` remains available to the other scripts:

```bash
source ./setup.sh
```

To inspect any command before using it:

```bash
./scripts/install/disk_formatting.sh --help
./scripts/system/install_packages.sh --help
```

## Fresh-install outline

From an Arch live ISO, a typical interactive sequence is:

```bash
source ./setup.sh
./scripts/install/disk_formatting.sh --interactive
./scripts/install/system_configuration.sh --interactive
./scripts/install/boot_configuration.sh
./scripts/system/add_user.sh --interactive
./scripts/system/self_deploy.sh --interactive
```

Review [scripts/install/README.md](scripts/install/README.md) before executing this sequence. In particular, `disk_formatting.sh` unmounts `/mnt`, repartitions the selected disk, creates filesystems, and mounts the new system.

After booting into the installed system, initialize the repository again and deploy the desired configuration links:

```bash
cd ~/ArchInstall
source ./setup.sh
./config/symlinks.sh --interactive
```

See [config/README.md](config/README.md) for the managed paths and setup-hook behavior.

