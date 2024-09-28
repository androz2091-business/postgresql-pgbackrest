FROM postgres:16-bookworm

RUN apt-get update && \
    apt-get install -y pgbackrest cron && \
    apt-get clean

RUN mkdir -p /etc/pgbackrest /var/lib/pgbackrest
RUN chown -R postgres:postgres /etc/pgbackrest /var/lib/pgbackrest

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY configure-pgbackrest.sh /docker-entrypoint-initdb.d/configure-pgbackrest.sh
RUN chmod +x /docker-entrypoint-initdb.d/configure-pgbackrest.sh

# otherwise PgBackRest will not run as postgres as recommended in the wiki
USER postgres

EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
