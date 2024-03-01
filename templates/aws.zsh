# print current aws account and workspace
function thisaws() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  echo "account: ${YELLOW}${AWS_PROFILE}${NOCOLOR}"
  echo "workspace: ${YELLOW}$(terraform workspace show)${NOCOLOR}"
}

# check if current or specific aws profile is still active
function stl() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local want
  local acc
  local env=$1
  local refresh=false
  if [[ $1 == "--refresh" || $1 == "-r" ]]; then
    env=$2
    refresh=true
  fi
  if [[ $env == "prod" ]]; then
    want="cms-hids-adele-ado2"
    acc=$AWS_PROD
  elif [[ $env == "sbx" || $env == "dev" || $env == "test" || $env == "impl" ]]; then
    want=$env
    if [[ $env == "sbx" ]]; then
      acc=$AWS_SBX
    elif [[ $env == "dev" ]]; then
      acc=$AWS_DEV
    elif [[ $env == "test" ]]; then
      acc=$AWS_TEST
    elif [[ $env == "impl" ]]; then
      acc=$AWS_IMPL
    fi
  elif [[ $env == "" ]]; then
    want=$(currentaws)
    env=$(currentaws)
    acc=$AWS_PROFILE
    if [[ $want == "prod" ]]; then
      want="cms-hids-adele-ado2"
    fi
  else
    echo "${RED}invalid account choice, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi
  local stsp=$(sauthp | grep $want)
  if [[ $stsp == *"active"* ]]; then
    echo "${GREEN}$want is active${NOCOLOR}"
    local stsexp=$(stsauth profiles -q "aws_credentials_expiry" $acc)
    local expireTime=${stsexp%%"."*}
    local currentTime=$(date +%s)
    local seconds=$(($expireTime - $currentTime))
    local remainingMinutes=$(($seconds / 60))
    local remainingSeconds=$(($seconds % 60))
    if [[ ${#remainingSeconds} == "1" ]]; then
      remainingSeconds="0$remainingSeconds"
    fi
    echo "${GREEN}remaining time: ${YELLOW}$remainingMinutes:$remainingSeconds${NOCOLOR}"
    if [[ $refresh == true ]]; then
      if (( $remainingMinutes < 10 )); then
        echo "${GREEN}refreshing for terraform...${NOCOLOR}"
        sauthl $env
      fi
    fi
  else
    echo "${YELLOW}$want is inactive...${NOCOLOR}"
    sauthl $env
  fi
  eval "aws$env"
}

# prints the shorthand of the current AWS account
function currentaws() { #noface
  if [[ $AWS_PROFILE == *"SBX"* ]]; then
    echo "sbx"
  elif [[ $AWS_PROFILE == *"DEV"* ]]; then
    echo "dev"
  elif [[ $AWS_PROFILE == *"TEST"* ]]; then
    echo "test"
  elif [[ $AWS_PROFILE == *"IMPL"* ]]; then
    echo "impl"
  else
    echo "prod"
  fi
}

# switch to an aws account and profile and refresh if profile is expired
function awsprof(){
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local acc=$1
  local wrk=$2
  if [[ $acc == "service" ]]; then
    acc="prod"
    wrk="default"
  fi
  if [[ $wrk == "" ]]; then
   wrk=$acc
  fi
  local validAccounts=(sbx dev test prod impl)
  # below conditional checks if 'validAccounts' array contains 'acc'
  if ! (($validAccounts[(I)$acc])); then
    echo "${RED}invalid account choice, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi
  echo "setting account to: ${YELLOW}$acc${NOCOLOR}"
  stl -r $acc
  rmtf
  echo "account: ${YELLOW}${AWS_PROFILE}${NOCOLOR}"
  tfiu
  terraform workspace select $wrk
  thisaws
}

# prints a list of currently deployed ECS service container image versions for a given environment
function showecs() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  local account=$1
  local env=''
  local type=$@[-1]
  local validtypes=('version' 'security')
  if [[ $account != 'sbx' && $account != 'dev' && $account != 'test' && $account != 'prod' ]]; then
    echo "${RED}invalid account, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi
  if [[ $type != 'version' && $type != 'security' ]]; then
    echo "${RED}invalid type, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi

  stl $account
  eval "aws$account"
  local clusters=$(aws ecs list-clusters | rg "arn")
  if [[ $account == 'prod' ]]; then
    if [[ $validtypes == *"$2"* ]]; then
      env=$account
    else
      env=$2
    fi
    clusters=$(echo $clusters | rg -i "$env")
  fi
  clusters=($(echo $clusters | xargs))  

  local clusternames=()
  for cluster in $clusters
  do
    cluster=${cluster/','/''}
    clusternames+=${cluster##*"/"}
  done
  for cluster in $clusternames
  do
    echo "${LAV}$cluster${NOCOLOR}"
    local services=($(aws ecs list-services --cluster $cluster | rg "arn" | xargs))
    for service in $services
    do
      service=${service/','/''}
      echo "${LAV}- ${GREEN}${service##*"/"}${NOCOLOR}"
      if [[ $type == 'security' ]]; then
        local securitygroups=$(aws ecs describe-services --cluster $cluster --service $service --query 'services[*].networkConfiguration.awsvpcConfiguration.securityGroups' | rg 'sg' | xargs)
        securitygroups=${securitygroups//','/''}
        local groups=(${(@s: :)securitygroups})
        for group in $groups
        do
          echo "${LAV}|   ${YELLOW}$group${NOCOLOR}"
        done
      else
        local servicedefinition=$(aws ecs describe-services --cluster $cluster --service $service | rg "taskDefinition" | xargs)
        servicedefinition=${servicedefinition%%","*}
        local currenttaskdefinition=${servicedefinition/'taskDefinition: '/''}
        local taskimage=$(aws ecs describe-task-definition --task-definition $currenttaskdefinition | rg 'image' | xargs)
        local taskimages=($(echo ${taskimage//'image: '/''} | xargs))
        local found=()
        for image in $taskimages
        do
          if [[ $found != *"$image"* ]]; then
            found+=$image
            image=${image/','/''}
            local taskname=${image##*".com/"}
            taskname=${taskname%%":"*}
            local taskversion=${image##*":"}
            echo "${LAV}|   ${YELLOW}$taskname${NOCOLOR}\n${LAV}|     ${BLUE}$taskversion${NOCOLOR}"
          fi
        done
      fi
    done   
  done
}

function checkssm() { #noface
  local sessionmanagercheck=$(which session-manager-plugin)
  if [[ $sessionmanagercheck == *"not found"* ]]; then
    echo "${YELLOW}downloading session manager plugin for awscli${NOCOLOR}"
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
    sleep .25
    unzip sessionmanager-bundle.zip
    sleep .25
    echo "${YELLOW}installing session manager plugin for awscli${NOCOLOR}"
    sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
  else
    echo "${LIGHTGREEN}session manager plugin for awscli already installed, skipping installation...${NOCOLOR}"
  fi
}

# cleans disk space on the jenkins agents in the prod account
function cleanjenkinsagents() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  stl -r prod
  awsprod
  checkssm
  local instanceids=($(aws ec2 describe-instances | jq '.Reservations[].Instances[] | select(.State.Name == "running")' | rg "InstanceId"))
  for id in $instanceids
  do
    if [[ $id != *"InstanceId"* ]]; then
      id=$(cut -d "\"" -f2 <<< $id)
      echo "instance: ${GREEN}$id${NOCOLOR}"
      local comment='clean jenkins agents'
      local command='sudo su - && docker system prune -af --volumes'
      local run=$(aws ssm send-command --instance-ids $id --document-name "AWS-RunShellScript" --comment "$comment" --parameters commands="$command" --output text)
      local runid=${run%%"$comment"*}
      runid=$(echo $runid | xargs)
      runid=${runid##*" "}
      local rundetails=$(aws ssm list-command-invocations --command-id $runid --details)
      local runstatus=$(echo $rundetails | rg "Status")
      while [[ $runstatus != *"Success"* ]];
      do
        echo "${YELLOW}docker system prune in progress...${NOCOLOR}"
        sleep 5
        rundetails=$(aws ssm list-command-invocations --command-id $runid --details)
        runstatus=$(echo $rundetails | rg "Status")
      done
      echo "${GREEN}docker system prune complete: ${NOCOLOR}"
      local output=$(aws ssm list-command-invocations --command-id $runid --details --query 'CommandInvocations[*].CommandPlugins[*].Output')
      output=$(echo $output | rg -v "\[|\]|\"")
      output=${output//'Deleted Containers:'/${BLUE}'Deleted Containers:'${NOCOLOR}}
      output=${output//'Deleted Images:'/${BLUE}'Deleted Images:'${NOCOLOR}}
      output=${output//'Deleted build cache objects:'/${BLUE}'Deleted build cache objects:'${NOCOLOR}}
      output=${output//'deleted:'/${GREEN}'deleted:'${NOCOLOR}}
      output=${output//'untagged:'/${LIGHTGREEN}'untagged:'${NOCOLOR}}
      if [[ $output == *"Total reclaimed"* ]]; then
        local runoutput=$(echo $output | rg "Total reclaimed" | xargs)
        local reclaimedsize=$(echo $runoutput | rg -o "( )[0-9.TGMB]*" | xargs)
        output=${output/$reclaimedsize/${GREEN}$reclaimedsize${NOCOLOR}}
      fi
      echo $output
      echo ""
    fi
  done
}

# shows available ec2 instances and connects to desired instance via ssm
function localssm() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  stl -r prod
  awsprod
  checkssm
  local jnkids=()
  local ghids=()
  local miscids=()
  local ids=""
  local instances=($(aws ec2 describe-instances | jq '[.Reservations[].Instances[] | select(.State.Name == "running")]' | jq ".[]" | jq '{id: .InstanceId, ip: .PrivateIpAddress, name: .Tags[] | select(.Key == "Name") | .Value, pdname: .Tags[] | select(.Key == "HCQISName") | .Value}' | jq -r '.id + "," + .ip + "," + .name + "," + .pdname' | xargs))
  for inst in $instances
  do
    inst=${inst//','/' '}
    local parts=($(echo $inst))
    local id=$parts[1]
    local ip=$parts[2]
    local instname=$parts[3]
    local pdname=$parts[4]
    if [[ $parts == *"jenkins-build-agent"* ]]; then
      jnkids+="${LIGHTYELLOW}${id} [ ${BLUE}$instname${LIGHTYELLOW} ] [ ${LIGHTGREEN}$pdname${LIGHTYELLOW} ] [ ${NOCOLOR}$ip${LIGHTYELLOW} ]${NOCOLOR}"
    elif [[ $parts == *"ghe"* ]]; then
      ghids+="${LIGHTYELLOW}${id} [ ${GREEN}$instname${LIGHTYELLOW} ] [ ${LIGHTGREEN}$pdname${LIGHTYELLOW} ] [ ${NOCOLOR}$ip${LIGHTYELLOW} ]${NOCOLOR}"
    else
      miscids+="${LIGHTYELLOW}${id} [ ${PINK}$instname${LIGHTYELLOW} ] [ ${LIGHTGREEN}$pdname${LIGHTYELLOW} ] [ ${NOCOLOR}$ip${LIGHTYELLOW} ]${NOCOLOR}"
    fi
  done
  local index=1
  for jnk in $jnkids
  do
    ids="${ids}\n${index}. $jnk\n"
    index=$(($index + 1))
  done
  for misc in $miscids
  do
    ids="${ids}\n${index}. $misc\n"
    index=$(($index + 1))
  done
  for gh in $ghids
  do
    ids="${ids}\n${index}. $gh\n"
    index=$(($index + 1))
  done
  local cleanIds=$(echo $ids | sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
  local fullChoice=""
  local choice=""
  if [[ $1 == '' ]]; then
    echo "\n${GREEN}available instances${NOCOLOR}"
    echo $ids
    local validchoice=false
    while ! $validchoice
    do
      echo -n "${GREEN}select an instance to connect to: ${NOCOLOR}"
      read idnumber
      if [[ $idnumber =~ '[0-9]' ]]; then
        if (( $idnumber < $index )); then
          choice=$(echo $cleanIds | rg -F "${idnumber}. " | head -1)
          fullChoice=$(echo $ids | rg -F "${idnumber}. " | head -1)
          choice=${choice##*". "}
          choice=${choice%%" ["*}
          validchoice=true
        else
          echo "${RED}invalid entry, try again...${NOCOLOR}"
        fi
      else
        echo "${RED}entry must be a number, try again...${NOCOLOR}"
      fi
    done
  else
    local filteredChoice=$(echo $cleanIds| rg -F "$1" | head -1)
    filteredChoice=${filteredChoice%%" i-"*}
    fullChoice=$(echo $ids | rg -F "$filteredChoice " | head -1)
    fullChoice=${fullChoice##*". "}
    choice=$(echo $cleanIds| rg -F "$1" | head -1)
    if [[ $choice == '' ]]; then
      echo "${RED}'$1' is an invalid instance, use '${PINK}$0 help${RED}' for more information.\nexiting${NOCOLOR}"
      return
    else
      choice=${choice##*". "}
      choice=${choice%%" ["*}
    fi
  fi
  if [[ $1 == '' ]]; then
    fullChoice="  $fullChoice"
  else
    fullChoice="- $fullChoice"
  fi
  echo "${GREEN}\nstarting session in${NOCOLOR}:\n$fullChoice"
  aws ssm start-session --target $choice
}

# show bootstrap process results on each ec2 instance
function bootstat() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  stl -r prod
  awsprod
  checkssm
  echo "${BLUE}==================================================${NOCOLOR}"
  echo "${LIGHTGREEN}$(date)${NOCOLOR}"
  echo "${LIGHTYELLOW}bootstrap process status check:${NOCOLOR}"
  echo "${BLUE}==================================================${NOCOLOR}"
  echo "${LIGHTGREEN}checking if bootstrap.log exists for:${NOCOLOR}"
  local ids=()
  local instances=$(aws ec2 describe-instances | jq -c '.Reservations[].Instances[] | select(.State.Name == "running")')
  echo $instances | while read -r line
  do 
    if [[ $line == *"jenkins-"* ]]; then
      local instid=$(echo $line | jq '.InstanceId' | xargs)
      echo -n "${LIGHTBLUE}instance: ${LIGHTYELLOW}$instid...${NOCOLOR}"
      local inststatus=$(aws ec2 describe-instance-status --instance-ids $instid | jq -c '.InstanceStatuses[]')
      if [[ $inststatus == *"initializing"* ]]; then
        echo "${RED}$instid is still initializing, skipping...${NOCOLOR}"
      else
        local bootcomment='check if bootstrap process is done'
        local bootcheckcommand='sudo su - && find /var/ansible/bootstrap.log'
        local bootrun=$(aws ssm send-command --instance-ids $instid --document-name "AWS-RunShellScript" --comment "$bootcomment" --parameters commands="$bootcheckcommand" --output text)
        local bootrunid=${bootrun%%"$bootcomment"*}
        bootrunid=$(echo $bootrunid | xargs)
        bootrunid=${bootrunid##*" "}
        local bootrundetails=$(aws ssm list-command-invocations --command-id $bootrunid --details)
        local bootrunstatus=$(echo $bootrundetails | rg "Status")
        while [[ $bootrunstatus != *"Success"* ]];
        do
          if [[ $bootrunstatus == *"Failed"* ]]; then
            break
          fi
          echo -n "${LIGHTYELLOW}.${NOCOLOR}"
          bootrundetails=$(aws ssm list-command-invocations --command-id $bootrunid --details)
          bootrunstatus=$(echo $bootrundetails | rg "Status")
          sleep .5
        done
        local bootoutput=$(aws ssm list-command-invocations --command-id $bootrunid --details --query 'CommandInvocations[*].CommandPlugins[*].Output')
        if [[ $bootoutput == *"No such file"* ]]; then
          echo "${ORANGE}not found, skipping...${NOCOLOR}"
        else
          echo "${LIGHTGREEN}found!${NOCOLOR}"
          ids+=$instid
        fi
      fi
    fi
  done
  echo "${BLUE}\n==================================================${NOCOLOR}"
  echo "${LIGHTYELLOW}bootstrap process results check:${NOCOLOR}"
  echo "${BLUE}==================================================${NOCOLOR}"
  local failedinstances=()
  for id in $ids
  do
    echo "${LIGHTBLUE}instance: ${GREEN}$id${NOCOLOR}"
    local comment='check bootstrap process'
    local command='sudo su - && tail /var/ansible/bootstrap.log -n 1'
    local run=$(aws ssm send-command --instance-ids $id --document-name "AWS-RunShellScript" --comment "$comment" --parameters commands="$command" --output text)
    local runid=${run%%"$comment"*}
    runid=$(echo $runid | xargs)
    runid=${runid##*" "}
    local rundetails=$(aws ssm list-command-invocations --command-id $runid --details)
    local runstatus=$(echo $rundetails | rg "Status")
    echo -n "${LIGHTYELLOW}bootstrap output fetching in progress...${NOCOLOR}"
    local timer=0
    local timeout=false
    while [[ $runstatus != *"Success"* ]];
    do
      rundetails=$(aws ssm list-command-invocations --command-id $runid --details)
      runstatus=$(echo $rundetails | rg "Status")
      sleep .5
      echo -n "${LIGHTYELLOW}.${NOCOLOR}"
      timer=$(($timer + 1))
      if (( $timer > 20 )); then
        timeout=true
        break
      fi
    done
    if $timeout; then
      echo "${RED}timeout!${NOCOLOR}"
      echo "${RED}timed out, skipping...${NOCOLOR}"
    else
      echo "${LIGHTGREEN}done!${NOCOLOR}"
      local output=$(aws ssm list-command-invocations --command-id $runid --details --query 'CommandInvocations[*].CommandPlugins[*].Output')
      if [[ $output == *"ok="* ]]; then
        if [[ $output == *"failed=0"* ]]; then
          echo "${LIGHTBLUE}-- ${GREEN}bootstrap process complete with 0 failures!${NOCOLOR}"
        else
          echo "${LIGHTBLUE}-- ${RED}bootstrap process failed!${NOCOLOR}"
          failedinstances+=$id
        fi
      else
        echo "${LIGHTBLUE}-- ${ORANGE}bootstrap process still in progress, check again later...${NOCOLOR}"
      fi
      echo ""
    fi
  done
  if [[ $1 == '--terminate-fails' ]]; then
    for inst in $failedinstances
    do
      echo "${LIGHTYELLOW}terminating instance: ${LIGHTBLUE}$inst${NOCOLOR}"
      aws ec2 terminate-instances --instance-ids $inst
    done
  fi
}

# terminate the instance of the provided instance id
function instakill() {
  if [[ $1 == 'help' && $2 == '' ]]; then
    zfunchelp $0
    return
  fi
  stl -r prod
  awsprod
  if [[ $1 == '' ]]; then
    echo "${RED}missing instance id parameter, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    return
  fi
  local terminate=$(aws ec2 terminate-instances --instance-ids $1)
  if [[ $terminate == *"Invalid id"* ]]; then
    echo "${RED}invalid id provided, exiting...${NOCOLOR}"
  else
    echo "${GREEN}terminating instance: ${LIGHTGREEN}$1${NOCOLOR}"
  fi
}
