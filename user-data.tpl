#!/bin/bash
cd ~
curl -sL https://deb.nodesource.com/setup_14.x -o setup.sh
sudo sh setup.sh
sudo apt update
sudo apt install nodejs

