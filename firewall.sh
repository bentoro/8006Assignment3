IP="/sbin/iptables"

Firewall(){
  $IP -A INPUT -s $1 -j DROP
}

Flush(){
  $IP -D -s $1 -J DROP
}

Search(){

}
