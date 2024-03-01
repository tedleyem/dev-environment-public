# checkout master or main
function gcm() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  git checkout $(gitdefaultbranch)
}

# pull from master or main
function gpm() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  git pull origin $(gitdefaultbranch)
}


# git reset and remove tf lock if applicable
function grh() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  git reset --hard
  local gst=$(gst)
  if [[ $gst == *"terraform.lock.hcl"* ]]; then
    rmtfl
  fi
}

# search remote branches and checkout branch that matches the filter
function gco() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  git fetch --all
  local searchCMD="git branch -a | rg -i origin | rg -v 'HEAD'"
  for var in ${@:1:#}
  do
    searchCMD="${searchCMD} | rg -i '$var' "
  done
  local found=$(eval $searchCMD)
  local first=$(head -1 <<< $found)
  local branch=${first##*"remotes/origin/"}
  git checkout $branch
}

# git clone to $PROJECT_PATH
function gitc() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local url=$1
  local currentpath=$(pwd)
  cd $PROJECT_PATH
  git clone $url
  sleep .5
  cd $currentpath
}

# create new branch
function gnb() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  branchName=$1
  git checkout -b $branchName
  git push --set-upstream origin $branchName
}

# delete branch
function gdb() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  branchName=$1
  git branch -d $branchName
  git push origin --delete $branchName
}

# delete branch and return to master or main
function gdbm() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local branches=$(git branch)
  local top=$(gitdefaultbranch)
  local oldbranch=$(git rev-parse --abbrev-ref HEAD)
  if [[ $oldbranch == $top ]]; then
    echo "${RED}current branch is $top, exiting...${NOCOLOR}"
    return
  fi
  git checkout $top
  git pull
  gdb $oldbranch
}

# create pull request from current branch to target branch, default to master
function gpr() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local target=$1
  if [[ $target == "" ]]; then
    target=$(gitdefaultbranch)
  fi
  local currentbranch=$(git branch --show-current)
  local prstatus=$(gh pr status)
  local currentbranchstatus=$(echo $prstatus | rg -i "$currentbranch")
  if [[ $currentbranchstatus == *"Merged"* || $currentbranchstatus == *"Closed"* || $prstatus == *"There is no pull request associated with [$currentbranch]"* ]]; then
    echo "${BLUE}[ creating pull request... ]${NOCOLOR}"
    gh pr create --base $target --fill
    local prurl=$(getprurl $currentbranch)
    echo -n $prurl | pbcopy
    echo "${YELLOW}copied to clipboard${NOCOLOR}"
  else
    echo "${BLUE}[ pull request already exists ]${NOCOLOR}"
    local prurl=$(getprurl $currentbranch)
    echo "pr url: $prurl"
    echo -n $prurl | pbcopy
    echo "${YELLOW}copied to clipboard${NOCOLOR}"
  fi
}

# git add and commit
function gcom() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local msg=${@:1:#}
  if [[ $msg == "" ]]; then
    echo "missing commit message, use '${PINK}$0 help${RED}' for more information.\nexiting..."
    return
  else
    echo "Running command: ${BLUE}git add . ${NOCOLOR}&&${GREEN} git commit -m \"${YELLOW}$msg${GREEN}\"${NOCOLOR}"
    echo "[ ${BLUE}GIT ADD${NOCOLOR} ]"
    git add .
    git status
    echo "[ ${GREEN}GIT COMMIT${NOCOLOR} ]"
    git commit -m "$msg"
    echo "[ ${GREEN}GIT COMMIT STATUS${NOCOLOR} ]"
    git status
  fi
}

# git add and commit with commitzen
function gcz() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  git add .
  cz commit
}

# open current project's github repo on current branch
function gopen() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  echo "${YELLOW}opening github repo in chrome...${NOCOLOR}"
  gh repo view -b $(git branch --show-current) -w > /dev/null 2>&1
}

# search and list all repos that match the filters
function grls() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local searchCMD="gh repo list Bellese -L 1000 --no-archived"
  for var in ${@:1:#}
  do
    local add=" | rg -i --fixed-strings --color=never '$var' "
    if [[ $var == *"-"* ]]; then
      local add=" | rg -i --color=never -e '$var' "
    fi
    searchCMD="$searchCMD$add"
  done
  echo "${YELLOW}searching for repositories...${NOCOLOR}"
  local found=$(eval $searchCMD)
  if [[ $found == "" ]]; then
    echo "${RED}no projects found that match the provided filter(s)"
  else
    echo "${GREEN}[ found ]: ${NOCOLOR}"
    local parts=("${(@f)found}")
    for repo in $parts
    do
      local name=${repo%%$'\t'*}
      echo $name
    done
  fi
}

# search repos in github using filter and clone to local
function grclone() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local args=(${@:1:#})
  local searchCMD="gh repo list Bellese -L 1000 --no-archived"
  for arg in $args
  do
    local add=" | rg -i --fixed-strings --color=never '$arg' "
    if [[ $arg == *"-"* ]]; then
      local add=" | rg -i --color=never -e '$arg' "
    fi
    searchCMD="$searchCMD$add"
  done
  echo "${YELLOW}searching for repositories...${NOCOLOR}"
  local found=($(eval $searchCMD | sort))
  if [[ $found == "" ]]; then
    echo "${RED}no matching projects found, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi
  local first=$found[1]
  echo "${GREEN}[ found ]:${NOCOLOR}"
  for repo in $found
  do 
    if [[ $repo == *"Bellese/"* ]]; then
      echo "${LIGHTYELLOW}- ${LIGHTGREEN}$repo${NOCOLOR}"
    fi
  done
  echo -n "${BLUE}do you want to clone: [ ${YELLOW}$first${BLUE} ]: ${NOCOLOR}"
  read -k1
  if [[ ${REPLY} == $'\n' ]]; then
    echo "${GREEN}[ cloning ]: ${NOCOLOR}${YELLOW}$first${NOCOLOR}"
    gitc "git@qnetgit.cms.gov:$first.git"
  else
    echo "${RED}\ncancelling clone...${NOCOLOR}"
  fi
}

function gitdefaultbranch() { #noface
  local gitbranch=$(git branch -a)
  if [[ $gitbranch == *"origin/HEAD -> origin/main"* ]]; then
    echo "main"
  else
    echo "master"
  fi
}

# update all projects that are currently on the epic branch
function gtfpull() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local currentpath=$(pwd)
  local type=$1
  if [[ $type == "" ]]; then
    local found=$(lsa $PROJECT_PATH | rg -i "tf" | rg -v "(service-environment)|(hqr-tf)")
    local repos=("${(@f)found}")
    local nonepics=""
    for repo in $repos
    do
      local projectname=${repo##*" "}
      cd $PROJECT_PATH/$projectname
      local thisbranch=$(git branch --show-current)
      if [[ $thisbranch == "epic/aws-account-breakout" ]]; then
        gitpullstatus $projectname
      else
        nonepics="$nonepics\n$projectname"
      fi
    done
    if [[ $nonepics != "" ]]; then
      echo "${RED}[ repositories not currently on epic ]:${YELLOW}$nonepics${NOCOLOR}"
    fi
  elif [[ $type == "service" ]]; then
    local found=$(lsa $PROJECT_PATH | rg -i "service-environment" | rg -v "hqr-tf")
    local repos=("${(@f)found}")
    local nonmasters=""
    for repo in $repos
    do
      local projectname=${repo##*" "}
      cd $PROJECT_PATH/$projectname
      local thisbranch=$(git branch --show-current)
      if [[ $thisbranch == "master" || $thisbranch == "main" ]]; then
        gitpullstatus $projectname
      else
        nonmasters="$nonmasters\n$projectname"
      fi
    done
    if [[ $nonmasters != "" ]]; then
      echo "${RED}[ repositories not currently on master ]:${YELLOW}$nonmasters${NOCOLOR}"
    fi
  fi
  cd $currentpath
}

function gitpullstatus() { #noface
  local projectname=$1
  echo -n "${LIGHT}$projectname : ${NOCOLOR}"
  local pull=$(git pull)
  if [[ $pull == *"Already up to date"* ]]; then
    echo "${GREEN}good${NOCOLOR}"
  elif [[ $pull == *"CONFLICT"* ]]; then
    echo "${RED}conflict${NOCOLOR}"
  elif [[ $pull == *"Aborting"* ]]; then
    echo "${YELLOW}local changes${NOCOLOR}"
  elif [[ $pull == *"files changed"* ]]; then
    echo "${BLUE}pulled${NOCOLOR}"
  else
    echo $pull
  fi
}

# update precommits on all projects on the epic branch and push to remote
function gepicprecommit() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local currentpath=$(pwd)
  local found=$(lsa $PROJECT_PATH | rg -i "tf")
  local parts=("${(@f)found}")
  for repo in $parts
  do
    local name=${repo##*" "}
    cd $PROJECT_PATH/$name
    local thisbranch=$(git branch --show-current)
    if [[ $thisbranch == *"epic/aws-account-breakout"* ]]; then
      echo -n "${LIGHT}$name : ${NOCOLOR}"
      local precommitsetup=$(prcinit)
      if [[ $precommitsetup == *"git:"* ]]; then
        echo "${RED}need https${NOCOLOR}"
        continue
      elif [[ $precommitsetup == *"already up to date"* ]]; then
        echo "${GREEN}good${NOCOLOR}"
      else
        precommit run -a
        gcom automated - precommit update
        gp
      fi
    fi
  done
  cd $currentpath
}

# search for all modules matching filter, provide version to match against
function gtfmoduleversion() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local currentpath=$(pwd)
  local awstype=$1
  local wantedversion=$2
  local wantedrepos=$(lsa $PROJECT_PATH | rg -i "tf")
  local repos=("${(@f)wantedrepos}")
  local previousreponame=""
  for repo in $repos
  do
    local reponame=${repo##*" "}
    cd $PROJECT_PATH/$reponame
    local thisbranch=$(git branch --show-current)
    local wantedfiles=$(lsa | rg -i ".tf" | rg -v ".tfvars" | rg -v ".tfstate")
    local files=("${(@f)wantedfiles}")
    for file in $files
    do
      local filename=${file##*" "}
      local wantedmodules=$(cat $filename | rg -i -U "(module \").*\n.*($awstype)")
      local modules=("${(@f)wantedmodules}")
      if [[ $modules != "" ]]; then
        if [[ $previousreponame != $reponame ]]; then
          previousreponame=$reponame
          echo "${GREEN}$reponame : [ ${PINK}$thisbranch${GREEN} ]${NOCOLOR}"
        fi
        echo "${BLUE}  $filename${NOCOLOR}"
      fi
      for mod in $modules
      do
        if [[ $mod == *"module"* ]]; then
          local modulename=$(cut -d "\"" -f2 <<< $mod)
          echo -n "${LIGHT}    $modulename : ${NOCOLOR}"
        elif [[ $mod == *"tags"* ]]; then
          local removetag=${mod##*"tags/v"}
          local version=${removetag%%"\""*}
          if [[ $wantedversion != "" && $version != $wantedversion ]]; then
            echo "${RED}$version${NOCOLOR}"
          else
            echo "${YELLOW}$version${NOCOLOR}"
          fi
        fi
      done
    done
  done
  cd $currentpath
}

# search github terraform repositories and compare with locally cloned projects
function comparetfs() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  echo "${YELLOW}searching remote github for tf projects, this may take a few minutes...${NOCOLOR}"
  local remotetfs=($(grlstf --clean))
  local localtfs=($(ls $PROJECT_PATH))
  local locs=()
  for loc in $localtfs
  do
    locs+="Bellese/$loc"
  done
  local results=()
  for remote in $remotetfs
  do
    local namewithorg="Bellese/$remote"
    if [[ $locs != *"$namewithorg"* ]]; then
      results+=$remote
    fi
  done
  if [[ $results == '' ]]; then
    echo "${GREEN}all terraform repositories are cloned locally${NOCOLOR}"
  else
    echo "${BLUE}found in github but not in local:${NOCOLOR}"
    for result in $results
    do
      echo "${CYAN}- ${LIGHTYELLOW}$result${NOCOLOR}"
    done
  fi
  
}

# get url of pull request from current branch
function getprurl() { #noface
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local currentbranch=$1
  local msg=$(gh pr status | rg $currentbranch | xargs)
  local number=${msg%%" "*}
  number=${number##*"#"}
  local prstatus=$(gh pr view $number | rg "url" | xargs)
  local url=${prstatus##*"url: "}
  echo $url 
}

# get latest released version of modules in a project
function latestmods() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local fullmain=""
  local maintfs=$(ls | rg -v "tfvars" | rg ".tf" | rg -v "outputs.tf|variables.tf|.tfstate")
  maintfs=("${(@f)maintfs}")
  for maintf in $maintfs
  do
    local contents=$(cat $maintf)
    fullmain="$fullmain\n$contents"
  done
  local sources=$(echo $fullmain | rg 'qnetgit.cms.gov')
  local sourcelist=("${(@f)sources}")
  local searched=()
  for source in $sourcelist
  do
    local modulename=${source##*"Bellese/"}
    modulename=${modulename%%".git"*}
    modulename="Bellese/$modulename"
    if [[ $searched == *"$modulename"* ]]; then
      continue
    else
      searched+=$modulename
    fi
    local releases=$(gh release list --repo $modulename | sort -r)
    local version=$(echo $releases | HEAD -1 | rg -o --color=never "(v)[0-9.]*" | HEAD -1)
    modulename=${modulename##*"Bellese/"}
    echo "\n- ${LIGHTYELLOW}$modulename${NOCOLOR} : ${BLUE}$version${NOCOLOR}"
  done
  echo ""
}

# Run git pull recursively in projects dir  
function gpall() {
  # perform a git pull on every dir in the projects dir.  
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi 
  find $PROJECT_PATH -mindepth 1 -maxdepth 1 -type d -print -exec git -C {} pull \; 
} 

# Merge pull request, checkout base branch
function gprm() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local currentPath=""
  if [[ $1 != "" ]]; then
    currentpath=$(pwd)
    local first=$(listp --no-color ${@:1:#} | HEAD -1)
    if [[ $first == *"failed"* ]]; then
      echo "$first\n${RED}exiting...${NOCOLOR}"
      return
    fi
    echo -n "${BLUE}check for pull requests on [ ${LIGHTYELLOW}$first${BLUE} ]: ${NOCOLOR}"
    read -k1
    if [[ ${REPLY} == $'\n' ]]; then
      cd $PROJECT_PATH/$first
    else
      echo "${RED}\nexiting...${NOCOLOR}"
      return
    fi
  fi
  local currentBranch=$(git branch --show-current)
  echo -n "${LIGHTYELLOW}merge pull request from [ ${BLUE}$currentBranch${LIGHTYELLOW} ]: ${NOCOLOR}"
  read -k1
  if [[ ${REPLY} == $'\n' ]]; then
    local pr=($(gh pr list))
    if [[ $pr == "" ]]; then
      echo "${RED}no pull requests open found, exiting...${NOCOLOR}"
      if [[ $1 != "" ]]; then
        cd $currentpath
      fi
      return
    fi
    if [[ $(gh pr view --json reviews | jq '.reviews[].state') != *"APPROVED"* ]]; then
      echo "${RED}the pull request on this branch has not yet been approved, exiting...${NOCOLOR}"
      if [[ $1 != "" ]]; then
        cd $currentpath
      fi
      return
    fi
    local prbase=$(gh pr view --json baseRefName | jq '.baseRefName')
    prbase=${prbase//'"'/''}
    gh pr merge -m
    gco $prbase
    git pull
  else
    echo "${RED}\nexiting...${NOCOLOR}"
  fi
  if [[ $1 != "" ]]; then
    sleep 1
    cd $currentpath
  fi
}

# list all remote terraform repositories
function grlstf() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local clean=false
  if [[ $1 == '--clean' ]]; then
    local clean=true
  fi
  local knowntfs=$(cat $ZFUNCS_PATH/data/known-tf-repos.log)
  local nontfs=$(cat $ZFUNCS_PATH/data/known-non-tf-repos.log)
  local repos=$(gh repo list Bellese -L 1000 --no-archived | sort)
  repos=("${(@f)repos}")
  local totalrepos=${#repos[@]}
  local index=1
  if ! $clean; then
    echo "${LIGHTGREEN}searching for terraform repositories, this may take a few minutes...${NOCOLOR}"
  fi
  for repo in $repos
  do
    if ! $clean; then
      echo -ne "\r${LIGHTGREEN}[${LIGHTYELLOW} $index ${LIGHTGREEN}/ ${GREEN}$totalrepos ${LIGHTGREEN}]${NOCOLOR}"
      index=$(($index + 1))
    fi
    local name=($(echo $repo | xargs))
    name=$name[1]
    if [[ $knowntfs == *"::$name::"* || $nontfs == *"::$name::"* ]]; then
      continue
    else
      local repolang=$(curl -s -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token ${GH_AUTH_TOKEN}" "https://qnetgit.cms.gov/api/v3/repos/${name}/languages")
      if [[ $repolang == *"HCL"* ]]; then
        echo "::$name::" >> $ZFUNCS_PATH/data/known-tf-repos.log
      else
        local repobranches=($(curl -s -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token ${GH_AUTH_TOKEN}" "https://qnetgit.cms.gov/api/v3/repos/${name}/branches" | jq '.[].name' | xargs))
        local foundtf=false
        for branch in $repobranches
        do
          local escaped=${branch//"&"/"%26"}
          escaped=${escaped//"+"/"%2B"}
          local branchcontents=$(curl -s -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token ${GH_AUTH_TOKEN}" "https://qnetgit.cms.gov/api/v3/repos/${name}/contents/?ref=${escaped}" | jq '.[].name' | xargs)
          if [[ $branchcontents == *"main.tf"* ]]; then
            echo "::$name::" >> $ZFUNCS_PATH/data/known-tf-repos.log
            foundtf=true
            break
          fi
        done
        if ! $foundtf; then
          echo "::$name::" >> $ZFUNCS_PATH/data/known-non-tf-repos.log
        fi
      fi
    fi
  done
  if $clean; then
    local knowns=$(cat $ZFUNCS_PATH/data/known-tf-repos.log | xargs)
    knowns=${knowns//"Bellese\/"/""}
    knowns=${knowns//"::"/""}
    echo $knowns
  else 
    echo ""
    local knowns=$(cat $ZFUNCS_PATH/data/known-tf-repos.log)
    knowns=${knowns//"Bellese\/"/""}
    knowns=${knowns//"::"/""}
    echo $knowns
  fi
  if ! $clean; then
    local tfrepos=($(cat $ZFUNCS_PATH/data/known-tf-repos.log | xargs))
    echo "${LIGHTGREEN}total tf repos: [ ${LIGHTYELLOW}${#tfrepos[@]} ${LIGHTGREEN}/ ${GREEN}$totalrepos ${LIGHTGREEN}]${NOCOLOR}"
  fi
}