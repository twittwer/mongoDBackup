#!/bin/bash -e

### Functions ###
function initEnv {
    # Main Config
    export BCK2GIT_INSTANCE_NAME="${BCK2GIT_INSTANCE_NAME:-unknown}"
    export BCK2GIT_BCK_DIR="/bck/backups/$BCK2GIT_INSTANCE_NAME"
    BCK_SCHEDULE="${BCK2GIT_SCHEDULE:-0 1,13 * * *}"
    unset BCK2GIT_SCHEDULE
    printf " | backup instance: $BCK2GIT_INSTANCE_NAME\n"
    printf " | backup schedule: $BCK_SCHEDULE\n"
    
    # Git Config
    GIT_URL="$BCK2GIT_GIT_URL"
    unset BCK2GIT_GIT_URL
    GIT_NAME="${BCK2GIT_GIT_NAME:-"Backup2Git $BCK2GIT_INSTANCE_NAME"}"
    unset BCK2GIT_GIT_NAME
    printf " | git author: $GIT_NAME\n"
    
    # MongoDB Config
    export BCK2GIT_MONGO_HOST="${BCK2GIT_MONGO_HOST:-localhost}"
    export BCK2GIT_MONGO_PORT="${BCK2GIT_MONGO_PORT:-27017}"
    export BCK2GIT_MONGO_USERNAME="$BCK2GIT_MONGO_USERNAME"
    export BCK2GIT_MONGO_PASSWORD="$BCK2GIT_MONGO_PASSWORD"
    printf " | mongo db\n"
    printf " | \`- host: $BCK2GIT_MONGO_HOST:$BCK2GIT_MONGO_PORT (user: $BCK2GIT_MONGO_USERNAME)\n"

    # save config environment in file
    printenv | sed 's/^\(.*\)$/export \1/g' | grep -E "^export BCK2GIT_" > /bck/env.sh
    source /bck/env.sh
}

function prepareGit {
    git config --global user.name "$GIT_NAME"

    mkdir -p ~/.ssh/
    cat /bck/github_com >> ~/.ssh/known_hosts
    cp /data/ssh_private_key ~/.ssh/id_rsa
}

function cloneRepo {
    printf " |---> clone backup repository...\n"

    rm -rf /bck/backups
    mkdir /bck/backups
    git clone $GIT_URL /bck/backups
    
    printf " | \`-> backup repository cloned.\n"
}

function initRepo {
    printf " |---> prepare backup repository...\n"
    pushd /bck/backups &>/dev/null

    if [ ! -d "$BCK2GIT_BCK_DIR/mongodb" ]; then
        mkdir -p "$BCK2GIT_BCK_DIR/mongodb"
        touch "$BCK2GIT_BCK_DIR/mongodb/.gitkeep"
        git add .; git commit -m "Initialize MongoDB Backup Directory" &>/dev/null
        git push origin master
    fi

    popd &>/dev/null
    printf " | \`-> backup repository prepared.\n"
}

function scheduleBackup {
    printf " |---> schedule backup (via cron)...\n"
    
    touch /bck/backup.log
    printf "$BCK_SCHEDULE /bck/backup.sh >> /bck/backup.log 2>&1" | crontab -
    cron
    
    printf " | \`-> backup scheduled.\n"
}

function observeBackupExec {
    printf "Observing Backup Log:\n=====================\n"
    tail -f /bck/backup.log
}

### Execution ###
printf "Database Backup Initilization...\n"
initEnv
prepareGit
cloneRepo
initRepo
scheduleBackup
printf "Backup Initilized.\n\n"
observeBackupExec
