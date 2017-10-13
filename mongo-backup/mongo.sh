#!/bin/bash -e
source /bck/env.sh

if [ -n "$1" ]; then
    INIT_CMD="$1"
else
    INIT_CMD="show dbs\n"
fi

if [ ! -z $BCK2GIT_MONGO_USERNAME ] && [ ! -z $BCK2GIT_MONGO_PASSWORD ]; then
    AUTH="--username $BCK2GIT_MONGO_USERNAME --password $BCK2GIT_MONGO_PASSWORD  --authenticationDatabase $BCK2GIT_MONGO_AUTH_DB"
fi

printf "$INIT_CMD" | mongo --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT $AUTH --quiet

mongo --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT $AUTH --quiet
