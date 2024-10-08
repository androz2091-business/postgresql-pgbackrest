FROM postgres:16-bookworm

RUN apt-get update && \
    apt-get install -y pgbackrest cron && \
    apt-get clean

RUN mkdir -p /etc/pgbackrest /var/lib/pgbackrest
RUN chown -R postgres:postgres /etc/pgbackrest /var/lib/pgbackrest

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# this will run once postgres is up and running (it creates the pgbackrest stanza and enable archiving in postgres)
COPY configure-pgbackrest.sh /docker-entrypoint-initdb.d/configure-pgbackrest.sh
RUN chmod +x /docker-entrypoint-initdb.d/configure-pgbackrest.sh

EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
