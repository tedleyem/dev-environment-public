export NOCOLOR='\033[0m'
export RED='\033[38;5;204m'
export ORANGE='\033[38;5;209m'
export YELLOW='\033[38;5;11m'
export LIGHTYELLOW='\033[38;5;222m'
export LIGHTGREEN='\033[38;5;193m'
export GREEN='\033[38;5;10m'
export CYAN='\033[38;5;49m'
export LIGHTBLUE='\033[38;5;159m'
export BLUE='\033[38;5;117m'
export LAV='\033[38;5;147m'
export PINK='\033[38;5;212m'
export LIGHT='\033[38;5;225m'

# initialization and update of simon-zfuncs
function zetup() {
  local cmd=$1
  local flags=${@:2:#}
  if [[ $cmd == "init" ]]; then
    # setup projects directory
    local homels=$(ls ~)
    if [[ $homels != *"projects"* ]]; then
      mkdir ~/projects
    else
      echo "${CYAN}- ${YELLOW}project directory ${NOCOLOR}: already found in home directory"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    fi
    # install homebrew
    local brewexists=$(which brew)
    if [[ $brewexists == *"not found"* ]]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo "${CYAN}- ${YELLOW}brew ${NOCOLOR}: already installed"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    fi

    # install pip
    local pipexists=$(which pip)
    if [[ $pipexists == *"not found"* ]]; then
      curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
      python3 get-pip.py
    else
      echo "${CYAN}- ${YELLOW}pip ${NOCOLOR}: already installed"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    fi

    local brewlist=$(brew list)
    # install ripgrep
    if [[ $brewlist == *"ripgrep"* ]]; then
      echo "${CYAN}- ${YELLOW}ripgrep ${NOCOLOR}: already installed"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    else
      brew install ripgrep
    fi
    # install pyenv
    if [[ $brewlist == *"pyenv"* ]]; then
      echo "${CYAN}- ${YELLOW}pyenv ${NOCOLOR}: already installed"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    else
      brew install pyenv
    fi
    # install tfenv
    if [[ $brewlist == *"tfenv"* ]]; then
      echo "${CYAN}- ${YELLOW}tfenv ${NOCOLOR}: already installed"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    else
      brew install tfenv
    fi 
    # install awscli
    if [[ $brewlist == *"awscli"* ]]; then
      echo "${CYAN}- ${YELLOW}awscli ${NOCOLOR}: already installed"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    else
      brew install awscli
    fi
    # install github cli
    if [[ $brewlist == *"gh"* ]]; then
      local whichgh=$(which gh)
      if [[ $whichgh != *"not found"* ]]; then
        echo "${CYAN}- ${YELLOW}github cli ${NOCOLOR}: already installed"
        echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
      else
        brew install gh
      fi
    else
      brew install gh
    fi
    # install lsd
    if [[ $brewlist == *"lsd"* ]]; then
      local whichlsd=$(which lsd)
      if [[ $whichgh != *"not found"* ]]; then
        echo "${CYAN}- ${YELLOW}lsd ${NOCOLOR}: already installed"
        echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
      else
        brew install lsd
      fi
    else
      brew install lsd
    fi
    # install packer
    if [[ $brewlist == *"packer"* ]]; then
      local whichjq=$(which packer)
      if [[ $whichjq != *"not found"* ]]; then
        echo "${CYAN}- ${YELLOW}packer ${NOCOLOR}: already installed"
        echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
      else
        brew install packer
      fi
    else
      brew install packer
    fi
    # install docker
    if [[ $brewlist == *"docker"* ]]; then
      local whichjq=$(which docker)
      if [[ $whichjq != *"not found"* ]]; then
        echo "${CYAN}- ${YELLOW}docker ${NOCOLOR}: already installed"
        echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
      else
        brew install docker
      fi
    else
      brew install docker
    fi
    # install docker-compose
    if [[ $brewlist == *"docker-compose"* ]]; then
      local whichjq=$(which docker-compose)
      if [[ $whichjq != *"not found"* ]]; then
        echo "${CYAN}- ${YELLOW}docker-compose ${NOCOLOR}: already installed"
        echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
      else
        brew install docker-compose
      fi
    else
      brew install docker-compose
    fi
    # install jq
    if [[ $brewlist == *"jq"* ]]; then
      local whichjq=$(which jq)
      if [[ $whichjq != *"not found"* ]]; then
        echo "${CYAN}- ${YELLOW}jq ${NOCOLOR}: already installed"
        echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
      else
        brew install jq
      fi
    else
      brew install jq
    fi
    # install tfutils
    local piplist=$(pip list)
    if [[ $piplist == *"py-tf-utils"* ]]; then
      echo "${CYAN}- ${YELLOW}tfutils ${NOCOLOR}: already installed"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    else
      pip install py-tf-utils
    fi
    # setup plugins
    if [[ $flags == *"--no-plugs"* ]]; then
      echo "${YELLOW}skipping plugin setup...${NOCOLOR}"
    else
      local oldzshrc=$(cat ~/.zshrc)
      local oldplugs=$(echo $oldzshrc | rg -U "^(plugins=\()(\n.*?)*(\))|^(plugins=\().*(\))")
      oldplugs=${oldplugs%%")"*}
      oldplugs=${oldplugs##*"("}
      oldplugs=$(echo $oldplugs | xargs)
      oldplugs=(${(@s: :)oldplugs})
      local zshcustoms=$(ls ${ZSH_CUSTOM}/plugins)
      local replaceplugins=false
      if [[ $oldplugs != *"zsh-autosuggestions"* ]]; then
        if [[ $zshcustoms == *"zsh-autosuggestions"* ]]; then
          echo "${CYAN}- ${YELLOW}zsh-autosuggestions ${NOCOLOR}: already installed"
          echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
        else
          git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        fi
        oldplugs+='zsh-autosuggestions'
        replaceplugins=true
      fi
      if [[ $oldplugs != *"zsh-syntax-highlighting"* ]]; then
        if [[ $zshcustoms == *"zsh-syntax-highlighting"* ]]; then
          echo "${CYAN}- ${YELLOW}zsh-syntax-highlighting ${NOCOLOR}: already installed"
          echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
        else
          git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        fi
        oldplugs+='zsh-syntax-highlighting'
        replaceplugins=true
      fi
      if [[ $oldplugs != *"zsh-completions"* ]]; then
        if [[ $zshcustoms == *"zsh-completions"* ]]; then
          echo "${CYAN}- ${YELLOW}zsh-completions ${NOCOLOR}: already installed"
          echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
        else
          git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
        fi
        oldplugs+='zsh-completions'
        replaceplugins=true
      fi
      if $replaceplugins; then
        local oldzshrc=$(cat ~/.zshrc)
        local oldpluginblock=$(echo $oldzshrc | rg -U "^(plugins=\()(\n.*?)*(\))|^(plugins=\().*(\))")
        local newpluginblock='plugins=('
        for plug in $oldplugs
        do
          newpluginblock="$newpluginblock\n  $plug"
        done
        newpluginblock="$newpluginblock\n)"
        local updatedpluginszshrc=${oldzshrc/$oldpluginblock/$newpluginblock}
        echo $updatedpluginszshrc > ~/.zshrc
        echo "${GREEN}updated zsh plugins${NOCOLOR}"
      else
        echo "${CYAN}- ${YELLOW}plugins list ${NOCOLOR}: already contain desired plugins"
        echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
      fi
    fi

    # setup colors
    local oldzshrc=$(cat ~/.zshrc)
    local setupcolors=$(cat $ZFUNCS_PATH/templates/setup-template-colors.sh)
    if [[ $oldzshrc != *"$setupcolors"* ]]; then
      echo "" >> ~/.zshrc
      cat $ZFUNCS_PATH/templates/setup-template-colors.sh >> ~/.zshrc
      source ~/.zshrc
    else
      echo "${CYAN}- ${YELLOW}color codes ${NOCOLOR}: already found"
      echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
    fi

    # zshrc template setup
    local setuptemplate=$(cat $ZFUNCS_PATH/templates/setup-template.sh)
    local oldzshrc=$(cat ~/.zshrc)
    local oldtemplate=$(echo $oldzshrc | rg -U '(# \[DO NOT REMOVE\] template-start)(\n.*)*(# \[DO NOT REMOVE\] template-end)')
    if [[ $flags == *"--no-cred"* ]]; then
      local currentid=$(echo $oldzshrc | rg '(export).*(QUALNET_EMAIL)')
      local currentpassword=$(echo $oldzshrc | rg -m1 '(stsauth authenticate)')
      if [[ $currentid != "" && $currentpassword != "" ]]; then
        currentid=${currentid##*"="}
        currentid=$(echo $currentid | xargs)
        currentid=${currentid%%"@"*}
        setuptemplate=${setuptemplate/'{ ADFS_ID }'/$currentid}
        currentpassword=${currentpassword##*"-p "}
        currentpassword=$(echo "'$currentpassword" | xargs)
        currentpassword=${currentpassword%%"@"*}
        setuptemplate=${setuptemplate/'{ ADFS_PASSWORD }'/$currentpassword}
      else
        echo "${YELLOW}'--no-cred' option found, but failed to find current ADFS id and password${NOCOLOR}"
        echo -n "${BLUE}Enter your ADFS ID: ${NOCOLOR}"
        read adfsid
        setuptemplate=${setuptemplate/'{ ADFS_ID }'/$adfsid}
        echo -n "${BLUE}Enter your ADFS Password: ${NOCOLOR}"
        read adfspassword
        setuptemplate=${setuptemplate/'{ ADFS_PASSWORD }'/$adfspassword}
      fi
    else
      echo -n "${BLUE}Enter your ADFS ID: ${NOCOLOR}"
      read adfsid
      setuptemplate=${setuptemplate/'{ ADFS_ID }'/$adfsid}
      echo -n "${BLUE}Enter your ADFS Password: ${NOCOLOR}"
      read adfspassword
      setuptemplate=${setuptemplate/'{ ADFS_PASSWORD }'/$adfspassword}
    fi
    local validide=false
    while ! $validide;
    do
      echo -n "${BLUE}Enter you default IDE [ 'intellij' or 'vscode' ]: ${NOCOLOR}"
      read defaultide
      if [[ $defaultide == 'intellij' ]]; then
        validide=true
        setuptemplate=${setuptemplate/'{ DEFAULT_IDE }'/'idea'}
      elif [[ $defaultide == 'vscode' ]]; then
        validide=true
        setuptemplate=${setuptemplate/'{ DEFAULT_IDE }'/'code'}
      else
        echo "${RED}invalid IDE selected, try again...${NOCOLOR}"
      fi
    done
    
    if [[ $oldtemplate == "" ]]; then
      echo "\n$setuptemplate" >> ~/.zshrc
    else
      local newzshrc=${oldzshrc/$oldtemplate/$setuptemplate}
      printf '%s' $newzshrc > ~/.zshrc
    fi

    source ~/.zshrc
    echo "${CYAN}\n[ Initialization Complete! ]\n${NOCOLOR}"
  elif [[ $cmd == "update" ]]; then
    local currentpath=$(pwd)
    cd $ZFUNCS_PATH
    local branch=$(git branch --show-current)
    if [[ $branch != "master" ]]; then
      local gst=$(gst)
      if [[ $gst != "nothing to commit" ]]; then
        echo "${RED}zfuncs project directory not on master and current branch has changes.\nCommit and push up any changes and then run this command again, exiting...${NOCOLOR}"
        return
      else
        git checkout master
      fi
    fi
    git pull
    cd $currentpath
    srcz
  elif [[ $cmd == "help" ]]; then
    zfunchelp $0
  else
    echo "${RED}invalid command, use '${PINK}$0 help${RED}' for more information.\nexiting...${NOCOLOR}"
    echo "${YELLOW}run 'zimon help' for a list of available commands${NOCOLOR}"
  fi
}




if [[ $oldplugs != *"zsh-autosuggestions"* ]]; then
  if [[ $zshcustoms == *"zsh-autosuggestions"* ]]; then
    echo "${CYAN}- ${YELLOW}zsh-autosuggestions ${NOCOLOR}: already installed"
    echo "${CYAN}-- ${GREEN}skipping...${NOCOLOR}"
  else
  git clone https://github.com/t-lastname/wallpaper-dumps ~/Pictures/wallpaper 
  fi 
fi