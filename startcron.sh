#User configuration---------------------------------

#IDS script location:
script=/home/aing/git/8006/8006Assignment3/ids.sh

#Security log location:
log=/home/aing/git/8006/8006Assignment3/secure

#Service to monitor
service=ssh

#Duration to block
duration=2

#Failure tolerance
tolerance=3

#---------------------------------------------------

#/home/aing/git/8006/8006Assignment3/ids.sh /home/aing/git/8006/8006Assignment3/secure ssh 2 3

#run IDS immediately after starting cron job
echo "* * * * * $script $log $service $duration $tolerance" > start

#echo "* * * * * /home/aing/git/8006/8006Assignment3/ids.sh /home/aing/git/8006/8006Assignment3/secure ssh 2 3" > start

#install new cron file
crontab start


#$script $log $service $duration $tolerance
