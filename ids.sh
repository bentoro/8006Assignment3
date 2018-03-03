IP="/sbin/iptables"
time1=$(date +%s -d "$3 min ago")
time2=$(date +%s)

#parses the /var/log/secure file for $1 service, and creates an array with the Date, Time, IP address, and port
parse_logs(){

    #find all failed attempts within time range
    cat $1 | grep $2 | grep 'Failed password for root from' > service_array

    #empty the parsed_secure file
    echo > parsed_secure
    #parse the failed attempts by date
    while read line
    do
        arr=($line)
        str=("${arr[0]} ${arr[1]} ${arr[2]}")
        test=$( date -d"$str" +"%s" )
        time=("Mar 2 16:34:17");test=$(date -d"$time 1 minutes"); echo $test

        if [ $test -ge $time1 ] && [ $test -le $time2 ]
        then
            echo "found entry at: " $test " against: " $time1
            echo "${arr[0]} ${arr[1]} ${arr[2]} ${arr[10]}" >> parsed_secure

        fi
    done < service_array
}

isBlocked(){
  #if the ip exists in the file return true
  if grep -q $1 blocked; then
    t="$1"
    #extract the last time the ip was used
    line=$(tac blocked | grep -m1 $t | sed "s/$t.*//")
    test=$(date +%s -d"$line $2 minutes")
    #compare the blocked time + duration with the current time
    printf "comparing $(date -d"$line") and $(date) \n"
    if [ $test -ge $time2 ]
    then
      #drop the ip because time duration has passed
        $ip -D INPUT -s $1 -j DROP
    else
        return 0
    fi
  else
    #false
    return 1
  fi
}
unblock(){
  #check if ips need to be unblocked first
  while read line
  do
    $arr=($line)
    isBlocked ${arr[3]}
  fi
done < blocked
}

block_ip(){
    #find ip and port of all failed attempts for ssh
    cat parsed_secure | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | uniq -c > block_ip

    while read line
    do
        arr=($line)
        if [ "${arr[0]}" -ge $2 ]
        then
          #1 = ip to be checked if being blocked or not
          #2 = amount of time
          if isBlocked ${arr[1]} $1; then
            echo "already blocked"
          else
            #empty the remove.sh file
            echo > remove.sh
            echo "blocking ip" ${arr[1]}
            #add ip to the blocked list and time
            t="${arr[1]}"
            line=$(tac parsed_secure | grep -m1 $t | sed "s/$t.*//")
            echo "$line ${arr[1]}" >> blocked
            #$IP -A INPUT -s ${arr[1]} -j DROP
            #echo "/sbin/iptables -D INPUT -s ${arr[1]} -j DROP" >> remove.sh
            #echo "sed -i "/${arr[1]}/d" blocked" >> remove.sh
            #chmod 755 remove.sh
            #at -f jobs.txt now + 1 minutes
            #echo "at job set to remove block after $1 mins"
          fi

        else
            echo "not blocking" ${arr[1]} " since instances: " ${arr[0]} "/" $2
        fi

    done < block_ip
}

#1 = log file location
#2 = service
#3 = time to check
#4 = number of failed attempts before blocking ip
if [ "$#" -ne 4 ]; then
    echo "Usage error: ./ids.sh [log file location] [service to find] [amount of time blocked] [number of failed attempts]"
    exit 1
fi
#check if ips need to be unblocked
unblock
parse_logs $1 $2 $3
block_ip $3 $4
