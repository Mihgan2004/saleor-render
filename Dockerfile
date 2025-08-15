# Dockerfile
FROM ghcr.io/saleor/saleor:3.21

WORKDIR /app
ENV PYTHONUNBUFFERED=1

# gunicorn для воркеров и uvicorn для ASGI + клиент к Postgres для проверки подключения
RUN pip install --no-cache-dir "gunicorn>=21,<22" \
    "uvicorn[standard]>=0.23,<1" \
    psycopg2-binary

# Наш стартовый скрипт
COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN set -eux; \
    sed -i 's/\r$//' /usr/local/bin/render-entrypoint.sh; \
    chmod 755 /usr/local/bin/render-entrypoint.sh

# В Render Start Command оставьте пустым — возьмётся CMD из образа
CMD ["/usr/local/bin/render-entrypoint.sh"]
