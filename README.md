# MongoDBackup
Docker container to regularly dump (backup) your MongoDB databases in a git repository.

## Backup Service

### Docker Compose Setup (Sample)

```
services:
  mongo_db:
    container_name: mongo_db
    image: mongo:latest
    expose:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USERNAME}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD}
  mongo_backup:
    container_name: mongo_backup
    image: twittwer/mongodbackup
    links:
      - mongo_db
    environment:
      - BCK2GIT_INSTANCE_NAME=devServer01
      - BCK2GIT_MONGO_HOST=mongo_db
      - BCK2GIT_MONGO_USERNAME=${MONGO_USERNAME}
      - BCK2GIT_MONGO_PASSWORD=${MONGO_PASSWORD}
      - BCK2GIT_GIT_URL=git@github.com:<USERNAME>/db-bck.git
    volumes:
      - ~/.ssh/id_rsa:/data/ssh_private_key
```
You can try the sample provided in the repository.  
Just create a test repository a run the script.  
> WARNING: sample setup will try to use your local ssh key `~/.ssh/id_rsa`  

Start: `/setup.sh <repo-url> up`  
Stop : `/setup.sh <repo-url> down`  

### Volumes

| Container Path            | Sample                                | Description                           |
| ------------------------- | ------------------------------------- | ------------------------------------- |
| **/data/ssh_private_key** | `~/.ssh/id_rsa:/data/ssh_private_key` | private ssh key for git interactions* |

> *) The corresponding public key has to be registered at git host, e.g. `github.com/settings/keys`.

### Environment Variables

| Variable                     | Default (Sample)                         | Description                                                     |
| ---------------------------- | ---------------------------------------- | --------------------------------------------------------------- |
| *BCK2GIT_INSTANCE_NAME*      | `unknown`                                | name of configured service instance (see repo structure)        |
| *BCK2GIT_SCHEDULE*           | `0 1,13 * * *`                           | cron schedule for db dumping (default: daily at 01:00 & 13:00)  |
| **BCK2GIT_GIT_URL**          | (`git@github.com:<USERNAME>/db-bck.git`) | ssh url of git repository to save db dumps in                   |
| *BCK2GIT_GIT_NAME*           | `Backup2Git <INSTANCE_NAME>`             | name of commit author                                           |
| *BCK2GIT_GIT_EMAIL*          | (`backup-script@email.com`)              | email of commit author                                          |
| *BCK2GIT_MONGO_HOST*         | `localhost`                              | host address of mongo server                                    |
| *BCK2GIT_MONGO_PORT*         | `27017`                                  | port number of mongo server                                     |
| **BCK2GIT_MONGO_USERNAME***  | (`root`)                                 | mongo user with privileges for `mongodump` and `mongorestore`   |
| **BCK2GIT_MONGO_PASSWORD***  | (`paxxword`)                             | password of configured username                                 |
| *BCK2GIT_MONGO_AUTH_DB*      | `admin`                                  | definition of mongo's authentication database                   |
| *BCK2GIT_LOGROTATE_SCHEDULE* | `42 1 * * 7`                             | cron schedule for log rotation (default: every sunday at 01:42) |
| *BCK2GIT_LOGROTATE_LIMIT*    | `4`                                      | number of archived log files to keep                            |

> *) currently there are problems with unsecured mongo instances, that's why authorization is required

## Restore Command

Minimal Sample : `docker exec mongo_backup ./restore.sh -bck=<SHA> -incl="myDB.*"`
Extended Sample: `docker exec mongo_backup ./restore.sh -bck=<SHA> -src=DevelopServer -incl="myDB.*" -excl="myDB.*_beta" -opts="--dryRun"`

### Command Options

| Option                      | Description                                                                 |
| --------------------------- | --------------------------------------------------------------------------- |
| **-bck=**, **--bck-hash=**  | commit hash of backup version to restore from                               |
| *-src=*, *--src-instance=*  | name of backup's source instance (default is the local instance)            |
| -incl=*, --nsInclude=\*     | equivalent to mongorestore option                                           |
| -excl=*, --nsExclude=\*     | equivalent to mongorestore option                                           |
| -opts=*, --mongo-options=\* | string to append mongorestore command by more detailed mongorestore options |
| *--no-drop*                 | negated version of mongorestore's `--drop` option                           |

> *) one of the 3 options had to be defined

## Mongo DB Accessor

Can be used to perform action on the mongo db instance. The first parameter can be used to perform initial commands.  
The commands are restricted to the privileges of the backup user.  
Samples:
- `docker exec -it mongo_backup ./mongo.sh`
- `docker exec -it mongo_backup ./mongo.sh "use myDB;\ndb.myData.insert({data:"test"});\ndb.myData.find();\n"`

## Structure of Backup Repository

```
<backup-repository>
    |- <instanceA>
    |   `- mongodb
    |       |- <year>-<month>-<day>_<hour>-<minute>.log
    |       `- <year>-<month>-<day>_<hour>-<minute>.gz
    `- SampleInstance
        `- mongodb
            |- 2017-10-12_17-48.log
            `- 2017-10-12_17-48.gz
```
