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
MONGORESTORE_CMD="mongorestore --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT"
if [ -n $BCK2GIT_MONGO_USERNAME ] && [ -n $BCK2GIT_MONGO_PASSWORD ]; then
    MONGODUMP_CMD="$MONGODUMP_CMD --username $BCK2GIT_MONGO_USERNAME --password $BCK2GIT_MONGO_PASSWORD  --authenticationDatabase $BCK2GIT_MONGO_AUTH_DB"
fi

SRC_COMMIT=""
SRC_INSTANCE="$BCK2GIT_INSTANCE_NAME"
RST_DIR="/bck/restore"
RST_FILE=""

INCLUDE=""
EXCLUDE=""
MONGO_OPTS=""
DROP=true

### Functions ###
function evalParams {
    printf "evaluate parameters..." | indent task

    for i in "$@"
    do
    case $i in
        -bck=*|--bck-hash=*)
            SRC_COMMIT="${i#*=}"
            shift # past argument=value
        ;;
        -src=*|--src-instance=*)
            SRC_INSTANCE="${i#*=}"
            shift
        ;;
        -incl=*|--nsInclude=*)
            INCLUDE="${i#*=}"
            shift
        ;;
        -excl=*|--nsExclude=*)
            EXCLUDE="${i#*=}"
            shift
        ;;
        -opts=*|--mongo-options=*)
            MONGO_OPTS="${i#*=}"
            shift
        ;;
        --no-drop)
            DROP=false
            shift
        ;;
        *)
            printf "\n ! ERROR: Unknown Option ${i} !\n"
            exit 1
        ;;
    esac
    done

    RST_DIR="$RST_DIR/$SRC_INSTANCE/mongodb"

    if [ ! -n "$SRC_COMMIT" ]; then
        printf "\n ! ERROR: Missing Commit Hash (needed to define source backup to restore from) !\n"
        exit 1
    fi

    if [ ! -n "$INCLUDE" ] && [ ! -n "$EXCLUDE" ] && [ ! -n "$MONGO_OPTS" ]; then
        printf "\n ! ERROR: Insufficient Specifications (nsInclude, nsExclude or mongo-options needed) !\n"
        exit 1
    fi

    printf " done.\n"
}

function initRestore {
    printf "init restore directory...\n" | indent task

    if [ ! -d "/bck/restore/.git" ]; then
        printf "clone backup repo as restore base...\n" | indent taskState
        rm -rf /bck/restore
        mkdir /bck/restore
        git clone $BCK2GIT_GIT_URL /bck/restore 2>&1 | indent taskProgress
    fi

    printf "checkout selected backup version...\n" | indent taskState
    pushd /bck/restore &>/dev/null
    git checkout $SRC_COMMIT 2>&1 | indent taskProgress

    printf "restore directory initilized.\n" | indent taskEnd
}

function checkRestoreFile {
    RST_FILE=$(ls $RST_DIR -N1 | grep '\.gz$' | sort -r | head -n 1)
    if [ ! -f "$RST_DIR/$RST_FILE" ]; then
        printf " ! ERROR: Backup File Not Found !\n"
        exit 1
    fi

    printf "selected backup: $RST_DIR/$RST_FILE\n" | indent processInfo
}

function restoreDatabase {
    printf "restore database...\n" | indent task

    CMD_OPTIONS="--archive=$RST_DIR/$RST_FILE --gzip"
    if [ -n "$INCLUDE" ]; then
        CMD_OPTIONS="$CMD_OPTIONS --nsInclude $INCLUDE"
    fi
    if [ -n "$EXCLUDE" ]; then
        CMD_OPTIONS="$CMD_OPTIONS --nsExclude $EXCLUDE"
    fi
    if [ -n "$MONGO_OPTS" ]; then
        CMD_OPTIONS="$CMD_OPTIONS $MONGO_OPTS"
    fi
    if [ "$DROP" = true ]; then
        CMD_OPTIONS="$CMD_OPTIONS --drop"
    fi

    printf "options: $CMD_OPTIONS\n" | indent taskInfo

    RESTORE_CMD="$MONGORESTORE_CMD $CMD_OPTIONS"
    if $RESTORE_CMD 2>&1 | indent taskProgress; then
        printf "database is restored.\n" | indent taskEnd
    else
        printf "restore failed.\n" | indent taskEnd
    fi
}

function finishRestore {
    popd &>/dev/null
}

### Execution ###
printf "MongoDB Restore Running...\n" | indent process
evalParams $*
initRestore
checkRestoreFile
restoreDatabase
finishRestore
printf "MongoDB Restore Finished.\n" | indent process
