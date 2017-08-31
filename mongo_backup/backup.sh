#!/bin/bash
echo "MongoDB Backup Running..."

MONGODUMP_CMD="mongodump --host $MONGO_HOST --port $MONGO_PORT --username $MONGO_USERNAME --password $MONGO_PASSWORD"
BCK_DIR="/bck/backups/mongodb"
BCK_NAME=\$(date +\%Y-\%m-\%d_\%H-\%M)

pushd /bck/backups
git pull

IFS=',' read -r -a DB_ARRAY <<< "$BCK_DATABASES"
for DB in "${DB_ARRAY[@]}"
do
    echo "=> dumping database... ($DB)"
    mkdir -p $BCK_DIR/$DB

    $MONGODUMP_CMD --archive=$BCK_DIR/$DB/$BCK_NAME.gz --gzip --db $DB

    while [ $(ls $BCK_DIR/$DB -N1 | wc -l) -gt 10 ];
    do
        BACKUP_TO_BE_DELETED=$(ls $BCK_DIR/$DB -N1 | sort | head -n 1)
        rm -rf $BCK_DIR/$DB/$BACKUP_TO_BE_DELETED
    done
done

git add --ignore-removal .; git commit -m "MongoDB Backup at $BCK_NAME"
git push origin master
popd
