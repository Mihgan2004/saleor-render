#!/bin/sh
set -eu

# Миграции + статика
python manage.py migrate --noinput
python manage.py collectstatic --noinput || true

# Однократная загрузка демо-данных
if [ "${RUN_POPULATEDB:-false}" = "true" ]; then
  python - <<'PY'
import os, django, sys
os.environ.setdefault("DJANGO_SETTINGS_MODULE", os.environ.get("DJANGO_SETTINGS_MODULE","saleor.settings"))
django.setup()
from saleor.product.models import Product
# exit 0 if DB has data, 1 if empty
sys.exit(0 if Product.objects.exists() else 1)
PY
  NEED_POPULATE=$?
  if [ "$NEED_POPULATE" -ne 0 ]; then
    echo "Populating DB with sample data and creating superuser…"
    python manage.py populatedb --createsuperuser --noinput
  else
    echo "DB already has data, skip populatedb."
  fi
fi

# Запуск — слушаем PORT от Render
exec gunicorn saleor.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers ${WEB_CONCURRENCY:-4} --timeout 60
