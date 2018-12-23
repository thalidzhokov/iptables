#!/bin/bash
# Last update 2017-04-05
# NOTICE! Add crontab task
# e.g.  17      17      *       *       *       bash /opt/hdh-iptables/rules-ve.sh >> /opt/hdh-iptables/iptables-rules-ve.log

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

set_ipset HN_IPS "${HN_IPS[@]}"

echo "Established, Related"
iptables -I INPUT   -i $HN_INTERFACE -m set --match-set HN_IPS dst $STATES_ER -j ACCEPT
iptables -I OUTPUT  -o $HN_INTERFACE -m set --match-set HN_IPS src $STATES_ER -j ACCEPT

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

echo "Bacula Server" # TODO: add OUTPUT/INPUT and source/destination
iptables -A INPUT  -p tcp --dport 9101:9103 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 9101:9103 -j ACCEPT

echo "Bacula Client" # TODO: add OUTPUT/INPUT and source/destination
iptables -A INPUT  -p tcp --dport 9102 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 9102 -j ACCEPT

# RECOMMENDED! Install cPanel plugin
# http://configserver.com/cp/csf.html
#wget -P /tmp/ https://download.configserver.com/csf.tgz
#tar -xzf /tmp/csf.tgz
#sh /tmp/csf/install.cpanel.sh

# Based on https://documentation.cpanel.net/display/CKB/How+to+Configure+Your+Firewall+for+cPanel+Services
echo "WHM/cPanel"
iptables -A INPUT   -p tcp -m multiport --dports 20,21,22,25,26,53,80,110,143,443,465,587,783,993,995 -j ACCEPT
iptables -A INPUT   -p tcp -m multiport --dports 2077,2078,2079,2080,2082,20823,2082,2083,2086,2087,2095,2096,3306,6277,24441 -j ACCEPT
iptables -A INPUT   -p udp -m multiport --dports 53,465,783,6277,24441 -j ACCEPT
# SMTP, DNS, DNS Cluster
iptables -A INPUT   -p tcp -m multiport --sports 25,53,587,2087 -j ACCEPT
# Passive mode
iptables -A INPUT   -p tcp --dport 49152:65534 -j ACCEPT

iptables -A OUTPUT  -p tcp -m multiport --sports 20,21,25,26,37,43,53,80,113,443,465,587,873 -j ACCEPT
iptables -A OUTPUT  -p tcp -m multiport --sports 2077,2078,2079,2080,2089,2703,6277,24441 -j ACCEPT
iptables -A OUTPUT  -p udp -m multiport --sports 53,465,873,6277,24441 -j ACCEPT
# SSH, SMTP, DNS, DNS Cluster, SVN
iptables -A OUTPUT  -p tcp -m multiport --dports 22,25,53,587,2087,3690 -j ACCEPT


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

policy_drop

echo "============================================================================="







