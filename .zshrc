# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

if [ "$TMUX" = "" ]; then 
    tmux;
fi

# Path to your oh-my-zsh installation.
export ZSH="/Users/jose.cabeda/.oh-my-zsh"

export LC_CTYPE="en_US.UTF-8"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="avit"

DISABLE_UPDATE_PROMPT="true"
ENABLE_CORRECTION="true"

# plugins=(zsh-autosuggestions)

export LANG=en_US.UTF-8


# Script that holds alias and tokens
source ~/env.sh

alias python=python3
alias pip=pip3

# Make sure pyenv version is used
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

export DYLD_FALLBACK_LIBRARY_PATH=/usr/local/opt/openssl/lib:$DYLD_LIBRARY_PATH


export PATH="$HOME/.npm-packages/bin:$PATH"

################ Global Mac ALIAS ################
alias start="bash $(dirname $(readlink ${(%):-%N}))/start.sh"

alias dkill='docker stop $(docker ps -qa) && docker volume prune && docker image prune && docker rm -f $(docker ps -aq) && docker system prune'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias presto="~/Documents/presto-cli-332-executable.jar"

alias gn="git commit --no-verify"

alias sp="speedtest"

export GPG_TTY=$(tty)

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

eval "$(starship init zsh)"

# Init z command
. $(brew --prefix)/etc/profile.d/z.sh

bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# Allow autocompletition (i.e git)
autoload -Uz compinit && compinit

unsetopt nomatch