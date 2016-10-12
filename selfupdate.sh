#!/bin/sh

#curl http://antisigma.classics.utoronto.ca/hipp/hb.tgz > ~/venv/hb.tgz
#curl http://antisigma.classics.utoronto.ca/hipp/hs.tgz > ~/venv/hs.tgz
#cd ~/venv/
#tar zvxf ./hb.tgz
#tar zvxf ./hs.tgz

# to kill local changes
# git fetch --all
# git reset --hard master

cd ~/venv/HipparchiaBuilder/
git pull https://github.com/e-gun/HipparchiaBuilder.git
cd ~/venv/HipparchiaServer/
git pull https://github.com/e-gun/HipparchiaServer.git
cd ~/venv/HipparchiaSQLoader/
git pull https://github.com/e-gun/HipparchiaSQLoader.git
cd ~

# ~/circusctl stop && sleep 2 && ~/circusctl start
~/circusctl restart