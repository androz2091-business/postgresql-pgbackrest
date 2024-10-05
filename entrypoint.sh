#!/bin/bash

# define environment variables for the local and s3 backup repositories
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

PG_BACKREST_CRON_INCR_SCHEDULE=${PG_BACKREST_CRON_INCR_SCHEDULE:-"0 0 * * *"} # Every day at midnight
PG_BACKREST_CRON_FULL_SCHEDULE=${PG_BACKREST_CRON_FULL_SCHEDULE:-"0 0 * * 0"} # Sunday at midnight

cat > /etc/pgbackrest/pgbackrest.conf <<EOF
[my-pg-pgbackrest-stanza]
pg1-path=/var/lib/postgresql/data
pg1-port=5432

[global]
repo1-path=$PG_BACKREST_REPO_LOCAL_PATH
repo1-retention-full=$PG_BACKREST_REPO_LOCAL_RETENTION_FULL
repo1-retention-diff=$PG_BACKREST_REPO_LOCAL_RETENTION_INCR
EOF

if [ "$PG_BACKREST_REPO_S3_ENABLED" = "true" ]; then
    cat >> /etc/pgbackrest/pgbackrest.conf <<EOF

repo2-type=s3
repo2-path=$PG_BACKREST_REPO_S3_PATH
repo2-s3-bucket=$PG_BACKREST_REPO_S3_BUCKET
repo2-s3-endpoint=$PG_BACKREST_REPO_S3_ENDPOINT
repo2-s3-region=$PG_BACKREST_REPO_S3_REGION
repo2-s3-key=$PG_BACKREST_REPO_S3_KEY
repo2-s3-key-secret=$PG_BACKREST_REPO_S3_KEY_SECRET
repo2-s3-verify-tls=$PG_BACKREST_REPO_S3_VERIFY_TLS
repo2-retention-full=$PG_BACKREST_REPO_S3_RETENTION_FULL
repo2-retention-diff=$PG_BACKREST_REPO_S3_RETENTION_INCR
EOF
    echo "S3 backup repository configured in /etc/pgbackrest/pgbackrest.conf"
fi

echo "pgBackRest config file created with the following settings:"
cat /etc/pgbackrest/pgbackrest.conf # todo remove this

# do this later, see configure-pgbackrest.sh
# # Configure PostgreSQL to use pgBackRest for WAL archiving
# sed -i "s/#archive_mode = off/archive_mode = on/" /var/lib/postgresql/data/postgresql.conf
# sed -i "s/#archive_command = ''/archive_command = 'pgbackrest --stanza=my-pg-pgbackrest-stanza archive-push %p'/" /var/lib/postgresql/data/postgresql.conf
# sed -i "s/#archive_timeout = 0/archive_timeout = 60/" /var/lib/postgresql/data/postgresql.conf

echo "$PG_BACKREST_CRON_INCR_SCHEDULE pgbackrest --stanza=my-pg-pgbackrest-stanza --type=incr backup" >> /etc/crontab
echo "$PG_BACKREST_CRON_FULL_SCHEDULE pgbackrest --stanza=my-pg-pgbackrest-stanza --type=full backup" >> /etc/crontab
echo "Cron job created for pgBackRest incremental backups with schedule: $PG_BACKREST_CRON_INCR_SCHEDULE"
echo "Cron job created for pgBackRest full backups with schedule: $PG_BACKREST_CRON_FULL_SCHEDULE"

service cron start

# see https://github.com/docker-library/postgres/blob/c9906f922daaacdfc425b3b918e7644a8722290d/16/bookworm/Dockerfile#L192
exec docker-entrypoint.sh postgres

#sleep forever
#while true; do sleep 1000; done

# note: no need to "start" pgbackrest, as it is run as a cron job, it's not a continuously running service
