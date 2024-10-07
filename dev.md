### Debug locally

Here are some useful debug commands when developing locally:

```
mkdir test
mkdir test/data
mkdir test/pgbackrest
sudo chown -R 999:999 test
sudo docker build . -t pgbr && sudo docker run -e PG_BACKREST_REPO_LOCAL_ENABLED=true -e POSTGRES_PASSWORD=mysecretpassword -p 5435:5432 -v ./test/data:/var/lib/postgresql/data -v ./test/pgbackrest:/var/lib/pgbackrest pgbr
```
```
sudo rm -rf test && mkdir test && mkdir test/data && mkdir test/pgbackrest && sudo chown -R 999:999 test
```

```
sudo docker build . -t pgbr && sudo docker run -e PG_BACKREST_REPO_LOCAL_ENABLED=true -e POSTGRES_PASSWORD=mysecretpassword -e RESTORE_ENABLED=true -e RESTORE_TIMESTAMP="2024-10-06 17:33:27" -p 5435:5432 -v ./test/data:/var/lib/postgresql/data -v ./test/pgbackrest:/var/lib/pgbackrest pgbr
```

```
create table users_test (
    user_id     varchar(50),
    date        timestamp NOT NULL DEFAULT NOW()
);
```

```
insert into users_test (user_id) values (1);
```

```
pgbackrest --stanza=my-pg-pgbackrest-stanza --type=time --target="2024-10-05 12:53:55" restore
```
