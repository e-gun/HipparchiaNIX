#!/bin/sh
#

# PROVIDE: foo
# REQUIRE: bar_service_required_to_precede_foo

. /etc/rc.subr

name="hipparchia_server"
rcvar=hipparchia_enable
user="hipparchia"
su_cmd="/usr/local/bin/sudo"
ex="/home/${user}/hipparchia_venv/bin/gunicorn --bind=unix:/tmp/gunicorn.sock -t 1200 --workers=1 --chdir /home/${user}/hipparchia_venv/HipparchiaServer server:hipparchia"

start_cmd="daemon -c -u ${user} -R 10 /home/${user}/hipparchia_venv/bin/gunicorn --bind=unix:/tmp/gunicorn.sock -t 1200 --workers=1 --chdir /home/${user}/hipparchia_venv/HipparchiaServer server:hipparchia"

load_rc_config $name
run_rc_command "$1"
