FROM ghcr.io/saleor/saleor:3.21
WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN chmod +x /usr/local/bin/render-entrypoint.sh
CMD ["/usr/local/bin/render-entrypoint.sh"]
