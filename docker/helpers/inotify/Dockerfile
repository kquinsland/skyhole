##
#   this file instructs docker in how to buile the inotify tool container.
#   
#   It's pretty straightforward.
#
#   See: https://docs.docker.com/engine/reference/builder/
#   See: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#
##

FROM alpine:latest

# update / get the basics
RUN apk --update upgrade
RUN apk add --no-cache --update inotify-tools curl

# clear out if there was anything left...
RUN rm -rf /var/cache/apk/*

# add the watcher wrapper
ADD init.sh /init.sh

# make it executable
RUN chmod 750 /init.sh

# Scratch space
WORKDIR /tmp

ENTRYPOINT ["/init.sh"]
