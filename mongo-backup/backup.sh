#!/bin/bash -e
source /bck/env.sh

function indent() {
    case "$1" in
    process)  sed 's/^/== /'
        ;;
    processInfo)  sed 's/^/ |> /'
        ;;
    task)  sed 's/^/ |---> /'
        ;;
    taskEnd)  sed 's/^/ | \`-> /'
        ;;
    taskInfo)  sed 's/^/ | |> /'
        ;;
    taskProgress)  sed 's/^/ | |.. /'
        ;;
    taskState)  sed 's/^/ | |-> /'
        ;;
    esac
}

### Variables ###
MONGODUMP_CMD="mongodump --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT"
if [ ! -z $BCK2GIT_MONGO_USERNAME ] && [ ! -z $BCK2GIT_MONGO_PASSWORD ]; then
    MONGODUMP_CMD="$MONGODUMP_CMD --username $BCK2GIT_MONGO_USERNAME --password $BCK2GIT_MONGO_PASSWORD  --authenticationDatabase $BCK2GIT_MONGO_AUTH_DB"
fi
BCK_DIR="$BCK2GIT_BCK_DIR/mongodb"
BCK_NAME=$(date +\%Y-\%m-\%d_\%H-\%M)

### Functions ###
function initBackup {
    printf "init backup...\n" | indent task

    pushd /bck/backups &>/dev/null
    touch $BCK_DIR/$BCK_NAME.log
    git pull --no-edit 2>&1 | indent taskProgress

    printf "done.\n" | indent taskEnd
}

function dumpDatabases {
    printf "dumping databases..." | indent task

    BCK_CMD="$MONGODUMP_CMD --archive=$BCK_DIR/$BCK_NAME.gz --gzip"

    if $BCK_CMD >> $BCK_DIR/$BCK_NAME.log 2>&1; then
        printf " done.\n"
    else
        printf " failed.\n"
    fi
}

function cleanUpBackupDirectory {
    printf "clean up old backups..." | indent task

    while [ $(ls $BCK_DIR -N1 | grep '\.gz$' | wc -l) -gt 1 ];
    do
        OLD_BACKUP=$(ls $BCK_DIR -N1 | grep '\.gz$' | sort | head -n 1)
        rm -rf $BCK_DIR/$OLD_BACKUP
    done

    while [ $(ls $BCK_DIR -N1 | grep '\.log$' | wc -l) -gt 1 ];
    do
        OLD_LOG=$(ls $BCK_DIR -N1 | grep '\.log$' | sort | head -n 1)
        rm -rf $BCK_DIR/$OLD_LOG
    done

    printf " done.\n"
}

function uploadBackups {
    printf "uploading backups...\n" | indent task

    git add .
    if git diff-index --quiet HEAD --; then
        printf "nothing to upload.\n" | indent taskEnd
    else
        git commit -m "MongoDB of $BCK2GIT_INSTANCE_NAME at $BCK_NAME" 2>&1 | indent taskProgress
        PUSHED=false
        until [ "$PUSHED" = true ]; do
            printf "push updates...\n" | indent taskState
            git pull --no-edit 2>&1 | indent taskProgress
            if git push origin master 2>&1 | indent taskProgress; then
                PUSHED=true
                printf "push succeeds.\n" | indent taskState
            else
                printf "push failed.\n" | indent taskState
            fi
        done
        printf "backups uploaded.\n" | indent taskEnd
    fi
}

function finishBackup {
    popd &>/dev/null
}

### Execution ###
printf "MongoDB Backup Running...\n" | indent process
printf "ID: $BCK_NAME\n" | indent processInfo
initBackup
dumpDatabases
cleanUpBackupDirectory
uploadBackups
finishBackup
printf "MongoDB Backup Finished.\n" | indent process
