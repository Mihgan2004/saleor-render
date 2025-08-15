#!/bin/sh
set -euo pipefail

# Базовые переменные
export PORT="${PORT:-8000}"
export DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-saleor.settings}"
export PYTHONPATH="/app:${PYTHONPATH:-}"

echo "[entrypoint] Sanity-check Python imports..."
python3 - <<'PY'
import importlib
for mod in ("saleor", "saleor.settings", "saleor.asgi"):
    importlib.import_module(mod)
print("Saleor import OK")
PY

echo "[entrypoint] Waiting for Postgres from \$DATABASE_URL ..."
python3 - <<'PY'
import os, time, sys
import psycopg2
url = os.environ.get("DATABASE_URL")
if not url:
    print("DATABASE_URL is not set", file=sys.stderr); sys.exit(1)
for i in range(30):
    try:
        conn = psycopg2.connect(url); conn.close()
        print("Postgres is up."); sys.exit(0)
    except Exception as e:
        print(f"Postgres not ready yet ({e}), retry {i+1}/30...")
        time.sleep(2)
print("Postgres timed out", file=sys.stderr); sys.exit(2)
PY

echo "[entrypoint] Running migrate ..."
python3 manage.py migrate --noinput

echo "[entrypoint] Collecting static (best-effort) ..."
python3 manage.py collectstatic --noinput || true

echo "[entrypoint] Ensuring superuser (optional) ..."
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

echo "[entrypoint] Starting ASGI: gunicorn + uvicorn worker on 0.0.0.0:${PORT} ..."
# Важно: Saleor 3.x — ASGI
exec gunicorn -k uvicorn.workers.UvicornWorker saleor.asgi:application \
  --chdir /app \
  --bind 0.0.0.0:${PORT} \
  --workers ${WEB_CONCURRENCY:-2} \
  --timeout 60
