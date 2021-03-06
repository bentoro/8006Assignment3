#!/bin/bash
#------------------------------------------------------------------------------
# SOURCE FILE: 		ips.sh
#
# PROGRAM:  		COMP8006 - Assignment 3
#
#			function parse_logs()
#			function isBlocked()
#			function unblock()
#			function block_ip()
#
# DATE:			Mar 6, 2018
#
# DESIGNER:		Benedict Lo
# Programmer:		Benedict Lo
#
# Parameters: String filename - filename of the log
#             String service - service to check for failed attempts
#             int time - duration to go back in the log
#
# NOTES:		This script checks /var/log/secure and determines if there are any
#           IP's that have failed attempts using the specified service, if it
#           exceeds the limit block the ip for the user defined time.
#
#------------------------------------------------------------------------------

IP="/sbin/iptables"
log=log.txt
#parses the /var/log/secure file for $1 service, and creates an array with the Date, Time, IP address, and port
parse_logs(){

    #find all failed attempts within time range
    cat $1 | grep $2 | grep 'Failed password for root from' > service_array

    #empty the parsed_secure file
    echo > parsed_secure
    #parse the failed attempts by date
    time1=$(date +%s -d "$3 minutes ago")
    time2=$(date +%s)
    while read line
    do
        arr=($line)
        str=("${arr[0]} ${arr[1]} ${arr[2]}")
        test=$( date -d"$str" +"%s" )
        if [ $test -ge $time1 ] && [ $test -le $time2 ]
        then
            printf "found entry at: $(date -d"$str") \n" >> $log
            echo "${arr[0]} ${arr[1]} ${arr[2]} ${arr[10]}" >> parsed_secure

        fi
    done < service_array
}
#---------------------------------------------------------------------------
	#
	#    FUNCTION:		isBlocked()
	#
  #    DATE:			Mar 6, 2018
  #
  #    DESIGNER:		Benedict Lo
  #    Programmer:		Benedict Lo
  #
	#    DESCRIPTION:	Check if the ip is blocked if its blocked return true else unblock if it is expired
  #
  #    Parameters: String IP - IP address to check
  #
  #
	#    RETURNS:
	#                	bool blocked or not
	#
	#---------------------------------------------------------------------------
isBlocked(){
  #if the ip exists in the file return true
  if grep -q $1 blocked; then
    t="$1"
    #extract the last time the ip was used
    line=$(tac blocked | grep -m1 $t | sed "s/$t.*//")
    test=$(date +%s -d"$line $2 minutes")
    currtime=$(date +%s)
    #compare the blocked time + duration with the current time
    printf "comparing $(date -d"$line $2 minutes") with $(date) \n" >> $log
    if [ $currtime -ge $test ]
    then
      #drop the ip because time duration has passed
        $IP -D INPUT -s $1 -j DROP
        sed -i "/$1/d" blocked
        echo $1 "has been unblocked" >> $log

    else
        return 0
    fi
  else
    #false
    return 1
  fi
}
#---------------------------------------------------------------------------
	#
	#    FUNCTION:		unblock()
	#
  #    DATE:			Mar 6, 2018
  #
  #    DESIGNER:		Benedict Lo
  #    Programmer:		Benedict Lo
  #
	#    DESCRIPTION:	This method checks if the ips in the blocked list needs to be
  #               needs to be unblocked
	#
	#
	#    RETURNS:
	#                	void
	#
	#---------------------------------------------------------------------------
unblock(){
  #check if ips need to be unblocked first
  while read line
  do
    arr=($line)
    isBlocked ${arr[3]}
done < blocked
}
#---------------------------------------------------------------------------
	#
	#    FUNCTION:		block_ip()
	#
  #    DATE:			Mar 6, 2018
  #
  #    DESIGNER:		Benedict Lo
  #    Programmer:		Benedict Lo
  #
	#    DESCRIPTION:	This method removes checks if the ip that was parsed is blocked
  #                 If the ip isn't blocked block it and add it to iptables
  #
  #   Parameters: int time - duration to go back in the log
  #               int amount - amount of fialed attempts 
  #
	#    RETURNS:
	#                	void
	#
	#---------------------------------------------------------------------------
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
            echo "already blocked" >> $log
          else
            #echo > remove.sh
            echo "blocking ip" ${arr[1]} >> $log
            #add ip to the blocked list and time
            t="${arr[1]}"
            #add the last instance of the time into the blocked list
            line=$(tac parsed_secure | grep -m1 $t | sed "s/$t.*//")
            echo "$line ${arr[1]}" >> blocked
            $IP -A INPUT -s ${arr[1]} -j DROP
          fi

        else
            echo "not blocking" ${arr[1]} " since instances: " ${arr[0]} "/" $2 >> $log
        fi

    done < block_ip
}

#1 = log file location
#2 = service
#3 = time to check
#4 = number of failed attempts before blocking ip
if [ "$#" -ne 4 ]; then
    echo "Usage error: ./ids.sh [log file location] [service to find] [amount of time blocked] [number of failed attempts]" >> $log
    exit 1
fi
#check if ips need to be unblocked

while true
do
    unblock
    parse_logs $1 $2 $3
    block_ip $3 $4
    sleep 1
done
