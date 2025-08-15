#!/bin/sh
set -eu

python manage.py migrate --noinput
python manage.py collectstatic --noinput || true

if [ "${RUN_POPULATEDB:-false}" = "true" ]; then
  python - <<'PY'
import os, django, sys
os.environ.setdefault("DJANGO_SETTINGS_MODULE", os.environ.get("DJANGO_SETTINGS_MODULE","saleor.settings"))
django.setup()
from saleor.product.models import Product
sys.exit(0 if Product.objects.exists() else 1)
PY
  if [ "$?" -ne 0 ]; then
    python manage.py populatedb --createsuperuser --noinput
  fi
fi

exec gunicorn saleor.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers ${WEB_CONCURRENCY:-4} --timeout 60
