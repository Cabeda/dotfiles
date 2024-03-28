# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

plugins=()

# EXPORT configs
export TERM=xterm-256color
export LC_CTYPE="en_US.UTF-8"
export LANG=en_US.UTF-8
export TT_LOG_FOLDER=$HOME/Git/pensamentos/Journal/2021
export ZSH_THEME="avit"
export DISABLE_UPDATE_PROMPT="true"
export ENABLE_CORRECTION="true"
export MCFLY_FUZZY=2
export LDFLAGS="-L $(xcrun --show-sdk-path)/usr/lib -L brew --prefix bzip2/lib"
export CFLAGS="-L $(xcrun --show-sdk-path)/usr/include -L brew --prefix bzip2/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig"
export PATH=/opt/homebrew/bin:$PATH
export PATH="/usr/local/sbin:$PATH"
export PATH="/Users/jose.cabeda/.deno/bin:$PATH"

# Run commands specific to shell
if [[ "$OSTYPE" == "darwin"* ]]; then

  export ZSH="/Users/jose.cabeda/.oh-my-zsh"
  # source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

elif [[ "$OSTYPE" == "linux-android" ]]; then
  echo $OSTYPE
else
  echo "Unsupported shell"
fi

source ~/env # Script that holds alias and tokens
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(starship init zsh)"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/maid_ed25519

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
alias start="bash $HOME/Git/dotfiles/scripts/start.sh"
alias write="bash $HOME/Git/dotfiles/scripts/write.sh"

alias dkill='docker stop $(docker ps -qa) && docker volume prune && docker image prune && docker rm -f $(docker ps -aq) && docker system prune'

alias gp="git pull"
alias gs="git pull && git push"
alias sp="speedtest"
alias dcd="docker compose down"
alias cb="open https://www.gocomics.com/random/calvinandhobbes"
alias cql="~/cqlsh-astra/bin/cqlsh"
alias trino="~/trino-cli-363-executable.jar"
alias presto="~/presto-cli-350-executable.jar"
alias todo="vim ~/git/pensamentos/To-Do.md"
alias kafkacat=kcat
alias ip="curl ifconfig.me"
alias k="kubectl"
alias tf="terraform"
alias caws="code ~/.aws/credentials"
alias rc="code ~/.zshrc"
alias lofi="mpv https://www.youtube.com/live/jfKfPfyJRdk --no-video"
alias synth="mpv https://www.youtube.com/live/4xDzrJKXOOY --no-video"
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# GIT functions

function gac() {
  git add -p
  git commit
}

function gacq() {
  git add -p
  git commit -m "Auto Update"
}

function gsw() {
  git checkout -t $(git branch -r | fzf)
}

function glt() {
  git pull
  git describe --tags --abbrev=0
}

function gdp() {
  git pull
  main=$(basename $(git symbolic-ref --short refs/remotes/origin/HEAD))
  release=$(git describe --tags --abbrev=0)
  git log $release...$main --pretty=oneline
}

# - - - - - -
# - DOCKER  -
# - - - - - -
function docker-selector-containers() {
  docker ps -a --format="{{.ID}}\t\t{{.Names}}" |
    fzf -0 -1 --delimiter="\t" --with-nth="-1" |
    cut -f1
}
function docker-selector-running-containers() {
  docker ps --format="{{.ID}}\t\t{{.Names}}" |
    fzf -0 -1 --delimiter="\t" --with-nth="-1" |
    cut -f1
}
function docker-selector-images() {
  docker images --format="{{.ID}}\t\t{{.Repository}}" |
    fzf -0 -1 --delimiter="\t" --with-nth="-1" |
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
  branch=$(git branch --format='%(refname:short)' | fzf)
  git reset --hard $branch
  git push -f origin staging
  git checkout $branch
}

function teststg() {
  git checkout staging
  git pull
  branch=$(git branch --format='%(refname:short)' | fzf)
  git pull origin $branch
  git push
  git checkout $branch
}

if [ -d "$HOME/adb-fastboot/platform-tools" ]; then
  export PATH="$HOME/platform-tools:$PATH"
fi

zstyle ':completion:*' menu select
fpath+=~/.zfunc

export GOPATH=$HOME/golang
export GOROOT=/usr/local/opt/go/libexec
export PATH="$PATH:/Users/jose.cabeda/Library/Application Support/Coursier/bin"
export PATH="/usr/local/opt/mysql-client/bin:$PATH"

# Setup asdf
# . $(brew --prefix asdf)/libexec/asdf.sh
# . ~/.asdf/plugins/java/set-java-home.zsh

# Makes sure gpg is running
gpg-agent

source ~/.bash_profile

# autoload -U +X bashcompinit && bashcompinit

eval "$(direnv hook zsh)"


export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Make sure it's the last command
eval "$(mcfly init zsh)"