# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_CUSTOM="$HOME/oh-my-zsh-custom"
ZSH_THEME="socrates"
CASE_SENSITIVE="true"
ENABLE_CORRECTION="false"
HIST_STAMPS="dd/mm/yyyy"
COMPLETION_WAITING_DOTS="true"

plugins=(git python virtualenv-prompt virtualenvwrapper pip fabric debian themes)

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.cask/bin"
export SSH_KEY_PATH="~/.ssh/id_rsa"

source ~/.profile
source "$ZSH/oh-my-zsh.sh"
source "$VENV_WRAPPER"

setxkbmap -layout us -option ctrl:nocaps
