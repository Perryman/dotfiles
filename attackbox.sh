#!/bin/bash

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
