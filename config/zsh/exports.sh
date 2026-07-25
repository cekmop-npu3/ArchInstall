#!/usr/bin/bash

source "$ROOT_DIR/scripts/utils/make_sourced.sh"

export ZSH="$HOME/.oh-my-zsh"
export MANPAGER="nvim -c 'Man!' -"

typeset -U path
path=(
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.local/share/flatpak/exports/bin"
    "/var/lib/flatpak/exports/bin"
    "$HOME/lua-language-server/bin"
    $path
)
export PATH
