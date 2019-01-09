##
#   this file instructs docker in how to buile the keys dumper tool container.
#   
#   It's pretty straightforward.
#
#   See: https://docs.docker.com/engine/reference/builder/
#   See: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#
##

FROM alpine:latest


# update / get JQ to parse the json strem
RUN apk --update upgrade
RUN apk add --no-cache --update jq

# clear out if there was anything left...
RUN rm -rf /var/cache/apk/*

# move the tool into the root of the container
COPY keys.sh /keys.sh

# make it executable
RUN chmod 750 /keys.sh

# set keys.sh as the runnable
ENTRYPOINT ["/keys.sh"]
