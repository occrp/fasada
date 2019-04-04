#!/bin/bash

#
# running the tests
# 
# this should be ran directly on the bare metal
# *not* in the docker container
#
# it will generate the tests and then run them,
# first on bare metal, and then in the nginx container
# 

# get the source directory
FASADA_TESTS_DIR="$( dirname "$BASH_SOURCE" )"

# generate the tests
# 
# ...but only if we're not currently running the tests inside the container
if [ "$1" != '--running-in-container' ]; then
    "$FASADA_TESTS_DIR"/gentests.sh "$FASADA_TESTS_DIR/../services/etc/nginx/conf.d/upstreams.conf"
fi

# make sure PATH is set to what we need
export PATH="$FASADA_TESTS_DIR/bats-core/bin:$PATH"

# do the bagic
bats "$FASADA_TESTS_DIR"/*.bats

# do the magic in the container
# 
# ...unless we are already running in the container
if [ "$1" != '--running-in-container' ]; then
    cd "$FASADA_TESTS_DIR/../"
    docker-compose exec nginx /opt/tests/runtests.sh --running-in-container
fi
