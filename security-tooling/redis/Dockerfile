FROM redis:7-alpine

EXPOSE 6379

# Use REDIS_PASSWORD env var; default provided in docker-compose
CMD sh -c "redis-server --requirepass ${REDIS_PASSWORD:-honeypod-redis-password-2024}"
