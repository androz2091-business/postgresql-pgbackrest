# PostgreSQL PgBackRest

## Environment Variables

```bash
PG_BACKREST_REPO_LOCAL_PATH=/var/lib/pgbackrest
PG_BACKREST_REPO_LOCAL_RETENTION_FULL=2
PG_BACKREST_REPO_LOCAL_RETENTION_INCR=7

PG_BACKREST_REPO_S3_ENABLED=false
# see " S3-Compatible Object Store Support" section of https://pgbackrest.org/user-guide.html
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

To enable WAL archiving, the script updates the `postgresql.conf` file and restarts the PostgreSQL service. What if some PostgreSQL instance use their own archiving or even their own `postgresql.conf` file as a `ConfigMap`? Will it be a conflict issue?

### Debug locally

```
mkdir test
mkdir test/data
mkdir test/pgbackrest
chown -R 999:999 test
sudo docker build . -t pgbr && sudo docker run -e POSTGRES_PASSWORD=mysecretpassword -p 5435:5432 -v ./test/data:/var/lib/postgresql/data -v ./test/pgbackrest:/var/lib/pgbackrest pgbr
```
