FROM ghcr.io/saleor/saleor:3.21

WORKDIR /app

RUN pip install --no-cache-dir "gunicorn>=21,<22" \
    && pip install --no-cache-dir psycopg2-binary

COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN set -eux; \
    sed -i 's/\r$//' /usr/local/bin/render-entrypoint.sh; \
    chmod 755 /usr/local/bin/render-entrypoint.sh

ENTRYPOINT ["render-entrypoint.sh"]
