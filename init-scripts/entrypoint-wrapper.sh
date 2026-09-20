#!/bin/bash
# Entrypoint wrapper — runs on EVERY container start.
# Launches postgres via the original entrypoint, then ensures
# the POSTGRES_USER role and POSTGRES_DB database exist.
# Connects as the 'postgres' fallback superuser (created by
# 00-ensure-fallback-superuser.sh on first init).

set -e

# Background task: wait for postgres, then ensure role + db
(
    until pg_isready -h /var/run/postgresql -q 2>/dev/null; do
        sleep 1
    done

    psql -h /var/run/postgresql -U postgres -d postgres -v ON_ERROR_STOP=0 <<-EOSQL
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${POSTGRES_USER}') THEN
                CREATE ROLE "${POSTGRES_USER}" WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}' SUPERUSER CREATEDB CREATEROLE;
                RAISE NOTICE 'Created role: ${POSTGRES_USER}';
            END IF;
        END
        \$\$;

        SELECT 'CREATE DATABASE "${POSTGRES_DB}" OWNER "${POSTGRES_USER}"'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_DB}')\gexec
EOSQL

    echo "ensure-role: done"
) &

# Hand off to the original entrypoint
exec docker-entrypoint.sh "$@"

