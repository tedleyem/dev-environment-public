# dev-environment-setup
 
This dev-env will install and configure your 
dev environment for fresh installed versions of Ubuntu or OSX

This is a public repo, my personal one has much more specific tools
and aliases that are being used. 
Feel free to modify as you wish. 

# devops tools being installed
ansible 
docker 
gh-cli 
packer
terraform 

### VIMRC SETUP 
whenever you want to install a new plug-in hosted on GitHub, 
you can specify it using the format Plugin '<github_account>/<repository_name>' 
between the call vundle#begin(..) and call vundle#end() lines. 
Also take note that repositories will be downloaded into the ~/.vim/plugged/ directory on the file system.

```
$ cp vimrc ~/.vimrc
# In Vim
:PluginInstall -- Install an individual Plugin 
:PluginClean -- Update and remove commented out Plugins 
```

