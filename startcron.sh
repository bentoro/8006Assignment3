/home/aing/git/8006/8006Assignment3/ids.sh /home/aing/git/8006/8006Assignment3/secure ssh 2 3
echo "* * * * * /home/aing/git/8006/8006Assignment3/ids.sh /home/aing/git/8006/8006Assignment3/secure ssh 2 3" > start
#install new cron file
crontab start
