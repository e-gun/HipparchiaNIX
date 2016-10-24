#!/bin/sh

# to kill local changes
# git fetch --all
# git reset --hard master

cd ~/venv/HipparchiaServer/ && git init && git pull https://github.com/e-gun/HipparchiaServer.git
cd ~/venv/HipparchiaBuilder/ && git init && git pull https://github.com/e-gun/HipparchiaBuilder.git
cd ~/venv/HipparchiaSQLoader/ && git init && git pull https://github.com/e-gun/HipparchiaSQLoader.git
cd ~/venv/HipparchiaBSD/ && git init && git pull https://github.com/e-gun/HipparchiaBSD.git

cd ~
~/circusctl restart