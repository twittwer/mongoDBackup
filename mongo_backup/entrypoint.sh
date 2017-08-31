#!/bin/bash
echo "Database Backup Initilization..."

### Clone Git Repository for Backups ###
echo "=> clone backup repository..."
rm -rf /bck/backups
mkdir /bck/backups
git clone https://$GIT_USERNAME:$GIT_PASSWORD@$GIT_REPO /bck/backups
echo "=> backup repository cloned."

### Prepare Backup Repository ###
echo "=> prepare backup repository..."
pushd /bck/backups
if [ ! -d "/bck/backups/mongodb" ]; then
    mkdir /bck/backups/mongodb
    git add .; git commit -m "Initialize MongoDB Backup Directory"
    git push origin master
fi
popd
echo "=> backup repository prepared."

### Register Cron Job ###
echo "=> register cronjob for backup..."
echo "$BCK_CRON /bck/backup.sh >> /bck/backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> cronjob for backup registered."
exec cron -f
