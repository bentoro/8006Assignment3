#echo new cron into cron file
echo "* * * * * ./ids.sh secure ssh 1 3" >> start
#install new cron file
crontab start
