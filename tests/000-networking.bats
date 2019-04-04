#
# basic networking tests
# a reality check, of sorts
#

@test "[$HOSTNAME][general] networking: is the outside world accessible via IPv4?" {
    run ping -c 2 -w 3 8.8.8.8
    [ "$status" -eq 0 ]
}

@test "[$HOSTNAME][general] networking: is the outside world accessible via IPv6?" {
    run ping6 -c 2 -w 3 ipv6.google.com
    [ "$status" -eq 0 ]
}
