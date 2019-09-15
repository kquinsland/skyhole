#!/bin/sh
##
#   this file extracts the SSL key/certs obtained by traefik and
#       stores them so that they can be consumed by coreDNS
#   
#   it is launched, does it's job, and then quits.
#   it is meant to be triggered by the iNotify helper
#
##


# If something goes wrong, bail!
set -e

### Setup
## file paths - mapped back to host / coreDNS & traefik volumes
# CERT_JSON is where traefik stores the key and cert from LE
CERT_JSON="/etc/traefik/acme.json"

# Where the extracted private key should be written
# We write it to the volume that is co-mounted with the coreDNS container
KEY_FILE="/etc/coredns/key.pem"

# Certificats, same as the key.
# We need the full chain, of certificates from LE; not just the last 
#   cert in the chain. At least andoid seems to reliably connect to 
#   coreDNS only when the full chain is offered.
CRT_FILE="/etc/coredns/fchain.pem"

## JQ Queries used to extract the parts of the certificate
# written in JMES.
# See: http://jmespath.org/tutorial.html
JQ_CRT=".Certificates[].Certificate"
JQ_KEY=".Certificates[].Key"

# This script will (almost) be exclusively run by iNotify container events
#   so it's pretty a safe assumption to assume that acme.json has right stuff
#   but it wouldn't hurt to verify this.  
##
# TODO: capture return code from JQ to determine if malformed json?
echo "dumping keys..."

# `cat` sends a the content of `$CERT_JSON` to the `jq` binary.
#   which then uses the query in `$JQ_CRT` and `$JQ_KEY` to
#   extract the useful bits of acme.json into teh `base64`
#   binary to decode the b64 string into the pem format cert/key
##
cat $CERT_JSON | jq -r '.Certificates[] | select(.Domain.Main=="my.domain.com") | .Certificate' | base64 -d > $CRT_FILE
cat $CERT_JSON | jq -r '.Certificates[] | select(.Domain.Main=="my.domain.com") | .Key' | base64 -d > $KEY_FILE

# 
echo "done..."
