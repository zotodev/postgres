#!/bin/bash
# Runs ONLY on first init (empty data dir).
# Ensures a 'postgres' fallback superuser always exists,
# even if POSTGRES_USER is set to something else.
# This gives us a known account the entrypoint wrapper can
# connect with on every subsequent start.

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-'EOSQL'
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'postgres') THEN
            CREATE ROLE postgres WITH LOGIN SUPERUSER;
            RAISE NOTICE 'Created fallback superuser: postgres';
        END IF;
    END
    $$;
EOSQL

