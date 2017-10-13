#!/bin/bash
printf "\nDB Seeding...\n"

if [ -n $MONGO_INITDB_ROOT_USERNAME ] && [ ! -z $MONGO_INITDB_ROOT_USERNAME ] && [ -n $MONGO_INITDB_ROOT_PASSWORD ] && [ ! -z $MONGO_INITDB_ROOT_PASSWORD ]; then
    MONGO_AUTH="--username $MONGO_INITDB_ROOT_USERNAME --password $MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin"
fi

# user seeding
# -

# data seeding
printf " |---> data seed on test db\n"
mongo test --host localhost $MONGO_AUTH /docker-entrypoint-initdb.d/data-init.js
printf " |---> data seed on stage db\n"
mongo stage --host localhost $MONGO_AUTH /docker-entrypoint-initdb.d/data-init.js

printf "DB Seeded.\n\n"
