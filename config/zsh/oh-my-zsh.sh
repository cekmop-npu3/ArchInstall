#!/usr/bin/bash

source "$ROOT_DIR/scripts/utils/make_sourced.sh"

ZSH_THEME="awesomepanda"

VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true

plugins=(git vi-mode)

source "$ZSH/oh-my-zsh.sh"

