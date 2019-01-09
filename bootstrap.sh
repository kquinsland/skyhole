#!/bin/bash
##
#   this file is a semi-automatic way to configure and build a SkyHole instance
#
#   It is very straight forward bash. It probably can be done better.
#   
##

# bail
set -e 

###
# SETUP
###
# the file to store the username and encrypted passwords in for traefik
HT_FILE=/opt/skyhole/docker/vol/traefik/.htpasswd

# where traefik stores the certificate data
# the only "on disk" format they support is a json file
# See: https://docs.traefik.io/configuration/acme/#as-a-file
ACME_JSON=/opt/skyhole/docker/vol/traefik/acme.json

# where docker compose expects the piHole IP address
#   environment variable to be defined
CDNS_ENV=/opt/skyhole/docker/env/pi.public_ip.env

## Traefik does authentication; 
# Configure the user name and password you wish to use
##
# you'll use this for to authenticate to traefik; required to access any piHole web page
HTTP_USER="somebody"

# The expression:
#       `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
#   will generate a random string of 16 alpha-numeric characters as a password
#   This password will not be used if `$HT_FILE` is found on disk.
#
# Source: https://gist.github.com/earthgecko/3089509
##
HTTP_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)


# Quick root check
if [[ $EUID -ne 0 ]]; then
   echo "  [WARN]  please run this as root..."
   exit 1
fi

# both Docker compose and (some of) the containers will not start withouh
# their necessary config files in place
echo "  [INFO]  creating files for docker-compose..."

# check if there's an existing file; otherwise write the user-given creds to disk
#   in a format that traefik can understand
if [ ! -f $HT_FILE ]; then
    echo "creating $HT_FILE..."
    touch $HT_FILE

    # -i is for read password from STDIN; do not ask user to confirm
    # -C is the performance penalty factor; i chose an arbitrary number
    # -B is the "blowfish" encryption standard; thought to be very secure
    echo $HTTP_PASS | htpasswd -i -B -C 10 -c $HT_FILE $HTTP_USER

    echo 
    # Dump the random password we generated for the user's benefit
    echo "your http credentials are $HTTP_USER:$HTTP_PASS"

else
    echo "existing $HT_FILE..."
fi

# We also check that the file for traefik exists
#   the permissions of 0600 are required for the acme/lets encrypt 
#   component of traefik to function.
if [ ! -f $ACME_JSON ]; then
    echo "creating $ACME_JSON..."
    touch $ACME_JSON
    chmod 0600 $ACME_JSON
else
    echo "existing $ACME_JSON..."
    # Ensure permissions are set properly
    chmod 0600 $ACME_JSON
fi



# piHole needs to know a few things about the WAN environment in which it's operating
# 
# If runing in an cloud-provider's environment, there are almost certainly better ways
#   to get the public IP that points to an instance.
#   Something like: 
#   aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" 
#    or
#   curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip
#
#   But this curl command should just work ™️.
echo "  [INFO]  getting runtime WAN IP configuration..."
echo "ServerIP=$(curl -q -s ifconfig.me)" > $CDNS_ENV

# Get docker-compose creating...
echo "  [INFO]  beginning container creation..."
# change into skyhole dir
cd /opt/skyhole/docker

# create the networks and the containers; detach!
docker-compose up -d

# Docker will need to build two helper containers. There are more details in the readme
##
# After the helpers are built, the general startup order will look like:
#   0. everything is launched; keys helper will immediately create a cert / key for coredns or fail
#   1. traefik will get a cert and store into acme.json (if needed)
#   2. this will re-start keys helper and coreDNS container
#
# At this point:
#   0. pihole should be fully booted
#   1. and traefik should have a cert
#   2. that cert has been dumped into coreDNS
#   3. coreDNS has been reloaded with keys and accepting DoT queries

echo "  [INFO]  Should be good to go!"
