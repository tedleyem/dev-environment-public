# [DO NOT REMOVE] template-start
export AWS_REGION='us-east-1'
export AWS_PROFILE='354979567826-ADFS-ADELE-ADO2-ADOADMIN'
export AWS_PROD='354979567826-ADFS-ADELE-ADO2-ADOADMIN'
export AWS_SBX='909963434412-ADFS-ADELE-ADO2-ADOADMIN-SBX'
export AWS_DEV='052662718199-ADFS-ADELE-ADO2-ADOADMIN-DEV'
export AWS_TEST='772782995265-ADFS-ADELE-ADO2-ADOADMIN-TEST'
export AWS_IMPL='702808056329-ADFS-ADELE-ADO2-ADOADMIN-IMPL'

export ZFUNCS_PATH="${HOME}/zfuncs"
export PROJECT_PATH="${HOME}/projects"
export QUALNET_EMAIL='{ ADFS_ID }@qnet.qualnet.org'
export DEFAULT_IDE='{ DEFAULT_IDE }'

alias awsprod='export AWS_PROFILE=${AWS_PROD}'
alias awssbx='export AWS_PROFILE=${AWS_SBX}'
alias awsdev='export AWS_PROFILE=${AWS_DEV}'
alias awstest='export AWS_PROFILE=${AWS_TEST}'
alias awsimpl='export AWS_PROFILE=${AWS_IMPL}'

alias sauthp='stsauth profiles'
alias sauthl='stsauth authenticate -u ${QUALNET_EMAIL} -t $(vipaccess) -p { ADFS_PASSWORD }'

alias tf='terraform'
alias tfutils='tf-utils'
alias tfi='tf init'
alias tfiu='tf init -upgrade'

alias rmtf='rm -rf .terraform && echo "${GREEN}deleted .terraform directory${NOCOLOR}"'
alias rmtfl='rm -rf .terraform.lock.hcl && echo "${GREEN}deleted .terraform.lock.hcl${NOCOLOR}"'

alias precommit='pre-commit'
alias prcinit='precommit install && precommit autoupdate'

alias gst='git status'
alias gepic='git checkout epic/aws-account-breakout'
alias gp='git push'

alias ls='lsd'

alias srczsh="source ${HOME}/.zshrc"

# source all zsh function files
function srcz() {
  for file in ~/zfuncs/*
  do
    local filename=${file##*"/"}
    if [[ $filename == *".zsh"* ]]; then
      source $file
    fi
  done
}

# source all zsh files on terminal startup
srcz
# [DO NOT REMOVE] template-end