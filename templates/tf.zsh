# precommit install and run, check tfutils unused
function clup() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  prcinit
  tfutils unused
  precommit run -a
}

# terraform plan, add 'autover' to use 'getver' output
function tfp(){
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local append=${@:1:#}
  local autover=false
  local useTfvar=true
  stl --refresh
  local ls=$(ls)
  local workspace=$(terraform workspace show)
  if [[ $ls != *"$workspace.tfvars"* ]]; then
    echo "${YELLOW}did not find $workspace.tfvars${NOCOLOR}"
    useTfvar=false
  fi
  if [[ $1 == "autover" ]]; then
    autover=true
    append="${@:2:#} ${TFP_VARS}"
  fi
  local base="terraform plan -out $workspace.out "
  local vf="-var-file=$workspace.tfvars "
  local last=""
  if $useTfvar; then
    if [[ $append == *"-var-file"* ]]; then
      last="$base$append"
    else
      last="$base$vf$append"
    fi
  else
    last="$base$append"
  fi

  echo "Planning for account: ${YELLOW}$AWS_PROFILE${NOCOLOR}"
  echo "Planning for workspace: ${YELLOW}$workspace${NOCOLOR}"
  if $autover; then
    local tfpvars=$(echo ${TFP_VARS} | xargs)
    local varlist=(${(@s: :)tfpvars})
    echo "Using the following variable definitions:"
    for var in $varlist
    do
      if [[ $var == "-var" ]]; then
        continue
      else
        local varname=${var%%"="*}
        local version=${var##*"="}
        echo "${GREEN}- $varname${NOCOLOR} : ${YELLOW}$version${NOCOLOR}"
      fi
    done
  fi
  eval $last
}

# terraform apply
function tfa(){
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  stl --refresh
  local append=${@:1:#}
  local workspace=$(terraform workspace show)
  echo "Applying for account: ${YELLOW}$AWS_PROFILE${NOCOLOR}"
  echo "Applying for workspace: ${YELLOW}$workspace${NOCOLOR}"
  local cmd="terraform apply $workspace.out $append"
  eval $cmd
  sleep .25
  rm -rf $workspace.out
}

# terraform destroy
function tfd(){
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  stl --refresh
  local append=${@:1:#}
  local autover=false
  local useTfvar=true
  local ls=$(ls)
  local workspace=$(terraform workspace show)
  if [[ $ls != *"$workspace.tfvars"* ]]; then
    echo "${YELLOW}did not find $workspace.tfvars${NOCOLOR}"
    useTfvar=false
  fi
  local workspace=$(terraform workspace show)
  local base="terraform destroy"
  local vf="-var-file=$workspace.tfvars"
  local last=""
  if [[ $1 == "autover" ]]; then
    autover=true
    append=${@:2:#}
    append="$append ${TFP_VARS}"
  fi
  if [[ ! $useTfvar || $append == *"-var-file"* ]]; then
    last="$base $append"
  else
    last="$base $vf $append"
  fi
  echo "Destroying for account: ${YELLOW}$AWS_PROFILE${NOCOLOR}"
  echo "Destroying for workspace: ${YELLOW}$workspace${NOCOLOR}"
  if $autover; then
    local tfpvars=$(echo ${TFP_VARS} | xargs)
    local varlist=(${(@s: :)tfpvars})
    echo "Using the following variable definitions:"
    for var in $varlist
    do
      if [[ $var == "-var" ]]; then
        continue
      else
        local varname=${var%%"="*}
        local version=${var##*"="}
        echo "${GREEN}- $varname${NOCOLOR} : ${YELLOW}$version${NOCOLOR}"
      fi
    done
  fi
  eval $last
}

# terraform refresh
function tfr() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local useTfvar-true
  local ls=$(ls)
  local workspace=$(terraform workspace show)
  if [[ $ls != *"$workspace.tfvars"* ]]; then
    echo "${YELLOW}did not find $workspace.tfvars${NOCOLOR}"
    useTfvar=false
  fi
  if $useTfvar; then
    eval "terraform refresh -var-file=$workspace.tfvars"
  else
    terraform refresh
  fi
}

# terraform state list
function tfsl() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  thisaws
  tf state list
}

# terraform workspace select, also works with 'new' and 'list'
function tfw() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local option=$1
  local currrentworkspace=$(terraform workspace show)
  if [[ $option == $currrentworkspace ]]; then
    echo "${RED}already on $currrentworkspace${NOCOLOR}"
    return
  fi
  if [[ $option == "prod" || $option == "sbx" || $option == "dev" || $option == "test" ]]; then
    terraform workspace select $option
  elif [[ $option == "list" || $option == "show" ]]; then
    terraform workspace $option
  elif [[ $option == "new" || $option == "delete" ]]; then
    terraform workspace $option $2
  fi
}

# reset local workspace, set workspace or use the current account's
function restf() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  rmtf
  tfi
  if [[ $1 == '' ]]; then
    terraform workspace select $(currentaws)
  else
    terraform workspace select $1
  fi
}

# search and get terraform state resources that match filters
function tfstls() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local want=(${@:1:#})
  local color='always'
  if [[ $1 == '--no-color' ]]; then
    want=(${@:2:#})
    color='never'
  fi
  if [[ $want == "" ]]; then
    echo "${RED}search filter missing...${NOCOLOR}"
    return
  fi
  local searchCMD="tf state list "
  for var in $want
  do
    searchCMD="$searchCMD| rg -i --color=$color $var "
  done
  local found=$(eval $searchCMD)
  echo $found
}

# search and get the terraform state resource that matches a filter
function tfstget() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local want=${@:1:#}
  if [[ $want == "" ]]; then
    echo "${RED}search filter missing...${NOCOLOR}"
    return
  fi
  local searchCMD="tf state list "
  for var in ${@:1:#}
  do
    searchCMD="$searchCMD| rg -i --color=always $var "
  done
  echo "${YELLOW}searching for terraform state...${NOCOLOR}"
  local found=$(eval $searchCMD)
  echo $found
  if [[ $found == "" ]]; then
    echo "${RED}failed to find resource...${NOCOLOR}"
    return
  else
    local first=$(head -1 <<< $found | sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
    echo "${GREEN}[ found ]: ${NOCOLOR}${YELLOW}$first${NOCOLOR}"
    echo "${GREEN}[ result ]:${NOCOLOR}"
    tf state show $first
  fi
}

# search and get all terraform state resources that match the filter
function tfstgets() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local want=${@:1:#}
  if [[ $want == "" ]]; then
    echo "${RED}search filter missing...${NOCOLOR}"
    return
  fi
  local searchCMD="tf state list "
  for var in ${@:1:#}
  do
    searchCMD="$searchCMD| rg -i --color=always $var "
  done
  echo "${YELLOW}searching for terraform state...${NOCOLOR}"
  local found=$(eval $searchCMD)
  if [[ $found == "" ]]; then
    echo "${RED}failed to find resource...${NOCOLOR}"
    return
  else
    echo $found
    echo "${BLUE}[ found ]:${NOCOLOR}"
    local resources=("${(@f)found}")
    for item in $resources
    do
      echo "${YELLOW}-${NOCOLOR} $item"
    done
    echo -n "${BLUE}do you want to retrieve these: ${NOCOLOR}"
    read -k1
    if [[ ${REPLY} == $'\n' ]]; then
      for item in $resources
      do
        local first=$(echo $item | sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
        echo "${GREEN}[ getting state ]: ${NOCOLOR}${YELLOW}$item${NOCOLOR}"
        tf state show $first
      done
    else
      echo "${RED}\ncancelling open...${NOCOLOR}"
    fi
  fi
}

# get the image version or s3 keys of the current project's main resource(s)
function getver() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local type=$1
  local resource=$2
  stl -r
  if [[ $1 != "ms" && $1 != "fn" ]]; then
    local currPath=$(pwd)
    resource=$1
    if [[ $currPath == *"microservice"* || $currPath == *"ms"* ]]; then
      echo "${GREEN}this is a microservice project${NOCOLOR}"
      type="ms"
    elif [[ $currPath == *"function"* || $currPath == *"fn"* ]]; then
      echo "${GREEN}this is a lambda project${NOCOLOR}"
      type="fn"
    else
      echo "${RED}failed to determine main resource type, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
      return
    fi
  fi
  export TFP_VARS=""
  local fullmain=""
  local maintfs=$(ls | rg -v "tfvars" | rg ".tf" | rg -v "outputs.tf|variables.tf|.tfstate")
  maintfs=("${(@f)maintfs}")
  for maintf in $maintfs
  do
    local contents=$(cat $maintf)
    fullmain="$fullmain\n$contents"
  done
  fullmain=$(echo $fullmain | rg -U '(module |resource ).*(\n.*?)*(^\}$)')
  local fullvar=""
  local vartfs=$(ls | rg ".tfvars|variables.tf")
  vartfs=("${(@f)vartfs}")
  for vartf in $vartfs
  do
    local contents=$(cat $vartf)
    fullvar="$fullvar\n$contents"
  done
  echo "${YELLOW}searching terraform state for resource...${NOCOLOR}"
  if [[ $type == "ms" ]]; then
    varname="container_image_version"
    version=$(getresourceversion $type)
    echo "${YELLOW}$varname: ${BLUE}$version${NOCOLOR}"
    export TFP_VARS="${TFP_VARS}-var $varname=$version "
  elif [[ $type == "fn" ]]; then
    local resources=$(tfstls --no-color module aws_lambda_function $resource)
    resources=($(getstatename "$resources"))
    for resource in $resources
    do
      echo "module name: ${GREEN}$resource${NOCOLOR}"
      local block=$(echo $fullmain | rg -U "(module |resource ).*($resource).*(\n.*?)*(^\}$)")
      local s3key=$(echo $block | rg -U "(s3_key)")
      if [[ $s3key == *"("* && $s3key != *")"* ]]; then
        s3key=$(echo $block | rg -U '(s3_key).*(\n.*?)*(\)\n)')
      fi
      # echo $s3key
      local s3vars=$(echo $s3key | rg -o '(var)(.)[_a-z0-9]*')
      local vars=("${(@f)s3vars}")
      local version=""
      local varname=""
      if (( ${#vars[@]} == 1 )); then
        varname=$(echo $s3key | rg -o '(var)(.)[_a-z0-9]*')
        varname=${varname/'var.'/''}
        # echo $varname
        local cleans3key=$(echo $s3key | xargs)
        cleans3key=${cleans3key##*"s3_key = "}
        local s3keysuffix=$(echo $cleans3key | rg -o "($s3vars).*")
        local s3keyprefix=""
        if [[ $s3keysuffix[-1] == '}' ]]; then
          s3keyprefix=${cleans3key/"\${$s3keysuffix"/''}
        else
          s3keyprefix=${cleans3key/"$s3keysuffix"/''}
        fi
        version=$(getresourceversion $type $resource)
        version=${version/$s3keyprefix/''}
      else
        local removefromversion=()
        for var in $vars
        do
          varname=${var/'var.'/''}
          # echo $varname
          local matchingvariableblock=$(echo $fullvar | rg -U "(variable).*(\"$varname\"| $varname ).*(\{.*\})")
          if [[ $matchingvariableblock == "" ]]; then
            matchingvariableblock=$(echo $fullvar | rg -U "(variable).*(\"$varname\"| $varname ).*(\{\}|(\n.*?)*(^\}$))")
          fi
          if [[ $matchingvariableblock == *"default"*"="* ]]; then
            local vardefault=$(echo $matchingvariableblock | rg "(default).*" | xargs)
            vardefault=${vardefault/'default = '/''}
            removefromversion+=$vardefault
          else
            version=$(getresourceversion $type $resource)
          fi
        done
        for remove in $removefromversion
        do
          version=${version/$remove/''}
        done
        while ! [[ $version[1] =~ '[a-z0-9]' ]];
        do
          version=${version:1}
        done
      fi
      echo "${YELLOW}$varname: ${BLUE}$version${NOCOLOR}"
      export TFP_VARS="${TFP_VARS}-var $varname=$version "
    done
  fi
}

function getresourceversion() { #noface
  local type=$1
  local resource=$2
  local version=""
  if [[ $type == 'ms' ]]; then
    local state=$(tfstget aws_ecs_task_definition.task_definition)
    version=${state#*image}    
    version=${version#*\"}
    version=${version%%\"*}
    version=$(cut -d: -f2 <<< $version)
  elif [[ $type == 'fn' ]]; then
    local state=$(tfstget "module.$resource" aws_lambda_function.lambda)
    version=${state#*'s3_key'}
    version=${version#*\"}
    version=${version%%\"*}
  fi
  echo $version
}

function getstatename() { #noface
  local resources=$1
  resources=("${(@f)resources}")
  for resource in $resources
  do
    if [[ $resource == *"searching for terraform state..."* || $resource == *"[ contains ]"* ]]; then
      continue
    else
      local modulename=$(cut -d "." -f2 <<< $resource)
      echo $modulename
    fi
  done
}

# gets image version or s3 key in different environment
function getverenv() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local currentworkspace=$(tfw show)
  local currentaws=$(currentaws)
  local wantenv=$1
  local wantresource=(${@:2:#})
  local type=""
  local currPath=$(pwd)
  if [[ $2 == "ms" || $2 == "fn" ]]; then
    type=$2
    wantresource=(${@:3:#})
  elif [[ $currPath == *"microservice"* || $currPath == *"ms"* ]]; then
    echo "${LIGHTBLUE}this is a microservice project${NOCOLOR}"
    type="ms"
  elif [[ $currPath == *"function"* || $currPath == *"fn"* ]]; then
    echo "${LIGHTBLUE}this is a lambda project${NOCOLOR}"
    type="fn"
  else
    echo "${RED}failed to determine main resource type, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    eval "aws$currentaws"
    return
  fi
  if [[ $wantenv == "prod" || $wantenv == "test" ]]; then
    if [[ $type == "ms" ]]; then
      getverprod $wantenv $wantresource
    elif [[ $type == 'fn' ]]; then
      echo "${RED}checking lambda s3 key on prod or test environment not supported, exiting...${NOCOLOR}"
    fi
  elif [[ $wantenv == "sbx" || $wantenv == "dev" ]]; then
    stl $wantenv
    eval "aws$wantenv"
    local version=""
    if [[ $type == "ms" ]]; then
      local search=$(aws ecs list-task-definitions)
      for var in $wantresource
      do
        search="$search | rg -i --color=never '$var'"
      done
      local wantedtaskdef=$(eval $search)
      if [[ $wantedtaskdef == "" ]]; then
        echo "${RED}failed to find task definition matching : ${YELLOW}$wantresource${NOCOLOR}"
        return
      else
        local taskdef=$(cut -d "\"" -f2 <<< $wantedtaskdef)
        echo "${GREEN}found task definition : ${YELLOW}$taskdef${NOCOLOR}"
        local imageline=$(aws ecs describe-task-definition --task-definition $taskdef | rg "\"image\"")
        local valuepart=$(cut -d ":" -f2- <<< $imageline)
        local image=$(cut -d "\"" -f2 <<< $valuepart)
        version=${image##*":"}
        echo "${YELLOW}$varname in $wantenv: ${BLUE}$version${NOCOLOR}"
        export TFP_VARS="${TFP_VARS}-var container_image_version=$version "
      fi
      sleep .25
      eval "aws$currentaws"
    elif [[ $type == "fn" ]]; then
      stl -r $wantenv
      eval "aws$wantenv"
      tfw $wantenv
      getver
      eval "aws$currentaws"
      eval "tfw $currentworkspace"
    fi
  else 
    echo "${RED}invalid environment selected, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
  fi
}

function getverprod() { #noface
  local currentaws=$(currentaws)
  local wantenv=$1
  if [[ $wantenv != "prod" && $wantenv != "test" ]]; then 
    echo "${RED}first argument should be 'prod' or 'test'${NOCOLOR}"
    return
  fi
  stl prod
  awsprod
  local searchCMD="aws ecs list-task-definitions"
  for var in ${@:2:#}
  do
    searchCMD="$searchCMD | rg -i --color=never '$var'"
  done
  echo "${YELLOW}searching aws for desired task definitions...${NOCOLOR}"
  local wantedtaskdefs=$(eval $searchCMD)
  if [[ $wantedtaskdefs == "" ]]; then
      echo "${RED}failed to find matching task definition matching"
      return
  else
    local desired
    wantedtaskdefs=("${(@f)wantedtaskdefs}")
    for opt in $wantedtaskdefs
    do
      local name=$(cut -d "\"" -f2 <<< $opt)
      local check=$(aws ecs describe-task-definition --task-definition $name)
      if [[ $check == *"name"*"ENV"*"value"*"$wantenv"* ]]; then
        desired=$check
        break
      fi
    done
    local imageline=$(echo $desired | rg "\"image\":")
    local valuepart=$(cut -d ":" -f2- <<< $imageline)
    local image=$(cut -d "\"" -f2 <<< $valuepart)
    version=${image##*":"}
    echo "${YELLOW}$varname in $wantenv: ${BLUE}$version${NOCOLOR}"
    export TFP_VARS="${TFP_VARS}-var container_image_version=$version "
  fi
  sleep .25
  eval "aws$currentaws"
}

# gets the module/resource/data name in the current project's .tf files
function tftg() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local want
  local target

  local full=""
  local tfs=$(ls | rg -v "tfvars" | rg ".tf" | rg -v "outputs.tf|variables.tf")
  local files=("${(@f)tfs}")
  for file in $files
  do
    local contents=$(cat $file)
    full="$full\n$contents"
  done
  local searchCMD="echo '$full' | rg --color=always 'resource |module |data '"
  for var in ${@:1:#}
  do
    searchCMD="${searchCMD}| rg -i --color=always '$var' "
  done
  local found=$(eval $searchCMD)
  local first=$(head -1 <<< $found | sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
  if [[ $first == *"module"* ]]; then
    local dataType=$(cut -d " " -f1 <<< $first)
    local name=$(cut -d "\"" -f2 <<< $first)
    target="$dataType.$name"
  else
    local removeTerraformType=$(cut -d "\"" -f2- <<< $first)
    local dataType=$(cut -d "\"" -f1 <<< $removeTerraformType)
    local removeDataType=$(cut -d "\"" -f3- <<< $removeTerraformType)
    local name=${removeDataType%%"\" {"*}
    target="$dataType.$name"
  fi
  echo "${GREEN}target: ${YELLOW}$target${NOCOLOR}"
  local targetInput="-target $target"
  echo -n $targetInput | pbcopy
  echo "${GREEN}copied [ ${YELLOW}$targetInput${GREEN} ] to clipboard${NOCOLOR}"
}

# get a list of resources created in a desired branch, project selected by filter
function datadeps() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local currentpath=$(pwd)
  local wantbranch
  local needtoswitchbranch=false
  if [[ $1 != "epic" && $1 != "master" ]]; then
    echo "${RED}invalid branch selection, first parameter should be 'epic' or 'master'${NOCOLOR}"
    return
  else
    if [[ $1 == "epic" ]]; then
      wantbranch="epic/aws-account-breakout"
    else
      wantbranch=$1
    fi
  fi

  local searchCMD="ls $PROJECT_PATH"
  for filter in ${@:2:#}
  do
    searchCMD="${searchCMD} | rg -i --color=always '$filter'"
  done
  local found=$(eval $searchCMD)
  if [[ $found == "" ]]; then
    echo "${RED}failed to find matching projects, exiting...${NOCOLOR}"
    return
  else
    echo "${GREEN}[ found ]:${NOCOLOR}"
    echo $found
  fi
  local first=$(head -1 <<< $found | sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
  echo -n "${BLUE}do you want to search: [ ${YELLOW}$first${BLUE} ]: ${NOCOLOR}"
  read -k1
  if [[ ${REPLY} == $'\n' ]]; then
    echo "${BLUE}searching: ${YELLOW}$first${NOCOLOR}"
    cd "$PROJECT_PATH/$first"
    local currentbranch=$(git branch --show-current)
    if [[ $currentbranch == $wantbranch ]]; then
      echo "${ORANGE}already on desired branch, continuing...${NOCOLOR}"
    else
      needtoswitchbranch=true
      local gst=$(gst)
      if [[ $gst == *"nothing to commit, working tree clean"* ]]; then
        echo "${ORANGE}checking out desired branch...${NOCOLOR}"
        gco $wantbranch > /dev/null 2>&1
      else
        echo "${RED}current branch has changes, fix first...${NOCOLOR}"
        sleep .25
        cd $currentpath
        return
      fi
    fi
    if [[ $wantbranch == "epic/aws-account-breakout" ]]; then
      getdeps
    fi
    local full=""
    local tfs=$(ls | rg -v "tfvars" | rg ".tf" | rg -v "outputs.tf|variables.tf")
    local files=("${(@f)tfs}")
    for file in $files
    do
      local contents=$(cat $file)
      full="$full\n$contents"
    done
    local regexfilter='(module ).*\n.*(s3|rds|dynamodb|sqs)|(resource ).*(aws_s3_bucket |aws_s3_bucket" |aws_dyanmodb_table |aws_dynamodb_table" |sqs|aws_efs_file_system)'
    local foundresources=$(echo $full | rg -v "required_tags|aws_iam_role_policy_attachment" | rg -U $regexfilter)
    local modules=("${(@f)foundresources}")
    allmodules=""
    allresources=""
    for mod in $modules
    do
      if [[ $mod == *"resource "* ]]; then
        local resourcetype=$(cut -d " " -f2 <<< $mod)
        if [[ $resourcetype == *"\""* ]]; then
          resourcetype=$(cut -d "\"" -f2 <<< $resourcetype)
        fi
        local resourcename=$(cut -d " " -f3 <<< $mod)
        if [[ $resourcename == *"\""* ]]; then
          resourcename=$(cut -d "\"" -f2 <<< $resourcename)
        fi
        allresources="$allresources\n$resourcetype:$resourcename"
      elif [[ $mod == *"module "* ]]; then
        local modulename=$(cut -d " " -f2 <<< $mod)
        if [[ $modulename == *"\""* ]]; then
          modulename=$(cut -d "\"" -f2 <<< $modulename)
        fi
        allmodules="$allmodules\n$modulename:"
      elif [[ $mod == *" source "* ]]; then
        local source=$(cut -d "\"" -f2 <<< $mod)
        if [[ $mod == *"Bellese"* ]]; then
          source=${mod##*".gov/"}
          source=${source%%".git"*}
        fi
        allmodules="$allmodules$source"
      else
        continue
      fi
    done
    echo "${YELLOW}\n=============:[ CREATIONS ]:==============${NOCOLOR}"
    if [[ $allmodules == "" && $allresources == "" ]]; then
      echo "${RED}no creations${NOCOLOR}"
    else
      if [[ $allmodules != "" ]]; then
        echo "${PINK}modules:${NOCOLOR}"
        printcreatedmodules "rds-aurora" "rds"
        printcreatedmodules "aws-s3" "s3"
        printcreatedmodules "aws-dynamodb" "dynamodb"
        printcreatedmodules "sqs-queue" "sqs"
      fi
      if [[ $allmodules != "" ]]; then
        echo "${RED}  unaccounted modules:${NOCOLOR}"
        local remainingmodules=$(echo $allmodules | xargs)
        remainingmodules=("${(@s: :)remainingmodules}")
        for remmod in $remainingmodules
        do
          echo "   - $remmod"
        done
      fi
      if [[ $allresources != "" ]]; then
        echo "${PINK}resources:${NOCOLOR}"
        printcreatedresources "aws_s3_bucket"
        printcreatedresources "aws_dynamodb_table"
        printcreatedresources "aws_sqs_queue"
        printcreatedresources "aws_efs_file_system"
      fi
      if [[ $allresources != "" ]]; then
        echo "${RED}  unaccounted resources:${NOCOLOR}"
        local remainingresources=$(echo $allresources | xargs)
        remainingresources=("${(@s: :)remainingresources}")
        for remres in $remainingresources
        do
          echo "   - $remres"
        done
      fi
    fi
    sleep .25
    if [[ $needtoswitchbranch == true ]]; then
      echo "${ORANGE}reverting to original branch...${NOCOLOR}"
      gco $currentbranch > /dev/null 2>&1
    fi
  else
    echo "${RED}\ncancelling search...${NOCOLOR}"
  fi
  cd $currentpath
}

function printcreatedmodules() { #noface
  local awstype=$1
  local name=$2
  if [[ $allmodules == "" ]]; then
    return
  fi
  local modules=$(echo $allmodules | rg --color=never -F $awstype)
  if [[ $modules != "" ]]; then
    echo "${CYAN}  $name:${NOCOLOR}"
    modules=("${(@f)modules}")
    for module in $modules
    do
      echo "    - ${module%%":"*}"
      allmodules=$(echo $allmodules | rg -v -F $module)
    done
  fi
}

function printcreatedresources() { #noface
  local awstype=$1
  if [[ $allresources == "" ]]; then
    return
  fi
  local resources=$(echo $allresources | rg --color=never -F $awstype)
  if [[ $resources != "" ]]; then
    local name=${awstype##*"aws_"}
    echo "${CYAN}  $name:${NOCOLOR}"
    resources=("${(@f)resources}")
    for resource in $resources
    do
      echo "    - ${resource##*":"}"
      allresources=$(echo $allresources | rg -v -F $resource)
    done
  fi
}

function getdeps() { #noface
  local full=""
  local tfs=$(ls | rg -v "tfvars" | rg ".tf" | rg -v "outputs.tf|variables.tf")
  local files=("${(@f)tfs}")
  for file in $files
  do
    local contents=$(cat $file)
    full="$full\n$contents"
  done
  alldepends=""
  allremotes=""
  local excludes="terraform_remote_state|aws_iam_policy_document|aws_subnet|aws_caller_identity|aws_availability_zones|archive_file|aws_route53_zone|aws_acm_certificate|template_file|aws_vpc"
  local datas=$(echo $full | rg -v $excludes | rg -U "(data \").*(\n.*?)*(^\}$)" | rg -v "count|}" | sed '/^[[:space:]]*$/d')
  local remotes=$(echo $full | rg -v "operational_environment|service_environment" | rg -U '(data "terraform_remote_state").*(\n.*){1,5}(bucket)')

  local sources=$(echo "$datas\n$remotes" | rg -v "config = |backend =|region =")
  sources=$(echo $sources | sed '/^[[:space:]]*$/d') #removes empty lines from list
  sources=("${(@f)sources}")
  currentremotename=""
  currentremotebody=""
  for source in $sources
  do
    if [[ $source == *"terraform_remote_state"* ]]; then
      local remotestatename=$(cut -d " " -f3 <<< $source)
      if [[ $remotestatename == *"\""* ]]; then
        remotestatename=$(cut -d "\"" -f2 <<< $remotestatename)
      fi
      getremoteuses $remotestatename
    elif [[ $source == *"data "* ]]; then
      local awstype=$(cut -d " " -f2 <<< $source)
      if [[ $awstype == *"\""* ]]; then
        awstype=$(cut -d "\"" -f2 <<< $awstype)
      fi
      alldepends="$alldepends$awstype:"
    elif [[ $source == *"="* ]]; then
      local name=${source##*"= "}
      if [[ $name == *"\""* ]]; then
        name=$(cut -d "\"" -f2 <<< $name)
      fi
      if [[ $source == *"state.tf"* ]]; then
        allremotes="$allremotes$currentremotename${YELLOW}$name${NOCOLOR}\n$currentremotebody"
      else
        alldepends="$alldepends$name\n"
      fi
    else
      continue
    fi
  done
  echo "${YELLOW}\n============:[ DEPENDENCIES ]:============${NOCOLOR}"
  if [[ $alldepends == "" && $allremotes == "" ]]; then
    echo "${RED}no dependencies${NOCOLOR}"
  else
    if [[ $allremotes != "" ]]; then
      echo "${PINK}remotes:"
      echo -n $allremotes
    fi
    if [[ $alldepends != "" ]]; then
      echo "${PINK}data sources:"
      printdeps "aws_ssm_parameter"
      printdeps "aws_sqs_queue"
      printdeps "aws_security_group"
      printdeps "aws_s3_bucket"
      printdeps "aws_lambda_function"
      printdeps "aws_dynamodb_table"
    fi
    if [[ $alldepends != "" ]]; then
      echo "${RED}  unaccounted depends:${NOCOLOR}"
      local remainingdepends=$(echo $alldepends | xargs)
      remainingdepends=("${(@s: :)remainingdepends}")
      for remdepend in $remainingdepends
      do
        echo "   - $remdepend"
      done
    fi
  fi
}

function printdeps() { #noface
  local awstype=$1
  if [[ $alldepends == "" ]]; then
    return
  fi
  local depends=$(echo $alldepends | rg --color=never -F $awstype)
  if [[ $depends != "" ]]; then
    local name=${awstype##*"aws_"}
    echo "${CYAN}  $name:${NOCOLOR}"
    depends=("${(@f)depends}")
    for depend in $depends
    do
      echo "    - ${depend##*":"}"
      alldepends=$(echo $alldepends | rg -v -F $depend)
    done
  fi
}

function getremoteuses() { #noface
  local remotename=$1
  local full=""
  local tfs=$(ls | rg -v "tfvars" | rg -F ".tf" | rg -v "outputs.tf|variables.tf")
  local files=("${(@f)tfs}")
  for file in $files
  do
    local contents=$(cat $file)
    full="$full\n$contents"
  done

  currentremotename="${CYAN}  $remotename: ${NOCOLOR}"
  local remotebody=""
  local locals=$(echo $full | rg -U '(locals \{)(\n.*?)*(^\}$)')
  local localremote=$(echo $locals | rg "data.terraform_remote_state.$remotename")
  local alluses=""
  if [[ $localremote != "" ]]; then
    local localname=${localremote%%" ="*}
    localname=$(echo $localname | xargs)
    remotebody="${remotebody}${BLUE}    locals: ${LIGHTBLUE}$localname${NOCOLOR}\n"
    local localuses=$(echo $full | rg "(local\.)$localname(\.|\[|\))")
    localuses=("${(@f)localuses}")
    for localuse in $localuses
    do
      local localusage=${localuse##*"= "}
      localusage=$(echo $localusage | xargs)
      alluses="$alluses$localusage"
      remotebody="${remotebody}    - $localusage\n"
    done
  fi
  local searchotherscmds
  local others
  if [[ $localremote != "" ]]; then
    others=$(echo $full | rg -v $localremote | rg "data.terraform_remote_state.$remotename")
  else
    others=$(echo $full | rg "data.terraform_remote_state.$remotename")
  fi
  if [[ $others != "" ]]; then
    remotebody="${remotebody}${ORANGE}    others:${NOCOLOR}\n"
    others=("${(@f)others}")
    for other in $others
    do
      local otherusage="${other##*"= "}"
      otherusage=$(echo $otherusage | xargs)
      alluses="$alluses$otherusage"
      remotebody="${remotebody}    - $otherusage\n"
    done
  fi
  if [[ $alluses == "" ]]; then
    remotebody="${RED}  - remote state not in use and can be removed${NOCOLOR}"
  fi
  currentremotebody=$remotebody
}

# print migrated resources, use in graveyard project
function getgravemigrated() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local env=$1
  if [[ $env == "" ]]; then
    echo "${RED}env parameter required...${NOCOLOR}"
    return
  fi
  stl -r prod
  tfw $env
  local state=$(tf state list | rg "module" | rg "aws_rds_cluster_instance|aws_dynamodb_table")
  local rds=$(echo $state | rg 'aws_rds_cluster_instance')
  rds=("${(@f)rds}")
  if [[ $rds != "" ]]; then
    echo "${BLUE}rds:${NOCOLOR}"
    for db in $rds
    do
      local name=$(cut -d "." -f2 <<< $db)
      echo "${PINK}- ${LIGHTYELLOW}$name${NOCOLOR}"
    done
  fi
  local dynamo=$(echo $state | rg 'aws_dynamodb_table')
  dynamo=("${(@f)dynamo}")
  if [[ $dynamo != "" ]]; then
    echo "${BLUE}dynamodb:${NOCOLOR}"
    for table in $dynamo
    do
      local name=$(cut -d "." -f2 <<< $table)
      echo "${PINK}- ${LIGHTYELLOW}$name${NOCOLOR}"
    done
  fi
}

# Prints all created and dependent resources for a terraform project
function tfarch() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local full=""
  local tfs=$(ls | rg -v "tfvars" | rg -F ".tf" | rg -v "outputs.tf|variables.tf")
  local files=("${(@f)tfs}")
  for file in $files
  do
    local contents=$(cat $file)
    full="$full\n$contents"
  done
  getdeps
  echo "${YELLOW}\n==============:[ MODULES ]:===============${NOCOLOR}"
  local modulelist=()
  local modules=$(echo $full | rg -U "(module)( )(|\").*(|\")( \{\n)(.*source)")
  local modentries=("${(@f)modules}")
  local currentmodule=""
  for modentry in $modentries
  do
    if [[ $modentry == *"{"* ]]; then
      local name=${modentry##*"module "}
      name=${name/' {'/''}
      name=$(echo $name | xargs)
      currentmodule=$name
    else
      local source=$(echo $modentry | xargs)
      source=${source/'source = '/''}
      if [[ $source == *"git@qnetgit.cms.gov"* ]]; then
        source=${source##*"Bellese/"}
        source=${source%%".git"*}
      fi
      modulelist+="$currentmodule:$source"
    fi
  done
  declare -A modulemap
  for mod in $modulelist
  do
    local modtype=${mod##*":"}
    local modname=${mod%%":"*}
    if [[ $modulemap[$modtype] == '' ]]; then
      modulemap[$modtype]=$modname
    else
      modulemap[$modtype]="${modulemap[$modtype]},$modname"
    fi
  done
  for key val in ${(@kv)modulemap}
  do
    echo "${CYAN}$key${NOCOLOR}"
    local values=(${(@s:,:)val})
    for value in $values
    do
      echo " - $value"
    done
  done

  echo "${YELLOW}\n=============:[ RESOURCES ]:==============${NOCOLOR}"
  local resourcelist=()
  local resources=$(echo $full | rg "(resource)( )(|\").*(|\")( )(|\").*(|\")( \{)")
  local resentries=("${(@f)resources}")
  for resentry in $resentries
  do
    local name=$(cut -d "\"" -f4 <<< $resentry)
    local type=$(cut -d "\"" -f2 <<< $resentry)
    resourcelist+="$name:$type"
  done
  declare -A resourcemap
  for res in $resourcelist
  do
    local restype=${res##*":"}
    local resname=${res%%":"*}
    if [[ $resourcemap[$restype] == '' ]]; then
      resourcemap[$restype]=$resname
    else
      resourcemap[$restype]="${resourcemap[$restype]},$resname"
    fi
  done
  for key val in ${(@kv)resourcemap}
  do
    echo "${CYAN}$key${NOCOLOR}"
    local values=(${(@s:,:)val})
    for value in $values
    do
      echo " - $value"
    done
  done
}

# find all usages of a module in the terraform projects
function findtype() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  if [[ $1 == "" ]]; then
    echo "${RED}filter parameter missing, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi
  local filter=$1
  local search=""
  if [[ $filter == "s3" ]]; then
    search="hqr-tf-aws-s3|(resource ).*(aws_s3_bucket( |\"))"
  elif [[ $filter == "rds" ]]; then
    search="hqr-tf-aws-rds-aurora|(resource ).*(aws_rds_cluster( |\"))"
  elif [[ $filter == "sqs" ]]; then
    search="hqr-tf-aws-sqs-queue|(resource ).*(aws_sqs_queue( |\"))"
  elif [[ $filter == "ecs" ]]; then
    search="hqr-tf-aws-ecs-service|(resource ).*(aws_ecs_cluster( |\"))"
  elif [[ $filter == "iam" ]]; then
    search="hqr-tf-aws-iam-role|(resource ).*(aws_iam_role( |\"))"
  elif [[ $filter == "glue" ]]; then
    search="hqr-tf-aws-cdr-glue-job|(resource ).*(aws_glue_job( |\"))"
  elif [[ $filter == "dynamodb" ]]; then
    search="hqr-tf-aws-dynamodb|(resource ).*(aws_dynamodb_table( |\"))"
  elif [[ $filter == "lambda" ]]; then
    search="hqr-tf-aws-lambda-function|(resource ).*(aws_lambda_function( |\"))"
  elif [[ $filter == "redshift" ]]; then
    search="hqr-tf-aws-redshift|(resource ).*(aws_redshift_cluster( |\"))"
  elif [[ $filter == "sg" ]]; then
    search="hqr-tf-aws-security-group|(resource ).*(aws_security_group( |\"))"
  elif [[ $filter == "sns" ]]; then
    search="(resource ).*(aws_sns_topic( |\"))|(resource ).*(aws_sns_topic_subscription( |\"))"
  else
    echo "${RED}invalid parameter, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi
  local tfs=($(cat $ZFUNCS_PATH/data/known-tf-repos.log))
  local found=()
  echo "${LIGHTYELLOW}searching for ${LIGHTGREEN}$filter${LIGHTYELLOW} module uses...${NOCOLOR}"
  for tf in $tfs
  do
    local name=${tf//"::"/""}
    name=${name/"Bellese\/"/""}
    if [[ $(ls $PROJECT_PATH) != *"$name"* || $name == *"service-environment"* ]]; then
      continue
    fi
    local files=($(ls $PROJECT_PATH/$name| rg -v ".tfvars|.tfstate" | rg "(\.tf)"))
    local branch=$(getprojectbranch $name)
    local currentfile=""
    local currentproject=""
    for file in $files
    do
      local check=$(cat $PROJECT_PATH/$name/$file | rg "$search")
      local checks=("${(@f)check}")
      local countinfile=${#checks[@]}
      if [[ $check != "" ]]; then
        if [[ $name != $currentproject ]]; then
          echo "${BLUE}$name${NOCOLOR}: [ ${LIGHTYELLOW}$branch${NOCOLOR} ]"
        fi
        currentproject=$name
        if [[ $file != $currentfile ]]; then
          echo "  ${LIGHTGREEN}$file${NOCOLOR}:"
        fi
        currentfile=$file
        for ch in $checks
        do
          if [[ $ch == *"resource"* ]]; then
            local resname=${ch//"\""/""}
            resname=$(cut -d " " -f3 <<< $resname)
            echo "    ${ORANGE}$resname${NOCOLOR}"
          elif [[ $ch == *"modules"* ]]; then
            local modulepath=$(echo $ch | xargs)
            modulepath=${modulepath/"source = "/""}
            modulepath=${modulepath/".\/"/""}
            echo "    ${LIGHT}$modulepath${NOCOLOR}"
          else
            local version=$(echo $ch | rg -o "(ref=).*")
            version=${version//"\""/""}
            version=${version//"ref="/""}
            if [[ $2 == "" ]]; then
              echo "    ${LIGHTYELLOW}$version${NOCOLOR}"
            else
              if [[ $version == *"$2"* ]]; then
                echo "    ${PINK}$version${NOCOLOR}"
              else
                echo "    ${LIGHTYELLOW}$version${NOCOLOR}"
              fi
            fi
          fi
        done
      fi
    done
  done
}