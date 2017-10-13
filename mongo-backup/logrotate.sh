#!/bin/bash -e
source /bck/env.sh

LOG_FILE="/bck/backup.log"
LOG_ARCHIVE="/bck/logs"
DATETIME=$(date +\%Y-\%m-\%d_\%H-\%M)

cp $LOG_FILE $LOG_ARCHIVE/backup.$DATETIME.log
printf "" > $LOG_FILE

while [ $(ls $LOG_ARCHIVE -N1 | wc -l) -gt $BCK2GIT_LOGROTATE_LIMIT ];
do
    OUTDATED_LOG=$(ls $LOG_ARCHIVE -N1 | sort | head -n 1)
    rm -rf $LOG_ARCHIVE/$OUTDATED_LOG
done
