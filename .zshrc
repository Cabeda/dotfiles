# TO DEBUG time to load
# zmload zsh/zprof # beginning
# zprof # end
# time zsh -i -c exit # Run

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

plugins=(
)

# EXPORT configs
export LC_CTYPE="en_US.UTF-8"
export LANG=en_US.UTF-8

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
export DOCKER_HOST=unix://$HOME/.colima/docker.sock
export GOPATH=$HOME/golang
export GOROOT=/usr/local/opt/go/libexec
export DYLD_FALLBACK_LIBRARY_PATH=/usr/local/opt/openssl/lib:$DYLD_LIBRARY_PATH

source ~/env # Script that holds alias and tokens


# eval "$(ssh-agent -s)"
# ssh-add ~/.ssh/maid_ed25519


################ Global Mac ALIAS ################
alias start="bash $HOME/Git/dotfiles/scripts/start.sh"
alias write="bash $HOME/Git/dotfiles/scripts/write.sh"

alias dkill='docker stop $(docker ps -qa) && docker volume prune && docker image prune && docker rm -f $(docker ps -aq) && docker system prune'

alias g="git"
alias gp="git pull"
alias gs="git pull && git push"
alias sp="speedtest"
alias dcd="docker compose down"
alias cb="open https://www.gocomics.com/random/calvinandhobbes"
alias todo="vim ~/git/pensamentos/To-Do.md"
alias ip="curl ifconfig.me"
alias caws="code ~/.aws/credentials"
alias rc="code ~/.zshrc"
alias sva="source .venv/bin/activate"

alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
alias ttt="tt thought -t"

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
  git switch $(git branch | fzf)
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


function mdev() {
    export AWS_DEFAULT_PROFILE=mania-dev
    aws sso login
}

function mint() {
    export AWS_DEFAULT_PROFILE=mania-int
    aws sso login
}

function fidv() {
    export AWS_DEFAULT_PROFILE=fidv-dev
    aws sso login
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

# Function to run glue notebook locally
function glue() {
  JUPYTER_WORKSPACE_LOCATION=$PWD
  PROFILE_NAME="mania-dev"
  podman run -it -v ~/.aws:/home/glue_user/.aws -v $JUPYTER_WORKSPACE_LOCATION:/home/glue_user/workspace/jupyter_workspace/ -e AWS_PROFILE=$PROFILE_NAME -e DISABLE_SSL=true --rm -p 4040:4040 -p 18080:18080 -p 8998:8998 -p 8888:8888 --name glue_jupyter_lab amazon/aws-glue-libs:glue_libs_4.0.0_image_01 /home/glue_user/jupyter/jupyter_start.sh
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

# List step functions and run
function steprun() {
  aws stepfunctions list-state-machines --query "stateMachines[].stateMachineArn" | fzf | xargs aws stepfunctions start-execution --state-machine-arn
}

if [ -d "$HOME/adb-fastboot/platform-tools" ]; then
  export PATH="$HOME/platform-tools:$PATH"
fi


# Makes sure gpg is running
# GPG_TTY=$(tty)
# export GPG_TTY
# eval $(gpg-agent --daemon)

# source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(direnv hook zsh)"
eval "$(fzf --zsh)"
eval "$(gh copilot alias -- zsh)"
eval "$(mcfly init zsh)"
eval "$(zoxide init zsh)"
eval "$(/opt/homebrew/bin/mise activate zsh)"
