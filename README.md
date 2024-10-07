# PostgreSQL PgBackRest

This repository contains the Dockerfile used to build a PostgreSQL image with [PgBackRest](https://pgbackrest.org/) backup tool.

## Configuration

The following environment variables are available. By default, the image should be run with `RESTORE_ENABLED=false`. It is going to start backing up the database, archiving the WAL and pushing them to the configured repositories.

When starting the image with the same repositories and `RESTORE_ENABLED=true`, it **WILL ERASE THE CURRENT CLUSTER DATA** (if existing) and restore the cluster to the specified timestamp (if a valid backup can be found on the repositories).

### Restore configuration

```bash
RESTORE_ENABLED=false
RESTORE_TYPE=timestamp
RESTORE_TIMESTAMP="2024-10-06 17:33:27+00"
# or you can use:
#RESTORE_TYPE=latest
```

### Repositories configuration

```bash
PG_BACKREST_REPO_LOCAL_ENABLED=true
PG_BACKREST_REPO_LOCAL_PATH=/var/lib/pgbackrest
PG_BACKREST_REPO_LOCAL_RETENTION_FULL=2 # Number of full backups to keep
PG_BACKREST_REPO_LOCAL_RETENTION_INCR=7 # Number of incremental backups to keep

PG_BACKREST_REPO_S3_ENABLED=false
# see " S3-Compatible Object Store Support" section of https://pgbackrest.org/user-guide.html
# note: s3 uri style is path style
PG_BACKREST_REPO_S3_TYPE=
PG_BACKREST_REPO_S3_BUCKET=
PG_BACKREST_REPO_S3_ENDPOINT=
PG_BACKREST_REPO_S3_REGION=
PG_BACKREST_REPO_S3_KEY=
PG_BACKREST_REPO_S3_KEY_SECRET=
PG_BACKREST_REPO_S3_VERIFY_TLS=
PG_BACKREST_REPO_S3_RETENTION_FULL=
PG_BACKREST_REPO_S3_RETENTION_INCR=
PG_BACKREST_REPO_S3_PATH=

PG_BACKREST_CRON_INCR_SCHEDULE="0 0 * * *" # Every day at midnight
PG_BACKREST_CRON_FULL_SCHEDULE="0 0 * * 0" # Sunday at midnight
```

### Known issues

To enable WAL archiving, the script updates the `postgresql.conf` file and restarts the PostgreSQL service. You can not use any other `archive_command` with this postgres image.

### Retention

The WAL is kept as long as a full backup is not expired. When a full backup expires, all the incrementals/differentials that depend on it are expired too. Incremental backups can not be expired independently, they are always expired with the full/differential backup they depend on.

### Debug

You can use the image with `QUIT_SHOW_REPO_INFO=true` to make it print the repositories information (it will list the backups) and exit.
