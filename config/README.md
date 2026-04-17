# Create or delete symlinks from a JSON config file.

## Prerequisites

Export absolute path of a root directory:

```bash
source ./setup.sh
```

## Usage

Interactive mode:

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

## Config format

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
