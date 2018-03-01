IP="/sbin/iptables"
ssh_array=()


#parses the /var/log/secure file for $1 service, and creates an array with the Date, Time, IP address, and port
parse_logs(){
    #find ip and port of all failed attempts for ssh TODO: add Date and Time to block_ip
    cat /var/log/secure | grep $1 | grep 'Failed password for root from' | sed 's/^.*from //' > service_array

    #find all instances that failed
    cat block_ip | sed 's/ .*//'

    #find all failed attempts within time range
    start="Feb 28 14:04:31"
    end="Feb 28 14:04:40"

    cat /var/log/secure | grep $1 | grep 'Failed password for root from' | awk -F: -v start="$start" -v end="$end" '$1<start && $1 <= end' > service_array

    #store the lines into the array
    while read line
    do
      arr=($line)
      array+=("${arr[0]} ${arr[1]} ${arr[2]} ${arr[10]} ${arr[12]}")
    done < /var/log/secure

}

#wrapper function to easily analyze date/time format from the /var/log/sercure file
find_date_time() {

}

#wrapper function to easily analyze ip from a line
find_ip() {
    #sed
}

#wrapper function to easily analyze port from a line (extra)
find_port() {

}

firewall(){
  $IP -A INPUT -s $1 -j DROP
}

flush(){
  $IP -D -s $1 -J DROP
}
