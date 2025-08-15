FROM ghcr.io/saleor/saleor:3.21
WORKDIR /app
ENV PYTHONUNBUFFERED=1

# Устанавливаем gunicorn (чисто и без кеша)
RUN pip install --no-cache-dir "gunicorn>=21,<22"

# Копируем entrypoint и нормализуем
COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN set -eux; \
    sed -i 's/\r$//' /usr/local/bin/render-entrypoint.sh; \
    chmod 755 /usr/local/bin/render-entrypoint.sh

CMD ["/usr/local/bin/render-entrypoint.sh"]
