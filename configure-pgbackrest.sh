#!/bin/bash

# this file has to be created separately from the entrypoint.sh script
# because it is not possible to modify the postgresql.conf file before the database is initialized

echo "Configuring pgBackRest for WAL archiving and create stanza ($PGDATA)"

if [ -f $PGDATA/postgresql.conf ]; then
    sed -i "s/#archive_mode = off/archive_mode = on/" $PGDATA/postgresql.conf
    sed -i "s/#archive_command = ''/archive_command = 'pgbackrest --stanza=my-pg-pgbackrest-stanza archive-push %p'/" $PGDATA/postgresql.conf
    sed -i "s/#archive_timeout = 0/archive_timeout = 60/" $PGDATA/postgresql.conf

    pg_ctl restart
    echo "pgBackRest WAL archiving configured in postgresql.conf"

    pgbackrest --stanza=my-pg-pgbackrest-stanza --log-level-console=info stanza-create
    echo "pgBackRest stanza created"

    # create a backup immediately
    pgbackrest --stanza=my-pg-pgbackrest-stanza --log-level-console=info --type=full backup
else
    echo "postgresql.conf not found, skipping configuration."
fi
