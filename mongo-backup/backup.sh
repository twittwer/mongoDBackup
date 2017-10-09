#!/bin/bash -e
source /bck/env.sh

### Variables ###
MONGODUMP_CMD="mongodump --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT --username $BCK2GIT_MONGO_USERNAME --password $BCK2GIT_MONGO_PASSWORD  --authenticationDatabase admin"
BCK_DIR="$BCK2GIT_BCK_DIR/mongodb"
BCK_NAME=$(date +\%Y-\%m-\%d_\%H-\%M)

### Internal Functions ###
function cleanUpBackupDirectory {
    while [ $(ls $BCK_DIR -N1 | wc -l) -gt 10 ];
    do
        BACKUP_TO_BE_DELETED=$(ls $BCK_DIR -N1 | sort | head -n 1)
        rm -rf $BCK_DIR/$BACKUP_TO_BE_DELETED
    done
}

### Functions ###
function initBackupProcess {
    pushd /bck/backups &>/dev/null
    git pull &>/dev/null
}

function dumpDatabases {
    printf " |---> dumping databases...\n"
    
    BCK_CMD="$MONGODUMP_CMD --archive=$BCK_DIR/$BCK_NAME.gz --gzip"

    if $BCK_CMD; then
        printf " | \`-> successfully dumped.\n"
    else
        printf " | \`-> dump failed.\n"
    fi

    cleanUpBackupDirectory
}

function uploadBackups {
    printf " |---> uploading backups...\n"

    git add --ignore-removal .
    if git diff-index --quiet HEAD --diff-filter=d --; then
        printf " | \`-> no backups found.\n"
    else
        git commit -m "MongoDB Backup at $BCK_NAME" &>/dev/null
        git push origin master &>/dev/null
        printf " | \`-> backups uploaded.\n"
    fi
}

function finishBackupProcess {
    popd &>/dev/null
}

### Execution ###
printf "MongoDB Backup Running...\n"
printf " | ID: $BCK_NAME\n"
initBackupProcess
dumpDatabases
uploadBackups
finishBackupProcess
printf "MongoDB Backup Finished.\n"
printf "===========================\n"
