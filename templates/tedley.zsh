# Functions for zrcsh specific to firstname- -lastname  
###############################
# MISC ALIASES 
###############################

# Vagrant shortcuts 
alias vg='vagrant'
alias vgp='vagrant provision'
# kubernetes shortcut 
alias k='kubectl'
alias mk='minikube'

alias zstart='sudo open -a /Applications/Zscaler/Zscaler.app --hide'
alias zkill="sudo find /Library/LaunchDaemons -name '*zscaler*' -exec launchctl unload {} \;"

export CYPRESS_PASS=bellese_cypress
export CYPRESS_AES_KEY=d9a830ad92aa09c69834896efa463ad5
export AES_KEY=$CYPRESS_AES_KEY

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

alias cdp='cd ~/projects'
alias cypress-dev='npx cypress open cy:dev'
alias update-vim='vim +PluginInstall +qall'

###############################
# Pyhton Aliases
###############################
alias p3='python3'
alias p3p='python3 -m pip'
alias p3pi='python3 -m pip install'

###############################
# DOCKER ALIASES
###############################

# Docker Shortcuts
alias dcps='sudo docker ps'
alias dci='sudo docker images'
alias dcvls='sudo docker volume ls'
alias dcnls='sudo docker network ls'
alias dck='docker rmi -f $(docker images -a -q)'
alias dcstop='sudo docker stop $(docker ps -a -q)'
alias dcom='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs'
alias dckb='docker-compose build'
alias dcub='docker-compose up --build'
alias dckb='docker-compose build'
alias dcub='docker-compose up --build'
alias dcvp='docker volume prune -f'
alias dcnp='docker network prune -f'
alias dcrmi='docker rmi -f $(docker images -a -q)'

dcc () {
   echo 'Stopping running containers (if available)...'
   docker stop $(docker ps -aq) && sleep 1

   echo 'Removing containers ..'
   docker rm $(docker ps -aq)  && sleep 1

   echo 'Removing images ...'
   docker rmi $(docker images -q) && sleep 1

   echo 'Revoming docker container volumes (if any)'
   docker volume rm $(docker volume ls -q) && sleep 1

 }

###############################
# DOCKS and GH-CLI
###############################
# get current gh-cli status 
alias ghas='gh auth status'

# copy firstname-.zsh to zfuncs dir
function cptme() {
  if [[ -f ~/work-related/bellese/zsh-funcs/firstname-.zsh ]]
  then
      echo "updating firstname-.zsh"  && sleep 1
      cp ~/work-related/bellese/zsh-funcs/firstname-.zsh ~/zfuncs/
      source ~/.zshrc
      echo "updated aliases"
  else
      echo "firstname-.zsh not found"
      echo "check working branch of simon-zfuncs"
  fi 
 }

# Update personal notes repo 
function update-notes() {
  TIMESTAMP=`date`
  #NOTES_DIR='~/projects/work-related' /Users/firstname--lastname/projects/work-related
  NOTES_DIR='/Users/firstname--lastname/work-related'
  MESSAGE=" updating notes with timestamp: $TIMESTAMP " 
  CURRENT_DIR=$(pwd)
  echo "RUN CPTME to update local aliases"
    if [[ -f ~/projects/simon-zfuncs/firstname-.zsh ]]
  then
      echo "updating firstname-.zsh"
      cp ~/projects/simon-zfuncs/firstname-.zsh ~/zfuncs/
      source ~/.zshrc
      echo "updated aliases"
  else
      echo "firstname-.zsh not found"
      echo "check working branch of simon-zfuncs"
  fi 
  echo "COPY Aliases"
  rsync -arv /Users/firstname--lastname/projects/simon-zfuncs/*.zsh $NOTES_DIR/bellese/zfuncs/ 
  echo "GRABBING LATEST NOTES"
  cd $NOTES_DIR && git pull 
  echo "UPDATING NOTES"
  cd $NOTES_DIR && git add . && git commit -m " $MESSAGE "  
  cd $NOTES_DIR && git status && sleep 2
  cd $NOTES_DIR && git push
  cd $CURRENT_DIR 
  echo "Notes Updated!" 

 }

# create ssh key and push to github 
ghp1 () {
  GHUSER=t-lastname
  GHHOST_HOME=github.com
  GHHOST_WORK=qnetgit.cms.gov
  GHPROTO=ssh 
  CLITOKEN_HOME=$(echo $GHCLI_HOME)
  CLITOKEN_WORK=$(echo $GHCLI_WORK)
  # logout of current user 
  gh auth status 
  # unset current gh token 
  #echo "Unset gh-cli token" && sleep 1
  #unset GH_TOKEN
  echo "LOGGING OUT OF EXISTING GH PROFILE" && sleep 1
  echo "LOGOUT OF WORK PROFILE" && sleep 1 
  #export GH_TOKEN=$CLITOKEN_WORK
  gh auth logout -h $GHHOST_WORK 
  echo "LOGOUT OF TME PROFILE" && sleep 1 
  gh auth logout -h $GHHOST_HOME
  # set env variable to gh-work token
  echo "Updating new token" && sleep 1 
  echo "Logging into gh-cli as $GHUSER" && sleep 1
  echo $CLITOKEN_HOME | gh auth login -h $GHHOST_HOME --with-token  
  gh config set git_protocol ssh --host $GHHOST_HOME
  # set gh token 
  echo "Setting up gh_token" && sleep 1
  export GH_TOKEN=$CLITOKEN_HOME
  # print status to confirm connection
  gh auth status 
}

ghp2 () {
  GHUSER=t-lastname1
  GHHOST_HOME=github.com
  GHHOST_WORK=qnetgit.cms.gov
  GHPROTO=ssh
  CLITOKEN_HOME=$(echo $GHCLI_HOME)
  CLITOKEN_WORK=$(echo $GHCLI_WORK)
  # logout of current user 
  gh auth status 
  # unset current gh token 
  #echo "Unset gh-cli token" && sleep 1
  #unset GH_TOKEN
  echo "LOGGING OUT OF EXISTING GH PROFILE" && sleep 1
  echo "LOGOUT OF WORK PROFILE" && sleep 1 
  gh auth logout -h $GHHOST_WORK 
  echo "LOG OUT TME PROFILE" && sleep 1 
  gh auth logout -h $GHHOST_HOME
  # set env variable to gh-work token
  echo "Updating new token" && sleep 1 
  echo "Logging into gh-cli as $GHUSER" && sleep 1
  echo $CLITOKEN_WORK | gh auth login -h $GHHOST_WORK --with-token  
  gh config set git_protocol ssh --host $GHHOST_WORK
  # set gh token 
  echo "Setting up gh_token" && sleep 1
  export GH_TOKEN=$CLITOKEN_WORK
  # print status to confirm connection
  gh auth status  
} 


ghlistkey() {
  gh ssh-key list
}

ghlistkeys() {
  gh ssh-key list
}

ghaddkey() {
  gh ssh-key add ~/.ssh/id_rsa.pub -t 'macbook-bellese'
}

ghdelkey () {
 GitHub CLI api
 https://cli.github.com/manual/gh_api
  gh api \
    --method DELETE \
    -H "Accept: application/vnd.github+json" \
    /user/keys/70644299
}

runec2 () {
  aws ec2 describe-instances \
--query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,InstanceID:InstanceId,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" \
--filters Name=instance-state-name,Values=running \
--output=table
}

