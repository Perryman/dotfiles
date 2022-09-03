#!/bin/bash

### TO USE RUN THIS COMMAND:
### curl https://raw.githubusercontent.com/Perryman/dotfiles/main/attackbox.sh && chmod +x attackbox.sh && attackbox.sh

# Delete the symlink to /dev/null
rm .bash_history
# Create the file again
touch .bash_history


# Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install


# Install stegoveritas
pip install stegoveritas
# Get some dependencies...  This comes with the python package
stegoveritas_install_deps
pip install -U Pillow
pip install -U numpy

# Install mediainfo from apt package manager
sudo apt -y install mediainfo  

# Install zsteg from ruby gems
gem install zsteg

### Might need to restart the shell after this to make sure paths are up to date and stuff. and rc files.
/bin/bash
