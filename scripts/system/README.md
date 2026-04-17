# Inside installed system

There are scripts in `system/` intended for post-install tasks:

- `mnt_scripts/misc.sh`
- `mnt_scripts/symlinks.sh`

## Prerequisites 

Before running any `system/*`, run
```bash
source ./setup.sh
```

### 1) Miscelaneous tasks

- Set shell profile snippets.
- Clone and build `lua-language-server`.

Run:

```bash
./misc.sh
```

## After installation (Inside installed system)

After a successful installation you may want to enable some of the following services:

```bash
systemctl --user enable pipewire wireplumber --now
sudo systemctl enable NetworkManager bluetooth --now
```

