FROM ghcr.io/saleor/saleor:3.21
WORKDIR /app
ENV PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir "gunicorn>=21,<22"

COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN set -eux; \
    sed -i 's/\r$//' /usr/local/bin/render-entrypoint.sh; \
    chmod 755 /usr/local/bin/render-entrypoint.sh

CMD ["/usr/local/bin/render-entrypoint.sh"]
