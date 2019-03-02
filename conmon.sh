#!/bin/sh
#
# NAME
#        conmon - Restart service when some criterion fails
#
# SYNOPSIS
#        conmon <profile>
#
# DESCRIPTION
#        Polls a user-defined `check` command periodically.  On failure, the
#        user-defined `restart` command is called.
#
#        The time between periodic checks is at least `interval` seconds.
#        There are some additional delays between the restarts to allow the
#        service to act and to prevent frequent but futile restarts during
#        extended outages.  These timings can be adjusted via the `init_pause`
#        and `max_pause` parameters.
#
#        The script must be run as root.  To reduce the risk of this, `check`
#        is executed as `nobody`.  This can be configured using the `user`
#        parameter.
#
# OPTIONS
#        <profile>
#               Name of the profile script, corresponding to
#               /etc/conmon/<profile>.conf.
#
# EXAMPLE
#        A profile that tests Internet connectivity and restarts wlp3s0 on
#        failure:
#
#          # /etc/conmon/wlp3s0.conf
#
#          interval=300   # in seconds
#          #user=nobody   # user under which `check` is run
#          #init_pause=30 # in seconds
#          #max_pause=600 # in seconds
#
#          check() { # must return 0 on success
#              ping -c 5 -W 300 google.com >/dev/null
#          }
#
#          restart() {
#              systemctl restart netctl-auto@wlp3s0
#          }
#
#        The script itself may be managed via a systemd unit template:
#
#          # /etc/systemd/system/conmon@.service
#
#          [Unit]
#          Description=Restart service when some criterion fails
#
#          [Service]
#          ExecStart=/usr/local/bin/conmon %I
#          Restart=always
#          RestartSec=600
#
#          [Install]
#          WantedBy=multi-user.target
#
set -eu

if [ $# -ne 1 ]
then
    prog=`basename "$0"`
    printf >&2 "usage: %s PROFILE\n" "$prog"
    exit 2
fi

interval=600
user=nobody
init_pause=30
max_pause=600
restart() { :; }
profile=$1

. "/etc/conmon/$profile.sh"

pause=$init_pause

# return 37 on immediate failure and 0 on subsequent failures
test_connectivity() {
    cd "${TMP:-/tmp}"
    if sudo -n -u "$user" profile="$profile" sh <<"EOF"

    check() { :; }

    . "/etc/conmon/$profile.sh"

    exitcode=37
    while check
    do
        if [ "$exitcode" -eq 1 ]
        then echo "Connection active."
        fi
        exitcode=0
        sleep "$interval"
    done
    echo "Connection failed."
    exit "$exitcode"

EOF
    then return 0
    else return "$?"
    fi
}

# allow some time for service to initialize
# since it may have been started in parallel
sleep "$pause"
while :
do

    # wait for failures; if it didn't fail immediately, reset the pause timer
    if test_connectivity
    then pause=$init_pause
    else
        exitcode=$?
        if [ "$exitcode" -ne 37 ]
        then exit "$exitcode"
        fi
    fi

    # restart and then pause for some time
    echo "Restarting ..."
    restart && :
    e=$?
    [ $e -eq 0 ] || printf >&2 "Warning: restart exited with %i.\n" $e
    printf "Restarted %s.\n" "$service"
    sleep "$pause"

    # double the pause timer, up to some maximum
    pause=`expr "$pause" \* 2`
    if [ "$pause" -gt "$max_pause" ]
    then pause=$max_pause
    fi

done
