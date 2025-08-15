#!/usr/bin/env bash
set -euo pipefail

# Миграции и статика
python manage.py migrate --noinput
python manage.py collectstatic --noinput || true

# Однократная инициализация демо-данных (без дублей)
if [ "${RUN_POPULATEDB:-false}" = "true" ]; then
  echo "Checking if DB is empty to run populatedb…"
  if python - <<'PY'
import os, django, sys
os.environ.setdefault("DJANGO_SETTINGS_MODULE", os.environ.get("DJANGO_SETTINGS_MODULE", "saleor.settings"))
django.setup()
from saleor.product.models import Product
sys.exit(0 if Product.objects.exists() else 1)
PY
  then
    echo "DB already contains data. Skipping populatedb."
  else
    echo "Populating database with sample data and creating superuser…"
    python manage.py populatedb --createsuperuser --noinput
  fi
fi

# Запуск приложения — слушаем именно $PORT от Render
exec gunicorn saleor.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers ${WEB_CONCURRENCY:-4} --timeout 60
