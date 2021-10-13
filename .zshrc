# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

if [ "$TMUX" = "" ]; then 
    tmux;
fi

# plugins=()

# Path to your oh-my-zsh installation.
export ZSH="/Users/jose.cabeda/.oh-my-zsh"
export EDITOR="vi"
export TERM=xterm-256color;
export LC_CTYPE="en_US.UTF-8"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="avit"
DISABLE_UPDATE_PROMPT="true"
ENABLE_CORRECTION="true"

export LANG=en_US.UTF-8

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /Users/jose.cabeda/.config/broot/launcher/bash/br
source ~/env # Script that holds alias and tokens
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Make sure pyenv version is used
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

eval "$(starship init zsh)"

# CONFIG Zoxide
function z() {
    __zoxide_z "$@"
}

eval "$(zoxide init zsh)"

# Auto complete pipx
# eval "$(register-python-argcomplete pipx)"

export DYLD_FALLBACK_LIBRARY_PATH=/usr/local/opt/openssl/lib:$DYLD_LIBRARY_PATH


export PATH="$HOME/.npm-packages/bin:$PATH"

################ Global Mac ALIAS ################
alias start="bash $(dirname $(readlink ${(%):-%N}))/start.sh"
alias write="bash $(dirname $(readlink ${(%):-%N}))/write.sh"

alias dkill='docker stop $(docker ps -qa) && docker volume prune && docker image prune && docker rm -f $(docker ps -aq) && docker system prune'


alias gp="git pull"
alias sp="speedtest"
alias dcd="docker compose down"
alias cb="open -a firefox https://www.gocomics.com/random/calvinandhobbes"
alias cql="~/Documents/cqlsh-astra/bin/cqlsh"
alias trino="~/Documents/trino-cli-358-executable.jar"
alias presto="~/Documents/presto-cli-350-executable.jar"
alias python=python3
alias pip=pip3
alias todo="vim ~/Documents/git/pensamentos/To-Do.md"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"


bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# Allow autocompletition (i.e git)
# autoload -Uz compinit && compinit
# unsetopt nomatch

# GIT functions

function gac() {
  git add -p 
  git commit
}
# - - - - - -
# - DOCKER  -
# - - - - - -
function docker-selector-containers() {
  docker ps -a --format="{{.ID}}\t\t{{.Names}}" | \
    fzf -0 -1 --delimiter="\t" --with-nth="-1" | \
    cut -f1
}
function docker-selector-running-containers() {
  docker ps --format="{{.ID}}\t\t{{.Names}}" | \
    fzf -0 -1 --delimiter="\t" --with-nth="-1" | \
    cut -f1
}
function docker-selector-images() {
  docker images --format="{{.ID}}\t\t{{.Repository}}" | \
    fzf -0 -1 --delimiter="\t" --with-nth="-1" | \
    cut -f1
}
function din() {
  docker exec -it $(docker-selector-containers) bash
}
function dlogs() {
  docker logs -f $(docker-selector-running-containers)
}
function dip() {
  docker inspect --format '{{ .NetworkSettings.IPAddress }}' $(docker-selector-containers)
}
function dre() {
  docker restart $(docker-selector-containers)
}
function drm() {
  docker rm $(docker-selector-containers)
}
function drma() {
  docker rm $(docker ps -a | grep Exit | cut -d ' ' -f 1)
}
function drmi() {
  docker rmi -f $(docker-selector-images)
}
function dsp() {
  docker stop $(docker-selector-running-containers)
}
function dspa() {
  docker stop $(docker ps -a | grep Up | cut -d ' ' -f 1)
}

function steal() {
  git checkout staging
  git pull
  git reset --hard $(git branch --format='%(refname:short)' | fzf)
  git push -f origin staging
}

function teststg() {
  git checkout staging
  git pull
  branch=$(git branch --format='%(refname:short)' | fzf)
  git pull origin $branch
  git push
  git checkout $branch
}

if [ -d "$HOME/adb-fastboot/platform-tools" ] ; then
 export PATH="$HOME/platform-tools:$PATH"
fi

# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
# export SDKMAN_DIR="/Users/jose.cabeda/.sdkman"
# [[ -s "/Users/jose.cabeda/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/jose.cabeda/.sdkman/bin/sdkman-init.sh"

zstyle ':completion:*' menu select
fpath+=~/.zfunc

eval export PATH="/Users/jose.cabeda/.jenv/shims:${PATH}"
export JENV_SHELL=zsh
export JENV_LOADED=1
unset JAVA_HOME
source '/usr/local/Cellar/jenv/0.5.4/libexec/libexec/../completions/jenv.zsh'
jenv rehash 2>/dev/null
jenv refresh-plugins
jenv() {
  typeset command
  command="$1"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
  enable-plugin|rehash|shell|shell-options)
    eval `jenv "sh-$command" "$@"`;;
  *)
    command jenv "$command" "$@";;
  esac
}
