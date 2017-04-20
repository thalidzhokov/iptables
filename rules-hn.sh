#!/bin/bash

# Last update 2017-04-05
# NOTICE! Add crontab task
# e.g.  17      17      *       *       *       bash /opt/hdh-iptables/rules-hn.sh >> /opt/hdh-iptables/rules-hn.log

date

# VARIABLES

# IPv4 e.g.
# 88.99.68.28
# OR $(ip addr show eth0 | grep 'inet ' | cut -f2 | awk '{print $2}')
# OR multiple $(ip -o -4 addr show up primary scope global | while read -r num dev fam addr rest; do echo ${addr%/*}; done)
# OR other function
HN_IPS="$(ip -o -4 addr show up primary scope global | while read -r num dev fam addr rest; do echo ${addr%/*}; done)"
echo "HN_IPS ${HN_IPS[@]}"

# IPv6 e.g.
# 2a01:4f8:10a:145b::128
# OR $(ip addr show eth0 | grep 'inet6 ' | cut -f2 | awk '{ print $2}' | sed -e "s/\/.*$//")
# OR multiple $(ip -o -6 addr show up primary scope global | while read -r num dev fam addr rest; do echo ${addr%/*}; done)
# OR other function
HN_IPS6="$(ip -o -6 addr show up primary scope global | while read -r num dev fam addr rest; do echo ${addr%/*}; done)"
echo "HN_IPS6 ${HN_IPS6[@]}"

#VE_IPS="88.99.109.120/29 88.99.68.53 88.99.68.54 88.99.68.55 88.99.68.56"
VE_IPS="$(vzlist -o ip -H | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort)"
echo "VE_IPS ${VE_IPS[@]}"

#VE_IPS6="2a01:4f8:10a:145b::/64"
VE_IPS6="$(vzlist -o ip -H | egrep -o '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{1,4}' | sort)"
echo "VE_IPS6 ${VE_IPS6[@]}"

CF_PROTECTED_IPS="88.99.109.121 88.99.109.124 88.99.223.241" # CloudFlare protected ips
echo "CF_PROTECTED_IPS ${CF_PROTECTED_IPS[@]}"

# Interfaces
HN_INTERFACE="$(ip -o link show | grep 'link/ether' | awk -F': ' '{print $2}')"
VE_INTERFACE="venet0"

# Iptables
IPTABLES="iptables ip6tables"
IPSET="ipset"

# States
STATES_NER="-m state --state NEW,ESTABLISHED,RELATED"
STATES_ER=" -m state --state ESTABLISHED,RELATED"
STATES_N="  -m state --state NEW"

. functions.sh

# SCRIPT

# Stop and start iptables
service iptables stop
service iptables start

policy_accept
policy_fx

spamhaus # -I
cloudflare "${CF_PROTECTED_IPS[@]}" # -I

# INSTALL fail2ban FOR BRUTEFORCE PROTECTION
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-centos-6
#rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#yum install fail2ban -y

echo "Adding new INPUT, OUTPUT and FORWARD rules..."

set_ipset "HN_IPS" "${HN_IPS[@]}" # "ip"

echo "Established, Related"
iptables -I INPUT   -i $HN_INTERFACE -m set --match-set HN_IPS dst $STATES_ER -j ACCEPT
iptables -I OUTPUT  -o $HN_INTERFACE -m set --match-set HN_IPS src $STATES_ER -j ACCEPT
iptables -I FORWARD                                                $STATES_ER -j ACCEPT

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









