
/sbin/iptables -D INPUT -s 192.168.0.25 -j DROP
sed -i /192.168.0.25/d blocked
