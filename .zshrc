# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

if [ "$TMUX" = "" ]; then 
    tmux;
fi

plugins=(web-search)

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

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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
alias write="bash $(dirname $(readlink ${(%):-%N}))/write.sh"

alias dkill='docker stop $(docker ps -qa) && docker volume prune && docker image prune && docker rm -f $(docker ps -aq) && docker system prune'

alias kci="open $(basename "$PWD" | awk '{print "https://kci.talkdeskapp.com/blue/organizations/jenkins/talkdesk%2F"$1"/activity"}')"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias gn="git commit --no-verify"

alias sp="speedtest"

alias dcd="docker compose down"

alias cb="open -a firefox https://www.gocomics.com/random/calvinandhobbes"

alias cql="~/Documents/cqlsh-astra/bin/cqlsh"
alias trino="~/Documents/trino-cli-354-executable.jar"
alias presto="~/Documents/presto-cli-350-executable.jar"


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

if [ -d "$HOME/adb-fastboot/platform-tools" ] ; then
 export PATH="$HOME/platform-tools:$PATH"
fi
export PATH="~/.deta/bin:$PATH"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/jose.cabeda/.sdkman"
[[ -s "/Users/jose.cabeda/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/jose.cabeda/.sdkman/bin/sdkman-init.sh"

