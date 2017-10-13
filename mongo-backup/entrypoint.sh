#!/bin/bash -e

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

### Functions ###
function prepareEnv {
    # Instance Config
    export BCK2GIT_INSTANCE_NAME="${BCK2GIT_INSTANCE_NAME:-unknown}"
    printf "backup instance: $BCK2GIT_INSTANCE_NAME\n" | indent processInfo
    
    # Backup Config
    BCK_SCHEDULE="${BCK2GIT_SCHEDULE:-0 1,13 * * *}"
    unset BCK2GIT_SCHEDULE
    printf "backup schedule: $BCK_SCHEDULE\n" | indent processInfo
    export BCK2GIT_BCK_DIR="/bck/backups/$BCK2GIT_INSTANCE_NAME"

    # Logrotate Config
    LOGROTATE_SCHEDULE="${BCK2GIT_LOGROTATE_SCHEDULE:-42 1 * * 7}"
    unset BCK2GIT_LOGROTATE_SCHEDULE
    printf "logrotate schedule: $LOGROTATE_SCHEDULE\n" | indent processInfo
    export BCK2GIT_LOGROTATE_LIMIT="${BCK2GIT_LOGROTATE_LIMIT:-4}"
    printf "logrotate limit: $BCK2GIT_LOGROTATE_LIMIT\n" | indent processInfo
    
    # Git Config
    BCK2GIT_GIT_URL="$BCK2GIT_GIT_URL"
    printf "git repo: $BCK2GIT_GIT_URL\n" | indent processInfo
    if [ -z $BCK2GIT_GIT_URL ]; then
        printf " ! ERROR: BCK2GIT_GIT_URL needs to be set) !\n"
        exit 1
    fi
    GIT_NAME="${BCK2GIT_GIT_NAME:-"Backup2Git $BCK2GIT_INSTANCE_NAME"}"
    unset BCK2GIT_GIT_NAME
    GIT_EMAIL="$BCK2GIT_GIT_EMAIL"
    unset BCK2GIT_GIT_EMAIL
    printf "git author: $GIT_NAME (mail: $GIT_EMAIL)\n" | indent processInfo
    
    # MongoDB Config
    export BCK2GIT_MONGO_HOST="${BCK2GIT_MONGO_HOST:-localhost}"
    export BCK2GIT_MONGO_PORT="${BCK2GIT_MONGO_PORT:-27017}"
    export BCK2GIT_MONGO_USERNAME="$BCK2GIT_MONGO_USERNAME"
    export BCK2GIT_MONGO_PASSWORD="$BCK2GIT_MONGO_PASSWORD"
    export BCK2GIT_MONGO_AUTH_DB="${BCK2GIT_MONGO_AUTH_DB:-admin}"
    if ( [ -z $BCK2GIT_MONGO_USERNAME ] && [ ! -z $BCK2GIT_MONGO_PASSWORD ] ) || ( [ ! -z $BCK2GIT_MONGO_USERNAME ] && [ -z $BCK2GIT_MONGO_PASSWORD ] ); then
        printf " ! ERROR: Mongo Authorization requires BCK2GIT_MONGO_USERNAME and BCK2GIT_MONGO_PASSWORD !\n"
        exit 1
    fi
    printf "mongo host: $BCK2GIT_MONGO_HOST:$BCK2GIT_MONGO_PORT" | indent processInfo
    if [ ! -z $BCK2GIT_MONGO_USERNAME ] && [ ! -z $BCK2GIT_MONGO_PASSWORD ]; then
        printf " (user: $BCK2GIT_MONGO_USERNAME, auth: $BCK2GIT_MONGO_AUTH_DB)\n"
    else
        printf " (unsecured mongo db instance)\n"
    fi

    # save config environment in file
    printenv | sed 's/^\(.*\)$/export \1/g' | grep -E "^export BCK2GIT_" > /bck/env.sh
    source /bck/env.sh
}

function prepareGit {
    printf "prepare git..." | indent task
    
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    mkdir -p ~/.ssh/
    cat /bck/github_com >> ~/.ssh/known_hosts
    cp /data/ssh_private_key ~/.ssh/id_rsa

    printf " done.\n"
}

function cloneRepo {
    printf "clone backup repository...\n" | indent task

    rm -rf /bck/backups
    mkdir -p /bck/backups
    git clone $BCK2GIT_GIT_URL /bck/backups 2>&1 | indent taskProgress
    
    printf "backup repository cloned.\n" | indent taskEnd
}

function prepareRepo {
    printf "prepare backup repository...\n" | indent task
    pushd /bck/backups &> /dev/null

    if [ ! -d "$BCK2GIT_BCK_DIR/mongodb" ]; then
        printf "create mongodb directory...\n" | indent taskState
        mkdir -p "$BCK2GIT_BCK_DIR/mongodb"
        touch "$BCK2GIT_BCK_DIR/mongodb/.gitkeep"
        git add .; git commit -m "Initialize MongoDB Backup Directory" 2>&1 | indent taskProgress
        PUSHED=false
        until [ "$PUSHED" = true ]; do
            printf "push created directory...\n" | indent taskState
            git pull --no-edit 2>&1 | indent taskProgress
            if git push origin master 2>&1 | indent taskProgress; then
                PUSHED=true
                printf "push succeeds.\n" | indent taskState
            else
                printf "push failed.\n" | indent taskState
            fi
        done
    fi

    popd &>/dev/null
    printf "backup repository prepared.\n" | indent taskEnd
}

function scheduleBackup {
    printf "schedule backup & logrotation (via cron)...\n" | indent task
    
    mkdir /bck/logs
    touch /bck/backup.log
    touch /bck/rotate.log

    touch cron.tmp
    echo -e "$BCK_SCHEDULE /bck/backup.sh >> /bck/backup.log 2>&1" >> cron.tmp
    echo -e "$LOGROTATE_SCHEDULE /bck/logrotate.sh >> /dev/null 2>&1" >> cron.tmp
    crontab cron.tmp
    rm cron.tmp
    
    printf "schedule ready.\n" | indent taskEnd
}

### Execution ###
printf "Database Backup Initilization...\n" | indent process
prepareEnv
prepareGit
cloneRepo
prepareRepo
scheduleBackup
printf "Backup Initilized.\n" | indent process
printf "cron will be executed in foreground mode\n" | indent processInfo
printf "logs can be observed via \"tail -f /bck/backup.log\" (archived logs can be found in /bck/logs)\n" | indent processInfo
cron -f
