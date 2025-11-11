# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

plugins=()

# EXPORT configs
export TERM=xterm-256color
export LC_CTYPE="en_US.UTF-8"
export LANG=en_US.UTF-8

export ZSH_THEME="avit"
export DISABLE_UPDATE_PROMPT="true"
export ENABLE_CORRECTION="true"
export MCFLY_FUZZY=2
# export LDFLAGS="-L $(xcrun --show-sdk-path)/usr/lib -L $(brew --prefix bzip2)/lib"
# export CFLAGS="-L $(xcrun --show-sdk-path)/usr/include -L $(brew --prefix bzip2)/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig"
export PATH=/opt/homebrew/bin:$PATH
export PATH="/usr/local/sbin:$PATH"
export PATH="/Users/jose.cabeda/.deno/bin:$PATH"
ZSH_DISABLE_COMPFIX="true"
export DOCKER_HOST=unix://$HOME/.colima/docker.sock

export GENERATIVE_AI_TELEMETRY_ENABLED=FALSE

# Run commands specific to shell
if [[ "$OSTYPE" == "darwin"* ]]; then

  export ZSH="/Users/jose.cabeda/.oh-my-zsh"
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

elif [[ "$OSTYPE" == "linux-android" ]]; then
  echo $OSTYPE
else
  echo "Unsupported shell"
fi

source ~/env # Script that holds alias and tokens
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(starship init zsh)"
eval "$(ssh-agent -s)"

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
alias sba="source .venv/bin/activate"

alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
alias ttt="tt thought -t"
alias y="yazi"

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

function secret() {
  local secret_name
  secret_name=$(aws secretsmanager list-secrets --query "SecretList[].Name" --output text | tr '\t' '\n' | fzf)
  if [[ -n "$secret_name" ]]; then
    aws secretsmanager get-secret-value --secret-id "$secret_name" --query SecretString --output text
  else
    echo "No secret selected."
  fi
}


function mdev() {
    export AWS_PROFILE="mania-dev"
    export AWS_DEPLOYMENT_STAGE=dev
    export AWS_DEFAULT_PROFILE="mania-dev"
}

function mint() {
    export AWS_PROFILE="mania-int"
    export AWS_DEPLOYMENT_STAGE=INT
    export AWS_DEFAULT_PROFILE="mania-int"
}

function main() {
    export AWS_PROFILE="maintenance"
    export AWS_DEPLOYMENT_STAGE="maintenance"
    export AWS_DEFAULT_PROFILE="maintenance"
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

# List step functions and tail logs of the last execution
function steplogs() {
  step=$(aws stepfunctions list-state-machines --query "stateMachines[].stateMachineArn" | fzf)

  last_execution=$(aws stepfunctions get-execution-history --execution-arn $execution | jq -r '.events[] | select(.type == "ExecutionStarted") | .executionStartedEventDetails.input')

  aws stepfunctions get-execution-history --execution-arn $last_execution | jq -r '.events[] | select(.type == "LambdaFunctionFailed" or .type == "LambdaFunctionTimedOut") | .lambdaFunctionFailedEventDetails.cause'
}

if [ -d "$HOME/adb-fastboot/platform-tools" ]; then
  export PATH="$HOME/platform-tools:$PATH"
fi

zstyle ':completion:*' menu select
fpath+=~/.zfunc

export PATH="$PATH:/Users/jose.cabeda/Library/Application Support/Coursier/bin"
export PATH="/usr/local/opt/mysql-client/bin:$PATH"

# Makes sure gpg is running
GPG_TTY=$(tty)
export GPG_TTY
eval $(gpg-agent --daemon)

source ~/.bash_profile

autoload -U +X bashcompinit && bashcompinit

eval "$(direnv hook zsh)"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#Copilot
eval "$(gh copilot alias -- zsh)"

# Enable natural text editing
bindkey "^[[1;3C" forward-word # Alt + Right
bindkey "^[[1;3D" backward-word # Alt + Left
bindkey "^[[1;2C" forward-word # Shift + Right
bindkey "^[[1;2D" backward-word # Shift + Left
bindkey "^[[1;5C" forward-word # Ctrl + Right
bindkey "^[[1;5D" backward-word # Ctrl + Left
bindkey "^H" backward-delete-char # Backspace
bindkey "^[[3~" delete-char # Delete
bindkey '^[[H' beginning-of-line # Home
bindkey '^[[F' end-of-line # End

eval "$(fzf --zsh)"

# Make sure it's the last command
eval "$(mcfly init zsh)"

# Prefer fzf for Ctrl+R history search (override other bindings like mcfly)
if type -p fzf >/dev/null 2>&1; then
  if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
  elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
  fi
  # Explicitly bind Ctrl-R to fzf history widget
  bindkey '^R' fzf-history-widget
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
# pnpm
export PNPM_HOME="/Users/jose.cabeda/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/Users/jose.cabeda/.bun/_bun" ] && source "/Users/jose.cabeda/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
