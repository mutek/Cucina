#!/bin/sh

# This script will automatically join the mesh network at PPS.

# Assuming you run Babel and AHCP, you can probably adapt it to your own
# network by tweaking the following parameters:

essid="pps"
channel=6

die() {
    echo "$@" >&2
    exit 1
}

findcmd() {
    type "$1" > /dev/null || \
        die "Couldn't find $1, please install ${2:-it} or fix your path."
}

if [ "$(whoami)" != root ]; then
    die "Sorry, you need to be root."
fi

usage="Usage: $0 [-N] [-d debuglevel] interface"
debuglevel=0
nodns=

while getopts "Nd:" name
do
    case $name in
        d) debuglevel="$OPTARG";;
        N) nodns=1;;
        ?) die "$usage"
    esac
done

shift $(($OPTIND - 1))

[ $# -lt 1 ] && die "$usage"

interfaces="$@"

findcmd iwconfig "wireless-tools"
findcmd babeld
findcmd ahcpd

modprobe ipv6
wait

(ip -6 addr show dev lo | grep -q 'inet6') || \
    die "No IPv6 address on lo, please modprobe ipv6"

while [ "$1" != "" ] ; do

interface="$1"

# order is important for mac80211-based drivers

ifconfig "$interface" down || die "Couldn't configure interface"
iwconfig "$interface" mode ad-hoc || die "Couldn't configure interface"
ifconfig "$interface" up || die "Couldn't configure interface"
iwconfig "$interface" essid "$essid" channel $channel || \
    die "Couldn't configure interface"

ip link set up dev "$interface" || die "Couldn't up interface"

shift

done

terminate() {
    echo -n 'Killing ahcpd and babel...'
    [ -e /var/run/ahcpd.pid ] && kill "$(cat /var/run/ahcpd.pid)"
    # give ahcpd time to release the lease
    sleep 2
    [ -e /var/run/babeld.pid ] && kill "$(cat /var/run/babeld.pid)"
    echo 'done.'
    trap - EXIT
    exit 0
}

trap terminate INT QUIT TERM EXIT

# allow time for the link layer to associate
sleep 1

babeld ${debuglevel:+-d} $debuglevel -z 3 $interfaces &
ahcpd ${nodns:+-N} ${debuglevel:+-d} $debuglevel $interfaces &

echo "Ahcpd and babeld running on $interfaces, press ^C to terminate."

while :; do sleep 3600; done
