#!/bin/bash

uids() {
  CHAIN="UIDS"

  echo "Reset $CHAIN"
  iptables -F $CHAIN

  echo "Delete $CHAIN"
  iptables -X $CHAIN

  echo "Create $CHAIN"
  iptables -N $CHAIN

  # e.g. awk -F: '($3 >= 1000) {printf "%s:%s\n",$1,$3}' /etc/passwd
  UIDS="$(awk -F: '{printf "%s\n",$3}' /etc/passwd)"
  echo "Get UIDS $UIDS"

  for UID_OWNER in $UIDS
  do
    echo "Rule for $UID_OWNER..."
    iptables -A $CHAIN -m owner --uid-owner $UID_OWNER
  done
}

uids

# Get UID e.g. cat /etc/passwd | grep 1029

iptables -D OUTPUT -p tcp -m multiport --dports 80,443 -j $CHAIN
iptables -I OUTPUT -p tcp -m multiport --dports 80,443 -j $CHAIN
