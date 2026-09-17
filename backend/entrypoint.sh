#!/bin/sh
set -e

echo "Waiting for PostgreSQL..."
until python -c "
import sys, psycopg
try:
    psycopg.connect('${DATABASE_URL_SYNC}')
except Exception as e:
    print(e); sys.exit(1)
" 2>/dev/null; do
  sleep 1
done
echo "PostgreSQL is up."

echo "Running Alembic migrations..."
alembic upgrade head

if [ "$SEED_DB" = "true" ]; then
  echo "Seeding database (SEED_DB=true)..."
  python -c "
import os, psycopg
with open('seed_data.sql') as f:
    sql = f.read()
with psycopg.connect(os.environ['DATABASE_URL_SYNC']) as conn:
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()
print('Seed applied (or already present).')
" || echo "Seed skipped (already applied or error ignored)."
fi

echo "Starting Uvicorn..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
