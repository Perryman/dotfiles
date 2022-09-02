#!/bin/bash

# Install stegoveritas
pip install stegoveritas
# Get some dependencies...
stegoveritas_install_deps
pip install -U Pillow
pip install -U numpy

# Install mediainfo
sudo apt -y install mediainfo  
