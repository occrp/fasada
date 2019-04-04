#!/bin/bash

#
# generating relevant tests
#
# $1 -- path of the upstreams.conf file to use

#
# first, upstream-related tests
#

FASADA_TESTS_DIR="$( dirname "$BASH_SOURCE" )"
FASADA_TESTS_UPSTREAMS_FILE="$FASADA_TESTS_DIR/001-upstreams.bats"

# clear the playing field
echo > "$FASADA_TESTS_UPSTREAMS_FILE"

# do we have *any* upstreams configured?
cat <<EOF >> "$FASADA_TESTS_UPSTREAMS_FILE"
@test "[\$HOSTNAME][upstreams] any upstreams configured?" {
    [ $( awk '/^upstream/,/^}/' "$1" | egrep '^\s+server' | sed -r -e 's/^\s*server\s([][a-f0-9\.\:]+)(;|\s+.+)/\1/g' | wc -l ) != 0 ]
}
EOF

# ok, let's go through hte upstreams
# and generate tests per-upstream
for upstream in $( awk '/^upstream/,/^}/' "$1" | egrep '^\s+server' | sed -r -e 's/^\s*server\s([][a-f0-9\.\:]+)(;|\s+.+)/\1/g' ); do

    # NOTICE: this will also handle regular domain names... not sure if that's what we want
    if [[ "$upstream" = *'.'* ]]; then
        # IPv4
        BATS_RUN="run ping -c 2 -w 3 '${upstream%:*}'"
    else
        # IPv6
        BATS_RUN="run ping6 -c 2 -w 3 '$( echo -n ${upstream%]*} | tr -d '[]' )'"
    fi

    cat <<EOF >> "$FASADA_TESTS_UPSTREAMS_FILE"
# pinging the upstream but *without* the port, obviously
@test "[\$HOSTNAME][upstreams] testing upstream: $upstream - accessible via ping?" {
    $BATS_RUN
    [ "\$status" -eq 0 ]
}
EOF

    # checking TCP connectivity
    # yes we're using bash built-in /dev/tcp for this to not rely on things like curl or wget
    # relevant: https://www.linuxjournal.com/content/more-using-bashs-built-devtcp-file-tcpip
    #
    # no need to get *too* fancy here, if a HTTP request is sent to a HTTPS port
    # we will still get a HTTP/1.1 Bad Request plain text response
    # 
    # if no port is specified, default to 80
    # using example.com for all requests, we just want to check if a webserver is listening
    # are we doing IPv4 or IPv6?
    if [[ $upstream = *'.'* ]]; then
        # IPv4 (or a domain name), we can assume there's max. a single ':'
        UPSTREAM_IP="${upstream%:*}"
        UPSTREAM_PORT="${upstream#*:}"
        if [ "$UPSTREAM_IP" == "$UPSTREAM_PORT" ]; then
            UPSTREAM_PORT="80"
        fi
    else
        # IPv6, square brackets are obligatory, otherwise nginx complains about invalid port
        # so we can use that to drop the port if any
        UPSTREAM_IP="$( echo -n ${upstream%]*} | tr -d '[]' )"
        UPSTREAM_PORT="${upstream#*]:}"
        if [ "$UPSTREAM_PORT" == "" ]; then
            UPSTREAM_PORT="80"
        fi
    fi

cat <<EOF >> "$FASADA_TESTS_UPSTREAMS_FILE"
@test "[\$HOSTNAME][upstreams] testing upstream: $upstream - accessible via HTTP/HTTPS?" {
    exec 8<>/dev/tcp/$UPSTREAM_IP/$UPSTREAM_PORT
    echo -e "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n" >&8
    run timeout 3 cat <&8
    exec 8<&-
    [[ "\${lines[0]}" == "HTTP/1.1 "* ]]
}

EOF
done
