#!/bin/bash
printf "\nDB Seeding...\n"

# user seeding
# -

# data seeding
printf " |---> data seed on test db\n"
mongo test --host localhost --username $MONGO_INITDB_ROOT_USERNAME --password $MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin /docker-entrypoint-initdb.d/data-init.js
printf " |---> data seed on stage db\n"
mongo stage --host localhost --username $MONGO_INITDB_ROOT_USERNAME --password $MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin /docker-entrypoint-initdb.d/data-init.js

printf "DB Seeded.\n\n"
