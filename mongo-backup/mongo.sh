#!/bin/bash -e
source /bck/env.sh

if [ -n "$1" ]; then
    INIT_CMD="$1"
else
    INIT_CMD="show dbs\n"
fi

printf "$INIT_CMD" | mongo --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT --username $BCK2GIT_MONGO_USERNAME --password $BCK2GIT_MONGO_PASSWORD  --authenticationDatabase admin --quiet

mongo --host $BCK2GIT_MONGO_HOST --port $BCK2GIT_MONGO_PORT --username $BCK2GIT_MONGO_USERNAME --password $BCK2GIT_MONGO_PASSWORD  --authenticationDatabase admin --quiet
