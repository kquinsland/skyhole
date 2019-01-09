#!/bin/sh
##
#   this file is inspired by / forked from this repo:
#       https://github.com/pstauffer/docker-inotify
#   
#   it uses `inotify` to watch a file in the container;
#   this file is mapped to the same files used by other containers
#   
#   when a change is detected, it restarts the containers dependent on the file change
#
##


# If something goes wrong, bail!
set -e

# Setup
CURL_OPTIONS_DEFAULT=

# We only care about file upserts. move or delete is not good, but not this script's problem
INOTIFY_EVENTS_DEFAULT="modify"
INOTIFY_OPTONS_DEFAULT='--monitor'

# little bit of output to help with debugging
echo "inotify settings"
echo "================"
echo
echo "  Container:        ${CONTAINER1}, ${CONTAINER2}"
echo "  Volumes:          ${VOLUMES}"
echo "  Curl_Options:     ${CURL_OPTIONS:=${CURL_OPTIONS_DEFAULT}}"
echo "  Inotify_Events:   ${INOTIFY_EVENTS:=${INOTIFY_EVENTS_DEFAULT}}"
echo "  Inotify_Options:  ${INOTIFY_OPTONS:=${INOTIFY_OPTONS_DEFAULT}}"
echo

# start the loop
echo "[Starting inotifywait...]"
inotifywait -e ${INOTIFY_EVENTS} ${INOTIFY_OPTONS} "${VOLUMES}" | \
    while read -r notifies;
    do
    	echo "notification: $notifies"
        echo ""
        echo "notify received, restarting container ${CONTAINER1} now..."
        echo ""
        curl ${CURL_OPTIONS} -X POST --unix-socket /var/run/docker.sock http:/docker/containers/${CONTAINER1}/restart > /dev/stdout 2> /dev/stderr

        # Restart C2 (coredns) after some amount of time
        echo "notify received, restarting container ${CONTAINER2} in ${COUNTDOWN} seconds..."
        curl ${CURL_OPTIONS} -X POST --unix-socket /var/run/docker.sock http:/docker/containers/${CONTAINER2}/restart?t=${COUNTDOWN} > /dev/stdout 2> /dev/stderr
        echo ""
    done

echo "[exiting...]"
