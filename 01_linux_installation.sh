#!/bin/bash
# this is just another version of a macOS installation and not a full nginx installation
# python36, postgresql96 (and extensions), and wget will need to be installed first
# postgresql96 needs to be initialized by hand: see the bottom of this script 
# you might have to fiddle with some path names for the executables

# debian does not like pooled connections to postgres

HIPPHOME="$HOME/hipparchia_venv"
SERVERPATH="$HIPPHOME/HipparchiaServer"
BUILDERPATH="$HIPPHOME/HipparchiaBuilder"
LOADERPATH="$HIPPHOME/HipparchiaSQLoader"
BSDPATH="$HIPPHOME/HipparchiaBSD"
MACPATH="$HIPPHOME/HipparchiaMacOS"
DATAPATH="$HIPPHOME/HipparchiaData"
THEDB="hipparchiaDB"


RED='\033[0;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

GIT='git'

# ready the installation files and directories
printf "${WHITE}preparing the installation files and directories${NC}\n"

for dir in $HIPPHOME $SERVERPATH $BUILDERPATH $LOADERPATH $BSDPATH $DATAPATH $MACPATH
do
	if [ ! -d $dir ]; then
		/bin/mkdir $dir
	else
		echo "$dir already exists; no need to create it"
	fi
done

cd $SERVERPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaServer.git
cd $BUILDERPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaBuilder.git
cd $LOADERPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaSQLoader.git
cd $BSDPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaBSD.git
cd $MACPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaMacOS.git

cp $MACPATH/macOS_selfupdate.sh $HIPPHOME/selfupdate.sh
chmod 700 $HIPPHOME/selfupdate.sh
cp -rp $MACPATH/macos_launch_hipparchia_application.app $HIPPHOME/launch_hipparchia.app
cp -rp $MACPATH/macos_dbload_hipparchia.app $LOADERPATH/load_hipparchia_data.app


# prepare the python virtual environment
printf "${WHITE}preparing the python virtual environment${NC}\n"
python3.6 -m venv $HIPPHOME
source $HIPPHOME/bin/activate
$HIPPHOME/bin/pip3 install bs4 flask psycopg2 websockets


# set up some random passwords

SSL="openssl"

WRPASS=`${SSL} rand -base64 12`
RDPASS=`${SSL} rand -base64 12`
SKRKEY=`${SSL} rand -base64 24`

# you might have regex control chars in there if you are not lucky: 'VvIUkQ9CerGTo/sx5vneHeo+PCKpx7V5'
WRPASS=`echo ${WRPASS//[^[:word:]]/}`
RDPASS=`echo ${RDPASS//[^[:word:]]/}`
SKRKEY=`echo ${SKRKEY//[^[:word:]]/}`

printf "\n\n${WHITE}setting up your passwords in the configuration files${NC}\n"
printf "\t${RED}hippa_wr${NC} password will be: ${YELLOW}${WRPASS}${NC}\n"
printf "\t${RED}hippa_rd${NC} password will be: ${YELLOW}${RDPASS}${NC}\n"
printf "\t${RED}secret key${NC} will be: ${YELLOW}${SKRKEY}${NC}\n\n"

if [ ! -f "$BUILDERPATH/config.ini" ]; then
	sed "s/DBPASS = >>yourpasshere<</DBPASS = $WRPASS/" $BUILDERPATH/sample_config.ini > $BUILDERPATH/config.ini
else
	echo "oops - found old config.ini: will not change the password for hippa_wr"
	echo "nb: your OLD password is still there; you will need to change it to your NEW one ($WRPASS)"
fi

if [ ! -f "$LOADERPATH/config.ini" ]; then
	sed "s/DBPASS = yourpasshere/DBPASS = $WRPASS/" $LOADERPATH/sample_config.ini > $LOADERPATH/config.ini
fi

if [ ! -f "$SERVERPATH/config.py" ]; then
	sed "s/DBPASS = 'yourpassheretrytomakeitstrongplease'/DBPASS = '$RDPASS'/" $SERVERPATH/sample_config.py > $SERVERPATH/config.py
	sed -i "" "s/SECRET_KEY = 'yourkeyhereitshouldbelongandlooklikecryptographicgobbledygook'/SECRET_KEY = '$SKRKEY'/" $SERVERPATH/config.py
else
	echo "oops - found old config.py: will not change the password for hippa_rd"
	echo "nb: your OLD password is still there; you will need to change it to your NEW one ($RDPASS)"
fi


# support files
printf "${WHITE}fetching 3rd party support files${NC}\n"
GET="wget"
STATIC="$SERVERPATH/server/static"

cd $STATIC/
$GET https://code.jquery.com/jquery-3.1.0.min.js
mv $STATIC/jquery-3.1.0.min.js $STATIC/jquery.min.js
$GET https://raw.githubusercontent.com/js-cookie/js-cookie/master/src/js.cookie.js
$GET https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2
$GET http://jqueryui.com/resources/download/jquery-ui-1.12.1.zip

echo "${WHITE}unpacking 3rd party support files"
tar jxf $STATIC/dejavu-fonts-ttf-2.37.tar.bz2
cp $STATIC/dejavu-fonts-ttf-2.37/ttf/*.ttf $STATIC/ttf/
unzip $STATIC/jquery-ui-1.12.1.zip
cp $STATIC/jquery-ui-1.12.1/jquery-ui* $STATIC/
cp $STATIC/jquery-ui-1.12.1/images/*.png $STATIC/images/
rm -rf $STATIC/dejavu-fonts-ttf-2.37.tar.bz2 $STATIC/jquery-ui-1.12.1.zip $STATIC/jquery-ui-1.12.1/ $STATIC/dejavu-fonts-ttf-2.37/

if [ ! -d "$DATAPATH/lexica" ]; then
	printf "${WHITE}fetching the lexica${NC}\n"
	mkdir $DATAPATH/lexica/
	cd $DATAPATH/lexica/
	$GET https://community.dur.ac.uk/p.j.heslin/Software/Diogenes/Download/diogenes-linux-3.2.0.tar.bz2
	tar jxf diogenes-linux-3.2.0.tar.bz2
	mv $DATAPATH/lexica/diogenes-3.2.0/diogenes/perl/Perseus_Data/*.* $DATAPATH/lexica/
	rm -rf $DATAPATH/lexica/diogenes-3.2.0/
	mv $DATAPATH/lexica/1999.04.0057.xml $DATAPATH/lexica/greek-lexicon_1999.04.0057.xml
	mv $DATAPATH/lexica/1999.04.0059.xml $DATAPATH/lexica/latin-lexicon_1999.04.0059.xml
fi

printf "\n\n${RED}congratulations, you are ready to build${NC}\n[provided you did not see any show-stopping error messages above...]\n\n"
printf "[A1] If you are ${WHITE}building${NC}, make sure that your ${YELLOW}data files${NC} are all in place and that their locations reflect the values set in ${YELLOW}$BUILDERPATH/config.ini${NC}\n\n"
printf "after that you can execute the following in the Terminal.app:\n"
printf "\t${WHITE}cd $BUILDERPATH && $HIPPHOME/bin/python3 ./makecorpora.py${NC}\n\n"
printf "[A2] Alternately you are ${WHITE}reloading${NC}. Make sure that your ${YELLOW}sqldump files${NC} are all in place and that their locations reflect the values set in ${YELLOW}$LOADERPATH/config.ini${NC}\n\n"
printf "after that you can double-click ${WHITE}load_hipparchia_data.app${NC} which is located at ${WHITE}${LOADERPATH}${NC}\n"
printf "[B] Once the databases are loaded all you need to do is double-click ${WHITE}launch_hipparchia.app${NC} which is presently located at $HIPPHOME\n\n"

# build the db framework
# sudo systemctl enable postgresql.service
# 
# sudo su postgres
# cd ~
# initdb --locale $LANG -E UTF8 -D '/var/lib/postgres/data'
# exit
# sudo systemctl start postgresql.service
# sudo su postgres
# cd ~
# createdb -E UTF8 hipparchiaDB
# psql hipparchiaDB
		# [insert sql via generate_hipparchia_dbs.sql]
		# [but for the ownership problems it is: psql -d hipparchiaDB -a -f ~/hipparchia_venv/HipparchiaBuilder/builder/sql/sample_generate_hipparchia_dbs.sql]
		# [need two roles (hippa_wr & hippa_rd) and authors and works tables]
			#	\password hippa_wr
			#	\password hippa_rd

