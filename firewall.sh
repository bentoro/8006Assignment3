IP="/sbin/iptables"

Firewall(){
  $IP -A INPUT -s $1 -j DROP
}

Flush(){
  $IP -D -s $1 -J DROP
}

Search(){
  cat /var/log/secure | grep ssh | grep 'Failed password for root from' | sed 's/^.*from //' > block_ip
}
