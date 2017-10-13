#!/bin/bash -e

export MONGO_USERNAME=root
export MONGO_PASSWORD=paxxword
export GIT_URL="$1"

case "$2" in
up)
    docker network create db-tier
    docker-compose -f ./docker-compose.db.yml up -d $3
    docker-compose -f ./docker-compose.bck.yml up -d $3
    ;;
down)
    docker-compose -f ./docker-compose.bck.yml down $3
    docker-compose -f ./docker-compose.db.yml down $3
    docker network rm db-tier
    ;;
esac
