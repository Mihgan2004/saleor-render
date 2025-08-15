FROM ghcr.io/saleor/saleor:3.21

ENV PORT=8000

# При старте: миграции + демо-данные + gunicorn
CMD python manage.py migrate && \
    python manage.py populatedb --createsuperuser --noinput && \
    gunicorn saleor.wsgi:application --bind 0.0.0.0:8000
