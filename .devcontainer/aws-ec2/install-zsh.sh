#!/bin/bash

# Aim: install zsh and oh-my-zsh

sudo apt-get update
sudo apt-get install -yq zsh
sudo curl wget jq vim git-core gnupg locales
sudo apt-get clean

# non-root user, by default it's been set to `ubuntu`
NONROOTUSER='ubuntu'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true
chsh -s /bin/zsh ubuntu
# init zsh
export PATH=/home/$NONROOTUSER/miniconda/bin:$PATH
conda init zsh

