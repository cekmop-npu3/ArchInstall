#!/usr/bin/bash

source "$ROOT_DIR/scripts/utils/make_sourced.sh"

export ZSH="$HOME/.oh-my-zsh"
export MANPAGER="nvim -c 'Man!' -"

typeset -U path
path=(
    "$HOME/.cargo/bin"
    "$HOME/lua-language-server/bin"
    $path
)
export PATH

