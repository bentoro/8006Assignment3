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
    time1=$(date +%s -d "$3 min ago")
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
    #find ip and port of all failed attempts for ssh
    cat service_array | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | uniq -c > block_ip

    while read line
    do
        arr=($line)
        if [ "${arr[0]}" -le $2 ]
        then
            echo "blocking ip" ${arr[1]}
            $IP -A INPUT -s ${arr[1]} -j DROP
            echo "/sbin/iptables -D INPUT -s ${arr[1]} -j DROP" > remove_ip
            at -f jobs.txt ${arr[1]} now + $3 min
            echo "at job set to remove block after $3 mins"
        fi

    done < block_ip
}

#1 = log file location
#2 = service
#3 = time to check
#4 = number of failed attempts before blocking ip
if [ "$#" -ne 3 ]; then
  echo "Usage error: ./ids.sh [log file location] [service to find] [amount of time blocked] [number of failed attempts]"
  exit 1
fi
parse_logs $1 $2 $3
block_ip service_array $3 $4
