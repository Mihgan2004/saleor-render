FROM ghcr.io/saleor/saleor:3.21

# На всякий случай зафиксируем рабочую директорию
WORKDIR /app

# Логи без буфера
ENV PYTHONUNBUFFERED=1

# Скрипт запуска (мидграйты + опциональный демо-сид + gunicorn)
COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN chmod +x /usr/local/bin/render-entrypoint.sh

CMD ["/usr/local/bin/render-entrypoint.sh"]
