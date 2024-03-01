#Zsetup script to setup a macbook for a dev environment
#brew_pkgs=(awscli clocker docker docker-compose gh itsycal jq libreoffice lsd packer py-tf-utils pip ripgrep precommit zsh-autosuggestions)
brew_pkgs=(ansible ansible-lint docker gh git itsycal magic-wormhole lsd pip zsh-autosuggestions)

cmd=$1
flags=${@:2:#}
brewexists=$(which brew)
pipexists=$(which pip) 
brewlist=$(brew list)
   
if [[ $cmd == "init" ]]; then
  # setup projects directory
  local homels=$(ls ~)
  if [[ $homels != *"projects"* ]]; then
    mkdir ~/projects
  else
    echo "project directory : already found in home directory"
    echo "skipping..."
fi

# install homebrew
if [[ $brewexists == *"not found"* ]]; then
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
   echo "brew : already installed"
   echo "skipping..."
fi
    
# Install PIP 
if [[ $pipexists == *"not found"* ]]; then
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  python3 get-pip.py
else
  echo "pip : already installed"
  echo "skipping..."
fi

# Install Homebrew Packages 
for i in `$brew_pkgs[@]`; do 
  print -r -- $i
# install brew packages for loop  
  if [[ $brewlist == *$i* ]]; then
     echo " $i : already installed"
     echo "skipping..."
   else
     brew install $i
   fi  

echo "Setting up Vundle (Vim Plugin Manager) "
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
if [[ ! -f ~/.vimrc ]]; then
  echo "vimrc file NOT found!! "
  echo "Setting up vimrc"
  cp vimrc ~/.vimrc    
  vim +PluginInstall +qall
else 
  echo "vimrc file found"
  echo "Installing Vim Plugins" 
  vim +PluginInstall +qall
fi


echo "Running ansible playbook"
ansible-playbook playbook.yml 


