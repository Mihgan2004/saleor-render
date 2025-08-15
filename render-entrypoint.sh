#!/bin/sh
set -eu

# 1) миграции и статика
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput || true

# 2) создать суперюзера, если отсутствует (без populatedb)
python3 - <<'PY'
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", os.environ.get("DJANGO_SETTINGS_MODULE","saleor.settings"))
django.setup()
from django.contrib.auth import get_user_model
email = os.environ.get("DASHBOARD_SUPERUSER_EMAIL")
password = os.environ.get("DASHBOARD_SUPERUSER_PASSWORD")
first = os.environ.get("DASHBOARD_SUPERUSER_FIRST_NAME","Admin")
last  = os.environ.get("DASHBOARD_SUPERUSER_LAST_NAME","User")
User = get_user_model()
if email and password:
    if not User.objects.filter(email=email).exists():
        User.objects.create_superuser(email=email, password=password, first_name=first, last_name=last)
        print(f"Superuser created: {email}")
    else:
        print("Superuser already exists, skip.")
else:
    print("No superuser env provided, skip.")
PY

# 3) демо-данные — в фоне (не блокируем поднятие порта)
if [ "${RUN_POPULATEDB:-false}" = "true" ]; then
  (python3 manage.py populatedb --noinput >/proc/1/fd/1 2>/proc/1/fd/2 &) || true
fi

# 4) запуск — слушаем именно $PORT, вызываем через python3 -m (мимо PATH)
exec python3 -m gunicorn saleor.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers ${WEB_CONCURRENCY:-2} --timeout 60
