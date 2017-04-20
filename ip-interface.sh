#!/bin/bash
# Variables
# $HN_IPS
# $HN_IPS6
# $VE_IPS
# $VE_IPS6
# $CF_PROTECTED_IPS
# $HN_INTERFACE
# $VE_INTERFACE

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