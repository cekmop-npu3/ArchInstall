export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="awesomepanda"

VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true

plugins=(git vi-mode)

source $ZSH/oh-my-zsh.sh

export MANPAGER="nvim -c 'Man!' -"
export PATH=$PATH:~/lua-language-server/bin
export ROOT_DIR="$HOME/ArchInstall"
export PATH="$HOME/.cargo/bin:$PATH"

# >>> Codex installer >>>
export PATH="/home/cekmop-npu3/.local/bin:$PATH"
# <<< Codex installer <<<
