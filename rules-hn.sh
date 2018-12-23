#!/bin/bash
# Last update 2018-12-23
# CLONE THIS!
# git clone https://github.com/thalidzhokov/iptables /opt/hdh-iptables
# NOTICE! Add crontab task
# e.g.  17      17      *       *       *       bash /opt/hdh-iptables/rules-hn.sh >> /opt/hdh-iptables/rules-hn.log

date

PATH="$(dirname "$0")"

# Iptables
IPTABLES="iptables ip6tables"
IPSET="ipset"

# States
STATES_NER="-m state --state NEW,ESTABLISHED,RELATED"
STATES_ER=" -m state --state ESTABLISHED,RELATED"
STATES_N="  -m state --state NEW"

. "${PATH}/ip-interface.sh"
. "${PATH}/functions.sh"

# SCRIPT

# Stop and start iptables
service iptables stop
service iptables start

policy_accept
policy_fx

# Block
spamhaus # -I

# Accept
cloudflare "${CF_PROTECTED_IPS[@]}" # -I
yandex_kassa # -I

# INSTALL fail2ban FOR BRUTEFORCE PROTECTION
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-centos-6
#rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#yum install fail2ban -y

echo "Adding new INPUT, OUTPUT and FORWARD rules..."

set_ipset "HN_IPS" "${HN_IPS[@]}" # "ip"

echo "LAN"
iptables -A FORWARD -d 192.168.0.0/16 -j DROP
iptables -A OUTPUT  -d 192.168.0.0/16 -j DROP

echo "Established, Related"
iptables -A INPUT   -i $HN_INTERFACE -m set --match-set HN_IPS dst $STATES_ER -j ACCEPT
iptables -A OUTPUT  -o $HN_INTERFACE -m set --match-set HN_IPS src $STATES_ER -j ACCEPT
iptables -A FORWARD                                                $STATES_ER -j ACCEPT

echo "SSH"
iptables -A INPUT  -i $HN_INTERFACE -m set --match-set HN_IPS dst -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p tcp --sport 22 -j ACCEPT

echo "DNS"
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p tcp --dport 53 -j ACCEPT
iptables -A INPUT  -i $HN_INTERFACE -m set --match-set HN_IPS dst -p udp --sport 53 --dport 1024:65535 -j ACCEPT
iptables -A INPUT  -i $HN_INTERFACE -m set --match-set HN_IPS dst -p tcp --sport 53 --dport 1024:65535 -j ACCEPT

echo "YUM"
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p tcp -m multiport --dports 20,21,80,443 -j ACCEPT

echo "NTP"
iptables -A OUTPUT -o $HN_INTERFACE -p udp --sport 123 --dport 123 -j ACCEPT

echo "ICMP"
iptables -A INPUT  -i $HN_INTERFACE -m set --match-set HN_IPS dst -p icmp -m icmp --icmp-type 0  -j ACCEPT
iptables -A INPUT  -i $HN_INTERFACE -m set --match-set HN_IPS dst -p icmp -m icmp --icmp-type 3  -j ACCEPT
iptables -A INPUT  -i $HN_INTERFACE -m set --match-set HN_IPS dst -p icmp -m icmp --icmp-type 8  -j ACCEPT
iptables -A INPUT  -i $HN_INTERFACE -m set --match-set HN_IPS dst -p icmp -m icmp --icmp-type 12 -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p icmp -m icmp --icmp-type 0  -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p icmp -m icmp --icmp-type 3  -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p icmp -m icmp --icmp-type 4  -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p icmp -m icmp --icmp-type 8  -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p icmp -m icmp --icmp-type 11 -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p icmp -m icmp --icmp-type 12 -j ACCEPT
iptables -A OUTPUT -o $HN_INTERFACE -m set --match-set HN_IPS src -p icmp -m icmp --icmp-type 30 -j ACCEPT

echo "Localhost"
iptables -A INPUT  -s 127.0.0.1/8 -d 127.0.0.1/8 -j ACCEPT
iptables -A OUTPUT -s 127.0.0.1/8 -d 127.0.0.1/8 -j ACCEPT

echo "Loopbacks"
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

set_ipset "VE_IPS" "${VE_IPS[@]}" # "ip"

echo "VM"
iptables -A FORWARD -m set --match-set VE_IPS src -j ACCEPT
iptables -A FORWARD -m set --match-set VE_IPS dst -j ACCEPT

policy_drop









