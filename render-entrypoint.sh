#!/bin/sh
set -eu

export PYTHONPATH="/app:${PYTHONPATH:-}"
: "${PORT:=8000}"

echo "[entrypoint] Waiting for Postgres from \$DATABASE_URL ..."
python3 - <<'PY'
import os, time, sys, urllib.parse
import psycopg2

url = os.environ.get("DATABASE_URL")
if not url:
    print("DATABASE_URL is not set", file=sys.stderr); sys.exit(1)

# Render's DATABASE_URL is already in psycopg2 format.
for i in range(30):
    try:
        conn = psycopg2.connect(url); conn.close()
        print("Postgres is up."); sys.exit(0)
    except Exception as e:
        print(f"Postgres not ready yet ({e}), retry {i+1}/30...")
        time.sleep(2)
sys.exit(2)
PY

echo "[entrypoint] Running migrate & collectstatic ..."
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput || true

echo "[entrypoint] Ensuring superuser ..."
python3 - <<'PY'
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", os.environ.get("DJANGO_SETTINGS_MODULE","saleor.settings"))
django.setup()
from django.contrib.auth import get_user_model
email=os.environ.get("DASHBOARD_SUPERUSER_EMAIL")
password=os.environ.get("DASHBOARD_SUPERUSER_PASSWORD")
first=os.environ.get("DASHBOARD_SUPERUSER_FIRST_NAME","Admin")
last=os.environ.get("DASHBOARD_SUPERUSER_LAST_NAME","User")
User=get_user_model()
if email and password:
    if not User.objects.filter(email=email).exists():
        User.objects.create_superuser(email=email, password=password, first_name=first, last_name=last)
        print(f"Superuser created: {email}")
    else:
        print("Superuser already exists, skip.")
else:
    print("No superuser env provided, skip.")
PY

if [ "${RUN_POPULATEDB:-false}" = "true" ]; then
  echo "[entrypoint] Seeding demo data in background ..."
  (python3 manage.py populatedb --noinput >/proc/1/fd/1 2>/proc/1/fd/2 &) || true
fi

echo "[entrypoint] Starting Gunicorn on 0.0.0.0:${PORT} ..."
exec gunicorn saleor.wsgi:application \
  --chdir /app \
  --bind 0.0.0.0:${PORT} \
  --workers ${WEB_CONCURRENCY:-2} \
  --timeout 60
