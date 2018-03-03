#echo new cron into cron file
echo "* * * * * /home/Ben/github/8006Assignment3/test.sh" > start
#install new cron file
crontab start
