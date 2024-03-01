# generate vipaccess code and copy to clipboard
function vipcp() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local code=$(vipaccess)
  echo -n $code | pbcopy
  echo "[ ${YELLOW}$code${NOCOLOR} ]: vipaccess code copied to clipboard"
}

# search all projects' contents in the project's directory for the filter
function findp() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  if [[ $1 == '--all' ]]; then
    if [[ $2 == '' ]]; then
      echo "${RED}search filter missing, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    fi
    rg -A5 -B3 -i -e "$2" $PROJECT_PATH
  else
    local args=(${@:1:#})
    local searchCMD="rg --type-add 'tf:*.{tf,tfvars}' --type-add 'gomod:*.mod' --type-add 'jenk:Jenkinsfile' -B1 -A10 -i -t tf -t gomod -t jenk -U '' $PROJECT_PATH"
    for arg in $args
    do
      local add=" | rg -i --fixed-strings --color=always '$arg' "
      if [[ $arg == *"-"* ]]; then
        local add=" | rg -i --color=always -e '$arg' "
      fi
      searchCMD="$searchCMD$add"
    done
    eval $searchCMD
  fi
}

# search and get projects that match the provided filters
function listp() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local args=(${@:1:#})
  if [[ $args == "" ]]; then
    echo "${RED}search filter missing, use '${PINK}$0 help${RED}' for more information.\nexiting......${NOCOLOR}"
    return
  fi
  local color="always"
  if [[ $1 == *"--no-color"* ]]; then
    args=(${@:2:#})
    color="never"
  fi
  local searchCMD="ls $PROJECT_PATH"
  for arg in $args
  do
    local add=" | rg -i --fixed-strings --color=$color '$arg' "
    if [[ $arg == *"-"* ]]; then
      local add=" | rg -i --color=$color -e '$arg' "
    fi
    searchCMD="$searchCMD$add"
  done
  local found=$(eval $searchCMD)
  if [[ $found == "" ]]; then
    echo "${RED}failed to find matching projects...${NOCOLOR}"
  else
    if [[ $color == "always" ]]; then
      echo "${GREEN}[ found ]:${NOCOLOR}"
    fi
    echo $found
  fi
}

# list all terraform projects
function listf() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local tfs=()
  local projects=($(ls $PROJECT_PATH))
  for project in $projects
  do
    local prls=$(ls $PROJECT_PATH/$project)
    if [[ $prls == *"main.tf"* ]]; then
      echo $project
    fi
  done
}

# search and open project in intellij
function iop() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local want=${@:1:#}
  local ide=""
  if [[ $1 == "--vs" ]]; then
    ide="code"
    want=${@:2:#}
  elif [[ $1 == "--ij" ]]; then
    ide="idea"
    want=${@:2:#}
  else
    ide=$DEFAULT_IDE
  fi
  local startsWith=""
  if [[ $want == "" ]]; then
    echo "search filter missing..."
    return
  else
    want=($(echo $want))
    local searchCMD="ls $PROJECT_PATH"
    for var in $want
    do
      if [[ $var == "/"* ]]; then
        if [[ $startsWith == "" ]]; then
          var=${var//'\/'/''}
          startsWith=$var
        else
          echo "${RED}mulitple start value filters found, exiting...${NOCOLOR}"
          return
        fi
      fi
      local add=" | rg -i --fixed-strings --color=never '$var'"
      searchCMD="$searchCMD$add"
    done
  fi
  local found=""
  if [[ $startsWith == "" ]]; then
    found=($(eval $searchCMD))
  else
    local tempfound=($(eval $searchCMD))
    for fnd in $tempfound
    do
      found="${found}[!]${fnd}\n"
    done
    found=$(echo $found | rg --fixed-strings "[!]${startsWith}")
    found=${found//'[!]'/''}
    found=($(echo $found | xargs))
  fi
  want=(${want//"\/"/''})
  local coloredfounds=()
  for fnd in $found
  do
    for wt in $want
    do
      fnd=${fnd//$wt/${RED}$wt${NOCOLOR}}
    done
    coloredfounds+=$fnd
  done
  if [[ $found == "" ]]; then
    echo "${RED}failed to find matching project...${NOCOLOR}"
  else
    echo "${GREEN}[ found ]:${NOCOLOR}"
    for cf in $coloredfounds
    do
      echo $cf
    done
    local first=$(echo $coloredfounds[1] | sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
    echo -n "${BLUE}do you want to open: [ ${YELLOW}$first${BLUE} ]: ${NOCOLOR}"
    read -k1
    if [[ ${REPLY} == $'\n' ]]; then
      echo "${GREEN}[ opening ]: ${NOCOLOR}${YELLOW}$first${NOCOLOR}"
      eval "$ide $PROJECT_PATH/$first"
    else
      echo "${RED}\ncancelling open...${NOCOLOR}"
    fi
  fi
}

# search the projects directory that match the filter and cd into the result
function cdpr() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local searchCMD="ls $PROJECT_PATH"
  for var in ${@:1:#}
  do
    searchCMD="$searchCMD | rg -i --fixed-strings '$var'"
  done
  local found=$(eval $searchCMD)
  local first=$(head -1 <<< $found | sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
  cd $PROJECT_PATH/$first
}

# show currently used colors
function showcolors() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local colors=$(cat ${HOME}/.zshrc | rg "033\[")
  colors=("${(@f)colors}")
  for color in $colors
  do
    local code=${color##*"["}
    code=${code%%"\""*}
    code=${code//"'"/''}
    local name=${color%%"="*}
    name=${name##*"export "}
    echo -n "\033[${code}$name : ${NOCOLOR}"
    echo -n "$code : "
    echo "\033[${code}the quick brown fox jumps over the lazy dog${NOCOLOR}"
  done
}

# print all available colors
function coloropts() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  for i in {0..255}
  do
    local code="38;5;${i}m"
    echo -n "$code : "
    echo "\033[${code}the quick brown fox jumps over the lazy dog${NOCOLOR}"
  done
}

# print the current branch checked out
function getprojectbranch() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  if [[ $1 == "" ]]; then
    echo "${RED}missing project name, exiting...${NOCOLOR}"
  fi
  local project=$1
  local currentPath=$(pwd)
  cd $PROJECT_PATH/$project
  git branch --show-current
  cd $currentPath
}