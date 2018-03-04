IP="/sbin/iptables"
ssh_array=()
log=log.txt

#parses the /var/log/secure file for $1 service, and creates an array with the Date, Time, IP address, and port
parse_logs(){

    #find all failed attempts within time range
    cat $1 | grep $2 | grep 'Failed password for root from' > service_array
    echo > parsed_secure

    time1=$(date +%s -d "$3 min ago")
    time2=$(date +%s)

    while read line
    do
        arr=($line)
        str=("${arr[0]} ${arr[1]} ${arr[2]}")
        test=$( date -d"$str" +"%s" )
        if [ $test -ge $time1 ] && [ $test -le $time2 ]
        then
            echo "found entry at: " $test " against: " $time1 >> $log
            echo "${arr[0]} ${arr[1]} ${arr[2]} ${arr[10]} ${arr[12]}" >> parsed_secure
        else
            echo "found nothing" >> $log
        fi
    done < service_array
}
#if the ip exists in the file return true
isblocked(){
  if grep -q $1 blocked; then
    return 0
  else
    return 1
  fi
}

block_ip(){
    #find ip and port of all failed attempts for ssh
    cat parsed_secure | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | uniq -c > block_ip

    while read line
    do
        arr=($line)
        if [ "${arr[0]}" -ge $2 ]
        then
          #if ip is already blocked dont block it
          if isblocked ${arr[1]}; then
            echo "already blocked" >> $log
          else
            echo > remove.sh
            echo "blocking ip" ${arr[1]} >> $log
            #add ip to the blocked list
            echo ${arr[1]} > blocked
            $IP -A INPUT -s ${arr[1]} -j DROP
            echo "/sbin/iptables -D INPUT -s ${arr[1]} -j DROP" >> remove.sh
            echo "sed -i "/${arr[1]}/d" blocked" >> remove.sh
          fi

        else
            echo "not blocking" ${arr[1]} " since instances: " ${arr[0]} "/" $2 >> $log
        fi

    done < block_ip
}

unblock(){
    while read line
    do
        attempted=$( grep -c $line parsed_secure)
        echo $line attempted: $attempted/$1 times >>$log
        if [ $attempted -lt $1 ]
        then
            echo clearing: $line >> $log
            $IP -D INPUT -s $line -j DROP
            sed -i.bak '/$line/d' blocked
        fi
    done < blocked
}

#1 = log file location
#2 = service
#3 = time to check
#4 = number of failed attempts before blocking ip
if [ "$#" -ne 4 ]; then
    echo "Usage error: ./ids.sh [log file location] [service to find] [amount of time blocked] [number of failed attempts]" >> $log
    exit 1
fi

#rm -f blocked
rm -f block_ip
rm -f parsed_secure
rm -f service_array
rm -f log.txt
echo > log.txt
#echo > blocked

while true
do
    parse_logs $1 $2 $3
    block_ip $3 $4
    #after blocked and block_ip are updated
    unblock $4
    sleep 5
done
