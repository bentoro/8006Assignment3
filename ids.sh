IP="/sbin/iptables"
ssh_array=()


#parses the /var/log/secure file for $1 service, and creates an array with the Date, Time, IP address, and port
parse_logs(){

    #find all failed attempts within time range
    cat $1 | grep $2 | grep 'Failed password for root from' > service_array

    #start date
    #start=$(date +%s -d "yesterday")

    #end date
    #end=$(date +%s)
    time1=$(date +%s -d "yesterday")
    time2=$(date +%s)

    while read line
    do
      arr=($line)
      str=("${arr[0]} ${arr[1]} ${arr[2]}")
      test=$( date -d"$str" +"%s" )
      if [ $test -ge $time1 ] && [ $test -le $time2 ]
      then
              ssh_array+=("${arr[0]} ${arr[1]} ${arr[2]} ${arr[10]} ${arr[12]}")
      fi
    done < service_array
}

block_ip(){
    #find ip and port of all failed attempts for ssh TODO: add Date and Time to block_ip
    #cat $1 | grep 'Failed password for root from' | sed 's/^.*from //' > block_ip

    #find all instances that failed
    #cat block_ip | sed 's/ .*//'



    cat service_array | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | uniq -c >block_ip


    while read line
    do
        arr=($line)
        if [ "${arr[0]}" -le $2 ]
        then
            echo "blocking ip" ${arr[1]}
            $IP -A INPUT -s $1 -j DROP
            echo $IP -D INPU -s ${arr[1]} -j DROP > remove_ip
            at -f jobs.txt ${arr[1]} now + 24 days
        fi

    done < block_ip
}

#wrapper function to easily analyze date/time format from the /var/log/sercure file
#find_date_time()



#wrapper function to easily analyze ip from a line
#find_ip()
    #sed


#wrapper function to easily analyze port from a line (extra)
#find_port()

firewall(){
  $IP -A INPUT -s $1 -j DROP
}

flush(){
  $IP -D -s $1 -J DROP
}

#1 = log file location
#2 = service
parse_logs $1 $2
block_ip service_array $3
