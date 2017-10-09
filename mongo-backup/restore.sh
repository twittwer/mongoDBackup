#!/bin/bash -e
source /bck/env.sh

printf "MongoDB Restore Running...\n"

### Internal Variables ###
MONGORESTORE_CMD="mongorestore --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT --username $BCK2GIT_MONGO_USERNAME --password $BCK2GIT_MONGO_PASSWORD  --authenticationDatabase admin"

BCK_DIR=""
BCK_FILE=""

INCLUDE=""
EXCLUDE=""
MONGO_OPTS=""
DROP=true

### Parameter Evaluation ###
for i in "$@"
do
case $i in
    -bck=*|--backup=*)
        BCK_FILE="${i#*=}.gz"
        shift # past argument=value
    ;;
    -src=*|--src-instance=*)
        BCK_DIR="/bck/backups/${i#*=}"
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
        printf " ! ERROR: Unknown Option ${i} !\n"
        exit 1
    ;;
esac
done

if [ ! -n "$BCK_DIR" ]; then
    BCK_DIR="$BCK2GIT_BCK_DIR"
fi
BCK_DIR="$BCK_DIR/mongodb"

if [ ! -n "$BCK_FILE" ]; then
    BCK_FILE=$(ls $BCK_DIR -N1 | sort -r | head -n 1)
fi

if [ ! -n "$INCLUDE" ] && [ ! -n "$EXCLUDE" ] && [ ! -n "$MONGO_OPTS" ]; then
    printf " ! ERROR: Insufficient Specifications (nsInclude, nsExclude or mongo-options needed) !\n"
    exit 1
fi

### Init ###
pushd /bck/backups &>/dev/null
git pull &>/dev/null
git checkout $BCK_DIR &>/dev/null

if [ ! -f "$BCK_DIR/$BCK_FILE" ]; then
    printf " ! ERROR: Backup File Not Found !\n"
    exit 1
fi
printf " | selected backup: $BCK_DIR/$BCK_FILE\n"

### Restore ###
printf " |---> restore database...\n"

RESTORE_CMD="$MONGORESTORE_CMD --archive=$BCK_DIR/$BCK_FILE --gzip"
if [ -n "$INCLUDE" ]; then
    RESTORE_CMD="$RESTORE_CMD --nsInclude $INCLUDE"
fi
if [ -n "$EXCLUDE" ]; then
    RESTORE_CMD="$RESTORE_CMD --nsExclude $EXCLUDE"
fi
if [ -n "$MONGO_OPTS" ]; then
    RESTORE_CMD="$RESTORE_CMD $MONGO_OPTS"
fi
if [ "$DROP" = true ]; then
    RESTORE_CMD="$RESTORE_CMD --drop"
fi

if $RESTORE_CMD; then
    printf " | \`-> database is restored.\n"
else
    printf " | \`-> restore failed.\n"
fi

### Finish ###
popd &>/dev/null
printf "MongoDB Restore Finished.\n"
