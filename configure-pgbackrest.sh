#!/bin/bash

# this file has to be created separately from the entrypoint.sh script
# because it is not possible to modify the postgresql.conf file before the database is initialized

if [ -f /var/lib/postgresql/data/postgresql.conf ]; then
    sed -i "s/#archive_mode = off/archive_mode = on/" /var/lib/postgresql/data/postgresql.conf
    sed -i "s/#archive_command = ''/archive_command = 'pgbackrest --stanza=my-pg-pgbackrest-stanza archive-push %p'/" /var/lib/postgresql/data/postgresql.conf
    sed -i "s/#archive_timeout = 0/archive_timeout = 60/" /var/lib/postgresql/data/postgresql.conf

    echo "pgBackRest WAL archiving configured in postgresql.conf"
else
    echo "postgresql.conf not found, skipping configuration."
fi