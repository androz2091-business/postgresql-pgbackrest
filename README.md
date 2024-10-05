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

### Retention

Full backup expires => all the incrementals/differentials that depend on it are expired too.
Any backup not expired => full WAL archive is kept.
Incremental backups can not be expired independently, they are always expired with the full/differential backup they depend on.

### Debug locally

```
mkdir test
mkdir test/data
mkdir test/pgbackrest
sudo chown -R 999:999 test
sudo docker build . -t pgbr && sudo docker run -e POSTGRES_PASSWORD=mysecretpassword -p 5435:5432 -v ./test/data:/var/lib/postgresql/data -v ./test/pgbackrest:/var/lib/pgbackrest pgbr
```
```
sudo rm -rf test && mkdir test && mkdir test/data && mkdir test/pgbackrest && sudo chown -R 999:999 test

```
create table users_test (
    user_id     varchar(50),
    date        timestamp NOT NULL DEFAULT NOW()
);
```

```
insert into users_test (user_id) values (1);
```

todo autoriser postgres tmp

```
pgbackrest --stanza=my-pg-pgbackrest-stanza --type=time --target="2024-10-05 12:53:55" restore
```
