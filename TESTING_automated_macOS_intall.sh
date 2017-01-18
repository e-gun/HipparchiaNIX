#!/bin/bash

HIPPHOME="$HOME/hipparchia_venv"
SERVERPATH="$HIPPHOME/HipparchiaServer"
BUILDERPATH="$HIPPHOME/HipparchiaBuilder"
LOADERPATH="$HIPPHOME/HipparchiaSQLoader"
BSDPATH="$HIPPHOME/HipparchiaBSD"
DATAPATH="$HIPPHOME/HipparchiaData"
THEDB="hipparchiaDB"

# ready the installation files and directories
echo "preparing the installation files and directories"

for dir in $HIPPHOME $SERVERPATH $BUILDERPATH $LOADERPATH $BSDPATH $DATAPATH
do
	if [ ! -d $dir ]; then
		/bin/mkdir $dir
	else
		echo "$dir already exists; no need to create it"
	fi
done

GIT='/usr/bin/git'
cd $SERVERPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaServer.git
cd $BUILDERPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaBuilder.git
cd $LOADERPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaSQLoader.git
cd $BSDPATH && $GIT init && $GIT pull https://github.com/e-gun/HipparchiaBSD.git

cp $BSDPATH/macOS_selfupdate.sh $HIPPHOME/selfupdate.sh
chmod 700 $HIPPHOME/selfupdate.sh
cp -rp $BSDPATH/macos_launch_hipparchia_application.app $HIPPHOME/launch_hipparchia.app


# install brew
BREW='/usr/local/bin/brew'

if [ -f "$BREW" ]
then
	echo "brew found; no need to install it"
else
	echo "brew not found; installing"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

$BREW install python3
$BREW install postgresql
$BREW services start postgresql

# harden postgresql

echo "hardening postgresql"
HBACONF='/usr/local/var/postgres/pg_hba.conf'

sed -i "" "s/local   all             all                                     trust/local   all   `whoami`   trust/" $HBACONF
sed -i "" "s/host    all             all             127.0.0.1\/32            trust/host   all   `whoami`   127.0.0.1\/32   trust/" $HBACONF

if grep hipparchiaDB $HBACONF; then
	echo "found hipparchia rules in pg_hba.conf; leaving it untouched"
else
	echo "local   $THEDB   hippa_rd,hippa_wr   password" >>  $HBACONF
	echo "host   $THEDB   hippa_rd,hippa_wr   127.0.0.1/32   password" >>  $HBACONF
	$BREW services restart postgresql
fi

# build the db framework

/usr/local/bin/createdb -E UTF8 $THEDB
/usr/local/bin/psql -d $THEDB -a -f $BUILDERPATH/builder/sql/sample_generate_hipparchia_dbs.sql

# set up some random passwords

WRPASS=`/usr/bin/openssl rand -base64 12`
RDPASS=`/usr/bin/openssl rand -base64 12`
SKRKEY=`/usr/bin/openssl rand -base64 24`

# you might have regex control chars in there if you are not lucky: 'VvIUkQ9CerGTo/sx5vneHeo+PCKpx7V5'
WRPASS=`echo ${RWPASS//[^[:word:]]/}`
RDPASS=`echo ${RDPASS//[^[:word:]]/}`
SKRKEY=`echo ${SKRKEY//[^[:word:]]/}`

echo -e "\nsetting up your passwords in the configuration files"
echo -e "\thippa_rw password will be: "$WRPASS
echo -e "\thippa_rd password will be: "$RDPASS
echo -e "\tsecret key will be: "$SKRKEY

if [ ! -f "$BUILDERPATH/config.ini" ]; then
	cp $BUILDERPATH/sample_config.ini $BUILDERPATH/config.ini
	sed -i "" "s/DBPASS = >>yourpasshere<</DBPASS = $WRPASS/" $BUILDERPATH/config.ini
	# note: this only works if pg_hba.conf has 'trust' in localhost for `whoami`
	/usr/local/bin/psql -d $THEDB --command="ALTER ROLE hippa_wr WITH PASSWORD '$WRPASS';"
else
	echo "oops - found old config.ini: will not change the password for hippa_wr"
fi

if [ ! -f "$LOADERPATH/config.ini"]; then
	cp $LOADERPATH/sample_config.ini $LOADERPATH/config.ini
	sed -i "" "s/DBPASS = yourpasshere/DBPASS = $WRPASS/" $LOADERPATH/config.ini
fi

if [ ! -f "$SERVERPATH/config.py"]; then
	cp $SERVERPATH/sample_config.py $SERVERPATH/config.py
	sed -i "" "s/DBPASS = 'yourpassheretrytomakeitstrongplease'/DBPASS = '$RDPASS'/" $SERVERPATH/config.py
	sed -i "" "s/SECRET_KEY = 'yourkeyhereitshouldbelongandlooklikecryptographicgobbledygook'/SECRET_KEY = '$SKRKEY'/" $SERVERPATH/config.py
	# note: this only works if pg_hba.conf has 'trust' in localhost for `whoami`
	/usr/local/bin/psql -d $THEDB --command="ALTER ROLE hippa_rd WITH PASSWORD '$RDPASS';"
else
	echo "oops - found old config.py: will not change the password for hippa_rd"
fi

# prepare the python virtual environment
echo "preparing the python virtual environment"
/usr/local/bin/python3.6 -m venv $HIPPHOME
source $HIPPHOME/bin/activate
$HIPPHOME/bin/pip3 install bs4 flask psycopg2

# support files
echo "fetching 3rd party support files"
CURL='/usr/bin/curl'
$STATIC = $SERVERPATH/server/static/

$CURL https://code.jquery.com/jquery-3.1.0.min.js > $STATIC/jquery.min.js
$CURL https://raw.githubusercontent.com/js-cookie/js-cookie/master/src/js.cookie.js > $STATIC/js.cookie.js
$CURL -LOk --progress-bar https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2 > $STATIC/dejavu-fonts-ttf-2.37.tar.bz2
$CURL -LOk --progress-bar http://jqueryui.com/resources/download/jquery-ui-1.12.1.zip > $STATIC/jquery-ui-1.12.1.zip

echo "unpacking 3rd party support files"
cd $STATIC
tar jxf $STATIC/dejavu-fonts-ttf-2.37.tar.bz2
mkdir $STATIC/ttf
cp $STATIC/dejavu-fonts-ttf-2.37/ttf/*.ttf $STATIC/ttf/
unzip $STATIC/jquery-ui-1.12.1.zip
cp $STATIC/jquery-ui-1.12.1/jquery-ui* $STATIC/
cp $STATIC/jquery-ui-1.12.1/images/*.png $STATIC/images/
rm -rf $STATIC/dejavu-fonts-ttf-2.37.tar.bz2 $STATIC/jquery-ui-1.12.1.zip $STATIC/jquery-ui-1.12.1/ $STATIC/dejavu-fonts-ttf-2.37/

if [ ! -d "$DATAPATH/lexica"]; then
	echo "fetching the lexica"
	mkdir $DATAPATH/lexica/
	curl https://community.dur.ac.uk/p.j.heslin/Software/Diogenes/Download/diogenes-linux-3.2.0.tar.bz2 > $DATAPATH/diogenes-linux-3.2.0.tar.bz2
	cd $DATAPATH/lexica/
	tar jxf diogenes-linux-3.2.0.tar.bz2
	mv $DATAPATH/lexica/diogenes-3.2.0/diogenes/perl/Perseus_Data/*.* $DATAPATH/lexica/
	rm -rf $DATAPATH/lexica/diogenes-3.2.0/
	mv $DATAPATH/lexica/1999.04.0057.xml $DATAPATH/lexica/greek-lexicon_1999.04.0057.xml
	mv $DATAPATH/lexica/1999.04.0059.xml $DATAPATH/lexica/latin-lexicon_1999.04.0059.xml
fi

echo "congratulations, you are ready to build"
echo "make sure that your data files are all in place and that their locations reflect the values set in $BUILDERPATH/config.ini"
echo "after that you can execute the following:"
echo "     cd $BUILDERPATH && $HIPPHOME/bin/python3 ./makecorpora.py"

