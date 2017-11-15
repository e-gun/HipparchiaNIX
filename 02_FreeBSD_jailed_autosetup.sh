#!/bin/sh

# qemu installation of FreeBSD itself
# /usr/local/bin/qemu-img create -f raw -o size=14G ./qemu-freebsd.raw
# /usr/local/bin/qemu-system-x86_64 -display vnc=localhost:1 -cdrom ./FreeBSD-11.0-RELEASE-i386-dvd1.iso -drive file=./qemu-freebsd.raw,format=raw -boot d
# /usr/local/bin/qemu-system-x86_64 -display vnc=localhost:1 -drive file=./qemu-freebsd.raw,format=raw -boot d -smp 3 \
# -device e1000,netdev=network0,mac=52:54:00:12:34:56 -netdev user,id=network0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8888-:80 

HUSER="huser"
HJAIL="hipparchia"
PJAIL="sql"
JAILHOME="/usr/jails/$HJAIL/usr/home/$HUSER"
HIPPHOME="$JAILHOME/hipparchia_venv"
SERVERPATH="$HIPPHOME/HipparchiaServer"
BUILDERPATH="$HIPPHOME/HipparchiaBuilder"
LOADERPATH="$HIPPHOME/HipparchiaSQLoader"
BSDPATH="$HIPPHOME/HipparchiaBSD"
MACPATH="$HIPPHOME/HipparchiaMacOS"
DATAPATH="$HIPPHOME/HipparchiaData"
THEDB="hipparchiaDB"


su root
	root# pkg install nano nginx python36 rsync sudo postgresql96-server postgresql96-contrib curl git-lite
	root# visudo [and add huser]
	root# printf "\033[31mHipparchia Server\033[0m" > /etc/issue
	root# printf "\n\n\t\tWelcome to \033[31mHipparchia Server\033[0m\n\n\n" > /etc/motd
	root# exit

mkdir ~/hipparchia_venv logs run
mkdir ~/hipparchia_venv/HipparchiaData ~/hipparchia_venv/HipparchiaServer ~/hipparchia_venv/HipparchiaSQLoader ~/hipparchia_venv/HipparchiaBuilder ~/hipparchia_venv/HipparchiaBSD
cd ~/hipparchia_venv/HipparchiaServer/ && git init && git pull https://github.com/e-gun/HipparchiaServer.git
cd ~/hipparchia_venv/HipparchiaBuilder/ && git init && git pull https://github.com/e-gun/HipparchiaBuilder.git
cd ~/hipparchia_venv/HipparchiaSQLoader/ && git init && git pull https://github.com/e-gun/HipparchiaSQLoader.git
cd ~/hipparchia_venv/HipparchiaBSD/ && git init && git pull https://github.com/e-gun/HipparchiaBSD.git

sudo su root
	root# cat ~huser/hipparchia_venv/HipparchiaBSD/rc_conf.txt >> /etc/rc.conf
	root# /usr/local/etc/rc.d/postgresql initdb
	root# nano /var/db/postgres/data96/postgresql.conf [shared_buffers = 256MB]
	root# /usr/local/etc/rc.d/postgresql start
	root# exit

sudo su postgres
	postgres$ createdb hipparchiaDB
	postgres$ /usr/local/bin/psql -d hipparchiaDB -a -f ~huser/hipparchia_venv/HipparchiaBuilder/builder/sql/sample_generate_hipparchia_dbs.sql
	psql hipparchiaDB
		# [insert sql via generate_hipparchia_dbs.sql]
		# [but for the ownership problems it is: psql -d hipparchiaDB -a -f ~/hipparchia_venv/HipparchiaBuilder/builder/sql/sample_generate_hipparchia_dbs.sql]
		# [need two roles (hippa_wr & hippa_rd) and authors and works tables]
			#	\password hippa_wr
			#	\password hippa_rd
			#	\q
	postgres$ exit

cp ~/hipparchia_venv/HipparchiaBSD/uwsgi.ini ~/uwsgi.ini
cp ~/hipparchia_venv/HipparchiaBSD/selfupdate.sh ~/selfupdate.sh
cp ~/hipparchia_venv/HipparchiaBSD/cshrc.txt ~/.cshrc
source ~/.cshrc 
sudo cp ~/hipparchia_venv/HipparchiaBSD/ngingx_conf.txt /usr/local/etc/nginx/nginx.conf
sudo cp ~/hipparchia_venv/HipparchiaBSD/circusd.ini /usr/local/etc/circusd.ini
sudo cp ~/hipparchia_venv/HipparchiaBSD/circusd /usr/local/etc/rc.d/circusd
# you had best check the pf.conf rules lest you lock yourself out...
# if you don't know how to set them properly, then skipping the next it is the least bad option
sudo cp ~/hipparchia_venv/HipparchiaBSD/pf_conf.txt /etc/pf.conf


/usr/local/bin/python3.6 -m venv ~/hipparchia_venv/
source ~/hipparchia_venv/bin/activate.csh
~/hipparchia_venv/bin/pip3 install bs4 circus flask psycopg2 uWSGI websockets

ln -s ~/hipparchia_venv/bin/circusctl ~/circusctl
ln -s /usr/local/etc/circusd.ini ~/the_circusd.ini
sudo cp ~/hipparchia_venv/bin/circusd /usr/local/bin/circusd
cp ~/hipparchia_venv/HipparchiaServer/sample_config.py ~/hipparchia_venv/HipparchiaServer/config.py
nano ~/hipparchia_venv/HipparchiaServer/config.py
cp ~/hipparchia_venv/HipparchiaBuilder/sample_config.ini ~/hipparchia_venv/HipparchiaBuilder/config.ini
nano ~/hipparchia_venv/HipparchiaBuilder/config.ini
cp ~/hipparchia_venv/HipparchiaSQLoader/sample_config.ini ~/hipparchia_venv/HipparchiaSQLoader/config.ini
nano ~/hipparchia_venv/HipparchiaSQLoader/config.ini

# [install jquery, fonts, etc. in ~/hipparchia_venv/HipparchiaServer/server/static/]

curl https://code.jquery.com/jquery-3.1.1.min.js > ~/hipparchia_venv/HipparchiaServer/server/static/jquery.min.js
curl https://raw.githubusercontent.com/js-cookie/js-cookie/master/src/js.cookie.js > ~/hipparchia_venv/HipparchiaServer/server/static/js.cookie.js
curl -LOk https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2 > ~/hipparchia_venv/HipparchiaServer/server/static/dejavu-fonts-ttf-2.37.tar.bz2
curl -LOk https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2 > ~/hipparchia_venv/HipparchiaServer/server/static/dejavu-fonts-ttf-2.37.tar.bz2
curl -LOk https://noto-website.storage.googleapis.com/pkgs/NotoSans-unhinted.zip > ~/hipparchia_venv/HipparchiaServer/server/static/NotoSans-unhinted.zip
curl -LOk https://github.com/google/fonts/raw/master/apache/robotomono/RobotoMono-Medium.ttf >  ~/hipparchia_venv/HipparchiaServer/server/static/RobotoMono-Medium.ttf
curl -LOk https://github.com/google/fonts/raw/master/apache/robotocondensed/RobotoCondensed-Regular.ttf > ~/hipparchia_venv/HipparchiaServer/server/static/RobotoCondensed-Regular.ttf
curl -LOk https://github.com/google/roboto/raw/master/src/hinted/Roboto-Thin.ttf > ~/hipparchia_venv/HipparchiaServer/server/static/Roboto-Thin.ttf
curl -LOk https://github.com/google/roboto/raw/master/src/hinted/Roboto-Light.ttf > ~/hipparchia_venv/HipparchiaServer/server/static/Roboto-Light.ttf
cd ~/hipparchia_venv/HipparchiaServer/server/static/
tar jxf ~/hipparchia_venv/HipparchiaServer/server/static/dejavu-fonts-ttf-2.37.tar.bz2
cp ~/hipparchia_venv/HipparchiaServer/server/static/dejavu-fonts-ttf-2.37/ttf/*.ttf ~/hipparchia_venv/HipparchiaServer/server/static/ttf/
curl -LOk http://jqueryui.com/resources/download/jquery-ui-1.12.1.zip ~/hipparchia_venv/HipparchiaServer/server/static/jquery-ui-1.12.1.zip
unzip ~/hipparchia_venv/HipparchiaServer/server/static/jquery-ui-1.12.1.zip
unzip ~/hipparchia_venv/HipparchiaServer/server/static/NotoSans-unhinted.zip

mv ~/hipparchia_venv/HipparchiaServer/server/static/*.ttf ~/hipparchia_venv/HipparchiaServer/server/static/ttf/
cp ~/hipparchia_venv/HipparchiaServer/server/static/jquery-ui-1.12.1/jquery-ui* ~/hipparchia_venv/HipparchiaServer/server/static/
cp ~/hipparchia_venv/HipparchiaServer/server/static/jquery-ui-1.12.1/images/*.png ~/hipparchia_venv/HipparchiaServer/server/static/images/
rm -rf ~/hipparchia_venv/HipparchiaServer/server/static/NotoSans-unhinted.zip ~/hipparchia_venv/HipparchiaServer/server/static/dejavu-fonts-ttf-2.37.tar.bz2 ~/hipparchia_venv/HipparchiaServer/server/static/jquery-ui-1.12.1.zip ~/hipparchia_venv/HipparchiaServer/server/static/jquery-ui-1.12.1/ ~/hipparchia_venv/HipparchiaServer/server/static/dejavu-fonts-ttf-2.37/

# here comes the SHOWSTOPPER moment if you are going to be a HipparchiaBuilder
# if you do not have access to the data, then you can't build
# and this data is not available on github and unlikely ever to be available on github
# You need access to the TLG_E and PHI00005 and PHI7 disks. Get your hands on them.
# I do not know if other versions will build. They probably will.  

# NOTE: HipparchiaServer can and will run just fine with 0 languages and lexica actually installed. 
# Just don't expect to find anything in an empty database. 
# You probably want more than nothing. But there is no need to install more than you will use. 
# If you only install Latin literature, you will only be presented with Latin as a search option.

# OPTION ONE: BE BUILDER

# make the datafiles available where config.ini says they will be

# the lexica and grammatical analyses are not officially available anywhere that I know of. This material used to be distributed via the Perseus Hopper. No more?
# 
# BUILDING - ACQUIRING THE LEXICA OPTION A:
# use the files inside of Diogenes
mkdir ~/hipparchia_venv/HipparchiaData/lexica/
curl https://community.dur.ac.uk/p.j.heslin/Software/Diogenes/Download/diogenes-linux-3.2.0.tar.bz2 > ~/hipparchia_venv/HipparchiaData/lexica/diogenes-linux-3.2.0.tar.bz2
cd ~/hipparchia_venv/HipparchiaData/lexica/
tar jxf diogenes-linux-3.2.0.tar.bz2
mv ~/hipparchia_venv/HipparchiaData/lexica/diogenes-3.2.0/diogenes/perl/Perseus_Data/*.* ~/hipparchia_venv/HipparchiaData/lexica/
rm -rf ~/hipparchia_venv/HipparchiaData/lexica/diogenes-3.2.0/
mv ~/hipparchia_venv/HipparchiaData/lexica/1999.04.0057.xml ~/hipparchia_venv/HipparchiaData/lexica/greek-lexicon_1999.04.0057.xml
mv ~/hipparchia_venv/HipparchiaData/lexica/1999.04.0059.xml ~/hipparchia_venv/HipparchiaData/lexica/latin-lexicon_1999.04.0059.xml

# BUILDING - ACQUIRING THE LEXICA OPTION B [incomplete data / no Latin items]: 
# TLG:
# curl -LOk https://raw.githubusercontent.com/cltk/greek_lexica_perseus/master/greek_english_lexicon_lsj_1.xml > ~/hipparchia_venv/HipparchiaData/lexica/greek_english_lexicon_lsj_1.xml
# curl -LOk https://raw.githubusercontent.com/cltk/greek_lexica_perseus/master/greek_english_lexicon_lsj_2.xml > ~/hipparchia_venv/HipparchiaData/lexica/greek_english_lexicon_lsj_2.xml
# LEMMATA
# curl -LOk https://raw.githubusercontent.com/cltk/greek_lexica_perseus/master/greek-lemmata.txt > ~/hipparchia_venv/HipparchiaData/lexica/greek-lemmata.txt 
# ANALYSES
# curl -LOk https://raw.githubusercontent.com/cltk/greek_lexica_perseus/master/greek-analyses_1.txt > ~/hipparchia_venv/HipparchiaData/lexica/greek-analyses_1.txt
# curl -LOk https://raw.githubusercontent.com/cltk/greek_lexica_perseus/master/greek-analyses_2.txt > ~/hipparchia_venv/HipparchiaData/lexica/greek-analyses_2.txt

# if you have the builder data all properly in place, then...

cd ~/hipparchia_venv/HipparchiaBuilder && ~/hipparchia_venv/bin/python3 ./makecorpora.py

# build times vary, but 10-40m per corpus should be possible on most machines. 
# 5-25m is achievable if you are a speed freak who knows how to optimize for your rig


# OPTION TWO: BE A RELOADER
# if you have access to a HipparchiaSQLoader dump, then...

# cd ~/hipparchia_venv/HipparchiaSQLoader/ && ../bin/python ./reloadhipparchiaDBs.py 

# CONGRATULATIONS: Hipparchia's data has been installed
# you are now ready to run HipparchiaServer 

# [reboot]

