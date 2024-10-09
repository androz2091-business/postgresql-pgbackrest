#!/bin/bash

RESTORE_ENABLED=${RESTORE_ENABLED:-false}
RESTORE_TIMESTAMP=${RESTORE_TIMESTAMP:-""}

QUIT_SHOW_REPO_INFO=${QUIT_SHOW_REPO_INFO:-false}

# define environment variables for the local and s3 backup repositories
PG_BACKREST_REPO_LOCAL_ENABLED=${PG_BACKREST_REPO_LOCAL_ENABLED:-true}
PG_BACKREST_REPO_LOCAL_PATH=${PG_BACKREST_REPO_LOCAL_PATH:-/var/lib/pgbackrest}
PG_BACKREST_REPO_LOCAL_RETENTION_FULL=${PG_BACKREST_REPO_LOCAL_RETENTION_FULL:-2}
PG_BACKREST_REPO_LOCAL_RETENTION_INCR=${PG_BACKREST_REPO_LOCAL_RETENTION_INCR:-7}

PG_BACKREST_REPO_S3_ENABLED=${PG_BACKREST_REPO_S3_ENABLED:-false}
PG_BACKREST_REPO_S3_TYPE=${PG_BACKREST_REPO_S3_TYPE:-""}
PG_BACKREST_REPO_S3_BUCKET=${PG_BACKREST_REPO_S3_BUCKET:-""}
PG_BACKREST_REPO_S3_ENDPOINT=${PG_BACKREST_REPO_S3_ENDPOINT:-""}
PG_BACKREST_REPO_S3_REGION=${PG_BACKREST_REPO_S3_REGION:-""}
PG_BACKREST_REPO_S3_KEY=${PG_BACKREST_REPO_S3_KEY:-""}
PG_BACKREST_REPO_S3_KEY_SECRET=${PG_BACKREST_REPO_S3_KEY_SECRET:-""}
PG_BACKREST_REPO_S3_VERIFY_TLS=${PG_BACKREST_REPO_S3_VERIFY_TLS:-y}
PG_BACKREST_REPO_S3_RETENTION_FULL=${PG_BACKREST_REPO_S3_RETENTION_FULL:-2}
PG_BACKREST_REPO_S3_RETENTION_INCR=${PG_BACKREST_REPO_S3_RETENTION_INCR:-7}
PG_BACKREST_REPO_S3_PATH=${PG_BACKREST_REPO_S3_PATH:-"/"}
PG_BACKREST_REPO_S3_URI_STYLE=${PG_BACKREST_REPO_S3_URI_STYLE:-path}

PG_BACKREST_CRON_INCR_SCHEDULE=${PG_BACKREST_CRON_INCR_SCHEDULE:-"0 0 * * *"} # Every day at midnight
PG_BACKREST_CRON_FULL_SCHEDULE=${PG_BACKREST_CRON_FULL_SCHEDULE:-"0 0 * * 0"} # Sunday at midnight

PG_BACKREST_CIPHER_ENABLED=${PG_BACKREST_CIPHER_ENABLED:-false}
PG_BACKREST_CIPHER_PASS=${PG_BACKREST_CIPHER_PASS:-""}
PG_BACKREST_CIPHER_TYPE=${PG_BACKREST_CIPHER_TYPE:-"aes-256-cbc"}

cat > /etc/pgbackrest/pgbackrest.conf << EOF
[my-pg-pgbackrest-stanza]
pg1-path=/var/lib/postgresql/data/pgdata
pg1-port=5432
EOF

if [ "$PG_BACKREST_REPO_LOCAL_ENABLED" = "true" ]; then
    cat >> /etc/pgbackrest/pgbackrest.conf << EOF
[global]
repo1-path=$PG_BACKREST_REPO_LOCAL_PATH
repo1-retention-full=$PG_BACKREST_REPO_LOCAL_RETENTION_FULL
repo1-retention-diff=$PG_BACKREST_REPO_LOCAL_RETENTION_INCR
EOF
    echo "Local backup repository configured /etc/pgbackrest/pgbackrest.conf"
fi

if [ "$PG_BACKREST_CIPHER_ENABLED" = "true" ]; then
    cat >> /etc/pgbackrest/pgbackrest.conf << EOF
repo1-cipher-pass=${PG_BACKREST_CIPHER_PASS}
repo1-cipher-type=${PG_BACKREST_CIPHER_TYPE}
EOF
    echo "pgBackRest encryption enabled in repo1 (local) /etc/pgbackrest/pgbackrest.conf"
fi

if [ "$PG_BACKREST_REPO_S3_ENABLED" = "true" ]; then
    repo_number=1
    if [ "$PG_BACKREST_REPO_LOCAL_ENABLED" = "true" ]; then
        repo_number=2
    fi

    cat >> /etc/pgbackrest/pgbackrest.conf <<EOF

repo${repo_number}-type=$PG_BACKREST_REPO_S3_TYPE
repo${repo_number}-path=$PG_BACKREST_REPO_S3_PATH
repo${repo_number}-s3-bucket=$PG_BACKREST_REPO_S3_BUCKET
repo${repo_number}-s3-endpoint=$PG_BACKREST_REPO_S3_ENDPOINT
repo${repo_number}-s3-region=$PG_BACKREST_REPO_S3_REGION
repo${repo_number}-s3-key=$PG_BACKREST_REPO_S3_KEY
repo${repo_number}-s3-key-secret=$PG_BACKREST_REPO_S3_KEY_SECRET
repo${repo_number}-s3-verify-tls=$PG_BACKREST_REPO_S3_VERIFY_TLS
repo${repo_number}-s3-uri-style=$PG_BACKREST_REPO_S3_URI_STYLE
repo${repo_number}-retention-full=$PG_BACKREST_REPO_S3_RETENTION_FULL
repo${repo_number}-retention-diff=$PG_BACKREST_REPO_S3_RETENTION_INCR
repo${repo_number}-bundle=y
EOF

if [ "$PG_BACKREST_CIPHER_ENABLED" = "true" ]; then
    cat >> /etc/pgbackrest/pgbackrest.conf << EOF
repo${repo_number}-cipher-pass=${PG_BACKREST_CIPHER_PASS}
repo${repo_number}-cipher-type=${PG_BACKREST_CIPHER_TYPE}
EOF
    echo "pgBackRest encryption enabled in repo${repo_number} /etc/pgbackrest/pgbackrest.conf"
fi

    echo "S3 backup repository configured in /etc/pgbackrest/pgbackrest.conf"
fi

echo "pgBackRest config file created with the following settings:"
cat /etc/pgbackrest/pgbackrest.conf # todo remove this

if [ "$QUIT_SHOW_REPO_INFO" = "true" ]; then
    date
    pgbackrest --stanza=my-pg-pgbackrest-stanza info
    exit 0
fi

if [ "$RESTORE_ENABLED" = "true" ]; then
    echo "Restoring database from backup"

    if [ "$RESTORE_TYPE" = "timestamp" ]; then
    
        if [ -z "$RESTORE_TIMESTAMP" ]; then
            echo "RESTORE_TIMESTAMP is required when RESTORE_TYPE is set to timestamp"
            exit 1
        fi

        # first move the data directory to a temporary location
        mkdir /var/lib/postgresql/data-tmp

        # if no data directory exists, this will just throw an error, but that's fine
        mv /var/lib/postgresql/data/* /var/lib/postgresql/data-tmp/
        echo "Moved data directory to /var/lib/postgresql/data-tmp"

        # then restore the database from the backup
        pgbackrest --stanza=my-pg-pgbackrest-stanza --type=time --target="$RESTORE_TIMESTAMP" restore
        echo "Database restored from backup"

    elif [ "$RESTORE_TYPE" = "latest" ]; then

        pgbackrest --stanza=my-pg-pgbackrest-stanza restore

    else
        echo "Invalid value for RESTORE_TYPE: $RESTORE_TYPE"
        exit 1
    fi
  
    echo "Database restored from backup"
fi

echo "$PG_BACKREST_CRON_INCR_SCHEDULE pgbackrest --stanza=my-pg-pgbackrest-stanza --type=incr backup" >> /etc/crontab
echo "$PG_BACKREST_CRON_FULL_SCHEDULE pgbackrest --stanza=my-pg-pgbackrest-stanza --type=full backup" >> /etc/crontab
echo "Cron job created for pgBackRest incremental backups with schedule: $PG_BACKREST_CRON_INCR_SCHEDULE"
echo "Cron job created for pgBackRest full backups with schedule: $PG_BACKREST_CRON_FULL_SCHEDULE"

service cron start

PG_DATA=/var/lib/postgresql/data/pgdata

# # see https://github.com/docker-library/postgres/blob/c9906f922daaacdfc425b3b918e7644a8722290d/16/bookworm/Dockerfile#L192
exec docker-entrypoint.sh postgres

#sleep forever
#while true; do sleep 1000; done

# note: no need to "start" pgbackrest, as it is run as a cron job, it's not a continuously running service
